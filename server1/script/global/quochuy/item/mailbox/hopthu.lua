-- \script\global\quochuy\item\hopthu.lua
IncludeLib("SETTING")
IncludeLib("ITEM")
IncludeLib("TITLE")
IncludeLib("STRING")
IncludeLib("TABLE")
Include("\\script\\dailogsys\\dailogsay.lua")
Include("\\script\\global\\quochuy\\chucnang\\hide_box_item_res_lib.lua")
Include("\\script\\global\\quochuy\\item\\mailbox\\hopthu_lib.lua")
function main()
    --    dofile("script/global/quochuy/item/mailbox/hopthu.lua")
    OnMailMenu()
    return 1
end

-- ================= HIEN THI MENU CHINH =================

function MailHasItem(mail)
    if not mail then return 0 end
    if mail.ItemID and mail.ItemID > 0 then return 1 end
    if mail.ItemData and mail.ItemData ~= "" and mail.ItemData ~= "0" then return 1 end
    return 0
end

function MailCountOpen(list)
    local n = 0
    list = list or {}
    for i = 1, getn(list) do
        if tonumber(list[i].isClaimed) == 0 then n = n + 1 end
    end
    return n
end

function MailRecentName(list, field)
    list = list or {}
    for i = getn(list), 1, -1 do
        if tonumber(list[i].isClaimed) == 0 and list[i][field] and list[i][field] ~= "" then
            return list[i][field]
        end
    end
    return "Kh«ng cã"
end

function MailTimeText(mail)
    if not mail or not mail.SendTime or mail.SendTime == "" or mail.SendTime == "0" then return "" end
    local tStr = tostring(mail.SendTime)
    if strlen(tStr) >= 12 then
        return " <color=yellow>["..strsub(tStr, 9, 10)..":"..strsub(tStr, 11, 12).." | "..strsub(tStr, 7, 8).."/"..strsub(tStr, 5, 6).."/"..strsub(tStr, 1, 4).."]<color>"
    end
    return " <color=yellow>["..tStr.."]<color>"
end

function MailItemColor(tb)
    if not tb then return "yellow" end
    if tb.nQuality == 1 then return "yellow" end
    if tb.nQuality == 2 then return "pink" end
    if tb.nQuality == 4 then return "gold" end
    if tb.tbProp and tb.tbProp[1] == 0 then return "blue" end
    return "yellow"
end

function MailCleanResPath(szSpr)
    if not szSpr or szSpr == "" then return "" end
    szSpr = gsub(szSpr, "/", "\\")
    if strsub(szSpr, 1, 1) ~= "\\" then
        szSpr = "\\"..szSpr
    end
    if not strfind(strlower(szSpr), "%.spr") then
        szSpr = szSpr..".spr"
    end
    return szSpr
end

function MailItemImagePath(tb)
    if not tb or not HIDE_BOX_ITEM_RES_DATA then return "" end
    if tb.nQuality == 1 then
        return MailCleanResPath(HIDE_BOX_ITEM_RES_DATA.gold[MailItemGoldId(tb)])
    end
    if tb.nQuality == 4 then
        return MailCleanResPath(HIDE_BOX_ITEM_RES_DATA.platina[(tb.tbProp and tb.tbProp[2]) or 0])
    end
    if tb.tbProp then
        local szKey = (tb.tbProp[2] or 0).."_"..(tb.tbProp[3] or 0).."_"..(tb.tbProp[4] or 0)
        return MailCleanResPath(HIDE_BOX_ITEM_RES_DATA.normal[szKey])
    end
    return ""
end

function MailItemImageTag(tb)
    local szPath = MailItemImagePath(tb)
    if szPath == "" then return "" end
    return "<link=image:"..szPath.."><link><color>\n"
end

function MailMagicDesc(tbMagic)
    if not tbMagic or not tbMagic[1] or tbMagic[1] <= 0 then return "" end
    if GetItemMagicDesc then
        local s = GetItemMagicDesc(tbMagic[1], tbMagic[2] or 0, tbMagic[3] or 0, tbMagic[4] or 0)
        if s and s ~= "" then return s end
    end
    return "Magic "..(tbMagic[1] or 0)..": "..(tbMagic[2] or 0)..","..(tbMagic[3] or 0)..","..(tbMagic[4] or 0)
