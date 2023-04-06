local R, E, L, V, P, G = unpack((select(2, ...)))
local MP = R:GetModule('MythicPlus')

-- Lua functions
local _G = _G
local format, ipairs = format, ipairs

-- WoW API / Variables
local C_ChallengeMode_SlotKeystone = C_ChallengeMode.SlotKeystone
local C_Container_GetContainerItemID = C_Container.GetContainerItemID
local C_Container_GetContainerNumSlots = C_Container.GetContainerNumSlots
local C_Container_PickupContainerItem = C_Container.PickupContainerItem
local C_GossipInfo_CloseGossip = C_GossipInfo.CloseGossip
local C_GossipInfo_GetOptions = C_GossipInfo.GetOptions
local C_GossipInfo_SelectOption = C_GossipInfo.SelectOption
local CursorHasItem = CursorHasItem
local UnitGUID = UnitGUID

local TooltipDataProcessor_AddTooltipPostCall = TooltipDataProcessor.AddTooltipPostCall

local BACKPACK_CONTAINER = BACKPACK_CONTAINER
local Enum_TooltipDataType_Unit = Enum.TooltipDataType.Unit
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

    -- Expection
    if self.currentRun.mapID then
        local npcID = R:ParseNPCID(UnitGUID('npc'))

        if npcID == 198927 then return end -- Temporal Attendant
        if self.currentRun.mapID == 376 and npcID == 166663 then return end -- The Necrotic Wake / Steward
        if self.currentRun.mapID == 401 and npcID == 197081 then return end -- The Azure Vault / Sindragosa
    end

    -- Court of Stars / Spy Exploit
    C_GossipInfo_SelectOption(109818)

    local options = C_GossipInfo_GetOptions()
    for _, option in ipairs(options) do
        if option.icon == 132053 then
            local popupWasShown = self:IsStaticPopupShown()
            C_GossipInfo_SelectOption(option.gossipOptionID)
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

local function TooltipAddProgress(tooltip)
    if tooltip ~= _G.GameTooltip then return end

    if not _G.MDT or not MP.currentRun or not MP.currentRun.inProgress then return end

    local npcID = R:ParseNPCID(UnitGUID('mouseover'))
    if not npcID then return end

    local count, total, totalTeeming, countTeeming = _G.MDT:GetEnemyForces(npcID)
    if not count then return end

    if MP.currentRun.isTeeming then
        tooltip:AppendText(format(" (%.2f%% - %d)", countTeeming / totalTeeming * 100, countTeeming))
    else
        tooltip:AppendText(format(" (%.2f%% - %d)", count / total * 100, count))
    end
end

function MP:BuildUtility()
    self:RegisterEvent('CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN')
    self:RegisterEvent('GOSSIP_SHOW')

    self:SecureHook(_G.ObjectiveTrackerFrame, 'Show', 'TrackerOnShow')
    self:RegisterSignal('CHALLENGE_MODE_START', 'LockHideTracker')
    self:RegisterSignal('CHALLENGE_MODE_LEAVE', 'UnlockHideTracker')

    TooltipDataProcessor_AddTooltipPostCall(Enum_TooltipDataType_Unit, TooltipAddProgress)
end
