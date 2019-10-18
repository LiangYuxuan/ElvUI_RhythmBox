local R, E, L, V, P, G = unpack(select(2, ...))
local AB = R:GetModule('ActionBars')

-- Lua functions
local _G = _G
local ipairs, pairs = ipairs, pairs

-- WoW API / Variables
local AttemptToSaveBindings = AttemptToSaveBindings
local LoadBindings = LoadBindings
local SetBinding = SetBinding
local SaveBindings = SaveBindings

local HideUIPanel = HideUIPanel

local DEFAULT_BINDINGS = 0
local ACCOUNT_BINDINGS = 1

local unbindingMap = {
    'CTRL-F1',
    'CTRL-F2',
    'CTRL-F3',
    'CTRL-F4',
    'CTRL-F5',
    'CTRL-F6',
    'CTRL-F7',
    'CTRL-F8',
    'CTRL-F9',
    'CTRL-F10',
}

local bindingMap = {
    ['MULTIACTIONBAR1BUTTON1']  = 'Q',
    ['MULTIACTIONBAR1BUTTON2']  = 'E',
    ['MULTIACTIONBAR1BUTTON3']  = 'R',
    ['MULTIACTIONBAR1BUTTON4']  = 'T',
    ['MULTIACTIONBAR1BUTTON5']  = 'F',
    ['MULTIACTIONBAR1BUTTON6']  = 'G',
    ['MULTIACTIONBAR1BUTTON7']  = 'SHIFT-Q',
    ['MULTIACTIONBAR1BUTTON8']  = 'SHIFT-E',
    ['MULTIACTIONBAR1BUTTON9']  = 'SHIFT-R',
    ['MULTIACTIONBAR1BUTTON10'] = 'SHIFT-T',
    ['MULTIACTIONBAR1BUTTON11'] = 'SHIFT-F',
    ['MULTIACTIONBAR1BUTTON12'] = 'SHIFT-G',

    ['MULTIACTIONBAR2BUTTON1']  = 'SHIFT-1',
    ['MULTIACTIONBAR2BUTTON2']  = 'SHIFT-2',
    ['MULTIACTIONBAR2BUTTON3']  = 'SHIFT-3',
    ['MULTIACTIONBAR2BUTTON4']  = 'SHIFT-4',
    ['MULTIACTIONBAR2BUTTON5']  = 'SHIFT-5',
    ['MULTIACTIONBAR2BUTTON6']  = 'SHIFT-6',
    ['MULTIACTIONBAR2BUTTON7']  = 'SHIFT-7',
    ['MULTIACTIONBAR2BUTTON8']  = 'SHIFT-8',
    ['MULTIACTIONBAR2BUTTON9']  = 'SHIFT-9',
    ['MULTIACTIONBAR2BUTTON10'] = 'SHIFT-0',
    ['MULTIACTIONBAR2BUTTON11'] = 'SHIFT--',
    ['MULTIACTIONBAR2BUTTON12'] = 'SHIFT-=',

    ['SHAPESHIFTBUTTON1']       = 'F1',
    ['SHAPESHIFTBUTTON2']       = 'F2',
    ['SHAPESHIFTBUTTON3']       = 'F3',
    ['SHAPESHIFTBUTTON4']       = 'F4',
    ['SHAPESHIFTBUTTON5']       = 'F5',
    ['SHAPESHIFTBUTTON6']       = 'F6',
    ['SHAPESHIFTBUTTON7']       = 'F7',
    ['SHAPESHIFTBUTTON8']       = 'F8',
    ['SHAPESHIFTBUTTON9']       = 'F9',
    ['SHAPESHIFTBUTTON10']      = 'F10',
}

function AB:InstallActionBars()
    if _G.KeyBindingFrame then
        HideUIPanel(_G.KeyBindingFrame)
    end

    LoadBindings(DEFAULT_BINDINGS)

    for _, key in ipairs(unbindingMap) do
        SetBinding(key, nil, 1)
    end

    for command, key in pairs(bindingMap) do
        SetBinding(key, command, 1)
    end

    if R.Retail then
        SaveBindings(ACCOUNT_BINDINGS)
    else
        AttemptToSaveBindings(ACCOUNT_BINDINGS)
    end
end
