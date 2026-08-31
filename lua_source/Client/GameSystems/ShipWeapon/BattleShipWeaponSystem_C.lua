-----------------------------------------------------
--File Name    : BattleShipWeaponSystem_C.lua
--Author       : Song Fuhao
--Create Time  : 2020-07-22
--Description  : 新版舰船武器系统客户端逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleShipWeaponSystem = require("BattleShipWeaponSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local BattleShipWeaponProtoHelper = require("BattleShipWeaponProtoHelper")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local CommonEventDef = require("CommonEventDef")
local ShipUtilityExHelper = require("ShipUtilityExHelper")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingIni = require("SettingIni")
local SettingKeyDef = require("SettingKeyDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")

--- @class BattleShipWeaponSystem_C : BattleShipWeaponSystem
local BattleShipWeaponSystem_C = luaclass("BattleShipWeaponSystem_C", BattleShipWeaponSystem)

local function LOG(...)
    log("[BattleShipWeapon][System_C]", ...)
end

local function GetComponent()
    local Component = GamePlayerSelfHelper:Get().BattleShipWeaponComponent
    assert(Component)
    return Component
end

--- 队伍信息改变时，刷新客户端上所有水雷的颜色
local function OnBattleTeamIdChanged(self, tbCharacter)
    if not GamePlayerSelfHelper:IsPlayerSelf(tbCharacter) then
        return
    end
    ShipUtilityExHelper.RefreshOwningTorpedoColor(GWorld)
end

--- 设置玩家船帆显隐
local function SetCharacterMastVisible(tbCharacter, bMastVisible, nNormalSailOpacity, nFiringSailOpacity)
    if (not tbCharacter)
    or (not tbCharacter:IsShip())
    or tbCharacter:IsDead()
    or (not tbCharacter.pUEActor) then
        return
    end
    tbCharacter.pUEActor.VisibleSailOpacity = nNormalSailOpacity
    tbCharacter.pUEActor.InvisibleSailOpacity = nFiringSailOpacity
    tbCharacter.pUEActor:SetMastVisible(bMastVisible)
end

--- 刷新队友帆的显隐状态
local function UpdateTeamMemberMastVisible(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsDead() or tbPlayer:IsHuman() then
        return
    end

    -- 获取船帆透明度
    local tbInstance = SettingSystemNew:GetInstance(SettingClassType.Setting_Basic)
    local tbSailOpacity = SettingIni.tbSailOpacity
    local nNormalSailOpacity = tbInstance:Get(SettingKeyDef.LocalKeys.NORMAL_SAIL_OPACITY, tbSailOpacity.nNormalDefault) / 100
    local nFiringSailOpacity = tbInstance:Get(SettingKeyDef.LocalKeys.FIRING_SAIL_OPACITY, tbSailOpacity.nFiringDefault) / 100

    -- 刷新自己船帆显隐
    local bMastVisible = self:GetActiveWeaponSlot_C() == ShipWeaponSlotDef.UNKNOWN
    SetCharacterMastVisible(tbPlayer, bMastVisible, nNormalSailOpacity, nFiringSailOpacity)

    -- 刷新队友船帆显隐
    local tbTeamInfos = TeamWatchClientHelper.GetCurrentTeamInfo()
    if (not tbTeamInfos) or (#tbTeamInfos <= 0) then
        return
    end
    for i, tbMemberInfo in ipairs(tbTeamInfos) do
        local tbTeammate = GameObjectSystem:FindByInstanceId(tbMemberInfo.nInstanceId)
        SetCharacterMastVisible(tbTeammate, bMastVisible, nNormalSailOpacity, nFiringSailOpacity)
    end
end

function BattleShipWeaponSystem_C:Init()
    LOG("Init")
    BattleShipWeaponSystem_C.super.Init(self)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_TEAM_ID_CHANGED             , self, OnBattleTeamIdChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED              , self, UpdateTeamMemberMastVisible)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_SHIP_SAIL_OPACITY_CHANGED  , self, UpdateTeamMemberMastVisible)
end

function BattleShipWeaponSystem_C:Uninit()
    LOG("Uninit")
    BattleShipWeaponSystem_C.super.Uninit(self)
end

--[[
    服务器数据同步接口（仅由 ShipWeaponPacketProcessor 调用）
]]

--- 收到激活武器改变通知
--- @param NewActiveWeaponItem ShipWeaponItemBase 武器实例
function BattleShipWeaponSystem_C:ReceiveActiveWeaponItemChanged(NewActiveWeaponItem)
    LOG("ReceiveActiveWeaponItemChanged", NewActiveWeaponItem and NewActiveWeaponItem:GetInstanceId())
    if not GlobalVariableSystem:IsStandalone() then
        GetComponent():SetActiveWeaponItem(NewActiveWeaponItem)
    end
    UpdateTeamMemberMastVisible(self)
end

--- 收到装备的投掷物改变通知
--- @param NewEquippedThrownItem number 投掷物实例
function BattleShipWeaponSystem_C:ReceiveEquippedThrownItemChanged(NewEquippedThrownItem)
    LOG("ReceiveEquippedThrownItemChanged", NewEquippedThrownItem and NewEquippedThrownItem:GetInstanceId())
    if GlobalVariableSystem:IsStandalone() then
        return
    end
    GetComponent():SetEquippedThrownItem(NewEquippedThrownItem)
end

--- 收到武器开始装弹通知
--- @param WeaponItem ShipWeaponItemBase 武器实例
--- @param nDuration number 装弹持续时间
--- @param nElapsedTime number 装弹开始已经过去的时间
function BattleShipWeaponSystem_C:ReceiveBulletLoadingBegan(WeaponItem, nDuration, nElapsedTime)
    LOG("ReceiveBulletLoadingBegan", WeaponItem and WeaponItem:GetInstanceId(), nDuration)
    local nStartTime = getseconds() - nElapsedTime
    WeaponItem:SyncBulletLoadingInfo(nDuration, nStartTime)
end

--- 收到武器结束装弹通知
--- @param WeaponItem ShipWeaponItemBase 武器实例
function BattleShipWeaponSystem_C:ReceiveBulletLoadingEnded(WeaponItem)
    LOG("ReceiveBulletLoadingEnded", WeaponItem and WeaponItem:GetInstanceId())
    WeaponItem:SyncBulletLoadingInfo(0, 0)
end

--- 收到武器开始开火CD通知
--- @param WeaponItem ShipWeaponItemBase 武器实例
--- @param nDuration number 开火CD持续时间
--- @param nElapsedTime number CD开始已经过去的时间
function BattleShipWeaponSystem_C:ReceiveFiringCDBegan(WeaponItem, nDuration, nElapsedTime)
    LOG("ReceiveFiringCDBegan", WeaponItem and WeaponItem:GetInstanceId(), nDuration)
    local nStartTime = getseconds() - nElapsedTime
    WeaponItem:SyncFiringCD(nStartTime, nDuration)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_SHIP_WEAPON_FIRING_CD_BEGAN_CLIENT, WeaponItem, nDuration, nStartTime)
