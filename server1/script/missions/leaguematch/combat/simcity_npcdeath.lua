Include("\\script\\global\\nobitaxd\\vdk\\simcity\\components\\liendau.lua")

function OnDeath(nNpcIndex)
    local pidx = GetNpcParam and GetNpcParam(nNpcIndex, 1) or 0
    WriteLog("SIMCITY_WLLS\tNativeDeathScript\tNpc:"..tostring(nNpcIndex)
        .."\tPlayer:"..tostring(pidx))
    if SimCityLeague and SimCityLeague.OnNativeBotDeath then
        SimCityLeague:OnNativeBotDeath(nNpcIndex)
    end
end
