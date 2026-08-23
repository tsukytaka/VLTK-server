Include("\\script\\lib\\composeex.lua")
Include("\\script\\dailogsys\\dailogsay.lua")
Include("\\script\\lib\\awardtemplet.lua")
Include("\\script\\lib\\log.lua")
Include("\\script\\global\\pgaming\\configserver\\configall.lua")
-----------------------------------------------
---------------------------------
function main() 
dofile("script/global/pgaming/npc/freepk/vatphamhotro.lua")
	local tbOpt = {
		{"Mua Phi Tèc Hoµn",PhiTocHoan},
		{"Mua §¹i Lùc Hoµn",DaiLucHoan},
		{"Mua Tèng Kim Phi Tèc Hoµn",TKPhiTocHoan},
		{"Mua LÖnh Bµi",LenhBai},
		{"Mua ChiÕn Cæ",ChienCo},
		{"Mua Kh¸ng §¬n Chi Gi¸c",KhangDonChiGiac},
		{"KÕt Thóc §èi Tho¹i",No},
	}
	CreateNewSayEx("<color=green>Ng­¬i Muèn §æi Set Trang BÞ Hoµng Kim Mèn Ph¸i kh«ng?<color>", tbOpt)
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function PhiTocHoan()
local nXu = CalcEquiproomItemCount(4,417,1,-1);
	Describe("Sè l­îng Xu hiÖn cã: <color=yellow>: "..nXu.."<color><enter>     Tû lÖ ®æi 2 Xu = 1 Phi Tèc Hoµn<enter>",11,
	"Ta ®ång ý ®æi/PhiTocHoan2",
	"Ta sÏ quay l¹i sau!/no"
	);
end

function PhiTocHoan2()
	local nXu = floor(CalcEquiproomItemCount(4,417,1,-1)/2)
	AskClientForNumber("PhiTocHoan3",0,nXu, "2/1: ")
end

function PhiTocHoan3(n_key)
	MuaVatPhamXepChong(n_key, 0, 6, "Phi Tèc Hoµn")
end;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function DaiLucHoan()
local nXu = CalcEquiproomItemCount(4,417,1,-1);
	Describe("Sè l­îng Xu hiÖn cã: <color=yellow>: "..nXu.."<color><enter>     Tû lÖ ®æi 2 Xu = 1 Phi Tèc Hoµn<enter>",11,
	"Ta ®ång ý ®æi/DaiLucHoan2",
	"Ta sÏ quay l¹i sau!/no"
	);
end

function DaiLucHoan2()
	local nXu = floor(CalcEquiproomItemCount(4,417,1,-1)/2)
	AskClientForNumber("DaiLucHoan3",0,nXu, "2/1: ")
end

function DaiLucHoan3(n_key)
	MuaVatPhamXepChong(n_key, 0, 3, "§¹i Lùc Hoµn")
end;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function TKPhiTocHoan()
local nXu = CalcEquiproomItemCount(4,417,1,-1);
	Describe("Sè l­îng Xu hiÖn cã: <color=yellow>: "..nXu.."<color><enter>     Tû lÖ ®æi 2 Xu = 1 Phi Tèc Hoµn<enter>",11,
	"Ta ®ång ý ®æi/tkphitochoan2",
	"Ta sÏ quay l¹i sau!/no"
	);
end

function tkphitochoan2()
	local nXu = floor(CalcEquiproomItemCount(4,417,1,-1)/2)
	AskClientForNumber("tkphitochoan3",0,nXu, "2/1: ")
end

function tkphitochoan3(n_key)
	MuaVatPhamXepChong(n_key, 1, 190, "Tèng Kim Phi Tèc Hoµn")
end;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function LenhBai()
local nXu = CalcEquiproomItemCount(4,417,1,-1);
	Describe("Sè l­îng Xu hiÖn cã: <color=yellow>: "..nXu.."<color><enter>     Tû lÖ ®æi 2 Xu = 1 Phi Tèc Hoµn<enter>",11,
	"Ta ®ång ý ®æi/LenhBai2",
	"Ta sÏ quay l¹i sau!/no"
	);
end

function LenhBai2()
	local nXu = floor(CalcEquiproomItemCount(4,417,1,-1)/2)
	AskClientForNumber("LenhBai3",0,nXu, "2/1: ")
end

