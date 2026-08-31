-----------------------------------------------------
--File Name    : UIUtils.lua
--Author       : Song Fuhao
--Create Time  : 2016-08-16
--Description  : UI相关工具类方法
-----------------------------------------------------

local UIUtils = {}

local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UPCommonButtonList = require("UPCommonButtonList")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HttpHelper = require("HttpHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")

-- 显示提示
-- @param   l10nMessage 待显示的Toast文本
function UIUtils.ShowToast(l10nMessage)
    local Wnd = UIManager:OpenWnd(UIDef.UI_TOAST_BOARD)
    Wnd:ShowToast(l10nMessage)
end

-- 显示提示
-- @param   szKey TextDataTable中的Key
function UIUtils.ShowToastWithKey(szKey)
    local Wnd = UIManager:OpenWnd(UIDef.UI_TOAST_BOARD)
    local l10nMessage = UISetUtils.GetL10NTextByKey(szKey)
    Wnd:ShowToast(l10nMessage)
end

-- format字符串并显示提示
-- @param   szKey TextDataTable中的Key
function UIUtils.ShowToastWithL10NFormat(szKey, ...)
    local tbArgs = {...}
    local Wnd = UIManager:OpenWnd(UIDef.UI_TOAST_BOARD)
    local l10nFormatMessage = UISetUtils.GetL10NTextByKey(szKey)
    local l10nMessage = L10N:FormatFromTable(l10nFormatMessage, tbArgs)
    Wnd:ShowToast(l10nMessage)
end

-- 显示特殊Toast
function UIUtils.ShowSpecialToast(nId, l10nMessage, nWaitTime, bJudgeRepeat)
    local Wnd = UIManager:OpenWnd(UIDef.UI_SPECIAL_TOAST_BOARD)
    if not Wnd then
        logwarning("[UI] UI_ToastBoard is open failed.")
        return
    end
    Wnd:ShowToast(nId, l10nMessage, nWaitTime, bJudgeRepeat)
end

-- 显示Loading对话框
-- @param   szKey TextDataTable中的Key
function UIUtils.ShowLoadingDialogWithKey(szKey)
    local l10nMessage = UISetUtils.GetL10NTextByKey(szKey)
    UIUtils.ShowLoadingDialog(l10nMessage)
end

-- 显示Loading对话框
-- @param   l10nMessage 待显示的消息文本
function UIUtils.ShowLoadingDialog(l10nMessage)
    local tbOpenArgs = {}
    tbOpenArgs.l10nMessage = l10nMessage
    UIManager:OpenWnd(UIDef.UI_LOADING_DIALOG, tbOpenArgs)
end

-- 隐藏Loading对话框
function UIUtils.HideLoadingDialog()
    UIManager:CloseWnd(UIDef.UI_LOADING_DIALOG)
end

-- 用于取得目前dialog中的dialogfram控件，如果没有则返回空
-- @param   Dialog  对话框Prefabn实例，ShowDialog/CreateDialog之后会返回
function UIUtils:GetCurrentDialog()
    local Wnd = UIManager:GetWnd(UIDef.UI_DIALOG_BOARD)
    return Wnd:GetCurrentDialog()
end

-- 用于判断Dialog是否还存在，可以避免重复弹出问题
-- @param   Dialog  对话框Prefabn实例，ShowDialog/CreateDialog之后会返回
function UIUtils:IsDialogExist(Dialog)
    if Dialog then
        local Wnd = UIManager:GetWnd(UIDef.UI_DIALOG_BOARD)
        if Wnd then
            return Wnd:IsDialogExist(Dialog)
        end
    end
    return false
end

-- 显示确认对话框
-- @param   l10nTitle           标题
-- @param   l10nMessage         对话框消息内容
-- @param   fnPositiveCallback  确定点击事件
-- @return  Dialog              对话框Prefabn实例，可用于自定义
function UIUtils.ShowConfirmDialog(l10nTitle, l10nMessage, fnPositiveCallback)
    local Dialog = UIUtils.CreateDialog(l10nTitle, l10nMessage)
    if fnPositiveCallback then
        Dialog:SetPositiveButtonCallback(fnPositiveCallback)
    end
    Dialog:SetNegativeButtonVisible(false)
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
    return Dialog
end

-- 显示确认/取消对话框
-- @param   l10nTitle           标题
-- @param   l10nMessage         对话框消息内容
-- @param   fnPositiveCallback  确定点击事件
-- @param   fnNegativeCallback  取消点击事件
-- @return  Dialog              对话框Prefabn实例，可用于自定义
function UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, fnPositiveCallback, fnNegativeCallback)
    local Dialog = UIUtils.CreateDialog(l10nTitle, l10nMessage)
    if fnPositiveCallback then
        Dialog:SetPositiveButtonCallback(fnPositiveCallback)
    end
    if fnNegativeCallback then
        Dialog:SetNegativeButtonCallback(fnNegativeCallback)
    end
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
    return Dialog
