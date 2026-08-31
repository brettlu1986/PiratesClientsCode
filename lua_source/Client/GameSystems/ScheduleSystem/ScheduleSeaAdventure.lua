-- [[
-- 航海大冒险
-- ]]


local luaclass = require("luaclass")
local ScheduleBase = require("ScheduleBase")
local ScheduleSeaAdventure = luaclass("ScheduleSeaAdventure", ScheduleBase)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local Proto = require("ClientProtoNames")
local ItemSystem = require("ItemSystem")
local SeaAdventureHelper = require("SeaAdventureHelper")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ScheduleTable = require("ScheduleTable")
local ScheduleTypeDef = require("ScheduleTypeDef")

ScheduleSeaAdventure.nTicketId = nil
ScheduleSeaAdventure.tbTasks = nil
ScheduleSeaAdventure.nCurrentTile = SeaAdventureHelper.TILE_START

ScheduleSeaAdventure.tbCircleRewardsState = nil

local function OnRefreshTask(self, _ , tbTaskProtoData)
    if tbTaskProtoData.type ~= SeaAdventureHelper.ROLL_TASK_TYPE then return end

    local bFound = false
    for i, v in ipairs(self.tbTasks) do
        if tbTaskProtoData.type == v.type and tbTaskProtoData.id == v.id then   
            v.status = tbTaskProtoData.status
            v.finishtimes = tbTaskProtoData.finish_times
            bFound = true
            break
        end
    end

    if not bFound then  
        local task = {}
        task.id = tbTaskProtoData.id 
        task.type = tbTaskProtoData.type
        task.status = tbTaskProtoData.status 
        task.finishtimes = tbTaskProtoData.finish_times
        table.insert(self.tbTasks, task)
    end
end

function ScheduleSeaAdventure:Init(Owner, tbTemp, szName)
    local bResult = ScheduleSeaAdventure.super.Init(self, Owner, tbTemp, szName)
    self.nTicketId = self.tbTemplate.tbScheduleData.nTicketId
    self.tbCircleRewardsState = {}
    self.tbTasks = {}
    return bResult
end

function ScheduleSeaAdventure:Uninit()
    ScheduleSeaAdventure.super.Uninit(self)
end

function ScheduleSeaAdventure:Activate()
    self:RequestAdventureInfo()
    EventManager:BindEventMethod(ClientEventDef.EV_SCHEDULE_TASK_REFRESH, self, OnRefreshTask)

    ScheduleSeaAdventure.super.Activate(self)
end

function ScheduleSeaAdventure:Deactivate()
    UIManager:CloseWnd(UIDef.UI_SCHEDULE_SEAADVENTURE)
    UIManager:CloseWnd(UIDef.UI_SCHEDULE_SEAADVENTURE_POP)
    EventManager:UnBindEventMethod(ClientEventDef.EV_SCHEDULE_TASK_REFRESH, self, OnRefreshTask)

    ScheduleSeaAdventure.super.Deactivate(self)
end

function ScheduleSeaAdventure:RequestAdventureInfo()
    self.Owner:SendPacket(Proto.c2s_GetRollActivityInfo)
end

function ScheduleSeaAdventure:RequestRollDice()
    self.Owner:SendPacket(Proto.c2s_RollDice)
end

-- function ScheduleSeaAdventure:RequestGetTileReward()
--     self.Owner:SendPacket(Proto.c2s_GetTileReward)
-- end

function ScheduleSeaAdventure:RequestGetDiceReward(index)
    self.Owner:SendPacket(Proto.c2s_GetDiceReward, {index = index})
end

function ScheduleSeaAdventure:RecvGetRollActivityInfo(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        log("ScheduleSeaAdventure:RecvGetRollActivityInfo ", tbPacket.return_code)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
        self:Deactivate()
        return
    end
    self.tbTasks = {}
    for i, v in ipairs(tbPacket.tasks) do
        local task = {}
        task.id = v.id 
        task.type = v.type
        task.status = v.status 
        task.finishtimes = v.finish_times
        table.insert(self.tbTasks, task)
    end
    local ScheduleTemp = ScheduleTable:GetTemplateByType(ScheduleTypeDef.ROLL)
    self:SetData({nId = ScheduleTemp.nId})
    self.nCurrentTile = tbPacket.current_tile
    self.tbCircleRewardsState = tbPacket.reward_state

    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH)
