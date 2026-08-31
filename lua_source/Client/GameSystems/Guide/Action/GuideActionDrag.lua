-----------------------------------------------------
--File Name    : GuideActionDrag.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionDrag               = luaclass("GuideActionDrag", GuideActionFullUIControl)

--import
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local L10N                  = require("L10N")

--local 
local TIME_TICK = 1 / 30

GuideActionDrag.LeftTargetScope = nil
GuideActionDrag.RightTargetScope = nil
GuideActionDrag.nLastDragDir = nil
GuideActionDrag.nMatchCount = 0
GuideActionDrag.bLastCameraRotationLag = nil


function GuideActionDrag:Begin()
    GuideActionDrag.super.Begin(self)
    local tbTemplate = self.tbTemplate
    
    local ShipActor = GamePlayerSelfHelper:Get():GetModelActor()
    if(ShipActor == nil)then
        self:LogError("GuideActionDrag:Begin, ship actor is nil")
        return
    end
    local ShipInputComponent = ShipActor.ShipInputComponent
    local PlayerInputComponent = ShipActor.PlayerInputComponent

    self:DebugLog("GuideActionDrag:Begin,nDragDirection="..tbTemplate.nDragDirection)
    if(ShipInputComponent ~= nil)then
        ShipInputComponent:LockCameraLeftInputForNewPlayer(true)
        ShipInputComponent:LockCameraRightInputForNewPlayer(true)
    elseif(PlayerInputComponent ~= nil)then
        PlayerInputComponent:LockCameraLeftInputForNewPlayer(true)
        PlayerInputComponent:LockCameraRightInputForNewPlayer(false)
    end    
end

function GuideActionDrag:DoAction(tbTemplate)
    GuideActionDrag.super.DoAction(self, tbTemplate)
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pRotation = pCameraManager:GetCameraRotation()
    self.nRotationYaw = pRotation.Yaw
    local nAngleOffset = tbTemplate.nAngleOffset%360
    local nDragDirection = tbTemplate.nDragDirection
    if(nDragDirection == 0)then  --左
        self.LeftTargetScope = self.nRotationYaw - nAngleOffset
        local nTargetAngle = self.LeftTargetScope
        if nTargetAngle <= -180 then
            self.LeftTargetScope = 360 - math.abs(nTargetAngle)
        end
    elseif(nDragDirection == 1)then  --右
        self.RightTargetScope = self.nRotationYaw + nAngleOffset
        local nTargetAngle = self.RightTargetScope
        if nTargetAngle >= 180 then
            self.RightTargetScope = math.abs(nTargetAngle) - 360
        end 
    end
    self:CallSetDragInfo(nDragDirection, tbTemplate.nDragAngle, L10N:ToString(tbTemplate.l10nGuideText), 
            tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.nGuidePos, self)
    self.TimerHelper:NewTimerMethod(self, self.OnTickTimerFunc, TIME_TICK, true)
end

function GuideActionDrag:OnTickTimerFunc()
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pRotation = pCameraManager:GetCameraRotation()
    if not pRotation then
        return
    end
    local tbTemplate = self.tbTemplate
    local nCurrentRotationYaw = pRotation.Yaw
    local bMatch = false
    -- self:DebugLog(" GuideActionDrag:OnTickTimerFunc pRotation.Yaw = " .. tostring(pRotation.Yaw) .. " pRotation.Roll = " .. tostring(pRotation.Roll) .. " pRotation.Pitch = " .. tostring(pRotation.Pitch))
    if(self.LeftTargetScope ~= nil and tbTemplate.nDragDirection == 0)then --左
        if(nCurrentRotationYaw <= self.LeftTargetScope)then
            bMatch = true
        end
        
    elseif(self.RightTargetScope ~= nil and tbTemplate.nDragDirection == 1)then --右
        if(nCurrentRotationYaw >= self.RightTargetScope)then
            bMatch = true
        end
    end
    
    if bMatch then
        self:CallShowSpaceScreen(true)
        local ShipActor = GamePlayerSelfHelper:Get():GetModelActor()
        if(ShipActor)then
            local ShipInputComponent = ShipActor.ShipInputComponent
            local PlayerInputComponent = ShipActor.PlayerInputComponent
            if ShipInputComponent ~= nil then
                ShipInputComponent:LockCameraLeftInputForNewPlayer(false)
                ShipInputComponent:LockCameraRightInputForNewPlayer(false)
            elseif PlayerInputComponent ~= nil then
                PlayerInputComponent:LockCameraLeftInputForNewPlayer(false)
                PlayerInputComponent:LockCameraRightInputForNewPlayer(false)
            end
        end
        self:EndAction()
    end
end

return GuideActionDrag
