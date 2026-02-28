local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local unpack = unpack
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables

local function BigWigs()
    R:RegisterAddOnLoad('BigWigs', function()
        R:RegisterAddOnLoad('ElvUI_WindTools', function()
            local BigWigsAPI = _G.BigWigsAPI
            local W = unpack(_G.WindTools)

            local styleData = BigWigsAPI:GetBarStyle(W.PlainTitle)
            if styleData and not BigWigsAPI:GetBarStyle("WindTools") then
                BigWigsAPI:RegisterBarStyle("WindTools", styleData)
            else
                hooksecurefunc(BigWigsAPI, 'RegisterBarStyle', function(_, key, styleData)
                    if key == W.PlainTitle and not BigWigsAPI:GetBarStyle("WindTools") then
                        BigWigsAPI:RegisterBarStyle("WindTools", styleData)
                    end
                end)
            end
        end)

    end)
end

RI:RegisterPipeline(BigWigs)
