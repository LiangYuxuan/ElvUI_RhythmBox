-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/SquareMinimapButtons.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local SMB = R:NewModule('MinimapButtons', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local atan2, cos, deg, floor, max, min, pairs, rad = atan2, cos, deg, floor, max, min, pairs, rad
local select, sin, sqrt, strfind, strlen, strmatch = select, sin, sqrt, strfind, strlen, strmatch
local strlower, strsub, tContains, tinsert, tostring, unpack = strlower, strsub, tContains, tinsert, tostring, unpack

-- WoW API / Variables
local C_PetBattles = C_PetBattles
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local GetGameTime = GetGameTime
local HasNewMail = HasNewMail
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local ShowUIPanel = ShowUIPanel
local UIFrameFadeIn = UIFrameFadeIn
local UIFrameFadeOut = UIFrameFadeOut

local GroupFinderFrame_ShowGroupFrame = GroupFinderFrame_ShowGroupFrame
local MinimapMailFrameUpdate = MinimapMailFrameUpdate
local Mixin = Mixin

SMB.Buttons = {}

SMB.IgnoreButton = {
    'HelpOpenWebTicketButton',
    'MiniMapVoiceChatFrame',
    'TimeManagerClockButton',
    'BattlefieldMinimap',
    'ButtonCollectFrame',
    'GameTimeFrame',
    'QueueStatusMinimapButton',
    'GarrisonLandingPageMinimapButton',
    'MiniMapMailFrame',
    'MiniMapTracking',
    'MinimapZoomIn',
    'MinimapZoomOut',
    'Narci_MinimapButton',
    'TukuiMinimapZone',
    'TukuiMinimapCoord',
    'RecipeRadarMinimapButtonFrame',
}

SMB.GenericIgnore = {
    'Archy',
    'GatherMatePin',
    'GatherNote',
    'GuildInstance',
    'HandyNotesPin',
    'MiniMap',
    'Spy_MapNoteList_mini',
    'ZGVMarker',
    'poiMinimap',
    'GuildMap3Mini',
    'LibRockConfig-1.0_MinimapButton',
    'NauticusMiniIcon',
    'WestPointer',
    'Cork',
    'DugisArrowMinimapPoint',
    'QuestieFrame',
}

SMB.PartialIgnore = { 'Node', 'Pin', 'POI' }

SMB.OverrideTexture = {
    BagSync_MinimapButton = 'Interface/AddOns/BagSync/media/icon',
    DBMMinimapButton = 'Interface/Icons/INV_Helmet_87',
    SmartBuff_MiniMapButton = 'Interface/Icons/Spell_Nature_Purge',
    VendomaticButtonFrame = 'Interface/Icons/INV_Misc_Rabbit_2',
    OutfitterMinimapButton = '',
    RecipeRadar_MinimapButton = 'Interface/Icons/INV_Scroll_03',
    GameTimeFrame = '',
}

SMB.DoNotCrop = {
    ZygorGuidesViewerMapIcon = true,
    ItemRackMinimapFrame = true,
}

SMB.UnrulyButtons = {
    'WIM3MinimapButton',
    'RecipeRadar_MinimapButton',
}

local ButtonFunctions = { 'SetParent', 'ClearAllPoints', 'SetPoint', 'SetSize', 'SetScale', 'SetFrameStrata', 'SetFrameLevel' }

local RemoveTextureID = {
    [136430] = true,
    [136467] = true,
    [136468] = true,
    [130924] = true,
}

local RemoveTextureFile = {
    ['interface/minimap/minimap-trackingborder'] = true,
    ['interface/minimap/ui-minimap-border'] = true,
    ['interface/minimap/ui-minimap-background'] = true,
}

-- API function from ProjectAzilroka
-- with Backdrop change fallback and sightly different from ElvUI toolkit
function SMB:SetTemplate(frame)
    if _G.AddOnSkins then
        _G.AddOnSkins[1]:SetTemplate(frame)
    else
        if not frame.SetBackdrop then
            Mixin(frame, _G.BackdropTemplateMixin)
        end
        frame:SetTemplate('Transparent', true)
        frame:SetBackdropColor(.08, .08, .08, .8)
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0)
    end
