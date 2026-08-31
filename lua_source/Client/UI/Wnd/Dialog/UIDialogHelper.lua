-----------------------------------------------------
--File Name    : UIDialogHelper.lua
--Author       : Chang Nan
--Create Time  : 2017-04-06
--Description  : 对话框相关的操作
-----------------------------------------------------

local UIDialogHelper = {}

-- import require
-- local UIDef = require("UIDef")
-- local UIManager = require("UIManager")
-- local DisconnectType = require("DisconnectTypeNew")

UIDialogHelper.tbDialogList = {}

-- function UIDialogHelper:ShowOKMessageDialog(szTitle, szMessage, szTipText, szBtnOkText, funOK, bCancelFullScreen)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_DIALOG_MESSAGE)
--     local szDialogName = UIDef.UI_DIALOG_MESSAGE
--     Wnd:ShowMessageDialog(szTitle, szMessage, szTipText, szBtnOkText, "", funOK, nil, bCancelFullScreen, true, true)
--     self.tbDialogList[szDialogName] = Wnd
-- end

-- 用于提示错误，层级最高
-- function UIDialogHelper:ShowErrorDialog(szTitle, szMessage, szTipText, szBtnOkText, szBtnCancelText, funOK, funCancel, bCancelFullScreen, bMiddle, bWithoutCancel)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_ERROR_DIALOG)
--     local szDialogName = UIDef.UI_ERROR_DIALOG
--     Wnd:ShowMessageDialog(szTitle, szMessage, szTipText, szBtnOkText, szBtnCancelText, funOK, funCancel, bCancelFullScreen, bMiddle, bWithoutCancel)
--     Wnd.UPDialogCommon.szCurrentDialogType = szDialogName
--     self.tbDialogList[szDialogName] = Wnd
-- end


--显示信息对话框
--bCancelFullScreen 是否可以通过点框外来关闭窗口, false表示不能关掉，默认值为可以关掉
--bMiddle message是否居中，true表示居中
--bWithoutCancel 是否需要取消按钮，true表示没有取消按钮
-- function UIDialogHelper:ShowMessageDialog(szTitle, szMessage, szTipText, szBtnOkText, szBtnCancelText, funOK, funCancel, bCancelFullScreen, bMiddle, bWithoutCancel)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_DIALOG_MESSAGE)
--     local szDialogName = UIDef.UI_DIALOG_MESSAGE
--     Wnd:ShowMessageDialog(szTitle, szMessage, szTipText, szBtnOkText, szBtnCancelText, funOK, funCancel, bCancelFullScreen, bMiddle, bWithoutCancel)
--     self.tbDialogList[szDialogName] = Wnd
-- end

--显示交易对话框
-- function UIDialogHelper:ShowTradeDialog(szTitle, szMessage, bCost, szCostTxt01, nGold01, nSilver01, szCostTxt02, nGold02, nSilver02, szBtnOKText, szBtnCancelText, funcOK)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_DIALOG_TRADE)
--     local szDialogName = UIDef.UI_DIALOG_TRADE
--     Wnd:ShowTradeDialog(szTitle, szMessage, bCost, szCostTxt01, nGold01, nSilver01, szCostTxt02, nGold02, nSilver02, szBtnOKText, szBtnCancelText, funcOK)
--     self.tbDialogList[szDialogName] = Wnd
-- end

--显示消耗对话框
--bWithoutCancel true表示没有取消按钮
-- function UIDialogHelper:ShowCostItemDialog(szTitle, szCost, nFomulationId, nMultiple, nGold, nSilver, szBtnConfirmTxt, funConfirm, bWithoutCancel, sztip)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_DIALOG_COST_ITEM)
--     local szDialogName = UIDef.UI_DIALOG_COST_ITEM
--     Wnd:ShowCostItemDialog(szTitle, szCost, nFomulationId, nMultiple, nGold, nSilver, szBtnConfirmTxt, funConfirm, bWithoutCancel, sztip)
--     self.tbDialogList[szDialogName] = Wnd
-- end

--显示复活界面
-- function UIDialogHelper:ShowReviveDialog(nReviveType)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_REVIVE)
--     local szDialogName = UIDef.UI_REVIVE
--     Wnd:ShowReviveDialog(nReviveType)
--     self.tbDialogList[szDialogName] = Wnd
-- end

-- function UIDialogHelper:ShowGoodsFullDialog(tbAwardList)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_DIALOG_GOODS_FULL)
--     local szDialogName = UIDef.UI_DIALOG_GOODS_FULL
--     Wnd:ShowGoodsFullDialog(tbAwardList)
--     self.tbDialogList[szDialogName] = Wnd
-- end

-- function UIDialogHelper:ShowReconnectingDialog()
--     local Wnd = UIManager:OpenWnd(UIDef.UI_RECONNECTING)
--     local szDialogName = UIDef.UI_RECONNECTING
--     Wnd:ShowReconnectingDialog()
--     self.tbDialogList[szDialogName] = Wnd    
-- end

-- function UIDialogHelper:ShowCountDownDialog(szTitle, l10nMessage, CancelMatchFunc, Object)
--     local Wnd = UIManager:OpenWnd(UIDef.UI_COUNT_DOWN)
--     local szDialogName = UIDef.UI_COUNT_DOWN
--     Wnd.CancelMatchmaking:Bind(CancelMatchFunc, Object)
--     Wnd:ShowCountDownDialog(szTitle, l10nMessage)
--     self.tbDialogList[szDialogName] = Wnd    
-- end

