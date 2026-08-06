Include("\\script\\dailogsys\\dailogsay.lua")
Include("\\script\\global\\quochuy\\item\\mailbox\\hopthu.lua")
Include("\\script\\global\\quochuy\\chucnang\\hide_box.lua")
function main()
        dofile("script/global/quochuy/item/homcongduc.lua")
		OnMenu()
    return 1
end

function OnMenu()
    local charName = GetName()
    local szText = "Chµo!"..charName
    local tbOpt = {
        {"1. Hép tïy th©n", HideBox_Main},
        {"2. Hép th­", OnMailMenu},
        {"Tho¸t", OnCancel}
    }
    CreateNewSayEx(szText, tbOpt)
end