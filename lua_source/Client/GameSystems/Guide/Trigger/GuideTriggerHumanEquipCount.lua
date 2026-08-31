-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerHumanEquipCount   = luaclass("GuideTriggerHumanEquipCount", GuideTrigger)

local GamePlayerSelfHelper          = require("GamePlayerSelfHelper")
local BattleItemCategoryDef         = require("BattleItemCategoryDef")
local BattleItemSystemHelper        = require("BattleItemSystemHelper")
local ClientEventDef                = require("ClientEventDef")
local ControlModeDef                = require("ControlModeDef")
local UIManager                     = require("UIManager")
local UIDef                         = require("UIDef")
-----------------------------------------------------
GuideTriggerHumanEquipCount.nCount = 0
-----------------------------------------------------

function GuideTriggerHumanEquipCount:CheckEquipWeaponCount()
    self:DebugLog("CheckEquipWeaponCount ")
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf or PlayerSelf:IsShip() then
        return
    end
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError("uipCount Wnd is nil")
        return
    end
    local tbHumanControl = Wnd.tbControlModePrefab[ControlModeDef.HUMAN]
    if not tbHumanControl then
        self:LogError("uipCount human control is nil")
        return
    end
    local bActivate = tbHumanControl.bActivate
    if not bActivate then
        self:LogError("uipCount not activate")
        return
    end
    local nInstanceId = PlayerSelf:GetServerInstanceId()
    local tbEquipItems = BattleItemSystemHelper:GetEquippedItems(nInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nInstanceId, true)
    if not tbEquipItems then
        return
    end
    local nEquipItemCount = 0
    for k,v in pairs(tbEquipItems) do
        nEquipItemCount = nEquipItemCount + 1
    end
    self:DebugLog("CheckEquipWeaponCount nEquipItemCount = " .. tostring(nEquipItemCount) .. " nCount = " .. tostring(self.nCount))
    if nEquipItemCount >= self.nCount then
        self:Execute()
    end
end

function GuideTriggerHumanEquipCount:OnControlModeChange(nControlMode)
    self:DebugLog("OnControlModeChange nControlMode = " .. tostring(nControlMode))
    if nControlMode == ControlModeDef.HUMAN then
        self:CheckEquipWeaponCount()
    end
end

--override
function GuideTriggerHumanEquipCount:Execute()
    self:Trigger()
end

function GuideTriggerHumanEquipCount:Begin()
    GuideTriggerHumanEquipCount.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    self.nCount = tonumber(tbParam[1])
end

function GuideTriggerHumanEquipCount:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_CLIENT, self, self.CheckEquipWeaponCount)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_ON_FFAHUMAN_ACTIVATE, self, self.CheckEquipWeaponCount)
end

return GuideTriggerHumanEquipCount
