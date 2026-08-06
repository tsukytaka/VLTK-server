-- \script\global\quochuy\item\hopthu_lib.lua
szPathInBox   = "data/quochuy/mailbox/inbox/"
szPathOutBox  = "data/quochuy/mailbox/outbox/"
szPathContact = "data/quochuy/mailbox/contact/"

-- ================= CAC HAM TIEN ICH =================

function max(a, b) if a > b then return a else return b end end
function min(a, b) if a < b then return a else return b end end

function split(str, delim)
    local result = {}
    local i = 1
    local from = 1
    local s, e = strfind(str, delim, from, true)
    while s do
        result[i] = strsub(str, from, s - 1)
        i = i + 1
        from = e + 1
        s, e = strfind(str, delim, from, true)
    end
    result[i] = strsub(str, from)
    return result
end

function SanitizeText(text)
    if not text then return "" end
    text = gsub(text, "|", "-") 
    text = gsub(text, "\n", " ") 
    return text
end

function StringToHex(str)
    if not str then return "" end
    local hex = ""
    for i = 1, strlen(str) do
        hex = hex .. format("%02x", strbyte(strsub(str, i, i)))
    end
    return hex
end

function HexToString(hex)
    if not hex then return "" end
    local text = ""
    for i = 1, strlen(hex), 2 do
        local nByte = tonumber(strsub(hex, i, i + 1), 16)
        if nByte then text = text .. strchar(nByte) end
    end
    return text
end

function MailNum(v, d)
    v = tonumber(v)
    if v then return v end
    return d or 0
end

function MailPack(...)
    return arg
end

function MailJoin(tb, sep)
    local s = ""
    for i = 1, getn(tb) do
        if i > 1 then s = s .. sep end
        s = s .. tostring(tb[i])
    end
    return s
end

function EnsureMailboxDir(path)
    local f = openfile(path .. "__test.tmp", "a")
    if f then closefile(f) return 1 end
    if execute then
        execute("mkdir -p " .. path)
        execute("mkdir data\\quochuy\\mailbox")
        execute("mkdir data\\quochuy\\mailbox\\inbox")
        execute("mkdir data\\quochuy\\mailbox\\outbox")
        execute("mkdir data\\quochuy\\mailbox\\contact")
    end
    f = openfile(path .. "__test.tmp", "a")
    if f then closefile(f) return 1 end
    return 0
end

function MailInboxPath(charName)
    return szPathInBox .. StringToHex(charName) .. ".txt"
end

function MailOutboxPath(charName)
    return szPathOutBox .. "out_" .. StringToHex(charName) .. ".txt"
end

function MailFileExists(path)
    local f = openfile(path, "r")
    if f then closefile(f) return 1 end
    return 0
end

function GenerateMailID()
    return tostring(random(1000000, 9999999))
end

function NewMail(senderName, receiverName, title, content, itemId, goldAmount, itemCount, itemName, itemD, mailID, sendTime, ItemG, ItemL, itemData)
    return {
        From = SanitizeText(senderName),
        Title = SanitizeText(title),
        Content = SanitizeText(content),
        ItemID = tonumber(itemId) or 0,
        Gold = tonumber(goldAmount) or 0,
        ItemCount = tonumber(itemCount) or 1,
        ItemName = SanitizeText(itemName),  
        isClaimed = 0,
        ItemD = tonumber(itemD) or 1,
        MailID = mailID or "0",
        To = SanitizeText(receiverName),
        SendTime = sendTime or "",
        ItemG = tonumber(ItemG) or 0,
        ItemL = tonumber(ItemL) or 0,
        ItemData = itemData or ""
    }
end

