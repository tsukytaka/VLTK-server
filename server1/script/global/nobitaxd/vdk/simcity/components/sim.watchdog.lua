SimCityWatchdog = SimCityWatchdog or { sweepNo = 0 }

-- Mot so ban JX xu ly chuoi Include theo hang doi. Chi cai hook khi cac class
-- da duoc nap day du; main loop se Include lai file nay neu can.
if SimCitizen and SimCityThanhThi and SimCityChienTranh then
SIMCITY_WATCHDOG_HOOKS = 1

-- Thanh thi va thon luon hoa binh o khu vuc ben trong. Watchdog co the tao
-- bot bu truoc khi pthanhthi dat cityPeace, nen ep co nay ngay tai moi lan
-- kiem tra chien dau. Ben ngoai vung trung tam/cua thanh van duoc danh nhau.
function SimCityForceTownPeace(tbNpc)
    if not tbNpc or not tbNpc.worldInfo or not tbNpc.nMapId then return end
    local nW = tbNpc.nMapId
    local isCity = SimCityWorld and SimCityWorld.IsThanhThiMap
                   and SimCityWorld:IsThanhThiMap(nW) == 1
    local isVillage = nW == 53 or nW == 20 or nW == 99 or nW == 100
                      or nW == 101 or nW == 121 or nW == 153 or nW == 174
    if isCity or isVillage then
        tbNpc.worldInfo.allowFighting = 0
        tbNpc.worldInfo.cityPeace = 1
    end
end

SIMCITY_BASE_CAN_FIGHT = SIMCITY_BASE_CAN_FIGHT or SimCityCanFight
function SimCityCanFight(tbNpc)
    SimCityForceTownPeace(tbNpc)
    return SIMCITY_BASE_CAN_FIGHT(tbNpc)
end

SIMCITY_BASE_IS_PEACE_ZONE = SIMCITY_BASE_IS_PEACE_ZONE or SimCityIsPeaceZone
function SimCityIsPeaceZone(tbNpc)
    SimCityForceTownPeace(tbNpc)
    return SIMCITY_BASE_IS_PEACE_ZONE(tbNpc)
end

-- Khong ro ri PIdx ra bien toan cuc.
function DelNpcSafe(nNpcIndex)
    if not nNpcIndex or nNpcIndex <= 0 then return end
    local pIdx = NpcIdx2PIdx(nNpcIndex)
    if pIdx and pIdx > 0 then return end
    DelNpc(nNpcIndex)
end

