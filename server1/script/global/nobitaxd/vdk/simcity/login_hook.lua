-- Khoi tao SimCity trong script package cua login.
-- Engine JX tach bien global theo package, nen callback dang ky trong Activity
-- khong duoc nhin thay truc tiep tu global/login.lua.
Include("\\script\\global\\nobitaxd\\vdk\\main.lua")

function SimCity_ProcessLogin()
    if SIMCITY_LOGIN_REGISTERED ~= 1 then
        if simcity_addNpcs then simcity_addNpcs() end
        SIMCITY_LOGIN_REGISTERED = 1
    end
    if SimCity_StartLoops then SimCity_StartLoops() end
    if SimCity_EnsureInitialized then SimCity_EnsureInitialized() end
    if SimCityThanhThi and SimCityThanhThi.onPlayerEnterMap then
        return SimCityThanhThi:onPlayerEnterMap()
    end
    return 0
end