end

--- 收到武器开火操作变化通知
--- @param WeaponItem ShipWeaponItemBase 武器实例
--- @param nFiringOperation number 开火CD持续时间
function BattleShipWeaponSystem_C:ReceiveFiringOperationChanged(WeaponItem, nFiringOperation)
    LOG("ReceiveFiringOperationChanged", WeaponItem and WeaponItem:GetInstanceId(), nFiringOperation)
    WeaponItem:SyncFiringOperation(nFiringOperation)
end

--- 收到开镜状态变化通知
--- @param bInAim bool 当前开镜状态
function BattleShipWeaponSystem_C:ReceiveAimStateChanged(bInAim)
    LOG("ReceiveAimStateChanged", bInAim)
    if GlobalVariableSystem:IsStandalone() then
        return
    end
    GetComponent():SetIsInAim(bInAim)
end

--[[
    请求接口
]]

--- 请求激活武器
--- @param WeaponItem ShipWeaponItemBase 武器实例
--- @return boolean
function BattleShipWeaponSystem_C:RequestActivateWeaponItem(WeaponItem)
    local nWeaponItemInstanceId = WeaponItem and WeaponItem:GetInstanceId()
    LOG("RequestActivateWeaponItem nWeaponItemInstanceId =", nWeaponItemInstanceId)
    if (not GamePlayerSelfHelper:Get():IsAlive()) then
        return false
    end
    local ActiveWeaponItem = GetComponent():GetActiveWeaponItem()
    if ActiveWeaponItem == WeaponItem then
        return false
    end
    BattleShipWeaponProtoHelper.RequestActivateWeaponItem(nWeaponItemInstanceId)
    return true
