local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local CH = R:NewModule('Chores', 'AceEvent-3.0')

-- Lua functions
local ipairs, math, pairs, tonumber = ipairs, math, pairs, tonumber

-- WoW API / Variables
local C_QuestLog_IsOnQuest = C_QuestLog.IsOnQuest
local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTarget = SetRaidTarget
local UnitGUID = UnitGUID

local coordinateToHelper = {
    [169022] = {{0.5291, 0.4579}},
    [169023] = {{0.5306, 0.4750}},
    [169024] = {{0.5263, 0.4617}, {0.5258, 0.4660}},
    [169025] = {{0.5199, 0.4846}, {0.5265, 0.4744}},
    [169026] = {{0.5251, 0.4877}, {0.5182, 0.4540}},
    [169027] = {{0.5333, 0.4701}},
}

function CH:GetWorldDistance(oX, oY, dX, dY)
    local deltaX, deltaY = dX - oX, dY - oY
    return (deltaX * deltaX + deltaY * deltaY) ^ 0.5
end

function CH:GetClostestQuestNPC()
    local closestNPC
    local closestDistance = math.huge

    local playerX, playerY = E.MapInfo.x, E.MapInfo.y
    if not playerX or not playerY then return end

    for npcID, data in pairs(coordinateToHelper) do
        for _, coords in ipairs(data) do
            local distance = self:GetWorldDistance(playerX, playerY, coords[1], coords[2])
            if distance < closestDistance then
                closestNPC = npcID
                closestDistance = distance
            end
        end
    end

    return closestNPC
end

function CH:UPDATE_MOUSEOVER_UNIT()
    local npcID = R:ParseNPCID(UnitGUID('mouseover'))

    local closestQuestNPC = self:GetClostestQuestNPC()
    if closestQuestNPC and closestQuestNPC == tonumber(npcID) and GetRaidTargetIndex('mouseover') ~= 4 then
        SetRaidTarget('mouseover', 4)
    end
end

function CH:Unwatch()
    self:UnregisterEvent('QUEST_REMOVED')
    self:UnregisterEvent('UPDATE_MOUSEOVER_UNIT')
end

function CH:Watch()
    self:RegisterEvent('QUEST_REMOVED')
    self:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
end

function CH:QUEST_REMOVED(_, questID)
    if questID == 60565 then
        self:Unwatch()
    end
end

function CH:QUEST_ACCEPTED(_, questID)
    if questID == 60565 then
        self:Watch()
    end
end

function CH:QUEST_LOG_UPDATE()
    if C_QuestLog_IsOnQuest(60565) then
        self:Watch()
    else
        self:Unwatch()
    end
end

function CH:Initialize()
    self:RegisterEvent('QUEST_LOG_UPDATE')
    self:RegisterEvent('QUEST_ACCEPTED')
end

R:RegisterModule(CH:GetName())
