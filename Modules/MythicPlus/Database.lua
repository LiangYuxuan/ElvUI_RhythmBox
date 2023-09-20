local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- [challengeMapID] = {journalInstanceID, displayName, portalSpellID},
MP.database = {
    -- Cata
    [438] = {68, "VP", 410080}, -- The Vortex Pinnacle
    [456] = {68, "TOTT", 424142}, -- Throne of the Tides

    -- MOP
    [2]   = {313, "TJS", 131204}, -- Temple of the Jade Serpent
    [56]  = {302, nil, 131205}, -- Stormstout Brewery
    [57]  = {303, nil, 131225}, -- Gate of the Setting Sun
    [58]  = {312, nil, 131206}, -- Shado-Pan Monastery
    [59]  = {324, nil, 131228}, -- Siege of Niuzao Temple
    [60]  = {321, nil, 131222}, -- Mogu'shan Palace
    [76]  = {246, nil, 131232}, -- Scholomance
    [77]  = {311, nil, 131231}, -- Scarlet Halls
    [78]  = {316, nil, 131229}, -- Scarlet Monastery

    -- WoD
    [161] = {476, nil, 159898}, -- Skyreach
    [163] = {385, nil, 159895}, -- Bloodmaul Slag Mines
    [164] = {547, nil, 159897}, -- Auchindoun
    [165] = {537, "SBG", 159899}, -- Shadowmoon Burial Grounds
    [166] = {536, "GD", 159900}, -- Grimrail Depot
    [167] = {559, nil, 159902}, -- Upper Blackrock Spire
    [168] = {556, "EB", 159901}, -- The Everbloom
    [169] = {558, "ID", 159896}, -- Iron Docks

    -- LEG
    [197] = {716, "EOA"}, -- Eye of Azshara
    [198] = {762, "DHT", 424163}, -- Darkheart Thicket
    [199] = {740, "BRH", 424153}, -- Black Rook Hold
    [200] = {721, "HOV", 393764}, -- Halls of Valor
    [206] = {767, "NL", 410078}, -- Neltharion's Lair
    [207] = {707, "VOTW"}, -- Vault of the Wardens
    [208] = {727, "MOS"}, -- Maw of Souls
    [209] = {726, "ARC"}, -- The Arcway
    [210] = {800, "COS", 393766}, -- Court of Stars
    [227] = {860, "LOWR", 373262}, -- Return to Karazhan: Lower
    [233] = {900, "COEN"}, -- Cathedral of Eternal Night
    [234] = {860, "UPPR", 373262}, -- Return to Karazhan: Upper
    [239] = {945, "SEAT"}, -- Seat of the Triumvirate

    -- BfA
    [244] = {968, "AD", 424187}, -- Atal'Dazar
    [245] = {1001, "FH", 410071}, -- Freehold
    [246] = {1002, "TD"}, -- Tol Dagor
    [247] = {1012, "ML"}, -- The MOTHERLODE!!
    [248] = {1021, "WM", 424167}, -- Waycrest Manor
    [249] = {1041, "KR"}, -- Kings' Rest
    [250] = {1030, "TOS"}, -- Temple of Sethraliss
    [251] = {1022, "UNDR", 410074}, -- The Underrot
    [252] = {1036, "SOTS"}, -- Shrine of the Storm
    [353] = {1023, "SIEGE"}, -- Siege of Boralus
    [369] = {1178, "JY", 373274}, -- Operation: Mechagon - Junkyard
    [370] = {1178, "WS", 373274}, -- Operation: Mechagon - Workshop

    -- SL
    [375] = {1184, "MISTS", 354464}, -- Mists of Tirna Scithe
    [376] = {1182, "NW", 354462}, -- The Necrotic Wake
    [377] = {1188, "DOS", 354468}, -- De Other Side
    [378] = {1185, "HOA", 354465}, -- Halls of Atonement
    [379] = {1183, "PF", 354463}, -- Plaguefall
    [380] = {1189, "SD", 354469}, -- Sanguine Depths
    [381] = {1186, "SOA", 354466}, -- Spires of Ascension
    [382] = {1187, "TOP", 354467}, -- Theater of Pain
    [391] = {1194, "STRT", 367416}, -- Tazavesh: Streets of Wonder
    [392] = {1194, "GMBT", 367416}, -- Tazavesh: So'leah's Gambit

    -- DF
    [399] = {1202, "RLP", 393256}, -- Ruby Life Pools
    [400] = {1198, "TNO", 393262}, -- The Nokhud Offensive
    [401] = {1203, "TAV", 393279}, -- The Azure Vault
    [402] = {1201, "AA", 393273}, -- Algeth'ar Academy
    [403] = {1197, "ULD", 393222}, -- Uldaman: Legacy of Tyr
    [404] = {1199, "NELT", 393276}, -- Neltharus
    [405] = {1196, "BH", 393267}, -- Brackenhide Hollow
    [406] = {1204, "HOI", 393283}, -- Halls of Infusion
    [463] = {1204, "FALL", 424197}, -- Dawn of the Infinite: Galakrond's Fall
    [464] = {1204, "RISE", 424197}, -- Dawn of the Infinite: Murozond's Rise
}

--[[
    -- Here we put not yet used Challenge Map abbrs
    -- We wants to sync with RIO but they're not decided yet

    [56]  = "BREW", -- Stormstout Brewery
    [57]  = "GSS", -- Gate of the Setting Sun
    [58]  = "SPM", -- Shado-Pan Monastery
    [59]  = "SNT", -- Siege of Niuzao Temple
    [60]  = "MP", -- Mogu'shan Palace
    [76]  = "SCH", -- Scholomance
    [77]  = "SH", -- Scarlet Halls
    [78]  = "SM", -- Scarlet Monastery

    [161] = "SKY", -- Skyreach
    [163] = "BSM", -- Bloodmaul Slag Mines
    [164] = "AUC", -- Auchindoun
    [167] = "UBS", -- Upper Blackrock Spire
]]
