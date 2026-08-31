-----------------------------------------------------
--File Name    : BotDistributionSystem_C.lua
--Author       : Chen Jing
--Create Time  : 2019-05-06
--Description  : 显示机器人的分布和状态
-----------------------------------------------------
local luaclass           = require("luaclass")
local BotDistributionSystem   = require("BotDistributionSystem")
local BotDistributionSystem_C = luaclass("BotDistributionSystem_C", BotDistributionSystem)
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
-----------------------------------------------------
BotDistributionSystem.tbBotInfos = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->BotDistributionSystem_C:", ...)
end
-- luacheck: pop

function BotDistributionSystem_C:Init()
    BotDistributionSystem_C.super.Init(self)
    self.tbBotInfos = {}

    return true
end

function BotDistributionSystem_C:Uninit()
    BotDistributionSystem_C.super.Uninit(self)
    self.tbBotInfos   = nil
end

function BotDistributionSystem_C:UpdateBotInfo(tbBotInfoPacket)
    local nServerInstanceId = tbBotInfoPacket.instanceId
    local tbBotInfo = self.tbBotInfos[nServerInstanceId] or {}
    tbBotInfo.nState = tbBotInfoPacket.state
    tbBotInfo.nX = tbBotInfoPacket.x
    tbBotInfo.nY = tbBotInfoPacket.y
    tbBotInfo.nBotIndex = tbBotInfoPacket.bot_index
    tbBotInfo.bIsHuman = tbBotInfoPacket.human
    tbBotInfo.nDestX = tbBotInfoPacket.mov_x or 0
    tbBotInfo.nDestY = tbBotInfoPacket.mov_y or 0
    tbBotInfo.nTeamId = tbBotInfoPacket.teamid
    tbBotInfo.bCaptain = tbBotInfoPacket.captain
    self.tbBotInfos[nServerInstanceId] = tbBotInfo
end

function BotDistributionSystem_C:ReceivePacket(tbPacket)
    for i=1,tbPacket.num_bot do
        local tbBotInfo = tbPacket.bots[i]
        self:UpdateBotInfo(tbBotInfo)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_BOT_INFO_UPDATED)
end

return BotDistributionSystem_C()