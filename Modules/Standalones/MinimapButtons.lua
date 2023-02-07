-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/SquareMinimapButtons.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local SMB = R:NewModule('MinimapButtons', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local ipairs, next, pairs, strfind, strmatch = ipairs, next, pairs, strfind, strmatch
local strlower, tinsert, tostring, type, unpack = strlower, tinsert, tostring, type, unpack

-- WoW API / Variables
local C_Garrison = C_Garrison
local C_PetBattles = C_PetBattles
local CreateFrame = CreateFrame
local HasNewMail = HasNewMail
local HideUIPanel = HideUIPanel
local InCombatLockdown = InCombatLockdown
local ShowUIPanel = ShowUIPanel
local UIFrameFadeIn = UIFrameFadeIn
local UIFrameFadeOut = UIFrameFadeOut

local GroupFinderFrame_ShowGroupFrame = GroupFinderFrame_ShowGroupFrame
local MinimapMailFrameUpdate = MinimapMailFrameUpdate
local Mixin = Mixin
local RegisterStateDriver = RegisterStateDriver
local UnregisterStateDriver = UnregisterStateDriver

SMB.Buttons = {}

SMB.IgnoreButton = {
    BattlefieldMinimap = true,
    ButtonCollectFrame = true,
    ElvUI_MinimapHolder = true,
    ExpansionLandingPageMinimapButton = true,
    GameTimeFrame = true,
    HelpOpenWebTicketButton = true,
    HelpOpenTicketButton = true,
    InstanceDifficultyFrame = true,
    MinimapBackdrop = true,
    MiniMapMailFrame = true,
    MinimapPanel = true,
    MiniMapTracking = true,
    MiniMapVoiceChatFrame = true,
    MinimapZoomIn = true,
    MinimapZoomOut = true,
    QueueStatusButton = true,
    RecipeRadarMinimapButtonFrame = true,
    SexyMapCustomBackdrop = true,
    SexyMapPingFrame = true,
    TimeManagerClockButton = true,
    TukuiMinimapCoord = true,
    TukuiMinimapZone = true,
    SL_MinimapDifficultyFrame = true, -- S&L Instance Indicator
    SLECoordsHolder = true, -- S&L Coords Holder
    QuestieFrameGroup = true -- Questie
}

local ButtonFunctions = { 'SetParent', 'ClearAllPoints', 'SetPoint', 'SetSize', 'SetScale', 'SetIgnoreParentScale', 'SetFrameStrata', 'SetFrameLevel' }

local RemoveTextureID = { [136430] = true, [136467] = true, [136477] = true, [136468] = true, [130924] = true }
local RemoveTextureFile = { 'interface/characterframe', 'border', 'background', 'alphamask', 'highlight' }

function SMB:RemoveTexture(texture)
    if type(texture) == 'string' then
        for _, path in next, RemoveTextureFile do
            if strfind(texture, path) or (strfind(texture, 'interface/minimap') and not strfind(texture, 'interface/minimap/tracking')) then
                return true
            end
        end
    else
        return RemoveTextureID[texture]
    end
end

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
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end
end

function SMB:LockButton(Button)
    for _, Function in pairs(ButtonFunctions) do
        Button[Function] = E.noop
    end

    if Button.SetFixedFrameStrata then
        Button:SetFixedFrameStrata(true)
    end
    if Button.SetFixedFrameLevel then
        Button:SetFixedFrameLevel(true)
    end
end

function SMB:UnlockButton(Button)
    for _, Function in pairs(ButtonFunctions) do
        Button[Function] = nil
    end

    if Button.SetFixedFrameStrata then
        Button:SetFixedFrameStrata(false)
    end
    if Button.SetFixedFrameLevel then
        Button:SetFixedFrameLevel(false)
    end
end

function SMB:HandleBlizzardButtons()
    if not E.db.RhythmBox.MinimapButtons.BarEnabled then return end
    local Size = E.db.RhythmBox.MinimapButtons.IconSize

    local MailFrame = _G.MinimapCluster.MailFrame
    if E.db.RhythmBox.MinimapButtons.MoveMail and MailFrame and not MailFrame.SMB then
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

        MailFrame:HookScript('OnShow', function() Frame.Icon:SetVertexColor(0, 1, 0) end)
        MailFrame:HookScript('OnHide', function() Frame.Icon:SetVertexColor(1, 1, 1) end)
        MailFrame:EnableMouse(false)

        if MailFrame:IsShown() then
            Frame.Icon:SetVertexColor(0, 1, 0)
        end

        -- Hide Icon & Border
        _G.MiniMapMailIcon:Hide()
        -- _G.MiniMapMailBorder:Hide()

        if E.db.RhythmBox.MinimapButtons.Shadows then
            Frame:CreateShadow()
        end

        MailFrame.SMB = true
        tinsert(self.Buttons, Frame)
    end

    if E.db.RhythmBox.MinimapButtons.HideGarrison then
        _G.ExpansionLandingPageMinimapButton:UnregisterAllEvents()
        _G.ExpansionLandingPageMinimapButton:SetParent(self.Hider)
        _G.ExpansionLandingPageMinimapButton:Hide()
    elseif (
        E.db.RhythmBox.MinimapButtons.MoveGarrison and
        C_Garrison.GetLandingPageGarrisonType() > 0 and
        not _G.ExpansionLandingPageMinimapButton.SMB
    ) then
        Mixin(_G.ExpansionLandingPageMinimapButton, _G.BackdropTemplateMixin)
        _G.ExpansionLandingPageMinimapButton:SetParent(_G.Minimap)
        _G.ExpansionLandingPageMinimapButton:UnregisterEvent('GARRISON_HIDE_LANDING_PAGE')
        _G.ExpansionLandingPageMinimapButton:Show()
        _G.ExpansionLandingPageMinimapButton:SetScale(1)
        _G.ExpansionLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)
        _G.ExpansionLandingPageMinimapButton:SetScript('OnEnter', function(self)
            self:SetBackdropBorderColor(unpack(SMB.ClassColor))
            if SMB.Bar:IsShown() then
                UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
            end
        end)
        _G.ExpansionLandingPageMinimapButton:SetScript('OnLeave', function(self)
            SMB:SetTemplate(self)
            if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
                UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
            end
        end)

        _G.ExpansionLandingPageMinimapButton.SMB = true

        if E.db.RhythmBox.MinimapButtons.Shadows then
            _G.ExpansionLandingPageMinimapButton:CreateShadow()
        end

        tinsert(self.Buttons, _G.ExpansionLandingPageMinimapButton)
    end

    if E.db.RhythmBox.MinimapButtons.MoveTracker and not _G.MinimapCluster.Tracking.Button.SMB then
        -- _G.MinimapCluster.Tracking.Show = nil

        _G.MinimapCluster.Tracking.Button:Show()
        SMB:SetTemplate(_G.MinimapCluster.Tracking.Button)

        _G.MinimapCluster.Tracking.Button:SetParent(self.Bar)
        _G.MinimapCluster.Tracking.Button:SetSize(Size, Size)

        -- _G.MinimapCluster.Tracking.Icon:ClearAllPoints()
        -- _G.MinimapCluster.Tracking.Icon:SetPoint('CENTER')

        _G.MinimapCluster.Tracking.Background:SetAlpha(0)
        -- _G.MinimapCluster.Tracking.IconOverlay:SetAlpha(0)
        _G.MinimapCluster.Tracking.Button:SetAlpha(0)

        _G.MinimapCluster.Tracking.Button:SetParent(_G.MinimapCluster.Tracking)
        _G.MinimapCluster.Tracking.Button:ClearAllPoints()
        _G.MinimapCluster.Tracking.Button:SetAllPoints(_G.MinimapCluster.Tracking)

        _G.MinimapCluster.Tracking.Button:SetScript('OnMouseDown', nil)
        _G.MinimapCluster.Tracking.Button:SetScript('OnMouseUp', nil)

        _G.MinimapCluster.Tracking.Button:HookScript('OnEnter', function(self)
            _G.MinimapCluster.Tracking.Button:SetBackdropBorderColor(unpack(SMB.ClassColor))
            if SMB.Bar:IsShown() then
                UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
            end
        end)
        _G.MinimapCluster.Tracking.Button:HookScript('OnLeave', function(self)
            SMB:SetTemplate(_G.MinimapCluster.Tracking.Button)
            if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
                UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
            end
        end)

        _G.MinimapCluster.Tracking.Button.SMB = true

        if E.db.RhythmBox.MinimapButtons.Shadows then
            _G.MinimapCluster.Tracking.Button:CreateShadow()
        end

        tinsert(self.Buttons, _G.MinimapCluster.Tracking.Button)
    end

    if E.db.RhythmBox.MinimapButtons.MoveQueue and not _G.QueueStatusButton.SMB then
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

        _G.QueueStatusButton:SetParent(self.Bar)
        _G.QueueStatusButton:SetFrameLevel(Frame:GetFrameLevel() + 2)
        _G.QueueStatusButton:ClearAllPoints()
        _G.QueueStatusButton:SetPoint('CENTER', Frame, 'CENTER', 0, 0)

        -- _G.QueueStatusButton:SetHighlightTexture(nil)

        _G.QueueStatusButton:HookScript('OnShow', function(self)
            Frame:EnableMouse(false)
        end)
        _G.QueueStatusButton:HookScript('PostClick', _G.QueueStatusButton.OnLeave)
        _G.QueueStatusButton:HookScript('OnHide', function(self)
            Frame:EnableMouse(true)
        end)

        _G.QueueStatusButton.SMB = true

        if E.db.RhythmBox.MinimapButtons.Shadows then
            Frame:CreateShadow()
        end

        tinsert(self.Buttons, Frame)
    end

    if not InCombatLockdown() then
        self:Update()
    end