-- Ban New an toan: khong de lai ghost neu reset vi tri loi, va giu fighter
-- trong hang retry neu engine tam het slot NPC.
function SimCitizen:New(fighter)
    -- THANHTHI_SIZE/THON_SIZE are total populations, including stall NPCs.
    -- Normal stalls and Da Tau stalls have separate web limits. Both groups
    -- are still included in the total city/village population.
    if fighter and fighter.nMapId and fighter.mode ~= "chiendau" then
        local capTotal, capStall, capDaTau = nil, nil, SIMCITY_STALL_DATAU_MAX or 0
        if SimCityWorld:IsThanhThiMap(fighter.nMapId) == 1 then
            capTotal = SIMCITY_WEB_CITY_SIZE or THANHTHI_SIZE or 300
            capStall = SIMCITY_STALL_CITY_MAX or 0
        elseif fighter.nMapId == 53 or fighter.nMapId == 20 or fighter.nMapId == 99
            or fighter.nMapId == 100 or fighter.nMapId == 101 or fighter.nMapId == 121
            or fighter.nMapId == 153 or fighter.nMapId == 174 then
            capTotal = SIMCITY_WEB_VILLAGE_SIZE or THON_SIZE or 50
            capStall = SIMCITY_STALL_VILLAGE_MAX or 0
        end
        if capTotal then
            local currentTotal, currentStall, currentDaTau = 0, 0, 0
            for id, current in self.fighterList do
                if current.nMapId == fighter.nMapId and current.mode ~= "chiendau"
                   and current.ploidaiBot ~= 1 then
                    currentTotal = currentTotal + 1
                    if current.stall == 1 then
                        if current.daTau == 1 then
                            currentDaTau = currentDaTau + 1
                        else
                            currentStall = currentStall + 1
                        end
                    end
                end
            end
            if currentTotal >= capTotal then return nil end
            if fighter.stall == 1 then
                if fighter.daTau == 1 and currentDaTau >= capDaTau then return nil end
                if fighter.daTau ~= 1 and currentStall >= capStall then return nil end
            end
        end
    end

    -- Apply the web combat settings to normal SimCity fighters.  Several spawn
    -- presets used to hard-code 15/1800 and silently ignored webconfig.lua.
    if fighter and (fighter.mode == "train" or fighter.mode == "thanhthi")
       and fighter.tongkim ~= 1 then
        fighter.RADIUS_FIGHT_PLAYER = RADIUS_FIGHT_PLAYER or 20
        fighter.RADIUS_FIGHT_NPC = RADIUS_FIGHT_NPC or 8
        fighter.RADIUS_FIGHT_SCAN = RADIUS_FIGHT_SCAN or 8
        fighter.TIME_FIGHTING_minTs = TIME_FIGHTING and TIME_FIGHTING.minTs or 6000
        fighter.TIME_FIGHTING_maxTs = TIME_FIGHTING and TIME_FIGHTING.maxTs or 6000
        fighter.TIME_RESTING_minTs = TIME_RESTING and TIME_RESTING.minTs or 0
        fighter.TIME_RESTING_maxTs = TIME_RESTING and TIME_RESTING.maxTs or 1
    end

    -- Thanh/thon citizens used to stay in "thanhthi" mode forever.  That mode
    -- is intentionally rejected by SimCityCanFight, so even citizens walking
    -- outside the peace area at a gate could never start a bot-vs-bot fight.
    -- Only turn mobile citizens into train fighters; stall NPCs remain peaceful.
    if fighter and fighter.mode == "thanhthi" and fighter.stall ~= 1
       and (SIMCITY_GATE_COMBAT == nil or SIMCITY_GATE_COMBAT == 1) then
        local nW = fighter.nMapId
        local isCity = SimCityWorld and SimCityWorld.IsThanhThiMap
                       and SimCityWorld:IsThanhThiMap(nW) == 1
        local isVillage = nW == 53 or nW == 20 or nW == 99 or nW == 100
                          or nW == 101 or nW == 121 or nW == 153 or nW == 174
        if isCity or isVillage then
            fighter.mode = "train"
            fighter.noStop = 1
            fighter.CHANCE_ATTACK_PLAYER = 1
            fighter.CHANCE_ATTACK_NPC = 1
            fighter.CHANCE_JOIN_FIGHT = 1
            fighter.RADIUS_FIGHT_PLAYER = RADIUS_FIGHT_PLAYER or 20
            fighter.RADIUS_FIGHT_NPC = RADIUS_FIGHT_NPC or 8
            fighter.RADIUS_FIGHT_SCAN = RADIUS_FIGHT_SCAN or 8
            fighter.TIME_FIGHTING_minTs = TIME_FIGHTING and TIME_FIGHTING.minTs or 6000
            fighter.TIME_FIGHTING_maxTs = TIME_FIGHTING and TIME_FIGHTING.maxTs or 6000
            fighter.TIME_RESTING_minTs = TIME_RESTING and TIME_RESTING.minTs or 0
            fighter.TIME_RESTING_maxTs = TIME_RESTING and TIME_RESTING.maxTs or 1
        end
    end

    self:initCharConfig(fighter)
    local nListId = self:AcquireListId()
    self.totalFighters = (self.totalFighters or 0) + 1
    local tbNpc = {
        id = nListId,
        children = nil,
        worldInfo = SimCityWorld:Get(fighter.nMapId),
        last2VisitedEdges = {},
        processGroup = mod(self.totalFighters, 2) + 1,
    }
    local isLienDauMap = fighter
        and (fighter.liendauHallManaged == 1 or fighter.liendauCombatManaged == 1)
    if not tbNpc.worldInfo or (not tbNpc.worldInfo.worldId and not isLienDauMap) then
        self.totalFighters = self.totalFighters - 1
        self:ReleaseListId(nListId)
        return nil
    end
    for k, v in fighter do tbNpc[k] = v end

    if tbNpc.mode == nil or tbNpc.mode == "thanhthi" or tbNpc.mode == "train" then
        if tbNpc.worldInfo.showName == 1 then
            if not tbNpc.szName or tbNpc.szName == "" then
                tbNpc.szName = SimCityNPCInfo:getName(tbNpc.nNpcId)
            end
        else
            tbNpc.szName = " "
        end
    end

    self.fighterList[nListId] = tbNpc
    if tbNpc.movementSys:resetPos(self, nListId) == 0 then
        self.fighterList[nListId] = nil
        self.totalFighters = self.totalFighters - 1
        self:ReleaseListId(nListId)
        return nil
    end

    local created = tbNpc.entitySys:CreateChar(self, tbNpc, 1, tbNpc.goX32, tbNpc.goY32)
    if not created or created == 0 then
        self:ScheduleSpawnRetry(tbNpc, 0)
        return nListId
    end
    self:initChildrenConfig(nListId, fighter)
    return nListId
