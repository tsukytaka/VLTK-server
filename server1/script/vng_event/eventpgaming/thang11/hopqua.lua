---------------Youtube PGaming---------------
Include("\\script\\lib\\awardtemplet.lua");
Include("\\script\\item\\newyear_2009\\head.lua");
local nYear  = tonumber(date("%y"));
local nTime = "20"..nYear.."1201"
tb_bluebox_item	=
{
	[1]	= {szName="T«n",	tbProp={6, 1, 1599, 1, 0, 0},	nRate = 60,	nExpiredTime=0},
	[2]	= {szName="S­",	tbProp={6, 1, 1600, 1, 0, 0},	nRate = 30, nExpiredTime=0},
	[3]	= {szName="Träng",	tbProp={6, 1, 1601, 1, 0, 0},	nRate = 6, nExpiredTime=0},
	[4]	= {szName="§¹o",	tbProp={6, 1, 1602, 1, 0, 0},	nRate = 2, nExpiredTime=0},
	[5]	= {szName="Hoa Hång",	tbProp={6, 0, 20, 1, 0, 0},	nRate = 2, nExpiredTime=0},
};

function main()
local nYear  = tonumber(date("%y"));
local nTime2 = "20"..nYear.."1201"
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
	tbAwardTemplet:GiveAwardByList(tb_bluebox_item, "Lam B¶o R­¬ng");
end

function IsPickable( nItemIndex, nPlayerIndex )
local nYear  = tonumber(date("%y"));
local nTime2 = "20"..nYear.."1201"
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