if glua_ext_loaded then return end

local R = debug.getregistry()
local ENTITY = R.Entity
local WEAPON = R.Weapon
local NPC = R.NPC
local PLAYER = R.Player
local PHYS = R.PhysObj

do
	local THREAD = debug.getmetatable(coroutine.create(function() end))
	local FUNC = debug.getmetatable(function() end)

	do
		local typeMeta = {
			[debug.getmetatable("")] = 'string',
			[debug.getmetatable(0)] = 'number',
			[debug.getmetatable(false)] = 'boolean',
			[FUNC] = 'function',
			[THREAD] = "thread",
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
			[FUNC] = TYPE_FUNCTION,
			[THREAD] = TYPE_THREAD,
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
	local strSub = string.sub
	-- string.GetPathFromFilename = function(path)
		-- local i = #path
		-- ::iter::
		-- local c = strSub( path, i, i )
		-- if ( c == "/" or c == "\\" ) then return strSub( path, 1, i ) end
		-- i = i - 1
		-- if i > 0 then goto iter end
		-- return path
	-- end

-- string.Explode:
        -- sum = 2.867
        -- avg = 0.02867
        -- median = 0.027500000000003
-- string.SplitString:
        -- sum = 0.69100000000003
        -- avg = 0.0069100000000003
        -- median = 0.0059999999999718
	local strLen = string.len
	string.SplitString = function(separator, str)
		local results = {}
		local index, lastPos = 1, 1
		local i, iMax = 1, strLen(str)
		local lastArg

		::iter::
		if strSub(str, i, i) == separator then
			lastArg = strSub(str, lastPos, i - 1)
			-- #lastArg > 0 then
				results[index] = lastArg
				index = index + 1
			-- end
			lastPos = i + 1
		end
		i = i + 1
		if i <= iMax then goto iter end

		lastArg = strSub(str, lastPos)
		if lastArg ~= "" then results[index] = lastArg end

		return results
	end
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

		local _, players = player.Iterator()
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

do
	local inext = ipairs({})
	local EntityCache, EntityLen = nil, 0
	local PlayerCache, PlayerLen = nil, 0

	-- alias player.GetCount but faster
	function player.Count()
		if PlayerCache == nil then
			PlayerCache = player.GetAll()
			PlayerLen = #PlayerCache
		end

		return PlayerLen
	end

	-- alias ents.GetCount but faster
	function ents.Count()
		if EntityCache == nil then
			EntityCache = ents.GetAll()
			EntityLen = #EntityCache
		end

		return EntityLen
	end

	function player.Iterator()
		if PlayerCache == nil then
			PlayerCache = player.GetAll()
			PlayerLen = #PlayerCache
		end

		return inext, PlayerCache, 0
	end

	function ents.Iterator()
		if EntityCache == nil then
			EntityCache = ents.GetAll()
			EntityLen = #EntityCache
		end

		return inext, EntityCache, 0
	end

	function player.All()
		if PlayerCache == nil then
			PlayerCache = player.GetAll()
			PlayerLen = #PlayerCache
		end

		return PlayerLen, PlayerCache
	end

	function ents.All()
		if EntityCache == nil then
			EntityCache = ents.GetAll()
			EntityLen = #EntityCache
		end

		return EntityLen, EntityCache
	end

	local function InvalidateEntityCache(ent)
		if ent:IsPlayer() then PlayerCache, PlayerLen = nil, 0 end
		EntityCache, EntityLen = nil, 0
	end

	hook.Remove( "OnEntityCreated", "player.Iterator" )
	hook.Remove( "EntityRemoved", "player.Iterator" )

	hook.Add( "OnEntityCreated", "ents.Iterator", InvalidateEntityCache )
	hook.Add( "EntityRemoved", "ents.Iterator", InvalidateEntityCache )

	-- example ::
	-- for k, v in player.Iterator() do print(k, v) end

	-- local playerLen, players = player.All()
	-- for i = 1, playerLen do print(i, players[i]) end
end

do
	local FrameNumber = FrameNumber
	local TraceLine = util.TraceLine

	local VECTOR = R.Vector
	local V_Add, V_Mul, V_Set = VECTOR.Add, VECTOR.Mul, VECTOR.Set

	do
		local LastPlayerTrace
		local output = {}
		-- Thanks @GoodOldBrick
		local START_VECTOR, END_VECTOR, DIR_VECTOR = Vector(), Vector(), Vector()
		local trace = { output = output, start = START_VECTOR, endpos = END_VECTOR, filter = NULL }
		local GetAimVector, EyePos = PLAYER.GetAimVector, ENTITY.EyePos

		function PLAYER:GetEyeTrace(distance)
			if (CLIENT) then
				local framenum = FrameNumber()
				if (LastPlayerTrace == framenum) then return output end
				LastPlayerTrace = framenum
			end

			V_Set(START_VECTOR, EyePos(self))
			V_Set(END_VECTOR, START_VECTOR)
			V_Set(DIR_VECTOR, GetAimVector(self))
			V_Mul(DIR_VECTOR, distance or 32768)
			V_Add(END_VECTOR, DIR_VECTOR)

			trace.filter = self
			TraceLine(trace)
			return output
		end
	end

	do
		local LastPlayerAimTrace
		local output = {}
		local START_VECTOR, END_VECTOR, DIR_VECTOR = Vector(), Vector(), Vector()
		local trace = { output = output, start = START_VECTOR, endpos = END_VECTOR, filter = NULL }
		local EyeAngles, Forward, EyePos = ENTITY.EyeAngles, R.Angle.Forward, ENTITY.EyePos

		function PLAYER:GetEyeTraceNoCursor(distance)
			if (CLIENT) then
				local framenum = FrameNumber()
				if (LastPlayerAimTrace == framenum) then return output end
				LastPlayerAimTrace = framenum
			end

			V_Set(START_VECTOR, EyePos(self))
			V_Set(END_VECTOR, START_VECTOR)
			V_Set(DIR_VECTOR, Forward(EyeAngles(self)))
			V_Mul(DIR_VECTOR, distance or 32768)
			V_Add(END_VECTOR, DIR_VECTOR)

			trace.filter = self
			TraceLine(trace)
			return output
		end
	end
end

MAX_PLAYER_BITS = math.ceil( math.log( 1 + game.MaxPlayers() ) / math.log( 2 ) )

do
	local cachergb = {}
	local cachehex = {}

	for i = 0, 255 do
		local c = string.format("%02x", i)
		cachergb[c] = i
		cachehex[i] = c
	end

	util.RGBToHex2 = function(r, g, b)
		return ( cachehex[r] or "ff" ) .. (cachehex[g] or "ff" ) .. ( cachehex[b] or "ff" ) .. "ff"
	end

	util.RGBToHex = function(color)
		return ( cachehex[color.r] or "ff" ) .. (cachehex[color.g] or "ff" ) .. ( cachehex[color.b] or "ff" ) .. "ff"
	end

	util.RGBAToHex = function(color)
		return ( cachehex[color.r] or "ff" ) .. (cachehex[color.g] or "ff" ) .. ( cachehex[color.b] or "ff" ) .. ( cachehex[color.a] or "ff" )
	end

	local sub = string.sub
	util.HexToRGB = function(hex)
		return cachergb[sub(hex,1,2)], cachergb[sub(hex,3,4)], cachergb[sub(hex,5,6)]
	end

	util.HexToRGBA = function(hex)
		return cachergb[sub(hex,1,2)], cachergb[sub(hex,3,4)], cachergb[sub(hex,5,6)], cachergb[sub(hex,7,8)]
	end

	-- :: Example ::
	-- TOOL.ClientConVar[ "hex" ] = "ffffffff"
	-- ply:ConCommand( "remover_hex " .. util.RGBAToHex( color_white ) )
	-- local hex = LocalPlayer():GetInfo("remover_hex")
	-- if not hex then hex = "ffffffff" end
	-- local r,g,b,a = util.HexToRGBA(hex)
end

glua_ext_loaded = true