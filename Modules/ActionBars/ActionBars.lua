local R, E, L, V, P, G = unpack(select(2, ...))
local AB = R:NewModule('ActionBars', 'AceEvent-3.0', 'AceTimer-3.0')

function AB:Initialize()
    if R.Retail then
        self:MacroHelper()
    end
end

R:RegisterModule(AB:GetName())