end

function SMB:LockButton(Button)
    for _, Function in pairs(ButtonFunctions) do
        Button[Function] = E.noop
    end
end

function SMB:UnlockButton(Button)
    for _, Function in pairs(ButtonFunctions) do
        Button[Function] = nil
    end
end

function SMB:OnUpdate()
    local mx, my = _G.Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = _G.Minimap:GetEffectiveScale()

    px, py = px / scale, py / scale

    local pos = deg(atan2(py - my, px - mx)) % 360
    local angle = rad(pos or 225)
    local x, y = cos(angle), sin(angle)
    local w = (_G.Minimap:GetWidth() + E.db.RhythmBox.MinimapButtons.IconSize) / 2
    local h = (_G.Minimap:GetHeight() + E.db.RhythmBox.MinimapButtons.IconSize) / 2
    local diagRadiusW = sqrt(2*(w)^2)-10
    local diagRadiusH = sqrt(2*(h)^2)-10

    x = max(-w, min(x*diagRadiusW, w))
    y = max(-h, min(y*diagRadiusH, h))

    self:ClearAllPoints()
    self:SetPoint('CENTER', _G.Minimap, 'CENTER', x, y)
end

function SMB:OnDragStart()
    self:SetScript('OnUpdate', SMB.OnUpdate)
end

function SMB:OnDragStop()
    self:SetScript('OnUpdate', nil)
end

