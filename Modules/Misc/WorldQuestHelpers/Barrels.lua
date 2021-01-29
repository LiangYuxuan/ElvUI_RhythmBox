local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local BA = R:NewModule('Barrels', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local pairs, wipe = pairs, wipe

-- WoW API / Variables
local GetActionInfo = GetActionInfo
local GetRaidTargetIndex = GetRaidTargetIndex
local HasExtraActionBar = HasExtraActionBar
local SetRaidTarget = SetRaidTarget
local UnitGUID = UnitGUID

local barrels = {}
local quests = {
    [45068] = true,
    [45069] = true,
    [45070] = true,
    [45071] = true,
    [45072] = true,
}

local function tSize(t)
    local size = 0
    for _ in pairs(t) do
        size = size + 1
    end
    return size
end

function BA:UPDATE_MOUSEOVER_UNIT()
    local unitGUID = UnitGUID('mouseover')
    local npcID = R:ParseNPCID(unitGUID)
    if npcID == 115947 and not barrels[unitGUID] then
        local index = (tSize(barrels) % 8) + 1
        barrels[unitGUID] = index

        if GetRaidTargetIndex('mouseover') ~= index then
            SetRaidTarget('mouseover', index)
        end
    end
end

function BA:QUEST_REMOVED(_, questID)
    if quests[questID] then
        wipe(barrels)

        self:UnregisterEvent('QUEST_REMOVED')
        self:UnregisterEvent('UPDATE_MOUSEOVER_UNIT')
    end
end

function BA:UPDATE_OVERRIDE_ACTIONBAR()
    if HasExtraActionBar() then
        local _, spellID = GetActionInfo(_G.ExtraActionButton1.action)
        if spellID == 230884 then
            self:RegisterEvent('QUEST_REMOVED')
            self:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
        end
    end
end

function BA:Initialize()
    self:RegisterEvent('UPDATE_OVERRIDE_ACTIONBAR')
end

R:RegisterModule(BA:GetName())
