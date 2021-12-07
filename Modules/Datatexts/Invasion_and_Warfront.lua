local R, E, L, V, P, G = unpack(select(2, ...))
local DT = E:GetModule('DataTexts')

-- Lua functions
local date, floor, format, ipairs = date, floor, format, ipairs
local pairs, time, tinsert, unpack = pairs, time, tinsert, unpack

-- WoW API / Variables
local C_AreaPoiInfo_GetAreaPOISecondsLeft = C_AreaPoiInfo.GetAreaPOISecondsLeft
local C_ContributionCollector_GetContributionAppearance = C_ContributionCollector.GetContributionAppearance
local C_ContributionCollector_GetName = C_ContributionCollector.GetName
local C_ContributionCollector_GetState = C_ContributionCollector.GetState
local C_Map_GetMapInfo = C_Map.GetMapInfo
local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo

local SecondsToTime = SecondsToTime
local WrapTextInColorCode = WrapTextInColorCode

local UNKNOWN = UNKNOWN

local region = GetCVar('portal')
if not region or #region ~= 2 then
    local regionID = GetCurrentRegion()
    region = regionID and ({ 'US', 'KR', 'EU', 'TW', 'CN' })[regionID]
end

local faction = E.myfaction
local oppositeFaction = faction == 'Alliance' and 'Horde' or 'Alliance'

local invIndex = {
    {
        title = "阵营突袭",
        interval = 68400,
        duration = 25200,
        maps = {862, 863, 864, 896, 942, 895},
        timeTable = {4, 1, 6, 2, 5, 3},
        -- Drustvar Beginning
        baseTime = {
            US = 1548032400, -- 01/20/2019 17:00 UTC-8
            EU = 1548000000, -- 01/20/2019 16:00 UTC+0
            CN = 1546743600, -- 01/06/2019 11:00 UTC+8
        },
    },
    {
        title = "军团突袭",
        interval = 66600,
        duration = 21600,
        maps = {630, 641, 650, 634},
        -- timeTable = {4, 3, 2, 1, 4, 2, 3, 1, 2, 4, 1, 3},
        -- Stormheim Beginning then Highmountain
        baseTime = {
            US = 1547614800, -- 01/15/2019 21:00 UTC-8
            EU = 1547586000, -- 01/15/2019 21:00 UTC+0
            CN = 1546844400, -- 01/07/2019 15:00 UTC+8
        },
    }
}

local function expectSecondsToTime(second)
    local hour = second / 60 / 60
    local day = floor(hour / 24)
    hour = hour - day * 24
    if day > 0 then
        return format("%d 天 %d 小时", day, hour)
    else
        return format("%d 小时", hour)
    end
end

-- Fallback
local mapAreaPoiIDs = {
    [630] = 5175,
    [641] = 5210,
    [650] = 5177,
    [634] = 5178,
    [862] = 5973,
    [863] = 5969,
    [864] = 5970,
    [896] = 5964,
    [942] = 5966,
    [895] = 5896,
}

local function GetInvasionInfo(mapID)
    local areaPoiID = mapAreaPoiIDs[mapID]
    local seconds = C_AreaPoiInfo_GetAreaPOISecondsLeft(areaPoiID)
    local mapInfo = C_Map_GetMapInfo(mapID)
    return seconds, mapInfo.name
end

local function CheckInvasion(index)
    for _, mapID in pairs(invIndex[index].maps) do
        local timeLeft, name = GetInvasionInfo(mapID)
        if timeLeft and timeLeft > 0 then
            return timeLeft, name
        end
    end
end

