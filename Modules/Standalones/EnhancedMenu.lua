local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local EM = R:NewModule('EnhancedMenu', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local ipairs, strfind, unpack = ipairs, strfind, unpack

-- WoW API / Variables
local BNGetFriendIndex = BNGetFriendIndex
local C_BattleNet_GetFriendGameAccountInfo = C_BattleNet.GetFriendGameAccountInfo
local C_BattleNet_GetFriendNumGameAccounts = C_BattleNet.GetFriendNumGameAccounts
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer

local CloseDropDownMenus = CloseDropDownMenus
local GetUnitName = GetUnitName

local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE

local supportedTypes = {
    SELF = 1,
    PARTY = 1,
    PLAYER = 1,
    RAID_PLAYER = 1,
    RAID = 1,
    FRIEND = 1,
    BN_FRIEND = 1,
    GUILD = 1,
    GUILD_OFFLINE = 1,
    CHAT_ROSTER = 1,
    TARGET = 1,
    ARENAENEMY = 1,
    FOCUS = 1,
    WORLD_STATE_SCORE = 1,
    COMMUNITIES_WOW_MEMBER = 1,
    COMMUNITIES_GUILD_MEMBER = 1,
}

local menuButtons = {
    {
        title = '复制名字',
        func = function()
            R:Print(EM.characterName)
            CloseDropDownMenus()
        end,

        group = {},
        groupFunc = function(self)
            R:Print(self.info.group[self:GetID()])
            CloseDropDownMenus()
        end,
    },
}

function EM:GetCharacterInfo(which, unit, name, bnetIDAccount)
    if UnitExists(unit) then
        return UnitIsPlayer(unit), GetUnitName(unit, true) or name, 'UNIT'
    elseif which and which:find('^BN_') then
        local index = bnetIDAccount and BNGetFriendIndex(bnetIDAccount)
        local numGameAccounts = index and C_BattleNet_GetFriendNumGameAccounts(index)
        if numGameAccounts then
            for i = 1, numGameAccounts do
                local gameAccountInfo = C_BattleNet_GetFriendGameAccountInfo(index, i)
                if gameAccountInfo.wowProjectID == WOW_PROJECT_MAINLINE then
                    -- return true, bnetIDAccount, 'BN'
                    -- TODO: return all characters

                    local characterName = gameAccountInfo.characterName
                    if gameAccountInfo.realmName then
                        characterName = characterName .. '-' .. gameAccountInfo.realmName
                    end
                    return true, characterName, 'BN'
                end
            end
        end
    elseif name then
        return true, name, 'NAME'
    end
end

function EM:ShowMenu(list)
    local mainMenu = self.mainMenu
    -- set positioning above the active dropdown
    mainMenu:SetParent(list)
    mainMenu:SetFrameStrata(list:GetFrameStrata())
    mainMenu:SetFrameLevel(list:GetFrameLevel() + 2)
    mainMenu:ClearAllPoints()
    mainMenu:SetPoint('BOTTOMLEFT', list, 'TOPLEFT', 0, 0)
    mainMenu:SetPoint('BOTTOMRIGHT', list, 'TOPRIGHT', 0, 0)
    mainMenu:Show()
end

function EM:HideMenu()
    self.mainMenu:Hide()
    self.subMenu:Hide()
end

do
    local function ButtonOnEnter(self)
        self.Highlight:Show()
        -- TODO: handle arrow button
    end
    local function ButtonOnLeave(self)
        self.Highlight:Hide()
    end
    local function ButtonHandlesGlobalMouseEvent()
        return true
    end
    function EM:BuildButton(buttonName, parent, index)
        local button = _G[buttonName]
        if not button then
            button = CreateFrame('Button', buttonName, parent, 'UIDropDownMenuButtonTemplate')
            button:SetID(index)
        end

        button:Hide()
        button:SetScript('OnClick', nil)
        button:SetScript('OnEnter', ButtonOnEnter)
        button:SetScript('OnLeave', ButtonOnLeave)
        button:SetScript('OnEnable', nil)
        button:SetScript('OnDisable', nil)
        button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 16, -16 * index)

        button.HandlesGlobalMouseEvent = ButtonHandlesGlobalMouseEvent

        _G[buttonName .. 'Check']:Hide()
        _G[buttonName .. 'UnCheck']:Hide()
        _G[buttonName .. 'Icon']:Hide()
        _G[buttonName .. 'ColorSwatch']:Hide()
        _G[buttonName .. 'InvisibleButton']:Hide()

        local expandArrow = _G[buttonName .. 'ExpandArrow']
        local normTex = expandArrow:GetNormalTexture()
        expandArrow:SetNormalTexture(E.Media.Textures.ArrowUp)
        normTex:SetVertexColor(unpack(E.media.rgbvaluecolor))
        normTex:SetRotation(E:GetModule('Skins').ArrowRotation.right)
        expandArrow:SetSize(12, 12)
        expandArrow:Hide()

        local r, g, b = unpack(E.media.rgbvaluecolor)
        local highlight = button.Highlight
        highlight:SetTexture(E.Media.Textures.Highlight)
        highlight:SetBlendMode('BLEND')
        highlight:SetDrawLayer('BACKGROUND')
        highlight:SetVertexColor(r, g, b)

        local text = _G[buttonName .. 'NormalText']
        text:ClearAllPoints()
        text:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
        text:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 0, 0)
        button.text = text

        return button
    end
