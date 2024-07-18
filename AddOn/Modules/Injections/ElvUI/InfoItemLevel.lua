local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local M = E:GetModule('Misc')

-- luacheck: read globals PlayerGetTimerunningSeasonID

-- Lua functions
local _G = _G
local floor, gmatch, gsub, ipairs, pairs, select = floor, gmatch, gsub, ipairs, pairs, select
local strmatch, tonumber, type = strmatch, tonumber, type
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local C_Item_GetItemInfoInstant = C_Item.GetItemInfoInstant
local C_TooltipInfo_GetInventoryItem = C_TooltipInfo.GetInventoryItem
local CreateFrame = CreateFrame
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemLink = GetInventoryItemLink
local PlayerGetTimerunningSeasonID = PlayerGetTimerunningSeasonID
local UnitLevel = UnitLevel

local tContains = tContains

local ADDON_MISSING = ADDON_MISSING

local maxLevel = GetMaxLevelForPlayerExpansion()

---@class EnchantmentInfo
---@field classID number
---@field subClassIDs number[]

---@class SlotEnchantmentInfo
---@field [number] EnchantmentInfo|true

---@class GearEnchantmentInfo
---@field [number] SlotEnchantmentInfo|false

---@type GearEnchantmentInfo
local gearEnchantments = {
    ---AUTO_GENERATED LEADING InfoItemLevelEnchantments
    [1] = false, -- Head
    [2] = false, -- Neck
    [3] = false, -- Shoulder
    [5] = { -- Chest
        [6616] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Accelerated Agility (Tier 3)
        [6619] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Reserve of Intellect (Tier 3)
        [6622] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Sustained Strength (Tier 3)
        [6625] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Waking Stats (Tier 3)
        [7355] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Stormrider's Agility (Tier 3)
        [7358] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Council's Intellect (Tier 3)
        [7361] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Oathsworn's Strength (Tier 3)
        [7364] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Crystalline Radiance (Tier 3)
    },
    [6] = { -- Waist
        [6904] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Shadowed Belt Clasp (Tier 3)
    },
    [7] = { -- Legs
        [6490] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Fierce Armor Kit (Tier 3)
        [6496] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Frosted Armor Kit (Tier 3)
        [6541] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Frozen Spellthread (Tier 3)
        [6544] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Temporal Spellthread (Tier 3)
        [6830] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Lambent Armor Kit (Tier 3)
        [7531] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Daybreak Spellthread (Tier 3)
        [7534] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Sunset Spellthread (Tier 3)
        [7595] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Defender's Armor Kit (Tier 3)
        [7601] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Stormbound Armor Kit (Tier 3)
    },
    [8] = { -- Feet
        [6607] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Plainsrunner's Breeze (Tier 3)
        [6610] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Rider's Reassurance (Tier 3)
        [6613] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Watcher's Loam (Tier 3)
        [7418] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Scout's March (Tier 3)
        [7421] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cavalry's March (Tier 3)
        [7424] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Defender's March (Tier 3)
    },
    [9] = { -- Wrist
        [6574] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Avoidance (Tier 3)
        [6580] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Leech (Tier 3)
        [6586] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Speed (Tier 3)
        [7385] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Armored Avoidance (Tier 3)
        [7391] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Armored Leech (Tier 3)
        [7397] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Armored Speed (Tier 3)
    },
    [10] = false, -- Hands
    [11] = { -- Finger 1
        [6550] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Critical Strike (Tier 3)
        [6556] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Haste (Tier 3)
        [6562] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Mastery (Tier 3)
        [6568] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Versatility (Tier 3)
        [7334] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Critical Strike (Tier 3)
        [7340] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Haste (Tier 3)
        [7346] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Mastery (Tier 3)
        [7352] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Versatility (Tier 3)
        [7470] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Critical Strike (Tier 3)
        [7473] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Haste (Tier 3)
        [7476] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Versatility (Tier 3)
        [7479] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Mastery (Tier 3)
    },
    [12] = { -- Finger 2
        [6550] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Critical Strike (Tier 3)
        [6556] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Haste (Tier 3)
        [6562] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Mastery (Tier 3)
        [6568] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Versatility (Tier 3)
        [7334] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Critical Strike (Tier 3)
        [7340] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Haste (Tier 3)
        [7346] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Mastery (Tier 3)
        [7352] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Radiant Versatility (Tier 3)
        [7470] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Critical Strike (Tier 3)
        [7473] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Haste (Tier 3)
        [7476] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Versatility (Tier 3)
        [7479] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cursed Mastery (Tier 3)
    },
    [13] = false, -- Trinket 1
    [14] = false, -- Trinket 2
    [15] = { -- Back
        [6592] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Graceful Avoidance (Tier 3)
        [6598] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Regenerative Leech (Tier 3)
        [6604] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Homebound Speed (Tier 3)
        [7403] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Winged Grace (Tier 3)
        [7409] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Leeching Fangs (Tier 3)
        [7415] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Burrowing Rapidity (Tier 3)
    },
    [16] = { -- Main Hand
        [3368] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Fallen Crusader
        [3370] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Razorice
        [3847] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Stoneskin Gargoyle
        [6241] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Sanguination
        [6242] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Spellwarding
        [6244] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Unending Thirst
        [6245] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Apocalypse
        [6522] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Gyroscopic Kaleidoscope (Tier 3)
        [6525] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Projectile Propulsion Pinion (Tier 3)
        [6528] = {classID = 2, subClassIDs = {2, 3, 18}}, -- High Intensity Thermal Scanner (Tier 3)
        [6628] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Burning Writ (Tier 3)
        [6631] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Burning Devotion (Tier 3)
        [6634] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Earthen Writ (Tier 3)
        [6637] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Earthen Devotion (Tier 3)
        [6640] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Sophic Writ (Tier 3)
        [6643] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Sophic Devotion (Tier 3)
        [6646] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Frozen Writ (Tier 3)
        [6649] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Frozen Devotion (Tier 3)
        [6652] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Wafting Writ (Tier 3)
        [6655] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Wafting Devotion (Tier 3)
        [6824] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Spore Tender (Tier 3)
        [6827] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Shadowflame Wreathe (Tier 3)
        [7003] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Dreaming Devotion (Tier 3)
        [7439] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Council's Guile (Tier 3)
        [7442] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Stormrider's Fury (Tier 3)
        [7445] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Stonebound Artistry (Tier 3)
        [7448] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Oathsworn's Tenacity (Tier 3)
        [7451] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Air (Tier 3)
        [7454] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Fiery Resolve (Tier 3)
        [7457] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Storms (Tier 3)
        [7460] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of the Depths (Tier 3)
        [7463] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Radiant Power (Tier 3)
    },
    [17] = { -- Off Hand
        [3368] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Fallen Crusader
        [3370] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Razorice
        [3847] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Stoneskin Gargoyle
        [6241] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Sanguination
        [6242] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Spellwarding
        [6244] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Unending Thirst
        [6245] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Apocalypse
        [6522] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Gyroscopic Kaleidoscope (Tier 3)
        [6525] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Projectile Propulsion Pinion (Tier 3)
        [6528] = {classID = 2, subClassIDs = {2, 3, 18}}, -- High Intensity Thermal Scanner (Tier 3)
        [6628] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Burning Writ (Tier 3)
        [6631] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Burning Devotion (Tier 3)
        [6634] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Earthen Writ (Tier 3)
        [6637] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Earthen Devotion (Tier 3)
        [6640] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Sophic Writ (Tier 3)
        [6643] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Sophic Devotion (Tier 3)
        [6646] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Frozen Writ (Tier 3)
        [6649] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Frozen Devotion (Tier 3)
        [6652] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Wafting Writ (Tier 3)
        [6655] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Wafting Devotion (Tier 3)
        [6824] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Spore Tender (Tier 3)
        [6827] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Shadowflame Wreathe (Tier 3)
        [7003] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}}, -- Dreaming Devotion (Tier 3)
        [7439] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Council's Guile (Tier 3)
        [7442] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Stormrider's Fury (Tier 3)
        [7445] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Stonebound Artistry (Tier 3)
        [7448] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Oathsworn's Tenacity (Tier 3)
        [7451] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Air (Tier 3)
        [7454] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Fiery Resolve (Tier 3)
        [7457] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Storms (Tier 3)
        [7460] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of the Depths (Tier 3)
        [7463] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Authority of Radiant Power (Tier 3)
    },
    ---AUTO_GENERATED TAILING InfoItemLevelEnchantments
}

