-- SimCity cho Vo Lam Lien Dau - Don dau tu do.
-- File nguon UTF-8, khi cai vao server se duoc chuyen sang TCVN3.

Include("\\script\\global\\nobitaxd\\vdk\\simcity\\webconfig.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\libs\\common.lua")

-- Superseded by plugins/pliendau.lua and missions/leaguematch/bots.
-- Kept only for rollback; never install the incompatible legacy hooks.
if 1 == 1 then return end

SimCityLeague = SimCityLeague or {
    active = {},
    botToPlayer = {},
}

SimCityLeague.active = SimCityLeague.active or {}
SimCityLeague.botToPlayer = SimCityLeague.botToPlayer or {}

local tbLeagueNpcIds = {1786,1787,1788,1789,1790,1791,1792,1793,1794,1795}
local tbLeagueSkills = {
    [1786] = {325,20},
    [1787] = {318,20},
    [1788] = {353,20},
    [1789] = {302,20},
    [1790] = {328,20},
    [1791] = {336,20},
    [1792] = {715,20},
    [1793] = {357,20},
    [1794] = {368,20},
    [1795] = {717,20},
}
local tbHallSkills = {
    [2000]={318,20}, [2001]={319,20}, [2002]={321,20},
    [2003]={322,20}, [2004]={323,20}, [2005]={325,20},
    [2006]={339,20}, [2007]={342,20}, [2008]={302,20},
    [2009]={302,20}, [2010]={353,20}, [2011]={355,20},
    [2012]={328,20}, [2013]={380,20}, [2014]={336,20},
    [2015]={337,20}, [2016]={357,20}, [2017]={359,20},
    [2018]={361,20}, [2019]={362,20}, [2020]={365,20},
    [2021]={368,20}, [2022]={372,20}, [2023]={375,20},
}

function SimCityLeague:IsEnabled()
    return SIMCITY_LEAGUE_ENABLED == 1
end

function SimCityLeague:IsSingleType()
    if not GetGlbValue or not WLLS_TAB then return nil end
    local nType = GetGlbValue(GLB_WLLS_TYPE)
    local nSingleType = tonumber(SIMCITY_LEAGUE_MATCH_TYPE) or 5
    return nType == nSingleType
        and WLLS_TAB[nType]
        and WLLS_TAB[nType].max_member == 1
end

function SimCityLeague:CanReplaceBye(nCamp)
    return self:IsEnabled() and self:IsSingleType() and nCamp and nCamp > 0
end

function SimCityLeague:EnsureWorld(nMap, nX, nY)
    if not SimCityWorld or not SimCityWorld.Get or not SimCityWorld.New then return nil end
    local centerKey = tostring(nX).."_"..tostring(nY)
    local world = SimCityWorld:Get(nMap)
    if not world or not world.worldId then
        local nodes = {}
        for ix = -2, 2 do
            for iy = -2, 2 do
                local px = nX + ix * 8
                local py = nY + iy * 8
                local key = tostring(px).."_"..tostring(py)
                nodes[key] = {
                    x=px, y=py, linkedNodes={centerKey}, isExact=0,
                    nodeType=0, isNearAtraction=0, isNotPreset=1
                }
            end
        end
        nodes[centerKey].linkedNodes = {}
        for key, node in nodes do
            if key ~= centerKey then tinsert(nodes[centerKey].linkedNodes, key) end
        end
        world = SimCityWorld:New({
            worldId = nMap,
            name = "Vâ L©m Liªn §Êu",
            showName = 1,
            allowFighting = 1,
            cityPeace = 0,
            firstNode = {nX, nY},
            nodes = nodes,
        })
    end
    if world then
        world.showName = 1
        world.allowFighting = 1
        world.cityPeace = 0
    end
    return world, centerKey
end

function SimCityLeague:IsLiveHallSim(tb, nMap)
    if not tb or tb.nMapId ~= nMap or not tb.finalIndex
        or tb.finalIndex <= 0 or tb.isDead == 1 then
        return nil
    end
    if GetNpcPos then
        local nX32, nY32, nMapIndex = GetNpcPos(tb.finalIndex)
        if not nX32 or not nY32 then return nil end
        if nMapIndex and SubWorldIdx2ID
            and SubWorldIdx2ID(nMapIndex) ~= nMap then return nil end
    end
    if GetNpcParam and GetNpcParam(tb.finalIndex, 4) ~= 1 then return nil end
    return 1
end

function SimCityLeague:CountHallCitizens(nMap)
    local count = 0
    if not SimCitizen or not SimCitizen.fighterList then return count end
    for id, tb in SimCitizen.fighterList do
        if tb and tb.leagueHall == 1 and self:IsLiveHallSim(tb, nMap) then
            count = count + 1
        end
    end
    return count
end

