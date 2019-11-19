-- From SimpleObjectiveProgress
-- By Simca@Malfurion-US (MMOSimca)
-- https://www.curseforge.com/wow/addons/simpleobjectiveprogress

local R, E, L, V, P, G = unpack(select(2, ...))
local SOP = R:NewModule('SimpleObjectiveProgress', 'AceHook-3.0')
local LOP = LibStub('LibObjectiveProgress-1.0')

-- Lua functions
local _G = _G
local floor, pairs, select, strsplit, tonumber, tostring = floor, pairs, select, strsplit, tonumber, tostring

-- WoW API / Variables
local C_TaskQuest_GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID
local GetQuestLogIndexByID = GetQuestLogIndexByID
local GetQuestLogTitle = GetQuestLogTitle
local UnitGUID = UnitGUID

function SOP:OnTooltipSetUnit(tooltip)
    if not tooltip or tooltip:IsForbidden() or not tooltip.NumLines or tooltip:NumLines() == 0 then return end

    local unit = select(2, tooltip:GetUnit())
    local GUID = unit and UnitGUID(unit)
    if not GUID or GUID == '' then return end

    local npcID = select(6, strsplit('-', GUID))
    if not npcID or npcID == '' then return end

    local weightsTable = LOP:GetNPCWeightByCurrentQuests(tonumber(npcID))
    if not weightsTable then return end

    for questID, npcWeight in pairs(weightsTable) do
        local questTitle = C_TaskQuest_GetQuestInfoByQuestID(questID) or GetQuestLogTitle(GetQuestLogIndexByID(questID))
        if questTitle then
            local displayText = questTitle .. " - " .. tostring(floor((npcWeight * 100) + 0.5) / 100) .. "%"

            local found
            for line = 1, tooltip:NumLines() do
                if _G['GameTooltipTextLeft' .. line] and _G['GameTooltipTextLeft' .. line]:GetText() == questTitle then
                    _G['GameTooltipTextLeft' .. line]:SetText(displayText)

                    found = true
                    break
                end
            end

            if not found then
                tooltip:AddLine(displayText, 1, 210 / 255, 0)
            end
        end
    end
end

function SOP:Initialize()
    self:HookScript(_G.GameTooltip, 'OnTooltipSetUnit')
end

R:RegisterModule(SOP:GetName())
