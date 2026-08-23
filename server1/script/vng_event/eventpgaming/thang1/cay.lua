---------------Youtube PGaming---------------
Include("\\script\\dailogsys\\dailogsay.lua")
Include("\\script\\lib\\awardtemplet.lua")
Include("\\script\\lib\\log.lua")
Include("\\script\\activitysys\\npcdailog.lua")
Include("\\script\\misc\\eventsys\\type\\npc.lua")
Include("\\script\\task\\task_addplayerexp.lua");
Include("\\script\\lib\\awardtemplet.lua");
Include("\\script\\task\\equipex\\head.lua")
Include("\\script\\global\\pgaming\\configserver\\configall.lua")
--------------------------------------------------------
BANHCHUNGTHUONGHAN 		 = 5862
NHANTHUONGMOC1	 		 = 5861
NHANTHUONGMOC2	 		 = 5860
NHANTHUONGMOC3			 = 5859
---------------------------------------------------------
function myplayersex()
	if GetSex() == 1 then 
		return "N÷ HiÖp";
	else
		return "§¹i HiÖp";
	end
end
--------------------------------------------------------------
function main()
dofile("script/vng_event/eventpgaming/thang1/cay.lua")

	local nNpcIndex = GetLastDiagNpc();
	local szNpcName = GetNpcName(nNpcIndex)
	
	if NpcName2Replace then
		szNpcName = NpcName2Replace(szNpcName);
	end
	
	local tbDailog = DailogClass:new(szNpcName);
	tbDailog.szTitleMsg = "<color=green>Ho¹t ®éng h¸i léc ®Çu xu©n ®· b¾t ®Çu, trong thêi gian chØ ®Þnh, Ng­êi ch¬i ®Õn tr­íc c©y ®µo, c©y mai ë thÊt ®¹i thµnh thÞ, t©n thñ th«n thµnh t©m cÇu nguyÖn, sÏ nhËn ®­îc nh÷ng phÇn th­ëng n¨m míi. Ngoµi ra, c¸c vÞ ®¹i hiÖp còng cã thÓ treo thªm liÔn tÕt víi ba ch÷ Phóc - Léc - Thä sÏ nhËn ®­îc nh÷ng phÇn th­ëng bÊt ngê.<color>\n HiÖn t¹i b¹n ®· treo ®­îc "..GetTask(5782).." liÔn",
	G_ACTIVITY:OnMessage("ClickNpc", tbDailog, nNpcIndex)

local nYear  = tonumber(date("%y"));
local nTime1 = "20"..nYear.."01010000"
local nTime2 = "20"..nYear.."02010000"
local nYMD  = tonumber(date("%y%m%d%H%M"))
local nDayNow = "20"..nYMD..""
	if EventThangDangMo(1) == 1 then
		tbDailog:AddOptEntry("Ta muèn treo liÔn Phóc - Léc - Thä ®Ó ®ãn tÕt",NhanMoc);
		tbDailog:Show();
	else
		Talk(1,"","<color=green>Ho¹t §éng DiÔn Ra Tõ:\n\n <color=red>0h Ngµy 01 - 01 - 20"..nYear.." §Õn 0h Ngµy 01 - 02 - 20"..nYear.."<color><color>")
	end
end				
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function NhanMoc()
	--for i = 1657, 1659 do
	--ItemIndex = CalcEquiproomItemCount(6,1,i,-1)
	--SyncItem(ItemIndex); 
	--end
	AskClientForNumber("phucloctho",0,nItemIndex, "NhËp sè l­îng muèn treo: ")
end	

--------------------------------------------------------Del item---------------------------------------------------------------------------------------
function DelNguyenLieu(nIndex,count)
	ConsumeEquiproomItem(count,6,1,nIndex,-1)
end
-----------------------------------------------------So luong item-------------------------------------------------------------------------------------------------------------------------------------------
function phucloctho(n_key)
	n_key = floor(tonumber(n_key) or 0)
	if n_key < 1 then return end
	if EventThangDangMo(1) ~= 1 then
		Msg2Player("Sù kiÖn Phóc Léc Thä hiÖn kh«ng më.")
		return
	end
	if GetLevel() < 50 then
		Msg2Player("Nh©n vËt ph¶i ®¹t cÊp 50 trë lªn.")
		return
	end
	local nRemain = 100 - GetTask(5782)
	if nRemain <= 0 then
		Msg2Player("B¹n ®· nhËn ®ñ 100 l­ît th­ëng Phóc Léc Thä.")
		return
	end
	if n_key > nRemain then n_key = nRemain end
	if CalcEquiproomItemCount(6,1,1657,-1) < n_key or
	   CalcEquiproomItemCount(6,1,1658,-1) < n_key or
	   CalcEquiproomItemCount(6,1,1659,-1) < n_key then
		Msg2Player("CÇn ®ñ mçi bé: 1 Phóc + 1 Léc + 1 Thä.")
		return
	end
	local nCost = n_key * 9999
	if GetCash() < nCost then
		Msg2Player("Kh«ng ®ñ Ng©n l­îng, mçi bé cÇn 9.999 l­îng.")
		return
	end
	if CalcFreeItemCellCount() < 1 then
		Msg2Player("Hµnh trang kh«ng ®ñ chç trèng.")
		return
	end
	DelNguyenLieu(1657,n_key)
	DelNguyenLieu(1658,n_key)
	DelNguyenLieu(1659,n_key)
	Pay(nCost)
	for i=1,n_key do
		AddItem(6,1,random(122,124),1,0,0)
	end
	SetTask(5782,GetTask(5782)+n_key)
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