end

function MailItemPreviewText(mail)
    if not mail or MailHasItem(mail) ~= 1 then return "" end
    if mail.ItemData and mail.ItemData ~= "" and mail.ItemData ~= "0" then
        local tbList = MailUnserializeItemList(mail.ItemData)
        if getn(tbList) > 0 then
            local s = "\n[VËt phÈm ®Ýnh kÌm] <color=yellow>"..getn(tbList).."<color> mãn"
            for n = 1, getn(tbList) do
                local tb = tbList[n]
                s = s.."\n"..n..". "..MailItemImageTag(tb).."<color="..MailItemColor(tb)..">"..(tb.szName or mail.ItemName or "VËt phÈm").."<color> x"..(tb.nCount or 1)
                --s = s.."\nLo¹i: "..(tb.nQuality or 0).." | RandSeed: "..(tb.nRandSeed or 0)
                local szMagic = ""
                for i = 1, 6 do
                    local desc = MailMagicDesc(tb.tbMagic and tb.tbMagic[i])
                    if desc ~= "" then
                        szMagic = szMagic.."\n<color="..MailItemColor(tb)..">"..desc.."<color>"
                    end
                end
                if szMagic ~= "" then s = s.."\nThuéc tÝnh:"..szMagic end
            end
            return s
        end
    end
    return "\n[VËt phÈm ®Ýnh kÌm]\n<color=yellow>"..(mail.ItemName or "VËt phÈm").."<color> x"..(mail.ItemCount or 1)
end

function MailRestoreItemData(itemData)
    local tbList = MailUnserializeItemList(itemData)
    local nOk = 0
    for i = 1, getn(tbList) do
        local nBackIdx = MailCreateItem(tbList[i])
        if nBackIdx and nBackIdx > 0 then
            AddItemByIndex(nBackIdx)
            nOk = nOk + 1
        end
    end
    return nOk
end

function MailCreateAttachedItems(itemData)
    local tbList = MailUnserializeItemList(itemData)
    local tbIndex = {}
    for i = 1, getn(tbList) do
        local nNewIdx = MailCreateItem(tbList[i])
        if not nNewIdx or nNewIdx <= 0 then
            return nil
        end
        tinsert(tbIndex, nNewIdx)
    end
    return tbIndex
end

function MailAddCreatedItems(tbIndex)
    if not tbIndex then return 0 end
    for i = 1, getn(tbIndex) do
        AddItemByIndex(tbIndex[i])
    end
    return getn(tbIndex)
end

function OnMailMenu()
    local charName = GetName()
    MailRefreshUser(charName)
    local inList = MailBox[charName] or {}
    local outList = MailBoxOut[charName] or {}
    local nInbox = MailCountOpen(inList)
    local nOutbox = MailCountOpen(outList)
    local szText = "Chµo! Ta nhËn chuyÓn ®å vµ tiÒn, kÓ c¶ khi hä kh«ng cã mÆt.\n<color=red>PhÝ göi lµ 1 v¹n.<color>\nB¹n cã thÓ thu håi nÕu lë tay göi nhÇm tr­íc khi hä nhËn ®å."
    szText = szText.."\n\nTh­ ®Õn: <color=yellow>"..nInbox.."<color> | Th­ ®i: <color=yellow>"..nOutbox.."<color>"
    szText = szText.."\nNg­êi göi gÇn nhÊt: <color=green>"..MailRecentName(outList, "To").."<color>"
    szText = szText.."\nNg­êi nhËn gÇn nhÊt: <color=green>"..MailRecentName(inList, "From").."<color>"
    local tbOpt = {
        {"1. Göi tiÒn v¹n", ChooseSendGold},
        {"2. Göi VËt PhÈm", ChooseAttachItem},
        {"3. Hép th­ ®Õn ("..nInbox..")", ChooseInbox},
        {"4. Hép th­ ®i ("..nOutbox..")", ChooseOutbox},
        {"Tho¸t", OnCancel}
    }
    CreateNewSayEx(szText, tbOpt)
end

