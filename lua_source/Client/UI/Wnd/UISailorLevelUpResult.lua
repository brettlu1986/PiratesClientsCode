-----------------------------------------------------
--File Name    : UISailorLevelUpResult.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-04
--Description  : 船水手界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISailorLevelUpResult = luaclass("UISailorLevelUpResult", WndBase)

function UISailorLevelUpResult:OnEnter()
    local tbOpenArgs = self.tbOpenArgs
    local nLastTotalGrade = tbOpenArgs.nLastTotalGrade
    local nCurrentTotalGrade = tbOpenArgs.nCurrentTotalGrade
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtLastGrade:SetText(nLastTotalGrade)
    pWidgetRef.txtCurrentGrade:SetText(nCurrentTotalGrade)
    pWidgetRef.txtTotalGrade:SetText(nCurrentTotalGrade)

    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UISailorLevelUpResult:OnHide()
    self:PlayAnimation("animHide", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        self:HideFinished()
    end)
    return false
end

function UISailorLevelUpResult:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnClose.OnClicked, self, self.CloseSelf)
end

return UISailorLevelUpResult