local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local issecretvalue, pcall = issecretvalue, pcall
local string_format = string.format

-- WoW API / Variables
local C_UnitAuras_GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local CreateFrame = CreateFrame
local UnitClassBase = UnitClassBase
local UnitClassification = UnitClassification
local UnitLevel = UnitLevel
local UnitPowerType = UnitPowerType
local UnitSex = UnitSex

local modelFrame = CreateFrame('PlayerModel')

local fingerprints = {
    -- Algeth'ar Academy (402)
    [402] = {
        ['1102558:0:elite:1:WARRIOR:1'] = 196694, -- Arcane Forager
        ['3952432:0:elite:1:WARRIOR:1'] = 196045, -- Corrupted Manafiend
        ['3951256:0:elite:1:WARRIOR:1'] = 197406, -- Aggravated Skitterfly
        ['4077816:1:elite:1:WARRIOR:1'] = 192333, -- Alpha Eagle
        ['4033880:1:elite:1:WARRIOR:1'] = 192680, -- Guardian Sentry
        ['1100483:0:minus:1:WARRIOR:1'] = 192329, -- Territorial Eagle
        ['4216711:0:elite:3:PALADIN:0'] = 196202, -- Spectral Invoker
        ['617127:0:elite:1:WARRIOR:1'] = 196044, -- Unruly Textbook
        ['4217881:1:elite:3:WARRIOR:1'] = 196200, -- Algeth'ar Echoknight
        ['1382579:0:elite:2:WARRIOR:1'] = 196577, -- Spellbound Battleaxe
        ['1722688:0:normal:1:WARRIOR:1'] = 197398, -- Hungry Lasher
        ['1722688:1:elite:1:WARRIOR:1'] = 197219, -- Vile Lasher
        ['4323766:1:elite:1:WARRIOR:1'] = -63875, -- Vicious Ravager (custom)
    },

    -- Maisara Caverns (560)
    [560] = {
        ['6875167:0:elite:3:WARRIOR:1'] = 249036, -- Tormented Shade
        ['6875167:0:elite:3:WARRIOR:1:0'] = 249036,
        ['6875167:0:elite:3:PALADIN:0'] = 254740, -- Umbral Shadowbinder
        ['6875167:0:elite:3:PALADIN:0:0'] = 254740,
        ['6366139:0:elite:3:WARRIOR:1'] = 242964, -- Keen Headhunter
        ['6366139:0:elite:3:WARRIOR:1:0'] = 248693, -- Mire Laborer (extended: 0 buffs)
        ['6366139:0:elite:3:WARRIOR:1:1'] = 242964, -- Keen Headhunter (extended: 1 buff)
        ['6366139:1:elite:3:PALADIN:0'] = 248686, -- Dread Souleater
        ['6366141:0:elite:2:WARRIOR:1'] = 248684, -- Frenzied Berserker
        ['6366141:1:elite:2:PALADIN:0'] = 253458, -- Zil'jan
        ['6366141:1:elite:2:PALADIN:0:0'] = 253458,
        ['1716306:0:elite:1:WARRIOR:1'] = 248690, -- Grim Skirmisher
        ['1716306:0:elite:1:WARRIOR:1:1'] = 248690,
        ['6875165:0:elite:2:PALADIN:0'] = 248685, -- Ritual Hexxer
        ['6875165:1:elite:2:PALADIN:0'] = 253683, -- Rokh'zal
        ['6875165:1:elite:2:PALADIN:0:0'] = 253683,
        ['6875165:0:elite:2:WARRIOR:1'] = 249036, -- Tormented Shade
        ['6875165:0:elite:2:WARRIOR:1:0'] = 249036,
        ['7127711:1:elite:2:WARRIOR:1'] = 249030, -- Restless Gnarldin
        ['7127711:1:elite:2:WARRIOR:1:1'] = 249030,
        ['4034801:1:elite:1:WARRIOR:1'] = 248678, -- Hulking Juggernaut
        ['1695668:1:elite:1:PALADIN:0'] = 249024, -- Hollow Soulrender
        ['1695668:1:elite:1:PALADIN:0:0'] = 249024,
        ['804504:0:elite:1:WARRIOR:1'] = 253473, -- Gloomwing Bat
        ['804504:0:elite:1:WARRIOR:1:0'] = 253473,
        ['6163242:0:elite:1:WARRIOR:1'] = 249020, -- Hexbound Eagle
        ['1266661:0:elite:1:WARRIOR:1'] = 249022, -- Bramblemaw Bear
        ['1719446:1:elite:1:WARRIOR:1'] = 249025, -- Bound Defender
        ['1719446:1:elite:1:WARRIOR:1:1'] = 249025,
        ['124640:0:normal:1:WARRIOR:1'] = 249002, -- Warding Mask
        ['124640:0:normal:1:WARRIOR:1:1'] = 249002,
        ['124640:1:elite:1:PALADIN:0'] = 253302, -- Hex Guardian
        ['1716306:0:elite:1:WARRIOR:1:0'] = 248692, -- Reanimated Warrior (extended: 0 buffs)
    },

    -- Seat of the Triumvirate (239)
    [239] = {
        ['6152557:0:elite:3:PALADIN:0'] = 122404, -- Dire Voidbender
        ['6152557:0:elite:3:PALADIN:0:0'] = 122404,
        ['6152557:1:elite:3:PALADIN:0'] = 122423, -- Grand Shadow-Weaver
        ['6152557:1:elite:3:PALADIN:0:0'] = 122423,
        ['6152557:0:elite:3:WARRIOR:1'] = 122403, -- Shadowguard Champion
        ['1572365:0:elite:2:WARRIOR:1'] = 122413, -- Ruthless Riftstalker
        ['1572365:0:elite:2:WARRIOR:1:0'] = 122413,
        ['5926159:1:elite:2:WARRIOR:1'] = 122421, -- Umbral War-Adept
        ['5926159:1:elite:2:WARRIOR:1:0'] = 122421,
        ['6705352:1:elite:1:WARRIOR:1'] = 122571, -- Rift Warden
        ['6705352:1:elite:1:WARRIOR:1:1'] = 122571,
        ['6254042:1:elite:1:WARRIOR:1'] = 252756, -- Void-Infused Destroyer
        ['6254042:1:elite:1:WARRIOR:1:0'] = 252756,
        ['1574725:0:normal:0:?:-1:0'] = 255320, -- Ravenous Umbralfin
        ['1570694:0:elite:1:WARRIOR:1'] = 255320,
        ['1574725:0:normal:1:WARRIOR:1'] = 122322, -- Famished Broken
        ['1572377:1:elite:3:PALADIN:0'] = 124171, -- Merciless Subjugator
        ['6152557:0:elite:3:PALADIN:0:1'] = 122405, -- Dark Conjurer (extended: 1 buff)
    },

    -- Windrunner Spire (557)
    [557] = {
        ['1100258:0:elite:3:WARRIOR:1'] = 232070, -- Restless Steward
        ['1100087:0:elite:2:WARRIOR:1'] = 232071, -- Dutiful Groundskeeper
        ['1100087:1:elite:2:PALADIN:0'] = 232113, -- Spellguard Magus
        ['6251997:1:elite:1:PALADIN:0'] = 232122, -- Phalanx Breaker
        ['997378:0:elite:3:WARRIOR:1'] = 232173, -- Fervent Apothecary
        ['959310:0:elite:2:WARRIOR:1'] = 232171, -- Ardent Cutthroat
        ['1252028:1:elite:3:WARRIOR:1'] = 232175, -- Devoted Woebringer
        ['1598184:1:elite:1:WARRIOR:1'] = 232176, -- Flesh Behemoth
        ['6119019:0:elite:1:WARRIOR:1'] = 232056, -- Territorial Dragonhawk
        ['1513629:0:normal:1:WARRIOR:1'] = 234673, -- Spindleweb Hatchling
        ['1513629:0:elite:1:WARRIOR:1'] = 232067, -- Creeping Spindleweb
        ['6338575:1:elite:1:WARRIOR:1'] = 232063, -- Apex Lynx
        ['5095674:0:normal:1:WARRIOR:1'] = 238099, -- Pesty Lashling
        ['5095674:1:elite:1:ROGUE:3'] = 236894, -- Bloated Lasher
        ['1373320:0:elite:1:WARRIOR:1'] = 232283, -- Loyal Worg
        ['6366139:0:elite:3:WARRIOR:1'] = 232148, -- Spectral Axethrower
        ['930099:1:elite:2:PALADIN:0'] = 232146, -- Phantasmal Mystic
        ['917116:0:elite:2:WARRIOR:1'] = 258868, -- Haunting Grunt
    },

    -- Nexus-Point Xenas (559)
    [559] = {
        ['6152557:0:elite:3:WARRIOR:1'] = 241643, -- Shadowguard Defender
        ['6152557:0:elite:3:WARRIOR:1:1'] = 241643,
        ['6152557:0:elite:3:PALADIN:0'] = 241644, -- Corewright Arcanist
        ['6152557:0:elite:3:PALADIN:0:1'] = 241644,
        ['6377937:0:elite:1:WARRIOR:1'] = 241645, -- Hollowsoul Scrounger
        ['6377937:0:elite:1:WARRIOR:1:1'] = 241645,
        ['5926159:0:elite:2:WARRIOR:1'] = 241647, -- Flux Engineer
        ['5926159:0:elite:2:WARRIOR:1:1'] = 241647,
        ['5926159:0:normal:2:PALADIN:0'] = 248708, -- Nexus Adept
        ['5926159:0:normal:2:PALADIN:0:0'] = 248708,
        ['5926159:1:elite:1:MAGE:0'] = 248373, -- Circuit Seer
        ['5926159:1:elite:1:MAGE:0:1'] = 248373,
        ['6705352:0:normal:1:PALADIN:0'] = 248706, -- Cursed Voidcaller
        ['6705352:0:normal:1:PALADIN:0:1'] = 248706,
        ['6705352:0:elite:1:PALADIN:0'] = 251853, -- Grand Nullifier
        ['6705352:0:elite:1:PALADIN:0:1'] = 251853,
        ['6181818:1:elite:1:WARRIOR:1'] = 248506, -- Dreadflail
        ['6181818:1:elite:1:WARRIOR:1:0'] = 248506,
        ['6181816:1:elite:1:MAGE:0'] = 241660, -- Duskfright Herald
        ['6181816:1:elite:1:MAGE:0:0'] = 241660,
        ['6181814:1:elite:1:WARRIOR:1'] = 248502, -- Null Sentinel
        ['6181814:1:elite:1:WARRIOR:1:0'] = 248502,
        ['6730408:1:elite:2:PALADIN:0'] = 241642, -- Lingering Image
        ['6730408:1:elite:2:PALADIN:0:0'] = 241642,
        ['124640:0:minus:1:WARRIOR:1'] = 254932, -- Radiant Swarm
        ['124640:0:minus:1:WARRIOR:1:1'] = 254932,
        ['3952432:0:elite:1:WARRIOR:1'] = 254926, -- Lightwrought
        ['3952432:0:elite:1:WARRIOR:1:0'] = 254926,
        ['2966279:0:normal:1:WARRIOR:1'] = 254928, -- Flarebat
        ['2966279:0:normal:1:WARRIOR:1:1'] = 254928,
        ['7344962:0:normal:1:WARRIOR:1'] = 248501, -- Reformed Voidling
        ['7344962:0:normal:1:WARRIOR:1:1'] = 248501,
    },

    -- Skyreach (161)
    [161] = {
        ['986699:0:elite:1:WARRIOR:1'] = 76132, -- Soaring Chakram Master
        ['986699:0:elite:1:PALADIN:0'] = 78932, -- Driving Gale-Caller
        ['986699:1:elite:1:WARRIOR:1'] = 79303, -- Adorned Bladetalon
        ['1033563:0:elite:1:WARRIOR:1'] = 75976, -- Lowborn Servant
        ['1000727:1:elite:1:PALADIN:0'] = 76087, -- Solar Construct
        ['3952432:1:elite:1:PALADIN:0'] = 78933, -- Solar Elemental
        ['1031301:1:normal:1:WARRIOR:1'] = 79093, -- Suntalon
        ['948417:1:elite:1:WARRIOR:1'] = 76149, -- Dread Raven
        ['3946582:0:elite:1:ROGUE:3'] = 250992, -- Raging Squall
        ['353152:0:elite:1:ROGUE:3'] = 253963, -- Outcast Warrior (custom NPC)
    },

    -- Pit of Saron (556)
    [556] = {
        ['3087468:0:elite:2:WARRIOR:1'] = 252551, -- Deathwhisper Necrolyte
        ['3487358:0:elite:2:PALADIN:0'] = 252566, -- Rimebone Coldwraith
        ['3487358:0:elite:2:WARRIOR:1'] = 252561, -- Quarry Tormentor
        ['1574421:0:elite:1:WARRIOR:1'] = 252558, -- Rotting Ghoul
        ['125234:0:normal:1:WARRIOR:1'] = 252559, -- Leaping Geist
        ['122815:1:elite:2:WARRIOR:1'] = 252610, -- Ymirjar Graveblade
        ['124131:0:elite:3:WARRIOR:1'] = 252606, -- Plungetalon Gargoyle
        ['3197237:0:elite:1:WARRIOR:1'] = 252555, -- Lumbering Plaguehorror
        ['4672491:1:elite:1:WARRIOR:1'] = 257190, -- Iceborn Proto-Drake
        ['3482565:1:elite:2:WARRIOR:1'] = 252563, -- Dreadpulse Lich
        ['1709401:1:elite:1:WARRIOR:1'] = 252564, -- Glacieth
    },

    -- Magisters' Terrace (558)
    [558] = {
        ['1100258:0:elite:3:PALADIN:0'] = 232369, -- Arcane Magister
        ['1100258:1:elite:3:PALADIN:0'] = 251861, -- Blazing Pyromancer / Runed Spellbreaker (same forces)
        ['1100087:0:elite:2:WARRIOR:1'] = 234124, -- Sunblade Enforcer
        ['1100087:0:elite:2:PALADIN:0'] = 234486, -- Lightward Healer
        ['6705352:1:elite:1:ROGUE:3'] = 234068, -- Shadowrift Voidcaller
        ['1410362:1:elite:1:WARRIOR:1'] = 234066, -- Devouring Tyrant
        ['3087474:0:elite:1:PALADIN:0'] = 234064, -- Dreaded Voidwalker
        ['7344962:0:normal:1:WARRIOR:1'] = 234069, -- Voidling
        ['6316091:1:elite:1:ROGUE:3'] = 234062, -- Arcane Sentry
        ['6253063:0:normal:1:PALADIN:0'] = 232106, -- Brightscale Wyrm
        ['1102558:0:normal:1:PALADIN:0'] = 241354, -- Void-Infused Brightscale
        ['6377937:0:elite:1:WARRIOR:1'] = 257447, -- Hollowsoul Shredder
        ['3034257:0:elite:1:PALADIN:0'] = -21937, -- Void Terror (custom)
        ['7464966:0:normal:1:ROGUE:3'] = 245325, -- Spellwoven Familiar (custom)
    },
}

