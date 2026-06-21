local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local M = E:GetModule('Misc')

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
    [1] = { -- Head
        [7961] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Helm - Empowered Hex of Leeching (Tier 2)
        [7991] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Helm - Empowered Blessing of Speed (Tier 2)
        [8017] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Helm - Empowered Rune of Avoidance (Tier 2)
        [8702] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- R0CKY
    },
    [2] = false, -- Neck
    [3] = { -- Shoulder
        [7973] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Shoulders - Akil'zon's Swiftness (Tier 2)
        [8001] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Shoulders - Amirdrassil's Grace (Tier 2)
        [8031] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Shoulders - Silvermoon's Mending (Tier 2)
    },
    [5] = { -- Chest
        [7957] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Chest - Mark of Nalorakk (Tier 2)
        [7985] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Chest - Mark of the Rootwarden (Tier 2)
        [7987] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Chest - Mark of the Worldsoul (Tier 2)
        [8013] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Chest - Mark of the Magister (Tier 2)
    },
    [6] = false, -- Waist
    [7] = { -- Legs
        [7935] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Sunfire Silk Spellthread (Tier 2)
        [7937] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Arcanoweave Spellthread (Tier 2)
        [8159] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Forest Hunter's Armor Kit (Tier 2)
        [8163] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Blood Knight's Armor Kit (Tier 2)
    },
    [8] = { -- Feet
        [7963] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Boots - Lynx's Dexterity (Tier 2)
        [7993] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Boots - Shaladrassil's Roots (Tier 2)
        [8019] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Boots - Farstrider's Hunt (Tier 2)
    },
    [9] = false, -- Wrist
    [10] = false, -- Hands
    [11] = { -- Finger 1
        [7967] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Eyes of the Eagle (Tier 2)
        [7969] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Zul'jin's Mastery (Tier 2)
        [7997] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Nature's Fury (Tier 2)
        [8025] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Silvermoon's Alacrity (Tier 2)
        [8027] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Silvermoon's Tenacity (Tier 2)
    },
    [12] = { -- Finger 2
        [7967] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Eyes of the Eagle (Tier 2)
        [7969] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Zul'jin's Mastery (Tier 2)
        [7997] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Nature's Fury (Tier 2)
        [8025] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Silvermoon's Alacrity (Tier 2)
        [8027] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Enchant Ring - Silvermoon's Tenacity (Tier 2)
    },
    [13] = false, -- Trinket 1
    [14] = false, -- Trinket 2
    [15] = false, -- Back
    [16] = { -- Main Hand
        [3368] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Fallen Crusader
        [3370] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Razorice
        [3847] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Stoneskin Gargoyle
        [6241] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Sanguination
        [6242] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Spellwarding
        [6244] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Unending Thirst
        [6245] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Apocalypse
        [7979] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Strength of Halazzi (Tier 2)
        [7981] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Jan'alai's Precision (Tier 2)
        [7983] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Berserker's Rage (Tier 2)
        [8007] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Worldsoul Cradle (Tier 2)
        [8009] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Worldsoul Aegis (Tier 2)
        [8011] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Worldsoul Tenacity (Tier 2)
        [8037] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Flames of the Sin'dorei (Tier 2)
        [8039] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Acuity of the Ren'dorei (Tier 2)
        [8041] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Arcane Mastery (Tier 2)
        [8613] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Smuggler's Lynxeye (Tier 2)
        [8615] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Farstrider's Hawkeye (Tier 2)
        [8689] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Rite of the Hash'ey (Tier 2)
    },
    [17] = { -- Off Hand
        [3368] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Fallen Crusader
        [3370] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Razorice
        [3847] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Stoneskin Gargoyle
        [6241] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Sanguination
        [6242] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Spellwarding
        [6244] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of Unending Thirst
        [6245] = {classID = 2, subClassIDs = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}}, -- Rune of the Apocalypse
        [7979] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Strength of Halazzi (Tier 2)
        [7981] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Jan'alai's Precision (Tier 2)
        [7983] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Berserker's Rage (Tier 2)
        [8007] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Worldsoul Cradle (Tier 2)
        [8009] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Worldsoul Aegis (Tier 2)
        [8011] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Worldsoul Tenacity (Tier 2)
        [8037] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Flames of the Sin'dorei (Tier 2)
        [8039] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Acuity of the Ren'dorei (Tier 2)
        [8041] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Arcane Mastery (Tier 2)
        [8613] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Smuggler's Lynxeye (Tier 2)
        [8615] = {classID = 2, subClassIDs = {2, 3, 18}}, -- Farstrider's Hawkeye (Tier 2)
        [8689] = {classID = 2, subClassIDs = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19}}, -- Enchant Weapon - Rite of the Hash'ey (Tier 2)
    },
    ---AUTO_GENERATED TAILING InfoItemLevelEnchantments
}