end

-- The original IsActive always made train-mode bots attack players, even when
-- the web checkbox was off.  Preserve self-defence but otherwise respect it.
if SimMovement and SimMovement.Citizen and SimMovement.Citizen.IsActive then
    SIMCITY_ORIGINAL_CITIZEN_IS_ACTIVE = SIMCITY_ORIGINAL_CITIZEN_IS_ACTIVE
        or SimMovement.Citizen.IsActive
    SimMovement.Citizen.IsActive = function(self, simInstance, tbNpc)
        local result = SIMCITY_ORIGINAL_CITIZEN_IS_ACTIVE(self, simInstance, tbNpc)
        if SIMBOT_AGGRO_PLAYER ~= 1 then
            local selfDef = tbNpc.selfDefTick and tbNpc.tick_breath
                            and tbNpc.selfDefTick > tbNpc.tick_breath
            if not selfDef then tbNpc.isPlayerEnemyAround = 0 end
        end
        return result
    end
end

function SimCitizen:initChildrenConfig(nListId, parentConfig)
    local tbNpc = self.fighterList[nListId]
    if not tbNpc or not tbNpc.childrenSetup or getn(tbNpc.childrenSetup) <= 0 then return end
    local createdChildren = {}
    local nX32, nY32 = GetNpcPos(tbNpc.finalIndex)
    for i = 1, getn(tbNpc.childrenSetup) do
        local childConfig = objCopy(parentConfig)
        childConfig.faction = nil
        childConfig.series = nil
        childConfig.nSettingsIdx = nil
        childConfig.skillHoTro = nil
        childConfig.parentID = tbNpc.id
        childConfig.childID = i
        childConfig.role = "child"
        childConfig.hardsetName = nil
        childConfig.childrenSetup = nil
        for k, v in tbNpc.childrenSetup[i] do childConfig[k] = v end
        childConfig.goX32 = nX32
        childConfig.goY32 = nY32
        local childId = self:New(childConfig)
        if childId then tinsert(createdChildren, childId) end
    end
    tbNpc.children = createdChildren
end

function SimCityThanhThi:countMap(nW)
    local count = 0
    for id, fighter in SimCitizen.fighterList do
        if fighter.nMapId == nW then
            if fighter.finalIndex and fighter.finalIndex > 0 and SimCitizen:IsOwnedNpc(fighter) == 1 then
                count = count + 1
            elseif fighter.spawnRetryTick or fighter.isDead == 1 then
                count = count + 1
            end
        end
    end
    return count
end

function SimCityThanhThi:createRefillNpcs(nW, amount)
    if not amount or amount <= 0 then return 0 end
    local worldInfo = SimCityWorld:Get(nW)
    if not worldInfo or not worldInfo.worldId then return 0 end
    local pool = {2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,
        2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,2023}
    local made = 0
    for i = 1, amount do
        local cfg = { ngoaitrang = 1, level = 95, capHP = 1, walkMode = "random" }
        -- Sap hang chi duoc tao theo dung lo tableStall trong pthanhthi.lua
        -- nhu /home/old/s1. Watchdog chi bu bot di chuyen/chien dau, khong tao
        -- them sap le co vong doi khac voi sap goc.
        if worldInfo.isTrainMap == 1 then
            cfg.mode = "train"
            cfg.noStop = 1
            cfg.camp = mod(i - 1, 4) + 1
            cfg.CHANCE_ATTACK_PLAYER = 1
            cfg.CHANCE_ATTACK_NPC = 1
            cfg.CHANCE_JOIN_FIGHT = 1
        end
        local id = self:_createSingle(pool[random(1, getn(pool))], nW, cfg)
        if id then made = made + 1 end
    end
    return made
