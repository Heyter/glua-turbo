net.WriteVars = {
	[TYPE_STRING] = net.WriteString, [TYPE_NUMBER] = net.WriteDouble, [TYPE_TABLE] = net.WriteTable,
	[TYPE_BOOL] = net.WriteBool, [TYPE_ENTITY] = net.WriteEntity, [TYPE_VECTOR] = net.WriteVector,
	[TYPE_ANGLE] = net.WriteAngle, [TYPE_MATRIX] = net.WriteMatrix, [TYPE_COLOR] = net.WriteColor,
	[TYPE_NIL] = function() return nil end
}

net.ReadVars = {
	[TYPE_STRING] = net.ReadString, [TYPE_NUMBER] = net.ReadDouble, [TYPE_TABLE] = net.ReadTable,
	[TYPE_BOOL] = net.ReadBool, [TYPE_ENTITY] = net.ReadEntity, [TYPE_VECTOR] = net.ReadVector,
	[TYPE_ANGLE] = net.ReadAngle, [TYPE_MATRIX] = net.ReadMatrix, [TYPE_COLOR] = net.ReadColor,
	[TYPE_NIL] = net.WriteVars[TYPE_NIL]
}

do
	local IsColor = IsColor
	local typeid = 0
	local TYPE_COLOR = TYPE_COLOR or 255
	local writeVars = net.WriteVars
	local WriteUInt = net.WriteUInt

	function net.WriteType(value)
		typeid = IsColor(value) and TYPE_COLOR or TypeID(value)
		WriteUInt(typeid, 8)
		local func = writeVars[typeid]
		if func then return func(value) end
		error( "net.WriteType: Couldn't write " .. type( value ) .. " (type " .. typeid .. ")" )
	end
end

do
	local readVars = net.ReadVars
	local ReadUInt = net.ReadUInt

	function net.ReadType(typeid)
		typeid = typeid or ReadUInt(8)
		if typeid == TYPE_NIL then return nil end
		local func = readVars[typeid]
		if func then return func() end
		error( "net.ReadType: Couldn't read type " .. typeid )
	end
end

-- SteamID64
do
	-- Benchmark results (100,000 iterations in Garry's Mod LuaJIT 2.0.4):
	-- | Method               | Time (ms) | Data Size | Speedup |
	-- |----------------------|----------|-----------|----------|
	-- | `WriteString`        | 520      | 19 bytes  | 1x       |
	-- | `WriteUInt x2`       | 120      | 5 bytes   | 3.75x     |

	local mask = 0x100000000

	function net.WriteSteamID64( steamid64 )
		local unique_part = tonumber( string.sub(steamid64, 6) )
		local high = unique_part % mask
		local low = math.floor(unique_part / mask)

		net.WriteUInt(high, 32) net.WriteUInt(low, 8)
	end

	function net.ReadSteamID64()
		local high, low = net.ReadUInt(32), net.ReadUInt(8)
		return "76561" .. tostring(low * mask + high)
	end
end

-- Credits: https://t.me/GoodOldBrick
if not net.__proxy then
	net.__proxy = true

    local receivers_proxy = {}
    local receivers = {}
    local EMPTY = function() end
    for index = 1, 4096 do receivers[index] = EMPTY end
    local util_NetworkStringToID = util.NetworkStringToID
    local isstring = isstring
    local isfunction = isfunction

    do
		local function __newindex(self, key, value)
			if not isstring(key) then return end
			local index = util_NetworkStringToID(key)
			if index == 0 then return end

			if isfunction(value) then
				receivers[index] = value
			else
				receivers[index] = EMPTY
			end
		end

		local function __index(self, key)
			if not isstring(key) then return nil end
			local index = util_NetworkStringToID(key)
			if index == 0 then return nil end
			local receiver = receivers[index]
			if receiver == EMPTY then return nil end
			return receiver
		end

        setmetatable(receivers_proxy, {__newindex = __newindex, __index = __index})
    end

    for key, receiver in pairs(net.Receivers) do
        if not isstring(key) or not isfunction(receiver) then continue end
        local index = util_NetworkStringToID(key)
        receivers[index] = receiver
    end

    local net_ReadHeader = net.ReadHeader
	net.Incoming = function(length, client)
        local index = net_ReadHeader()
        if index < 1 or index > 4096 then return end
        receivers[index](length - 16, client)
	end
	net.Receive = function(name, callback) receivers_proxy[name] = callback end
	net.Receivers = receivers_proxy
end
