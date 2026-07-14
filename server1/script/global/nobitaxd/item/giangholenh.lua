Include("\\script\\lib\\common.lua")
Include("\\script\\global\\nobitaxd\\item\\faction_def.lua")
Include("\\script\\dailogsys\\dailogsay.lua")

function main()
    local szTitle = "Giang Ho Lenh - Ho tro gia nhap mon phai va nhan skill\n" ..
                    "Nhan vat: <color=green>" .. GetName() .. "</color>"
    local tbOpt = {
        {"Gia nhap mon phai (Nhan skill 60)", change_phai_tanthu},
        {"Thoat"}
    }
    CreateNewSayEx(szTitle, tbOpt)
    return 1
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
