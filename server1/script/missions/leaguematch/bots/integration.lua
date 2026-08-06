-- Boot-preload gate: the engine preloads every script standalone at boot and a
-- SUCCESSFUL preload would be recorded in the global include cache, which then
-- makes schedule.lua's Include a no-op in the timer 50 environment (the
-- functions would resolve globals in the wrong environment). Failing here on
-- purpose evicts this file from the cache so the timer environment always
-- re-executes it. The resulting one-line boot luaerror is EXPECTED and harmless.
if WllsBotIntegrationBootGate ~= 1 then
    error("expected boot-preload skip: integration.lua chi duoc nap qua timer 50 schedule.lua")
end

WllsBotIntegration = WllsBotIntegration or {}

function WllsBotIntegration:Count(values)
    local count = 0
    if not values then return count end
    while values[count + 1] do count = count + 1 end
    return count
end

function WllsBotIntegration.SpawnHallMember(hallSelf, member, mapId, x, y)
    if DynamicExecute then
        return DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "SimCityLienDau:SpawnHallMember",
            member,
            mapId,
            x,
            y
        )
    end
    if not SimCityLienDau or not SimCityLienDau.SpawnHallMember then
        return nil, "SimCityLienDau is unavailable"
    end
    return SimCityLienDau:SpawnHallMember(member, mapId, x, y)
end

function WllsBotIntegration.SpawnCombatMember(combatSelf, member, missionCamp, mapId, x, y)
    if DynamicExecute then
        return DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "SimCityLienDau:SpawnCombatMember",
            member,
            missionCamp,
            mapId,
            x,
            y
        )
    end
    if not SimCityLienDau or not SimCityLienDau.SpawnCombatMember then
        return nil, "SimCityLienDau is unavailable"
    end
    return SimCityLienDau:SpawnCombatMember(member, missionCamp, mapId, x, y)
end

-- Attached onto the real WllsBotManager at runtime by AttachManagerMethods; this
-- file must not touch foreign globals at load time because the engine preloads
-- every script standalone at boot (a load-time reference would fail there and
-- poison the include cache for the timer environment).
function WllsBotIntegration.ManagerOnValidatedRegistration(managerSelf, sessionId, realTeamCount, context)
    if realTeamCount == nil or realTeamCount < 1 then return nil, 0, 0 end
    context = context or {}

    local session = managerSelf.sessions[sessionId]
    if not session then
        session = managerSelf:StartSession(sessionId, context.matchType, context.memberCount)
    end
    if not session or session.active ~= 1 then return nil, 0, 0 end

    local createdTeams = managerSelf:EnsureTeams(sessionId, realTeamCount)
    local createdHall = 0
    WllsBotHall.spawnMember = WllsBotIntegration.SpawnHallMember
    if type(context.hallMapId) == "number" and type(context.hallX) == "number"
       and type(context.hallY) == "number" then
        createdHall = WllsBotHall:Reconcile(
            sessionId,
            context.hallMapId,
            context.hallX,
            context.hallY
        )
    end
    session.validatedRegistration = 1
    return session, createdTeams, createdHall
end

function WllsBotIntegration:GetPairPositions(context, pairIndex)
    if context and context.arenaPositions and context.arenaPositions[pairIndex] then
        return context.arenaPositions[pairIndex]
    end
    if context then return context.positions end
    return nil
end

function WllsBotIntegration:StartActivePairs(sessionId, activePairs, context)
    if not context or context.deferCombat == 1 then return 0 end
    WllsBotCombat.spawnMember = self.SpawnCombatMember
    local startedCount = 0
    local pairIndex = 1
    while activePairs and activePairs[pairIndex] do
        local pair = activePairs[pairIndex]
        pair.arenaIndex = pair.arenaIndex or pairIndex
        local leftCamp = pair.leftCamp or pairIndex * 2 - 1
        local rightCamp = pair.rightCamp or pairIndex * 2
        local positions = self:GetPairPositions(context, pairIndex)
        local started, startError = WllsBotCombat:StartPair(
            sessionId,
            pair,
            leftCamp,
            rightCamp,
            context.combatMapId,
            positions
        )
        if started == 1 then
            startedCount = startedCount + 1
        else
            pair.startError = startError
            self:LogCombat("WllsBot pair " .. tostring(pair.id) .. " start failed: "
                .. tostring(startError))
        end
        pairIndex = pairIndex + 1
    end
    self:LogCombat("WllsBot started " .. tostring(startedCount) .. " combat pair(s) for "
        .. tostring(sessionId))
    return startedCount
end

function WllsBotIntegration:LogCombat(message)
    if WriteLog then WriteLog(message) end
    if print then print(message) end
end

