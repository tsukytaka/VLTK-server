---------------Youtube PGaming---------------
Include("\\script\\lib\\awardtemplet.lua");
Include("\\script\\item\\newyear_2009\\head.lua");
local nYear  = tonumber(date("%y"));
local nTime = "20"..nYear.."1001"
tb_bluebox_item	=
{
	[1]	= {szName="M¶nh b¶n ®å 1",	tbProp={4, 490, 1, 0, 0, 0},	nRate = 10},
	[2]	= {szName="M¶nh b¶n ®å 2",	tbProp={4, 491, 1, 0, 0, 0},	nRate = 10},
	[3]	= {szName="M¶nh b¶n ®å 3",	tbProp={4, 492, 1, 0, 0, 0},	nRate = 10},
	[4]	= {szName="M¶nh b¶n ®å 4",	tbProp={4, 493, 1, 0, 0, 0},	nRate = 10},
	[5]	= {szName="M¶nh b¶n ®å 5",	tbProp={4, 494, 1, 0, 0, 0},	nRate = 10},
	[6]	= {szName="M¶nh b¶n ®å 6",	tbProp={4, 495, 1, 0, 0, 0},	nRate = 10},
	[7]	= {szName="M¶nh b¶n ®å 7",	tbProp={4, 496, 1, 0, 0, 0},	nRate = 10},
	[8]	= {szName="M¶nh b¶n ®å 8",	tbProp={4, 497, 1, 0, 0, 0},	nRate = 5},
	[9]	= {szName="M¶nh b¶n ®å 9",	tbProp={4, 498, 1, 0, 0, 0},	nRate = 5},
	[10]	= {szName="M¶nh b¶n ®å 10",	tbProp={4, 499, 1, 0, 0, 0},	nRate = 5},
	[11]	= {szName="M¶nh b¶n ®å 11",	tbProp={4, 500, 1, 0, 0, 0},	nRate = 5},
	[12]	= {szName="M¶nh b¶n ®å 12",	tbProp={4, 501, 1, 0, 0, 0},	nRate = 5},
	[13]	= {szName="huy ch­¬ng quèc kh¸nh",	tbProp={6, 1, 1496, 1, 0, 0},	nRate = 5, nExpiredTime=0},
};

function main()
local nYear  = tonumber(date("%y"));
local nTime2 = "20"..nYear.."1001"
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
local nTime2 = "20"..nYear.."1001"
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