function LenhBai3(n_key)
	MuaVatPhamXepChong(n_key, 1, 157, "LÖnh Bµi")
end;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ChienCo()
local nXu = CalcEquiproomItemCount(4,417,1,-1);
	Describe("Sè l­îng Xu hiÖn cã: <color=yellow>: "..nXu.."<color><enter>     Tû lÖ ®æi 2 Xu = 1 Phi Tèc Hoµn<enter>",11,
	"Ta ®ång ý ®æi/ChienCo2",
	"Ta sÏ quay l¹i sau!/no"
	);
end

function ChienCo2()
	local nXu = floor(CalcEquiproomItemCount(4,417,1,-1)/2)
	AskClientForNumber("ChienCo3",0,nXu, "2/1: ")
end

function ChienCo3(n_key)
	MuaVatPhamXepChong(n_key, 1, 156, "ChiÕn Cæ")
end;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function KhangDonChiGiac()
local nXu = CalcEquiproomItemCount(4,417,1,-1);
	Describe("Sè l­îng Xu hiÖn cã: <color=yellow>: "..nXu.."<color><enter>     Tû lÖ ®æi 2 Xu = 1 Phi Tèc Hoµn<enter>",11,
	"Ta ®ång ý ®æi/KhangDonChiGiac2",
	"Ta sÏ quay l¹i sau!/no"
	);
end

function KhangDonChiGiac2()
	local nXu = floor(CalcEquiproomItemCount(4,417,1,-1)/2)
	AskClientForNumber("KhangDonChiGiac3",0,nXu, "2/1: ")
end

function KhangDonChiGiac3(n_key)
	MuaVatPhamXepChong(n_key, 1, 214, "Kh¸ng §¬n Chi Gi¸c")
end;

function MuaVatPhamXepChong(nSoLuong, nDetail, nParticular, szTenVatPham)
	nSoLuong = floor(tonumber(nSoLuong) or 0)
	if nSoLuong < 1 then
		Msg2Player("Sè l­îng mua kh«ng hîp lÖ.")
		return 0
	end

	local nChiPhi = nSoLuong * 2
	if CalcEquiproomItemCount(4,417,1,-1) < nChiPhi then
		Msg2Player("Kh«ng ®ñ Xu ®Ó mua vËt phÈm.")
		return 0
	end
	if CalcFreeItemCellCount() < 1 then
		Msg2Player("Hµnh trang cÇn Ýt nhÊt 1 « trèng.")
		return 0
	end

	ConsumeEquiproomItem(nChiPhi, 4, 417, 1, 1)
	tbAwardTemplet:GiveAwardByList({
		szName = szTenVatPham,
		tbProp = {6,nDetail,nParticular,1,(nDetail == 0 and 1 or 0),0},
		nCount = nSoLuong,
		nBindState = -2,
	}, "NPC B¸n VËt PhÈm Hç Trî", 1)
	return 1
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function OnTimer(nNpcIndex,nTimeOut)
    local tab_Chat = {
			"     <pic=115><pic=115><pic=115><bclr=blue><enter>Muèn gia t¨ng søc m¹nh h·y t×m gÆp ta <pic=00>!!!<color><bclr>",
            "     <pic=36><bclr=blue><enter>Chóc c¸c nh©n sü gÆp nhiÒu may m¾n vµ ph¸t tµi...! <bclr>",            
    }
    local ran = random(1,getn(tab_Chat))
    NpcChat(nNpcIndex,tab_Chat[ran])
    local ranTimer = random(10,20)
    SetNpcTimer(nNpcIndex,ranTimer*18)
    SetNpcScript(nNpcIndex,"\\script\\global\\pgaming\\npc\\freepk\\vatphamhotro.lua") 
end

function Add_Npc_VatPhamHoTro()
    local tb_npc_hotro = {
        {1579,3240},
    }
    local nMapIndex = SubWorldID2Idx(78)
    for i=1,getn(tb_npc_hotro) do
            local npcID    = (203)
            local npcName = "B¸n VËt PhÈm Hæ Trî"
            local npcdialog = AddNpc(npcID,0,nMapIndex,(tb_npc_hotro[i][1])*32,(tb_npc_hotro[i][2])*32,0,npcName,1)
            SetNpcTimer(npcdialog,5*18)
            SetNpcScript(npcdialog,"\\script\\global\\pgaming\\npc\\freepk\\vatphamhotro.lua")     
    end
end
