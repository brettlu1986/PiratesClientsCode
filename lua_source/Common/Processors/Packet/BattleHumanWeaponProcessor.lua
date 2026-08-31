local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleHumanWeaponProcessor = luaclass("BattleHumanWeaponProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleHumanWeaponSystem = dynamic_require("BattleHumanWeaponSystem")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

local function GetComponent(nSenderUniqueId)
    local tbObject = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbObject then
        return tbObject.HumanWeaponComponent
    end
end

local function IsItemInstanceIdValid(nWeaponInstanceId)
    local tbItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, false)
    if not tbItem then
        return false
    end
    return true
end

local function StartAttack(self, tbPacket, nSenderUniqueId)
    local Component = GetComponent(nSenderUniqueId)
    if(Component) then
        Component:StartAttack()
    end
end

local function FinishAttack(self, tbPacket, nSenderUniqueId)
    local Component = GetComponent(nSenderUniqueId)
    if(Component) then
        Component:FinishAttack()
    end
end

local function CancelAttack(self, tbPacket, nSenderUniqueId)
    local Component = GetComponent(nSenderUniqueId)
    if(Component) then
        Component:CancelAttack()
    end
end

local function Reload(self, tbPacket, nSenderUniqueId)
    local Component = GetComponent(nSenderUniqueId)
    if(Component) then
        Component:Reload()
    end
end

local function SetAim(self, tbPacket, nSenderUniqueId)
    local Component = GetComponent(nSenderUniqueId)
    if(Component) then
        Component:SetAim(tbPacket.enable)
    end
end

local function SetCurrentWeapon(self, tbPacket, nSenderUniqueId)
    local Component = GetComponent(nSenderUniqueId)
    if(Component) then
        local nWeaponInstanceId = tbPacket.weapon_instance_id
        if nWeaponInstanceId == 0 then
            Component:SetCurrentWeapon(nWeaponInstanceId)
        else
            local tbItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, false)
            local tbObject = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
            if tbItem and tbObject and tbItem:GetOwnerCharacterInstanceId() == tbObject.nServerInstanceId then 
                Component:SetCurrentWeapon(nWeaponInstanceId)   
            else
                logwarning("BattleHumanWeaponProcessor, SetCurrentWeapon invalid, item id : ", nWeaponInstanceId)
            end 
        end
    end
end

local function UniqueIdToInstanceId(nSenderUniqueId)
    local tbSender = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    return tbSender:GetServerInstanceId()
end

local function ChangeWeaponFireType(self, tbPacket, nSenderUniqueId )
    local nCharacterId = UniqueIdToInstanceId(nSenderUniqueId)
    local nWeaponId = tbPacket.weapon_instance_id
    if IsItemInstanceIdValid(nWeaponId) then
        BattleHumanWeaponSystem:OnRequestChangeWeaponFireTypeReceived(nCharacterId, nWeaponId)
    else
        logwarning("BattleHumanWeaponProcessor, ChangeWeaponFireType invalid, item id : ", nWeaponId)
    end
end

local function HoldThrowItem(self, tbPacket, nSenderUniqueId)
    local nCharacterId = UniqueIdToInstanceId(nSenderUniqueId)
    local nItemInstanceId = tbPacket.item_instance_id
    if IsItemInstanceIdValid(nItemInstanceId) then
        BattleHumanWeaponSystem:OnRequestHoldThrownItemReceived(nCharacterId, nItemInstanceId)
    else
        logwarning("BattleHumanWeaponProcessor, HoldThrowItem invalid, item id : ", nItemInstanceId)
    end
end

local function UnholdThrowItem(self, tbPacket, nSenderUniqueId)
    local nCharacterId = UniqueIdToInstanceId(nSenderUniqueId)
    local nItemInstanceId = tbPacket.item_instance_id
    if IsItemInstanceIdValid(nItemInstanceId) then
        BattleHumanWeaponSystem:OnRequestUnholdThrownItemReceived(nCharacterId, nItemInstanceId)
    else
        logwarning("BattleHumanWeaponProcessor, UnholdThrowItem invalid, item id : ", nItemInstanceId)
    end
end

local function ChangeThrowType(self, tbPacket, nSenderUniqueId)
    local nCharacterId = UniqueIdToInstanceId(nSenderUniqueId)
    local nThrowType = tbPacket.throw_type
    BattleHumanWeaponSystem:OnRequestChangeThrowTypeReceived(nCharacterId, nThrowType)
end

local function CancelThrowExplosive(self, tbPacket, nSenderUniqueId)
    local nCharacterId = UniqueIdToInstanceId(nSenderUniqueId)
    BattleHumanWeaponSystem:OnRequestCancelThrowExplosive(nCharacterId)
end
-- 注册处理包
function BattleHumanWeaponProcessor:RegisterPackets()
    self:BindMethod(Proto.c2d_HumanStartAttack,          self, StartAttack)
    self:BindMethod(Proto.c2d_HumanFinishAttack,         self, FinishAttack)
    self:BindMethod(Proto.c2d_HumanCancelAttack,         self, CancelAttack)
    self:BindMethod(Proto.c2d_HumanReload,               self, Reload)
    self:BindMethod(Proto.c2d_HumanAim,                  self, SetAim)
    self:BindMethod(Proto.c2d_HumanSetCurrentWeapon,     self, SetCurrentWeapon)
    self:BindMethod(Proto.c2d_ChangeHumanWeaponFireType, self, ChangeWeaponFireType)
    self:BindMethod(Proto.c2d_HoldThrownItem           , self, HoldThrowItem)
    self:BindMethod(Proto.c2d_UnholdThrownItem         , self, UnholdThrowItem)
    self:BindMethod(Proto.c2d_ChangeHumanThrowType     , self, ChangeThrowType)
    self:BindMethod(Proto.c2d_CancelThrowExplosive     , self, CancelThrowExplosive)
end

-- 初始化
function BattleHumanWeaponProcessor:Init()
    BattleHumanWeaponProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

return BattleHumanWeaponProcessor
