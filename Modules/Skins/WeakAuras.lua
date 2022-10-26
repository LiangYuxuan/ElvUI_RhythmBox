-- WeakAuras icon and aura bar skin is from NDui
-- Profiling Window skin is from ElvUI_WindTools

local R, E, L, V, P, G = unpack(select(2, ...))
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

local cooldowns = {}
local function Skin_WeakAuras(region, regionType)
    if regionType == 'icon' then
        if not region.styled then
            handleWeakAurasIcon(region.icon)

            region.styled = true
        end

        local cd = region.cooldown.CooldownSettings or {}
        cd.font = E.Libs.LSM:Fetch('font', E.db.cooldown.fonts.font)
        cd.fontSize = E.db.cooldown.fonts.fontSize
        cd.fontOutline = E.db.cooldown.fonts.fontOutline
        region.cooldown.CooldownSettings = cd

        region.cooldown.forceDisabled = nil

        if region.id and _G.WeakAuras.GetData(region.id).cooldownTextDisabled then
            region.cooldown.hideText = true
            region.cooldown.noCooldownCount = true
        else
            region.cooldown.hideText = false
            region.cooldown.noCooldownCount = true
        end
        region.cooldown:SetHideCountdownNumbers(region.cooldown.noCooldownCount)

        if not cooldowns[region] then
            E:RegisterCooldown(region.cooldown)
            cooldowns[region] = true
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
    if region.regionType == 'icon' then
        E:UpdateCooldownOverride('global')
    end
end

local function OnPrototypeModifyFinish(_, region)
    Skin_WeakAuras(region, region.regionType)
    if region.regionType == 'icon' then
        E:UpdateCooldownOverride('global')
    end
end

function RS:WeakAuras()
    local prototype = _G.WeakAuras.regionPrototype
    hooksecurefunc(prototype, 'create', OnPrototypeCreate)
    hooksecurefunc(prototype, 'modifyFinish', OnPrototypeModifyFinish)

    -- for _, regions in pairs(_G.WeakAuras.regions) do
    --     if regions.regionType == 'icon' or regions.regionType == 'aurabar' then
    --         Skin_WeakAuras(regions.region, regions.regionType)
    --     end
    -- end
end

RS:RegisterSkin(RS.WeakAuras, 'WeakAuras')
