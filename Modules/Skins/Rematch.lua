local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local S = E:GetModule('Skins')
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G
local ipairs, next, pairs, select, unpack = ipairs, next, pairs, select, unpack

-- WoW API / Variables
local hooksecurefunc = hooksecurefunc

-- luacheck: ignore 113
-- GLOBALS: CollectionsJournal, RematchJournal, RematchLoreFont, RematchTooltip
-- GLOBALS: RematchTableTooltip, RematchHealButton, RematchBandageButton, RematchLesserPetTreatButton
-- GLOBALS: RematchPetTreatButton, RematchToolbar, RematchBottomPanel, RematchMiniPanel
-- GLOBALS: RematchPetPanel, RematchLoadedTeamPanel, RematchLoadoutPanel, RematchTeamPanel
-- GLOBALS: RematchQueuePanel, RematchOptionPanel, RematchPetCard, RematchAbilityCard
-- GLOBALS: RematchWinRecordCard, RematchDialog, UseRematchButton, ALPTRematchOptionButton
-- GLOBALS: RematchFrame, Rematch, RematchNotes, RematchTeamTabs, RematchSettings

local classColor = E:ClassColor(E.myclass, true)
local cr, cg, cb = classColor.r, classColor.g, classColor.b

function RS:RematchFilter(frame)
    S:HandleButton(frame, true)
    frame.Arrow:SetTexture(self.NDuiTexture.arrowRight)
    frame.Arrow:SetPoint('RIGHT', frame, 'RIGHT', -5, 0)
    frame.Arrow:SetSize(8, 8)
end

function RS:RematchIcon(frame)
    if frame.styled then return end

    if frame.IconBorder then frame.IconBorder:Hide() end
    if frame.Background then frame.Background:Hide() end
    if frame.Icon then
        frame.Icon:SetTexCoord(unpack(E.TexCoords))
        frame.Icon:CreateBackdrop()
        local hl = frame.GetHighlightTexture and frame:GetHighlightTexture() or select(3, frame:GetRegions())
        if hl then
            hl:SetColorTexture(1, 1, 1, .25)
            hl:SetAllPoints(frame.Icon)
        end
    end
    if frame.Level then
        if frame.Level.BG then frame.Level.BG:Hide() end
        if frame.Level.Text then frame.Level.Text:SetTextColor(1, 1, 1) end
    end
    if frame.GetCheckedTexture then
        frame:SetCheckedTexture(self.NDuiTexture.pushed)
    end

    frame.styled = true
end

function RS:RematchInput(frame)
    frame:DisableDrawLayer("BACKGROUND")
    frame:SetBackdrop(nil)
    S:HandleEditBox(frame)
    frame.backdrop:SetPoint("TOPLEFT", 2, 0)
    frame.backdrop:SetPoint("BOTTOMRIGHT", -2, 0)
end

function RS:RematchScroll(frame)
    frame.Background:Hide()
    S:HandleScrollBar(frame.ScrollFrame.ScrollBar)
end

function RS:RematchDropdown(frame)
    frame:SetBackdrop(nil)
    frame:StripTextures(nil, true)
    frame:CreateBackdrop()
    frame.backdrop:SetBackdropColor(0, 0, 0, 0)
    RS:CreateGradient(frame.backdrop)
    if frame.Icon then
        frame.Icon:SetAlpha(1)
        frame.Icon:CreateBackdrop()
    end
    local arrow = frame:GetChildren()
    S:HandleNextPrevButton(arrow, 'down', nil, true)
end

function RS:RematchXP(frame)
    frame:StripTextures()
    frame:SetStatusBarTexture(self.NDuiTexture.bdTex)
    frame:CreateBackdrop()
    frame.backdrop:SetBackdropColor(0, 0, 0, .25)
end

function RS:RematchCard(frame)
    frame:SetBackdrop(nil)
    if frame.Source then
        frame.Source:StripTextures()
    end
    frame.Middle:StripTextures()
    frame.Middle:CreateBackdrop()
    frame.Middle.backdrop:SetBackdropColor(0, 0, 0, .25)
    if frame.Middle.XP then
        RS:RematchXP(frame.Middle.XP)
    end
    frame.Bottom:StripTextures()
    frame.Bottom:CreateBackdrop()
    frame.Bottom.backdrop:SetBackdropColor(0, 0, 0, .25)
    frame.Bottom.backdrop:SetPoint("TOPLEFT", -E.mult, -3)
