NEWBIE_GUIDE_TANTHU_FILE = "data//newbie_guides_tanthu.ini"
NEWBIE_GUIDE_ACCOUNT_FILE = "data//admin_accounts.ini"
NEWBIE_GUIDE_TANTHU_GENRE = 6
NEWBIE_GUIDE_TANTHU_DETAIL = 1
NEWBIE_GUIDE_TANTHU_PARTICULAR = 6000

function NewbieGuideTanThu_NameHex(szName)
	local szHex = ""
	for i = 1, strlen(szName) do szHex = szHex .. format("%02X", strbyte(szName, i)) end
	return szHex
end


function NewbieGuideTanThu_ReadAccountFlag(szSection, szAccount)
	szAccount = strlower(szAccount or "")
	if (szAccount == "") then return 0 end
	local hFile = openfile(NEWBIE_GUIDE_ACCOUNT_FILE, "r")
	if (hFile == nil) then return 0 end
	local szCurrentSection = ""
	while 1 do
		local szLine = read(hFile, "*l")
		if (szLine == nil) then break end
		if (strsub(szLine, 1, 1) == "[") then
			local nEnd = strfind(szLine, "]")
			if (nEnd ~= nil) then szCurrentSection = strsub(szLine, 2, nEnd - 1) end
		elseif (szCurrentSection == szSection) then
			local nEq = strfind(szLine, "=")
			if (nEq ~= nil) then
				local szKey = strlower(strsub(szLine, 1, nEq - 1))
				local szValue = strsub(szLine, nEq + 1)
				if (szKey == szAccount) then
					closefile(hFile)
					return tonumber(szValue) or 0
				end
			end
		end
	end
	closefile(hFile)
	return 0
end

function NewbieGuideTanThu_IsEnabled()
	local szAccount = strlower(GetAccount() or "")
	if (NewbieGuideTanThu_ReadAccountFlag("admin", szAccount) == 1) then return 0 end
	local hFile = openfile(NEWBIE_GUIDE_TANTHU_FILE, "r")
	if (hFile == nil) then return 1 end
	local szRoleHex = NewbieGuideTanThu_NameHex(GetName())
	while 1 do
		local szLine = read(hFile, "*l")
		if (szLine == nil) then break end
		if (strsub(szLine, 1, 1) ~= "#") then
			local tb = split(szLine, "|")
			if (getn(tb) >= 4 and strlower(tb[1]) == szAccount and tb[2] == szRoleHex) then
				closefile(hFile)
				if (tonumber(tb[4]) == 0) then return 0 end
				return 1
			end
		end
	end
	closefile(hFile)
	return 1
end

function NewbieGuideTanThu_ProcessLogin()
	local nCount = CalcEquiproomItemCount(NEWBIE_GUIDE_TANTHU_GENRE, NEWBIE_GUIDE_TANTHU_DETAIL, NEWBIE_GUIDE_TANTHU_PARTICULAR, -1)
	if (NewbieGuideTanThu_IsEnabled() ~= 1) then
		if (nCount and nCount > 0) then
			ConsumeEquiproomItem(nCount, NEWBIE_GUIDE_TANTHU_GENRE, NEWBIE_GUIDE_TANTHU_DETAIL, NEWBIE_GUIDE_TANTHU_PARTICULAR, -1)
		end
		return 0
	end
	if (nCount == nil or nCount == 0) then
		if (CalcFreeItemCellCount() < 1) then Msg2Player("Can it nhat 1 o trong de nhan Cam nang Tan thu.") return end
		local nItemIndex = AddItem(NEWBIE_GUIDE_TANTHU_GENRE, NEWBIE_GUIDE_TANTHU_DETAIL, NEWBIE_GUIDE_TANTHU_PARTICULAR, 1, 0, 0)
		if (nItemIndex and nItemIndex > 0) then SetItemBindState(nItemIndex, -1) Msg2Player("Da nhan Cam nang Tan thu.") end
	end
end
