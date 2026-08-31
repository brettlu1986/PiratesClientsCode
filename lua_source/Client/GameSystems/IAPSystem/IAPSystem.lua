local IAPSystem = {}

local L10N = require("L10N")
local UIDef = require("UIDef")
local IapIni = require("IapIni")
local UIManager = require("UIManager")
local DelayTimer = require("DelayTimer")
local EventManager = require("EventManager")
local IAPDataTable = require("IAPDataTable")
local ClientEventDef = require("ClientEventDef")
local IAPResultCodeDef = require("IAPResultCodeDef")
local ChannelSDKSystem = require("ChannelSDKSystem")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

-- EGSDK充值结果状态码
local EGSDK_PAY_RESULT_CODE = {
    SUCCESS = 0, -- 充值成功
    CANCEL  = 1, -- 用户取消
    FAIL    = 2, -- 充值失败
}

local DEFAULT_IAP_URL           = ""                -- 默认充值回调地址
local DEFAULT_IAP_SERVER_ID     = "lobby"           -- 默认服务器ID
local IAP_PURCHASING_TIME_OUT   = 60                -- 充值超时时长

IAPSystem.bIAPEnabled           = true              -- 充值系统是否开启
IAPSystem.bInPurchasing         = false             -- 是否正在充值中
IAPSystem.szIAPUrl              = DEFAULT_IAP_URL   -- 充值回调的地址
IAPSystem.tbIAPTimeoutTimer     = nil               -- 充值超时TimerHandle

IAPSystem.nFirstPurchaseState   = nil               -- 首充状态

-- 打印普通日志
local function LogIAP(...)
    log("[IAP]", ...)
end

-- 打印错误日志
local function LogErrorIAP(...)
    logerror("[IAP]", ...)
end

-- 清除当前的支付状态
local function ClearPurchasingStatus(self)
    if self.bInPurchasing then
        LogIAP("Clear purchasing status")
        self.bInPurchasing = false
        self.tbIAPTemplate = nil
    end
end

-- 清理充值超时Timer
local function ClearIAPTimeoutTimer(self)
    if self.tbIAPTimeoutTimer then
        LogIAP("Clear timeout timer")
        DelayTimer:ClearTimer(self.tbIAPTimeoutTimer)
        self.tbIAPTimeoutTimer = nil
    end
end

-- 处理充值结束（有可能并没有真正结束，如超时，还需要等待服务器回包）
-- @nResultCode     IAP的ResultCode，参照IAPResultCodeDef文件中定义
-- @bClearStatus    是否充值充值状态，不传默认为true，只有当充值结果未知时才不重置
local function HandleIAPEnd(self, nResultCode, bClearStatus)
    if not self.bInPurchasing then
        LogErrorIAP("Handle IAP end failed, now is not in purchasing")
        return
    end

    LogIAP("Handle IAP end", nResultCode, bClearStatus)
    if bClearStatus ~= false then -- bClearStatus只要传的不是false，就默认执行clear
        ClearPurchasingStatus(self)
    end
    ClearIAPTimeoutTimer(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_IAP_END, nResultCode)
end

-- 处理充值开始（从发起充值请求开始算起）
-- @tbIAPTemplate   IAP配置，直到充值结束会被Cache住
local function HandleIAPBegin(self, tbIAPTemplate)
    if self.bInPurchasing then
        LogErrorIAP("Handle IAP begin failed, now is in purchasing")
        return
    end
    LogIAP("Handle IAP begin", t2s(tbIAPTemplate))
    self.bInPurchasing = true
    self.tbIAPTemplate = tbIAPTemplate
    EventManager:OnFireEvent(ClientEventDef.EV_ON_IAP_BEGIN)
end

-- SDK返回充值成功，开始计算超时
local function StartTimeoutTimer(self)
    LogIAP("Start timeout timer after sdk success")
    self.tbIAPTimeoutTimer = DelayTimer:DelayRun(function()
        LogIAP("Timeout...")
        HandleIAPEnd(self, IAPResultCodeDef.UNKNOWN_RESULT_WITH_TIMEOUT, false)
    end, IAP_PURCHASING_TIME_OUT)
end

