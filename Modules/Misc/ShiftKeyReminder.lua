-- Link: https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Misc/Misc.lua

local R, E, L, V, P, G = unpack(select(2, ...))
local SKR = R:NewModule('ShiftKeyReminder', 'AceEvent-3.0', 'AceTimer-3.0')

function SKR:Reminder()
    _G.UIErrorsFrame:AddMessage(E.InfoColor .. "你的Shift键可能卡住了。")
end

function SKR:MODIFIER_STATE_CHANGED(_, key, down)
    if key == 'LSHIFT' then
        if down == 1 then
            self.timer = self:ScheduleTimer('Reminder', 5)
        else
            self:CancelTimer(self.timer)
        end
    end
end

function SKR:Initialize()
    self:RegisterEvent('MODIFIER_STATE_CHANGED')
end

R:RegisterModule(SKR:GetName())
