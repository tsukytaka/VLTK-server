IncludeLib("ITEM")
IncludeLib("SETTING")
Include("\\script\\dailogsys\\dailogsay.lua")
Include("\\script\\global\\quochuy\\chucnang\\hide_box_item_res_lib.lua")
Include("\\script\\global\\quochuy\\item\\mailbox\\hopthu_lib.lua")

HIDE_BOX_PATH = "data/quochuy/hide_box/"
HIDE_BOX_PAGE_SIZE = 10
HIDE_BOX_MAX_ITEM = 500
HIDE_BOX_FRAGMENT_ITEM_ID = 4946
HIDE_BOX_FILTER_FILE = "script/global/quochuy/chucnang/item_filter.txt"
HIDE_BOX_FILTER_FILE2 = "\\script\\global\\quochuy\\chucnang\\item_filter.txt"
HIDE_BOX_FILTER_FILE3 = "\\item_filter.txt"
HIDE_BOX_AUTO_FILTER_FLAG = 199
HIDE_BOX_AUTO_FILTER_TIMER = 198
HIDE_BOX_AUTO_BREAK_FLAG = 195
HIDE_BOX_AUTO_BREAK_TIMER = 194
HIDE_BOX_FILTER_EDIT_MAGIC = 197
HIDE_BOX_FILTER_EDIT_PAGE = 196
HideBox_Data = HideBox_Data or {}
HideBox_MoneyData = HideBox_MoneyData or {}
HideBox_FilterEditState = HideBox_FilterEditState or {}
HideBox_MailState = HideBox_MailState or {}
HIDE_BOX_GOLD_SET = {
	["V« Danh"] = {141, 142},
	["§éng S¸t"] = {143, 146},
	["§Þnh Quèc"] = {159, 163},
	["An Bang"] = {164, 167},
	["Thiªn Hoµng"] = {168, 176},
	["Kim Phong"] = {177, 185},
	["HiÖp Cèt"] = {186, 189},
	["Nh­ T×nh"] = {190, 193},
	["Kim Quang"] = {194, 203},
	["Hång ¶nh"] = {204, 207},
}

HIDE_BOX_FILTER_DEFAULT = {
	{85, "Sinh lùc", 150, 0},
	{89, "Néi lùc", 150, 0},
	{88, "Phôc håi sinh lùc", 1, 1},
	{92, "Phôc håi néi lùc", 1, 1},
	{97, "Søc m¹nh (§iÓm tiÒm n¨ng)", 20, 0},
	{98, "Th©n ph¸p (§iÓm tiÒm n¨ng)", 20, 0},
	{99, "Sinh khÝ (§iÓm tiÒm n¨ng)", 20, 0},
	{100, "Néi lùc (§iÓm tiÒm n¨ng)", 20, 0},
	{101, "Kh¸ng ®éc", 20, 0},
	{102, "Kh¸ng háa", 20, 0},
	{103, "Kh¸ng l«i", 20, 0},
	{104, "Phßng thñ vËt lý", 20, 0},
	{105, "Kh¸ng b¨ng", 20, 0},
	{106, "Thêi gian lµm chËm", 40, 1},
	{108, "Thêi gian tróng ®éc", 40, 1},
	{110, "Thêi gian cho¸ng", 40, 1},
	{111, "Tèc ®é di chuyÓn", 40, 1},
	{113, "Thêi gian phôc håi", 40, 1},
	{114, "Kh¸ng tÊt c¶", 5, 1},
	{115, "Tèc ®é ®¸nh ngo¹i c«ng", 20, 1},
	{136, "Hót sinh lùc", 1, 1},
	{137, "Hót néi lùc", 1, 1},
	{139, "Kü n¨ng vèn cã", 1, 1},
}

function HideBox_Split(szText, szSep)
	local tb = {}
	local nStart = 1
	local nPos = strfind(szText, szSep, nStart, 1)
	while nPos do
		tinsert(tb, strsub(szText, nStart, nPos - 1))
		nStart = nPos + strlen(szSep)
		nPos = strfind(szText, szSep, nStart, 1)
	end
	tinsert(tb, strsub(szText, nStart))
	return tb
end

function HideBox_StringToHex(szText)
	if not szText then return "" end
	local szHex = ""
	for i = 1, strlen(szText) do
		szHex = szHex..format("%02x", strbyte(strsub(szText, i, i)))
	end
	return szHex
end

function HideBox_HexToString(szHex)
	if not szHex then return "" end
	local szText = ""
	local nLen = strlen(szHex)
	for i = 1, nLen, 2 do
		local nByte = tonumber(strsub(szHex, i, i + 1), 16)
		if nByte then
			szText = szText..strchar(nByte)
		end
	end
	return szText
end

function HideBox_Num(v, nDefault)
	v = tonumber(v)
	if v then return v end
	return nDefault or 0
end

function HideBox_PlayerKey()
	return HideBox_StringToHex(GetAccount().."_"..GetName())
end

function HideBox_FilePath()
	return HIDE_BOX_PATH..HideBox_PlayerKey()..".txt"
end

function HideBox_FilterSavePath()
	return HIDE_BOX_PATH.."filter_"..HideBox_PlayerKey()..".txt"
end

function HideBox_EnsureDir()
	local f = openfile(HIDE_BOX_PATH.."__test.tmp", "a")
	if f then
		closefile(f)
		return 1
	end
	if execute then
		execute("mkdir -p "..HIDE_BOX_PATH)
	end
	f = openfile(HIDE_BOX_PATH.."__test.tmp", "a")
	if f then
		closefile(f)
		return 1
	end
	return 0
end

function HideBox_Pack(...)
	return arg
end

function HideBox_LoadFilterSwitch()
	local tbSwitch = {}
	local f = openfile(HideBox_FilterSavePath(), "r")
	if not f then return tbSwitch end
	local szLine = read(f, "*l")
	szLine = read(f, "*l")
	while szLine do
		local tb = HideBox_Split(szLine, "\t")
		local nMagicId = tonumber(tb[1])
		if nMagicId then
			if tb[4] then
				tbSwitch[nMagicId] = {
					nMinValue = HideBox_Num(tb[2], 0),
					nMaxValue = HideBox_Num(tb[3], 0),
					nOnOff = HideBox_Num(tb[4], 0),
				}
			else
				tbSwitch[nMagicId] = {
					nMinValue = HideBox_Num(tb[2], 0),
					nMaxValue = 0,
					nOnOff = HideBox_Num(tb[3], 0),
				}
			end
		end
		szLine = read(f, "*l")
	end
	closefile(f)
	return tbSwitch
end

function HideBox_SaveFilterSwitch(tbRule)
	if HideBox_EnsureDir() ~= 1 then return 0 end
	local f = openfile(HideBox_FilterSavePath(), "w")
	if not f then return 0 end
	write(f, "MAGIC_ID\tMIN_VALUE\tMAX_VALUE\tON_OFF\n")
	local tbOrder = tbRule.__tbOrder or {}
	for i = 1, getn(tbOrder) do
		local tb = tbOrder[i]
		write(f, tb.nMagicId.."\t"..(tb.nMinValue or 0).."\t"..(tb.nMaxValue or 0).."\t"..(tb.nOnOff or 0).."\n")
	end
	closefile(f)
	return 1
end

function HideBox_AddFilterRule(tbRule, tbOrder, tbSwitch, nMagicId, szText, nMinValue, nOnOff)
	if not nMagicId then return 0 end
	local nMaxValue = 0
	if tbSwitch[nMagicId] then
		nOnOff = tbSwitch[nMagicId].nOnOff
		nMinValue = tbSwitch[nMagicId].nMinValue or nMinValue
		nMaxValue = tbSwitch[nMagicId].nMaxValue or 0
	end
	local tbInfo = {
		nMagicId = nMagicId,
		szText = szText or ("Magic "..nMagicId),
		nMinValue = nMinValue or 0,
		nMaxValue = nMaxValue,
		nOnOff = nOnOff or 0,
	}
	tbRule[nMagicId] = tbInfo
	tinsert(tbOrder, tbInfo)
	return tbInfo.nOnOff
end

function HideBox_LoadFilterRules()
	local tbRule = {}
	local tbOrder = {}
	local tbSwitch = HideBox_LoadFilterSwitch()
	local f = openfile(HIDE_BOX_FILTER_FILE, "r")
	if not f then f = openfile(HIDE_BOX_FILTER_FILE2, "r") end
	if not f then f = openfile(HIDE_BOX_FILTER_FILE3, "r") end
	local nActive = 0
	if not f then
		for i = 1, getn(HIDE_BOX_FILTER_DEFAULT) do
			local tb = HIDE_BOX_FILTER_DEFAULT[i]
			local nOnOff = HideBox_AddFilterRule(tbRule, tbOrder, tbSwitch, tb[1], tb[2], tb[3], tb[4])
			if nOnOff == 1 then nActive = nActive + 1 end
		end
		tbRule.__tbOrder = tbOrder
		tbRule.__nActive = nActive
		return tbRule
	end
	local szLine = read(f, "*l")
	szLine = read(f, "*l")
	while szLine do
		local tb = HideBox_Split(szLine, "\t")
		local nMagicId = tonumber(tb[1])
		if nMagicId then
			local nOnOff = HideBox_AddFilterRule(tbRule, tbOrder, tbSwitch, nMagicId, tb[2], HideBox_Num(tb[3], 0), HideBox_Num(tb[4], 0))
			if nOnOff == 1 then nActive = nActive + 1 end
		end
		szLine = read(f, "*l")
	end
	closefile(f)
	tbRule.__tbOrder = tbOrder
	tbRule.__nActive = nActive
	return tbRule
end

function HideBox_FilterCanProcess(nItemIndex)
	local nG = GetItemProp(nItemIndex)
	local nBindState = GetItemBindState(nItemIndex)
	local nQuality = GetItemQuality(nItemIndex)
	if nBindState == -2 then return 0 end
	if nQuality == 1 or nQuality == 2 or nQuality == 4 then return 0 end
	if nG == 6 or nG == 4 then return 0 end
	return 1
end

function HideBox_CanDismantleBlueItem(nItemIndex)
	if not nItemIndex or nItemIndex <= 0 then return 0 end
	local nG = GetItemProp(nItemIndex)
	local nQuality = GetItemQuality(nItemIndex)
	local nExpiredTime = ITEM_GetExpiredTime(nItemIndex) or 0
	if nG == 0 and nQuality == 0 and nExpiredTime == 0 then
		return 1
	end
	return 0
end

function HideBox_FilterIsGood(nItemIndex, tbRule)
	if not tbRule then return 0 end
	for i = 1, 6 do
		local nMagicId, nMagicValue = GetItemMagicAttrib(nItemIndex, i)
		local tb = tbRule[nMagicId]
		nMagicValue = nMagicValue or 0
		if tb and tb.nOnOff == 1 and tb.nMinValue <= nMagicValue and ((tb.nMaxValue or 0) <= 0 or nMagicValue <= tb.nMaxValue) then
			return 1
		end
	end
	return 0
end

function HideBox_FilterRangeText(tb)
	if not tb then return "" end
	if tb.nMaxValue and tb.nMaxValue > 0 then
		return tb.nMinValue.." - "..tb.nMaxValue
	end
	return ">= "..tb.nMinValue
end

function HideBox_FilterActiveText(tbRule)
	if not tbRule then return "" end
	local tbOrder = tbRule.__tbOrder or {}
	local szText = ""
	local nCount = 0
	for i = 1, getn(tbOrder) do
		local tb = tbOrder[i]
		if tb.nOnOff == 1 then
			nCount = nCount + 1
			szText = szText.."\n<color=green>"..tb.szText.."<color>: <color=yellow>"..HideBox_FilterRangeText(tb).."<color>"
		end
	end
	if nCount <= 0 then return "\nCh­a bËt thuéc tÝnh nµo." end
	return "\nThuéc tÝnh ®ang bËt: <color=yellow>"..nCount.."<color>"..szText
end

