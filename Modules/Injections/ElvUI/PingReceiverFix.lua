local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local UF = E:GetModule('UnitFrames')

-- Lua functions
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables

local enableUnitType = {
    party = true,
    raid1 = true,
    raid2 = true,
    raid3 = true,
}

local disableUnitType = {
    target = true,
}

local function ApplyFix(_, frame)
    if enableUnitType[frame.unitframeType] and not frame.isChild then
        frame:SetAttribute('ping-receiver', true)
    elseif disableUnitType[frame.unitframeType] and not frame.isChild then
        frame:SetAttribute('ping-receiver', false)
    end
end

local function PingReceiverFix()
    hooksecurefunc(UF, 'RegisterForClicks', ApplyFix)
end

RI:RegisterPipeline(PingReceiverFix)
