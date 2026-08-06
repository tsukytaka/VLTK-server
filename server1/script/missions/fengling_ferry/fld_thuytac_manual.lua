-- Mo Phong Lang Do Thuy Tac ngoai khung gio co dinh.

Include("\\script\\missions\\fengling_ferry\\fldmap_boat1.lua")

PLD_THUYTAC_FORCE_UNTIL = PLD_THUYTAC_FORCE_UNTIL or 0
PLD_THUYTAC_FORCE_TIMER = PLD_THUYTAC_FORCE_TIMER or 0

function PLD_ThuyTacForcedCheck()
	if GetCurServerTime() <= PLD_THUYTAC_FORCE_UNTIL then
		return 1
	end
	return 0
end

function PLD_StopThuyTacForce(nTimerId, nParam)
	local nRemain = PLD_THUYTAC_FORCE_UNTIL - GetCurServerTime()
	if nRemain > 0 then
		return nRemain * 18, 0
	end

	if PLD_THUYTAC_NormalCheck ~= nil then
		check_new_shuizeitask = PLD_THUYTAC_NormalCheck
	end
	PLD_THUYTAC_FORCE_TIMER = 0
	return 0, 0
end

function PLD_StartThuyTacManual()
	-- Neu chuyen Thuy Tac thu cong van dang mo, chi giu lai che do
	-- dac biet; khong dong/mo mission va reset thoi gian bao danh.
	if PLD_THUYTAC_FORCE_UNTIL > GetCurServerTime() then
		check_new_shuizeitask = PLD_ThuyTacForcedCheck
		return
	end

	if check_new_shuizeitask ~= PLD_ThuyTacForcedCheck then
		PLD_THUYTAC_NormalCheck = check_new_shuizeitask
	end

	-- Bao danh 5 phut, di thuyen 15 phut, them 5 phut du phong.
	PLD_THUYTAC_FORCE_UNTIL = GetCurServerTime() +
		(ThoiGianBaoDanhPLD + ThoiGianDiThuyenPLD + 5) * 60
	check_new_shuizeitask = PLD_ThuyTacForcedCheck

	fenglingdu_main()

	-- OpenMission co the Include lai fld_head.lua, nen gan lai sau khi mo.
	check_new_shuizeitask = PLD_ThuyTacForcedCheck

	if PLD_THUYTAC_FORCE_TIMER == 0 then
		PLD_THUYTAC_FORCE_TIMER = AddTimer(
			(ThoiGianBaoDanhPLD + ThoiGianDiThuyenPLD + 5) * 60 * 18,
			"PLD_StopThuyTacForce",
			0
		)
	end
end