end

function SMB:SkinMinimapButton(button)
    for _, frames in next, { button, button:GetChildren() } do
        for _, region in next, { frames:GetRegions() } do
            if region.IsObjectType and region:IsObjectType('Texture') then
                local texture = region.GetTextureFileID and region:GetTextureFileID()
                if not texture then
                    texture = strlower(tostring(region:GetTexture()))
                end

                if SMB:RemoveTexture(texture) then
                    region:SetTexture()
                    region:SetAlpha(0)
                else
                    region:ClearAllPoints()
                    region:SetDrawLayer('ARTWORK')
                    region:SetInside()

                    local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = region:GetTexCoord()
                    if ULx == 0 and ULy == 0 and LLx == 0 and LLy == 1 and URx == 1 and URy == 0 and LRx == 1 and LRy == 1 then
                        region:SetTexCoord(unpack(self.TexCoords))
                        button:HookScript('OnLeave', function() region:SetTexCoord(unpack(self.TexCoords)) end)
                    end

                    region.SetPoint = E.noop
                end
            end
        end
    end

    button:SetFrameLevel(_G.Minimap:GetFrameLevel() + 10)
    button:SetFrameStrata(_G.Minimap:GetFrameStrata())
    button:SetSize(E.db.RhythmBox.MinimapButtons.IconSize, E.db.RhythmBox.MinimapButtons.IconSize)

    if not button.ignoreTemplate then
        SMB:SetTemplate(button)

        if E.db.RhythmBox.MinimapButtons.Shadows then
            button:CreateShadow()
        end
    end

    button:HookScript('OnEnter', function(self)
        if SMB.Bar:IsShown() then
            UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
        end
    end)
    button:HookScript('OnLeave', function(self)
        SMB:SetTemplate(self)
        if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons.BarMouseOver then
            UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
        end
    end)

    button.isSkinned = true
    tinsert(self.Buttons, button)
