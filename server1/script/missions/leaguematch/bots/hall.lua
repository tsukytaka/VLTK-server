WllsBotHall = WllsBotHall or {
    sessions = {},
    spawnMember = nil,
}

function WllsBotHall:GetBatchSize()
    local batchSize = WLLS_BOT_HALL_BATCH_SIZE
    if type(batchSize) ~= "number" or batchSize < 1 then return 1 end
    return batchSize
end

function WllsBotHall:GetReservedRadius()
    local reservedRadius = WLLS_BOT_HALL_RESERVED_RADIUS
    if type(reservedRadius) ~= "number" or reservedRadius < 0 then return 0 end
    return reservedRadius
end

function WllsBotHall:GetGridSpacing()
    local gridSpacing = WLLS_BOT_HALL_GRID_SPACING
    if type(gridSpacing) ~= "number" or gridSpacing < 1 then return 1 end
    return gridSpacing
end

function WllsBotHall:GetSession(sessionId)
    local hallSession = self.sessions[sessionId]
    if hallSession then return hallSession end
    hallSession = {
        slots = {},
    }
    self.sessions[sessionId] = hallSession
    return hallSession
end

function WllsBotHall:GetSlot(hallSession, teamId, memberSlot)
    local teamSlots = hallSession.slots[teamId]
    if not teamSlots then
        teamSlots = {}
        hallSession.slots[teamId] = teamSlots
    end
    local slot = teamSlots[memberSlot]
    if slot then return slot end
    slot = {}
    teamSlots[memberSlot] = slot
    return slot
end

function WllsBotHall:IsLiveSlot(slot, sessionId, teamId, memberSlot)
    if not slot or not slot.listId then return 0 end
    if not SimCitizen or not SimCitizen.fighterList then
        slot.listId = nil
        return 0
    end
    local fighter = SimCitizen.fighterList[slot.listId]
    if not fighter or fighter.liendauSessionId ~= sessionId or fighter.liendauTeamId ~= teamId
       or fighter.liendauMemberSlot ~= memberSlot or fighter.liendauHallManaged ~= 1 then
        slot.listId = nil
        return 0
    end
    return 1
end

function WllsBotHall:GetPosition(slotIndex, originX, originY)
    local ring = 1
    local previousSlots = 0
    local ringSlots = 8
    while slotIndex > previousSlots + ringSlots do
        previousSlots = previousSlots + ringSlots
        ring = ring + 1
        ringSlots = ring * 8
    end

    local offset = slotIndex - previousSlots - 1
    local xOffset = 0
    local yOffset = 0
    if offset <= ring * 2 then
        xOffset = -ring + offset
        yOffset = -ring
    elseif offset <= ring * 4 then
        xOffset = ring
        yOffset = -ring + (offset - ring * 2)
    elseif offset <= ring * 6 then
        xOffset = ring - (offset - ring * 4)
        yOffset = ring
    else
        xOffset = -ring
        yOffset = ring - (offset - ring * 6)
    end

    local spacing = self:GetGridSpacing()
    local reservedRadius = self:GetReservedRadius()
    local ringDistance = reservedRadius + ring * spacing
    if yOffset == -ring then
        return originX + xOffset * spacing, originY - ringDistance
    end
    if xOffset == ring then
        return originX + ringDistance, originY + yOffset * spacing
    end
    if yOffset == ring then
        return originX + xOffset * spacing, originY + ringDistance
    end
    return originX - ringDistance, originY + yOffset * spacing
end

function WllsBotHall:BuildMember(member, sessionId, teamId, memberSlot, mapId, x, y)
    local displayName = member.szName
    if not displayName or displayName == "" then
        displayName = "Lien Dau Bot " .. tostring(-teamId) .. "-" .. tostring(memberSlot)
    end
    return {
        nMapId = mapId,
        goX = x,
        goY = y,
        mode = "liendau_hall",
        szName = displayName,
        sourceMember = member.sourceMember,
        strengthProfile = member.strengthProfile,
        liendauSessionId = sessionId,
        liendauTeamId = teamId,
        liendauMemberSlot = memberSlot,
        liendauHallManaged = 1,
        isCombatBot = 0,
    }
end

function WllsBotHall:SpawnMember(member, mapId, x, y)
    if self.spawnMember then return self.spawnMember(self, member, mapId, x, y) end
    if SimCitizen and SimCitizen.New then return SimCitizen:New(member) end
    return nil, "SimCitizen is unavailable"
