WllsBotManager = WllsBotManager or {
    sessions = {},
    nextTeamId = 0,
    nextCampId = 0,
}

function WllsBotManager:BuildSessionId(matchId, matchType, prepGroup)
    if matchId == nil then matchId = 0 end
    if matchType == nil then matchType = 0 end
    if prepGroup == nil then prepGroup = 0 end
    return matchId .. ":" .. matchType .. ":" .. prepGroup
end

function WllsBotManager:GetTargetTeamCount(memberCount)
    if WLLS_BOT_TEAMS_ENABLED ~= 1 then return 0 end
    if memberCount == 1 then return WLLS_BOT_TEAM_COUNT_1V1 or 32 end
    if memberCount == 2 then return WLLS_BOT_TEAM_COUNT_2V2 or 16 end
    if memberCount == 3 then return WLLS_BOT_TEAM_COUNT_3V3 or 12 end
    return 0
end

function WllsBotManager:StartSession(sessionId, matchType, memberCount)
    local session = self.sessions[sessionId]
    if session then return session end

    if sessionId == nil then
        sessionId = self:BuildSessionId(0, matchType, 0)
    end

    session = {
        id = sessionId,
        matchType = matchType,
        memberCount = memberCount,
        teams = {},
        teamIds = {},
        teamCount = 0,
        teamsCreated = 0,
        active = 1,
    }
    self.sessions[sessionId] = session
    -- Mang song song de duyet duoc phien bang vong while (Lua 4 khong co pairs).
    self.sessionIds = self.sessionIds or {}
    local idIndex = 1
    while self.sessionIds[idIndex] do
        if self.sessionIds[idIndex] == sessionId then return session end
        idIndex = idIndex + 1
    end
    self.sessionIds[idIndex] = sessionId
    return session
end

function WllsBotManager:ForgetSessionId(sessionId)
    if not self.sessionIds then return 0 end
    local readIndex = 1
    local writeIndex = 1
    while self.sessionIds[readIndex] do
        if self.sessionIds[readIndex] ~= sessionId then
            self.sessionIds[writeIndex] = self.sessionIds[readIndex]
            writeIndex = writeIndex + 1
        end
        readIndex = readIndex + 1
    end
    while writeIndex < readIndex do
        self.sessionIds[writeIndex] = nil
        writeIndex = writeIndex + 1
    end
    return 1
end

function WllsBotManager:GetTeam(sessionId, teamId)
    local session = self.sessions[sessionId]
    if not session then return nil end
    return session.teams[teamId]
end

function WllsBotManager:GetMember(sessionId, teamId, memberSlot)
    local team = self:GetTeam(sessionId, teamId)
    if not team then return nil end
    return team.members[memberSlot]
end

-- Ten bot lay tu kho ten nguoi choi cua SimCity (nameProvider do integration gan
-- luc runtime). Sinh MOT LAN o day nen ten giu nguyen tu hoi truong sang dau
-- truong; co chong trung trong cung mot phien.
function WllsBotManager:GenerateMemberName(session, team, memberSlot)
    if self.nameProvider then
        session.usedNames = session.usedNames or {}
        local attempt = 1
        while attempt <= 8 do
            local generated = self.nameProvider(self, session, team, memberSlot)
            if generated and generated ~= "" and not session.usedNames[generated] then
                session.usedNames[generated] = 1
                return generated
            end
            attempt = attempt + 1
        end
    end
    return "Lien Dau Bot " .. tostring(-team.id) .. "-" .. tostring(memberSlot)
end

function WllsBotManager:CreateMember(session, team, memberSlot)
    local member = {
        isCombatBot = 1,
        mode = "chiendau",
        szName = self:GenerateMemberName(session, team, memberSlot),
        liendauSessionId = session.id,
        liendauTeamId = team.id,
        liendauMemberSlot = memberSlot,
        sourceMember = memberSlot,
    }
    if SimBotStrengthCompat and SimBotStrengthCompat.Apply then
        member = SimBotStrengthCompat:Apply(member, memberSlot) or member
    end
    member.isCombatBot = 1
    member.liendauSessionId = session.id
    member.liendauTeamId = team.id
    member.liendauMemberSlot = memberSlot
    if not member.szName or member.szName == "" then
        member.szName = self:GenerateMemberName(session, team, memberSlot)
    end
    return member
end

function WllsBotManager:CreateTeam(session)
    self.nextTeamId = (self.nextTeamId or 0) - 1
    self.nextCampId = (self.nextCampId or 0) - 1

    local team = {
        id = self.nextTeamId,
        campId = self.nextCampId,
        name = "Lien Dau Bot " .. (-self.nextTeamId),
        isBot = 1,
        members = {},
        point = 0,
        win = 0,
        tie = 0,
        total = 0,
        time = 0,
        enemies = {},
        state = "waiting",
    }

    for memberSlot = 1, session.memberCount do
        team.members[memberSlot] = self:CreateMember(session, team, memberSlot)
    end

    session.teams[team.id] = team
    session.teamCount = session.teamCount + 1
    session.teamIds[session.teamCount] = team.id
    return team
end

function WllsBotManager:EnsureTeams(sessionId, realTeamCount)
    local session = self.sessions[sessionId]
    if not session or session.active ~= 1 then return 0 end
    if realTeamCount == nil or realTeamCount < 1 then return 0 end
    if session.teamsCreated == 1 then return 0 end

    local target = self:GetTargetTeamCount(session.memberCount)
    local createdCount = 0
    for teamSlot = 1, target do
        self:CreateTeam(session)
        createdCount = createdCount + 1
    end
    session.teamsCreated = 1
    return createdCount
