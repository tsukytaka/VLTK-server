SimCityLienDau = SimCityLienDau or {}

-- Lien Dau maps are not part of SimCityMap.  SimCitizen still expects the
-- runtime world object to contain these fields while scanning nearby players.
-- Keep one small shared world record per arena instead of the empty table
-- returned by SimCityWorld:Get for an unknown map.
function SimCityLienDau:GetWorldInfo(mapId, x, y)
    self.worldInfos = self.worldInfos or {}
    local worldInfo = self.worldInfos[mapId]
    if not worldInfo then
        worldInfo = {
            worldId = mapId,
            name = "Lien Dau",
            allowFighting = 1,
            cityPeace = 0,
            showFightingArea = 0,
            showName = 1,
            playerTracker = {},
            playerTrackerCount = 0,
            nodes = {},
            attractions = {},
            attractionNodes = {},
            presetPaths = {},
            firstNode = {x, y},
        }
        self.worldInfos[mapId] = worldInfo
    end
    return worldInfo
end

-- Bot dau truong phai CHU DONG nham nguoi choi khac phe. Duong aggro goc
-- (sim.movement IsActive) chi set isPlayerEnemyAround khi SIMBOT_AGGRO_PLAYER == 1,
-- ma co do khong duoc dinh nghia o dau -> bot chi biet danh tra khi bi danh.
function SimCityLienDau:AggroNearestPlayer(fighter)
    if not GetNpcAroundPlayerList then return 0 end
    if not fighter.finalIndex or fighter.finalIndex <= 0 then return 0 end
    if fighter.isPlayerEnemyAround and fighter.isPlayerEnemyAround > 0 then return 1 end

    local scanRadius = fighter.RADIUS_FIGHT_PLAYER or 15
    local players, playerCount = GetNpcAroundPlayerList(fighter.finalIndex, scanRadius)
    if not playerCount then return 0 end
    local index = 1
    while index <= playerCount do
        local playerId = players[index]
        local playerCamp = CallPlayerFunction(playerId, GetCurCamp)
        if IsAttackableCamp(playerCamp, fighter.camp) == 1 then
            fighter.isPlayerEnemyAround = playerId
            return 1
        end
        index = index + 1
    end
    return 0
end

function SimCityLienDau.CombatIsActive(movementSelf, simInstance, fighter)
    local result = SimCityLienDau.originalMovementIsActive(movementSelf, simInstance, fighter)
    if fighter and fighter.liendauCombatManaged == 1 then
        fighter.isActive = 1
        SimCityLienDau:AggroNearestPlayer(fighter)
        return 1
    end
    return result
end

-- A Lien Dau fighter must choose the real opposing player before any ambient
-- NPC in the arena.  The generic Citizen.Move only gives players a 25 percent
-- priority, which lets arena/referee NPCs steal the target.
function SimCityLienDau.CombatMove(movementSelf, simInstance, fighter)
    if fighter and fighter.liendauCombatManaged == 1
       and fighter.isFighting == 0
       and fighter.isPlayerEnemyAround and fighter.isPlayerEnemyAround > 0 then
        if fighter.fightSys:TriggerFightWithPlayer(simInstance, fighter) == 1 then
            return 1
        end
    end
    return SimCityLienDau.originalMovementMove(movementSelf, simInstance, fighter)
end

function SimCityLienDau.CombatCanFight(fighter)
    local result = SimCityLienDau.originalCanFight(fighter)
    if result ~= 0 or not fighter or fighter.liendauCombatManaged ~= 1 then return result end

    local worldInfo = fighter.worldInfo
    if not worldInfo then return 0 end
    if SIMBOT_NOFIGHT_MAPS and fighter.nMapId and SIMBOT_NOFIGHT_MAPS[fighter.nMapId] then return 0 end
    if worldInfo.cityPeace == 1 and fighter.finalIndex and fighter.finalIndex > 0 then
        local x, y = GetNpcPos(fighter.finalIndex)
        if SimCityIsInCity(worldInfo, x / 32, y / 32) == 1 then return 0 end
    end
    -- Arena maps are not registered in SimCityWorld, so worldInfo.allowFighting is nil
    -- there; combat-managed fighters may always fight outside no-fight/city-peace areas.
    return 1
