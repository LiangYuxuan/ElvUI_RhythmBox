local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables
local C_ProfSpecs_GetConfigIDForSkillLine = C_ProfSpecs.GetConfigIDForSkillLine
local C_ProfSpecs_GetSpecTabIDsForSkillLine = C_ProfSpecs.GetSpecTabIDsForSkillLine
local C_ProfSpecs_GetTabInfo = C_ProfSpecs.GetTabInfo
local C_Traits_GetNodeInfo = C_Traits.GetNodeInfo
local C_Traits_PurchaseRank = C_Traits.PurchaseRank
local CreateFrame = CreateFrame
-- luacheck: globals IsPublicTestClient
local IsPublicTestClient = IsPublicTestClient

local function Purchase(configID, nodeID)
    local nodeInfo = C_Traits_GetNodeInfo(configID, nodeID)
    if nodeInfo then
        for _ = nodeInfo.ranksPurchased, nodeInfo.maxRanks do
            C_Traits_PurchaseRank(configID, nodeID)
        end

        for _, edgeInfo in ipairs(nodeInfo.visibleEdges) do
            Purchase(configID, edgeInfo.targetNode)
        end
    end
end

local function ButtonOnClick(self)
    local specPage = self:GetParent()
    local professionID = specPage:GetProfessionID()
    local configID = C_ProfSpecs_GetConfigIDForSkillLine(professionID)
    local treeIDs = C_ProfSpecs_GetSpecTabIDsForSkillLine(professionID)

    for _, treeID in ipairs(treeIDs) do
        local tabInfo = C_ProfSpecs_GetTabInfo(treeID)
        if tabInfo then
            Purchase(configID, tabInfo.rootNodeID)
        end
    end

    specPage.TreePreview:Hide()
end

local function Blizzard_Professions()
    if IsPublicTestClient and IsPublicTestClient() then
        R:RegisterAddOnLoad('Blizzard_Professions', function()
            local button = CreateFrame('Button', nil, _G.ProfessionsFrame.SpecPage, 'MagicButtonTemplate')
            button:ClearAllPoints()
            button:SetPoint('TOPRIGHT', -10, -40)
            button:SetSize(160, 36)
            button:SetText("学习全部专精")
            button:SetScript('OnClick', ButtonOnClick)

            S:HandleButton(button)
        end)
    end
end

RI:RegisterPipeline(Blizzard_Professions)