end

function WllsBotManager:BuildUnifiedRosterKey(sessionId, realCamps, realLGs)
    local rosterKey = ""
    local campIndex = 1
    while realCamps and realCamps[campIndex] do
        local camp = realCamps[campIndex]
        local lgInfo = nil
        if realLGs then lgInfo = realLGs[camp] end
        local leagueId = 0
        if lgInfo then leagueId = lgInfo.nLGID or lgInfo.nNameID or 0 end
        rosterKey = rosterKey .. "R" .. tostring(camp) .. "=" .. tostring(leagueId) .. ";"
        campIndex = campIndex + 1
    end

    local session = self.sessions[sessionId]
    local teamIndex = 1
    while session and teamIndex <= session.teamCount do
        rosterKey = rosterKey .. "B" .. tostring(session.teamIds[teamIndex]) .. ";"
        teamIndex = teamIndex + 1
    end
    return rosterKey
end

function WllsBotManager:BuildUnifiedEntries(sessionId, realCamps, realLGs)
    local session = self.sessions[sessionId]
    local rosterKey = self:BuildUnifiedRosterKey(sessionId, realCamps, realLGs)
    if session and session.active == 1 and session.unifiedRosterKey == rosterKey
       and session.unifiedEntries then
        return session.unifiedEntries
    end

    local entries = {}
    local entryCount = 0
    local campIndex = 1

    if WllsTeamAdapter and realCamps and realLGs then
        while realCamps[campIndex] do
            local camp = realCamps[campIndex]
            local entry = WllsTeamAdapter:FromReal(camp, realLGs[camp])
            if entry then
                entryCount = entryCount + 1
                entries[entryCount] = entry
            end
            campIndex = campIndex + 1
        end
    end

    if not session or session.active ~= 1 or not WllsTeamAdapter then return entries end

    local teamIndex = 1
    while teamIndex <= session.teamCount do
        local teamId = session.teamIds[teamIndex]
        local entry = WllsTeamAdapter:FromBot(session.teams[teamId])
        if entry then
            entryCount = entryCount + 1
            entries[entryCount] = entry
        end
        teamIndex = teamIndex + 1
    end

    entries.liendauSessionId = sessionId
    entries.liendauRosterKey = rosterKey
    session.unifiedEntries = entries
    session.unifiedRosterKey = rosterKey
    session.pairingBuilt = 0
    session.pairingRosterKey = nil
    session.activePairs = nil
    session.queuedPairs = nil
    session.byeEntry = nil
    session.prioritizedPairs = nil
    session.pairingCapacity = nil
    return entries
end

function WllsBotManager:CompareRank(leftEntry, rightEntry)
    local leftPoint = WllsTeamAdapter:GetStat(leftEntry, "point")
    local rightPoint = WllsTeamAdapter:GetStat(rightEntry, "point")
    if leftPoint ~= rightPoint then
        if leftPoint > rightPoint then return 1 end
        return 0
    end
    local leftWin = WllsTeamAdapter:GetStat(leftEntry, "win")
    local rightWin = WllsTeamAdapter:GetStat(rightEntry, "win")
    if leftWin ~= rightWin then
        if leftWin > rightWin then return 1 end
        return 0
    end
    local leftTime = WllsTeamAdapter:GetStat(leftEntry, "time")
    local rightTime = WllsTeamAdapter:GetStat(rightEntry, "time")
    if leftTime ~= rightTime then
        if leftTime < rightTime then return 1 end
        return 0
    end
    if (leftEntry.id or 0) < (rightEntry.id or 0) then return 1 end
    return 0
end

function WllsBotManager:BuildRanking(sessionId, entries)
    if not entries then
        local session = self.sessions[sessionId]
        entries = session and session.unifiedEntries
    end

    local sorted = {}
    local sortedCount = 0
    local entryIndex = 1
    while entries and entries[entryIndex] do
        local entry = entries[entryIndex]
        local insertAt = 1
        while insertAt <= sortedCount and self:CompareRank(sorted[insertAt], entry) == 1 do
            insertAt = insertAt + 1
        end
        local shiftIndex = sortedCount
        while shiftIndex >= insertAt do
            sorted[shiftIndex + 1] = sorted[shiftIndex]
            shiftIndex = shiftIndex - 1
        end
        sorted[insertAt] = entry
        sortedCount = sortedCount + 1
        entryIndex = entryIndex + 1
    end
    return sorted
end

function WllsBotManager:EndSession(sessionId, reason)
    local session = self.sessions[sessionId]
    if not session then return nil end

    if WllsBotHall and WllsBotHall.Cleanup then
        WllsBotHall:Cleanup(sessionId, reason)
    end
    if WllsBotCombat and WllsBotCombat.CleanupPair then
        local pairList = session.prioritizedPairs or session.activePairs
        local pairIndex = 1
        while pairList and pairList[pairIndex] do
            local pair = pairList[pairIndex]
            if pair.id then WllsBotCombat:CleanupPair(pair.id, reason) end
            pairIndex = pairIndex + 1
        end
    end

    session.activePairs = nil
    session.queuedPairs = nil
    session.prioritizedPairs = nil
    session.active = 0
    session.endReason = reason
    self.sessions[sessionId] = nil
    self:ForgetSessionId(sessionId)
    return session
end
