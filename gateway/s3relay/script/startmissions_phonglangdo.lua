-- Lenh mo Phong Lang Do Thuy Tac thu cong tu menu.
-- File nay duoc Include boi leaguematch/switch.lua khi startmissions.lua nap.

function PhongLangDoThuyTac()
	GlobalExecute("dwf \\script\\missions\\fengling_ferry\\fld_thuytac_manual.lua PLD_StartThuyTacManual()")

	local szMsg = "Phong Lang Do Thuy Tac da bat dau bao danh. Hay den gap Thuyen Phu de tham gia."
	GlobalExecute(format("dw AddLocalCountNews([[%s]], 2)", szMsg))
	GlobalExecute(format("dw Msg2SubWorld([[%s]])", szMsg))
	OutputMsg("===> KHOI DONG PHONG LANG DO THUY TAC [GM]")
end