end

SIMCITY_ORIGINAL_ENTER_MAP = SIMCITY_ORIGINAL_ENTER_MAP or SimCityThanhThi.onPlayerEnterMap
function SimCityThanhThi:onPlayerEnterMap()
    -- Use namespaced web values to avoid the legacy globals being reset by a
    -- second config.lua context in the JX script engine.
    if SIMCITY_WEB_CITY_SIZE then THANHTHI_SIZE = SIMCITY_WEB_CITY_SIZE end
    if SIMCITY_WEB_VILLAGE_SIZE then THON_SIZE = SIMCITY_WEB_VILLAGE_SIZE end
    local nW = GetWorldPos()
    local worldInfo = SimCityWorld:Get(nW)
    if worldInfo then
        worldInfo.simcityActivated = 1
        if SimCityWorld:IsThanhThiMap(nW) == 1
           or SimCityWatchdog:IsVillage(nW) == 1 then
            worldInfo.allowFighting = 0
            worldInfo.cityPeace = 1
        end
    end
    return SIMCITY_ORIGINAL_ENTER_MAP(self)
end

SIMCITY_ORIGINAL_EXIT_MAP = SIMCITY_ORIGINAL_EXIT_MAP or SimCityThanhThi.onPlayerExitMap
function SimCityThanhThi:onPlayerExitMap()
    if SIMCITY_PERSIST_EMPTY_MAPS ~= 1 then return SIMCITY_ORIGINAL_EXIT_MAP(self) end
    local nW = GetWorldPos()
    local worldInfo = SimCityWorld:Get(nW)
    if worldInfo and worldInfo.playerTracker then
        if worldInfo.playerTracker[PlayerIndex] then
            worldInfo.playerTracker[PlayerIndex] = nil
            worldInfo.playerTrackerCount = (worldInfo.playerTrackerCount or 1) - 1
            if worldInfo.playerTrackerCount < 0 then worldInfo.playerTrackerCount = 0 end
        end
    end
    return 1
end

SIMCITY_ORIGINAL_AUTO_CREATE = SIMCITY_ORIGINAL_AUTO_CREATE or SimCityThanhThi.autoCreateNpc
function SimCityThanhThi:autoCreateNpc(nW)
    local worldInfo = SimCityWorld:Get(nW)
    if SIMCITY_PERSIST_EMPTY_MAPS == 1 and worldInfo and worldInfo.worldId then
        if (worldInfo.playerTrackerCount or 0) > 0 then
            worldInfo.simcityActivated = 1
            return SIMCITY_ORIGINAL_AUTO_CREATE(self, nW)
        end
        -- Khong xoa dan so khi nguoi choi roi map; watchdog se tiep tuc bu.
        self.playerTimerIdsByMap[nW] = nil
        return 1
    end
    return SIMCITY_ORIGINAL_AUTO_CREATE(self, nW)
end

function SimCitySetTongKimWarState(nW, active)
    local worldInfo = SimCityWorld:Get(nW)
    if not worldInfo or not worldInfo.worldId then return end
    worldInfo.tkWarStarted = active
    if active == 1 then
        worldInfo.allowFighting = 1
        worldInfo.cityPeace = 0
    end
    for id, fighter in SimCitizen.fighterList do
        if fighter.nMapId == nW and fighter.tongkim == 1 then
            fighter.tick_canWalk = active == 1 and 0 or (fighter.tick_breath or 0) + 30
            fighter.isStanding = 0
            fighter.peaceState = active == 1 and 0 or fighter.peaceState
            if active == 1 and fighter.finalIndex and fighter.finalIndex > 0
               and SimCitizen:IsOwnedNpc(fighter) == 1 then
                if SetNpcPeace then SetNpcPeace(fighter.finalIndex, 0) end
                if SetNpcCombat then
                    SetNpcCombat(fighter.finalIndex, 1, fighter.skillCastBua and fighter.skillCastBua[1] or 0)
                end
            end
        end
    end
