-----------------------------------------------------
--File Name    : HomelandPacketProcessor.lua
--Author       : zhiyuan
--Create Time  : 2019-04-24
--Description  : 家园的协议接收
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local HomelandPacketProcessor = luaclass("HomelandPacketProcessor", NetMessageProcessorBase)

local HomelandSystem = require("HomelandSystem")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local UIUtils = require("UIUtils")

local function GetHomelandItemSystem()
    return HomelandSystem:GetSubSystem("HomelandItemSystem")
end

-- 同步家园数据
function HomelandPacketProcessor:OnSyncHomeland(tbPacket)
    HomelandSystem:OnSyncHomeland(tbPacket.homeland)
end

-- 切换家园场景
function HomelandPacketProcessor:OnSwitchScene(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        HomelandSystem:OnSwitchScene(tbPacket.scene_id, tbPacket.recover_layout)
    else
        --todo 临时toast
        UIUtils.ShowToast("切换场景失败，错误码"..nReturnCode)
    end
end

-- 标志性建筑升级
function HomelandPacketProcessor:OnLandmarkUpgradeBegin(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        HomelandSystem:OnLandmarkUpgradeBegin(tbPacket.landmark_id, tbPacket.remain_seconds)
    else
        --todo 临时toast
        UIUtils.ShowToast("建筑升级失败，错误码"..nReturnCode)
    end
end

-- 标志性建筑升级完成
function HomelandPacketProcessor:OnLandmarkUpgradeComplete(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        HomelandSystem:OnLandmarkUpgradeComplete(tbPacket.landmark)
    else
        --todo 临时toast
        UIUtils.ShowToast("建筑升级完成失败，错误码"..nReturnCode)
    end
end

-- 建造装饰物
function HomelandPacketProcessor:OnPlaceBuilding(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        HomelandSystem:OnPlaceBuilding(tbPacket.index, tbPacket.instance_id, tbPacket.rotation_id)
    else
        --todo 临时toast
        UIUtils.ShowToast("建造装饰物失败，错误码"..nReturnCode)
    end
end

-- 拆除装饰物
function HomelandPacketProcessor:OnDestroyBuilding(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        HomelandSystem:OnDestroyBuilding(tbPacket.index)
    else
        --todo 临时toast
        UIUtils.ShowToast("拆除装饰物失败，错误码"..nReturnCode)
    end
end

-- 购买场景
function HomelandPacketProcessor:OnPurchaseScene(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        HomelandSystem:OnPurchaseScene(tbPacket.scene_id)
    else
        --todo 临时toast
        UIUtils.ShowToast("购买家园场景失败，错误码"..nReturnCode)
    end
end

-- 购买地块
function HomelandPacketProcessor:OnPurchaseBlock(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        HomelandSystem:OnPurchaseBlock(tbPacket.index)
    else
        --todo 临时toast
        UIUtils.ShowToast("购买地块失败，错误码"..nReturnCode)
    end
end

-- 购买地块
function HomelandPacketProcessor:OnExchangeBuilding(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode ~= Proto.ReturnCode.OK then
        --todo 临时toast
        UIUtils.ShowToast("兑换失败，错误码"..nReturnCode)
    end
end

-- 出售建筑道具
function HomelandPacketProcessor:OnSellDecorativeBuilding(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode ~= Proto.ReturnCode.OK then
        --todo 临时toast
        UIUtils.ShowToast("出售失败，错误码"..nReturnCode)
    end
end

-- 研发道具
function HomelandPacketProcessor:OnResearchItem(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        local HomelandItemSystem = GetHomelandItemSystem()
        HomelandItemSystem:OnResearchItem(tbPacket.item_id, tbPacket.remain_seconds)
    else
        --todo 临时toast
        UIUtils.ShowToast("研发道具失败，错误码"..nReturnCode)
    end
end

-- 研发道具完成
function HomelandPacketProcessor:OnResearchItemComplete(tbPacket)
    local nReturnCode = tbPacket.return_code
    if nReturnCode == Proto.ReturnCode.OK then
        local HomelandItemSystem = GetHomelandItemSystem()
        HomelandItemSystem:OnResearchItemComplete(tbPacket.instance_id)
    else
        --todo 临时toast
        UIUtils.ShowToast("研发道具完成失败，错误码"..nReturnCode)
    end
end

-- 同步所有正在研发的数据
function HomelandPacketProcessor:OnSyncResearchItems(tbPacket)
    local HomelandItemSystem = GetHomelandItemSystem()
    HomelandItemSystem:OnSyncResearchItems(tbPacket.items)
end

-- 注册处理包
function HomelandPacketProcessor:RegisterPackets()
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_GetHomeland, self, self.OnSyncHomeland)
    self:BindMethod(Proto.s2c_SwitchScene, self, self.OnSwitchScene)
    self:BindMethod(Proto.s2c_LandmarkUpgrade, self, self.OnLandmarkUpgradeBegin)
    self:BindMethod(Proto.s2c_LandmarkUpgradeComplete, self, self.OnLandmarkUpgradeComplete)
    self:BindMethod(Proto.s2c_PlaceBuilding, self, self.OnPlaceBuilding)
    self:BindMethod(Proto.s2c_DestroyBuilding, self, self.OnDestroyBuilding)
    self:BindMethod(Proto.s2c_PurchaseScene, self, self.OnPurchaseScene)
    self:BindMethod(Proto.s2c_PurchaseBlock, self, self.OnPurchaseBlock)
    self:BindMethod(Proto.s2c_ExchangeBuilding, self, self.OnExchangeBuilding)
    self:BindMethod(Proto.s2c_SellDecorativeBuilding, self, self.OnSellDecorativeBuilding)
    self:BindMethod(Proto.s2c_ResearchItem, self, self.OnResearchItem)
    self:BindMethod(Proto.s2c_ResearchItemComplete, self, self.OnResearchItemComplete)
    self:BindMethod(Proto.s2c_ResearchItems, self, self.OnSyncResearchItems)
end

-- 初始化
function HomelandPacketProcessor:Init()
    HomelandPacketProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

-- 结束
function HomelandPacketProcessor:Uninit()
    HomelandPacketProcessor.super.Uninit(self)
end

return HomelandPacketProcessor
