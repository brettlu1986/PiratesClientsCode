-----------------------------------------------------
--File Name    : GuideTriggerNpcDead.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerNpcDead = luaclass("GuideTriggerNpcDead",GuideTrigger)

local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GuideSharedInfoHelper = require("GuideSharedInfoHelper")

GuideTriggerNpcDead.tbTakeDamageNpc = {}

local function OnPawnDead(self, tbGameObject)
    self:DebugLog("GuideTriggerNpcDead:OnPawnDead,",tbGameObject:GetName())
    if tbGameObject:GetObjectType() == GameObjectTypeDef.Npc then
        if self.tbTakeDamageNpc[tbGameObject:GetServerInstanceId()] then
            GuideSharedInfoHelper.FillObjectNameToSharedInfo(self, tbGameObject)
            self:Trigger()
        end
        self.tbTakeDamageNpc[tbGameObject:GetServerInstanceId()] = nil
    end
end

local function OnTakeDamage(self, tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId)
    if tbTaker and tbTaker:GetObjectType() == GameObjectTypeDef.Npc then
        if tbCauser and tbCauser:GetObjectType() == GameObjectTypeDef.PlayerSelf then
            self.tbTakeDamageNpc[tbTaker:GetServerInstanceId()] = tbTaker
        else
            self.tbTakeDamageNpc[tbTaker:GetServerInstanceId()] = nil
        end
    end
end

--override
function GuideTriggerNpcDead:Begin()
    GuideTriggerNpcDead.super.Begin(self)
    self.tbTakeDamageNpc = {}
end

function GuideTriggerNpcDead:End()
    GuideTriggerNpcDead.super.End(self)
    self.tbTakeDamageNpc = nil
end

function GuideTriggerNpcDead:Uninit()
    GuideTriggerNpcDead.super.Uninit(self)
    self.tbTakeDamageNpc = nil
end

function GuideTriggerNpcDead:BindEvent(EventHelper)
    GuideTriggerNpcDead.super.BindEvent(self, EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnTakeDamage)
end


return GuideTriggerNpcDead