end

-- Battle mission scripts run in a different JX script environment.  This Lua
-- build neither carries callback globals into that environment nor supports
-- closure upvalues, so removeAll must be self-contained.  This is the original
-- removeAll behavior plus the Tong Kim runtime-state cleanup.
function SimCityChienTranh:removeAll(targetWorld)
    for key, worldInfo in SimCityWorld.data do
        if not targetWorld or worldInfo.worldId == targetWorld then
            self.nW = worldInfo.worldId
            SimCitizen:ClearMap(self.nW, "chiendau")
            if SimCityWorld:IsTongKimMap(worldInfo.worldId) == 1 then
                worldInfo.tkWarStarted = 0
                for id, fighter in SimCitizen.fighterList do
                    if fighter.nMapId == worldInfo.worldId and fighter.tongkim == 1 then
                        fighter.tick_canWalk = (fighter.tick_breath or 0) + 30
                        fighter.isStanding = 0
                    end
                end
            end
        end
    end
end

end -- delayed hooks

function SimCityWatchdog:IsVillage(nW)
    if nW == 53 or nW == 20 or nW == 99 or nW == 100 or nW == 101
       or nW == 121 or nW == 153 or nW == 174 then return 1 end
    return 0
end

function SimCityWatchdog:IsManagedWorld(worldInfo)
    if not worldInfo or not worldInfo.worldId or worldInfo.name == "" then return 0 end
    local nW = worldInfo.worldId
    if SimCityWorld:IsTongKimMap(nW) == 1 then return 0 end
    if SubWorldID2Idx and SubWorldID2Idx(nW) < 0 then return 0 end
    if worldInfo.playerTrackerCount and worldInfo.playerTrackerCount > 0 then
        worldInfo.simcityActivated = 1
    end
    -- Chi bu dan so sau khi map da duoc nguoi choi kich hoat. Neu coi tat ca
    -- thanh/thon la managed ngay luc preload, watchdog se tao hang nghin NPC
    -- truoc ServerStart va day jx_linux_y den gioi han bo nho.
    if worldInfo.simcityActivated == 1 then return 1 end
    if worldInfo.isTrainMap == 1 and worldInfo.playerTrackerCount
       and worldInfo.playerTrackerCount > 0 then return 1 end
    return 0
end

function SimCityWatchdog:GetTarget(worldInfo)
    local nW = worldInfo.worldId
    if SimCityWorld:IsThanhThiMap(nW) == 1 then
        return SIMCITY_WEB_CITY_SIZE or THANHTHI_SIZE or 300
    end
    if self:IsVillage(nW) == 1 then
        return SIMCITY_WEB_VILLAGE_SIZE or THON_SIZE or 50
    end
    if worldInfo.isTrainMap == 1 then return SIMCITY_TRAIN_SIZE or 10 end
    return SIMCITY_DEFAULT_SIZE or 100
end

function SimCityWatchdog:Reconcile(simInstance)
    if not simInstance or not simInstance.fighterList then return 0 end
    local total = 0
    for id, fighter in simInstance.fighterList do
        total = total + 1
        if fighter.finalIndex and fighter.finalIndex > 0 then
            if simInstance.IsOwnedNpc and simInstance:IsOwnedNpc(fighter) ~= 1 then
                -- Index co the da duoc engine tai su dung cho NPC khac: khong xoa no.
                fighter.finalIndex = nil
                fighter.isDead = 0
                simInstance:ScheduleSpawnRetry(fighter, 1)
            else
                fighter.deadWatchCount = 0
            end
        elseif fighter.isDead == 1 then
            -- The normal death callback normally respawns immediately.  If the
            -- engine refuses that AddNpcEx call, recover on the next watchdog
            -- sweep instead of leaving a dead entry counted as pending forever.
            fighter.deadWatchCount = (fighter.deadWatchCount or 0) + 1
            if fighter.deadWatchCount >= 1 then
                fighter.isDead = 0
                fighter.deadWatchCount = 0
                simInstance:ScheduleSpawnRetry(fighter, 1)
                simInstance:RetrySpawn(fighter, 1)
            end
        elseif fighter.spawnRetryTick then
            -- OnTimer follows the old combat path and does not own retry work.
            -- Advance pending retries here, once per watchdog sweep.
            simInstance:RetrySpawn(fighter, SIMCITY_WATCHDOG_INTERVAL or 15 * 18)
        else
            simInstance:ScheduleSpawnRetry(fighter, 1)
            simInstance:RetrySpawn(fighter, 1)
        end
    end
    simInstance.totalFighters = total
    return total
