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

local tContains = tContains

local ADDON_MISSING = ADDON_MISSING

---AUTO_GENERATED LEADING InfoItemLevelEnchantments
local armorEnchantments = {
    [1] = { -- Head
        [7052] = true, -- Incandescent Essence
    },
    [2] = false, -- Neck
    [3] = false, -- Shoulder
    [5] = { -- Chest
        [6616] = {0, 1, 2, 3, 4}, -- Accelerated Agility (Tier 3)
        [6619] = {0, 1, 2, 3, 4}, -- Reserve of Intellect (Tier 3)
        [6622] = {0, 1, 2, 3, 4}, -- Sustained Strength (Tier 3)
        [6625] = {0, 1, 2, 3, 4}, -- Waking Stats (Tier 3)
    },
    [6] = { -- Waist
        [6904] = {1, 2, 3, 4}, -- Shadowed Belt Clasp (Tier 3)
    },
    [7] = { -- Legs
        [6490] = {1, 2, 3, 4}, -- Fierce Armor Kit (Tier 3)
        [6496] = {1, 2, 3, 4}, -- Frosted Armor Kit (Tier 3)
        [6541] = {1, 2, 3, 4}, -- Frozen Spellthread (Tier 3)
        [6544] = {1, 2, 3, 4}, -- Temporal Spellthread (Tier 3)
        [6830] = {1, 2, 3, 4}, -- Lambent Armor Kit (Tier 3)
    },
    [8] = { -- Feet
        [6607] = {0, 1, 2, 3, 4}, -- Plainsrunner's Breeze (Tier 3)
        [6610] = {0, 1, 2, 3, 4}, -- Rider's Reassurance (Tier 3)
        [6613] = {0, 1, 2, 3, 4}, -- Watcher's Loam (Tier 3)
    },
    [9] = { -- Wrist
        [6574] = {0, 1, 2, 3, 4}, -- Devotion of Avoidance (Tier 3)
        [6580] = {0, 1, 2, 3, 4}, -- Devotion of Leech (Tier 3)
        [6586] = {0, 1, 2, 3, 4}, -- Devotion of Speed (Tier 3)
    },
    [10] = false, -- Hands
    [11] = { -- Finger0
        [6550] = {0, 1, 2, 3, 4}, -- Devotion of Critical Strike (Tier 3)
        [6556] = {0, 1, 2, 3, 4}, -- Devotion of Haste (Tier 3)
        [6562] = {0, 1, 2, 3, 4}, -- Devotion of Mastery (Tier 3)
        [6568] = {0, 1, 2, 3, 4}, -- Devotion of Versatility (Tier 3)
    },
    [12] = { -- Finger1
        [6550] = {0, 1, 2, 3, 4}, -- Devotion of Critical Strike (Tier 3)
        [6556] = {0, 1, 2, 3, 4}, -- Devotion of Haste (Tier 3)
        [6562] = {0, 1, 2, 3, 4}, -- Devotion of Mastery (Tier 3)
        [6568] = {0, 1, 2, 3, 4}, -- Devotion of Versatility (Tier 3)
    },
    [13] = false, -- Trinket0
    [14] = false, -- Trinket1
    [15] = { -- Back
        [6589] = {0, 1, 2, 3, 4}, -- Writ of Avoidance (Tier 3)
        [6592] = {0, 1, 2, 3, 4}, -- Graceful Avoidance (Tier 3)
        [6595] = {0, 1, 2, 3, 4}, -- Writ of Leech (Tier 3)
        [6598] = {0, 1, 2, 3, 4}, -- Regenerative Leech (Tier 3)
        [6601] = {0, 1, 2, 3, 4}, -- Writ of Speed (Tier 3)
        [6604] = {0, 1, 2, 3, 4}, -- Homebound Speed (Tier 3)
    },
}

local weaponEnchantments = {
    [3368] = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}, -- Rune of the Fallen Crusader
    [3370] = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}, -- Rune of Razorice
    [3847] = {1, 5, 6, 8, 10}, -- Rune of the Stoneskin Gargoyle
    [6241] = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}, -- Rune of Sanguination
    [6242] = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}, -- Rune of Spellwarding
    [6243] = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}, -- Rune of Hysteria
    [6244] = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}, -- Rune of Unending Thirst
    [6245] = {0, 1, 4, 5, 6, 7, 8, 10, 13, 14, 15, 17}, -- Rune of the Apocalypse
    [6522] = {2, 3, 18}, -- Gyroscopic Kaleidoscope (Tier 3)
    [6525] = {2, 3, 18}, -- Projectile Propulsion Pinion (Tier 3)
    [6528] = {2, 3, 18}, -- High Intensity Thermal Scanner (Tier 3)
    [6628] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Burning Writ (Tier 3)
    [6631] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Burning Devotion (Tier 3)
    [6634] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Earthen Writ (Tier 3)
    [6637] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Earthen Devotion (Tier 3)
    [6640] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Sophic Writ (Tier 3)
    [6643] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Sophic Devotion (Tier 3)
    [6646] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Frozen Writ (Tier 3)
    [6649] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Frozen Devotion (Tier 3)
    [6652] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Wafting Writ (Tier 3)
    [6655] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Wafting Devotion (Tier 3)
    [6824] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Spore Tender (Tier 3)
    [6827] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Shadowflame Wreathe (Tier 3)
    [7003] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 19}, -- Enchant Weapon: Dreaming Devotion (Tier 3)
}
---AUTO_GENERATED TAILING InfoItemLevelEnchantments

