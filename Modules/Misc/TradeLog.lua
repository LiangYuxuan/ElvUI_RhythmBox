local R, E, L, V, P, G = unpack((select(2, ...)))
local TL = R:NewModule('TradeLog', 'AceEvent-3.0')

-- Lua functions
local format, ipairs, select, strlen, strmatch, tinsert, type = format, ipairs, select, strlen, strmatch, tinsert, type
local table_concat = table.concat

-- WoW API / Variables
local CheckInteractDistance = CheckInteractDistance
local GetPlayerTradeMoney = GetPlayerTradeMoney
local GetTargetTradeMoney = GetTargetTradeMoney
local GetTradePlayerItemInfo = GetTradePlayerItemInfo
local GetTradePlayerItemLink = GetTradePlayerItemLink
local GetTradeTargetItemInfo = GetTradeTargetItemInfo
local GetTradeTargetItemLink = GetTradeTargetItemLink
local SendChatMessage = SendChatMessage
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitName = UnitName

local WrapTextInColorCode = WrapTextInColorCode
local ERR_TRADE_BAG_FULL = ERR_TRADE_BAG_FULL
local ERR_TRADE_CANCELLED = ERR_TRADE_CANCELLED
local ERR_TRADE_COMPLETE = ERR_TRADE_COMPLETE
local ERR_TRADE_MAX_COUNT_EXCEEDED = ERR_TRADE_MAX_COUNT_EXCEEDED
local ERR_TRADE_TARGET_BAG_FULL = ERR_TRADE_TARGET_BAG_FULL
local ERR_TRADE_TARGET_DEAD = ERR_TRADE_TARGET_DEAD
local ERR_TRADE_TARGET_MAX_COUNT_EXCEEDED = ERR_TRADE_TARGET_MAX_COUNT_EXCEEDED
local ERR_TRADE_TOO_FAR = ERR_TRADE_TOO_FAR
local MAX_TRADABLE_ITEMS = MAX_TRADABLE_ITEMS
local TRADE_ENCHANT_SLOT = TRADE_ENCHANT_SLOT

local patternCountExceeded = gsub(ERR_TRADE_TARGET_MAX_LIMIT_CATEGORY_COUNT_EXCEEDED_IS, '%%[ds]', '(.+)')

function TL:GetTradeList(unit)
    local result = {}

    if self.trade[unit .. 'Money'] > 0 then
        tinsert(result, {
            E:FormatMoney(self.trade[unit .. 'Money']),
            E:FormatMoney(self.trade[unit .. 'Money'], nil, true)
        })
    end

    local items = self.trade[unit .. 'Items']
    for index = 1, MAX_TRADABLE_ITEMS do
        if items[index] then
            if items[index].numItems > 1 then
                tinsert(result, items[index].itemLink .. 'x' .. items[index].numItems)
            else
                tinsert(result, items[index].itemLink)
            end
        end
    end

    -- we cross put TRADE_ENCHANT_SLOT in :TRADE_ACCEPT_UPDATE, use this slot directly
    if items[TRADE_ENCHANT_SLOT] and items[TRADE_ENCHANT_SLOT].enchantment then
        tinsert(result, items[TRADE_ENCHANT_SLOT].enchantment)
    end

    return result
end

function TL:GuessFailReason()
    if self.trade.reason then
        return self.trade.reason
    end

    local events = self.trade.events
    local length = #events
    local result

    if length >= 3 then
        if events[length] == 'TRADE_REQUEST_CANCEL' then
            if events[length - 1] == 'TRADE_CLOSED' then
                if events[length - 2] == 'TRADE_CLOSED' then
                    -- TRADE_REQUEST_CANCEL <- TRADE_CLOSED <- TRADE_CLOSED
                    result = "我取消了交易"
                elseif events[length - 2] == 'TRADE_SHOW' then
                    -- TRADE_REQUEST_CANCEL <- TRADE_CLOSED <- TRADE_SHOW
                    result = "我超出了距离"
                end
            elseif events[length - 1] == 'TRADE_SHOW' and events[length - 2] == 'TRADE_CLOSED' then
                -- TRADE_REQUEST_CANCEL <- TRADE_SHOW <- TRADE_CLOSED
                result = "我隐藏了界面，交易窗口关闭"
            end
        elseif
            events[length] == 'TRADE_CLOSED' and
            events[length - 1] == 'TRADE_CLOSED' and events[length - 2] == 'TRADE_REQUEST_CANCEL'
        then
            if self.trade.tooFar then
                result = "双方距离过远"
            else
                result = "对方取消了交易"
            end
        end
    end

    self.trade.reason = result or "未知原因"
