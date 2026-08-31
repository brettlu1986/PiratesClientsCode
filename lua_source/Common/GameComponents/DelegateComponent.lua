---------------------------------------------------------------------
--File Name    : DelegateComponent.lua
--Author       : Song Fuhao
--Create Time  : 2020-05-18
--Description  : 用于管理一个Character身上的Delegate
--               CppDelegate为惰性注册，只有bind了才会注册到蓝图/C++上
--               暴露在Lua中为LuaDelegate形式
---------------------------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local DelegateComponent = luaclass("DelegateComponent", GameComponentBase)

local LuaDelegate = require("LuaDelegate")
local TemplateTypeDef = require("TemplateTypeDef")
local SelfEventHelper = require("SelfEventHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

DelegateComponent.EventHelper           = nil
DelegateComponent.tbCppRegisters        = nil
DelegateComponent.tbBindedCppDelegagtes = nil

local function LOG(self, ...)
    log("[DelegateComponent]", self.Owner.szName, ...)
end

local function OnShipBulletBoom(self, ...)
    EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_CANNON_BULLET_BOOM, ...)
end

local function GetCppDelegateRef(pUEActor, szCppComponentName, szCppDelegateName)
    local pCppDelegate = nil
    if szCppComponentName == nil then
        pCppDelegate = pUEActor[szCppDelegateName]
    else
        assert(pUEActor[szCppComponentName], "Cannot find component : " .. szCppComponentName)
        pCppDelegate = pUEActor[szCppComponentName][szCppDelegateName]
    end
    assert(pCppDelegate, "Cannot find delegate : " .. szCppDelegateName)
    return pCppDelegate
end

local function BindCppDelegate(self, tbRegister)
    local pOwnerActor = self.Owner.pUEActor
    local szLuaDelegateName = tbRegister.szLuaDelegateName
    if (pOwnerActor == nil)                                                     -- Actor还没创建好
    or (not tbRegister.tbLuaDelegate:IsBinded())                                -- LuaDelegate没有被Bind
    or ((tbRegister.nActorTemplateType & self.Owner:GetTemplateType()) == 0)    -- 注册类型不匹配
    or self.tbBindedCppDelegagtes[szLuaDelegateName] then                       -- 已经Bind了对应CppDelegate
        return
    end

    self.tbBindedCppDelegagtes[szLuaDelegateName] = tbRegister
    local tbLuaDelegate = tbRegister.tbLuaDelegate
    local pCppDelegate = GetCppDelegateRef(pOwnerActor, tbRegister.szCppComponentName, tbRegister.szCppDelegateName)
    self.EventHelper:RegisterCppDelegate(pCppDelegate, tbLuaDelegate, tbLuaDelegate.Fire)
    LOG(self, "BindCppDelegate", szLuaDelegateName)
end

-- @param szLuaDelegateName     面向Lua的Delegate名字
-- @param nActorTemplateType    Ship or Huamn or CHARACTER，具体参见 TemplateTypeDef.lua
-- @param szCppDelegateName     C++/蓝图中Delegate/Dispatcher的名字
-- @param szCppComponentName    绑定Actor身上的Delegate时填nil
local function RegisterCppDelegate(self, szLuaDelegateName, nActorTemplateType, szCppDelegateName, szCppComponentName)
    local tbRegister = {}
    tbRegister.szLuaDelegateName = szLuaDelegateName
    tbRegister.nActorTemplateType = nActorTemplateType
    tbRegister.szCppDelegateName = szCppDelegateName
    tbRegister.szCppComponentName = szCppComponentName

    local tbLuaDelegate = LuaDelegate()
    tbRegister.tbLuaDelegate = tbLuaDelegate
    tbLuaDelegate:SetBindCallback(function()
        BindCppDelegate(self, tbRegister)
    end)
    self[szLuaDelegateName] = tbLuaDelegate

    table.insert(self.tbCppRegisters, tbRegister)
end