---AUTO_GENERATED LEADING InfoItemLevelItemSets
local tierSetItemIDs = {
    -- Warrior
    -- Molten Vanguard's Mortarplate
    [207180] = 31, [207181] = 31, [207182] = 31, [207183] = 31, [207185] = 31,
    -- Irons of the Onyx Crucible
    [217216] = 32, [217217] = 32, [217218] = 32, [217219] = 32, [217220] = 32,
    -- Paladin
    -- Zealous Pyreknight's Ardor
    [207189] = 31, [207190] = 31, [207191] = 31, [207192] = 31, [207194] = 31,
    -- Heartfire Sentinel's Authority
    [217196] = 32, [217197] = 32, [217198] = 32, [217199] = 32, [217200] = 32,
    -- Hunter
    -- Blazing Dreamstalker's Trophies
    [207216] = 31, [207217] = 31, [207218] = 31, [207219] = 31, [207221] = 31,
    -- Stormwing Harrier's Camouflage
    [217181] = 32, [217182] = 32, [217183] = 32, [217184] = 32, [217185] = 32,
    -- Rogue
    -- Lucid Shadewalker's Silence
    [207234] = 31, [207235] = 31, [207236] = 31, [207237] = 31, [207239] = 31,
    -- Lurking Specter's Shadeweave
    [217206] = 32, [217207] = 32, [217208] = 32, [217209] = 32, [217210] = 32,
    -- Priest
    -- Blessings of Lunar Communion
    [207279] = 31, [207280] = 31, [207281] = 31, [207282] = 31, [207284] = 31,
    -- The Furnace Seraph's Verdict
    [217201] = 32, [217202] = 32, [217203] = 32, [217205] = 32, [217204] = 32,
    -- Death Knight
    -- Risen Nightmare's Gravemantle
    [207198] = 31, [207199] = 31, [207200] = 31, [207201] = 31, [207203] = 31,
    -- Risen Nightmare's Gravemantle
    [217221] = 32, [217222] = 32, [217223] = 32, [217224] = 32, [217225] = 32,
    -- Shaman
    -- Vision of the Greatwolf Outcast
    [207207] = 31, [207208] = 31, [207209] = 31, [207210] = 31, [207212] = 31,
    -- Vision of the Greatwolf Outcast
    [217236] = 32, [217237] = 32, [217238] = 32, [217239] = 32, [217240] = 32,
    -- Mage
    -- Wayward Chronomancer's Clockwork
    [207288] = 31, [207289] = 31, [207290] = 31, [207291] = 31, [207293] = 31,
    -- Wayward Chronomancer's Clockwork
    [217235] = 32, [217231] = 32, [217232] = 32, [217233] = 32, [217234] = 32,
    -- Warlock
    -- Devout Ashdevil's Pactweave
    [207270] = 31, [207271] = 31, [207272] = 31, [207273] = 31, [207275] = 31,
    -- Sinister Savant's Cursethreads
    [217211] = 32, [217212] = 32, [217213] = 32, [217215] = 32, [217214] = 32,
    -- Monk
    -- Mystic Heron's Discipline
    [207243] = 31, [207244] = 31, [207245] = 31, [207246] = 31, [207248] = 31,
    -- Wrappings of the Waking Fist
    [217186] = 32, [217187] = 32, [217188] = 32, [217189] = 32, [217190] = 32,
    -- Druid
    -- Benevolent Embersage's Guidance
    [207252] = 31, [207253] = 31, [207254] = 31, [207255] = 31, [207257] = 31,
    -- Strands of the Autumn Blaze
    [217191] = 32, [217192] = 32, [217193] = 32, [217194] = 32, [217195] = 32,
    -- Demon Hunter
    -- Screaming Torchfiend's Brutality
    [207261] = 31, [207262] = 31, [207263] = 31, [207264] = 31, [207266] = 31,
    -- Screaming Torchfiend's Brutality
    [217226] = 32, [217227] = 32, [217228] = 32, [217229] = 32, [217230] = 32,
    -- Evoker
    -- Werynkeeper's Timeless Vigil
    [207225] = 31, [207226] = 31, [207227] = 31, [207228] = 31, [207230] = 31,
    -- Scales of the Awakened
    [217176] = 32, [217177] = 32, [217178] = 32, [217179] = 32, [217180] = 32,
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

    hooksecurefunc(M, 'UpdatePageStrings', function(_, i, iLevelDB, inspectItem, slotInfo, which)
        local unitID = which == 'Character' and 'player' or _G.InspectFrame.unit

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
            local expectedClassID = (i == 16 or i == 17) and 2 or 4
            local enchantments = (expectedClassID == 2) and weaponEnchantments or armorEnchantments[i]
            if enchant and (not enchantments or enchantments[enchant]) then
                slot.enchants = true
                slot.enchantSlots = true
            elseif enchantments and (not enchant or not enchantments[enchant]) then
                local classID, subclassID = select(6, C_Item_GetItemInfoInstant(itemLink))
                if classID == expectedClassID then
                    local canEnchant = false

                    for _, subClasses in pairs(enchantments) do
                        if type(subClasses) == 'boolean' or tContains(subClasses, subclassID) then
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
        end
    end)
end

RI:RegisterPipeline(InfoItemLevel)