-- quest reward introduced in 10.2.0
-- remove in next expansion
gearEnchantments[1] = { -- Head
    [7052] = true, -- Incandescent Essence
}

local tierSetItemIDs = {
    ---AUTO_GENERATED LEADING InfoItemLevelItemSets
    -- Warrior
    -- Irons of the Onyx Crucible
    [217216] = 1, [217217] = 1, [217218] = 1, [217219] = 1, [217220] = 1,
    -- Warsculptor's Masterwork
    [211987] = 2, [211985] = 2, [211984] = 2, [211983] = 2, [211982] = 2,
    -- Paladin
    -- Heartfire Sentinel's Authority
    [217196] = 1, [217197] = 1, [217198] = 1, [217199] = 1, [217200] = 1,
    -- Entombed Seraph's Radiance
    [211996] = 2, [211994] = 2, [211993] = 2, [211992] = 2, [211991] = 2,
    -- Hunter
    -- Stormwing Harrier's Camouflage
    [217181] = 1, [217182] = 1, [217183] = 1, [217184] = 1, [217185] = 1,
    -- Lightless Scavenger's Necessities
    [212023] = 2, [212021] = 2, [212020] = 2, [212019] = 2, [212018] = 2,
    -- Rogue
    -- Lurking Specter's Shadeweave
    [217206] = 1, [217207] = 1, [217208] = 1, [217209] = 1, [217210] = 1,
    -- K'areshi Phantom's Bindings
    [212041] = 2, [212039] = 2, [212038] = 2, [212037] = 2, [212036] = 2,
    -- Priest
    -- The Furnace Seraph's Verdict
    [217201] = 1, [217202] = 1, [217203] = 1, [217205] = 1, [217204] = 1,
    -- Shards of Living Luster
    [212084] = 2, [212083] = 2, [212082] = 2, [212086] = 2, [212081] = 2,
    -- Death Knight
    -- Risen Nightmare's Gravemantle
    [217221] = 1, [217222] = 1, [217223] = 1, [217224] = 1, [217225] = 1,
    -- Exhumed Centurion's Relics
    [212005] = 2, [212003] = 2, [212002] = 2, [212001] = 2, [212000] = 2,
    -- Shaman
    -- Vision of the Greatwolf Outcast
    [217236] = 1, [217237] = 1, [217238] = 1, [217239] = 1, [217240] = 1,
    -- Waves of the Forgotten Reservoir
    [212014] = 2, [212012] = 2, [212011] = 2, [212010] = 2, [212009] = 2,
    -- Mage
    -- Wayward Chronomancer's Clockwork
    [217235] = 1, [217231] = 1, [217232] = 1, [217233] = 1, [217234] = 1,
    -- Sparks of Violet Rebirth
    [212095] = 2, [212093] = 2, [212092] = 2, [212091] = 2, [212090] = 2,
    -- Warlock
    -- Sinister Savant's Cursethreads
    [217211] = 1, [217212] = 1, [217213] = 1, [217215] = 1, [217214] = 1,
    -- Rites of the Hexflame Coven
    [212075] = 2, [212074] = 2, [212073] = 2, [212077] = 2, [212072] = 2,
    -- Monk
    -- Wrappings of the Waking Fist
    [217186] = 1, [217187] = 1, [217188] = 1, [217189] = 1, [217190] = 1,
    -- Gatecrasher's Fortitude
    [212050] = 2, [212048] = 2, [212047] = 2, [212046] = 2, [212045] = 2,
    -- Druid
    -- Strands of the Autumn Blaze
    [217191] = 1, [217192] = 1, [217193] = 1, [217194] = 1, [217195] = 1,
    -- Mane of the Greatlynx
    [212059] = 2, [212057] = 2, [212056] = 2, [212055] = 2, [212054] = 2,
    -- Demon Hunter
    -- Screaming Torchfiend's Brutality
    [217226] = 1, [217227] = 1, [217228] = 1, [217229] = 1, [217230] = 1,
    -- Husk of the Hypogeal Nemesis
    [212068] = 2, [212066] = 2, [212065] = 2, [212064] = 2, [212063] = 2,
    -- Evoker
    -- Scales of the Awakened
    [217176] = 1, [217177] = 1, [217178] = 1, [217179] = 1, [217180] = 1,
    -- Destroyer's Scarred Wards
    [212032] = 2, [212030] = 2, [212029] = 2, [212028] = 2, [212027] = 2,
    ---AUTO_GENERATED TAILING InfoItemLevelItemSets
}

