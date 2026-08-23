-- ploidai.lua  (ASCII, khong dau)  -- MO RONG he bot SimCity, khong sua gi cua engine
-- "Loi dai ti vo Cong Binh Tu" - phien ban DAU VOI BOT MINH TO DOI:
-- Reversible:
--   * BOTDUEL_ENABLED = 0  -> tat (cong o Cong Binh Tu tra ve luong goc nguoi-vs-nguoi).
--   * Xoa dong Include o head.lua + 1 dong hook o bwmanager.lua (OnRegister).

-- CANH BAO: BOTDUEL_ENABLED CO Y KHONG duoc dinh nghia o day - control.lua la
-- NOI DUY NHAT dat (engine Include = "dinh nghia dau tien thang", global da co khong bi ghi de).
-- Khong co control.lua => BOTDUEL_ENABLED = nil => cac check "~= 1" coi nhu TAT (luong goc nguoi-vs-nguoi).
BW_MISSIONID_DUEL = 4

BotDuel = {
    arenaMap   = 209,
    ownerPos   = { 1620, 3202 },
    botPos     = { 1612, 3187 },
    ownerCamp  = 2,
    botCamp    = 3,
    maxTicks   = floor((SIMCITY_DUEL_FIGHT_SECONDS or 600) / 3),
    active     = {},
    botToOwner = {},
    prepTicks  = floor((SIMCITY_DUEL_READY_SECONDS or 18) / 3),
}

-- Map 209 chi danh cho mot cap dau BotDuel. Watchdog va bo tao dan so
-- SimCity thuong phai bo qua map nay, neu khong se bu them 15 bot khi tran dau bat dau.
function SimCityIsDuelOnlyMap(nW)
    if BotDuel and nW == BotDuel.arenaMap then return 1 end
    return 0
end

if SimCityWorld and SimCityWorld.New then
    SimCityWorld:New({
        worldId   = 209,
        name      = "DiÔn Vâ Tr­êng",
        allowFighting = 1,
        cityPeace = 0,
        firstNode = { 1610, 3200 },
        nodes = {
            ["1610_3200"] = { x = 1610, y = 3200, linkedNodes = { "1620_3202", "1612_3187" }, isExact = 0, nodeType = 0, isNearAtraction = 0, isNotPreset = 1 },
            ["1620_3202"] = { x = 1620, y = 3202, linkedNodes = { "1610_3200" }, isExact = 0, nodeType = 0, isNearAtraction = 0, isNotPreset = 1 },
            ["1612_3187"] = { x = 1612, y = 3187, linkedNodes = { "1610_3200" }, isExact = 0, nodeType = 0, isNearAtraction = 0, isNotPreset = 1 },
        },
    })
end

function BotDuel:FindBot(pidx)
    if not pidx or pidx <= 0 then return nil end
    if not SimCitizen or not SimCitizen.fighterList then return nil end

    -- Uu tien bo nho SimCity, sau do doi chieu truc tiep trang thai to doi
    -- native. PollParty cap nhat som hon partyPlayerId trong mot so nhip tick.
    for id, tb in SimCitizen.fighterList do
        if tb and tb.partyPlayerId == pidx and tb.finalIndex and tb.finalIndex > 0
           and tb.ploidaiBot ~= 1 then
            return id, tb
        end
    end
    if PollParty then
        for id, tb in SimCitizen.fighterList do
            if tb and tb.finalIndex and tb.finalIndex > 0 and tb.ploidaiBot ~= 1 then
                local owner = PollParty(tb.finalIndex)
                if owner == pidx then
                    tb.partyPlayerId = pidx
                    tb.partyFarTicks = 0
                    return id, tb
                end
            end
        end
    end
    return nil
end

function BotDuel:WriteDetectLog(pidx)
    if not openfile then return end
    local fh = openfile("Logs/ploidai_diag.txt", "a")
    if not fh then return end
    local total, cached, native = 0, 0, 0
    if SimCitizen and SimCitizen.fighterList then
        for id, tb in SimCitizen.fighterList do
            if tb and tb.finalIndex and tb.finalIndex > 0 then
                total = total + 1
                if tb.partyPlayerId == pidx then cached = cached + 1 end
                if PollParty and PollParty(tb.finalIndex) == pidx then native = native + 1 end
            end
        end
    end
    write(fh, (GetLocalDate and GetLocalDate("[%d-%m-%y %H:%M:%S] ") or "")
        .. "owner=" .. tostring(pidx)
        .. " enabled=" .. tostring(BOTDUEL_ENABLED)
        .. " total=" .. tostring(total)
        .. " cached=" .. tostring(cached)
        .. " native=" .. tostring(native) .. "\n")
    closefile(fh)
