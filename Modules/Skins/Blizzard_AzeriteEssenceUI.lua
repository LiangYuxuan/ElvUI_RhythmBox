local R, E, L, V, P, G = unpack(select(2, ...))
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local ipairs = ipairs

-- WoW API / Variables

function RS:Blizzard_AzeriteEssenceUI()
    if _G.AzeriteEssenceUI and _G.AzeriteEssenceUI.EssenceList and _G.AzeriteEssenceUI.EssenceList.buttons then
        for _, button in ipairs(_G.AzeriteEssenceUI.EssenceList.buttons) do
            button:HookScript('OnEnter', function(self)
                self._rhythmNext = 0
                _G.GameTooltip:AddLine("中键点击查看下一级", 0, 1, 0)
                _G.GameTooltip:Show()
            end)
            button:HookScript('OnClick', function(self, button)
                if button == 'MiddleButton' then
                    self._rhythmNext = (self._rhythmNext or 0) + 1
                    _G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                    _G.GameTooltip:SetAzeriteEssence(self.essenceID, (self.rank + self._rhythmNext) % 4 )
                    _G.GameTooltip:AddLine("中键点击查看下一级", 0, 1, 0)
                    _G.GameTooltip:Show()
                end
            end)
            button:RegisterForClicks('AnyUp')
        end
    end
end

RS:RegisterSkin(RS.Blizzard_AzeriteEssenceUI, 'Blizzard_AzeriteEssenceUI')
