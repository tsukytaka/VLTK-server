Include("\\script\\lib\\common.lua")
Include("\\script\\global\\nobitaxd\\item\\faction_def.lua")
Include("\\script\\dailogsys\\dailogsay.lua")

function main()
    local szTitle = "Giang Ho Lenh - Ho tro gia nhap mon phai va nhan skill\\n" ..
                    "Nhan vat: <color=green>" .. GetName() .. "</color>"
    local tbOpt = {
        {"Nhan ho tro tan thu (1 Bo An Bang & 1 VK HKMP)", check_and_give_support},
        {"Gia nhap mon phai (Nhan skill 60)", change_phai_tanthu},
        {"Thoat"}
    }
    CreateNewSayEx(szTitle, tbOpt)
    return 1
end

function check_and_give_support()
    -- Check if already received
    if GetTask(3027) == 1 then
        Talk(1, "", "Moi nhan vat chi duoc nhan ho tro tan thu 1 lan duy nhat!")
        return 1
    end
    
    -- Check free bag slots (at least 5 slots)
    if CalcFreeItemCellCount() < 5 then
        Talk(1, "", "Hanh trang can co it nhat 5 o trong de nhan trang bi!")
        return 1
    end
    
    -- Give An Bang set
    AddGoldItem(0, 164)
    AddGoldItem(0, 165)
    AddGoldItem(0, 166)
    AddGoldItem(0, 167)
    Msg2Player("Ban da nhan duoc 1 bo trang bi An Bang!")
    
    -- Forward to choose HKMP weapon
    choose_hkmp_weapon()
end

