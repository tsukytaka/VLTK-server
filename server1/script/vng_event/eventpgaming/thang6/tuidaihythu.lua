---------------Youtube PGaming---------------
Include("\\script\\lib\\awardtemplet.lua");
Include("\\script\\item\\newyear_2009\\head.lua");
local nYear  = tonumber(date("%y"));
local nTime = "20"..nYear.."0701"

tb_bluebox_item	=
{
	[1]	= {szName="Mõng",	tbProp={6, 1, 1752, 1, 0, 0},	nRate = 25,nExpiredTime=0},
	[2]	= {szName="VLTK",	tbProp={6, 1, 1753, 1, 0, 0},	nRate = 25,nExpiredTime=0},
	[3]	= {szName="3",	tbProp={6, 1, 1754, 1, 0, 0},	nRate = 25, nExpiredTime=0},
	[4]	= {szName="Tuæi",	tbProp={6, 1, 1755, 1, 0, 0},	nRate = 25, nExpiredTime=0},
};

function main()
local nYear  = tonumber(date("%y"));
local nTime2 = "20"..nYear.."0701"
local nYMD  = tonumber(date("%y%m%d%H%M"))
local nDayNow = "20"..nYMD..""
	if (1 ~= 1) then
		Msg2Player("VËt phÈm nµy ®· qu¸ h¹n.");
		return 0;
	end
	
	if (CalcFreeItemCellCount() < 6) then
		Msg2Player("Hµnh trang cña ®¹i hiÖp kh«ng ®ñ chç trèng!");
		return 1;
	end
	tbAwardTemplet:GiveAwardByList(tb_bluebox_item, "Bao L× X×");
end

function IsPickable( nItemIndex, nPlayerIndex )
local nYear  = tonumber(date("%y"));
local nTime = "20"..nYear.."0701"
local nYMD  = tonumber(date("%y%m%d%H%M"))
local nDayNow = "20"..nYMD..""
	if (1 ~= 1) then
		return 0;
	end
	if( IsMyItem( nItemIndex ) ) then
		if (ITEM_GetExpiredTime(nItemIndex) ~= 0) then
			ITEM_SetExpiredTime(nItemIndex, 0);
			SyncItem(nItemIndex);
		end
		return 1;
	end
end