end


function BotDuel:ArenaState()
    if not GetMissionV or not SubWorldID2Idx then return 0 end
    local _oldSW = SubWorld
    SubWorld = SubWorldID2Idx(self.arenaMap)
    local st = GetMissionV(1)
    SubWorld = _oldSW
    return st or 0
end

function BotDuel:ArenaStage()
    if not GetMissionV or not SubWorldID2Idx then return 0 end
    local _oldSW = SubWorld
    SubWorld = SubWorldID2Idx(self.arenaMap)
    local v = GetMissionV(8)
    SubWorld = _oldSW
    return v or 0
end
function BotDuel_TryOffer()
    if BOTDUEL_ENABLED ~= 1 or not BotDuel then return nil end
    if BotDuel:ArenaStage() ~= 0 then
        Say("C«ng B×nh Tö: DiÔn Vâ Tr­êng ®ang cã trËn ®Êu, xin chê trËn sau.", 0)
        return 1
    end
    local id, tb = BotDuel:FindBot(PlayerIndex)
    if not id then
        BotDuel:WriteDetectLog(PlayerIndex)
        Say("C«ng B×nh Tö: Ta ch­a nhËn ra SIM trong tæ ®éi. H·y mêi l¹i SIM, ®îi 2 gi©y råi thö l¹i.", 0)
        return 1
    end
    if BotDuel.active[PlayerIndex] then
        Say("C«ng B×nh Tö: Ng­¬i ®ang trong trËn tØ vâ råi.", 0)
        return 1
    end
    Say("C«ng B×nh Tö: Ng­¬i muèn tØ vâ víi " .. (tb.szName or "b¹n ®ång hµnh") .. " ph¶i kh«ng? Ta sÏ ®­a c¶ hai lªn DiÔn Vâ Tr­êng.",
        2,
        "§óng vËy, vµo ®Êu ngay!/#BotDuel_Confirm()",
        "Th«i, ®Ó ta suy nghÜ./OnCancel")
    return 1
end

function BotDuel_Confirm()
    if BotDuel then BotDuel:Start(PlayerIndex) end
end

function BotDuel_OnOwnerDead()
    if BotDuel and BotDuel.OnOwnerDead then BotDuel:OnOwnerDead(PlayerIndex, nil) end
end
function BotDuel:PrepArena(camp)
    local _oldSW = SubWorld
    if SubWorldID2Idx then SubWorld = SubWorldID2Idx(self.arenaMap) end
    if StopMissionTimer then StopMissionTimer(BW_MISSIONID_DUEL, 10); StopMissionTimer(BW_MISSIONID_DUEL, 11) end
    if CloseMission then CloseMission(BW_MISSIONID_DUEL) end
    if SetMissionV then SetMissionV(1, 0) end
    if OpenMission then OpenMission(BW_MISSIONID_DUEL) end
    if StopMissionTimer then StopMissionTimer(BW_MISSIONID_DUEL, 10); StopMissionTimer(BW_MISSIONID_DUEL, 11) end
    if AddMSPlayer then AddMSPlayer(BW_MISSIONID_DUEL, camp) end
    if SetTaskTemp then SetTaskTemp(200, 1) end
    if SetMissionV then SetMissionV(8, 1) end
    SubWorld = _oldSW
end

