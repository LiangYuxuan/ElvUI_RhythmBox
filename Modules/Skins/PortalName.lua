local R, E, L, V, P, G = unpack(select(2, ...))
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G

-- WoW API / Variables

local spellIDToName = {
    [354462] = 'NW',
    [354463] = 'PF',
    [354464] = 'MISTS',
    [354465] = 'HOA',
    [354466] = 'SOA',
    [354467] = 'TOP',
    [354468] = 'DOS',
    [354469] = 'SD',
    [367416] = 'TAZ',
}

local length = 0
for _ in pairs(spellIDToName) do
    length = length + 1
end

local function OnToggleHandler()
    if _G.SpellFlyout:IsShown() then
        for i = 1, length do
            local button = _G['SpellFlyoutButton' .. i]

            if button then
                if button.spellID and spellIDToName[button.spellID] then
                    if not button.abbrText then
                        button.abbrText = button:CreateFontString(nil, 'OVERLAY')
                        button.abbrText:FontTemplate(nil, 12)
                        button.abbrText:SetTextColor(1, 1, 1, 1)
                        button.abbrText:SetPoint('CENTER', button, 'CENTER', 0, 0)
                        button.abbrText:SetJustifyH('CENTER')
                    end

                    button.abbrText:SetText(spellIDToName[button.spellID])
                elseif button.abbrText then
                    button.abbrText:SetText('')
                end
            end
        end
    else
        for i = 1, length do
            local button = _G['SpellFlyoutButton' .. i]

            if button and button.abbrText then
                button.abbrText:SetText('')
            end
        end
    end
end

function RS:PortalName()
    self:SecureHook(_G.SpellFlyout, 'Toggle', OnToggleHandler)
end

RS:RegisterSkin(RS.PortalName)