-- ================= LOGIC GUI THU =================
function SendMail(senderName, receiverName, title, content, itemId, goldAmount, itemCount, itemName, itemD, itemG, itemL, itemData)
    MailBox = MailBox or {}  
    if (not title or title == "") and (not content or content == "") and ((tonumber(itemId) or 0) == 0) and ((tonumber(goldAmount) or 0) == 0) and (not itemData or itemData == "") then
        return 0, "Kh«ng thÓ göi th­ rçng."
    end

    EnsureMailboxLoaded(receiverName)

    MailBox[receiverName] = MailBox[receiverName] or {}
    if getn(MailBox[receiverName]) >= 10 then
        return 0, "Hép th­ ng­êi nhËn ®Çy ko thÓ göi lóc nµy."
    end

    local mailFee = 10000 
    local totalCost = mailFee
    if goldAmount and goldAmount > 0 then
        totalCost = totalCost + goldAmount
    end

    local myCash = GetCash()
    if myCash < totalCost then
        return 0, "B¹n kh«ng ®ñ tiÒn v¹n ®Ó tr¶ phÝ göi th­ (CÇn Ýt nhÊt 1 V¹n)."
    end

    if (itemId and itemId > 0) or (itemData and itemData ~= "") then
        local pd = PlayerData[PlayerIndex]
        if not pd or not pd.AttachItemList or getn(pd.AttachItemList) <= 0 then return 0, "Lçi d÷ liÖu vËt phÈm!" end

        for i = 1, getn(pd.AttachItemList) do
            local it = pd.AttachItemList[i]
            local currG, currD, currP, currL = GetItemProp(it.Index)
            local currCount = GetItemStackCount(it.Index) or 1
            if currG ~= it.G or currD ~= it.D or currP ~= it.P or currCount < it.Count then
                return 0, "VËt phÈm ®Ýnh kÌm ®· bÞ thay ®æi hoÆc kh«ng ®ñ sè l­îng! Hñy göi th­."
            end
        end
        itemData = pd.AttachItemData or itemData or ""

        local tbRemoved = {}
        for i = 1, getn(pd.AttachItemList) do
            local it = pd.AttachItemList[i]
            if RemoveItemByIndex(it.Index) == 1 then
                tinsert(tbRemoved, it.Data)
            else
                MailRestoreItemData(MailSerializeItemList(tbRemoved))
                return 0, "Kh«ng thÓ xãa vËt phÈm trong hµnh trang. Hñy göi!"
            end
        end
    end
  
    local mailID = GenerateMailID()
	local sendTime =  GetLocalDate("%Y%m%d%H%M")
	local mail = NewMail(senderName, receiverName, title, content, itemId, goldAmount, itemCount, itemName, itemD, mailID, sendTime, itemG, itemL, itemData)
    
    local inList = MailBox[receiverName]
    tinsert(inList, mail)
    if SaveMailbox(receiverName) ~= 1 then
        tremove(inList, getn(inList))
        if itemData and itemData ~= "" then MailRestoreItemData(itemData) end
        return 0, "Kh«ng l­u ®­îc hép th­ ng­êi nhËn."
    end
    
    MailBoxOut = MailBoxOut or {}
    MailBoxOut[senderName] = MailBoxOut[senderName] or {}
    tinsert(MailBoxOut[senderName], mail)
    if SaveOutbox(senderName) ~= 1 then
        tremove(MailBoxOut[senderName], getn(MailBoxOut[senderName]))
        tremove(inList, getn(inList))
        SaveMailbox(receiverName)
        if itemData and itemData ~= "" then MailRestoreItemData(itemData) end
        return 0, "Kh«ng l­u ®­îc hép th­ ®i."
    end
    Pay(totalCost)
    
   -- AddContact(senderName, receiverName) -- Luu vao Danh ba gan day
	local nSenderIdx = PlayerIndex
    local nTargetIdx = FindPlayerOnline(receiverName)
		if nTargetIdx > 0 and nTargetIdx ~= nSenderIdx then
				PlayerIndex = nTargetIdx
				Msg2Player("<color=cyan>NhËn ®­îc th­ míi tõ: <color=yellow>"..senderName.."<color><color>")
				PutMessage("NhËn th­ míi tõ :"..senderName)
				PlayerIndex = nSenderIdx
		end
    return 1, "Göi th­ thµnh c«ng ®Õn: " .. receiverName .. " (PhÝ: 1 V¹n)"
