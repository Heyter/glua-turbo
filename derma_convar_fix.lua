
local cacheKeys, cache, len = {}, {}, 0
local name
timer.Create("derma_convar_fix", 0.5, 0,  function()
	if len == 0 then return end
	for i = 1, len do
		name = cache[i]
		RunConsoleCommand(name, cacheKeys[name])
		cacheKeys[name] = nil
		cache[i] = nil
	end
	len = 0
end)

function Derma_SetCvar_Safe(name, value)
	if not cacheKeys[name] then
		cacheKeys[name] = tostring(value)
		len = len + 1
		cache[len] = name
	else
		cacheKeys[name] = tostring(value)
	end
end

function Derma_Install_Convar_Functions( PANEL )
	function PANEL:SetConVar( strConVar )
		self.m_strConVar = strConVar
	end

	function PANEL:ConVarChanged( strNewValue )
		local cvar = self.m_strConVar
		if ( not cvar or string.len(cvar) < 2 ) then return end
		Derma_SetCvar_Safe(cvar, strNewValue)
	end

	-- Todo: Think only every 0.1 seconds?
	function PANEL:ConVarStringThink()
		local cvar = self.m_strConVar
		if ( not cvar or string.len(cvar) < 2 ) then return end

		local strValue = GetConVarString(cvar)
		if ( self.m_strConVarValue == strValue ) then return end

		self.m_strConVarValue = strValue
		self:SetValue( strValue )
	end

	function PANEL:ConVarNumberThink()
		local cvar = self.m_strConVar
		if ( not cvar or string.len(cvar) < 2 ) then return end
		local numValue = GetConVarNumber( cvar )

		-- In case the convar is a "nan"
		if ( numValue != numValue ) then return end
		if ( self.m_strConVarValue == numValue ) then return end

		self.m_strConVarValue = numValue
		self:SetValue( numValue )
	end
end