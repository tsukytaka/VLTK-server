Include("\\script\\missions\\leaguematch\\glbmission\\combat.lua")
-- Full SimCity chain: pair cleanup and monitors called from this timer
-- environment need DelNpcSafe and friends reachable through include links.
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\head.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\config.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\components\\sim.strength.lua")

if DynamicExecute then
    if WLLS_BOT_TEAMS_ENABLED == nil then
        WLLS_BOT_TEAMS_ENABLED = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_TEAMS_ENABLED"
        )
    end
    if not SimBotStrengthCompat then
        SimBotStrengthCompat = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "SimBotStrengthCompat"
        )
    end
end

if WLLS_BOT_TEAMS_ENABLED == nil then
    error("Lien Dau bot configuration is unavailable in timer 51")
end
if not SimBotStrengthCompat then
    error("Lien Dau strength facade is unavailable in timer 51")
end

Include("\\script\\missions\\leaguematch\\bots\\manager.lua")
Include("\\script\\missions\\leaguematch\\bots\\adapter.lua")
Include("\\script\\missions\\leaguematch\\bots\\pairing.lua")
Include("\\script\\missions\\leaguematch\\bots\\hall.lua")
Include("\\script\\missions\\leaguematch\\bots\\combat.lua")

if DynamicExecute then
    if not WllsBotManager then
        WllsBotManager = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WllsBotManager"
        )
    end
    if not WllsTeamAdapter then
        WllsTeamAdapter = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WllsTeamAdapter"
        )
    end
    if not WllsBotPairing then
        WllsBotPairing = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WllsBotPairing"
        )
    end
    if not WllsBotHall then
        WllsBotHall = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WllsBotHall"
        )
    end
    if not WllsBotCombat then
        WllsBotCombat = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WllsBotCombat"
        )
    end
end

if not WllsBotManager then error("WllsBotManager is unavailable in timer 51") end
if not WllsTeamAdapter then error("WllsTeamAdapter is unavailable in timer 51") end
if not WllsBotPairing then error("WllsBotPairing is unavailable in timer 51") end
if not WllsBotHall then error("WllsBotHall is unavailable in timer 51") end
if not WllsBotCombat then error("WllsBotCombat is unavailable in timer 51") end

-- integration.lua fails its own boot preload on purpose (see the gate at its
-- top); the flag below lets it load here. If timer 50's wrapper already loaded
-- it, this Include is a cache hit and simply links the shared module.
WllsBotIntegrationBootGate = 1
Include("\\script\\missions\\leaguematch\\bots\\integration.lua")

if not WllsBotIntegration or not WllsBotIntegration.RunCombatTick then
    error("Lien Dau integration is incomplete in timer 51")
end

WllsBotIntegration:BindSimCityRuntime()

-- Capture the legacy combat callback in THIS environment, then shadow OnTimer
-- with a wrapper that hands it over per call (same contract as timer 50).
WllsBotCombatLegacyOnTimer = OnTimer
if type(WllsBotCombatLegacyOnTimer) ~= "function" then
    error("legacy Lien Dau combat OnTimer is unavailable in timer 51")
end
function OnTimer()
    return WllsBotIntegration:RunCombatTick(WllsBotCombatLegacyOnTimer)
end
