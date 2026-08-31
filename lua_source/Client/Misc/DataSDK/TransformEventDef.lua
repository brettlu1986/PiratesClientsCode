-----------------------------------------------------
--File Name    : TransformEventDef.lua
--Author       : Edward J
--Create Time  : 2020-08-11
--Description  : 定义转化log名称
-----------------------------------------------------

local TransformEventDef = {}
local function GetTargetEventTable(szTargetId, szTargetDes)
    local tbTemp = {}
    tbTemp.szId = szTargetId
    tbTemp.szDes = szTargetDes
    return tbTemp
end

local tbTargetEventName = {}
tbTargetEventName.APP_START             = "APP_START"
tbTargetEventName.CONNECT_SERVER        = "CONNECT_SERVER"
tbTargetEventName.LOAD_RESOURCE         = "LOAD_RESOURCE"
tbTargetEventName.LOAD_RESOURCE_FINISHI = "LOAD_RESOURCE_FINISHI"
tbTargetEventName.ENTER_GAME_START      = "ENTER_GAME_START"
tbTargetEventName.LOGIN_FINISHI         = "LOGIN_FINISHI"

TransformEventDef[tbTargetEventName.APP_START]              = GetTargetEventTable(1, "启动APP")
TransformEventDef[tbTargetEventName.CONNECT_SERVER]         = GetTargetEventTable(2, "连接服务器")
TransformEventDef[tbTargetEventName.LOAD_RESOURCE]          = GetTargetEventTable(3, "加载资源")
TransformEventDef[tbTargetEventName.LOAD_RESOURCE_FINISHI]  = GetTargetEventTable(4, "加载资源完成")
TransformEventDef[tbTargetEventName.ENTER_GAME_START]       = GetTargetEventTable(5, "登录页面展示")
TransformEventDef[tbTargetEventName.LOGIN_FINISHI]          = GetTargetEventTable(6, "登录成功")

TransformEventDef.TARGET_EVENT_NAME = tbTargetEventName
return TransformEventDef