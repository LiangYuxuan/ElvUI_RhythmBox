local R, E, L, V, P, G = unpack(select(2, ...))
local RS = R.Skin

function RS:Initialize()
    self:HandleReputation()
end

local function InitializeCallback()
	RS:Initialize()
end

E:RegisterModule(RS:GetName(), InitializeCallback)
