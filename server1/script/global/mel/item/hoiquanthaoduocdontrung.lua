IncludeLib("SETTING")

----------------------------------------------------------------------------------------------------
--                                  Héi Qu¸n Th¶o D­îc §¬n (trung)                                --
----------------------------------------------------------------------------------------------------
function HoiQuanThaoDuocDon_ClearStates()
	RemoveSkillState(1301)
	RemoveSkillState(1252)
	RemoveSkillState(1253)
	RemoveSkillState(1256)
	RemoveSkillState(1257)
	RemoveSkillState(1319)
	RemoveSkillState(1320)
end

function main()
	HoiQuanThaoDuocDon_ClearStates()
	AddSkillState(1319, 2, 1, 7*24*60*60*18,1)
	local _,nX32,nY32 = GetWorldPos()
	CastSkill(1204, 1, nX32*32, nY32*32)
	Msg2Player("NhËn tr¹ng th¸i håi phôc sinh lùc vµ néi lùc trong vßng 7 ngµy.")
end

function GetDesc(nItemIdx)
    local szDesc = "<color=water>Trong vßng 7 ngµy håi phôc sinh lùc vµ néi lùc<color>\n"
    szDesc = szDesc.."<color=water>Mçi nöa gi©y phôc håi sinh lùc: <color><color=orange>1000 ®iÓm<color>\n"
    szDesc = szDesc.."<color=water>Mçi nöa gi©y phôc håi néi lùc: <color><color=orange>1000 ®iÓm<color>"
    return szDesc
end
