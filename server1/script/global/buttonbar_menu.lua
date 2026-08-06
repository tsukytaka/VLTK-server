function ButtonBarMenu_Main()
	Say("TiÖn Ých nhanh", 4,
		"Më r­¬ng chøa ®å/ButtonBarMenu_OpenBox",
		"HiÖu thuèc/ButtonBarMenu_OpenPharmacy",
		"Hßm c«ng ®øc/ButtonBarMenu_OpenDonationBox",
		"§ãng/OnCancel")
end

-- Entry point nhan truc tiep RemoteExecute tu game client.
function ButtonBarMenu_Remote(ParamHandle, ResultHandle)
	ButtonBarMenu_Main()
end

function ButtonBarMenu_OpenBox()
	OpenBox()
end

function ButtonBarMenu_OpenPharmacy()
	Sale(12)
end

function ButtonBarMenu_OpenDonationBox()
	Include("\\script\\global\\quochuy\\item\\homcongduc.lua")
	OnMenu()
end
