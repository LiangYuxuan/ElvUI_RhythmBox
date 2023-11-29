local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables

local function ResetFont()
    if type(E.db.general.font) ~= 'nil' then
        E.db.general.font = nil
        E:UpdateMedia()
    end
end

function RI:NaowhUI()
    -- NaowhUI enforce Naowh font every update as soon as it loads
    -- We revert this behavior

    hooksecurefunc(E, 'UpdateMedia', ResetFont)

    ResetFont()
end

RI:RegisterInjection(RI.NaowhUI, 'NaowhUI')