end

-- ================= LOGIC INBOX =================
function ChooseInbox()
    local charName = GetName()
    MailRefreshUser(charName)
    DisplayMailbox(charName)
end

function DisplayMailbox(charName)
    local list = MailBox[charName] or {}
    local nCount = MailCountOpen(list)
    if nCount == 0 then
        CreateNewSayEx("Ng­¬i kh«ng cã th­ nµo ®Ó ®äc.", {{"Quay l¹i", OnMailMenu}, {"Tho¸t", OnCancel}})
        return
    end
    local opts = {}
    for i = 1, getn(list) do
        if list[i].isClaimed == 0 then
            tinsert(opts, {"[" .. i .. "] Th­ cña: " .. list[i].From, ReadMail, {i}})
        end
    end
    tinsert(opts, {"Quay l¹i", OnMailMenu})
    tinsert(opts, {"Tho¸t", OnCancel})
    CreateNewSayEx("Hép th­ ®Õn (<color=yellow>"..nCount.."<color>)\nNg­êi göi gÇn nhÊt: <color=green>"..MailRecentName(list, "From").."<color>", opts)
end

function ReadMail(index)
    local charName = GetName()
    MailRefreshUser(charName)
    local list = MailBox[charName] or {}
    local mail = list[index]
    if not mail then
        CreateNewSayEx("Th­ kh«ng tån t¹i.", {{"Quay l¹i", ChooseInbox}})
        return
    end
    local text = "<color=red>Tõ: <color>" .. mail.From .." | Thêi gian"..MailTimeText(mail).. "\n<color=blue>Tiªu ®Ò: <color>" .. mail.Title .. "\n<color=green>Néi dung:<color>" .. mail.Content
    text = text .. MailItemPreviewText(mail)
    if mail.Gold > 0 then text = text .. "\n\n<color=yellow>- Vµng: " .. mail.Gold end
    if mail.isClaimed == 1 then
        CreateNewSayEx(text .. "\n(§· nhËn)", {{"Quay l¹i", ChooseInbox}, {"Tho¸t", OnCancel}})
    else
        CreateNewSayEx(text, {{"NhËn th­ nµy", ClaimMail, {index}}, {"Quay l¹i", ChooseInbox}, {"Tho¸t", OnCancel}})
    end
end

function ClaimMail(index)
    local charName = GetName()
    MailRefreshUser(charName)
    local list = MailBox[charName] or {}
    local mail = list[index]
    
    if not mail or mail.isClaimed == 1 then
        CreateNewSayEx("Kh«ng hîp lÖ hoÆc ®· nhËn.", {{"Quay l¹i", ChooseInbox}})
        return
    end

    if MailOutboxHasOpenMail(mail.From, mail.MailID) ~= 1 then
        MailMarkInboxClaimed(charName, mail.MailID)
        CreateNewSayEx("Th­ nµy ®· ®­îc ng­êi göi thu håi.", {{"Quay l¹i", ChooseInbox}})
        return
    end
    
    if mail.ItemID > 0 or (mail.ItemData and mail.ItemData ~= "" and mail.ItemData ~= "0") then
        local nNeedCell = MailItemDataCount(mail.ItemData)
        if nNeedCell <= 0 then nNeedCell = 1 end
        if CalcFreeItemCellCount() < nNeedCell then
            CreateNewSayEx("Hµnh trang cña b¹n kh«ng ®ñ chç trèng ®Ó nhËn ®å!", {{"Quay l¹i", ChooseInbox}})
            return
        end
    end
    
    if mail.ItemID > 0 or (mail.ItemData and mail.ItemData ~= "" and mail.ItemData ~= "0") then 
        if mail.ItemData and mail.ItemData ~= "" and mail.ItemData ~= "0" then
            local tbIndex = MailCreateAttachedItems(mail.ItemData)
            if not tbIndex then
                CreateNewSayEx("T¹o l¹i vËt phÈm thÊt b¹i. Th­ vÉn ®­îc gi÷ l¹i.", {{"Quay l¹i", ChooseInbox}})
                return
            end
            MailAddCreatedItems(tbIndex)
        else
            AddStackItem(mail.ItemCount, mail.ItemG, mail.ItemD, mail.ItemID, mail.ItemL, 0, 0)
        end
    end
    local nGold = tonumber(mail.Gold) or 0
    if nGold > 0 then Earn(nGold) end
    
    mail.isClaimed = 1
    CleanMailbox(charName) 
    MailMarkOutboxClaimed(mail.From, mail.MailID)
    CreateNewSayEx("§· nhËn th­ thµnh c«ng!", {{"Quay l¹i", ChooseInbox}})