-- @param szLuaDelegateName     面向Lua的Delegate名字
local function RegisterLuaDelegate(self, szLuaDelegateName)
    local tbLuaDelegate = LuaDelegate()
    self[szLuaDelegateName] = tbLuaDelegate
end

local function RegisterCppDelegates(self)
    local R = RegisterCppDelegate
    local T = TemplateTypeDef

    R(self, 'OnTakeCommonDamageEx'      , T.CHARACTER   , 'OnTakeCommonDamageEx'                                )
    R(self, 'OnTakePointDamageEx'       , T.CHARACTER   , 'OnTakePointDamageEx'                                 )
    R(self, 'OnTakeRadialDamageEx'      , T.CHARACTER   , 'OnTakeRadialDamageEx'                                )

    R(self, 'OnMoveTouchStarted'        , T.SHIP        , 'OnMoveTouchStarted'      , 'ShipInputComponent'      )
    R(self, 'OnMoveTouchMoved'          , T.SHIP        , 'OnMoveTouchMoved'        , 'ShipInputComponent'      )
    R(self, 'OnMoveTouchEnded'          , T.SHIP        , 'OnMoveTouchEnded'        , 'ShipInputComponent'      )
    R(self, 'OnAvatarResCommitFinish'   , T.SHIP        , 'OnCommitFinishDelegate'  , 'ShipAvatarComponent'     )
    R(self, 'OnShipInputDataChanged'    , T.SHIP        , 'OnShipInputDataChanged'  , 'ShipMovementComponent'   )
    R(self, 'OnGearValueChanged'        , T.SHIP        , 'OnGearValueChanged'      , 'ShipMovementComponent'   )
    R(self, 'OnShipBulletBoom'          , T.SHIP        , 'OnBulletBoom'            , 'CannonComponent'         )
    R(self, 'OnShipFireEnd'             , T.SHIP        , 'OnFireEnd'               , 'CannonComponent'         )
    R(self, 'OnRollForceBack'           , T.SHIP        , 'OnRollForceBack'         , 'CannonComponent'         )

    R(self, 'OnCameraTouchMoved'        , T.HUMAN       , 'OnCameraTouchMoved'      , "PlayerInputComponent"    )
end

local function RegisterLuaDelegates(self)
    local R = RegisterLuaDelegate
    R(self, "OnCharacterPreDead")
    R(self, "OnCharacterPostDead")
    R(self, "OnHumanWeaponActorCreated")
    R(self, "OnHumanArmorChanged")
end

-- TODO:Hao 回头要单独抽出来
local function TransformToGlobalEvent(self)
    if (self.Owner:GetObjectType() ~= GameObjectTypeDef.PlayerSelf) then
        return
    end
    self.OnShipBulletBoom:Bind(OnShipBulletBoom, self)
end

function DelegateComponent:OnCreate(...)
    DelegateComponent.super.OnCreate(self, ...)
    self.EventHelper = SelfEventHelper()
    self.tbCppRegisters = {}
    self.tbBindedCppDelegagtes = {}
    RegisterCppDelegates(self)
    RegisterLuaDelegates(self)
    TransformToGlobalEvent(self)
end

function DelegateComponent:OnDestroy(...)
    self.EventHelper = nil
    self.tbCppRegisters = nil
    self.tbBindedCppDelegagtes = nil
    DelegateComponent.super.OnDestroy(self, ...)
end

function DelegateComponent:OnActorCreated(...)
    DelegateComponent.super.OnActorCreated(self, ...)
    for _,tbRegister in pairs(self.tbCppRegisters) do
        BindCppDelegate(self, tbRegister)
    end
end

function DelegateComponent:OnActorDestroyed(...)
    self.EventHelper:UnregisterAll()
    self.tbBindedCppDelegagtes = {}
    LOG(self, "Unbind All CppDelegate")
    DelegateComponent.super.OnActorDestroyed(self, ...)
end

return DelegateComponent
