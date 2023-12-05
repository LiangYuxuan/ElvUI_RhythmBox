local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')

-- Lua functions
local _G = _G
local format, strmatch, tonumber = format, strmatch, tonumber

-- WoW API / Variables
local C_GossipInfo_GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local C_MajorFactions_GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local C_Reputation_IsMajorFaction = C_Reputation.IsMajorFaction
local GetFactionInfo = GetFactionInfo
local GetGuildInfo = GetGuildInfo
local GetNumFactions = GetNumFactions

local ChatFrame_AddMessageEventFilter = ChatFrame_AddMessageEventFilter
local ChatFrame_RemoveMessageEventFilter = ChatFrame_RemoveMessageEventFilter

local GUILD = GUILD
local FACTION_STANDING_INCREASED = FACTION_STANDING_INCREASED
local FACTION_STANDING_INCREASED_ACH_BONUS = FACTION_STANDING_INCREASED_ACH_BONUS
local COVENANT_SANCTUM_TAB_RENOWN = COVENANT_SANCTUM_TAB_RENOWN

local tailing = ' (%s %d/%d)'
local matchStanding = gsub(FACTION_STANDING_INCREASED, '%%[ds]', '(.+)')
local matchBonus = gsub(FACTION_STANDING_INCREASED_ACH_PART, '%+', '%%+')
matchBonus = matchStanding .. gsub(matchBonus, '%%%.1f', '(.+)')

local function findFaction(factionName)
    if factionName == GUILD then
        factionName = GetGuildInfo('player')
    end
    for i = 1, GetNumFactions() do
        local name, _, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _, factionID = GetFactionInfo(i)
        if factionName == name then
            return factionID, i, standingID, barValue - barMin, barMax - barMin
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
        local factionID, _, standingID, barValue, barMax = findFaction(name)
        if factionID then
            value = tonumber(value)
            local friendInfo = C_GossipInfo_GetFriendshipReputation(factionID)
            local standingLabel = friendInfo and friendInfo.reaction or _G['FACTION_STANDING_LABEL' .. standingID]
            local currentValue, threshold, _, hasRewardPending = C_Reputation_GetFactionParagonInfo(factionID)
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
            if C_Reputation_IsMajorFaction(factionID) then
                local majorFactionData = C_MajorFactions_GetMajorFactionData(factionID)
                if majorFactionData then
                    standingLabel = format('%s %s', COVENANT_SANCTUM_TAB_RENOWN, majorFactionData.renownLevel)
                    barValue = majorFactionData.renownReputationEarned
                    barMax = majorFactionData.renownLevelThreshold
                end
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
