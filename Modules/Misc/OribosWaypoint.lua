local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local OW = R:NewModule('OribosWaypoint', 'AceEvent-3.0')

-- Lua functions

-- WoW API / Variables
local C_Map_ClearUserWaypoint = C_Map.ClearUserWaypoint
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local C_Map_GetUserWaypoint = C_Map.GetUserWaypoint
local C_Map_HasUserWaypoint = C_Map.HasUserWaypoint
local C_Map_SetUserWaypoint = C_Map.SetUserWaypoint
local C_SuperTrack_IsSuperTrackingUserWaypoint = C_SuperTrack.IsSuperTrackingUserWaypoint
local C_SuperTrack_SetSuperTrackedUserWaypoint = C_SuperTrack.SetSuperTrackedUserWaypoint

local UiMapPoint_CreateFromCoordinates = UiMapPoint.CreateFromCoordinates

function OW:Toggle()
    local uiMapID = C_Map_GetBestMapForUnit('player')

    if uiMapID == 1671 and not self.overrided then
        if C_Map_HasUserWaypoint() then
            self.oldPoint = C_Map_GetUserWaypoint()
            self.isTracked = C_SuperTrack_IsSuperTrackingUserWaypoint()
        end

        C_Map_SetUserWaypoint(self.flightMaster)
        C_SuperTrack_SetSuperTrackedUserWaypoint(true)

        self.overrided = true
    elseif self.overrided then
        C_Map_ClearUserWaypoint()

        if self.oldPoint then
            C_Map_SetUserWaypoint(self.oldPoint)
            C_SuperTrack_SetSuperTrackedUserWaypoint(self.isTracked)

            self.oldPoint = nil
            self.isTracked = nil
        end

        self.overrided = nil
    end
end

function OW:Initialize()
    self.flightMaster = UiMapPoint_CreateFromCoordinates(1550, 0.4701, 0.5113, 0)

    self:RegisterEvent('ZONE_CHANGED_NEW_AREA', 'Toggle')
    self:RegisterEvent('ZONE_CHANGED', 'Toggle')
    self:RegisterEvent('ZONE_CHANGED_INDOORS', 'Toggle')
end

R:RegisterModule(OW:GetName())