function WllsBotIntegration.ManagerOnRegistrationClosed(managerSelf, sessionId, realCamps, realLGs, context)
    local session = managerSelf.sessions[sessionId]
    if not session or session.active ~= 1 then return nil, nil, nil end
    context = context or {}

    WllsBotHall:Cleanup(sessionId, "registration_closed")
    local entries = managerSelf:BuildUnifiedEntries(sessionId, realCamps, realLGs)
    local activePairs, queuedPairs, byeEntry = WllsBotPairing:Build(entries, context.maxArenas)
    WllsBotIntegration:StartActivePairs(sessionId, activePairs, context)

    session.registrationClosed = 1
    session.registrationCloseEntries = entries
    return activePairs, queuedPairs, byeEntry
end

-- Ten bot lay tu kho ten nguoi choi cua SimCity (moi truong vdk/main).
function WllsBotIntegration.ProvideBotName(managerSelf, session, team, memberSlot)
    if not DynamicExecute then return nil end
    return DynamicExecute(
        "\\script\\global\\nobitaxd\\vdk\\main.lua",
        "SimCityNPCInfo:generateName"
    )
end

function WllsBotIntegration:AttachManagerMethods()
    if not WllsBotManager then return 0 end
    WllsBotManager.OnValidatedRegistration = self.ManagerOnValidatedRegistration
    WllsBotManager.OnRegistrationClosed = self.ManagerOnRegistrationClosed
    WllsBotManager.nameProvider = self.ProvideBotName
    return 1
end

-- ===== Bot trang tri o HOI TRUONG BAO DANH (map 1) =====
-- Nguoi choi dung o hoi truong truoc khi duoc dua sang map chuan bi; luc do
-- chua co phien nao (phien chi sinh ra khi da co doi that tren map chuan bi),
-- nen lop nay chay doc lap voi session, chi song trong giai doan bao danh.

function WllsBotIntegration:GetSignupTarget()
    local target = WLLS_BOT_SIGNUP_COUNT
    if type(target) ~= "number" or target < 0 then return 0 end
    return target
end

function WllsBotIntegration:BuildSignupMember(mapId, slotIndex)
    local generatedName = nil
    if WllsBotManager and WllsBotManager.nameProvider then
        generatedName = WllsBotManager.nameProvider(WllsBotManager, nil, nil, slotIndex)
    end
    if not generatedName or generatedName == "" then
        generatedName = "Lien Dau " .. tostring(slotIndex)
    end
    return {
        szName = generatedName,
        sourceMember = slotIndex,
        liendauSessionId = "signup:" .. tostring(mapId),
        liendauTeamId = -slotIndex,
        liendauMemberSlot = 1,
    }
end

function WllsBotIntegration:ReconcileSignupHall(mapId, originX, originY)
    if WLLS_BOT_HALL_ENABLED ~= 1 then return 0 end
    local target = self:GetSignupTarget()
    if target <= 0 then return 0 end
    if type(mapId) ~= "number" or type(originX) ~= "number" or type(originY) ~= "number" then
        return 0
    end
    if not SimCitizen or not SimCitizen.fighterList then return 0 end

    self.signupBots = self.signupBots or {}
    self.signupMapIds = self.signupMapIds or {}
    local previous = self.signupBots[mapId]
    if not previous then
        previous = {}
        self.signupBots[mapId] = previous
        self.signupMapIds[self:Count(self.signupMapIds) + 1] = mapId
    end

    -- Danh sach duoc dat KHOA THEO SLOT (1..target) chu khong don lai, de bot
    -- thay the luon nhan dung o trong cua no, khong dam vao cho bot khac.
    local live = {}
    local batchSize = WLLS_BOT_HALL_BATCH_SIZE
    if type(batchSize) ~= "number" or batchSize < 1 then batchSize = 4 end
    WllsBotHall.spawnMember = self.SpawnHallMember

    local createdCount = 0
    local slotIndex = 1
    while slotIndex <= target do
        local existingId = previous[slotIndex]
        local fighter = existingId and SimCitizen.fighterList[existingId]
        if fighter and fighter.liendauHallManaged == 1 then
            live[slotIndex] = existingId
        elseif createdCount < batchSize then
            local x, y = WllsBotHall:GetPosition(slotIndex, originX, originY)
            local listId, spawnError = WllsBotHall:SpawnMember(
                self:BuildSignupMember(mapId, slotIndex),
                mapId,
                x,
                y
            )
            if listId and SimCitizen.fighterList[listId] then
                live[slotIndex] = listId
                createdCount = createdCount + 1
            else
                self:LogCombat("WllsBot signup hall spawn failed on map " .. tostring(mapId)
                    .. ": " .. tostring(spawnError))
                createdCount = batchSize
            end
        end
        slotIndex = slotIndex + 1
    end

    self.signupBots[mapId] = live
    if type(self.signupSlotMax) ~= "table" then self.signupSlotMax = {} end
    if (self.signupSlotMax[mapId] or 0) < target then self.signupSlotMax[mapId] = target end
    return createdCount
