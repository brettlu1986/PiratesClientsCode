local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local PartnerPacketProcessor = luaclass("PartnerPacketProcessor", NetMessageProcessorBase)

local UIUtils = require("UIUtils")
local Proto = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")

local ErrorReturnCodeText = {
    [Proto.ReturnCode.PARTNER_POOL_NOT_EXIST]       = "RETURN_CODE_PARTNER_POOL_NOT_EXIST",
    [Proto.ReturnCode.PARTNER_CAN_NOT_FOUND]        = "RETURN_CODE_PARTNER_CAN_NOT_FOUND",
    [Proto.ReturnCode.PARTNER_GRADE_NOT_FOUND]      = "RETURN_CODE_PARTNER_GRADE_NOT_FOUND",
    [Proto.ReturnCode.PARTNER_NOT_EXIST]            = "RETURN_CODE_PARTNER_NOT_EXIST",
    [Proto.ReturnCode.PARTNER_FRAGMENT_NOT_ENOUGH]  = "RETURN_CODE_PARTNER_FRAGMENT_NOT_ENOUGH",
    [Proto.ReturnCode.PARTNER_HIRED]                = "RETURN_CODE_PARTNER_HIRED",
    [Proto.ReturnCode.PARTNER_NOT_BE_HIRED]         = "RETURN_CODE_PARTNER_NOT_BE_HIRED",
    [Proto.ReturnCode.PARTNER_REPEATED]             = "RETURN_CODE_PARTNER_REPEATED",
    [Proto.ReturnCode.PARTNER_REACH_MAX_LEVEL]      = "RETURN_CODE_PARTNER_REACH_MAX_LEVEL"
}

local function CheckReturnCode(nReturnCode)
    if nReturnCode ~= Proto.ReturnCode.OK then
        local szKey = ErrorReturnCodeText[nReturnCode]
        if szKey then
            UIUtils.ShowToastWithKey(szKey)
        else
            logerror("PartnerPacketProcessor Unknown error code : " .. nReturnCode)
            UIUtils.ShowToastWithKey(ErrorReturnCodeText[Proto.ReturnCode.SHIP_UNKNOWN_ERROR])
        end
        return false
    end
    return true
end

local function GetPartnerComponent()
    return GamePlayerSelfHelper:Get().PartnerComponent
end

-- 招募
local function OnReceiveSummonPartner(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetPartnerComponent():ReceiveSummonPartner(tbPacket.result)
    end
end

-- 升星
local function OnReceiveUpLevelPartner(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetPartnerComponent():ReceiveUpLevelPartner(tbPacket.instance_id, tbPacket.level)
    end
end

-- 上阵
local function OnReceiveHirePartner(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetPartnerComponent():ReceiveEquipPartner(tbPacket.position, tbPacket.instance_id)
    end
end

-- 下阵
local function OnReceiveFirePartner(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetPartnerComponent():ReceiveUnequipPartner(tbPacket.position, tbPacket.instance_id)
    end
end

-- 合成
local function OnReceiveCompoundPartner(tbPacket)
    if CheckReturnCode(tbPacket.return_code) then
        GetPartnerComponent():ReceiveCompoundPartner(tbPacket.instance_id)
    end
end

function PartnerPacketProcessor:RegisterPackets()
    self:BindFunc(Proto.s2c_SummonPartner, OnReceiveSummonPartner)
    self:BindFunc(Proto.s2c_UpLevelPartner, OnReceiveUpLevelPartner)
    self:BindFunc(Proto.s2c_HirePartner, OnReceiveHirePartner)
    self:BindFunc(Proto.s2c_FirePartner, OnReceiveFirePartner)
    self:BindFunc(Proto.s2c_CompoundPartner, OnReceiveCompoundPartner)
end

function PartnerPacketProcessor:Init()
    PartnerPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetHubServerProxy())
    self:RegisterPackets()
    return true
end

return PartnerPacketProcessor
