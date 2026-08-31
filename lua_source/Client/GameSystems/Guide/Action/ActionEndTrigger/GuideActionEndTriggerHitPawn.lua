-----------------------------------------------------
--File Name    : GuideActionEndTriggerHitPawn.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerHitPawn          = luaclass("GuideActionEndTriggerHitPawn", GuideActionEndTriggerBase)

local GamePlayerSelfHelper      =   require("GamePlayerSelfHelper")
local GameObjectSystem          =   dynamic_require("GameObjectSystem")
local GameplayUtilityHelper     = require("GameplayUtilityHelper")

local TRACE_CHECK_INTERVAL   = 0.2
local ViewPortVectore        = Vector2D()
local DeprojectScreenToWorld = GameplayStatics.DeprojectScreenToWorld
local nInteractionDistance   = 160000

GuideActionEndTriggerHitPawn.tbTraceTimerHandler = nil
-----------------------------------------------------

local function ClearTraceTimer(self)
    local tbTraceTimerHandler = self.tbTraceTimerHandler
    if tbTraceTimerHandler then
        self.TimerHelper:ClearTimer(tbTraceTimerHandler)
        self.tbTraceTimerHandler = nil
    end
end

local function TraceActor(self, nTargetTypeId)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local tbActorsToIgnore = {PlayerSelf.pUEActor}
    local nViewX, nViewY = PlayerSelf.pUEController:GetViewportSize()
    ViewPortVectore.X = nViewX*0.5
    ViewPortVectore.Y = nViewY*0.5
    local __, pStartPos, pWorldDirection = DeprojectScreenToWorld(PlayerSelf.pUEController, ViewPortVectore)
    local nEndPoxX, nEndPoxY, nEndPoxZ = pStartPos.X + pWorldDirection.X*nInteractionDistance, pStartPos.Y + pWorldDirection.Y*nInteractionDistance, pStartPos.Z + pWorldDirection.Z*nInteractionDistance
    local pEndPos = Vector{X = nEndPoxX, Y = nEndPoxY, Z = nEndPoxZ}
    local bRet, pHitResult = GameplayUtilityHelper.TraceActor(GWorld, pStartPos, pEndPos, tbActorsToIgnore, false, true, true, true, true, false, GWorld)
    if bRet then
        local nUniqueId = EngineExtActorShell.GetActorUniqueId(pHitResult.Actor)
        local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
        if tbGameObject then
            self:DebugLog("tbGameObject.ObjectType = " .. tostring(tbGameObject.ObjectType) .. " nTargetTypeId = " .. nTargetTypeId .. " " .. type(tbGameObject.ObjectType))
        end
        if tbGameObject and tbGameObject.ObjectType == nTargetTypeId then
            ClearTraceTimer(self)
            self:Triggered()
        end
    end
end

local function StartTraceTimer(self, tbParam)
    ClearTraceTimer(self)
    local szTargetTypeId = tbParam[1]
    local szTickCount = tbParam[2]
    local nTickCount = TRACE_CHECK_INTERVAL
    if szTickCount then
        nTickCount = tonumber(szTickCount)
    end
    if not szTargetTypeId then
        self:Triggered()
        return
    end
    self.tbTraceTimerHandler = self.TimerHelper:NewTimerMethod(self, function() TraceActor(self, tonumber(szTargetTypeId)) end, nTickCount, true)
end

function GuideActionEndTriggerHitPawn:BindEvent(tbParam)
    GuideActionEndTriggerHitPawn.super.BindEvent(self, tbParam)
    StartTraceTimer(self, tbParam)
end

return GuideActionEndTriggerHitPawn
