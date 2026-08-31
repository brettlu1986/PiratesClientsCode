-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerGoNextSafeZone    = luaclass("GuideTriggerGoNextSafeZone", GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local ClientEventDef                = require("ClientEventDef")
-----------------------------------------------------

function GuideTriggerGoNextSafeZone:OnPoisonCircleUpdate(tbPacket)
    self:DebugLog("OnPoisonCircleUpdate ")
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local pCurLocation = PlayerSelf:GetLocation()
    local pCurVectior = Vector2D{X = pCurLocation.X, Y = pCurLocation.Y}
    local pDestVector = Vector2D{X = tbPacket.nNextX, Y = tbPacket.nNextY}
    local nDestRadius = tbPacket.nNextRadius
    local nDistance = math.sqrt((pDestVector.X - pCurVectior.X)^2 + (pDestVector.Y - pCurVectior.Y)^2)
    if nDistance > nDestRadius then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerGoNextSafeZone:Begin()
    GuideTriggerGoNextSafeZone.super.Begin(self)
end

function GuideTriggerGoNextSafeZone:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_UPDATE, self, self.OnPoisonCircleUpdate)
end

return GuideTriggerGoNextSafeZone