function HideBox_AutoFilterStatusText()
	local szSell = "<color=red>[T¾T]<color>"
	local szBreak = "<color=red>[T¾T]<color>"
	if GetTaskTemp(HIDE_BOX_AUTO_FILTER_FLAG) == 1 then
		szSell = "<color=blue>[BËT]<color>"
	end
	if GetTaskTemp(HIDE_BOX_AUTO_BREAK_FLAG) == 1 then
		szBreak = "<color=blue>[BËT]<color>"
	end
	return "\nTù ®éng läc vµ b¸n: "..szSell.."\nTù ®éng läc vµ t¸ch: "..szBreak
end

function HideBox_NormalizeAutoMode(nKeepMode)
	if GetTaskTemp(HIDE_BOX_AUTO_FILTER_FLAG) == 1 and GetTaskTemp(HIDE_BOX_AUTO_BREAK_FLAG) == 1 then
		if nKeepMode == 1 then
			HideBox_AutoBreak_OFF(1)
		else
			HideBox_AutoFilter_OFF(1)
		end
	end
end

function HideBox_ReadMagicList(nItemIndex)
	local tbMagic = {}
	for i = 1, 6 do
		tbMagic[i] = HideBox_Pack(GetItemMagicAttrib(nItemIndex, i))
	end
	return tbMagic
end

function HideBox_MagicDesc(tbMagic)
	if not tbMagic or not tbMagic[1] or tbMagic[1] <= 0 then return "" end
	if GetItemMagicDesc then
		local szDesc = GetItemMagicDesc(tbMagic[1], tbMagic[2] or 0, tbMagic[3] or 0, tbMagic[4] or 0)
		if szDesc and szDesc ~= "" then return szDesc end
	end
	return "Magic "..(tbMagic[1] or 0)..": "..(tbMagic[2] or 0)..","..(tbMagic[3] or 0)..","..(tbMagic[4] or 0)
end

function HideBox_ItemColor(tb)
	if tb.nQuality == 1 then return "yellow" end
	if tb.nQuality == 2 then return "pink" end
	if tb.nQuality == 4 then return "gold" end
	if HideBox_ItemCategory(tb) == "equip" then return "blue" end
	return "blue"
end

function HideBox_ItemNameText(tb)
	return tb.szName or ""
end

function HideBox_CleanResPath(szSpr)
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

function HideBox_ItemImagePath(tb)
	if not HIDE_BOX_ITEM_RES_DATA then return "" end
	if tb.nQuality == 1 then
		return HideBox_CleanResPath(HIDE_BOX_ITEM_RES_DATA.gold[HideBox_GoldId(tb)])
	end
	if tb.nQuality == 4 then
		return HideBox_CleanResPath(HIDE_BOX_ITEM_RES_DATA.platina[(tb.tbProp and tb.tbProp[2]) or 0])
	end
	if tb.tbProp then
		local szKey = (tb.tbProp[2] or 0).."_"..(tb.tbProp[3] or 0).."_"..(tb.tbProp[4] or 0)
		return HideBox_CleanResPath(HIDE_BOX_ITEM_RES_DATA.normal[szKey])
	end
	return ""
end

function HideBox_ItemImageTag(tb)
	local szPath = HideBox_ItemImagePath(tb)
	if szPath == "" then return "" end
	return "<link=image:"..szPath.."><link><color>\n"
end

function HideBox_MagicLineText(tb, nLine, bShow)
	local szDesc = HideBox_MagicDesc(tb.tbMagic[nLine])
	if szDesc == "" then return "" end
	if bShow == 1 then
		return "<color="..HideBox_ItemColor(tb)..">"..szDesc.."<color>"
	end
	return "<color=0x808080>"..szDesc.."<color>"
end

function HideBox_ItemMagicText(tb, nLimit, szSep)
	if not tb or not tb.tbMagic then return "" end
	local szText = ""
	local nCount = 0
	szSep = szSep or "\n"
	for i = 1, 6 do
		local bShow = 0
		if mod(nCount, 2) == 0 then bShow = 1 end
		local szDesc = HideBox_MagicLineText(tb, i, bShow)
		if szDesc ~= "" then
			if szText ~= "" then szText = szText..szSep end
			szText = szText..szDesc
			nCount = nCount + 1
			if nLimit and nLimit > 0 and nCount >= nLimit then
				return szText
			end
		end
	end
	return szText
end

function HideBox_ItemFrameText(tb)
	return HideBox_ItemImageTag(tb)..HideBox_ItemNameText(tb)
end

function HideBox_PageMagicText(tbIndex, nStart, nEnd)
	local tbList = HideBox_GetList()
	local szText = ""
	for i = nStart, nEnd do
		local tb = tbList[tbIndex[i]]
		local szMagic = HideBox_ItemMagicText(tb, 6, "\n   ")
		if szMagic ~= "" then
			if szText ~= "" then szText = szText.."\n" end
			szText = szText..i..". "..HideBox_ItemNameText(tb).."\n   "..szMagic.."\n"
		end
	end
	return szText
end

function HideBox_GroupKey(tb)
	return HideBox_ItemCategory(tb).."|"..(tb.szName or "")
end

function HideBox_BuildGroups(tbIndex)
	local tbList = HideBox_GetList()
	local tbGroup = {}
	local tbMap = {}
	for i = 1, getn(tbIndex) do
		local nRealIndex = tbIndex[i]
		local tb = tbList[nRealIndex]
		local szKey = HideBox_GroupKey(tb)
		local nGroup = tbMap[szKey]
		if not nGroup then
			tinsert(tbGroup, {szKey = szKey, szName = tb.szName, tbIndex = {}, nAmount = 0, nFirstIndex = nRealIndex})
			nGroup = getn(tbGroup)
			tbMap[szKey] = nGroup
		end
		tinsert(tbGroup[nGroup].tbIndex, nRealIndex)
		tbGroup[nGroup].nAmount = tbGroup[nGroup].nAmount + (tb.nCount or 1)
	end
	return tbGroup
end

function HideBox_GroupText(tbGroup)
	local tbList = HideBox_GetList()
	local tb = tbList[tbGroup.nFirstIndex]
	return HideBox_ItemNameText(tb).." ("..(tbGroup.nAmount or getn(tbGroup.tbIndex))..")"
end

function HideBox_GetIndexByBack(szBack, szArg)
	if szBack == "goldset" then
		return HideBox_CollectGoldSet(szArg)
	end
	return HideBox_CollectCategory(szArg or "all")
end

function HideBox_ShowGroupByKey(szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage)
	local tbIndex = HideBox_GetIndexByBack(szBack, szArg)
	local tbGroups = HideBox_BuildGroups(tbIndex)
	local tbGroup = nil
	for i = 1, getn(tbGroups) do
		if tbGroups[i].szKey == szGroupKey then
			tbGroup = tbGroups[i]
			break
		end
	end
	if not tbGroup then
		HideBox_ShowIndexPage(szTitle, tbIndex, nGroupPage or 1, szBack, szArg)
		return
	end
	local nTotal = getn(tbGroup.tbIndex)
	nPage = tonumber(nPage) or 1
	local nMaxPage = floor((nTotal - 1) / HIDE_BOX_PAGE_SIZE) + 1
	if nPage < 1 then nPage = 1 end
	if nPage > nMaxPage then nPage = nMaxPage end
	local nStart = (nPage - 1) * HIDE_BOX_PAGE_SIZE + 1
	local nEnd = nStart + HIDE_BOX_PAGE_SIZE - 1
	if nEnd > nTotal then nEnd = nTotal end
	local tbList = HideBox_GetList()
	local tbOpt = {}
	local tbBackArg = {szTitle, szGroupKey, szBack, szArg, nGroupPage or 1}
	tinsert(tbOpt, {"Rót tÊt c¶", HideBox_ConfirmWithdrawGroup, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1}})
	tinsert(tbOpt, {"B¸n tÊt c¶", HideBox_ConfirmSellGroup, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1}})
	tinsert(tbOpt, {"Göi tÊt c¶", HideBox_ConfirmMailGroup, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1}})
	for i = nStart, nEnd do
		local nRealIndex = tbGroup.tbIndex[i]
		local tb = tbList[nRealIndex]
		tinsert(tbOpt, {i..". "..HideBox_ItemNameText(tb), HideBox_ItemDetail, {nRealIndex, nPage, "group", tbBackArg}})
	end
	if nPage > 1 then
		tinsert(tbOpt, {"<<< Trang tr­íc", HideBox_ShowGroupByKey, {szTitle, szGroupKey, nPage - 1, szBack, szArg, nGroupPage or 1}})
	end
	if nPage < nMaxPage then
		tinsert(tbOpt, {"Trang sau >>>", HideBox_ShowGroupByKey, {szTitle, szGroupKey, nPage + 1, szBack, szArg, nGroupPage or 1}})
	end
	tinsert(tbOpt, {"<Trë l¹i>", HideBox_ShowIndexPage, {szTitle, tbIndex, nGroupPage or 1, szBack, szArg}})
	tinsert(tbOpt, {"Tho¸t", HideBox_Exit})
	local szMagicInfo = HideBox_PageMagicText(tbGroup.tbIndex, nStart, nEnd)
	if szMagicInfo ~= "" then
		szMagicInfo = "\n<color=green>Thuéc tÝnh tõng mßn:<color>\n"..szMagicInfo
	end
	CreateNewSayEx(HideBox_GroupText(tbGroup).." | Trang <color=yellow>"..nPage.."/"..nMaxPage.."<color>"..szMagicInfo, tbOpt)
end

function HideBox_GoldId(tb)
	if tb.nGoldId and tb.nGoldId > 0 then return tb.nGoldId end
	if tb.nQuality == 1 and tb.tbProp and tb.tbProp[2] and tb.tbProp[2] > 0 then
		return tb.tbProp[2]
	end
	return 0
end

function HideBox_GoldSetNameById(nGoldId)
	nGoldId = tonumber(nGoldId) or 0
	for szName, tbRange in HIDE_BOX_GOLD_SET do
		if nGoldId >= tbRange[1] and nGoldId <= tbRange[2] then
			return szName
		end
	end
	return "Kh¸c"
end

function HideBox_ItemCategory(tb)
	if tb.nQuality == 1 then return "gold" end
	if tb.nQuality == 2 then return "purple" end
	if tb.nQuality == 4 then return "platina" end
	if tb.tbProp and tb.tbProp[1] == 0 then return "equip" end
	return "item"
end

function HideBox_CollectCategory(szCategory)
	local tbList = HideBox_GetList()
	local tbIndex = {}
	for i = 1, getn(tbList) do
		if szCategory == "all" or HideBox_ItemCategory(tbList[i]) == szCategory then
			tinsert(tbIndex, i)
		end
	end
	return tbIndex
end

function HideBox_CollectGoldSet(szSetName)
	local tbList = HideBox_GetList()
	local tbIndex = {}
	for i = 1, getn(tbList) do
		local tb = tbList[i]
		if tb.nQuality == 1 and HideBox_GoldSetNameById(HideBox_GoldId(tb)) == szSetName then
			tinsert(tbIndex, i)
		end
	end
	return tbIndex
end

function HideBox_NewFromItem(nItemIndex)
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
	tb.tbMagic = HideBox_ReadMagicList(nItemIndex)
	tb.nGoldId = 0
	tb.szGoldSet = ""
	
	if tb.nQuality == 1 then
		tb.nGoldId = GetGlodEqIndex(nItemIndex) or 0
		tb.szGoldSet = HideBox_GoldSetNameById(tb.nGoldId)
		tb.tbProp = {0, tb.nGoldId, 0, 0, 0, 0}
	elseif tb.nQuality == 4 then
		tb.tbProp = {0, GetPlatinaEquipIndex(nItemIndex) or 0, 0, 0, 0, 0}
	else
		tb.tbProp = HideBox_Pack(GetItemProp(nItemIndex))
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

