Include("\\script\\lib\\common.lua")
Include("\\script\\global\\nobitaxd\\item\\faction_def.lua")
Include("\\script\\dailogsys\\dailogsay.lua")

function main()
    local szTitle = "Giang Ho Lenh - Ho tro gia nhap mon phai va nhan skill\\n" ..
                    "Nhan vat: <color=green>" .. GetName() .. "</color>"
    local tbOpt = {
        {"Nhan ho tro tan thu (1 Bo An Bang & 1 VK HKMP)", check_and_give_support},
        {"Gia nhap mon phai (Nhan skill 60)", change_phai_tanthu},
        {"Phan phoi diem tiem nang", menu_diemtiemnang},
        {"Phan phoi diem ky nang", menu_diemkynang},
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
    
    -- Nhan day du ky nang den cap 60 (bao gom ca chieu Tran phai cap 60/70)
    for i = 10, 70, 10 do
            AddFacSkill(FacNumber, i)
    end
    if DoClearPropCore then DoClearPropCore() end
    Msg2SubWorld(JoinMsgs)
    KickOutSelf()
end

---------------------- Phan Phoi Tiem Nang (New) -------------------------
function menu_diemtiemnang()
    local nPoints = GetProp()
    if nPoints <= 0 then
        Talk(1, "", "Ban khong co diem tiem nang nao de phan phoi!")
        return 1
    end
    
    local szTitle = "Phan phoi nhanh diem tiem nang\\n" ..
                    "Diem tiem nang hien tai: <color=yellow>" .. nPoints .. "</color> diem.\\n" ..
                    "Hay chon phuong thuc phan phoi:"
                    
    local tbOpt = {
        {"Tang Suc Manh (Str)", select_stat_points, {"str"}},
        {"Tang Than Phap (Dex)", select_stat_points, {"dex"}},
        {"Tang Ngoai Cong (Vit)", select_stat_points, {"vit"}},
        {"Tang Noi Cong (Eng)", select_stat_points, {"eng"}},
        {"Quay lai", main},
        {"Thoat"}
    }
    CreateNewSayEx(szTitle, tbOpt)
end

function select_stat_points(stat)
    local nPoints = GetProp()
    if nPoints <= 0 then
        Talk(1, "", "Ban khong co diem tiem nang!")
        return 1
    end
    
    local statName = ""
    if stat == "str" then statName = "Suc Manh"
    elseif stat == "dex" then statName = "Than Phap"
    elseif stat == "vit" then statName = "Ngoai Cong"
    elseif stat == "eng" then statName = "Noi Cong"
    end
    
    local szTitle = "Phan phoi vao: " .. statName .. "\\n" ..
                    "Diem tiem nang hien co: " .. nPoints .. "\\n" ..
                    "Nhap so diem muon cong:"
                    
    g_AskClientNumberEx(nPoints, nPoints, szTitle, {apply_stat_points, {stat}})
end

function apply_stat_points(stat, nCount)
    nCount = tonumber(nCount) or 0
    local nPoints = GetProp()
    if nCount <= 0 or nCount > nPoints then
        Talk(1, "", "So diem nhap vao khong hop le!")
        return 1
    end
    
    if stat == "str" then
        AddStrg(nCount)
    elseif stat == "dex" then
        AddDex(nCount)
    elseif stat == "vit" then
        AddVit(nCount)
    elseif stat == "eng" then
        AddEng(nCount)
    end
    
    Msg2Player("Cong thanh cong " .. nCount .. " diem tiem nang!")
    menu_diemtiemnang()
end

---------------------- Phan Phoi Ky Nang (New) -------------------------
function menu_diemkynang()
    local nFaction = GetLastFactionNumber()
    if nFaction == -1 or GetFaction() == "" then
        Talk(1, "", "Ban chua gia nhap mon phai!")
        return 1
    end
    
    local nPoints = GetMagicPoint()
    if nPoints <= 0 then
        Talk(1, "", "Ban khong co diem ky nang nao de phan phoi!")
        return 1
    end
    
    local faction_skills = {
        [0] = {10, 14, 4, 6, 8, 15, 16, 20, 11, 19, 271, 21, 273}, -- Thieu Lam
        [1] = {29, 30, 34, 23, 24, 26, 33, 31, 35, 37, 40, 42, 32, 36, 41, 324}, -- Thien Vuong
        [2] = {45, 43, 303, 347, 47, 50, 54, 343, 345, 349, 48, 58, 249, 341}, -- Duong Mon
        [3] = {63, 65, 60, 62, 67, 66, 70, 64, 68, 69, 384, 73, 356, 72, 71, 74, 75}, -- Ngu Doc
        [4] = {80, 85, 77, 79, 93, 82, 89, 385, 86, 92, 88, 91, 252, 282}, -- Nga My
        [5] = {99, 102, 95, 97, 269, 105, 113, 100, 109, 108, 111, 114}, -- Thuy Yen
        [6] = {119, 122, 115, 116, 129, 124, 274, 277, 125, 128, 130, 360}, -- Cai Bang
        [7] = {135, 145, 131, 132, 136, 137, 138, 140, 141, 364, 143, 142, 148, 150}, -- Thien Nhan
        [8] = {153, 155, 151, 152, 159, 158, 164, 160, 157, 165, 166, 267}, -- Vo Dang
        [9] = {169, 179, 167, 168, 171, 392, 174, 172, 173, 178, 393, 175, 181, 90, 176, 182, 275, 630} -- Con Lon
    }
    
    local skills = faction_skills[nFaction]
    if not skills then
        Talk(1, "", "Khong tim thay danh sach ky nang cua mon phai ban!")
        return 1
    end
    
    local szTitle = "Phan phoi nhanh diem ky nang\\n" ..
                    "Diem ky nang hien tai: <color=yellow>" .. nPoints .. "</color> diem.\\n" ..
                    "Hay chon ky nang muon cong diem:"
                    
    local tbOpt = {}
    for i = 1, getn(skills) do
        local skillId = skills[i]
        local curLvl = HaveMagic(skillId)
        if curLvl >= 0 then
            local maxLvl = GetSkillMaxLevel(skillId) + GetSkillMaxLevelAddons()
            if curLvl < maxLvl then
                local skillName = GetSkillName(skillId)
                tinsert(tbOpt, {skillName .. " (" .. curLvl .. "/" .. maxLvl .. ")", select_skill_points, {skillId, curLvl, maxLvl}})
            end
        end
    end
    tinsert(tbOpt, {"Quay lai", main})
    tinsert(tbOpt, {"Thoat"})
    
    CreateNewSayEx(szTitle, tbOpt)
end

function select_skill_points(skillId, curLvl, maxLvl)
    local nPoints = GetMagicPoint()
    if nPoints <= 0 then
        Talk(1, "", "Ban khong co diem ky nang!")
        return 1
    end
    
    local skillName = GetSkillName(skillId)
    local maxAddable = maxLvl - curLvl
    local limit = nPoints
    if limit > maxAddable then limit = maxAddable end
    
    local szTitle = "Ky nang: " .. skillName .. " (Cap hien tai: " .. curLvl .. "/" .. maxLvl .. ")\\n" ..
                    "Diem ky nang hien co: " .. nPoints .. "\\n" ..
                    "Nhap so diem muon cong (Toi da: " .. limit .. "):"
                    
    g_AskClientNumberEx(limit, limit, szTitle, {apply_skill_points, {skillId, curLvl, maxAddable}})
end

function apply_skill_points(skillId, curLvl, maxAddable, nCount)
    nCount = tonumber(nCount) or 0
    local nPoints = GetMagicPoint()
    if nCount <= 0 or nCount > nPoints or nCount > maxAddable then
        Talk(1, "", "So diem nhap vao khong hop le!")
        return 1
    end
    
    AddMagic(skillId, curLvl + nCount)
    AddMagicPoint(-nCount)
    
    Msg2Player("Cong " .. nCount .. " diem vao ky nang " .. GetSkillName(skillId) .. " thanh cong!")
    menu_diemkynang()
end
