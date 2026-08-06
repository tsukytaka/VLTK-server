-- SimCity opponent adapter for the faction championship tryout.
-- The bot replaces the old free win only when one real player remains.

Include("\\script\\lib\\timerlist.lua")
Include("\\script\\missions\\championship\\head.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\webconfig.lua")

SimCityChampionship = SimCityChampionship or {
	matchesByPlayer = {},
	matchesByNpc = {},
}

SimCityChampionshipTimer = SimCityChampionshipTimer or {}

function SimCityChampionshipTimer:OnTime(szPlayerName)
	SimCityChampionship:Finish(szPlayerName, 0)
	return 0
end

function SimCityChampionship:GetNpcType(nMatchMapId)
	local nFaction = floor((nMatchMapId - 397) / 2) + 1
	if nFaction < 1 or nFaction > 10 then
		nFaction = random(1, 10)
	end
	local tbSeries = {0, 0, 1, 1, 2, 2, 3, 3, 4, 4}
	return 1785 + nFaction, tbSeries[nFaction]
end

function SimCityChampionship:Start(nPlayerIndex, nMatchMapId, nPosX, nPosY, nTryoutMapId)
	if SIMCITY_CHAMPIONSHIP_ENABLED ~= 1 then
		return 0
	end
	if not nPlayerIndex or nPlayerIndex <= 0 then
		return 0
	end

	local nOldPlayer = PlayerIndex
	PlayerIndex = nPlayerIndex
	local szPlayerName = GetName()
	if not szPlayerName or szPlayerName == "" then
		PlayerIndex = nOldPlayer
		return 0
	end

	NewWorld(nMatchMapId, nPosX, nPosY)
	local nMapIndex = SubWorldID2Idx(nMatchMapId)
	local nNpcId, nSeries = self:GetNpcType(nMatchMapId)
	local nLevel = tonumber(SIMCITY_CHAMPIONSHIP_BOT_LEVEL) or 95
	local nNpcIndex = AddNpcEx(
		nNpcId,
		nLevel,
		nSeries,
		nMapIndex,
		(nPosX + 3) * 32,
		nPosY * 32,
		1,
		"SimCity Ti Vo",
		1
	)

	if not nNpcIndex or nNpcIndex <= 0 then
		NewWorld(nTryoutMapId, CP_MAPPOS_IN[1], CP_MAPPOS_IN[2])
		PlayerIndex = nOldPlayer
		return 0
	end

	local nHP = tonumber(SIMCITY_CHAMPIONSHIP_BOT_HP) or 120000
	if nHP < 1000 then
		nHP = 1000
	end
	SetNpcCurCamp(nNpcIndex, 3)
	SetNpcActiveRegion(nNpcIndex, 1)
	SetNpcKind(nNpcIndex, 0)
	SetNpcParam(nNpcIndex, 1, nPlayerIndex)
	SetNpcParam(nNpcIndex, 4, 1)
	SetNpcScript(nNpcIndex, "\\script\\missions\\championship\\simcity_npcdeath.lua")
	SetNpcDeathScript(nNpcIndex, "\\script\\missions\\championship\\simcity_npcdeath.lua")
	if NPCINFO_SetNpcCurrentMaxLife then
		NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, nHP)
	end
	if NPCINFO_SetNpcCurrentLife then
		NPCINFO_SetNpcCurrentLife(nNpcIndex, nHP)
	end
	if SetNpcAtkSpeed then
		SetNpcAtkSpeed(nNpcIndex, SIMBOT_ATTACK_SPEED or 250)
	end

	local tbMatch = {
		playerName = szPlayerName,
		npcIndex = nNpcIndex,
		tryoutMapId = nTryoutMapId,
		matchMapId = nMatchMapId,
	}
	self.matchesByPlayer[szPlayerName] = tbMatch
	self.matchesByNpc[nNpcIndex] = szPlayerName
	local nFightSeconds = tonumber(SIMCITY_CHAMPIONSHIP_FIGHT_SECONDS) or 180
	tbMatch.timerId = TimerList:AddTimer(SimCityChampionshipTimer, nFightSeconds * 18, szPlayerName)

	nt_settask(CP_TASKID_ROUND, nt_gettask(CP_TASKID_ROUND) + 1)
	nt_settask(CP_TASKID_ENEMY, 0)
	nt_settask(CP_TASKID_FLAG, 0)
	SetCurCamp(2)
	SetFightState(1)
	SetPKFlag(2)
	SetCreateTeam(0)
	DisabledStall(1)
	SetTaskTemp(200, 1)
	SetLogoutRV(1)
	ForbitTrade(1)
	ForbidChangePK(1)
	SetRevPos(nTryoutMapId, 1)
	DisabledUseTownP(1)
	SetDeathScript("\\script\\missions\\championship\\simcity_playerdeath.lua")
	Msg2Player("Khong du doi thu, ban duoc ghep tran voi cao thu SimCity.")
	Msg2Player("Ha bot de nhan 3 diem. Het gio hai ben se duoc tinh hoa.")
	WriteLog("SimCityChampionship\tStart\tPlayer:"..szPlayerName.."\tNpc:"..nNpcIndex)

	PlayerIndex = nOldPlayer
	return 1
