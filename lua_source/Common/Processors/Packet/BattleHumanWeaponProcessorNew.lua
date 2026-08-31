local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleHumanWeaponProcessorNew = luaclass("BattleHumanWeaponProcessorNew", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")

local function FindObject(nUniqueId)
    return GameObjectSystem:FindByUniqueId(nUniqueId)
end

local function Reload(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:Reload(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.time)
end

local function CancelReload(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:CancelReload(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end

local function SetAim(tbPacket, nSenderUniqueId)
    local tbObject = FindObject(nSenderUniqueId)
    BattleHumanWeaponSystemNew:SetAim(tbObject, tbPacket.weapon_id, tbPacket.enable)
end

local function SetCurrentWeapon(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:SetCurrentWeapon(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end
local function SetCurrentWeaponTemporary(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:SetCurrentWeapon(FindObject(nSenderUniqueId), tbPacket.weapon_id, false, true)
end

-- local function Unlock(tbPacket, nSenderUniqueId)
--     BattleHumanWeaponSystemNew:Unlock(FindObject(nSenderUniqueId), tbPacket.lock_counter)
-- end

local function AttackStart(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnAttackStart(FindObject(nSenderUniqueId))
end

local function AttackEnd(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnAttackEnd(FindObject(nSenderUniqueId))
end

local function RequestGunAttackOnce(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:RequestGunAttackOnce(
        FindObject(nSenderUniqueId),
        tbPacket.weapon_id,
        tbPacket.taker,
        tbPacket.start,
        tbPacket.end_pos,
        tbPacket.hit_type,
        tbPacket.index)
end

local function RequestGunAttackMulti(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:RequestGunAttackMulti(
        FindObject(nSenderUniqueId),
        tbPacket.weapon_id,
        tbPacket.takers,
        tbPacket.start,
        tbPacket.hit_ends,
        tbPacket.hit_types,
        tbPacket.miss_ends,
        tbPacket.indexes)
end

local function RouteGunGunAttack(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:RouteGunAttack(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket)
end

local function RouteProjectGunAttack(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:RouteProjectGunAttack(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket)
end 
local function BowPreAttack(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:BowPreAttack(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end 

local function RequestAttackSubstate(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:RequestAttackSubstate(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.substate)
end

local function CancelBowAttack(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnCancelBowAttack(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end

local function RequestAttack(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:RequestAttack(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.takers)
end

local function RouteMeleeAttack(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:RouteMeleeAttack(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.montage_index, tbPacket.in_jumping, tbPacket.start, tbPacket.yaw)
end

local function HoldThrownWeapon(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnHoldThrownWeapon(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end

local function UnholdThrownWeapon(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnUnholdThrownWeapon(FindObject(nSenderUniqueId))
end

local function SelectThrownWeapon(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnSelectThrownWeapon(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end

local function ChangeThrowType(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnChangeThrowType(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.high)
end

local function CancelThrow(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnCancelThrow(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end

local function Throw(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnThrow(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.pos, tbPacket.time)
end

local function BeginThrow(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:BeginThrow(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end

local function Ready(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnReady(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.high)
end

local function ExplodeBegin(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:OnExplodeBegin(FindObject(nSenderUniqueId), tbPacket.weapon_id)
end

local function DualWieldAttack(tbPacket, nSenderUniqueId)
    BattleHumanWeaponSystemNew:DualWieldAttack(FindObject(nSenderUniqueId), tbPacket.weapon_id, tbPacket.left_weapon)
end 

-- 注册处理包
local function RegisterPackets(self)
    self:BindFunc(Proto.c2d_HumanWeaponReload,              Reload)
    self:BindFunc(Proto.c2d_HumanWeaponCancelReload,        CancelReload)
    self:BindFunc(Proto.c2d_HumanWeaponSetAim,              SetAim)
    self:BindFunc(Proto.c2d_HumanWeaponSetCurrent,          SetCurrentWeapon)
    self:BindFunc(Proto.c2d_HumanWeaponSetCurrentTemporary, SetCurrentWeaponTemporary)
    --self:BindFunc(Proto.c2d_HumanWeaponUnlock,              Unlock)
    self:BindFunc(Proto.c2d_HumanAttackStart,               AttackStart)
    self:BindFunc(Proto.c2d_HumanAttackEnd,                 AttackEnd)

    self:BindFunc(Proto.c2d_HumanGunAttackOnceRequest,      RequestGunAttackOnce)
    self:BindFunc(Proto.c2d_HumanGunAttackMultiRequest,     RequestGunAttackMulti)
    self:BindFunc(Proto.c2d_HumanGunAttackRoute,            RouteGunGunAttack)
    self:BindFunc(Proto.c2d_HumanProjectAttackRoute,        RouteProjectGunAttack)
    self:BindFunc(Proto.c2d_HumanBowPreAttack,              BowPreAttack)
    self:BindFunc(Proto.c2d_HumanAttackSubstateRequest,     RequestAttackSubstate)
    self:BindFunc(Proto.c2d_HumanCancelBowAttack,           CancelBowAttack) 

    self:BindFunc(Proto.c2d_HumanAttackRequest,             RequestAttack)
    self:BindFunc(Proto.c2d_HumanMeleeAttackRoute,          RouteMeleeAttack)
    self:BindFunc(Proto.c2d_HumanDualWieldAttack,           DualWieldAttack)

    self:BindFunc(Proto.c2d_HumanHoldThrownWeapon,          HoldThrownWeapon)
    self:BindFunc(Proto.c2d_HumanUnholdThrownWeapon,        UnholdThrownWeapon)
    self:BindFunc(Proto.c2d_HumanSelectThrownWeapon,        SelectThrownWeapon)
    self:BindFunc(Proto.c2d_HumanChangeThrowType,           ChangeThrowType)
    self:BindFunc(Proto.c2d_HumanCancelThrow,               CancelThrow)
    self:BindFunc(Proto.c2d_HumanThrowRequest,              Throw)
    self:BindFunc(Proto.c2d_HumanBeginThrowRequest,         BeginThrow)
    self:BindFunc(Proto.c2d_HumanThrowReady,                Ready)
    self:BindFunc(Proto.c2d_HumanThrowExplodeBegin,         ExplodeBegin)
end

-- 初始化
function BattleHumanWeaponProcessorNew:Init()
    BattleHumanWeaponProcessorNew.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    RegisterPackets(self)
    return true
end

return BattleHumanWeaponProcessorNew
