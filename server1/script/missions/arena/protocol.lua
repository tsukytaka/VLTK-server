Include("\\script\\lib\\objbuffer_head.lua")
Include("\\script\\missions\\arena\\rule.lua")
Include("\\script\\dailogsys\\dailogsay.lua")
Include("\\script\\lib\\timerlist.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\webconfig.lua")

Include("\\script\\global\\logout_head.lua")
IncludeLib("SETTING")
local tbAccMapList = 
{
	[1] = "Ph­îng T­êng",
	[11] = "Thµnh §«",
	[37] = "BiÖn Kinh",
	[80] = "D­¬ng Ch©u",
	[78] = "T­¬ng D­¬ng",
	[162] = "§¹i Lý",
	[176] = "L©m An",
	[20] = "Giang T©n Th«n",
	[53] = "Ba L¨ng huyÖn",
	[54] = "Nam Nh¹c trÊn",
	[99] = "VÜnh L¹c trÊn",
	[100] = "Chu Tiªn trÊn",
	[101] = "§¹o H­¬ng th«n",
	[121] = "Long M«n trÊn",
	[153] = "Th¹ch Cæ trÊn",
	[174] = "Long TuyÒn th«n",
}

tinsert(TB_LOGOUT_FILEFUN, {"\\script\\missions\\arena\\protocol.lua",		"player_logout"})

ArenaSimCityQueue = ArenaSimCityQueue or {}
ArenaSimCityTimer = ArenaSimCityTimer or {}

function ArenaSimCityTimer:OnTime(szName, nTimerId)
	ArenaSimCityQueue[szName] = nil
	if SIMCITY_DUEL_ENABLED ~= 1 or SIMCITY_DUEL_BOT_ENABLED ~= 1 then
		return 0
	end
	local nPlayerIndex = SearchPlayer(szName)
	if nPlayerIndex <= 0 then
		return 0
	end
	local nCurMapId = CallPlayerFunction(nPlayerIndex, GetWorldPos)
	if not CallPlayerFunction(nPlayerIndex, tbPlayer.CheckState, tbPlayer) or not %tbAccMapList[nCurMapId] then
		return 0
	end
	player_cancel_remote(szName)
	local pDungeonType = DungeonType["arena"]
	if pDungeonType then
		local pDungeon = pDungeonType:new_dungeon(pDungeonType.TEMPLATE_MAP_ID)
		if pDungeon then
			pDungeon:StartSimCityMatch(nPlayerIndex)
			CallPlayerFunction(nPlayerIndex, Msg2Player, "Khong tim thay nguoi choi. Dang ghep doi thu SimCity...")
		else
			CallPlayerFunction(nPlayerIndex, Msg2Player, "Chua tao duoc dau truong, hay thu lai.")
		end
	end
	return 0
end

function cancel_simcity_timer(szName)
	local nTimerId = ArenaSimCityQueue[szName]
	if nTimerId then
		TimerList:DelTimer(nTimerId)
		ArenaSimCityQueue[szName] = nil
	end
end

function schedule_simcity_timer(szName)
	cancel_simcity_timer(szName)
	if SIMCITY_DUEL_BOT_ENABLED == 1 then
		local nWait = tonumber(SIMCITY_DUEL_WAIT_SECONDS) or 30
		if nWait < 5 then
			nWait = 5
		end
		ArenaSimCityQueue[szName] = TimerList:AddTimer(%ArenaSimCityTimer, nWait * 18, szName)
	end
end

function allocate_map(ParamHandle, ResultHandle)

	local pDungeonType = DungeonType["arena"]
	if pDungeonType then
		local pDungeon = pDungeonType:new_dungeon(pDungeonType.TEMPLATE_MAP_ID)
		if pDungeon then
			local handle = OB_Create()
			ObjBuffer:PushObject(handle, pDungeon.nMapId)
			RemoteExecute("\\script\\missions\\arena\\protocol.lua", "reg_map", handle)
			OB_Release(handle)
		end
	end

