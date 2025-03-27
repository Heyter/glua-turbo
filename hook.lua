local debug_getinfo = debug.getinfo
local isstring = isstring
local isfunction = isfunction
local IsValid = IsValid
local pairs = pairs

local hook_callbacks = {}
local hook_index = {}
local hook_id = {}

local function GetTable() -- This function is now slow
    local ret = {}
    for name, callbacks in pairs(hook_callbacks) do
        ret[name] = {}
        local ids = hook_id[name]
        for index = 1, #callbacks do
            ret[name][ids[index]] = callbacks[index]
        end
    end
    return ret
end

-- hook.Exists("HUDPaint", "test")
local function Exists(name, id)
    local index = hook_index[name]
    return index and index[id] ~= nil
end

-- hook.HasHook("HUDPaint")
local function HasHook(event_name)
    return hook_index[event_name] ~= nil
end

-- hook.GetHook("HUDPaint", "test")
local function GetHook(name, uniq) -- @return function
    local index = hook_index[name]
    if not index then return end
    
    local id = index[uniq]
    return id and hook_callbacks[name][id]
end

local function Call(name, gm, ...)
	local callbacks = hook_callbacks[name]

	if callbacks ~= nil then
		local i = #callbacks

		if i > 0 then
			::runhook::
			local v = callbacks[i]
			if v ~= nil then
				local a, b, c, d, e, f = v(...)

				if a ~= nil then
					return a, b, c, d, e, f
				end

				i = i - 1
				goto runhook
			end
		end
	end

	if not gm then return end

	local callback = gm[name]
	if not callback then return end

	return callback(gm, ...)
end

local function Run(name, ...)
	return Call(name, GAMEMODE, ...)
end

local function Remove(name, id)
	local callbacks = hook_callbacks[name]
	if not callbacks then return end

	local indexes = hook_index[name]
	local index = indexes[id]
	if not index then return end

	local count = #callbacks
	local ids = hook_id[name]

	if count == index then
		callbacks[index] = nil
		indexes[id] = nil
		ids[index] = nil
	else
		callbacks[index] = callbacks[count]
		callbacks[count] = nil

		local lastid = ids[count]
		indexes[id] = nil
		indexes[lastid] = index

		ids[index] = lastid
		ids[count] = nil
	end
end

local function Add(name, id, callback)
    if isfunction(id) then
        callback = id
        id = debug_getinfo(callback, "S").short_src
    end

	if not callback then return end
    if hook_callbacks[name] == nil then
        hook_callbacks[name] = {}
        hook_index[name] = {}
        hook_id[name] = {}
    end

    if Exists(name, id) then Remove(name, id) end
    local callbacks = hook_callbacks[name]
    local indexes = hook_index[name]

	if not isstring(id) then
		local orig = callback
		callback = function(...)
			if IsValid(id) then return orig(id, ...) end
			local index = indexes[id]
			Remove(name, id)

			local nextcallback = callbacks[index]
			if nextcallback ~= nil then return nextcallback(...) end
		end
	end

	local index = #callbacks + 1
	callbacks[index] = callback
	indexes[id] = index
	hook_id[name][index] = id
end

hook = setmetatable({
	Remove = Remove, GetTable = GetTable, Exists = Exists, HasHook = HasHook,
	Add = Add, Call = Call, GetHook = GetHook, Run = Run
}, { __call = function(self, ...) return self.Add(...) end })
