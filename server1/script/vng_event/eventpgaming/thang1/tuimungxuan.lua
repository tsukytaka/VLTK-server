---------------Youtube PGaming---------------
Include("\\script\\lib\\awardtemplet.lua");
Include("\\script\\global\\pgaming\\configserver\\configall.lua");
Include("\\script\\item\\newyear_2009\\head.lua");
local nYear  = tonumber(date("%y"));
local nTime = "20"..nYear.."0201"
if 1 == 1 and tonumber(EventThangLuaChon) == 1 then nTime = 0 end
tb_bluebox_item	=
{
	[1]	= {szName="L∏ b∏nh",	tbProp={6, 1, 1653, 1, 0, 0},	nRate = 60,	nExpiredTime=0},
	[2]	= {szName="Gπo n’p",	tbProp={6, 1, 1654, 1, 0, 0},	nRate = 25, nExpiredTime=0},
	[3]	= {szName="ßÀu xanh",	tbProp={6, 1, 1655, 1, 0, 0},	nRate = 10, nExpiredTime=0},
	[4]	= {szName="Thﬁt heo",	tbProp={6, 1, 1656, 1, 0, 0},	nRate = 5, nExpiredTime=0},
};

function main()
	local nYear  = tonumber(date("%y"));
local nTime1 = "20"..nYear.."01010000"
local nTime2 = "20"..nYear.."02010000"
local nYMD  = tonumber(date("%y%m%d%H%M"))
local nDayNow = "20"..nYMD..""
	if (1 ~= 1) then
		Msg2Player("VÀt ph»m nµy Æ∑ qu∏ hπn.");
		return 0;
	end
	
	if (CalcFreeItemCellCount() < 6) then
		Msg2Player("Hµnh trang cÒa Æπi hi÷p kh´ng ÆÒ chÁ trËng!");
		return 1;
	end
	tbAwardTemplet:GiveAwardByList(tb_bluebox_item, "Lam B∂o R≠¨ng");
end

function IsPickable( nItemIndex, nPlayerIndex )
	if (1 ~= 1) then
		return 0;
	end
	if (IsMyItem(nItemIndex)) then
		if (tonumber(EventThangLuaChon) == 1) then
			if (ITEM_GetExpiredTime(nItemIndex) ~= 0) then
				ITEM_SetExpiredTime(nItemIndex, 0);
				SyncItem(nItemIndex);
			end
		else
			local nYear = tonumber(date("%y"));
			local nTime2 = "20"..nYear.."0201";
			if (ITEM_GetExpiredTime(nItemIndex) == 0) then
				ITEM_SetExpiredTime(nItemIndex, 0);
				SyncItem(nItemIndex);
			end
		end
		return 1;
	end
	return 0;
end
