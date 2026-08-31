local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingChat = luaclass("SettingChat", SettingBase)
local SettingKeyDef = require("SettingKeyDef")
local QuickChatDataTable = require("QuickChatDataTable")

local LocalKeys = SettingKeyDef.LocalKeys

local CHATS = {
    LocalKeys.QUICK_CHAT_1,
    LocalKeys.QUICK_CHAT_2,
    LocalKeys.QUICK_CHAT_3,
    LocalKeys.QUICK_CHAT_4,
    LocalKeys.QUICK_CHAT_5,
    LocalKeys.QUICK_CHAT_6,
    LocalKeys.QUICK_CHAT_7,
    LocalKeys.QUICK_CHAT_8,
    LocalKeys.QUICK_CHAT_9,
    LocalKeys.QUICK_CHAT_10,
}

SettingChat.tbDefaults = nil

function SettingChat:Init(Owner)
    SettingChat.super.Init(self, Owner)

    self.tbDefaults = {}
end

function SettingChat:Uninit()
    self.tbDefaults = nil
    SettingChat.super.Uninit(self)
end

function SettingChat:LoadDefaultValue()
    local nMaxCount = #CHATS
    local nIndex = 0
    
    local tbAll = QuickChatDataTable:GetAll()
    for k, v in pairs(tbAll) do
        if v.nDefault > 0 and nIndex < nMaxCount then
            table.insert(self.tbDefaults, v)
            nIndex = nIndex + 1
            -- 初始化
            local nKey = CHATS[nIndex]
            if self:Get(nKey) < 0 then    
                self:Set(nKey, v.nId)
            end
        end
    end
end

function SettingChat:GetValues()
    local tbRet = {}
    for i, v in ipairs(CHATS) do
        local nValue = self:Get(v)
        table.insert(tbRet, nValue)
    end
    return tbRet
end

function SettingChat:SetValues(tbValues)
    local nCount = math.min(#CHATS, #tbValues)
    for i = 1, nCount do
        
        self:Set(CHATS[i], tbValues[i])
    end
    for i = nCount + 1, #CHATS do
        self:Set(CHATS[i], 0)
    end
end

function SettingChat:Reset()
    local nCount = math.min(#CHATS, #self.tbDefaults)
    for i = 1, nCount do
        self:Set(CHATS[i], self.tbDefaults[i].nId)
    end
    for i = nCount + 1, #CHATS do
        self:Set(CHATS[i], 0)
    end
end

return SettingChat