ITEM_FEATURE_CONFIG_FILE = "\\data\\item_features.ini";
Include("\\script\\global\\nobitaxd\\gm\\maxop.lua")
tbItemFeatureConfig = tbItemFeatureConfig or {};

function tbItemFeatureConfig:Load()
    if (IniFile_Load(ITEM_FEATURE_CONFIG_FILE, ITEM_FEATURE_CONFIG_FILE) == 0) then
        File_Create(ITEM_FEATURE_CONFIG_FILE);
        IniFile_Load(ITEM_FEATURE_CONFIG_FILE, ITEM_FEATURE_CONFIG_FILE);
    end
end

function tbItemFeatureConfig:IsEnabled(szSection, szFeature)
    -- Lenh bai Admin la vat pham cap cao nhat: tai khoan admin luon duoc
    -- dung cac chuc nang cua Cam nang Tan thu, ke ca khi muc starter bi tat.
    if ((szSection == "starter" or strsub(szSection, 1, 8) == "starter.") and
        tbAdminAuth ~= nil and tbAdminAuth.IsAdminAccount ~= nil and tbAdminAuth.IsRoleItemEnabled ~= nil and
        tbAdminAuth:IsAdminAccount(GetAccount()) == 1 and tbAdminAuth:IsRoleItemEnabled() == 1) then
        return 1;
    end
    self:Load();
    local szValue = IniFile_GetData(ITEM_FEATURE_CONFIG_FILE, szSection, szFeature);
    if (szValue == nil or szValue == "") then return 1 end
    return tonumber(szValue) == 1 and 1 or 0;
end

function tbItemFeatureConfig:FilterOptions(tbOptions, szSection, tbKeys, nKeepFirst)
    local tbResult = {};
    nKeepFirst = nKeepFirst or 0;
    for i = 1, getn(tbOptions) do
        if (i <= nKeepFirst) then
            tinsert(tbResult, tbOptions[i]);
        else
            local szKey = tbKeys[i - nKeepFirst];
            if (szKey == nil or szKey == "" or self:IsEnabled(szSection, szKey) == 1) then
                tinsert(tbResult, tbOptions[i]);
            end
        end
    end
    return tbResult;
end