end

-- 显示纯消息对话框（带右上角关闭按钮）
-- @param   l10nTitle           标题
-- @param   l10nMessage         对话框消息内容
-- @return  Dialog              对话框Prefabn实例，可用于自定义
function UIUtils.ShowPureDialog(l10nTitle, l10nMessage)
    local Dialog = UIUtils.CreateDialog(l10nTitle, l10nMessage)
    Dialog:SetPositiveButtonVisible(false)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
    return Dialog
end

-- 显示标准对话框，各处文字均可自定义
-- @param   l10nTitle           标题
-- @param   l10nMessage         对话框消息内容
-- @param   l10nPositiveText    右侧按钮文字
-- @param   fnPositiveCallback  右侧按钮点击事件
-- @param   l10nNegativeText    左侧按钮文字
-- @param   fnNegativeCallback  左侧按钮点击事件
-- @return  Dialog              对话框Prefabn实例，可用于自定义
function UIUtils.ShowDialog(l10nTitle, l10nMessage, l10nPositiveText, fnPositiveCallback, l10nNegativeText, fnNegativeCallback)
    local Dialog = UIUtils.CreateDialog(l10nTitle, l10nMessage)
    if l10nPositiveText then
        Dialog:SetPositiveText(l10nPositiveText)
        if fnPositiveCallback then
            Dialog:SetPositiveButtonCallback(fnPositiveCallback)
        end
    else
        Dialog:SetPositiveButtonVisible(false)
    end
    if l10nNegativeText then
        Dialog:SetNegativeText(l10nNegativeText)
        if fnNegativeCallback then
            Dialog:SetNegativeButtonCallback(fnNegativeCallback)
        end
    else
        Dialog:SetNegativeButtonVisible(false)
    end
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
    return Dialog
end

-- 显示标准对话框按钮带倒计时，各处文字均可自定义
-- @param   l10nTitle           标题
-- @param   l10nMessage         对话框消息内容
-- @param   l10nPositiveText    右侧按钮文字
-- @param   fnPositiveCallback  右侧按钮点击事件
-- @param   l10nNegativeText    左侧按钮文字
-- @param   fnNegativeCallback  左侧按钮点击事件
-- @return  Dialog              对话框Prefabn实例，可用于自定义
function UIUtils.ShowCountDownDialog(l10nTitle, l10nMessage, l10nPositiveText, fnPositiveCallback, l10nNegativeText, fnNegativeCallback, nEndTime, fnCountdownFinishedCallback)   
    local Dialog = UIUtils.CreateDialog(l10nTitle, L10N.NullString)
    local pbContent = Dialog.PrefabHelper:CreatePrefab(UIDef.UP_DIALOG_COUNTDOWN)
    Dialog:SetView(pbContent.pWidgetRef)
    pbContent:SetParent(Dialog)
    pbContent:SetMessage(l10nMessage)
    if fnPositiveCallback then
        pbContent:SetPositiveButtonCallback(fnPositiveCallback)
    end
    pbContent:SetPositiveButtonCountdownTime(l10nPositiveText, nEndTime)
    if fnCountdownFinishedCallback then
        pbContent:SetCountdownFinishedCallback(fnCountdownFinishedCallback)
    end
    if l10nNegativeText then
        pbContent:SetNegativeButtonVisible(true)
        if fnNegativeCallback then
            pbContent:SetNegativeButtonCallback(fnNegativeCallback)
        end
        pbContent:SetNegativeText(l10nNegativeText)
    else
        pbContent:SetNegativeButtonVisible(false)
    end
    
    Dialog:SetPositiveButtonVisible(false)
    Dialog:SetCloseButtonVisible(false)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
    return Dialog
end

-- 创建对话框（一般不直接调用，除非是有自定义需求）
-- @param   l10nTitle   标题
-- @param   l10nMessage 对话框消息内容（可为空）
-- @return  Dialog      对话框Prefabn实例，可用于自定义
function UIUtils.CreateDialog(l10nTitle, l10nMessage)
    local Wnd = UIManager:OpenWnd(UIDef.UI_DIALOG_BOARD)
    return Wnd:CreateDialog(l10nTitle, l10nMessage)
end

