local R, E, L, V, P, G = unpack((select(2, ...)))
local QMB = R:NewModule('QuickMenuButton', 'AceEvent-3.0')

-- R.IsTWW
-- luacheck: globals Menu.ModifyMenu

-- Lua functions
local _G = _G
local ipairs, unpack = ipairs, unpack
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local C_GuildInfo_Invite = C_GuildInfo.Invite
local CreateFrame = CreateFrame
local GetGuildInfo = GetGuildInfo
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName

local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatFrame_SendTell = ChatFrame_SendTell
local Menu_ModifyMenu = R.IsTWW and Menu.ModifyMenu

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

local currentName

local function ButtonOnEnter(self)
    _G.GameTooltip:Hide()
    _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -2)
    _G.GameTooltip:ClearLines()

    _G.GameTooltip:AddLine(self.text)

    _G.GameTooltip:Show()
end

local function ButtonOnLeave(self)
    _G.GameTooltip:Hide()
end

local function CopyName()
	local editBox = ChatEdit_ChooseBoxForSend()
	local hasText = editBox:GetText() ~= ''

	ChatEdit_ActivateChat(editBox)
	editBox:Insert(currentName)

	if not hasText then
        editBox:HighlightText()
    end
end

local function InviteToGuild()
    C_GuildInfo_Invite(currentName)
end

local function Whisper()
    ChatFrame_SendTell(currentName)
end

local menuList = {
    {
        text = gsub(CHAT_GUILD_INVITE_SEND, HEADER_COLON, ""),
        func = InviteToGuild, color = {0, .8, 0},
    },
    {
        text = COPY_NAME,
        func = CopyName, color = {1, 0, 0},
    },
    {
        text = WHISPER,
        func = Whisper, color = {1, .5, 1},
    },
}

function QMB:Initialize()
    if R.IsTWW then
        for _, tag in ipairs(menuTags) do
            Menu_ModifyMenu(tag, OnMenuShow)
        end
        return
    end

	local frame = CreateFrame('Frame', 'RhythmBoxMenuButtonFrame', _G.DropDownList1)
	frame:SetSize(10, 10)
	frame:SetPoint('TOPLEFT')
	frame:Hide()

	for index, data in ipairs(menuList) do
        ---@class QuickMenuButton: Button
		local button = CreateFrame('Button', nil, frame)
		button:SetSize(25, 10)
		button:SetPoint('TOPLEFT', frame, (index - 1) * 28 + 2, -2)

        button:SetScript('OnClick', data.func)
        button:SetScript('OnEnter', ButtonOnEnter)
        button:SetScript('OnLeave', ButtonOnLeave)

        button:SetTemplate('Default')
        button:StyleButton(nil, true, true)
        button:EnableMouse(true)

        -- Texture
        button.texture = button:CreateTexture(nil, 'ARTWORK')
        button.texture:SetInside()
        button.texture:SetColorTexture(unpack(data.color))

        button.text = data.text
	end

	hooksecurefunc('ToggleDropDownMenu', function(level, _, dropdownMenu)
		if level and level > 1 then return end

		local name = dropdownMenu.name
		local unit = dropdownMenu.unit
		local isPlayer = unit and UnitIsPlayer(unit)
		local isFriendMenu = dropdownMenu == _G.FriendsDropDown
		if not name or (not isPlayer and not dropdownMenu.chatType and not isFriendMenu) then
			frame:Hide()
			return
		end

		local gameAccountInfo = dropdownMenu.accountInfo and dropdownMenu.accountInfo.gameAccountInfo
		if gameAccountInfo and gameAccountInfo.characterName and gameAccountInfo.realmName then
			currentName = gameAccountInfo.characterName .. '-' .. gameAccountInfo.realmName
			frame:Show()
		else
			local server = dropdownMenu.server
			if not server or server == '' then
				server = E.myrealm
			end
			currentName = name .. '-' .. server
			frame:Show()
		end
	end)
end

R:RegisterModule(QMB:GetName())
