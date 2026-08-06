SIMCITY_CONFIG_DEFAULTS_LOADED = 1

CHANCE_AUTO_ATTACK = 1    -- 1/8000 co hoi chuyen sang chien dau
CHANCE_JOIN_FIGHT = 1     -- 1/3000 co hoi tham gia danh nhau khi di ngang qua dam danh nhau
CHANCE_ATTACK_PLAYER = 1  -- 1/3000 co hoi danh nguoi neu den gan nguoi choi dang chien dau

STARTUP_AUTOADD_THANHTHI = STARTUP_AUTOADD_THANHTHI or 1 -- tu dong moi nhan si tren tat ca ban do
THANHTHI_SIZE = THANHTHI_SIZE or 30   		 -- so luong nhan si trong thanh thi (gioi han an toan cho server 32-bit)
THON_SIZE = THON_SIZE or 10               -- so luong bot trong THON nho (it hon thanh, chong ket/chay 1 cho)
THANHTHI_QUAI = 0			 -- co cho phep quai nhan tu dong xuat hien trong thanh thi hay khong
LUYENCONG_AUTOADD = LUYENCONG_AUTOADD or 1		 -- tu dong them nhan si luyen cong vao map 9x

RADIUS_FIGHT_PLAYER = RADIUS_FIGHT_PLAYER or 20     -- tam quet+tan cong player 
RADIUS_FIGHT_NPC = RADIUS_FIGHT_NPC or 8         -- tam quet NPC chung quanh va tan cong
RADIUS_FIGHT_SCAN = RADIUS_FIGHT_SCAN or 8        -- tam quet dam danh nhau chung quanh de tham gia


CHANCE_CHAT = CHANCE_CHAT or 10               -- 10/1000 co hoi noi chuyen moi giay
CHANCE_DROP_MONEY = CHANCE_DROP_MONEY or 0 		   -- 1/10000 co hoi lam rot tien khi di chuyen


TIME_FIGHTING = TIME_FIGHTING or { -- khoang thoi gian danh nhau  (45-120giay)
	minTs = 6000,
	maxTs = 6000
}

TIME_RESTING = TIME_RESTING or { -- nghi ngoi, khong danh nhau lai trong vong thoi gian nay
	minTs = 0,
	maxTs = 1
}

-- TONG KIM setup
TONGKIM_SPAWN_MINSTAY = TONGKIM_SPAWN_MINSTAY or 0         -- thoi gian toi thieu o lai dai doanh truoc khi xong len
TONGKIM_SPAWN_MAXSTAY = TONGKIM_SPAWN_MAXSTAY or 1        -- thoi gian toi da co the nup trong dai doanh


-- PARAM setup
PARAM_LIST_ID = 1                  -- param to store fighter id
PARAM_CHILD_ID = 2                 -- param to store child id
PARAM_TYPE = 3                     -- param to store type
REFRESH_RATE = 18                  -- refresh rate
BOT_VS_BOT = BOT_VS_BOT or 1                     -- bot ngoai thanh TU tim+danh bot khac camp (BAT KE PK-mode/vi tri player). 0=tat
BOT_COMBAT_RADIUS = BOT_COMBAT_RADIUS or 20             -- tam quet bot combat

-- Watchdog vong doi va dan so bot.
SIMCITY_WATCHDOG_ENABLED = 1
SIMCITY_WATCHDOG_INTERVAL = 15 * 18
SIMCITY_PERSIST_EMPTY_MAPS = 1
SIMCITY_REFILL_BATCH = 20
SIMCITY_REFILL_GLOBAL_BATCH = 80
SIMCITY_DEFAULT_SIZE = 100
SIMBOT_RESPAWN_RETRY_TICKS = 5 * 18 / REFRESH_RATE
SIMBOT_RESPAWN_MAX_RETRIES = 5
SIMBOT_STUCK_ENABLED = 1
SIMBOT_STUCK_CHECK_TICKS = 30 * 18 / REFRESH_RATE
SIMBOT_STUCK_MAX_RETRIES = 2

-- Vo Lam Lien Dau: virtual SimCity teams. Bot teams are created only after
-- at least one real team has registered for the current event.
WLLS_BOT_TEAMS_ENABLED = WLLS_BOT_TEAMS_ENABLED or 1
WLLS_BOT_TEAM_COUNT_1V1 = WLLS_BOT_TEAM_COUNT_1V1 or 32
WLLS_BOT_TEAM_COUNT_2V2 = WLLS_BOT_TEAM_COUNT_2V2 or 16
WLLS_BOT_TEAM_COUNT_3V3 = WLLS_BOT_TEAM_COUNT_3V3 or 12
WLLS_BOT_HALL_ENABLED = WLLS_BOT_HALL_ENABLED or 1
WLLS_BOT_HALL_BATCH_SIZE = WLLS_BOT_HALL_BATCH_SIZE or 8
WLLS_BOT_HALL_RESERVED_RADIUS = WLLS_BOT_HALL_RESERVED_RADIUS or 8
WLLS_BOT_HALL_GRID_SPACING = WLLS_BOT_HALL_GRID_SPACING or 3
WLLS_BOT_SIGNUP_COUNT = WLLS_BOT_SIGNUP_COUNT or 16
WLLS_BOT_EMERGENCY_DISABLE = WLLS_BOT_EMERGENCY_DISABLE or 0
WLLS_BOT_QUEUE_MIN_SECONDS = WLLS_BOT_QUEUE_MIN_SECONDS or 60