function SimCityLeague:PopulateHall(nMap, nX, nY)
    if not self:IsEnabled() or not self:IsSingleType() then return nil end
    if not SimCityThanhThi or not SimCityThanhThi._createSingle then
        WriteLog("SIMCITY_WLLS\tPopulateFail\tThanhThiMissing")
        return nil
    end
    local world = self:EnsureWorld(nMap, nX, nY)
    if not world then
        WriteLog("SIMCITY_WLLS\tPopulateFail\tWorld:"..tostring(nMap))
        return nil
    end
    world.showName = 1
    world.allowFighting = 0
    world.cityPeace = 1
    self.hallMap = nMap
    self.hallX = nX
    self.hallY = nY
    local stale = {}
    for id, tb in SimCitizen.fighterList do
        if tb and tb.leagueHall == 1 and tb.nMapId == nMap
            and tb.leagueBot ~= 1 and not self:IsLiveHallSim(tb, nMap) then
            tinsert(stale, id)
        end
    end
    for i = 1, getn(stale) do
        local tb = SimCitizen.fighterList[stale[i]]
        if tb then
            tb.finalIndex = nil
            tb._ownerRemove = 1
            SimCitizen:Remove(stale[i])
        end
    end
    local target = tonumber(SIMCITY_LEAGUE_HALL_COUNT) or 30
    local current = self:CountHallCitizens(nMap)
    if current >= target then return 1 end

    -- Héi tr­êng ph¶i cã ®ñ SIM ngay khi më. Kh«ng dïng batch timer v× mçi
    -- batch chØ hiÖn kho¶ng 6 ng­êi vµ c¸c batch sau cã thÓ bÞ map ®ãng mÊt.
    if SimCityThanhThi.timerIdsByMap and SimCityThanhThi.timerIdsByMap[nMap] then
        SimCityThanhThi.timerIdsByMap[nMap].canceled = true
        SimCityThanhThi.batchesByMap[nMap] = nil
    end
    local need = target - current
    for i = 1, need do
        local slot = current + i
        local fixedX = nX + (mod(slot - 1, 6) - 3) * 2
        local fixedY = nY + (floor((slot - 1) / 6) - 2) * 2
        local botId = SimCityThanhThi:_createSingle(random(2000, 2023), nMap, {
            ngoaitrang = 1,
            leagueHall = 1,
            level = tonumber(SIMCITY_LEAGUE_BOT_LEVEL) or 95,
            capHP = 1,
            camp = random(1, 4),
            goX32 = fixedX * 32,
            goY32 = fixedY * 32,
            isStanding = 1,
            walkMode = "random",
            walkVar = 0,
            noRevive = 0,
            resetPosWhenRevive = 1,
            CHANCE_ATTACK_PLAYER = 0,
            CHANCE_ATTACK_NPC = 0,
            CHANCE_JOIN_FIGHT = 0,
        })
        local tbNew = botId and SimCitizen.fighterList[botId]
        if tbNew and tbNew.finalIndex and SetNpcParam then
            local nGender = (tbNew.nSettingsIdx == -2) and 2 or 1
            local nLook = nGender
                + (tonumber(tbNew.nNewHelmType) or 0) * 10
                + (tonumber(tbNew.nNewArmorType) or 0) * 1000
                + (tonumber(tbNew.nNewWeaponType) or 0) * 100000
                + (tonumber(tbNew.nNewHorseType) or 0) * 10000000
            SetNpcParam(tbNew.finalIndex, 2, nLook)
        end
    end
    for id, tb in SimCitizen.fighterList do
        if tb and tb.leagueHall == 1 and self:IsLiveHallSim(tb, nMap) then
            tb.isStanding = 1
            tb.isFighting = 0
            if SetNpcAI then SetNpcAI(tb.finalIndex, 0) end
            if SetNpcPeace then SetNpcPeace(tb.finalIndex, 1) end
        end
    end
    local created = self:CountHallCitizens(nMap)
    WriteLog("SIMCITY_WLLS\tPopulateHall\tMap:"..tostring(nMap)
        .."\tBefore:"..tostring(current).."\tAfter:"..tostring(created)
        .."\tTarget:"..tostring(target))
    return created > 0 and 1 or nil
end

function SimCityLeague:CreateHallCitizen(pidx, nPlayerCamp)
    if not SimCitizen or not SimCitizen.fighterList then
        WriteLog("SIMCITY_WLLS\tCreateHallFail\tSimCitizenMissing")
        return nil
    end
    local oldPlayer = PlayerIndex
    PlayerIndex = pidx
    local nPlayerMap, nHallX, nHallY = GetWorldPos()
    PlayerIndex = oldPlayer
    local nHallMap = self.hallMap or nPlayerMap
    if not nHallMap or not nHallX or not nHallY then
        WriteLog("SIMCITY_WLLS\tCreateHallFail\tPlayerPos\tPlayer:"..tostring(pidx)
            .."\tMap:"..tostring(nPlayerMap).."\tX:"..tostring(nHallX)
            .."\tY:"..tostring(nHallY))
        return nil
    end
    self:PopulateHall(nHallMap, self.hallX or nHallX, self.hallY or nHallY)
    local list = {}
    local tagged = 0
    local allValid = 0
    for id, tb in SimCitizen.fighterList do
        if self:IsLiveHallSim(tb, nHallMap)
            and tb.leagueBot ~= 1 and not tb.partyPlayerId then
            allValid = allValid + 1
            if tb.leagueHall == 1 then tagged = tagged + 1 end
            if tb.leagueHall == 1 or tb.mode == "thanhthi" then
                tinsert(list, id)
            end
        end
    end
    if getn(list) < 1 then
        WriteLog("SIMCITY_WLLS\tCreateHallFail\tNoHallCitizen\tMap:"..tostring(nHallMap)
            .."\tTagged:"..tostring(tagged).."\tValid:"..tostring(allValid)
            .."\tPlayerMap:"..tostring(nPlayerMap))
        return nil
    end
    local botId = list[random(1, getn(list))]
    local tb = SimCitizen.fighterList[botId]
    tb.leagueBot = 1
    tb.leaguePlayerId = pidx
    WriteLog("SIMCITY_WLLS\tSelectHallCitizen\tBotId:"..tostring(botId)
        .."\tNpc:"..tostring(tb.finalIndex).."\tMap:"..tostring(nHallMap)
        .."\tName:"..tostring(tb.szName))
    return botId, tb
end