function HideBox_Serialize(tb)
	local tbLine = {}
	tinsert(tbLine, "1")
	tinsert(tbLine, HideBox_StringToHex(tb.szName or ""))
	tinsert(tbLine, tb.nVersion or 4)
	tinsert(tbLine, tb.nRandSeed or 0)
	tinsert(tbLine, tb.nQuality or 0)
	tinsert(tbLine, tb.nBindState or 0)
	tinsert(tbLine, tb.nCount or 1)
	tinsert(tbLine, tb.nStackable or 0)
	tinsert(tbLine, tb.nCurDurability or 0)
	tinsert(tbLine, tb.nMaxDurability or 0)
	tinsert(tbLine, tb.nExpiredTime or 0)
	tinsert(tbLine, tb.nLeftUsageTime or 0)
	tinsert(tbLine, tb.nUpgradeLevel or 0)
	for i = 1, 6 do
		tinsert(tbLine, (tb.tbProp and tb.tbProp[i]) or 0)
	end
	for i = 1, 6 do
		tinsert(tbLine, (tb.tbParam and tb.tbParam[i]) or 0)
	end
	tinsert(tbLine, HideBox_GoldId(tb))
	tinsert(tbLine, HideBox_StringToHex(tb.szGoldSet or ""))
	for i = 1, 6 do
		for j = 1, 4 do
			tinsert(tbLine, (tb.tbMagic and tb.tbMagic[i] and tb.tbMagic[i][j]) or 0)
		end
	end
	return HideBox_Join(tbLine, "|")
end

function HideBox_Join(tb, szSep)
	local sz = ""
	for i = 1, getn(tb) do
		if i > 1 then sz = sz..szSep end
		sz = sz..tostring(tb[i])
	end
	return sz
end

function HideBox_Unserialize(szLine)
	local p = HideBox_Split(szLine, "|")
	if getn(p) < 25 then return nil end
	local tb = {}
	tb.szName = HideBox_HexToString(p[2])
	tb.nVersion = HideBox_Num(p[3], 4)
	tb.nRandSeed = HideBox_Num(p[4], 0)
	tb.nQuality = HideBox_Num(p[5], 0)
	tb.nBindState = HideBox_Num(p[6], 0)
	tb.nCount = HideBox_Num(p[7], 1)
	tb.nStackable = HideBox_Num(p[8], 0)
	tb.nCurDurability = HideBox_Num(p[9], 0)
	tb.nMaxDurability = HideBox_Num(p[10], 0)
	tb.nExpiredTime = HideBox_Num(p[11], 0)
	tb.nLeftUsageTime = HideBox_Num(p[12], 0)
	tb.nUpgradeLevel = HideBox_Num(p[13], 0)
	tb.tbProp = {}
	tb.tbParam = {}
	for i = 1, 6 do
		tb.tbProp[i] = HideBox_Num(p[13 + i], 0)
	end
	for i = 1, 6 do
		tb.tbParam[i] = HideBox_Num(p[19 + i], 0)
	end
	tb.nGoldId = HideBox_Num(p[26], 0)
	if tb.nGoldId <= 0 then tb.nGoldId = HideBox_GoldId(tb) end
	tb.szGoldSet = HideBox_HexToString(p[27] or "")
	if tb.nQuality == 1 and tb.szGoldSet == "" then
		tb.szGoldSet = HideBox_GoldSetNameById(tb.nGoldId)
	end
	tb.tbMagic = {}
	local nPos = 28
	for i = 1, 6 do
		tb.tbMagic[i] = {}
		for j = 1, 4 do
			tb.tbMagic[i][j] = HideBox_Num(p[nPos], 0)
			nPos = nPos + 1
		end
	end
	return tb
end

function HideBox_Load()
	local szKey = HideBox_PlayerKey()
	HideBox_Data[szKey] = {}
	HideBox_MoneyData[szKey] = 0
	local f = openfile(HideBox_FilePath(), "r")
	if not f then return HideBox_Data[szKey] end
	local szLine = read(f, "*l")
	while szLine do
		szLine = gsub(szLine, "\r", "")
		if szLine ~= "" then
			local tbMoney = HideBox_Split(szLine, "\t")
			if tbMoney[1] == "MONEY" then
				HideBox_MoneyData[szKey] = HideBox_Num(tbMoney[2], 0)
			else
				local tb = HideBox_Unserialize(szLine)
				if tb then tinsert(HideBox_Data[szKey], tb) end
			end
		end
		szLine = read(f, "*l")
	end
	closefile(f)
	return HideBox_Data[szKey]
end

function HideBox_GetList()
	local szKey = HideBox_PlayerKey()
	if not HideBox_Data[szKey] then
		return HideBox_Load()
	end
	return HideBox_Data[szKey]
end

function HideBox_GetMoney()
	local szKey = HideBox_PlayerKey()
	if not HideBox_MoneyData[szKey] then
		HideBox_Load()
	end
	return HideBox_Num(HideBox_MoneyData[szKey], 0)
end

function HideBox_SetMoney(nMoney)
	local szKey = HideBox_PlayerKey()
	HideBox_MoneyData[szKey] = HideBox_Num(nMoney, 0)
	if HideBox_MoneyData[szKey] < 0 then
		HideBox_MoneyData[szKey] = 0
	end
	return HideBox_MoneyData[szKey]
end

function HideBox_Save()
	if HideBox_EnsureDir() ~= 1 then
		Say("Kh«ng thÓ t¹o th­ môc l­u Hép CÊt GiÊu. H·y kiÓm tra th­ môc data/quochuy/hide_box.", 0)
		return 0
	end
	local f = openfile(HideBox_FilePath(), "w")
	if not f then
		Say("Kh«ng thÓ ghi d÷ liÖu Hép CÊt GiÊu.", 0)
		return 0
	end
	local tbList = HideBox_GetList()
	write(f, "MONEY\t"..HideBox_GetMoney().."\n")
	for i = 1, getn(tbList) do
		write(f, HideBox_Serialize(tbList[i]).."\n")
	end
	closefile(f)
	return 1
end