end

function WllsBotIntegration:ReconcileSignupHalls()
    if self:GetSignupTarget() <= 0 then return 0 end
    local subworlds = wlls_get_subworld(1)
    local oldSubWorld = SubWorld
    local createdTotal = 0
    for subworldIndex, groupIndex in subworlds do
        SubWorld = subworldIndex
        createdTotal = createdTotal + self:ReconcileSignupHall(
            SubWorldIdx2ID(subworldIndex),
            WLLS_MAPPOS_SIGN[1],
            WLLS_MAPPOS_SIGN[2]
        )
    end
    SubWorld = oldSubWorld
    return createdTotal
end

function WllsBotIntegration:CleanupSignupHalls(reason)
    if not self.signupBots or not self.signupMapIds then return 0 end
    local removedCount = 0
    local mapIndex = 1
    while self.signupMapIds[mapIndex] do
        local mapId = self.signupMapIds[mapIndex]
        local list = self.signupBots[mapId]
        local slotMax = 0
        if type(self.signupSlotMax) == "table" then slotMax = self.signupSlotMax[mapId] or 0 end
        local slotIndex = 1
        while list and slotIndex <= slotMax do
            local listId = list[slotIndex]
            local fighter = listId and SimCitizen and SimCitizen.fighterList
                and SimCitizen.fighterList[listId]
            if fighter and fighter.liendauHallManaged == 1 and SimCitizen.Remove then
                SimCitizen:Remove(listId)
                removedCount = removedCount + 1
            end
            slotIndex = slotIndex + 1
        end
        self.signupBots[mapId] = nil
        self.signupMapIds[mapIndex] = nil
        mapIndex = mapIndex + 1
    end
    self.signupSlotMax = {}
    self.signupBots = {}
    self.signupMapIds = {}
    if removedCount > 0 then
        self:LogCombat("WllsBot cleaned " .. tostring(removedCount)
            .. " signup hall bot(s): " .. tostring(reason))
    end
    return removedCount
end

function WllsBotIntegration:TranslateLegacyResult(legacyResult)
    if legacyResult == 0 then return 2 end
    if legacyResult == 1 then return 1 end
    return 0
end

function WllsBotIntegration:ApplyLegacyResult(entry, legacyResult, usedTime)
    return WllsTeamAdapter:ApplyResult(
        entry,
        self:TranslateLegacyResult(legacyResult),
        usedTime
    )
end

function WllsBotIntegration:GetRegistrationContext()
    local matchType, prepGroup = wlls_get_mapinfo()
    return {
        matchId = GetGlbValue(GLB_WLLS_MATCHID),
        matchType = matchType,
        prepGroup = prepGroup,
        hallMapId = wlls_get_mapid(2),
        hallX = WLLS_MAPPOS_PRE[1],
        hallY = WLLS_MAPPOS_PRE[2],
        combatMapId = wlls_get_mapid(3),
    }
end

function WllsBotIntegration:BuildRealLGs(realCamps)
    local realLGs = {}
    local oldPlayerIndex = PlayerIndex
    local campIndex = 1
    while realCamps and realCamps[campIndex] do
        local camp = realCamps[campIndex]
        local players = wlls_get_ms_plidx(camp)
        PlayerIndex = players[1]
        if not PlayerIndex or PlayerIndex <= 0 then
            PlayerIndex = oldPlayerIndex
            return nil, "bad PlayerIndex"
        end
        local lgInfo = wlls_GetLGInfo()
        if not lgInfo then
            PlayerIndex = oldPlayerIndex
            return nil, "bad LG"
        end
        lgInfo.tbPlayer = players
        realLGs[camp] = lgInfo
        campIndex = campIndex + 1
    end
    PlayerIndex = oldPlayerIndex
    return realLGs
end

function WllsBotIntegration:ReconcilePreparationMaps()
    local subworlds = wlls_get_subworld(2)
    local oldSubWorld = SubWorld
    for subworldIndex, groupIndex in subworlds do
        SubWorld = subworldIndex
        local realCamps = wlls_get_ms_troop()
        local realTeamCount = self:Count(realCamps)
        if realTeamCount > 0 then
            local realLGs = self:BuildRealLGs(realCamps)
            if realLGs then
                local context = self:GetRegistrationContext()
                local firstLG = realLGs[realCamps[1]]
                context.memberCount = firstLG.nMemCount
                local sessionId = WllsBotManager:BuildSessionId(
                    context.matchId,
                    context.matchType,
                    context.prepGroup
                )
                WllsBotManager:OnValidatedRegistration(sessionId, realTeamCount, context)
            end
        end
    end
    SubWorld = oldSubWorld
