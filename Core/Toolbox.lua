local R, E, L, V, P, G = unpack(select(2, ...))
local LDB = E.Libs.LDB
local LDBI = LibStub('LibDBIcon-1.0')
local StdUi = LibStub('StdUi')

-- Lua functions

-- WoW API / Variables

local toolboxWindow
local objectDataBlocker
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

function R:ToolboxRegisterSubWindow(subWindow, buttonText)
    subWindow:Hide()

    local button = StdUi:Button(toolboxWindow, nil, 20, buttonText)
    button.window = subWindow
    button:SetScript('OnClick', EntranceButtonOnClick)
    subWindow:SetScript('OnHide', SubWindowOnHide)

    tinsert(subWindows, subWindow)
    toolboxWindow:SetHeight(50 + 30 * #subWindows)
    toolboxWindow:AddRow():AddElement(button)
    toolboxWindow:DoLayout()
end

function R:ToolboxInitialize()
    objectDataBlocker = LDB:NewDataObject('RhythmBoxToolbox', {
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
    LDBI:Register('RhythmBoxToolbox', objectDataBlocker, { hide = false })

    toolboxWindow = StdUi:Window(_G.UIParent, 600, 50, "Rhythm Box 工具箱")
    toolboxWindow:SetPoint('CENTER')
    StdUi:EasyLayout(toolboxWindow, { padding = { top = 40 } })
    toolboxWindow:Hide()
end