function HideBox_CreateItem(tb)
	local nItemIndex = 0
	local nRow = 0
	if tb.nQuality == 1 or tb.nQuality == 4 then
		nRow = 1
	end
	if tb.nQuality == 1 then
		tb.tbProp = tb.tbProp or {}
		tb.tbProp[1] = 0
		tb.tbProp[2] = HideBox_GoldId(tb)
	end
	nItemIndex = NewItemEx(
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
	return HideBox_ApplyItemState(nItemIndex, tb), 0
end

function HideBox_AddStoredItemToPlayer(tb)
	if not tb then return 0, 0 end
	if tb.nQuality == 1 or tb.nQuality == 4 then
		local nItemIndex = HideBox_CreateItem(tb)
		if not nItemIndex or nItemIndex <= 0 then return 0, 0 end
		AddItemByIndex(nItemIndex)
		return nItemIndex, 1
	end
	local tbProp = tb.tbProp or {}
	local tbParam = tb.tbParam or {}
	local nItemIndex = AddItemEx(
		tb.nVersion or 4,
		tonumber(format("%u", tb.nRandSeed or 0)),
		tb.nQuality or 0,
		tbProp[1] or 0,
		tbProp[2] or 0,
		tbProp[3] or 0,
		tbProp[4] or 0,
		tbProp[5] or 0,
		tbProp[6] or 0,
		tbParam[1] or 0,
		tbParam[2] or 0,
		tbParam[3] or 0,
		tbParam[4] or 0,
		tbParam[5] or 0,
		tbParam[6] or 0,
		tb.nCount or 1
	)
	if not nItemIndex or nItemIndex <= 0 then return 0, 0 end
	HideBox_ApplyItemState(nItemIndex, tb)
	return nItemIndex, 1
end

function HideBox_GetStoredItemSellPrice(tb)
	local nItemIndex = HideBox_CreateItem(tb)
	if not nItemIndex or nItemIndex <= 0 then return 0 end
	local nPrice = floor((GetItemPrice(nItemIndex) or 0) / 4)
	RemoveItemByIndex(nItemIndex)
	return nPrice
end

function HideBox_ApplyItemState(nItemIndex, tb)
	if IsItemStackable(nItemIndex) == 1 then
		SetItemStackCount(nItemIndex, tb.nCount or 1)
	else
		if tb.nCurDurability and tb.nCurDurability > 0 then
			SetCurDurability(nItemIndex, tb.nCurDurability)
		end
		if tb.nMaxDurability and tb.nMaxDurability > 0 then
			SetMaxDurability(nItemIndex, tb.nMaxDurability)
		end
	end
	if tb.nExpiredTime and tb.nExpiredTime > 0 then
		ITEM_SetExpiredTime(nItemIndex, tb.nExpiredTime)
	end
	if tb.nLeftUsageTime and tb.nLeftUsageTime > 0 then
		ITEM_SetLeftUsageTime(nItemIndex, tb.nLeftUsageTime)
	end
	if tb.nBindState and tb.nBindState ~= 0 then
		SetItemBindState(nItemIndex, tb.nBindState)
	end
	return nItemIndex
end

function HideBox_ItemTypeName(tb)
	if tb.nQuality == 1 then return "Hoµng Kim" end
	if tb.nQuality == 2 then return "Trang bÞ TÝm" end
	if tb.nQuality == 4 then return "B¹ch Kim" end
	if tb.tbProp and tb.tbProp[1] == 0 then return "Trang bÞ" end
	return "VËt phÈm"
end

function HideBox_MenuText()
	local tbList = HideBox_GetList()
	local nCount = getn(tbList)
	return "<color=cyan>R­¬ng Tïy Th©n<color>\nSè vËt phÈm ®ang cÊt: <color=yellow>"..nCount.."/"..HIDE_BOX_MAX_ITEM.."<color>\nTiÒn ®ang cÊt: <color=yellow>"..HideBox_GetMoney().."<color> ng©n l­îng\nCã thÓ cÊt trang bÞ tr¾ng/xanh/tÝm, B¹ch Kim, Hoµng Kim.\nVËt phÈm quý vµ vËt phÈm th­êng."
end

function main()
	HideBox_Main()
end

function HideBox_OpenOnMap()
	HideBox_Main()
end

function HideBox_Main()
	HideBox_Load()
	local tbOpt = {
		{"1. VËt phÈm", HideBox_ShowCategory, {"item", 1}},
		{"2. Trang bÞ th­êng", HideBox_ShowCategory, {"equip", 1}},
		{"3. Trang bÞ TÝm", HideBox_ShowCategory, {"purple", 1}},
		{"4. Trang bÞ Hoµng Kim", HideBox_ShowGoldMenu},
		{"5. Trang bÞ B¹ch Kim", HideBox_ShowCategory, {"platina", 1}},
		{"6. TÊt c¶ vËt phÈm", HideBox_ShowCategory, {"all", 1}},
		{"7. CÊt vËt phÈm", HideBox_DepositMenu},
		{"8. CÊt vµ rót tiÒn", HideBox_MoneyMenu},
		{"9. Läc ®å", HideBox_FilterMenu},
		{"10. T¶i l¹i d÷ liÖu", HideBox_Reload},
		{"Tho¸t", HideBox_Exit}
	}
	CreateNewSayEx(HideBox_MenuText(), tbOpt)
end

function HideBox_MoneyMenu()
	HideBox_Load()
	local nBoxMoney = HideBox_GetMoney()
	local nCash = 0
	if GetCash then nCash = GetCash() or 0 end
	local szTitle = "<color=cyan>CÊt/rót tiÒn trong R­¬ng Tïy Th©n<color>\nTiÒn trªn ng­êi: <color=yellow>"..nCash.."<color> ng©n l­îng\nTiÒn trong r­¬ng: <color=yellow>"..nBoxMoney.."<color> ng©n l­îng"
	local tbOpt = {
		{"CÊt tiÒn vµo r­¬ng", HideBox_AskDepositMoney},
		{"Rót tiÒn tõ r­¬ng", HideBox_AskWithdrawMoney},
		{"Rót tÊt c¶ tiÒn", HideBox_WithdrawAllMoney},
		{"<Trë l¹i>", HideBox_Main},
		{"Tho¸t", HideBox_Exit},
	}
	CreateNewSayEx(szTitle, tbOpt)
end

function HideBox_AskDepositMoney()
	local nCash = 0
	if GetCash then nCash = GetCash() or 0 end
	if nCash <= 0 then
		Msg2Player("<color=red>Trªn ng­êi kh«ng cã ng©n l­îng ®Ó cÊt.<color>")
		HideBox_MoneyMenu()
		return
	end
	AskClientForNumber("HideBox_DepositMoney", 1, nCash, "NhËp sè ng©n l­îng muèn cÊt:")
end

function HideBox_DepositMoney(nMoney)
	nMoney = HideBox_Num(nMoney, 0)
	if nMoney <= 0 then HideBox_MoneyMenu() return end
	if GetCash and GetCash() < nMoney then
		Msg2Player("<color=red>Kh«ng ®ñ ng©n l­îng trªn ng­êi.<color>")
		HideBox_MoneyMenu()
		return
	end
	if Pay then Pay(nMoney)
	elseif Earn then Earn(-nMoney) end
	HideBox_SetMoney(HideBox_GetMoney() + nMoney)
	if HideBox_Save() ~= 1 then
		HideBox_SetMoney(HideBox_GetMoney() - nMoney)
		if Earn then Earn(nMoney) end
		Msg2Player("<color=red>Ghi d÷ liÖu r­¬ng thÊt b¹i, ®· tr¶ l¹i tiÒn.<color>")
		HideBox_MoneyMenu()
		return
	end
	HideBox_Log("DEPOSIT_MONEY", nMoney)
	Msg2Player("§· cÊt <color=yellow>"..nMoney.."<color> ng©n l­îng vµo r­¬ng.")
	HideBox_MoneyMenu()
end

function HideBox_AskWithdrawMoney()
	local nBoxMoney = HideBox_GetMoney()
	if nBoxMoney <= 0 then
		Msg2Player("<color=red>Trong r­¬ng kh«ng cã ng©n l­îng.<color>")
		HideBox_MoneyMenu()
		return
	end
	AskClientForNumber("HideBox_WithdrawMoney", 1, nBoxMoney, "NhËp sè ng©n l­îng muèn rót:")
end

function HideBox_WithdrawMoney(nMoney)
	nMoney = HideBox_Num(nMoney, 0)
	local nBoxMoney = HideBox_GetMoney()
	if nMoney <= 0 then HideBox_MoneyMenu() return end
	if nMoney > nBoxMoney then nMoney = nBoxMoney end
	HideBox_SetMoney(nBoxMoney - nMoney)
	if HideBox_Save() ~= 1 then
		HideBox_SetMoney(nBoxMoney)
		Msg2Player("<color=red>Ghi d÷ liÖu r­¬ng thÊt b¹i, kh«ng rót tiÒn.<color>")
		HideBox_MoneyMenu()
		return
	end
	if Earn then Earn(nMoney) end
	HideBox_Log("WITHDRAW_MONEY", nMoney)
	Msg2Player("§· rót <color=yellow>"..nMoney.."<color> ng©n l­îng tõ r­¬ng.")
	HideBox_MoneyMenu()
end

function HideBox_WithdrawAllMoney()
	HideBox_WithdrawMoney(HideBox_GetMoney())
end

function HideBox_CategoryTitle(szCategory)
	if szCategory == "item" then return "VËt phÈm" end
	if szCategory == "equip" then return "Trang bÞ th­êng" end
	if szCategory == "purple" then return "Trang bÞ TÝm" end
	if szCategory == "gold" then return "Trang bÞ Hoµng Kim" end
	if szCategory == "platina" then return "Trang bÞ B¹ch Kim" end
	return "TÊt c¶ vËt phÈm"
end

function HideBox_ShowCategory(szCategory, nPage)
	local tbIndex = HideBox_CollectCategory(szCategory)
	HideBox_ShowIndexPage(HideBox_CategoryTitle(szCategory), tbIndex, nPage, "category", szCategory)
end

function HideBox_ShowGoldMenu()
	local tbList = HideBox_GetList()
	local tbOpt = {}
	for szSetName, tbRange in HIDE_BOX_GOLD_SET do
		local nCount = 0
		for i = 1, getn(tbList) do
			local tb = tbList[i]
			local nGoldId = HideBox_GoldId(tb)
			if tb.nQuality == 1 and nGoldId >= tbRange[1] and nGoldId <= tbRange[2] then
				nCount = nCount + 1
			end
		end
		if nCount > 0 then
			tinsert(tbOpt, {szSetName.." ("..nCount..")", HideBox_ShowGoldSet, {szSetName, 1}})
		end
	end
	local tbOther = HideBox_CollectGoldSet("Kh¸c")
	if getn(tbOther) > 0 then
		tinsert(tbOpt, {"Kh¸c ("..getn(tbOther)..")", HideBox_ShowGoldSet, {"Kh¸c", 1}})
	end
	if getn(tbOpt) <= 0 then
		CreateNewSayEx("Ch­a cã trang bÞ Hoµng Kim nµo trong hép.", {{"Trë l¹i", HideBox_Main}, {"Tho¸t", HideBox_Exit}})
		return
	end
	tinsert(tbOpt, {"<Trë l¹i>", HideBox_Main})
	tinsert(tbOpt, {"Tho¸t", HideBox_Exit})
	CreateNewSayEx("Trang bÞ Hoµng Kim\nChØ hiÖn nh÷ng bé ®ang cã trong hép.", tbOpt)
end

function HideBox_ShowGoldSet(szSetName, nPage)
	local tbIndex = HideBox_CollectGoldSet(szSetName)
	HideBox_ShowIndexPage("Hoµng Kim - "..szSetName, tbIndex, nPage, "goldset", szSetName)
end

function HideBox_ShowIndexPage(szTitle, tbIndex, nPage, szBack, szArg)
	local nTotalItem = getn(tbIndex)
	if nTotalItem <= 0 then
		CreateNewSayEx(szTitle.."\nKh«ng cã vËt phÈm.", {{"Trë l¹i", HideBox_Main}, {"Tho¸t", HideBox_Exit}})
		return
	end
	local tbGroups = HideBox_BuildGroups(tbIndex)
	local nTotal = getn(tbGroups)
	nPage = tonumber(nPage) or 1
	local nMaxPage = floor((nTotal - 1) / HIDE_BOX_PAGE_SIZE) + 1
	if nPage < 1 then nPage = 1 end
	if nPage > nMaxPage then nPage = nMaxPage end
	local nStart = (nPage - 1) * HIDE_BOX_PAGE_SIZE + 1
	local nEnd = nStart + HIDE_BOX_PAGE_SIZE - 1
	if nEnd > nTotal then nEnd = nTotal end
	local tbOpt = {}
	tinsert(tbOpt, {"Rót tÊt c¶", HideBox_ConfirmWithdrawAll, {szTitle, szBack, szArg, nPage}})
	tinsert(tbOpt, {"B¸n tÊt c¶", HideBox_ConfirmSellAll, {szTitle, szBack, szArg, nPage}})
	tinsert(tbOpt, {"Göi tÊt c¶", HideBox_ConfirmMailAll, {szTitle, szBack, szArg, nPage}})
	for i = nStart, nEnd do
		local tbGroup = tbGroups[i]
		if getn(tbGroup.tbIndex) > 1 then
			tinsert(tbOpt, {i..". "..HideBox_GroupText(tbGroup), HideBox_ShowGroupByKey, {szTitle, tbGroup.szKey, 1, szBack, szArg, nPage}})
		else
			tinsert(tbOpt, {i..". "..HideBox_GroupText(tbGroup), HideBox_ItemDetail, {tbGroup.nFirstIndex, nPage, szBack, szArg}})
		end
	end
	if nPage > 1 then
		if szBack == "goldset" then
			tinsert(tbOpt, {"<<< Trang tr­íc", HideBox_ShowGoldSet, {szArg, nPage - 1}})
		else
			tinsert(tbOpt, {"<<< Trang tr­íc", HideBox_ShowCategory, {szArg, nPage - 1}})
		end
	end
	if nPage < nMaxPage then
		if szBack == "goldset" then
			tinsert(tbOpt, {"Trang sau >>>", HideBox_ShowGoldSet, {szArg, nPage + 1}})
		else
			tinsert(tbOpt, {"Trang sau >>>", HideBox_ShowCategory, {szArg, nPage + 1}})
		end
	end
	if szBack == "goldset" then
		tinsert(tbOpt, {"<Trë l¹i>", HideBox_ShowGoldMenu})
	else
		tinsert(tbOpt, {"<Trë l¹i>", HideBox_Main})
	end
	tinsert(tbOpt, {"Tho¸t", HideBox_Exit})
	CreateNewSayEx(szTitle.." | Trang <color=yellow>"..nPage.."/"..nMaxPage.."<color> - Sè nhãm: <color=yellow>"..nTotal.."<color> - VËt phÈm: <color=yellow>"..nTotalItem.."<color>", tbOpt)
end

function HideBox_Reload()
	HideBox_Load()
	HideBox_Main()
end

function HideBox_DepositMenu()
	GiveItemUI("R­¬ng Tïy Th©n", "H·y ®Æt vËt phÈm muèn cÊt vµo ®©y.\nCã thÓ cÊt nhiÒu vËt phÈm mét lÇn.", "HideBox_OnDeposit", "HideBox_Exit", 1)
end

function HideBox_OnDeposit(nCount)
	if not nCount or nCount <= 0 then return end
	local tbList = HideBox_GetList()
	if getn(tbList) + nCount > HIDE_BOX_MAX_ITEM then
		Say("R­¬ng ®· gÇn ®Çy, kh«ng thÓ cÊt thªm nhiÒu vËt phÈm nh­ vËy.", 0)
		return
	end
	local tbNew = {}
	local tbRemove = {}
	for i = 1, nCount do
		local nItemIndex = GetGiveItemUnit(i)
		local tbItem = HideBox_NewFromItem(nItemIndex)
		if tbItem then
			tinsert(tbNew, tbItem)
			tinsert(tbRemove, nItemIndex)
		end
	end
	if getn(tbNew) <= 0 then
		Say("Kh«ng nhËn ®­îc vËt phÈm hîp lÖ.", 0)
		return
	end
	local nOk = 0
	local tbStored = {}
	for i = 1, getn(tbRemove) do
		if RemoveItemByIndex(tbRemove[i]) == 1 then
			tinsert(tbList, tbNew[i])
			tinsert(tbStored, tbNew[i])
			nOk = nOk + 1
		end
	end
	if nOk <= 0 then
		Say("Kh«ng thÓ xãa vËt phÈm gèc, thao t¸c cÊt bÞ hñy.", 0)
		return
	end
	if HideBox_Save() ~= 1 then
		for i = 1, getn(tbStored) do
			tremove(tbList, getn(tbList))
			local nNewIdx, nAddedDirect = HideBox_CreateItem(tbStored[i])
			if nNewIdx and nNewIdx > 0 and nAddedDirect ~= 1 then
				AddItemByIndex(nNewIdx)
			end
		end
		Say("Ghi d÷ liÖu hép thÊt b¹i, ®· cè g¾ng tr¶ l¹i vËt phÈm.", 0)
		return
	end
	Msg2Player("§· cÊt thµnh c«ng <color=yellow>"..nOk.."<color> vËt phÈm vµo R­¬ng Tïy Th©n.")
	if nOk ~= getn(tbRemove) then
		Msg2Player("Cã mét sè vËt phÈm kh«ng cÊt ®­îc v× kh«ng xãa ®­îc vËt phÈm gèc.")
	end
	HideBox_Log("DEPOSIT", nOk)
	HideBox_Main()
end

function HideBox_FilterMenu()
	HideBox_NormalizeAutoMode(0)
	local tbRule = HideBox_LoadFilterRules()
	local szActive = HideBox_FilterActiveText(tbRule)
	local szAutoSell = "[BËt]- läc, b¸n tù ®éng"
	local fnAutoSell = HideBox_AutoFilter_ON
	local szAutoBreak = "[BËt]- läc, t¸ch tù ®éng"
	local fnAutoBreak = HideBox_AutoBreak_ON
	if GetTaskTemp(HIDE_BOX_AUTO_FILTER_FLAG) == 1 then
		szAutoSell = "[T¾t]- läc, b¸n tù ®éng"
		fnAutoSell = HideBox_AutoFilter_OFF
	end
	if GetTaskTemp(HIDE_BOX_AUTO_BREAK_FLAG) == 1 then
		szAutoBreak = "[T¾t]- läc, t¸ch tù ®éng"
		fnAutoBreak = HideBox_AutoBreak_OFF
	end
	local tbOpt = {
		{"Läc vµ b¸n ®å", HideBox_FilterToBox},
		{"Läc vµ t¸ch ®å", HideBox_FilterAndBreak},
		{"Cµi ®Æt gi÷ thuéc tÝnh trang bÞ", HideBox_FilterConfig, {1}},
		{szAutoSell, fnAutoSell},
		{szAutoBreak, fnAutoBreak},
		{"<Trë l¹i>", HideBox_Main},
		{"Tho¸t", HideBox_Exit}
	}
	CreateNewSayEx("Läc ®å theo cÊu h×nh riªng cña nh©n vËt.\nLäc vµ b¸n: ®¹t ®iÒu kiÖn th× cÊt, kh«ng ®¹t th× b¸n.\nLäc vµ t¸ch: ®¹t ®iÒu kiÖn th× cÊt, kh«ng ®¹t th× t¸ch thµnh M¶nh Trang BÞ."..HideBox_AutoFilterStatusText()..szActive, tbOpt)
end

function HideBox_FilterConfig(nPage)
	local tbRule = HideBox_LoadFilterRules()
	if not tbRule then
		Say("Kh«ng ®äc ®­îc danh s¸ch option läc.", 0)
		return
	end
	local tbOrder = tbRule.__tbOrder or {}
	local nTotal = getn(tbOrder)
	if nTotal <= 0 then
		Say("Danh s¸ch option läc ®ang trèng.", 0)
		return
	end
	nPage = tonumber(nPage) or 1
	local nMaxPage = floor((nTotal - 1) / HIDE_BOX_PAGE_SIZE) + 1
	if nPage < 1 then nPage = 1 end
	if nPage > nMaxPage then nPage = nMaxPage end
	local nStart = (nPage - 1) * HIDE_BOX_PAGE_SIZE + 1
	local nEnd = nStart + HIDE_BOX_PAGE_SIZE - 1
	if nEnd > nTotal then nEnd = nTotal end
	local tbOpt = {}
	for i = nStart, nEnd do
		local tb = tbOrder[i]
		local szState = "[T¾t]"
		if tb.nOnOff == 1 then szState = "[BËt]" end
		tinsert(tbOpt, {szState.." "..tb.szText.." "..HideBox_FilterRangeText(tb), HideBox_FilterOptionDetail, {tb.nMagicId, nPage}})
	end
	if nPage > 1 then tinsert(tbOpt, {"<<< Trang tr­íc", HideBox_FilterConfig, {nPage - 1}}) end
	if nPage < nMaxPage then tinsert(tbOpt, {"Trang sau >>>", HideBox_FilterConfig, {nPage + 1}}) end
	tinsert(tbOpt, {"--BËt tÊt c¶--", HideBox_SetAllFilterOption, {1, nPage}})
	tinsert(tbOpt, {"T¾t tÊt c¶", HideBox_SetAllFilterOption, {0, nPage}})
	tinsert(tbOpt, {"Trë l¹i", HideBox_FilterMenu})
	tinsert(tbOpt, {"Tho¸t", HideBox_Exit})
	CreateNewSayEx("CÊu h×nh option läc riªng\nTrang <color=yellow>"..nPage.."/"..nMaxPage.."<color>"..HideBox_FilterActiveText(tbRule), tbOpt)
end

function HideBox_FilterOptionDetail(nMagicId, nPage)
	local tbRule = HideBox_LoadFilterRules()
	if not tbRule or not tbRule[nMagicId] then
		Say("Kh«ng t×m thÊy option läc.", 0)
		return
	end
	local tb = tbRule[nMagicId]
	local szState = "<color=gray>T¾T<color>"
	local szToggleText = "BËt option nµy"
	if tb.nOnOff == 1 then szState = "<color=green>BËT<color>" end
	if tb.nOnOff == 1 then szToggleText = "T¾t option nµy" end
	local tbOpt = {
		{szToggleText, HideBox_ToggleFilterOption, {nMagicId, nPage}},
		{"NhËp gi¸ trÞ nhá nhÊt", HideBox_AskFilterMinValue, {nMagicId, nPage}},
		{"NhËp gi¸ trÞ lín nhÊt", HideBox_AskFilterMaxValue, {nMagicId, nPage}},
		{"Trë l¹i", HideBox_FilterConfig, {nPage}},
		{"Tho¸t", HideBox_Exit}
	}
	CreateNewSayEx("<color=yellow>"..tb.szText.."<color>\nTr¹ng th¸i: "..szState.."\nGi¸ trÞ läc: <color=yellow>"..HideBox_FilterRangeText(tb).."<color>\nGi¸ trÞ lín nhÊt = 0 lµ kh«ng giíi h¹n.", tbOpt)
end

function HideBox_ClearFilterEditState()
	HideBox_FilterEditState[PlayerIndex] = nil
	SetTaskTemp(HIDE_BOX_FILTER_EDIT_MAGIC, 0)
	SetTaskTemp(HIDE_BOX_FILTER_EDIT_PAGE, 0)
end

function HideBox_ToggleFilterOption(nMagicId, nPage)
	local tbRule = HideBox_LoadFilterRules()
	if not tbRule or not tbRule[nMagicId] then
		Say("Kh«ng t×m thÊy option läc.", 0)
		return
	end
	if tbRule[nMagicId].nOnOff == 1 then
		tbRule[nMagicId].nOnOff = 0
	else
		tbRule[nMagicId].nOnOff = 1
	end
	if HideBox_SaveFilterSwitch(tbRule) ~= 1 then
		Say("Kh«ng l­u ®­îc cÊu h×nh läc.", 0)
		return
	end
	HideBox_FilterOptionDetail(nMagicId, nPage)
end

function HideBox_AskFilterMinValue(nMagicId, nPage)
	HideBox_FilterEditState[PlayerIndex] = {nMagicId = nMagicId, nPage = nPage}
	SetTaskTemp(HIDE_BOX_FILTER_EDIT_MAGIC, 0)
	SetTaskTemp(HIDE_BOX_FILTER_EDIT_PAGE, 0)
	AskClientForNumber("HideBox_SetFilterMinValue", 0, 99999, "NhËp gi¸ trÞ nhá nhÊt")
end

function HideBox_SetFilterMinValue(nValue)
	local tbState = HideBox_FilterEditState[PlayerIndex]
	if not tbState then
		HideBox_ClearFilterEditState()
		HideBox_FilterConfig(1)
		return
	end
	local nMagicId = tbState.nMagicId
	local nPage = tbState.nPage or 1
	local tbRule = HideBox_LoadFilterRules()
	if not tbRule or not tbRule[nMagicId] then
		HideBox_ClearFilterEditState()
		HideBox_FilterConfig(nPage)
		return
	end
	nValue = tonumber(nValue) or 0
	if nValue < 0 then nValue = 0 end
	tbRule[nMagicId].nMinValue = nValue
	if tbRule[nMagicId].nMaxValue > 0 and tbRule[nMagicId].nMaxValue < nValue then
		tbRule[nMagicId].nMaxValue = nValue
	end
	if HideBox_SaveFilterSwitch(tbRule) ~= 1 then
		HideBox_ClearFilterEditState()
		Say("Kh«ng l­u ®­îc cÊu h×nh läc.", 0)
		return
	end
	HideBox_ClearFilterEditState()
	HideBox_FilterOptionDetail(nMagicId, nPage)
end

function HideBox_AskFilterMaxValue(nMagicId, nPage)
	HideBox_FilterEditState[PlayerIndex] = {nMagicId = nMagicId, nPage = nPage}
	SetTaskTemp(HIDE_BOX_FILTER_EDIT_MAGIC, 0)
	SetTaskTemp(HIDE_BOX_FILTER_EDIT_PAGE, 0)
	AskClientForNumber("HideBox_SetFilterMaxValue", 0, 99999, "NhËp gi¸ trÞ lín nhÊt, 0 lµ kh«ng giíi h¹n")
end

function HideBox_SetFilterMaxValue(nValue)
	local tbState = HideBox_FilterEditState[PlayerIndex]
	if not tbState then
		HideBox_ClearFilterEditState()
		HideBox_FilterConfig(1)
		return
	end
	local nMagicId = tbState.nMagicId
	local nPage = tbState.nPage or 1
	local tbRule = HideBox_LoadFilterRules()
	if not tbRule or not tbRule[nMagicId] then
		HideBox_ClearFilterEditState()
		HideBox_FilterConfig(nPage)
		return
	end
	nValue = tonumber(nValue) or 0
	if nValue < 0 then nValue = 0 end
	if nValue > 0 and nValue < tbRule[nMagicId].nMinValue then
		nValue = tbRule[nMagicId].nMinValue
	end
	tbRule[nMagicId].nMaxValue = nValue
	if HideBox_SaveFilterSwitch(tbRule) ~= 1 then
		HideBox_ClearFilterEditState()
		Say("Kh«ng l­u ®­îc cÊu h×nh läc.", 0)
		return
	end
	HideBox_ClearFilterEditState()
	HideBox_FilterOptionDetail(nMagicId, nPage)
end

function HideBox_SetAllFilterOption(nOnOff, nPage)
	local tbRule = HideBox_LoadFilterRules()
	if not tbRule then
		Say("Kh«ng ®äc ®­îc danh s¸ch option läc.", 0)
		return
	end
	local tbOrder = tbRule.__tbOrder or {}
	for i = 1, getn(tbOrder) do
		tbOrder[i].nOnOff = nOnOff
	end
	if HideBox_SaveFilterSwitch(tbRule) ~= 1 then
		Say("Kh«ng l­u ®­îc cÊu h×nh läc.", 0)
		return
	end
	HideBox_FilterConfig(nPage)
end

function HideBox_FilterAndBreak()
	HideBox_FilterToBox(0, 1)
end

function HideBox_FilterToBox(bSilent, nBreakMode)
	local tbRule = HideBox_LoadFilterRules()
	if not tbRule then
		Say("Kh«ng ®äc ®­îc danh s¸ch option läc.", 0)
		return
	end
	if not tbRule.__nActive or tbRule.__nActive <= 0 then
		Say("Ch­a bËt option läc nµo, kh«ng t¸ch, cÊt ®å ®Ó tr¸nh mÊt vËt phÈm.", 0)
		return
	end
	HideBox_Load()
	local tbList = HideBox_GetList()
	local tbRoomItems = GetRoomItems(0)
	local tbStore = {}
	local tbSell = {}
	local tbBreak = {}
	local nFull = 0
	local nSkipBreak = 0
	for _, nItemIndex in tbRoomItems do
		if HideBox_FilterCanProcess(nItemIndex) == 1 then
			if HideBox_FilterIsGood(nItemIndex, tbRule) == 1 then
				if getn(tbList) + getn(tbStore) < HIDE_BOX_MAX_ITEM then
					local tbItem = HideBox_NewFromItem(nItemIndex)
					if tbItem then
						tinsert(tbStore, {nIndex = nItemIndex, tbItem = tbItem})
					end
				else
					nFull = nFull + 1
				end
			else
				if nBreakMode == 1 then
					if HideBox_CanDismantleBlueItem(nItemIndex) == 1 then
						tinsert(tbBreak, {nIndex = nItemIndex, nFragment = GetItemLevel(nItemIndex) or 0})
					else
						nSkipBreak = nSkipBreak + 1
					end
				else
					tinsert(tbSell, {nIndex = nItemIndex, nPrice = floor((GetItemPrice(nItemIndex) or 0) / 4)})
				end
			end
		end
	end
	local nStored = 0
	local tbStored = {}
	for i = 1, getn(tbStore) do
		if RemoveItemByIndex(tbStore[i].nIndex) == 1 then
			tinsert(tbList, tbStore[i].tbItem)
			tinsert(tbStored, tbStore[i].tbItem)
			nStored = nStored + 1
		end
	end
	if nStored > 0 and HideBox_Save() ~= 1 then
		for i = 1, getn(tbStored) do
			tremove(tbList, getn(tbList))
			local nNewIdx, nAddedDirect = HideBox_CreateItem(tbStored[i])
			if nNewIdx and nNewIdx > 0 and nAddedDirect ~= 1 then
				AddItemByIndex(nNewIdx)
			end
		end
		Say("Ghi d÷ liÖu hép thÊt b¹i, ®· cè g¾ng tr¶ l¹i ®å ®¹t läc.", 0)
		return
	end
	local nSold = 0
	local nEarn = 0
	for i = 1, getn(tbSell) do
		if RemoveItemByIndex(tbSell[i].nIndex) == 1 then
			nSold = nSold + 1
			nEarn = nEarn + tbSell[i].nPrice
		end
	end
	if nEarn > 0 then Earn(nEarn) end
	local nBroken = 0
	local nFragment = 0
	for i = 1, getn(tbBreak) do
		if RemoveItemByIndex(tbBreak[i].nIndex) == 1 then
			nBroken = nBroken + 1
			nFragment = nFragment + tbBreak[i].nFragment
		end
	end
	if nFragment > 0 then
		AddStackItem(nFragment, 6, 1, HIDE_BOX_FRAGMENT_ITEM_ID, 1, 0, 0)
	end
	if bSilent ~= 1 then
		if nBreakMode == 1 then
			Msg2Player("Läc vµ t¸ch xong: cÊt <color=yellow>"..nStored.."<color>, t¸ch <color=yellow>"..nBroken.."<color>, nhËn <color=green>"..nFragment.."<color> m¶nh.")
		else
			Msg2Player("Läc vµ b¸n xong: cÊt <color=yellow>"..nStored.."<color>, b¸n <color=yellow>"..nSold.."<color>, nhËn <color=yellow>"..nEarn.."<color> ng©n l­îng.")
		end
		if nFull > 0 then
			Msg2Player("Hép ®· ®Çy, gi÷ l¹i <color=yellow>"..nFull.."<color> vËt phÈm ®¹t ®iÒu kiÖn trong hµnh trang.")
		end
		if nBreakMode == 1 and nSkipBreak > 0 then
			Msg2Player("Gi÷ l¹i <color=yellow>"..nSkipBreak.."<color> vËt phÈm kh«ng ®¹t läc nh­ng kh«ng ph¶i trang bÞ tr¾ng/xanh ®Ó t¸ch.")
		end
		HideBox_Main()
	else
		if nBreakMode == 1 then
			Msg2Player("Tù ®éng läc, t¸ch: cÊt <color=yellow>"..nStored.."<color>, t¸ch <color=yellow>"..nBroken.."<color>, m¶nh <color=green>"..nFragment.."<color>.")
		else
			Msg2Player("Tù ®éng läc, b¸n: cÊt <color=yellow>"..nStored.."<color>, b¸n <color=yellow>"..nSold.."<color>, nhËn <color=yellow>"..nEarn.."<color>.")
		end
	end
	HideBox_Log("FILTER", "STORE="..nStored..",BREAKMODE="..(nBreakMode or 0)..",SELL="..nSold..",EARN="..nEarn..",BREAK="..nBroken..",FRAGMENT="..nFragment..",SKIPBREAK="..nSkipBreak..",FULL="..nFull)
end

function HideBox_AutoFilter_ON()
	HideBox_AutoBreak_OFF(1)
	SetTaskTemp(HIDE_BOX_AUTO_FILTER_FLAG, 1)
	AskClientForNumber("HideBox_StartAutoFilter", 30, 300, "NhËp sè gi©y tù ®éng läc/b¸n")
end

function HideBox_StartAutoFilter(nSecond)
	nSecond = tonumber(nSecond) or 30
	if nSecond < 30 then nSecond = 30 end
	if nSecond > 300 then nSecond = 300 end
	HideBox_NormalizeAutoMode(1)
	if GetTaskTemp(HIDE_BOX_AUTO_FILTER_FLAG) ~= 1 then return end
	local nOldTimer = GetTaskTemp(HIDE_BOX_AUTO_FILTER_TIMER)
	if nOldTimer and nOldTimer > 0 then
		DelTimer(nOldTimer)
	end
	HideBox_FilterToBox(1)
	local nTimer = AddTimer(nSecond * 18, "HideBox_StartAutoFilter", nSecond)
	SetTaskTemp(HIDE_BOX_AUTO_FILTER_TIMER, nTimer)
	Msg2Player("<color=yellow>Tù ®éng läc, b¸n sau mçi <color><color=green>"..nSecond.."<color> gi©y.")
end

function HideBox_AutoFilter_OFF(bSilent)
	SetTaskTemp(HIDE_BOX_AUTO_FILTER_FLAG, 0)
	local nTimer = GetTaskTemp(HIDE_BOX_AUTO_FILTER_TIMER)
	if nTimer and nTimer > 0 then
		DelTimer(nTimer)
	end
	SetTaskTemp(HIDE_BOX_AUTO_FILTER_TIMER, 0)
	if bSilent ~= 1 then
		Msg2Player("<color=yellow>§· t¾t tù ®éng läc, b¸n.<color>")
		HideBox_FilterMenu()
	end
end

function HideBox_AutoBreak_ON()
	HideBox_AutoFilter_OFF(1)
	SetTaskTemp(HIDE_BOX_AUTO_BREAK_FLAG, 1)
	AskClientForNumber("HideBox_StartAutoBreak", 30, 300, "NhËp sè gi©y tù ®éng läc, t¸ch")
end

function HideBox_StartAutoBreak(nSecond)
	nSecond = tonumber(nSecond) or 30
	if nSecond < 30 then nSecond = 30 end
	if nSecond > 300 then nSecond = 300 end
	HideBox_NormalizeAutoMode(2)
	if GetTaskTemp(HIDE_BOX_AUTO_BREAK_FLAG) ~= 1 then return end
	local nOldTimer = GetTaskTemp(HIDE_BOX_AUTO_BREAK_TIMER)
	if nOldTimer and nOldTimer > 0 then
		DelTimer(nOldTimer)
	end
	HideBox_FilterToBox(1, 1)
	local nTimer = AddTimer(nSecond * 18, "HideBox_StartAutoBreak", nSecond)
	SetTaskTemp(HIDE_BOX_AUTO_BREAK_TIMER, nTimer)
	Msg2Player("<color=yellow>Tù ®éng läc, t¸ch sau mçi <color><color=green>"..nSecond.."<color> gi©y.")
end

function HideBox_AutoBreak_OFF(bSilent)
	SetTaskTemp(HIDE_BOX_AUTO_BREAK_FLAG, 0)
	local nTimer = GetTaskTemp(HIDE_BOX_AUTO_BREAK_TIMER)
	if nTimer and nTimer > 0 then
		DelTimer(nTimer)
	end
	SetTaskTemp(HIDE_BOX_AUTO_BREAK_TIMER, 0)
	if bSilent ~= 1 then
		Msg2Player("<color=yellow>§· t¾t tù ®éng läc, t¸ch.<color>")
		HideBox_FilterMenu()
	end
end

function HideBox_ShowList(nPage)
	local tbList = HideBox_GetList()
	local nTotal = getn(tbList)
	if nTotal <= 0 then
		CreateNewSayEx("Hép CÊt GiÊu hiÖn ®ang trèng.", {{"Trë l¹i", HideBox_Main}, {"Tho¸t", HideBox_Exit}})
		return
	end
	nPage = tonumber(nPage) or 1
	local nMaxPage = floor((nTotal - 1) / HIDE_BOX_PAGE_SIZE) + 1
	if nPage < 1 then nPage = 1 end
	if nPage > nMaxPage then nPage = nMaxPage end
	local nStart = (nPage - 1) * HIDE_BOX_PAGE_SIZE + 1
	local nEnd = nStart + HIDE_BOX_PAGE_SIZE - 1
	if nEnd > nTotal then nEnd = nTotal end
	local tbOpt = {}
	tinsert(tbOpt, {"Rót tÊt c¶", HideBox_ConfirmWithdrawAll, {"TÊt c¶ vËt phÈm", "category", "all", nPage}})
	tinsert(tbOpt, {"B¸n tÊt c¶", HideBox_ConfirmSellAll, {"TÊt c¶ vËt phÈm", "category", "all", nPage}})
	tinsert(tbOpt, {"Göi tÊt c¶", HideBox_ConfirmMailAll, {"TÊt c¶ vËt phÈm", "category", "all", nPage}})
	for i = nStart, nEnd do
		local tb = tbList[i]
		local szCount = ""
		if tb.nCount and tb.nCount > 1 then szCount = " x"..tb.nCount end
		tinsert(tbOpt, {i..". ["..HideBox_ItemTypeName(tb).."] "..tb.szName..szCount, HideBox_ItemDetail, {i, nPage}})
	end
	if nPage > 1 then tinsert(tbOpt, {"<<< Trang tr­íc", HideBox_ShowList, {nPage - 1}}) end
	if nPage < nMaxPage then tinsert(tbOpt, {"Trang sau >>>", HideBox_ShowList, {nPage + 1}}) end
	tinsert(tbOpt, {"<Trë l¹i>", HideBox_Main})
	tinsert(tbOpt, {"Tho¸t", HideBox_Exit})
	CreateNewSayEx("Danh s¸ch Hép CÊt GiÊu\nTrang <color=yellow>"..nPage.."/"..nMaxPage.."<color>", tbOpt)
end

function HideBox_CopyIndexList(tbIndex)
	local tb = {}
	if not tbIndex then return tb end
	for i = 1, getn(tbIndex) do
		tinsert(tb, tbIndex[i])
	end
	return tb
end

function HideBox_SortIndexDesc(tbIndex)
	local tb = HideBox_CopyIndexList(tbIndex)
	for i = 1, getn(tb) do
		for j = i + 1, getn(tb) do
			if tb[i] < tb[j] then
				local nTmp = tb[i]
				tb[i] = tb[j]
				tb[j] = nTmp
			end
		end
	end
	return tb
end

function HideBox_CollectGroupIndexes(szGroupKey, szBack, szArg)
	local tbIndex = HideBox_GetIndexByBack(szBack, szArg)
	local tbGroups = HideBox_BuildGroups(tbIndex)
	for i = 1, getn(tbGroups) do
		if tbGroups[i].szKey == szGroupKey then
			return HideBox_CopyIndexList(tbGroups[i].tbIndex), HideBox_GroupText(tbGroups[i])
		end
	end
	return {}, ""
end

function HideBox_IndexListSellPrice(tbIndex)
	local tbList = HideBox_GetList()
	local nPrice = 0
	for i = 1, getn(tbIndex) do
		local tb = tbList[tbIndex[i]]
		if tb then
			nPrice = nPrice + HideBox_GetStoredItemSellPrice(tb)
		end
	end
	return nPrice
end

function HideBox_ConfirmWithdrawAll(szTitle, szBack, szArg, nPage)
	local tbIndex = HideBox_GetIndexByBack(szBack, szArg)
	local nCount = getn(tbIndex)
	if nCount <= 0 then
		Say("Danh s¸ch ®ang trèng.", 0)
		return
	end
	CreateNewSayEx("X¸c nhËn rót tÊt c¶ <color=yellow>"..nCount.."<color> vËt phÈm trong danh s¸ch: "..szTitle.."?", {
		{"X¸c nhËn rót", HideBox_WithdrawAll, {szBack, szArg, nPage}},
		{"Kh«ng rót n÷a", HideBox_ReturnPage, {nPage, szBack, szArg}}
	})
end

function HideBox_ConfirmSellAll(szTitle, szBack, szArg, nPage)
	local tbIndex = HideBox_GetIndexByBack(szBack, szArg)
	local nCount = getn(tbIndex)
	if nCount <= 0 then
		Say("Danh s¸ch vËt phÈm trèng.", 0)
		return
	end
	local nPrice = HideBox_IndexListSellPrice(tbIndex)
	CreateNewSayEx("X¸c nhËn b¸n tÊt c¶ <color=yellow>"..nCount.."<color> vËt phÈm trong danh s¸ch: "..szTitle.."?\nNhËn ®­îc: <color=yellow>"..nPrice.."<color> ng©n l­în.", {
		{"X¸c nhËn b¸n tÊt c¶", HideBox_SellAll, {szBack, szArg, nPage, nPrice}},
		{"Ta ch­a muèn b¸n", HideBox_ReturnPage, {nPage, szBack, szArg}}
	})
end

function HideBox_ConfirmWithdrawGroup(szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage)
	local tbIndex, szGroupName = HideBox_CollectGroupIndexes(szGroupKey, szBack, szArg)
	local nCount = getn(tbIndex)
	if nCount <= 0 then
		HideBox_ShowIndexPage(szTitle, HideBox_GetIndexByBack(szBack, szArg), nGroupPage or 1, szBack, szArg)
		return
	end
	CreateNewSayEx("X¸c nhËn rót tÊt c¶ <color=yellow>"..nCount.."<color> vËt phÈm trong nhãm:\n"..szGroupName.."?", {
		{"X¸c nhËn rót tÊt c¶", HideBox_WithdrawGroup, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1}},
		{"Th«i! ta kh«ng rót n÷a", HideBox_ShowGroupByKey, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1}}
	})
