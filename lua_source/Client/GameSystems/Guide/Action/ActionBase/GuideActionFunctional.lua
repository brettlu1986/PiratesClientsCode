-----------------------------------------------------
--File Name    : GuideActionFunctional.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                = require("luaclass")
local GuideActionBase         = require("GuideActionBase")
local GuideActionFunctional   = luaclass("GuideActionFunctional", GuideActionBase)
-----------------------------------------------------

--member veriable
-----------------------------------------------------

function GuideActionFunctional:AfterDoAction(tbTemplate)
    self:DebugLog("AfterDoAction")
    GuideActionFunctional.super.AfterDoAction(self, tbTemplate)
    self:EndAction()
end

function GuideActionFunctional:PreEnd()
    self:DebugLog("PreEnd")
end

function GuideActionFunctional:End()
    GuideActionFunctional.super.End(self) 
end

function GuideActionFunctional:CallSetDragInfo(nDirection, nAngle, szGuideText, szGuideIcon, bModal, nGuidePos, GuideActionRef)
    local tbParams = {}
    self:AddValue(tbParams, "nDirection", nDirection)
    self:AddValue(tbParams, "nAngle", nAngle)
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "szGuideIcon", szGuideIcon)
    self:AddValue(tbParams, "bModal", bModal)
    self:AddValue(tbParams, "nGuidePos", nGuidePos)
    self:AddValue(tbParams, "GuideActionRef", GuideActionRef)
    self:CallUIFunc("SetDragInfo", tbParams)
end

function GuideActionFunctional:CallDelayClickAnyWhere(nDelayTime)
    self:CallUIFunc("DelayClickAnyWhere", nDelayTime)
end

function GuideActionFunctional:CallSetDragOnly(szGuideText, szGuideIcon, nGuidePos)
    self:DebugLog("CallSetCentralGuide")
    local tbParams = {}
    self:AddValue(tbParams, "szGuideText", szGuideText)
    self:AddValue(tbParams, "szGuideIcon", szGuideIcon)
    self:AddValue(tbParams, "nGuidePos", nGuidePos)
    
    self:CallUIFunc("SetDragOnly", tbParams)
end

function GuideActionFunctional:CallShowShipWeaponVideoText()
    self:DebugLog("CallSetCentralGuide")
    local tbParams = {}
    
    self:CallUIFunc("ShowShipWeaponVideoText", tbParams)
end


return GuideActionFunctional