end

function SimCityLienDau.CombatTriggerFightWithNPC(fightSelf, simInstance, fighter)
    if not fighter or fighter.liendauCombatManaged ~= 1 or fighter.isPlayerFighting ~= 0 then
        return SimCityLienDau.originalTriggerFightWithNPC(fightSelf, simInstance, fighter)
    end

    local originalPlayerFighting = fighter.isPlayerFighting
    fighter.isPlayerFighting = 1
    local callOk, result = pcall(
        SimCityLienDau.originalTriggerFightWithNPC,
        fightSelf,
        simInstance,
        fighter
    )
    fighter.isPlayerFighting = originalPlayerFighting
    if not callOk then error(result) end
    return result
end

function SimCityLienDau.MovementResetPos(movementSelf, simInstance, nListId)
    local fighter = simInstance.fighterList[nListId]
    if fighter and (fighter.liendauHallManaged == 1 or fighter.liendauCombatManaged == 1)
       and type(fighter.goX32) == "number" and type(fighter.goY32) == "number"
       and fighter.goX32 > 0 and fighter.goY32 > 0 then
        -- Lien Dau maps carry no SimCity walk graph; nPosId must stay nil so that
        -- CreateChar and Move fall back to goX32/goY32 without touching worldInfo.nodes.
        fighter.nPosId = nil
        fighter.liendauResetPosDone = 1
        return 1
    end
    local result = SimCityLienDau.originalMovementResetPos(movementSelf, simInstance, nListId)
    if fighter and result == 1 then fighter.liendauResetPosDone = 1 end
    return result
end

function SimCityLienDau:InstallMovementGates()
    if SimMovement and SimMovement.Citizen and SimMovement.Citizen.resetPos
       and SimMovement.Citizen.resetPos ~= self.MovementResetPos then
        self.originalMovementResetPos = SimMovement.Citizen.resetPos
        SimMovement.Citizen.resetPos = self.MovementResetPos
    end
end

function SimCityLienDau:InstallCombatGates()
    if SimMovement and SimMovement.Citizen and SimMovement.Citizen.IsActive
       and SimMovement.Citizen.IsActive ~= self.CombatIsActive then
        self.originalMovementIsActive = SimMovement.Citizen.IsActive
        SimMovement.Citizen.IsActive = self.CombatIsActive
    end
    if SimMovement and SimMovement.Citizen and SimMovement.Citizen.Move
       and SimMovement.Citizen.Move ~= self.CombatMove then
        self.originalMovementMove = SimMovement.Citizen.Move
        SimMovement.Citizen.Move = self.CombatMove
    end
    if SimCityCanFight and SimCityCanFight ~= self.CombatCanFight then
        self.originalCanFight = SimCityCanFight
        SimCityCanFight = self.CombatCanFight
    end
    if SimFight and SimFight.Citizen and SimFight.Citizen.TriggerFightWithNPC
       and SimFight.Citizen.TriggerFightWithNPC ~= self.CombatTriggerFightWithNPC then
        self.originalTriggerFightWithNPC = SimFight.Citizen.TriggerFightWithNPC
        SimFight.Citizen.TriggerFightWithNPC = self.CombatTriggerFightWithNPC
    end
end

function SimCityLienDau:Count(values)
    local count = 0
    if not values then return count end
    while values[count + 1] do count = count + 1 end
    return count
end

function SimCityLienDau:BeginSpawn()
    self.nextSpawnToken = (self.nextSpawnToken or 0) + 1
    local removedCount = self:Count(SimCitizen.removedIds)
    local expectedListId = SimCitizen.counter
    local reusedId = 0
    if removedCount > 0 then
        expectedListId = SimCitizen.removedIds[removedCount]
        reusedId = 1
    end
    return {
        token = "liendau:" .. tostring(self.nextSpawnToken),
        expectedListId = expectedListId,
        reusedId = reusedId,
        counter = SimCitizen.counter,
        totalFighters = SimCitizen.totalFighters,
        removedCount = removedCount,
    }
end

