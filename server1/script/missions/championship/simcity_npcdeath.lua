Include("\\script\\missions\\championship\\simcity_bot.lua")

function OnDeath(nNpcIndex)
	SimCityChampionship:NpcDeath(nNpcIndex)
end
