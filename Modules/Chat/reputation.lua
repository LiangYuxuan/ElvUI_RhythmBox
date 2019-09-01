local R, E, L, V, P, G = unpack(select(2, ...))
local C = E:GetModule('RhythmBox_Chat')

local tailing = ' (%s %d/%d)'
local matchStanding = gsub(FACTION_STANDING_INCREASED, '%%[ds]', '(.+)')
local matchBonus = gsub(FACTION_STANDING_INCREASED_ACH_PART, '%+', '%%+')
matchBonus = matchStanding .. gsub(matchBonus, '%%%.1f', '(.+)')

local function findFaction(factionName)
    local isGuild = false
    if faction == GUILD then
        isGuild = true
        faction = GetGuildInfo('player')
    end
    for i = 1, GetNumFactions() do
        local name, _, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _, factionID = GetFactionInfo(i)
        if factionName == name then
            local watchedName = GetWatchedFactionInfo()
            if (
                UnitLevel('player') == MAX_PLAYER_LEVEL and not isGuild and
                watchedName ~= name and E.db.RhythmBox.Chat.AutoTrace
            ) then
                SetWatchedFactionIndex(i)
            end
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
        local factionID, index, standingID, barValue, barMax = findFaction(name)
        if factionID then
            value = tonumber(value)
            if not R.IsClassic() then
                local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
                local standingLabel = _G['FACTION_STANDING_LABEL' .. standingID]
                if currentValue then
                    standingLabel = standingLabel .. "+"
                    barValue = mod(currentValue, threshold)
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

function C:HandleReputation()
    if E.db.RhythmBox.Chat.EnhancedReputation and not self.filtering then
        ChatFrame_AddMessageEventFilter('CHAT_MSG_COMBAT_FACTION_CHANGE', filterFunc)
        self.filtering = true
    elseif self.filtering then
        ChatFrame_RemoveMessageEventFilter('CHAT_MSG_COMBAT_FACTION_CHANGE', filterFunc)
        self.filtering = nil
    end
end
