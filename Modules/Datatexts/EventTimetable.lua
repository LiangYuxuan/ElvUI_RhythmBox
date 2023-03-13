local R, E, L, V, P, G = unpack(select(2, ...))
local DT = E:GetModule('DataTexts')

-- Lua functions
local date, floor, format, ipairs, pairs, time, unpack = date, floor, format, ipairs, pairs, time, unpack

-- WoW API / Variables
local C_AreaPoiInfo_GetAreaPOISecondsLeft = C_AreaPoiInfo.GetAreaPOISecondsLeft
local C_ContributionCollector_GetContributionAppearance = C_ContributionCollector.GetContributionAppearance
local C_ContributionCollector_GetName = C_ContributionCollector.GetName
local C_ContributionCollector_GetState = C_ContributionCollector.GetState
local C_Map_GetMapInfo = C_Map.GetMapInfo
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo
local GetServerTime = GetServerTime

local SecondsToTime = SecondsToTime
local WrapTextInColorCode = WrapTextInColorCode

local UNKNOWN = UNKNOWN

local region = GetCVar('portal')
if not region or #region ~= 2 then
    local regionID = GetCurrentRegion()
    region = regionID and ({ 'US', 'KR', 'EU', 'TW', 'CN' })[regionID]
end
if region ~= 'US' and region ~= 'EU' then region = 'CN' end

local faction = E.myfaction
local oppositeFaction = faction == 'Alliance' and 'Horde' or 'Alliance'

-- TODO: allow use local time to find future sequence to show these in local time (provide options)
local futureDateUseServerTime = false
local TIME = futureDateUseServerTime and GetServerTime or time

local function GetSequence(futureLength, baseTime, interval, duration, timeTable)
    local result = {}

    local currentTime = GetServerTime()
    local elapsed = (currentTime - baseTime) % interval
    local currentIndex
    if timeTable then
        local count = #timeTable
        local round = (floor((currentTime - baseTime) / interval) + 1) % count
        if round == 0 then round = count end

        currentIndex = round
    end

    if elapsed < duration then
        result[0] = { duration - elapsed, currentIndex and timeTable[currentIndex] }
    end

    local nextTime = interval - elapsed + TIME()
    for i = 1, futureLength do
        if currentIndex then
            currentIndex = (currentIndex + 1) % #timeTable
            if currentIndex == 0 then currentIndex = #timeTable end
        end

        result[i] = { nextTime, currentIndex and timeTable[currentIndex] }
        nextTime = nextTime + interval
    end

    return result
end