-- 处理EGSDK充值的返回结果
-- @nReturnCode     SDK充值结果状态码，参照文件头部EGSDK_PAY_RESULT_CODE定义
local function OnReceiveEGSDKPayResult(self, nResultCode, szTradeNo)
    if not self.bInPurchasing then
        LogErrorIAP("Receive EGSDK pay result, now is not in purchasing")
        return
    end

    LogIAP("Receive EGSDK pay result, nResultCode =", nResultCode)
    if nResultCode == EGSDK_PAY_RESULT_CODE.SUCCESS then
        local tbIAPTemplate = self.tbIAPTemplate
        EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_PAY_FINISH, tbIAPTemplate.szCurrencyName, tbIAPTemplate.nPrice, szTradeNo)
        StartTimeoutTimer(self)
    elseif nResultCode == EGSDK_PAY_RESULT_CODE.CANCEL then
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_USER_CANCEL)
    elseif nResultCode == EGSDK_PAY_RESULT_CODE.FAIL then
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_UNKNOWN_SDK_ERROR)
    end
end

-- 调用EGSDK支付接口
-- @szToken         Lobby服务器生成，用于透传的Token字段
local function CallEGSDKPay(self, szToken)
    local szProductId = self.tbIAPTemplate.szProductId
    local szProductName = L10N:ToString(self.tbIAPTemplate.l10nDisplayName)
    local szPrice = tostring(self.tbIAPTemplate.nPrice)
    local szCurrencyName = self.tbIAPTemplate.szCurrencyName
    local szPayDes = t2s({
        token = szToken,
        platform = GlobalVariableSystem:GetPlatformName(true)
    })
    LogIAP("Call EGSDK pay", szProductId, szProductName, szPayDes, DEFAULT_IAP_SERVER_ID, self.szIAPUrl, szPrice, szCurrencyName)
    local bResult = ChannelSDKSystem:EGSDKPay(szProductId, szProductName, szPayDes, DEFAULT_IAP_SERVER_ID, self.szIAPUrl, szPrice, szCurrencyName)
    if not bResult then
        LogErrorIAP("Call EGSDK pay failed")
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_SDK_NO_RESPONSE)
    end
end

-- 新手引导结束后打开首充活动界面
local function OnUIGuildEndStep(self, nModule, nGroup, nStep)
    if not self:IsIAPEnabled() then
        log("IAPSystem iap disenabled")
        return
    end
    local tbGuildFirstPurchase = IapIni.tbGuildFirstPurchase
    if nModule == tbGuildFirstPurchase.nModule
        and nGroup == tbGuildFirstPurchase.nGroup
        and nStep == tbGuildFirstPurchase.nStep then
        local tbState = Proto.FirstPurchaseState
        if self.nFirstPurchaseState == tbState.NONE or self.nFirstPurchaseState == tbState.DEBT then
            UIManager:OpenWnd(UIDef.UI_FIRST_PRIZE)
        end
    end
end

function IAPSystem:Init()
    LogIAP("IAPSystem init")
    EventManager:BindEventMethod(ClientEventDef.EV_ON_PAY_RESULT, self, OnReceiveEGSDKPayResult)
    EventManager:BindEventMethod(ClientEventDef.EV_UI_GUIDE_END_STEP, self, OnUIGuildEndStep)
end

function IAPSystem:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_ON_PAY_RESULT, self, OnReceiveEGSDKPayResult)
    EventManager:UnBindEventMethod(ClientEventDef.EV_UI_GUIDE_END_STEP, self, OnUIGuildEndStep)
    ClearIAPTimeoutTimer(self)
    ClearPurchasingStatus(self)
    LogIAP("IAPSystem uninit")
end

-- 获取充值系统是否开启
function IAPSystem:IsIAPEnabled()
    return self.bIAPEnabled
end

-- 设置充值系统是否开启，由Procedure_Config在ParseConfigFile阶段调用
-- @bIAPEnabled     充值是否开启
function IAPSystem:SetIAPEnabled(bIAPEnabled)
    LogIAP("SetIAPEnabled", bIAPEnabled)
    self.bIAPEnabled = bIAPEnabled
end

-- 设置EGSdk充值回调地址，由Procedure_Config在ParseConfigFile阶段调用
-- @szIAPUrl        充值回调地址
function IAPSystem:SetIAPUrl(szIAPUrl)
    LogIAP("SetIAPUrl", szIAPUrl)
    self.szIAPUrl = szIAPUrl or DEFAULT_IAP_URL
