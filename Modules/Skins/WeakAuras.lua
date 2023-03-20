-- WeakAuras icon and aura bar skin is from NDui
-- Profiling Window skin is from ElvUI_WindTools

local R, E, L, V, P, G = unpack((select(2, ...)))
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local unpack = unpack

-- WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function UpdateIconBgAlpha(icon, _, _, _, alpha)
	icon.backdrop:SetAlpha(alpha)
	if icon.shadow then
		icon.shadow:SetAlpha(alpha)
	end
end

local function UpdateIconTexCoord(icon)
    if icon.isCutting then return end
    icon.isCutting = true

    local width, height = icon:GetSize()
    if width ~= 0 and height ~= 0 then
        local left, right, top, bottom = unpack(E.TexCoords) -- normal icon
        local ratio = width / height
        if ratio > 1 then -- fat icon
            local offset = (1 - 1 / ratio) / 2
            top = top + offset
            bottom = bottom - offset
        elseif ratio < 1 then -- thin icon
            local offset = (1 - ratio) / 2
            left = left + offset
            bottom = bottom - offset
        end
        icon:SetTexCoord(left, right, top, bottom)
    end

    icon.isCutting = nil
end

local function handleWeakAurasIcon(icon)
    UpdateIconTexCoord(icon)
    hooksecurefunc(icon, 'SetTexCoord', UpdateIconTexCoord)
    icon:CreateBackdrop()
    icon.backdrop.Center:StripTextures()
    icon.backdrop:SetFrameLevel(0)
    hooksecurefunc(icon, 'SetVertexColor', UpdateIconBgAlpha)
end

local function Skin_WeakAuras(region, regionType)
    if regionType == 'icon' then
        if not region.styled then
            handleWeakAurasIcon(region.icon)

            region.styled = true
        end
    elseif regionType == 'aurabar' then
        if not region.styled then
            handleWeakAurasIcon(region.icon)
            region:CreateBackdrop()
            region.backdrop.Center:StripTextures()
            region.backdrop:SetFrameLevel(0)

            region.styled = true
        end

        region.icon.backdrop:SetShown(not not region.iconVisible)
    end
end

local function OnPrototypeCreate(region)
    Skin_WeakAuras(region, region.regionType)
end

local function OnPrototypeModifyFinish(_, region)
    Skin_WeakAuras(region, region.regionType)
end

function RS:WeakAuras()
    local prototype = _G.WeakAuras.regionPrototype
    hooksecurefunc(prototype, 'create', OnPrototypeCreate)
    hooksecurefunc(prototype, 'modifyFinish', OnPrototypeModifyFinish)
end

RS:RegisterSkin(RS.WeakAuras, 'WeakAuras')