end

function WllsBotIntegration:BuildArenaPositions(activePairs)
    local arenaPositions = {}
    local pairIndex = 1
    while activePairs and activePairs[pairIndex] do
        local x = wlls_GetPosFileData(pairIndex, 1)
        local y = wlls_GetPosFileData(pairIndex, 2)
        arenaPositions[pairIndex] = {
            left = {x = x - 3, y = y},
            right = {x = x + 3, y = y},
            legacy = {x, y},
        }
        pairIndex = pairIndex + 1
    end
    return arenaPositions
end

function WllsBotIntegration:EnsureBotLG(realLGs, entry)
    if not entry or entry.kind ~= "bot" or realLGs[entry.camp] then return end
    realLGs[entry.camp] = {
        nLGID = entry.id,
        nNameID = entry.id,
        nMemCount = 0,
        nMType = entry.level,
        szName = entry.name,
        tbPlayer = {},
    }
end

function WllsBotIntegration:MoveRealSides(activePairs, realLGs, context)
    -- AddMSPlayer dang ky nguoi choi vao mission cua SubWorld HIEN TAI, nen phai
    -- chuyen sang subworld dau truong truoc (nhu legacy wlls_addtroop_combat lam);
    -- thieu buoc nay nguoi choi bi dang ky vao mission cua map chuan bi ->
    -- RunMission khong set fight state va moi lenh dem tren dau truong doc ra 0.
    local oldWorld = SubWorld
    SubWorld = SubWorldID2Idx(context.combatMapId)
    local pairIndex = 1
    while activePairs and activePairs[pairIndex] do
        local pair = activePairs[pairIndex]
        pair.leftCamp = pairIndex * 2 - 1
        pair.rightCamp = pairIndex * 2
        self:EnsureBotLG(realLGs, pair.left)
        self:EnsureBotLG(realLGs, pair.right)

        local arena = context.arenaPositions[pairIndex]
        local legacyPosition = {
            context.combatMapId,
            arena.legacy[1],
            arena.legacy[2],
        }
        if pair.left.kind == "real" then
            wlls_addplayer_combat(
                realLGs,
                pair.left.camp,
                pair.right.camp,
                pair.leftCamp,
                legacyPosition
            )
        end
        if pair.right.kind == "real" then
            wlls_addplayer_combat(
                realLGs,
                pair.right.camp,
                pair.left.camp,
                pair.rightCamp,
                legacyPosition
            )
        end
        pairIndex = pairIndex + 1
    end
    SubWorld = oldWorld
end

function WllsBotIntegration:ApplyBye(byeEntry)
    if not byeEntry then return end
    local usedTime = 5 * 60 * WLLS_FRAME2TIME
    if byeEntry.kind == "real" then
        wlls_matchresult(byeEntry.name, nil, nil, usedTime)
    else
        self:ApplyLegacyResult(byeEntry, 1, usedTime)
    end
end

function WllsBotIntegration:CloseRegistrationMap()
    local realCamps = wlls_get_ms_troop()
    local realTeamCount = self:Count(realCamps)
    local realLGs, lgError = self:BuildRealLGs(realCamps)
    if not realLGs then
        wlls_error_log("WllsBotIntegration:CloseRegistrationMap", lgError)
        return 0
    end

    local context = self:GetRegistrationContext()
    if realTeamCount > 0 then
        context.memberCount = realLGs[realCamps[1]].nMemCount
    end
    local sessionId = WllsBotManager:BuildSessionId(
        context.matchId,
        context.matchType,
        context.prepGroup
    )
    local session = WllsBotManager.sessions[sessionId]
    if session and session.closeTransactionStarted == 1 then return 0 end
    WllsBotManager:OnValidatedRegistration(sessionId, realTeamCount, context)
    session = WllsBotManager.sessions[sessionId]
    if not session or session.active ~= 1 then return 0 end
    if session.closeTransactionStarted == 1 then return 0 end
    session.closeTransactionStarted = 1

    context.deferCombat = 1
    local activePairs, queuedPairs, byeEntry = WllsBotManager:OnRegistrationClosed(
        sessionId,
        realCamps,
        realLGs,
        context
    )

    local oldWorld = SubWorld
    SubWorld = SubWorldID2Idx(context.combatMapId)
    CloseMission(WLLS_MSID_COMBAT)
    OpenMission(WLLS_MSID_COMBAT)
    SubWorld = oldWorld

    if activePairs then
        context.arenaPositions = self:BuildArenaPositions(activePairs)
        session.combatContext = context
        self:ApplyBye(byeEntry)
        self:MoveRealSides(activePairs, realLGs, context)
        context.deferCombat = 0
        WllsBotManager:OnRegistrationClosed(sessionId, realCamps, realLGs, context)
    end

    Msg2MSAll(
        WLLS_MSID_COMBAT,
        "Lien Dau combat begins after "
            .. tostring(WLLS_TIMER_FIGHT_FREQ * WLLS_TIMER_FIGHT_PREP)
            .. " seconds"
    )
    CloseMission(WLLS_MSID_SCHEDULE)
    session.closeTransactionCompleted = 1
    return 1
