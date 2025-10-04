local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- [challengeMapID] = {mapID, LFGDungeonID, displayName, portalSpellID},
MP.database = {
    ---AUTO_GENERATED LEADING MythicPlusDatabase
    -- Wrath of the Lich King
    [556] = {658, 253, nil, 1254555}, -- Pit of Saron

    -- Cataclysm
    [438] = {657, 311, "VP", 410080}, -- The Vortex Pinnacle
    [456] = {643, 302, "TOTT", 424142}, -- Throne of the Tides
    [507] = {670, 304, "GB", 445424}, -- Grim Batol
    [541] = {725, 307}, -- The Stonecore

    -- Mists of Pandaria
    [2] = {960, 464, "TJS", 131204}, -- Temple of the Jade Serpent
    [56] = {961, 465, nil, 131205}, -- Stormstout Brewery
    [57] = {962, 471, nil, 131225}, -- Gate of the Setting Sun
    [58] = {959, 466, nil, 131206}, -- Shado-Pan Monastery
    [59] = {1011, 554, nil, 131228}, -- Siege of Niuzao Temple
    [60] = {994, 467, nil, 131222}, -- Mogu'shan Palace
    [76] = {1007, 2, nil, 131232}, -- Scholomance
    [77] = {1001, 163, nil, 131231}, -- Scarlet Halls
    [78] = {1004, 164, nil, 131229}, -- Scarlet Monastery

    -- Warlords of Draenor
    [161] = {1209, 779, nil, 1254557}, -- Skyreach
    [163] = {1175, 787, nil, 159895}, -- Bloodmaul Slag Mines
    [164] = {1182, 820, nil, 159897}, -- Auchindoun
    [165] = {1176, 783, "SBG", 159899}, -- Shadowmoon Burial Grounds
    [166] = {1208, 822, "GD", 159900}, -- Grimrail Depot
    [167] = {1358, 330, nil, 159902}, -- Upper Blackrock Spire
    [168] = {1279, 824, "EB", 159901}, -- The Everbloom
    [169] = {1195, 765, "ID", 159896}, -- Iron Docks

    -- Legion
    [197] = {1456, 1174, "EOA"}, -- Eye of Azshara
    [198] = {1466, 1201, "DHT", 424163}, -- Darkheart Thicket
    [199] = {1501, 1204, "BRH", 424153}, -- Black Rook Hold
    [200] = {1477, 1193, "HOV", 393764}, -- Halls of Valor
    [206] = {1458, 1206, "NL", 410078}, -- Neltharion's Lair
    [207] = {1493, 1043, "VOTW"}, -- Vault of the Wardens
    [208] = {1492, 1191, "MOS"}, -- Maw of Souls
    [209] = {1516, 1189, "ARC"}, -- The Arcway
    [210] = {1571, 1318, "COS", 393766}, -- Court of Stars
    [227] = {1651, 1474, "LOWR", 373262}, -- Return to Karazhan: Lower
    [233] = {1677, 1488, "COEN"}, -- Cathedral of Eternal Night
    [234] = {1651, 1474, "UPPR", 373262}, -- Return to Karazhan: Upper
    [239] = {1753, 1535, "SEAT", 1254551}, -- Seat of the Triumvirate

    -- Battle for Azeroth
    [244] = {1763, 1668, "AD", 424187}, -- Atal'Dazar
    [245] = {1754, 1672, "FH", 410071}, -- Freehold
    [246] = {1771, 1713, "TD"}, -- Tol Dagor
    [247] = {1594, 1707, "ML", 467555}, -- The MOTHERLODE!!
    [248] = {1862, 1705, "WM", 424167}, -- Waycrest Manor
    [249] = {1762, 1785, "KR"}, -- Kings' Rest
    [250] = {1877, 1694, "TOS"}, -- Temple of Sethraliss
    [251] = {1841, 1711, "UNDR", 410074}, -- The Underrot
    [252] = {1864, 1710, "SOTS"}, -- Shrine of the Storm
    [353] = {1822, 1700, "SIEGE", 464256}, -- Siege of Boralus
    [369] = {2097, 2006, "YARD", 373274}, -- Operation: Mechagon - Junkyard
    [370] = {2097, 2006, "WORK", 373274}, -- Operation: Mechagon - Workshop

    -- Shadowlands
    [375] = {2290, 2072, "MISTS", 354464}, -- Mists of Tirna Scithe
    [376] = {2286, 2070, "NW", 354462}, -- The Necrotic Wake
    [377] = {2291, 2080, "DOS", 354468}, -- De Other Side
    [378] = {2287, 2074, "HOA", 354465}, -- Halls of Atonement
    [379] = {2289, 2062, "PF", 354463}, -- Plaguefall
    [380] = {2284, 2082, "SD", 354469}, -- Sanguine Depths
    [381] = {2285, 2076, "SOA", 354466}, -- Spires of Ascension
    [382] = {2293, 2078, "TOP", 354467}, -- Theater of Pain
    [391] = {2441, 2225, "STRT", 367416}, -- Tazavesh: Streets of Wonder
    [392] = {2441, 2225, "GMBT", 367416}, -- Tazavesh: So'leah's Gambit

    -- Dragonflight
    [399] = {2521, 2360, "RLP", 393256}, -- Ruby Life Pools
    [400] = {2516, 2368, "NO", 393262}, -- The Nokhud Offensive
    [401] = {2515, 2332, "AV", 393279}, -- The Azure Vault
    [402] = {2526, 2366, "AA", 393273}, -- Algeth'ar Academy
    [403] = {2451, 2352, "ULD", 393222}, -- Uldaman: Legacy of Tyr
    [404] = {2519, 2356, "NELT", 393276}, -- Neltharus
    [405] = {2520, 2362, "BH", 393267}, -- Brackenhide Hollow
    [406] = {2527, 2364, "HOI", 393283}, -- Halls of Infusion
    [463] = {2579, 2430, "FALL", 424197}, -- Dawn of the Infinite: Galakrond's Fall
    [464] = {2579, 2430, "RISE", 424197}, -- Dawn of the Infinite: Murozond's Rise

    -- The War Within
    [499] = {2649, 2695, "PSF", 445444}, -- Priory of the Sacred Flame
    [500] = {2648, 2637, "ROOK", 445443}, -- The Rookery
    [501] = {2652, 2693, "SV", 445269}, -- The Stonevault
    [502] = {2669, 2642, "COT", 445416}, -- City of Threads
    [503] = {2660, 2604, "ARAK", 445417}, -- Ara-Kara, City of Echoes
    [504] = {2651, 2518, "DFC", 445441}, -- Darkflame Cleft
    [505] = {2662, 2523, "DAWN", 445414}, -- The Dawnbreaker
    [506] = {2661, 2689, "BREW", 445440}, -- Cinderbrew Meadery
    [525] = {2773, 2791, "FLOOD", 1216786}, -- Operation: Floodgate
    [542] = {2830, 2987, "EDA", 1237215}, -- Eco-Dome Al'dani

    -- Midnight
    [557] = {2805, 2739, nil, 1254400}, -- Windrunner Spire
    [558] = {2811, 3067, nil, 1254572}, -- Magisters' Terrace
    [559] = {2915, 3056, nil, 1254563}, -- Nexus-Point Xenas
    [560] = {2874, 3097, nil, 1254559}, -- Maisara Caverns
    ---AUTO_GENERATED TAILING MythicPlusDatabase
}

-- Considering Siege of Boralus is the only dungeon that
-- has different entrance and teleport spell id for Alliance and Horde,
-- it's better to set the mapID here than in the builder.
-- EDIT: The MOTHERLODE!! also has different teleport spell id.
if E.myfaction == 'Alliance' then
    MP.database[247][4] = 467553 -- The MOTHERLODE!!
    MP.database[353][4] = 445418 -- Siege of Boralus
elseif E.myfaction == 'Horde' then
    MP.database[247][4] = 467555 -- The MOTHERLODE!!
    MP.database[353][4] = 464256 -- Siege of Boralus
end
