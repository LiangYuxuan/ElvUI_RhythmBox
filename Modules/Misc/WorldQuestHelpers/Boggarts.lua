local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local BO = R:NewModule('Boggarts', 'AceEvent-3.0')

-- Lua functions

-- WoW API / Variables
local C_QuestLog_IsOnQuest = C_QuestLog.IsOnQuest
local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTarget = SetRaidTarget
local UnitGUID = UnitGUID

function BO:UPDATE_MOUSEOVER_UNIT()
    local npcID = R:ParseNPCID(UnitGUID('mouseover'))
    if npcID == 170080 and GetRaidTargetIndex('mouseover') ~= 8 then
        SetRaidTarget('mouseover', 8)
    end
end

function BO:Unwatch()
    self:UnregisterEvent('QUEST_REMOVED')
    self:UnregisterEvent('UPDATE_MOUSEOVER_UNIT')
end

function BO:Watch()
    self:RegisterEvent('QUEST_REMOVED')
    self:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
end

function BO:QUEST_REMOVED(_, questID)
    if questID == 60739 then
        self:Unwatch()
    end
end

function BO:QUEST_ACCEPTED(_, questID)
    if questID == 60739 then
        self:Watch()
    end
end

function BO:QUEST_LOG_UPDATE()
    if C_QuestLog_IsOnQuest(60739) then
        self:Watch()
    else
        self:Unwatch()
    end
end

function BO:Initialize()
    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('QUEST_ACCEPTED')
end

R:RegisterModule(BO:GetName())
