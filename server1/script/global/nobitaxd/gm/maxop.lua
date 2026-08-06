IncludeLib("FILESYS")
IncludeLib("ITEM")

MAXOP_LOG_FILE = "/home/jxser/log/maxop_item.log"
MAXOP_MAGIC_FILE = "\\settings\\item\\004\\magicattrib.txt"
MAXOP_ITEM_VERSION = 4
MAXOP_ITEM_QUALITY = 0
MAXOP_ITEM_LUCK = 255
MAXOP_MAGIC_LEVEL = 10
MAXOP_MAX_LINES = 6
MAXOP_MAX_COUNT = 10
if (MAXOP_SEED_SERIAL == nil) then MAXOP_SEED_SERIAL = 0 end
if (MAXOP_MAGIC_MAX_CACHE == nil) then MAXOP_MAGIC_MAX_CACHE = {} end

function MaxOp_IsAdmin()
	if (tbAdminAuth and tbAdminAuth:IsAdminAccount(GetAccount()) == 1) then return 1 end
	return 0
end

function MaxOp_AppendLog(szLine)
	local hFile = openfile(MAXOP_LOG_FILE, "a+")
	if (hFile ~= nil) then
		write(hFile, szLine.."\n")
		closefile(hFile)
		return 1
	end
	return 0
end

function MaxOp_Back()
	if (tbAloneScript and tbAloneScript.AdminSupportItems) then tbAloneScript:AdminSupportItems() end
end

function MaxOp_ParseSix(szParam)
	if (szParam == nil or szParam == "") then return nil end
	local tbRaw = split(szParam, ",")
	if (getn(tbRaw) ~= 6) then return nil end
	local tbNum = {}
	for i = 1, 6 do
		tbNum[i] = tonumber(tbRaw[i])
		if (tbNum[i] == nil) then return nil end
	end
	return tbNum
end

function MaxOp_Validate(tbNum)
	if (tbNum == nil) then return 0, "Sai dinh dang. Can dung 6 so cach nhau bang dau phay." end
	if (tbNum[1] ~= 0) then return 0, "Genre phai bang 0." end
	if (tbNum[2] < 0 or tbNum[2] > 9) then return 0, "Detail trang bi phai tu 0 den 9." end
	if (tbNum[3] < 0 or tbNum[3] > 50000) then return 0, "Particular khong hop le." end
	if (tbNum[4] < 1 or tbNum[4] > 20) then return 0, "Level phai tu 1 den 20." end
	if (tbNum[5] < 0 or tbNum[5] > 4) then return 0, "Series phai tu 0 den 4." end
	if (tbNum[6] < 1 or tbNum[6] > MAXOP_MAX_COUNT) then return 0, "Count phai tu 1 den 10." end
	return 1, ""
end

function MaxOp_LoadMagicTable()
	TabFile_Load(MAXOP_MAGIC_FILE, MAXOP_MAGIC_FILE)
end

function MaxOp_GetMagicMaximum(nMagicID)
	local tbCached = MAXOP_MAGIC_MAX_CACHE[nMagicID]
	if (tbCached ~= nil) then return tbCached end
	local nRows = TabFile_GetRowCount(MAXOP_MAGIC_FILE)
	if (nRows == nil or nRows < 2) then return nil end
	local tbBest = nil
	for nRow = 2, nRows do
		local nLevel = tonumber(TabFile_GetCell(MAXOP_MAGIC_FILE, nRow, 4, -1))
		local nID = tonumber(TabFile_GetCell(MAXOP_MAGIC_FILE, nRow, 5, -1))
		if (nLevel == MAXOP_MAGIC_LEVEL and nID == nMagicID) then
			local tbNow = {
				tonumber(TabFile_GetCell(MAXOP_MAGIC_FILE, nRow, 7, -1)) or -1,
				tonumber(TabFile_GetCell(MAXOP_MAGIC_FILE, nRow, 9, -1)) or -1,
				tonumber(TabFile_GetCell(MAXOP_MAGIC_FILE, nRow, 11, -1)) or -1,
			}
			if (tbBest == nil) then
				tbBest = tbNow
			else
				for i = 1, 3 do
					if (tbNow[i] > tbBest[i]) then tbBest[i] = tbNow[i] end
				end
			end
		end
	end
	MAXOP_MAGIC_MAX_CACHE[nMagicID] = tbBest
	return tbBest