function SMB:HandleBlizzardButtons()
    if not E.db.RhythmBox.MinimapButtons.BarEnabled then return end
    local Size = E.db.RhythmBox.MinimapButtons.IconSize

    if E.db.RhythmBox.MinimapButtons.MoveMail and not _G.MiniMapMailFrame.SMB then
        local Frame = CreateFrame('Frame', 'SMB_MailFrame', self.Bar)
        Frame:SetSize(Size, Size)
        SMB:SetTemplate(Frame)
        Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
        Frame.Icon:SetPoint('CENTER')
        Frame.Icon:SetSize(18, 18)
        Frame.Icon:SetTexture(_G.MiniMapMailIcon:GetTexture())
        Frame:EnableMouse(true)
        Frame:HookScript('OnEnter', function(self)
            if HasNewMail() then
                _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT')
                if _G.GameTooltip:IsOwned(self) then
                    MinimapMailFrameUpdate()
                end
            end
            self:SetBackdropBorderColor(unpack(SMB.ClassColor))
            if SMB.Bar:IsShown() then
                UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
            end
        end)
        Frame:HookScript('OnLeave', function(self)
            _G.GameTooltip:Hide()
            SMB:SetTemplate(self)
            if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
                UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
            end
        end)

        _G.MiniMapMailFrame:HookScript('OnShow', function() Frame.Icon:SetVertexColor(0, 1, 0)	end)
        _G.MiniMapMailFrame:HookScript('OnHide', function() Frame.Icon:SetVertexColor(1, 1, 1) end)

        if _G.MiniMapMailFrame:IsShown() then
            Frame.Icon:SetVertexColor(0, 1, 0)
        end

        -- Hide Icon & Border
        _G.MiniMapMailIcon:Hide()
        _G.MiniMapMailBorder:Hide()

        if E.db.RhythmBox.MinimapButtons.Shadows then
            Frame:CreateShadow()
        end

        _G.MiniMapMailFrame.SMB = true
        tinsert(self.Buttons, Frame)
    end

    if R.Retail then
        if E.db.RhythmBox.MinimapButtons.HideGarrison then
            _G.GarrisonLandingPageMinimapButton:UnregisterAllEvents()
            _G.GarrisonLandingPageMinimapButton:SetParent(self.Hider)
            _G.GarrisonLandingPageMinimapButton:Hide()
        elseif E.db.RhythmBox.MinimapButtons.MoveGarrison and not _G.GarrisonLandingPageMinimapButton.SMB then
            _G.GarrisonLandingPageMinimapButton:SetParent(_G.Minimap)
            _G.GarrisonLandingPageMinimapButton_OnLoad(_G.GarrisonLandingPageMinimapButton)
            _G.GarrisonLandingPageMinimapButton_UpdateIcon(_G.GarrisonLandingPageMinimapButton)
            _G.GarrisonLandingPageMinimapButton:Show()
            _G.GarrisonLandingPageMinimapButton:SetScale(1)
            _G.GarrisonLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)
            _G.GarrisonLandingPageMinimapButton:SetScript('OnEnter', function(self)
                self:SetBackdropBorderColor(unpack(SMB.ClassColor))
                if SMB.Bar:IsShown() then
                    UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
                end
            end)
            _G.GarrisonLandingPageMinimapButton:SetScript('OnLeave', function(self)
                SMB:SetTemplate(self)
                if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
                    UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
                end
            end)

            _G.GarrisonLandingPageMinimapButton.SMB = true

            if E.db.RhythmBox.MinimapButtons.Shadows then
                _G.GarrisonLandingPageMinimapButton:CreateShadow()
            end

            tinsert(self.Buttons, _G.GarrisonLandingPageMinimapButton)
        end

        if E.db.RhythmBox.MinimapButtons.MoveTracker and not _G.MiniMapTrackingButton.SMB then
            _G.MiniMapTracking.Show = nil

            _G.MiniMapTracking:Show()

            _G.MiniMapTracking:SetParent(self.Bar)
            _G.MiniMapTracking:SetSize(Size, Size)

            _G.MiniMapTrackingIcon:ClearAllPoints()
            _G.MiniMapTrackingIcon:SetPoint('CENTER')

            _G.MiniMapTrackingBackground:SetAlpha(0)
            _G.MiniMapTrackingIconOverlay:SetAlpha(0)
            _G.MiniMapTrackingButton:SetAlpha(0)

            _G.MiniMapTrackingButton:SetParent(_G.MinimapTracking)
            _G.MiniMapTrackingButton:ClearAllPoints()
            _G.MiniMapTrackingButton:SetAllPoints(_G.MiniMapTracking)

            _G.MiniMapTrackingButton:SetScript('OnMouseDown', nil)
            _G.MiniMapTrackingButton:SetScript('OnMouseUp', nil)

            _G.MiniMapTrackingButton:HookScript('OnEnter', function(self)
                _G.MiniMapTracking:SetBackdropBorderColor(unpack(SMB.ClassColor))
                if SMB.Bar:IsShown() then
                    UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
                end
            end)
            _G.MiniMapTrackingButton:HookScript('OnLeave', function(self)
                SMB:SetTemplate(_G.MiniMapTracking)
                if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
                    UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
                end
            end)

            _G.MiniMapTrackingButton.SMB = true

            if E.db.RhythmBox.MinimapButtons.Shadows then
                _G.MiniMapTracking:CreateShadow()
            end

            tinsert(self.Buttons, _G.MiniMapTracking)
        end

        if E.db.RhythmBox.MinimapButtons.MoveQueue and not _G.QueueStatusMinimapButton.SMB then
            local Frame = CreateFrame('Frame', 'SMB_QueueFrame', self.Bar)
            SMB:SetTemplate(Frame)
            Frame:SetSize(Size, Size)
            Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
            Frame.Icon:SetSize(Size, Size)
            Frame.Icon:SetPoint('CENTER')
            Frame.Icon:SetTexture('Interface/LFGFrame/LFG-Eye')
            Frame.Icon:SetTexCoord(0, 64 / 512, 0, 64 / 256)
            Frame:SetScript('OnMouseDown', function()
                if _G.PVEFrame:IsShown() then
                    HideUIPanel(_G.PVEFrame)
                else
                    ShowUIPanel(_G.PVEFrame)
                    GroupFinderFrame_ShowGroupFrame()
                end
            end)
            Frame:HookScript('OnEnter', function(self)
                self:SetBackdropBorderColor(unpack(SMB.ClassColor))
                if SMB.Bar:IsShown() then
                    UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
                end
            end)
            Frame:HookScript('OnLeave', function(self)
                SMB:SetTemplate(self)
                if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
                    UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
                end
            end)

            _G.QueueStatusMinimapButton:SetParent(self.Bar)
            _G.QueueStatusMinimapButton:SetFrameLevel(Frame:GetFrameLevel() + 2)
            _G.QueueStatusMinimapButton:ClearAllPoints()
            _G.QueueStatusMinimapButton:SetPoint('CENTER', Frame, 'CENTER', 0, 0)

            _G.QueueStatusMinimapButton:SetHighlightTexture(nil)

            _G.QueueStatusMinimapButton:HookScript('OnShow', function(self)
                Frame:EnableMouse(false)
            end)
            _G.QueueStatusMinimapButton:HookScript('PostClick', _G.QueueStatusMinimapButton_OnLeave)
            _G.QueueStatusMinimapButton:HookScript('OnHide', function(self)
                Frame:EnableMouse(true)
            end)

            _G.QueueStatusMinimapButton.SMB = true

            if E.db.RhythmBox.MinimapButtons.Shadows then
                Frame:CreateShadow()
            end

            tinsert(self.Buttons, Frame)
        end
    else
        -- MiniMapTrackingFrame
        if E.db.RhythmBox.MinimapButtons.MoveGameTimeFrame and not _G.GameTimeFrame.SMB then
            local STEP = 5.625 -- 256 * 5.625 = 1440M = 24H
            local PX_PER_STEP = 0.00390625 -- 1 / 256
            local l, r, offset

            SMB:SetTemplate(_G.GameTimeFrame)
            _G.GameTimeTexture:SetTexture('')

            _G.GameTimeFrame.DayTimeIndicator = _G.GameTimeFrame:CreateTexture(nil, 'BACKGROUND', nil, 1)
            _G.GameTimeFrame.DayTimeIndicator:SetTexture('Interface/Minimap/HumanUITile-TimeIndicator', true)
            _G.GameTimeFrame.DayTimeIndicator:SetInside()

            _G.GameTimeFrame:SetSize(Size, Size)

            _G.GameTimeFrame.timeOfDay = 0
            local function OnUpdate(self, elapsed)
                self.elapsed = (self.elapsed or 1) + elapsed
                if self.elapsed > 1 then
                    local hour, minute = GetGameTime()
                    local time = hour * 60 + minute
                    if time ~= self.timeOfDay then
                        offset = PX_PER_STEP * floor(time / STEP)

                        l = 0.25 + offset -- 64 / 256
                        if l >= 1.25 then l = 0.25 end

                        r = 0.75 + offset -- 192 / 256
                        if r >= 1.75 then r = 0.75 end

                        self.DayTimeIndicator:SetTexCoord(l, r, 0, 1)

                        self.timeOfDay = time
                    end

                    self.elapsed = 0
                end
            end

            _G.GameTimeFrame:SetScript('OnUpdate', OnUpdate)
            _G.GameTimeFrame.SMB = true
            tinsert(self.Buttons, _G.GameTimeFrame)
        end
    end

    self:Update()
