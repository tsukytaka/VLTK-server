WllsBotCombat = WllsBotCombat or {
    pairs = {},
    spawnMember = nil,
}

function WllsBotCombat:Count(values)
    local count = 0
    if not values then return count end
    while values[count + 1] do count = count + 1 end
    return count
end

function WllsBotCombat:Append(values, value)
    values[self:Count(values) + 1] = value
end

function WllsBotCombat:GetSidePositions(positions, side)
    if not positions then return nil end
    if positions[side] then return positions[side] end
    if side == "left" and positions[1] then return positions[1] end
    if side == "right" and positions[2] then return positions[2] end
    if positions.x or type(positions[1]) == "number" then return positions end
    return nil
end

function WllsBotCombat:GetPosition(positions, side, memberSlot)
    local sidePositions = self:GetSidePositions(positions, side)
    if not sidePositions then return nil, nil end

    local memberPosition = sidePositions[memberSlot]
    if type(memberPosition) == "table" then
        return memberPosition.x or memberPosition[1], memberPosition.y or memberPosition[2]
    end

    local x = sidePositions.x or sidePositions[1]
    local y = sidePositions.y or sidePositions[2]
    if type(x) ~= "number" or type(y) ~= "number" then return nil, nil end
    return x + memberSlot - 1, y
end

function WllsBotCombat:BuildMember(member, sessionId, pairId, teamId, memberSlot, opponentCamp)
    return {
        nNpcId = member.nNpcId,
        szName = member.szName,
        sourceMember = member.sourceMember,
        strengthProfile = member.strengthProfile,
        level = member.level,
        faction = member.faction,
        series = member.series,
        nSettingsIdx = member.nSettingsIdx,
        skillCastBua = member.skillCastBua,
        liendauSessionId = sessionId,
        liendauTeamId = teamId,
        liendauMemberSlot = memberSlot,
        liendauPairId = pairId,
        liendauOpponentCamp = opponentCamp,
    }
end

function WllsBotCombat:SpawnCombatMember(member, missionCamp, mapId, x, y)
    if self.spawnMember then return self.spawnMember(self, member, missionCamp, mapId, x, y) end
    if SimCityLienDau and SimCityLienDau.SpawnCombatMember then
        return SimCityLienDau:SpawnCombatMember(member, missionCamp, mapId, x, y)
    end
    return nil, "SimCityLienDau is unavailable"
end

function WllsBotCombat:Rollback(sessionId, pairId, createdIds)
    local removedCount = 0
    local createdIndex = 1
    while createdIds and createdIds[createdIndex] do
        local listId = createdIds[createdIndex]
        local fighter = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[listId]
        if fighter and fighter.liendauSessionId == sessionId and fighter.liendauPairId == pairId
           and fighter.liendauCombatManaged == 1 and SimCitizen.Remove then
            SimCitizen:Remove(listId)
            removedCount = removedCount + 1
        end
        createdIndex = createdIndex + 1
    end
    return removedCount
end

function WllsBotCombat:SpawnEntry(sessionId, pair, entry, missionCamp, opponentCamp, mapId, positions, side, createdIds)
    if not entry or entry.kind ~= "bot" then return 1 end
    local members = entry.members
    local teamId = entry.id
    if entry.team then
        members = entry.team.members
        teamId = entry.team.id
    end
    if not members or not members[1] then return 0, "bot entry has no members" end

    local memberSlot = 1
    while members[memberSlot] do
        local x, y = self:GetPosition(positions, side, memberSlot)
        if type(x) ~= "number" or type(y) ~= "number" then
            return 0, "missing " .. side .. " position for member " .. tostring(memberSlot)
        end
        local spawnMember = self:BuildMember(
            members[memberSlot],
            sessionId,
            pair.id,
            teamId,
            memberSlot,
            opponentCamp
        )
        local listId, spawnError = self:SpawnCombatMember(spawnMember, missionCamp, mapId, x, y)
        local fighter = listId and SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[listId]
        if not fighter then
            if not spawnError then spawnError = "spawned fighter is missing" end
            return 0, side .. " member " .. tostring(memberSlot) .. ": " .. tostring(spawnError)
        end
        self:Append(createdIds, listId)
        memberSlot = memberSlot + 1
    end
    return 1
end

function WllsBotCombat:IsLiveRecord(record, sessionId, pair, leftCamp, rightCamp, mapId)
    if not record or record.sessionId ~= sessionId or record.pair ~= pair
       or record.leftCamp ~= leftCamp or record.rightCamp ~= rightCamp
       or record.mapId ~= mapId then return 0 end

    local requiredBotCount = record.requiredBotCount or self:Count(record.botIds)
    if self:Count(record.botIds) ~= requiredBotCount then return 0 end
    local botIndex = 1
    while botIndex <= requiredBotCount do
        local listId = record.botIds[botIndex]
        local fighter = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[listId]
        if not fighter or fighter.liendauSessionId ~= sessionId or fighter.liendauPairId ~= pair.id
           or fighter.liendauCombatManaged ~= 1 then return 0 end
        botIndex = botIndex + 1
    end
    return 1
end