end

function SMB:GrabMinimapButtons(forceUpdate)
    if (InCombatLockdown() or C_PetBattles and C_PetBattles.IsInBattle()) then return end

    local UpdateBar = forceUpdate
    for _, btn in ipairs({_G.Minimap:GetChildren()}) do
        local name = btn.GetName and btn.GetName() or btn.name

        if not (
            not btn:IsObjectType('Button') or -- Don't want frames only buttons
            (name and self.IgnoreButton[name]) or -- Ignored by default
            btn.isSkinned or -- Skinned buttons
            btn.uiMapID or -- HereBeDragons | HandyNotes
            btn.arrow or -- HandyNotes | TomCat Tours
            (btn.waypoint or btn.isZygorWaypoint) or -- Zygor
            (btn.nodeID or btn.title and btn.x and btn.y) or -- GatherMate2
            (btn.data and btn.data.UiMapID) or (name and strmatch(name, "^QuestieFrame")) or -- Questie
            (btn.uid or btn.point and btn.point.uid) or -- TomTom
            not name and not btn.icon -- don't want unnamed ones
        ) then
            self:SkinMinimapButton(btn)
            UpdateBar = true
        end
    end

    if UpdateBar then
        self:Update()
    end
end

function SMB:PLAYER_ENTERING_WORLD()
    SMB:GrabMinimapButtons(true)
end

function SMB:ToggleBar_FrameStrataLevel(value)
    if SMB.Bar.SetFixedFrameStrata then
        SMB.Bar:SetFixedFrameStrata(value)
    end
    if SMB.Bar.SetFixedFrameLevel then
        SMB.Bar:SetFixedFrameLevel(value)
    end
end

