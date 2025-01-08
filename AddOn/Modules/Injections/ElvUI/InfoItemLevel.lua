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
        [7355] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Stormrider's Agility (Tier 3)
        [7358] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Council's Intellect (Tier 3)
        [7361] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Oathsworn's Strength (Tier 3)
        [7364] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Crystalline Radiance (Tier 3)
    },
    [6] = false, -- Waist
    [7] = { -- Legs
        [7531] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Daybreak Spellthread (Tier 3)
        [7534] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Sunset Spellthread (Tier 3)
        [7595] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Defender's Armor Kit (Tier 3)
        [7601] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Stormbound Armor Kit (Tier 3)
    },
    [8] = { -- Feet
        [7418] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Scout's March (Tier 3)
        [7421] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Cavalry's March (Tier 3)
        [7424] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Defender's March (Tier 3)
    },
    [9] = { -- Wrist
        [7385] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Armored Avoidance (Tier 3)
        [7391] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Armored Leech (Tier 3)
        [7397] = {classID = 4, subClassIDs = {0, 1, 2, 3, 4}}, -- Chant of Armored Speed (Tier 3)
    },
    [10] = false, -- Hands
    [11] = { -- Finger 1
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

local tierSetItemIDs = {
    ---AUTO_GENERATED LEADING InfoItemLevelItemSets
    -- Warrior
    -- Warsculptor's Masterwork
    [211987] = 1, [211985] = 1, [211984] = 1, [211983] = 1, [211982] = 1,
    -- Underpin Strongarm's Muscle
    [229238] = 2, [229236] = 2, [229235] = 2, [229234] = 2, [229233] = 2,
    -- Paladin
    -- Entombed Seraph's Radiance
    [211996] = 1, [211994] = 1, [211993] = 1, [211992] = 1, [211991] = 1,
    -- Oath of the Aureate Sentry
    [229247] = 2, [229245] = 2, [229244] = 2, [229243] = 2, [229242] = 2,
    -- Hunter
    -- Lightless Scavenger's Necessities
    [212023] = 1, [212021] = 1, [212020] = 1, [212019] = 1, [212018] = 1,
    -- Tireless Collector's Bounties
    [229274] = 2, [229272] = 2, [229271] = 2, [229270] = 2, [229269] = 2,
    -- Rogue
    -- K'areshi Phantom's Bindings
    [212041] = 1, [212039] = 1, [212038] = 1, [212037] = 1, [212036] = 1,
    -- Spectral Gambler's Last Call
    [229292] = 2, [229290] = 2, [229289] = 2, [229288] = 2, [229287] = 2,
    -- Priest
    -- Shards of Living Luster
    [212084] = 1, [212083] = 1, [212082] = 1, [212086] = 1, [212081] = 1,
    -- Confessor's Unshakable Virtue
    [229337] = 2, [229335] = 2, [229334] = 2, [229333] = 2, [229332] = 2,
    -- Death Knight
    -- Exhumed Centurion's Relics
    [212005] = 1, [212003] = 1, [212002] = 1, [212001] = 1, [212000] = 1,
    -- Cauldron Champion's Encore
    [229256] = 2, [229254] = 2, [229253] = 2, [229252] = 2, [229251] = 2,
    -- Shaman
    -- Waves of the Forgotten Reservoir
    [212014] = 1, [212012] = 1, [212011] = 1, [212010] = 1, [212009] = 1,
    -- Currents of the Gale Sovereign
    [229265] = 2, [229263] = 2, [229262] = 2, [229261] = 2, [229260] = 2,
    -- Mage
    -- Sparks of Violet Rebirth
    [212095] = 1, [212093] = 1, [212092] = 1, [212091] = 1, [212090] = 1,
    -- Jewels of the Aspectral Emissary
    [229346] = 2, [229344] = 2, [229343] = 2, [229342] = 2, [229341] = 2,
    -- Warlock
    -- Rites of the Hexflame Coven
    [212075] = 1, [212074] = 1, [212073] = 1, [212077] = 1, [212072] = 1,
    -- Spliced Fiendtrader's Influence
    [229326] = 2, [229325] = 2, [229324] = 2, [229328] = 2, [229323] = 2,
    -- Monk
    -- Gatecrasher's Fortitude
    [212050] = 1, [212048] = 1, [212047] = 1, [212046] = 1, [212045] = 1,
    -- Ageless Serpent's Foresight
    [229301] = 2, [229299] = 2, [229298] = 2, [229297] = 2, [229296] = 2,
    -- Druid
    -- Mane of the Greatlynx
    [212059] = 1, [212057] = 1, [212056] = 1, [212055] = 1, [212054] = 1,
    -- Roots of Reclaiming Blight
    [229310] = 2, [229308] = 2, [229307] = 2, [229306] = 2, [229305] = 2,
    -- Demon Hunter
    -- Husk of the Hypogeal Nemesis
    [212068] = 1, [212066] = 1, [212065] = 1, [212064] = 1, [212063] = 1,
    -- Fel-Dealer's Contraband
    [229319] = 2, [229317] = 2, [229316] = 2, [229315] = 2, [229314] = 2,
    -- Evoker
    -- Destroyer's Scarred Wards
    [212032] = 1, [212030] = 1, [212029] = 1, [212028] = 1, [212027] = 1,
    -- Opulent Treasurescale's Hoard
    [229283] = 2, [229281] = 2, [229280] = 2, [229279] = 2, [229278] = 2,
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

        -- The War Within
        if (
            (slotID == 2 and info.gemSlots < 2) or
            (slotID == 11 and info.gemSlots < 2) or
            (slotID == 12 and info.gemSlots < 2)
        ) then
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