end

function SimCityWatchdog:CountMap(nW)
    local live = 0
    local pending = 0
    for id, fighter in SimCitizen.fighterList do
        if fighter.nMapId == nW and fighter.mode ~= "chiendau" and fighter.ploidaiBot ~= 1 then
            if fighter.finalIndex and fighter.finalIndex > 0 and SimCitizen:IsOwnedNpc(fighter) == 1 then
                live = live + 1
            elseif fighter.spawnRetryTick or fighter.isDead == 1 then
                pending = pending + 1
            end
        end
    end
    return live, pending
end

function SimCityWatchdog:MaintainPopulation()
    if not SimCityThanhThi or SimCityThanhThi.autoAddThanhThi ~= 1 then return 0 end
    local globalLeft = SIMCITY_REFILL_GLOBAL_BATCH or 80
    local worlds = {}
    for key, worldInfo in SimCityWorld.data do
        if self:IsManagedWorld(worldInfo) == 1 then tinsert(worlds, worldInfo) end
    end
    local n = getn(worlds)
    if n <= 0 then return 1 end
    local startAt = self.mapCursor or 1
    if startAt > n then startAt = 1 end
    local lastIndex = startAt
    for offset = 0, n - 1 do
        if globalLeft > 0 then
            local index = mod(startAt - 1 + offset, n) + 1
            lastIndex = index
            local worldInfo = worlds[index]
            -- Dat hoa binh truoc khi tao bot bu, tranh bot danh nhau trong
            -- thanh/thon do thu tu khoi tao map.
            if SimCityWorld:IsThanhThiMap(worldInfo.worldId) == 1
               or self:IsVillage(worldInfo.worldId) == 1 then
                worldInfo.allowFighting = 0
                worldInfo.cityPeace = 1
            end
            local live, pending = self:CountMap(worldInfo.worldId)
            local missing = self:GetTarget(worldInfo) - live - pending
            if missing > 0 then
                local amount = missing
                local perMap = SIMCITY_REFILL_BATCH or 20
                if amount > perMap then amount = perMap end
                if amount > globalLeft then amount = globalLeft end
                local made = SimCityThanhThi:createRefillNpcs(worldInfo.worldId, amount)
                globalLeft = globalLeft - (made or amount)
            end
        end
    end
    self.mapCursor = mod(lastIndex, n) + 1
    return 1
end

function SimCityWatchdog:KeepTongKimFighting()
    for id, fighter in SimCitizen.fighterList do
        if fighter.tongkim == 1 and fighter.worldInfo and fighter.worldInfo.tkWarStarted == 1
           and fighter.finalIndex and fighter.finalIndex > 0 and SimCitizen:IsOwnedNpc(fighter) == 1 then
            fighter.isStanding = 0
            fighter.tick_canWalk = 0
            fighter.peaceState = 0
            if SetNpcPeace then SetNpcPeace(fighter.finalIndex, 0) end
            if SetNpcCombat then
                SetNpcCombat(fighter.finalIndex, 1, fighter.skillCastBua and fighter.skillCastBua[1] or 0)
            end
        end
    end
end

function SimCityWatchdog:Tick()
    if SIMCITY_WATCHDOG_ENABLED ~= 1 then return 1 end
    self.sweepNo = (self.sweepNo or 0) + 1
    self:Reconcile(SimCitizen)
    self:Reconcile(SimTheoSau)
    self:KeepTongKimFighting()
    self:MaintainPopulation()
    return 1
end
