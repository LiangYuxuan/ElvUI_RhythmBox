local R, E, L, V, P, G = unpack(select(2, ...))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables
local GetBindingAction = GetBindingAction
local SetBinding = SetBinding

function RI:MailCommander_CheckBinding()
    if GetBindingAction('SHIFT-P') ~= 'TOGGLECOLLECTIONS' then
        -- MailCommander doing bad stuff
        SetBinding('SHIFT-P', 'TOGGLECOLLECTIONS')
    end
end

function RI:MailCommander()
    self:SecureHook(_G.MailCommander, 'OnInitialized', 'MailCommander_CheckBinding')
    self:MailCommander_CheckBinding()
end

RI:RegisterInjection(RI.MailCommander, 'MailCommander')