function choose_hkmp_weapon()
    local szTitle = "Xin chao! Hay chon mon phai cua vu khi Hoang Kim ban muon nhan:"
    local tbOpt = {
        {"Thieu Lam", tl_weapon},
        {"Thien Vuong", tv_weapon},
        {"Duong Mon", dm_weapon},
        {"Ngu Doc", nd_weapon},
        {"Nga My", nm_weapon},
        {"Thuy Yen", ty_weapon},
        {"Cai Bang", cb_weapon},
        {"Thien Nhan", tn_weapon},
        {"Vo Dang", vd_weapon},
        {"Con Lon", cl_weapon},
        {"Thoat"}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function tl_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Thieu Lam:"
    local tbOpt = {
        {"Thieu Lam Dao (Ti Khong Giang Ma Gioi Dao)", give_weapon, {11}},
        {"Thieu Lam Bong (Phuc Ma Tu Kim Con)", give_weapon, {6}},
        {"Thieu Lam Quyen (Mong Long Tu Kim Bat Nha Gioi)", give_weapon, {769}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function tv_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Thien Vuong:"
    local tbOpt = {
        {"Thien Vuong Chuy (Ham Thien Dai Nhan Than Chuy)", give_weapon, {16}},
        {"Thien Vuong Thuong (Ke Nghiep Bon Loi Toan Long Thuong)", give_weapon, {21}},
        {"Thien Vuong Dao (Ngu Long Luong Ngan Bao Dao)", give_weapon, {26}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function dm_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Duong Mon:"
    local tbOpt = {
        {"Duong Mon Phi Dao (Bang Han Don Chi Phi Dao)", give_weapon, {71}},
        {"Duong Mon Phi Tieu (Sam Hoang Phi Tinh Doat Hon)", give_weapon, {81}},
        {"Duong Mon Tu Tien (Thien Quang Hoa Vu Man Thien)", give_weapon, {76}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function nd_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Ngui Doc:"
    local tbOpt = {
        {"Ngu Doc Dao (Minh Ao Ta Sat Doc Nhan)", give_weapon, {61}},
        {"Ngu Doc Chuong (U Lung Kim Xa Phat Dai)", give_weapon, {56}},
        {"Ngu Doc Bua (Chu Phuoc Pha Giap Dau Hoan)", give_weapon, {66}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function nm_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Nga My:"
    local tbOpt = {
        {"Nga My Kiem (Vo Gian Y Thien Kiem)", give_weapon, {31}},
        {"Nga My Chuong (Vo Ma Ma Ni Quan)", give_weapon, {36}},
        {"Nga My Buff (Vo Tran Ngoc Nu To Tam Quan)", give_weapon, {41}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function ty_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Thuy Yen:"
    local tbOpt = {
        {"Thuy Yen Dao (Te Hoang Phung Nghi Dao)", give_weapon, {46}},
        {"Thuy Yen Song Dao (Bich Hai Uyen Uong Lien Hoan Dao)", give_weapon, {51}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function cb_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Cai Bang:"
    local tbOpt = {
        {"Cai Bang Bong (Dich Khai Luc Ngoc Truong)", give_weapon, {96}},
        {"Cai Bang Chuong (Dong Cuu Phi Long Dau Hoan)", give_weapon, {91}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function tn_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Thien Nhan:"
    local tbOpt = {
        {"Thien Nhan Thuong (Ma Sat Quy Coc U Minh Thuong)", give_weapon, {101}},
        {"Thien Nhan Dao (Ma Thi Liet Diem Quan Mien)", give_weapon, {111}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function vd_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Vo Dang:"
    local tbOpt = {
        {"Vo Dang Kiem (Cap Phong Chan Vu Kiem)", give_weapon, {121}},
        {"Vo Dang Khi (Lang Nhac Thai Cuc Kiem)", give_weapon, {116}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function cl_weapon()
    local szTitle = "Chon vu khi Hoang Kim Mon Phai Con Lon:"
    local tbOpt = {
        {"Con Lon Dao (Suong Tinh Thien Nien Han Thiet)", give_weapon, {126}},
        {"Con Lon Kiem (Loi Khung Han Tung Bang Bach Quan)", give_weapon, {131}},
        {"Quay lai", choose_hkmp_weapon}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function give_weapon(nDetailId)
    -- Add the chosen weapon
    AddGoldItem(0, nDetailId)
    
    -- Set task to prevent receiving again
    SetTask(3027, 1)
    
    Talk(1, "", "Chuc mung ban da nhan bo trang bi An Bang va vu khi Hoang Kim Mon Phai thanh cong!")
end

---------------------- Gia Nhap Mon Phai Tan Thu (New)-------------------------
function change_phai_tanthu()
    local szTitle = "Xin chao! Dai hiep muon gia nhap phai nao?"
    local tbOpt= {}
    local tbFacName = tbFacDef.tbFacShortName
    for i = 0, getn(tbFacName) do
            tinsert(tbOpt, {tbFacName[i], joinMonphaiTanthu, {i}})
    end
    tinsert(tbOpt, {"Lat nua quay lai"});
    CreateNewSayEx(szTitle, tbOpt)
end

function joinMonphaiTanthu(nIndex)
    local CurFaction = GetLastFactionNumber() 
    if nIndex == CurFaction then
            Msg2Player("Hien tai ban dang o mon phai nay")
            return 1;
    end
    
    -- Xoa ky nang mon phai cu
    local curFacNames = tbFacDef.tbFacNames[CurFaction]
    local fname = tbFacDef.tbFacChNames[CurFaction]
    if curFacNames ~= nil then
            local curFacNumber = tbFacDef.tbFacName2FacId[curFacNames]
            local curTaskId_Fact = tbFacDef.tbFacTaskIds[CurFaction]
            SetTask(curTaskId_Fact, 0)
            for i = 10, 120, 10 do
                    DelFacSkill(curFacNumber, i)
            end
            local szMsg = format("Da xoa tat ca ky nang cua %s", fname)
            Msg2Player(szMsg)
    end
    RollbackSkill()
    local nTotalSkillPoint = GetLevel() - 1
    local nCurSkillPoint = GetMagicPoint()
    local nDelta = nTotalSkillPoint - nCurSkillPoint
    if (nDelta ~= 0) then
            AddMagicPoint(nDelta)
    end
    
    -- Gia nhap mon phai moi
    local FacNames = tbFacDef.tbFacNames[nIndex]
    local FacNumber = tbFacDef.tbFacName2FacId[FacNames]
    local FacSeries = tbFacDef.tbSeriess[nIndex]
    local Camps = tbFacDef.tbCamps[nIndex]
    local RankIds = tbFacDef.tbRankIds[nIndex]
    local TaskId_Fact = tbFacDef.tbFacTaskIds[nIndex]
    local TaskId_137s = tbFacDef.tbTaskId_137s[nIndex]
    local Value_137s = tbFacDef.tbValue_137s[nIndex]
    local name = format("%s", GetName())
    local JoinMsgs = format(tbFacDef.tbJoinMsgs[nIndex], name)
    
    SetSeries(FacSeries)
    SetTask(TaskId_Fact, 60*256) -- Set lam nhiem vu xuat su
    SetFaction(FacNames) 
    SetCamp(Camps)
    SetCurCamp(Camps)
    SetRank(RankIds)
    SetTask(TaskId_137s, Value_137s)
    SetLastFactionNumber(FacNumber)
    
    -- Chi nhan ky nang toi cap 60
    for i = 10, 60, 10 do
            AddFacSkill(FacNumber, i)
    end
    if DoClearPropCore then DoClearPropCore() end
    Msg2SubWorld(JoinMsgs)
    KickOutSelf()
end
