-----------------------------------------------------
--File Name    : GuideTriggerHumanAmmoReload.lua
--Description  : 人弹药装填提醒
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerHumanAmmoReload  = luaclass("GuideTriggerHumanAmmoReload", GuideTrigger)

local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local HumanWeaponHelper         = require("HumanWeaponHelper")
local HumanWeaponMisc           = require("HumanWeaponMisc")
local CommonEventDef            = require("CommonEventDef")
local HumanWeaponStateDef       = require("HumanWeaponStateDef")
local BattleItemSystemHelper    = require("BattleItemSystemHelper")
local Timer                     = require("Timer")
-----------------------------------------------------
GuideTriggerHumanAmmoReload.tbParam         = nil
GuideTriggerHumanAmmoReload.nWaitSec        = nil
GuideTriggerHumanAmmoReload.bTriggerNow     = false

local AMMO_NOTE = "AmmoNote"
local HumanWeaponType = HumanWeaponMisc.Type
-----------------------------------------------------
local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if Owner:GetServerInstanceId() ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return 
    end

    self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 2 ----------------------")
    --满足等级
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local tbCurrentWeapon = Owner.HumanWeaponComponent:GetCurrentWeapon()
    if not tbCurrentWeapon then 
        self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 3") 
        return
    end
    if nCurrentState == HumanWeaponStateDef.HOLDED and tbCurrentWeapon:IsType(HumanWeaponType.GUN) then   
        --人的枪械的时候，先检查一下弹药，满足条件再起timer检测
        self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 4")
        local nRemain, nMax = HumanWeaponHelper.GetAmmoInfo(tbCurrentWeapon.nInstanceId)
        if nRemain < nMax and nMax > 1 then  
            self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 5")
            self.bTriggerNow = true
            Timer.StartOwnerTimer(self, AMMO_NOTE, function() 
                --倒计时结束得先判一下是不是人形态
                PlayerSelf = GamePlayerSelfHelper:Get()
                self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 6")
                if PlayerSelf:IsHuman()then
                    local Item = BattleItemSystemHelper:GetItem(tbCurrentWeapon.nInstanceId, true)
                    if Item then
                        nRemain, nMax = HumanWeaponHelper.GetAmmoInfo(tbCurrentWeapon.nInstanceId)
                        self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 7")
                        if nRemain < nMax then  
                            self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 8")
                            self:Trigger()
                        end
                    end
                end
                self.bTriggerNow = false
            end, self.nWaitSec )
        end
    end
end

local function CurrentWeaponChanged(self, nNewWeaponId, nLastWeaponId, nPlayerInstanceId)
    self:DebugLog("GuideTriggerHumanAmmoReload CurrentWeaponChanged 1 ")
    if nPlayerInstanceId ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return 
    end

    if self.bTriggerNow then  
        Timer.StopOwnerTimer(self, AMMO_NOTE)
        self:DebugLog("GuideTriggerHumanAmmoReload CurrentWeaponChanged 2 ")
    end
end

function GuideTriggerHumanAmmoReload:End()
    Timer.StopOwnerAllTimer(self, true)
    GuideTriggerHumanAmmoReload.super.End(self)
end

function GuideTriggerHumanAmmoReload:Uninit()
    Timer.StopOwnerAllTimer(self, true)
    GuideTriggerHumanAmmoReload.super.Uninit(self)
end
--override
function GuideTriggerHumanAmmoReload:Begin()
    GuideTriggerHumanAmmoReload.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam 
    if tbParam and tbParam[1] then
        self.tbParam = tbParam
        self.nWaitSec = tonumber(tbParam[1])  --等待时间
    end
    self.bTriggerNow = false
    self:DebugLog("GuideTriggerHumanAmmoReload ammo reload 1 ---------------")
end

function GuideTriggerHumanAmmoReload:BindEvent(EventHelper)
    --人换武器检查
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, CurrentWeaponChanged)
end

return GuideTriggerHumanAmmoReload