end

--- 请求装备投掷物类武器
--- @param nThrownItemTemplateId number 投掷物TemplateId
--- @return boolean
function BattleShipWeaponSystem_C:RequestEquipThrownItem(nThrownItemTemplateId)
    LOG("RequestEquipThrownItem nThrownItemTemplateId =", nThrownItemTemplateId)
    if (not GamePlayerSelfHelper:Get():IsAlive()) then
        return false
    end
    local ThrownItem = GetComponent():GetEquippedThrownItem()
    if ThrownItem and (ThrownItem:GetTemplateId() == nThrownItemTemplateId) then
        return false
    end
    BattleShipWeaponProtoHelper.RequestEquipThrownItem(nThrownItemTemplateId)
    return true
end

--- 请求开火
--- @param nFiringOperation ShipFiringOperationDef 开火状态，不传时默认值为ShipFiringStateDef.START
--- @return boolean
function BattleShipWeaponSystem_C:RequestFire(nFiringOperation)
    nFiringOperation = nFiringOperation or ShipFiringOperationDef.START
    LOG("RequestFire", nFiringOperation)
    if (not GamePlayerSelfHelper:Get():IsAlive()) then
        return false
    end
    local ActiveWeaponItem = GetComponent():GetActiveWeaponItem()
    if not ActiveWeaponItem then
        return false
    end
    local bResult, nFailedReason = ActiveWeaponItem:IsReadyToFire(nFiringOperation)
    if not bResult then
        LOG("RequestFire failed, nFailedReason =", nFailedReason)
        return false
    end
    BattleShipWeaponProtoHelper.RequestFire(nFiringOperation)
    return true
end

--- 请求武器装弹
--- @return boolean
function BattleShipWeaponSystem_C:RequestLoadBullet()
    LOG("RequestLoadBullet")
    if (not GamePlayerSelfHelper:Get():IsAlive()) then
        return false
    end
    local ActiveWeaponItem = GetComponent():GetActiveWeaponItem()
    if not ActiveWeaponItem then
        return false
    end
    local bResult, nFailedReason = ActiveWeaponItem:IsReadyToLoadBullet()
    if not bResult then
        LOG("RequestLoadBullet failed, nFailedReason =", nFailedReason)
        return false
    end
    BattleShipWeaponProtoHelper.RequestLoadBullet()
    return true
end

function BattleShipWeaponSystem_C:RequestChangeAimState(bInAim)
    LOG("RequestChangeAimState", bInAim)
    if (not GamePlayerSelfHelper:Get():IsAlive()) then
        return false
    end
    if not self:IsReadyToChangeAimState(GamePlayerSelfHelper:Get(), bInAim) then
        return false
    end
    BattleShipWeaponProtoHelper.RequestChangeAimState(bInAim)
end

--[[
    一般数据Get接口
]]

--- 获取当前激活的武器实例
--- @return ShipWeaponItemBase
function BattleShipWeaponSystem_C:GetActiveWeaponItem_C()
    return self:GetActiveWeaponItem(GamePlayerSelfHelper:Get())
end

--- 获取当前激活的武器槽位
--- @return ShipWeaponSlotDef
function BattleShipWeaponSystem_C:GetActiveWeaponSlot_C()
    return self:GetActiveWeaponSlot(GamePlayerSelfHelper:Get())
end

--- 获取当前装备的投掷物武器实例
--- @param nWeaponSlot ShipWeaponSlotDef 武器槽位
--- @return ShipWeaponItemBase
function BattleShipWeaponSystem_C:GetEquippedWeaponItem_C(nWeaponSlot)
    return self:GetEquippedWeaponItem(GamePlayerSelfHelper:Get(), nWeaponSlot)
end

--- 获取当前装备是否处于开镜状态
--- @return boolean
function BattleShipWeaponSystem_C:GetIsInAim_C()
    return self:GetIsInAim(GamePlayerSelfHelper:Get())
end

return BattleShipWeaponSystem_C()