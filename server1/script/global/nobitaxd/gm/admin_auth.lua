ADMIN_ACCOUNT_FILE = "\\data\\admin_accounts.ini";
ADMIN_ACCOUNT_TEXT_FILE = "data//admin_accounts.ini";
ADMIN_ROLE_ITEM_FILE = "data//admin_role_items.ini";
ADMIN_ITEM_GENRE = 6;
ADMIN_ITEM_DETAIL = 1;
ADMIN_ITEM_PARTICULAR = 4999;
ADMIN_ITEM_LEVEL = 0;
ADMIN_LEGACY_ITEM_PARTICULAR = 2766;
NEWBIE_GUIDE_GENRE = 6;
NEWBIE_GUIDE_DETAIL = 1;
NEWBIE_GUIDE_PARTICULAR = 6000;
ADMIN_HALO_TITLE_ID = 5000;
ADMIN_HALO_SKILL_ID = 1486;
ADMIN_HALO_SKILL_LEVEL = 20;
ADMIN_HALO_DURATION = 30*24*60*60*18;
ADMIN_HALO_TASK_ID = 3357;
-- 10 giay: du de khoi phuc danh hieu neu bi thay doi, khong tao tai moi tick.
ADMIN_HALO_TIMER_INTERVAL = 18*10;
ADMIN_HALO_TIMERS = ADMIN_HALO_TIMERS or {};

Include("\\script\\global\\item_feature_config.lua");

tbAdminAuth = tbAdminAuth or {};

function tbAdminAuth:NameHex(szName)
    local szHex = "";
    for i = 1, strlen(szName) do
        szHex = szHex .. format("%02X", strbyte(szName, i));
    end
    return szHex;
end

function tbAdminAuth:Load()
    if (IniFile_Load(ADMIN_ACCOUNT_FILE, ADMIN_ACCOUNT_FILE) == 0) then
        File_Create(ADMIN_ACCOUNT_FILE);
        IniFile_Load(ADMIN_ACCOUNT_FILE, ADMIN_ACCOUNT_FILE);
    end
end

function tbAdminAuth:ReadAccountFlag(szSection, szAccount)
    szAccount = strlower(szAccount or "");
    if (szAccount == "") then return 0 end
    local hFile = openfile(ADMIN_ACCOUNT_TEXT_FILE, "r");
    if (hFile == nil) then return 0 end
    local szCurrentSection = "";
    while 1 do
        local szLine = read(hFile, "*l");
        if (szLine == nil) then break end
        if (strsub(szLine, 1, 1) == "[") then
            local nEnd = strfind(szLine, "]");
            if (nEnd ~= nil) then
                szCurrentSection = strsub(szLine, 2, nEnd - 1);
            end
        elseif (szCurrentSection == szSection) then
            local nEq = strfind(szLine, "=");
            if (nEq ~= nil) then
                local szKey = strlower(strsub(szLine, 1, nEq - 1));
                local szValue = strsub(szLine, nEq + 1);
                if (szKey == szAccount) then
                    closefile(hFile);
                    return tonumber(szValue) or 0;
                end
            end
        end
    end
    closefile(hFile);
    return 0;
end

function tbAdminAuth:IsAdminAccount(szAccount)
    szAccount = szAccount or GetAccount() or "";
    szAccount = strlower(szAccount);
    if (szAccount == "") then return 0 end
    local nAdmin = self:ReadAccountFlag("admin", szAccount);
    if (nAdmin == 1) then return 1 end
    return 0;
end

function tbAdminAuth:WasGranted(szAccount)
    szAccount = szAccount or GetAccount() or "";
    szAccount = strlower(szAccount);
    return self:ReadAccountFlag("granted", szAccount);
end

function tbAdminAuth:IsRoleItemEnabled()
    local hFile = openfile(ADMIN_ROLE_ITEM_FILE, "r");
    if (hFile == nil) then return 1 end
    local szAccount = strlower(GetAccount() or "");
    local szRoleHex = self:NameHex(GetName() or "");
    while 1 do
        local szLine = read(hFile, "*l");
        if (szLine == nil) then break end
        if (strsub(szLine, 1, 1) ~= "#") then
            local tb = split(szLine, "|");
            if (getn(tb) >= 4 and strlower(tb[1]) == szAccount and tb[2] == szRoleHex) then
                closefile(hFile);
                if (tonumber(tb[4]) == 0) then return 0 end
                return 1;
            end
        end
    end
    closefile(hFile);
    return 1;
end

function tbAdminAuth:MarkGranted(szAccount)
    -- Khong ghi nguoc bang IniFile_Save de tranh engine luu cache cu de len
    -- thay doi vua thuc hien tu web-admin.
    return 1;
end

function tbAdminAuth:RemoveAdminItems()
    local nCount = CalcEquiproomItemCount(ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_ITEM_PARTICULAR, -1);
    if (nCount and nCount > 0) then
        ConsumeEquiproomItem(nCount, ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_ITEM_PARTICULAR, -1);
    end
    local nLegacyCount = CalcEquiproomItemCount(ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_LEGACY_ITEM_PARTICULAR, -1);
    if (nLegacyCount and nLegacyCount > 0) then
        ConsumeEquiproomItem(nLegacyCount, ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_LEGACY_ITEM_PARTICULAR, -1);
    end
