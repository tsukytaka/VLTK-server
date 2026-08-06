-- ============================================================================
-- control.lua   (ASCII only)   -- cong tac BAT / TAT tinh nang
-- ----------------------------------------------------------------------------
-- CANH BAO VAN HANH - doc truoc khi sua file nay:
--
--   * File nay phai la NOI DUY NHAT dinh nghia cac co ben duoi. Engine `Include`
--     hoat dong theo kieu "dinh-nghia-DAU-TIEN-thang": no KHONG ghi de mot global
--     da ton tai. Neu dat trung ten co o config.lua (hoac trong module) thi gia
--     tri o day bi BO QUA mot cach im lang, rat kho lan ra.
--
--   * Dat co = 0, hoac xoa dong Include control.lua trong head.lua, thi co = nil
--     va module tu coi nhu TAT -> server chay dung nhu ban goc. Luon lui duoc.
-- ============================================================================

-- Loi dai 1v1 nguoi-vs-bot tai NPC Cong Binh Tu (components/ploidai.lua).
-- 1 = bat, 0 = tat (cong o Cong Binh Tu tra ve luong goc nguoi-vs-nguoi).
BOTDUEL_ENABLED = (SIMCITY_DUEL_ENABLED == 1 and SIMCITY_DUEL_BOT_ENABLED == 1) and 1 or 0