end

function MaxOp_ParamIsMaximum(nValue, nMaximum)
	if (nMaximum == nil or nMaximum < 0) then return 1 end
	if (nValue == nMaximum) then return 1 end
	return 0
end

function MaxOp_VerifyItem(nItemIndex)
	local tbLevels = GetItemAllParams(nItemIndex)
	if (tbLevels == nil) then return 0, "Khong doc duoc magic-level" end
	for i = 1, MAXOP_MAX_LINES do
		if (tonumber(tbLevels[i]) ~= MAXOP_MAGIC_LEVEL) then
			return 0, format("Dong %d khong o magic-level 10", i)
		end
		local nMagicID, nP1, nP2, nP3 = GetItemMagicAttrib(nItemIndex, i)
		if (nMagicID == nil or nMagicID <= 0) then
			return 0, format("Thieu option dong %d", i)
		end
		local tbMax = MaxOp_GetMagicMaximum(nMagicID)
		if (tbMax == nil) then
			return 0, format("Khong tim thay MAGIC_ID %d cap 10", nMagicID)
		end
		if (MaxOp_ParamIsMaximum(nP1, tbMax[1]) ~= 1 or MaxOp_ParamIsMaximum(nP2, tbMax[2]) ~= 1 or MaxOp_ParamIsMaximum(nP3, tbMax[3]) ~= 1) then
			return 0, format("Dong %d MAGIC_ID %d chua dat MAX", i, nMagicID)
		end
	end
	return 1, ""
end

function MaxOp_CreateOne(nGenre, nDetail, nParticular, nLevel, nSeries)
	MAXOP_SEED_SERIAL = MAXOP_SEED_SERIAL + 1
	local nSeed = (tonumber(GetLocalDate("%H%M%S")) or 1) + MAXOP_SEED_SERIAL
	local nItemIndex = NewItemEx(
		MAXOP_ITEM_VERSION, nSeed, MAXOP_ITEM_QUALITY,
		nGenre, nDetail, nParticular, nLevel, nSeries, MAXOP_ITEM_LUCK,
		MAXOP_MAGIC_LEVEL, MAXOP_MAGIC_LEVEL, MAXOP_MAGIC_LEVEL,
		MAXOP_MAGIC_LEVEL, MAXOP_MAGIC_LEVEL, MAXOP_MAGIC_LEVEL, 0
	)
	if (nItemIndex == nil or nItemIndex <= 0) then return 0, nSeed, "NewItemEx khong tao duoc item" end
	local nValid, szReason = MaxOp_VerifyItem(nItemIndex)
	if (nValid ~= 1) then
		RemoveItemByIndex(nItemIndex)
		return 0, nSeed, szReason
	end
	if (AddItemByIndex(nItemIndex) <= 0) then
		RemoveItemByIndex(nItemIndex)
		return 0, nSeed, "Khong dua duoc item vao hanh trang"
	end
	SyncItem(nItemIndex)
	return nItemIndex, nSeed, ""
end

