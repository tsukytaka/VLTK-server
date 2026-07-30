Include("\\script\\gm_tool\\dispose_item.lua")
Include("\\script\\global\\mel\\configserver.lua")

----------------------------------------------------------------------------------------------------
--                                                                               C�m Nang ��ng H�nh                                                                               --
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
    local szThongTin = format("Th�ng tin:\n")
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>/<color=green>%d<color>\n", "T�y T�y Kinh", nTTK, GioiHanTTK)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>/<color=green>%d<color>\n", "V� L�m M�t T�ch", nVLMT, GioiHanVLMT)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>\n", "�i�m T�ng Kim", nDiemTK)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>\n", "�i�m Ph�c Duy�n", nPhucDuyen)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d<color>\n", "�i�m Vinh D�", nVinhDu)
    szThongTin = szThongTin..format("<pic=135> <color=green>%-"..nLen.."s<color>: <color=orange>%d", "Ch� s� May M�n", nMayMan)
    local tbSay = {szThongTin}
    tinsert(tbSay, "Ti�n �ch/TienIchMenu")
    tinsert(tbSay, "Nh�n tr�ng th�i Phi Chi�n ��u/phichiendau")
    tinsert(tbSay, "Gi�i k�t nh�n v�t/KetAcc")
    tinsert(tbSay, "S�a l�i Th�n H�nh Ph�/FixTHP")
    tinsert(tbSay, "H�y v�t ph�m/DisposeItem")
    tinsert(tbSay, "K�t th�c ��i tho�i./no")
    CreateTaskSay(tbSay)
    return 1
end

----------------------------------------------------------------------------------------------------
--                                                                                 Ti�n �ch                                                                                       --
----------------------------------------------------------------------------------------------------
function TienIchMenu()
    local tbSay = {"C�m Nang ��ng H�nh - Ti�n �ch:"}
    tinsert(tbSay, "C�ng �i�m nhanh/tangdiemnhanh")
    tinsert(tbSay, "Quay l�i/main")
    CreateTaskSay(tbSay)
end

function tangdiemnhanh()
    Say("H�y ch�n ti�m n�ng mu�n c�ng �i�m nhanh (�i�m c�n l�i: "..GetProp()..")", 4,
        "T�ng S�c M�nh/add_prop_str",
        "T�ng Th�n Ph�p/add_prop_dex",
        "T�ng Ngo�i C�ng/add_prop_vit",
        "T�ng N�i C�ng/add_prop_eng")
end

function add_prop_str()
    AskClientForNumber("enter_str_num", 0, GetProp(), "Xin h�y nh�p �i�m s� s�c m�nh: ")
end

function add_prop_dex()
    AskClientForNumber("enter_dex_num", 0, GetProp(), "Xin h�y nh�p �i�m s� th�n ph�p: ")
end

function add_prop_vit()
    AskClientForNumber("enter_vit_num", 0, GetProp(), "Xin h�y nh�p �i�m s� ngo�i c�ng: ")
end

function add_prop_eng()
    AskClientForNumber("enter_eng_num", 0, GetProp(), "Xin h�y nh�p �i�m s� n�i c�ng: ")
end

function enter_str_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddStrg(n_key)
    Msg2Player("T�ng th�nh c�ng "..n_key.." �i�m S�c M�nh.")
end

function enter_dex_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddDex(n_key)
    Msg2Player("T�ng th�nh c�ng "..n_key.." �i�m Th�n Ph�p.")
end

function enter_vit_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddVit(n_key)
    Msg2Player("T�ng th�nh c�ng "..n_key.." �i�m Ngo�i C�ng.")
end

function enter_eng_num(n_key)
    if (n_key < 0 or n_key > GetProp()) then
        return
    end
    AddEng(n_key)
    Msg2Player("T�ng th�nh c�ng "..n_key.." �i�m N�i C�ng.")
end

----------------------------------------------------------------------------------------------------
--                                                                                 Phi Chi�n ��u                                                                                  --
----------------------------------------------------------------------------------------------------
function phichiendau()
    SetFightState(0)
end

----------------------------------------------------------------------------------------------------
--                                                                               Gi�i K�t Nh�n V�t                                                                                --
----------------------------------------------------------------------------------------------------
function KetAcc()
    Say("B�n c� ch�c ch�n r�ng b�n �ang b� k�t acc kh�ng?", 2, "��ng v�y!/GiaiKetNhanVat", "Ta nh�m./no")
end

function GiaiKetNhanVat()
    local nW, nX, nY = GetWorldPos()
    for i=235,248 do
        if (nW == i) then
            Msg2Player("Map n�y kh�ng th� s� d�ng ti�n �ch n�y!")
            return 1
        end
    end
    if (nW == 53) then
        SetPos(1626,3179)
    else
        NewWorld(53, 1626, 3179)
    end
    SetFightState(0)
    Msg2Player("Gi�i k�t nh�n v�t th�nh c�ng!")
end

function FixTHP()
    DisabledUseTownP(0)
end

function GetDesc(nItemIndex)
    local szDesc = "<color=water>Thi�n la ��a v�ng c�ng kh�ng th� ng�n c�n!<color>\n"
    szDesc = szDesc.."<color=water>V�n tr��ng th�m s�n c�ng ch�ng th� c�ch l�ng!<color>\n"
    return szDesc
end