end

function HideBox_ConfirmSellGroup(szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage)
	local tbIndex, szGroupName = HideBox_CollectGroupIndexes(szGroupKey, szBack, szArg)
	local nCount = getn(tbIndex)
	if nCount <= 0 then
		HideBox_ShowIndexPage(szTitle, HideBox_GetIndexByBack(szBack, szArg), nGroupPage or 1, szBack, szArg)
		return
	end
	local nPrice = HideBox_IndexListSellPrice(tbIndex)
	CreateNewSayEx("X¸c nhËn b¸n tÊt c¶ <color=yellow>"..nCount.."<color> vËt phÈm trong nhãm:\n"..szGroupName.."\nNhËn ®­îc: <color=yellow>"..nPrice.."<color> ng©n l­îng.", {
		{"X¸c nhËn b¸n tÊt c¶", HideBox_SellGroup, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1, nPrice}},
		{"Th«i! ta ko b¸n n÷a", HideBox_ShowGroupByKey, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1}}
	})
end

function HideBox_WithdrawIndexList(tbIndex, nPage, szBack, szArg)
	local tbList = HideBox_GetList()
	local nNeedCell = getn(tbIndex)
	if nNeedCell <= 0 then
		Say("Kh«ng cã vËt phÈm ®Ó rót.", 0)
		return
	end
	if CalcFreeItemCellCount and CalcFreeItemCellCount() < nNeedCell then
		Say("Hµnh trang kh«ng ®ñ chç trèng. CÇn Ýt nhÊt "..nNeedCell.." « trèng.", 0)
		return
	end
	local tbSuccess = {}
	for i = 1, getn(tbIndex) do
		local nRealIndex = tbIndex[i]
		local tb = tbList[nRealIndex]
		if tb then
			local nItemIndex = HideBox_AddStoredItemToPlayer(tb)
			if nItemIndex and nItemIndex > 0 then
				tinsert(tbSuccess, nRealIndex)
			end
		end
	end
	if getn(tbSuccess) <= 0 then
		Say("Tao lai vat pham that bai. Du lieu van duoc giu trong hop.", 0)
		return
	end
	local tbRemove = HideBox_SortIndexDesc(tbSuccess)
	for i = 1, getn(tbRemove) do
		tremove(tbList, tbRemove[i])
	end
	HideBox_Save()
	Msg2Player("§· rótt <color=yellow>"..getn(tbSuccess).."<color> vËt phÈm khái r­¬ng tïy th©n.")
	HideBox_Log("WITHDRAW_ALL", getn(tbSuccess))
	HideBox_ReturnPage(nPage, szBack, szArg)
