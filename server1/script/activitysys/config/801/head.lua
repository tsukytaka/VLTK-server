Include("\\script\\activitysys\\activity.lua")

pActivity = ActivityClass:new()
pActivity.nId = 801
pActivity.szName = "Simcity"
pActivity.nStartDate = 202400000000
pActivity.nEndDate = 302400010000
pActivity.szDescription = "nil"
pActivity.nGroupId = nil
pActivity.nVersion = 5

 

function pActivity:InitAddNpc()
	Include("\\script\\global\\nobitaxd\\vdk\\main.lua")
	-- SimCity duoc khoi dong trong package login khi co nguoi choi dau tien.
	-- Lam nhu vay chi co mot fighterList/timer va khong dang ky EnterMap lap.
	if SimCity_EnsureInitialized then SimCity_EnsureInitialized() end
end
 

function pActivity:ClearTkNpc()
	Include("\\script\\global\\nobitaxd\\vdk\\main.lua")
    simcity_clearTongKim()
end
