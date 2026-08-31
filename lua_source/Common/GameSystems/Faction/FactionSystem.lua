-----------------------------------------------------
--File Name    : FactionSystem.lua
--Author       : Zuo Kun
--Create Time  : 2017-09-11
--Description  : 阵营
-----------------------------------------------------
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")

local FactionSystem = {}

function FactionSystem:Init()
end

function FactionSystem:Uninit()
end

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end


function FactionSystem:AnswerMatchMaking( bAgree )
    SendPacket(Proto.c2s_ArenaAnswerMatchmaking, {accepted = bAgree})
end

function FactionSystem:CancelMatchmaking()
    SendPacket(Proto.c2s_ArenaCancelMatchmaking)
end

function FactionSystem:OnMatchMakingBegin(nArenaID)
	if(not UIManager:IsWndVisible(UIDef.UI_PVP_MATCH)) then
		local wnd = UIManager:OpenWnd(UIDef.UI_PVP_MATCH, {szTitle = ""})
		
		wnd.CancelMatchmaking:Bind(self.CancelMatchmaking, self)
		wnd.AnswerMatchMaking:Bind(self.AnswerMatchMaking, self)
	end
end
return FactionSystem 