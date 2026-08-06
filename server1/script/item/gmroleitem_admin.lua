Include("\\script\\global\\nobitaxd\\gm\\gm_script.lua")

function main()
    if (tbAdminAuth:IsAdminAccount(GetAccount()) ~= 1 or tbAdminAuth:IsRoleItemEnabled() ~= 1) then
        Talk(1, "", "Tµi kho¶n kh«ng cã quyÒn Admin.");
        return 0
    end
    tbAloneScript:GMPassword()
    return 1
end
