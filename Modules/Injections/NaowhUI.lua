local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local type = type
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables

local function ResetFont()
    if type(E.db.general.font) ~= 'nil' then
        E.db.general.font = nil
        E:UpdateMedia()
    end
end

local function NaowhUI()
    R:RegisterAddOnLoad('NaowhUI', function()
        -- NaowhUI enforce Naowh font every update as soon as it loads
        -- We revert this behavior

        hooksecurefunc(E, 'UpdateMedia', ResetFont)

        ResetFont()
    end)
end

RI:RegisterPipeline(NaowhUI)