function SimCityLeague:CreateFreshBot(nMap, nX, nY, nBotCamp, pidx)
    if not SimCitizen or not SimCitizen.New then return nil end
    local world, nPosId = self:EnsureWorld(nMap, nX, nY)
    if not world then
        tb.leagueMoving = nil
        return nil
    end

    local nNpcId = random(2000, 2023)
    local szName = SimCityNPCInfo and SimCityNPCInfo.generateName
        and SimCityNPCInfo:generateName() or nil
    local botId = SimCitizen:New({
        nNpcId = nNpcId,
        nMapId = nMap,
        nPosId = nPosId,
        goX32 = (nX + 4) * 32,
        goY32 = nY * 32,
        hardsetName = szName,
        ngoaitrang = 1,
        mode = "thanhthi",
        level = tonumber(SIMCITY_LEAGUE_BOT_LEVEL) or 95,
        capHP = "auto",
        maxHP = tonumber(SIMCITY_LEAGUE_BOT_HP) or 120000,
        camp = nBotCamp,
        walkMode = "random",
        walkVar = 2,
        noRevive = 1,
        resetPosWhenRevive = 1,
        leagueBot = 1,
        leaguePlayerId = pidx,
        CHANCE_ATTACK_PLAYER = 0,
        CHANCE_ATTACK_NPC = 0,
        CHANCE_JOIN_FIGHT = 0,
    })
    local tb = botId and SimCitizen.fighterList[botId]
    if not tb or not tb.finalIndex or tb.finalIndex <= 0 then
        WriteLog("SIMCITY_WLLS\tCreateFreshFail\tMap:"..tostring(nMap))
        return nil
    end
    if SetNpcCurCamp then SetNpcCurCamp(tb.finalIndex, nBotCamp) end
    if SetTmpCamp then SetTmpCamp(nBotCamp, tb.finalIndex) end
    if SetNpcKind then SetNpcKind(tb.finalIndex, 0) end
    if SetNpcPeace then SetNpcPeace(tb.finalIndex, 1) end
    WriteLog("SIMCITY_WLLS\tCreateFreshOK\tBotId:"..tostring(botId)
        .."\tNpc:"..tostring(tb.finalIndex).."\tMap:"..tostring(nMap))
    return botId, tb
end

function SimCityLeague:SelectNativeHallSim(pidx)
    local oldPlayer = PlayerIndex
    local oldWorld = SubWorld
    PlayerIndex = pidx
    local nMap, nX, nY = GetWorldPos()
    if nMap and SubWorldID2Idx then SubWorld = SubWorldID2Idx(nMap) end
    local around = GetAroundNpcList and GetAroundNpcList(80) or {}
    local candidates = {}
    for i = 1, getn(around) do
        local nNpcIndex = around[i]
        local nTemplate = GetNpcSettingIdx and GetNpcSettingIdx(nNpcIndex) or 0
        local isSim = GetNpcParam and GetNpcParam(nNpcIndex, 4) or 0
        local nKind = GetNpcKind and GetNpcKind(nNpcIndex) or -1
        if isSim == 1 and nKind == 0 and nTemplate >= 2000 and nTemplate <= 2023 then
            tinsert(candidates, nNpcIndex)
        end
    end
    if getn(candidates) < 1 then
        PlayerIndex = oldPlayer
        SubWorld = oldWorld
        WriteLog("SIMCITY_WLLS\tNativeHallFail\tNoNpc\tPlayer:"..tostring(pidx)
            .."\tMap:"..tostring(nMap).."\tAround:"..tostring(getn(around)))
        return nil
    end
    local nHallNpc = candidates[random(1, getn(candidates))]
    local tb = {
        hallNpc = nHallNpc,
        hallMap = nMap,
        hallX = nX,
        hallY = nY,
        nNpcId = GetNpcSettingIdx(nHallNpc),
        level = NPCINFO_GetLevel and NPCINFO_GetLevel(nHallNpc)
            or (tonumber(SIMCITY_LEAGUE_BOT_LEVEL) or 95),
        series = GetNpcSeries and GetNpcSeries(nHallNpc) or random(0,4),
        szName = GetNpcName(nHallNpc),
        appearance = GetNpcParam and GetNpcParam(nHallNpc, 2) or 0,
    }
    tb.skillCastBua = %tbHallSkills[tb.nNpcId] or {325,20}
    PlayerIndex = oldPlayer
    SubWorld = oldWorld
    WriteLog("SIMCITY_WLLS\tNativeHallSelect\tNpc:"..tostring(nHallNpc)
        .."\tTemplate:"..tostring(tb.nNpcId).."\tName:"..tostring(tb.szName)
        .."\tCandidates:"..tostring(getn(candidates)))
    return tb
end

