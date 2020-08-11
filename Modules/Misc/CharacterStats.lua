-- From EKCore and NDui
-- https://github.com/EKE00372/EKCore/blob/master/Interface/CharacterStats.lua
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Misc/MissingStats.lua

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local CS = R:NewModule('CharacterStats', 'AceEvent-3.0')

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
        if (not _G[_G.PAPERDOLL_SIDEBARS[1].frame]:IsShown()) then
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

    function PaperDollFrame_SetLabelAndText(statFrame, label, text, isPercentage, numericValue)
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
                {stat = 'BLOCK', hideAt = 0, showFunc = C_PaperDollInfo.OffhandHasShield}
            }
        }
    }

    PAPERDOLL_STATINFO['ENERGY_REGEN'].updateFunc = function(statFrame, unit)
        statFrame.numericValue = 0
        PaperDollFrame_SetEnergyRegen(statFrame, unit)
    end

    PAPERDOLL_STATINFO['RUNE_REGEN'].updateFunc = function(statFrame, unit)
        statFrame.numericValue = 0
        PaperDollFrame_SetRuneRegen(statFrame, unit)
    end

    PAPERDOLL_STATINFO['FOCUS_REGEN'].updateFunc = function(statFrame, unit)
        statFrame.numericValue = 0
        PaperDollFrame_SetFocusRegen(statFrame, unit)
    end

    -- Fix Movespeed
    PAPERDOLL_STATINFO['MOVESPEED'].updateFunc = function(statFrame, unit)
        PaperDollFrame_SetMovementSpeed(statFrame, unit)
    end

    function PaperDollFrame_SetAttackSpeed(statFrame, unit)
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
        PaperDollFrame_SetLabelAndText(statFrame, WEAPON_SPEED, displaySpeed, false, speed)

        statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED) ..
            ' ' .. displaySpeed .. FONT_COLOR_CODE_CLOSE
        statFrame.tooltip2 = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, BreakUpLargeNumbers(meleeHaste))
        statFrame:Show()
    end

    function MovementSpeed_OnEnter(statFrame)
        GameTooltip:SetOwner(statFrame, 'ANCHOR_RIGHT')
        GameTooltip:SetText(
            HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED) ..
            ' ' .. format('%d%%', statFrame.speed + .5) .. FONT_COLOR_CODE_CLOSE
        )
        GameTooltip:AddLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, statFrame.runSpeed + .5))
        if statFrame.unit ~= 'pet' then
            GameTooltip:AddLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, statFrame.flightSpeed + .5))
        end
        GameTooltip:AddLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, statFrame.swimSpeed + .5))
        GameTooltip:AddLine(' ')
        GameTooltip:AddLine(
            format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED))
        )
        GameTooltip:Show()
    end

    function PaperDollFrame_SetMovementSpeed(statFrame, unit)
        statFrame.wasSwimming = nil
        statFrame.unit = unit
        MovementSpeed_OnUpdate(statFrame)
        statFrame.onEnterFunc = MovementSpeed_OnEnter
        statFrame:Show()
    end

    function E:GetPlayerItemLevel()
        local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
        local minItemLevel = C_PaperDollInfo.GetMinItemLevel()
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

        PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, displayItemLevel, false, displayItemLevel)
    end)
end

R:RegisterModule(CS:GetName())
