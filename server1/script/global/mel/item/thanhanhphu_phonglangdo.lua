-- Mo rong Than Hanh Phu: dua nguoi choi den khu bao danh
-- Phong Lang Do Thuy Tac trong Hoi Quan Vo Lam.
--
-- File nay duoc nap tu playerlist.lua vi file Than Hanh Phu goc dung
-- bang ma TCVN3. Hook chi tac dong dung menu co nut gototown.

function THP_PLD_GotoSignUp()
	if SubWorldID2Idx(1010) < 0 then
		Msg2Player("Khu bao danh Phong Lang Do hien chua duoc mo.")
		return
	end

	RemoteExc("\\script\\startmissions.lua", "PhongLangDoThuyTac")

	-- Ba Thuyen Phu dung quanh:
	-- thuyen 1: 1787,3431; thuyen 2: 1791,3427; thuyen 3: 1795,3423.
	NewWorld(1010, 1791, 3429)
	SetFightState(0)
	Msg2Player("Da den khu bao danh Phong Lang Do Thuy Tac.")
end

function THP_PLD_CreateNewSayEx(szTitle, tbOpt)
	if gototown ~= nil and tbOpt ~= nil and tbOpt[1] ~= nil and
	   tbOpt[1][2] == gototown then
		local nCount = getn(tbOpt)
		local tbExit = tbOpt[nCount]

		tbOpt[nCount] = {
			"Di den Phong Lang Do Thuy Tac",
			THP_PLD_GotoSignUp
		}
		tinsert(tbOpt, tbExit)
	end

	return THP_PLD_BaseCreateNewSayEx(szTitle, tbOpt)
end

function THP_PLD_InstallHook()
	if CreateNewSayEx == THP_PLD_CreateNewSayEx then
		return
	end
	if CreateNewSayEx == nil then
		return
	end

	THP_PLD_BaseCreateNewSayEx = CreateNewSayEx
	CreateNewSayEx = THP_PLD_CreateNewSayEx
end

-- playerlist.lua duoc nap rat som luc khoi dong. Cho 5 giay de cac file
-- hoi thoai nap xong, sau do gan hook vao ban CreateNewSayEx cuoi cung.
function THP_PLD_DelayedInstall(nTimerId, nParam)
	THP_PLD_HookTimerId = nil
	THP_PLD_InstallHook()
	print("THP_PLD: da gan menu Phong Lang Do Thuy Tac")
	return 0, 0
end

THP_PLD_InstallHook()

if THP_PLD_HookTimerId == nil then
	THP_PLD_HookTimerId = AddTimer(5 * 18, "THP_PLD_DelayedInstall", 0)
end
