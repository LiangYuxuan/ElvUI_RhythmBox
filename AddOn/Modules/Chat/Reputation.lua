local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')

-- Lua functions
local _G = _G
local format, ipairs, strmatch, tonumber, unpack = format, ipairs, strmatch, tonumber, unpack

-- WoW API / Variables
local C_GossipInfo_GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local C_MajorFactions_GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local C_Reputation_GetFactionDataByIndex = C_Reputation.GetFactionDataByIndex
local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local C_Reputation_GetGuildFactionData = C_Reputation.GetGuildFactionData
local C_Reputation_GetNumFactions = C_Reputation.GetNumFactions

local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local ChatFrame_RemoveMessageEventFilter = ChatFrame_RemoveMessageEventFilter

local GUILD = GUILD
local FACTION_STANDING_INCREASED = FACTION_STANDING_INCREASED
local FACTION_STANDING_INCREASED_ACH_BONUS = FACTION_STANDING_INCREASED_ACH_BONUS
local COVENANT_SANCTUM_TAB_RENOWN = COVENANT_SANCTUM_TAB_RENOWN

local tailing = ' (%s %d/%d)'
local matchCharacter = gsub(FACTION_STANDING_INCREASED, '%%[ds]', '(.+)')
local matchAccount = gsub(FACTION_STANDING_INCREASED_ACCOUNT_WIDE, '%%[ds]', '(.+)')
local matchCharacterBonus = gsub(gsub(FACTION_STANDING_INCREASED_ACH_BONUS, '%%[ds]', '(.+)'), '%+%%%.1f', '%%+(.+)')
local matchAccountBonus = gsub(gsub(FACTION_STANDING_INCREASED_ACH_BONUS_ACCOUNT_WIDE, '%%[ds]', '(.+)'), '%+%%%.1f', '%%+(.+)')

local matchTemplates = {
    {FACTION_STANDING_INCREASED_ACH_BONUS_ACCOUNT_WIDE, matchAccountBonus},
    {FACTION_STANDING_INCREASED_ACH_BONUS, matchCharacterBonus},
    {FACTION_STANDING_INCREASED_ACCOUNT_WIDE, matchAccount},
    {FACTION_STANDING_INCREASED, matchCharacter}
}

local function findFaction(factionName)
    if factionName == GUILD then
        local data = C_Reputation_GetGuildFactionData()
        if data then
            return data.factionID, data.reaction, data.currentStanding - data.currentReactionThreshold, data.nextReactionThreshold - data.currentReactionThreshold
        end
    end

    for i = 1, C_Reputation_GetNumFactions() do
        local data = C_Reputation_GetFactionDataByIndex(i)
        if data and factionName == data.name then
            return data.factionID, data.reaction, data.currentStanding - data.currentReactionThreshold, data.nextReactionThreshold - data.currentReactionThreshold
        end
    end
end

local function filterFunc(self, _, message, ...)
    local template, match, name, value, bonusValue
    for _, data in ipairs(matchTemplates) do
        template, match = unpack(data)
        name, value, bonusValue = strmatch(message, match)
        if name then
            break
        end
    end

    if name then
        local factionID, standingID, barValue, barMax = findFaction(name)
        if factionID then
            value = tonumber(value)
            local standingLabel = _G['FACTION_STANDING_LABEL' .. standingID]
            local friendInfo = C_GossipInfo_GetFriendshipReputation(factionID)
            local majorFactionData = C_MajorFactions_GetMajorFactionData(factionID)
            local currentValue, threshold, _, hasRewardPending = C_Reputation_GetFactionParagonInfo(factionID)
            if friendInfo and friendInfo.friendshipFactionID > 0 then
                barValue = friendInfo.standing - friendInfo.reactionThreshold
                barMax = (friendInfo.nextThreshold or friendInfo.maxRep) - friendInfo.reactionThreshold
                standingLabel = friendInfo.reaction
            end
            if majorFactionData then
                barValue = majorFactionData.renownReputationEarned
                barMax = majorFactionData.renownLevelThreshold
                standingLabel = format(
                    '%s%s',
                    COVENANT_SANCTUM_TAB_RENOWN,
                    (not currentValue and value > barValue) and (majorFactionData.renownLevel + 1) or majorFactionData.renownLevel
                )
            end
            if currentValue then
                standingLabel = "巅峰"
                barValue = currentValue % threshold
                if hasRewardPending or (barValue ~= 0 and value > barValue) then
                    -- when barValue equals to 0, there are two possibilities
                    -- 1. player just reached paragon
                    -- 2. player gained exactly rest reputation in current max value of paragon+
                    -- in first case, we should display 0/10000, for the second one, we should display 10000/10000
                    -- but the first one is more likely to happen
                    -- we cannot tell the different between this two if we don't store old value
                    -- so in this code, we prefer the first one
                    barValue = barValue + threshold
                end
                barMax = threshold
            end
            if bonusValue then
                message = format(template .. tailing, name, value, bonusValue, standingLabel, barValue, barMax)
            else
                message = format(template .. tailing, name, value, standingLabel, barValue, barMax)
            end
        end
    end

    return false, message, ...
end

function C:Reputation()
    if E.db.RhythmBox.Chat.EnhancedReputation then
        ChatFrame_AddMessageEventFilter('CHAT_MSG_COMBAT_FACTION_CHANGE', filterFunc)
    else
        ChatFrame_RemoveMessageEventFilter('CHAT_MSG_COMBAT_FACTION_CHANGE', filterFunc)
    end
end

C:RegisterPipeline(C.Reputation)
