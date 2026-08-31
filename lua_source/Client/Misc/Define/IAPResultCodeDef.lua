-----------------------------------------------------
--File Name    : IAPResultCodeDef.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-22
--Description  : 支付结果定义
-----------------------------------------------------
return
{
    -- 充值成功
    SUCCEED                                     = 0,    -- 充值成功

    -- 充值失败，客户端错误
    FAILED_WITH_CAN_NOT_FIND_IAP_TEMPLATE       = 101,  -- 充值失败，未找到充值Template

    -- 充值失败，Lobby错误
    FAILED_WITH_UNKNOWN_SERVER_ERROR_BEFORE_SDK = 201,  -- 充值失败，服务器未知错误，发生在SDK调用前
    FAILED_WITH_UNKNOWN_SERVER_ERROR_AFTER_SDK  = 202,  -- 充值失败，服务器未知错误，发生在SDK调用后
    FAILED_WITH_SERVER_REFUSE                   = 203,  -- 充值失败，服务器拒绝购买
    FAILED_WITH_SERVER_NOT_FOUND_PRODUCT        = 204,  -- 充值失败，服务器未找到对应产品
    FAILED_WITH_SERVER_EXIST_PENDING_ORDER      = 205,  -- 充值失败，服务器存在未处理的订单

    -- 充值失败，SDK错误
    FAILED_WITH_UNKNOWN_SDK_ERROR               = 301,  -- 充值失败，SDK未知错误
    FAILED_WITH_USER_CANCEL                     = 302,  -- 充值失败，用户已手动取消
    FAILED_WITH_SDK_NO_RESPONSE                 = 303,  -- 充值失败，SDK调用失败

    -- 充值结果未知
    UNKNOWN_RESULT_WITH_TIMEOUT                 = 401,  -- 充值结果未知，充值超时
    UNKNOWN_RESULT_WITH_PURCHASING              = 402,  -- 充值结果未知，仍于充值中
    UNKNOWN_RESULT_WITH_UI_CLOSED               = 403,  -- 充值结果未知，充值界面已关闭
}