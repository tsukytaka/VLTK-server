Include("\\script\\lib\\objbuffer_head.lua")
Include("\\script\\missions\\basemission\\dungeon.lua")
Include("\\script\\global\\autoexec_head.lua")
Include("\\script\\missions\\arena\\player.lua")
Include("\\script\\missions\\basemission\\lib.lua")
Include("\\script\\lib\\file.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\webconfig.lua")

Include("\\script\\item\\forbiditem.lua")

IncludeLib("SETTING")
local tbRule = Dungeon:new_type("arena")

tbRule.TEMPLATE_MAP_ID = 975

local CAMP_A = 1
local CAMP_B = 2

local FIGHT_TIME = tonumber(SIMCITY_DUEL_FIGHT_SECONDS) or 5*60
local READY_TIME = tonumber(SIMCITY_DUEL_READY_SECONDS) or 60
local READY_COUNT_DOWN = 5
local FIGHT_COUNT_DOWN = 5

local tbSimCityNpcIds = {1786,1787,1788,1789,1790,1791,1792,1793,1794,1795}
local tbSimCitySkills = {
	[1786] = {325,20},
	[1787] = {318,20},
	[1788] = {353,20},
	[1789] = {302,20},
	[1790] = {328,20},
	[1791] = {336,20},
	[1792] = {715,20},
	[1793] = {357,20},
	[1794] = {368,20},
	[1795] = {717,20},
}
local tbSimCityVisual = {
	[1786] = {2,-1},
	[1787] = {1,-1},
	[1788] = {4,-1},
	[1789] = {3,-1},
	[1790] = {5,-2},
	[1791] = {6,-2},
	[1792] = {7,-1},
	[1793] = {8,-1},
	[1794] = {9,-1},
	[1795] = {10,-1},
}
local tbSimCityHelm = {2,5,8,11,14,17,20}
local tbSimCityArmorMale = {2,8,11,14,20,23,29,32,35,41}
local tbSimCityArmorFemale = {8,14,19,20,29,35,40,41}
local tbSimCityWeapon = {20,23,24,26,28,30}

tbArenaSimBotMember = {}

function tbArenaSimBotMember:new(nCamp, nRank)
	local tb = {}
	for k, v in self do
		tb[k] = v
	end
	tb.szName = "SimCity 1v1"
	tb.nRank = nRank
	tb.nCamp = nCamp
	tb.nReceiveDamage = 0
	tb.bReady = 1
	tb.bSimCity = 1
	return tb
end

function tbArenaSimBotMember:SetResult(nOpponentRank, szResult)
end

function tbArenaSimBotMember:GoToLastPos()
end

local tbNpcList = 
{
	{szName = "R­¬ng chøa ®å", nPosX = 50112, nPosY = 102848, nNpcId = 625, szScriptPath = "\\script\\battles\\openbox.lua"},
	{szName = "Chñ d­îc ®iÕm", nPosX = 50496, nPosY = 102528, nNpcId = 203, szScriptPath = "\\script\\missions\\arena\\npc\\yaodian.lua"}

}
tbRule.tbForbitItemType = 
{
	"CALLNPC",
	"TRANSFER",
}

function tbRule:SetForbitItem()
	local szMapType = self.szDungeonType
	set_MapType(self.TEMPLATE_MAP_ID, szMapType)
		
	for i=1, getn(self.tbForbitItemType) do		
		tb_MapType[szMapType] = tb_MapType[szMapType] or {}
		tinsert(tb_MapType[szMapType], self.tbForbitItemType[i])
	end
end


function tbRule:_init(pBattle)
	self.tbMemberMap = {}
	self.tbFreeCamp = {}
	self.tbCamp = {}
	tinsert(self.tbFreeCamp, %CAMP_A)
	tinsert(self.tbFreeCamp, %CAMP_B)
	
	for i=1, getn(%tbNpcList) do
		ClearMapNpcWithName(self.nMapId, %tbNpcList[i].szName)
		basemission_CallNpc(%tbNpcList[i], self.nMapId)
	end
	
	self.nState = "free"
	return 1
