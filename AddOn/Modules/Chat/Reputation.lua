local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')

-- R.IsTWW
-- luacheck: globals C_Reputation.GetFactionDataByIndex C_Reputation.GetGuildFactionData C_Reputation.GetNumFactions

-- Lua functions
local _G = _G
local format, strmatch, tonumber = format, strmatch, tonumber

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

if not R.IsTWW then
    -- luacheck: push globals GetNumFactions GetFactionInfo
    local GetFactionInfo = GetFactionInfo
    local GetGuildInfo = GetGuildInfo
    local GetNumFactions = GetNumFactions

    C_Reputation_GetNumFactions = GetNumFactions
    C_Reputation_GetFactionDataByIndex = function(index)
        local name, description, standingID, barMin, barMax, barValue,
            atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep,
            isWatched, isChild, factionID, hasBonusRepGain, canSetInactive = GetFactionInfo(index)
        if name then
            return {
                factionID = factionID,
                name = name,
                description = description,
                reaction = standingID,
                currentReactionThreshold = barMin,
                nextReactionThreshold = barMax,
                currentStanding = barValue,
                atWarWith = atWarWith,
                canToggleAtWar = canToggleAtWar,
                isChild = isChild,
                isHeader = isHeader,
                isHeaderWithRep = isHeader and hasRep,
                isCollapsed = isCollapsed,
                isWatched = isWatched,
                hasBonusRepGain = hasBonusRepGain,
                canSetInactive = canSetInactive,
                isAccountWide = false,
            }
        end
    end
    C_Reputation_GetGuildFactionData = function()
        local factionName = GetGuildInfo('player')
        for index = 1, GetNumFactions() do
            local name, description, standingID, barMin, barMax, barValue,
                atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep,
                isWatched, isChild, factionID, hasBonusRepGain, canSetInactive = GetFactionInfo(index)
            if name and name == factionName then
                return {
                    factionID = factionID,
                    name = name,
                    description = description,
                    reaction = standingID,
                    currentReactionThreshold = barMin,
                    nextReactionThreshold = barMax,
                    currentStanding = barValue,
                    atWarWith = atWarWith,
                    canToggleAtWar = canToggleAtWar,
                    isChild = isChild,
                    isHeader = isHeader,
                    isHeaderWithRep = isHeader and hasRep,
                    isCollapsed = isCollapsed,
                    isWatched = isWatched,
                    hasBonusRepGain = hasBonusRepGain,
                    canSetInactive = canSetInactive,
                    isAccountWide = false,
                }
            end
        end
    end
    -- luacheck: pop
end

local tailing = ' (%s %d/%d)'
local matchStanding = gsub(FACTION_STANDING_INCREASED, '%%[ds]', '(.+)')
local matchBonus = gsub(FACTION_STANDING_INCREASED_ACH_PART, '%+', '%%+')
matchBonus = matchStanding .. gsub(matchBonus, '%%%.1f', '(.+)')

local function findFaction(factionName)
    if factionName == GUILD then
        local data = C_Reputation_GetGuildFactionData()
        if data then
            return data.factionID, data.reaction, data.currentStanding - data.currentReactionThreshold, data.nextReactionThreshold - data.currentReactionThreshold
        end
    end

    for i = 1, C_Reputation_GetNumFactions() do
        local data = C_Reputation_GetFactionDataByIndex(i)
        if factionName == data.name then
            return data.factionID, data.reaction, data.currentStanding - data.currentReactionThreshold, data.nextReactionThreshold - data.currentReactionThreshold
        end
    end
end

local function filterFunc(self, _, message, ...)
    local template = FACTION_STANDING_INCREASED_ACH_BONUS
    local name, value, bonusValue = strmatch(message, matchBonus)
    if not name then
        template = FACTION_STANDING_INCREASED
        name, value = strmatch(message, matchStanding)
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
                    (not currentValue and value > barValue) and majorFactionData.renownLevel or (majorFactionData.renownLevel + 1)
                )
            end
            if currentValue then
                standingLabel = standingLabel .. "+"
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
