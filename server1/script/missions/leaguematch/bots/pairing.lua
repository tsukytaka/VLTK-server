WllsBotPairing = WllsBotPairing or {
    nextPairId = 0,
}

function WllsBotPairing:Count(values)
    local count = 0
    if not values then return count end
    while values[count + 1] do
        count = count + 1
    end
    return count
end

function WllsBotPairing:Append(values, value)
    values[self:Count(values) + 1] = value
end

function WllsBotPairing:GetWinRateBucket(entry)
    local total = WllsTeamAdapter:GetStat(entry, "total")
    local winPoint = WllsTeamAdapter:GetStat(entry, "win") * 3
        + WllsTeamAdapter:GetStat(entry, "tie")
    local winRate = 0.1
    if winPoint > 0 then
        winRate = winPoint / total
    end
    if winRate > 3 or winRate <= 0 then
        winRate = 0.1
    end

    local bucket = 1
    while bucket < 10 and winRate > bucket * 0.3 do
        bucket = bucket + 1
    end
    return bucket
end

function WllsBotPairing:OrderEntries(entries)
    local buckets = {}
    local bucketIndex = 1
    while bucketIndex <= 10 do
        buckets[bucketIndex] = {}
        bucketIndex = bucketIndex + 1
    end

    local entryIndex = 1
    while entries and entries[entryIndex] do
        local entry = entries[entryIndex]
        local bucket = self:GetWinRateBucket(entry)
        self:Append(buckets[bucket], entry)
        entryIndex = entryIndex + 1
    end

    local ordered = {}
    bucketIndex = 10
    while bucketIndex >= 1 do
        local itemIndex = 1
        while buckets[bucketIndex][itemIndex] do
            self:Append(ordered, buckets[bucketIndex][itemIndex])
            itemIndex = itemIndex + 1
        end
        bucketIndex = bucketIndex - 1
    end
    return ordered
end

function WllsBotPairing:GetMeetRank(entry, enemyId)
    if not entry or not entry.enemies then return nil end
    local enemyIndex = 1
    while enemyIndex <= 3 do
        if entry.enemies[enemyIndex] == enemyId then return enemyIndex end
        enemyIndex = enemyIndex + 1
    end
    return nil
end

function WllsBotPairing:TakeBye(ordered)
    local count = self:Count(ordered)
    local remainder = count
    while remainder > 1 do
        remainder = remainder - 2
    end
    if remainder == 0 then return nil end

    local byeIndex = count
    local searchIndex = count
    while searchIndex >= 1 do
        if ordered[searchIndex].kind == "bot" then
            byeIndex = searchIndex
            break
        end
        searchIndex = searchIndex - 1
    end

    local byeEntry = ordered[byeIndex]
    while byeIndex < count do
        ordered[byeIndex] = ordered[byeIndex + 1]
        byeIndex = byeIndex + 1
    end
    ordered[count] = nil
    return byeEntry
end

function WllsBotPairing:CreatePair(left, right)
    self.nextPairId = (self.nextPairId or 0) + 1
    local arenaPriority = 2
    if left.kind == "real" or right.kind == "real" then arenaPriority = 1 end
    return {
        id = self.nextPairId,
        left = left,
        right = right,
        state = "pending",
        finalized = 0,
        arenaPriority = arenaPriority,
    }
end

function WllsBotPairing:NormalizeArenaCapacity(maxArenas, pairCount)
    local availableArenas = maxArenas
    if type(availableArenas) ~= "number" then availableArenas = pairCount end
    if availableArenas < 0 then availableArenas = 0 end

    local normalized = 0
    while normalized < pairCount and normalized + 1 <= availableArenas do
        normalized = normalized + 1
    end
    return normalized
end

function WllsBotPairing:AllocatePairs(prioritized, availableArenas)
    local activePairs = {}
    local queuedPairs = {}
    local pairIndex = 1
    while prioritized[pairIndex] do
        local pair = prioritized[pairIndex]
        if pairIndex <= availableArenas then
            pair.state = "active"
            self:Append(activePairs, pair)
        else
            pair.state = "queued"
            self:Append(queuedPairs, pair)
        end
        pairIndex = pairIndex + 1
    end
    return activePairs, queuedPairs