end



--Õý³£Ö´ÐÐ²»»áµ½ÕâÀï
function tbRule:KickOut()
	NewWorld(20,3546,6226)
end

function tbRule:GetFreeCamp()
	local nCamp = self.tbFreeCamp[1]
	if nCamp then
		tremove(self.tbFreeCamp, 1)
		return nCamp
	end
end

function tbRule:AddFreeCamp(nCamp)
	if nCamp then
		tinsert(self.tbFreeCamp, nCamp)
	end
end

function tbRule:GetFreeCampCount()
	return getn(self.tbFreeCamp)
end

function tbRule:OnEnterMap()
	if self.nState ~= "free" then
		self:KickOut()
		return
	end
	local nCamp = self:GetFreeCamp()
	
	if not nCamp then
		self:KickOut()
		return
	end
	local szName = GetName()
	
	if self.bSimCityMatch ~= 1 then
		DynamicExecute("\\script\\missions\\arena\\protocol.lua", "on_player_enter_map", szName, self.nMapId)
	end
	local pMember = tbMember:new(nCamp)
	self.tbMemberMap[szName] = pMember
	self.tbCamp[nCamp] = pMember
	SetLogoutRV(1)
	SetFightState(0)
	if self.bSimCityMatch == 1 then
		SetTmpCamp(2)
		SetCurCamp(2)
	else
		SetTmpCamp(nCamp)
	end
	SetPunish(0)
	ForbidEnmity(1)
	SetDeathType(-1)
	if self.bSimCityMatch == 1 then
		SetPKFlag(2)
	else
		SetPKFlag(1)
	end
	DisabledStall(1)
	LeaveTeam()
	SetCreateTeam(0)
	ForbidChangePK(1)
	ForbidEnmity(1)
end

function tbRule:StartSimCityMatch(nPlayerIndex)
	if nPlayerIndex <= 0 then
		return
	end
	self.bSimCityMatch = 1
	local szName = CallPlayerFunction(nPlayerIndex, GetName)
	local nLastMapId, nX, nY = CallPlayerFunction(nPlayerIndex, GetWorldPos)
	local nLastFightState = CallPlayerFunction(nPlayerIndex, GetFightState)
	self.tbSimCityLastState = {
		tbPos = {nLastMapId, nX, nY},
		nFightState = nLastFightState,
	}
	-- TrËn víi SIM dïng ngay khu chiÕn ®Êu ®Ó Player vµ bot nh×n thÊy nhau
	-- tõ lóc vµo map; khu chê gèc n»m c¸ch ®ã kho¶ng 60 «.
	CallPlayerFunction(nPlayerIndex, NewWorld, self.nMapId, self:GetBattlePos())
	self:AddTimer(18, self.SetupSimCityBot, {self, szName, 0})
end