end

function tbAdminAuth:RemoveNewbieGuideItems()
    local nGuideCount = CalcEquiproomItemCount(NEWBIE_GUIDE_GENRE, NEWBIE_GUIDE_DETAIL, NEWBIE_GUIDE_PARTICULAR, -1);
    if (nGuideCount and nGuideCount > 0) then
        ConsumeEquiproomItem(nGuideCount, NEWBIE_GUIDE_GENRE, NEWBIE_GUIDE_DETAIL, NEWBIE_GUIDE_PARTICULAR, -1);
    end
end

-- Vong sang GM chi bat khi GM dung Lenh bai Admin. Timer chi truyen PlayerIndex
-- de tranh crash do AddTimer nhan table param tren engine nay.
function tbAdminAuth:ApplyAdminHalo(nIsAdmin)
    if (nIsAdmin == 1) then
        SetTask(1122, ADMIN_HALO_TITLE_ID);
        Title_AddTitle(ADMIN_HALO_TITLE_ID, 1, ADMIN_HALO_DURATION);
        Title_ActiveTitle(ADMIN_HALO_TITLE_ID);
        if (HaveMagic(ADMIN_HALO_SKILL_ID) < ADMIN_HALO_SKILL_LEVEL) then
            AddMagic(ADMIN_HALO_SKILL_ID, ADMIN_HALO_SKILL_LEVEL);
        end
        AddSkillState(ADMIN_HALO_SKILL_ID, ADMIN_HALO_SKILL_LEVEL, 0, ADMIN_HALO_DURATION);
        if (GetSkillState(ADMIN_HALO_SKILL_ID) < 0) then
            AddSkillState(ADMIN_HALO_SKILL_ID, 1, 0, ADMIN_HALO_DURATION);
        end
        return 1;
    end
    if (GetTask(1122) == ADMIN_HALO_TITLE_ID) then
        SetTask(1122, 0);
    end
    Title_RemoveTitle(ADMIN_HALO_TITLE_ID);
    AddSkillState(ADMIN_HALO_SKILL_ID, ADMIN_HALO_SKILL_LEVEL, 0, 0);
    if (HaveMagic(ADMIN_HALO_SKILL_ID) >= 0) then
        DelMagic(ADMIN_HALO_SKILL_ID);
    end
    return 0;
end

function tbAdminAuth:StartAdminHaloMonitor()
    local nPlayerIndex = PlayerIndex;
    local nOldTimerId = ADMIN_HALO_TIMERS[nPlayerIndex];
    if (nOldTimerId ~= nil and nOldTimerId > 0) then
        DelTimer(nOldTimerId);
    end
    ADMIN_HALO_TIMERS[nPlayerIndex] = AddTimer(ADMIN_HALO_TIMER_INTERVAL, "AdminHalo_Monitor", nPlayerIndex);
    return 1;
end

function tbAdminAuth:StopAdminHaloMonitor()
    SetTask(ADMIN_HALO_TASK_ID, 0);
    local nTimerId = ADMIN_HALO_TIMERS[PlayerIndex];
    if (nTimerId ~= nil and nTimerId > 0) then
        DelTimer(nTimerId);
    end
    ADMIN_HALO_TIMERS[PlayerIndex] = nil;
    return 0;
end

function AdminHalo_Monitor(nPlayerIndex, nTimerId)
    if (nPlayerIndex == nil or nPlayerIndex <= 0) then return 0, 0 end

    -- Ban cu da sinh nhieu timer. Chi timer dau tien duoc giu lai, cac timer
    -- trung se tu ket thuc ngay khi chay callback moi nay.
    if (nTimerId ~= nil and nTimerId > 0) then
        local nActiveTimerId = ADMIN_HALO_TIMERS[nPlayerIndex];
        if (nActiveTimerId ~= nil and nActiveTimerId > 0 and nActiveTimerId ~= nTimerId) then
            return 0, 0;
        end
        ADMIN_HALO_TIMERS[nPlayerIndex] = nTimerId;
    end

    local nOldPlayerIndex = PlayerIndex;
    PlayerIndex = nPlayerIndex;
    if (GetTask(ADMIN_HALO_TASK_ID) == 1 and tbAdminAuth:IsAdminAccount(GetAccount()) == 1 and tbAdminAuth:IsRoleItemEnabled() == 1) then
        if (Title_GetActiveTitle() ~= ADMIN_HALO_TITLE_ID or GetSkillState(ADMIN_HALO_SKILL_ID) < 0 or HaveMagic(ADMIN_HALO_SKILL_ID) < ADMIN_HALO_SKILL_LEVEL) then
            tbAdminAuth:ApplyAdminHalo(1);
        end
        PlayerIndex = nOldPlayerIndex;
        return ADMIN_HALO_TIMER_INTERVAL, nPlayerIndex;
    end
    tbAdminAuth:ApplyAdminHalo(0);
    if (ADMIN_HALO_TIMERS[nPlayerIndex] == nTimerId or nTimerId == nil) then
        ADMIN_HALO_TIMERS[nPlayerIndex] = nil;
    end
    PlayerIndex = nOldPlayerIndex;
    return 0, 0;