local emptyGemSlots = {
    [136256] = true, -- ui-emptysocket-blue
    [136257] = true, -- ui-emptysocket-meta
    [136258] = true, -- ui-emptysocket-red
    [136259] = true, -- ui-emptysocket-yellow
    [136260] = true, -- ui-emptysocket
    [407324] = true, -- ui-emptysocket-cogwheel
    [407325] = true, -- ui-emptysocket-hydraulic
    [458977] = true, -- ui-emptysocket-prismatic
    [2958629] = true, -- ui-emptysocket-punchcardblue
    [2958630] = true, -- ui-emptysocket-punchcardred
    [2958631] = true, -- ui-emptysocket-punchcardyellow
    [4095404] = true, -- ui-emptysocket-domination
}

local primaryStats = {
    [ITEM_MOD_AGILITY_SHORT] = true,
    [ITEM_MOD_INTELLECT_SHORT] = true,
    [ITEM_MOD_STRENGTH_SHORT] = true,
}

local genericPrimaryStat = {
    ['主属性'] = true,
}

local statisticSlots = {
    {STAT_CRITICAL_STRIKE, STAT_CRITICAL_STRIKE},
    {STAT_HASTE, STAT_HASTE},
    {STAT_MASTERY, STAT_MASTERY},
    {STAT_VERSATILITY, STAT_VERSATILITY},
    {ITEM_MOD_AGILITY_SHORT},
    {STAT_AVOIDANCE, STAT_AVOIDANCE},
    {STAT_LIFESTEAL, STAT_LIFESTEAL},
    {STAT_SPEED, STAT_SPEED},
    {'宝石'},
    {'附魔'},
    {'旧套'},
    {'新套'},
}

