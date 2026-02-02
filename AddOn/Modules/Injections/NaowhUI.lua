local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local unpack = unpack

-- WoW API / Variables

local function NaowhUI()
    R:RegisterAddOnLoad('NaowhUI', function()
        local NUI = unpack(_G.NaowhUI)

        NUI.IsTokenValid = function()
            return true
        end
    end)
end

RI:RegisterPipeline(NaowhUI)
