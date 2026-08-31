-----------------------------------------------------
--File Name    : GuideTriggerShipAmmoReload.lua
--Description  : 船弹药装填提醒
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerShipAmmoReload  = luaclass("GuideTriggerShipAmmoReload", GuideTrigger)

local Timer                     = require("Timer")
local ClientEventDef            = require("ClientEventDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local BattleShipWeaponSystem    = dynamic_require("BattleShipWeaponSystem")
-----------------------------------------------------
GuideTriggerShipAmmoReload.tbParam         = nil
GuideTriggerShipAmmoReload.nWaitSec        = nil

GuideTriggerShipAmmoReload.bIsFireing      = false
GuideTriggerShipAmmoReload.bIsReload       = false

local AMMO_NOTE = "AmmoNote"
-----------------------------------------------------
local function FireStart(self)
    self.bIsFireing = true
end

local function FireEnd(self)
    self.bIsFireing = false
    --满足等级
    local PlayerSelf = GamePlayerSelfHelper:Get()
    self:DebugLog("ship ammo reload 2 ---------------------")
    if PlayerSelf:IsHuman() then
        self:DebugLog("ship ammo reload 3")
        return
    end

    Timer.StartOwnerTimer(self, AMMO_NOTE, function() 
        --倒计时结束得先判一下是不是船形态
        PlayerSelf = GamePlayerSelfHelper:Get()
        self:DebugLog("ship ammo reload 4")
        if PlayerSelf:IsShip()then
            local tbActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(PlayerSelf)
            if tbActiveWeaponItem and not self.bIsReload then 
                
                local nBulletItemTemplateId = tbActiveWeaponItem:GetBulletItemTemplateId()
                self:DebugLog("ship ammo reload 5", nBulletItemTemplateId)
                --是否有弹夹
                if nBulletItemTemplateId > 0 then  
                    local nLoadedCount = tbActiveWeaponItem:GetBulletLoadedCount(true)
                    local nMaxLoadedCount = 0
                    if tbActiveWeaponItem:IsInfiniteBullet() then
                        nMaxLoadedCount = tbActiveWeaponItem:GetBulletMaxLoadingCount()
                    else
                        nMaxLoadedCount = tbActiveWeaponItem:GetBulletUnloadedCount(true)
                    end
                    self:DebugLog("ship ammo reload 6 ::", nLoadedCount,nMaxLoadedCount )
                    if nLoadedCount < nMaxLoadedCount and nMaxLoadedCount > 1 then   
                        self:DebugLog("ship ammo reload 7")
                        self:Trigger()
                    end
                end
            end
        end
    end, self.nWaitSec )
end

local function LoadStart(self)
    self.bIsReload = true
end

local function LoadEnd(self)
    self.bIsReload = false
end

function GuideTriggerShipAmmoReload:End()
    Timer.StopOwnerAllTimer(self, true)
    GuideTriggerShipAmmoReload.super.End(self)
end

--override
function GuideTriggerShipAmmoReload:Begin()
    GuideTriggerShipAmmoReload.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.tbParam = tbParam
        self.nWaitSec = tonumber(tbParam[1])  --等待时间
    end
    self:DebugLog("ship ammo reload 1")
end

function GuideTriggerShipAmmoReload:BindEvent(EventHelper)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRED_CLIENT , self, FireStart)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_SUCCEED_CLIENT , self, FireEnd)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_BEGAN_CLIENT , self, LoadStart)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_SHIP_WEAPON_BULLET_LOAD_ENDED_CLIENT , self, LoadEnd)
    
end

return GuideTriggerShipAmmoReload