function SimCityLienDau:RestoreFailedSpawn(spawnState)
    local fighter = SimCitizen.fighterList and SimCitizen.fighterList[spawnState.expectedListId]
    if fighter and fighter.liendauSpawnToken == spawnState.token and SimCitizen.Remove then
        SimCitizen:Remove(spawnState.expectedListId)
    end

    if type(spawnState.counter) == "number" then SimCitizen.counter = spawnState.counter end
    if type(spawnState.totalFighters) == "number" then
        SimCitizen.totalFighters = spawnState.totalFighters
    end
    if SimCitizen.removedIds then
        local clearIndex = spawnState.removedCount + 1
        while SimCitizen.removedIds[clearIndex] do
            SimCitizen.removedIds[clearIndex] = nil
            clearIndex = clearIndex + 1
        end
        if spawnState.reusedId == 1 then
            SimCitizen.removedIds[spawnState.removedCount] = spawnState.expectedListId
        end
    end
end

function SimCityLienDau:DescribeSpawnFailure(config, spawnState)
    local fighter = SimCitizen.fighterList and SimCitizen.fighterList[spawnState.expectedListId]
    if not fighter or fighter.liendauSpawnToken ~= spawnState.token then
        return "worldInfo nil for map " .. tostring(config.nMapId)
    end
    if fighter.liendauResetPosDone ~= 1 then
        return "resetPos failed on map " .. tostring(config.nMapId)
            .. " (no walk graph; movement gate inactive)"
    end
    if not fighter.finalIndex or fighter.finalIndex <= 0 then
        return "CreateChar failed npcId=" .. tostring(config.nNpcId)
            .. " map=" .. tostring(config.nMapId)
            .. " pos=" .. tostring(config.goX) .. "," .. tostring(config.goY)
    end
    return "ownership token mismatch listId=" .. tostring(spawnState.expectedListId)
end

function SimCityLienDau:SpawnConfig(config, failureMessage)
    self:InstallMovementGates()
    local spawnState = self:BeginSpawn()
    config.liendauSpawnToken = spawnState.token
    local listId = SimCitizen:New(config)
    local fighter = listId and SimCitizen.fighterList and SimCitizen.fighterList[listId]
    -- The current SimCity watchdog keeps a failed CreateChar in its retry
    -- queue and returns a list id. Lien Dau needs an immediately live NPC;
    -- otherwise the hall/combat registry would own a ghost slot.
    if not fighter or fighter.liendauSpawnToken ~= spawnState.token
       or not fighter.finalIndex or fighter.finalIndex <= 0 then
        local failureDetail = self:DescribeSpawnFailure(config, spawnState)
        self:RestoreFailedSpawn(spawnState)
        return nil, failureMessage .. " [" .. failureDetail .. "]"
    end
    fighter.liendauSpawnToken = nil
    fighter.liendauResetPosDone = nil
    return listId
end

function SimCityLienDau:GetNpcId(member)
    if member and member.nNpcId then return member.nNpcId end
    -- Dung pool 2000-2023 giong bot Tong Kim (template hinh nguoi choi);
    -- tron theo doi + slot de cac bot khong trung mot khuon mat.
    local teamSeed = 0
    local memberSlot = 1
    if member and member.liendauTeamId then teamSeed = -member.liendauTeamId end
    if teamSeed < 0 then teamSeed = 0 end
    if member and member.liendauMemberSlot then
        memberSlot = member.liendauMemberSlot
    elseif member and member.sourceMember then
        memberSlot = member.sourceMember
    end
    return 2000 + mod(teamSeed * 3 + memberSlot, 24)
end

function SimCityLienDau:GetOpponentMissionCamp(missionCamp)
    if type(missionCamp) ~= "number" then return nil end
    if mod(missionCamp, 2) == 0 then return missionCamp - 1 end
    return missionCamp + 1
end

function SimCityLienDau:GetCombatCamp(missionCamp)
    if type(missionCamp) ~= "number" then return nil end
    return mod(missionCamp, 2) + 2
end

function SimCityLienDau:GetName(member)
    if member and member.szName then return member.szName end
    local teamId = 0
    local memberSlot = 1
    if member and member.liendauTeamId then teamId = member.liendauTeamId end
    if member and member.liendauMemberSlot then memberSlot = member.liendauMemberSlot end
    return "Lien Dau Bot " .. tostring(-teamId) .. "-" .. tostring(memberSlot)
end

