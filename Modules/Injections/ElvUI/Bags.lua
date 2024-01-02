local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')
local B = E:GetModule('Bags')

-- Lua functions
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables

local function updateAllSlots()
    B:UpdateAllSlots(B.BagFrame)
end

local function ElvUIBags()
    hooksecurefunc(B, 'OpenBags', updateAllSlots)
end

RI:RegisterPipeline(ElvUIBags)
