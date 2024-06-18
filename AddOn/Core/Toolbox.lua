local R, E, L, V, P, G = unpack((select(2, ...)))
local TB = R:NewModule('Toolbox', 'AceEvent-3.0')
local AceGUI = E.Libs.AceGUI
local LDB = E.Libs.LDB
local LDBI = LibStub('LibDBIcon-1.0')

-- Lua functions
local _G = _G
local ipairs, tinsert = ipairs, tinsert

-- WoW API / Variables

local toolboxWindow
local subWindows = {}

local function EntranceButtonOnClick(self)
    toolboxWindow:Hide()
    self.window:Show()
end

local function SubWindowOnHide()
    toolboxWindow:Show()
end

local function HideAllSubWindows()
    for _, subWindow in ipairs(subWindows) do
        subWindow:Hide()
    end
end

function TB:RegisterSubWindow(subWindow, buttonText)
    subWindow:Hide()

    local executeButton = AceGUI:Create('Button')
    executeButton:SetHeight(30)
    executeButton:SetFullWidth(true)
    executeButton:SetText(buttonText)
    executeButton:SetCallback('OnClick', EntranceButtonOnClick)
    executeButton.window = subWindow
    toolboxWindow:AddChild(executeButton)

    if subWindow.SetCallback then
        subWindow:SetCallback('OnClose', SubWindowOnHide)
    else
        subWindow:SetScript('OnHide', SubWindowOnHide)
    end

    tinsert(subWindows, subWindow)
    toolboxWindow:SetHeight(50 + 30 * #subWindows)

    local name = 'RhythmBoxToolbox' .. #subWindows
    _G[name] = subWindow
    tinsert(_G.UISpecialFrames, name)
end

function TB:Initialize()
    local objectDataBlocker = LDB:NewDataObject('RhythmBoxToolbox', {
        type = 'launcher',
        label = 'Toolbox',
        icon = 'Interface/Icons/inv_scroll_08',
        OnClick = function(self)
            if not toolboxWindow:IsShown() then
                HideAllSubWindows()
                toolboxWindow:Show()
            else
                toolboxWindow:Hide()
            end
        end,
        OnTooltipShow = function(tooltip)
            if tooltip and tooltip.AddLine then
                tooltip:SetText("Toolbox")
                tooltip:AddLine("左键点击 - 显示/隐藏Toolbox窗口")
                tooltip:Show()
            end
        end,
    })
    LDBI:Register('RhythmBoxToolbox', objectDataBlocker)

    toolboxWindow = AceGUI:Create('Window')
    toolboxWindow:SetTitle("Rhythm Box 工具箱")
    toolboxWindow:SetHeight(50)
    toolboxWindow:SetWidth(550)
    toolboxWindow:SetLayout('List')
    toolboxWindow:EnableResize(false)
    toolboxWindow:Hide()

    _G['RhythmBoxToolbox0'] = toolboxWindow
    tinsert(_G.UISpecialFrames, 'RhythmBoxToolbox0')
end

R:RegisterModule(TB:GetName())