local function GetModelFileID(unitID)
    modelFrame:SetUnit(unitID)

    local modelFileID = modelFrame:GetModelFileID()
    if not issecretvalue(modelFileID) and modelFileID and modelFileID > 0 then
        return modelFileID
    end
end

local function SafeRead(func, unitID, default)
    local status, result = pcall(func, unitID)
    if status and result and not issecretvalue(result) then
        return result
    end
    return default
end

local function GetBuffCount(unitID)
    local count = 0
    for i = 1, 20 do
        local ok, aura = pcall(C_UnitAuras_GetAuraDataByIndex, unitID, i, 'HELPFUL')
        if ok and aura then
            count = count + 1
        else
            break
        end
    end
    return count
end

local function GetFingerprint(unitID)
    local modelFileID = SafeRead(GetModelFileID, unitID)
    if not modelFileID then return end

    local level = SafeRead(UnitLevel, unitID, 0)
    local classn = SafeRead(UnitClassification, unitID, '?')
    local sex = SafeRead(UnitSex, unitID, 0)
    local class = SafeRead(UnitClassBase, unitID, '?')
    local ptype = SafeRead(UnitPowerType, unitID, -1)

    local relLevel = level % 10

    local base = string_format('%d:%d:%s:%d:%s:%d', modelFileID, relLevel, classn, sex, class, ptype)

    local count = GetBuffCount(unitID)
    local extra = base .. ':' .. count

    return base, extra
end

function MP:GetNPCIDFromFingerprint(unitID)
    if not self.currentRun or not self.currentRun.mapID then return end

    local mapFingerprints = fingerprints[self.currentRun.mapID]
    if not mapFingerprints then return end

    local base, extra = GetFingerprint(unitID)
    if not base then return end

    return mapFingerprints[extra] or mapFingerprints[base]
end