function SimCityLeague:CreateNativeHallBot(nMap, nX, nY, nBotCamp, pidx, tbHall)
    if not tbHall or not tbHall.nNpcId then return nil end
    local nMapIndex = SubWorldID2Idx(nMap)
    if not nMapIndex or nMapIndex < 0 then
        WriteLog("SIMCITY_WLLS\tNativeCreateFail\tBadMap:"..tostring(nMap))
        return nil
    end
    local nNpcIndex = AddNpcEx(
        tbHall.nNpcId,
        tbHall.level or (tonumber(SIMCITY_LEAGUE_BOT_LEVEL) or 95),
        tbHall.series or random(0,4),
        nMapIndex, (nX + 4) * 32, nY * 32, 1,
        tbHall.szName or "Cao thñ SimCity", 0
    )
    if not nNpcIndex or nNpcIndex <= 0 then
        WriteLog("SIMCITY_WLLS\tNativeCreateFail\tAddNpcEx\tTemplate:"
            ..tostring(tbHall.nNpcId))
        return nil
    end
    local nHP = tonumber(SIMCITY_LEAGUE_BOT_HP) or 120000
    if nHP < 1000 then nHP = 1000 end
    if NPCINFO_SetNpcCurrentMaxLife then NPCINFO_SetNpcCurrentMaxLife(nNpcIndex, nHP) end
    if NPCINFO_SetNpcCurrentLife then NPCINFO_SetNpcCurrentLife(nNpcIndex, nHP) end
    if SetNpcAtkSpeed then SetNpcAtkSpeed(nNpcIndex, SIMBOT_ATTACK_SPEED or 250) end
    if SetNpcCurCamp then SetNpcCurCamp(nNpcIndex, nBotCamp) end
    if SetTmpCamp then SetTmpCamp(nBotCamp, nNpcIndex) end
    if SetNpcKind then SetNpcKind(nNpcIndex, 3) end
    if SetNpcActiveRegion then SetNpcActiveRegion(nNpcIndex, 1) end
    if SetNpcParam then
        SetNpcParam(nNpcIndex, 1, pidx)
        SetNpcParam(nNpcIndex, 4, 1)
    end
    if SetNpcScript then
        SetNpcScript(nNpcIndex, "\\script\\missions\\leaguematch\\combat\\simcity_npcdeath.lua")
    end
    if SetNpcDeathScript then
        SetNpcDeathScript(nNpcIndex, "\\script\\missions\\leaguematch\\combat\\simcity_npcdeath.lua")
    end
    if SetNpcPeace then SetNpcPeace(nNpcIndex, 1) end
    local nLook = tonumber(tbHall.appearance) or 0
    if nLook > 0 and ChangeNpcFeature then
        local nGender = mod(nLook, 10)
        local nHelm = mod(floor(nLook / 10), 100)
        local nArmor = mod(floor(nLook / 1000), 100)
        local nWeapon = mod(floor(nLook / 100000), 100)
        local nHorse = mod(floor(nLook / 10000000), 100)
        local nSettingsIdx = (nGender == 2) and -2 or -1
        ChangeNpcFeature(nNpcIndex, 0, 0, nSettingsIdx,
            nHelm, nArmor, nWeapon, nHorse)
        if SetNpcRideHorse then SetNpcRideHorse(nNpcIndex, 1) end
    end

    -- ChØ rót SIM khái Héi tr­êng sau khi b¶n thÓ ë ®Êu tr­êng ®· t¹o thµnh c«ng.
    if tbHall.hallNpc and tbHall.hallNpc > 0 then DelNpcSafe(tbHall.hallNpc) end
    WriteLog("SIMCITY_WLLS\tNativeCreateOK\tHallNpc:"..tostring(tbHall.hallNpc)
        .."\tCombatNpc:"..tostring(nNpcIndex).."\tMap:"..tostring(nMap)
        .."\tName:"..tostring(tbHall.szName))
    return nNpcIndex, {
        finalIndex = nNpcIndex,
        szName = tbHall.szName,
        skillCastBua = tbHall.skillCastBua,
        directNpc = 1,
    }
end

-- Chuyen CHINH SimCitizen o hoi truong vao dau truong, cung co che voi
-- BotDuel:PutBotInArena cua Loi dai Cong Binh Tu.
function SimCityLeague:PutHallBotInCombat(botId, tb, nMap, nX, nY, nBotCamp, pidx)
    if not botId or not tb or not SimCitizen or not SimEntity then return nil end
    local oldX32, oldY32 = GetNpcPos and GetNpcPos(tb.finalIndex)
    tb.leagueHallState = {
        mapId = tb.nMapId,
        posId = tb.nPosId,
        x32 = oldX32 or ((self.hallX or nX) * 32),
        y32 = oldY32 or ((self.hallY or nY) * 32),
        walkMode = tb.walkMode,
        isStanding = tb.isStanding,
        camp = tb.camp,
        noRevive = tb.noRevive,
        maxHP = tb.maxHP,
    }
    tb.leagueMoving = 1
    if tb.finalIndex and tb.finalIndex > 0 then
        if PartyClear then PartyClear(tb.finalIndex) end
        if BotDuelDisarm then BotDuelDisarm(tb.finalIndex) end
        DelNpcSafe(tb.finalIndex)
    end

    local world, nPosId = self:EnsureWorld(nMap, nX, nY)
    if not world then return nil end
    world.allowFighting = 1
    world.cityPeace = 0
    tb.finalIndex = nil
    tb.isDead = 0
    tb.nMapId = nMap
    tb.worldInfo = world
    tb.nPosId = nPosId
    tb.goX32 = (nX + 4) * 32
    tb.goY32 = nY * 32
    tb.walkMode = "random"
    tb.walkVar = 2
    tb.isStanding = 0
    tb.isFighting = 1
    tb.camp = nBotCamp
    tb.partyOldCamp = nil
    tb.partyPlayerId = nil
    tb.partyTarget = nil
    tb.partyHuntCamp = nil
    tb.botDuelTarget = nil
    tb.duelPlayerId = pidx
    tb.duelTicks = 999999
    tb.isPlayerEnemyAround = pidx
    tb.noRevive = 1
    tb.leagueBot = 1
    tb.leaguePlayerId = pidx
    tb.peaceState = 0
    tb.peaceFlip = 0
    tb.peaceTick = 0
    tb.botCombatTick = nil
    tb.duelCombatTick = nil
    tb.duelArmTick = nil

    SimEntity.Citizen.CreateChar(
        SimEntity.Citizen, SimCitizen, tb, 0, tb.goX32, tb.goY32
    )
    if not tb.finalIndex or tb.finalIndex <= 0 then
        tb.leagueMoving = nil
        WriteLog("SIMCITY_WLLS\tRealMoveFail\tBotId:"..tostring(botId)
            .."\tMap:"..tostring(nMap))
        return nil
    end
    if SetNpcCurCamp then SetNpcCurCamp(tb.finalIndex, nBotCamp) end
    if SetTmpCamp then SetTmpCamp(nBotCamp, tb.finalIndex) end
    if SetNpcKind then SetNpcKind(tb.finalIndex, 0) end
    if SetNpcActiveRegion then SetNpcActiveRegion(tb.finalIndex, 1) end
    if SetNpcPeace then SetNpcPeace(tb.finalIndex, 0) end
    tb.leagueMoving = nil
    WriteLog("SIMCITY_WLLS\tRealMoveOK\tBotId:"..tostring(botId)
        .."\tNpc:"..tostring(tb.finalIndex).."\tMap:"..tostring(nMap)
        .."\tName:"..tostring(tb.szName))
    return botId, tb
