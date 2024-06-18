local R, E, L, V, P, G = unpack((select(2, ...)))
local S = E:GetModule('Skins')
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables

local function tdBattlePetScript()
    R:RegisterAddOnLoad('tdBattlePetScript', function()
        local bar = _G.ElvUIPetBattleActionBar
        local barWidth = bar:GetWidth()

        local SkipButton = _G.PetBattleFrame.BottomFrame.TurnTimer.SkipButton
        SkipButton:SetWidth(barWidth / 2 + (E.PixelMode and 0.5 or 0))
        SkipButton:SetPoint('BOTTOMRIGHT', bar, 'TOP', 0, E.PixelMode and -1 or 1, true)
        hooksecurefunc(SkipButton, 'SetPoint', function(_, point, _, relativePoint, _, _, forced)
            if (point ~= 'BOTTOMRIGHT' or relativePoint ~= 'TOP') and forced then
                SkipButton:ClearAllPoints()
                SkipButton:SetPoint('BOTTOMRIGHT', bar, 'TOP', 0, E.PixelMode and -1 or 1, true)
            end
        end)

        local xpBar = _G.PetBattleFrame.BottomFrame.xpBar
        xpBar:SetPoint('BOTTOM', SkipButton, 'TOPRIGHT', 0, E.PixelMode and 0 or 3)

        local AutoButton = _G.tdBattlePetScriptAutoButton
        AutoButton:SetWidth(barWidth / 2 + (E.PixelMode and 0.5 or 0))
        AutoButton:SetPoint('LEFT', SkipButton, 'RIGHT', E.PixelMode and -1 or 0, 0)
        S:HandleButton(AutoButton)
    end)
end

RS:RegisterPipeline(tdBattlePetScript)
