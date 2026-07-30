Include("\\script\\gm_tool\\dispose_item.lua")
Include("\\script\\global\\mel\\configserver.lua")

----------------------------------------------------------------------------------------------------
--                                                                               CÈm Nang §âng Hµnh                                                                               --
----------------------------------------------------------------------------------------------------
function main(nItemIndex)
    dofile("script/global/mel/item/camnangdonghanh.lua")
    local nTTK = GetTask(81)
    local nVLMT = GetTask(80)
    local nDiemTK = GetTask(747)
    local nPhucDuyen = GetTask(151)
    local nVinhDu = GetTask(2501)
    local nMayMan = GetLucky(0)
    local nLen = 17
    local szThongTin = format("Th«ng tin:\n")
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>/<color=green>%d<color>\n", "TÈy Tîy Kinh", nTTK, GioiHanTTK)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>/<color=green>%d<color>\n", "Vß L©m MËt TÛch", nVLMT, GioiHanVLMT)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>\n", "§iÓm Tång Kim", nDiemTK)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>\n", "§iÓm Phðc Duyªn", nPhucDuyen)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>\n", "§iÓm Vinh Dö", nVinhDu)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d", "ChØ så May M¾n", nMayMan)
    local tbSay = {szThongTin}
    tinsert(tbSay, "Cæng ®iÓm nhanh/tangdiemnhanh")
    tinsert(tbSay, "NhËn tr¹ng th¸i Phi ChiÕn §Êu/phichiendau")
    tinsert(tbSay, "Gi¶i kÑt nh©n vËt/KetAcc")
    tinsert(tbSay, "Sóa läi ThÇn Hµnh Phì/FixTHP")
    tinsert(tbSay, "Hîy vËt phÈm/DisposeItem")
    tinsert(tbSay, "KÕt thðc ®åi tho¹i./no")
    CreateTaskSay(tbSay)
    return 1
end

function tangdiemnhanh()
    Say("H·y chán tiÒm n¨ng muån cæng ®iÓm nhanh (§iÓm cÜn l¹i: "..GetProp()..")", 4,
        "T¨ng Sõc M¹nh/add_prop_str",
        "T¨ng Th©n Ph¸p/add_prop_dex",
        "T¨ng Ngo¹i C«ng/add_prop_vit",
        "T¨ng Næi C«ng/add_prop_eng")
end

function add_prop_str()
    AskClientForNumber("enter_str_num", 0, GetProp(), "Xin h·y nhËp ®iÓm så sõc m¹nh: ")
end

function add_prop_dex()
    AskClientForNumber("enter_dex_num", 0, GetProp(), "Xin h·y nhËp ®iÓm så th©n ph¸p: ")
end

function add_prop_vit()
    AskClientForNumber("enter_vit_num", 0, GetProp(), "Xin h·y nhËp ®iÓm så ngo¹i c«ng: ")
end

function add_prop_eng()
    AskClientForNumber("enter_eng_num", 0, GetProp(), "Xin h·y nhËp ®iÓm så næi c«ng: ")
end

function enter_str_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddStrg(n_key)
    Msg2Player("T¨ng thµnh c«ng "..n_key.." ®iÓm Sõc M¹nh.")
end

function enter_dex_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddDex(n_key)
    Msg2Player("T¨ng thµnh c«ng "..n_key.." ®iÓm Th©n Ph¸p.")
end

function enter_vit_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddVit(n_key)
    Msg2Player("T¨ng thµnh c«ng "..n_key.." ®iÓm Ngo¹i C«ng.")
end

function enter_eng_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddEng(n_key)
    Msg2Player("T¨ng thµnh c«ng "..n_key.." ®iÓm Næi C«ng.")
end

----------------------------------------------------------------------------------------------------
--                                                                                 Phi ChiÕn §Êu                                                                                  --
----------------------------------------------------------------------------------------------------
function phichiendau()
    SetFightState(0)
end

----------------------------------------------------------------------------------------------------
--                                                                               Gi¶i KÑt Nh©n VËt                                                                                --
----------------------------------------------------------------------------------------------------
function KetAcc()
    Say("B¹n cà ch¾c ch¾n r»ng b¹n ®ang bÛ kÑt acc kh«ng?", 2, "§ðng vËy!/GiaiKetNhanVat", "Ta nhÇm./no")
end

function GiaiKetNhanVat()
    local nW, nX, nY = GetWorldPos()
    for i=235,248 do
        if (nW == i) then
            Msg2Player("Map nµy kh«ng thÓ só dñng tiÖn Ùch nµy!")
            return 1
        end
    end
    if (nW == 53) then
        SetPos(1626,3179)
    else
        NewWorld(53, 1626, 3179)
    end
    SetFightState(0)
    Msg2Player("Gi¶i kÑt nh©n vËt thµnh c«ng!")
end

function FixTHP()
    DisabledUseTownP(0)
end

----------------------------------------------------------------------------------------------------
function GetDesc(nItemIndex)
    local szDesc = "<color=water>Thiªn la ®Ûa vßng cïng kh«ng thÓ ng¨n c¶n!<color>\n"
    szDesc = szDesc.."<color=water>V¹n tr­ëng th©m s¬n cïng ch¼ng thÓ c¸ch lÜng!<color>\n"
    return szDesc
end
