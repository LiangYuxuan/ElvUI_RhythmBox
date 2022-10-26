local R, E, L, V, P, G = unpack(select(2, ...))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G
local format = format

-- WoW API / Variables
local C_ChallengeMode_SlotKeystone = C_ChallengeMode.SlotKeystone
local C_Container_GetContainerItemID = R.DragonflightBeta and C_Container.GetContainerItemID or _G.GetContainerItemID
local C_Container_GetContainerNumSlots = R.DragonflightBeta and C_Container.GetContainerNumSlots or _G.GetContainerNumSlots
local C_Container_PickupContainerItem = R.DragonflightBeta and C_Container.PickupContainerItem or _G.PickupContainerItem
local C_GossipInfo_CloseGossip = C_GossipInfo.CloseGossip
local C_GossipInfo_GetOptions = C_GossipInfo.GetOptions
local C_GossipInfo_SelectOption = C_GossipInfo.SelectOption
local CursorHasItem = CursorHasItem
local UnitGUID = UnitGUID

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
		local numSlot = C_Container_GetContainerNumSlots(bagID)
		for slotID = 1, numSlot do
            local itemID = C_Container_GetContainerItemID(bagID, slotID)
            if itemID and self.keystoneItemIDs[itemID] then
                C_Container_PickupContainerItem(bagID, slotID)
                if CursorHasItem() then
                    C_ChallengeMode_SlotKeystone()
                end
            end
        end
    end
end

function MP:GOSSIP_SHOW()
    if not self.currentRun or not self.currentRun.inProgress then return end

    -- Expection: Don't auto gossip in NW with Steward
    if self.currentRun.mapID and self.currentRun.mapID == 376 then -- The Necrotic Wake
        local npcID = R:ParseNPCID(UnitGUID('npc'))
        if npcID == 166663 then return end -- Steward
    end

    local options = C_GossipInfo_GetOptions()
    for index, option in ipairs(options) do
        if option.type == 'gossip' then
            local popupWasShown = self:IsStaticPopupShown()
            C_GossipInfo_SelectOption(index)
            local popupIsShown = self:IsStaticPopupShown()
            if popupIsShown and not popupWasShown then
                _G.StaticPopup1Button1:Click()
                C_GossipInfo_CloseGossip()
            elseif not popupIsShown then
                C_GossipInfo_CloseGossip()
            end
            return
        end
    end
end

function MP:AddProgress()
    if not _G.MDT or not self.currentRun or not self.currentRun.inProgress then return end

    local npcID = R:ParseNPCID(UnitGUID('mouseover'))
    if not npcID then return end

    local count, total, totalTeeming, countTeeming = _G.MDT:GetEnemyForces(npcID)
    if not count then return end

    -- TODO: maybe check before append
    if self.currentRun.isTeeming then
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

    if R.DragonflightBeta then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(...)
            MP:AddProgress(...)
        end)
    else
        self:SecureHookScript(_G.GameTooltip, 'OnTooltipSetUnit', 'AddProgress')
    end

    self:SecureHook(_G.ObjectiveTrackerFrame, 'Show', 'TrackerOnShow')
    self:RegisterSignal('CHALLENGE_MODE_START', 'LockHideTracker')
    self:RegisterSignal('CHALLENGE_MODE_LEAVE', 'UnlockHideTracker')
end
