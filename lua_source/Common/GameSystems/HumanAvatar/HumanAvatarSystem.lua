-----------------------------------------------------
--File Name    : HumanAvatarSystem.lua
--Author       : WuJizhou
--Create Time  : 5/21/2020, 2:29:25 PM
--Description  : HumanAvatarSystem
-----------------------------------------------------
local luaclass = require("luaclass")
local HumanAvatarSystem = luaclass("HumanAvatarSystem")

local BattlePrepareSystem = require("BattlePrepareSystem")
local EventManager        = require("EventManager")
local CommonEventDef      = require("CommonEventDef")
local ProtoDC             = require("DungeonCommonProtoNames")

local NetworkManager      = dynamic_require("NetworkManager")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")


function HumanAvatarSystem:SyncWeaponAvatarPresetForSelf(tbPlayer)
    assert(GlobalVariableSystem:IsServerLogic())
    local nPlayerId = tbPlayer:GetPlayerId()
    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(nPlayerId)
    local tbWeaponFashionTemplateIds = tbPrepareInfo.tbHumanWeaponFashionTemplateIds
    local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
    local nUEControllerUniqueId = tbPlayer:GetUEControllerUniqueId()
    local d2c_SyncSelfWeaponAvatar = {}
    d2c_SyncSelfWeaponAvatar.weapon_fashion_template_id = tbWeaponFashionTemplateIds
    RPCNetworkProxy:SendToClient(nUEControllerUniqueId,  ProtoDC.d2c_SyncSelfWeaponAvatar, d2c_SyncSelfWeaponAvatar)
end

function HumanAvatarSystem:Init()
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.SyncWeaponAvatarPresetForSelf)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, self.SyncWeaponAvatarPresetForSelf)
    return true
end

function HumanAvatarSystem:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, self.SyncWeaponAvatarPresetForSelf)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, self.SyncWeaponAvatarPresetForSelf)
    return true
end

return HumanAvatarSystem