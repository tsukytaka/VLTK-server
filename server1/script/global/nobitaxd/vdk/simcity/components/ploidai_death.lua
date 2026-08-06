function OnDeath(Launcher)
    if DynamicExecuteByPlayer then
        DynamicExecuteByPlayer(PlayerIndex, "\\script\\global\\nobitaxd\\vdk\\simcity\\main.lua", "BotDuel_OnOwnerDead")
    end
end
