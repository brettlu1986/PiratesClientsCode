local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIRetryConnectDialog = luaclass("UIRetryConnectDialog", WndBase)
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local DisconnectType = require("DisconnectTypeNew")

UIRetryConnectDialog.pDialogFrame = nil
UIRetryConnectDialog.nLevel = nil
UIRetryConnectDialog.bClicked = nil

local function OnRefresh(self, tbParam)
    local nLevel = tbParam.nLevel
    if self.nLevel ~= nil then
        if self.nLevel >= nLevel then
            log("[ReconnectSystem] UI ShowRetryConnectDialog can't overload ", self.nLevel, nLevel)
            return            
        else
            log("[ReconnectSystem] UI ShowRetryConnectDialog overload ", self.nLevel, nLevel)
        end
    else
        log("[ReconnectSystem] UI ShowRetryConnectDialog")
    end
    self.bClicked = false
    self.nLevel = nLevel
    
    local Dialog = self.pDialogFrame

    if tbParam.l10nTitle ~= nil then
        Dialog:SetTitle(tbParam.l10nTitle)
    end
    if tbParam.l10nMessage ~= nil then
        Dialog:SetMessage(tbParam.l10nMessage)
    end

    if tbParam.l10nBtnOkText ~= nil then
        Dialog:SetPositiveText(tbParam.l10nBtnOkText)
    end
    if tbParam.funOK ~= nil then
        local fnCallback = function()
            log("[ReconnectSystem] ui try connect click ok ", self.bClicked)
            if self.bClicked == false then
                self.bClicked = true
                tbParam.funOK()
            end
        end
        Dialog:SetPositiveButtonCallback(fnCallback)
    end
    
    if tbParam.l10nBtnCancelText ~= nil then
        Dialog:SetNegativeText(tbParam.l10nBtnCancelText)
        Dialog:SetNegativeButtonVisible(true)
    else
        Dialog:SetNegativeButtonVisible(false)
    end
    if tbParam.funCancel ~= nil then
        local fnCallback = function()
            log("[ReconnectSystem] ui try connect click cancel ", self.bClicked)
            if self.bClicked == false then
                self.bClicked = true
                tbParam.funCancel()
            end
        end
        Dialog:SetNegativeButtonCallback(fnCallback)
    end
end

local function OnVerifyClose(self, bForce)
    if not bForce then
        if self.nLevel >= DisconnectType.disconnected then
            return
        end
    end  
    log("[ReconnectSystem] UI OnVerifyClose RetryConnectDialog")
    self:CloseSelf()
end

function UIRetryConnectDialog:OnLoad()
    local Dialog = self.PrefabHelper:CreatePrefab(UIDef.UP_DIALOG_FRAME)
    local pSlot = self.pWidgetRef.ovlContent:AddChild(Dialog.pWidgetRef)
    pSlot:SetHorizontalAlignment(EHorizontalAlignment.HAlign_Fill)
    pSlot:SetVerticalAlignment(EVerticalAlignment.VAlign_Fill)
    Dialog:SetCloseButtonVisible(false)

    self.pDialogFrame = Dialog
end

function UIRetryConnectDialog:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_RETRY_CONNECT_DIALOG, self, OnRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_CLOSE_RETRY_CONNECT_DIALOG, self, OnVerifyClose)
    
end

function UIRetryConnectDialog:OnShow()
    OnRefresh(self, self.tbOpenArgs)
    self.pDialogFrame:ShowDialog()
end

function UIRetryConnectDialog:OnHide()
    self.nLevel = nil
    self.bClicked = nil
end

return UIRetryConnectDialog