function BotDuel:StartCombat(pidx, a)
    -- Don lan cuoi ngay truoc khi khai chien de dam bao tren dai chi con
    -- dung mot SIM da duoc nguoi choi chon.
    self:ClearArenaExtras(a.botId)
    local _oldSW = SubWorld
    if SubWorldID2Idx then SubWorld = SubWorldID2Idx(self.arenaMap) end
    if RunMission then RunMission(BW_MISSIONID_DUEL) end
    if StopMissionTimer then StopMissionTimer(BW_MISSIONID_DUEL, 10); StopMissionTimer(BW_MISSIONID_DUEL, 11) end
    if SetMissionV then SetMissionV(8, 2) end
    SubWorld = _oldSW
    local _oldPI = PlayerIndex
    PlayerIndex = pidx
    if SetCurCamp then SetCurCamp(self.ownerCamp) end
    if SetTmpCamp then SetTmpCamp(self.ownerCamp) end
    if SetFightState then SetFightState(1) end
    if SetPKFlag then SetPKFlag(1) end
    PlayerIndex = _oldPI
    local tb = SimCitizen.fighterList[a.botId]
    if tb and tb.finalIndex and tb.finalIndex > 0 then
        self:ArmNativeDuel(tb, pidx)
        self:WriteCombatLog(tb, pidx)
    end
    if Msg2MSAll then Msg2MSAll(BW_MISSIONID_DUEL, "C«ng B×nh Tö: HÕt giê chuÈn bÞ, trËn tØ vâ b¾t ®Çu!") end
end

function BotDuel:ClearArenaExtras(keepId)
    if not SimCitizen or not SimCitizen.fighterList then return end
    local removeIds = {}
    for id, tb in SimCitizen.fighterList do
        if id ~= keepId and tb and tb.nMapId == self.arenaMap then
            tinsert(removeIds, id)
        end
    end
    for i = 1, getn(removeIds) do
        local id = removeIds[i]
        local tb = SimCitizen.fighterList[id]
        if tb then
            tb._ownerRemove = 1
            if tb.finalIndex and tb.finalIndex > 0 then DelNpcSafe(tb.finalIndex) end
            tb.finalIndex = nil
            tb.isDead = 1
            self.botToOwner[id] = nil
            SimCitizen:Remove(id)
        end
    end
    if SimCityThanhThi then
        SimCityThanhThi.batchesByMap[self.arenaMap] = nil
        SimCityThanhThi.timerIdsByMap[self.arenaMap] = nil
        SimCityThanhThi.playerTimerIdsByMap[self.arenaMap] = nil
    end
end

function BotDuel:Start(pidx)
    if BOTDUEL_ENABLED ~= 1 then return end
    if self.active[pidx] then return end
    local id, tb = self:FindBot(pidx)
    if not id then
        Say("C«ng B×nh Tö: Ta kh«ng thÊy SIM nµo trong tæ ®éi cña ng­¬i.", 0)
        return
    end
    local aidx = SubWorldID2Idx(self.arenaMap)
    if not aidx or aidx < 0 then
        Say("C«ng B×nh Tö: DiÔn Vâ Tr­êng ch­a s½n sµng.", 0)
        return
    end

    local rw, rx, ry = GetWorldPos()
    self.active[pidx] = { botId = id, botName = tb.szName, retW = rw, retX = rx, retY = ry, ticks = 0, stage = "prep", prepLeft = self.prepTicks }
    self.botToOwner[id] = pidx

    self:ClearArenaExtras(id)

    if not self:PutBotInArena(tb, pidx) then
        self.active[pidx] = nil
        self.botToOwner[id] = nil
        Say("C«ng B×nh Tö: Kh«ng thÓ ®­a " .. (tb.szName or "®èi thñ") .. " lªn ®µi.", 0)
        return
    end

    LeaveTeam()
    SetCreateTeam(0)
    SetFightState(0)
    SetPunish(0)
    SetCurCamp(self.ownerCamp)
    if SetTmpCamp then SetTmpCamp(self.ownerCamp) end
    SetPKFlag(1)
    ForbidChangePK(1)
    ForbidEnmity(1)
    DisabledStall(1)
    ForbitTrade(1)
    DisabledUseTownP(1)
    SetDeathScript("\\script\\global\\nobitaxd\\vdk\\simcity\\components\\ploidai_death.lua")
    SetTempRevPos(rw, rx * 32, ry * 32)
    NewWorld(self.arenaMap, self.ownerPos[1], self.ownerPos[2])
    self:PrepArena(self.ownerCamp)

    Msg2Player("C«ng B×nh Tö: ChuÈn bÞ tØ vâ víi " .. (tb.szName or "®èi thñ") .. ". Trong lóc chuÈn bÞ, mêi c¸c vÞ hµo hiÖp vµo xem!")
end

