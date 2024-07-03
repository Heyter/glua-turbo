do
	local getmetatable = getmetatable

	do
		local meta = debug.getmetatable("")
		function isstring(val) return val and getmetatable(val) == meta end
	end

	do
		local _type = 0
		debug.setmetatable(_type, {MetaName = "number", MetaID = TypeID(_type)})
		local meta = debug.getmetatable(_type)
		function isnumber(val) return val and getmetatable(val) == meta end
	end

	do
		local _type = coroutine.create(function() end)
		debug.setmetatable(_type, {MetaName = "thread", MetaID = TypeID(_type)})
	end

	do
		local _type = function() end
		debug.setmetatable(_type, {MetaName = "function", MetaID = TypeID(_type)})
		local meta = debug.getmetatable(_type)
		function isfunction(val) return val and getmetatable(val) == meta end
	end

	do
		local _type = true
		debug.setmetatable(_type, {MetaName = "boolean", MetaID = TypeID(_type)})
		local meta = debug.getmetatable(_type)
		function isboolean(val) return val and getmetatable(val) == meta end
	end

	for k, v in pairs({
		["Vector"] = "vector", ["Angle"] = "angle",
		["VMatrix"] = "matrix", ["Panel"] = "panel"
	}) do
		local meta = FindMetaTable(k)
		_G["is" .. v] = function(val) return val and getmetatable(val) == meta end
	end
end

do
	-- Unique meta-tables for each
	setmetatable(FindMetaTable("Weapon"), {__index = FindMetaTable("Entity")})
	setmetatable(FindMetaTable("NPC"), {__index = FindMetaTable("Entity")})
	setmetatable(FindMetaTable("Vehicle"), {__index = FindMetaTable("Entity")})

	-- Credits: https://github.com/swampservers/contrib/blob/master/lua/swamp/sh_meta.lua
	if isfunction(Entity) then
		local EntityFunction = Entity
		Entity = FindMetaTable("Entity")

		setmetatable(Entity, {
			__call = function(_, x) return EntityFunction(x) end
		})
	end

	if isfunction(Player) then
		local PlayerFunction = Player
		Player = FindMetaTable("Player")

		setmetatable(Player, {
			__call = function(_, x) return PlayerFunction(x) end
		})
	end

	local ENT = Entity

	do
		-- caches the Entity.GetTable so stuff is super fast
		CEntityGetTable = CEntityGetTable or ENT.GetTable
		local cgettable = CEntityGetTable
		local rawset = rawset

		-- __mode = "kv",
		EntityTable = setmetatable({}, {
			__mode = "k",
			__index = function(self, ent)
				local tab = cgettable(ent)
				-- extension: perhaps initialize default values in the entity table here?
				rawset(self, ent, tab)

				return tab
			end
		})
	end

	local GetTable = EntityTable
	local simple = timer.Simple

	-- Apparently entities cant be weak keys
	hook.Add("EntityRemoved", "CleanupEntityTableCache", function(ent)
		simple(0, function()
			GetTable[ent] = nil
		end)
	end)

	function ENT:GetTable()
		return GetTable[self]
	end

	do
		local rawequal = rawequal
		function ENT.__eq(a, b)
			return rawequal(a, b)
		end
	end

	local dt = {}

	do
		local PLY = Player
		function PLY:__index(key)
			return PLY[key] or ENT[key] or (GetTable[self] or dt)[key]
		end
	end

	local GetOwner = ENT.GetOwner
	local ownerkey = "Owner"

	function ENT:__index(key)
		if (key == ownerkey) then return GetOwner(self) end
		return ENT[key] or (GetTable[self] or dt)[key]
	end

	do
		local WEP = FindMetaTable("Weapon")
		function WEP:__index(key)
			if (key == ownerkey) then return GetOwner(self) end
			return WEP[key] or ENT[key] or (GetTable[self] or dt)[key]
		end
	end

	do
		local VEH = FindMetaTable("Vehicle")
		function VEH:__index(key)
			if (key == ownerkey) then return GetOwner(self) end
			return VEH[key] or ENT[key] or (GetTable[self] or dt)[key]
		end
	end

	-- do
		-- local _R = debug.getregistry()
		-- local ENTITY = _R.Entity

		-- local entTabs = {
			-- ["Entity"] = { __index = ENTITY },
			-- ["Player"] = { __index = setmetatable( table.Copy( _R.Player ), { __index = ENTITY } ) },
			-- ["Weapon"] = { __index = setmetatable( table.Copy( _R.Weapon ), { __index = ENTITY } ) },
			-- ["Vehicle"] = { __index = setmetatable( table.Copy( _R.Vehicle ), { __index = ENTITY } ) },
			-- ["NPC"] = { __index = setmetatable( table.Copy( _R.NPC ), { __index = ENTITY } ) }
		-- }

		-- local ownerkey = "Owner"
		-- local copyKeys = {"MetaID", "MetaName", "__tostring", "__eq", "__concat"}
		-- local copyKeysLength = #copyKeys

		-- local function copyMetatable( ent, entTabName )
			-- if (!entTabs[entTabName]) then return end
			-- local tab = GetTable[ent]
			-- setmetatable(tab, entTabs[entTabName])

			-- local mt = {
				-- __index = function( self, key )
					-- if key == ownerkey then return GetOwner(self, key) end
					-- return tab[key]
				-- end,
				-- __newindex = tab,
				-- __metatable = ENTITY
			-- }

			-- local v
			-- for i = 1, copyKeysLength do
				-- v = copyKeys[i]
				-- mt[v] = ENTITY[v]
			-- end
			-- v = nil

			-- debug.setmetatable(ent, mt)
		-- end

		-- hook.Add("OnEntityCreated", "turbo.ChangeEntMeta", function(ent)
			-- timer.Simple(0, function()
				-- if (IsValid(ent)) then
					-- copyMetatable(ent, debug.getmetatable(ent).MetaName)
				-- end
			-- end)
		-- end, HOOK_MONITOR_HIGH)
	-- end
end