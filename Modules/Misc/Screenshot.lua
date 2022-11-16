local R, E, L, V, P, G = unpack(select(2, ...))
local SS = R:NewModule('Screenshot', 'AceEvent-3.0', 'AceTimer-3.0')

-- Lua functions
local tinsert, tremove = tinsert, tremove

-- WoW API / Variables
local Screenshot = Screenshot

function SS:HandleScreenshot()
    Screenshot()
    tremove(self.queue, 1)
    if #self.queue > 0 then
        self:ScheduleTimer('HandleScreenshot', self.queue[1])
    end
end

function SS:HandleDelayScreenshot(delay)
    tinsert(self.queue, delay)
    if #self.queue == 1 then
        self:ScheduleTimer('HandleScreenshot', delay)
    end
end

function SS:ACHIEVEMENT_EARNED()
    self:HandleDelayScreenshot(1)
end

function SS:CHALLENGE_MODE_COMPLETED()
    self:HandleDelayScreenshot(5)
end

function SS:Initialize()
    self.queue = {}

    self:RegisterEvent('ACHIEVEMENT_EARNED')
    self:RegisterEvent('CHALLENGE_MODE_COMPLETED')
end

R:RegisterModule(SS:GetName())