function SerializeMail(mail)
    local s = tostring(mail.From)
    s = s .. "|" .. tostring(mail.Title)
    s = s .. "|" .. tostring(mail.Content)
    s = s .. "|" .. tostring(mail.ItemID)
    s = s .. "|" .. tostring(mail.Gold + 0)
    s = s .. "|" .. tostring(mail.ItemCount or 1)
    s = s .. "|" .. tostring(mail.ItemName or "")  
    s = s .. "|" .. tostring(mail.isClaimed)
    s = s .. "|" .. tostring(mail.ItemD or 1) 
    s = s .. "|" .. tostring(mail.MailID or "0")
    s = s .. "|" .. tostring(mail.To or "")
    s = s .. "|" .. tostring(mail.SendTime or "")
    s = s .. "|" .. tostring(mail.ItemG or 0)
    s = s .. "|" .. tostring(mail.ItemL or 0)
    s = s .. "|" .. tostring(mail.ItemData or "")
    return s
end

-- ================= DOC/GHI INBOX (Hop Thu Den) =================

function SaveMailbox(charName)
    if EnsureMailboxDir(szPathInBox) ~= 1 then return 0 end
    local path = MailInboxPath(charName)
    local f = openfile(path, "w")
    if not f then print("Loi mo file: " .. path) return 0 end
    local list = MailBox[charName] or {}
    for i = 1, getn(list) do
        write(f, SerializeMail(list[i]) .. "\n")
    end
    closefile(f)
    return 1
end

function RemoveMailFile(path)
    -- Thu dung ham mac dinh cua mot so ban JX
    if RemoveFile then 
        RemoveFile(path) 
    else
        -- Neu ko co ham xoa, ta mo file che do "w" (ghi de) roi dong lai luon -> File se co dung luong 0kb
        local f = openfile(path, "w")
        if f then closefile(f) end
    end
end

function FilterExpiredMail(list)
    local newList = {}
    -- Lay ngay hien tai duoi dang so: 20260312
    local szToday = GetLocalDate("%Y%m%d")
    local nToday = tonumber(szToday)

    for i = 1, getn(list) do
        local mail = list[i]
        local isExpired = false
        
        -- Lay ngay gui tu chuoi SendTime (202603112008 -> 20260311)
        if mail.SendTime and strlen(mail.SendTime) >= 8 then
            local nMailDate = tonumber(strsub(mail.SendTime, 1, 8))
            
            -- Logic don gian: Neu nToday - nMailDate > 100 (tuong duong 1 thang trong format YYYYMMDD)
            -- Hoac tinh chinh xac hon theo thang:
            if (nToday - nMailDate) >= 100 then 
                isExpired = true
            end
        end

        if not isExpired then
            tinsert(newList, mail)
        end
    end
    return newList
end

function LoadMailbox(charName)
    MailBox = MailBox or {}
    local safeName = StringToHex(charName)
    local path = szPathInBox .. safeName .. ".txt"
    local f = openfile(path, "r")
    MailBox[charName] = {}
    if not f then return end
    
    local rawList = {}
    local line = read(f)
    while line do
        line = gsub(line, "\r", "")
        if line ~= "" then
            local parts = split(line, "|")
		while getn(parts) < 15 do parts[getn(parts) + 1] = "0" end
            local mail = {
                From = parts[1], Title = parts[2], Content = parts[3],
                ItemID = tonumber(parts[4]) or 0, Gold = tonumber(parts[5]) or 0,
                ItemCount = tonumber(parts[6]) or 1, ItemName = parts[7] or "", 
                isClaimed = tonumber(parts[8]) or 0, ItemD = tonumber(parts[9]) or 1,
                MailID = parts[10] or "0", To = parts[11] or "",
                SendTime = parts[12] or "",
                ItemG = tonumber(parts[13]) or 0,
                ItemL = tonumber(parts[14]) or 0,
                ItemData = parts[15] or ""
            }
            tinsert(rawList, mail)
        end
        line = read(f)
    end
    closefile(f)

    -- Loc thu het han
    MailBox[charName] = FilterExpiredMail(rawList)
end

function CleanMailbox(charName)
    local list = MailBox[charName] or {}
    local cleaned = {}
    for i = 1, getn(list) do
        if tonumber(list[i].isClaimed) == 0 then
            tinsert(cleaned, list[i])
        end
    end
    
    MailBox[charName] = cleaned
    local path = MailInboxPath(charName)

    if getn(cleaned) > 0 then
        SaveMailbox(charName) 
    else
        -- Neu thong ke ko con thu, xoa file
        RemoveMailFile(path)
    end