--关闭弹窗
-- function UIDialogHelper:CloseDialog(szDialogName, tbParam, bForce)
--     if self.tbDialogList[szDialogName] ~= nil then
--         log("UIDialogHelper:CloseDialog", szDialogName, bForce)
--         -- if not bForce then
--         --     if szDialogName == UIDef.UI_DISCONNECTDIALOG then
--         --         log("UIDialogHelper:Close DisconnectDialog")
--         --         local Wnd = UIManager:GetWnd(UIDef.UI_DISCONNECTDIALOG)
--         --         if Wnd then
--         --             log("UIDialogHelper:Close DisconnectDialog ", Wnd.nLevel)
--         --             if Wnd.nLevel and Wnd.nLevel == DisconnectType.disconnected then
--         --                 log("UIDialogHelper:Close DisconnectDialog failed: level is max")
--         --                 return
--         --             end
--         --         end
--         --     end
--         -- end
--         self.tbDialogList[szDialogName]:CloseDialog(tbParam)
--         self.tbDialogList[szDialogName] = nil
--     end
-- end

-- function UIDialogHelper:ShowDisconnectDialog(szTitle, szMessage, szTipText, szBtnOkText, szBtnCancelText, funOK, funCancel, bCancelFullScreen, bMiddle, bWithoutCancel, nLevel)
--     -- 查闪断问题添加Trace
--     -- if funCancel == nil then
--     --     logwarning("UIDialogHelper:ShowDisconnectDialog", debug.traceback(  ))
--     -- end
--     if UIManager:IsWndOpen(UIDef.UI_DISCONNECTDIALOG) then
--         local Wnd = UIManager:GetWnd(UIDef.UI_DISCONNECTDIALOG)
--         if Wnd and Wnd.nLevel > nLevel then
--             log("UIDialogHelper:ShowDisconnectDialog and is opend")
--             return
--         else
--             log("UIDialogHelper:ShowDisconnectDialog overload")
--         end
--     end
--     local Wnd = UIManager:OpenWnd(UIDef.UI_DISCONNECTDIALOG)
--     local szDialogName = UIDef.UI_DISCONNECTDIALOG
--     Wnd:ShowMessageDialog(szTitle, szMessage, szTipText, szBtnOkText, szBtnCancelText, funOK, funCancel, bCancelFullScreen, bMiddle, bWithoutCancel)
--     Wnd.UPDialogCommon.szCurrentDialogType = szDialogName
--     Wnd.UPDialogCommon.bAutoCallCancel = false
--     Wnd.UPDialogCommon.bCancelCloseUi = false
--     Wnd.nLevel = nLevel
--     self.tbDialogList[szDialogName] = Wnd
--     return Wnd
-- end

-- function UIDialogHelper:ShowWaitConnectDialog()
--     local Wnd = UIManager:OpenWnd(UIDef.UI_WAIT_CONNECT_DIALOG)
--     local szDialogName = UIDef.UI_WAIT_CONNECT_DIALOG
--     self.tbDialogList[szDialogName] = Wnd  
-- end

-- function UIDialogHelper:ShowRetryConnectDialog(szMessage, szBtnOkText, szBtnCancelText, funOK, funCancel, nLevel)
--     log("UIDialogHelper:ShowRetryConnectDialog")
--     if UIManager:IsWndOpen(UIDef.UI_RETRY_CONNECT_DIALOG) then
--         local Wnd = UIManager:GetWnd(UIDef.UI_RETRY_CONNECT_DIALOG)
--         if Wnd and Wnd.nLevel >= nLevel then
--             log("UIDialogHelper:ShowRetryConnectDialog and is opend")
--             return
--         else
--             log("UIDialogHelper:ShowRetryConnectDialog overload")
--         end
--     end
--     local Wnd = UIManager:OpenWnd(UIDef.UI_RETRY_CONNECT_DIALOG)
--     local szDialogName = UIDef.UI_RETRY_CONNECT_DIALOG
--     Wnd:ShowMessageDialog("", szMessage, "", szBtnOkText, szBtnCancelText, funOK, funCancel, false, true, funCancel == nil, nLevel)
--     Wnd.UPDialogCommon.szCurrentDialogType = szDialogName
--     Wnd.UPDialogCommon.bAutoCallCancel = false
--     Wnd.UPDialogCommon.bCancelCloseUi = false
--     Wnd.nLevel = nLevel
--     self.tbDialogList[szDialogName] = Wnd
--     return Wnd
-- end

-- function UIDialogHelper:ShowDisconnectDialog2(szMessage, szBtnOkText, funOK, nLevel)
--     log("UIDialogHelper:ShowDisconnectDialog2")
--     nLevel = nLevel or DisconnectType.disconnected
--     self:ShowRetryConnectDialog(szMessage, szBtnOkText, "", funOK, nil, nLevel)
-- end

-- function UIDialogHelper:CloseConnectDialog(szDialogName, tbParam, bForce)
--     if self.tbDialogList[szDialogName] ~= nil then
--         log("UIDialogHelper:CloseConnectDialog", szDialogName, bForce)
--         if not bForce then
--             if szDialogName == UIDef.UI_RETRY_CONNECT_DIALOG then
--                 local Wnd = UIManager:GetWnd(UIDef.UI_RETRY_CONNECT_DIALOG)
--                 if Wnd then
--                     log("UIDialogHelper:Close Retry connect dialog ", Wnd.nLevel)
--                     if Wnd.nLevel and Wnd.nLevel >= DisconnectType.disconnected then
--                         log("UIDialogHelper:Close Retry connect dialog failed: level is max")
--                         return
--                     end
--                 end
--             end
--         end
--         self.tbDialogList[szDialogName]:CloseDialog(tbParam)
--         self.tbDialogList[szDialogName] = nil
--     end
-- end

return UIDialogHelper