function tbRule:SetupSimCityBot(szName, nRetry)
	local pMember = self.tbMemberMap[szName]
	if not pMember then
		self.nSimCitySetupRetry = (self.nSimCitySetupRetry or 0) + 1
		if self.nSimCitySetupRetry < 10 then
			return 18
		end
		self:close()
		return 0
	end
	pMember:SyncLastState(self.tbSimCityLastState)
	local nCamp = self:GetFreeCamp()
	if not nCamp then
		self:close()
		return 0
	end
	local nX, nY = self:GetBattlePos()
	local nNpcId = %tbSimCityNpcIds[random(1, getn(%tbSimCityNpcIds))]
	local nLevel = tonumber(SIMCITY_DUEL_BOT_LEVEL) or 95
	local nNpcIndex = AddNpcEx(nNpcId, nLevel, random(0,4), SubWorldID2Idx(self.nMapId), nX*32, nY*32, 1, "SimCity 1v1", 1)
	if nNpcIndex <= 0 then
		self:AddFreeCamp(nCamp)
		Msg2Map(self.nMapId, "Khong tao duoc doi thu SimCity.")
		self:close()
		return 0
	end
	local nHP = tonumber(SIMCITY_DUEL_BOT_HP) or 120000
	if nHP < 1000 then
		nHP = 1000
	end
	NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, nHP)
	NPCINFO_SetNpcCurrentLife(nNpcIndex, nHP)
	if SetNpcAtkSpeed then
		SetNpcAtkSpeed(nNpcIndex, SIMBOT_ATTACK_SPEED or 250)
	end
	local tbVisual = %tbSimCityVisual[nNpcId] or {2,-1}
	local tbArmor = %tbSimCityArmorMale
	if tbVisual[2] == -2 then
		tbArmor = %tbSimCityArmorFemale
	end
	if ChangeNpcFeature then
		ChangeNpcFeature(
			nNpcIndex, 0, 0, tbVisual[2],
			%tbSimCityHelm[random(1, getn(%tbSimCityHelm))],
			tbArmor[random(1, getn(tbArmor))],
			%tbSimCityWeapon[random(1, getn(%tbSimCityWeapon))],
			0
		)
	end
	if SetNpcRideHorse then
		SetNpcRideHorse(nNpcIndex, 0)
	end
	if SetBotFaction then
		SetBotFaction(nNpcIndex, tbVisual[1])
	end
	local nPlayerIndex = SearchPlayer(szName)
	if SetNpcParam then
		SetNpcParam(nNpcIndex, 1, nPlayerIndex)
		SetNpcParam(nNpcIndex, 4, 1)
	end
	SetNpcCurCamp(nNpcIndex, 4)
	SetNpcKind(nNpcIndex, 3)
	SetNpcDeathScript(nNpcIndex, "\\script\\missions\\arena\\npc\\simcity_death.lua")
	local pBot = tbArenaSimBotMember:new(nCamp, max(pMember.nRank, 1200))
	pBot.nNpcIndex = nNpcIndex
	pBot.nMaxLife = nHP
	pBot.tbSkill = %tbSimCitySkills[nNpcId] or {325,20}
	self.tbMemberMap[pBot.szName] = pBot
	self.tbCamp[nCamp] = pBot
	if nPlayerIndex > 0 then
		CallPlayerFunction(nPlayerIndex, Msg2Player, "§èi thñ SIM ®· vµo l«i ®µi. Xin chê hÕt thêi gian chuÈn bÞ.")
	end
	self:StartBattle()
	return 0
end

function tbRule:OnLeaveMap()
	ForbidEnmity(0)
	SetTmpCamp(0)
	SetCurCamp(GetCamp())
	SetPunish(1)
	SetDeathType(0)
	ForbitStamina(0)
	SetPKFlag(0)
	DisabledStall(0)
	SetCreateTeam(1)
	ForbidChangePK(0)
	ForbidEnmity(0)
	local szName = GetName()
	if self.bSimCityMatch ~= 1 then
		DynamicExecute("\\script\\missions\\arena\\protocol.lua", "on_player_leave_map", szName, self.nMapId)
	end
	local pMember = self.tbMemberMap[szName]
	if pMember then
		SetFightState(pMember.nLastFightState)
		self:AddFreeCamp(pMember.nCamp)
		if self.nState ~= "free" and self.nState ~= "result" then
			pMember.bDeath = 1
			self:ProcResult()
		end
		self.tbMemberMap[szName] = nil
		self.tbCamp[pMember.nCamp]=nil
	end
	
end

function tbRule:SetLastState(szName, tbLastState)
	local pMember = self.tbMemberMap[szName]
	if pMember then
		pMember:SyncLastState(tbLastState)
	end
	
	if self:GetFreeCampCount() == 0 then
		for szName, pMember in self.tbMemberMap do 
			if pMember and pMember.bReady ~= 1 then
				 return 
			end
		end
		self:StartBattle()
	end
