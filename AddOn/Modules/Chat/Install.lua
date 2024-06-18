local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')
local CH = E:GetModule('Chat')

-- Lua functions
local _G = _G
local ipairs, tinsert = ipairs, tinsert

-- WoW API / Variables
local ChangeChatColor = ChangeChatColor
local ChatFrame_AddChannel = ChatFrame_AddChannel
local ChatFrame_AddMessageGroup = ChatFrame_AddMessageGroup
local ChatFrame_RemoveAllMessageGroups = ChatFrame_RemoveAllMessageGroups
local CombatConfig_SetCombatFiltersToDefault = CombatConfig_SetCombatFiltersToDefault
local FCF_DockFrame = FCF_DockFrame
local FCF_OpenNewWindow = FCF_OpenNewWindow
local FCF_ResetChatWindows = FCF_ResetChatWindows
local FCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local FCF_SetLocked = FCF_SetLocked
local FCF_SetWindowName = FCF_SetWindowName
local FCF_StopDragging = FCF_StopDragging
local FCF_UnDockFrame = FCF_UnDockFrame
local ToggleChatColorNamesByClassGroup = ToggleChatColorNamesByClassGroup
local VoiceTranscriptionFrame_UpdateEditBox = VoiceTranscriptionFrame_UpdateEditBox
local VoiceTranscriptionFrame_UpdateVisibility = VoiceTranscriptionFrame_UpdateVisibility
local VoiceTranscriptionFrame_UpdateVoiceTab = VoiceTranscriptionFrame_UpdateVoiceTab

local GENERAL = GENERAL
local GROUPS = GROUPS
local GUILD = GUILD
local GUILD_EVENT_LOG = GUILD_EVENT_LOG
local NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS

function C:InstallChat()
    CombatConfig_SetCombatFiltersToDefault()
    for i = 1, 2 do
        _G.Blizzard_CombatLog_Filters.filters[i].settings.timestamp = true
        _G.Blizzard_CombatLog_Filters.filters[i].settings.braces = true
        _G.Blizzard_CombatLog_Filters.filters[i].settings.spellBraces = true
    end

    FCF_ResetChatWindows()

    FCF_SetLocked(_G.ChatFrame1, 1)
    FCF_DockFrame(_G.ChatFrame2)
    FCF_SetLocked(_G.ChatFrame2, 1)
    FCF_DockFrame(_G.ChatFrame3)
    FCF_SetLocked(_G.ChatFrame3, 1)

    FCF_OpenNewWindow(GUILD)
    FCF_UnDockFrame(_G.ChatFrame4)
    FCF_SetLocked(_G.ChatFrame4, 1)
    _G.ChatFrame4:Show()

    FCF_OpenNewWindow(GROUPS)
    FCF_UnDockFrame(_G.ChatFrame5)
    FCF_SetLocked(_G.ChatFrame5, 1)
    _G.ChatFrame5:Show()

    FCF_OpenNewWindow("PM")
    FCF_UnDockFrame(_G.ChatFrame6)
    FCF_SetLocked(_G.ChatFrame6, 1)
    _G.ChatFrame6:Show()

    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G['ChatFrame' .. i]

        CH:FCFTab_UpdateColors(CH:GetTab(frame))

        if i == 4 or i == 5 or i == 6 then
            FCF_UnDockFrame(frame)
            frame:ClearAllPoints()
            frame:SetPoint('BOTTOMLEFT', _G.LeftChatToggleButton, 'TOPLEFT', 1, 3)
            FCF_DockFrame(frame)
            FCF_SetLocked(frame, 1)
            frame:Show()
        elseif i == 3 then
            VoiceTranscriptionFrame_UpdateVisibility(frame)
            VoiceTranscriptionFrame_UpdateVoiceTab(frame)
            VoiceTranscriptionFrame_UpdateEditBox(frame)
        end

        FCF_SavePositionAndDimensions(frame)
        FCF_StopDragging(frame)

        -- set default Elvui font size
        FCF_SetChatWindowFontSize(nil, frame, 12)

        if i == 1 then
            FCF_SetWindowName(frame, GENERAL)
        elseif i == 2 then
            FCF_SetWindowName(frame, GUILD_EVENT_LOG)
        elseif i == 4 then
            FCF_SetWindowName(frame, GUILD)
        elseif i == 5 then
            FCF_SetWindowName(frame, GROUPS)
        elseif i == 6 then
            FCF_SetWindowName(frame, "PM")
        end
    end

    local chatGroup = { 'SYSTEM', 'CHANNEL', 'SAY', 'EMOTE', 'YELL', 'WHISPER', 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER', 'GUILD', 'OFFICER', 'MONSTER_SAY', 'MONSTER_YELL', 'MONSTER_EMOTE', 'MONSTER_WHISPER', 'MONSTER_BOSS_EMOTE', 'MONSTER_BOSS_WHISPER', 'ERRORS', 'AFK', 'DND', 'IGNORED', 'BG_HORDE', 'BG_ALLIANCE', 'BG_NEUTRAL', 'ACHIEVEMENT', 'GUILD_ACHIEVEMENT', 'BN_WHISPER', 'BN_INLINE_TOAST_ALERT', 'COMBAT_XP_GAIN', 'COMBAT_HONOR_GAIN', 'COMBAT_FACTION_CHANGE', 'SKILL', 'LOOT', 'CURRENCY', 'MONEY', 'PING' }
    ChatFrame_RemoveAllMessageGroups(_G.ChatFrame1)
    for _, v in ipairs(chatGroup) do
        ChatFrame_AddMessageGroup(_G.ChatFrame1, v)
    end

    chatGroup = { 'GUILD', 'OFFICER', 'GUILD_ACHIEVEMENT', 'GUILD_ITEM_LOOTED' }
    ChatFrame_RemoveAllMessageGroups(_G.ChatFrame4)
    for _, v in ipairs(chatGroup) do
        ChatFrame_AddMessageGroup(_G.ChatFrame4, v)
    end

    chatGroup = { 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER' }
    ChatFrame_RemoveAllMessageGroups(_G.ChatFrame5)
    for _, v in ipairs(chatGroup) do
        ChatFrame_AddMessageGroup(_G.ChatFrame5, v)
    end

    chatGroup = { 'WHISPER', 'BN_WHISPER' }
    ChatFrame_RemoveAllMessageGroups(_G.ChatFrame6)
    for _, v in ipairs(chatGroup) do
        ChatFrame_AddMessageGroup(_G.ChatFrame6, v)
    end

    ChatFrame_AddChannel(_G.ChatFrame1, GENERAL)

    -- set the chat groups names in class color to enabled for all chat groups which players names appear
    chatGroup = { 'SAY', 'EMOTE', 'YELL', 'WHISPER', 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER', 'GUILD', 'OFFICER', 'ACHIEVEMENT', 'GUILD_ACHIEVEMENT', 'COMMUNITIES_CHANNEL' }
    for i = 1, _G.MAX_WOW_CHAT_CHANNELS do
        tinsert(chatGroup, 'CHANNEL' .. i)
    end
    for _, v in ipairs(chatGroup) do
        ToggleChatColorNamesByClassGroup(true, v)
    end

    -- Adjust Chat Colors
    ChangeChatColor('CHANNEL1', 195/255, 230/255, 232/255) -- General
    ChangeChatColor('CHANNEL2', 232/255, 158/255, 121/255) -- Trade
    ChangeChatColor('CHANNEL3', 232/255, 228/255, 121/255) -- Local Defense

    if E.private.chat.enable then
        E:GetModule('Chat'):PositionChats()
    end

    if E.db.RightChatPanelFaded then
        _G.RightChatToggleButton:Click()
    end

    if E.db.LeftChatPanelFaded then
        _G.LeftChatToggleButton:Click()
    end

    -- Update AD Filter
    self:ADFilter()

    R:Print("已设置聊天框。")
end