end

function HideBox_SellIndexList(tbIndex, nPage, szBack, szArg, nPrice)
	local tbList = HideBox_GetList()
	if getn(tbIndex) <= 0 then
		Say("Kh«ng cã cËt phÈm ®Ó b¸n.", 0)
		return
	end
	nPrice = tonumber(nPrice) or HideBox_IndexListSellPrice(tbIndex)
	local tbRemove = HideBox_SortIndexDesc(tbIndex)
	local nSold = 0
	for i = 1, getn(tbRemove) do
		if tbList[tbRemove[i]] then
			tremove(tbList, tbRemove[i])
			nSold = nSold + 1
		end
	end
	if nSold <= 0 then
		Say("Kh«ng cã vËt phÈm nµo ®Ó b¸n.", 0)
		return
	end
	if HideBox_Save() ~= 1 then
		HideBox_Load()
		Say("Ghi d÷ liÖu thÊt b¹ii, kh«ng b¸n vËt phÈm.", 0)
		return
	end
	if nPrice > 0 then Earn(nPrice) end
	Msg2Player("§· b¸n <color=yellow>"..nSold.."<color> vËt phÈm trong r­¬ng tïy th©n, nhËn ®­îc <color=yellow>"..nPrice.."<color> ng©n l­îng.")
	HideBox_Log("SELL_ALL_STORED", nSold..","..nPrice)
	HideBox_ReturnPage(nPage, szBack, szArg)
