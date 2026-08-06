IncludeLib("SETTING")

----------------------------------------------------------------------------------------------------
--										   Thuèc Héi Qu¸n										  --
----------------------------------------------------------------------------------------------------
function main(itemIdx)
	local _,_,detail = GetItemProp(itemIdx)
	if(detail == 5003) then -- Tèc ®é xuÊt chiªu néi & ngo¹i 20%
		AddSkillState(1302,10,1,18*2700,1)
		return 0
	end
	if(detail == 5004) then -- Phßng thñ vËt lı 30%
		AddSkillState(1303,15,1,18*2700,1)
		return 0
	end
	if(detail == 5005) then -- Kh¸ng ®éc 30%
		AddSkillState(1304,15,1,18*2700,1)
		return 0
	end
	if(detail == 5006) then -- Kh¸ng b¨ng 30%
		AddSkillState(1305,15,1,18*2700,1)
		return 0
	end
	if(detail == 5007) then -- Kh¸ng háa 30%
		AddSkillState(1306,15,1,18*2700,1)
		return 0
	end
	if(detail == 5008) then -- Kh¸ng l«i 30%
		AddSkillState(1307,15,1,18*2700,1)
		return 0
	end
	if(detail == 5009) then -- Thêi gian bŞ th­¬ng / Thêi gian phôc håi 40%
		AddSkillState(1308,20,1,18*2700,1)
		return 0
	end
	if(detail == 5010) then -- Thêi gian cho¸ng 40%
		AddSkillState(1309,20,1,18*2700,1)
		return 0
	end
	if(detail == 5011) then -- Thêi gian tróng ®éc
		AddSkillState(1310,20,1,18*2700,1)
		return 0
	end
	if(detail == 5012) then -- Thêi gian lµm chËm
		AddSkillState(1311,20,1,18*2700,1)
		return 0
	end
	if(detail == 5013) then -- S¸t th­¬ng vËt lı - Ngo¹i c«ng 50% - Néi c«ng 100 ®iÓm
		AddSkillState(1312,10,1,18*2700,1)
		return 0
	end
	if(detail == 5014) then -- §éc s¸t  - Ngo¹i c«ng 10 ®iÓm - Néi c«ng 10 ®iÓm
		AddSkillState(1313,10,1,18*2700,1)
		return 0
	end
	if(detail == 5015) then -- B¨ng s¸t - Ngo¹i c«ng 100 ®iÓm - Néi c«ng 100 ®iÓm
		AddSkillState(1314,10,1,18*2700,1)
		return 0
	end
	if(detail == 5016) then -- Háa s¸t - Ngo¹i c«ng 100 ®iÓm - Néi c«ng 100 ®iÓm
		AddSkillState(1315,10,1,18*2700,1)
		return 0
	end
	if(detail == 5017) then -- L«i s¸t - Ngo¹i c«ng 100 ®iÓm - Néi c«ng 100 ®iÓm
		AddSkillState(1316,10,1,18*2700,1)
		return 0
	end
	if(detail == 5018) then -- Sinh lùc 1000 ®iÓm
		AddSkillState(1317,10,1,18*2700,1)
		return 0
	end
	if(detail == 5019) then -- Néi lùc 1000 ®iÓm
		AddSkillState(1318,10,1,18*2700,1)
		return 0
	end
end

function GetDesc(itemIdx)
	local _,_,detail = GetItemProp(itemIdx)
	if(detail == 5003) then
		return "<color=water>Trong 45 phót:\nTèc ®é xuÊt chiªu ngo¹i c«ng t¨ng <color=orange>20%<color>\nTèc ®é xuÊt chiªu néi c«ng t¨ng <color=orange>20%<color><color>"
	end
	if(detail == 5004) then
		return "<color=water>Trong 45 phót:\nPhßng thñ vËt lı t¨ng <color=orange>30%<color><color>"
	end
	if(detail == 5005) then
		return "<color=water>Trong 45 phót:\nKh¸ng ®éc t¨ng <color=orange>30%<color><color>"
	end
	if(detail == 5006) then
		return "<color=water>Trong 45 phót:\nKh¸ng b¨ng t¨ng <color=orange>30%<color><color>"
	end
	if(detail == 5007) then
		return "<color=water>Trong 45 phót:\nKh¸ng háa t¨ng <color=orange>30%<color><color>"
	end
	if(detail == 5008) then
		return "<color=water>Trong 45 phót:\nKh¸ng l«i t¨ng <color=orange>30%<color><color>"
	end
	if(detail == 5009) then
		return "<color=water>Trong 45 phót:\nThêi gian bŞ th­¬ng gi¶m <color=orange>40%<color><color>"
	end
	if(detail == 5010) then
		return "<color=water>Trong 45 phót:\nThêi gian cho¸ng gi¶m <color=orange>40%<color><color>"
	end
	if(detail == 5011) then
		return "<color=water>Trong 45 phót:\nThêi gian tróng ®éc gi¶m <color=orange>40%<color><color>"
	end
	if(detail == 5012) then
		return "<color=water>Trong 45 phót:\nThêi gian lµm chËm gi¶m <color=orange>40%<color><color>"
	end
	if(detail == 5013) then
		return "<color=water>Trong 45 phót:\nS¸t th­¬ng vËt lı hÖ ngo¹i c«ng t¨ng <color=orange>50%<color>\nS¸t th­¬ng vËt lı hÖ néi c«ng t¨ng <color=orange>100 ®iÓm<color><color>"
	end
	if(detail == 5014) then
		return "<color=water>Trong 45 phót:\n§éc s¸t hÖ ngo¹i c«ng t¨ng <color=orange>10 ®iÓm/lÇn<color>\n§éc s¸t hÖ néi c«ng t¨ng <color=orange>10 ®iÓm/lÇn<color><color>"
	end
	if(detail == 5015) then
		return "<color=water>Trong 45 phót:\nB¨ng s¸t hÖ ngo¹i c«ng t¨ng <color=orange>100 ®iÓm<color>\nB¨ng s¸t hÖ néi c«ng t¨ng <color=orange>100 ®iÓm<color><color>"
	end
	if(detail == 5016) then
		return "<color=water>Trong 45 phót:\nHáa s¸t hÖ ngo¹i c«ng t¨ng <color=orange>100 ®iÓm<color>\nHáa s¸t hÖ néi c«ng t¨ng <color=orange>100 ®iÓm<color><color>"
	end
	if(detail == 5017) then
		return "<color=water>Trong 45 phót:\nL«i s¸t ngo¹i c«ng t¨ng <color=orange>100 ®iÓm<color>\nL«i s¸t néi c«ng t¨ng <color=orange>100 ®iÓm<color><color>"
	end
	if(detail == 5018) then
		return "<color=water>Trong 45 phót:\nSinh lùc lín nhÊt t¨ng <color=orange>1000 ®iÓm<color><color>"
	end
	if(detail == 5019) then
		return "<color=water>Trong 45 phót:\nNéi lùc lín nhÊt t¨ng <color=orange>1000 ®iÓm<color><color>"
	end
end