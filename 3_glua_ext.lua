do
	local receivers = net.Receivers
	local lower = string.lower

	function net.Receive(name, func) receivers[lower(name)] = func end

	if !NetMonitor then
		local readHead = net.ReadHeader
		local networkID = util.NetworkIDToString

		function net.Incoming(len, client)
			local strName = networkID(readHead())
			if (!strName) then return end

			local func = receivers[lower(strName)]
			if (!func) then return end

			len = len - 16
			func(len, client)
		end
	end
end

local R = debug.getregistry()
local ENTITY = R.Entity
local WEAPON = R.Weapon
local NPC = R.NPC
local PLAYER = R.Player
local PHYS = R.PhysObj

do
	do
		local typeMeta = {
			[debug.getmetatable("")] = 'string',
			[debug.getmetatable(0)] = 'number',
			[debug.getmetatable(false)] = 'boolean',
			[debug.getmetatable(function() end)] = 'function',
			[R.Vector] = 'Vector',
			[R.Angle] = 'Angle',
			[R.VMatrix] = 'VMatrix',
			[PLAYER] = 'Player',
			[ENTITY] = 'Entity',
			[WEAPON] = 'Weapon',
			[NPC] = 'NPC',
			[R.Color] = 'table',
			[PHYS] = 'PhysObj',
			[R.Vehicle] = 'Vehicle',
			[R.IMaterial] = 'IMaterial',
			[R.CTakeDamageInfo] = 'CTakeDamageInfo',
			[R.CEffectData] = 'CEffectData',
			[R.CMoveData] = 'CMoveData',
			[R.CUserCmd] = 'CUserCmd',
			[R.ConVar] = 'ConVar'
		}

		if CLIENT then
			typeMeta[R.Panel] = 'Panel'
			typeMeta[R.CSEnt] = 'CSEnt'
			typeMeta[R.IMesh] = 'IMesh'
		end

		oldType = oldType or type
		local getmetatable = getmetatable
		local __type = oldType

		function type(object)
			if object == nil then return 'nil' end
			return typeMeta[getmetatable(object)] or __type(object)
		end
	end

	if jit.status() == true then
		local TYPE_NIL = TYPE_NIL
		local typeIDs = {
			[debug.getmetatable("")] = TYPE_STRING,
			[debug.getmetatable(0)] = TYPE_NUMBER,
			[debug.getmetatable(false)] = TYPE_BOOL,
			[debug.getmetatable(function() end)] = TYPE_FUNCTION,
			[R.Vector] = TYPE_VECTOR,
			[R.Angle] = TYPE_ANGLE,
			[R.VMatrix] = TYPE_MATRIX,
			[PLAYER] = TYPE_ENTITY,
			[ENTITY] = TYPE_ENTITY,
			[WEAPON] = TYPE_ENTITY,
			[NPC] = TYPE_ENTITY,
			[R.Color] = TYPE_COLOR,
			[PHYS] = TYPE_PHYSOBJ,
			[R.Vehicle] = TYPE_ENTITY,
			[R.IMaterial] = TYPE_MATERIAL,
			[R.CTakeDamageInfo] = TYPE_DAMAGEINFO,
			[R.CEffectData] = TYPE_EFFECTDATA,
			[R.CMoveData] = TYPE_MOVEDATA,
			[R.CUserCmd] = TYPE_USERCMD,
			[R.ConVar] = TYPE_CONVAR
		}

		if CLIENT then
			typeIDs[R.Panel] = TYPE_PANEL
			typeIDs[R.CSEnt] = TYPE_ENTITY
			typeIDs[R.IMesh] = TYPE_IMESH
		end

		oldTypeID = oldTypeID or TypeID
		local __oldType = oldTypeID
		local getmetatable = getmetatable

		function TypeID(object)
			if object == nil then return TYPE_NIL end
			return typeIDs[getmetatable(object)] or __oldType(object)
		end
	else
		local TYPE_NIL = TYPE_NIL
		oldTypeID = oldTypeID or TypeID
		local __oldType = oldTypeID

		function TypeID(object)
			if object == nil then return TYPE_NIL end
			return __oldType(object)
		end
	end