function WllsBotCombat:StartPair(sessionId, pair, leftCamp, rightCamp, mapId, positions)
    if not pair or not pair.id or not pair.left or not pair.right then
        return 0, "invalid Lien Dau pair"
    end
    local existingRecord = self.pairs[pair.id]
    if existingRecord then
        if self:IsLiveRecord(existingRecord, sessionId, pair, leftCamp, rightCamp, mapId) == 1 then
            pair.combatBotIds = existingRecord.botIds
            pair.state = "active"
            return 1
        end
        if existingRecord.pair == pair and existingRecord.sessionId == sessionId then
            self:CleanupPair(pair.id, "stale_record")
        end
        pair.combatBotIds = nil
        pair.state = "queued"
        return 0, "stale or conflicting Lien Dau pair id"
    end

    local createdIds = {}
    local leftStarted, leftError = self:SpawnEntry(
        sessionId,
        pair,
        pair.left,
        leftCamp,
        rightCamp,
        mapId,
        positions,
        "left",
        createdIds
    )
    if leftStarted ~= 1 then
        self:Rollback(sessionId, pair.id, createdIds)
        pair.state = "queued"
        pair.combatBotIds = nil
        return 0, leftError
    end

    local rightStarted, rightError = self:SpawnEntry(
        sessionId,
        pair,
        pair.right,
        rightCamp,
        leftCamp,
        mapId,
        positions,
        "right",
        createdIds
    )
    if rightStarted ~= 1 then
        self:Rollback(sessionId, pair.id, createdIds)
        pair.state = "queued"
        pair.combatBotIds = nil
        return 0, rightError
    end

    local botHP = {}
    local botCamp = {}
    local snapshotIndex = 1
    while createdIds[snapshotIndex] do
        local listId = createdIds[snapshotIndex]
        local fighter = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[listId]
        local maxLife = fighter and fighter.maxHP
        if not maxLife and fighter and fighter.finalIndex and fighter.finalIndex > 0
           and NPCINFO_GetNpcCurrentMaxLife then
            maxLife = NPCINFO_GetNpcCurrentMaxLife(fighter.finalIndex)
        end
        botHP[listId] = maxLife or 0
        botCamp[listId] = fighter and fighter.liendauMissionCamp
        snapshotIndex = snapshotIndex + 1
    end

    local record = {
        sessionId = sessionId,
        pairId = pair.id,
        pair = pair,
        leftCamp = leftCamp,
        rightCamp = rightCamp,
        mapId = mapId,
        botIds = createdIds,
        botHP = botHP,
        botCamp = botCamp,
        requiredBotCount = self:Count(createdIds),
    }
    self.pairs[pair.id] = record
    pair.combatBotIds = createdIds
    pair.leftCamp = leftCamp
    pair.rightCamp = rightCamp
    pair.mapId = mapId
    pair.state = "active"
    return 1
end

function WllsBotCombat:GetSideCamp(record, side)
    if side == "left" then return record.leftCamp end
    if side == "right" then return record.rightCamp end
    return nil
end

function WllsBotCombat:AliveCount(pairId, side)
    local record = self.pairs[pairId]
    if not record then return 0 end
    local sideCamp = self:GetSideCamp(record, side)
    if not sideCamp then return 0 end

    local aliveCount = 0
    local botIndex = 1
    while record.botIds[botIndex] do
        local listId = record.botIds[botIndex]
        local recordedCamp = (record.botCamp and record.botCamp[listId]) or nil
        local fighter = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[listId]
        if fighter and fighter.liendauPairId == pairId
           and (recordedCamp == sideCamp or fighter.liendauMissionCamp == sideCamp)
           and fighter.isDead ~= 1 then
            aliveCount = aliveCount + 1
        end
        botIndex = botIndex + 1
    end
    return aliveCount
end

function WllsBotCombat:DamageTaken(pairId, side)
    local record = self.pairs[pairId]
    if not record then return 0 end
    local sideCamp = self:GetSideCamp(record, side)
    if not sideCamp then return 0 end

    local damageTotal = 0
    local botIndex = 1
    while record.botIds[botIndex] do
        local listId = record.botIds[botIndex]
        local startLife = (record.botHP and record.botHP[listId]) or 0
        local fighter = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[listId]
        local sideMatches = 0
        if record.botCamp and record.botCamp[listId] == sideCamp then
            sideMatches = 1
        elseif fighter and fighter.liendauMissionCamp == sideCamp then
            sideMatches = 1
        end
        if sideMatches == 1 then
            local currentLife = 0
            if fighter and fighter.liendauPairId == pairId and fighter.isDead ~= 1
               and fighter.finalIndex and fighter.finalIndex > 0
               and NPCINFO_GetNpcCurrentLife then
                currentLife = NPCINFO_GetNpcCurrentLife(fighter.finalIndex) or 0
            end
            if currentLife > startLife then currentLife = startLife end
            damageTotal = damageTotal + (startLife - currentLife)
        end
        botIndex = botIndex + 1
    end
    return damageTotal
end

function WllsBotCombat:CleanupPair(pairId, reason)
    local record = self.pairs[pairId]
    if not record then return 0 end
    local removedCount = self:Rollback(record.sessionId, pairId, record.botIds)
    if record.pair then
        record.pair.combatBotIds = nil
        record.pair.cleanupReason = reason
        record.pair.state = "cleaned"
    end
    self.pairs[pairId] = nil
    return removedCount
end
