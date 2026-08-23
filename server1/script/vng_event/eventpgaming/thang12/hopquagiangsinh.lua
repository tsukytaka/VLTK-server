---------------Youtube PGaming---------------
Include("\\script\\lib\\awardtemplet.lua");
Include("\\script\\item\\newyear_2009\\head.lua");
local nYear  = tonumber(date("%y"));
local nYear2  = nYear+1
local nTime = "20"..nYear2.."0101"
tb_bluebox_item	=
{
	[1]	= {szName="Hoa tuyÕt",	tbProp={6, 1, 1312, 1, 0, 0},	nRate = 60,	nExpiredTime=0},
	[2]	= {szName="C¸nh th«ng",	tbProp={6, 1, 1314, 1, 0, 0},	nRate = 10, nExpiredTime=0},
	[3]	= {szName="Cµ rèt",	tbProp={6, 1, 1313, 1, 0, 0},	nRate = 10, nExpiredTime=0},
	[4]	= {szName="Nãn gi¸ng sinh",	tbProp={6, 1, 1315, 1, 0, 0},	nRate = 9, nExpiredTime=0},
	[5]	= {szName="Kh¨n choµng (xanh)",	tbProp={6, 1, 1316, 1, 0, 0},	nRate = 8, nExpiredTime=0},
	[6]	= {szName="Kh¨n choµng (®á)",	tbProp={6, 1, 1317, 1, 0, 0},	nRate = 2, nExpiredTime=0},
	[7]	= {szName="C©y th«ng",	tbProp={6, 1, 1318, 1, 0, 0},	nRate = 1, nExpiredTime=0},
};

function main()
local nYear  = tonumber(date("%y"));
local nYear2  = nYear+1
local nTime2 = "20"..nYear2.."0101"
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
local nYear2  = nYear+1
local nTime2 = "20"..nYear2.."0101"
local nYMD  = tonumber(date("%y%m%d%H%M"))
local nDayNow = "20"..nYMD..""
	local ndate = tonumber(GetLocalDate("%Y%m%d"));
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