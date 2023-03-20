-- From EKCore and NDui
-- https://github.com/EKE00372/EKCore/blob/master/Interface/CharacterStats.lua
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Misc/MissingStats.lua

local R, E, L, V, P, G = unpack((select(2, ...)))
local CS = R:NewModule('CharacterStats', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local format, max = format, max

-- WoW API / Variables
local C_PaperDollInfo_GetMinItemLevel = C_PaperDollInfo.GetMinItemLevel
local C_PaperDollInfo_OffhandHasShield = C_PaperDollInfo.OffhandHasShield
local CreateFrame = CreateFrame
local GetAverageItemLevel = GetAverageItemLevel
local GetCombatRating = GetCombatRating
local GetCombatRatingBonus = GetCombatRatingBonus
local GetMeleeHaste = GetMeleeHaste
local hooksecurefunc = hooksecurefunc
local UnitAttackSpeed = UnitAttackSpeed

local BreakUpLargeNumbers = BreakUpLargeNumbers
local GetPaperDollSideBarFrame = GetPaperDollSideBarFrame
local MovementSpeed_OnUpdate = MovementSpeed_OnUpdate
local PaperDollFrame_SetEnergyRegen = PaperDollFrame_SetEnergyRegen
local PaperDollFrame_SetFocusRegen = PaperDollFrame_SetFocusRegen
local PaperDollFrame_SetRuneRegen = PaperDollFrame_SetRuneRegen

local ATTACK_SPEED = ATTACK_SPEED
local CR_SPEED = CR_SPEED
local CR_SPEED_TOOLTIP = CR_SPEED_TOOLTIP
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local HIGHLIGHT_FONT_COLOR_CODE = HIGHLIGHT_FONT_COLOR_CODE
local LE_UNIT_STAT_STRENGTH = LE_UNIT_STAT_STRENGTH
local LE_UNIT_STAT_AGILITY = LE_UNIT_STAT_AGILITY
local LE_UNIT_STAT_INTELLECT = LE_UNIT_STAT_INTELLECT
local PAPERDOLLFRAME_TOOLTIP_FORMAT = PAPERDOLLFRAME_TOOLTIP_FORMAT
local STAT_ATTACK_SPEED_BASE_TOOLTIP = STAT_ATTACK_SPEED_BASE_TOOLTIP
local STAT_AVERAGE_ITEM_LEVEL = STAT_AVERAGE_ITEM_LEVEL
local STAT_AVOIDANCE = STAT_AVOIDANCE
local STAT_BLOCK = STAT_BLOCK
local STAT_CRITICAL_STRIKE = STAT_CRITICAL_STRIKE
local STAT_DODGE = STAT_DODGE
local STAT_FORMAT = STAT_FORMAT
local STAT_HASTE = STAT_HASTE
local STAT_LIFESTEAL = STAT_LIFESTEAL
local STAT_MASTERY = STAT_MASTERY
local STAT_MOVEMENT_GROUND_TOOLTIP = STAT_MOVEMENT_GROUND_TOOLTIP
local STAT_MOVEMENT_FLIGHT_TOOLTIP = STAT_MOVEMENT_FLIGHT_TOOLTIP
local STAT_MOVEMENT_SWIM_TOOLTIP = STAT_MOVEMENT_SWIM_TOOLTIP
local STAT_MOVEMENT_SPEED = STAT_MOVEMENT_SPEED
local STAT_PARRY = STAT_PARRY
local STAT_SPEED = STAT_SPEED
local STAT_VERSATILITY = STAT_VERSATILITY
local WEAPON_SPEED = WEAPON_SPEED

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
        local frame = GetPaperDollSideBarFrame(1)
        if not frame:IsShown() then
            statPanel:Hide()
        else
            statPanel:Show()
        end
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

    _G.PaperDollFrame_SetLabelAndText = function(statFrame, label, text, isPercentage, numericValue)
        if statFrame.Label then
            statFrame.Label:SetText(format(STAT_FORMAT, label))
        end
        if precisionStat[label] then
            text = format('%.2f%%', numericValue)
        elseif isPercentage then
            text = format('%d%%', numericValue + 0.5)
        end
        statFrame.Value:SetText(text)
        statFrame.numericValue = numericValue
    end

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

    _G.PAPERDOLL_STATINFO['ENERGY_REGEN'].updateFunc = function(statFrame, unit)
        statFrame.numericValue = 0
        PaperDollFrame_SetEnergyRegen(statFrame, unit)
    end

    _G.PAPERDOLL_STATINFO['RUNE_REGEN'].updateFunc = function(statFrame, unit)
        statFrame.numericValue = 0
        PaperDollFrame_SetRuneRegen(statFrame, unit)
    end

    _G.PAPERDOLL_STATINFO['FOCUS_REGEN'].updateFunc = function(statFrame, unit)
        statFrame.numericValue = 0
        PaperDollFrame_SetFocusRegen(statFrame, unit)
    end

    -- Fix Movespeed
    _G.PAPERDOLL_STATINFO['MOVESPEED'].updateFunc = function(statFrame, unit)
        _G.PaperDollFrame_SetMovementSpeed(statFrame, unit)
    end

    _G.PaperDollFrame_SetAttackSpeed = function(statFrame, unit)
        local meleeHaste = GetMeleeHaste()
        local speed, offhandSpeed = UnitAttackSpeed(unit)
        local displaySpeed = format('%.2f', speed)
        if offhandSpeed then
            offhandSpeed = format('%.2f', offhandSpeed)
        end
        if offhandSpeed then
            displaySpeed = BreakUpLargeNumbers(displaySpeed) .. ' / ' .. offhandSpeed
        else
            displaySpeed = BreakUpLargeNumbers(displaySpeed)
        end
        _G.PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false, speed)

        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) ..
            ' ' .. displaySpeed .. FONT_COLOR_CODE_CLOSE
        statFrame.tooltip2 = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, BreakUpLargeNumbers(meleeHaste))
        statFrame:Show()
    end

    _G.MovementSpeed_OnEnter = function(statFrame)
        _G.GameTooltip:SetOwner(statFrame, 'ANCHOR_RIGHT')
        _G.GameTooltip:SetText(
            HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED) ..
            ' ' .. format('%d%%', statFrame.speed + .5) .. FONT_COLOR_CODE_CLOSE
        )
        _G.GameTooltip:AddLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, statFrame.runSpeed + .5))
        if statFrame.unit ~= 'pet' then
            _G.GameTooltip:AddLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, statFrame.flightSpeed + .5))
        end
        _G.GameTooltip:AddLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, statFrame.swimSpeed + .5))
        _G.GameTooltip:AddLine(' ')
        _G.GameTooltip:AddLine(
            format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED))
        )
        _G.GameTooltip:Show()
    end

    _G.PaperDollFrame_SetMovementSpeed = function(statFrame, unit)
        statFrame.wasSwimming = nil
        statFrame.unit = unit
        MovementSpeed_OnUpdate(statFrame)
        statFrame.onEnterFunc = _G.MovementSpeed_OnEnter
        statFrame:Show()
    end

    function E:GetPlayerItemLevel()
        local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
        local minItemLevel = C_PaperDollInfo_GetMinItemLevel()
        local displayItemLevel = max(minItemLevel or 0, avgItemLevelEquipped)
        displayItemLevel = E:Round(displayItemLevel, 2)
        avgItemLevel = E:Round(avgItemLevel, 2)

        if displayItemLevel ~= avgItemLevel then
            return displayItemLevel ..' / '.. avgItemLevel
        end
        return displayItemLevel
    end

    hooksecurefunc('PaperDollFrame_SetItemLevel', function(statFrame, unit)
        if unit ~= 'player' then return end

        local displayItemLevel = E:GetPlayerItemLevel()

        _G.PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, displayItemLevel, false, displayItemLevel)
    end)
end

R:RegisterModule(CS:GetName())