end

function SMB:SkinMinimapButton(Button)
    if (not Button) or Button.isSkinned then return end

    local Name = Button.GetName and Button:GetName()
    if not Name then return end

    if tContains(SMB.IgnoreButton, Name) then return end

    for i = 1, #SMB.GenericIgnore do
        if strsub(Name, 1, strlen(SMB.GenericIgnore[i])) == SMB.GenericIgnore[i] then return end
    end

    for i = 1, #SMB.PartialIgnore do
        if strmatch(Name, SMB.PartialIgnore[i]) ~= nil then return end
    end

    for i = 1, Button:GetNumRegions() do
        local Region = select(i, Button:GetRegions())
        if Region.IsObjectType and Region:IsObjectType('Texture') then
            local Texture = Region.GetTextureFileID and Region:GetTextureFileID()

            if RemoveTextureID[Texture] then
                Region:SetTexture()
            else
                Texture = strlower(tostring(Region:GetTexture()))
                if RemoveTextureFile[Texture] or (strfind(Texture, 'interface/characterframe') or (strfind(Texture, 'interface/minimap') and not strfind(Texture, 'interface/minimap/tracking')) or strfind(Texture, 'border') or strfind(Texture, 'background') or strfind(Texture, 'alphamask') or strfind(Texture, 'highlight')) then
                    Region:SetTexture()
                    Region:SetAlpha(0)
                else
                    if SMB.OverrideTexture[Name] then
                        Region:SetTexture(SMB.OverrideTexture[Name])
                    end

                    Region:ClearAllPoints()
                    Region:SetDrawLayer('ARTWORK')
                    Region:SetInside()

                    if not SMB.DoNotCrop[Name] and not Button.ignoreCrop then
                        Region:SetTexCoord(unpack(self.TexCoords))
                        Button:HookScript('OnLeave', function() Region:SetTexCoord(unpack(self.TexCoords)) end)
                    end

                    Region.SetPoint = E.noop
                end
            end
        end
    end

    Button:SetFrameLevel(_G.Minimap:GetFrameLevel() + 10)
    Button:SetFrameStrata(_G.Minimap:GetFrameStrata())
    Button:SetSize(E.db.RhythmBox.MinimapButtons.IconSize, E.db.RhythmBox.MinimapButtons.IconSize)

    if not Button.ignoreTemplate then
        SMB:SetTemplate(Button)

        if E.db.RhythmBox.MinimapButtons.Shadows then
            Button:CreateShadow()
        end
    end

    Button:HookScript('OnEnter', function(self)
        if SMB.Bar:IsShown() then
            UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
        end
    end)
    Button:HookScript('OnLeave', function(self)
        SMB:SetTemplate(self)
        if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
            UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
        end
    end)

    Button.isSkinned = true
    tinsert(self.Buttons, Button)
