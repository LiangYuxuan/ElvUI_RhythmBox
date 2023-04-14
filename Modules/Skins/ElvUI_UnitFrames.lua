local R, E, L, V, P, G = unpack((select(2, ...)))
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G

-- WoW API / Variables
local hooksecurefunc = hooksecurefunc

function RS:ElvUIUnitFrames()
    local UF = E:GetModule('UnitFrames')

    hooksecurefunc(UF, 'Construct_PlayerFrame', function()
        _G.ElvUF_Player.RaisedElementParent:SetFrameStrata('MEDIUM')
    end)

    hooksecurefunc(UF, 'Construct_TargetFrame', function()
        _G.ElvUF_TargetBuffs:SetFrameStrata('BACKGROUND')
    end)
end

RS:RegisterSkin(RS.ElvUIUnitFrames)
