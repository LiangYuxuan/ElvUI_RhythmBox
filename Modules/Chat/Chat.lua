local R, E, L, V, P, G = unpack(select(2, ...))
local C = R:NewModule('Chat', 'AceEvent-3.0', 'AceHook-3.0')

function C:Initialize()
    self:ADFilter()
    self:EnhancedTab()
    self:Loot()
    self:Reputation()
end

R:RegisterModule(C:GetName())
