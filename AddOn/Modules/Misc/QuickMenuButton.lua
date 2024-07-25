local R, E, L, V, P, G = unpack((select(2, ...)))
local QMB = R:NewModule('QuickMenuButton', 'AceEvent-3.0')

-- Lua functions
local ipairs = ipairs

-- WoW API / Variables
local C_GuildInfo_Invite = C_GuildInfo.Invite
local GetGuildInfo = GetGuildInfo
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName

local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local Menu_ModifyMenu = Menu.ModifyMenu

local COPY_NAME = COPY_NAME

local INVITE_TO_GUILD = gsub(CHAT_GUILD_INVITE_SEND, HEADER_COLON, '')

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

local function ChatEditCopy(text)
    local editBox = ChatEdit_ChooseBoxForSend()
	local hasText = editBox:GetText() ~= ''

	ChatEdit_ActivateChat(editBox)
	editBox:Insert(text)

	if not hasText then
        editBox:HighlightText()
    end
end

local function OnMenuShow(_, rootDescription, contextData)
    local unitInGuild = false
    local unit, name, realm = contextData.unit, contextData.name, contextData.server
    if unit and not UnitIsPlayer(unit) then
        return
    elseif unit then
        name, realm = UnitName(unit)
        unitInGuild = not not GetGuildInfo(unit)
    end
    name = name .. '-' .. (realm or E.myrealm)

    rootDescription:CreateDivider()
    rootDescription:CreateTitle('Rhythm Box')
    rootDescription:CreateButton(COPY_NAME, ChatEditCopy, name)

    if not unitInGuild then
        rootDescription:CreateButton(INVITE_TO_GUILD, C_GuildInfo_Invite, name)
    end
end

function QMB:Initialize()
    for _, tag in ipairs(menuTags) do
        Menu_ModifyMenu(tag, OnMenuShow)
    end
end

R:RegisterModule(QMB:GetName())