end

function SMB:GrabMinimapButtons()
    if (InCombatLockdown() or C_PetBattles and C_PetBattles.IsInBattle()) then return end

    for _, Button in pairs(SMB.UnrulyButtons) do
        if _G[Button] then
            _G[Button]:SetParent(_G.Minimap)
        end
    end

    for _, Frame in pairs({ _G.Minimap, _G.MinimapBackdrop, _G.MinimapCluster }) do
        local NumChildren = Frame:GetNumChildren()
        if NumChildren < (Frame.SMBNumChildren or 0) then return end
        for i = 1, NumChildren do
            local object = select(i, Frame:GetChildren())
            if object then
                local name = object:GetName()
                local width = object:GetWidth()
                if name and width > 15 and width < 60 and (object:IsObjectType('Button') or object:IsObjectType('Frame')) then
                    self:SkinMinimapButton(object)
                end
            end
        end
        Frame.SMBNumChildren = NumChildren
    end

    self:Update()
end

function SMB:Update()
    if not E.db.RhythmBox.MinimapButtons.BarEnabled then return end

    local AnchorX, AnchorY = 0, 1
    local ButtonsPerRow = E.db.RhythmBox.MinimapButtons.ButtonsPerRow or 12
    local Spacing = E.db.RhythmBox.MinimapButtons.ButtonSpacing or 2
    local Size = E.db.RhythmBox.MinimapButtons.IconSize or 27
    local ActualButtons, Maxed = 0

    local Anchor, DirMult = 'TOPLEFT', 1

    if E.db.RhythmBox.MinimapButtons.ReverseDirection then
        Anchor, DirMult = 'TOPRIGHT', -1
    end

    for _, Button in pairs(SMB.Buttons) do
        if Button:IsVisible() then
            AnchorX, ActualButtons = AnchorX + 1, ActualButtons + 1

            if (AnchorX % (ButtonsPerRow + 1)) == 0 then
                AnchorY, AnchorX, Maxed = AnchorY + 1, 1, true
            end

            SMB:UnlockButton(Button)

            SMB:SetTemplate(Button)

            Button:SetParent(self.Bar)
            Button:ClearAllPoints()
            Button:SetPoint(Anchor, self.Bar, Anchor, DirMult * (Spacing + ((Size + Spacing) * (AnchorX - 1))), (- Spacing - ((Size + Spacing) * (AnchorY - 1))))
            Button:SetSize(E.db.RhythmBox.MinimapButtons.IconSize, E.db.RhythmBox.MinimapButtons.IconSize)
            Button:SetScale(1)
            Button:SetFrameStrata('MEDIUM')
            Button:SetFrameLevel(self.Bar:GetFrameLevel() + 1)
            Button:SetScript('OnDragStart', nil)
            Button:SetScript('OnDragStop', nil)
            --Button:SetScript('OnEvent', nil)

            SMB:LockButton(Button)

            if Maxed then ActualButtons = ButtonsPerRow end
        end
    end

    local BarWidth = Spacing + (Size * ActualButtons) + (Spacing * (ActualButtons - 1)) + Spacing
    local BarHeight = Spacing + (Size * AnchorY) + (Spacing * (AnchorY - 1)) + Spacing

    self.Bar:SetSize(BarWidth, BarHeight)

    if E.db.RhythmBox.MinimapButtons.Backdrop then
        SMB:SetTemplate(self.Bar)
    elseif self.Bar.SetBackdrop then
        self.Bar:SetBackdrop(nil)
    end

    if ActualButtons == 0 then
        self.Bar:Hide()
    else
        self.Bar:Show()
    end

    if E.db.RhythmBox.MinimapButtons.BarMouseOver then
        UIFrameFadeOut(self.Bar, 0.2, self.Bar:GetAlpha(), 0)
    else
        UIFrameFadeIn(self.Bar, 0.2, self.Bar:GetAlpha(), 1)
    end
