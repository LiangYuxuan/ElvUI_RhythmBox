-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/SquareMinimapButtons.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local SMB = R:NewModule('MinimapButtons', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local _G = _G
local pairs, select, strfind, strlen, strlower, strsub = pairs, select, strfind, strlen, strlower, strsub
local tContains, tinsert, tonumber, tostring, unpack = tContains, tinsert, tonumber, tostring, unpack

-- WoW API / Variables
local C_PetBattles = C_PetBattles
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local UIFrameFadeIn = UIFrameFadeIn
local UIFrameFadeOut = UIFrameFadeOut

SMB.Buttons = {}

SMB.IgnoreButton = {
	'GameTimeFrame',
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
	'TukuiMinimapZone',
	'TukuiMinimapCoord',
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

SMB.PartialIgnore = { 'Node', 'Note', 'Pin', 'POI' }

SMB.OverrideTexture = {
	BagSync_MinimapButton = [[Interface\AddOns\BagSync\media\icon]],
	DBMMinimapButton = [[Interface\Icons\INV_Helmet_87]],
	SmartBuff_MiniMapButton = [[Interface\Icons\Spell_Nature_Purge]],
	VendomaticButtonFrame = [[Interface\Icons\INV_Misc_Rabbit_2]],
}

local ButtonFunctions = { 'SetParent', 'ClearAllPoints', 'SetPoint', 'SetSize', 'SetScale', 'SetFrameStrata', 'SetFrameLevel' }

local RemoveTextureID = {
	[136430] = true,
	[136467] = true,
	[130924] = true,
}

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

function SMB:SkinMinimapButton(Button)
	if (not Button) or Button.isSkinned then return end

	local Name = Button:GetName()
	if not Name then return end

	if tContains(SMB.IgnoreButton, Name) then return end

	for i = 1, #SMB.GenericIgnore do
		if strsub(Name, 1, strlen(SMB.GenericIgnore[i])) == SMB.GenericIgnore[i] then return end
	end

	for i = 1, #SMB.PartialIgnore do
		if strfind(Name, SMB.PartialIgnore[i]) ~= nil then return end
	end

	for i = 1, Button:GetNumRegions() do
		local Region = select(i, Button:GetRegions())
		if Region.IsObjectType and Region:IsObjectType('Texture') then
			local Texture = strlower(tostring(Region:GetTexture()))

			if RemoveTextureID[tonumber(Texture)] then
				Region:SetTexture()
			elseif (strfind(Texture, [[interface\characterframe]]) or (strfind(Texture, [[interface\minimap]]) and not strfind(Texture, [[interface\minimap\tracking\]])) or strfind(Texture, 'border') or strfind(Texture, 'background') or strfind(Texture, 'alphamask') or strfind(Texture, 'highlight')) then
				Region:SetTexture()
				Region:SetAlpha(0)
			else
				if SMB.OverrideTexture[Name] then
					Region:SetTexture(SMB.OverrideTexture[Name])
				elseif Name == 'OutfitterMinimapButton' and Texture == [[interface\addons\outfitter\textures\minimapbutton]] then
					Region:SetTexture()
				end

				Region:ClearAllPoints()
				Region:SetDrawLayer('ARTWORK')
				R:SetInside(Region)

				if not Button.ignoreCrop then
					Region:SetTexCoord(unpack(self.TexCoords))
					Button:HookScript('OnLeave', function() Region:SetTexCoord(unpack(self.TexCoords)) end)
				end

				Region.SetPoint = E.noop
			end
		end
	end

	Button:SetFrameLevel(_G.Minimap:GetFrameLevel() + 5)
	Button:SetSize(E.db.RhythmBox.MinimapButtons['IconSize'], E.db.RhythmBox.MinimapButtons['IconSize'])

	if not Button.ignoreTemplate then
		R:SetTemplate(Button)

		if E.db.RhythmBox.MinimapButtons.Shadows then
			R:CreateShadow(Button)
		end
	end

	Button:HookScript('OnEnter', function(self)
		if SMB.Bar:IsShown() then
			UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
		end
	end)
	Button:HookScript('OnLeave', function(self)
		R:SetTemplate(self)
		if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
			UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
		end
	end)

	Button.isSkinned = true
	tinsert(self.Buttons, Button)
end

function SMB:GrabMinimapButtons()
	if (InCombatLockdown() or C_PetBattles and C_PetBattles.IsInBattle()) then return end

	for _, Frame in pairs({ _G.Minimap, _G.MinimapBackdrop }) do
		local NumChildren = Frame:GetNumChildren()
		if NumChildren < (Frame.SMBNumChildren or 0) then return end
		for i = 1, NumChildren do
			local object = select(i, Frame:GetChildren())
			if object then
				local name = object:GetName()
				local width = object:GetWidth()
				if name and width > 15 and width < 40 and (object:IsObjectType('Button') or object:IsObjectType('Frame')) then
					self:SkinMinimapButton(object)
				end
			end
		end
		Frame.SMBNumChildren = NumChildren
	end

	self:Update()
end

function SMB:Update()
	if not E.db.RhythmBox.MinimapButtons['BarEnabled'] then return end

	local AnchorX, AnchorY = 0, 1
	local ButtonsPerRow = E.db.RhythmBox.MinimapButtons['ButtonsPerRow'] or 12
	local Spacing = E.db.RhythmBox.MinimapButtons['ButtonSpacing'] or 2
	local Size = E.db.RhythmBox.MinimapButtons['IconSize'] or 27
	local ActualButtons, Maxed = 0

	local Anchor, DirMult = 'TOPLEFT', 1

	if E.db.RhythmBox.MinimapButtons['ReverseDirection'] then
		Anchor, DirMult = 'TOPRIGHT', -1
	end

	for _, Button in pairs(SMB.Buttons) do
		if Button:IsVisible() then
			AnchorX, ActualButtons = AnchorX + 1, ActualButtons + 1

			if (AnchorX % (ButtonsPerRow + 1)) == 0 then
				AnchorY, AnchorX, Maxed = AnchorY + 1, 1, true
			end

			SMB:UnlockButton(Button)

			R:SetTemplate(Button)

			Button:SetParent(self.Bar)
			Button:ClearAllPoints()
			Button:SetPoint(Anchor, self.Bar, Anchor, DirMult * (Spacing + ((Size + Spacing) * (AnchorX - 1))), (- Spacing - ((Size + Spacing) * (AnchorY - 1))))
			Button:SetSize(E.db.RhythmBox.MinimapButtons['IconSize'], E.db.RhythmBox.MinimapButtons['IconSize'])
			Button:SetScale(1)
			Button:SetFrameStrata('LOW')
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
		R:SetTemplate(self.Bar)
	else
		self.Bar:SetBackdrop(nil)
	end

	if ActualButtons == 0 then
		self.Bar:Hide()
	else
		self.Bar:Show()
	end

	if E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
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
	['Shadows'] = false,
	['ReverseDirection'] = true,
}

local function MinimapOptions()
    E.Options.args.RhythmBox.args.MinimapButtons = {
        order = 5,
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
	SMB.Bar:SetFrameStrata('LOW')
	SMB.Bar:SetClampedToScreen(true)
	SMB.Bar:SetMovable(true)
	SMB.Bar:EnableMouse(true)
	SMB.Bar:SetSize(E.db.RhythmBox.MinimapButtons.IconSize, E.db.RhythmBox.MinimapButtons.IconSize)

	SMB.Bar:SetScript('OnEnter', function(self) UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1) end)
	SMB.Bar:SetScript('OnLeave', function(self)
		if E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
			UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
		end
	end)

	E:CreateMover(SMB.Bar, 'SquareMinimapButtonBarMover', 'SquareMinimapButtonBar Anchor', nil, nil, nil, 'ALL,GENERAL')

	SMB.TexCoords = R.TexCoords

	SMB:ScheduleRepeatingTimer('GrabMinimapButtons', 6)
end

R:RegisterModule(SMB:GetName())