end

do
    local function MenuOnShow(self)
        local parent = self:GetParent() or self
        local width = parent:GetWidth()
        local height = 32
        for i = 1, #self.buttons do
            local button = self.buttons[i]
            if button:IsShown() then
                button:SetWidth(width - 32) -- anchor offsets for left/right
                height = height + 16
            end
        end
        self:SetHeight(height)
    end

    function EM:BuildMenu(prefix, level)
        local frame = CreateFrame('Button', prefix .. level, E.UIParent, 'UIDropDownListTemplate')
        frame:SetScript('OnClick', nil)
        frame:SetScript('OnUpdate', nil)
        frame:SetScript('OnShow', MenuOnShow)
        frame:SetScript('OnHide', nil)
        frame:SetTemplate('Transparent')
        frame:Hide()
        _G[frame:GetName() .. 'Backdrop']:Hide()
        _G[frame:GetName() .. 'MenuBackdrop']:Hide()

        frame.buttons = {}

        return frame
    end
end

function EM:Initialize()
    local prefix = 'RhythmBox_EM_Dropdown'

    local mainMenu = self:BuildMenu(prefix, 1)
    for index, info in ipairs(menuButtons) do
        local buttonName = mainMenu:GetName() .. 'Button' .. index
        local button = self:BuildButton(buttonName, mainMenu, index)
        button.info = info
        mainMenu.buttons[index] = button

        button.text:SetText(info.title)
        button:SetScript('OnClick', info.func)
        button:Show()
    end
    self.mainMenu = mainMenu

    local subMenu = self:BuildMenu(prefix, 2)
    for index = 1, 8 do -- one can only have 8 wow accounts
        local buttonName = subMenu:GetName() .. 'Button' .. index
        local button = self:BuildButton(buttonName, subMenu, index)
        subMenu.buttons[index] = button

        button:Hide()
    end
    self.subMenu = subMenu

    _G.DropDownList1:HookScript('OnShow', function(self)
        local dropdown = self.dropdown
        if not dropdown then return end

        if dropdown.which and supportedTypes[dropdown.which] then -- UnitPopup
            local dropdownFullName = dropdown.chatTarget
            if not dropdownFullName and dropdown.name then
                if dropdown.server and not strfind(dropdown.name, '-') then
                    dropdownFullName = dropdown.name .. '-' .. dropdown.server
                else
                    dropdownFullName = dropdown.name
                end
            end

            local show, characterName, kind = EM:GetCharacterInfo(dropdown.which, dropdown.unit, dropdownFullName, dropdown.bnetIDAccount)
            if not show then
                return EM:HideMenu()
            end

            EM.characterName = characterName
            EM.kind = kind

            EM:ShowMenu(self)
        end
    end)
    _G.DropDownList1:HookScript('OnHide', function()
        EM:HideMenu()
    end)
end

R:RegisterModule(EM:GetName())
