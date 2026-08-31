-----------------------------------------------------
--File Name    : GuideTriggerChangeToShip.lua
--Description  : 人变船指引
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerChangeToShip  = luaclass("GuideTriggerChangeToShip", GuideTrigger)

local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local CommonEventDef = require("CommonEventDef")

-----------------------------------------------------
GuideTriggerChangeToShip.tbParam         = nil
GuideTriggerChangeToShip.nActivePlayerLv = nil

-----------------------------------------------------
local function CheckChangeToShip(self, tbGameObject)
    local nInsId = tbGameObject:GetServerInstanceId()
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    --切船成功
    if nInsId == nCharacterInstanceId and tbGameObject:IsShip() then  
        self:Trigger()
    else
        self:Break()
    end
end

function GuideTriggerChangeToShip:End()
    GuideTriggerChangeToShip.super.End(self)
end
--override
function GuideTriggerChangeToShip:Begin()
    GuideTriggerChangeToShip.super.Begin(self)
end

function GuideTriggerChangeToShip:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, CheckChangeToShip)
end

return GuideTriggerChangeToShip
