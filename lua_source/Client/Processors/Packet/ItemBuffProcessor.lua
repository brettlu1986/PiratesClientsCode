-----------------------------------------------------
--File Name    : ItemBuffProcessor.lua
--Author       : lzheng
--Create Time  : 2019-10-15
--Description  : 物品buff
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local ItemBuffProcessor = luaclass("ItemBuffProcessor", NetMessageProcessorBase)

local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local ItemBuffHelper = require("ItemBuffHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

function ItemBuffProcessor:OnRefreshCurrentBuffs(tbPacket)
    if tbPacket.buff then
        ItemBuffHelper.SetItemBuffData(tbPacket.buff)
        EventManager:OnFireEvent(ClientEventDef.EV_ITEM_BUFF_BTN_VISIBLE)
    end
end

-- 注册处理包
function ItemBuffProcessor:RegisterPackets()
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_SyncBuff, self, self.OnRefreshCurrentBuffs)
end

-- 初始化
function ItemBuffProcessor:Init()
    ItemBuffProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

-- 结束
function ItemBuffProcessor:Uninit()
    ItemBuffProcessor.super.Uninit(self)
end

return ItemBuffProcessor