end

function TL:CompleteTrade()
    if not self.trade.reason then
        self:GuessFailReason()
    end

    local output, richOutput
    if not self.trade.target then
        output = format("交易失败：%s。", self.trade.reason)
        richOutput = output
    else
        local classColor = E:ClassColor(self.trade.targetClass)
        local targetLink = format("|Hplayer:%s|h[%s]|h", self.trade.target, WrapTextInColorCode(self.trade.target, classColor.colorStr) or self.trade.target)
        if self.trade.isError then
            output = format("与%s交易失败：%s。", self.trade.target, self.trade.reason)
            richOutput = format("与%s交易失败：%s。", targetLink, self.trade.reason)
        elseif self.trade.isCancelled then
            output = format("与%s交易取消：%s。", self.trade.target, self.trade.reason)
            richOutput = format("与%s交易取消：%s。", targetLink, self.trade.reason)
        else -- completed
            output = format("与%s交易完成：", self.trade.target)
            richOutput = format("与%s交易完成：", targetLink)

            local playerList = self:GetTradeList('player')
            local targetList = self:GetTradeList('target')

            if #playerList == 0 and #targetList == 0 then
                output = output .. "没有做任何交换。"
                richOutput = richOutput .. "没有做任何交换。"
            else
                output = output
                richOutput = {richOutput}

                local header = true
                if #playerList > 0 then
                    output = output .. "（交出）"
                    richOutput[#richOutput] = richOutput[#richOutput] .. "（交出）"
                    if type(playerList[1]) == 'table' then
                        output = output .. playerList[1][2]
                        playerList[1] = playerList[1][1]
                    end
                    output = output .. table_concat(playerList, ',', 2)
                    for _, line in ipairs(playerList) do
                        local pending = richOutput[#richOutput] .. (header and '' or ',') .. line
                        header = nil
                        if strlen(pending) > 255 then
                            richOutput[#richOutput + 1] = "（交出）" .. line
                        else
                            richOutput[#richOutput] = pending
                        end
                    end
                end

                if #targetList > 0 then
                    output = output .. "（收到）"
                    richOutput[#richOutput] = richOutput[#richOutput] .. "（收到）"
                    if type(targetList[1]) == 'table' then
                        output = output .. targetList[1][2]
                        targetList[1] = targetList[1][1]
                    end
                    output = output .. table_concat(targetList, ',', 2)
                    for _, line in ipairs(targetList) do
                        local pending = richOutput[#richOutput] .. (header and '' or ',') .. line
                        header = nil
                        if strlen(pending) > 255 then
                            richOutput[#richOutput + 1] = "（收到）" .. line
                        else
                            richOutput[#richOutput] = pending
                        end
                    end
                end
            end
        end
    end

    if type(richOutput) == 'string' then
        R:Print(richOutput)
    else
        for line = 1, #richOutput do
            R:Print(richOutput[line])
        end
    end
    if self.trade.target and E.db.RhythmBox.Misc.TradeLogWhisper then
        SendChatMessage(output, 'WHISPER', nil, self.trade.target)
    end
    self:ResetTrade()
end

function TL:ResetTrade()
    self.trade = {
        playerItems = {},
        targetItems = {},
        events = {},
    }
end

function TL:RecordEvent(event)
    tinsert(self.trade.events, event)
end

function TL:UI_ERROR_MESSAGE(_, _, message)
    if message == ERR_TRADE_TARGET_DEAD or message ==  ERR_TRADE_TOO_FAR then
        R:Print(message)
    elseif
        message == ERR_TRADE_BAG_FULL or message == ERR_TRADE_MAX_COUNT_EXCEEDED or
        message == ERR_TRADE_TARGET_BAG_FULL or message == ERR_TRADE_TARGET_MAX_COUNT_EXCEEDED or
        strmatch(message, patternCountExceeded)
    then
        self.trade.isError = true
        self.trade.reason = message
        self:CompleteTrade()
    end
end

function TL:UI_INFO_MESSAGE(_, _, message)
    if message == ERR_TRADE_CANCELLED or message == ERR_TRADE_COMPLETE then
        self.trade.isCancelled = (message == ERR_TRADE_CANCELLED)
        self:CompleteTrade()
    end
end

function TL:TRADE_REQUEST_CANCEL()
    self.tooFar = UnitExists('npc') and not CheckInteractDistance('npc', 2)
    self:RecordEvent('TRADE_REQUEST_CANCEL')
end

function TL:TRADE_SHOW()
    local name, realm = UnitName('npc')
    if realm and realm ~= '' and realm ~= E.myrealm then
        name = name .. '-' .. realm
    end

    self.trade.target = name
    self.trade.targetClass = select(2, UnitClass('npc'))
    self:RecordEvent('TRADE_SHOW')
end

function TL:TRADE_ACCEPT_UPDATE()
    local _, name, numItems, itemLink, enchantment
    for index = 1, MAX_TRADABLE_ITEMS do
        -- update player side
        name, _, numItems = GetTradePlayerItemInfo(index)
        if name then
            itemLink = GetTradePlayerItemLink(index)
            self.trade.playerItems[index] = {
                name = name,
                numItems = numItems,
                itemLink = itemLink,
            }
        end

        -- update target side
        name, _, numItems = GetTradeTargetItemInfo(index)
        if name then
            itemLink = GetTradeTargetItemLink(index)
            self.trade.targetItems[index] = {
                name = name,
                numItems = numItems,
                itemLink = itemLink,
            }
        end
    end

    name, _, _, _, enchantment = GetTradePlayerItemInfo(TRADE_ENCHANT_SLOT)
    if name then
        itemLink = GetTradePlayerItemLink(TRADE_ENCHANT_SLOT)
        -- store this in target items, this is not traded
        self.trade.targetItems[TRADE_ENCHANT_SLOT] = {
            name = name,
            enchantment = enchantment,
            itemLink = itemLink,
        }
    end

    name, _, _, _, _, enchantment = GetTradeTargetItemInfo(TRADE_ENCHANT_SLOT)
    if name then
        itemLink = GetTradeTargetItemLink(TRADE_ENCHANT_SLOT)
        -- store this in player items, this is not traded
        self.trade.playerItems[TRADE_ENCHANT_SLOT] = {
            name = name,
            enchantment = enchantment,
            itemLink = itemLink,
        }
    end

    self.trade.playerMoney = GetPlayerTradeMoney()
    self.trade.targetMoney = GetTargetTradeMoney()
end

function TL:Initialize()
    self:ResetTrade()

    if E.db.RhythmBox.Misc.TradeLog then
        -- just update item when accepting trade
        -- don't register event TRADE_PLAYER_ITEM_CHANGED and TRADE_TARGET_ITEM_CHANGED
        self:RegisterEvent('TRADE_ACCEPT_UPDATE')

        self:RegisterEvent('TRADE_SHOW')
        self:RegisterEvent('TRADE_REQUEST_CANCEL')
        self:RegisterEvent('TRADE_CLOSED', 'RecordEvent')
        self:RegisterEvent('UI_INFO_MESSAGE')
        self:RegisterEvent('UI_ERROR_MESSAGE')
    else
        self:UnregisterAllEvents()
    end
end

R:RegisterModule(TL:GetName())
