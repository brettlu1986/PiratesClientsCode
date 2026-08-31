-----------------------------------------------------
--File Name    : ChatSystemHelper.lua
--Author       : Edward J
--Create Time  : 2019-04-15
--Description  : Chat System Helper
-----------------------------------------------------
local ChatSystemHelper = {}

local SensitiveWordsSystem  = require("SensitiveWordsSystem")
-----------------------------------------------------
local ExpressionFormat          = "<img src=\"%s\"/>" 
local ExpressionResFormat       = "Spr_Face_%02d"
local ExpressionReg             = "#%d+"


ChatSystemHelper.eCheckResult   =
{
    Correct = 1,
    TooShort = 2,
    TooLong = 3,
}
ChatSystemHelper.EXPRESSION_START_INDEX    = 1
ChatSystemHelper.EXPRESSION_END_INDEX      = 33
ChatSystemHelper.MAX_MSG_LENGTH            = 32
ChatSystemHelper.MSG                       = 1
ChatSystemHelper.INVITE                    = 2
-----------------------------------------------------

local function Sortfunc(a, b)
    return a.nIndex > b.nIndex
end

function ChatSystemHelper.ColorLabelTrim(szMsg)
    if not szMsg then
        return
    end
    szMsg = string.gsub( szMsg, "</>", "")
    szMsg = string.gsub( szMsg, "<text.+>", "")
    return szMsg
end

function ChatSystemHelper.ParseExpressionSymbol(szMsg)
    local tbExpressionKeyWord = {}
    for keyWord in string.gmatch(szMsg, ExpressionReg) do
        local szIndex = string.sub(keyWord, 2)
        local nIndex = tonumber(szIndex)
        if nIndex >= ChatSystemHelper.EXPRESSION_START_INDEX and nIndex <= ChatSystemHelper.EXPRESSION_END_INDEX then
            tbExpressionKeyWord[keyWord] = nIndex
        end
    end

   --塞进一个排序的table中,目的是先替换index大的表情串 防止出现如 #2 #24 两个表情，如果先替换#2 那么#24会被破坏掉
   local tbSort = {}
   for keyword, nIndex in pairs(tbExpressionKeyWord) do
       local tbTemp = {}
       tbTemp.keyWord = keyword
       tbTemp.nIndex = nIndex
       table.insert(tbSort, tbTemp)
   end
   table.sort(tbSort, Sortfunc)
   for k,v in ipairs(tbSort) do
       local nIndex = v.nIndex
       local keyword = v.keyWord
       local szSpr = string.format(ExpressionResFormat, nIndex)
       szMsg = string.gsub(szMsg, keyword, string.format(ExpressionFormat,szSpr))
   end

    return szMsg
end

function ChatSystemHelper.CheckSpecialCharacter(szMsg)
    local szNew = string.gsub(szMsg, "<br>", "")
    return szNew
end

function ChatSystemHelper.CheckMsgSensitiveWords(szMsg)
    szMsg = SensitiveWordsSystem:Replace(szMsg)
    return szMsg
end

function ChatSystemHelper.AddValueWithLimit(tbTable, Value, nMaxCount)
    table.insert(tbTable, Value)
    local nHistoryCount = #tbTable
    if (nHistoryCount > nMaxCount) then
        table.remove(tbTable, 1)
    end
end

function ChatSystemHelper.CheckLengthValid(szMsg)
    local nLength = utf8.len(szMsg)
    if nLength > ChatSystemHelper.MAX_MSG_LENGTH then
        return ChatSystemHelper.eCheckResult.TooLong
    elseif nLength <= 0 then
        return ChatSystemHelper.eCheckResult.TooShort
    end
    return ChatSystemHelper.eCheckResult.Correct
end

function ChatSystemHelper.AddKeyAndValueToTab(tbValue, nKey, eValue)
    if not tbValue or type(tbValue) ~= "table" then
        return
    end
    if tbValue[nKey] then
        logerror("[UI] UPLobbyChat ,AddKeyAndValueToTab, key already exsit!")
    end
    tbValue[nKey] = eValue
end

return ChatSystemHelper