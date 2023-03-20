local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G

-- WoW API / Variables

function RI:DoYouNeedThat()
    local DoYouNeedThat = _G.DoYouNeedThat

    DoYouNeedThat.EventFrame:RegisterEvent('CHALLENGE_MODE_COMPLETED')
    DoYouNeedThat.CHALLENGE_MODE_COMPLETED = function(self)
        self:ClearEntries()
        self.lootFrame:Show()
    end
end

RI:RegisterInjection(RI.DoYouNeedThat, 'DoYouNeedThat')
