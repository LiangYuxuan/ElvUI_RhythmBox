local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local pairs = pairs

-- WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function AdjustRankFrame(self)
    self.RankFrame:ClearAllPoints()
    self.RankFrame:SetPoint('TOP', self, 'TOP', 0, 2)
    self.RankFrame.Label:FontTemplate(nil, 14, 'OUTLINE')
end

function RS:CharacterFrame()
	for _, Slot in pairs({_G.PaperDollItemsFrame:GetChildren()}) do
		if Slot:IsObjectType('Button') or Slot:IsObjectType('ItemButton') then
            hooksecurefunc(Slot, 'DisplayAsAzeriteItem', AdjustRankFrame)
        end
    end
end

RS:RegisterSkin(RS.CharacterFrame)
