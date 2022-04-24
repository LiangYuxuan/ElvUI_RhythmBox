local R, E, L, V, P, G = unpack(select(2, ...))
local CM = R:NewModule('CovenantMacro', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local gsub, loadstring, pcall, select, strfind = gsub, loadstring, pcall, select, strfind

-- WoW API / Variables
local GetActionInfo = GetActionInfo
local GetMacroInfo = GetMacroInfo
local InCombatLockdown = InCombatLockdown

local isPending

function CM:UpdateMacro()
    if InCombatLockdown() then
        self:Update()
        return
    end

    isPending = false

    for slotID = 1, 120 do
        local actionType, id = GetActionInfo(slotID)
        if actionType == 'macro' and id then
            local body = select(3, GetMacroInfo(id))
            if body then
                local code = select(3, strfind(body, '/run (.-SetMacroSpell%(.-GetRunningMacro%(%).-%))'))
                if code then
                    code = gsub(code, 'GetRunningMacro%(%)', id)
                    pcall(loadstring(code))
                end
            end
        end
    end
end

function CM:Update()
    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_ENABLED', 'Update')
        return
    end

    if isPending then return end

    isPending = true
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
    self:ScheduleTimer('UpdateMacro', 1)
end

function CM:Initialize()
    self:RegisterEvent('COVENANT_CHOSEN', 'Update')
    self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', 'Update')
    self:RegisterEvent('SPELLS_CHANGED', 'Update')
end

R:RegisterModule(CM:GetName())
