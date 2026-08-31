local luaclass = require("luaclass")
local ScheduleBase = luaclass("ScheduleBase")
local UIUtils = require("UIUtils")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
-- local PlayerInfoSystem = require("PlayerInfoSystem")
local TimeUtil = require("TimeUtil")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local Proto = require("ClientProtoNames")

ScheduleBase.Owner  = nil
ScheduleBase.tbTemplate = nil
ScheduleBase.szName = nil
ScheduleBase.tbData = nil
ScheduleBase.bActivate = nil

ScheduleBase.tbTaskProgress = nil

local TASK_STATUS = {
    UNCOMPLETE = 1,
    COMPLETE = 2,
    GETREWARD = 3
}

local Return_Code = {
}

function ScheduleBase:Init(Owner, tbTemp, szName)
    self.Owner = Owner
    self.tbTemplate = tbTemp
    self.szName = szName

    -- 活动任务
    local tbClientTaskIds = tbTemp.tbScheduleData and tbTemp.tbScheduleData.tbClientTaskIds
    if tbClientTaskIds ~= nil and tbTemp.tbTask ~= nil then
        local fnGetTaskDesc = function(nId)
            for i, v in ipairs(tbTemp.tbTask) do
                if v.nId == nId then
                    return v.l10nDesc
                end
            end
        end

        self.tbTaskProgress = {}
        for i, v in ipairs(tbClientTaskIds) do
            local nId = v[1]
            for nIndex, tbTaskTemp in ipairs(tbTemp.tbTask) do
                if tbTaskTemp.nId == nId then
                    if tbTaskTemp.tbCondition ~= nil then
                        -- 活动只用nFactor1
                        local l10nDesc = fnGetTaskDesc(nId)

                        local tbTaskProgress = {tbIds = v, 
                                                nStatus = TASK_STATUS.UNCOMPLETE, 
                                                nMaxProgress = tbTaskTemp.tbCondition.nFactor1, 
                                                nCurProgress = 0,
                                                l10nDesc = l10nDesc,
                                                nType = tbTaskTemp.nType,
                                                nFinishTimes = 0}
                        table.insert(self.tbTaskProgress, tbTaskProgress)
                    end
                end
            end
        end
    end

    return true
end

function ScheduleBase:Uninit()
    self.szName = nil
    self.tbTemplate = nil
    self.Owner = nil
end

function ScheduleBase:Activate()
    log("Schedule Activate ", self.tbTemplate and self.tbTemplate.nId)
    self.bActivate = true
end

function ScheduleBase:Deactivate()
    log("Schedule Deactivate ", self.tbTemplate and self.tbTemplate.nId)
    self.bActivate = false
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_DEACTIVATE, self.tbTemplate.nId)
end

function ScheduleBase:RecvResetActivity()
    log("Schedule Reset ", self.tbTemplate and self.tbTemplate.nId)
end

function ScheduleBase:BindEvent(EventHelper)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_SCHEDULE_AWARD, self, self.OnGetScheduleAward)
end

function ScheduleBase:SetData(tbData)
    log("schedule set data ", self.tbTemplate and self.tbTemplate.nId, tbData)
    self.tbData = tbData
end

function ScheduleBase:GetData()
    return self.tbData
end

function ScheduleBase:ShowErrorCode(tbReturnCode, nReturnCode)
    local l10nErrorCode = tbReturnCode[nReturnCode]
    if l10nErrorCode ~= nil then
        UIUtils.ShowToast(l10nErrorCode)
    else
        log("ScheduleSystem invalid return code:", nReturnCode, self.szName)
    end
end

-- 是否开启
function ScheduleBase:IsOpen()
    return self.bActivate
    -- local tbTemp = self.tbTemplate

    -- -- 时间
    -- local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    -- if nCurTime < tbTemp.tbTime.nStartTime or nCurTime >= tbTemp.tbTime.nStopTime then
    --     return false
    -- end

    -- return true
end

-- 是否推送
function ScheduleBase:CanPush()
end

-- 是否有小红点
function ScheduleBase:HasTip()
    return false
end

function ScheduleBase:NextDayProcess()
end

function ScheduleBase:OnEnterLobby()
end

function ScheduleBase:OnLeaveLobby()
end

function ScheduleBase:OnPlayerDataSync(tbSchedule, bReconnected)
end

function ScheduleBase:OnItemUpdate(nItemTemplateId, bAdd)
end

function ScheduleBase:OnGetScheduleAward(tbPacket)    
end

function ScheduleBase:GetTemplate()
    return self.tbTemplate
end

function ScheduleBase:GetTimeStr(l10nFormat)
    if l10nFormat == nil then
        l10nFormat = UITextDef.L10N_YMDTIME_FORMAT3
    end
    local tbTemp = self.tbTemplate
    local szTimeFormat = L10N:ToString(l10nFormat)

    local szStartTime = TimeUtil.GetTimeFormatString(tbTemp.tbTime.nStartTime, szTimeFormat)
    local szEndTime = TimeUtil.GetTimeFormatString(tbTemp.tbTime.nStopTime, szTimeFormat)

    return string.format("%s-%s", szStartTime, szEndTime)
end

function ScheduleBase:GetTaskProgress()
    return self.tbTaskProgress
end

function ScheduleBase:RequestUseActivityItem(nItemInstanceId, nCount)
    local c2s_UseActivityItem = {
        activity_id = self.tbTemplate.nId,
        id = nItemInstanceId,
        count = nCount
    }
    self.Owner:SendPacket(Proto.c2s_UseActivityItem, c2s_UseActivityItem)
end

function ScheduleBase:RecvUseActivityItem(tbPacket)
    if tbPacket.activity_id ~= self.tbTemplate.nId then
        return false
    end
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        self:ShowErrorCode(Return_Code, tbPacket.return_code)
        return false
    end

    return true
end

function ScheduleBase:RefreshTaskProgress(tbTaskProtoData, bDispatchEvent)
    if self.tbTaskProgress == nil then
        return
    end
    local nTaskId = tbTaskProtoData.id
    local nType = tbTaskProtoData.type

    local bRefreshed = false
    for i, v in ipairs(self.tbTaskProgress) do
        if nType == nil or v.nType == nType then 
            for nIndex, nId in ipairs(v.tbIds) do
                if nTaskId == nId then
                    v.nCurProgress = tbTaskProtoData.current_value
                    v.nStatus = tbTaskProtoData.status
                    v.nFinishTimes = tbTaskProtoData.finish_times
                    bRefreshed = true
                    break
                end
            end
        end
    end

    if bRefreshed and bDispatchEvent then
        EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_TASK_REFRESH, self.tbTemplate.nId, tbTaskProtoData)
    end
end

function ScheduleBase:RecvNotifyTask(tbPacket)
    self:RefreshTaskProgress(tbPacket.task, true)
end

return ScheduleBase