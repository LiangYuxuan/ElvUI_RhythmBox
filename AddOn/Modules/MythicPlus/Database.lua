local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- [challengeMapID] = {mapID, LFGDungeonID, displayName, portalSpellID},
MP.database = {
    ---AUTO_GENERATED LEADING MythicPlusDatabase
    -- Cataclysm
    [438] = {657, 68, "VP", 410080}, -- The Vortex Pinnacle
    [456] = {643, 65, "TOTT", 424142}, -- Throne of the Tides
    [507] = {670, 71, "GB", 445424}, -- Grim Batol

    -- Mists of Pandaria
    [2] = {960, 313, "TJS", 131204}, -- Temple of the Jade Serpent
    [56] = {961, 302, nil, 131205}, -- Stormstout Brewery
    [57] = {962, 303, nil, 131225}, -- Gate of the Setting Sun
    [58] = {959, 312, nil, 131206}, -- Shado-Pan Monastery
    [59] = {1011, 324, nil, 131228}, -- Siege of Niuzao Temple
    [60] = {994, 321, nil, 131222}, -- Mogu'shan Palace
    [76] = {1007, 246, nil, 131232}, -- Scholomance
    [77] = {1001, 311, nil, 131231}, -- Scarlet Halls
    [78] = {1004, 316, nil, 131229}, -- Scarlet Monastery

    -- Warlords of Draenor
    [161] = {1209, 476, nil, 159898}, -- Skyreach
    [163] = {1175, 385, nil, 159895}, -- Bloodmaul Slag Mines
    [164] = {1182, 547, nil, 159897}, -- Auchindoun
    [165] = {1176, 537, "SBG", 159899}, -- Shadowmoon Burial Grounds
    [166] = {1208, 536, "GD", 159900}, -- Grimrail Depot
    [167] = {1358, 559, nil, 159902}, -- Upper Blackrock Spire
    [168] = {1279, 556, "EB", 159901}, -- The Everbloom
    [169] = {1195, 558, "ID", 159896}, -- Iron Docks

    -- Legion
    [197] = {1456, 716, "EOA"}, -- Eye of Azshara
    [198] = {1466, 762, "DHT", 424163}, -- Darkheart Thicket
    [199] = {1501, 740, "BRH", 424153}, -- Black Rook Hold
    [200] = {1477, 721, "HOV", 393764}, -- Halls of Valor
    [206] = {1458, 767, "NL", 410078}, -- Neltharion's Lair
    [207] = {1493, 707, "VOTW"}, -- Vault of the Wardens
    [208] = {1492, 727, "MOS"}, -- Maw of Souls
    [209] = {1516, 726, "ARC"}, -- The Arcway
    [210] = {1571, 800, "COS", 393766}, -- Court of Stars
    [227] = {1651, 860, "LOWR", 373262}, -- Return to Karazhan: Lower
    [233] = {1677, 900, "COEN"}, -- Cathedral of Eternal Night
    [234] = {1651, 860, "UPPR", 373262}, -- Return to Karazhan: Upper
    [239] = {1753, 945, "SEAT"}, -- Seat of the Triumvirate

    -- Battle for Azeroth
    [244] = {1763, 968, "AD", 424187}, -- Atal'Dazar
    [245] = {1754, 1001, "FH", 410071}, -- Freehold
    [246] = {1771, 1002, "TD"}, -- Tol Dagor
    [247] = {1594, 1012, "ML"}, -- The MOTHERLODE!!
    [248] = {1862, 1021, "WM", 424167}, -- Waycrest Manor
    [249] = {1762, 1041, "KR"}, -- Kings' Rest
    [250] = {1877, 1030, "TOS"}, -- Temple of Sethraliss
    [251] = {1841, 1022, "UNDR", 410074}, -- The Underrot
    [252] = {1864, 1036, "SOTS"}, -- Shrine of the Storm
    [353] = {1822, 1023, "SIEGE", 445418}, -- Siege of Boralus
    [369] = {2097, 1178, "YARD", 373274}, -- Operation: Mechagon - Junkyard
    [370] = {2097, 1178, "WORK", 373274}, -- Operation: Mechagon - Workshop

    -- Shadowlands
    [375] = {2290, 1184, "MISTS", 354464}, -- Mists of Tirna Scithe
    [376] = {2286, 1182, "NW", 354462}, -- The Necrotic Wake
    [377] = {2291, 1188, "DOS", 354468}, -- De Other Side
    [378] = {2287, 1185, "HOA", 354465}, -- Halls of Atonement
    [379] = {2289, 1183, "PF", 354463}, -- Plaguefall
    [380] = {2284, 1189, "SD", 354469}, -- Sanguine Depths
    [381] = {2285, 1186, "SOA", 354466}, -- Spires of Ascension
    [382] = {2293, 1187, "TOP", 354467}, -- Theater of Pain
    [391] = {2441, 1194, "STRT", 367416}, -- Tazavesh: Streets of Wonder
    [392] = {2441, 1194, "GMBT", 367416}, -- Tazavesh: So'leah's Gambit

    -- Dragonflight
    [399] = {2521, 1202, "RLP", 393256}, -- Ruby Life Pools
    [400] = {2516, 1198, "NO", 393262}, -- The Nokhud Offensive
    [401] = {2515, 1203, "AV", 393279}, -- The Azure Vault
    [402] = {2526, 1201, "AA", 393273}, -- Algeth'ar Academy
    [403] = {2451, 1197, "ULD", 393222}, -- Uldaman: Legacy of Tyr
    [404] = {2519, 1199, "NELT", 393276}, -- Neltharus
    [405] = {2520, 1196, "BH", 393267}, -- Brackenhide Hollow
    [406] = {2527, 1204, "HOI", 393283}, -- Halls of Infusion
    [463] = {2579, 1209, "FALL", 424197}, -- Dawn of the Infinite: Galakrond's Fall
    [464] = {2579, 1209, "RISE", 424197}, -- Dawn of the Infinite: Murozond's Rise

    -- The War Within
    [499] = {2649, 1267, "PSF", 445444}, -- Priory of the Sacred Flame
    [500] = {2648, 1268, "ROOK", 445443}, -- The Rookery
    [501] = {2652, 1269, "SV", 445269}, -- The Stonevault
    [502] = {2669, 1274, "COT", 445416}, -- City of Threads
    [503] = {2660, 1271, "ARAK", 445417}, -- Ara-Kara, City of Echoes
    [504] = {2651, 1210, "DFC", 445441}, -- Darkflame Cleft
    [505] = {2662, 1270, "DAWN", 445414}, -- The Dawnbreaker
    [506] = {2661, 1272, "BREW", 445440}, -- Cinderbrew Meadery
    ---AUTO_GENERATED TAILING MythicPlusDatabase
}
