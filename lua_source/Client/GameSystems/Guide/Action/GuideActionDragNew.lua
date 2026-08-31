-----------------------------------------------------
--File Name    : GuideActionDrag.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionDragNew            = luaclass("GuideActionDragNew", GuideActionFullUIControl)

--import
local L10N                      = require("L10N")
local CameraGameHelper         = require("CameraGameHelper")

--local 
local TIME_TICK             = 1 / 30
local TARGET_MATCH_COUNT    = 1
local MATCH_COUNT           = 0

GuideActionDragNew.LeftTargetScope = nil
GuideActionDragNew.RightTargetScope = nil

function GuideActionDragNew:Begin()
    GuideActionDragNew.super.Begin(self)
    local tbTemplate = self.tbTemplate
    MATCH_COUNT = 0
    local bP1 = tonumber(tbTemplate.tbParam[1]) >= 1
    local bP2 = tonumber(tbTemplate.tbParam[2]) >= 1
    local bP3 = tonumber(tbTemplate.tbParam[3]) >= 1
    local bP4 = tonumber(tbTemplate.tbParam[4]) >= 1
    CameraGameHelper.SetLockUpScroll(bP1)
    CameraGameHelper.SetLockDownScroll(bP2)
    CameraGameHelper.SetLockLeftScroll(bP3)
    CameraGameHelper.SetLockRightScroll(bP4)
end


function GuideActionDragNew:DoAction(tbTemplate)
    GuideActionDragNew.super.DoAction(self, tbTemplate)
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pRotation = pCameraManager:GetCameraRotation()
    self.nRotationYaw = pRotation.Yaw
    local nDragAngle = tbTemplate.nDragAngle%360  
    local nDragDirection = tbTemplate.nDragDirection
    if nDragDirection == 0 then  --左
        self.LeftTargetScope = self.nRotationYaw - nDragAngle
        local nTargetAngle = self.LeftTargetScope
        if nTargetAngle <= -180 then
            self.LeftTargetScope = 360 - math.abs(nTargetAngle)
        end
        self:DebugLog(" GuideActionDragNew LeftTargetScope = " .. tostring(self.LeftTargetScope))
    elseif nDragDirection == 1 then  --右
        self.RightTargetScope = self.nRotationYaw + nDragAngle
        local nTargetAngle = self.RightTargetScope
        if nTargetAngle >= 180 then
            self.RightTargetScope = math.abs(nTargetAngle) - 360
        end
        self:DebugLog(" GuideActionDragNew RightTargetScope = " .. tostring(self.RightTargetScope))
    end

    self:DebugLog(" GuideActionDragNew nDragAngle = " .. nDragAngle .. " self.nRotationYaw = " .. self.nRotationYaw  .. " GuideText = " .. L10N:ToString(tbTemplate.l10nGuideText))
    self:CallSetDragInfo(nDragDirection, tbTemplate.nDragAngle, L10N:ToString(tbTemplate.l10nGuideText), 
            tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.nGuidePos, self)
    if tbTemplate.bEnable then
        self.TimerHelper:NewTimerMethod(self, self.OnTickTimerFunc, TIME_TICK, true)
    end
end

function GuideActionDragNew:OnTickTimerFunc()
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pRotation = pCameraManager:GetCameraRotation()
    if not pRotation then
        return
    end
    local tbTemplate = self.tbTemplate
    local nCurrentRotationYaw = pRotation.Yaw
    -- local bMatch = false
    --self:DebugLog(" GuideActionDragNew:OnTimerFunc pRotation.Yaw = " .. tostring(pRotation.Yaw) .. " pRotation.Roll = " .. tostring(pRotation.Roll) .. " pRotation.Pitch = " .. tostring(pRotation.Pitch))
    --logdebug(" GuideActionDragNew:OnTimerFunc pRotation.Pitch = " .. tostring(pRotation.Pitch))
    local nAngleOffset = tbTemplate.nAngleOffset
    if self.LeftTargetScope ~= nil and tbTemplate.nDragDirection == 0 then --左
        if nCurrentRotationYaw <= self.LeftTargetScope + nAngleOffset and nCurrentRotationYaw >= self.LeftTargetScope - nAngleOffset then
            self:DebugLog(" GuideActionDragNew Match LeftTarget")
            MATCH_COUNT = MATCH_COUNT + 1
        end
        
    elseif self.RightTargetScope ~= nil and tbTemplate.nDragDirection == 1 then --右
        if nCurrentRotationYaw <= self.RightTargetScope + nAngleOffset and nCurrentRotationYaw >= self.RightTargetScope - nAngleOffset then
            self:DebugLog(" GuideActionDragNew Match Right")
            MATCH_COUNT = MATCH_COUNT + 1
        end
    end
    
    if MATCH_COUNT >= TARGET_MATCH_COUNT then
        self:CallShowSpaceScreen(true)
        CameraGameHelper.SetLockUpScroll(false)
        CameraGameHelper.SetLockDownScroll(false)
        CameraGameHelper.SetLockLeftScroll(false)
        CameraGameHelper.SetLockRightScroll(false)
        self:DebugLog("self.nMatchCount,self.bMatch=", self.bMatch)
        self:EndAction()
    end
end

return GuideActionDragNew