end

function tbRule:ProcResult()
	if self.nState == "result" then
		return
	end
	self.nState = "result"
	for szName, pMember in self.tbMemberMap do
		if pMember then
			if pMember.bSimCity == 1 then
				if pMember.nNpcIndex and pMember.nNpcIndex > 0 then
					local nLife = NPCINFO_GetNpcCurrentLife(pMember.nNpcIndex) or 0
					pMember.nReceiveDamage = pMember.nMaxLife - nLife
				end
			else
				local nPlayerIndex = SearchPlayer(szName)
				if nPlayerIndex > 0 then
				CallPlayerFunction(nPlayerIndex, SetFightState, 0)
				pMember.nReceiveDamage = CallPlayerFunction(nPlayerIndex, ST_GetDamageCounter)
				CallPlayerFunction(nPlayerIndex, ST_StopDamageCounter)
				end
			end
		end
	end
	local pMemberA = self.tbCamp[%CAMP_A]
	local pMemberB = self.tbCamp[%CAMP_B]
	if not pMemberA or not pMemberB then
		return
	end
	
	if pMemberA.bDeath == 1 or pMemberB.bDeath == 1 then
		if pMemberA.bDeath == pMemberB.bDeath then
			self:SetResult(pMemberA, pMemberB, "DRAW")
			Msg2Map(self.nMapId, "Hai bªn ®Òu tö trËn.")			
		elseif pMemberA.bDeath == 1 then
			self:SetResult(pMemberA, pMemberB, "LOSE")
			Msg2Map(self.nMapId, format("%s ®¸nh b¹i %s", pMemberB.szName, pMemberA.szName))			
		else
			self:SetResult(pMemberA, pMemberB, "VICTORY")
			Msg2Map(self.nMapId, format("%s ®¸nh b¹i %s", pMemberA.szName, pMemberB.szName))
		end
	else
		Msg2Map(self.nMapId, format("%s lùc s¸t th­¬ng lµ %d", pMemberA.szName, pMemberB.nReceiveDamage))
		Msg2Map(self.nMapId, format("%s lùc s¸t th­¬ng lµ %d", pMemberB.szName, pMemberA.nReceiveDamage))
		
		if pMemberA.nReceiveDamage == pMemberB.nReceiveDamage then
			self:SetResult(pMemberA, pMemberB, "DRAW")
			Msg2Map(self.nMapId, "ThÕ lùc hai bªn bÊt ph©n th¾ng b¹i")
		elseif pMemberA.nReceiveDamage > pMemberB.nReceiveDamage then
			self:SetResult(pMemberA, pMemberB, "LOSE")
			Msg2Map(self.nMapId, format("%s th¾ng lîi", pMemberB.szName))
		else
			self:SetResult(pMemberA, pMemberB, "VICTORY")
			Msg2Map(self.nMapId, format("%s th¾ng lîi", pMemberA.szName))
		end
	end
	self:close()
	
end

function tbRule:SetResult(pMemberA, pMemberB, szResult)
	if szResult == "DRAW" then
		pMemberA:SetResult(pMemberB.nRank, "DRAW")
		pMemberB:SetResult(pMemberA.nRank, "DRAW")
		WriteLog(format("[%s]\t%s\t%s\tDRAW", self.szDungeonType, pMemberA.szName, pMemberB.szName ))
	elseif szResult == "VICTORY" then
		pMemberA:SetResult(pMemberB.nRank, "VICTORY")
		pMemberB:SetResult(pMemberA.nRank, "LOSE")
		WriteLog(format("[%s]\t%s\t%s\tVICTORY", self.szDungeonType, pMemberA.szName, pMemberB.szName ))
	elseif szResult == "LOSE" then
		pMemberA:SetResult(pMemberB.nRank, "LOSE")
		pMemberB:SetResult(pMemberA.nRank, "VICTORY")
		WriteLog(format("[%s]\t%s\t%s\tVICTORY", self.szDungeonType, pMemberB.szName, pMemberA.szName ))
	end
