local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPTitleBar = luaclass("UPTitleBar", PrefabBase)

UPTitleBar.bCloseEnabled = true
UPTitleBar.bExitAnim = false
UPTitleBar.bWithAnim = false
UPTitleBar.OnBtnReturnClickedDelegate = nil
UPTitleBar.OnExitAnimFinishedDelegate = nil

function UPTitleBar:OnLoad()
    self.pbWindowBase = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowBase)
    self.OnBtnReturnClickedDelegate = self.pbWindowBase.OnBtnReturnClickedDelegate
    self.OnExitAnimFinishedDelegate = self.pbWindowBase.OnExitAnimFinishedDelegate
end

function UPTitleBar:ResetNSZOrder(nLeft, nRight, nContent)
    self.pWidgetRef.nsLeftContent.Slot:SetZOrder(nLeft)
    self.pWidgetRef.nsRightContent.Slot:SetZOrder(nRight)
    self.pWidgetRef.nsCenterContent.Slot:SetZOrder(nContent)
end

function UPTitleBar:SetTitleData(tbTitleData)
    self:SetTitleName(tbTitleData.l10nTitleName)
    self.pbWindowBase:SetTitleData(tbTitleData)
end

function UPTitleBar:SetTitleName(l10nTitleName)
    self.pWidgetRef.txtTitleNameDefault:SetText(l10nTitleName)
end

function UPTitleBar:PlayEnterAnim()
    self.bExitAnim = false
    self:PlayAnimation("animEnter", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPTitleBar:PlayExitAnim()
    if self.bExitAnim == false then
        self:PlayAnimation("animEnter", 0, 1, EUMGSequencePlayMode.Reverse, 1)
    end
    
end

function UPTitleBar:ShowDialog()
    self.bDialogShow = true
    self:PlayAnimation("animDialog", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPTitleBar:HideDialog()
    self.bDialogShow = false
    self:PlayAnimation("animDialog", 0, 1, EUMGSequencePlayMode.Reverse, 1)
end

function UPTitleBar:SetCloseEnabled(bEnabled)
    self.bCloseEnabled = bEnabled
    self.pbWindowBase:SetCloseEnabled(bEnabled)
end

return UPTitleBar

