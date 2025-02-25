local R, E, L, V, P, G = unpack((select(2, ...)))
local QMB = R:NewModule('QuickMenuButton', 'AceEvent-3.0')
local LRI = LibStub('LibRealmInfo')

-- Lua functions
local _G = _G
local gsub, ipairs, strlower, strsub = gsub, ipairs, strlower, strsub

-- WoW API / Variables
local C_BattleNet_GetAccountInfoByID = C_BattleNet.GetAccountInfoByID
local C_GuildInfo_Invite = C_GuildInfo.Invite
local GetGuildInfo = GetGuildInfo
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName
local IsControlKeyDown = IsControlKeyDown
local C_Timer_After = C_Timer.After

local Menu_ModifyMenu = Menu.ModifyMenu
local StaticPopup_Show = StaticPopup_Show
local StaticPopup_Hide = StaticPopup_Hide

local COPY_NAME = COPY_NAME

local INVITE_TO_GUILD = gsub(CHAT_GUILD_INVITE_SEND, HEADER_COLON, '')

local function CopiedToClipboard()
    StaticPopup_Hide('RHYTHMBOX_COPY_TEXT')
    _G.UIErrorsFrame:AddMessage("已复制到剪贴板")
end

StaticPopupDialogs['RHYTHMBOX_COPY_TEXT'] = {
    text = '%s',
    button2 = CLOSE,
    hasEditBox = true,
    hasWideEditBox = true,
    editBoxWidth = 350,
    preferredIndex = 3,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    OnShow = function(self)
        self:SetWidth(420)

        local editBox = _G[self:GetName() .. 'WideEditBox'] or _G[self:GetName() .. 'EditBox']
        editBox:SetText(self.text.text_arg2)
        editBox:SetFocus()
        editBox:HighlightText()
        self.editBox:SetScript('OnKeyDown', function(_, key)
            if key == 'C' and IsControlKeyDown() then
                C_Timer_After(.1, CopiedToClipboard)
            end
        end)

        local button = _G[self:GetName() .. 'Button2']
        button:ClearAllPoints()
        button:SetWidth(200)
        button:SetPoint('CENTER', editBox, 'CENTER', 0, -30)
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    OnHide = nil,
    OnAccept = nil,
    OnCancel = nil,
}

local menuTags = {
    'MENU_UNIT_SELF',
    -- 'MENU_UNIT_PET',
    -- 'MENU_UNIT_OTHERPET',
    -- 'MENU_UNIT_BATTLEPET',
    -- 'MENU_UNIT_OTHERBATTLEPET',
    'MENU_UNIT_PARTY',
    'MENU_UNIT_PLAYER',
    'MENU_UNIT_ENEMY_PLAYER',
    'MENU_UNIT_RAID_PLAYER',
    'MENU_UNIT_RAID',
    'MENU_UNIT_FRIEND',
    'MENU_UNIT_FRIEND_OFFLINE',
    'MENU_UNIT_BN_FRIEND',
    -- 'MENU_UNIT_BN_FRIEND_OFFLINE',
    -- 'MENU_UNIT_GLUE_FRIEND',
    -- 'MENU_UNIT_GLUE_FRIEND_OFFLINE',
    'MENU_UNIT_GUILD',
    'MENU_UNIT_GUILD_OFFLINE',
    'MENU_UNIT_CHAT_ROSTER',
    -- 'MENU_UNIT_VEHICLE',
    'MENU_UNIT_TARGET',
    'MENU_UNIT_ARENAENEMY',
    'MENU_UNIT_FOCUS',
    -- 'MENU_UNIT_BOSS',
    'MENU_UNIT_COMMUNITIES_WOW_MEMBER',
    'MENU_UNIT_COMMUNITIES_GUILD_MEMBER',
    -- 'MENU_UNIT_GUILDS_GUILD',
    -- 'MENU_UNIT_COMMUNITIES_MEMBER',
    -- 'MENU_UNIT_COMMUNITIES_COMMUNITY',
    -- 'MENU_UNIT_RAID_TARGET_ICON',
    -- 'MENU_UNIT_WORLD_STATE_SCORE',
    -- 'MENU_UNIT_PVP_SCOREBOARD',
    -- 'MENU_UNIT_GLUE_PARTY_MEMBER',
}

local function GetServerURLInfo(realmName)
    local _, _, _, _, locale, _, region, _, _, englishName = LRI:GetRealmInfo(realmName)

    local regionURL = strlower(region)
    local localeURL = strlower(strsub(locale, 1, 2) .. '-' .. strsub(locale, 3, 4))
    local realmNameURL = strlower(gsub(gsub(englishName, '\'', ''), ' ', '-'))

    return regionURL, localeURL, realmNameURL
end

local function ShowStaticPopupDialog(text)
    StaticPopup_Show('RHYTHMBOX_COPY_TEXT', "按 Ctrl + C 复制", text)
end

local function OnMenuShow(_, rootDescription, contextData)
    local name, realm = contextData.name, contextData.server
    local unitInGuild = false

    if contextData.bnetIDAccount then
        local info = C_BattleNet_GetAccountInfoByID(contextData.bnetIDAccount)
        name = info and info.gameAccountInfo and info.gameAccountInfo.characterName
        realm = info and info.gameAccountInfo and info.gameAccountInfo.realmName
    elseif contextData.unit then
        if not UnitIsPlayer(contextData.unit) then
            return
        end

        name, realm = UnitName(contextData.unit)
        unitInGuild = not not GetGuildInfo(contextData.unit)
    end

    if not name then return end
    local fullName = name .. '-' .. (realm or E.myrealm)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle('Rhythm Box')
    rootDescription:CreateButton(COPY_NAME, ShowStaticPopupDialog, fullName)

    local regionURL, localeURL, realmNameURL = GetServerURLInfo(realm or E.myrealm)
    local armoryURL
    if LRI:GetCurrentRegion() == 'CN' then
        armoryURL = 'https://wow.blizzard.cn/character/#/' .. realmNameURL .. '/' .. name
    else
        armoryURL = 'https://worldofwarcraft.com/' .. localeURL .. '/character/' .. regionURL .. '/' .. realmNameURL .. '/' .. name
    end
    local wclURL = 'https://' .. regionURL .. '.warcraftlogs.com/character/' .. regionURL .. '/' .. realmNameURL .. '/' .. name
    local rioURL = 'https://raider.io/characters/' .. regionURL .. '/' .. realmNameURL .. '/' .. name

    rootDescription:CreateButton("复制英雄榜地址", ShowStaticPopupDialog, armoryURL)
    rootDescription:CreateButton("复制 Logs 地址", ShowStaticPopupDialog, wclURL)
    rootDescription:CreateButton("复制 RIO 地址", ShowStaticPopupDialog, rioURL)

    if not unitInGuild then
        rootDescription:CreateButton(INVITE_TO_GUILD, C_GuildInfo_Invite, fullName)
    end
end

function QMB:Initialize()
    for _, tag in ipairs(menuTags) do
        Menu_ModifyMenu(tag, OnMenuShow)
    end
end

R:RegisterModule(QMB:GetName())
