Include("\\script\\bonus_onlinetime\\head.lua")
Include("\\script\\vng_feature\\resetbox.lua")
Include("\\script\\item\\tianziyuxi.lua")
Include("\\script\\nationalwar\\login.lua")
Include("\\script\\tong\\tong_login.lua")
Include("\\script\\missions\\leaguematch\\wlls_login.lua")
Include("\\script\\activitysys\\playerfunlib.lua")
Include("\\script\\activitysys\\g_activity.lua")
Include("\\script\\misc\\extpoint_loginmsg\\login_msg.lua")
Include("\\script\\misc\\taskmanager.lua")
Include("\\script\\misc\\eventsys\\type\\player.lua")
Include("\\script\\misc\\daiyitoushi\\toushi_resetbase.lua")
Include("\\script\\global\\login_old.lua")
Include("\\script\\global\\offline_login.lua")
Include("\\script\\global\\recordplayerinfo.lua")
Include("\\script\\global\\playerlist.lua")
Include("\\script\\global\\login_hint.lua")
Include("\\script\\global\\gm\\gm_script.lua")
Include("\\script\\global\\gm\\lenhbaiadmintestserver.lua")
Include("\\script\\global\\login_head.lua")
Include("\\script\\global\\admin_item_login.lua")
Include("\\script\\global\\newbie_guide_tanthu.lua")
Include("\\script\\global\\œ¥pkµƒ—√“€.lua")
Include("\\script\\global\\limitaccount_ip.lua")
Include("\\script\\global\\pgaming\\configserver\\configall.lua")
Include("\\script\\global\\pgaming\\xephang\\worldrank_hook.lua")
Include("\\script\\global\\pgaming\\xephang\\inc.lua")
Include("\\script\\global\\general\\xephang_exp_title\\rankexp.lua")
Include("\\script\\item\\ib\\zimudai.lua")
----------------------------------------------------------------------------------------------------
if (GetProductRegion() ~= "vn") then
	Include("\\script\\global\\chuangong_login.lua")
	Include("\\script\\task\\lv120skill\\head.lua")
end

if (GetProductRegion() == "cn_ib") then
end