end

function SimCityLeague:CreateBot(nMap, nX, nY, nBotCamp, pidx)
    WriteLog("SIMCITY_WLLS\tCreateBotBegin\tMap:"..tostring(nMap)
        .."\tPos:"..tostring(nX)..","..tostring(nY))
    if SimCitizen and SimCitizen.fighterList and SimEntity then
        local botId, tb = self:CreateHallCitizen(pidx, nBotCamp)
        if not botId or not tb then
            WriteLog("SIMCITY_WLLS\tCreateBotFail\tNoRealHallSim")
            return nil
        end
        return self:PutHallBotInCombat(botId, tb, nMap, nX, nY, nBotCamp, pidx)
    end
    local tbHall = self:SelectNativeHallSim(pidx)
    if not tbHall then
        WriteLog("SIMCITY_WLLS\tCreateBotFail\tNoHallSim")
        return nil
    end
    return self:CreateNativeHallBot(nMap, nX, nY, nBotCamp, pidx, tbHall)
end

function SimCityLeague:RestoreHallBot(tb)
    if not tb then return nil end
    local state = tb.leagueHallState
    if not state or not state.mapId then return nil end
    if tb.finalIndex and tb.finalIndex > 0 then
        if BotDuelDisarm then BotDuelDisarm(tb.finalIndex) end
        DelNpcSafe(tb.finalIndex)
    end
    tb.finalIndex = nil
    tb.isDead = 0
    tb.nMapId = state.mapId
    tb.worldInfo = SimCityWorld:Get(state.mapId)
    tb.nPosId = state.posId
    tb.goX32 = state.x32
    tb.goY32 = state.y32
    tb.walkMode = state.walkMode or "random"
    tb.isStanding = state.isStanding or 1
    tb.isFighting = 0
    tb.camp = state.camp or random(1, 4)
    tb.noRevive = state.noRevive or 0
    tb.maxHP = state.maxHP
    tb.lastHP = nil
    tb.duelPlayerId = nil
    tb.duelTicks = nil
    tb.isPlayerEnemyAround = nil
    tb.leaguePlayerId = nil
    tb.leagueBot = nil
    tb.leagueHallState = nil
    tb.peaceState = 1
    if not tb.worldInfo then
        WriteLog("SIMCITY_WLLS\tRestoreHallFail\tWorld:"..tostring(state.mapId))
        return nil
    end
    SimEntity.Citizen.CreateChar(
        SimEntity.Citizen, SimCitizen, tb, 0, state.x32, state.y32
    )
    if not tb.finalIndex or tb.finalIndex <= 0 then
        WriteLog("SIMCITY_WLLS\tRestoreHallFail\tCreate\tBotId:"..tostring(tb.id))
        return nil
    end
    if SetNpcCurCamp then SetNpcCurCamp(tb.finalIndex, tb.camp) end
    if SetTmpCamp then SetTmpCamp(tb.camp, tb.finalIndex) end
    if SetNpcPeace then SetNpcPeace(tb.finalIndex, 1) end
    WriteLog("SIMCITY_WLLS\tRestoreHallOK\tBotId:"..tostring(tb.id)
        .."\tNpc:"..tostring(tb.finalIndex).."\tMap:"..tostring(tb.nMapId))
    return 1
end