local FONT_SIZE = 12
local HEIGHT = 18
local LABEL_WIDTH = 32
local VALUE_WIDTH = 47
local SPACING = 4

local function updateStatisticFrame(parent, data)
    if not data then
        if parent.statisticFrame then
            parent.statisticFrame:Hide()
        end
        return
    end

    if not parent.statisticFrame then
        ---@class StatisticFrame:Frame
        local frame = CreateFrame('Frame', nil, parent)
        frame:ClearAllPoints()
        frame:SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', 0, -35)
        frame:SetSize(
            (LABEL_WIDTH + VALUE_WIDTH + SPACING) * 4 + SPACING,
            (HEIGHT + SPACING) * 3 + SPACING
        )
        frame:CreateBackdrop('Transparent')

        frame.slots = {}
        for i = 1, 12 do
            ---@class StatisticSlot:Frame
            local slot = CreateFrame('Frame', nil, frame)
            slot:ClearAllPoints()
            slot:SetPoint(
                'TOPLEFT', frame, 'TOPLEFT',
                SPACING + ((i - 1) % 4) * (LABEL_WIDTH + VALUE_WIDTH + SPACING),
                -SPACING - floor((i - 1) / 4) * (HEIGHT + SPACING)
            )
            slot:SetSize(LABEL_WIDTH + VALUE_WIDTH + SPACING, HEIGHT)

            ---@class StatisticSlotLabel:Frame
            slot.label = CreateFrame('Frame', nil, slot)
            slot.label:ClearAllPoints()
            slot.label:SetPoint('TOPLEFT', slot, 'TOPLEFT', 0, 0)
            slot.label:SetSize(LABEL_WIDTH, HEIGHT)
            slot.label:CreateBackdrop()
            slot.label.backdrop:SetBackdropColor(0, 0.9, 0.9, 0.2)
            slot.label.backdrop:SetBackdropBorderColor(0, 0.9, 0.9, 0.2)

            slot.label.text = slot.label:CreateFontString(nil, 'ARTWORK')
            slot.label.text:ClearAllPoints()
            slot.label.text:SetPoint('CENTER', slot.label, 'CENTER', 0, 0)
            slot.label.text:SetSize(LABEL_WIDTH - 2, HEIGHT - 2)
            slot.label.text:FontTemplate(nil, FONT_SIZE, 'OUTLINE')
            slot.label.text:SetJustifyH('CENTER')
            slot.label.text:SetText(statisticSlots[i][1])

            slot.value = slot:CreateFontString(nil, 'ARTWORK')
            slot.value:ClearAllPoints()
            slot.value:SetPoint('LEFT', slot.label, 'RIGHT', SPACING, 0)
            slot.value:SetSize(VALUE_WIDTH, HEIGHT)
            slot.value:FontTemplate(nil, FONT_SIZE, 'OUTLINE')
            slot.value:SetJustifyH('LEFT')

            frame.slots[i] = slot
        end

        parent.statisticFrame = frame
    end

    local frame = parent.statisticFrame
    frame:Show()

    local allStats = {}
    local gems = 0
    local gemSlots = 0
    local isMissingGemSlots = false
    local bestEnchants = 0
    local enchants = 0
    local enchantSlots = 0
    local oldTier = 0
    local newTier = 0

    local primaryStat

    for slotID, info in pairs(data) do
        gems = gems + info.gems
        gemSlots = gemSlots + info.gemSlots

        -- Dragonflight
        if slotID == 2 and info.gemSlots < 3 then
            isMissingGemSlots = true
        end

        if info.enchantSlots then
            enchantSlots = enchantSlots + 1
            if info.enchants then
                bestEnchants = bestEnchants + 1
                enchants = enchants + 1
            elseif type(info.enchants) == 'boolean' then
                enchants = enchants + 1
            end
        end

        if info.oldTier then
            oldTier = oldTier + 1
        end

        if info.newTier then
            newTier = newTier + 1
        end

        for name, stat in pairs(info.stats) do
            if not allStats[name] then
                allStats[name] = { value = stat.value, color = stat.color }
            else
                allStats[name].value = allStats[name].value + stat.value
                if stat.color.g > allStats[name].color.g then
                    allStats[name].color = stat.color
                end
            end

            if primaryStats[name] and stat.color.g >= 1 then
                primaryStat = name
            end
        end
    end

    if primaryStat then
        for name in pairs(genericPrimaryStat) do
            if allStats[name] then
                allStats[primaryStat].value = allStats[primaryStat].value + allStats[name].value
            end
        end
        frame.slots[5].label.text:SetText(primaryStat)
        frame.slots[5].value:SetText(allStats[primaryStat].value)
    end

    for i, slotData in ipairs(statisticSlots) do
        if slotData[2] then
            local slot = frame.slots[i]
            local value = allStats[slotData[2]] and allStats[slotData[2]].value or 0
            slot.value:SetText(value)
            if value > 0 then
                slot.value:SetTextColor(0, 1, 0)
            else
                slot.value:SetTextColor(1, 1, 1)
            end
        end
    end

    frame.slots[9].value:SetText(gems .. '/' .. gemSlots)
    if gems < gemSlots then
        frame.slots[9].value:SetTextColor(1, 0, 0)
    elseif isMissingGemSlots then
        frame.slots[9].value:SetTextColor(1, 1, 0)
    else
        frame.slots[9].value:SetTextColor(0, 1, 0)
    end

    frame.slots[10].value:SetText(enchants .. '/' .. enchantSlots)
    if enchants < enchantSlots then
        frame.slots[10].value:SetTextColor(1, 0, 0)
    elseif bestEnchants < enchantSlots then
        frame.slots[10].value:SetTextColor(1, 1, 0)
    else
        frame.slots[10].value:SetTextColor(0, 1, 0)
    end

    frame.slots[11].value:SetText(oldTier)
    if oldTier <= 1 then
        frame.slots[11].value:SetTextColor(1, 1, 1)
    elseif oldTier <= 3 then
        frame.slots[11].value:SetTextColor(1, 1, 0)
    else
        frame.slots[11].value:SetTextColor(0, 1, 0)
    end

    frame.slots[12].value:SetText(newTier)
    if newTier <= 1 then
        frame.slots[12].value:SetTextColor(1, 1, 1)
    elseif newTier <= 3 then
        frame.slots[12].value:SetTextColor(1, 1, 0)
    else
        frame.slots[12].value:SetTextColor(0, 1, 0)
    end