-- Bounded strength profiles used by Lien Dau combat members.
SIMBOT_STRENGTH_ENABLED = SIMBOT_STRENGTH_ENABLED or 1
SIMBOT_SAFE_LEVEL_MAX = SIMBOT_SAFE_LEVEL_MAX or 119
SIMBOT_STRENGTH_PROFILES = SIMBOT_STRENGTH_PROFILES or {
    {id = "weak",   weight = 25, minHP = 6000,  maxHP = 9000,  level = 85,  minSkillLevel = 10, maxSkillLevel = 13, attackSpeed = 220},
    {id = "normal", weight = 50, minHP = 9000,  maxHP = 13000, level = 95,  minSkillLevel = 14, maxSkillLevel = 17, attackSpeed = 250},
    {id = "strong", weight = 20, minHP = 13000, maxHP = 17000, level = 105, minSkillLevel = 18, maxSkillLevel = 20, attackSpeed = 275},
    {id = "elite",  weight = 5,  minHP = 17000, maxHP = 20000, level = 119, minSkillLevel = 20, maxSkillLevel = 20, attackSpeed = 300},
}

-- The game preloads scripts in several environments. Keep a global facade so
-- timer 50/51 can safely reach the strength component through DynamicExecute.
SimBotStrengthCompat = SimBotStrengthCompat or {}

function SimBotStrengthCompat:GetSafeLevel(level, fallback)
    if SimBotStrength and SimBotStrength.GetSafeLevel then
        return SimBotStrength:GetSafeLevel(level, fallback)
    end
    local configuredMax = SIMBOT_SAFE_LEVEL_MAX
    if type(configuredMax) ~= "number" or configuredMax < 1 then configuredMax = 119 end
    if configuredMax > 119 then configuredMax = 119 end
    if type(level) == "number" and level >= 1 and level <= configuredMax then
        return floor(level)
    end
    return fallback or 95
end

function SimBotStrengthCompat:ResolveFaction(config)
    if SimBotStrength and SimBotStrength.ResolveFaction then
        return SimBotStrength:ResolveFaction(config)
    end
    return config
end

function SimBotStrengthCompat:Apply(config, roll)
    if SimBotStrength and SimBotStrength.Apply then
        return SimBotStrength:Apply(config, roll)
    end
    return config
end

function SimBotStrengthCompat:GetSkillLevel(tbNpc, fallback)
    if SimBotStrength and SimBotStrength.GetSkillLevel then
        return SimBotStrength:GetSkillLevel(tbNpc, fallback)
    end
    return (tbNpc and tbNpc.skillLevel) or fallback or 20
end

function SimBotStrengthCompat:SyncMainSkillLevel(config)
    if SimBotStrength and SimBotStrength.SyncMainSkillLevel then
        return SimBotStrength:SyncMainSkillLevel(config)
    end
end

function SimBotStrengthCompat:RestoreProfileHP(tbNpc, npcIndex)
    if SimBotStrength and SimBotStrength.RestoreProfileHP then
        return SimBotStrength:RestoreProfileHP(tbNpc, npcIndex)
    end
    return 0
end

function SimBotStrengthCompat:ApplyRuntimeStats(tbNpc, npcIndex)
    if SimBotStrength and SimBotStrength.ApplyRuntimeStats then
        SimBotStrength:ApplyRuntimeStats(tbNpc, npcIndex)
        return
    end
    if not npcIndex or npcIndex <= 0 then return end
    if SetNpcLevel then SetNpcLevel(npcIndex, 95) end
    if SetNpcAtkSpeed then SetNpcAtkSpeed(npcIndex, (tbNpc and tbNpc.attackSpeed) or 250) end
end

-- CHILD SIM CITIZEN/KEOXE setup
DISTANCE_CAN_CONTINUE = 5          -- start next position if within 3 points from destination
DISTANCE_CAN_SPIN = 2              -- when spinning make sure the check is tighter
SPINNING_WAIT_TIME = 0             -- wait time to correct position
CHAR_SPACING = 1                   -- spacing between fighter characters
DISTANCE_FOLLOW_PLAYER = 28        -- chay theo nguoi choi neu cach xa
DISTANCE_SUPPORT_PLAYER = 8        -- neu gan nguoi choi khoang cach 12 thi chuyen sang chien dau
DISTANCE_FOLLOW_PLAYER_TOOFAR = 30 -- neu qua xa nguoi choi vi chay nhanh thi phai bien hinh theo
DISTANCE_VISION = 15               -- qua 15 = phai respawn vi no se quay ve cho cu

LIFE_RESTORE_PERCENT = LIFE_RESTORE_PERCENT or 5       -- phan tram life se duoc hoi lai moi 1s

ENABLE_BANNGUAMIXDEV = 0	   -- sua lai thanh 1 neu xai ban mix dev vi bi mat ban ngua

-- webconfig.lua duoc nap mot lan trong head.lua, sau file mac dinh nay va
-- truoc cac plugin. Khong Include long o day vi engine JX xu ly theo hang doi.