function BotDuel:PutBotInArena(tb, pidx)
    if tb.finalIndex and tb.finalIndex > 0 then
        if PartyClear then PartyClear(tb.finalIndex) end
        if BotDuelDisarm then BotDuelDisarm(tb.finalIndex) end
        DelNpcSafe(tb.finalIndex)
    end
    tb.finalIndex    = nil
    tb.isDead        = 0
    tb.nMapId        = self.arenaMap
    tb.worldInfo     = SimCityWorld:Get(self.arenaMap)
    tb.worldInfo.allowFighting = 1
    tb.worldInfo.cityPeace = 0
    tb.nPosId        = "1612_3187"
    tb.walkMode      = "random"
    tb.stall         = 0
    tb.daTau         = 0
    tb.isFighting    = 1
    tb.camp          = self.botCamp
    tb.partyOldCamp  = nil
    tb.partyPlayerId = nil
    tb.botDuelTarget = nil
    tb.dashUntil     = nil
    tb.noReviveOld   = tb.noRevive
    tb.noRevive      = 1
    tb.ploidaiBot    = 1
    tb.peaceState    = 0
    tb.peaceFlip     = 0
    tb.peaceTick     = 0
    tb.partyArmTick  = nil
    tb.partyTarget   = nil
    tb.partyHuntCamp = nil
    tb.botCombatTick = nil
    tb.duelCombatTick = nil
    tb.duelArmTick   = nil

    -- SIM con dung FormationChild va phu thuoc SIM cha. Khi len loi dai,
    -- chuyen no thanh mot dau si Citizen doc lap de AI khong bi keo ve cha.
    if tb.role == "child" then
        tb.role = "citizen"
        tb.parentID = nil
        tb.childID = nil
        tb.parentAppointPos = { 0, 0 }
        if SimMovementSys then tb.movementSys = SimMovementSys(tb) end
        if SimFunSys then tb.funSys = SimFunSys(tb) end
        if SimEntitySys then tb.entitySys = SimEntitySys(tb) end
        if SimFightSys then tb.fightSys = SimFightSys(tb) end
    end

    SimEntity.Citizen.CreateChar(SimEntity.Citizen, SimCitizen, tb, 0, self.botPos[1] * 32, self.botPos[2] * 32)
    if not (tb.finalIndex and tb.finalIndex > 0) then
        return nil
    end
    SetNpcCurCamp(tb.finalIndex, self.botCamp)
    tb.duelPlayerId = nil
    tb.duelTicks    = 0
    tb.selfDefDuel  = nil
    if SetTmpCamp then SetTmpCamp(self.botCamp, tb.finalIndex) end
    if SetNpcKind then SetNpcKind(tb.finalIndex, 0) end
    if SetNpcPeace then SetNpcPeace(tb.finalIndex, 0) end
    return 1
end

-- Dang ky quan he ti vo trong engine native. Chi gan duelPlayerId o Lua
-- chi du de SIM danh cuong che, nhung player co the van xem SIM la dong doi.
function BotDuel:ArmNativeDuel(tb, pidx)
    if not tb or not tb.finalIndex or tb.finalIndex <= 0 then return 0 end
    local nNpcIndex = tb.finalIndex
    local nPlayerNpc = PIdx2NpcIdx and PIdx2NpcIdx(pidx) or 0
    tb.isFighting = 1
    tb.camp = self.botCamp
    tb.duelPlayerId = pidx
    tb.duelTicks = 999999
    tb.isPlayerEnemyAround = pidx
    tb.peaceState = 0
    if SetNpcCurCamp then SetNpcCurCamp(nNpcIndex, self.botCamp) end
    if SetTmpCamp then SetTmpCamp(self.botCamp, nNpcIndex) end
    if SetNpcKind then SetNpcKind(nNpcIndex, 0) end
    if SetNpcActiveRegion then SetNpcActiveRegion(nNpcIndex, 1) end
    if SetNpcPeace then SetNpcPeace(nNpcIndex, 0) end
    if SetNpcCombat then
        SetNpcCombat(nNpcIndex, 1, tb.skillCastBua and tb.skillCastBua[1] or 0)
    end
    if SetNpcDuelAI and nPlayerNpc and nPlayerNpc > 0 then
        SetNpcDuelAI(nNpcIndex, nPlayerNpc)
    elseif SetNpcAI then
        SetNpcAI(nNpcIndex, 1)
    end
    return 1
end

