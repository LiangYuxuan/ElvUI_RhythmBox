local R, E, L, V, P, G = unpack((select(2, ...)))
local C = R:GetModule('Chat')
local CH = E:GetModule('Chat')

-- Lua functions
local _G = _G
local ipairs, tinsert = ipairs, tinsert

-- WoW API / Variables
local ChangeChatColor = ChangeChatColor
local JoinPermanentChannel = JoinPermanentChannel

local CombatConfig_SetCombatFiltersToDefault = CombatConfig_SetCombatFiltersToDefault
local FCF_DockFrame = FCF_DockFrame
local FCF_OpenNewWindow = FCF_OpenNewWindow
local FCF_ResetChatWindow = FCF_ResetChatWindow
local FCF_ResetChatWindows = FCF_ResetChatWindows
local FCF_SavePositionAndDimensions = FCF_SavePositionAndDimensions
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local FCF_SetWindowName = FCF_SetWindowName
local FCF_StopDragging = FCF_StopDragging
local ToggleChatColorNamesByClassGroup = ToggleChatColorNamesByClassGroup
local VoiceTranscriptionFrame_UpdateEditBox = VoiceTranscriptionFrame_UpdateEditBox
local VoiceTranscriptionFrame_UpdateVisibility = VoiceTranscriptionFrame_UpdateVisibility
local VoiceTranscriptionFrame_UpdateVoiceTab = VoiceTranscriptionFrame_UpdateVoiceTab

local GENERAL = GENERAL
local GROUPS = GROUPS
local GUILD = GUILD
local GUILD_EVENT_LOG = GUILD_EVENT_LOG
local VOICE = VOICE

function C:InstallChat()
    CombatConfig_SetCombatFiltersToDefault()
    for i = 1, #_G.Blizzard_CombatLog_Filters.filters do
        _G.Blizzard_CombatLog_Filters.filters[i].settings.timestamp = true
        _G.Blizzard_CombatLog_Filters.filters[i].settings.braces = true
        _G.Blizzard_CombatLog_Filters.filters[i].settings.spellBraces = true
    end

    local chatFrames = _G.CHAT_FRAMES
    FCF_ResetChatWindows()

    -- force initialize the tts chat (it doesn't get shown unless you use it)
    local voiceChat = _G[chatFrames[3]]
    FCF_ResetChatWindow(voiceChat, VOICE)
    FCF_DockFrame(voiceChat, 3)

    local guildChat = FCF_OpenNewWindow(GUILD)
    FCF_DockFrame(guildChat)

    local groupChat = FCF_OpenNewWindow(GROUPS)
    FCF_DockFrame(groupChat)

    local pmChat = FCF_OpenNewWindow("PM")
    FCF_DockFrame(pmChat)

    for id, frameName in ipairs(chatFrames) do
        local frame = _G[frameName]

        if E.private.chat.enable then
            CH:FCFTab_UpdateColors(CH:GetTab(frame))
        end

        if id == 1 then
            frame:ClearAllPoints()
            frame:Point('BOTTOMLEFT', _G.LeftChatToggleButton, 'TOPLEFT', 1, 3)
            FCF_SetWindowName(frame, GENERAL)
        elseif id == 2 then
            FCF_SetWindowName(frame, GUILD_EVENT_LOG)
        elseif id == 3 then
            VoiceTranscriptionFrame_UpdateVisibility(frame)
            VoiceTranscriptionFrame_UpdateVoiceTab(frame)
            VoiceTranscriptionFrame_UpdateEditBox(frame)
        elseif id == 4 then
            FCF_SetWindowName(frame, GUILD)
        elseif id == 5 then
            FCF_SetWindowName(frame, GROUPS)
        elseif id == 6 then
            FCF_SetWindowName(frame, "PM")
        end

        FCF_SetChatWindowFontSize(nil, frame, 12)
        FCF_SavePositionAndDimensions(frame)
        FCF_StopDragging(frame)
    end

    local chatGroup = { 'SYSTEM', 'CHANNEL', 'SAY', 'EMOTE', 'YELL', 'WHISPER', 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER', 'GUILD', 'OFFICER', 'MONSTER_SAY', 'MONSTER_YELL', 'MONSTER_EMOTE', 'MONSTER_WHISPER', 'MONSTER_BOSS_EMOTE', 'MONSTER_BOSS_WHISPER', 'ERRORS', 'AFK', 'DND', 'IGNORED', 'BG_HORDE', 'BG_ALLIANCE', 'BG_NEUTRAL', 'ACHIEVEMENT', 'GUILD_ACHIEVEMENT', 'BN_WHISPER', 'BN_INLINE_TOAST_ALERT', 'COMBAT_XP_GAIN', 'COMBAT_HONOR_GAIN', 'COMBAT_FACTION_CHANGE', 'SKILL', 'LOOT', 'CURRENCY', 'MONEY', 'PING' }
    _G.ChatFrame1:RemoveAllMessageGroups()
    for _, v in ipairs(chatGroup) do
        _G.ChatFrame1:AddMessageGroup(v)
    end

    chatGroup = { 'GUILD', 'OFFICER', 'GUILD_ACHIEVEMENT', 'GUILD_ITEM_LOOTED' }
    guildChat:RemoveAllMessageGroups()
    for _, v in ipairs(chatGroup) do
        guildChat:AddMessageGroup(v)
    end

    chatGroup = { 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER' }
    groupChat:RemoveAllMessageGroups()
    for _, v in ipairs(chatGroup) do
        groupChat:AddMessageGroup(v)
    end

    chatGroup = { 'WHISPER', 'BN_WHISPER' }
    pmChat:RemoveAllMessageGroups()
    for _, v in ipairs(chatGroup) do
        pmChat:AddMessageGroup(v)
    end

    _G.ChatFrame1:AddChannel(GENERAL)
    JoinPermanentChannel('大脚世界频道', nil, 1)
    _G.ChatFrame1:AddChannel('大脚世界频道')

    -- set the chat groups names in class color to enabled for all chat groups which players names appear
    chatGroup = { 'SAY', 'EMOTE', 'YELL', 'WHISPER', 'PARTY', 'PARTY_LEADER', 'RAID', 'RAID_LEADER', 'RAID_WARNING', 'INSTANCE_CHAT', 'INSTANCE_CHAT_LEADER', 'GUILD', 'OFFICER', 'ACHIEVEMENT', 'GUILD_ACHIEVEMENT', 'COMMUNITIES_CHANNEL' }
    for i = 1, _G.MAX_WOW_CHAT_CHANNELS do
        tinsert(chatGroup, 'CHANNEL' .. i)
    end
    for _, v in ipairs(chatGroup) do
        ToggleChatColorNamesByClassGroup(true, v)
    end

    -- Adjust Chat Colors
    ChangeChatColor('CHANNEL1', 0.76, 0.90, 0.91) -- General
    ChangeChatColor('CHANNEL2', 0.91, 0.62, 0.47) -- Trade
    ChangeChatColor('CHANNEL3', 0.91, 0.89, 0.47) -- Local Defense

    if E.private.chat.enable then
        CH:PositionChats()
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