end

function ScheduleSeaAdventure:RecvRollDice(tbPacket)
    if tbPacket.return_code == Proto.ReturnCode.OK then 
        self.nCurrentTile = tbPacket.current_tile
        self.tbCircleRewardsState = tbPacket.reward_state
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_DICE_ROLL, true, tbPacket.num, tbPacket.current_tile, tbPacket.move)
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH_CIRLEREWARD, true)
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH)
    else  
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_DICE_ROLL, false)
        UIUtils.ShowToast(string.format("ErrorCode :%s", tbPacket.return_code))
    end
end



-- function ScheduleSeaAdventure:RecvGetTileReward(tbPacket)
--     if tbPacket.return_code == Proto.ReturnCode.OK then 
--         EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_DICE_REWARD_OK)
--     else 
--         log("[DICE] get tile reward error code:", tbPacket.return_code )
--     --     UIUtils.ShowToast(string.format("ErrorCode :%s", tbPacket.return_code))
--     end
-- end

function ScheduleSeaAdventure:RecvGetDiceReward(tbPacket)
    if tbPacket.return_code == Proto.ReturnCode.OK then 
        self.tbCircleRewardsState = tbPacket.reward_state
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH_CIRLEREWARD, false)
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH)
    else 
        UIUtils.ShowToast(string.format("ErrorCode :%s", tbPacket.return_code))
    end
end

function ScheduleSeaAdventure:GetDiceId()
    return self.nTicketId
end

function ScheduleSeaAdventure:GetCircleRewardState()
    return self.tbCircleRewardsState
end

function ScheduleSeaAdventure:GetCurrentTile()
    return self.nCurrentTile
end

function ScheduleSeaAdventure:GetCurrentTaskRewardCount()
    local nCount = 0
    for _, task in ipairs(self.tbTasks) do
        if task.id == SeaAdventureHelper.ROLL_SUB_TASK_ID then 
            nCount = nCount + task.finishtimes
        end
    end
    return nCount
end

function ScheduleSeaAdventure:CanPush()
    return true
end

function ScheduleSeaAdventure:NextDayProcess()
    if self:IsOpen() then
        self:RequestAdventureInfo()
    end
end

--当前的 推送弹窗 需要判断3个条件，1.是当前是否有骰子，2.是当天的任务是否都完成了 3.是否有满圈奖励
local function IsPopSeaAdventure(self)
    local tbTemplate = self:GetTemplate()
    return self:HasTip() or self:GetCurrentTaskRewardCount() < tbTemplate.tbScheduleData.nDiceMaxDay
end

function ScheduleSeaAdventure:ProcessScheduleSeaAdventureGoTo() 
    if self.Owner.bInLobby and self.Owner.bReconnected == nil then
        if self:IsOpen() and IsPopSeaAdventure(self) then
            UIManager:OpenWnd(UIDef.UI_SCHEDULE_SEAADVENTURE_POP)
            return true
        end
    end
    return false
end

function ScheduleSeaAdventure:OnItemUpdate(nItemTemplateId, bAdd)
    if nItemTemplateId == self.nTicketId then 
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_DICE_COUNT_CHANGE)
        EventManager:OnFireEvent(ClientEventDef.EV_SEA_ADVENTURE_REFRESH)
    end
end

function ScheduleSeaAdventure:HasTip()
    --dice count 
    --has circle reward
    local nCount = ItemSystem:GetItemCount(self.nTicketId) 
    local bHasCircleReward = false
    for _, v in pairs(self.tbCircleRewardsState) do   
        if v == Proto.RewardState.RECEIVE then  
            bHasCircleReward = true
            break
        end
    end
    return nCount > 0 or bHasCircleReward
end

return ScheduleSeaAdventure