end

function tbAdminAuth:IsAdminHaloEnabled()
    if (GetTask(ADMIN_HALO_TASK_ID) == 1) then
        return 1;
    end
    return 0;
end

function tbAdminAuth:IsAdminHaloAutoEnabled()
    local hFile = openfile("data//item_features.ini", "r");
    if (hFile == nil) then return 0 end
    local szCurrentSection = "";
    while 1 do
        local szLine = read(hFile, "*l");
        if (szLine == nil) then break end
        if (strsub(szLine, 1, 1) == "[") then
            local nEnd = strfind(szLine, "]");
            if (nEnd ~= nil) then
                szCurrentSection = strsub(szLine, 2, nEnd - 1);
            end
        elseif (szCurrentSection == "admin.functions") then
            local nEq = strfind(szLine, "=");
            if (nEq ~= nil) then
                local szKey = strlower(strsub(szLine, 1, nEq - 1));
                local szValue = strsub(szLine, nEq + 1);
                szKey = gsub(szKey, " ", "");
                szValue = gsub(szValue, " ", "");
                if (szKey == "halo_auto") then
                    closefile(hFile);
                    if (tonumber(szValue) == 1) then return 1 end
                    return 0;
                end
            end
        end
    end
    closefile(hFile);
    return 0;
end

function tbAdminAuth:ToggleAdminHalo()
    if (self:IsAdminAccount(GetAccount()) ~= 1 or self:IsRoleItemEnabled() ~= 1) then
        self:StopAdminHaloMonitor();
        self:ApplyAdminHalo(0);
        Talk(1, "", "Tµi kho¶n hoÆc nh©n vËt kh«ng cã quyÒn Admin.");
        return 0;
    end
    if (GetTask(ADMIN_HALO_TASK_ID) == 1) then
        self:StopAdminHaloMonitor();
        self:ApplyAdminHalo(0);
        Msg2Player("Da tat vong sang GM.");
        return 0;
    end
    SetTask(ADMIN_HALO_TASK_ID, 1);
    self:ApplyAdminHalo(1);
    self:StartAdminHaloMonitor();
    Msg2Player("Da bat vong sang GM.");
    return 1;
end

function tbAdminAuth:ProcessLogin()
    local szAccount = strlower(GetAccount() or "");
    local nLegacyCount = CalcEquiproomItemCount(ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_LEGACY_ITEM_PARTICULAR, -1);
    if (nLegacyCount and nLegacyCount > 0) then
        ConsumeEquiproomItem(nLegacyCount, ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_LEGACY_ITEM_PARTICULAR, -1);
    end
    local nCount = CalcEquiproomItemCount(ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_ITEM_PARTICULAR, -1);
    local nIsAdmin = self:IsAdminAccount(szAccount);
    local nRoleItemEnabled = self:IsRoleItemEnabled();
    print(format("[AdminAuth] login account=%s is_admin=%d role_item=%d item_count=%s item=%d,%d,%d level=%d", szAccount, nIsAdmin, nRoleItemEnabled, tostring(nCount), ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_ITEM_PARTICULAR, ADMIN_ITEM_LEVEL));
    if (nIsAdmin ~= 1 or nRoleItemEnabled ~= 1) then
        self:ApplyAdminHalo(0);
        self:StopAdminHaloMonitor();
        self:RemoveAdminItems();
        return 0;
    end
    self:RemoveNewbieGuideItems();
    if (self:IsAdminHaloAutoEnabled() == 1) then
        SetTask(ADMIN_HALO_TASK_ID, 1);
    end
    if (GetTask(ADMIN_HALO_TASK_ID) == 1) then
        self:ApplyAdminHalo(1);
        self:StartAdminHaloMonitor();
    else
        self:ApplyAdminHalo(0);
    end

    if (nCount and nCount > 0) then
        self:MarkGranted(szAccount);
        return 1;
    end

    if (CalcFreeItemCellCount() < 1) then
        print(format("[AdminAuth] no free cell account=%s", szAccount));
        Msg2Player("CÇn Ýt nhÊt 1 « trèng ®Ó nhËn LÖnh Bµi Admin.");
        return 0;
    end
    local nItemIndex = AddItem(ADMIN_ITEM_GENRE, ADMIN_ITEM_DETAIL, ADMIN_ITEM_PARTICULAR, ADMIN_ITEM_LEVEL, 0, 0, 0);
    print(format("[AdminAuth] AddItem account=%s result=%s", szAccount, tostring(nItemIndex)));
    if (nItemIndex and nItemIndex > 0) then
        SetItemBindState(nItemIndex, -2);
        self:MarkGranted(szAccount);
        Msg2Player("§· nhËn LÖnh Bµi Admin.");
        return 1;
    end
    return 0;
end
