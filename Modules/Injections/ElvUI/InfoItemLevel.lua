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
    },
    [8] = { -- Feet
        [6607] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Plainsrunner's Breeze (Tier 3)
        [6610] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Rider's Reassurance (Tier 3)
        [6613] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Watcher's Loam (Tier 3)
    },
    [9] = { -- Wrist
        [6574] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Avoidance (Tier 3)
        [6580] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Leech (Tier 3)
        [6586] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Speed (Tier 3)
    },
    [10] = false, -- Hands
    [11] = { -- Finger 1
        [6550] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Critical Strike (Tier 3)
        [6556] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Haste (Tier 3)
        [6562] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Mastery (Tier 3)
        [6568] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Versatility (Tier 3)
    },
    [12] = { -- Finger 2
        [6550] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Critical Strike (Tier 3)
        [6556] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Haste (Tier 3)
        [6562] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Mastery (Tier 3)
        [6568] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Devotion of Versatility (Tier 3)
    },
    [13] = false, -- Trinket 1
    [14] = false, -- Trinket 2
    [15] = { -- Back
        [6592] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Graceful Avoidance (Tier 3)
        [6598] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Regenerative Leech (Tier 3)
        [6604] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Homebound Speed (Tier 3)
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
    },
    ---AUTO_GENERATED TAILING InfoItemLevelEnchantments
}

-- quest reward introduced in 10.2.0
-- remove in next expansion
gearEnchantments[1] = { -- Head
    [7052] = true, -- Incandescent Essence
}

---AUTO_GENERATED LEADING InfoItemLevelItemSets
local tierSetItemIDs = {
    -- Warrior
    -- Irons of the Onyx Crucible
    [217216] = 32, [217217] = 32, [217218] = 32, [217219] = 32, [217220] = 32,
    -- Warsculptor's Masterwork
    [211987] = 33, [211985] = 33, [211984] = 33, [211983] = 33, [211982] = 33,
    -- Paladin
    -- Heartfire Sentinel's Authority
    [217196] = 32, [217197] = 32, [217198] = 32, [217199] = 32, [217200] = 32,
    -- Entombed Seraph's Radiance
    [211996] = 33, [211994] = 33, [211993] = 33, [211992] = 33, [211991] = 33,
    -- Hunter
    -- Stormwing Harrier's Camouflage
    [217181] = 32, [217182] = 32, [217183] = 32, [217184] = 32, [217185] = 32,
    -- Lightless Scavenger's Necessities
    [212023] = 33, [212021] = 33, [212020] = 33, [212019] = 33, [212018] = 33,
    -- Rogue
    -- Lurking Specter's Shadeweave
    [217206] = 32, [217207] = 32, [217208] = 32, [217209] = 32, [217210] = 32,
    -- K'areshi Phantom's Bindings
    [212041] = 33, [212039] = 33, [212038] = 33, [212037] = 33, [212036] = 33,
    -- Priest
    -- The Furnace Seraph's Verdict
    [217201] = 32, [217202] = 32, [217203] = 32, [217205] = 32, [217204] = 32,
    -- Shards of Living Luster
    [212084] = 33, [212083] = 33, [212082] = 33, [212086] = 33, [212081] = 33,
    -- Death Knight
    -- Risen Nightmare's Gravemantle
    [217221] = 32, [217222] = 32, [217223] = 32, [217224] = 32, [217225] = 32,
    -- Exhumed Centurion's Relics
    [212005] = 33, [212003] = 33, [212002] = 33, [212001] = 33, [212000] = 33,
    -- Shaman
    -- Vision of the Greatwolf Outcast
    [217236] = 32, [217237] = 32, [217238] = 32, [217239] = 32, [217240] = 32,
    -- Waves of the Forgotten Reservoir
    [212014] = 33, [212012] = 33, [212011] = 33, [212010] = 33, [212009] = 33,
    -- Mage
    -- Wayward Chronomancer's Clockwork
    [217235] = 32, [217231] = 32, [217232] = 32, [217233] = 32, [217234] = 32,
    -- Sparks of Violet Rebirth
    [212095] = 33, [212093] = 33, [212092] = 33, [212091] = 33, [212090] = 33,
    -- Warlock
    -- Sinister Savant's Cursethreads
    [217211] = 32, [217212] = 32, [217213] = 32, [217215] = 32, [217214] = 32,
    -- Rites of the Hexflame Coven
    [212075] = 33, [212074] = 33, [212073] = 33, [212077] = 33, [212072] = 33,
    -- Monk
    -- Wrappings of the Waking Fist
    [217186] = 32, [217187] = 32, [217188] = 32, [217189] = 32, [217190] = 32,
    -- Gatecrasher's Fortitude
    [212050] = 33, [212048] = 33, [212047] = 33, [212046] = 33, [212045] = 33,
    -- Druid
    -- Strands of the Autumn Blaze
    [217191] = 32, [217192] = 32, [217193] = 32, [217194] = 32, [217195] = 32,
    -- Mane of the Greatlynx
    [212059] = 33, [212057] = 33, [212056] = 33, [212055] = 33, [212054] = 33,
    -- Demon Hunter
    -- Screaming Torchfiend's Brutality
    [217226] = 32, [217227] = 32, [217228] = 32, [217229] = 32, [217230] = 32,
    -- Husk of the Hypogeal Nemesis
    [212068] = 33, [212066] = 33, [212065] = 33, [212064] = 33, [212063] = 33,
    -- Evoker
    -- Scales of the Awakened
    [217176] = 32, [217177] = 32, [217178] = 32, [217179] = 32, [217180] = 32,
    -- Destroyer's Scarred Wards
    [212032] = 33, [212030] = 33, [212029] = 33, [212028] = 33, [212027] = 33,
}
---AUTO_GENERATED TAILING InfoItemLevelItemSets

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
}

local minTierIndex = math.huge
for _, tierIndex in pairs(tierSetItemIDs) do
    if tierIndex < minTierIndex then
        minTierIndex = tierIndex
    end
end

statisticSlots[11] = {'T' .. minTierIndex}
statisticSlots[12] = {'T' .. (minTierIndex + 1)}

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
        frame.slots[12].value:SetTextColor(0, 1, 0)
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
            if tierSetItemIDs[itemID] > minTierIndex then
                slot.newTier = true
            else
                slot.oldTier = true
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
                        enchantmentData.classID == classID and
                        (type(enchantmentData.subClassIDs) == 'boolean' or tContains(enchantmentData.subClassIDs, subclassID))
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