local function GetCurrentInvasion(index)
    local inv = invIndex[index]
    local currentTime = time()
    local baseTime = inv.baseTime[region]
    local duration = inv.duration
    local interval = inv.interval
    local elapsed = (currentTime - baseTime) % interval
    if elapsed < duration then
        if inv.timeTable then
            local count = #inv.timeTable
            local round = (floor((currentTime - baseTime) / interval) + 1) % count
            if round == 0 then round = count end
            return duration - elapsed, C_Map_GetMapInfo(inv.maps[inv.timeTable[round]]).name
        else
            -- unknown order
            local timeLeft, name = CheckInvasion(index)
            if timeLeft then
                -- found POI on map
                return timeLeft, name
            else
                -- fallback
                return duration - elapsed, UNKNOWN
            end
        end
    end
end

local function GetFutureInvasion(index, length)
    if not length then length = 1 end
    local tbl = {}
    local inv = invIndex[index]
    local currentTime = time()
    local baseTime = inv.baseTime[region]
    local interval = inv.interval
    local elapsed = (currentTime - baseTime) % interval
    local nextTime = interval - elapsed + currentTime
    if not inv.timeTable then
        for _ = 1, length do
            tinsert(tbl, {nextTime, ''})
            nextTime = nextTime + interval
        end
    else
        local count = #inv.timeTable
        local round = (floor((nextTime - baseTime) / interval) + 1) % count
        for _ = 1, length do
            if round == 0 then round = count end
            tinsert(tbl, {nextTime, C_Map_GetMapInfo(inv.maps[inv.timeTable[round]]).name})
            nextTime = nextTime + interval
            round = (round + 1) % count
        end
    end
    return tbl
end

local warfronts = {
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
}

local tormentors = {
    timeTable = {1, 6, 15, 4, 7, 11, 3, 10, 12, 5, 9, 13, 2, 8, 14},
    interval = 7200,
    baseTime = {
        CN = 1626786000, -- 07/20/2021 21:00 UTC+8
    },
}

local function GetCurrentTormentor()
    local currentTime = time()
    local baseTime = tormentors.baseTime[region]
    local interval = tormentors.interval
    local elapsed = (currentTime - baseTime) % interval
    local lastTime = currentTime - elapsed
    local count = #tormentors.timeTable
    local round = (floor((currentTime - baseTime) / interval) + 1) % count
    if round == 0 then round = count end

    local criteriaString, _, completed = GetAchievementCriteriaInfo(15054, tormentors.timeTable[round])
    return lastTime, criteriaString, completed
end

local function GetFutureTormentor(length)
    local tbl = {}
    local currentTime = time()
    local baseTime = tormentors.baseTime[region]
    local interval = tormentors.interval
    local elapsed = (currentTime - baseTime) % interval
    local nextTime = interval - elapsed + currentTime
    local count = #tormentors.timeTable
    local round = (floor((nextTime - baseTime) / interval) + 1) % count
    for _ = 1, length do
        if round == 0 then round = count end

        local criteriaString, _, completed = GetAchievementCriteriaInfo(15054, tormentors.timeTable[round])
        tinsert(tbl, {nextTime, criteriaString, completed})
        nextTime = nextTime + interval
        round = (round + 1) % count
    end
    return tbl
end

local function OnEvent(self)
    self.text:SetText("入侵与战争前线")
end

