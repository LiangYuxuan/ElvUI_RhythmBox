-- From SimpleObjectiveProgress
-- By Simca@Malfurion-US (MMOSimca)
-- https://www.curseforge.com/wow/addons/simpleobjectiveprogress

local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local SOP = R:NewModule('SimpleObjectiveProgress', 'AceHook-3.0')
local LOP = LibStub('LibObjectiveProgress-1.0')

-- Lua functions
local _G = _G
local floor, select, strsplit, tonumber, tostring = floor, select, strsplit, tonumber, tostring

-- WoW API / Variables
local C_QuestLog_GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries
local C_QuestLog_GetQuestIDForLogIndex = C_QuestLog.GetQuestIDForLogIndex
local C_QuestLog_GetTitleForLogIndex = C_QuestLog.GetTitleForLogIndex
local UnitGUID = UnitGUID

function SOP:OnTooltipSetUnit(tooltip)
    if not tooltip or tooltip:IsForbidden() or not tooltip.NumLines or tooltip:NumLines() == 0 then return end

    local unitID = select(2, tooltip:GetUnit())
    local unitGUID = unitID and UnitGUID(unitID)
    if not unitGUID then return end

    local npcID = select(6, strsplit('-', unitGUID))
    npcID = npcID and tonumber(npcID)
    if not npcID then return end

    local numEntries = C_QuestLog_GetNumQuestLogEntries()
    for questLogIndex = 1, numEntries do
        local questID = C_QuestLog_GetQuestIDForLogIndex(questLogIndex)
        if questID then
            local weight = LOP:GetNPCWeightByQuest(questID, npcID)
            if weight then
                local questTitle = C_QuestLog_GetTitleForLogIndex(questLogIndex)
                if questTitle then
                    local displayText = questTitle .. " - " .. tostring(floor((weight * 100) + 0.5) / 100) .. "%"

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
    end
end

function SOP:Initialize()
    self:HookScript(_G.GameTooltip, 'OnTooltipSetUnit')
end

R:RegisterModule(SOP:GetName())