-- 显示Tips（点背景关闭的那种）
-- @param   szPrefabName
-- @param   pRootWidgetRef  用于定位Tips位置的控件
-- @return  Tips对应的Prefab脚本实例
function UIUtils.ShowTips(szPrefabName, pRootWidgetRef)
    local Wnd = UIManager:OpenWnd(UIDef.UI_TIPS_BOARD)
    return Wnd:CreateTips(szPrefabName, pRootWidgetRef)
end

-- 隐藏Tips（点背景关闭的那种）
function UIUtils.HideTips()
    UIManager:CloseWnd(UIDef.UI_TIPS_BOARD)
end

-- Toggle的方式显示CommonBtnList
-- @param pTargetWidgetRef 是标示一个控件的唯一ID，一般传控件指针的引用
-- @param tbArgs btn的参数列表
-- @param pScreenPos 需要显示的位置（可为空）
-- @param pSize 以pScreenPos为顶点不可遮挡区域的大小（可为空）
-- @param nLayoutType BtnList的布局方式(可为空)
function UIUtils.ToggleCommonBtnList(pTargetWidgetRef, tbArgs, pScreenPos, pSize, nLayoutType)
    local pWnd = nil
    pWnd = UIManager:OpenWnd(UIDef.UI_COMMON_BUTTON_LIST_CONTENT)
    return pWnd:ToggleBtnsList(pTargetWidgetRef, {tbBtnsArg = tbArgs}, pScreenPos, pSize, nLayoutType)
end

-- Create一个CommonBtnList
-- @param pTargetWidgetRef 是标示一个控件的唯一ID，一般传控件指针的引用
-- @param tbArgs btn的参数列表
-- @param pScreenPos 需要显示的位置（可为空）
-- @param pSize 以pScreenPos为顶点不可遮挡区域的大小（可为空）
-- @param nLayoutType BtnList的布局方式(可为空)
function UIUtils.CreateCommonBtnList(pTargetWidgetRef, tbArgs, pScreenPos, pSize, nLayoutType)
    local pWnd = nil
    pWnd = UIManager:OpenWnd(UIDef.UI_COMMON_BUTTON_LIST_CONTENT)
    return pWnd:CreateBtnsList(pTargetWidgetRef, {tbBtnsArg = tbArgs}, pScreenPos, pSize, nLayoutType)
end

-- 关闭一个CommonBtnList
-- @param  pTargetWidgetRef 是标示一个控件的唯一ID，一般传控件指针的引用
function UIUtils.DestroyCommonBtnList(pTargetWidgetRef)
    if UIManager:IsWndVisible(UIDef.UI_COMMON_BUTTON_LIST_CONTENT) then
        local pWnd = UIManager:OpenWnd(UIDef.UI_COMMON_BUTTON_LIST_CONTENT)
        return pWnd:DestoryButtonList(pTargetWidgetRef)
    end
end

function UIUtils.DestroyAllCommonBtnList()
    UIManager:CloseWnd(UIDef.UI_COMMON_BUTTON_LIST_CONTENT)
end

-- 生成CommonBtnList中用到的tbArgs
-- @param tbArgs参数列表的引用
-- @param szBtnType button的类型（可为空）
-- @param szName button上显示的内容
-- @param pIcon button上的icon
-- @param pFunc button所对应的回调函数
function UIUtils.AddCommonBtnListArgs(tbArgs, szBtnType, szName, pIcon, pFunc)
    if(tbArgs == nil) then
        error("[UI] UIUtils.AddCommonBtnListArgs failed, tbArgs == nil")
        return false
    end
    szBtnType = szBtnType or UPCommonButtonList.CommonButton
    local tbTemp = {["szBtnType"] = szBtnType, ["szName"] = szName, ["pIcon"] = pIcon,["pFunc"] = pFunc }
    table.insert(tbArgs, tbTemp)
    return tbArgs
end

-- 显示跑马灯
-- @param szContent string类型 格式为 “系统消息id<br>[物品id]”
function UIUtils.ShowSystemNotifaction(szContent)
    local pWnd = nil
    pWnd = UIManager:OpenWnd(UIDef.UI_SYSTEMNOTIFACTION)
    return pWnd:AddMsg(szContent)
end

-- 显示等待网络回包的转菊花
function UIUtils.ShowWaitingPacket()
    UIManager:OpenWnd(UIDef.UI_WAITING)
end

--隐藏等待网络回包的转菊花
function UIUtils.HideWaitingPacket()
    UIManager:CloseWnd(UIDef.UI_WAITING)
end

-- 显示大喇叭内容（在跑马灯下面的滚动UI）
-- @param tbData = {szName= "玩家名称", szContent="大喇叭内容"}
function UIUtils.ShowTopMsgNotifaction(tbData)
    local pWnd = nil
    pWnd = UIManager:OpenWnd(UIDef.UI_TOPMSGNOTIFACTION)
    return pWnd:AddMsg(tbData)