local function OnEnter(self)
    DT:SetupTooltip(self)

    DT.tooltip:AddLine("托加斯特的折磨者")
    if tormentors.baseTime[region] then
        -- baseTime provided
        local lastTime, name, completed = GetCurrentTormentor()
        DT.tooltip:AddDoubleLine(
            "当前: " .. WrapTextInColorCode(name, completed and 'ffffffff' or 'ffff2020'),
            date("%m/%d %H:%M", lastTime), 1, 1, 1, 1, 1, 1
        )

        local futureTable = GetFutureTormentor(15)
        for i = 1, #futureTable do
            local nextTime, name, completed = unpack(futureTable[i])
            if i < 3 or not completed then
                DT.tooltip:AddDoubleLine(
                    "下次: " .. WrapTextInColorCode(name, completed and 'ffffffff' or 'ffff2020'),
                    date("%m/%d %H:%M", nextTime), 1, 1, 1, 1, 1, 1
                )
            end
        end
    else
        DT.tooltip:AddLine("Missing tormentor info on your realm.")
    end

    DT.tooltip:AddLine("战争前线")
    for _, tbl in pairs(warfronts) do
        local contributionID = tbl[faction]
        local contributionName = C_ContributionCollector_GetName(contributionID)
        local state, stateAmount, timeOfNextStateChange = C_ContributionCollector_GetState(contributionID)
        local stateName = C_ContributionCollector_GetContributionAppearance(contributionID, state).stateName
        if state == 4 then
            -- captured
            state, stateAmount, timeOfNextStateChange = C_ContributionCollector_GetState(tbl[oppositeFaction])
            stateName = format("%s (%s)", stateName, C_ContributionCollector_GetContributionAppearance(contributionID, state).stateName)
        end
        if state == 2 and timeOfNextStateChange then
            -- attacking
            -- rest time available
            DT.tooltip:AddDoubleLine(contributionName, SecondsToTime(timeOfNextStateChange - time()), 1, 210 / 255, 0, 1, 1, 1)
            DT.tooltip:AddDoubleLine(stateName, date("%m/%d %H:%M", timeOfNextStateChange), 1, 1, 1, 1, 1, 1)
        elseif state == 2 then
            -- rest time not available
            local expectTime = 7 * 24 * 60 * 60 -- 7 days
            DT.tooltip:AddDoubleLine(contributionName, "100%", 1, 210 / 255, 0, 1, 1, 1)
            DT.tooltip:AddDoubleLine(stateName, date("~ %m/%d %H:00", expectTime + time()), 1, 1, 1, 1, 1, 1)
        elseif stateAmount then
            -- contributing
            -- contribute amount available
            local expectTime = (1 - stateAmount) * 7 * 24 * 60 * 60 -- 7 days
            DT.tooltip:AddDoubleLine(contributionName, format("%.2f%% (%s)", stateAmount * 100, expectSecondsToTime(expectTime, true)), 1, 210 / 255, 0, 1, 1, 1)
            DT.tooltip:AddDoubleLine(stateName, date("~ %m/%d %H:00", expectTime + time()), 1, 1, 1, 1, 1, 1)
        else
            -- contribute amount not available
            DT.tooltip:AddDoubleLine(contributionName, stateName, 1, 210 / 255, 0, 1, 1, 1)
        end
    end

    for index, value in ipairs(invIndex) do
        DT.tooltip:AddLine(value.title)
        if value.baseTime[region] then
            -- baseTime provided
            local timeLeft, zoneName = GetCurrentInvasion(index)
            if timeLeft then
                timeLeft = timeLeft / 60
                DT.tooltip:AddDoubleLine("当前: " .. zoneName, format("%dh %.2dm", timeLeft / 60, timeLeft % 60), 1, 1, 1, 0, 1, 0)
            end
            local futureTable = GetFutureInvasion(index, 2)
            for i = 1, #futureTable do
                local nextTime, zoneName = unpack(futureTable[i])
                DT.tooltip:AddDoubleLine("下次: " .. zoneName, date("%m/%d %H:%M", nextTime), 1, 1, 1, 1, 1, 1)
            end
        else
            local timeLeft, zoneName = CheckInvasion(index)
            if timeLeft then
                timeLeft = timeLeft / 60
                DT.tooltip:AddDoubleLine("当前: " .. zoneName, format("%dh %.2dm", timeLeft / 60, timeLeft % 60), 1, 1, 1, 0, 1, 0)
            else
                DT.tooltip:AddLine("Missing invasion info on your realm.")
            end
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
DT:RegisterDatatext('RhythmBox_Invasion_and_Warfront', nil, { 'PLAYER_ENTERING_WORLD' }, OnEvent, nil, nil, OnEnter, nil, "入侵与战争前线")
