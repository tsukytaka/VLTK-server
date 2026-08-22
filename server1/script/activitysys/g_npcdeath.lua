

-- ====================== 文件信息 ======================

-- 剑侠情缘网络版大陆版 - 
-- 文件用途：全局NPC死亡都会掉该脚本的OnGlobalNpcDeath函数
-- 创建者　：ZERO.SYS
-- 创建时间：2009-09-28 17:57:03

-- ======================================================
--默认全局PlayerIndex为物品所有者, PlayerIndex
--nNpcIndex 死亡的npc的NpcIndex
--nAttackerIndex 最后一击者 的PlayerIndex，, 
IncludeLib("NPCINFO")
Include("\\script\\lib\\string.lua")
Include("\\script\\activitysys\\npcfunlib.lua")
Include("\\script\\activitysys\\g_activity.lua")
Include("\\script\\task\\killmonster\\killmonster.lua")
Include("\\script\\missions\\boss\\bigboss.lua");
Include("\\script\\activitysys\\playerfunlib.lua")
Include("\\script\\event\\jiefang_jieri\\201004\\refining_iron\\head.lua")
Include("\\script\\activitysys\\config\\32\\killdailytask.lua")
--tinhpn 20100706: Vo Lam Minh Chu
Include("\\script\\bonusvlmc\\killmonster.lua")

Include("\\script\\task\\150skilltask\\g_task.lua")
Include("\\script\\misc\\eventsys\\eventsys.lua")
Include("\\script\\global\\nobitaxd\\vdk\\coin_drop_webconfig.lua")

function JX_WebDropCoin(nNpcIndex)
	local nRate = JX_WEB_COIN_DROP_BP or 0
	if JX_WEB_COIN_DROP_ENABLED ~= 1 or nRate <= 0 or not PlayerIndex or PlayerIndex <= 0 then
		return
	end
	local nParam4 = GetNpcParam(nNpcIndex, 4)
	if nParam4 == 1 or nParam4 == 2 then
		return
	end
	local nNpcType = GetNpcPowerType(nNpcIndex)
	if nNpcType and nNpcType > 1 then
		return
	end
	if random(1, 10000) > nRate then
		return
	end
	local nX32, nY32, nSubWorldIdx = GetNpcPos(nNpcIndex)
	if nSubWorldIdx then
		DropItemEx(nSubWorldIdx, nX32, nY32, PlayerIndex, 4, 0, 0,
			4, 417, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0)
	end
end

