-- [[
-- 宝箱抽奖（伯爵宝藏）
-- ]]

local luaclass = require("luaclass")
local ScheduleBase = require("ScheduleBase")
local ScheduleChest = luaclass("ScheduleChest", ScheduleBase)
local Proto = require("ClientProtoNames")
local ItemSystem = require("ItemSystem")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")

ScheduleChest.bInit = nil
ScheduleChest.nToOpenBoxId = nil
ScheduleChest.nKeyId = nil
ScheduleChest.nKeyCount = nil

local Return_Code = {

}

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

local function VerifyClientDeactive(self)
    if self.tbData ~= nil and #self.tbData >= self.tbTemplate.tbScheduleData.nBoxCount then
        log("schedule chest deactivate")
        self.Owner:DeactivateByType(self.tbTemplate.szType)
    end
end

-- 
function ScheduleChest:Init(Owner, tbTemp, szName)
    local bResult = ScheduleChest.super.Init(self, Owner, tbTemp, szName)
    self.nKeyId = self.tbTemplate.tbScheduleData.nKeyId
    self.nKeyCount = -1
    UpdateKeyCount(self)
    return bResult
end

function ScheduleChest:Uninit()
    self.bInit = nil
    self.nKeyId = nil
    self.nKeyCount = nil
    self.nToOpenBoxId = nil
    ScheduleChest.super.Uninit(self)
end

function ScheduleChest:Activate()
    UpdateKeyCount(self)
    self:RequestGetBoxActivityInfo()
    ScheduleChest.super.Activate(self)
end

function ScheduleChest:Deactivate()
    -- UIManager:CloseWnd(UIDef.UI_SCHEDULE_CHEST_POP)
    ScheduleChest.super.Deactivate(self)
end

function ScheduleChest:OnEnterLobby()
    UpdateKeyCount(self)
end

function ScheduleChest:CanPush()
    local tbTaskData = self:GetTaskProgress()
    local bTaskComplete = true
    for i, v in ipairs(tbTaskData) do
        if v.nFinishTimes < v.nMaxProgress then
            bTaskComplete = false
            break
        end
    end
    return self:HasTip() or (not bTaskComplete)
end

function ScheduleChest:HasTip()
    local nCount = 0
    if self.tbData ~= nil then
        for k, v in pairs(self.tbData) do
            nCount = nCount + 1
        end
    end
    return self.nKeyCount > 0 and self.tbData ~= nil and nCount < self.tbTemplate.tbScheduleData.nBoxCount
end

function ScheduleChest:NextDayProcess()
    if self:IsOpen() then
        self:RequestGetBoxActivityInfo()
    end
end

function ScheduleChest:OnItemUpdate(nItemTemplateId, bAdd)
    UpdateKeyCount(self)
end

function ScheduleChest:ProcessScheduleChestPop()
    if self.Owner.bInLobby and self.Owner.bReconnected == nil then
        if self:IsOpen() and self:CanPush() then
            UIManager:OpenWnd(UIDef.UI_SCHEDULE_CHEST_POP)
            return true
        end
    end

    return false
end

function ScheduleChest:RecvResetActivity()
    ScheduleChest.super.RecvResetActivity(self)
    self:RequestGetBoxActivityInfo()
end

function ScheduleChest:RequestGetBoxActivityInfo()
    self.Owner:SendPacket(Proto.c2s_GetBoxActivityInfo)
end

function ScheduleChest:RequestOpenBox(nBoxId)
    self.nToOpenBoxId = nBoxId

    local c2s_OpenBox = {
        box_id = nBoxId
    }
    self.Owner:SendPacket(Proto.c2s_OpenBox, c2s_OpenBox)
end

function ScheduleChest:RecvGetBoxActivityInfo(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        log("ScheduleChest:RecvGetBoxActivityInfo ", tbPacket.return_code)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
        self.Owner:DeactivateByType(self.tbTemplate.szType)
        return
    end

    self.bInit = tbPacket.init
    for i, v in ipairs(tbPacket.tasks) do
        self:RefreshTaskProgress(v)
    end

    local tbOpenIds = {}
    for i, v in ipairs(tbPacket.open_box_id) do
        tbOpenIds[v] = true
    end
    self:SetData(tbOpenIds)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)

    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self.tbData)

    VerifyClientDeactive(self)
end

function ScheduleChest:RecvOpenBox(tbPacket)
    local nBoxId = self.nToOpenBoxId
    if nBoxId == nil then
        logerror("ScheduleChest:RecvOpenBox box id is nil")
        return
    end
    self.nToOpenBoxId = nil
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        self:ShowErrorCode(Return_Code, tbPacket.return_code)
        EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self.tbData, nBoxId, false)
        return
    end

    self.tbData[nBoxId] = true

    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_CHEST_REFRESH, self.tbData, nBoxId, true)

    VerifyClientDeactive(self)
end

function ScheduleChest:RecvUseActivityItem(tbPacket)
    local bResult = ScheduleChest.super.RecvUseActivityItem(self, tbPacket)
    if not  bResult then
        -- 客户端服务器数据不一致，重新请求
        self:RequestGetBoxActivityInfo()
    end
    -- EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_USE_ITEM, tbPacket.activity_id, bResult)
end

function ScheduleChest:GetKeyCount()
    return self.nKeyCount
end

return ScheduleChest