end

-- 客服帮助界面
-- @param 
function UIUtils.ShowCustomerHelper()
    local szHelper = GlobalVariableSystem:GetHelpUrl()

    local _ = HttpHelper:SendGetRequest(szHelper, function(nRetCode, szContent)
    if nRetCode ~= HttpHelper.HttpResponseCodes.OK then
            szContent = "这是一个帮助"
        end
        UIManager:OpenWnd(UIDef.UI_CUSTOMERHELPER, {szTitle = UISetUtils.GetL10NTextByKey("LOGIN_HELP"), szContent = szContent})
    end)
end

--- 打印日志到屏幕上
--- @param   szMessage      string  | "显示的文本"
--- @param   nTimeToDisplay number  | "显示时长，默认3s"
--- @param   pSlateColor    userdata| "显示颜色，默认白色（使用UIResourceDef里的SlateColor定义）"
--- @param   nScale         number  | "文本缩放，默认1倍"
function UIUtils.PrintScreen(szMessage, nTimeToDisplay, pSlateColor, nScale)
    local Wnd = UIManager:OpenWnd(UIDef.UI_PRINT_SCREEN)
    Wnd:PrintScreen(szMessage, nTimeToDisplay, pSlateColor, nScale)
end

-- 选择大厅底部菜单
-- @param nSubType:         LobbySubTypeDef
-- @param bForceActivateSub:true: 强制激活subsystem false:仅设置菜单选中效果 
function UIUtils.BottomMenuSelect(nSubType, bForceActivateSub)
    local tbWnd = UIManager:GetWnd(UIDef.UI_LOBBY_BOTTOM_MENU)
    if tbWnd then
        tbWnd:SelectMenu(nSubType, bForceActivateSub)
    end
end

-- 大厅底部菜单全部未选中
function UIUtils.BottomMenuUnselectAll()
    local tbWnd = UIManager:GetWnd(UIDef.UI_LOBBY_BOTTOM_MENU)
    if tbWnd then
        tbWnd:UnselectAll()
    end
end

function UIUtils.BottomMenuHide(bHide)
    local tbWnd = UIManager:GetWnd(UIDef.UI_LOBBY_BOTTOM_MENU)
    if tbWnd then  
        tbWnd:HideBottom(bHide)
    end
end

function UIUtils.ShowRetryConnectDialog(l10nMessage, l10nBtnOkText, l10nBtnCancelText, funOK, funCancel, nLevel)
    log("[ReconnectSystem] UIUtils.ShowRetryConnectDialog ", nLevel)

    local tbParam = {
        l10nTitle = UISetUtils.GetL10NTextByKey("RECONNECT_DUNGEON_TITLE"),
        l10nMessage = l10nMessage,
        l10nBtnOkText = l10nBtnOkText,
        l10nBtnCancelText = l10nBtnCancelText,
        funOK = funOK,
        funCancel = funCancel,
        nLevel = nLevel
    }
    if UIManager:IsWndVisible(UIDef.UI_RETRY_CONNECT_DIALOG) then
        EventManager:OnFireEvent(ClientEventDef.EV_REFRESH_RETRY_CONNECT_DIALOG, tbParam)
    else
        UIManager:OpenWnd(UIDef.UI_RETRY_CONNECT_DIALOG, tbParam)
    end
end

function UIUtils.CloseConnectDialog(bForce)
    log("[ReconnectSystem] UIUtils.CloseConnectDialog ", bForce)
    EventManager:OnFireEvent(ClientEventDef.EV_CLOSE_RETRY_CONNECT_DIALOG, bForce)
end

function UIUtils.ShowDisconnectDialog(l10nMessage, l10nBtnOkText, funOK, nLevel)
    log("[ReconnectSystem] UIUtils.ShowDisconnectDialog ", nLevel)
    UIUtils.ShowRetryConnectDialog(l10nMessage, l10nBtnOkText, nil, funOK, nil, nLevel)    
end

function UIUtils.ShowErrorDialog(l10nTitle, l10nMessage, fnPositiveCallback)
    local Wnd = UIManager:OpenWnd(UIDef.UI_ERROR_DIALOG)
    local Dialog = Wnd:CreateDialog(l10nTitle, l10nMessage)
    if fnPositiveCallback then
        Dialog:SetPositiveButtonCallback(fnPositiveCallback)
    end
    Dialog:SetNegativeButtonVisible(false)
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
    return Dialog    
end

return UIUtils
