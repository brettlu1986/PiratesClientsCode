-----------------------------------------------------
--File Name    : HumanAvatarPacketProcessor.lua
--Author       : WuJizhou
--Create Time  : 5/21/2020, 8:06:07 PM
--Description  : HumanAvatarPacketProcessor
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local HumanAvatarPacketProcessor = luaclass("HumanAvatarPacketProcessor", NetMessageProcessorBase)

local ProtoDC             = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local HumanAvatarSystem = dynamic_require("HumanAvatarSystem")

local function OnSyncSelfWeaponAvatar(self, tbPacket)
    local tbWeaponAvatarTemplateIds = tbPacket.weapon_fashion_template_id
    HumanAvatarSystem:SetWeaponAvatarPresetForSelf(tbWeaponAvatarTemplateIds)
end

function HumanAvatarPacketProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(ProtoDC.d2c_SyncSelfWeaponAvatar, self, OnSyncSelfWeaponAvatar)
end


--------base api from NetMessageProcessorBase--------
function HumanAvatarPacketProcessor:Init()
    self.super.Init(self)
    self:RegisterPackets()
    return true
end

-- function HumanAvatarPacketProcessor:Uninit()
--     self.super.Uninit(self)

return HumanAvatarPacketProcessor