local R, E, L, V, P, G = unpack((select(2, ...)))
local PH = R:NewModule('PreyHelper', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local hooksecurefunc = hooksecurefunc
local string_find = string.find

-- WoW API / Variables
local C_AdventureMap_GetAdventureMapTextureKit = C_AdventureMap.GetAdventureMapTextureKit
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo
local GetAchievementNumCriteria = GetAchievementNumCriteria

local achievementIDMap = {
    ['难度：普通'] = 42701,
    ['难度：困难'] = 42702,
    ['难度：梦魇'] = 42703,
}

local function GetPreyTargetCompleteStatus(achievementID, preyTargetName)
    local numCriteria = GetAchievementNumCriteria(achievementID)
    for i = 1, numCriteria do
        local criteriaString, _, completed = GetAchievementCriteriaInfo(achievementID, i)
        if criteriaString and string_find(criteriaString, preyTargetName) then
            return completed
        end
    end
end

function PH:Initialize()
    R:RegisterAddOnLoad('Blizzard_AdventureMap', function()
        hooksecurefunc(_G.AdventureMap_QuestOfferPinMixin, 'OnMouseEnter', function(pin)
            local adventureMapTextureKit = C_AdventureMap_GetAdventureMapTextureKit()
            if adventureMapTextureKit == 'midnight' then
                local title = pin.title
                local description = pin.description

                if title and description then
                    local achievementID = achievementIDMap[description]
                    if achievementID then
                        local isCompleted = GetPreyTargetCompleteStatus(achievementID, title)
                        if isCompleted then
                            _G.GameTooltip:AddLine('已完成', 0, 1, 0)
                            _G.GameTooltip:Show()
                        else
                            _G.GameTooltip:AddLine('未完成', 1, 0, 0)
                            _G.GameTooltip:Show()
                        end
                    end
                end
            end
        end)
    end)
end

R:RegisterModule(PH:GetName())
