local R, E, L, V, P, G = unpack((select(2, ...)))
---@class RhythmBoxProfessionModule
local RP = R:GetModule('Profession')

-- Lua functions
local ipairs = ipairs
local math_max = math.max

-- WoW API / Variables
local C_ProfSpecs_GetChildrenForPath = C_ProfSpecs.GetChildrenForPath
local C_ProfSpecs_GetConfigIDForSkillLine = C_ProfSpecs.GetConfigIDForSkillLine
local C_ProfSpecs_GetPerksForPath = C_ProfSpecs.GetPerksForPath
local C_ProfSpecs_GetRootPathForTab = C_ProfSpecs.GetRootPathForTab
local C_ProfSpecs_GetSpecTabIDsForSkillLine = C_ProfSpecs.GetSpecTabIDsForSkillLine
local C_ProfSpecs_GetStateForPerk = C_ProfSpecs.GetStateForPerk
local C_Traits_GetNodeInfo = C_Traits.GetNodeInfo

local Enum_ProfessionsSpecPerkState_Earned = Enum.ProfessionsSpecPerkState.Earned

---@param configID number
---@param pathID number
---@return number currentKnowledge, number maxKnowledge, number currentPerks, number maxPerks
local function HandlePath(configID, pathID)
    local currentPerks, maxPerks = 0, 0

    local pathInfo = C_Traits_GetNodeInfo(configID, pathID)
    local currentKnowledge = math_max(0, pathInfo.activeRank - 1)
    local maxKnowledge = pathInfo.maxRanks - 1

    local perkInfos = C_ProfSpecs_GetPerksForPath(pathID)
    for _, perkInfo in ipairs(perkInfos) do
        if C_ProfSpecs_GetStateForPerk(perkInfo.perkID, configID) == Enum_ProfessionsSpecPerkState_Earned then
            currentPerks = currentPerks + 1
        end
        maxPerks = maxPerks + 1
    end

    local childIDs = C_ProfSpecs_GetChildrenForPath(pathID)
    for _, childID in ipairs(childIDs) do
        local childKnowledge, childMaxKnowledge, childPerks, childMaxPerks = HandlePath(configID, childID)
        currentKnowledge = currentKnowledge + childKnowledge
        maxKnowledge = maxKnowledge + childMaxKnowledge
        currentPerks = currentPerks + childPerks
        maxPerks = maxPerks + childMaxPerks
    end

    return currentKnowledge, maxKnowledge, currentPerks, maxPerks
end

---@param skillLineID number
---@return number currentKnowledge, number maxKnowledge, number currentPerks, number maxPerks
function RP:GetProfessionKnowledgeInfo(skillLineID)
    local configID = C_ProfSpecs_GetConfigIDForSkillLine(skillLineID)
    local specTabIDs = C_ProfSpecs_GetSpecTabIDsForSkillLine(skillLineID)

    local currentKnowledge, maxKnowledge, currentPerks, maxPerks = 0, 0, 0, 0
    for _, specTabID in ipairs(specTabIDs) do
        local rootPathID = C_ProfSpecs_GetRootPathForTab(specTabID)
        local pathKnowledge, pathMaxKnowledge, pathPerks, pathMaxPerks = HandlePath(configID, rootPathID)
        currentKnowledge = currentKnowledge + pathKnowledge
        maxKnowledge = maxKnowledge + pathMaxKnowledge
        currentPerks = currentPerks + pathPerks
        maxPerks = maxPerks + pathMaxPerks
    end

    return currentKnowledge, maxKnowledge, currentPerks, maxPerks
end
