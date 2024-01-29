local E, L, V, P, G = unpack(ElvUI)
local LSM = E.Libs.LSM
local koKR, ruRU, zhCN, zhTW, western = LSM.LOCALE_BIT_koKR, LSM.LOCALE_BIT_ruRU, LSM.LOCALE_BIT_zhCN, LSM.LOCALE_BIT_zhTW, LSM.LOCALE_BIT_western

local MediaType_FONT = LSM.MediaType.FONT
local MediaType_SOUND = LSM.MediaType.SOUND
local MediaType_STATUSBAR = LSM.MediaType.STATUSBAR

-- -----
--   BACKGROUND
-- -----

-- -----
--   BORDER
-- ----

-- -----
--   FONT
-- -----
do
    -- GothamNarrowUltra + Rhythm and hijack GothamNarrowUltra font in NaowhUI
    local res = LSM:Register(MediaType_FONT, "GothamNarrowUltra", [[Interface\Addons\ElvUI_RhythmBox\Media\Font\GothamNarrowUltra_Round.ttf]], koKR + ruRU + zhCN + zhTW + western)
    if not res then
        local data = LSM:HashTable(MediaType_FONT)
        data["GothamNarrowUltra"] = [[Interface\Addons\ElvUI_RhythmBox\Media\Font\GothamNarrowUltra_Round.ttf]]
    end
end
do
    -- hijack Naowh font in NaowhUI
    local res = LSM:Register(MediaType_FONT, "Naowh", [[Interface\Addons\ElvUI_RhythmBox\Media\Font\Rhythm.ttf]], koKR + ruRU + zhCN + zhTW + western)
    if not res then
        local data = LSM:HashTable(MediaType_FONT)
        data["Naowh"] = [[Interface\Addons\ElvUI_RhythmBox\Media\Font\Rhythm.ttf]]
    end
end

-- -----
--   SOUND
-- -----
LSM:Register(MediaType_SOUND, "Yike: Stop Casting", [[Interface\Addons\ElvUI_RhythmBox\Media\Sound\StopCasting.ogg]])

-- -----
--   STATUSBAR
-- -----
LSM:Register(MediaType_STATUSBAR, "AtlzSkada",   [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\AtlzSkada.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI A",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI A.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI B",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI B.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI D",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI D.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI E",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI E.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI F",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI F.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI G",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI G.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI H",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI H.tga]])
LSM:Register(MediaType_STATUSBAR, "ElvUI P",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\ElvUI P.tga]])
LSM:Register(MediaType_STATUSBAR, "FF_Antonia",  [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FF_Antonia.tga]])
LSM:Register(MediaType_STATUSBAR, "FF_Bettina",  [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FF_Bettina.tga]])
LSM:Register(MediaType_STATUSBAR, "FF_Jasmin",   [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FF_Jasmin.tga]])
LSM:Register(MediaType_STATUSBAR, "FF_Larissa",  [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FF_Larissa.tga]])
LSM:Register(MediaType_STATUSBAR, "FF_Lisa",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FF_Lisa.tga]])
LSM:Register(MediaType_STATUSBAR, "FF_Sam",      [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FF_Sam.tga]])
LSM:Register(MediaType_STATUSBAR, "FF_Stella",   [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FF_Stella.tga]])
LSM:Register(MediaType_STATUSBAR, "FX_001",      [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FX_001.tga]])
LSM:Register(MediaType_STATUSBAR, "FX_002",      [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FX_002.tga]])
LSM:Register(MediaType_STATUSBAR, "FX_003",      [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FX_003.tga]])
LSM:Register(MediaType_STATUSBAR, "FX_004",      [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\FX_004.tga]])
LSM:Register(MediaType_STATUSBAR, "MaoRSkada",   [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\MaoRSkada.tga]])
LSM:Register(MediaType_STATUSBAR, "WindTools_1", [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\WindTools_1.tga]])
LSM:Register(MediaType_STATUSBAR, "WindTools_2", [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\WindTools_2.tga]])
LSM:Register(MediaType_STATUSBAR, "YaSkada05",   [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\YaSkada05.tga]])
LSM:Register(MediaType_STATUSBAR, "Yaskada",     [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\Yaskada.tga]])
LSM:Register(MediaType_STATUSBAR, "Yaskada04",   [[Interface\Addons\ElvUI_RhythmBox\Media\StatusBar\Yaskada04.tga]])
