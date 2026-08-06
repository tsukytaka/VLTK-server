Include("\\script\\missions\\championship\\simcity_bot.lua")

function OnDeath(Launcher)
	SimCityChampionship:PlayerDeath(GetName())
end
