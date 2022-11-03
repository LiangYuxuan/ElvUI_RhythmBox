local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')
local S = E:GetModule('Skins')

-- Lua functions
local _G = _G

-- WoW API / Variables
local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local IsControlKeyDown = IsControlKeyDown

local ExportUtil_MakeExportDataStream = ExportUtil.MakeExportDataStream
local StaticPopup_Show = StaticPopup_Show

local LOADOUT_SERIALIZATION_VERSION = 1

local exportButton

StaticPopupDialogs['RhythmBoxExportInspectTalentTreeDialog'] = {
    preferredIndex = 3,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    text = '按 Ctrl + C 复制',
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 240,
    OnShow = function(dialog, data)
        local function HidePopup()
            dialog:Hide()
        end
        dialog.editBox:SetScript('OnEscapePressed', HidePopup)
        dialog.editBox:SetScript('OnEnterPressed', HidePopup)
        dialog.editBox:SetScript('OnKeyUp', function(_, key)
            if IsControlKeyDown() and key == 'C' then
                HidePopup()
            end
        end)
        dialog.editBox:SetMaxLetters(0)
        dialog.editBox:SetText(data)
        dialog.editBox:HighlightText()
    end,
}

local function ExportString()
    local talentsTab = _G.ClassTalentFrame.TalentsTab
    local configID = talentsTab:GetConfigID()
    local specID = talentsTab:GetSpecID()
    local treeInfo = talentsTab:GetTreeInfo()

    local stream = ExportUtil_MakeExportDataStream()
    stream:AddValue(talentsTab.bitWidthHeaderVersion, LOADOUT_SERIALIZATION_VERSION)
    stream:AddValue(talentsTab.bitWidthSpecID, specID)
    stream:AddValue(8 * 16, 0)

    talentsTab:WriteLoadoutContent(stream, configID, treeInfo.ID)

    local exportString = stream:GetExportString()
    StaticPopup_Show('RhythmBoxExportInspectTalentTreeDialog', nil, nil, exportString)
end

local function UpdateExportButton()
    exportButton:SetShown(_G.ClassTalentFrame.TalentsTab:IsInspecting())
end

function RI:Blizzard_ClassTalentUI()
    local button = CreateFrame('Button', nil, _G.ClassTalentFrame.TalentsTab, 'UIPanelButtonNoTooltipTemplate, UIButtonTemplate')
    button:ClearAllPoints()
    button:SetPoint('CENTER', _G.ClassTalentFrame.TalentsTab.BottomBar, 'CENTER', 0, 0)
    button:SetSize(164, 22)

    button:SetScript('OnClick', ExportString)
    S:HandleButton(button)

    button:SetText('导出')
    button:Show()

    exportButton = button

    hooksecurefunc(_G.ClassTalentFrame.TalentsTab, 'UpdateInspecting', UpdateExportButton)
end

RI:RegisterInjection(RI.Blizzard_ClassTalentUI, 'Blizzard_ClassTalentUI')
