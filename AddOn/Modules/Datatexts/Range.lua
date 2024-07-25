local R, E, L, V, P, G = unpack((select(2, ...)))
local DT = E:GetModule('DataTexts')
local RC = E.Libs.RangeCheck

-- Lua functions

-- WoW API / Variables
local UnitName = UnitName

local nextRefreshTime = 1
local haveTarget, needUpdate
local curMin, curMax

local betweenTemplate = "%d - %d"
local overTemplate = "%d+"

local function OnUpdate(self, elapsed)
    if not haveTarget then return end

    nextRefreshTime = nextRefreshTime - elapsed
    if nextRefreshTime > 0 then return end
    nextRefreshTime = .25

    local minRange, maxRange = RC:GetRange('target')
    if not needUpdate and (minRange == curMin and maxRange == curMax) then return end

    curMin = minRange
    curMax = maxRange

    if minRange and maxRange then
        self.text:SetFormattedText(betweenTemplate, minRange, maxRange)
    elseif minRange then
        self.text:SetFormattedText(overTemplate, minRange)
    else
        self.text:SetText("")
    end

    needUpdate = nil
end

local function OnEvent(self)
    haveTarget = UnitName('target') ~= nil
    nextRefreshTime = 0
    if haveTarget then
        needUpdate = true
    else
        self.text:SetText("")
    end
end

local function ValueColorUpdate(self, hex)
    betweenTemplate = hex .. "%d|r - " .. hex .. "%d|r"
    overTemplate = hex .. "%d|r+"

    OnEvent(self)
end

DT:RegisterDatatext('Target Range', nil, {'PLAYER_TARGET_CHANGED'}, OnEvent, OnUpdate, nil, nil, nil, "目标距离", nil, ValueColorUpdate)
