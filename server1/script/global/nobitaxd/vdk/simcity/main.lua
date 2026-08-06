Include("\\script\\global\\nobitaxd\\vdk\\simcity\\head.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\components\\sim.watchdog.lua")
--Include("\\script\\global\\nobitaxd\\vdk\\simcity\\controllers\\thanhthi.lua")
function main()
	SimCityThanhThi:mainMenu()
	return 1
end

-- Dam bao du lieu world luon duoc tao, ke ca khi controller/thanhthi.lua
-- khong duoc Include. Ham nay idempotent, co the goi lai tu timer/EnterMap.
function SimCity_EnsureInitialized()
    -- mainLoop goi ham nay lien tuc. Khong duyet lai SimCityMap moi frame;
    -- viec noi chuoi key cho hang nghin map se chiem tron game loop.
    if SIMCITY_INITIALIZED == 1 then
        return SIMCITY_WORLD_COUNT or 1
    end
    if not SimCityMap or not SimCityWorld or not SimCityWorld.New then return 0 end
    local count = 0
    for worldId, worldInfo in SimCityMap do
        if worldInfo and worldInfo.worldId then
            SimCityWorld:New(worldInfo)
            count = count + 1
        end
    end
    if count > 0 and not SIMCITY_WATCHDOG_HOOKS and SimCitizen and SimCityThanhThi then
        Include("\\script\\global\\nobitaxd\\vdk\\simcity\\components\\sim.watchdog.lua")
    end
    if count > 0 then
        SIMCITY_WORLD_COUNT = count
        SIMCITY_INITIALIZED = 1
    end
    return count
end

-- Main loop
function mainLoop(nParam)
    -- Giu dung co che cua /home/old/s1: moi callback ket thuc timer cu va
    -- dang ky dung mot timer moi. Khong vua AddTimer vua return timeout.
    if SIMCITY_MAINLOOP_BUSY == 1 then
        AddTimer(REFRESH_RATE, "mainLoop", 0)
        return
    end
    SIMCITY_MAINLOOP_BUSY = 1
    if SimCity_EnsureInitialized() <= 0 then
        SIMCITY_MAINLOOP_BUSY = 0
        AddTimer(REFRESH_RATE, "mainLoop", 0)
        return
    end
    if SimCitizen and SimCitizen.ATick then SimCitizen:ATick() end
	if SimTheoSau and SimTheoSau.ATick then SimTheoSau:ATick() end
	--SimCityKeoXe:ATick()
    -- SimCitizen:FastCastTick()   -- [2026-06-27 TAT: fast-cast + SetNpcFightTarget ghi de target engine-AI moi 0.7s -> pha bot-vs-bot da chay hom qua. Tra ve engine-AI tu nhien.
    SIMCITY_MAINLOOP_BUSY = 0
    AddTimer(REFRESH_RATE, "mainLoop", 0)
end 

function worldLoop(nParam)
	if SIMCITY_WORLDLOOP_BUSY == 1 then
		AddTimer(REFRESH_RATE*3, "worldLoop", 0)
		return
	end
	SIMCITY_WORLDLOOP_BUSY = 1
	if SimCity_EnsureInitialized() <= 0 then
		SIMCITY_WORLDLOOP_BUSY = 0
		AddTimer(REFRESH_RATE*3, "worldLoop", 0)
		return
	end
	if SimCityWorld and SimCityWorld.ATick then SimCityWorld:ATick(20) end
	SIMCITY_WORLDLOOP_BUSY = 0
    AddTimer(REFRESH_RATE*3, "worldLoop", 0)
end 

function simcityWatchdogLoop(nParam)
    if SIMCITY_WATCHDOG_BUSY == 1 then
        AddTimer(SIMCITY_WATCHDOG_INTERVAL or 15*18, "simcityWatchdogLoop", 0)
        return
    end
    SIMCITY_WATCHDOG_BUSY = 1
    if SimCity_EnsureInitialized() <= 0 then
        SIMCITY_WATCHDOG_BUSY = 0
        AddTimer(SIMCITY_WATCHDOG_INTERVAL or 15*18, "simcityWatchdogLoop", 0)
        return
    end
    if not SIMCITY_WATCHDOG_HOOKS then
        Include("\\script\\global\\nobitaxd\\vdk\\simcity\\components\\sim.watchdog.lua")
    end
    if SIMCITY_WATCHDOG_HOOKS and SimCityWatchdog then SimCityWatchdog:Tick() end
    SIMCITY_WATCHDOG_BUSY = 0
    AddTimer(SIMCITY_WATCHDOG_INTERVAL or 15*18, "simcityWatchdogLoop", 0)
end

function SimCity_StartLoops()
    if SIMCITY_LOOP_STARTED == 1 then return 1 end
    SIMCITY_LOOP_STARTED = 1
    AddTimer(REFRESH_RATE, "mainLoop", 0)
    AddTimer(REFRESH_RATE*3, "worldLoop", 0)
    if SIMCITY_WATCHDOG_ENABLED == 1 then
        AddTimer(SIMCITY_WATCHDOG_INTERVAL or 15*18, "simcityWatchdogLoop", 0)
    end
    return 1
end


-- Khong khoi dong timer o day. Engine preload file nay khi game server van dang
-- nap script; watchdog chay luc do se tao dan so cho tat ca map da load va lam
-- server het bo nho truoc khi den su kien ServerStart. Activity 801 se khoi
-- dong cac loop sau khi server san sang.

-- [2026-06-27] fast-cast goi tu mainLoop (xem ham mainLoop) -> bo timer rieng (ko on dinh)