function MaxOp_CreateBySpec(nGenre, nDetail, nParticular, nLevel, nSeries, nCount)
	local tbNum = {nGenre, nDetail, nParticular, nLevel, nSeries, nCount}
	local nValid, szError = MaxOp_Validate(tbNum)
	if (nValid ~= 1) then Msg2Player(szError) return 0 end
	if (CalcFreeItemCellCount() < nCount) then Msg2Player("Khong du o trong trong hanh trang.") return 0 end
	MaxOp_LoadMagicTable()
	local nMade = 0
	for i = 1, nCount do
		local nItemIndex, nSeed, szCreateError = MaxOp_CreateOne(nGenre, nDetail, nParticular, nLevel, nSeries)
		if (nItemIndex == nil or nItemIndex <= 0) then
			Msg2Player("Tao MAXOP that bai: "..szCreateError)
			MaxOp_AppendLog(format("TIME=%s ACCOUNT=%s ROLE=%s RESULT=FAILED G=%d D=%d P=%d L=%d S=%d REASON=%s", GetLocalDate("%Y-%m-%d %H:%M:%S"), GetAccount(), GetName(), nGenre, nDetail, nParticular, nLevel, nSeries, szCreateError))
			break
		end
		nMade = nMade + 1
		MaxOp_AppendLog(format("TIME=%s ACCOUNT=%s ROLE=%s RESULT=VERIFIED_MAX ITEM=%s G=%d D=%d P=%d L=%d S=%d SEED=%d INDEX=%d", GetLocalDate("%Y-%m-%d %H:%M:%S"), GetAccount(), GetName(), GetItemName(nItemIndex), nGenre, nDetail, nParticular, nLevel, nSeries, nSeed, nItemIndex))
	end
	Msg2Player(format("Da tao %d/%d trang bi MAXOP 6 dong cap 10.", nMade, nCount))
	return nMade
end

-- Ca Cam nang Tan thu va Lenh bai Admin deu goi ham chung nay.
function laydoxanh4(nIndex, nType, nSeries, nCount)
	local tbEquipSelect = tbDoXanh[nType]["tbEquip"][nIndex]
	if (nCount == nil or nCount < 1) then return 0 end
	return MaxOp_CreateBySpec(tbEquipSelect[2], tbEquipSelect[3], tbEquipSelect[4], 10, nSeries, nCount)
end

function MaxOp_DoCreate(szParam)
	if (MaxOp_IsAdmin() ~= 1) then Msg2Player("Tai khoan khong co quyen Admin.") return 0 end
	local tbNum = MaxOp_ParseSix(szParam)
	local nValid, szError = MaxOp_Validate(tbNum)
	if (nValid ~= 1) then Msg2Player(szError) return 0 end
	return MaxOp_CreateBySpec(tbNum[1], tbNum[2], tbNum[3], tbNum[4], tbNum[5], tbNum[6])
end

function MaxOp_AskCreate()
	g_AskClientStringEx("0,2,28,10,0,1", 1, 96, "Genre,Detail,Particular,Level,Series,Count", {MaxOp_DoCreate, {}})
end

function MaxOp_CreateSampleArmor()
	if (MaxOp_IsAdmin() ~= 1) then Msg2Player("Tai khoan khong co quyen Admin.") return 0 end
	return MaxOp_CreateBySpec(0, 2, 28, 10, 0, 1)
end

function MaxOp_Help()
	local szMsg = "Nhap 6 so cach nhau bang dau phay:<enter>Genre,Detail,Particular,Level,Series,Count<enter><enter>Genre=0. Series: 0 Kim, 1 Moc, 2 Thuy, 3 Hoa, 4 Tho.<enter>Vi du ao cap 10 he Kim: 0,2,28,10,0,1"
	Say(szMsg, 2, "Tao theo ID/MaxOp_AskCreate", "Quay lai/MaxOp_ShowMenu")
end

function MaxOp_ShowMenu()
	if (MaxOp_IsAdmin() ~= 1) then Msg2Player("Tai khoan khong co quyen Admin.") return 0 end
	local tbOpt = {{"Tao trang bi MAXOP theo ID", MaxOp_AskCreate}, {"Tao ao MAXOP mau", MaxOp_CreateSampleArmor}, {"Huong dan thong so", MaxOp_Help}, {"Quay lai", MaxOp_Back}, {"Dong"}}
	CreateNewSayEx("Trang bi MAXOP - 6 dong magic-level 10, MIN = MAX", tbOpt)
	return 1
end

MaxOp_LoadMagicTable()
MaxOp_AppendLog(format("TIME=%s RESULT=MAXOP_NATIVE_ENGINE_LOADED", GetLocalDate("%Y-%m-%d %H:%M:%S")))
