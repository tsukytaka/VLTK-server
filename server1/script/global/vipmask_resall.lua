VIP_MASK_RES_SKILL_ID = 1490
VIP_MASK_RES_TIMER_INTERVAL = 18
VIP_MASK_RES_DURATION = 279936000
VIP_MASK_RES_TIMERS = VIP_MASK_RES_TIMERS or {}
VIP_MASK_RES_ACTIVE = VIP_MASK_RES_ACTIVE or {}

function VipMaskRes_IsEquipped()
    local tbEquip = GetAllEquipment()
    if tbEquip == nil then
        return 0
    end

    -- This CTC build exposes the mask at one-based equipment entry 12.
    local nItemIndex = tbEquip[12]
    if nItemIndex == nil or nItemIndex <= 0 then
        return 0
    end

    local nGenre, nDetail, nParticular = GetItemProp(nItemIndex)
    if nGenre == 0 and nDetail == 11 and nParticular == 592 then
        return 1
    end
    return 0
end

function VipMaskRes_Refresh(nPlayerIndex)
    if VipMaskRes_IsEquipped() == 1 then
        if VIP_MASK_RES_ACTIVE[nPlayerIndex] ~= 1 or
           GetSkillState(VIP_MASK_RES_SKILL_ID) < 0 then
            AddSkillState(VIP_MASK_RES_SKILL_ID, 1, 0,
                          VIP_MASK_RES_DURATION)
        end
        VIP_MASK_RES_ACTIVE[nPlayerIndex] = 1
    else
        if VIP_MASK_RES_ACTIVE[nPlayerIndex] == 1 or
           GetSkillState(VIP_MASK_RES_SKILL_ID) >= 0 then
            RemoveSkillState(VIP_MASK_RES_SKILL_ID)
        end
        VIP_MASK_RES_ACTIVE[nPlayerIndex] = nil
    end
end

function VipMaskRes_Monitor(nPlayerIndex, nTimerId)
    if nPlayerIndex == nil or nPlayerIndex <= 0 then
        return 0, 0
    end

    local nCurrentTimer = VIP_MASK_RES_TIMERS[nPlayerIndex]
    if nTimerId ~= nil and nTimerId > 0 and
       nCurrentTimer ~= nil and nCurrentTimer > 0 and
       nCurrentTimer ~= nTimerId then
        return 0, 0
    end
    if nTimerId ~= nil and nTimerId > 0 then
        VIP_MASK_RES_TIMERS[nPlayerIndex] = nTimerId
    end

    local nOldPlayerIndex = PlayerIndex
    PlayerIndex = nPlayerIndex
    local szName = GetName()
    if szName == nil or szName == "" then
        VIP_MASK_RES_TIMERS[nPlayerIndex] = nil
        VIP_MASK_RES_ACTIVE[nPlayerIndex] = nil
        PlayerIndex = nOldPlayerIndex
        return 0, 0
    end

    VipMaskRes_Refresh(nPlayerIndex)
    PlayerIndex = nOldPlayerIndex
    return VIP_MASK_RES_TIMER_INTERVAL, nPlayerIndex
end

function VipMaskRes_Start()
    local nPlayerIndex = PlayerIndex
    local nOldTimer = VIP_MASK_RES_TIMERS[nPlayerIndex]
    if nOldTimer ~= nil and nOldTimer > 0 then
        DelTimer(nOldTimer)
    end

    VipMaskRes_Refresh(nPlayerIndex)
    VIP_MASK_RES_TIMERS[nPlayerIndex] =
        AddTimer(VIP_MASK_RES_TIMER_INTERVAL, "VipMaskRes_Monitor", nPlayerIndex)
end