local stateAndTimers = {
    {
        title = "社区盛宴",
        data = {
            interval = 5400,
            duration = 900,
            baseTime = {
                US = 1678698000, -- 2023-03-13 01:00 UTC-8
                EU = 1678696200, -- 2023-03-13 08:30 UTC+0
                CN = 1678608000, -- 2023-03-12 16:00 UTC+8
            },
        },
        func = function(tooltip, data)
            local seq = GetSequence(2, data.baseTime[region], data.interval, data.duration)
            if seq[0] then
                local minutesLeft = seq[0][1] / 60
                tooltip:AddDoubleLine("当前", format("%dh %.2dm", minutesLeft / 60, minutesLeft % 60), 1, 1, 1, 0, 1, 0)
            end
            for i = 1, #seq do
                local nextTime = seq[i][1]
                tooltip:AddDoubleLine("下次", date("%m/%d %H:%M", nextTime), 1, 1, 1, 1, 1, 1)
            end
        end,
    },
    {
        title = "围攻灭龙要塞",
        data = {
            interval = 7200,
            duration = 3600,
            baseTime = {
                US = 1670320800, -- 2022-12-06 02:00 UTC-8
                EU = 1670320800, -- 2022-12-06 10:00 UTC+0
                CN = 1670144400, -- 2022-12-04 17:00 UTC+8
            },
        },
        func = function(tooltip, data)
            local seq = GetSequence(2, data.baseTime[region], data.interval, data.duration)
            if seq[0] then
                local minutesLeft = seq[0][1] / 60
                tooltip:AddDoubleLine("当前", format("%dh %.2dm", minutesLeft / 60, minutesLeft % 60), 1, 1, 1, 0, 1, 0)
            end
            for i = 1, #seq do
                local nextTime = seq[i][1]
                tooltip:AddDoubleLine("下次", date("%m/%d %H:%M", nextTime), 1, 1, 1, 1, 1, 1)
            end
        end,
    },
    {
        title = "托加斯特的折磨者",
        data = {
            interval = 7200,
            duration = 7200,
            timeTable = {1, 6, 15, 4, 7, 11, 3, 10, 12, 5, 9, 13, 2, 8, 14},
            baseTime = {
                US = 1670389200, -- 2022-12-06 21:00 UTC-8
                EU = 1670360400, -- 2022-12-06 21:00 UTC+0
                CN = 1626786000, -- 2021-07-20 21:00 UTC+8
            },
        },
        func = function(tooltip, data)
            local seq = GetSequence(3, data.baseTime[region], data.interval, data.duration, data.timeTable)
            if seq[0] then
                local secondsLeft, index = unpack(seq[0])
                local criteriaString, _, completed = GetAchievementCriteriaInfo(15054, index)
                tooltip:AddDoubleLine(
                    "当前: " .. WrapTextInColorCode(criteriaString, completed and 'ffffffff' or 'ffff2020'),
                    date("%m/%d %H:%M", TIME() - data.duration + secondsLeft), 1, 1, 1, 1, 1, 1
                )
            end
            for i = 1, #seq do
                local nextTime, index = unpack(seq[i])
                local criteriaString, _, completed = GetAchievementCriteriaInfo(15054, index)
                tooltip:AddDoubleLine(
                    "下次: " .. WrapTextInColorCode(criteriaString, completed and 'ffffffff' or 'ffff2020'),
                    date("%m/%d %H:%M", nextTime), 1, 1, 1, 1, 1, 1
                )
            end
        end,
    },
    {
        title = "战争前线",
        data = {
            warfronts = {
                -- Arathi Highlands
                {
                  Alliance = 116,
                  Horde = 11,
                },
                -- Darkshores
                {
                  Alliance = 117,
                  Horde = 118,
                },
            },
        },
        func = function(tooltip, data)
            for _, warfront in pairs(data.warfronts) do
                local contributionID = warfront[faction]
                local contributionName = C_ContributionCollector_GetName(contributionID)
                local state, stateAmount, timeOfNextStateChange = C_ContributionCollector_GetState(contributionID)
                local stateName = C_ContributionCollector_GetContributionAppearance(contributionID, state).stateName
                if state == 4 then
                    -- captured
                    state, stateAmount, timeOfNextStateChange = C_ContributionCollector_GetState(warfront[oppositeFaction])
                    stateName = format("%s (%s)", stateName, C_ContributionCollector_GetContributionAppearance(contributionID, state).stateName)
                end
                if state == 2 and timeOfNextStateChange then
                    -- attacking
                    -- rest time available
                    tooltip:AddDoubleLine(contributionName, SecondsToTime(timeOfNextStateChange - GetServerTime()), 1, 210 / 255, 0, 1, 1, 1)
                    tooltip:AddDoubleLine(stateName, date("%m/%d %H:%M", timeOfNextStateChange), 1, 1, 1, 1, 1, 1)
                elseif state == 2 then
                    -- rest time not available
                    local expectTime = 7 * 24 * 60 * 60 -- 7 days
                    tooltip:AddDoubleLine(contributionName, "100%", 1, 210 / 255, 0, 1, 1, 1)
                    tooltip:AddDoubleLine(stateName, date("~ %m/%d %H:00", expectTime + TIME()), 1, 1, 1, 1, 1, 1)
                elseif stateAmount then
                    -- contributing
                    -- contribute amount available
                    local expectTime = (1 - stateAmount) * 7 * 24 * 60 * 60 -- 7 days
                    local hour = expectTime / 60 / 60
                    local day = floor(hour / 24)
                    hour = hour - day * 24

                    local expectTimeText
                    if day > 0 then
                        expectTimeText = format("%d 天 %d 小时", day, hour)
                    else
                        expectTimeText = format("%d 小时", hour)
                    end

                    tooltip:AddDoubleLine(contributionName, format("%.2f%% (%s)", stateAmount * 100, expectTimeText), 1, 210 / 255, 0, 1, 1, 1)
                    tooltip:AddDoubleLine(stateName, date("~ %m/%d %H:00", expectTime + TIME()), 1, 1, 1, 1, 1, 1)
                else
                    -- contribute amount not available
                    tooltip:AddDoubleLine(contributionName, stateName, 1, 210 / 255, 0, 1, 1, 1)
                end
            end
        end,
    },
    {
        title = "阵营突袭",
        data = {
            interval = 68400,
            duration = 25200,
            timeTable = {896, 862, 895, 863, 942, 864},
            baseTime = {
                US = 1548032400, -- 2019-01-20 17:00 UTC-8
                EU = 1548000000, -- 2019-01-20 16:00 UTC+0
                CN = 1546743600, -- 2019-01-06 11:00 UTC+8
            },
            maps = {862, 863, 864, 896, 942, 895},
            mapAreaPoiIDs = {
                [862] = 5973,
                [863] = 5969,
                [864] = 5970,
                [896] = 5964,
                [942] = 5966,
                [895] = 5896,
            },
        },
        func = function(tooltip, data)
            local seq = GetSequence(2, data.baseTime[region], data.interval, data.duration, data.timeTable)
            if seq[0] then
                local secondsLeft, uiMapID = unpack(seq[0])
                local minutesLeft = secondsLeft / 60
                local uiMapName = uiMapID and C_Map_GetMapInfo(uiMapID).name or UNKNOWN
                tooltip:AddDoubleLine("当前: " .. uiMapName, format("%dh %.2dm", minutesLeft / 60, minutesLeft % 60), 1, 1, 1, 0, 1, 0)
            end
            for i = 1, #seq do
                local nextTime, uiMapID = unpack(seq[i])
                local uiMapName = uiMapID and C_Map_GetMapInfo(uiMapID).name or UNKNOWN
                tooltip:AddDoubleLine("下次: " .. uiMapName, date("%m/%d %H:%M", nextTime), 1, 1, 1, 1, 1, 1)
            end
        end,
    },
    {
        title = "军团突袭",
        data = {
            interval = 66600,
            duration = 21600,
            baseTime = {
                US = 1547614800, -- 2019-01-15 21:00 UTC-8
                EU = 1547586000, -- 2019-01-15 21:00 UTC+0
                CN = 1546844400, -- 2019-01-07 15:00 UTC+8
            },
            maps = {630, 641, 650, 634},
            mapAreaPoiIDs = {
                [630] = 5175,
                [641] = 5210,
                [650] = 5177,
                [634] = 5178,
            },
        },
        func = function(tooltip, data)
            local seq = GetSequence(2, data.baseTime[region], data.interval, data.duration)
            if seq[0] then
                local minutesLeft = seq[0][1] / 60
                local uiMapName = UNKNOWN
                for _, uiMapID in ipairs(data.maps) do
                    local areaPoiID = data.mapAreaPoiIDs[uiMapID]
                    local seconds = C_AreaPoiInfo_GetAreaPOISecondsLeft(areaPoiID)
                    if seconds and seconds > 0 then
                        uiMapName = C_Map_GetMapInfo(uiMapID).name
                        break
                    end
                end
                tooltip:AddDoubleLine("当前: " .. uiMapName, format("%dh %.2dm", minutesLeft / 60, minutesLeft % 60), 1, 1, 1, 0, 1, 0)
            end
            for i = 1, #seq do
                local nextTime = seq[i][1]
                tooltip:AddDoubleLine("下次", date("%m/%d %H:%M", nextTime), 1, 1, 1, 1, 1, 1)
            end
        end,
    },
}

