local R, E, L, V, P, G = unpack(select(2, ...))
local PA = R:NewModule('Paste', 'AceEvent-3.0')

local LDB = E.Libs.LDB
local LDBI = LibStub('LibDBIcon-1.0')
local StdUi = LibStub('StdUi')

-- Lua functions
local _G = _G
local gsub, ipairs, strsplit, strtrim = gsub, ipairs, strsplit, strtrim

-- WoW API / Variables
local ChatEdit_DeactivateChat = ChatEdit_DeactivateChat
local ChatEdit_GetActiveWindow = ChatEdit_GetActiveWindow
local ChatEdit_SendText = ChatEdit_SendText
local ChatFrame_OpenChat = ChatFrame_OpenChat

function PA:NormalizeText(text)
    if not text then return end

    -- normalize new line
    text = gsub(text, '\r\n', '\n')
    text = gsub(text, '\r', '\n')

    -- stripe empty line
    text = gsub(text, '\n%s*\n', '\n')
    text = gsub(text, '^%s*\n', '\n')
    text = gsub(text, '\n%s*$', '\n')

    -- trim white space
    text = gsub(text, '\n%s*', '\n')
    text = gsub(text, '%s*\n', '\n')
    text = gsub(text, '^%s*', '')
    text = gsub(text, '%s*$', '')

    return strtrim(text)
end

function PA:ExecuteText(text)
    local lines = { strsplit('\n', text) }
    for _, line in ipairs(lines) do
        ChatFrame_OpenChat('')
        local editbox = ChatEdit_GetActiveWindow()
        editbox:SetText(line)
        ChatEdit_SendText(editbox, 1)
        ChatEdit_DeactivateChat(editbox)
    end
end

function PA:Initialize()
    self.object = LDB:NewDataObject('RhythmBoxPaste', {
        type = 'launcher',
        label = 'Paste',
        icon = 'Interface/Icons/inv_scroll_08',
        OnClick = function(self)
            if not P.window:IsShown() then
                P.window:Show()
            else
                P.window:Hide()
            end
        end,
        OnTooltipShow = function(tooltip)
            if tooltip and tooltip.AddLine then
                tooltip:SetText("Paste")
                tooltip:AddLine("左键点击 - 显示/隐藏Paste窗口")
                tooltip:Show()
            end
        end,
    })
    LDBI:Register('RhythmBoxPaste', self.object, { hide = false })

    local window = StdUi:Window(_G.UIParent, 600, 400, 'Paste')
    window:SetPoint('CENTER')
    StdUi:EasyLayout(window, { padding = { top = 40 } })

    local editbox = StdUi:MultiLineBox(window, 200, 300, '')
    local button = StdUi:Button(window, nil, 20, "执行")
    button:SetScript('OnClick', function()
        local text = P:NormalizeText(editbox:GetValue())
        P:ExecuteText(text)
    end)

    window:AddRow():AddElement(editbox)
    window:AddRow():AddElement(button)
    window:DoLayout()

    window:Hide()
    self.window = window
end

R:RegisterModule(PA:GetName())
