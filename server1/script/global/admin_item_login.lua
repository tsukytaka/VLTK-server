Include("\\script\\global\\nobitaxd\\gm\\admin_auth.lua")
Include("\\script\\global\\nobitaxd\\vdk\\simcity\\login_hook.lua")

function AdminItem_ProcessLogin()
	-- Dang nhap truc tiep vao map khong phat EnterMap tren mot so ban engine.
	-- Goi SimCity tai day de tao dan so ngay khi nhan vat vao game; cac lan
	-- chuyen map sau van do EventSys xu ly nhu ban old/s1.
	if SimCity_ProcessLogin then
		SimCity_ProcessLogin()
	end
	if (tbAdminAuth and tbAdminAuth.ProcessLogin) then
		return tbAdminAuth:ProcessLogin()
	end
	return 0
end
