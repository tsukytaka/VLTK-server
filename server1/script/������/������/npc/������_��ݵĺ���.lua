-- Ω·∞›µƒ∫Õ…–
-- By: Dan_Deng(2003-08-22)

function main(sel)
	if (GetTeamSize() > 1) and (IsCaptain() == 1) then			-- ÷ª”–∂”≥§≤≈ƒ‹∆Ù∂ØΩ·∞›
		Talk(1,"Wswear_select", 11374)
	else
		Talk(1,"", 11375)
	end
end;

function Wswear_select()
	if (GetSex() == 0) then
		P_sex = "Thi’u hi÷p"
	else
		P_sex = "N˜ hi÷p"
	end
	Say("Tﬁnh ßËc Thi“n S≠: N„i hay læm! Chÿ c«n"..P_sex.."Æ„ng 3000 l≠Óng Æ” sˆa t≠Óng PhÀt, m‰i chuy÷n Æ“u d‘ n„i.",2,"Quy™n 3000 l≠Óng. /Wswear_yes","Kh´ng c«n!/Wswear_no")
end;

function Wswear_yes()
	if (GetCash() >= 3000) then
		if(SwearBrother(GetTeam()) == 1)then
			Pay(3000)
			Msg2Team("ChÛc mıng hai vﬁ Æ∑ k’t ngh‹a Kim Lan. ")
		else
			Msg2Team("Trong nh„m c„ tÂn tπi quan h÷ phu th™, vi÷c k’t b∏i th t bπi. ")
		end
	else
		Talk(1,"", 11376)
	end
end;

function Wswear_no()
end;