end

-- 处理申请充值结果
-- @nReturnCode     结果状态码，参照Proto统一ReturnCode
function IAPSystem:ReceivePurchaseResult(nReturnCode, szToken)
    if not self.bInPurchasing then
        LogErrorIAP("Receive purchase result, now is not in purchasing")
        return
    end

    LogIAP("Receive apply purchase result, nReturnCode, szToken =", nReturnCode, szToken)
    if nReturnCode == Proto.ReturnCode.OK then
        CallEGSDKPay(self, szToken)
    elseif nReturnCode == Proto.ReturnCode.IAP_REFUSE_APPLY_PURCHASE then
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_SERVER_REFUSE)
    elseif nReturnCode == Proto.ReturnCode.IAP_NOT_FOUND_PRODUCT_ID then
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_SERVER_NOT_FOUND_PRODUCT)
    elseif nReturnCode == Proto.ReturnCode.IAP_EXIST_PENDING_ORDER then
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_SERVER_EXIST_PENDING_ORDER)
    else
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_UNKNOWN_SERVER_ERROR_BEFORE_SDK)
    end
end

-- 处理申请恢复订单结果
-- @nReturnCode     结果状态码，参照Proto统一ReturnCode
function IAPSystem:ReceiveRestoreOrderResult(nReturnCode)
    LogIAP("Receive apply restore order result, nReturnCode =", nReturnCode)
    -- 暂时不用处理
end

-- 处理最终充值结果
-- @bResult         服务器返回的充值结果成功/失败
function IAPSystem:ReceivePurchaseResultNotify(bResult)
    LogIAP("Receives purchase result, bResult =", bResult)
    HandleIAPEnd(self, bResult and IAPResultCodeDef.SUCCEED or IAPResultCodeDef.FAILED_WITH_UNKNOWN_SERVER_ERROR_AFTER_SDK)
end

function IAPSystem:ReceiveApplyFirstPurchaseReward(nReturnCode)
    LogIAP("Receive apply first purchase reward result, nReturnCode =", nReturnCode)
end

-- 首充状态
function IAPSystem:ReceiveFirstPurchaseState(nState)
    local nOldState = self.nFirstPurchaseState

    self.nFirstPurchaseState = nState
    EventManager:OnFireEvent(ClientEventDef.EV_ON_FRESH_FIRST_PURCHASE)

    local tbState = Proto.FirstPurchaseState
    if nOldState and nOldState == tbState.NONE and nState == tbState.DEBT then
        UIManager:OpenWnd(UIDef.UI_FIRST_PRIZE)
    end
end

function IAPSystem:GetFirstPurchaseState()
    return self.nFirstPurchaseState
end

-- 客户端申请充值
-- @szProductId     商品ID
function IAPSystem:RequestPurchase(nIAPId)
    LogIAP("------------------------------------------------------------------------")
    if not self:IsIAPEnabled() then
        LogErrorIAP("Request purchase failed, IAP is disabled.")
        return
    end

    if self.bInPurchasing then
        LogErrorIAP("Request purchase failed. IAP is in purchasing.")
        HandleIAPEnd(self, IAPResultCodeDef.UNKNOWN_RESULT_WITH_PURCHASING, false)
        return
    end

    local tbTemplate =  IAPDataTable:GetTemplate(nIAPId)
    if not tbTemplate then
        LogErrorIAP("Request purchase failed. Can not find iap template, id =", nIAPId)
        HandleIAPEnd(self, IAPResultCodeDef.FAILED_WITH_CAN_NOT_FIND_IAP_TEMPLATE)
        return
    end

    LogIAP("Request purchase", nIAPId)
    HandleIAPBegin(self, tbTemplate)
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_RequestPurchase, { product_id = tbTemplate.szProductId })
end

-- 客户端申请恢复订单
function IAPSystem:RequestRestoreOrder()
    if not self:IsIAPEnabled() then
        LogErrorIAP("Request restore order failed, IAP is disabled.")
        return
    end

    LogIAP("Request restore order")
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_RequestRestoreOrder)
end

function IAPSystem:RequestApplyFirstPurchaseReward()
    LogIAP("Request apply first purchase reward")
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ApplyFirstPurchaseReward)
end

return IAPSystem