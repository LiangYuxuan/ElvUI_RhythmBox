local R, E, L, V, P, G = unpack(select(2, ...))
local RS = R:GetModule('Skins')

-- Lua functions
local _G = _G

-- WoW API / Variables
local C_Timer_After = C_Timer.After

function RS:ElvUIUnitFrames()
    C_Timer_After(5, function()
        _G.ElvUF_Player.RaisedElementParent:SetFrameStrata("MEDIUM")
        _G.ElvUF_TargetBuffs:SetFrameStrata("BACKGROUND")
    end)
end

RS:RegisterSkin(RS.ElvUIUnitFrames)
