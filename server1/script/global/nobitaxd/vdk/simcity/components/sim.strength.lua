SimBotStrength = SimBotStrength or {}

SimBotStrength.ABSOLUTE_HP_MAX = 20000
SimBotStrength.VERIFIED_LEVEL_MAX = 119

function SimBotStrength:ClampInteger(value, minimum, maximum, fallback)
    if type(value) ~= "number" then value = fallback end
    if type(value) ~= "number" then value = minimum end
    value = floor(value)
    if value < minimum then value = minimum end
    if value > maximum then value = maximum end
    return value
end

function SimBotStrength:GetSafeLevel(level, fallback)
    local configuredMax = SIMBOT_SAFE_LEVEL_MAX
    if type(configuredMax) ~= "number" or configuredMax < 1 then
        configuredMax = self.VERIFIED_LEVEL_MAX
    end
    configuredMax = floor(configuredMax)
    if configuredMax > self.VERIFIED_LEVEL_MAX then
        configuredMax = self.VERIFIED_LEVEL_MAX
    end
    return self:ClampInteger(level, 1, configuredMax, fallback or 95)
end

function SimBotStrength:ResolveFaction(config)
    config = config or {}
    if not config.faction and SimCityPhai and SimCityPhai.id2phai then
        config.faction = SimCityPhai.id2phai[config.nNpcId]
    end

    local factionSeries = {
        thieulam = 0, thienvuong = 0,
        duongmon = 1, ngudoc = 1,
        ngami = 2, thuyyen = 2,
        caibang = 3, thiennhan = 3,
        vodang = 4, conlon = 4,
    }
    if config.series == nil and config.faction then
        config.series = factionSeries[config.faction]
    end

    local factionInfo = config.faction and SimCityPhai and SimCityPhai[config.faction]
    local known = factionInfo and factionInfo.knownIds and factionInfo.knownIds[config.nNpcId]
    if known then
        if known.series ~= nil then config.series = known.series end
        if known.gen == 1 then
            config.nSettingsIdx = -1
        elseif known.gen == 2 then
            config.nSettingsIdx = -2
        end
    end
    return config
end

function SimBotStrength:IsEligible(config)
    config = config or {}

    if SIMBOT_STRENGTH_ENABLED ~= 1 then return 0 end
    if config.stall == 1 or config.daTau == 1 or config.isCombatBot == 0 then return 0 end
    if config.role == "pet" then return 0 end
    if config.mode == "pet" or config.mode == "tieuthiep" then return 0 end
    if config.mode == "trangtri" or config.mode == "decorative" then return 0 end

    if config.isCombatBot == 1 then return 1 end
    if config.mode == "chiendau" or config.mode == "train" or config.mode == "keoxe" then return 1 end
    if config.role == "keoxe" then return 1 end
    return config.isAttackable == 1 and 1 or 0
end

function SimBotStrength:ValidateProfiles(profiles)
    profiles = profiles or {}
    if getn(profiles) == 0 then return 0, "strength profile list is empty" end

    local totalWeight = 0
    for i = 1, getn(profiles) do
        local profile = profiles[i]
        if type(profile) ~= "table" or type(profile.weight) ~= "number"
            or profile.weight <= 0 or floor(profile.weight) ~= profile.weight then
            return 0, "strength profile weights must be positive integers"
        end
        totalWeight = totalWeight + profile.weight

        if type(profile.minHP) ~= "number" or type(profile.maxHP) ~= "number"
            or profile.minHP < 1 or profile.maxHP < profile.minHP
            or profile.maxHP > self.ABSOLUTE_HP_MAX
            or floor(profile.minHP) ~= profile.minHP
            or floor(profile.maxHP) ~= profile.maxHP then
            return 0, "strength profile HP bounds must be sane integers capped at 20000"
        end

        if type(profile.minSkillLevel) ~= "number" or type(profile.maxSkillLevel) ~= "number"
            or profile.minSkillLevel < 1 or profile.maxSkillLevel < profile.minSkillLevel
            or profile.maxSkillLevel > 20
            or floor(profile.minSkillLevel) ~= profile.minSkillLevel
            or floor(profile.maxSkillLevel) ~= profile.maxSkillLevel then
            return 0, "strength profile skill bounds must be integer levels from 1 to 20"
        end
    end

    if totalWeight ~= 100 then
        return 0, "strength profile weights must total exactly 100"
    end
    return 1
end

function SimBotStrength:SafeDefinition(profile)
    return {
        id = profile.id,
        weight = profile.weight,
        minHP = profile.minHP,
        maxHP = profile.maxHP,
        level = SimBotStrength:GetSafeLevel(profile.level, 95),
        minSkillLevel = profile.minSkillLevel,
        maxSkillLevel = profile.maxSkillLevel,
        attackSpeed = profile.attackSpeed,
    }
end

function SimBotStrength:SelectProfile(config, roll)
    if self:IsEligible(config) ~= 1 then return nil end

    local profiles = SIMBOT_STRENGTH_PROFILES or {}
    local valid, reason = self:ValidateProfiles(profiles)
    if valid ~= 1 then error(reason) end

    roll = roll or random(1, 100)
    if type(roll) ~= "number" or roll < 1 or roll > 100 then return nil end

    local cumulative = 0
    for i = 1, getn(profiles) do
        local profile = profiles[i]
        cumulative = cumulative + profile.weight
        if roll <= cumulative then return self:SafeDefinition(profile) end
    end

    error("valid strength profile configuration did not cover selected roll")
