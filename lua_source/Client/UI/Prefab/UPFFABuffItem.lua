-----------------------------------------------------
--File Name    : UPFFABuffItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-10
--Description  : 战斗界面顶部Buff面板Item
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFABuffItem = luaclass("UPFFABuffItem", PrefabBase)

local UIDef = require("UIDef")
local MathUtil = require("MathUtil")
local UIToolTipHelper = require("UIToolTipHelper")
local BattleBuffDataTable = require("BattleBuffDataTable")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

UPFFABuffItem.bTipShowing = false
UPFFABuffItem.nTemplateId = -1
UPFFABuffItem.nLevel = -1
UPFFABuffItem.nOverlapCount = -1
UPFFABuffItem.nUpdateTime = -1

-- 刷新Buff数量显示
local function UpdateOverlapCount(self)
    if self.nOverlapCount > 1 then
        self.pWidgetRef.txtCount:SetText(self.nOverlapCount)
        self.pWidgetRef.txtCount:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.txtCount:SetVisibility(ESlateVisibility.Collapsed)
    end
end

-- 刷新Buff时间半分比显示
local function UpdateTimePercent(self)
    if self.nLastTime > 0 then
        local nRemainTime = MathUtil.Clamp(self.nUpdateTime + self.nLastTime - GlobalVariableSystem:GetDSTimeSeconds(), 0, self.nLastTime)
        local nPercent = nRemainTime / self.nLastTime
        self.pWidgetRef.cpgbBuffStatus:StartAnimation(nPercent, 0, nRemainTime)
    else
        self.pWidgetRef.cpgbBuffStatus:SetPercent(1)
    end
end

local function ShowTips(self)
    if not self.bTipShowing then
        local tbTipData = BattleBuffDataTable:GetStatusDescTipData(self.nTemplateId, self.nLevel)
        if not tbTipData then
            tbTipData = {szTitle = "None", szDetail = "None"}
            logerror("[ULBuffList]", self, self.nTemplateId, self.nLevel)
        end
        UIToolTipHelper:ShowCustomTipInAutoLayout(UIDef.UP_FFA_BUFF_TIPS, tbTipData, self.pWidgetRef)
        self.bTipShowing = true
    end
end

local function HideTips(self)
    if self.bTipShowing then
        UIToolTipHelper:HideTip()
        self.bTipShowing = false
    end
end

function UPFFABuffItem:OnBindEvent(Helper)
    Helper:RegisterCppDelegate(self.pWidgetRef.btnBuff.OnPressed, self, ShowTips)
    Helper:RegisterCppDelegate(self.pWidgetRef.btnBuff.OnReleased, self, HideTips)
end

function UPFFABuffItem:Start(nInstanceId, nTemplateId, nLevel, nOverlapCount, nUpdateTime)
    self.nTemplateId = nTemplateId
    self.nLevel = nLevel
    local tbTemplate = BattleBuffDataTable:GetTemplate(nTemplateId)
    self.nLastTime = tbTemplate.nTime

    local tbResTemplate = BattleBuffDataTable:GetResTemplate(nTemplateId)
    local pIconRes = tbResTemplate.szIconRes:load()
    self.pWidgetRef.cpgbBuffStatus:SetFillImage(pIconRes)
    self.pWidgetRef.cpgbBuffStatus:SetBackgroundImage(pIconRes)

    self:Update(nOverlapCount, nUpdateTime)
end

function UPFFABuffItem:Update(nOverlapCount, nUpdateTime)
    self.nOverlapCount = nOverlapCount
    self.nUpdateTime = nUpdateTime

    UpdateOverlapCount(self)
    UpdateTimePercent(self)
end

function UPFFABuffItem:Clear()
    HideTips(self)
    self.pWidgetRef.cpgbBuffStatus:StopAnimation()

    self.nTemplateId = -1
    self.nLevel = -1
    self.nOverlapCount = -1
    self.nUpdateTime = -1
end

return UPFFABuffItem