end

function WllsBotIntegration:OnRegistrationCloseTick()
    if GetGlbValue(GLB_WLLS_PHASE) == 5 then return 0 end
    -- Bot hoi truong bao danh (map 1) KHONG bi don o day: nguoi choi thang tran
    -- se duoc tra ve chinh hoi truong nay, hoi truong trong tron la mat suc song.
    -- Chung song toi het su kien (xem MonitorCombatMaps).
    SetGlbValue(GLB_WLLS_TIME, GetGlbValue(GLB_WLLS_TIME) + 1)
    StopGlbMSTimer(WLLS_MSID_GLB, WLLS_TIMERID_SCHEDULE)
    SetGlbValue(GLB_WLLS_PHASE, 5)
    SetGlbValue(GLB_WLLS_TIME, 0)
    StartGlbMSTimer(
        WLLS_MSID_GLB,
        WLLS_TIMERID_COMBAT,
        WLLS_TIMER_FIGHT_FREQ * WLLS_FRAME2TIME
    )
    Msg2SubWorld("Lien Dau registration closed; combat is starting")

    local subworlds = wlls_get_subworld(2)
    local oldSubWorld = SubWorld
    for subworldIndex, groupIndex in subworlds do
        SubWorld = subworldIndex
        self:CloseRegistrationMap()
    end
    SubWorld = oldSubWorld
    return 1
end

function WllsBotIntegration:GetCurrentSessionId()
    if not WllsBotManager then return nil end
    local matchType, prepGroup = wlls_get_mapinfo()
    if not matchType then return nil end
    return WllsBotManager:BuildSessionId(
        GetGlbValue(GLB_WLLS_MATCHID),
        matchType,
        prepGroup
    )
end

function WllsBotIntegration:EmergencyCleanupPreparation()
    self:CleanupSignupHalls("emergency_disable")
    if not WllsBotManager then return 0 end
    local subworlds = wlls_get_subworld(2)
    local oldSubWorld = SubWorld
    for subworldIndex, groupIndex in subworlds do
        SubWorld = subworldIndex
        local sessionId = self:GetCurrentSessionId()
        if sessionId and WllsBotManager.sessions[sessionId] then
            WllsBotManager:EndSession(sessionId, "emergency_disable")
        end
    end
    SubWorld = oldSubWorld
    return 1
end

-- Timer 50 entry: schedule.lua passes its own captured legacy OnTimer so this
-- method never needs to read or write the OnTimer global of a foreign
-- environment (two timer wrappers share this module).
function WllsBotIntegration:RunScheduleTick(legacyOnTimer)
    if WLLS_BOT_EMERGENCY_DISABLE == 1 then
        self:EmergencyCleanupPreparation()
        return legacyOnTimer()
    end
    if GetGlbValue(GLB_WLLS_PHASE) == 5 then return 0 end
    local nextTick = GetGlbValue(GLB_WLLS_TIME) + 1
    if nextTick < WLLS_TIMER_PREP_TOTAL then
        local result = legacyOnTimer()
        self:ReconcileSignupHalls()
        self:ReconcilePreparationMaps()
        return result
    end
    return self:OnRegistrationCloseTick()
end

function WllsBotIntegration:GetSideAlive(pair, side)
    local entry
    local camp
    if side == "left" then
        entry = pair.left
        camp = pair.leftCamp
    else
        entry = pair.right
        camp = pair.rightCamp
    end
    if not entry then return 0 end
    if entry.kind == "real" then
        if GetMSPlayerCount and camp then
            return GetMSPlayerCount(WLLS_MSID_COMBAT, camp) or 0
        end
        return 0
    end
    if WllsBotCombat and WllsBotCombat.AliveCount then
        return WllsBotCombat:AliveCount(pair.id, side)
    end
    return 0
end

function WllsBotIntegration:GetSideDamage(pair, side)
    local entry
    local camp
    if side == "left" then
        entry = pair.left
        camp = pair.leftCamp
    else
        entry = pair.right
        camp = pair.rightCamp
    end
    if not entry then return 0 end
    if entry.kind == "real" then
        if wlls_get_ms_damage and camp then
            return wlls_get_ms_damage(camp) or 0
        end
        return 0
    end
    if WllsBotCombat and WllsBotCombat.DamageTaken then
        return WllsBotCombat:DamageTaken(pair.id, side)
    end
    return 0