end

function player_enter_map(ParamHandle, ResultHandle)
	local szName = ObjBuffer:PopObject(ParamHandle)
	cancel_simcity_timer(szName)
	local nMapId = ObjBuffer:PopObject(ParamHandle)
	local nTimeOut = ObjBuffer:PopObject(ParamHandle)
	local nPlayerIndex = SearchPlayer(szName)	
	if nPlayerIndex > 0 then
		local nCurMapId = CallPlayerFunction(nPlayerIndex, GetWorldPos )
		if not CallPlayerFunction(nPlayerIndex, tbPlayer.CheckState, tbPlayer) or not %tbAccMapList[nCurMapId] then
			CallPlayerFunction(nPlayerIndex, Msg2Player, "B¶n ®å hiÖn t¹i ng­¬i ®ang ®øng kh«ng thÓ ®i vµo c¶nh Kü Tr­êng")
			player_cancel(szName)
		else
--			local tbOpt = 
--			{
--				{"½øÈë", player_enter_map_confirm, {nMapId, nTimeOut}},
--				{"·ÅÆú", player_cancel, {szName}},
--				{"µÈµÈ"}
--			}
--			CallPlayerFunction(nPlayerIndex, CreateNewSayEx, "ÏÖÔÚ¿ÉÒÔ½øÈë¾º¼¼³¡", tbOpt)
			CallPlayerFunction(nPlayerIndex, player_enter_map_confirm, nMapId, nTimeOut)
		end
	end
end

function player_logout(nPlayerIndex)
	if nPlayerIndex > 0 then
		local szName = CallPlayerFunction(nPlayerIndex, GetName)
		cancel_simcity_timer(szName)
		local handle = OB_Create()
		ObjBuffer:PushObject(handle, szName)
		RemoteExecute("\\script\\missions\\arena\\protocol.lua", "player_logout", handle)
		OB_Release(handle)
	end
end

function player_cancel(szName)
	cancel_simcity_timer(szName)
	player_cancel_remote(szName)
end

function player_cancel_remote(szName)
	local handle = OB_Create()
	ObjBuffer:PushObject(handle, szName)
	RemoteExecute("\\script\\missions\\arena\\protocol.lua", "player_cancel", handle)
	OB_Release(handle)
end

function player_enter_map_confirm(nMapId, nTimeOut)
	local szName = GetName()
	local nCurMapId = GetWorldPos()
	if not tbPlayer:CheckState() or not %tbAccMapList[nCurMapId] then
		player_cancel(szName)
		return 
	end
	local nCurTime = GetCurServerTime()
	if nTimeOut < nCurTime then
		return Talk(1, "", "Thao t¸c nµy ®· v­ît qu¸ thêi gian")
	end
	
	local nLastMapId, nX, nY = GetWorldPos()
	local nLastFightState = GetFightState()
	local tbLastState  = {tbPos ={nLastMapId, nX, nY}, nFightState = nLastFightState}
	
	local handle = OB_Create()
	ObjBuffer:PushObject(handle, szName)
	ObjBuffer:PushObject(handle, tbLastState)
	RemoteExecute("\\script\\missions\\arena\\protocol.lua", "set_last_state", handle)
	OB_Release(handle)
	local pDungeonType = DungeonType["arena"]
	if pDungeonType then
		NewWorld(nMapId, pDungeonType:GetReadyPos())
	end
end


function set_last_state(nParam, ParamHandle)
	local szName = ObjBuffer:PopObject(ParamHandle)
	local nMapId = ObjBuffer:PopObject(ParamHandle)
	local tbLastState = ObjBuffer:PopObject(ParamHandle)

	if SubWorldID2Idx(nMapId) >= 0 then
		local pDungeon = DungeonList[nMapId]
		if pDungeon then
			pDungeon:SetLastState(szName, tbLastState)
		end
	end
end