end

-- ================= LOGIC OUTBOX (Thu hoi) =================
function ChooseOutbox()
    local charName = GetName()
    MailRefreshUser(charName)
    DisplayOutbox(charName)
end

function DisplayOutbox(charName)
    local list = MailBoxOut[charName] or {}
    local nCount = MailCountOpen(list)
    if nCount == 0 then
        CreateNewSayEx("Ng­¬i ch­a göi bøc th­ nµo hoÆc th­ ®· ®­îc nhËn.", {{"Quay l¹i", OnMailMenu}})
        return
    end
    local opts = {}
    for i = 1, getn(list) do
        if list[i].isClaimed == 0 then
            tinsert(opts, {"[" .. i .. "] §· göi: " .. list[i].To, ReadOutboxMail, {i}})
        end
    end
    tinsert(opts, {"Quay l¹i", OnMailMenu})
    tinsert(opts, {"Tho¸t", OnCancel})
    CreateNewSayEx("Hép th­ ®i (<color=yellow>"..nCount.."<color>)\nNg­êi nhËn gÇn nhÊt: <color=green>"..MailRecentName(list, "To").."<color>", opts)
end

function ReadOutboxMail(index)
    local charName = GetName()
    MailRefreshUser(charName)
    local list = MailBoxOut[charName] or {}
    local mail = list[index]
    if not mail then return end
    local text = "<color=red>Ng­êi nhËn: <color>" .. mail.To .. "\n<color=blue>Tiªu ®Ò: <color>" .. mail.Title .. "\n<color=green>Néi dung:<color>" .. mail.Content.."\n<color=yellow>Ngµy göi: <color>"..MailTimeText(mail)
    text = text .. MailItemPreviewText(mail)
    if mail.Gold > 0 then text = text .. "\n\n<color=yellow>- Vµng: " .. mail.Gold end
    CreateNewSayEx(text, {{"Thu håi th­ nµy", RecallMail, {index}}, {"Quay l¹i", ChooseOutbox}, {"Tho¸t", OnCancel}})
end

function RecallMail(index)
    local charName = GetName()
    MailRefreshUser(charName)
    local listOut = MailBoxOut[charName] or {}
    local mailOut = listOut[index]
    
    if not mailOut or mailOut.isClaimed == 1 then
        CreateNewSayEx("Th­ nµy kh«ng tån t¹i hoÆc ®· bÞ xö lý.", {{"Quay l¹i", ChooseOutbox}})
        return
    end
    
    local receiverName = mailOut.To
    LoadMailbox(receiverName)
    local listIn = MailBox[receiverName] or {}
    local foundIdx = -1
    
    for i = 1, getn(listIn) do
        if listIn[i].MailID == mailOut.MailID and listIn[i].isClaimed == 0 then
            foundIdx = i
            break
        end
    end
    
    if foundIdx == -1 then
        CreateNewSayEx("Ng­êi nhËn ®· lÊy ®å hoÆc th­ kh«ng tån t¹i. Kh«ng thÓ thu håi!", {{"Quay l¹i", ChooseOutbox}})
        mailOut.isClaimed = 1
        CleanOutbox(charName)
        return
    end
    
    if mailOut.ItemID > 0 or (mailOut.ItemData and mailOut.ItemData ~= "" and mailOut.ItemData ~= "0") then
        local nNeedCell = MailItemDataCount(mailOut.ItemData)
        if nNeedCell <= 0 then nNeedCell = 1 end
        if CalcFreeItemCellCount() < nNeedCell then
            CreateNewSayEx("Hµnh trang cña b¹n kh«ng ®ñ chç trèng ®Ó thu håi ®å!", {{"Quay l¹i", ChooseOutbox}})
            return
        end
    end
    
    if mailOut.ItemID > 0 or (mailOut.ItemData and mailOut.ItemData ~= "" and mailOut.ItemData ~= "0") then 
        if mailOut.ItemData and mailOut.ItemData ~= "" and mailOut.ItemData ~= "0" then
            local tbIndex = MailCreateAttachedItems(mailOut.ItemData)
            if not tbIndex then
                CreateNewSayEx("T¹o l¹i vËt phÈm thÊt b¹i. Th­ vÉn ®­îc gi÷ l¹i.", {{"Quay l¹i", ChooseOutbox}})
                return
            end
            MailAddCreatedItems(tbIndex)
        else
		    AddStackItem(mailOut.ItemCount, mailOut.ItemG, mailOut.ItemD, mailOut.ItemID, mailOut.ItemL, 0, 0)
        end
    end
    local nGold = tonumber(mailOut.Gold) or 0
    if nGold > 0 then Earn(nGold) end
    
    listIn[foundIdx].isClaimed = 1
    CleanMailbox(receiverName)
    mailOut.isClaimed = 1
    CleanOutbox(charName)
    
    CreateNewSayEx("Thu håi thµnh c«ng! VËt phÈm ®· ®­îc tr¶ vÒ hµnh trang (Kh«ng hoµn tr¶ phÝ göi 1 V¹n).", {{"Quay l¹i", ChooseOutbox}})