end

function WllsBotIntegration:DecideTimeoutWinner(pair)
    local aliveLeft = self:GetSideAlive(pair, "left")
    local aliveRight = self:GetSideAlive(pair, "right")
    if aliveLeft > aliveRight then return "left" end
    if aliveRight > aliveLeft then return "right" end
    local damageLeft = self:GetSideDamage(pair, "left")
    local damageRight = self:GetSideDamage(pair, "right")
    if damageLeft < damageRight then return "left" end
    if damageRight < damageLeft then return "right" end
    return nil
end

-- Nha trang thai tran dau cho tung thanh vien doi that THEO TEN (khong phu
-- thuoc roster mission co the doc trong luc nguoi choi dang chuyen map):
-- wlls_clear_pl_state mo lai than hanh phu/the luc/giao dich, roi go khoi
-- mission va tra ve hoi truong neu con dung tren map dau truong.
function WllsBotIntegration:ReleaseRealTeam(entry)
    if not entry or entry.kind ~= "real" or not SearchPlayer then return 0 end
    local releasedCount = 0
    local oldIndex = PlayerIndex
    local memberIndex = 1
    while entry.members and entry.members[memberIndex] do
        local playerIndex = SearchPlayer(entry.members[memberIndex])
        if playerIndex and playerIndex > 0 then
            PlayerIndex = playerIndex
            wlls_clear_pl_state()
            SetPKFlag(0)
            ForbidChangePK(0)
            SetTask(WLLS_TASKID_ORGCAMP, 0)
            if ST_StopDamageCounter then ST_StopDamageCounter() end
            local playerWorld = GetWorldPos()
            if playerWorld == wlls_get_mapid(3) then
                DelMSPlayer(WLLS_MSID_COMBAT, 0)
                SetLogoutRV(0)
                NewWorld(wlls_get_mapid(1), WLLS_MAPPOS_SIGN[1], WLLS_MAPPOS_SIGN[2])
            end
            releasedCount = releasedCount + 1
        end
        memberIndex = memberIndex + 1
    end
    PlayerIndex = oldIndex
    return releasedCount
end

function WllsBotIntegration:ApplySideResult(entry, legacyResult, usedTime, missionCamp)
    if not entry then return 0 end
    if entry.kind == "real" then
        if wlls_award_lg and wlls_get_level and wlls_get_mapinfo then
            local matchType = wlls_get_mapinfo(1)
            wlls_award_lg(
                wlls_get_level(matchType),
                entry.leagueName or entry.name,
                legacyResult,
                usedTime
            )
        end
        local releasedCount = self:ReleaseRealTeam(entry)
        if releasedCount > 0 then
            self:LogCombat("WllsBot released " .. tostring(releasedCount)
                .. " player(s) of [" .. tostring(entry.name) .. "]")
        end
        if missionCamp and wlls_remove_camp then wlls_remove_camp(missionCamp) end
        return 1
    end
    return self:ApplyLegacyResult(entry, legacyResult, usedTime)
end

function WllsBotIntegration:StartQueuedPair(session, freedArenaIndex)
    if not session or not session.queuedPairs or not session.queuedPairs[1] then return 0 end
    if not freedArenaIndex then return 0 end
    local context = session.combatContext
    if not context or not context.arenaPositions then return 0 end

    local minSeconds = WLLS_BOT_QUEUE_MIN_SECONDS
    if type(minSeconds) ~= "number" then minSeconds = 60 end
    local remainingSeconds = (WLLS_TIMER_FIGHT_TOTAL - GetGlbValue(GLB_WLLS_TIME))
        * WLLS_TIMER_FIGHT_FREQ
    if remainingSeconds < minSeconds then return 0 end

    local nextPair = session.queuedPairs[1]
    local shiftIndex = 1
    while session.queuedPairs[shiftIndex + 1] do
        session.queuedPairs[shiftIndex] = session.queuedPairs[shiftIndex + 1]
        shiftIndex = shiftIndex + 1
    end
    session.queuedPairs[shiftIndex] = nil

    nextPair.arenaIndex = freedArenaIndex
    nextPair.leftCamp = freedArenaIndex * 2 - 1
    nextPair.rightCamp = freedArenaIndex * 2
    if not WllsBotCombat.spawnMember then
        WllsBotCombat.spawnMember = self.SpawnCombatMember
    end
    local started, startError = WllsBotCombat:StartPair(
        session.id,
        nextPair,
        nextPair.leftCamp,
        nextPair.rightCamp,
        context.combatMapId,
        self:GetPairPositions(context, freedArenaIndex)
    )
    if started == 1 then
        session.activePairs[self:Count(session.activePairs) + 1] = nextPair
        return 1
    end
    nextPair.startError = startError
    return 0
