-----------------------------------------------------
--File Name    : GuideActionChangeShipDir.lua
--Description  : 指引动作
--废弃 2020.8.31
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideAction = require("GuideAction")
local GuideActionChangeShipDir = luaclass("GuideActionChangeShipDir",GuideAction)

--import
-- local PropertyGetterHelper = require("PropertyGetterHelper")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- local UIManager = require("UIManager")
-- -- local UIDef = require("UIDef")
-- local SelfTimerHelperClass = require("SelfTimerHelper")

-- --local Variable
-- GuideActionChangeShipDir.nRotationYaw = 0
-- GuideActionChangeShipDir.TimerHelper = nil
-- GuideActionChangeShipDir.bIsStop = false
-- GuideActionChangeShipDir.SelectWidget = nil

-- function GuideActionChangeShipDir:Begin()
--     GuideActionChangeShipDir.super.Begin(self)
--     self.TimerHelper = SelfTimerHelperClass()
--     local tbTemplate = self.tbTemplate
--     local Wnd = UIManager:GetWnd( self.tbTemplate.szUIName )
--     local pWidgetRef = Wnd.pWidgetRef
--     for k,v in ipairs(tbTemplate.tbPrefabName)do
--         pWidgetRef = pWidgetRef[v]
--         if(pWidgetRef == nil)then
--             self:LogError("GuideActionChangeShipDir:Begin,not found prefab,prefab name="..v)
--             return
--         end
--     end
--     local SelectWidget = pWidgetRef[self.tbTemplate.tbWidgetName[1]]
--     if(SelectWidget == nil)then
--         self:EndAction()
--         return
--     end
--     --暂停船只
--     local SelfObj = GamePlayerSelfHelper:Get()
--     local ShipActor = SelfObj:GetModelActor()
--     ShipActor.ShipMovementComponent:Deactivate()
--     --
--     self.SelectWidget = SelectWidget
--     SelectWidget:SetVisibility(ESlateVisibility.Visible)
--     self.EventHelper:RegisterCppDelegate(SelectWidget.OnPressed, self, self.OnSelect)
--     self.EventHelper:RegisterCppDelegate(SelectWidget.OnReleased, self, self.OnReleased)
--     --local Pos,Size,bIsFound = KMUMGLibrary.GetWidgetInfoAsAbsolute(SelectWidget)

-- end

-- function GuideActionChangeShipDir:End()
--     GuideActionChangeShipDir.super.End(self)
-- end

-- function GuideActionChangeShipDir:DoAction(tbTemplate)
--     -- local pGeometry = SelectWidget:GetCachedGeometry()
--     -- local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
--     -- local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
--     -- local GuideWnd = UIManager:OpenWnd(UIDef.UI_GUIDE)
--     -- GuideWnd:SetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
--     -- tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self)
--     -- local SelfObj = GamePlayerSelfHelper:Get()
--     -- local pShipRotation = PropertyGetterHelper.GetProperty(PropertyGetterHelper.ShipRotation,SelfObj)
--     -- self.nRotationYaw = pShipRotation.Yaw
--     -- self.TimerHelper:NewTimerMethod(self,self.OnTimerFunc, 0.5, true)
-- end

-- function GuideActionChangeShipDir:OnSelect()
--     self:DebugLog("GuideActionChangeShipDir:OnSelect")
--     local SelfObj = GamePlayerSelfHelper:Get()
--     local ShipActor = SelfObj:GetModelActor()
--     ShipActor.ShipMovementComponent:Activate()
-- end

-- function GuideActionChangeShipDir:OnReleased()
--     if(self.bIsStop)then
--         return
--     end
--     local SelfObj = GamePlayerSelfHelper:Get()
--     local ShipActor = SelfObj:GetModelActor()
--     ShipActor.ShipMovementComponent:Deactivate()
-- end

-- function GuideActionChangeShipDir:OnTimerFunc()
--     GuideActionChangeShipDir.super.OnTimerFunc(self)
--     -- local SelfObj = GamePlayerSelfHelper:Get()
--     -- local pShipRotation = PropertyGetterHelper.GetProperty(PropertyGetterHelper.ShipRotation,SelfObj)
--     -- if(pShipRotation == nil)then
--     --     return
--     -- end
--     -- local nDiff = math.abs(pShipRotation.Yaw - self.nRotationYaw)
--     -- if(self.nRotationYaw < 0 and pShipRotation.Yaw > 0)then
--     --     nDiff = 360 - math.abs(self.nRotationYaw)  - pShipRotation.Yaw
--     -- elseif(self.nRotationYaw > 0 and pShipRotation.Yaw < 0)then
--     --     nDiff = self.nRotationYaw + math.abs(pShipRotation.Yaw)
--     -- end
--     -- self:DebugLog("GuideActionChangeShipDir:OnTimerFunc,nDiff="..nDiff)
--     -- if(nDiff >= self.tbTemplate.nAngleOffset)then
--     --     self.bIsStop = true
--     --     if(self.SelectWidget ~= nil)then
--     --         self.SelectWidget.OnReleased:call()
--     --     end
--     --     self:ForceEndCurrentGroup()
--     --     self:EndAction()
--     --     if(SelfObj ~= nil)then
--     --         local ShipActor = SelfObj:GetModelActor()
--     --         if(ShipActor ~= nil and ShipActor.ShipMovementComponent ~= nil)then
--     --             ShipActor.ShipMovementComponent:Activate()
--     --         end
--     --     end
--     -- end
-- end

return GuideActionChangeShipDir
