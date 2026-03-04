local R, E, L, V, P, G = unpack((select(2, ...)))
local RI = R:GetModule('Injections')

-- Lua functions
local _G = _G
local select = select

-- WoW API / Variables
local UnitCastingDuration = UnitCastingDuration
local UnitCastingInfo = UnitCastingInfo
local UnitChannelDuration = UnitChannelDuration
local UnitChannelInfo = UnitChannelInfo

local EMPOWERED_CAST_START = {
    UNIT_SPELLCAST_EMPOWER_START = true,
}

local CAST_START = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_INTERRUPTIBLE = true,
    UNIT_SPELLCAST_NOT_INTERRUPTIBLE = true,
    UNIT_SPELLCAST_SENT = true,
}

local CHANNEL_START = {
    UNIT_SPELLCAST_CHANNEL_START = true,
}

local function hookOnEvent(self, event)
    if CAST_START[event] then
        local castDuration = UnitCastingDuration('player')
        if not castDuration then return end

        self.SpellNameText:SetText(UnitCastingInfo('player'))
    elseif EMPOWERED_CAST_START[event] then
        local isEmpowered = select(9, UnitChannelInfo('player'))
        if not isEmpowered then return end

        self.SpellNameText:SetText(UnitChannelInfo('player'))
    elseif CHANNEL_START[event] then
        local channelDuration = UnitChannelDuration('player')
        if not channelDuration then return end

        self.SpellNameText:SetText(UnitChannelInfo('player'))
    end
end

local function BetterCooldownManager()
    R:RegisterAddOnLoad('BetterCooldownManager', function()
        local originalSetScript = _G.BCDM_CastBar.SetScript
        _G.BCDM_CastBar.SetScript = function(self, scriptTypeName, script)
            if scriptTypeName == 'OnEvent' and script then
                local result = originalSetScript(self, scriptTypeName, script)

                self:HookScript('OnEvent', hookOnEvent)

                return result
            elseif scriptTypeName == 'OnEvent' then
                return originalSetScript(self, scriptTypeName, script)
            else
                return originalSetScript(self, scriptTypeName, script)
            end
        end
    end)
end

RI:RegisterPipeline(BetterCooldownManager)