end

function WllsBotPairing:Build(entries, maxArenas)
    local ownerSession = nil
    if entries and entries.liendauSessionId and WllsBotManager and WllsBotManager.sessions then
        ownerSession = WllsBotManager.sessions[entries.liendauSessionId]
    end
    if ownerSession and ownerSession.active == 1 and ownerSession.unifiedEntries == entries
       and ownerSession.pairingBuilt == 1
       and ownerSession.pairingRosterKey == entries.liendauRosterKey then
        local cachedCapacity = self:NormalizeArenaCapacity(
            maxArenas,
            self:Count(ownerSession.prioritizedPairs)
        )
        if ownerSession.pairingCapacity == cachedCapacity then
            return ownerSession.activePairs, ownerSession.queuedPairs, ownerSession.byeEntry
        end
        ownerSession.activePairs, ownerSession.queuedPairs = self:AllocatePairs(
            ownerSession.prioritizedPairs,
            cachedCapacity
        )
        ownerSession.pairingCapacity = cachedCapacity
        return ownerSession.activePairs, ownerSession.queuedPairs, ownerSession.byeEntry
    end

    local ordered = self:OrderEntries(entries)
    local byeEntry = self:TakeBye(ordered)
    local pairCount = self:Count(ordered) / 2
    local pairs = {}
    local pairIndex = 1
    local entryIndex = 1

    while pairIndex <= pairCount do
        local left = ordered[entryIndex]
        local selectedIndex = entryIndex + 1
        local selectedMeet = 0
        local candidateIndex = entryIndex + 1
        local orderedCount = self:Count(ordered)

        while candidateIndex <= orderedCount do
            local meet = self:GetMeetRank(left, ordered[candidateIndex].id)
            if not meet or meet > selectedMeet then
                selectedIndex = candidateIndex
                selectedMeet = meet
            end
            if not selectedMeet then break end
            candidateIndex = candidateIndex + 1
        end

        if selectedIndex ~= entryIndex + 1 then
            local selected = ordered[selectedIndex]
            ordered[selectedIndex] = ordered[entryIndex + 1]
            ordered[entryIndex + 1] = selected
        end

        local right = ordered[entryIndex + 1]
        local pair = self:CreatePair(left, right)
        pairs[pairIndex] = pair
        if WllsTeamAdapter and WllsTeamAdapter.SaveEnemy then
            WllsTeamAdapter:SaveEnemy(left, right)
            WllsTeamAdapter:SaveEnemy(right, left)
        end
        pairIndex = pairIndex + 1
        entryIndex = entryIndex + 2
    end

    local prioritized = {}
    pairIndex = 1
    while pairs[pairIndex] do
        if pairs[pairIndex].arenaPriority == 1 then self:Append(prioritized, pairs[pairIndex]) end
        pairIndex = pairIndex + 1
    end
    pairIndex = 1
    while pairs[pairIndex] do
        if pairs[pairIndex].arenaPriority ~= 1 then self:Append(prioritized, pairs[pairIndex]) end
        pairIndex = pairIndex + 1
    end

    local availableArenas = self:NormalizeArenaCapacity(maxArenas, self:Count(prioritized))
    local activePairs, queuedPairs = self:AllocatePairs(prioritized, availableArenas)


    if ownerSession and ownerSession.active == 1 and ownerSession.unifiedEntries == entries then
        ownerSession.pairingBuilt = 1
        ownerSession.pairingRosterKey = entries.liendauRosterKey
        ownerSession.activePairs = activePairs
        ownerSession.queuedPairs = queuedPairs
        ownerSession.byeEntry = byeEntry
        ownerSession.prioritizedPairs = prioritized
        ownerSession.pairingCapacity = availableArenas
    end
    return activePairs, queuedPairs, byeEntry
end
