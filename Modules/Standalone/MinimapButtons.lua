-- From ProjectAzilroka
-- https://git.tukui.org/Azilroka/ProjectAzilroka/blob/master/Modules/SquareMinimapButtons.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local SMB = E:NewModule('RhythmBox_MinimapButtons', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

SMB.TexCoords = {.08, .92, .08, .92}
if _G.ElvUI then
	SMB.TexCoords = {0, 1, 0, 1}
	local modifier = 0.04 * _G.ElvUI[1].db.general.cropIcon
	for i, v in ipairs(SMB.TexCoords) do
		if i % 2 == 0 then
			SMB.TexCoords[i] = v - modifier
		else
			SMB.TexCoords[i] = v + modifier
		end
	end
end

local Color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass]
SMB.ClassColor = { Color.r, Color.g, Color.b }

SMB.Solid = E.Libs.LSM:Fetch('background', 'Solid')
function SMB:SetTemplate(frame)
	if _G.AddOnSkins then
		AddOnSkins[1]:SetTemplate(frame)
	elseif frame.SetTemplate then
		frame:SetTemplate('Transparent', true)
	else
		frame:SetBackdrop({ bgFile = self.Solid, edgeFile = self.Solid, tile = false, tileSize = 0, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
		frame:SetBackdropColor(.08, .08, .08, .8)
		frame:SetBackdropBorderColor(0, 0, 0)
	end
end

function SMB:CreateShadow(frame)
	if _G.AddOnSkins then
		AddOnSkins[1]:CreateShadow(frame)
	elseif frame.CreateShadow then
		frame:CreateShadow()
	end
end

function SMB:SetInside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or 1
	yOffset = yOffset or 1
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', xOffset, -yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', -xOffset, yOffset)
end

function SMB:SetOutside(obj, anchor, xOffset, yOffset, anchor2)
	xOffset = xOffset or 1
	yOffset = yOffset or 1
	anchor = anchor or obj:GetParent()

	assert(anchor)
	if obj:GetPoint() then
		obj:ClearAllPoints()
	end

	obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -xOffset, yOffset)
	obj:SetPoint('BOTTOMRIGHT', anchor2 or anchor, 'BOTTOMRIGHT', xOffset, -yOffset)
end

SMB.Buttons = {}