local tierSetItemIDs = {
    ---AUTO_GENERATED LEADING InfoItemLevelItemSets
    -- Warrior
    -- Rage of the Night Ender
    [249955] = 1, [249953] = 1, [249952] = 1, [249951] = 1, [249950] = 1,
    -- Jade Warlord's Dominion
    [271459] = 2, [271457] = 2, [271456] = 2, [271455] = 2, [271454] = 2,
    -- Paladin
    -- Luminant Verdict's Vestments
    [249964] = 1, [249962] = 1, [249961] = 1, [249960] = 1, [249959] = 1,
    -- Radiance of the Consecrated Flame
    [271468] = 2, [271466] = 2, [271465] = 2, [271464] = 2, [271463] = 2,
    -- Hunter
    -- Primal Sentry's Camouflage
    [249991] = 1, [249989] = 1, [249988] = 1, [249987] = 1, [249986] = 1,
    -- Skulking Viper's Ambush
    [271495] = 2, [271493] = 2, [271492] = 2, [271491] = 2, [271490] = 2,
    -- Rogue
    -- Motley of the Grim Jest
    [250009] = 1, [250007] = 1, [250006] = 1, [250005] = 1, [250004] = 1,
    -- Chosen Bloodslayer's Hexweave
    [271513] = 2, [271511] = 2, [271510] = 2, [271509] = 2, [271508] = 2,
    -- Priest
    -- Blind Oath's Burden
    [250052] = 1, [250051] = 1, [250050] = 1, [250054] = 1, [250049] = 1,
    -- Cosmic Penitent's Raiment
    [271556] = 2, [271555] = 2, [271554] = 2, [271558] = 2, [271553] = 2,
    -- Death Knight
    -- Relentless Rider's Lament
    [249973] = 1, [249971] = 1, [249970] = 1, [249969] = 1, [249968] = 1,
    -- Baleful Grave-Knight's Crucible
    [271477] = 2, [271475] = 2, [271474] = 2, [271473] = 2, [271472] = 2,
    -- Shaman
    -- Mantle of the Primal Core
    [249982] = 1, [249980] = 1, [249979] = 1, [249978] = 1, [249977] = 1,
    -- Ophidian Oracle's Prophecy
    [271486] = 2, [271484] = 2, [271483] = 2, [271482] = 2, [271481] = 2,
    -- Mage
    -- Voidbreaker's Accordance
    [250063] = 1, [250061] = 1, [250060] = 1, [250059] = 1, [250058] = 1,
    -- Primal Leywarden's Attire
    [271567] = 2, [271565] = 2, [271564] = 2, [271563] = 2, [271562] = 2,
    -- Warlock
    -- Reign of the Abyssal Immolator
    [250043] = 1, [250042] = 1, [250041] = 1, [250045] = 1, [250040] = 1,
    -- Damned Necrolyte's Shattered Restraints
    [271547] = 2, [271546] = 2, [271545] = 2, [271549] = 2, [271544] = 2,
    -- Monk
    -- Way of Ra-den's Chosen
    [250018] = 1, [250016] = 1, [250015] = 1, [250014] = 1, [250013] = 1,
    -- Guile of the Monkey King
    [271522] = 2, [271520] = 2, [271519] = 2, [271518] = 2, [271517] = 2,
    -- Druid
    -- Sprouts of the Luminous Bloom
    [250027] = 1, [250025] = 1, [250024] = 1, [250023] = 1, [250022] = 1,
    -- Bark of the Enigmatic Dreamwatcher
    [271531] = 2, [271529] = 2, [271528] = 2, [271527] = 2, [271526] = 2,
    -- Demon Hunter
    -- Devouring Reaver's Sheathe
    [250036] = 1, [250034] = 1, [250033] = 1, [250032] = 1, [250031] = 1,
    -- Abyssal Doomhound's Pursuit
    [271540] = 2, [271538] = 2, [271537] = 2, [271536] = 2, [271535] = 2,
    -- Evoker
    -- Livery of the Black Talon
    [250000] = 1, [249998] = 1, [249997] = 1, [249996] = 1, [249995] = 1,
    -- Echo of Calamity
    [271504] = 2, [271502] = 2, [271501] = 2, [271500] = 2, [271499] = 2,
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

    local isTimewalking = PlayerGetTimerunningSeasonID()
    local maxLevel = E.expansionLevelMax

    for slotID, info in pairs(data) do
        gems = gems + info.gems
        gemSlots = gemSlots + info.gemSlots

        if not isTimewalking then
            -- The War Within
            if maxLevel == 80 and (
                (slotID == 2 and info.gemSlots < 2) or
                (slotID == 11 and info.gemSlots < 2) or
                (slotID == 12 and info.gemSlots < 2)
            ) then
                isMissingGemSlots = true
            end
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

    if PlayerGetTimerunningSeasonID() then
        gearEnchantments = {}
    end

    hooksecurefunc(M, 'UpdatePageStrings', function(_, i, iLevelDB, inspectItem, slotInfo, which)
        local unitID = which == 'Character' and 'player' or _G.InspectFrame.unit
        if UnitLevel(unitID) < E.expansionLevelMax then return end

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
