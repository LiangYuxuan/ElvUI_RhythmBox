local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local UN = R:NewModule('Unknown', 'AceEvent-3.0')

-- Lua functions

-- WoW API / Variables
local C_GossipInfo_GetNumOptions = C_GossipInfo.GetNumOptions
local C_GossipInfo_SelectOption = C_GossipInfo.SelectOption
local IsShiftKeyDown = IsShiftKeyDown
local UnitGUID = UnitGUID

local gormJuiceStage
local correctFairies = {
    [174770] = true,
    [174498] = true,
    [174771] = true,
    [174499] = true,
}

function UN:GOSSIP_SHOW()
    if IsShiftKeyDown() then return end

    local npcID = R:ParseNPCID(UnitGUID('npc'))
    if npcID == 174365 then
        -- Guess the correct word in sentence, we always pick option 2 because it's easy, she
        -- will just keep asking for the correct one if you make a mistake
        if C_GossipInfo_GetNumOptions() == 1 then
            C_GossipInfo_SelectOption(1)
        else
            C_GossipInfo_SelectOption(2)
        end
    elseif npcID == 174371 then
        -- Mixy Mak, you ask her if the _can_ create something, then ask her to create it
        if not gormJuiceStage then
            C_GossipInfo_SelectOption(2)
        elseif gormJuiceStage == 1 then
            C_GossipInfo_SelectOption(C_GossipInfo_GetNumOptions())
        end

        gormJuiceStage = (gormJuiceStage or 0) + 1
    elseif correctFairies[npcID] then
        -- Guess the correct drunk faerie, they're all correct
        C_GossipInfo_SelectOption(3)
    end
end

function UN:Initialize()
    self:RegisterEvent('GOSSIP_SHOW')
end

R:RegisterModule(UN:GetName())