function SMB:Update()
    if not E.db.RhythmBox.MinimapButtons.BarEnabled or not E.db.RhythmBox.MinimapButtons.Enable then return end

    local AnchorX, AnchorY = 0, 1
    local ButtonsPerRow = E.db.RhythmBox.MinimapButtons.ButtonsPerRow or 12
    local Spacing = E.db.RhythmBox.MinimapButtons.ButtonSpacing or 2
    local Size = E.db.RhythmBox.MinimapButtons.IconSize or 27
    local ActualButtons = 0
    local Maxed

    local Anchor, DirMult = 'TOPLEFT', 1

    if E.db.RhythmBox.MinimapButtons.ReverseDirection then
        Anchor, DirMult = 'TOPRIGHT', -1
    end

    SMB:ToggleBar_FrameStrataLevel(false)
    SMB.Bar:SetFrameStrata(E.db.RhythmBox.MinimapButtons.Strata)
    SMB.Bar:SetFrameLevel(E.db.RhythmBox.MinimapButtons.Level)
    SMB:ToggleBar_FrameStrataLevel(true)

    for _, Button in next, SMB.Buttons do
        if Button:IsVisible() then
            AnchorX, ActualButtons = AnchorX + 1, ActualButtons + 1

            if (AnchorX % (ButtonsPerRow + 1)) == 0 then
                AnchorY, AnchorX, Maxed = AnchorY + 1, 1, true
            end

            SMB:UnlockButton(Button)

            SMB:SetTemplate(Button)

            Button:SetParent(self.Bar)
            Button:SetIgnoreParentScale(false)
            Button:ClearAllPoints()
            Button:SetPoint(Anchor, self.Bar, Anchor, DirMult * (Spacing + ((Size + Spacing) * (AnchorX - 1))), (- Spacing - ((Size + Spacing) * (AnchorY - 1))))
            Button:SetSize(E.db.RhythmBox.MinimapButtons.IconSize, E.db.RhythmBox.MinimapButtons.IconSize)
            Button:SetScale(1)
            Button:SetFrameStrata(E.db.RhythmBox.MinimapButtons.Strata)
            Button:SetFrameLevel(E.db.RhythmBox.MinimapButtons.Level + 1)
            Button:SetScript('OnDragStart', nil)
            Button:SetScript('OnDragStop', nil)

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
        UnregisterStateDriver(self.Bar, 'visibility')
        self.Bar:Hide()
    else
        RegisterStateDriver(self.Bar, 'visibility', E.db.RhythmBox.MinimapButtons.Visibility)
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
    ['Strata'] = 'MEDIUM',
    ['Level'] = 12,
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
    ['Shadows'] = false,
    ['ReverseDirection'] = true,
    ['Visibility'] = '[petbattle] hide; show',
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
                        min = -1, max = 10, step = 1,
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
                        type = 'toggle',
                        name = "反向排序",
                    },
                    Strata = {
                        order = 9,
                        type = 'select',
                        name = "框架层级",
                        values = {
                            ['BACKGROUND'] = "BACKGROUND",
                            ['LOW'] = "LOW",
                            ['MEDIUM'] = "MEDIUM",
                            ['HIGH'] = "HIGH",
                            ['DIALOG'] = "DIALOG",
                            ['FULLSCREEN'] = "FULLSCREEN",
                            ['FULLSCREEN_DIALOG'] = "FULLSCREEN_DIALOG",
                            ['TOOLTIP'] = "TOOLTIP",
                        },
                    },
                    Level = {
                        order = 10,
                        type = 'range',
                        name = "框架优先级",
                        min = 0, max = 255, step = 1,
                    },
                    Visibility = {
                        order = 11,
                        type = 'input',
                        name = "可见性",
                        width = 'double',
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
                    },
                    MoveGarrison  = {
                        type = 'toggle',
                        name = "移动要塞图标",
                        disabled = function() return E.db.RhythmBox.MinimapButtons.HideGarrison end,
                    },
                    MoveMail = {
                        type = 'toggle',
                        name = "移动邮件图标",
                    },
                    MoveTracker = {
                        type = 'toggle',
                        name = "移动追踪图标",
                    },
                    MoveQueue = {
                        type = 'toggle',
                        name = "移动队列图标",
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

    SMB:RegisterEvent('PLAYER_ENTERING_WORLD')
    SMB:ScheduleRepeatingTimer('GrabMinimapButtons', 6)
    SMB:ScheduleTimer('HandleBlizzardButtons', 7)
end

R:RegisterModule(SMB:GetName())