local function OnEvent(self)
    self.text:SetText("世界活动时间表")
end

local function OnEnter(self)
    DT:SetupTooltip(self)

    for _, data in ipairs(stateAndTimers) do
        DT.tooltip:AddLine(data.title)
        if data.baseTime and not data.baseTime[region] then
            DT.tooltip:AddLine("此区域未有已知时间表。")
        else
            data.func(DT.tooltip, data.data)
        end
    end

    DT.tooltip:Show()
end

--[[
    DT:RegisterDatatext(name, category, events, eventFunc, updateFunc, clickFunc, onEnterFunc, onLeaveFunc, localizedName, objectEvent)

    name - name of the datatext (required)
	category - name of the category the datatext belongs to.
    events - must be a table with string values of event names to register
    eventFunc - function that gets fired when an event gets triggered
    updateFunc - onUpdate script target function
    click - function to fire when clicking the datatext
    onEnterFunc - function to fire OnEnter
    onLeaveFunc - function to fire OnLeave, if not provided one will be set for you that hides the tooltip.
    localizedName - localized name of the datetext
]]
DT:RegisterDatatext('RhythmBox_Event_Timetable', nil, { 'PLAYER_ENTERING_WORLD' }, OnEvent, nil, nil, OnEnter, nil, "世界活动时间表")
