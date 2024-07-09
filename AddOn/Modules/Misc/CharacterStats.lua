-- From EKCore and NDui
-- https://github.com/EKE00372/EKCore/blob/master/Interface/CharacterStats.lua
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Misc/MissingStats.lua

local R, E, L, V, P, G = unpack((select(2, ...)))
local CS = R:NewModule('CharacterStats', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local max = max
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local C_PaperDollInfo_GetMinItemLevel = C_PaperDollInfo.GetMinItemLevel
local C_PaperDollInfo_OffhandHasShield = C_PaperDollInfo.OffhandHasShield
local CreateFrame = CreateFrame
local GetAverageItemLevel = GetAverageItemLevel

local LE_UNIT_STAT_AGILITY = LE_UNIT_STAT_AGILITY
local LE_UNIT_STAT_INTELLECT = LE_UNIT_STAT_INTELLECT
local LE_UNIT_STAT_STRENGTH = LE_UNIT_STAT_STRENGTH
local STAT_AVERAGE_ITEM_LEVEL = STAT_AVERAGE_ITEM_LEVEL
local STAT_AVOIDANCE = STAT_AVOIDANCE
local STAT_BLOCK = STAT_BLOCK
local STAT_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE
local STAT_DODGE = STAT_DODGE
local STAT_HASTE = STAT_HASTE
local STAT_LIFESTEAL = STAT_LIFESTEAL
local STAT_MASTERY = STAT_MASTERY
local STAT_PARRY = STAT_PARRY
local STAT_SPEED = STAT_SPEED
local STAT_VERSATILITY = STAT_VERSATILITY

function CS:Initialize()
    local statPanel = CreateFrame('Frame', nil, _G.CharacterFrameInsetRight)
    statPanel:SetSize(200, 350)
    statPanel:SetPoint('TOP', 0, -5)

    local scrollFrame = CreateFrame('ScrollFrame', nil, statPanel, 'UIPanelScrollFrameTemplate')
    scrollFrame:SetAllPoints()
    scrollFrame.ScrollBar:Hide()
    scrollFrame.ScrollBar.Show = E.noop

    local stat = CreateFrame('Frame', nil, scrollFrame)
    stat:SetSize(200, 1)
    scrollFrame:SetScrollChild(stat)

    _G.CharacterStatsPane:ClearAllPoints()
    _G.CharacterStatsPane:SetParent(stat)
    _G.CharacterStatsPane:SetAllPoints(stat)

    hooksecurefunc('PaperDollFrame_UpdateSidebarTabs', function()
        statPanel:SetShown(_G.CharacterStatsPane:IsShown())
    end)

    local precisionStat = {
        [STAT_CRITICAL_STRIKE] = true,
        [STAT_MASTERY]         = true,
        [STAT_HASTE]           = true,
        [STAT_VERSATILITY]     = true,
        [STAT_LIFESTEAL]       = true,
        [STAT_AVOIDANCE]       = true,
        [STAT_SPEED]           = true,
        [STAT_DODGE]           = true,
        [STAT_BLOCK]           = true,
        [STAT_PARRY]           = true
    }

    hooksecurefunc('PaperDollFrame_SetLabelAndText', function(statFrame, label, _, isPercentage)
        if isPercentage or precisionStat[label] then
            statFrame.Value:SetFormattedText('%.2f%%', statFrame.numericValue)
        end
    end)

    ---@diagnostic disable-next-line: inject-field
    _G.PAPERDOLL_STATCATEGORIES = {
        [1] = {
            categoryFrame = 'AttributesCategory',
            stats = {
                [1] = {stat = 'STRENGTH', primary = LE_UNIT_STAT_STRENGTH},
                [2] = {stat = 'AGILITY', primary = LE_UNIT_STAT_AGILITY},
                [3] = {stat = 'INTELLECT', primary = LE_UNIT_STAT_INTELLECT},
                [4] = {stat = 'STAMINA'},
                [5] = {stat = 'ARMOR'},
                [6] = {stat = 'STAGGER', hideAt = 0, roles = {'TANK'}},
                [7] = {stat = 'ATTACK_DAMAGE', primary = LE_UNIT_STAT_STRENGTH, roles = {'TANK', 'DAMAGER'}},
                [8] = {stat = 'ATTACK_AP', hideAt = 0, primary = LE_UNIT_STAT_STRENGTH, roles = {'TANK', 'DAMAGER'}},
                [9] = {stat = 'ATTACK_ATTACKSPEED', primary = LE_UNIT_STAT_STRENGTH, roles = {'TANK', 'DAMAGER'}},
                [10] = {stat = 'ATTACK_DAMAGE', primary = LE_UNIT_STAT_AGILITY, roles = {'TANK', 'DAMAGER'}},
                [11] = {stat = 'ATTACK_AP', hideAt = 0, primary = LE_UNIT_STAT_AGILITY, roles = {'TANK', 'DAMAGER'}},
                [12] = {stat = 'ATTACK_ATTACKSPEED', primary = LE_UNIT_STAT_AGILITY, roles = {'TANK', 'DAMAGER'}},
                [13] = {stat = 'SPELLPOWER', hideAt = 0, primary = LE_UNIT_STAT_INTELLECT},
                [14] = {stat = 'MANAREGEN', hideAt = 0, primary = LE_UNIT_STAT_INTELLECT},
                [15] = {stat = 'ENERGY_REGEN', hideAt = 0, primary = LE_UNIT_STAT_AGILITY},
                [16] = {stat = 'RUNE_REGEN', hideAt = 0, primary = LE_UNIT_STAT_STRENGTH},
                [17] = {stat = 'FOCUS_REGEN', hideAt = 0, primary = LE_UNIT_STAT_AGILITY},
                [18] = {stat = 'MOVESPEED'}
            }
        },
        [2] = {
            categoryFrame = 'EnhancementsCategory',
            stats = {
                {stat = 'CRITCHANCE', hideAt = 0},
                {stat = 'HASTE', hideAt = 0},
                {stat = 'MASTERY', hideAt = 0},
                {stat = 'VERSATILITY', hideAt = 0},
                {stat = 'LIFESTEAL', hideAt = 0},
                {stat = 'AVOIDANCE', hideAt = 0},
                {stat = 'SPEED', hideAt = 0},
                {stat = 'DODGE', roles = {'TANK'}},
                {stat = 'PARRY', hideAt = 0, roles = {'TANK'}},
                {stat = 'BLOCK', hideAt = 0, showFunc = C_PaperDollInfo_OffhandHasShield}
            }
        }
    }

    hooksecurefunc('PaperDollFrame_SetItemLevel', function(statFrame, unit)
        if unit ~= 'player' then return end

        local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
        local minItemLevel = C_PaperDollInfo_GetMinItemLevel()

        avgItemLevelEquipped = max(minItemLevel or 0, avgItemLevelEquipped)

        local displayAvgItemLevel = E:Round(avgItemLevel, 2)
        local displayAvgItemLevelEquipped = E:Round(avgItemLevelEquipped, 2)

        local displayFullItemLevel = displayAvgItemLevel == displayAvgItemLevelEquipped
            and displayAvgItemLevel
            or (displayAvgItemLevelEquipped ..' / '.. displayAvgItemLevel)

        _G.PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, displayFullItemLevel, false, displayFullItemLevel)
    end)
end

R:RegisterModule(CS:GetName())
