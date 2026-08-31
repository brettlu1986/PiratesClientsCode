-- [[
-- 幸运轮盘
-- ]]


local luaclass = require("luaclass")
local ScheduleBase = require("ScheduleBase")
local ScheduleRoulette = luaclass("ScheduleRoulette", ScheduleBase)
local Proto = require("ClientProtoNames")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ItemSystem = require("ItemSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")

ScheduleRoulette.nKeyId = nil
ScheduleRoulette.nKeyCount = nil

local function UpdateKeyCount(self)
    local PlayerSelf = PlayerSelfHelper:Get()
    if PlayerSelf == nil then
        log("Update Key Count no player self")
        return
    end

    local nOldCount = self.nKeyCount
    self.nKeyCount = ItemSystem:GetItemCount(self.nKeyId)
    if nOldCount >= 0 and nOldCount ~= self.nKeyCount then
        EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_ITEM_UPDATE, self.tbTemplate.szType, nOldCount < self.nKeyCount)
    end
end

function ScheduleRoulette:Init(Owner, tbTemp, szName)
    local bResult = ScheduleRoulette.super.Init(self, Owner, tbTemp, szName)
    self.nKeyId = self.tbTemplate.tbScheduleData.nTicketId 
    self.nKeyCount = -1
    UpdateKeyCount(self)
    return bResult
end

function ScheduleRoulette:Uninit()
    self.nKeyId = nil
    self.nKeyCount = nil
    ScheduleRoulette.super.Uninit(self)
end

function ScheduleRoulette:Activate()
    UpdateKeyCount(self)
    self:RequestGetDrawActivityInfo()
    ScheduleRoulette.super.Activate(self)
end

function ScheduleRoulette:Deactivate()
    UIManager:CloseWnd(UIDef.UI_SCHEDULE_ROULETTE)
    UIManager:CloseWnd(UIDef.UI_SCHEDULE_ROULETTE_POP)

    ScheduleRoulette.super.Deactivate(self)
end

function ScheduleRoulette:RecvResetActivity()
    ScheduleRoulette.super.RecvResetActivity(self)
    self:RequestGetDrawActivityInfo()
end

function ScheduleRoulette:OnEnterLobby()
    UpdateKeyCount(self)
end

function ScheduleRoulette:CanPush()
    return true
end

function ScheduleRoulette:HasTip()
    return self.nKeyCount > 0
end

function ScheduleRoulette:GetKeyCount()
    return self.nKeyCount
end

function ScheduleRoulette:NextDayProcess()
    if self:IsOpen() then
        self:RequestGetDrawActivityInfo()
    end
end

function ScheduleRoulette:OnItemUpdate(nItemTemplateId, bAdd)
    UpdateKeyCount(self)
    -- if self.tbTemplate.tbRewardPool[nItemTemplateId] then
    --     log("ScheduleRoulette:OnItemUpdate ", nItemTemplateId, bAdd)
    --     EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_ROULETTE_RESULT, nItemTemplateId, bAdd)
    -- end
end

function ScheduleRoulette:OnGetScheduleAward(tbPacket)
    if tbPacket.source_type == Proto.AwardSourceType.DRAW_ACTIVITY_AWARD then
        local tbAward = tbPacket.award_addition[1]
        EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_ROULETTE_SUCCESS, tbAward)
    end
end

function ScheduleRoulette:ProcessScheduleRoulettePop()
    if self.Owner.bInLobby and self.Owner.bReconnected == nil then
        if self:IsOpen() and self.nKeyCount > 0 then
            UIManager:OpenWnd(UIDef.UI_SCHEDULE_ROULETTE_POP)
            return true
        end
    end

    return false
end

function ScheduleRoulette:RequestGetDrawActivityInfo()
    self.Owner:SendPacket(Proto.c2s_GetDrawActivityInfo)
end

function ScheduleRoulette:RequestGetReward()
    local tbItems = ItemSystem:GetItemsByTemplateId(self.nKeyId)
    if #tbItems <= 0 then
        return
    end
    local nInstanceId = tbItems[1]:GetInstanceId()
    self:RequestUseActivityItem(nInstanceId, 1)
end

function ScheduleRoulette:RecvGetDrawActivityInfo(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        log("ScheduleChest:RecvGetDrawActivityInfo ", tbPacket.return_code)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
        self.Owner:DeactivateByType(self.tbTemplate.szType)
        return
    end

    local tbData = {
        lucky_value = tbPacket.lucky_value,
        draw_times = tbPacket.draw_times,
        already_reward = tbPacket.already_reward
    }

    for i, v in ipairs(tbPacket.tasks) do
        self:RefreshTaskProgress(v)
    end

    self:SetData(tbData)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_ROULETTE_REFRESH, self.tbData)
end

function ScheduleRoulette:RecvUseActivityItem(tbPacket)
    local bResult = ScheduleRoulette.super.RecvUseActivityItem(self, tbPacket)
    if bResult then
        local nMaxLuckyValue = self.tbTemplate.tbScheduleData.nLuckyLimit
        local tbData = self:GetData()
        tbData.lucky_value = math.min(tbData.lucky_value + 1, nMaxLuckyValue)
        tbData.draw_times = math.max(tbData.draw_times - 1, 0)        
    else
        -- 客户端服务器数据不一致，重新请求
        self:RequestGetDrawActivityInfo()
    end
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_USE_ITEM, tbPacket.activity_id, bResult)
end

return ScheduleRoulette