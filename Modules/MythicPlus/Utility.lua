local R, E, L, V, P, G = unpack(select(2, ...))

if R.Classic then return end

local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G
local format, strsplit, select, tonumber = format, strsplit, select, tonumber

-- WoW API / Variables
local C_ChallengeMode_SlotKeystone = C_ChallengeMode.SlotKeystone
local CloseGossip = CloseGossip
local CursorHasItem = CursorHasItem
local GetContainerItemID = GetContainerItemID
local GetContainerNumSlots = GetContainerNumSlots
local GetGossipOptions = GetGossipOptions
local GetNumGossipOptions = GetNumGossipOptions
local PickupContainerItem = PickupContainerItem
local SelectGossipOption = SelectGossipOption
local UnitGUID = UnitGUID

local tContains = tContains

local BACKPACK_CONTAINER = BACKPACK_CONTAINER
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local STATICPOPUP_NUMDIALOGS = STATICPOPUP_NUMDIALOGS

function MP:IsStaticPopupShown()
	for index = 1, STATICPOPUP_NUMDIALOGS do
		local frame = _G['StaticPopup' .. index]
		if frame and frame:IsShown() then
			return true
		end
	end
end

function MP:CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN()
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local numSlot = GetContainerNumSlots(bagID)
		for slotID = 1, numSlot do
            local itemID = GetContainerItemID(bagID, slotID)
            if itemID and itemID == 158923 then
                PickupContainerItem(bagID, slotID)
                if CursorHasItem() then
                    C_ChallengeMode_SlotKeystone()
                end
            end
        end
    end
end

function MP:GOSSIP_SHOW()
    if not self.currentRun or not self.currentRun.inProgress then return end

    local options = {GetGossipOptions()}
    for i = 1, GetNumGossipOptions() do
        if options[i * 2] == 'gossip' then
            local popupWasShown = self:IsStaticPopupShown()
            SelectGossipOption(i)
            local popupIsShown = self:IsStaticPopupShown()
            if popupIsShown then
                if not popupWasShown then
                    _G.StaticPopup1Button1:Click()
                    CloseGossip()
                end
            else
                CloseGossip()
            end
            return
        end
    end
end

function MP:AddProgress()
    if not _G.MDT or not self.currentRun or not self.currentRun.inProgress then return end

    local unitGUID = UnitGUID('mouseover')
    if not unitGUID then return end

    local npcID = select(6, strsplit('-', unitGUID))
    npcID = npcID and tonumber(npcID)
    if not npcID then return end

    local count, total, totalTeeming, countTeeming = _G.MDT:GetEnemyForces(npcID)
    if not count then return end

    local isTeeming = tContains(self.currentRun.affixes, 5)
    if isTeeming then
        _G.GameTooltip:AppendText(format(" (%.2f%% - %d)", countTeeming / totalTeeming * 100, countTeeming))
    else
        _G.GameTooltip:AppendText(format(" (%.2f%% - %d)", count / total * 100, count))
    end
end

function MP:LockHideTracker()
    self.shouldHideTracker = true
    _G.ObjectiveTrackerFrame:Hide()
end

function MP:UnlockHideTracker()
    self.shouldHideTracker = nil
    _G.ObjectiveTrackerFrame:Show()
end

function MP:TrackerOnShow()
    if self.shouldHideTracker then
        _G.ObjectiveTrackerFrame:Hide()
    end
end

function MP:BuildUtility()
    self:RegisterEvent('CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN')
    self:RegisterEvent('GOSSIP_SHOW')

    self:SecureHookScript(_G.GameTooltip, 'OnTooltipSetUnit', 'AddProgress')

    self:SecureHook(_G.ObjectiveTrackerFrame, 'Show', 'TrackerOnShow')
    self:RegisterSignal('CHALLENGE_MODE_START', 'LockHideTracker')
    self:RegisterSignal('CHALLENGE_MODE_LEAVE', 'UnlockHideTracker')
end
