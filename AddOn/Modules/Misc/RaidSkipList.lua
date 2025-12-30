local R, E, L, V, P, G = unpack((select(2, ...)))
local RSL = R:NewModule('RaidSkipList', 'AceEvent-3.0')
-- local TB = R:GetModule('Toolbox')
-- local AceGUI = E.Libs.AceGUI

-- Lua functions
-- local _G = _G
local ipairs = ipairs

-- WoW API / Variables
local C_QuestLog_GetNumQuestObjectives = C_QuestLog.GetNumQuestObjectives
local C_QuestLog_IsOnQuest = C_QuestLog.IsOnQuest
local C_QuestLog_IsQuestFlaggedCompleted = C_QuestLog.IsQuestFlaggedCompleted
local C_TooltipInfo_GetHyperlink = C_TooltipInfo.GetHyperlink
local GetLFGDungeonInfo = GetLFGDungeonInfo
local GetQuestObjectiveInfo = GetQuestObjectiveInfo

local questIDs = {
    91461, -- Manaforge Omega: A Walking Shadow
    89353, -- Liberation of Undermine: Splitting Pairs
    82639, -- Nerub-ar Palace: For Nerubian Eyes Only
    78602, -- Amirdrassil, the Dream's Hope: Up in Smoke
    76086, -- Aberrus, the Shadowed Crucible: Echoes of the Earth-Warder
    71020, -- Vault of the Incarnates: Break a Few Eggs
    65762, -- Sepulcher of the First Ones - Heavy is the Crown
    64599, -- Sanctum of Domination - Damned If You Don't
    62056, -- Castle Nathria: Getting a Head
    58375, -- Ny'alotha: MOTHER's Guidance
    49135, -- Antorus, the Burning Throne: The Heart of Argus
    49076, -- Antorus, the Burning Throne: Dark Passage
    47727, -- Tomb of Sargeras: Aegwynn's Path
    45383, -- The Nighthold: Talisman of the Shal'dorei
    44285, -- The Emerald Nightmare: Piercing the Veil
    39505, -- The Fel Spire
    39501, -- Well of Souls
    37031, -- Sigil of the Black Hand (Mythic)
}

local missingRaidNameQuestIDs = {
    [39505] = 989, -- Hellfire Citadel: The Fel Spire
    [39501] = 989, -- Hellfire Citadel: Well of Souls
    [37031] = 900, -- Blackrock Foundry: Sigil of the Black Hand (Mythic)
}

function RSL:PrintList()
    for _, questID in ipairs(questIDs) do
        if not C_QuestLog_IsQuestFlaggedCompleted(questID) then
            local name = C_TooltipInfo_GetHyperlink('quest:' .. questID).lines[1].leftText
            if missingRaidNameQuestIDs[questID] then
                local raidName = GetLFGDungeonInfo(missingRaidNameQuestIDs[questID])
                name = raidName .. ": " .. name
            end

            if C_QuestLog_IsOnQuest(questID) then
                R:Print("进行中: %s", name)

                local leaderboardCount = C_QuestLog_GetNumQuestObjectives(questID)
                for i = 1, leaderboardCount do
                    local text = GetQuestObjectiveInfo(questID, i, false)
                    R:Print("    %s", text)
                end
            else
                R:Print("未完成: %s", name)
            end

        end
    end
end

function RSL:Initialize()
    -- TODO
end

-- R:RegisterModule(RSL:GetName())