end

function EnsureMailboxLoaded(charName)
    if not MailBox then MailBox = {} end
    if not MailBox[charName] then LoadMailbox(charName) end
end

-- ================= DOC/GHI OUTBOX (Hop Thu Da Gui) =================

function SaveOutbox(charName)
    if EnsureMailboxDir(szPathOutBox) ~= 1 then return 0 end
    local path = MailOutboxPath(charName)
    local f = openfile(path, "w")
    if not f then print("Loi mo file: " .. path) return 0 end
    local list = MailBoxOut[charName] or {}
    for i = 1, getn(list) do
        write(f, SerializeMail(list[i]) .. "\n")
    end
    closefile(f)
    return 1
end

function LoadOutbox(charName)
    MailBoxOut = MailBoxOut or {}
    local path = MailOutboxPath(charName)
    local f = openfile(path, "r")
    MailBoxOut[charName] = {}
    if not f then return end
    
    local line = read(f)
    while line do
        line = gsub(line, "\r", "")
        if line ~= "" then
            local parts = split(line, "|")
            while getn(parts) < 15 do parts[getn(parts) + 1] = "0" end
            local mail = {
                From = parts[1], Title = parts[2], Content = parts[3],
                ItemID = tonumber(parts[4]) or 0, Gold = tonumber(parts[5]) or 0,
                ItemCount = tonumber(parts[6]) or 1, ItemName = parts[7] or "", 
                isClaimed = tonumber(parts[8]) or 0, ItemD = tonumber(parts[9]) or 1,
                MailID = parts[10] or "0", To = parts[11] or "",
                SendTime = parts[12] or "",
				ItemG = tonumber(parts[13]) or 0,
                ItemL = tonumber(parts[14]) or 0,
                ItemData = parts[15] or ""
            }
            tinsert(MailBoxOut[charName], mail)
        end
        line = read(f)
    end
    closefile(f)
end

function CleanOutbox(charName)
    local list = MailBoxOut[charName] or {}
    local cleaned = {}
    for i = 1, getn(list) do
        if tonumber(list[i].isClaimed) == 0 then
            tinsert(cleaned, list[i])
        end
    end
    MailBoxOut[charName] = cleaned
    SaveOutbox(charName) 
end

function EnsureOutboxLoaded(charName)
    if not MailBoxOut then MailBoxOut = {} end
    if not MailBoxOut[charName] then LoadOutbox(charName) end
end

function MailFindOpenIndex(list, mailID)
    if not list or not mailID then return -1 end
    for i = 1, getn(list) do
        if list[i].MailID == mailID and tonumber(list[i].isClaimed) == 0 then
            return i
        end
    end
    return -1
end

function MailFindAnyIndex(list, mailID)
    if not list or not mailID then return -1 end
    for i = 1, getn(list) do
        if list[i].MailID == mailID then
            return i
        end
    end
    return -1
end

function MailOutboxHasOpenMail(senderName, mailID)
    if not senderName or senderName == "" then return 0 end
    if MailFileExists(MailOutboxPath(senderName)) ~= 1 then return 0 end
    LoadOutbox(senderName)
    if MailFindOpenIndex(MailBoxOut[senderName] or {}, mailID) > 0 then return 1 end
    return 0
end

function MailInboxHasOpenMail(receiverName, mailID)
    if not receiverName or receiverName == "" then return 0 end
    if MailFileExists(MailInboxPath(receiverName)) ~= 1 then return 0 end
    LoadMailbox(receiverName)
    if MailFindOpenIndex(MailBox[receiverName] or {}, mailID) > 0 then return 1 end
    return 0
end

function MailMarkOutboxClaimed(senderName, mailID)
    if not senderName or senderName == "" then return 0 end
    LoadOutbox(senderName)
    local list = MailBoxOut[senderName] or {}
    local idx = MailFindAnyIndex(list, mailID)
    if idx > 0 then
        list[idx].isClaimed = 1
        CleanOutbox(senderName)
        return 1
    end
    return 0
end