function SimCityLienDau:SpawnHallMember(member, mapId, x, y)
    if type(member) ~= "table" then return nil, "invalid Lien Dau member" end
    if not SimCitizen or not SimCitizen.New then return nil, "SimCitizen is unavailable" end
    if type(mapId) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
        return nil, "invalid hall spawn position"
    end

    local config = {
        nNpcId = self:GetNpcId(member),
        nMapId = mapId,
        goX = x,
        goY = y,
        goX32 = x * 32,
        goY32 = y * 32,
        szName = self:GetName(member),
        mode = "liendau_hall",
        camp = 0,
        walkMode = "random",
        walkVar = 1,
        ngoaitrang = 1,
        kind = 4,
        noStop = 0,
        noRevive = 0,
        isAttackable = 0,
        CHANCE_ATTACK_PLAYER = 0,
        CHANCE_ATTACK_NPC = 0,
        CHANCE_JOIN_FIGHT = 0,
        sourceMember = member.sourceMember,
        strengthProfile = member.strengthProfile,
        level = member.level or (member.strengthProfile and member.strengthProfile.level),
        faction = member.faction,
        series = member.series,
        nSettingsIdx = member.nSettingsIdx,
        skillCastBua = member.skillCastBua,
        worldInfo = self:GetWorldInfo(mapId, x, y),
        liendauSessionId = member.liendauSessionId,
        liendauTeamId = member.liendauTeamId,
        liendauMemberSlot = member.liendauMemberSlot,
        liendauHallManaged = 1,
        isCombatBot = 0,
    }
    return self:SpawnConfig(config, "SimCitizen hall spawn failed")
end

function SimCityLienDau:SpawnCombatMember(member, missionCamp, mapId, x, y)
    if type(member) ~= "table" then return nil, "invalid Lien Dau member" end
    if not SimCitizen or not SimCitizen.New then return nil, "SimCitizen is unavailable" end
    if type(missionCamp) ~= "number" or type(mapId) ~= "number"
       or type(x) ~= "number" or type(y) ~= "number" then
        return nil, "invalid combat spawn position"
    end
    self:InstallCombatGates()

    local opponentCamp = member.liendauOpponentCamp
    if not opponentCamp then opponentCamp = self:GetOpponentMissionCamp(missionCamp) end
    local config = {
        nNpcId = self:GetNpcId(member),
        nMapId = mapId,
        goX = x,
        goY = y,
        goX32 = x * 32,
        goY32 = y * 32,
        szName = self:GetName(member),
        mode = "chiendau",
        camp = self:GetCombatCamp(missionCamp),
        walkMode = "random",
        walkVar = 1,
        ngoaitrang = 1,
        kind = 0,
        noStop = 1,
        leaveFightWhenNoEnemy = 5,
        noRevive = 1,
        isAttackable = 1,
        CHANCE_ATTACK_PLAYER = 1,
        CHANCE_ATTACK_NPC = 1,
        CHANCE_JOIN_FIGHT = 1,
        RADIUS_FIGHT_PLAYER = 15,
        RADIUS_FIGHT_NPC = 15,
        RADIUS_FIGHT_SCAN = 15,
        TIME_FIGHTING_minTs = 1800,
        TIME_FIGHTING_maxTs = 3000,
        TIME_RESTING_minTs = 0,
        TIME_RESTING_maxTs = 1,
        sourceMember = member.sourceMember,
        strengthProfile = member.strengthProfile,
        level = member.level or (member.strengthProfile and member.strengthProfile.level),
        faction = member.faction,
        series = member.series,
        nSettingsIdx = member.nSettingsIdx,
        skillCastBua = member.skillCastBua,
        worldInfo = self:GetWorldInfo(mapId, x, y),
        liendauSessionId = member.liendauSessionId,
        liendauTeamId = member.liendauTeamId,
        liendauMemberSlot = member.liendauMemberSlot,
        liendauPairId = member.liendauPairId,
        liendauMissionCamp = missionCamp,
        liendauOpponentCamp = opponentCamp,
        liendauCombatManaged = 1,
        isCombatBot = 1,
    }
    local listId, spawnError = self:SpawnConfig(config, "SimCitizen combat spawn failed")
    if not listId then return nil, spawnError end
    return listId
end
