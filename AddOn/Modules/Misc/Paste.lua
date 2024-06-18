local R, E, L, V, P, G = unpack((select(2, ...)))
local PA = R:NewModule('Paste', 'AceEvent-3.0')
local TB = R:GetModule('Toolbox')
local AceGUI = E.Libs.AceGUI

-- Lua functions
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

function PA:BuildWindow()
    local window = AceGUI:Create('Window')
    window:SetTitle('Paste')
    window:SetHeight(400)
    window:SetWidth(600)
    window:SetLayout('Fill')
    window:EnableResize(false)

    local container = AceGUI:Create('SimpleGroup')
    container:SetFullHeight(true)
    container:SetFullWidth(true)
    container:SetLayout('List')
    window:AddChild(container)

    local editbox = AceGUI:Create('MultiLineEditBox')
    editbox:SetNumLines(20)
    editbox:SetHeight(300)
    editbox:SetFullWidth(true)
    editbox:DisableButton(true)
    editbox:SetLabel('')
    container:AddChild(editbox)

    local buttonContainer = AceGUI:Create('SimpleGroup')
    buttonContainer:SetFullWidth(true)
    buttonContainer:SetLayout('Flow')
    container:AddChild(buttonContainer)

    local normalizeButton = AceGUI:Create('Button')
    normalizeButton:SetWidth(180)
    normalizeButton:SetText('整理')
    normalizeButton:SetCallback('OnClick', function()
        local text = PA:NormalizeText(editbox:GetText())
        editbox:SetText(text)
    end)
    buttonContainer:AddChild(normalizeButton)

    local executeButton = AceGUI:Create('Button')
    executeButton:SetWidth(180)
    executeButton:SetText('执行')
    executeButton:SetCallback('OnClick', function()
        local text = PA:NormalizeText(editbox:GetText())
        PA:ExecuteText(text)
    end)
    buttonContainer:AddChild(executeButton)

    local clearButton = AceGUI:Create('Button')
    clearButton:SetWidth(180)
    clearButton:SetText('清空')
    clearButton:SetCallback('OnClick', function()
        editbox:SetText('')
    end)
    buttonContainer:AddChild(clearButton)

    return window
end

function PA:Initialize()
    local window = PA:BuildWindow()
    TB:RegisterSubWindow(window, 'Paste')
end

R:RegisterModule(PA:GetName())