function MailMarkInboxClaimed(receiverName, mailID)
    if not receiverName or receiverName == "" then return 0 end
    LoadMailbox(receiverName)
    local list = MailBox[receiverName] or {}
    local idx = MailFindAnyIndex(list, mailID)
    if idx > 0 then
        list[idx].isClaimed = 1
        CleanMailbox(receiverName)
        return 1
    end
    return 0
end

function MailSyncInboxState(receiverName)
    LoadMailbox(receiverName)
    local list = MailBox[receiverName] or {}
    local changed = 0
    for i = 1, getn(list) do
        local mail = list[i]
        if tonumber(mail.isClaimed) == 0 and mail.From and mail.From ~= "" then
            if MailFileExists(MailOutboxPath(mail.From)) ~= 1 then
                mail.isClaimed = 1
                changed = 1
            else
                LoadOutbox(mail.From)
                if MailFindOpenIndex(MailBoxOut[mail.From] or {}, mail.MailID) < 1 then
                    mail.isClaimed = 1
                    changed = 1
                end
            end
        end
    end
    if changed == 1 then CleanMailbox(receiverName) end
end

function MailSyncOutboxState(senderName)
    LoadOutbox(senderName)
    local list = MailBoxOut[senderName] or {}
    local changed = 0
    for i = 1, getn(list) do
        local mail = list[i]
        if tonumber(mail.isClaimed) == 0 and mail.To and mail.To ~= "" then
            if MailFileExists(MailInboxPath(mail.To)) ~= 1 then
                mail.isClaimed = 1
                changed = 1
            else
                LoadMailbox(mail.To)
                if MailFindOpenIndex(MailBox[mail.To] or {}, mail.MailID) < 1 then
                    mail.isClaimed = 1
                    changed = 1
                end
            end
        end
    end
    if changed == 1 then CleanOutbox(senderName) end
end

function MailRefreshUser(charName)
    MailSyncInboxState(charName)
    MailSyncOutboxState(charName)
    LoadMailbox(charName)
    LoadOutbox(charName)
end

-- ================= DANH BA GAN DAY =================

function SaveContacts(charName)
    if EnsureMailboxDir(szPathContact) ~= 1 then return 0 end
    local safeName = StringToHex(charName)
    local path = szPathContact .. safeName .. ".txt"
    local f = openfile(path, "w")
    if not f then return end
    local list = MailContacts[charName] or {}
    for i = 1, getn(list) do
        write(f, list[i] .. "\n")
    end
    closefile(f)
end

function LoadContacts(charName)
    MailContacts = MailContacts or {}
    local safeName = StringToHex(charName)
    local path = szPathContact .. safeName .. ".txt"
    local f = openfile(path, "r")
    MailContacts[charName] = {}
    if not f then return end
    local line = read(f)
    while line do
        line = gsub(line, "\r", "")
        if line ~= "" then
            tinsert(MailContacts[charName], line)
        end
        line = read(f)
    end
    closefile(f)
end

function AddContact(senderName, receiverName)
    EnsureContactsLoaded(senderName)
    local list = MailContacts[senderName] or {}
    local newList = {receiverName} 
    
    for i = 1, getn(list) do
        if list[i] ~= receiverName then
            tinsert(newList, list[i])
        end
        if getn(newList) >= 8 then break end 
    end
    
    MailContacts[senderName] = newList
    SaveContacts(senderName)
end

function EnsureContactsLoaded(charName)
    if not MailContacts then MailContacts = {} end
    if not MailContacts[charName] then LoadContacts(charName) end
end

function FindPlayerOnline(szRoleName)
    local nOldIdx = PlayerIndex
    local nMaxPlayer = 2000
    local nFound = 0
    
    for i = 1, nMaxPlayer do

        PlayerIndex = i 

        local szName = GetName() 
        
        if szName and szName == szRoleName then
            nFound = i
            break 
        end
    end

    PlayerIndex = nOldIdx 
    
    return nFound
end

function MailReadMagicList(nItemIndex)
    local tbMagic = {}
    for i = 1, 6 do
        tbMagic[i] = MailPack(GetItemMagicAttrib(nItemIndex, i))
    end
    return tbMagic
