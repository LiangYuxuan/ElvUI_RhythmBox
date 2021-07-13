local R, E, L, V, P, G = unpack(select(2, ...))
local LDB = E.Libs.LDB
local LDBI = LibStub('LibDBIcon-1.0')
local StdUi = LibStub('StdUi')

-- Lua functions
local _G = _G
local ipairs, tinsert = ipairs, tinsert

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

    local button = StdUi:Button(toolboxWindow, 500, 20, buttonText)
    button.window = subWindow
    button:SetScript('OnClick', EntranceButtonOnClick)
    subWindow:SetScript('OnHide', SubWindowOnHide)

    tinsert(subWindows, subWindow)
    StdUi:GlueTop(button, toolboxWindow, 0, -15 - 30 * #subWindows)
    toolboxWindow:SetHeight(50 + 30 * #subWindows)

    local name = 'RhythmBoxToolbox' .. #subWindows
    _G[name] = subWindow
    tinsert(_G.UISpecialFrames, name)
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

    toolboxWindow = StdUi:Window(_G.UIParent, 550, 50, "Rhythm Box 工具箱")
    toolboxWindow:SetPoint('CENTER')
    toolboxWindow:Hide()

    _G['RhythmBoxToolbox0'] = toolboxWindow
    tinsert(_G.UISpecialFrames, 'RhythmBoxToolbox0')
end
