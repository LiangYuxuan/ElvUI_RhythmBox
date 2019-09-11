local E, L, V, P, G = unpack(ElvUI)
local LSM = E.Libs.LSM
local koKR, ruRU, zhCN, zhTW, western = LSM.LOCALE_BIT_koKR, LSM.LOCALE_BIT_ruRU, LSM.LOCALE_BIT_zhCN, LSM.LOCALE_BIT_zhTW, LSM.LOCALE_BIT_western

-- local MediaType_BACKGROUND = LSM.MediaType.BACKGROUND
local MediaType_BORDER = LSM.MediaType.BORDER
local MediaType_FONT = LSM.MediaType.FONT
-- local MediaType_STATUSBAR = LSM.MediaType.STATUSBAR

-- -----
--   BACKGROUND
-- -----


-- -----
--   BORDER
-- ----
LSM:Register(MediaType_BORDER, "Naowh1", [[Interface\Addons\ElvUI_RhythmBox\Media\Border\Naowh1.tga]])
LSM:Register(MediaType_BORDER, "Naowh2", [[Interface\Addons\ElvUI_RhythmBox\Media\Border\Naowh2.tga]])
LSM:Register(MediaType_BORDER, "Naowh3", [[Interface\Addons\ElvUI_RhythmBox\Media\Border\Naowh3.tga]])

-- -----
--   FONT
-- -----
-- for combat font only, marked with chinese character for convenience
LSM:Register(MediaType_FONT, "GothamNarrowUltra", [[Interface\Addons\ElvUI_RhythmBox\Media\Font\GothamNarrowUltra.ttf]], koKR + ruRU + zhCN + zhTW + western)
LSM:Register(MediaType_FONT, "Naowh",             [[Interface\Addons\ElvUI_RhythmBox\Media\Font\Naowh.ttf]],             koKR + ruRU + zhCN + zhTW + western)

-- -----
--   SOUND
-- -----


-- -----
--   STATUSBAR
-- -----

