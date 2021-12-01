-- This file is basically from NDui (https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Core/Functions.lua)
-- all credit goes to siweia

local R, E, L, V, P, G = unpack(select(2, ...))

local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local rad, unpack = rad, unpack

-- WoW API / Variables

RS.NDuiTexture = {
    bdTex = [[Interface\ChatFrame\ChatFrameBackground]],
    pushed = [[Interface\Addons\ElvUI_RhythmBox\Media\NDui\Actionbar\pushed]],
}

-- Handle arrows
local arrowDegree = {
    ['up'] = 0,
    ['down'] = 180,
    ['left'] = 90,
    ['right'] = -90,
}
function RS:SetupArrow(frame, direction)
    frame:SetTexture([[Interface\Addons\ElvUI_RhythmBox\Media\NDui\arrow]])
    frame:SetRotation(rad(arrowDegree[direction]))
end

function RS:ReskinTooltip(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end

    if not tooltip.tipStyled then
        RS:HideBackdrop(tooltip)
        tooltip:DisableDrawLayer("BACKGROUND")
        tooltip:CreateBackdrop()
        tooltip.backdrop:SetBackdropColor(unpack(E.media.backdropfadecolor))

        tooltip.tipStyled = true
    end

    tooltip.backdrop:SetBackdropBorderColor(0, 0, 0)

    local font = E.Libs.LSM:Fetch("font", E.db.tooltip.font)
    local fontOutline = E.db.tooltip.fontOutline
    local headerSize = E.db.tooltip.headerFontSize
    local textSize = E.db.tooltip.textFontSize

    if tooltip.NumLines and tooltip:NumLines() > 0 then
        for index = 1, tooltip:NumLines() do
            if index == 1 then
                _G[tooltip:GetName().."TextLeft"..index]:SetFont(font, headerSize, fontOutline)
            else
                _G[tooltip:GetName().."TextLeft"..index]:SetFont(font, textSize, fontOutline)
            end
            _G[tooltip:GetName().."TextRight"..index]:SetFont(font, textSize, fontOutline)
        end
    end
end

function RS:HideBackdrop(frame)
    if frame.NineSlice then
        frame.NineSlice:SetAlpha(0)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop(nil)
    end
end
