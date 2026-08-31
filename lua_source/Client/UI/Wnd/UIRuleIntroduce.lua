-----------------------------------------------------
--File Name    : UIRuleIntroduce.lua
--Description  : 系统规则界面
-----------------------------------------------------

local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIRuleIntroduce = luaclass("UIRuleIntroduce", WndBase)

local WidgetAnimationHandle = require("WidgetAnimationHandle")

UIRuleIntroduce.nIsOpen = true

--override 
function UIRuleIntroduce:OnLoad()

end

function UIRuleIntroduce:OnShow()
    self:PlayEnterAnim()
    local pWidgetRef = self.pWidgetRef
    local tbOpenArgs = self.tbOpenArgs
    local szTitle = tbOpenArgs.szTitle
    if szTitle ~= nil then
        pWidgetRef.txtTitle:SetText(szTitle)
    end
    local szContent = tbOpenArgs.szContent
    if szContent ~= nil then
        pWidgetRef.ktxtContent:SetText(szContent)
    end
    local nLineHeightPercentage = tbOpenArgs.nLineHeightPercentage
    if nLineHeightPercentage == nil then
        nLineHeightPercentage = 1.5
    end
    pWidgetRef.ktxtContent:SetLineHeightPercentage(nLineHeightPercentage)
end

function UIRuleIntroduce:OnHide()
    
end

function UIRuleIntroduce:OnBindEvent(Helper)
    Helper:RegisterCppDelegate(self.pWidgetRef.imgBg.OnMouseButtonDownEvent,self,self.OnBgMouseButtonDown)
    Helper:RegisterCppDelegate(self.pWidgetRef.btnBack.OnClicked,self,self.OnClickClose)
    Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(self.pWidgetRef, self.pWidgetRef.animShow, self.OnAnimFinished, self))
end

function UIRuleIntroduce:OnBgMouseButtonDown(pGeometry, pMouseEvent)
    if self.nIsOpen == true then
        self:Close()
    end
    return WidgetBlueprintLibrary.Handled()
end

function UIRuleIntroduce:OnClickClose()
    if self.nIsOpen == true then
        self:Close()
    end
end

function UIRuleIntroduce:PlayEnterAnim()
    self.nIsOpen = true
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UIRuleIntroduce:PlayExitAnim()
    self.nIsOpen = false
    self:PlayAnimation("animShow", 0, 1, EUMGSequencePlayMode.Reverse, 1)
end

function UIRuleIntroduce:OnAnimFinished()
    if(not self.nIsOpen)then
        self:Close()
    end
end


return UIRuleIntroduce
