Include("\\script\\missions\\leaguematch\\glbmission\\schedule.lua")
-- Full SimCity chain: closures called from this timer environment (for example
-- SimCitizen:Remove during hall cleanup) resolve globals through this
-- environment's include links, so DelNpcSafe and friends must be reachable here.
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
    if WLLS_BOT_TEAM_COUNT_1V1 == nil then
        WLLS_BOT_TEAM_COUNT_1V1 = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_TEAM_COUNT_1V1"
        )
    end
    if WLLS_BOT_TEAM_COUNT_2V2 == nil then
        WLLS_BOT_TEAM_COUNT_2V2 = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_TEAM_COUNT_2V2"
        )
    end
    if WLLS_BOT_TEAM_COUNT_3V3 == nil then
        WLLS_BOT_TEAM_COUNT_3V3 = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_TEAM_COUNT_3V3"
        )
    end
    if WLLS_BOT_HALL_ENABLED == nil then
        WLLS_BOT_HALL_ENABLED = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_HALL_ENABLED"
        )
    end
    if WLLS_BOT_HALL_BATCH_SIZE == nil then
        WLLS_BOT_HALL_BATCH_SIZE = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_HALL_BATCH_SIZE"
        )
    end
    if WLLS_BOT_HALL_RESERVED_RADIUS == nil then
        WLLS_BOT_HALL_RESERVED_RADIUS = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_HALL_RESERVED_RADIUS"
        )
    end
    if WLLS_BOT_HALL_GRID_SPACING == nil then
        WLLS_BOT_HALL_GRID_SPACING = DynamicExecute(
            "\\script\\global\\nobitaxd\\vdk\\main.lua",
            "getglobal",
            "WLLS_BOT_HALL_GRID_SPACING"
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
    error("Lien Dau bot configuration is unavailable in timer 50")
end
if not SimBotStrengthCompat then
    error("Lien Dau strength facade is unavailable in timer 50")
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

if not WllsBotManager then error("WllsBotManager is unavailable in timer 50") end
if not WllsTeamAdapter then error("WllsTeamAdapter is unavailable in timer 50") end
if not WllsBotPairing then error("WllsBotPairing is unavailable in timer 50") end
if not WllsBotHall then error("WllsBotHall is unavailable in timer 50") end
if not WllsBotCombat then error("WllsBotCombat is unavailable in timer 50") end

-- integration.lua fails its own boot preload on purpose (see the gate at its
-- top), so the global include cache never contains it and this Include always
-- re-executes the chunk inside this timer environment. The gate flag below is
-- what lets it load here and nowhere else.
WllsBotIntegrationBootGate = 1
Include("\\script\\missions\\leaguematch\\bots\\integration.lua")

if not WllsBotIntegration or not WllsBotIntegration.RunScheduleTick then
    error("Lien Dau integration is incomplete in timer 50")
end

WllsBotIntegration:BindSimCityRuntime()

-- Capture the legacy schedule callback in THIS environment, then shadow OnTimer
-- with a wrapper that hands it over per call. The shared integration module must
-- never touch OnTimer globals itself: with two timer wrappers (50 and 51) its
-- closures may live in the other wrapper's environment.
WllsBotScheduleLegacyOnTimer = OnTimer
if type(WllsBotScheduleLegacyOnTimer) ~= "function" then
    error("legacy Lien Dau schedule OnTimer is unavailable in timer 50")
end
function OnTimer()
    return WllsBotIntegration:RunScheduleTick(WllsBotScheduleLegacyOnTimer)
end