end

function WllsBotIntegration:FinishPair(session, pair, winnerSide, usedTime)
    if not pair or pair.finalized == 1 then return 0 end
    if pair.left and pair.left.kind == "real" and pair.right and pair.right.kind == "real" then
        -- Real-versus-real results stay fully owned by the legacy mission flow.
        return 0
    end
    pair.finalized = 1
    pair.state = "finished"

    local leftResult = 0
    local rightResult = 0
    if winnerSide == "left" then
        leftResult = 1
        rightResult = 2
    elseif winnerSide == "right" then
        leftResult = 2
        rightResult = 1
    end

    self:ApplySideResult(pair.left, leftResult, usedTime, pair.leftCamp)
    self:ApplySideResult(pair.right, rightResult, usedTime, pair.rightCamp)

    if Msg2SubWorld then
        local message
        if winnerSide == "left" then
            message = "[" .. tostring(pair.left.name) .. "] chien thang ["
                .. tostring(pair.right.name) .. "]!"
        elseif winnerSide == "right" then
            message = "[" .. tostring(pair.right.name) .. "] chien thang ["
                .. tostring(pair.left.name) .. "]!"
        else
            message = "[" .. tostring(pair.left.name) .. "] va ["
                .. tostring(pair.right.name) .. "] hoa nhau!"
        end
        Msg2SubWorld("<color=cyan>Lien Dau: " .. message)
    end

    if WllsBotCombat and WllsBotCombat.CleanupPair then
        WllsBotCombat:CleanupPair(pair.id, "finished")
    end
    self:StartQueuedPair(session, pair.arenaIndex)
    return 1
end

function WllsBotIntegration:MonitorSessionPairs(session, isTimeout, usedTime)
    local finishedCount = 0
    local pairIndex = 1
    while session.activePairs and session.activePairs[pairIndex] do
        local pair = session.activePairs[pairIndex]
        local involvesBot = 0
        if (pair.left and pair.left.kind == "bot")
           or (pair.right and pair.right.kind == "bot") then
            involvesBot = 1
        end
        if involvesBot == 1 and pair.finalized ~= 1 and pair.state == "active" then
            if isTimeout == 1 then
                self:LogCombat("WllsBot pair " .. tostring(pair.id) .. " timeout: alive "
                    .. tostring(self:GetSideAlive(pair, "left")) .. "-"
                    .. tostring(self:GetSideAlive(pair, "right")))
                finishedCount = finishedCount
                    + self:FinishPair(session, pair, self:DecideTimeoutWinner(pair), usedTime)
            else
                local aliveLeft = self:GetSideAlive(pair, "left")
                local aliveRight = self:GetSideAlive(pair, "right")
                -- Phe nguoi that phai bi doc 0 mang o 2 tick lien tiep moi tinh
                -- la bi diet (chong GetMSPlayerCount chap chon khi chuyen map).
                if aliveLeft == 0 and pair.left and pair.left.kind == "real" then
                    pair.zeroTicksLeft = (pair.zeroTicksLeft or 0) + 1
                    if pair.zeroTicksLeft < 2 then aliveLeft = -1 end
                else
                    pair.zeroTicksLeft = 0
                end
                if aliveRight == 0 and pair.right and pair.right.kind == "real" then
                    pair.zeroTicksRight = (pair.zeroTicksRight or 0) + 1
                    if pair.zeroTicksRight < 2 then aliveRight = -1 end
                else
                    pair.zeroTicksRight = 0
                end
                if aliveLeft == 0 or aliveRight == 0 then
                    self:LogCombat("WllsBot pair " .. tostring(pair.id) .. " elimination: alive "
                        .. tostring(aliveLeft) .. "-" .. tostring(aliveRight))
                end
                if aliveLeft == 0 and aliveRight == 0 then
                    finishedCount = finishedCount
                        + self:FinishPair(session, pair, self:DecideTimeoutWinner(pair), usedTime)
                elseif aliveLeft == 0 then
                    finishedCount = finishedCount + self:FinishPair(session, pair, "right", usedTime)
                elseif aliveRight == 0 then
                    finishedCount = finishedCount + self:FinishPair(session, pair, "left", usedTime)
                end
            end
        end
        pairIndex = pairIndex + 1
    end
    return finishedCount
end