end

function HideBox_WithdrawAll(szBack, szArg, nPage)
	HideBox_WithdrawIndexList(HideBox_GetIndexByBack(szBack, szArg), nPage, szBack, szArg)
end

function HideBox_SellAll(szBack, szArg, nPage, nPrice)
	HideBox_SellIndexList(HideBox_GetIndexByBack(szBack, szArg), nPage, szBack, szArg, nPrice)
end

function HideBox_WithdrawGroup(szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage)
	local tbIndex = HideBox_CollectGroupIndexes(szGroupKey, szBack, szArg)
	HideBox_WithdrawIndexList(tbIndex, nGroupPage or 1, szBack, szArg)
end

function HideBox_SellGroup(szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage, nPrice)
	local tbIndex = HideBox_CollectGroupIndexes(szGroupKey, szBack, szArg)
	HideBox_SellIndexList(tbIndex, nGroupPage or 1, szBack, szArg, nPrice)
end

function HideBox_MailItemDataList(tbStored)
	local tbData = {}
	for i = 1, getn(tbStored) do
		local szData = MailSerializeItem(tbStored[i])
		if not szData or szData == "" then
			return ""
		end
		tinsert(tbData, szData)
	end
	return MailSerializeItemList(tbData)
end

function HideBox_BuildStoredListByIndex(tbIndex)
	local tbList = HideBox_GetList()
	local tbStored = {}
	for i = 1, getn(tbIndex) do
		local tb = tbList[tbIndex[i]]
		if tb then
			tinsert(tbStored, tb)
		end
	end
	return tbStored
end

function HideBox_RemoveIndexListFromBox(tbIndex)
	local tbList = HideBox_GetList()
	local tbRemove = HideBox_SortIndexDesc(tbIndex)
	for i = 1, getn(tbRemove) do
		if tbList[tbRemove[i]] then
			tremove(tbList, tbRemove[i])
		end
	end
	return 1
end

function HideBox_RestoreIndexListToBox(tbIndex, tbStored)
	local tbList = HideBox_GetList()
	for i = 1, getn(tbIndex) do
		local nPos = tbIndex[i]
		if nPos < 1 then nPos = 1 end
		if nPos > getn(tbList) + 1 then nPos = getn(tbList) + 1 end
		for j = getn(tbList) + 1, nPos + 1, -1 do
			tbList[j] = tbList[j - 1]
		end
		tbList[nPos] = tbStored[i]
	end
	HideBox_Save()
end

function HideBox_SendMailDataFromBox(szReceiver, szTitle, szContent, tbStored)
	if not szReceiver or szReceiver == "" then
		return 0, "Tªn ng­êi nhËn kh«ng hîp lÖ."
	end
	local nCount = getn(tbStored)
	if nCount <= 0 then
		return 0, "Kh«ng cã vËt phÈm ®Ó göi."
	end
	local szItemData = HideBox_MailItemDataList(tbStored)
	if szItemData == "" then
		return 0, "Kh«ng thÓ t¹o d÷ liÖu vËt phÈm ®Ó göi."
	end

	EnsureMailboxLoaded(szReceiver)
	MailBox[szReceiver] = MailBox[szReceiver] or {}
	if getn(MailBox[szReceiver]) >= 10 then
		return 0, "Hép th­ ng­êi nhËn ®Çy, kh«ng thÓ göi lóc nµy."
	end
	if GetCash() < 10000 then
		return 0, "B¹n kh«ng ®ñ 1 v¹n ng©n l­îng ®Ó tr¶ phÝ göi th­."
	end

	local tbFirst = tbStored[1] or {}
	local tbProp = tbFirst.tbProp or {}
	local szItemName = tbFirst.szName or "VËt phÈm"
	if nCount > 1 then
		szItemName = szItemName.." vµ "..(nCount - 1).." vËt phÈm kh¸c"
	end
	local szMailID = GenerateMailID()
	local szSendTime = GetLocalDate("%Y%m%d%H%M")
	local mail = NewMail(GetName(), szReceiver, szTitle or "Göi vËt phÈm tõ r­¬ng", szContent or "", 0, 0, nCount, szItemName, tbProp[2] or 0, szMailID, szSendTime, tbProp[1] or 0, tbProp[4] or 0, szItemData)

	tinsert(MailBox[szReceiver], mail)
	if SaveMailbox(szReceiver) ~= 1 then
		tremove(MailBox[szReceiver], getn(MailBox[szReceiver]))
		return 0, "Kh«ng l­u ®­îc hép th­ ng­êi nhËn."
	end

	local szSender = GetName()
	MailBoxOut = MailBoxOut or {}
	EnsureOutboxLoaded(szSender)
	MailBoxOut[szSender] = MailBoxOut[szSender] or {}
	tinsert(MailBoxOut[szSender], mail)
	if SaveOutbox(szSender) ~= 1 then
		tremove(MailBoxOut[szSender], getn(MailBoxOut[szSender]))
		tremove(MailBox[szReceiver], getn(MailBox[szReceiver]))
		SaveMailbox(szReceiver)
		return 0, "Kh«ng l­u ®­îc hép th­ ®i."
	end

	Pay(10000)
	AddContact(szSender, szReceiver)
	local nSenderIdx = PlayerIndex
	local nTargetIdx = FindPlayerOnline(szReceiver)
	if nTargetIdx and nTargetIdx > 0 and nTargetIdx ~= nSenderIdx then
		PlayerIndex = nTargetIdx
		Msg2Player("<color=cyan>NhËn ®­îc th­ míi tõ: <color=yellow>"..szSender.."<color><color>")
		if PutMessage then PutMessage("NhËn th­ míi tõ: "..szSender) end
		PlayerIndex = nSenderIdx
	end
	return 1, "§· göi <color=yellow>"..nCount.."<color> vËt phÈm ®Õn <color=green>"..szReceiver.."<color>. PhÝ: <color=yellow>1 V¹n<color>."
end

function HideBox_SetMailState(tbIndex, nPage, szBack, szArg)
	HideBox_MailState[PlayerIndex] = {
		tbIndex = HideBox_CopyIndexList(tbIndex),
		nPage = nPage or 1,
		szBack = szBack,
		szArg = szArg,
	}
end

function HideBox_ConfirmMailOne(nIndex, nPage, szBack, szArg)
	local tbList = HideBox_GetList()
	local tb = tbList[nIndex]
	if not tb then return end
	CreateNewSayEx("X¸c nhËn göi "..HideBox_ItemNameText(tb).." b»ng th­?\nPhÝ göi: <color=yellow>1 V¹n<color>.", {
		{"X¸c nhËn göi", HideBox_StartMailIndexList, {{nIndex}, nPage, szBack, szArg}},
		{"Kh«ng göi", HideBox_ItemDetail, {nIndex, nPage, szBack, szArg}}
	})
end

function HideBox_ConfirmMailAll(szTitle, szBack, szArg, nPage)
	local tbIndex = HideBox_GetIndexByBack(szBack, szArg)
	local nCount = getn(tbIndex)
	if nCount <= 0 then
		Say("Danh s¸ch ®ang trèng.", 0)
		return
	end
	CreateNewSayEx("X¸c nhËn göi tÊt c¶ <color=yellow>"..nCount.."<color> vËt phÈm trong danh s¸ch: "..szTitle.."?\nPhÝ göi: <color=yellow>1 V¹n<color>.", {
		{"X¸c nhËn göi", HideBox_StartMailIndexList, {tbIndex, nPage, szBack, szArg}},
		{"Kh«ng göi", HideBox_ReturnPage, {nPage, szBack, szArg}}
	})
end

function HideBox_ConfirmMailGroup(szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage)
	local tbIndex, szGroupName = HideBox_CollectGroupIndexes(szGroupKey, szBack, szArg)
	local nCount = getn(tbIndex)
	if nCount <= 0 then
		HideBox_ShowIndexPage(szTitle, HideBox_GetIndexByBack(szBack, szArg), nGroupPage or 1, szBack, szArg)
		return
	end
	CreateNewSayEx("X¸c nhËn göi tÊt c¶ <color=yellow>"..nCount.."<color> vËt phÈm trong nhãm:\n"..szGroupName.."\nPhÝ göi: <color=yellow>1 V¹n<color>.", {
		{"X¸c nhËn göi", HideBox_StartMailIndexList, {tbIndex, nGroupPage or 1, szBack, szArg}},
		{"Kh«ng göi", HideBox_ShowGroupByKey, {szTitle, szGroupKey, nPage, szBack, szArg, nGroupPage or 1}}
	})