end

P["RhythmBox"]["MinimapButtons"] = {
    ['Enable'] = true,
    ['BarMouseOver'] = false,
    ['BarEnabled'] = true,
    ['Backdrop'] = false,
    ['IconSize'] = 27,
    ['ButtonsPerRow'] = 6,
    ['ButtonSpacing'] = 3,
    ['HideGarrison'] = false,
    ['MoveGarrison'] = false,
    ['MoveMail'] = false,
    ['MoveTracker'] = false,
    ['MoveQueue'] = false,
    ['MoveGameTimeFrame'] = true,
    ['Shadows'] = false,
    ['ReverseDirection'] = true,
}

local function MinimapOptions()
    E.Options.args.RhythmBox.args.MinimapButtons = {
        order = 13,
        type = 'group',
        name = "小地图按钮",
        get = function(info) return E.db.RhythmBox.MinimapButtons[info[#info]] end,
        set = function(info, value) E.db.RhythmBox.MinimapButtons[info[#info]] = value; SMB:Update() end,
        args = {
            Enable = {
                order = 1,
                type = 'toggle',
                name = "启用",
                set = function(info, value) E.db.RhythmBox.MinimapButtons[info[#info]] = value; E:StaticPopup_Show('PRIVATE_RL') end,
            },
            mbb = {
                order = 2,
                type = 'group',
                name = "小地图按钮 / 按钮条",
                guiInline = true,
                args = {
                    BarEnabled = {
                        order = 1,
                        type = 'toggle',
                        name = "启用按钮条",
                    },
                    BarMouseOver = {
                        order = 2,
                        type = 'toggle',
                        name = "鼠标划过显示",
                    },
                    Backdrop = {
                        order = 3,
                        type = 'toggle',
                        name = "背景",
                    },
                    IconSize = {
                        order = 4,
                        type = 'range',
                        name = "按钮尺寸",
                        min = 12, max = 48, step = 1,
                    },
                    ButtonSpacing = {
                        order = 5,
                        type = 'range',
                        name = "按钮间隔",
                        min = 0, max = 10, step = 1,
                    },
                    ButtonsPerRow = {
                        order = 6,
                        type = 'range',
                        name = "每行按钮数",
                        min = 1, max = 100, step = 1,
                    },
                    Shadows = {
                        order = 7,
                        type = 'toggle',
                        name = "阴影",
                    },
                    ReverseDirection = {
                        order = 8,
                        type = "toggle",
                        name = "反向排序",
                    },
                },
            },
            blizzard = {
                type = 'group',
                name = "暴雪原生图标",
                guiInline = true,
                set = function(info, value) E.db.RhythmBox.MinimapButtons[info[#info]] = value; SMB:Update(); SMB:HandleBlizzardButtons() end,
                order = 2,
                args = {
                    HideGarrison  = {
                        type = 'toggle',
                        name = "隐藏要塞图标",
                        disabled = function() return E.db.RhythmBox.MinimapButtons.MoveGarrison end,
                        hidden = R.Classic,
                    },
                    MoveGarrison  = {
                        type = 'toggle',
                        name = "移动要塞图标",
                        disabled = function() return E.db.RhythmBox.MinimapButtons.HideGarrison end,
                        hidden = R.Classic,
                    },
                    MoveMail = {
                        type = 'toggle',
                        name = "移动邮件图标",
                    },
                    MoveGameTimeFrame = {
                        type = 'toggle',
                        name = "移动游戏时间图标",
                        hidden = R.Retail,
                    },
                    MoveTracker = {
                        type = 'toggle',
                        name = "移动追踪图标",
                        hidden = R.Classic,
                    },
                    MoveQueue = {
                        type = 'toggle',
                        name = "移动队列图标",
                        hidden = R.Classic,
                    },
                },
            },
        },
    }
end
tinsert(R.Config, MinimapOptions)

function SMB:Initialize()
    if E.db.RhythmBox.MinimapButtons.Enable ~= true then return end

    SMB.Hider = CreateFrame('Frame', nil, _G.UIParent)

    SMB.Bar = CreateFrame('Frame', 'SquareMinimapButtonBar', _G.UIParent)
    SMB.Bar:Hide()
    SMB.Bar:SetPoint('RIGHT', _G.UIParent, 'RIGHT', -45, 0)
    SMB.Bar:SetFrameStrata('MEDIUM')
    SMB.Bar:SetClampedToScreen(true)
    SMB.Bar:SetMovable(true)
    SMB.Bar:EnableMouse(true)
    SMB.Bar:SetSize(E.db.RhythmBox.MinimapButtons.IconSize, E.db.RhythmBox.MinimapButtons.IconSize)

    SMB.Bar:SetScript('OnEnter', function(self) UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1) end)
    SMB.Bar:SetScript('OnLeave', function(self)
        if E.db.RhythmBox.MinimapButtons.BarMouseOver then
            UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
        end
    end)

    E:CreateMover(SMB.Bar, 'SquareMinimapButtonBarMover', 'SquareMinimapButtonBar Anchor', nil, nil, nil, 'ALL,GENERAL,RHYTHMBOX')

    local classColor = E:ClassColor(E.myclass, true)
    SMB.ClassColor = {classColor.r, classColor.g, classColor.b}
    SMB.TexCoords = E.TexCoords

    SMB:ScheduleRepeatingTimer('GrabMinimapButtons', 6)
    SMB:ScheduleTimer('HandleBlizzardButtons', 7)
end

R:RegisterModule(SMB:GetName())