end

function tbRule:OnClose()
	for szName, pMember in self.tbMemberMap do
		if pMember then
			if pMember.bSimCity == 1 then
				if pMember.nNpcIndex and pMember.nNpcIndex > 0 then
					DelNpc(pMember.nNpcIndex)
					pMember.nNpcIndex = nil
				end
			else
				pMember:GoToLastPos()
			end
		end
	end
end

function tbRule:SimCityNpcDeath(nNpcIndex)
	if self.nState == "result" then
		return
	end
	for szName, pMember in self.tbMemberMap do
		if pMember and pMember.bSimCity == 1 and pMember.nNpcIndex == nNpcIndex then
			pMember.bDeath = 1
			pMember.nReceiveDamage = pMember.nMaxLife
			pMember.nNpcIndex = nil
			self:ProcResult()
			return
		end
	end
end


function tbRule:GetReadyPos()
	local nX32, nY32 = GetRandomAData("\\settings\\missions\\arena\\readypos.txt")
	
	return nX32 / 32, nY32 / 32
end

function tbRule:GetBattlePos()
	local nX32, nY32 = GetRandomAData("\\settings\\missions\\arena\\battlepos.txt")
	return nX32 / 32, nY32 / 32
end

function tbRule:StartBattle()
	self.nState = "ready"
	
	if self.bSimCityMatch ~= 1 then
		DynamicExecute("\\script\\missions\\arena\\protocol.lua", "on_begin_battle", self.nMapId, self.tbMemberMap)
	end
	Msg2Map(self.nMapId, format("Sau %d gi©y chÝnh thøc b¾t ®Çu", %READY_TIME))
	self:AddTimer((%READY_TIME - %READY_COUNT_DOWN)* 18, self.OnTime, {self})
end

function tbRule:ReadyFight()
	for szName, pMember in self.tbMemberMap do
		if pMember then
			if pMember.bSimCity ~= 1 then
				local nPlayerIndex = SearchPlayer(szName)
				if nPlayerIndex > 0 then
				local nX, nY = self:GetBattlePos()
				CallPlayerFunction(nPlayerIndex, SetPos, nX, nY)
				end
			end
		end
	end
end



function tbRule:StartFight()
	Msg2Map(self.nMapId, "Ph©n tranh ")
	for szName, pMember in self.tbMemberMap do
		if pMember then
			if pMember.bSimCity == 1 then
				if pMember.nNpcIndex and pMember.nNpcIndex > 0 then
					SetNpcKind(pMember.nNpcIndex, 0)
					local nBotCamp = pMember.nCamp
					if self.bSimCityMatch == 1 then
						nBotCamp = 3
					end
					SetNpcCurCamp(pMember.nNpcIndex, nBotCamp)
					if SetTmpCamp then
						SetTmpCamp(nBotCamp, pMember.nNpcIndex)
					end
					SetNpcActiveRegion(pMember.nNpcIndex, 1)
					if SetNpcPeace then
						SetNpcPeace(pMember.nNpcIndex, 0)
					end
					if SetNpcCombat then
						SetNpcCombat(pMember.nNpcIndex, 1, 0)
					end
				end
			else
				local nPlayerIndex = SearchPlayer(szName)
				if nPlayerIndex > 0 then
					local nX, nY = self:GetBattlePos()
					if self.bSimCityMatch == 1 then
						CallPlayerFunction(nPlayerIndex, SetTmpCamp, 2)
						CallPlayerFunction(nPlayerIndex, SetCurCamp, 2)
						CallPlayerFunction(nPlayerIndex, SetPKFlag, 2)
					end
					CallPlayerFunction(nPlayerIndex, SetFightState, 1)
				CallPlayerFunction(nPlayerIndex, ForbitStamina, 1)
				CallPlayerFunction(nPlayerIndex, ST_StartDamageCounter)
				end
			end
		end
	end
	if self.bSimCityMatch == 1 then
		self:AddTimer(1, self.SimCityFightTick, {self})
	end