function signup_callback(nParam, ParamHandle)
	local szName = ObjBuffer:PopObject(ParamHandle)
	local bFind = ObjBuffer:PopObject(ParamHandle)
	
	local nPlayerIndex = SearchPlayer(szName)
	if nPlayerIndex > 0 and bFind ~= 1 then
		CallPlayerFunction(nPlayerIndex, Talk, 1, "", "Bao danh thanh cong. Dang tim doi thu, xin hay doi...")
	end
end


function finded_oppoent(ParamHandle, ResultHandle)
	local szName = ObjBuffer:PopObject(ParamHandle)
	cancel_simcity_timer(szName)
	local nPlayerIndex = SearchPlayer(szName)
	if nPlayerIndex > 0 then
		CallPlayerFunction(nPlayerIndex, Msg2Player, "T×m ®­îc ®èi thñ")
	end
end

function wait_map(ParamHandle, ResultHandle)
	local szName = ObjBuffer:PopObject(ParamHandle)
	local nPlayerIndex = SearchPlayer(szName)
	if nPlayerIndex > 0 then
		CallPlayerFunction(nPlayerIndex, Msg2Player, "§ang chuÈn bÞ ®Êu tr­êng cña C¶nh Kü Tr­êng…")
	end
end

function notify_oppoent_cancel(ParamHandle, ResultHandle)
	local szName = ObjBuffer:PopObject(ParamHandle)
	local nPlayerIndex = SearchPlayer(szName)
	if nPlayerIndex > 0 then
		CallPlayerFunction(nPlayerIndex, Msg2Player, "§èi thñ cña ng­¬i ®· bá trËn nµy, hÖ thèng ®ang t×m ®èi thñ míi…")
	end
end
-------------------------------------------------------




function on_player_enter_map(szName, nMapId)
	local handle = OB_Create()
	ObjBuffer:PushObject(handle, szName)
	ObjBuffer:PushObject(handle, nMapId)
	RemoteExecute("\\script\\missions\\arena\\protocol.lua", "player_enter_map", handle, "set_last_state")
	OB_Release(handle)
end

function on_player_leave_map(szName, nMapId)
	local handle = OB_Create()
	ObjBuffer:PushObject(handle, szName)
	ObjBuffer:PushObject(handle, nMapId)
	RemoteExecute("\\script\\missions\\arena\\protocol.lua", "player_leave_map", handle)
	OB_Release(handle)
end

function on_begin_battle(nMapId, tbMemberMap)
	local handle = OB_Create()
	ObjBuffer:PushObject(handle, nMapId)
	for szName, pInfo in tbMemberMap do
		if pInfo then
			ObjBuffer:PushObject(handle, szName)
		end
	end
	RemoteExecute("\\script\\missions\\arena\\protocol.lua", "begin_battle", handle)
	OB_Release(handle)
end



function apply_signup()
	if SIMCITY_DUEL_ENABLED ~= 1 then
		return Talk(1, "", "Canh Ky Truong 1 dau 1 dang tam tat trong Web Admin.")
	end
	if not tbPlayer:CheckState() then
		return Talk(1, "", "Trang thai hien tai khong the bao danh Canh Ky Truong.")
	end
	local nMapId = GetWorldPos()
	if not %tbAccMapList[nMapId] then
		return Talk(1, "", "Hay bao danh tai thanh thi hoac thon tran.")
	end
	local szName = GetName()
	local nRank = tbPlayer:GetRank()
	local nGroup = floor(nRank / 100) + 1
	if nGroup < 1 then
		nGroup = 1
	elseif nGroup > 30 then
		nGroup = 30
	end
	local handle = OB_Create()
	ObjBuffer:PushObject(handle, szName)
	ObjBuffer:PushObject(handle, nGroup)
	RemoteExecute("\\script\\missions\\arena\\protocol.lua", "apply_search_opponents", handle, "signup_callback")
	OB_Release(handle)
	schedule_simcity_timer(szName)
end