function main(bExchangeIn)
	PlayerList:AddPlayer(PlayerIndex)
	TaskManager:ResetUseGroup()
	LoginDelaySync(1)

	-- Kh∏ng ¢m
	local seris = GetSeries()
	if seris == 0 then
	AddSkillState(1235,30,1,279936000,1)
	end
	local seris = GetSeries()
	if seris == 1 then
	AddSkillState(1236,30,1,279936000,1)
	end
	local seris = GetSeries()
	if seris == 2 then
	AddSkillState(1237,30,1,279936000,1)
	end
	local seris = GetSeries()
	if seris == 3 then
	AddSkillState(1238,30,1,279936000,1)
	end
	local seris = GetSeries()
	if seris == 4 then
	AddSkillState(1239,30,1,279936000,1)
	end

	-- BÀt/Tæt Bµy B∏n
	if KhoaChucNangBayBan == 1 then
		DisabledStall(1)
	else
		DisabledStall(0)
	end

	-- BÀt/Tæt Giao Dﬁch
	if KhoaChucNangGiaoDich == 1 then
		ForbitTrade(1)
	else
		ForbitTrade(0)
	end

	-- C p ßÈ ß®ng NhÀp L«n ß«u
	if CapKhiLoginVaoServer == 1 then
		if GetLevel() < CapDo then
		local nCureLevel = GetLevel()
		local nAddLevel = CapDo - nCureLevel
		ST_LevelUp(nAddLevel)
		end
	end

	-- Qu√† kh·ªüi t·∫°o nh√¢n v·∫≠t (Set ƒê·ªông S√°t & Ng·ª±a Chi·∫øu D·∫°)
	if (GetTask(3000) == 0) then
		if CalcFreeItemCellCount() >= 5 then
			-- Set ƒê·ªông S√°t
			for i = 143, 146 do
				local nItemIndex = AddGoldItem(0, i)
				if (nItemIndex and nItemIndex > 0) then
					SetItemBindState(nItemIndex, -2)
					SyncItem(nItemIndex)
				end
			end
			-- Ng·ª±a Chi·∫øu D·∫°
			local nHorseIndex = AddItem(0, 10, 5, 10, 0, 0)
			if (nHorseIndex and nHorseIndex > 0) then
				SetItemBindState(nHorseIndex, -2)
				SyncItem(nHorseIndex)
			end
			SetTask(3000, 1)
			Msg2Player("B·∫°n nh·∫≠n ƒë∆∞·ª£c 1 b·ªô trang b·ªã ƒê·ªông S√°t v√† 1 Ng·ª±a Chi·∫øu D·∫° (Kh√≥a)!")
		end
	end

	-- GiÌi Hπn IP
	if GioiHanLoginIP == 1 then
		if (LimitAccountPerIP:Login() == 1) then
			OfflineLive(PlayerIndex)
			KickOutSelf()
			return
		end
	end

	-- Òy Th∏c
	SetTask(5998,0)

	-- X’p Hπng Tinh L˘c
	LoginMain()

	-- X’p Hπng
	SendExpRanking()

	-- C©u C∏
	if CauCa == 1 then
		local nSubWorldID = GetWorldPos()
		if (nSubWorldID == 1009) and GetFightState() == 1 then
			SetFightState(1)
			SetFightState(1)
			SetPKFlag(1)
			ForbidChangePK(1)
		end
	end

	-- K›ch Ng≠Íi Ch¨i Bﬁ Kh„a
	DynamicExecute("\\script\\global\\gm\\gm_script.lua", "tbAloneScript:GameServerKickOut", PlayerIndex)
	
	-- HÁ TrÓ GM
	tbAloneScript:GMLoginInGame()
	GMLoginInGame()

	-- Sync trang thai trung sinh mo rong TS6/TS7 cho client hien thi dung.
	if (SyncTaskValue) then
		SyncTaskValue(2577);
		SyncTaskValue(2578);
		SyncTaskValue(2579);
		SyncTaskValue(2583);
		SyncTaskValue(1122);
	end

	if (AdminItem_ProcessLogin) then
		AdminItem_ProcessLogin()
	end

	-- Cap item Cam nang Tan Thu moi, tach biet voi item hien tai.
	if (NewbieGuideTanThu_ProcessLogin) then
		NewbieGuideTanThu_ProcessLogin()
	end

	-- Reset MÀt Kh»u R≠¨ng
	ResetBox:AnnounceResetBoxDate()

	-- Online NhÀn Th≠Îng
	if (OnlineAward_StartDate() == 1 and OnlineAward_Check_TransferLife() ~= 0) then
		Msg2Player("ßang trong thÍi gian hoπt ÆÈng Online NhÀn Th≠Îng")
		OnlineAward_ResetDaily()
		OnlineAward_SummaryOnlineTime()
		OnlineAward_StartTime()
	end
	if (TB_LOGIN_FUN[0]) then
		for i = 1, getn(TB_LOGIN_FUN[0]) do
			local func = TB_LOGIN_FUN[0][i]
			if (func) then
				func(bExchangeIn)
			end
		end
	end
	for i = 1, getn(TB_LOGIN_FILEFUN) do
		local reg = TB_LOGIN_FILEFUN[i]
		DynamicExecute(reg[1], reg[2], PlayerIndex, bExchangeIn)
	end
end

-- X’p Hπng Tinh L˘c
function LoginMain()
	RankHook:GetRank(GetName())
end

----------------------------------------------------------------------------------------------------
function main_delaysync(nStep)
	if (nStep < 1 or nStep > getn(TB_LOGIN_FUN)) then
		print("main_delaysync error: "..nStep.." funccount:"..getn(TB_LOGIN_FUN))
		return 1
	end
	if (TB_LOGIN_FUN[nStep]) then
		for i = 1, getn(TB_LOGIN_FUN[nStep]) do
			if (TB_LOGIN_FUN[nStep][i]) then TB_LOGIN_FUN[nStep][i]() end
		end
	end
	if (nStep < getn(TB_LOGIN_FUN)) then
		return 0
	else
		return 1
	end
end

function no()
	if chuangong_login ~= nil then
		chuangong_login()
	end
end