end

---- 1 000 000
-- table.remove:
        -- sum = 12.332
        -- avg = 0.12332
        -- median = 0.010999999999999
-- table.Remove:
        -- sum = 1.041
        -- avg = 0.01041
        -- median = 0.009999999999998
function table.Remove(tbl, index)
    local c = #tbl

	-- if index > c then
		-- index = c
	-- end

	local lastValue = tbl[index]

	if index >= c or c == 1 then
		tbl[index] = nil
    else
        tbl[index] = tbl[c]
        tbl[c] = nil
    end

	return lastValue
end

do
	---- 1 000 000
	-- BlastDamageSqr:
			-- sum = 0.13600000000002
			-- avg = 0.13600000000002
			-- median = 0.13600000000002
	-- BlastDamage:
			-- sum = 0.858
			-- avg = 0.858
			-- median = 0.858

	local trace = {}
	local traceData = {output = trace, filter = {}}

	function util.BlastDamageSqr(inflictor, attacker, damageOrigin, damageRadius, damage)
		if damage == 0 then return end

		-- local players = player.cache.IteratorHumans()
		local players = player.GetAll()
		local ply = NULL
		local dmg = 0

		local info = DamageInfo()
		info:SetAttacker(attacker)
		info:SetInflictor(inflictor)
		info:SetDamageType(DMG_BLAST)
		info:SetDamageForce(vector_up)
		info:SetDamagePosition(damageOrigin)

		traceData.start = damageOrigin
		traceData.filter[1] = inflictor

		local sqr = damageRadius * damageRadius
		local dist = 0

		for i = 1, #players do
			ply = players[i]

			if ply then
				dist = ply:GetPos():DistToSqr(damageOrigin)

				if dist == 0 or dist <= sqr then
					dmg = dist == 0 and damage or 0

					if dmg == 0 then
						traceData.filter[2] = ply
						traceData.endpos = ply:NearestPoint(damageOrigin)
						util.TraceLine(traceData)

						if not trace.Hit or trace.Entity == ply then
							dmg = ((damageRadius - traceData.endpos:Distance(damageOrigin)) / damageRadius) * damage
						end
					end

					if dmg > 0 then
						info:SetDamage(dmg)
						ply:TakeDamageInfo(info)
					end
				end
			end
		end
	end
end

--- type
local returnFalse = function() return false end
local returnTrue = function() return true end

ENTITY.IsPlayer = returnFalse
ENTITY.IsWeapon = returnFalse
ENTITY.IsNPC = returnFalse
ENTITY.IsNextbot = returnFalse
WEAPON.IsPlayer = returnFalse
WEAPON.IsWeapon = returnTrue
WEAPON.IsNPC = returnFalse
WEAPON.IsNextbot = returnFalse
NPC.IsPlayer = returnFalse
NPC.IsWeapon = returnFalse
NPC.IsNPC = returnTrue
NPC.IsNextbot = returnFalse
PLAYER.IsWeapon = returnFalse
PLAYER.IsNPC = returnFalse
PLAYER.IsNextbot = returnFalse
PLAYER.IsPlayer = returnTrue
PHYS.IsWeapon = returnFalse
PHYS.IsNPC = returnFalse
PHYS.IsNextbot = returnFalse
PHYS.IsPlayer = returnFalse

if (SERVER) then
	local NEXTBOT = R.NextBot
	NEXTBOT.IsPlayer = returnFalse
	NEXTBOT.IsWeapon = returnFalse
	NEXTBOT.IsNPC = returnFalse
	NEXTBOT.IsNextbot = returnTrue
end

local pattern = "%s%s%s"
local format = string.format

do
	local cache = {}
	function SVector(a, b, c)
		local id = format(pattern, a, b, c)
		local result = cache[id]
		if result then return result end
		cache[id] = Vector(a, b, c)
		return cache[id]
	end
end

do
	local cache = {}
	function SAngle(a, b, c)
		local id = format(pattern, a, b, c)
		local result = cache[id]
		if result then return result end
		cache[id] = Angle(a, b, c)
		return cache[id]
	end
end