end

local function InfoItemLevel()
    hooksecurefunc(M, 'UpdateAverageString', function(_, frame, which, iLevelDB)
        updateStatisticFrame(frame, iLevelDB.RhythmBox)

        -- add avg total info for Character
        if which == 'Character' then
            local avgTotal, avgItemLevel = E:GetPlayerItemLevel()
            if avgTotal ~= avgItemLevel then
                frame.ItemLevelText:SetText(avgItemLevel .. " / " .. avgTotal)
            end
        end
    end)

    if PlayerGetTimerunningSeasonID() == 1 then
        -- WoW Remix: Mists of Pandaria
        gearEnchantments = {}
    end

    hooksecurefunc(M, 'UpdatePageStrings', function(_, i, iLevelDB, inspectItem, slotInfo, which)
        local unitID = which == 'Character' and 'player' or _G.InspectFrame.unit
        if UnitLevel(unitID) < maxLevel then return end

        if not iLevelDB.RhythmBox then
            iLevelDB.RhythmBox = {}
        end

        local slot = {
            gems = 0,
            gemSlots = 0,
            stats = {},
        }
        iLevelDB.RhythmBox[i] = slot

        local stats = slot.stats
        local data = C_TooltipInfo_GetInventoryItem(unitID, i)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                for valueText, name in gmatch(line.leftText, '%+([0-9,]+) ([^%| ,，]+)') do
                    local value = tonumber((gsub(valueText, ',', ''))) or 0
                    if not stats[name] then
                        stats[name] = { value = value, color = line.leftColor }
                    else
                        stats[name].value = stats[name].value + value
                        if line.leftColor.g > stats[name].color.g then
                            stats[name].color = line.leftColor
                        end
                    end
                end
            end
        end

        for _, texture in ipairs(slotInfo.gems) do
            if not emptyGemSlots[texture] then
                slot.gems = slot.gems + 1
            end
            slot.gemSlots = slot.gemSlots + 1
        end

        local itemID = GetInventoryItemID(unitID, i)
        if itemID and tierSetItemIDs[itemID] then
            if tierSetItemIDs[itemID] == 1 then
                slot.oldTier = true
            elseif tierSetItemIDs[itemID] == 2 then
                slot.newTier = true
            end
        end

        local itemLink = GetInventoryItemLink(unitID, i)
        if itemLink then
            local enchant = tonumber(strmatch(itemLink, 'item:%d+:(%d+):'))
            local enchantments = gearEnchantments[i]
            if enchant and (not enchantments or enchantments[enchant]) then
                slot.enchants = true
                slot.enchantSlots = true
            elseif enchantments and (not enchant or not enchantments[enchant]) then
                local classID, subclassID = select(6, C_Item_GetItemInfoInstant(itemLink))
                local canEnchant = false

                for _, enchantmentData in pairs(enchantments) do
                    if (
                        type(enchantmentData) == 'boolean' or
                        (enchantmentData.classID == classID and tContains(enchantmentData.subClassIDs, subclassID))
                    ) then
                        canEnchant = true
                        break
                    end
                end

                if canEnchant then
                    slot.enchantSlots = true
                    if not enchant then
                        inspectItem.enchantText:SetText(ADDON_MISSING)
                        inspectItem.enchantText:SetTextColor(1, 0, 0)
                    else
                        slot.enchants = false
                        inspectItem.enchantText:SetTextColor(1, 1, 0)
                    end
                end
            end
        end
    end)
end

RI:RegisterPipeline(InfoItemLevel)
