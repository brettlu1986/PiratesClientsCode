-----------------------------------------------------
--File Name    : UPHubBuffTip.lua
--Author       : Zuo Kun
--Create Time  : 2018-02-26
--Description  : UPHubBuffTip
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPTipBase = require("UPTipBase")
local UPHubBuffTip = luaclass("UPHubBuffTip",UPTipBase)
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local Timer = require("Timer")

UPHubBuffTip.tbTip = {}
UPHubBuffTip.tbTimerHander = nil 

local function GetBuffRemainTime(tbBuff)
    local nDuration = tbBuff.nDuration
    local nEndTime = tbBuff.nEndTime
    local nRemainSeconds = nEndTime - GlobalVariableSystem:GetServerTimeUtc()
    local nRemainPercent = nRemainSeconds / nDuration
    return nRemainSeconds, nRemainPercent
end

-- TODO: L10N the Buff Description
local function GetBuffDesc(tbBuff)
    local nRemainSeconds = GetBuffRemainTime(tbBuff)
    if nRemainSeconds <= 0 then 
        return nil 
    end 
    -- Making remain time more readable
    if nRemainSeconds < 60 then
        return string.format("%s\n\n剩余时间：%d秒", tbBuff.szDesc, nRemainSeconds)
    elseif nRemainSeconds < 3600 then
        local nRemainMinutes = nRemainSeconds // 60
        return string.format("%s\n\n剩余时间：%d分钟", tbBuff.szDesc, nRemainMinutes)
    elseif nRemainSeconds < 86400 then
        local nRemainHours = nRemainSeconds // 3600
        return string.format("%s\n\n剩余时间：%d小时", tbBuff.szDesc, nRemainHours)
    else
        local nRemainDays = nRemainSeconds // 86400
        return string.format("%s\n\n剩余时间：%d天", tbBuff.szDesc, nRemainDays)
    end
end

local function GetTip(self, tbBuff)
    -- local tbBuff = tbBuff
    assert(tbBuff)
    local tbTip = self.tbTip
    if not tbTip then
        tbTip = {}
        self.tbTip = tbTip
    end
    tbTip.szTitle = tbBuff.szName
    tbTip.szDetail = GetBuffDesc(tbBuff)
    return tbTip
end


local function HiddenOthers(self)
    local pWidget = self.pWidgetRef
    pWidget.sizeItem:SetVisibility(ESlateVisibility.Collapsed)
    pWidget.ktxtDurability:SetVisibility(ESlateVisibility.Collapsed)
    pWidget.hboxCost:SetVisibility(ESlateVisibility.Collapsed)
    pWidget.hboxExpireTime:SetVisibility(ESlateVisibility.Collapsed)
end

--public interface
function UPHubBuffTip:OnSetData(tbBuff)
    UPHubBuffTip.super.OnSetData(self,tbBuff)
    HiddenOthers(self)

    if not self.tbTimerHander then 
        local fnTimerCallback = function()
            self:SetData(tbBuff)
        end        
        self.tbTimerHander = Timer.StartTimer(self.tbTimerHander, fnTimerCallback, 1, true)
    end 

    local tbTipData = GetTip(self, tbBuff)
    if not tbTipData.szDetail then 
        self.Owner:CloseTip()
        return 
    end 
    
    local pWidget = self.pWidgetRef
    --标题
    pWidget.ktxtTitle:SetText(tbTipData.szTitle)
    if tbTipData.szSubTitle then
        pWidget.ktxtSubTitle:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidget.ktxtSubTitle:SetText(tbTipData.szSubTitle)
    else
        pWidget.ktxtSubTitle:SetVisibility(ESlateVisibility.Collapsed)
    end
    --描述信息
    pWidget.ktxtConnet:SetText(tbTipData.szDetail)
    --隐藏技能图标背景
    pWidget.imgSkillBg:SetVisibility(ESlateVisibility.Collapsed)
end


function UPHubBuffTip:OnHide()
    if self.tbTimerHander then 
        self.tbTimerHander:Clear()
        self.tbTimerHander = nil 
    end 
end 

return UPHubBuffTip