function SimCityLeague:StartOdd(tbLeague, nOrgCamp, nNewCamp, tbPos)
    if not self:IsEnabled() then
        WriteLog("SIMCITY_WLLS\tStartOddSkip\tDisabled")
        return nil
    end
    if not nOrgCamp or nOrgCamp <= 0 or not tbLeague or not tbLeague.tbPlayer then
        WriteLog("SIMCITY_WLLS\tStartOddSkip\tBadInput\tCamp:"..tostring(nOrgCamp))
        return nil
    end
    local nLeagueType = tbLeague.nLGID
        and LG_GetLeagueTask(tbLeague.nLGID, WLLS_LGTASK_STYPE) or 0
    local nSingleType = tonumber(SIMCITY_LEAGUE_MATCH_TYPE) or 5
    if nLeagueType ~= nSingleType then
        WriteLog("SIMCITY_WLLS\tStartOddSkip\tLeagueType:"..tostring(nLeagueType)
            .."\tExpected:"..tostring(nSingleType))
        return nil
    end
    if getn(tbLeague.tbPlayer) ~= 1 then
        WriteLog("SIMCITY_WLLS\tStartOddSkip\tMemberCount:"..tostring(getn(tbLeague.tbPlayer)))
        return nil
    end
    local pidx = tbLeague.tbPlayer[1]
    if not pidx or pidx <= 0 then
        WriteLog("SIMCITY_WLLS\tStartOddSkip\tBadPlayer:"..tostring(pidx))
        return nil
    end
    -- Global Mission khong so huu SimCitizen.fighterList. Chuyen lenh sang
    -- player environment cua main.lua, giong cau noi cua Loi dai Cong Binh Tu.
    if (not SimCitizen or not SimCitizen.fighterList) and DynamicExecuteByPlayer then
        local ret = DynamicExecuteByPlayer(
            pidx,
            "\\script\\global\\nobitaxd\\vdk\\simcity\\main.lua",
            "SimCityLeague_StartOddBridge",
            tbLeague.szName, tbLeague.nLGID, nOrgCamp, nNewCamp,
            tbPos[1], tbPos[2], tbPos[3]
        )
        WriteLog("SIMCITY_WLLS\tBridgeStart\tPlayer:"..tostring(pidx)
            .."\tResult:"..tostring(ret))
        return ret
    end
    if self.active[pidx] then
        WriteLog("SIMCITY_WLLS\tStartOddSkip\tAlreadyActive:"..tostring(pidx))
        return nil
    end

    -- Handshake native da duoc kiem chung o Loi dai Cong Binh Tu:
    -- nguoi choi phe 2, SimCity phe 3, PK chien dau = 1.
    local nPlayerCamp = 2
    local nBotCamp = 3
    local nMType = wlls_get_mapinfo(1)
    local nLevel = wlls_get_level(nMType)
    local botId, tbBot = self:CreateBot(tbPos[1], tbPos[2], tbPos[3], nBotCamp, pidx)
    if not botId or not tbBot then
        WriteLog("SIMCITY_WLLS\tStartOddFail\tCreateBot\tPlayer:"..tostring(pidx))
        return nil
    end

    -- §i ®óng ng÷ c¶nh SubWorld nh­ wlls_addtroop_combat cña cÆp ng­êi-ng­êi.
    local oldWorld = SubWorld
    SubWorld = SubWorldID2Idx(tbPos[1])
    local oldPlayer = PlayerIndex
    PlayerIndex = pidx
    LG_ApplySetLeagueTask(WLLS_LGTYPE, tbLeague.szName, WLLS_LGTASK_MSCAMP, nNewCamp)
    NewWorld(tbPos[1], tbPos[2], tbPos[3])
    AddMSPlayer(WLLS_MSID_COMBAT, nNewCamp)
    SetCurCamp(nPlayerCamp)
    if SetTmpCamp then SetTmpCamp(nPlayerCamp) end
    if SetPKFlag then SetPKFlag(1) end
    if ForbidEnmity then ForbidEnmity(1) end
    if ForbidChangePK then ForbidChangePK(1) end
    wlls_set_pl_state()
    SetTask(WLLS_TASKID_ORGCAMP, nNewCamp)
    SetDeathScript(WLLS_FILE_DEATHSCRIPT)
    ST_StartDamageCounter()
    PlayerIndex = oldPlayer
    SubWorld = oldWorld
    WriteLog("SIMCITY_WLLS\tMissionJoin\tPlayer:"..tostring(pidx)
        .."\tMissionCamp:"..tostring(nNewCamp).."\tMap:"..tostring(tbPos[1]))

    self.active[pidx] = {
        player = pidx,
        playerCamp = nPlayerCamp,
        missionCamp = nNewCamp,
        botCamp = nBotCamp,
        botId = botId,
        botNpc = tbBot.finalIndex,
        botName = tbBot.szName or "V« Danh Kh¸ch",
        botSkill = tbBot.skillCastBua or {325,20},
        directNpc = tbBot.directNpc,
        leagueName = tbLeague.szName,
        mapId = tbPos[1],
        level = nLevel,
        finished = 0,
        started = 0,
    }
    self.botToPlayer[botId] = pidx

    local old = PlayerIndex
    PlayerIndex = pidx
    Msg2Player("<color=yellow>Liªn ®Êu ®· chän "..self.active[pidx].botName
        .." tõ Héi tr­êng SimCity lµm ®èi thñ cña b¹n.<color>")
    PlayerIndex = old
    WriteLog("SIMCITY_WLLS\tMatchOK\tPlayer:"..tostring(pidx).."\tBotId:"..tostring(botId).."\tLeague:"..tostring(tbLeague.szName))
    return 1
end

function SimCityLeague:Arm(a)
    if not a or a.finished == 1 then return end
    local tb
    if a.directNpc ~= 1 then
        tb = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[a.botId]
        if not tb or not tb.finalIndex or tb.finalIndex <= 0 then return end
        a.botNpc = tb.finalIndex
    elseif not a.botNpc or a.botNpc <= 0 then
        return
    end

    local old = PlayerIndex
    PlayerIndex = a.player
    if SetCurCamp then SetCurCamp(a.playerCamp) end
    if SetTmpCamp then SetTmpCamp(a.playerCamp) end
    if SetFightState then SetFightState(1) end
    if SetPKFlag then SetPKFlag(1) end
    local playerNpc = PIdx2NpcIdx and PIdx2NpcIdx(a.player) or 0
    PlayerIndex = old

    if tb then
        tb.isFighting = 1
        tb.camp = a.botCamp
        tb.duelPlayerId = a.player
        tb.duelTicks = 999999
        tb.isPlayerEnemyAround = a.player
        tb.peaceState = 0
    end
    if SetNpcCurCamp then SetNpcCurCamp(a.botNpc, a.botCamp) end
    if SetTmpCamp then SetTmpCamp(a.botCamp, a.botNpc) end
    if SetNpcKind then SetNpcKind(a.botNpc, 0) end
    if SetNpcActiveRegion then SetNpcActiveRegion(a.botNpc, 1) end
    if SetNpcPeace then SetNpcPeace(a.botNpc, 0) end
    local tbSkill = (tb and tb.skillCastBua) or a.botSkill or {325,20}
    if SetNpcCombat then
        SetNpcCombat(a.botNpc, 1, tbSkill[1] or 0)
    end
    if SetNpcFightTarget and playerNpc and playerNpc > 0 then
        SetNpcFightTarget(a.botNpc, playerNpc)
    end
    if SetNpcDuelAI and playerNpc and playerNpc > 0 then
        SetNpcDuelAI(a.botNpc, playerNpc)
    elseif SetNpcAI then
        SetNpcAI(a.botNpc, 1)
    end
    if playerNpc and playerNpc > 0 then
        local skillId = tbSkill[1] or 0
        local skillLevel = tbSkill[2] or 20
        if BotDuelArm and skillId > 0 then
            BotDuelArm(a.botNpc, playerNpc, skillId, skillLevel)
        elseif BotDoSkill and skillId > 0 then
            BotDoSkill(a.botNpc, skillId, skillLevel, playerNpc)
        end
    end
    if not a.armLogged then
        a.armLogged = 1
        local pCamp = GetNpcCurCamp and playerNpc > 0 and GetNpcCurCamp(playerNpc) or -1
        local bCamp = GetNpcCurCamp and GetNpcCurCamp(a.botNpc) or -1
        local oldDiag = PlayerIndex
        PlayerIndex = a.player
        local pTmp = GetTmpCamp and GetTmpCamp() or -1
        local pFight = GetFightState and GetFightState() or -1
        PlayerIndex = oldDiag
        local bTmp = GetTmpCamp and GetTmpCamp(a.botNpc) or -1
        local bKind = GetNpcKind and GetNpcKind(a.botNpc) or -1
        local pMode = GetPlayerPkMode and playerNpc > 0 and GetPlayerPkMode(playerNpc) or -1
        local canFight = GetNpcCanFight and GetNpcCanFight(a.botNpc) or -1
        WriteLog("SIMCITY_WLLS\tArm\tPlayerCamp:"..tostring(pCamp)
            .."\tPlayerTmp:"..tostring(pTmp)
            .."\tBotCamp:"..tostring(bCamp).."\tBotTmp:"..tostring(bTmp)
            .."\tKind:"..tostring(bKind).."\tFight:"..tostring(pFight)
            .."\tPk:"..tostring(pMode)
            .."\tCanFight:"..tostring(canFight))
    end