local ignoreButtons = {
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

local GenericIgnores = {
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
}

local PartialIgnores = { 'Node', 'Note', 'Pin', 'POI' }

local ButtonFunctions = { 'SetParent', 'ClearAllPoints', 'SetPoint', 'SetSize', 'SetScale', 'SetFrameStrata', 'SetFrameLevel' }

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

function SMB:HandleBlizzardButtons()
	if not E.db.RhythmBox.MinimapButtons['BarEnabled'] then return end

	if E.db.RhythmBox.MinimapButtons['HideGarrison'] then
		GarrisonLandingPageMinimapButton:UnregisterAllEvents()
		GarrisonLandingPageMinimapButton:SetParent(self.Hider)
		GarrisonLandingPageMinimapButton:Hide()
	elseif E.db.RhythmBox.MinimapButtons["MoveGarrison"] and not GarrisonLandingPageMinimapButton.SMB then
		GarrisonLandingPageMinimapButton:SetParent(Minimap)
		GarrisonLandingPageMinimapButton_OnLoad(GarrisonLandingPageMinimapButton)
		GarrisonLandingPageMinimapButton_UpdateIcon(GarrisonLandingPageMinimapButton)
		GarrisonLandingPageMinimapButton:Show()
		GarrisonLandingPageMinimapButton:SetScale(1)
		GarrisonLandingPageMinimapButton:SetHitRectInsets(0, 0, 0, 0)
		GarrisonLandingPageMinimapButton:SetScript('OnEnter', function(self)
			self:SetBackdropBorderColor(unpack(SMB.ClassColor))
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		GarrisonLandingPageMinimapButton:SetScript('OnLeave', function(self)
			SMB:SetTemplate(self)
			if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		GarrisonLandingPageMinimapButton.SMB = true

		if E.db.RhythmBox.MinimapButtons.Shadows then
			SMB:CreateShadow(GarrisonLandingPageMinimapButton)
		end

		tinsert(self.Buttons, GarrisonLandingPageMinimapButton)
	end

	if E.db.RhythmBox.MinimapButtons["MoveMail"] and not MiniMapMailFrame.SMB then
		local Frame = CreateFrame('Frame', 'SMB_MailFrame', self.Bar)
		Frame:SetSize(E.db.RhythmBox.MinimapButtons['IconSize'], E.db.RhythmBox.MinimapButtons['IconSize'])
		SMB:SetTemplate(Frame)
		Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
		Frame.Icon:SetPoint('CENTER')
		Frame.Icon:SetSize(18, 18)
		Frame.Icon:SetTexture(MiniMapMailIcon:GetTexture())
		Frame:EnableMouse(true)
		Frame:HookScript('OnEnter', function(self)
			if HasNewMail() then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
				if GameTooltip:IsOwned(self) then
					MinimapMailFrameUpdate()
				end
			end
			self:SetBackdropBorderColor(unpack(SMB.ClassColor))
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		Frame:HookScript('OnLeave', function(self)
			GameTooltip:Hide()
			SMB:SetTemplate(self)
			if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		MiniMapMailFrame:HookScript('OnShow', function() Frame.Icon:SetVertexColor(0, 1, 0)	end)
		MiniMapMailFrame:HookScript('OnHide', function() Frame.Icon:SetVertexColor(1, 1, 1) end)

		if MiniMapMailFrame:IsShown() then
			Frame.Icon:SetVertexColor(0, 1, 0)
		end

		-- Hide Icon & Border
		MiniMapMailIcon:Hide()
		MiniMapMailBorder:Hide()

		if E.db.RhythmBox.MinimapButtons.Shadows then
			SMB:CreateShadow(Frame)
		end

		MiniMapMailFrame.SMB = true
		tinsert(self.Buttons, Frame)
	end

	if E.db.RhythmBox.MinimapButtons["MoveTracker"] and not MiniMapTrackingButton.SMB then
		MiniMapTracking.Show = nil

		MiniMapTracking:Show()

		MiniMapTracking:SetParent(self.Bar)
		MiniMapTracking:SetSize(E.db.RhythmBox.MinimapButtons['IconSize'], E.db.RhythmBox.MinimapButtons['IconSize'])

		MiniMapTrackingIcon:ClearAllPoints()
		MiniMapTrackingIcon:SetPoint('CENTER')

		MiniMapTrackingBackground:SetAlpha(0)
		MiniMapTrackingIconOverlay:SetAlpha(0)
		MiniMapTrackingButton:SetAlpha(0)

		MiniMapTrackingButton:SetParent(MinimapTracking)
		MiniMapTrackingButton:ClearAllPoints()
		MiniMapTrackingButton:SetAllPoints(MiniMapTracking)

		MiniMapTrackingButton:SetScript('OnMouseDown', nil)
		MiniMapTrackingButton:SetScript('OnMouseUp', nil)

		MiniMapTrackingButton:HookScript('OnEnter', function(self)
			MiniMapTracking:SetBackdropBorderColor(unpack(SMB.ClassColor))
			if SMB.Bar:IsShown() then
				UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
			end
		end)
		MiniMapTrackingButton:HookScript('OnLeave', function(self)
			SMB:SetTemplate(MiniMapTracking)
			if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		MiniMapTrackingButton.SMB = true

		if E.db.RhythmBox.MinimapButtons.Shadows then
			SMB:CreateShadow(MiniMapTracking)
		end

		tinsert(self.Buttons, MiniMapTracking)
	end

	if E.db.RhythmBox.MinimapButtons["MoveQueue"] and not QueueStatusMinimapButton.SMB then
		local Frame = CreateFrame('Frame', 'SMB_QueueFrame', self.Bar)
		SMB:SetTemplate(Frame)
		Frame:SetSize(E.db.RhythmBox.MinimapButtons['IconSize'], E.db.RhythmBox.MinimapButtons['IconSize'])
		Frame.Icon = Frame:CreateTexture(nil, 'ARTWORK')
		Frame.Icon:SetSize(E.db.RhythmBox.MinimapButtons['IconSize'], E.db.RhythmBox.MinimapButtons['IconSize'])
		Frame.Icon:SetPoint('CENTER')
		Frame.Icon:SetTexture([[Interface\LFGFrame\LFG-Eye]])
		Frame.Icon:SetTexCoord(0, 64 / 512, 0, 64 / 256)
		Frame:SetScript('OnMouseDown', function()
			if PVEFrame:IsShown() then
				HideUIPanel(PVEFrame)
			else
				ShowUIPanel(PVEFrame)
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
			if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
				UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
			end
		end)

		QueueStatusMinimapButton:SetParent(self.Bar)
		QueueStatusMinimapButton:SetFrameLevel(Frame:GetFrameLevel() + 2)
		QueueStatusMinimapButton:ClearAllPoints()
		QueueStatusMinimapButton:SetPoint("CENTER", Frame, "CENTER", 0, 0)

		QueueStatusMinimapButton:SetHighlightTexture(nil)

		QueueStatusMinimapButton:HookScript('OnShow', function(self)
			Frame:EnableMouse(false)
		end)
		QueueStatusMinimapButton:HookScript('PostClick', QueueStatusMinimapButton_OnLeave)
		QueueStatusMinimapButton:HookScript('OnHide', function(self)
			Frame:EnableMouse(true)
		end)

		QueueStatusMinimapButton.SMB = true

		if E.db.RhythmBox.MinimapButtons.Shadows then
			SMB:CreateShadow(Frame)
		end

		tinsert(self.Buttons, Frame)
	end

	self:Update()
end

function SMB:SkinMinimapButton(Button)
	if (not Button) or Button.isSkinned then return end

	local Name = Button:GetName()
	if not Name then return end

	if tContains(ignoreButtons, Name) then return end

	for i = 1, #GenericIgnores do
		if strsub(Name, 1, strlen(GenericIgnores[i])) == GenericIgnores[i] then return end
	end

	for i = 1, #PartialIgnores do
		if strfind(Name, PartialIgnores[i]) ~= nil then return end
	end

	for i = 1, Button:GetNumRegions() do
		local Region = select(i, Button:GetRegions())
		if Region.IsObjectType and Region:IsObjectType('Texture') then
			local Texture = strlower(tostring(Region:GetTexture()))

			if (strfind(Texture, [[interface\characterframe]]) or (strfind(Texture, [[interface\minimap]]) and not strfind(Texture, [[interface\minimap\tracking\]])) or strfind(Texture, 'border') or strfind(Texture, 'background') or strfind(Texture, 'alphamask') or strfind(Texture, 'highlight')) then
				Region:SetTexture()
				Region:SetAlpha(0)
			else
				if Name == 'BagSync_MinimapButton' then
					Region:SetTexture([[Interface\AddOns\BagSync\media\icon]])
				elseif Name == 'DBMMinimapButton' then
					Region:SetTexture([[Interface\Icons\INV_Helmet_87]])
				elseif Name == 'OutfitterMinimapButton' then
					if Texture == [[interface\addons\outfitter\textures\minimapbutton]] then
						Region:SetTexture()
					end
				elseif Name == 'SmartBuff_MiniMapButton' then
					Region:SetTexture([[Interface\Icons\Spell_Nature_Purge]])
				elseif Name == 'VendomaticButtonFrame' then
					Region:SetTexture([[Interface\Icons\INV_Misc_Rabbit_2]])
				end
				Region:ClearAllPoints()
				SMB:SetInside(Region)
				Region:SetTexCoord(unpack(self.TexCoords))
				Button:HookScript('OnLeave', function() Region:SetTexCoord(unpack(self.TexCoords)) end)
				Region:SetDrawLayer('ARTWORK')
				Region.SetPoint = function() return end
			end
		end
	end

	Button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	Button:SetSize(E.db.RhythmBox.MinimapButtons['IconSize'], E.db.RhythmBox.MinimapButtons['IconSize'])
	SMB:SetTemplate(Button)

	if E.db.RhythmBox.MinimapButtons.Shadows then
		SMB:CreateShadow(Button)
	end

	Button:HookScript('OnEnter', function(self)
		self:SetBackdropBorderColor(unpack(SMB.ClassColor))
		if SMB.Bar:IsShown() then
			UIFrameFadeIn(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 1)
		end
	end)
	Button:HookScript('OnLeave', function(self)
		SMB:SetTemplate(self)
		if SMB.Bar:IsShown() and E.db.RhythmBox.MinimapButtons['BarMouseOver'] then
			UIFrameFadeOut(SMB.Bar, 0.2, SMB.Bar:GetAlpha(), 0)
		end
	end)

	Button.isSkinned = true
	tinsert(self.Buttons, Button)
end

function SMB:GrabMinimapButtons()
	if (InCombatLockdown() or (not R.IsClassic() and C_PetBattles.IsInBattle())) then return end

	for _, Frame in pairs({ Minimap, MinimapBackdrop }) do
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

			SMB:SetTemplate(Button)

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
		SMB:SetTemplate(self.Bar)
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
	['HideGarrison'] = false,
	['MoveGarrison'] = false,
	['MoveMail'] = false,
	['MoveTracker'] = false,
	['MoveQueue'] = false,
	['Shadows'] = false,
	['ReverseDirection'] = true,
}

local function MinimapOptions()
    E.Options.args.RhythmBox.args.MinimapButtons = {
        order = 5,
        type = 'group',
		name = "小地图按钮",
		get = function(info) return E.db.RhythmBox.MinimapButtons[info[#info]] end,
		set = function(info, value) E.db.RhythmBox.MinimapButtons[info[#info]] = value SMB:Update() end,
        args = {
			Enable = {
				order = 1,
				type = 'toggle',
				name = "启用"
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
				name = "Blizzard",
				guiInline = true,
				set = function(info, value) E.db.RhythmBox.MinimapButtons[info[#info]] = value SMB:Update() SMB:HandleBlizzardButtons() end,
				order = 2,
				args = {
					HideGarrison = {
						type = 'toggle',
						name = "隐藏要塞图标",
						order = 1,
						disabled = function() return E.db.RhythmBox.MinimapButtons.MoveGarrison end,
					},
					MoveGarrison = {
						type = 'toggle',
						name = "移动要塞图标",
						order = 2,
						disabled = function() return E.db.RhythmBox.MinimapButtons.HideGarrison end,
					},
					MoveMail = {
						type = 'toggle',
						name = "移动邮件图标",
						order = 3,
					},
					MoveTracker = {
						type = 'toggle',
						name = "移动跟踪图标",
						order = 3,
					},
					MoveQueue = {
						type = 'toggle',
						name = "移动队列图标",
						order = 3,
					},
				},
			},
        },
    }
end
tinsert(R.Config, MinimapOptions)

function SMB:Initialize()
	if E.db.RhythmBox.MinimapButtons.Enable ~= true then
		return
	end

	SMB.Hider = CreateFrame("Frame", nil, UIParent)

	SMB.Bar = CreateFrame('Frame', 'SquareMinimapButtonBar', UIParent)
	SMB.Bar:Hide()
	SMB.Bar:SetPoint('RIGHT', UIParent, 'RIGHT', -45, 0)
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

	ElvUI[1]:CreateMover(SMB.Bar, 'SquareMinimapButtonBarMover', 'SquareMinimapButtonBar Anchor', nil, nil, nil, 'ALL,GENERAL')

	SMB:ScheduleRepeatingTimer('GrabMinimapButtons', 6)
	SMB:ScheduleTimer('HandleBlizzardButtons', 7)
end

local function InitializeCallback()
    SMB:Initialize()
end

E:RegisterModule(SMB:GetName(), InitializeCallback)