end

function RS:RematchInset(frame)
    frame:StripTextures()
    frame:CreateBackdrop()
    frame.backdrop:SetBackdropColor(0, 0, 0, .25)
    frame.backdrop:SetPoint("TOPLEFT", 3, 0)
    frame.backdrop:SetPoint("BOTTOMRIGHT", -3, 0)
end

local function buttonOnEnter(self)
    self.backdrop:SetBackdropColor(cr, cg, cb, .25)
end

local function buttonOnLeave(self)
    self.backdrop:SetBackdropColor(0, 0, 0, .25)
end

function RS:RematchPetList(frame)
    local buttons = frame.ScrollFrame.Buttons
    if not buttons then return end

    for i = 1, #buttons do
        local button = buttons[i]
        if not button.styled then
            local parent
            if button.Pet then
                button.Pet:CreateBackdrop()
                if button.Rarity then
                    button.Rarity:SetTexture(nil)
                end
                if button.LevelBack then
                    button.LevelBack:SetTexture(nil)
                end
                button.LevelText:SetTextColor(1, 1, 1)
                parent = button.Pet
            end

            if button.Pets then
                for j = 1, 3 do
                    local bu = button.Pets[j]
                    bu:SetWidth(25)
                    bu:CreateBackdrop()
                end
                if button.Border then button.Border:SetTexture(nil) end
                parent = button.Pets[3]
            end

            if button.Back then
                button.Back:SetTexture(nil)
                button.Back:CreateBackdrop()
                button.Back.backdrop:SetBackdropColor(0, 0, 0, .25)
                button.Back.backdrop:SetPoint("TOPLEFT", parent, "TOPRIGHT", 3, E.mult)
                button.Back.backdrop:SetPoint("BOTTOMRIGHT", 0, E.mult)
                button.backdrop = button.Back.backdrop
                button:HookScript("OnEnter", buttonOnEnter)
                button:HookScript("OnLeave", buttonOnLeave)
            end

            button.styled = true
        end
    end
end

function RS:RematchSelectedOverlay(frame)
    frame.SelectedOverlay:StripTextures()
    frame.SelectedOverlay:CreateBackdrop()
    frame.SelectedOverlay.backdrop:SetBackdropColor(1, .8, 0, .5)
end

function RS:ResizeJournal()
    local parent = RematchJournal:IsShown() and RematchJournal or CollectionsJournal
    CollectionsJournal.backdrop:SetPoint("BOTTOMRIGHT", parent, E.mult, -E.mult)
end

-- Fix: Rematch Tab cannot be handle by ElvUI functions,
-- get this from NDui
function RS:RematchTab(frame)
    frame:DisableDrawLayer("BACKGROUND")
    frame:CreateBackdrop()
    frame.backdrop:SetPoint("TOPLEFT", 8, -3)
    frame.backdrop:SetPoint("BOTTOMRIGHT", -8, 0)

    frame:SetHighlightTexture(self.NDuiTexture.bdTex)
    local hl = frame:GetHighlightTexture()
    hl:ClearAllPoints()
    hl:SetInside(frame.backdrop)
    hl:SetVertexColor(cr, cg, cb, .25)
end

