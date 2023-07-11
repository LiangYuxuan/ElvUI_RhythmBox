local R, E, L, V, P, G = unpack((select(2, ...)))
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local floor, format, min, select = floor, format, min, select

-- WoW API / Variables
local BreakUpLargeNumbers = BreakUpLargeNumbers
local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local C_Reputation_IsFactionParagon = C_Reputation.IsFactionParagon
local GetFactionInfo = GetFactionInfo
local hooksecurefunc = hooksecurefunc

local ARCHAEOLOGY_COMPLETION = ARCHAEOLOGY_COMPLETION
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local HIGHLIGHT_FONT_COLOR_CODE = HIGHLIGHT_FONT_COLOR_CODE
local REPUTATION_PROGRESS_FORMAT = REPUTATION_PROGRESS_FORMAT
local TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT = TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT

function RS:ReputationFrame()
    hooksecurefunc('ReputationParagonFrame_SetupParagonTooltip', function()
        if _G.GameTooltip.factionID then
            local text = _G[_G.GameTooltip:GetName() .. 'TextLeft' .. _G.GameTooltip:NumLines()]
            if text:GetText() == TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT.headerText then
                local currentValue, threshold, _, hasRewardPending = C_Reputation_GetFactionParagonInfo(_G.GameTooltip.factionID)
                if currentValue then
                    local completionCount = floor(currentValue / threshold) - (hasRewardPending and 1 or 0)
                    text:SetText(text:GetText() .. "  ( " ..
                        format(ARCHAEOLOGY_COMPLETION, completionCount) .. " )"
                    )
                end
            end
        end
    end)

    hooksecurefunc('ReputationFrame_InitReputationRow', function(factionRow, elementData)
        local factionIndex = elementData.index
        local factionContainer = factionRow.Container
        local factionBar = factionContainer.ReputationBar
        local factionStanding = factionBar.FactionStanding

        local factionID = select(14, GetFactionInfo(factionIndex))
        if (factionID and C_Reputation_IsFactionParagon(factionID)) then
            local currentValue, threshold, _, hasRewardPending = C_Reputation_GetFactionParagonInfo(factionID)
            local barMax, barValue = threshold, (currentValue % threshold) + (hasRewardPending and threshold or 0)
            local colorIndex = min(floor((barValue / barMax) * 10) + 1, 8)
            local color = FACTION_BAR_COLORS[colorIndex]
            factionRow.standingText = factionRow.standingText .. "+"
            factionRow.rolloverText = HIGHLIGHT_FONT_COLOR_CODE .. " " ..
                format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(barMax)) ..
                FONT_COLOR_CODE_CLOSE
            factionBar:SetMinMaxValues(0, barMax)
            factionBar:SetValue(barValue)
            factionBar:SetStatusBarColor(color.r, color.g, color.b)
            factionStanding:SetText(factionRow.standingText)
        end
    end)
end

RS:RegisterSkin(RS.ReputationFrame)
