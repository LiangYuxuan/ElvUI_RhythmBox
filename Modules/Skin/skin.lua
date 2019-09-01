local R, E, L, V, P, G = unpack(select(2, ...))
local RS = E:NewModule('RhythmBox_Skin', 'AceHook-3.0')

function RS:Initialize()
    if not R.IsClassic() then
        self:HandleReputation()
    end
end

local function InitializeCallback()
	RS:Initialize()
end

E:RegisterModule(RS:GetName(), InitializeCallback)
