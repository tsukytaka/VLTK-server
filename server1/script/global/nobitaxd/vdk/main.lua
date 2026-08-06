
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\main.lua")
Include("\\script\\misc\\eventsys\\eventsys.lua")

function add_npc_vinh()
end

function simcity_addNpcs()
	-- Activity 801 la diem khoi dong thuc te. Tao world truoc khi dang ky EnterMap.
	if SimCity_EnsureInitialized then SimCity_EnsureInitialized() end
	SIMCITY_REGISTERED_MAPS = SIMCITY_REGISTERED_MAPS or {}
	-- SimCity: them Trieu Man o 7 thanh
	--SimCityThanhThi:addNpcs()
	
	-- KeoXe: them VoKy o TuongDuong
	--add_dialognpc({ 
	--	{103,78,1619,3251,"\\script\\global\\nobitaxd\\vdk\\simcity\\controllers\\keoxe.lua","V« Kþ"}, 
	--	{103,53,1614,3210,"\\script\\global\\nobitaxd\\vdk\\simcity\\controllers\\keoxe.lua","V« Kþ"},
	--})

	-- VatNuoi: them VatNuoi o TuongDuong
	--SimCityVatNuoi:addNpcs()

	-- Event sys when user enter/leave map
	for id, map in SimCityMap do
		if not SIMCITY_REGISTERED_MAPS[id] then
			EventSys:GetType("EnterMap"):Reg(id, SimCityThanhThi.onPlayerEnterMap, SimCityThanhThi)
			EventSys:GetType("LeaveMap"):Reg(id, SimCityThanhThi.onPlayerExitMap, SimCityThanhThi)
			EventSys:GetType("EnterMap"):Reg(id, SimCityVatNuoi.onPlayerEnterMap, SimCityVatNuoi)
			SIMCITY_REGISTERED_MAPS[id] = 1
		end
	end
	

end

function simcity_clearTongKim()
	SimCityChienTranh:removeAll()
end