function WllsBotIntegration:AnnounceRanking(session)
    if not WllsBotManager or not WllsBotManager.BuildRanking then return 0 end
    local sorted = WllsBotManager:BuildRanking(session.id, session.unifiedEntries)
    if not sorted[1] then return 0 end
    if Msg2SubWorld then
        Msg2SubWorld("<color=yellow>===== Xep Hang Lien Dau (nguoi + bot) =====")
        local rankIndex = 1
        while sorted[rankIndex] and rankIndex <= 3 do
            local entry = sorted[rankIndex]
            Msg2SubWorld("<color=yellow>" .. tostring(rankIndex) .. ". ["
                .. tostring(entry.name) .. "] "
                .. tostring(WllsTeamAdapter:GetStat(entry, "point")) .. " diem")
            rankIndex = rankIndex + 1
        end
    end
    return 1
end

-- Tim phien dang dieu khien mot map dau truong. Uu tien tra cuu theo sessionId
-- (nhanh), nhung KHONG phu thuoc vao no: tren map dau truong wlls_get_mapinfo
-- co the tra ra group khac voi luc tao phien tren map chuan bi, khi do tra cuu
-- theo id se truot va tran bi treo. Fallback: quet danh sach phien theo
-- combatMapId da luu luc dong dang ky.
function WllsBotIntegration:FindSessionForCombatMap(combatMapId)
    if not WllsBotManager then return nil end

    local sessionId = self:GetCurrentSessionId()
    local session = sessionId and WllsBotManager.sessions[sessionId]
    if session and session.active == 1 then return session end

    if type(combatMapId) ~= "number" or not WllsBotManager.sessionIds then return nil end
    local index = 1
    while WllsBotManager.sessionIds[index] do
        local candidate = WllsBotManager.sessions[WllsBotManager.sessionIds[index]]
        if candidate and candidate.active == 1 and candidate.combatContext
           and candidate.combatContext.combatMapId == combatMapId then
            return candidate
        end
        index = index + 1
    end
    return nil
end

function WllsBotIntegration:MonitorCombatMaps(emergencyFlag)
    if not WllsBotManager then return 0 end
    local currentTime = GetGlbValue(GLB_WLLS_TIME)
    local isTimeout = 0
    if GetGlbValue(GLB_WLLS_PHASE) == 3 or currentTime >= WLLS_TIMER_FIGHT_TOTAL then
        isTimeout = 1
    end
    -- Grace: trong giai doan chuan bi (va them 1 tick) nguoi choi con dang duoc
    -- chuyen vao arena, GetMSPlayerCount co the tam thoi bang 0 -> KHONG duoc
    -- xu loai truc tiep, neu khong bot thang oan va bi don truoc khi nguoi
    -- choi kip nhin thay (loi quan sat 13:41 03/08).
    if emergencyFlag ~= 1 and isTimeout == 0 and currentTime <= (WLLS_TIMER_FIGHT_PREP + 1) then
        return 0
    end
    local usedTime = currentTime * WLLS_TIMER_FIGHT_FREQ * WLLS_FRAME2TIME
    if isTimeout == 1 then self:CleanupSignupHalls("event_end") end

    local subworlds = wlls_get_subworld(3)
    local oldSubWorld = SubWorld
    for subworldIndex, groupIndex in subworlds do
        SubWorld = subworldIndex
        local session = self:FindSessionForCombatMap(SubWorldIdx2ID(subworldIndex))
        if session then
            if emergencyFlag == 1 then
                WllsBotManager:EndSession(session.id, "emergency_disable")
            else
                self:MonitorSessionPairs(session, isTimeout, usedTime)
                if isTimeout == 1 then
                    self:AnnounceRanking(session)
                    WllsBotManager:EndSession(session.id, "event_end")
                end
            end
        else
            self.missingSessionTicks = (self.missingSessionTicks or 0) + 1
            if self.missingSessionTicks == 1 or self.missingSessionTicks == 12 then
                self:LogCombat("WllsBot combat monitor found no session for arena map "
                    .. tostring(SubWorldIdx2ID(subworldIndex)))
            end
        end
    end
    SubWorld = oldSubWorld
    return 1
end

-- Timer 51 entry: combat_schedule.lua passes its own captured legacy OnTimer.
function WllsBotIntegration:RunCombatTick(legacyOnTimer)
    local result = legacyOnTimer()
    if WLLS_BOT_EMERGENCY_DISABLE == 1 then
        self:MonitorCombatMaps(1)
        return result
    end
    self:MonitorCombatMaps(0)
    return result
end

function WllsBotIntegration:BindSimCityRuntime()
    self:AttachManagerMethods()
    if not DynamicExecute then return 0 end
    local runtimePath = "\\script\\global\\nobitaxd\\vdk\\main.lua"
    if not SimCitizen then
        SimCitizen = DynamicExecute(runtimePath, "getglobal", "SimCitizen")
    end
    WllsBotHall.spawnMember = self.SpawnHallMember
    WllsBotCombat.spawnMember = self.SpawnCombatMember
    if SimCitizen then return 1 end
    return 0
end