end

-- ================= NHAP LIEU GUI TIEN =================

function ChooseSendGold()
    PlayerData = PlayerData or {}
    PlayerData[PlayerIndex] = PlayerData[PlayerIndex] or {}
    
    local charName = GetName()
    EnsureContactsLoaded(charName)
    local list = MailContacts[charName] or {}
    
    local opts = {{"NhËp tªn míi", InputNewReceiver_Gold}}
    if getn(list) > 0 then
        tinsert(opts, {"Danh B¹", ShowContacts_Gold})
    end
    tinsert(opts, {"Quay l¹i", OnMailMenu})
    tinsert(opts, {"Tho¸t", OnCancel})
    CreateNewSayEx("Chän ng­êi nhËn tiÒn v¹n:", opts)
end

-- Sub-menu hien thi danh sach ten da gui tien
function ShowContacts_Gold()
    local charName = GetName()
    local list = MailContacts[charName] or {}
    local opts = {}
    
    for i = 1, getn(list) do
        tinsert(opts, {list[i], SelectContact_Gold, {i}})
    end
    tinsert(opts, {"Quay l¹i", ChooseSendGold})
    tinsert(opts, {"Tho¸t", OnCancel})
    CreateNewSayEx("Chän tªn tõ danh b¹:", opts)
end

function InputNewReceiver_Gold()
    AskClientForString("InputReceiver_Gold", "", 1, 50, "NhËp tªn ng­êi nhËn:")
end

function InputReceiver_Gold(charName)
    PlayerData[PlayerIndex].ReceiverName = SanitizeText(charName)
    AskClientForString("InputTitle_Gold", "", 1, 50, "Tiªu ®Ò:")
end

function SelectContact_Gold(index)
    local charName = GetName()
    local list = MailContacts[charName] or {}
    if list[index] then
        PlayerData[PlayerIndex].ReceiverName = list[index]
        AskClientForString("InputTitle_Gold", "", 1, 50, "Tiªu ®Ò:")
    else
        CreateNewSayEx("Lçi danh b¹!", {{"Quay l¹i", ChooseSendGold}, {"Tho¸t", OnCancel}})
    end
end

function InputTitle_Gold(t)
    PlayerData[PlayerIndex].MailTitle = t
    AskClientForString("InputContent_Gold", "", 1, 100, "Néi dung:")
end

function InputContent_Gold(c)
    PlayerData[PlayerIndex].MailContent = c
    AskClientForNumber("InputAttachGold_Only", 1, 50000, "Sè tiÒn (V¹n):")
end

