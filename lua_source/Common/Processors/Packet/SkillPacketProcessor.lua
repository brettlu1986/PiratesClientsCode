local luaclass = require "luaclass"
local NetMessageProcessorBase = require "NetMessageProcessorBase"
local SkillPacketProcessor = luaclass("SkillPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")

-- 获取SkillComponent
local function GetSkillComponent(nSenderUniqueId, bServer)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if(tbGameObject == nil) then
        logerror("SkillPacketProcessor:GetSkillComponent failed, can not find object", nSenderUniqueId)
        return nil
    end
    if bServer then
        return tbGameObject.SkillComponentServer
    else
        return tbGameObject.SkillComponentClient
    end
end

-- local function RequestAddBuff_S(self, tbPacket, nSenderUniqueId)
--     local tbGameObject = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
--     if tbGameObject then
--         tbGameObject.BuffComponentServer:AddBuffById(tbPacket.buff_id, tbPacket.nCount, tbPacket.nLevel)
--     end
-- end

-- 客户端向服务器发起请求释放技能
local function RequestCastSkill_S(self, tbPacket, nSenderUniqueId)
    local SkillComponent = GetSkillComponent(nSenderUniqueId, true)
    if SkillComponent and tbPacket.skill_id then
        local tbTargetPawn = GameObjectSystem:FindByInstanceId(tbPacket.target_instance_id)
        SkillComponent.tbTargetPawn = tbTargetPawn
        SkillComponent:RequestCastSkill(tbPacket.skill_id)
    end
end

-- 服务器释放技能失败
local function CastSkillFailedResponse_C(self, tbPacket, nSenderUniqueId)
    local SkillComponent = GetSkillComponent(nSenderUniqueId, false)
    if SkillComponent then
        SkillComponent:CastSkillFailedResponse(tbPacket.skill_id, tbPacket.failed_reason_id)
    end
end

local function CastSkillSuccessedResponse_C(self, tbPacket, nSenderUniqueId)
    local SkillComponent = GetSkillComponent(nSenderUniqueId, false)
    if SkillComponent then
        SkillComponent:CastSkillSuccessedResponse(tbPacket.skill_id)
    end
end

local function ResetSkillCD_C(self, tbPacket, nSenderUniqueId)
    local SkillComponent = GetSkillComponent(nSenderUniqueId, false)
    if SkillComponent then
        SkillComponent:ResetSkillCD()
    end
end

-- 注册处理包
function SkillPacketProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    -- self:BindMethod(Proto.c2d_RequestAddBuff            , self, RequestAddBuff_S)
    self:BindMethod(Proto.c2d_RequestCastSkill          , self, RequestCastSkill_S)
    self:BindMethod(Proto.d2c_CastSkillFailedResponse   , self, CastSkillFailedResponse_C)
    self:BindMethod(Proto.d2c_CastSkillSuccessedResponse, self, CastSkillSuccessedResponse_C)
    self:BindMethod(Proto.d2c_ResetSkillCD              , self, ResetSkillCD_C)
end

-- 初始化
function SkillPacketProcessor:Init()
    SkillPacketProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

return SkillPacketProcessor
