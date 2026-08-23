-- Public Viem De and Translife helpers for Cam Nang Tan Thu.
-- This module deliberately has no dependency on gm_script.lua or admin auth.
IncludeLib("SETTING")
IncludeLib("PARTNER")
IncludeLib("ITEM")
Include("\\script\\lib\\remoteexc.lua")
Include("\\script\\lib\\log.lua")
Include("\\script\\global\\titlefuncs.lua")
Include("\\script\\global\\translife.lua")

StarterPublicSupport = StarterPublicSupport or {}

function StarterPublicSupport:StartViemDe()
    RemoteExc("\\script\\startmissions.lua", "ViemDe")
    Msg2Player("Da kich hoat Viem De.")
    return 1
end

function StarterPublicSupport:GiveViemDeLenh()
    if CalcFreeItemCellCount() < 1 then
        Msg2Player("Can it nhat 1 o trong.")
        return 0
    end
    local nItemIndex = AddItem(6, 1, 1617, 1, 0, 0)
    if not nItemIndex or nItemIndex <= 0 then
        Msg2Player("Khong the nhan Viem De Lenh.")
        return 0
    end
    Msg2Player("Da nhan Viem De Lenh.")
    return 1
end

function StarterPublicSupport:TransLifeError(szError)
    SetTaskTemp(198, 0)
    Msg2Player("Trung sinh that bai: "..tostring(szError))
    WriteLog(format("[StarterTransLifeError] Account:%s Name:%s Error:%s",
        GetAccount(), GetName(), tostring(szError)))
    return 0
end

function StarterPublicSupport:GetTransLifeCount()
    local nEngineTrans = 0
    if type(ST_GetTransLifeCount) == "function" then
        nEngineTrans = ST_GetTransLifeCount() or 0
    end
    local nTaskTrans = 0
    if type(zhuansheng_get_gre) == "function" then
        for i = 1, 7 do
            local nLevel = zhuansheng_get_gre(i)
            if nLevel and nLevel > 0 then nTaskTrans = i end
        end
    end
    if nTaskTrans > nEngineTrans then return nTaskTrans end
    return nEngineTrans
end

function StarterPublicSupport:ApplyTransLifeTitle(nTarget)
    if not nTarget or nTarget < 1 or nTarget > 7 then return 0 end
    if not Title_AddTitle or not Title_ActiveTitle then return 0 end
    local nTransTitleId = 5000 + nTarget
    SetTask(1122, nTransTitleId)
    Title_AddTitle(nTransTitleId, 1, 30 * 24 * 60 * 60 * 18)
    Title_ActiveTitle(nTransTitleId)
    if SyncTaskValue then SyncTaskValue(1122) end
    return 1
end

function StarterPublicSupport:CheckTransLife(nTarget)
    if type(ST_GetTransLifeCount) ~= "function" then return self:TransLifeError("thieu API ST_GetTransLifeCount") end
    if type(ST_LevelUp) ~= "function" then return self:TransLifeError("thieu API ST_LevelUp") end
    if type(ST_DoTransLife) ~= "function" then return self:TransLifeError("thieu API ST_DoTransLife") end
    if type(zhuansheng_set_gre) ~= "function" then return self:TransLifeError("thieu task_func.lua") end
    if type(zhuansheng_clear_skill) ~= "function" or type(zhuansheng_clear_prop) ~= "function" then
        return self:TransLifeError("thieu ham xu ly diem ky nang hoac tiem nang")
    end
    if type(TB_LEVEL_LIMIT) ~= "table" or type(TB_LEVEL_REMAIN_PROP) ~= "table" then
        return self:TransLifeError("thieu task_head.lua hoac translife.txt")
    end
    if not nTarget or nTarget < 1 or nTarget > 7 then
        return self:TransLifeError("muc Trung sinh phai tu 1 den 7")
    end
    local nRequiredLevel = TB_LEVEL_LIMIT[nTarget]
    if not nRequiredLevel then return self:TransLifeError("thieu cap yeu cau") end
    if not TB_LEVEL_REMAIN_PROP[nRequiredLevel]
       or not TB_LEVEL_REMAIN_PROP[nRequiredLevel][nTarget] then
        return self:TransLifeError("translife.txt thieu du lieu muc "..nTarget)
    end
    if nTarget == 4 then
        if type(TBITEMNEED_4) ~= "table" or getn(TBITEMNEED_4) < 1 then
            return self:TransLifeError("thieu cau hinh nguyen lieu Trung sinh 4")
        end
        for i = 1, getn(TBITEMNEED_4) do
            local tbItem = TBITEMNEED_4[i]
            if type(tbItem) ~= "table" or type(tbItem.tbProb) ~= "table"
               or not tbItem.tbProb[1] or not tbItem.tbProb[2]
               or not tbItem.tbProb[3] or not tbItem.nCount then
                return self:TransLifeError("cau hinh nguyen lieu Trung sinh 4 khong hop le")
            end
        end
    end
    return 1
