-----------------------------------------------------
--File Name    : AbilityPacketProcessor_C.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-22
--Description  : Ability相关（Skill、Buff）的协议都放在这，服务器接收逻辑放到基类实现中
-----------------------------------------------------

local luaclass = require("luaclass")
local AbilityPacketProcessor = require("AbilityPacketProcessor")
local AbilityPacketProcessor_C = luaclass("AbilityPacketProcessor_C", AbilityPacketProcessor)

-- require
local Proto = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")

-- local variable
local EBuffChangedType = Proto.d2c_CharacterBuffChanged_EBuffChangedType

local function OnCharacterBuffChanged(self, tbPacket)
    local tbGameObject = GameObjectSystem:FindByInstanceId(tbPacket.nOwnerInstanceId)
    if tbGameObject then
        local tbBuff = tbPacket.tbBuff
        local BuffComponentClient = tbGameObject.BuffComponentClient
        if tbPacket.BuffChangedType == EBuffChangedType.ADD then
            BuffComponentClient:AddBuff(tbBuff)
        elseif tbPacket.BuffChangedType == EBuffChangedType.UPDATE then
            BuffComponentClient:UpdateBuff(tbBuff)
        elseif tbPacket.BuffChangedType == EBuffChangedType.REMOVE then
            BuffComponentClient:RemoveBuff(tbBuff)
        end
    end
end

function AbilityPacketProcessor_C:RegisterPackets()
    AbilityPacketProcessor_C.super.RegisterPackets(self)
    self:BindMethod(Proto.d2c_CharacterBuffChanged, self, OnCharacterBuffChanged)
end

return AbilityPacketProcessor_C
