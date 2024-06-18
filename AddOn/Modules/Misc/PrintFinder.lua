local R, E, L, V, P, G = unpack((select(2, ...)))
local PF = R:NewModule('PrintFinder', 'AceEvent-3.0')

-- Lua functions
local format = format
local hooksecurefunc = hooksecurefunc

-- WoW API / Variables
local debugstack = debugstack

PF.targets = {
    ['CONTENT'] = true,
}

function PF:Initialize()
    hooksecurefunc('print', function(content)
        if PF.targets[content] then
            R:Debug(format("Caller: %s, Debug Stack: %s", debugstack(2, 1, 0), debugstack(2)), 'print caller')
        end
    end)
end

-- R:RegisterModule(PF:GetName())