end

function SimCityLeague:GetCurrentMap()
    if SubWorldIdx2ID and SubWorld ~= nil then
        return SubWorldIdx2ID(SubWorld)
    end
end

function SimCityLeague:OnCombatStart(nMap)
    if not self:IsEnabled() then return end
    nMap = nMap or self:GetCurrentMap()
    for pidx, a in self.active do
        if not nMap or a.mapId == nMap then
            a.started = 1
            self:Arm(a)
            local old = PlayerIndex
            PlayerIndex = pidx
            Msg2Player("<color=yellow>TrËn ®¬n ®Êu víi "..a.botName.." b¾t ®Çu!<color>")
            PlayerIndex = old
        end
    end
end

function SimCityLeague:GetUsedTime()
    local freq = WLLS_TIMER_FIGHT_FREQ or 1
    local frame = WLLS_FRAME2TIME or 18
    local ticks = (GetGlbValue(GLB_WLLS_TIME) + 1) * freq
    if ticks < 1 then ticks = 1 end
    return ticks * frame
end

function SimCityLeague:Award(a, result)
    local nLevel = a.level
    if not nLevel then
        local nMType = wlls_get_mapinfo(1)
        nLevel = wlls_get_level(nMType)
    end
    local used = self:GetUsedTime()
    local code = 0
    if result == "win" then code = 1 elseif result == "lose" then code = 2 end
    wlls_award_lg(nLevel, a.leagueName, code, used)
    LG_ApplySetLeagueTask(WLLS_LGTYPE, a.leagueName, WLLS_LGTASK_MSCAMP, 0)
end

function SimCityLeague:Finish(pidx, result)
    local a = self.active[pidx]
    if not a or a.finished == 1 then return nil end
    a.finished = 1
    self.active[pidx] = nil
    self.botToPlayer[a.botId] = nil

    self:Award(a, result)
    local msg
    if result == "win" then
        msg = "<color=cyan>Vâ L©m Liªn §Êu: B¹n ®· ®¸nh b¹i "..a.botName.."!<color>"
    elseif result == "lose" then
        msg = "<color=cyan>Vâ L©m Liªn §Êu: B¹n ®· thua "..a.botName..".<color>"
    else
        msg = "<color=cyan>Vâ L©m Liªn §Êu: B¹n vµ "..a.botName.." hßa nhau.<color>"
    end

    local old = PlayerIndex
    PlayerIndex = pidx
    Msg2Player(msg)
    if DelMSPlayer then DelMSPlayer(WLLS_MSID_COMBAT, pidx) end
    wlls_clear_pl_state()
    SetPKFlag(0)
    ForbidChangePK(0)
    if ForbidEnmity then ForbidEnmity(0) end
    SetTask(WLLS_TASKID_ORGCAMP, 0)
    SetDeathScript("")
    NewWorld(wlls_get_mapid(1), WLLS_MAPPOS_SIGN[1], WLLS_MAPPOS_SIGN[2])
    PlayerIndex = old

    if a.directNpc == 1 then
        if SetNpcDuelEnd and a.botNpc and a.botNpc > 0 and PIdx2NpcIdx then
            SetNpcDuelEnd(a.botNpc, PIdx2NpcIdx(pidx))
        end
        if a.botNpc and a.botNpc > 0 then DelNpcSafe(a.botNpc) end
    else
        local tb = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[a.botId]
        if tb then
            if SetNpcDuelEnd and tb.finalIndex and tb.finalIndex > 0 and PIdx2NpcIdx then
                SetNpcDuelEnd(tb.finalIndex, PIdx2NpcIdx(pidx))
            end
            self:RestoreHallBot(tb)
        end
    end
    WriteLog("SIMCITY_WLLS\t"..a.leagueName.."\t"..result.."\t"..a.botName)
    return 1
end

function SimCityLeague:OnPlayerDeath(pidx)
    if self.active[pidx] then
        return self:Finish(pidx, "lose")
    end
end

function SimCityLeague:OnBotDeath(tb)
    if not tb or not tb.id then return end
    local pidx = self.botToPlayer[tb.id]
    if pidx and self.active[pidx] and self.active[pidx].started == 1 then
        self:Finish(pidx, "win")
    end
end

function SimCityLeague:OnNativeBotDeath(nNpcIndex)
    if not nNpcIndex then return end
    local pidx = self.botToPlayer[nNpcIndex]
    if (not pidx or pidx <= 0) and GetNpcParam then
        pidx = GetNpcParam(nNpcIndex, 1)
    end
    WriteLog("SIMCITY_WLLS\tNativeDeath\tNpc:"..tostring(nNpcIndex)
        .."\tPlayer:"..tostring(pidx)
        .."\tActive:"..tostring(pidx and self.active[pidx] ~= nil))
    if pidx and self.active[pidx] then
        self:Finish(pidx, "win")
    end