end

function HideBox_StartMailIndexList(tbIndex, nPage, szBack, szArg)
	if not tbIndex or getn(tbIndex) <= 0 then
		Say("Kh«ng cã vËt phÈm ®Ó göi.", 0)
		return
	end
	HideBox_SetMailState(tbIndex, nPage, szBack, szArg)
	HideBox_ChooseMailReceiver()
end

function HideBox_ChooseMailReceiver()
	local tbState = HideBox_MailState[PlayerIndex]
	if not tbState then
		HideBox_Main()
		return
	end
	local szName = GetName()
	EnsureContactsLoaded(szName)
	local tbContact = MailContacts[szName] or {}
	local tbOpt = {
		{"NhËp tªn míi", HideBox_InputNewMailReceiver},
	}
	if getn(tbContact) > 0 then
		tinsert(tbOpt, {"Danh b¹", HideBox_ShowMailContacts})
	end
	tinsert(tbOpt, {"Quay l¹i", HideBox_ReturnPage, {tbState.nPage, tbState.szBack, tbState.szArg}})
	tinsert(tbOpt, {"Tho¸t", HideBox_Exit})
	CreateNewSayEx("Chän ng­êi nhËn vËt phÈm tõ r­¬ng:", tbOpt)
end

function HideBox_ShowMailContacts()
	local tbState = HideBox_MailState[PlayerIndex]
	if not tbState then
		HideBox_Main()
		return
	end
	local szName = GetName()
	EnsureContactsLoaded(szName)
	local tbContact = MailContacts[szName] or {}
	local tbOpt = {}
	for i = 1, getn(tbContact) do
		tinsert(tbOpt, {tbContact[i], HideBox_SelectMailContact, {i}})
	end
	tinsert(tbOpt, {"NhËp tªn míi", HideBox_InputNewMailReceiver})
	tinsert(tbOpt, {"Quay l¹i", HideBox_ChooseMailReceiver})
	tinsert(tbOpt, {"Tho¸t", HideBox_Exit})
	CreateNewSayEx("Danh b¹ göi th­:", tbOpt)
end

function HideBox_SelectMailContact(nIndex)
	local tbState = HideBox_MailState[PlayerIndex]
	if not tbState then
		HideBox_Main()
		return
	end
	local szName = GetName()
	EnsureContactsLoaded(szName)
	local tbContact = MailContacts[szName] or {}
	if not tbContact[nIndex] then
		CreateNewSayEx("Kh«ng t×m thÊy tªn trong danh b¹.", {{"Quay l¹i", HideBox_ChooseMailReceiver}, {"Tho¸t", HideBox_Exit}})
		return
	end
	tbState.szReceiver = tbContact[nIndex]
	AskClientForString("HideBox_InputMailTitle", "Göi vËt phÈm tõ r­¬ng", 1, 50, "Tiªu ®Ò:")
end

function HideBox_InputNewMailReceiver()
	AskClientForString("HideBox_InputMailReceiver", "", 1, 50, "NhËp tªn ng­êi nhËn:")
end

function HideBox_InputMailReceiver(szReceiver)
	local tbState = HideBox_MailState[PlayerIndex]
	if not tbState then
		HideBox_Main()
		return
	end
	tbState.szReceiver = SanitizeText(szReceiver)
	AskClientForString("HideBox_InputMailTitle", "Göi vËt phÈm tõ r­¬ng", 1, 50, "Tiªu ®Ò:")
end

function HideBox_InputMailTitle(szTitle)
	local tbState = HideBox_MailState[PlayerIndex]
	if not tbState then
		HideBox_Main()
		return
	end
	tbState.szTitle = SanitizeText(szTitle)
	AskClientForString("HideBox_InputMailContent", "VËt phÈm göi tõ r­¬ng tïy th©n.", 1, 100, "Néi dung:")
end

function HideBox_InputMailContent(szContent)
	local tbState = HideBox_MailState[PlayerIndex]
	if not tbState then
		HideBox_Main()
		return
	end
	tbState.szContent = SanitizeText(szContent)
	HideBox_DoSendMailFromBox()
end

function HideBox_DoSendMailFromBox()
	local tbState = HideBox_MailState[PlayerIndex]
	if not tbState then
		HideBox_Main()
		return
	end
	local tbIndex = HideBox_CopyIndexList(tbState.tbIndex)
	local tbStored = HideBox_BuildStoredListByIndex(tbIndex)
	if getn(tbStored) <= 0 then
		HideBox_MailState[PlayerIndex] = nil
		Say("VËt phÈm kh«ng cßn tån t¹i trong r­¬ng.", 0)
		return
	end

	HideBox_RemoveIndexListFromBox(tbIndex)
	if HideBox_Save() ~= 1 then
		HideBox_RestoreIndexListToBox(tbIndex, tbStored)
		HideBox_MailState[PlayerIndex] = nil
		Say("Ghi d÷ liÖu r­¬ng thÊt b¹i, kh«ng göi th­.", 0)
		return
	end

	local nOk, szMsg = HideBox_SendMailDataFromBox(tbState.szReceiver, tbState.szTitle, tbState.szContent, tbStored)
	if nOk ~= 1 then
		HideBox_RestoreIndexListToBox(tbIndex, tbStored)
		HideBox_MailState[PlayerIndex] = nil
		CreateNewSayEx(szMsg, {{"Quay l¹i", HideBox_ReturnPage, {tbState.nPage, tbState.szBack, tbState.szArg}}, {"Tho¸t", HideBox_Exit}})
		return
	end

	local nPage = tbState.nPage
	local szBack = tbState.szBack
	local szArg = tbState.szArg
	HideBox_MailState[PlayerIndex] = nil
	HideBox_Log("MAIL_FROM_BOX", szMsg)
	CreateNewSayEx(szMsg, {{"Quay l¹i", HideBox_ReturnPage, {nPage, szBack, szArg}}, {"Tho¸t", HideBox_Exit}})
end

function HideBox_ItemDetail(nIndex, nPage, szBack, szArg)
	local tbList = HideBox_GetList()
	local tb = tbList[nIndex]
	if not tb then
		Say("VËt phÈm kh«ng tån t¹i.", 0)
		return
	end
	local szMagic = HideBox_ItemMagicText(tb, 0, "\n")
	if szMagic ~= "" then
		szMagic = "\nThuéc tÝnh:\n"..szMagic
	end
	local nSellPrice = HideBox_GetStoredItemSellPrice(tb)
	local szMsg = HideBox_ItemFrameText(tb).."\n"..szMagic.."\n\nGi¸ b¸n: <color=yellow>"..nSellPrice.."<color> ng©n l­îng.\nNg­¬i muèn thao t¸c g×?"
	local tbOpt = {
		{"Rót vËt phÈm", HideBox_ConfirmWithdraw, {nIndex, nPage, szBack, szArg}},
		{"B¸n vËt phÈm nµy", HideBox_ConfirmSellStoredItem, {nIndex, nPage, szBack, szArg}},
		{"Göi vËt phÈm nµy", HideBox_ConfirmMailOne, {nIndex, nPage, szBack, szArg}},
		{"Quay l¹i", HideBox_ReturnPage, {nPage, szBack, szArg}},
		{"Tho¸t", HideBox_Exit}
	}
	CreateNewSayEx(szMsg, tbOpt)
end

function HideBox_ConfirmWithdraw(nIndex, nPage, szBack, szArg)
	local tbList = HideBox_GetList()
	local tb = tbList[nIndex]
	if not tb then return end
	local tbOpt = {
		{"X¸c nhËn rót", HideBox_Withdraw, {nIndex, nPage, szBack, szArg}},
		{"Kh«ng rót", HideBox_ItemDetail, {nIndex, nPage, szBack, szArg}}
	}
	CreateNewSayEx("X¸c nhËn rót "..HideBox_ItemNameText(tb).." ra khái Hép CÊt GiÊu?", tbOpt)
end

function HideBox_ConfirmSellStoredItem(nIndex, nPage, szBack, szArg)
	local tbList = HideBox_GetList()
	local tb = tbList[nIndex]
	if not tb then return end
	local nSellPrice = HideBox_GetStoredItemSellPrice(tb)
	local tbOpt = {
		{"X¸c nhËn b¸n", HideBox_SellStoredItem, {nIndex, nPage, szBack, szArg, nSellPrice}},
		{"Kh«ng b¸n", HideBox_ItemDetail, {nIndex, nPage, szBack, szArg}}
	}
	CreateNewSayEx("X¸c nhËn b¸n "..HideBox_ItemNameText(tb).." trong Hép CÊt GiÊu?\nNhËn ®­îc: <color=yellow>"..nSellPrice.."<color> ng©n l­îng.", tbOpt)
end

function HideBox_SellStoredItem(nIndex, nPage, szBack, szArg, nSellPrice)
	local tbList = HideBox_GetList()
	local tb = tbList[nIndex]
	if not tb then
		Say("VËt phÈm kh«ng tån t¹i.", 0)
		return
	end
	nSellPrice = tonumber(nSellPrice) or HideBox_GetStoredItemSellPrice(tb)
	tremove(tbList, nIndex)
	if HideBox_Save() ~= 1 then
		for i = getn(tbList) + 1, nIndex + 1, -1 do
			tbList[i] = tbList[i - 1]
		end
		tbList[nIndex] = tb
		Say("Ghi d÷ liÖu hép thÊt b¹i, kh«ng b¸n vËt phÈm.", 0)
		return
	end
	if nSellPrice > 0 then Earn(nSellPrice) end
	Msg2Player("§· b¸n "..HideBox_ItemNameText(tb).." trong Hép CÊt GiÊu, nhËn <color=yellow>"..nSellPrice.."<color> ng©n l­îng.")
	HideBox_Log("SELL_STORED", tb.szName..","..nSellPrice)
	HideBox_ReturnPage(nPage, szBack, szArg)
end

function HideBox_Withdraw(nIndex, nPage, szBack, szArg)
	local tbList = HideBox_GetList()
	local tb = tbList[nIndex]
	if not tb then
		Say("VËt phÈm kh«ng tån t¹i.", 0)
		return
	end
	if CalcFreeItemCellCount and CalcFreeItemCellCount() < 1 then
		Say("Hµnh trang kh«ng ®ñ chç trèng. CÇn Ýt nhÊt 1 « trèng.", 0)
		return
	end
	local nItemIndex, nAddedDirect = HideBox_AddStoredItemToPlayer(tb)
	if not nItemIndex or nItemIndex <= 0 then
		Say("T¹o l¹i vËt phÈm thÊt b¹i. D÷ liÖu vÉn ®­îc gi÷ trong hép.", 0)
		return
	end
	if nAddedDirect ~= 1 then
		AddItemByIndex(nItemIndex)
	end
	tremove(tbList, nIndex)
	HideBox_Save()
	Msg2Player("§· rót "..HideBox_ItemNameText(tb).." khái Hép CÊt GiÊu.")
	HideBox_Log("WITHDRAW", tb.szName)
	HideBox_ReturnPage(nPage, szBack, szArg)
end

function HideBox_ReturnPage(nPage, szBack, szArg)
	if szBack == "group" then
		HideBox_ShowGroupByKey(szArg[1], szArg[2], nPage, szArg[3], szArg[4], szArg[5])
	elseif szBack == "goldset" then
		HideBox_ShowGoldSet(szArg, nPage)
	elseif szBack == "category" then
		HideBox_ShowCategory(szArg, nPage)
	else
		HideBox_ShowList(nPage)
	end
end

function HideBox_Log(szAction, szInfo)
	local f = openfile("Logs/hide_box.log", "a")
	if not f then return end
	write(f, GetLocalDate("%Y-%m-%d %H:%M:%S").."\t"..GetAccount().."\t"..GetName().."\t"..szAction.."\t"..tostring(szInfo).."\n")
	closefile(f)
end

function HideBox_Exit()
end

function OnCancel()
end