function OnGlobalNpcDeath(nNpcIndex, nAttackerIndex)
	if PlayerIndex and PlayerIndex > 0 then
		Msg2Player("DEBUG: OnGlobalNpcDeath triggered!")
	end
	-- [PARTY XP 2026-07-01] bot trong nhom giet quai -> gan PlayerIndex = chu nhom + cong exp tay
	--   (engine CalcExp bo qua bot kill; nAttackerIndex=0 -> lay KNpc bot qua GetNpcLastAttacker -> PollParty)
	if (not PlayerIndex or PlayerIndex <= 0) and GetNpcLastAttacker and PollParty then
		local _botIdx = GetNpcLastAttacker(nNpcIndex)
		if _botIdx and _botIdx > 0 then
			local _pp = PollParty(_botIdx)
			local _p4 = GetNpcParam(nNpcIndex, 4)
			if _pp and _pp > 0 and not (_p4 == 1 or _p4 == 2) then   -- KO cong exp khi giet sim-bot (chong farm)
				PlayerIndex = _pp
				if NPCINFO_GetLevel and vGetNpcExp and AddOwnExp then
					local _npcLv = NPCINFO_GetLevel(nNpcIndex)
					local _plLv = CallPlayerFunction(_pp, GetLevel)
					if _npcLv and _plLv and _npcLv > 0 and _plLv > 0 then
						local _rate = 1 + (_plLv - (10 * floor(_plLv / 10))) / 10
						CallPlayerFunction(_pp, AddOwnExp, floor(vGetNpcExp(min(_npcLv, _plLv)) * _rate))
					end
				end
			end
		end
	end
	local found = vinh_OnGlobalNpcDeath(nNpcIndex, nAttackerIndex)

	if PlayerIndex and PlayerIndex > 0 then
		JX_WebDropCoin(nNpcIndex)
		--PlayerEvent:OnEvent("OnKillNpc", nNpcIndex, nAttackerIndex)

		local szNpcName = GetNpcName(nNpcIndex)
		if NpcName2Replace then
			szNpcName = NpcName2Replace(szNpcName)
		end
		EventSys:GetType("NpcDeath"):OnEvent(szNpcName, nNpcIndex, nAttackerIndex)		
		local nTeamSize = GetTeamSize()
		if nTeamSize > 0 then
			for i=1, nTeamSize do
				local nPlayerIndex = GetTeamMember(i)
				if (type(found) ~= "table" or found[nPlayerIndex] == nil) then
					lib:DoFunByPlayer(nPlayerIndex, tbKillMonster.KillMonster, tbKillMonster, nNpcIndex)
				end
				--tinhpn 20100706: VLMC
				lib:DoFunByPlayer(nPlayerIndex, VLMC.KillMonster, VLMC, nNpcIndex)
			end
		else
			if (type(found) ~= "table" or found[PlayerIndex] == nil) then
				tbKillMonster:KillMonster(nNpcIndex)
			end
			--tinhpn 20100706: VLMC
			VLMC:KillMonster(nNpcIndex)
		end
		tbKillDailyTask:OnKillMonster(nNpcIndex)		
		G_ACTIVITY:OnMessage("NpcOnDeath", nNpcIndex)
		G_TASK:OnMessage("Th髖 Y猲", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("Nga Mi", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("Л阯g M玭", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("C竔 Bang", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("Ng?чc", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("Thi猲 Nh蒼", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("Thi誹 L﹎", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("V?ng", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("Thi猲 Vng", nNpcIndex, "KillNpc")
		G_TASK:OnMessage("C玭 L玭", nNpcIndex, "KillNpc")
		DynamicExecute("\\script\\missions\\tianchimijing\\floor4\\bossdeath.lua", "OnDeath", nNpcIndex, PlayerIndex)
		-- 闯关调整 2011.03.03
		DynamicExecute("\\script\\missions\\challengeoftime\\chuangguang30.lua", "ChuangGuan30:OnNpcDeath", nNpcIndex, PlayerIndex)
		-- 转生4怪物死亡掉落霹雳弹
		DynamicExecute("\\script\\task\\metempsychosis\\npcdeath_translife_4.lua", "OnNpcDeath", nNpcIndex, PlayerIndex)
		
		-- 炼金活动掉落
		if NpcFunLib:CheckBoatBoss(nNpcIndex) == 1 and tbRefiningIron:IsCarryOn() == 1 then
			tbDropTemplet:GiveAwardByList(nNpcIndex, PlayerIndex, {tbProp={6,1, 2293, 1,0,0,},nExpiredTime=tbRefiningIron.nCloseDate,}, "Th駓 t芻 u l躰h r琲 ?ho箃 ng luy謓 kim", 1)
		end
		
		if (DynamicExecute("\\script\\event\\jiefang_jieri\\201004\\main.lua", "FreedomEvent2010:IsActive1") == 1) then
			DynamicExecute("\\script\\event\\jiefang_jieri\\201004\\soldier\\main.lua", "Soldier2010:MonsterDrop", nNpcIndex, PlayerIndex);
		end
		-- 活跃度世界十大boss
		DynamicExecute("\\script\\huoyuedu\\worldtop10.lua", "checkworldtop10", nNpcIndex, PlayerIndex)
	end
end

function vCalcExp(Level, Param1, Param2)
	result = Param2 * Level + Param1;
	return result;
end;

function vGetNpcExp(Level)
	if (Level <= 10) then
		DataPara1 = 40
		DataPara2 = 5
		return vCalcExp(Level, DataPara1, DataPara2)
	end;

	if (Level <= 20) then
		DataPara1 = 120
		DataPara2 = 5
		return vCalcExp(Level - 10, DataPara1, DataPara2)
	end;

	if (Level <= 30) then
		DataPara1 = 240
		DataPara2 = 5
		return vCalcExp(Level - 20, DataPara1, DataPara2)
	end;

	if (Level <= 40) then
		DataPara1 = 360
		DataPara2 = 5
		return vCalcExp(Level - 30, DataPara1, DataPara2)
	end;

	if (Level <= 50) then
		DataPara1 = 480
		DataPara2 = 5
		return vCalcExp(Level - 40, DataPara1, DataPara2)
	end;

	if (Level <= 60) then
		DataPara1 = 600
		DataPara2 = 5
		return vCalcExp(Level - 50, DataPara1, DataPara2)
	end;

	if (Level <= 70) then
		DataPara1 = 720
		DataPara2 = 5
		return vCalcExp(Level - 60, DataPara1, DataPara2)
	end;

	if (Level <= 80) then
		DataPara1 = 800
		DataPara2 = 5
		return vCalcExp(Level - 70, DataPara1, DataPara2)
	end;

	if (Level <= 90) then
		DataPara1 = 900
		DataPara2 = 5
		return vCalcExp(Level - 80, DataPara1, DataPara2)
	end;


	DataPara1 = 1000
	DataPara2 = 5
	return vCalcExp(Level - 90, DataPara1, DataPara2)
end;


function vinh_OnGlobalNpcDeath(nNpcIndex, nAttackerIndex)
	local found = {}
	local npcType = GetNpcPowerType(nNpcIndex)
	
	Msg2Player("DEBUG: nNpcIndex="..tostring(nNpcIndex))
	Msg2Player("DEBUG: nAttackerIndex="..tostring(nAttackerIndex))
	if PlayerIndex and PlayerIndex > 0 then
		Msg2Player("DEBUG: vinh_OnGlobalNpcDeath called 1! npcType="..tostring(npcType))
	end

	-- Neu la SimCity bi chet thi dung rot gi ca
	local param4 = GetNpcParam(nNpcIndex, 4)
	Msg2Player("DEBUG: vinh_OnGlobalNpcDeath param4="..tostring(param4))
	if param4 and (param4 == 1 or param4 == 2) then
		return 1
	end

	-- Keoxe: them EXP
	local npcLevel = NPCINFO_GetLevel(nNpcIndex)
	local tbRoundPlayer, nCount = GetNpcAroundPlayerList(nNpcIndex, 10);
	for i = 1, nCount do
		local nPlayerIndex = tbRoundPlayer[i]
		if (not found[nPlayerIndex]) then
			local nPlayerLevel = CallPlayerFunction(nPlayerIndex, GetLevel)
			local rate = 1 + (nPlayerLevel - (10 * floor(nPlayerLevel / 10))) / 10
			if not npcType and (npcType > 1) then
				rate = rate * random(4,10)
			end
			local AddExpAmount = vGetNpcExp(min(npcLevel, nPlayerLevel))
			if (type(found) ~= "table" or found[nPlayerIndex] == nil) then
					lib:DoFunByPlayer(nPlayerIndex, tbKillMonster.KillMonster, tbKillMonster, nNpcIndex)
				end
			CallPlayerFunction(nPlayerIndex, AddOwnExp, floor(AddExpAmount * rate))
			found[nPlayerIndex] = true
		end
	end

	-- Keoxe: them tien + vat pham
	local _, _, nMapIndex = GetNpcPos(nNpcIndex)
	local mapDropFile = GetMapDropRateFile(nMapIndex)
	local npcLevel = 10*floor(NPCINFO_GetLevel(nNpcIndex) / 10)
	local levelDropFile = format("\\settings\\droprate\\npcdroprate%d.ini", npcLevel)
	local npcDropFile = GetNpcDropRateFile(nNpcIndex)
	local finalDropFile

	-- Map as priority
	if mapDropFile then
		finalDropFile = mapDropFile
	elseif levelDropFile then
		finalDropFile = levelDropFile
	else
		finalDropFile = npcDropFile
	end

	local rate = random(1,10)
	if (npcType > 1) then
		rate = random((npcType+0)*100, (npcType+1)*100)
	end

	if finalDropFile then
		ITEM_DropRateItem(nNpcIndex, rate, finalDropFile, 1, 100, GetNpcSeries(nNpcIndex));
	end

	-- Roi do An Bang / Dinh Quoc tu Boss Xanh (ti le 0.1%)
	if (npcType == 2) then
		local nChance = random(1, 1000)
		if nChance == 1 then
			if PlayerIndex and PlayerIndex > 0 then
				Msg2Player("DEBUG: Dropping An Bang / Dinh Quoc!")
				Msg2Player("DEBUG: PlayerIndex="..tostring(PlayerIndex))
			end
			-- goldequip.txt rowID - 2
			local tbItems = {
				{0, 152, 0, 0}, -- DQ
				{0, 153, 0, 0}, -- DQ
				{0, 154, 0, 0}, -- DQ
				{0, 155, 0, 0}, -- DQ
				{0, 156, 0, 0}, -- DQ
				{0, 157, 0, 0}, -- DQ
				{0, 158, 0, 0}, -- DQ
				{0, 159, 0, 0}, -- DQ
				{0, 160, 0, 0}, -- DQ
				{0, 161, 0, 0}, -- DQ
				{0, 162, 0, 0}, -- DQ
				{0, 163, 0, 0}, -- An Bang Hang Lien
				{0, 164, 0, 0}, -- An Bang Cuc Hoa
				{0, 165, 0, 0}, -- An Bang Ngoc Boi
				{0, 166, 0, 0}, -- An Bang Gioi Chi
				{6, 1, 15, 1}, -- Phi Phong
			}
			local nSelect = random(1, 16)
			local tbItem = tbItems[nSelect]
			local nX32, nY32, nSubWorldIdx = GetNpcPos(nNpcIndex)
			Msg2Player("DEBUG: nSubWorldIdx="..tostring(nSubWorldIdx))
			if nSubWorldIdx then
				local nBelonger = PlayerIndex or -1
				DropItemEx(nSubWorldIdx, nX32, nY32, nBelonger, 4, 0, 1, tbItem[1], tbItem[2], tbItem[3], tbItem[4], 0, 0, 0, 0, 0, 0, 0)
				if PlayerIndex and PlayerIndex > 0 then
					Msg2Player("Chuc mung ban da tieu diet Thu Linh va nhan duoc trang bi hiem!")
				end
			end
		end
	end

	-- Roi bi kip 120 tu Elite/Leader 110 tro len (ti le 0.1%)
	if (npcType == 2) then
		local dropFile = GetNpcDropRateFile(nNpcIndex) or ""
		if strfind(dropFile, "110") or strfind(dropFile, "119") or true then
			local nChance = random(1, 1000)
			if nChance = 1 then
				if PlayerIndex and PlayerIndex > 0 then
					Msg2Player("DEBUG: Dropping Skill 120 Book!")
				end
				local nX32, nY32, nSubWorldIdx = GetNpcPos(nNpcIndex)
				if nSubWorldIdx then
					local nBelonger = PlayerIndex or -1
					DropItemEx(nSubWorldIdx, nX32, nY32, nBelonger, 4, 0, 0, 6, 1, 1125, 1, 0, 0, 0, 0, 0, 0, 0)
					if PlayerIndex and PlayerIndex > 0 then
						Msg2Player("Chuc mung ban da tieu diet quai Tinh Anh/Thu Linh va nhan duoc Bi quyet ky nang cap 120!")
					end
				end
			end
		end
	end

	return found
end