end

function SimBotStrength:Materialize(profileDef, faction)
    if not profileDef then return nil end

    local minHP = self:ClampInteger(profileDef.minHP, 1, self.ABSOLUTE_HP_MAX, 1)
    local maxHP = self:ClampInteger(profileDef.maxHP, minHP, self.ABSOLUTE_HP_MAX, minHP)
    local midpoint = floor((minHP + maxHP) / 2)

    if faction == "thieulam" or faction == "thienvuong" then
        minHP = midpoint
    elseif faction == "duongmon" or faction == "ngudoc"
        or faction == "ngami" or faction == "thuyyen" then
        maxHP = midpoint
    end

    local minSkillLevel = self:ClampInteger(profileDef.minSkillLevel or profileDef.skillLevel, 1, 20, 20)
    local maxSkillLevel = self:ClampInteger(profileDef.maxSkillLevel or profileDef.skillLevel,
        minSkillLevel, 20, minSkillLevel)
    local materializedSkillLevel = random(minSkillLevel, maxSkillLevel)
    local materializedHP = random(minHP, maxHP)
    if materializedHP > self.ABSOLUTE_HP_MAX then materializedHP = self.ABSOLUTE_HP_MAX end

    return {
        id = profileDef.id,
        level = self:GetSafeLevel(profileDef.level, 95),
        maxHP = materializedHP,
        skillLevel = floor(materializedSkillLevel),
        attackSpeed = profileDef.attackSpeed,
    }
end

function SimBotStrength:SyncMainSkillLevel(config)
    if config and config.strengthProfile and config.skillCastBua and config.skillCastBua[1] then
        config.skillCastBua[2] = config.skillLevel
    end
end

function SimBotStrength:Apply(config, roll)
    config = config or {}
    if config.isCombatBot == 0 then
        local staleProfile = config.strengthProfile
        if staleProfile then
            if config.level == staleProfile.level then config.level = nil end
            if config.maxHP == staleProfile.maxHP then config.maxHP = nil end
            if config.skillLevel == staleProfile.skillLevel then config.skillLevel = nil end
            if config.attackSpeed == staleProfile.attackSpeed then config.attackSpeed = nil end
        end
        config.strengthProfile = nil
        return config
    end
    if config.strengthProfile then
        local profile = config.strengthProfile
        profile.level = self:GetSafeLevel(profile.level, 95)
        profile.maxHP = self:ClampInteger(profile.maxHP, 1, self.ABSOLUTE_HP_MAX, 1)
        config.level = profile.level
        config.maxHP = profile.maxHP
        config.skillLevel = profile.skillLevel
        config.attackSpeed = profile.attackSpeed
        self:SyncMainSkillLevel(config)
        return config
    end

    local profileDef = self:SelectProfile(config, roll)
    if not profileDef then return config end

    local profile = self:Materialize(profileDef, config.faction)
    if not profile then return config end

    config.strengthProfile = profile
    config.level = profile.level
    config.maxHP = profile.maxHP
    config.skillLevel = profile.skillLevel
    config.attackSpeed = profile.attackSpeed
    self:SyncMainSkillLevel(config)
    return config
end

function SimBotStrength:GetSkillLevel(tbNpc, fallback)
    tbNpc = tbNpc or {}
    return tbNpc.skillLevel or fallback or 20
end

function SimBotStrength:RestoreProfileHP(tbNpc, npcIndex)
    if not tbNpc or not tbNpc.strengthProfile then return 0 end

    local profileMaxHP = self:ClampInteger(tbNpc.strengthProfile.maxHP, 1, self.ABSOLUTE_HP_MAX, 1)
    tbNpc.strengthProfile.maxHP = profileMaxHP
    tbNpc.maxHP = profileMaxHP

    if npcIndex and npcIndex > 0 then
        if NPCINFO_SetNpcCurrentMaxLife then NPCINFO_SetNpcCurrentMaxLife(npcIndex, profileMaxHP) end
        if NPCINFO_SetMaxLife then NPCINFO_SetMaxLife(npcIndex, profileMaxHP) end
        if NPCINFO_GetNpcCurrentLife and NPCINFO_SetNpcCurrentLife then
            local currentLife = NPCINFO_GetNpcCurrentLife(npcIndex)
            if currentLife and currentLife > profileMaxHP then
                NPCINFO_SetNpcCurrentLife(npcIndex, profileMaxHP)
            end
        end
    end
    return 1
end

function SimBotStrength:ApplyRuntimeStats(tbNpc, npcIndex)
    if not npcIndex or npcIndex <= 0 then return end
    tbNpc = tbNpc or {}
    local safeLevel = self:GetSafeLevel(tbNpc.level, 95)
    if SetNpcLevel then SetNpcLevel(npcIndex, safeLevel) end
    if SetNpcAtkSpeed then SetNpcAtkSpeed(npcIndex, tbNpc.attackSpeed or 250) end
end
