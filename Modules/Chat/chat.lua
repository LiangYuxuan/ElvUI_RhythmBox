local R, E, L, V, P, G = unpack(select(2, ...))
local C = R.Chat

function C:Initialize()
    self:HandleAD()
    self:HandleReputation()
end

local function InitializeCallback()
	C:Initialize()
end

E:RegisterModule(C:GetName(), InitializeCallback)
