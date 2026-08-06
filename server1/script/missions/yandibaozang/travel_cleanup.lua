-- Clear travel locks left behind when a player changes map without the
-- Viem De mission OnLeave callback being executed.
function YDBZ_ClearStaleTravelLock()
	local nMapId = SubWorldIdx2ID(SubWorld)
	if nMapId >= 851 and nMapId <= 862 then
		return 0
	end

	local nTeamState = GetTask(1853)
	local nViemDeCamp = GetByte(nTeamState, 2)
	local nMissionKey = GetTask(1854)
	if nViemDeCamp <= 0 and nMissionKey <= 0 then
		return 0
	end

	DisabledUseTownP(0)
	SetTaskTemp(200, 0)
	SetLogoutRV(0)
	SetDeathScript("")
	SetDeathType(0)
	SetTask(1853, SetByte(nTeamState, 2, 0))
	SetTask(1854, 0)
	return 1
end