end

function SimCityChampionship:Finish(szPlayerName, nResult)
	local tbMatch = self.matchesByPlayer[szPlayerName]
	if not tbMatch then
		return 0
	end

	self.matchesByPlayer[szPlayerName] = nil
	self.matchesByNpc[tbMatch.npcIndex] = nil
	if tbMatch.timerId then
		TimerList:DelTimer(tbMatch.timerId)
	end

	local nPlayerIndex = SearchPlayer(szPlayerName)
	if nResult ~= 1 and tbMatch.npcIndex and tbMatch.npcIndex > 0 then
		DelNpc(tbMatch.npcIndex)
	end
	if not nPlayerIndex or nPlayerIndex <= 0 then
		return 0
	end

	local nOldPlayer = PlayerIndex
	PlayerIndex = nPlayerIndex
	if nResult == 1 then
		nt_settask(CP_TASKID_WIN, nt_gettask(CP_TASKID_WIN) + 1)
		nt_settask(CP_TASKID_POINT, nt_gettask(CP_TASKID_POINT) + 3)
		Ladder_NewLadder(checkmap(2), GetName(), nt_gettask(CP_TASKID_POINT), 1)
		AddAword(GetLevel(), 20, 2)
		Msg2Player("Ban da ha cao thu SimCity va nhan 3 diem.")
	elseif nResult == -1 then
		nt_settask(CP_TASKID_LOSE, nt_gettask(CP_TASKID_LOSE) + 1)
		AddAword(GetLevel(), 5, 0)
		Msg2Player("Ban da thua cao thu SimCity.")
	else
		nt_settask(CP_TASKID_TIE, nt_gettask(CP_TASKID_TIE) + 1)
		nt_settask(CP_TASKID_POINT, nt_gettask(CP_TASKID_POINT) + 1)
		Ladder_NewLadder(checkmap(2), GetName(), nt_gettask(CP_TASKID_POINT), 1)
		AddAword(GetLevel(), 10, 0)
		Msg2Player("Tran dau voi SimCity het gio, ban nhan 1 diem hoa.")
	end

	nt_settask(CP_TASKID_FLAG, 1)
	nt_settask(CP_TASKID_ENEMY, 0)
	SetDeathScript("")
	SetLogoutRV(0)
	SetCreateTeam(1)
	DisabledStall(0)
	DisabledUseTownP(0)
	SetTaskTemp(200, 0)
	SetFightState(0)
	SetPunish(1)
	ForbidChangePK(0)
	SetPKFlag(0)
	ForbitTrade(0)
	SetCurCamp(GetCamp())
	RestoreOwnFeature()
	NewWorld(tbMatch.tryoutMapId, CP_MAPPOS_IN[1], CP_MAPPOS_IN[2])
	WriteLog("SimCityChampionship\tFinish\tPlayer:"..szPlayerName.."\tResult:"..nResult)
	PlayerIndex = nOldPlayer
	return 1
end

function SimCityChampionship:NpcDeath(nNpcIndex)
	local szPlayerName = self.matchesByNpc[nNpcIndex]
	if not szPlayerName then
		return 0
	end
	return self:Finish(szPlayerName, 1)
end

function SimCityChampionship:PlayerDeath(szPlayerName)
	return self:Finish(szPlayerName, -1)
end
