local E, L, V, P, G = unpack(ElvUI);
local R = unpack(select(2, ...))

hooksecurefunc("EmbeddedItemTooltip_SetItemByQuestReward", function(tooltip)
    if tooltip == EmbeddedItemTooltip.ItemTooltip and EmbeddedItemTooltip.factionID then
        local frame = _G[EmbeddedItemTooltip:GetName() .. "TextLeft" .. EmbeddedItemTooltip:NumLines()]
        if frame:GetText() == TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT.headerText then
            local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(EmbeddedItemTooltip.factionID)
            if currentValue then
                local completionCount = floor(currentValue / threshold) - (hasRewardPending and 1 or 0)
                frame:SetText(frame:GetText() .. "  ( " ..
                    format(ARCHAEOLOGY_COMPLETION, completionCount) .. " )"
                )
            end
        end
    end
end)

hooksecurefunc("ReputationFrame_Update", function()
    local numFactions = GetNumFactions()
    local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame)
    for i = 1, NUM_FACTIONS_DISPLAYED, 1 do
        local factionIndex = factionOffset + i
        if (factionIndex > numFactions) then break end

        local factionID = select(14, GetFactionInfo(factionIndex))
        if (factionID and C_Reputation.IsFactionParagon(factionID)) then
            local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
            local barMax, barValue = threshold, mod(currentValue, threshold) + (hasRewardPending and threshold or 0)
            local colorIndex = min(floor((barValue / barMax) * 10) + 1, 8)
            local color = FACTION_BAR_COLORS[colorIndex]

            local factionRow = _G["ReputationBar" .. i]
            local factionBar = _G["ReputationBar" .. i .. "ReputationBar"]
            local factionStanding = _G["ReputationBar" .. i .. "ReputationBarFactionStanding"];

            factionRow.standingText = factionRow.standingText .. "+"
            factionRow.rolloverText = HIGHLIGHT_FONT_COLOR_CODE .. " " ..
                format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(barMax)) ..
                FONT_COLOR_CODE_CLOSE

            factionBar:SetMinMaxValues(0, barMax)
            factionBar:SetValue(barValue)
            factionBar:SetStatusBarColor(color.r, color.g, color.b)

            factionStanding:SetText(factionRow.standingText)
        end
    end
end)
