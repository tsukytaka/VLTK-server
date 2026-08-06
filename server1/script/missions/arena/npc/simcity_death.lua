function OnDeath(nNpcIndex)
	local nMapId = SubWorldIdx2ID(SubWorld)
	if DungeonList and DungeonList[nMapId] then
		DungeonList[nMapId]:SimCityNpcDeath(nNpcIndex)
	end
end
