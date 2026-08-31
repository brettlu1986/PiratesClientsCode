-----------------------------------------------------
--File Name    : UPWidgetDialog.lua
--Author       : Zuo Kun
--Create Time  : 2017-05-10
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPDialogWidget = luaclass("UPDialogWidget", UPWidgetBase)
local UISetUtils = require("UISetUtils")

local DIALOG_DURATION_TIME = 5
UPDialogWidget.bCloseComponentOnEnd = false 

function UPDialogWidget:OnWidgetCreated()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end 

function UPDialogWidget:RefreshWidget(tbParams)
    -- logdebug("RefreshWidget")
    if tbParams.bCloseComponentOnEnd ~= nil then 
        self.bCloseComponentOnEnd = tbParams.bCloseComponentOnEnd
        if self.bCloseComponentOnEnd then 
            self.Owner:SetVisibility(true)
        end 
    end 
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.txtTips:SetVisibility(ESlateVisibility.Visible)
    -- self.pWidgetRef.ovlHead:SetVisibility(ESlateVisibility.Collapsed)
    self.TimerHelper:ClearAllTimer()
    self.TimerHelper:NewTimerMethod(self, self.OnTipsTimeEnd, DIALOG_DURATION_TIME, false)
    -- if string.len( tbParams.szText ) > 0 then 
        self.pWidgetRef.vboxText:SetVisibility(ESlateVisibility.Visible)
        self.pWidgetRef.txtTips:SetText( tbParams.szText )
    -- else
        -- self.pWidgetRef.vboxText:SetVisibility(ESlateVisibility.Collapsed)
    -- end
    local szPortraitPath = tbParams.szPortraitPath
    if szPortraitPath and string.len(szPortraitPath) > 0 then 
        UISetUtils.SetImageBrushRes(self.pWidgetRef.imgPlayerHead, szPortraitPath:load())
        self.pWidgetRef.imgPlayerHead:SetVisibility(ESlateVisibility.Visible)
    else
        self.pWidgetRef.imgPlayerHead:SetVisibility(ESlateVisibility.Collapsed)
    end 
end 


function UPDialogWidget:OnTipsTimeEnd()
    -- logdebug("OnTipsTimeEnd  ")
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetRef.vboxText:SetVisibility(ESlateVisibility.Collapsed)
    self.pWidgetComponent:RequestRedraw()
    -- self:SetHeadInfo(self.nQuestType)
    -- self.OnTipsHide:Fire()
    if self.bCloseComponentOnEnd then 
        self.Owner:SetVisibility(false)
    end 
end

return UPDialogWidget