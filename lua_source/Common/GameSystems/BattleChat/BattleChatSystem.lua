-----------------------------------------------------
--File Name    : BattleChatSystem.lua
--Author       : Edward J
--Create Time  : 2019-03-19
--Description  : Chat system server-side
-----------------------------------------------------
local luaclass         = require("luaclass")
local BattleChatSystem = luaclass("BattleChatSystem")

local NetworkManager   = dynamic_require("NetworkManager") 
local BattleTeamSystem = dynamic_require("BattleTeamSystem")
local Proto            = require("DungeonCommonProtoNames")
-----------------------------------------------------

function BattleChatSystem:RouteMsgToTeamMembers(tbSender, szMsg, nSoundId)
    local nTeamID = BattleTeamSystem:FindTeamId(tbSender)
    local tbTeamMember = BattleTeamSystem:GetTeamMembers(nTeamID)
    assert(tbTeamMember)
    
    local bSenderInTeam = false
    local tbPacket = {}
    tbPacket.instance_id = tbSender:GetServerInstanceId()
    tbPacket.content = szMsg
    tbPacket.sound_id = nSoundId
    local NetProxy = NetworkManager:GetRPCNetworkProxy()

    for k, v in pairs(tbTeamMember) do
        if(v ~= tbSender) then
            NetProxy:SendToClient(v:GetUEControllerUniqueId(), Proto.d2c_Chat, tbPacket)
        else
            bSenderInTeam = true
        end
    end
    assert(bSenderInTeam)
end

function BattleChatSystem:RouteVoiceRoomMemberIdToTeamMembers(tbSender, nInstanceId, nMemberId)
    --logerror("RouteVoiceRoomMemberIdToTeamMembers%%%%%%%%%%%%%%%%%")
    local nTeamID = BattleTeamSystem:FindTeamId(tbSender)
    local tbTeamMember = BattleTeamSystem:GetTeamMembers(nTeamID)
    assert(tbTeamMember)
    
    local bSenderInTeam = false
    local tbPacket = {}
    tbPacket.instance_id = nInstanceId
    tbPacket.member_Id = nMemberId
    local NetProxy = NetworkManager:GetRPCNetworkProxy()

    for k, v in pairs(tbTeamMember) do
        if(v ~= tbSender) then
            NetProxy:SendToClient(v:GetUEControllerUniqueId(), Proto.d2c_ChatRoomMemberId, tbPacket)
        else
            bSenderInTeam = true
        end
    end
    assert(bSenderInTeam)
end

function BattleChatSystem:RoutePointLocationToTeamMembers(tbSender, pos, pointType)
    local nTeamID = BattleTeamSystem:FindTeamId(tbSender)
    local tbTeamMember = BattleTeamSystem:GetTeamMembers(nTeamID)
    assert(tbTeamMember)
    
    local bSenderInTeam = false
    local tbPacket = {}
    tbPacket.instance_id = tbSender:GetServerInstanceId()
    tbPacket.posX = pos.X
    tbPacket.posY = pos.Y
    tbPacket.posZ = pos.Z
    tbPacket.point_type = pointType
    local NetProxy = NetworkManager:GetRPCNetworkProxy()

    for k, v in pairs(tbTeamMember) do
        if(v ~= tbSender) then
            NetProxy:SendToClient(v:GetUEControllerUniqueId(), Proto.d2c_PointLocation, tbPacket)
        else
            bSenderInTeam = true
        end
    end
    assert(bSenderInTeam)
end

return BattleChatSystem()