function BotDuel:WriteCombatLog(tb, pidx)
    if not openfile or not tb or not tb.finalIndex then return end
    local oldPlayerIndex = PlayerIndex
    PlayerIndex = pidx
    local playerCur = GetCurCamp and GetCurCamp() or -1
    local playerTmp = GetTmpCamp and GetTmpCamp() or -1
    local playerFight = GetFightState and GetFightState() or -1
    local playerNpc = PIdx2NpcIdx and PIdx2NpcIdx(pidx) or -1
    local playerPk = GetPlayerPkMode and playerNpc > 0 and GetPlayerPkMode(playerNpc) or -1
    PlayerIndex = oldPlayerIndex
    local botCur = GetNpcCurCamp and GetNpcCurCamp(tb.finalIndex) or -1
    local botTmp = GetTmpCamp and GetTmpCamp(tb.finalIndex) or -1
    local botKind = GetNpcKind and GetNpcKind(tb.finalIndex) or -1
    local canFight = SimCityCanFight and SimCityCanFight(tb) or -1
    local fh = openfile("Logs/ploidai_combat.txt", "a")
    if fh then
        write(fh, (GetLocalDate and GetLocalDate("[%d-%m-%y %H:%M:%S] ") or "")
            .. "player=" .. tostring(pidx)
            .. " playerNpc=" .. tostring(playerNpc)
            .. " playerCur=" .. tostring(playerCur)
            .. " playerTmp=" .. tostring(playerTmp)
            .. " playerFight=" .. tostring(playerFight)
            .. " playerPk=" .. tostring(playerPk)
            .. " bot=" .. tostring(tb.finalIndex)
            .. " botCur=" .. tostring(botCur)
            .. " botTmp=" .. tostring(botTmp)
            .. " botKind=" .. tostring(botKind)
            .. " role=" .. tostring(tb.role)
            .. " mode=" .. tostring(tb.mode)
            .. " canFight=" .. tostring(canFight)
            .. " native=" .. tostring(SetNpcDuelAI ~= nil) .. "\n")
        closefile(fh)
    end
end

function BotDuel:OnBotDead(pidx, tb)
    if not self.active[pidx] then return end
    self:Finish(pidx, "win")
end

function BotDuel:OnOwnerDead(pidx, launcher)
    if not self.active[pidx] then return end
    self:Finish(pidx, "lose")
end

function BotDuel:Finish(pidx, result)
    local a = self.active[pidx]
    if not a then return end
    self.active[pidx] = nil

    local old = PlayerIndex
    PlayerIndex = pidx
    local _pname = (GetName and GetName()) or "Ng­êi ch¬i"
    local _res
    if result == "win" then
        _res = "L«i ®µi C«ng B×nh Tö: " .. _pname .. " ®· ®¸nh b¹i " .. (a.botName or "®èi thñ") .. "!"
    elseif result == "lose" then
        _res = "L«i ®µi C«ng B×nh Tö: " .. (a.botName or "®èi thñ") .. " ®· ®¸nh b¹i " .. _pname .. "!"
    else
        _res = "L«i ®µi C«ng B×nh Tö: TrËn tØ vâ " .. _pname .. " víi " .. (a.botName or "®èi thñ") .. " kÕt thóc hßa."
    end
    local _oldSWr = SubWorld
    if SubWorldID2Idx then SubWorld = SubWorldID2Idx(self.arenaMap) end
    if Msg2MSAll then Msg2MSAll(BW_MISSIONID_DUEL, _res) end
    SubWorld = _oldSWr
    if AddGlobalNews then AddGlobalNews(_res) end
    local _oldSWf = SubWorld
    if SubWorldID2Idx then SubWorld = SubWorldID2Idx(self.arenaMap) end
    if DelMSPlayer then DelMSPlayer(BW_MISSIONID_DUEL, pidx) end
    if StopMissionTimer then StopMissionTimer(BW_MISSIONID_DUEL, 10); StopMissionTimer(BW_MISSIONID_DUEL, 11) end
    if CloseMission then CloseMission(BW_MISSIONID_DUEL) end
    if SetMissionV then SetMissionV(1, 0) end
    if SetMissionV then SetMissionV(8, 0) end
    SubWorld = _oldSWf
    SetFightState(0)
    SetPunish(1)
    SetPKFlag(0)
    ForbidChangePK(0)
    ForbidEnmity(0)
    DisabledStall(0)
    ForbitTrade(0)
    DisabledUseTownP(0)
    SetCurCamp(GetCamp())
    if SetTmpCamp then SetTmpCamp(GetCamp()) end
    SetCreateTeam(1)
    SetDeathScript("")
    if result == "win" then
        if Earn then Earn(50000) end
        Msg2Player("C«ng B×nh Tö: Chóc mõng! Ng­¬i ®· ®¸nh b¹i " .. (a.botName or "®èi thñ") .. ". Th­ëng 5 v¹n b¹c.")
    elseif result == "lose" then
        Msg2Player("C«ng B×nh Tö: Ng­¬i ®· b¹i trËn tr­íc " .. (a.botName or "®èi thñ") .. ". LÇn sau cè g¾ng h¬n!")
    else
        Msg2Player("C«ng B×nh Tö: TrËn tØ vâ kÕt thóc.")
    end
    if result ~= "lose" then
        NewWorld(a.retW, a.retX, a.retY)
    end
    PlayerIndex = old

    self.botToOwner[a.botId] = nil
    local tb = SimCitizen.fighterList[a.botId]
    if tb then
        if SetNpcDuelEnd and tb.finalIndex and tb.finalIndex > 0 and PIdx2NpcIdx then
            SetNpcDuelEnd(tb.finalIndex, PIdx2NpcIdx(pidx))
        end
        if tb.finalIndex and tb.finalIndex > 0 then DelNpcSafe(tb.finalIndex) end
        tb.finalIndex = nil
        tb.isDead = 1
        tb.duelPlayerId = nil
        tb._ownerRemove = 1
        if SimCitizen.Remove then SimCitizen:Remove(a.botId) end
    end
