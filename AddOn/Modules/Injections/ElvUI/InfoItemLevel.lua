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
        [7654] = {classID = 4, subClassIDs = {1, 2, 3, 4}}, -- Charged Armor Kit (Tier 3)
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
    -- Underpin Strongarm's Muscle
    [229238] = 1, [229236] = 1, [229235] = 1, [229234] = 1, [229233] = 1,
    -- Chains of the Living Weapon
    [237613] = 2, [237611] = 2, [237610] = 2, [237609] = 2, [237608] = 2,
    -- Paladin
    -- Oath of the Aureate Sentry
    [229247] = 1, [229245] = 1, [229244] = 1, [229243] = 1, [229242] = 1,
    -- Vows of the Lucent Battalion
    [237622] = 2, [237620] = 2, [237619] = 2, [237618] = 2, [237617] = 2,
    -- Hunter
    -- Tireless Collector's Bounties
    [229274] = 1, [229272] = 1, [229271] = 1, [229270] = 1, [229269] = 1,
    -- Midnight Herald's Pledge
    [237649] = 2, [237647] = 2, [237646] = 2, [237645] = 2, [237644] = 2,
    -- Rogue
    -- Spectral Gambler's Last Call
    [229292] = 1, [229290] = 1, [229289] = 1, [229288] = 1, [229287] = 1,
    -- Shroud of the Sudden Eclipse
    [237667] = 2, [237665] = 2, [237664] = 2, [237663] = 2, [237662] = 2,
    -- Priest
    -- Confessor's Unshakable Virtue
    [229337] = 1, [229335] = 1, [229334] = 1, [229333] = 1, [229332] = 1,
    -- Eulogy to a Dying Star
    [237710] = 2, [237709] = 2, [237708] = 2, [237712] = 2, [237707] = 2,
    -- Death Knight
    -- Cauldron Champion's Encore
    [229256] = 1, [229254] = 1, [229253] = 1, [229252] = 1, [229251] = 1,
    -- Hollow Sentinel's Wake
    [237631] = 2, [237629] = 2, [237628] = 2, [237627] = 2, [237626] = 2,
    -- Shaman
    -- Currents of the Gale Sovereign
    [229265] = 1, [229263] = 1, [229262] = 1, [229261] = 1, [229260] = 1,
    -- Howls of Channeled Fury
    [237640] = 2, [237638] = 2, [237637] = 2, [237636] = 2, [237635] = 2,
    -- Mage
    -- Jewels of the Aspectral Emissary
    [229346] = 1, [229344] = 1, [229343] = 1, [229342] = 1, [229341] = 1,
    -- Augur's Ephemeral Plumage
    [237721] = 2, [237719] = 2, [237718] = 2, [237717] = 2, [237716] = 2,
    -- Warlock
    -- Spliced Fiendtrader's Influence
    [229326] = 1, [229325] = 1, [229324] = 1, [229328] = 1, [229323] = 1,
    -- Inquisitor's Feast of Madness
    [237701] = 2, [237700] = 2, [237699] = 2, [237703] = 2, [237698] = 2,
    -- Monk
    -- Ageless Serpent's Foresight
    [229301] = 1, [229299] = 1, [229298] = 1, [229297] = 1, [229296] = 1,
    -- Crash of Fallen Storms
    [237676] = 2, [237674] = 2, [237673] = 2, [237672] = 2, [237671] = 2,
    -- Druid
    -- Roots of Reclaiming Blight
    [229310] = 1, [229308] = 1, [229307] = 1, [229306] = 1, [229305] = 1,
    -- Ornaments of the Mother Eagle
    [237685] = 2, [237683] = 2, [237682] = 2, [237681] = 2, [237680] = 2,
    -- Demon Hunter
    -- Fel-Dealer's Contraband
    [229319] = 1, [229317] = 1, [229316] = 1, [229315] = 1, [229314] = 1,
    -- Charhound's Vicious Hunt
    [237694] = 2, [237692] = 2, [237691] = 2, [237690] = 2, [237689] = 2,
    -- Evoker
    -- Opulent Treasurescale's Hoard
    [229283] = 1, [229281] = 1, [229280] = 1, [229279] = 1, [229278] = 1,
    -- Spellweaver's Immaculate Design
    [237658] = 2, [237656] = 2, [237655] = 2, [237654] = 2, [237653] = 2,
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
