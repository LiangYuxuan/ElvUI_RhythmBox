-- WeakAuras icon and aura bar skin is from NDui
-- Profiling Window skin is from ElvUI_WindTools

local R, E, L, V, P, G = unpack(select(2, ...))

local S = E:GetModule('Skins')
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local pairs, unpack = pairs, unpack

-- WoW API / Variables
local hooksecurefunc = hooksecurefunc

local function IconBgOnUpdate(self)
    self:SetAlpha(self.icon:GetAlpha())
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

local cooldowns = {}
local function Skin_WeakAuras(region, regionType)
    if regionType == 'icon' then
        if not region.styled then
            UpdateIconTexCoord(region.icon)
            hooksecurefunc(region.icon, 'SetTexCoord', UpdateIconTexCoord)
            region:CreateBackdrop()
            region.backdrop.Center:StripTextures()
            region.backdrop:SetFrameLevel(0)
            region.backdrop.icon = region.icon
            region.backdrop:HookScript('OnUpdate', IconBgOnUpdate)

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
            UpdateIconTexCoord(region.icon)
            hooksecurefunc(region.icon, 'SetTexCoord', UpdateIconTexCoord)
            region:CreateBackdrop()
            region.backdrop.Center:StripTextures()
            region.backdrop:SetFrameLevel(0)
            region.iconFrame:SetAllPoints(region.icon)
            region.iconFrame:CreateBackdrop()

            region.styled = true
        end
    end
end

function RS:WeakAuras_PrintProfile()
    local frame = _G.WADebugEditBox.Background

    if frame and not frame.styled then
        S:HandleScrollBar(_G.WADebugEditBoxScrollFrameScrollBar)

        frame:StripTextures()
        frame:CreateBackdrop('Transparent')

        for _, child in pairs({frame:GetChildren()}) do
            if child:GetNumRegions() == 3 then
                child:StripTextures()

                local closeButton = child:GetChildren()
                S:HandleCloseButton(closeButton)
                closeButton:ClearAllPoints()
                closeButton:Point('TOPRIGHT', frame, 'TOPRIGHT', 3, 7)
            end
        end

        frame.styled = true
    end
end

function RS:ProfilingWindow_UpdateButtons(frame)
    for _, button in pairs({frame.statsFrame:GetChildren()}) do
        S:HandleButton(button)
    end

    for _, button in pairs({frame.titleFrame:GetChildren()}) do
        if not button.styled and button.GetNormalTexture then
            local normalTexturePath = button:GetNormalTexture():GetTexture()
            if normalTexturePath == 'Interface\\BUTTONS\\UI-Panel-CollapseButton-Up' then
                button:StripTextures()

                button.Texture = button:CreateTexture(nil, 'OVERLAY')
                button.Texture:Point('CENTER')
                button.Texture:SetTexture(E.Media.Textures.ArrowUp)
                button.Texture:Size(14, 14)

                button:HookScript('OnEnter', function(self)
                    if self.Texture then
                        self.Texture:SetVertexColor(unpack(E.media.rgbvaluecolor))
                    end
                end)

                button:HookScript('OnLeave', function(self)
                    if self.Texture then
                        self.Texture:SetVertexColor(1, 1, 1)
                    end
                end)

                button:HookScript('OnClick', function(self)
                    self:SetNormalTexture('')
                    self:SetPushedTexture('')
                    self.Texture:Show('')
                    if self:GetParent():GetParent().minimized then
                        button.Texture:SetRotation(S.ArrowRotation['down'])
                    else
                        button.Texture:SetRotation(S.ArrowRotation['up'])
                    end
                end)

                button:SetHitRectInsets(6, 6, 7, 7)
                button:Point('TOPRIGHT', frame.titleFrame, 'TOPRIGHT', -19, 3)
            else
                S:HandleCloseButton(button)
                button:ClearAllPoints()
                button:Point('TOPRIGHT', frame.titleFrame, 'TOPRIGHT', 3, 5)
            end

            button.styled = true
        end
    end
end

function RS:WeakAuras()
    local regionTypes = _G.WeakAuras.regionTypes
    local Create_Icon, Modify_Icon = regionTypes.icon.create, regionTypes.icon.modify
    local Create_AuraBar, Modify_AuraBar = regionTypes.aurabar.create, regionTypes.aurabar.modify

    regionTypes.icon.create = function(parent, data)
        local region = Create_Icon(parent, data)
        Skin_WeakAuras(region, 'icon')

        E:UpdateCooldownOverride('global')

        return region
    end

    regionTypes.aurabar.create = function(parent)
        local region = Create_AuraBar(parent)
        Skin_WeakAuras(region, 'aurabar')
        return region
    end

    regionTypes.icon.modify = function(parent, region, data)
        Modify_Icon(parent, region, data)
        Skin_WeakAuras(region, 'icon')

        E:UpdateCooldownOverride('global')
    end

    regionTypes.aurabar.modify = function(parent, region, data)
        Modify_AuraBar(parent, region, data)
        Skin_WeakAuras(region, 'aurabar')
    end

    for regionName in pairs(_G.WeakAuras.regions) do
        local regions = _G.WeakAuras.regions[regionName]
        if regions.regionType == 'icon' or regions.regionType == 'aurabar' then
            Skin_WeakAuras(regions.region, regions.regionType)
        end
    end

    local profilingWindow = _G.WeakAuras.frames['RealTime Profiling Window']
    if profilingWindow then
        self:SecureHook(profilingWindow, 'UpdateButtons', 'ProfilingWindow_UpdateButtons')
        self:SecureHook(_G.WeakAuras, 'PrintProfile', 'WeakAuras_PrintProfile')
    end
end

RS:RegisterSkin(RS.WeakAuras, 'WeakAuras')