end

function BotDuel:Tick()
    if not self.active then return end
    local toFinish = {}
    for pidx, a in self.active do
        a.ticks = (a.ticks or 0) + 1
        if a.stage == "prep" then
            a.prepLeft = (a.prepLeft or 0) - 1
            if a.prepLeft > 0 then
                local _oPI = PlayerIndex
                PlayerIndex = pidx
                if Msg2Player then Msg2Player("<color=yellow>L«i ®µi: TrËn tØ vâ b¾t ®Çu sau " .. a.prepLeft .. "...<color>") end
                PlayerIndex = _oPI
            end
            if a.prepLeft <= 0 then
                a.stage = "battle"
                self:StartCombat(pidx, a)
            end
        else
            local tb = SimCitizen.fighterList[a.botId]
            if not tb or not tb.finalIndex or tb.finalIndex <= 0 then
                tinsert(toFinish, { pidx, "win" })
            elseif a.ticks > self.maxTicks then
                tinsert(toFinish, { pidx, "draw" })
            else
                local _oldPI = PlayerIndex
                PlayerIndex = pidx
                if SetCurCamp then SetCurCamp(self.ownerCamp) end
                if SetTmpCamp then SetTmpCamp(self.ownerCamp) end
                if SetFightState then SetFightState(1) end
                PlayerIndex = _oldPI
                self:ArmNativeDuel(tb, pidx)
            end
        end
    end
    for i = 1, getn(toFinish) do
        self:Finish(toFinish[i][1], toFinish[i][2])
    end
end

if SimEntity and SimEntity.Citizen and not BotDuel._patchedOnDeath then
    BotDuel._patchedOnDeath = 1
    BotDuel._origEntityOnDeath = SimEntity.Citizen.OnDeath
    SimEntity.Citizen.OnDeath = function(self, simInstance, tbNpc, nNpcIndex, attackerIndex)
        local ret = BotDuel._origEntityOnDeath(self, simInstance, tbNpc, nNpcIndex, attackerIndex)
        if tbNpc and BotDuel and BotDuel.botToOwner and BotDuel.botToOwner[tbNpc.id] then
            local ow = BotDuel.botToOwner[tbNpc.id]
            if BotDuel.active[ow] then BotDuel:OnBotDead(ow, tbNpc) end
        end
        return ret
    end
end

if SimCityWorld and not BotDuel._patchedATick then
    BotDuel._patchedATick = 1
    BotDuel._origWorldATick = SimCityWorld.ATick
    function SimCityWorld:ATick(rate)
        if BotDuel and BotDuel.Tick then BotDuel:Tick() end
        return BotDuel._origWorldATick(self, rate)
    end
end
