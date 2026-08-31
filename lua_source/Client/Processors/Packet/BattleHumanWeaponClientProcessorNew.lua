local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleHumanWeaponClientProcessorNew = luaclass("BattleHumanWeaponClientProcessorNew", NetMessageProcessorBase)

local Proto = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")

local function SetCurrentWeapon(self, tbPacket)
    BattleHumanWeaponSystemNew:ResponseSetCurrentWeapon(tbPacket.weapon_id, tbPacket.force)
end

local function WeaponLock(self, tbPacket)
end

local function ThrowAllFinished(self, tbPacket)
    BattleHumanWeaponSystemNew:ResponseSetThrowStateReset(true)
end
-- 注册处理包
local function RegisterPackets(self)
    self:BindMethod(Proto.d2c_HumanSetCurrentWeapon, self, SetCurrentWeapon)
    self:BindMethod(Proto.d2c_HumanWeaponLock, self, WeaponLock)
    self:BindMethod(Proto.d2c_HumanThrowResponse, self, ThrowAllFinished)
end

-- 初始化
function BattleHumanWeaponClientProcessorNew:Init()
    BattleHumanWeaponClientProcessorNew.super.Init(self)
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    RegisterPackets(self)
    return true
end

return BattleHumanWeaponClientProcessorNew