end

function MailNewItemData(nItemIndex)
    if not nItemIndex or nItemIndex <= 0 then return nil end
    local tb = {}
    tb.szName = GetItemName(nItemIndex) or "Unknown"
    tb.nVersion = 4
    tb.nRandSeed = ITEM_GetItemRandSeed(nItemIndex) or 0
    tb.nQuality = GetItemQuality(nItemIndex) or 0
    tb.nBindState = GetItemBindState(nItemIndex) or 0
    tb.tbParam = GetItemAllParams(nItemIndex) or {0,0,0,0,0,0}
    tb.nUpgradeLevel = GetPlatinaLevel(nItemIndex) or 0
    tb.nExpiredTime = ITEM_GetExpiredTime(nItemIndex) or 0
    tb.nLeftUsageTime = ITEM_GetLeftUsageTime(nItemIndex) or 0
    tb.nStackable = IsItemStackable(nItemIndex) or 0
    tb.tbMagic = MailReadMagicList(nItemIndex)
    tb.nGoldId = 0
    if tb.nQuality == 1 then
        tb.nGoldId = GetGlodEqIndex(nItemIndex) or 0
        tb.tbProp = {0, tb.nGoldId, 0, 0, 0, 0}
    elseif tb.nQuality == 4 then
        tb.tbProp = {0, GetPlatinaEquipIndex(nItemIndex) or 0, 0, 0, 0, 0}
    else
        tb.tbProp = MailPack(GetItemProp(nItemIndex))
    end
    if tb.nStackable == 1 then
        tb.nCount = GetItemStackCount(nItemIndex) or 1
        tb.nCurDurability = 0
        tb.nMaxDurability = 0
    else
        tb.nCount = 1
        tb.nCurDurability = GetCurDurability(nItemIndex) or 0
        tb.nMaxDurability = GetMaxDurability(nItemIndex) or 0
    end
    return tb
end

function MailItemGoldId(tb)
    if tb.nGoldId and tb.nGoldId > 0 then return tb.nGoldId end
    if tb.nQuality == 1 and tb.tbProp and tb.tbProp[2] and tb.tbProp[2] > 0 then return tb.tbProp[2] end
    return 0
end

function MailSerializeItem(tb)
    if not tb then return "" end
    local line = {}
    tinsert(line, "1")
    tinsert(line, StringToHex(tb.szName or ""))
    tinsert(line, tb.nVersion or 4)
    tinsert(line, tb.nRandSeed or 0)
    tinsert(line, tb.nQuality or 0)
    tinsert(line, tb.nBindState or 0)
    tinsert(line, tb.nCount or 1)
    tinsert(line, tb.nStackable or 0)
    tinsert(line, tb.nCurDurability or 0)
    tinsert(line, tb.nMaxDurability or 0)
    tinsert(line, tb.nExpiredTime or 0)
    tinsert(line, tb.nLeftUsageTime or 0)
    tinsert(line, tb.nUpgradeLevel or 0)
    for i = 1, 6 do tinsert(line, (tb.tbProp and tb.tbProp[i]) or 0) end
    for i = 1, 6 do tinsert(line, (tb.tbParam and tb.tbParam[i]) or 0) end
    tinsert(line, MailItemGoldId(tb))
    for i = 1, 6 do
        for j = 1, 4 do
            tinsert(line, (tb.tbMagic and tb.tbMagic[i] and tb.tbMagic[i][j]) or 0)
        end
    end
    return StringToHex(MailJoin(line, "#"))
end

function MailSerializeItemList(tbList)
    if not tbList or getn(tbList) <= 0 then return "" end
    if getn(tbList) == 1 then
        return tbList[1]
    end
    return "M2" .. StringToHex(MailJoin(tbList, "~"))
end

function MailUnserializeItemList(itemData)
    local tbList = {}
    if not itemData or itemData == "" or itemData == "0" then return tbList end
    if strsub(itemData, 1, 2) == "M2" then
        local raw = HexToString(strsub(itemData, 3))
        local parts = split(raw, "~")
        for i = 1, getn(parts) do
            if parts[i] and parts[i] ~= "" then
                local tb = MailUnserializeItem(parts[i])
                if tb then tinsert(tbList, tb) end
            end
        end
    else
        local tb = MailUnserializeItem(itemData)
        if tb then tinsert(tbList, tb) end
    end
    return tbList