function InputAttachGold_Only(g)
    local pd = PlayerData[PlayerIndex]
    local goldAmount = g * 10000  
    local ok, msg = SendMail(GetName(), pd.ReceiverName, pd.MailTitle, pd.MailContent, 0, goldAmount)
    
    -- Kiem tra neu gui thanh cong (ok == 1) thi chuyen sang buoc hoi danh ba
    if ok == 1 then
        CheckAndPromptContact(msg, pd.ReceiverName)
    else
        CreateNewSayEx(msg, {{"Quay l¹i", OnMailMenu}, {"Tho¸t", OnCancel}})
    end
end

-- ================= NHAP LIEU GUI VAT PHAM =================

function ChooseAttachItem()
    GiveItemUI("B­u KiÖn", "Bá mét hoÆc nhiÒu vËt phÈm muèn göi vµo.", "ConfirmAttachItem", "OnMailMenu", 1)
end

function ConfirmAttachItem(nCount)
    if not nCount or nCount <= 0 then
        CreateNewSayEx("B¹n ch­a bá vËt phÈm!", {{"Quay l¹i", OnMailMenu}})
        return
    end

    PlayerData = PlayerData or {}
    PlayerData[PlayerIndex] = PlayerData[PlayerIndex] or {}

    local tbAttach = {}
    local tbData = {}
    local szNameList = ""
    for i = 1, nCount do
        local itemIdx = GetGiveItemUnit(i)
        if itemIdx and itemIdx > 0 then
            local nG, nD, nP, nL = GetItemProp(itemIdx)
            local quantity = GetItemStackCount(itemIdx) or 1
            local itemName = GetItemName(itemIdx) or "VËt PhÈm"
            local tbItemData = MailNewItemData(itemIdx)
            local szItemData = MailSerializeItem(tbItemData)
            if not tbItemData or szItemData == "" then
                CreateNewSayEx("Kh«ng thÓ ®äc d÷ liÖu vËt phÈm: "..itemName, {{"Quay l¹i", OnMailMenu}})
                return
            end
            tinsert(tbAttach, {Index = itemIdx, G = nG, D = nD, P = nP, L = nL, Count = quantity, Name = itemName, Data = szItemData})
            tinsert(tbData, szItemData)
            if szNameList ~= "" then szNameList = szNameList..", " end
            szNameList = szNameList..itemName
        end
    end

    if getn(tbAttach) <= 0 then
        CreateNewSayEx("B¹n ch­a bá vËt phÈm!", {{"Quay l¹i", OnMailMenu}})
        return
    end

    local first = tbAttach[1]
    PlayerData[PlayerIndex].AttachItem = first.P
    PlayerData[PlayerIndex].AttachItemD = first.D
    PlayerData[PlayerIndex].AttachItemG = first.G
    PlayerData[PlayerIndex].AttachItemL = first.L
    PlayerData[PlayerIndex].AttachItemCount = first.Count
    PlayerData[PlayerIndex].AttachItemName = first.Name
    PlayerData[PlayerIndex].AttachItemIndex = first.Index
    PlayerData[PlayerIndex].AttachItemList = tbAttach
    PlayerData[PlayerIndex].AttachItemData = MailSerializeItemList(tbData)

    Msg2Player("HÖ thèng: B¹n ®ang chuÈn bÞ göi <color=yellow>"..getn(tbAttach).."<color> vËt phÈm.")
    ChooseReceiver_Item()
end

function ChooseReceiver_Item()
    local charName = GetName()
    EnsureContactsLoaded(charName)
    local list = MailContacts[charName] or {}
    
    local opts = {{"NhËp tªn míi", InputNewReceiver_Item}}
    if getn(list) > 0 then
        tinsert(opts, {"Danh b¹", ShowContacts_Item})
    end
    tinsert(opts, {"Quay l¹i", OnMailMenu})
    tinsert(opts, {"Tho¸t", OnCancel})
    CreateNewSayEx("Chän ng­êi nhËn vËt phÈm:", opts)
end

-- Sub-menu hien thi danh sach ten da gui do
function ShowContacts_Item()
    local charName = GetName()
    local list = MailContacts[charName] or {}
    local opts = {}
    
    for i = 1, getn(list) do
        tinsert(opts, {list[i], SelectContact_Item, {i}})
    end
    tinsert(opts, {"Quay l¹i", ChooseReceiver_Item})
    tinsert(opts, {"Tho¸t", OnCancel})
    CreateNewSayEx("Chän tªn tõ danh b¹:", opts)
