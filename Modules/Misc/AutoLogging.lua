local R, E, L, V, P, G = unpack((select(2, ...)))
local AL = R:NewModule('AutoLogging', 'AceEvent-3.0')

-- Lua functions

-- WoW API / Variables
local GetInstanceInfo = GetInstanceInfo
local LoggingCombat = LoggingCombat
local SetCVar = SetCVar

AL.dungeonList = {
    [643]  = true, -- Throne of the Tides
    [657]  = true, -- The Vortex Pinnacle

    [959]  = true, -- Shado-Pan Monastery
    [960]  = true, -- Temple of the Jade Serpent
    [961]  = true, -- Stormstout Brewery
    [962]  = true, -- Gate of the Setting Sun
    [994]  = true, -- Mogu'shan Palace
    [1001] = true, -- Scarlet Halls
    [1004] = true, -- Scarlet Monastery
    [1007] = true, -- Scholomance
    [1011] = true, -- Siege of Niuzao Temple

    [1175] = true, -- Bloodmaul Slag Mines
    [1176] = true, -- Shadowmoon Burial Grounds
    [1182] = true, -- Auchindoun
    [1195] = true, -- Iron Docks
    [1208] = true, -- Grimrail Depot
    [1209] = true, -- Skyreach
    [1279] = true, -- The Everbloom
    [1358] = true, -- Upper Blackrock Spire

    [1456] = true, -- Eye of Azshara
    [1458] = true, -- Neltharion's Lair
    [1466] = true, -- Darkheart Thicket
    [1477] = true, -- Halls of Valor
    [1492] = true, -- Maw of Souls
    [1493] = true, -- Vault of the Wardens
    [1501] = true, -- Black Rook Hold
    [1516] = true, -- The Arcway
    [1571] = true, -- Court of Stars
    [1651] = true, -- Return to Karazhan
    [1677] = true, -- Cathedral of Eternal Night
    [1753] = true, -- Seat of the Triumvirate

    [1594] = true, -- The MOTHERLODE!!
    [1754] = true, -- Freehold
    [1762] = true, -- Kings' Rest
    [1763] = true, -- Atal'Dazar
    [1771] = true, -- Tol Dagor
    [1822] = true, -- Siege of Boralus
    [1841] = true, -- The Underrot
    [1862] = true, -- Waycrest Manor
    [1864] = true, -- Shrine of the Storm
    [1877] = true, -- Temple of Sethraliss
    [2097] = true, -- Operation: Mechagon

    [2284] = true, -- Sanguine Depths
    [2285] = true, -- Spires of Ascension
    [2286] = true, -- The Necrotic Wake
    [2287] = true, -- Halls of Atonement
    [2289] = true, -- Plaguefall
    [2290] = true, -- Mists of Tirna Scithe
    [2291] = true, -- De Other Side
    [2293] = true, -- Theater of Pain
    [2441] = true, -- Tazavesh, the Veiled Market

    [2451] = true, -- Uldaman: Legacy of Tyr
    [2515] = true, -- The Azure Vault
    [2516] = true, -- The Nokhud Offensive
    [2519] = true, -- Neltharus
    [2520] = true, -- Brackenhide Hollow
    [2521] = true, -- Ruby Life Pools
    [2526] = true, -- Algeth'ar Academy
    [2527] = true, -- Halls of Infusion
    [2579] = true, -- Dawn of the Infinite
}

AL.raidList = {
    [2522] = true, -- Vault of the Incarnates
    [2549] = true, -- Amirdrassil, the Dream's Hope
    [2569] = true, -- Aberrus, the Shadowed Crucible
}

function AL:IsShouldLogging()
    local _, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    if (
        instanceType == 'raid' and self.raidList[instanceID] and
        (difficultyID == 14 or difficultyID == 15 or difficultyID == 16)
    ) then
        return true
    elseif (
        instanceType == 'party' and self.dungeonList[instanceID] and
        (difficultyID == 8 or difficultyID == 23)
    ) then
        return true
    end
end

function AL:UpdateLogging()
    local isActive = LoggingCombat()
    local shouldLogging = self:IsShouldLogging()

    if not isActive and shouldLogging then
        LoggingCombat(true)
        R:Print("开始记录战斗日志")
    elseif isActive and not shouldLogging then
        LoggingCombat(false)
        R:Print("停止记录战斗日志")
    end
end

function AL:Initialize()
    SetCVar('advancedCombatLogging', 1)

    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'UpdateLogging')
    self:RegisterEvent('CHALLENGE_MODE_START', 'UpdateLogging')
    self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateLogging')
end

R:RegisterModule(AL:GetName())
