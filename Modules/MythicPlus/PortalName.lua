local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G

-- WoW API / Variables

local spellIDToName = {}
for _, data in pairs(MP.database) do
    local _, abbrText, spellID = unpack(data)
    if spellID then
        spellIDToName[spellID] = abbrText
    end
end

spellIDToName[373262] = 'KARA' -- Return to Karazhan
spellIDToName[373274] = 'MECH' -- Operation: Mechagon
spellIDToName[367416] = 'TAZA' -- Tazavesh

local function OnToggleHandler()
    if _G.SpellFlyout:IsShown() then
        for i = 1, 20 do
            local button = _G['SpellFlyoutButton' .. i]
            if not button then return end

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
    else
        for i = 1, 20 do
            local button = _G['SpellFlyoutButton' .. i]
            if not button then return end

            if button.abbrText then
                button.abbrText:SetText('')
            end
        end
    end
end

function MP:BuildPortalName()
    self:SecureHook(_G.SpellFlyout, 'Toggle', OnToggleHandler)
end