end

function InputNewReceiver_Item()
    AskClientForString("InputReceiverItem", "", 1, 50, "NhËp tªn ng­êi nhËn:")
end

function InputReceiverItem(charName)
    PlayerData[PlayerIndex].ReceiverName = SanitizeText(charName)
    AskClientForString("InputTitleItem", "", 1, 50, "Tiªu ®Ò:")
end

function SelectContact_Item(index)
    local charName = GetName()
    local list = MailContacts[charName] or {}
    if list[index] then
        PlayerData[PlayerIndex].ReceiverName = list[index]
        AskClientForString("InputTitleItem", "", 1, 50, "Tiªu ®Ò:")
    else
        CreateNewSayEx("Lçi danh b¹!", {{"Quay l¹i", ChooseReceiver_Item}})
    end
end

function InputTitleItem(t)
    PlayerData[PlayerIndex].MailTitle = t
    AskClientForString("InputContentItem", "", 1, 100, "Néi dung:")
end

function InputContentItem(c)
    PlayerData[PlayerIndex].MailContent = c
    local pd = PlayerData[PlayerIndex]

    -- Them pd.AttachItemG, pd.AttachItemL vao cuoi
    local ok, msg = SendMail(
        GetName(), pd.ReceiverName, pd.MailTitle, pd.MailContent,
        pd.AttachItem, 0, pd.AttachItemCount, pd.AttachItemName, pd.AttachItemD, pd.AttachItemG, pd.AttachItemL, pd.AttachItemData
    )
    
    if ok == 1 then
        CheckAndPromptContact(msg, pd.ReceiverName)
    else
        CreateNewSayEx(msg, {{"Quay l¹i", OnMailMenu}, {"Tho¸t", OnCancel}})
    end
end

-- Kiem tra xem da co trong danh ba chua, neu chua thi hoi
function CheckAndPromptContact(msg, receiverName)
    local senderName = GetName()
    EnsureContactsLoaded(senderName)
    local list = MailContacts[senderName] or {}
    local found = 0
    
    for i = 1, getn(list) do
        if list[i] == receiverName then
            found = 1
            break
        end
    end
    
    if found == 1 then
        CreateNewSayEx(msg, {{"Quay l¹i", OnMailMenu}, {"Tho¸t", OnCancel}})
    else
        -- Chua co thi luu ten vao bien tam va hoi nguoi choi
        PlayerData = PlayerData or {}
        PlayerData[PlayerIndex] = PlayerData[PlayerIndex] or {}
        PlayerData[PlayerIndex].PendingContact = receiverName
        
        CreateNewSayEx(msg .. "\n\nNg­êi nµy ch­a cã trong danh b¹, b¹n cã muèn l­u l¹i kh«ng?", {
            {"Cã, l­u vµo danh b¹", DoAddContact},
            {"Kh«ng cÇn", OnMailMenu},
            {"Tho¸t", OnCancel}
        })
    end
end

-- Thuc hien luu neu nguoi choi dong y
function DoAddContact()
    local pd = PlayerData[PlayerIndex]
    if pd and pd.PendingContact and pd.PendingContact ~= "" then
        AddContact(GetName(), pd.PendingContact)
        CreateNewSayEx("§· l­u vµo danh b¹!", {{"Quay l¹i", OnMailMenu}, {"Tho¸t", OnCancel}})
    else
        CreateNewSayEx("Lçi l­u danh b¹!", {{"Quay l¹i", OnMailMenu}, {"Tho¸t", OnCancel}})
    end
end

-- \script\global\quochuy\item\hopthu.lua

function CheckMailOnLogin()
    local charName = GetName()
    LoadMailbox(charName) 
    
    if not MailBox or not MailBox[charName] then
        return
    end
    
    local list = MailBox[charName]
    local unreadCount = 0
    
    for i = 1, getn(list) do
        if tonumber(list[i].isClaimed) == 0 then
            unreadCount = unreadCount + 1
        end
    end
    if unreadCount > 0 then
        Talk(1, "", "B¹n ®ang cã <color=yellow>"..unreadCount.."<color> th­ ch­a nhËn!. Thêi gian tån t¹i: <color=red> 30 ngµy<color>")
    end
end

function OnCancel()
end
