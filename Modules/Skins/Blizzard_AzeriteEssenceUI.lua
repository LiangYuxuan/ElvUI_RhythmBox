local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local RS = R:GetModule('Skins')

-- Lua functions

-- WoW API / Variables

function RS:Blizzard_AzeriteEssenceUI()
    if AzeriteEssenceUI and AzeriteEssenceUI.EssenceList and AzeriteEssenceUI.EssenceList.buttons then
        for _, button in ipairs(AzeriteEssenceUI.EssenceList.buttons) do
            button:HookScript('OnEnter', function(self)
                self._rhythmNext = 0
                GameTooltip:AddLine("中键点击查看下一级", 0, 1, 0)
                GameTooltip:Show()
            end)
            button:HookScript('OnClick', function(self, button)
                if button == 'MiddleButton' then
                    self._rhythmNext = (self._rhythmNext or 0) + 1
                    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                    GameTooltip:SetAzeriteEssence(self.essenceID, (self.rank + self._rhythmNext) % 4 )
                    GameTooltip:AddLine("中键点击查看下一级", 0, 1, 0)
                    GameTooltip:Show()
                end
            end)
            button:RegisterForClicks('AnyUp')
        end
    end
end

RS:RegisterSkin(RS.Blizzard_AzeriteEssenceUI, 'Blizzard_AzeriteEssenceUI')