end

function MailItemDataCount(itemData)
    local tbList = MailUnserializeItemList(itemData)
    return getn(tbList)
end

function MailUnserializeItem(hex)
    local raw = HexToString(hex or "")
    if raw == "" then return nil end
    local p = split(raw, "#")
    if getn(p) < 26 then return nil end
    local tb = {}
    tb.szName = HexToString(p[2])
    tb.nVersion = MailNum(p[3], 4)
    tb.nRandSeed = MailNum(p[4], 0)
    tb.nQuality = MailNum(p[5], 0)
    tb.nBindState = MailNum(p[6], 0)
    tb.nCount = MailNum(p[7], 1)
    tb.nStackable = MailNum(p[8], 0)
    tb.nCurDurability = MailNum(p[9], 0)
    tb.nMaxDurability = MailNum(p[10], 0)
    tb.nExpiredTime = MailNum(p[11], 0)
    tb.nLeftUsageTime = MailNum(p[12], 0)
    tb.nUpgradeLevel = MailNum(p[13], 0)
    tb.tbProp = {}
    tb.tbParam = {}
    for i = 1, 6 do tb.tbProp[i] = MailNum(p[13 + i], 0) end
    for i = 1, 6 do tb.tbParam[i] = MailNum(p[19 + i], 0) end
    tb.nGoldId = MailNum(p[26], 0)
    tb.tbMagic = {}
    local pos = 27
    for i = 1, 6 do
        tb.tbMagic[i] = {}
        for j = 1, 4 do
            tb.tbMagic[i][j] = MailNum(p[pos], 0)
            pos = pos + 1
        end
    end
    return tb
end

function MailApplyItemState(nItemIndex, tb)
    if IsItemStackable(nItemIndex) == 1 then
        SetItemStackCount(nItemIndex, tb.nCount or 1)
    else
        if tb.nCurDurability and tb.nCurDurability > 0 then SetCurDurability(nItemIndex, tb.nCurDurability) end
        if tb.nMaxDurability and tb.nMaxDurability > 0 then SetMaxDurability(nItemIndex, tb.nMaxDurability) end
    end
    if tb.nExpiredTime and tb.nExpiredTime > 0 then ITEM_SetExpiredTime(nItemIndex, tb.nExpiredTime) end
    if tb.nLeftUsageTime and tb.nLeftUsageTime > 0 then ITEM_SetLeftUsageTime(nItemIndex, tb.nLeftUsageTime) end
    if tb.nBindState and tb.nBindState ~= 0 then SetItemBindState(nItemIndex, tb.nBindState) end
    return nItemIndex
end

function MailCreateItem(tb)
    if not tb then return 0 end
    local nRow = 0
    if tb.nQuality == 1 or tb.nQuality == 4 then nRow = 1 end
    if tb.nQuality == 1 then
        tb.tbProp = tb.tbProp or {}
        tb.tbProp[1] = 0
        tb.tbProp[2] = MailItemGoldId(tb)
    end
    local nItemIndex = NewItemEx(
        tb.nVersion or 4,
        tonumber(format("%u", tb.nRandSeed or 0)),
        tb.nQuality or 0,
        tb.tbProp[1] or 0,
        (tb.tbProp[2] or 0) - nRow,
        tb.tbProp[3] or 0,
        tb.tbProp[4] or 0,
        tb.tbProp[5] or random(0, 4),
        tb.tbProp[6] or 0,
        tb.tbParam[1] or 0,
        tb.tbParam[2] or 0,
        tb.tbParam[3] or 0,
        tb.tbParam[4] or 0,
        tb.tbParam[5] or 0,
        tb.tbParam[6] or 0,
        tb.nUpgradeLevel or 0
    )
    if not nItemIndex or nItemIndex <= 0 then return 0 end
    return MailApplyItemState(nItemIndex, tb)
end
