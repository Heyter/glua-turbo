--[[

	Title: Random Patches
	Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2806290767
	GitHub: https://github.com/Pika-Software/gmod_random_patches

--]]

local addonName = 'Random Patches'
-- local version = '5.0.0'
local NULL = NULL

local ipairs = ipairs
local table = table
local math = math
local hook = hook
local math_random = math.random
local istable = istable
local rawset = rawset

function math.Clamp( num, min, max )
	if num < min then return min end
	if num > max then return max end
	return num
end

function table.Shuffle( tbl )
	local len = #tbl
	for i = len, 1, -1 do
		local rand = math_random( len )
		tbl[ i ], tbl[ rand ] = tbl[ rand ], tbl[ i ]
	end

	return tbl
end

function table.Random( tbl, issequential )
	local keys = issequential and tbl or table.GetKeys( tbl )
	local rand = keys[ math_random( 1, #keys ) ]
	return tbl[ rand ], rand
end

if SERVER then
	local R = debug.getregistry()
	local ENTITY = R.Entity

	-- Normal Deploy Speed
	RunConsoleCommand( 'sv_defaultdeployspeed', '1' )

	-- Missing Stuff
	-- From metastruct code
	CreateConVar( 'room_type', '0' )
	scripted_ents.Register( {
		['Base'] = 'base_point',
		['Type'] = 'point'
	}, 'info_ladder' )

	-- Little optimization idea by Billy (used in voicebox)
	-- "for something that really shouldn't be O(n)"
	-- https://i.imgur.com/yPtoNvO.png
	-- https://i.imgur.com/a0lmB9m.png
	do
		local meta = FindMetaTable( 'Player' )
		if meta.UserID and debug.getinfo( meta.UserID ).short_src == '[C]' then
			CUserID = CUserID or meta.UserID

			function meta:UserID()
				return self.__UserID or CUserID( self )
			end

			local function CacheUserID( ply ) ply.__UserID = CUserID( ply ) end
			hook.Add( 'PlayerInitialSpawn', addonName .. ' - CacheUserID', CacheUserID, HOOK_MONITOR_HIGH )
			hook.Add( 'PlayerAuthed', addonName .. ' - CacheUserID', CacheUserID, HOOK_MONITOR_HIGH )
		end
	end

	local CEntityGetInternalVariable = ENTITY.GetInternalVariable
	local CEntityGetClass = ENTITY.GetClass

	-- Area portals fix
	do

		local mapIsCleaning = false
		hook.Add( 'PreCleanupMap', addonName .. ' - Area Portal Fix', function() mapIsCleaning = true end )
		hook.Add( 'PostCleanupMap', addonName .. ' - Area Portal Fix', function() mapIsCleaning = false end )

		local doorClasses = {
			['func_door_rotating'] = true,
			['prop_door_rotating'] = true,
			['func_movelinear'] = true,
			['func_door'] = true
		}

		local ents_FindByClass = ents.FindByClass
		hook.Add( 'EntityRemoved', addonName .. ' - Area Portal Fix', function( ent )
			if (mapIsCleaning) then return end
			if ent and ent:IsValid() and doorClasses[ CEntityGetClass(ent) ] then
				local name = ent:GetName()
				if (name ~= '') then
					local portals = ents_FindByClass( 'func_areaportal' )
					local portal = NULL

					for i = 1, #portals do
						portal = portals[i]

						if portal and CEntityGetInternalVariable(portal, 'target' ) == name then
							portal:SetSaveValue( 'target', '' )
							portal:Fire( 'open' )
						end
					end
				end
			end
		end )

	end

	-- Pod network fix by Kefta (code_gs#4197)
	-- Literally garrysmod-issues #2452
	do

		local EFL_NO_THINK_FUNCTION = EFL_NO_THINK_FUNCTION
		local podName = "prop_vehicle_prisoner_pod"
		local CEntityAddEFlags = ENTITY.AddEFlags

		-- Fixes for prop_vehicle_prisoner_pod, worldspawn (and other not Valid but not NULL entities) damage taking (bullets only)
		-- Explosive damage only works if is located in front of prop_vehicle_prisoner_pod (wtf?)
		hook.Add( 'EntityTakeDamage', addonName .. ' - PrisonerFix', function( ent, dmg )
			if !ent or !ent:IsValid() or ent:IsNPC() then return end
			if CEntityGetClass(ent) ~= podName or ent.AcceptDamageForce then return end

			ent:TakePhysicsDamage( dmg )
		end )

		hook.Add( 'OnEntityCreated', addonName .. ' - Pod Fix', function( veh )
			if (CEntityGetClass(veh) == podName) then
				CEntityAddEFlags(veh, EFL_NO_THINK_FUNCTION )
			end
		end )

		hook.Add( 'PlayerEnteredVehicle', addonName .. ' - Pod Fix', function( _, veh )
			if (CEntityGetClass(veh) == podName) then
				veh:RemoveEFlags( EFL_NO_THINK_FUNCTION )
			end
		end )

		hook.Add( 'PlayerLeaveVehicle', addonName .. ' - Pod Fix', function( _, veh )
			if CEntityGetClass(veh) != podName then return end
			hook.Add('Think', veh, function( self )
				hook.Remove( "Think", self )

				if CEntityGetInternalVariable(self, "m_bEnterAnimOn" ) then return end
				if CEntityGetInternalVariable(self, "m_bExitAnimOn" ) then return end
				CEntityAddEFlags(self, EFL_NO_THINK_FUNCTION )
			end)
		end )
	end

	-- Fix for https://github.com/Facepunch/garrysmod-issues/issues/2447
	-- https://github.com/SuperiorServers/dash/blob/master/lua/dash/extensions/player.lua#L44-L57
	do
		local CEntitySetPos = ENTITY.SetPos
		local positions = {}

		FindMetaTable('Player').SetPos = function(ply, pos)
			if isvector(pos) then
				positions[ply] = pos
			end
		end

		hook.Add('FinishMove', addonName .. ' - SetPos Fix', function(ply)
			local pos = positions[ply]
			if not pos then return end

			CEntitySetPos(ply, pos)
			positions[ply] = nil

			return true
		end)

		hook.Add("PlayerDisconnected", addonName .. ' - SetPos Fix', function(ply)
			positions[ply] = nil
		end)
	end
end

-- Trying to start a new lag compensation session while one is already active!
do
	local playerMeta = FindMetaTable("Player")
	CPlayerLagC = CPlayerLagC or playerMeta.LagCompensation
	function playerMeta:LagCompensation(bool)
		if (bool and self.isLagCompensation) then
			return
		end

		self.isLagCompensation = bool
		CPlayerLagC(self, bool)
	end
end

if (CLIENT) then
	-- https://github.com/Facepunch/garrysmod-issues/issues/3637
	do
		game.oldCleanUpMap = game.oldCleanUpMap or game.CleanUpMap
		local cleanUp = game.oldCleanUpMap
		local ents = {"env_fire", "entityflame", "_firesmoke"}

		function game.CleanUpMap(dontSendToClients, extraFilters)
			if (istable(extraFilters)) then
				local len = #extraFilters
				rawset(extraFilters, len + 1, "env_fire")
				rawset(extraFilters, len + 2, "entityflame")
				rawset(extraFilters, len + 3, "_firesmoke")
			else
				return cleanUp(dontSendToClients, ents)
			end

			return cleanUp(dontSendToClients, extraFilters)
		end
	end

	-- https://github.com/Facepunch/garrysmod-issues/issues/1091
	do
		cam.oldStartOrthoView = cam.oldStartOrthoView or cam.StartOrthoView
		local startOrtho = cam.oldStartOrthoView
		local camStack = 0

		function cam.StartOrthoView(a, b, c, d)
			camStack = camStack + 1
			startOrtho(a, b, c, d)
		end

		cam.oldEndOrthoView = cam.oldEndOrthoView or cam.EndOrthoView
		local endOrtho = cam.oldEndOrthoView

		function cam.EndOrthoView()
			if (camStack == 0) then
				return
			end

			camStack = math.max(0, camStack - 1)
			endOrtho()
		end
	end

	-- Speeding up LocalPlayer
	do
		local ply
		local localPlayer = LocalPlayer

		function LocalPlayer()
			ply = localPlayer()

			if ply and ply:IsValid() then
				_G.LocalPlayer = function() return ply end
			end

			return ply
		end
	end

	-- wtf: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/client/render.lua#L111C2-L111C2
	local camStart = cam.Start

	do
		local data = { type = '2D' }
		function cam.Start2D() return camStart(data) end
	end

	do
		local tab = { type = '3D' }

		function cam.Start3D( pos, ang, fov, x, y, w, h, znear, zfar )
			tab.origin = pos
			tab.angles = ang

			if ( fov != nil ) then tab.fov = fov end

			if ( x != nil && y != nil && w != nil && h != nil ) then
				tab.x = x
				tab.y = y
				tab.w = w
				tab.h = h
				tab.aspect = ( w / h )
			end

			if (znear != nil && zfar != nil) then
				tab.znear = znear
				tab.zfar = zfar
			end

			return camStart(tab)
		end
	end
end