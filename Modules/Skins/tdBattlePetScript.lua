local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local S = E:GetModule('Skins')
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G

-- WoW API / Variables
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

function RS:tdBattlePetScript()
    local barWidth = _G.ElvUIPetBattleActionBar:GetWidth()
    local anchor = CreateFrame('Frame', nil, _G.ElvUIPetBattleActionBar)
    anchor:SetSize(barWidth / 2, 1)
    anchor:ClearAllPoints()
    anchor:SetPoint('BOTTOMRIGHT', _G.ElvUIPetBattleActionBar, 'TOP', 0, E.PixelMode and -2 or 0)

    local SkipButton = _G.PetBattleFrame.BottomFrame.TurnTimer.SkipButton
    SkipButton:SetParent(anchor)
    SkipButton:SetWidth(barWidth / 2 + (E.PixelMode and 0.5 or 0))
    SkipButton:SetPoint('BOTTOM', anchor, 'TOP', 0, E.PixelMode and -1 or 1)
    hooksecurefunc(SkipButton, 'SetPoint', function(_, point, _, anchorPoint, xOffset, yOffset)
        if point ~= 'BOTTOM' or anchorPoint ~= 'TOP' or xOffset ~= 0 or yOffset ~= (E.PixelMode and -1 or 1) then
            SkipButton:ClearAllPoints()
            SkipButton:SetPoint('BOTTOM', anchor, 'TOP', 0, E.PixelMode and -1 or 1)
        end
    end)

    local AutoButton = _G.tdBattlePetScriptAutoButton
    AutoButton:SetWidth(barWidth / 2 + (E.PixelMode and 0.5 or 0))
    AutoButton:SetPoint('LEFT', SkipButton, 'RIGHT', E.PixelMode and -1 or 0, 0)
    S:HandleButton(AutoButton)
end

RS:RegisterSkin(RS.tdBattlePetScript, 'tdBattlePetScript')