function RS:Rematch()
    local RematchJournal = RematchJournal
    if not RematchJournal then return end

    if _G.RematchSettings then
        _G.RematchSettings.ColorPetNames = true
        _G.RematchSettings.FixedPetCard = true
    end
    RematchLoreFont:SetTextColor(1, 1, 1)

    local mainStyled
    local function RematchMainSkin()
        if mainStyled then return end

        RS:ReskinTooltip(RematchTooltip)
        RS:ReskinTooltip(RematchTableTooltip)

        -- RematchToolbar
        local buttons = {
            RematchHealButton,
            RematchBandageButton,
            RematchToolbar.SafariHat,
            RematchLesserPetTreatButton,
            RematchPetTreatButton,
            RematchToolbar.SummonRandom,
            RematchToolbar.FindBattle,
        }
        for _, button in pairs(buttons) do
            RS:RematchIcon(button)
        end

        local petCount = RematchToolbar.PetCount
        petCount:SetWidth(130)
        petCount:StripTextures()
        petCount:CreateBackdrop()
        petCount.backdrop:SetBackdropColor(0, 0, 0, .25)
        petCount.backdrop:SetPoint("TOPLEFT", -6, -8)
        petCount.backdrop:SetPoint("BOTTOMRIGHT", -4, 3)

        -- RematchBottomPanel
        S:HandleButton(RematchBottomPanel.SummonButton)
        S:HandleCheckBox(RematchBottomPanel.UseDefault)
        S:HandleButton(RematchBottomPanel.SaveButton)
        S:HandleButton(RematchBottomPanel.SaveAsButton)
        S:HandleButton(RematchBottomPanel.FindBattleButton)

        -- RematchMiniPanel
        RematchMiniPanel.Background:Hide()
        for i = 1, 3 do
            local button = RematchMiniPanel.Pets[i]
            RS:RematchIcon(button)
            button.Icon.backdrop:SetBackdropBorderColor(button.IconBorder:GetVertexColor())

            RS:RematchXP(button.HP)
            RS:RematchXP(button.XP)

            for j = 1, 3 do
                RS:RematchIcon(button.Abilities[j])
            end
        end

        local miniTarget = RematchMiniPanel.Target
        miniTarget:StripTextures()
        miniTarget:CreateBackdrop()
        miniTarget.backdrop:SetBackdropColor(0, 0, 0, .25)
        S:HandleButton(miniTarget.LoadButton)
        miniTarget.ModelBorder:SetBackdrop(nil)
        miniTarget.ModelBorder:DisableDrawLayer("BACKGROUND")
        miniTarget.ModelBorder:CreateBackdrop()
        miniTarget.ModelBorder.backdrop:SetBackdropColor(0, 0, 0, .25)
        for i = 1, 3 do
            local button = miniTarget.Pets[i]
            RS:RematchIcon(button)
            button.Icon.backdrop:SetBackdropBorderColor(button.IconBorder:GetVertexColor())
        end

        -- RematchPetPanel
        RematchPetPanel.Top:StripTextures()
        S:HandleButton(RematchPetPanel.Top.Toggle)
        RematchPetPanel.Top.TypeBar:SetBackdrop(nil)
        for i = 1, 10 do
            RS:RematchIcon(RematchPetPanel.Top.TypeBar.Buttons[i])
        end

        RS:RematchSelectedOverlay(RematchPetPanel)
        RS:RematchInset(RematchPetPanel.Results)
        RS:RematchInput(RematchPetPanel.Top.SearchBox)
        RS:RematchFilter(RematchPetPanel.Top.Filter)
        RS:RematchScroll(RematchPetPanel.List)

        local qualityBar = RematchPetPanel.Top.TypeBar.QualityBar
        local qualityBarButtons = {
            qualityBar.HealthButton,
            qualityBar.PowerButton,
            qualityBar.SpeedButton,
            qualityBar.Level25Button,
            qualityBar.RareButton,
        }
        for _, button in ipairs(qualityBarButtons) do
            RS:RematchIcon(button)
        end
        -- Fix: Level25Button's Icon
        RematchPetPanel.Top.TypeBar.QualityBar.Level25Button.Icon:SetTexCoord(0.09375, 0.7265625, 0.09375, 0.7265625)

        -- RematchLoadedTeamPanel
        RematchLoadedTeamPanel:StripTextures()
        RematchLoadedTeamPanel:CreateBackdrop()
        RematchLoadedTeamPanel.backdrop:SetBackdropColor(1, .8, 0, .1)
        RematchLoadedTeamPanel.backdrop:SetPoint("TOPLEFT", -E.mult, -E.mult)
        RematchLoadedTeamPanel.backdrop:SetPoint("BOTTOMRIGHT", E.mult, E.mult)
        RematchLoadedTeamPanel.Footnotes:StripTextures()

        -- RematchLoadoutPanel
        local target = RematchLoadoutPanel.Target
        target:StripTextures()
        target:CreateBackdrop()
        target.backdrop:SetBackdropColor(0, 0, 0, .25)
        RS:RematchFilter(target.TargetButton)
        target.ModelBorder:SetBackdrop(nil)
        target.ModelBorder:DisableDrawLayer("BACKGROUND")
        target.ModelBorder:CreateBackdrop()
        target.ModelBorder.backdrop:SetBackdropColor(0, 0, 0, .25)
        S:HandleButton(target.LoadSaveButton)
        for i = 1, 3 do
            RS:RematchIcon(target["Pet"..i])
        end

        local flyout = RematchLoadoutPanel.Flyout
        flyout:SetBackdrop(nil)
        for i = 1, 2 do
            RS:RematchIcon(flyout.Abilities[i])
        end

        -- RematchTeamPanel
        RematchTeamPanel.Top:StripTextures()
        RS:RematchInput(RematchTeamPanel.Top.SearchBox)
        RS:RematchFilter(RematchTeamPanel.Top.Teams)
        RS:RematchScroll(RematchTeamPanel.List)
        RS:RematchSelectedOverlay(RematchTeamPanel)

        RematchQueuePanel.Top:StripTextures()
        RS:RematchFilter(RematchQueuePanel.Top.QueueButton)
        RS:RematchScroll(RematchQueuePanel.List)
        RS:RematchInset(RematchQueuePanel.Status)

        -- RematchOptionPanel
        RS:RematchScroll(RematchOptionPanel.List)
        for i = 1, 4 do
            RS:RematchIcon(RematchOptionPanel.Growth.Corners[i])
        end

        -- RematchPetCard
        local petCard = RematchPetCard
        petCard:StripTextures()
        S:HandleCloseButton(petCard.CloseButton)
        petCard.Title:StripTextures()
        petCard.PinButton:StripTextures()
        S:HandleNextPrevButton(petCard.PinButton, 'up', nil, true)
        petCard.PinButton:SetPoint("TOPLEFT", 5, -5)
        petCard.Title:CreateBackdrop()
        petCard.Title:CreateShadow()
        petCard.Title.backdrop:SetBackdropColor(0, 0, 0, .7)
        petCard.Title.backdrop:SetAllPoints(petCard)
        RS:RematchCard(petCard.Front)
        RS:RematchCard(petCard.Back)
        for i = 1, 6 do
            local button = RematchPetCard.Front.Bottom.Abilities[i]
            button.IconBorder:Hide()
            select(8, button:GetRegions()):SetTexture(nil)
            S:HandleIcon(button.Icon, true)
        end

        -- RematchAbilityCard
        local abilityCard = RematchAbilityCard
        abilityCard:StripTextures(nil, true)
        select(15, abilityCard:GetRegions()):SetAlpha(1)
        abilityCard:CreateBackdrop()
        abilityCard.backdrop:SetBackdropColor(0, 0, 0, .7)
        abilityCard.Hints.HintsBG:Hide()

        -- RematchWinRecordCard
        local card = RematchWinRecordCard
        card:StripTextures()
        card:CreateBackdrop('Transparent')
        S:HandleCloseButton(card.CloseButton)
        card.Content:StripTextures()
        card.Content:CreateBackdrop()
        card.Content.backdrop:SetBackdropColor(0, 0, 0, .25)
        card.Content.backdrop:SetPoint("TOPLEFT", 2, -2)
        card.Content.backdrop:SetPoint("BOTTOMRIGHT", -2, 2)
        for _, result in pairs({"Wins", "Losses", "Draws"}) do
            RS:RematchInput(card.Content[result].EditBox)
            card.Content[result].Add.IconBorder:Hide()
        end
        S:HandleButton(card.Controls.ResetButton)
        S:HandleButton(card.Controls.SaveButton)
        S:HandleButton(card.Controls.CancelButton)

        -- RematchDialog
        local dialog = RematchDialog
        dialog:StripTextures()
        dialog:CreateBackdrop('Transparent')
        S:HandleCloseButton(dialog.CloseButton)

        RS:RematchIcon(dialog.Slot)
        RS:RematchInput(dialog.EditBox)
        dialog.Prompt:StripTextures()
        S:HandleButton(dialog.Accept)
        S:HandleButton(dialog.Cancel)
        S:HandleButton(dialog.Other)
        S:HandleCheckBox(dialog.CheckButton)
        RS:RematchInput(dialog.SaveAs.Name)
        RS:RematchInput(dialog.Send.EditBox)
        RS:RematchDropdown(dialog.SaveAs.Target)
        RS:RematchDropdown(dialog.TabPicker)
        RS:RematchIcon(dialog.Pet.Pet)

        local preferences = dialog.Preferences
        RS:RematchInput(preferences.MinHP)
        S:HandleCheckBox(preferences.AllowMM)
        RS:RematchInput(preferences.MaxHP)
        RS:RematchInput(preferences.MinXP)
        RS:RematchInput(preferences.MaxXP)

        local iconPicker = dialog.TeamTabIconPicker
        S:HandleScrollBar(iconPicker.ScrollFrame.ScrollBar)
        iconPicker:StripTextures()
        iconPicker:CreateBackdrop()
        iconPicker.backdrop:SetBackdropColor(0, 0, 0, .25)

        S:HandleScrollBar(dialog.MultiLine.ScrollBar)
        select(2, dialog.MultiLine:GetChildren()):SetBackdrop(nil)
        dialog.MultiLine:CreateBackdrop()
        dialog.MultiLine.backdrop:SetBackdropColor(0, 0, 0, .25)
        dialog.MultiLine.backdrop:SetPoint("TOPLEFT", -5, 5)
        dialog.MultiLine.backdrop:SetPoint("BOTTOMRIGHT", 5, -5)
        S:HandleCheckBox(dialog.ShareIncludes.IncludePreferences)
        S:HandleCheckBox(dialog.ShareIncludes.IncludeNotes)

        local report = dialog.CollectionReport
        RS:RematchDropdown(report.ChartTypeComboBox)
        report.Chart:StripTextures()
        report.Chart:CreateBackdrop()
        report.Chart.backdrop:SetBackdropColor(0, 0, 0, .25)
        report.Chart.backdrop:SetPoint("TOPLEFT", -E.mult, -3)
        report.Chart.backdrop:SetPoint("BOTTOMRIGHT", E.mult, 2)
        S:HandleRadioButton(report.ChartTypesRadioButton)
        S:HandleRadioButton(report.ChartSourcesRadioButton)

        local border = report.RarityBarBorder
        border:Hide()
        border:CreateBackdrop()
        border.backdrop:SetBackdropColor(0, 0, 0, .25)
        border.backdrop:SetPoint("TOPLEFT", border, 6, -5)
        border.backdrop:SetPoint("BOTTOMRIGHT", border, -6, 5)

        mainStyled = true
    end

    local journalStyled
    hooksecurefunc(RematchJournal, "ConfigureJournal", function()
        RS:ResizeJournal()

        if journalStyled then return end

        -- Main Elements
        hooksecurefunc("CollectionsJournal_UpdateSelectedTab", function(frame)
            RS:ResizeJournal(frame)
        end)
        for i = 1, 3 do
            local menu = Rematch:GetMenuFrame(i, _G.UIParent)
            menu.Title:StripTextures()
            menu.Title:CreateBackdrop()
            menu.Title.backdrop:SetBackdropColor(1, .8, .0, .25)
            menu:StripTextures()
            menu:CreateBackdrop()
            menu:CreateShadow()
            menu.backdrop:SetBackdropColor(0, 0, 0, .7)
        end

        RematchJournal:StripTextures()
        S:HandleCloseButton(RematchJournal.CloseButton)
        for _, tab in ipairs(RematchJournal.PanelTabs.Tabs) do
            RS:RematchTab(tab)
        end

        S:HandleCheckBox(UseRematchButton)

        if ALPTRematchOptionButton then
            ALPTRematchOptionButton:SetPushedTexture(nil)
            ALPTRematchOptionButton:SetHighlightTexture(self.NDuiTexture.bdTex)
            ALPTRematchOptionButton:GetHighlightTexture():SetVertexColor(1, 1, 1, .25)
            local tex = ALPTRematchOptionButton:GetNormalTexture()
            tex:SetTexCoord(unpack(E.TexCoords))
            tex:CreateBackdrop()
        end

        RematchMainSkin()

        journalStyled = true
    end)

    -- Fix: Missing RematchFrame skin
    local frameStyled
    hooksecurefunc(RematchFrame, 'ConfigureFrame', function()
        if frameStyled then return end

        RematchFrame:StripTextures()
        RematchFrame:CreateBackdrop('Transparent')

        for _, tab in ipairs(RematchFrame.PanelTabs.Tabs) do
            RS:RematchTab(tab)
        end

        local titleBar = RematchFrame.TitleBar
        titleBar:StripTextures()
        S:HandleCloseButton(titleBar.CloseButton)

        local buttons = {
            titleBar.LockButton,
            titleBar.MinimizeButton,
            titleBar.SinglePanelButton,
        }
        for _, button in ipairs(buttons) do
            button:StripTextures(nil, true)
            button.Icon:SetAlpha(1)
            button:CreateBackdrop()
            button.backdrop:SetBackdropColor(0, 0, 0, .25)
            button.backdrop:SetPoint("TOPLEFT", 7, -7)
            button.backdrop:SetPoint("BOTTOMRIGHT", -7, 7)
        end

        RematchMainSkin()

        frameStyled = true
    end)

    -- RematchNotes
    do
        local note = RematchNotes
        note:StripTextures()
        -- Fix: no idea why RematchNotes.CloseButton is so special,
        -- and simply :HandleCloseButton would not handle,
        -- so set .Icon true to avoid Rematch:ConvertTitlebarCloseButton
        note.CloseButton.Icon = true
        S:HandleCloseButton(note.CloseButton)
        note.LockButton:StripTextures(nil, true)
        select(2, note.LockButton:GetRegions()):SetAlpha(1)
        note.LockButton:SetBackdrop(nil)
        note.LockButton:SetPoint("TOPLEFT")
        note.LockButton:CreateBackdrop()
        note.LockButton.backdrop:SetBackdropColor(0, 0, 0, .25)
        note.LockButton.backdrop:SetPoint("TOPLEFT", 7, -7)
        note.LockButton.backdrop:SetPoint("BOTTOMRIGHT", -7, 7)

        local content = note.Content
        content:StripTextures()
        content:CreateBackdrop('Transparent')
        content.backdrop:SetAllPoints(note)
        S:HandleScrollBar(content.ScrollFrame.ScrollBar)
        content.ScrollFrame:CreateBackdrop()
        content.ScrollFrame.backdrop:SetBackdropColor(0, 0, 0, .25)
        content.ScrollFrame.backdrop:SetPoint("TOPLEFT", 0, 5)
        content.ScrollFrame.backdrop:SetPoint("BOTTOMRIGHT", 0, -2)
        for _, icon in pairs({"Left", "Right"}) do
            local bu = content[icon.."Icon"]
            local mask = content[icon.."CircleMask"]
            if mask then
                mask:Hide()
            else
                bu:SetMask(nil)
            end
            S:HandleIcon(bu, true)
        end

        S:HandleButton(note.Controls.DeleteButton)
        S:HandleButton(note.Controls.UndoButton)
        S:HandleButton(note.Controls.SaveButton)
    end

    hooksecurefunc(Rematch, "FillPetTypeIcon", function(_, texture, _, prefix)
        if prefix then
            local button = texture:GetParent()
            RS:RematchIcon(button)
        end
    end)

    hooksecurefunc(Rematch, "MenuButtonSetChecked", function(_, button, isChecked, isRadio)
        if isChecked then
            local x = .5
            local y = isRadio and .5 or .25
            button.Check:SetTexCoord(x, x+.25, y-.25, y)
        else
            button.Check:SetTexCoord(0, 0, 0, 0)
        end

        if not button.styled then
            button.Check:SetVertexColor(cr, cg, cb)
            button.Check:CreateBackdrop('Transparent')
            button.Check.backdrop:SetBackdropColor(0, 0, 0, 0)
            button.Check.backdrop:SetPoint("TOPLEFT", button.Check, 4, -4)
            button.Check.backdrop:SetPoint("BOTTOMRIGHT", button.Check, -4, 4)
            RS:CreateGradient(button.Check.backdrop)

            button.styled = true
        end
    end)

    hooksecurefunc(Rematch, "FillCommonPetListButton", function(self, petID)
        local petInfo = Rematch.petInfo:Fetch(petID)
        local parentPanel = self:GetParent():GetParent():GetParent():GetParent()
        if petInfo.isSummoned and parentPanel == Rematch.PetPanel then
            local backdrop = parentPanel.SelectedOverlay.backdrop
            if backdrop then
                backdrop:ClearAllPoints()
                backdrop:SetAllPoints(self.backdrop)
            end
        end
    end)

    hooksecurefunc(Rematch, "DimQueueListButton", function(_, button)
        button.LevelText:SetTextColor(1, 1, 1)
    end)

    hooksecurefunc(RematchDialog, "FillTeam", function(_, frame)
        for i = 1, 3 do
            local button = frame.Pets[i]
            RS:RematchIcon(button)
            button.Icon.backdrop:SetBackdropBorderColor(button.IconBorder:GetVertexColor())

            for j = 1, 3 do
                RS:RematchIcon(button.Abilities[j])
            end
        end
    end)

    hooksecurefunc(RematchTeamTabs, "Update", function(self)
        for _, tab in next, self.Tabs do
            RS:RematchIcon(tab)
            tab:SetSize(40, 40)
            tab.Icon:SetPoint("CENTER")
        end

        for _, direc in pairs({"UpButton", "DownButton"}) do
            RS:RematchIcon(self[direc])
            self[direc]:SetSize(40, 40)
            self[direc].Icon:SetPoint("CENTER")
        end
    end)

    hooksecurefunc(RematchTeamTabs, "TabButtonUpdate", function(self, index)
        local selected = self:GetSelectedTab()
        local button = self:GetTabButton(index)
        if not button.Icon.backdrop then return end

        if index == selected then
            button.Icon.backdrop:SetBackdropBorderColor(1, 1, 1)
        else
            button.Icon.backdrop:SetBackdropBorderColor(0, 0, 0)
        end
    end)

    hooksecurefunc(RematchTeamTabs, "UpdateTabIconPickerList", function()
        local buttons = RematchDialog.TeamTabIconPicker.ScrollFrame.buttons
        for i = 1, #buttons do
            local button = buttons[i]
            for j = 1, 10 do
                local bu = button.Icons[j]
                if not bu.styled then
                    bu:SetSize(26, 26)
                    bu.Icon = bu.Texture
                    RS:RematchIcon(bu)
                end
            end
        end
    end)

    hooksecurefunc(RematchLoadoutPanel, "UpdateLoadouts", function(self)
        if not self then return end

        for i = 1, 3 do
            local loadout = self.Loadouts[i]
            if not loadout.styled then
                loadout:StripTextures()
                loadout:CreateBackdrop()
                loadout.backdrop:SetBackdropColor(0, 0, 0, .25)
                loadout.backdrop:SetPoint("BOTTOMRIGHT", E.mult, E.mult)
                RS:RematchIcon(loadout.Pet.Pet)
                RS:RematchXP(loadout.HP)
                RS:RematchXP(loadout.XP)
                loadout.XP:SetSize(255, 7)
                loadout.HP.MiniHP:SetText("HP")
                for j = 1, 3 do
                    RS:RematchIcon(loadout.Abilities[j])
                end

                loadout.styled = true
            end

            local icon = loadout.Pet.Pet.Icon
            local iconBorder = loadout.Pet.Pet.IconBorder
            if icon.backdrop then
                icon.backdrop:SetBackdropBorderColor(iconBorder:GetVertexColor())
            end
        end
    end)

    local activeTypeMode = 1
    hooksecurefunc(RematchPetPanel, "SetTypeMode", function(_, typeMode)
        activeTypeMode = typeMode
    end)
    hooksecurefunc(RematchPetPanel, "UpdateTypeBar", function(self)
        local typeBar = self.Top.TypeBar
        if typeBar:IsShown() then
            for i = 1, 4 do
                local tab = typeBar.Tabs[i]
                if not tab.styled then
                    tab:StripTextures()
                    tab:CreateBackdrop()
                    local r, g, b = tab.Selected.MidSelected:GetVertexColor()
                    tab.backdrop:SetBackdropColor(r, g, b, .5)
                    tab.Selected:StripTextures()

                    tab.styled = true
                end
                tab.backdrop:SetShown(activeTypeMode == i)
            end
        end
    end)

    hooksecurefunc(RematchPetPanel.List, "Update", function(self)
        RS:RematchPetList(self)
    end)
    hooksecurefunc(RematchQueuePanel.List, "Update", function(self)
        RS:RematchPetList(self)
    end)
    hooksecurefunc(RematchTeamPanel.List, "Update", function(self)
        RS:RematchPetList(self)
    end)

    hooksecurefunc(RematchTeamPanel, "FillTeamListButton", function(self, key)
        local teamInfo = Rematch.teamInfo:Fetch(key)
        if not teamInfo then return end

        local panel = RematchTeamPanel
        if teamInfo.key == RematchSettings.loadedTeam then
            local backdrop = panel.SelectedOverlay.backdrop
            if backdrop then
                backdrop:ClearAllPoints()
                backdrop:SetAllPoints(self.backdrop)
            end
        end
    end)

    hooksecurefunc(RematchOptionPanel, "FillOptionListButton", function(self, index)
        local panel = RematchOptionPanel
        local opt = panel.opts[index]
        if opt then
            self.optType = opt[1]
            local checkButton = self.CheckButton
            if not checkButton.backdrop then
                checkButton:CreateBackdrop()
                RS:CreateGradient(checkButton.backdrop)
                self.HeaderBack:SetTexture(nil)
            end
            checkButton.backdrop:SetBackdropColor(0, 0, 0, 0)
            checkButton.backdrop:Show()

            if self.optType == "header" then
                self.headerIndex = opt[3]
                self.Text:SetPoint("LEFT", checkButton, "RIGHT", 5, 0)
                checkButton:SetSize(8, 8)
                checkButton:SetPoint("LEFT", 5, 0)
                checkButton:SetTexture("Interface\\Buttons\\UI-PlusMinus-Buttons")
                checkButton.backdrop:SetBackdropColor(0, 0, 0, .25)
                checkButton.backdrop:SetPoint("TOPLEFT", checkButton, -3, 3)
                checkButton.backdrop:SetPoint("BOTTOMRIGHT", checkButton, 3, -3)

                local isCollapsed = RematchSettings.CollapsedOptHeaders[opt[3]]
                if isCollapsed then
                    checkButton:SetTexCoord(0, .4375, 0, .4375)
                else
                    checkButton:SetTexCoord(.5625, 1, 0, .4375)
                end
                if self.headerIndex == 0 and panel.allCollapsed then
                    checkButton:SetTexCoord(0, .4375, 0, .4375)
                end
            elseif self.optType == "check" then
                checkButton:SetSize(22, 22)
                checkButton.backdrop:SetPoint("TOPLEFT", checkButton, 3, -3)
                checkButton.backdrop:SetPoint("BOTTOMRIGHT", checkButton, -3, 3)
                if self.isChecked and self.isDisabled then
                    checkButton:SetTexCoord(.25, .5, .75, 1)
                elseif self.isChecked then
                    checkButton:SetTexCoord(.5, .75, 0, .25)
                else
                    checkButton:SetTexCoord(0, 0, 0, 0)
                end
            elseif self.optType == "radio" then
                local isChecked = RematchSettings[opt[2]] == opt[5]
                checkButton:SetSize(22, 22)
                checkButton.backdrop:SetPoint("TOPLEFT", checkButton, 3, -3)
                checkButton.backdrop:SetPoint("BOTTOMRIGHT", checkButton, -3, 3)
                if isChecked then
                    checkButton:SetTexCoord(.5, .75, .25, .5)
                else
                    checkButton:SetTexCoord(0, 0, 0, 0)
                end
            else
                checkButton.backdrop:Hide()
            end
        end
    end)

    -- Fix: RematchToolbar: fix GameTooltip white border
    hooksecurefunc(RematchToolbar, 'ButtonOnEnter', function(self)
        if not self.tooltipTitle and self ~= RematchToolbar.SummonRandom and self ~= RematchToolbar.Import then
            _G.GameTooltip:SetBackdropBorderColor(0, 0, 0)
        end
    end)

    -- Fix: RematchJournal:OtherAddonJournalStuff: Skin PetTracker Checkbox
    hooksecurefunc(RematchJournal, 'OtherAddonJournalStuff', function()
        if RematchJournal.PetTrackerJournalButton then
            S:HandleCheckBox(RematchJournal.PetTrackerJournalButton)
        end
    end)
end

RS:RegisterSkin(RS.Rematch, 'Rematch')