end

function WllsBotHall:LogSpawnFailure(sessionId, teamId, memberSlot, reason)
    local message = "WllsBotHall spawn failed sessionId=" .. tostring(sessionId)
        .. " teamId=" .. tostring(teamId) .. " memberSlot=" .. tostring(memberSlot)
        .. " reason=" .. tostring(reason)
    if WriteLog then WriteLog(message) end
    if self.logFailure then
        self.logFailure(self, message, sessionId, teamId, memberSlot, reason)
        return
    end
    if print then print(message) end
end

function WllsBotHall:Reconcile(sessionId, mapId, originX, originY)
    if WLLS_BOT_HALL_ENABLED ~= 1 then
        self:Cleanup(sessionId, "hall_disabled")
        return 0
    end
    if not WllsBotManager then return 0 end
    local session = WllsBotManager.sessions[sessionId]
    if not session or session.active ~= 1 or session.teamsCreated ~= 1 then return 0 end
    if not SimCitizen or not SimCitizen.fighterList then return 0 end

    local hallSession = self:GetSession(sessionId)
    local batchSize = self:GetBatchSize()
    local createdCount = 0
    local attemptedCount = 0
    local slotIndex = 0
    local teamIndex = 1
    while teamIndex <= session.teamCount and attemptedCount < batchSize do
        local teamId = session.teamIds[teamIndex]
        local memberSlot = 1
        while memberSlot <= session.memberCount and attemptedCount < batchSize do
            slotIndex = slotIndex + 1
            local slot = self:GetSlot(hallSession, teamId, memberSlot)
            if self:IsLiveSlot(slot, sessionId, teamId, memberSlot) ~= 1 then
                local member = WllsBotManager:GetMember(sessionId, teamId, memberSlot)
                if member then
                    local x, y = self:GetPosition(slotIndex, originX, originY)
                    local hallMember = self:BuildMember(member, sessionId, teamId, memberSlot, mapId, x, y)
                    attemptedCount = attemptedCount + 1
                    local listId, spawnError = self:SpawnMember(hallMember, mapId, x, y)
                    if listId and SimCitizen.fighterList[listId] then
                        slot.listId = listId
                        createdCount = createdCount + 1
                    else
                        if not spawnError then spawnError = "spawned fighter is missing" end
                        self:LogSpawnFailure(sessionId, teamId, memberSlot, spawnError)
                    end
                end
            end
            memberSlot = memberSlot + 1
        end
        teamIndex = teamIndex + 1
    end
    return createdCount
end

function WllsBotHall:Count(sessionId)
    if not WllsBotManager then return 0 end
    local session = WllsBotManager.sessions[sessionId]
    local hallSession = self.sessions[sessionId]
    if not session or not hallSession then return 0 end
    local count = 0
    local teamIndex = 1
    while teamIndex <= session.teamCount do
        local teamId = session.teamIds[teamIndex]
        local memberSlot = 1
        while memberSlot <= session.memberCount do
            local slot = self:GetSlot(hallSession, teamId, memberSlot)
            if self:IsLiveSlot(slot, sessionId, teamId, memberSlot) == 1 then
                count = count + 1
            end
            memberSlot = memberSlot + 1
        end
        teamIndex = teamIndex + 1
    end
    return count
end

function WllsBotHall:Cleanup(sessionId, reason)
    if not WllsBotManager then return 0 end
    local session = WllsBotManager.sessions[sessionId]
    local hallSession = self.sessions[sessionId]
    if not session or not hallSession then return 0 end
    local removedCount = 0
    local teamIndex = 1
    while teamIndex <= session.teamCount do
        local teamId = session.teamIds[teamIndex]
        local memberSlot = 1
        while memberSlot <= session.memberCount do
            local slot = self:GetSlot(hallSession, teamId, memberSlot)
            if self:IsLiveSlot(slot, sessionId, teamId, memberSlot) == 1 then
                local listId = slot.listId
                if SimCitizen.Remove then
                    SimCitizen:Remove(listId)
                    removedCount = removedCount + 1
                end
                slot.listId = nil
            end
            memberSlot = memberSlot + 1
        end
        teamIndex = teamIndex + 1
    end
    hallSession.reason = reason
    self.sessions[sessionId] = nil
    return removedCount
end