end

function SimCityLeague:OnCombatEnd(nMap)
    nMap = nMap or self:GetCurrentMap()
    local list = {}
    for pidx, a in self.active do
        if not nMap or a.mapId == nMap then
            tinsert(list, pidx)
        end
    end
    for i = 1, getn(list) do
        self:Finish(list[i], "draw")
    end
end

function SimCityLeague:Tick()
    if not self:IsEnabled() or not self.active then return end
    if self.hallMap and self.hallX and self.hallY then
        self.hallCheckTick = (self.hallCheckTick or 0) + 1
        if self.hallCheckTick >= 30 then
            self.hallCheckTick = 0
            self:PopulateHall(self.hallMap, self.hallX, self.hallY)
        end
    end
    if GetGlbValue and GetGlbValue(GLB_WLLS_PHASE) ~= 5 then return end
    local wins = {}
    for pidx, a in self.active do
        if a.started ~= 1 then
            -- Khong arm/khong xu thang trong thoi gian chuan bi.
        elseif a.directNpc == 1 then
            local nLife = NPCINFO_GetNpcCurrentLife
                and NPCINFO_GetNpcCurrentLife(a.botNpc)
            local nX = GetNpcPos and GetNpcPos(a.botNpc)
            local nOwner = GetNpcParam and GetNpcParam(a.botNpc, 1)
            if (nLife and nLife <= 0) or not nX
                or (nOwner and nOwner ~= pidx) then
                WriteLog("SIMCITY_WLLS\tNativeDeathPoll\tNpc:"
                    ..tostring(a.botNpc).."\tPlayer:"..tostring(pidx)
                    .."\tLife:"..tostring(nLife).."\tOwner:"..tostring(nOwner))
                tinsert(wins, pidx)
            else
                self:Arm(a)
            end
        else
            local tb = SimCitizen and SimCitizen.fighterList and SimCitizen.fighterList[a.botId]
            if not tb or not tb.finalIndex or tb.finalIndex <= 0 then
                tinsert(wins, pidx)
            else
                self:Arm(a)
            end
        end
    end
    for i = 1, getn(wins) do
        self:Finish(wins[i], "win")
    end
end

function SimCityLeague_StartOddBridge(szLeagueName, nLeagueId, nOrgCamp,
    nNewCamp, nMap, nX, nY)
    if not SimCityLeague then return nil end
    local tbLeague = {
        szName = szLeagueName,
        nLGID = nLeagueId,
        tbPlayer = { PlayerIndex },
    }
    return SimCityLeague:StartOdd(
        tbLeague, nOrgCamp, nNewCamp, { nMap, nX, nY }
    )
end

function SimCityLeague_OnPlayerDeathBridge()
    if SimCityLeague and SimCityLeague.OnPlayerDeath then
        return SimCityLeague:OnPlayerDeath(PlayerIndex)
    end
end

function SimCityLeague_OnCombatStartBridge()
    if SimCityLeague and SimCityLeague.active then
        local a = SimCityLeague.active[PlayerIndex]
        if a then
            a.started = 1
            SimCityLeague:Arm(a)
            Msg2Player("<color=yellow>TrËn ®¬n ®Êu víi "
                ..a.botName.." b¾t ®Çu!<color>")
            WriteLog("SIMCITY_WLLS\tBridgeCombatStart\tPlayer:"
                ..tostring(PlayerIndex).."\tBotId:"..tostring(a.botId))
            return 1
        end
    end
end

function SimCityLeague_OnCombatEndBridge()
    if SimCityLeague and SimCityLeague.active
        and SimCityLeague.active[PlayerIndex] then
        return SimCityLeague:Finish(PlayerIndex, "draw")
    end
end

if SimEntity and SimEntity.Citizen and not SimCityLeague._patchedDeath then
    SimCityLeague._patchedDeath = 1
    SimCityLeague._origEntityDeath = SimEntity.Citizen.OnDeath
    SimEntity.Citizen.OnDeath = function(self, simInstance, tbNpc, nNpcIndex, attackerIndex)
        -- DelNpcSafe cua than cu phat callback tre. Neu object da mang mot
        -- finalIndex moi thi day khong phai cai chet cua SIM trong tran.
        if tbNpc and tbNpc.leagueBot == 1 and tbNpc.leagueMoving == 1 then
            WriteLog("SIMCITY_WLLS\tIgnoreMoveDeath\tNpc:"
                ..tostring(nNpcIndex).."\tBotId:"..tostring(tbNpc.id))
            return 1
        end
        if tbNpc and tbNpc.leagueBot == 1 and tbNpc.finalIndex
            and tbNpc.finalIndex > 0 and tbNpc.finalIndex ~= nNpcIndex then
            WriteLog("SIMCITY_WLLS\tIgnoreStaleDeath\tOldNpc:"
                ..tostring(nNpcIndex).."\tCurrentNpc:"..tostring(tbNpc.finalIndex)
                .."\tBotId:"..tostring(tbNpc.id))
            return 1
        end
        local ret = SimCityLeague._origEntityDeath(self, simInstance, tbNpc, nNpcIndex, attackerIndex)
        if tbNpc and tbNpc.leagueBot == 1 then
            SimCityLeague:OnBotDeath(tbNpc)
        end
        return ret
    end
end

if SimCityWorld and not SimCityLeague._patchedTick then
    SimCityLeague._patchedTick = 1
    SimCityLeague._origWorldTick = SimCityWorld.ATick
    function SimCityWorld:ATick(rate)
        if SimCityLeague and SimCityLeague.Tick then SimCityLeague:Tick() end
        return SimCityLeague._origWorldTick(self, rate)
    end
end
