local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')
local LAB = E.Libs.LAB

-- Lua functions
local _G = _G

-- WoW API / Variables

local spellIDToName = {}
for _, data in pairs(MP.database) do
    local _, _, abbrText, spellID = unpack(data)
    if spellID then
        spellIDToName[spellID] = abbrText
    end
end

spellIDToName[373262] = 'KARA' -- Return to Karazhan
spellIDToName[373274] = 'MECH' -- Operation: Mechagon
spellIDToName[367416] = 'TAZA' -- Tazavesh
spellIDToName[424197] = 'DOTI' -- Dawn of the Infinite

local function handleButton(button, isShown)
    if isShown then
        local spellID = button.spellID or button._state_action
        if spellID and spellIDToName[spellID] then
            if not button.abbrText then
                button.abbrText = button:CreateFontString(nil, 'OVERLAY')
                button.abbrText:FontTemplate(nil, 12)
                button.abbrText:SetTextColor(1, 1, 1, 1)
                button.abbrText:SetPoint('CENTER', button, 'CENTER', 0, 0)
                button.abbrText:SetJustifyH('CENTER')
            end

            button.abbrText:SetText(spellIDToName[spellID])
        elseif button.abbrText then
            button.abbrText:SetText('')
        end
    elseif button.abbrText then
        button.abbrText:SetText('')
    end
end

local function OnToggleHandler()
    local isShown = _G.SpellFlyout:IsShown()
    for i = 1, 20 do
        local button = _G['SpellFlyoutButton' .. i]
        if not button then return end

        handleButton(button, isShown)
    end
end

local function OnFlyoutUpdate()
    local isShown = _G.LABFlyoutHandlerFrame:IsShown()
    for i = 1, 20 do
        local button = _G['LABFlyoutButton' .. i]
        if not button then return end

        handleButton(button, isShown)
    end
end

function MP:BuildPortalName()
    self:SecureHook(_G.SpellFlyout, 'Toggle', OnToggleHandler)
    LAB.RegisterCallback(MP, 'OnFlyoutUpdate', OnFlyoutUpdate)
end
