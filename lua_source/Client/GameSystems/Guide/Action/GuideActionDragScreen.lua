-----------------------------------------------------
--File Name    : GuideActionDrag.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFullUIControl  = require("GuideActionFullUIControl")
local GuideActionDragScreen     = luaclass("GuideActionDragScreen",GuideActionFullUIControl)
--import
local L10N                  = require("L10N")
-----------------------------------------------------
--local 
local TIME_TICK = 1 / 30

GuideActionDragScreen.nDragDirection    = nil
GuideActionDragScreen.nOriginYaw        = 0
GuideActionDragScreen.nOriginPitch      = 0
-----------------------------------------------------

function GuideActionDragScreen:Begin()
    GuideActionDragScreen.super.Begin(self)
    local tbTemplate = self.tbTemplate
    self:DebugLog("Begin,nDragDirection="..tbTemplate.nDragDirection)
    local nDragDirection = tbTemplate.nDragDirection
    self.nDragDirection = nDragDirection
    self:DebugLog("Begin,SetDragInfo="..tbTemplate.nDragDirection)
    self:CallSetDragInfo(nDragDirection, tbTemplate.nDragAngle, L10N:ToString(tbTemplate.l10nGuideText), 
            tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.nGuidePos, self)
end

function GuideActionDragScreen:DoAction(tbTemplate)
    GuideActionDragScreen.super.DoAction(self, tbTemplate)
    local nDragDirection = self.nDragDirection
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pRotation = pCameraManager:GetCameraRotation()
    if nDragDirection == 3 or nDragDirection == 2 then
        self.nOriginPitch = pRotation.Pitch
    else
        self.nOriginYaw = pRotation.Yaw
    end
    self.TimerHelper:NewTimerMethod(self, self.OnTickTimerFunc, TIME_TICK, true)
end

function GuideActionDragScreen:OnTickTimerFunc()
    local pCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local pRotation = pCameraManager:GetCameraRotation()
    if not pRotation then
        return
    end
    local tbTemplate = self.tbTemplate
    local nDragAngle = tbTemplate.nDragAngle
    if self.nDragDirection == 3 or self.nDragDirection == 2 then
        if math.abs(pRotation.Pitch - self.nOriginPitch) >= nDragAngle then
            self:EndAction()
        end
    else
        if math.abs(pRotation.Yaw - self.nOriginYaw) >= nDragAngle then
            self:EndAction()
        end
    end
    
end

return GuideActionDragScreen
