local R, E, L, V, P, G = unpack((select(2, ...)))
local QMB = R:NewModule('QuickMenuButton', 'AceEvent-3.0')

-- Lua functions
local _G = _G
local ipairs, unpack = ipairs, unpack
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local CreateFrame = CreateFrame
local GuildInvite = GuildInvite
local UnitIsPlayer = UnitIsPlayer

local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatFrame_SendTell = ChatFrame_SendTell

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
    GuildInvite(currentName)
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
	local frame = CreateFrame('Frame', 'RhythmBoxMenuButtonFrame', _G.DropDownList1)
	frame:SetSize(10, 10)
	frame:SetPoint('TOPLEFT')
	frame:Hide()

	for index, data in ipairs(menuList) do
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
