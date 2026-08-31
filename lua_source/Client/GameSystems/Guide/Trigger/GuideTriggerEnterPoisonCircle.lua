-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerEnterPoisonCircle = luaclass("GuideTriggerEnterPoisonCircle", GuideTrigger)

-- local GameObjectTypeDef         = require("GameObjectTypeDef")
local ClientEventDef            = require("ClientEventDef")
-- local GameObjectSystem          = dynamic_require("GameObjectSystem")
local SelfTimerHelperClass      = require("SelfTimerHelper")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
-- local PoisonCircleSystem        = require("PoisonCircleSystem")
-----------------------------------------------------
local TIME_TICK = 1--3 / 10

GuideTriggerEnterPoisonCircle.pbTrigger     = nil
GuideTriggerEnterPoisonCircle.TimerHelper   = nil
GuideTriggerEnterPoisonCircle.tbPlayerSelf  = nil
-----------------------------------------------------

local function IsAddPoisionCircleBuff(self)
    local tbBuffList = {30001,30002,30003,30004,30005,30006,30007,30008,30009}
    for i, buffId in ipairs(tbBuffList) do
        local bInPoison = self.tbPlayerSelf.BuffComponentClient:IsExistBuffById(buffId)
        if bInPoison then
            return true
        end
    end
    return false
end

function GuideTriggerEnterPoisonCircle:OnPoisonCircleUpdate(tbPacket)
    self:CheckEnterPoisonCircle()
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_UPDATE, self, self.OnPoisonCircleUpdate)
end

function GuideTriggerEnterPoisonCircle:CheckEnterPoisonCircle()
    -- local tbGameObjectList = GameObjectSystem:GetAllGameObjects()
    -- self:DebugLog("GuideTriggerEnterPoisonCircle:CheckEnterPoisonCircle tbGameObjectList = " .. tostring(tbGameObjectList))
    -- logerror("GuideTriggerEnterPoisonCircle:CheckEnterPoisonCircle tbGameObjectList = " .. tostring(tbGameObjectList))
    -- for _, GameObject in pairs(tbGameObjectList) do
    --     if GameObject:GetObjectType() == GameObjectTypeDef.Trigger then
    --         if GameObject.nResId == 22 then -- 是毒圈先写死
    --             local pbTrigger = GameObject.pUEActor
    --             self.pbTrigger = pbTrigger
    --             local nRadius = pbTrigger.CollisionRadius
    --             self:DebugLog("GuideTriggerEnterPoisonCircle:CheckEnterPoisonCircle1 nRadius = " .. tostring(nRadius))
    --         end
    --     end
    -- end
    self.TimerHelper:NewTimerMethod(self, self.OnTickTimerFunc, TIME_TICK, true)
end

function GuideTriggerEnterPoisonCircle:OnTickTimerFunc()
    local bInPoison = IsAddPoisionCircleBuff(self)
    if bInPoison then
        self:Trigger()
    else
        self:Break()
    end
    -- if not self.pbTrigger or not self.pbTrigger.CollisionRadius then
    --     return
    -- end
    -- logerror("GuideTriggerEnterPoisonCircle:OnTickTimerFunc 2")
    -- local nRadius = self.pbTrigger.CollisionRadius
    -- local PlayerSelf = GamePlayerSelfHelper:Get()
    -- local pCurLocation = PlayerSelf:GetLocation()
    -- local pCurVectior = Vector2D{X = pCurLocation.X, Y = pCurLocation.Y}
    -- local pDestVector = PoisonCircleSystem.pDestVector
    -- if pDestVector then
    --     local nDistance = math.sqrt((pDestVector.X - pCurVectior.X)^2 + (pDestVector.Y - pCurVectior.Y)^2)
    --     logerror("GuideTriggerEnterPoisonCircle:CheckEnterPoisonCircle2 nRadius = " .. tostring(nRadius) .. " playerDistance = " .. tostring(nDistance))
    --     if nDistance >= nRadius then
    --         self:Trigger()
    --     end
    -- end
    -- if math.abs(nDistance - nRadius) < 300000 then
    --     self:Trigger()
    -- end
end

--override
function GuideTriggerEnterPoisonCircle:Begin()
    self.TimerHelper = SelfTimerHelperClass()
    GuideTriggerEnterPoisonCircle.super.Begin(self)
    self.tbPlayerSelf = GamePlayerSelfHelper:Get()
end

function GuideTriggerEnterPoisonCircle:End()
    self:DebugLog("end TimerHelper = " .. tostring(self.TimerHelper))
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
        self.TimerHelper = nil
    end
    GuideTriggerEnterPoisonCircle.super.End(self)
end

function GuideTriggerEnterPoisonCircle:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_UPDATE, self, self.OnPoisonCircleUpdate)
end

return GuideTriggerEnterPoisonCircle