end

function tbRule:SimCityFightTick()
	if self.nState ~= "fight" then
		return 0
	end
	local pBot = nil
	local nPlayerIndex = 0
	for szName, pMember in self.tbMemberMap do
		if pMember then
			if pMember.bSimCity == 1 then
				pBot = pMember
			else
				nPlayerIndex = SearchPlayer(szName)
			end
		end
	end
	if not pBot or not pBot.nNpcIndex or pBot.nNpcIndex <= 0 or nPlayerIndex <= 0 then
		return 18
	end
	local nTargetNpc = PIdx2NpcIdx(nPlayerIndex)
	if not nTargetNpc or nTargetNpc <= 0 then
		return 18
	end
	if SetNpcCombat then
		SetNpcCombat(pBot.nNpcIndex, 1, 0)
	end
	SetNpcCurCamp(pBot.nNpcIndex, 3)
	if SetTmpCamp then
		SetTmpCamp(3, pBot.nNpcIndex)
	end
	if SetNpcPeace then
		SetNpcPeace(pBot.nNpcIndex, 0)
	end
	CallPlayerFunction(nPlayerIndex, SetTmpCamp, 2)
	CallPlayerFunction(nPlayerIndex, SetCurCamp, 2)
	CallPlayerFunction(nPlayerIndex, SetPKFlag, 2)
	if SetNpcFightTarget then
		SetNpcFightTarget(pBot.nNpcIndex, nTargetNpc)
	end
	local tbSkill = pBot.tbSkill or {325,20}
	local bCanCast = 1
	if GetNpcDoing then
		local nDoing = GetNpcDoing(pBot.nNpcIndex)
		if nDoing == 6 or nDoing == 7 then
			bCanCast = 0
		end
	end
	if bCanCast == 1 then
		if BotDuelArm then
			BotDuelArm(pBot.nNpcIndex, nTargetNpc, tbSkill[1], tbSkill[2])
		elseif BotDoSkill then
			BotDoSkill(pBot.nNpcIndex, tbSkill[1], tbSkill[2], nTargetNpc)
		end
	end
	return 18
end

function tbRule:OnTime()
	if self.nState == "ready" then
		self.nState = "ready_count_down"
		self.nCountDown = %READY_COUNT_DOWN
		Msg2Map(self.nMapId, format("Thêi gian chuÈn bÞ cßn l¹i %d gi©y", self.nCountDown))
		return 18
	elseif self.nState == "ready_count_down" then
		if self.nCountDown > 0 then
			self.nCountDown = self.nCountDown - 1
			Msg2Map(self.nMapId, format("Thêi gian chuÈn bÞ cßn l¹i %d gi©y", self.nCountDown))
		else
			self.nState = "fight_count_down"
			self.nCountDown = %FIGHT_COUNT_DOWN
			self:ReadyFight()
		end
		return 18
	elseif self.nState == "fight_count_down" then
		if self.nCountDown > 0 then
			self.nCountDown = self.nCountDown - 1
			Msg2Map(self.nMapId, format("%d", self.nCountDown))
			return 18
		else
			self.nState = "fight"
			self:StartFight()
			return %FIGHT_TIME * 18
		end
	elseif self.nState == "fight" then
		self:ProcResult()
		return 0
	end
end

local init_rule = function ()
	PreApplyDungeonMap(%tbRule.TEMPLATE_MAP_ID, 0, 0)
end
AutoFunctions:Add(init_rule)
tbRule:SetForbitItem()
DynamicExecute("\\script\\item\\heart_head.lua", "add_forbit_templatemap", tbRule.TEMPLATE_MAP_ID)
