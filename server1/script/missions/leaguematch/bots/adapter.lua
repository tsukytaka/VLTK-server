WllsTeamAdapter = WllsTeamAdapter or {}

function WllsTeamAdapter:GetLeagueTask(key)
    if key == "point" then return WLLS_LGTASK_POINT end
    if key == "win" then return WLLS_LGTASK_WIN end
    if key == "tie" then return WLLS_LGTASK_TIE end
    if key == "total" then return WLLS_LGTASK_TOTAL end
    if key == "time" then return WLLS_LGTASK_TIME end
    return nil
end

function WllsTeamAdapter:FromReal(camp, lgInfo)
    if not lgInfo then return nil end

    local memberCount = lgInfo.nMemCount or 0
    local members = {}
    local enemies = {}
    local memberIndex

    if LG_GetMemberInfo then
        for memberIndex = 0, memberCount - 1 do
            members[memberIndex + 1] = LG_GetMemberInfo(lgInfo.nLGID, memberIndex)
        end
    end

    if LG_GetLeagueTask then
        enemies[1] = LG_GetLeagueTask(lgInfo.nLGID, WLLS_LGTASK_EMY1)
        enemies[2] = LG_GetLeagueTask(lgInfo.nLGID, WLLS_LGTASK_EMY2)
        enemies[3] = LG_GetLeagueTask(lgInfo.nLGID, WLLS_LGTASK_EMY3)
    end

    return {
        kind = "real",
        camp = camp,
        id = lgInfo.nNameID or lgInfo.nLGID,
        name = lgInfo.szName,
        members = members,
        memberCount = memberCount,
        enemies = enemies,
        leagueId = lgInfo.nLGID,
        leagueName = lgInfo.szName,
        level = lgInfo.nMType or 1,
        lgInfo = lgInfo,
    }
end

function WllsTeamAdapter:FromBot(team)
    if not team or team.isBot ~= 1 then return nil end

    local memberCount = 0
    local level = team.level or team.matchType
    if team.members then
        while team.members[memberCount + 1] do
            memberCount = memberCount + 1
        end
    end
    if not level and team.members and team.members[1] and WllsBotManager and WllsBotManager.sessions then
        local session = WllsBotManager.sessions[team.members[1].liendauSessionId]
        if session then level = session.matchType end
    end

    return {
        kind = "bot",
        camp = team.campId,
        id = team.id,
        name = team.name,
        members = team.members,
        memberCount = memberCount,
        enemies = team.enemies,
        level = level or 1,
        team = team,
    }
end

function WllsTeamAdapter:IsActiveBot(entry)
    if not entry or entry.kind ~= "bot" or not entry.team then return 0 end

    local team = entry.team
    if team.isBot ~= 1 or not team.members or not team.members[1] then return 0 end

    local sessionId = team.members[1].liendauSessionId
    if not sessionId or not WllsBotManager or not WllsBotManager.sessions then return 0 end

    local session = WllsBotManager.sessions[sessionId]
    if not session or session.active ~= 1 then return 0 end
    if session.teams[team.id] ~= team then return 0 end
    return 1
end

function WllsTeamAdapter:GetStat(entry, key)
    if not entry then return 0 end

    if entry.kind == "real" then
        local task = self:GetLeagueTask(key)
        if task and LG_GetLeagueTask then
            return LG_GetLeagueTask(entry.leagueId, task) or 0
        end
        return 0
    end

    if self:IsActiveBot(entry) == 1 then
        return entry.team[key] or 0
    end
    return 0
end

function WllsTeamAdapter:SaveEnemy(entry, enemyEntry)
    if not entry or not enemyEntry then return 0 end

    local enemyId = enemyEntry.id
    if entry.kind == "real" then
        if not LG_ApplySetLeagueTask or not LG_GetLeagueTask then return 0 end

        local oldEnemy1 = LG_GetLeagueTask(entry.leagueId, WLLS_LGTASK_EMY1)
        local oldEnemy2 = LG_GetLeagueTask(entry.leagueId, WLLS_LGTASK_EMY2)
        LG_ApplySetLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_EMY3, oldEnemy2)
        LG_ApplySetLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_EMY2, oldEnemy1)
        LG_ApplySetLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_EMY1, enemyId)
        entry.enemies[3] = oldEnemy2
        entry.enemies[2] = oldEnemy1
        entry.enemies[1] = enemyId
        return 1
    end

    if self:IsActiveBot(entry) == 1 then
        local enemies = entry.team.enemies
        if not enemies then
            enemies = {}
            entry.team.enemies = enemies
            entry.enemies = enemies
        end
        enemies[3] = enemies[2]
        enemies[2] = enemies[1]
        enemies[1] = enemyId
        return 1
    end
    return 0
end

function WllsTeamAdapter:ApplyResult(entry, result, usedTime)
    if not entry then return 0 end

    local win = 0
    local tie = 0
    if result == 1 then
        win = 1
    elseif result == 2 then
        tie = 1
    end

    if usedTime == nil then usedTime = 0 end
    local level = entry.level or 1
    local point = 0
    if wlls_GetAddPoint then
        point = wlls_GetAddPoint(level, win, tie)
    end

    if entry.kind == "real" then
        if not LG_ApplyAppendLeagueTask then return 0 end

        if win > 0 then
            LG_ApplyAppendLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_WIN, win)
        end
        if tie > 0 then
            LG_ApplyAppendLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_TIE, tie)
        end
        LG_ApplyAppendLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_POINT, point)
        LG_ApplyAppendLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_TOTAL, 1)
        LG_ApplyAppendLeagueTask(WLLS_LGTYPE, entry.leagueName, WLLS_LGTASK_TIME, usedTime)
        return 1
    end

    if self:IsActiveBot(entry) == 1 then
        local team = entry.team
        team.win = (team.win or 0) + win
        team.tie = (team.tie or 0) + tie
        team.point = (team.point or 0) + point
        team.total = (team.total or 0) + 1
        team.time = (team.time or 0) + usedTime
        return 1
    end
    return 0
end