end

function StarterPublicSupport:DoTransLifeDirect(nTarget, nRequiredLevel, nBeforeTrans)
    local tbRemain = TB_LEVEL_REMAIN_PROP[nRequiredLevel][nTarget]
    local nmgpoint, nprop, nresist, naddskill = tbRemain[1], tbRemain[2], tbRemain[3], tbRemain[4]
    LeaveTeam()
    ST_LevelUp(nRequiredLevel - GetLevel())
    local nLevel = GetLevel()
    SetTaskTemp(TSKM_ZHUANSHENG_RESISTID, 0)
    SetTask(TSK_ZHUANSHENG_FLAG, 1)
    zhuansheng_set_gre(nTarget, nLevel, 0)
    if SyncTaskValue then
        SyncTaskValue(2577)
        SyncTaskValue(2578)
        SyncTaskValue(2579)
        SyncTaskValue(2583)
        SyncTaskValue(1122)
    end
    SetTask(144, 0)
    SetRevPos(121, 55)
    zhuansheng_clear_skill(nLevel, nmgpoint)
    zhuansheng_clear_prop(nLevel, nprop)
    SetSkillMaxLevelAddons(GetSkillMaxLevelAddons() + naddskill)
    for i = 0, 4 do AddMaxResist(i, nresist) end
    ST_LevelUp(1 - nLevel)
    SetTask(TSK_ZHUANSHENG_FLAG, 0)
    SetTask(TSK_ZHUANSHENG_LASTTIME, GetCurServerTime())
    PARTNER_CallOutCurPartner(0)
    local nAfterTrans = self:GetTransLifeCount()
    WriteLog(format("[StarterTransLifeDirect] Account:%s Name:%s Target:%d Before:%d After:%d Level:%d",
        GetAccount(), GetName(), nTarget, nBeforeTrans, nAfterTrans, nLevel))
    if nAfterTrans ~= nTarget then
        return self:TransLifeError(format("trang thai khong tang (truoc=%d, sau=%d)",
            nBeforeTrans, nAfterTrans))
    end
    self:ApplyTransLifeTitle(nTarget)
    Msg2Player("Linh hoi Bac Dau Truong Sinh Thuat - Tam Phap Thien.")
    KickOutSelf()
    return 1
end

function StarterPublicSupport:DoTrungSinh(nTarget)
    if self:CheckTransLife(nTarget) ~= 1 then return 0 end
    local nTrans = self:GetTransLifeCount()
    if nTrans + 1 ~= nTarget then
        Msg2Player(format("Nhan vat dang Trung sinh %d, khong the dung muc %d.", nTrans, nTarget))
        return 0
    end
    local nRequiredLevel = TB_LEVEL_LIMIT[nTarget]
    local nBeforeTrans = nTrans
    if nTarget >= 6 then
        return self:DoTransLifeDirect(nTarget, nRequiredLevel, nBeforeTrans)
    end
    LeaveTeam()
    ST_LevelUp(nRequiredLevel - GetLevel())
    SetTaskTemp(TSKM_ZHUANSHENG_RESISTID, 0)
    SetTaskTemp(198, 1)
    SetTask(TSK_ZHUANSHENG_FLAG, 1)
    WriteLog(format("[StarterTransLife] Account:%s Name:%s Target:%d RequiredLevel:%d",
        GetAccount(), GetName(), nTarget, nRequiredLevel))
    local nResult = ST_DoTransLife()
    local nAfterTrans = self:GetTransLifeCount()
    if nAfterTrans ~= nTarget then
        return self:TransLifeError(format("trang thai khong tang (truoc=%d, sau=%d, ket qua=%s)",
            nBeforeTrans, nAfterTrans, tostring(nResult)))
    end
    self:ApplyTransLifeTitle(nTarget)
    return 1
end
