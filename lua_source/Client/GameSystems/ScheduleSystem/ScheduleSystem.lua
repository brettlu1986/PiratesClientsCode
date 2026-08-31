local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local SelfEventHelper = require("SelfEventHelper")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local DelayTimer = require("DelayTimer")
local NoobLoginDataTable = require("NoobLoginDataTable")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ScheduleIni = require("ScheduleIni")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local UITextDef = require("UITextDef")
local ScheduleUITable = require("ScheduleUITable")
local ProtoDR = require("DungeonRepProtoNames")
local ScheduleHelper = require("ScheduleHelper")
local TimeUtil = require("TimeUtil")
local Timer = require("Timer")
local ScheduleTable = require("ScheduleTable")

-- local SeaAdventureHelper = require("SeaAdventureHelper")
-- local ScheduleClassType = require("ScheduleClassType")
-- local ScheduleTypeDef = require("ScheduleTypeDef")
local ItemSystem = require("ItemSystem")

local GetL10NTextByKey = UISetUtils.GetL10NTextByKey

local ScheduleSystem = {}

local Return_Code = {
    [Proto.ReturnCode.NOOB_LOGIN_AWARD_RECEIVED] = GetL10NTextByKey("LOGIN_AWARD_GETED"),
    [Proto.ReturnCode.NOOB_LOGIN_DAY_NOT_ENOUGH] = GetL10NTextByKey("LOGIN_AWARD_NOT_REACH"),
    [Proto.ReturnCode.TIMED_AWARD_BEFORE] = GetL10NTextByKey("TIMED_AWARD_BEFORE"),
    [Proto.ReturnCode.TIMED_AWARD_OUT] = GetL10NTextByKey("TIMED_AWARD_OUT"),
    [Proto.ReturnCode.TIMED_AWARDED] = GetL10NTextByKey("TIMED_AWARDED"),
    -- [Proto.ReturnCode.CONTINUOUS_DAY_NOT_ENOUGH] = GetL10NTextByKey("CONTINUOUS_DAY_NOT_ENOUGH"),
    -- [Proto.ReturnCode.CONTINUOUS_AWARD_RECEIVED] = GetL10NTextByKey("CONTINUOUS_AWARD_RECEIVED"),
}

ScheduleSystem.tbBattleStarTimerHandle = nil

ScheduleSystem.bReconnected = nil
ScheduleSystem.tbCrossDayTimerHandle = nil
ScheduleSystem.tbMinTimerHandle = nil
ScheduleSystem.bInLobby = nil

-- 以前的新手活动都是分散做的，以后活动统一注册到Instance中，分别在自己的文件中做处理
ScheduleSystem.tbInstances = nil

local RefreshNextDay = nil

-- local function Register(self, nType, szFileName)
--     local szType = ScheduleTypeDef[nType]
--     local tbTemp = ScheduleTable:GetTemplateByType(szType)
--     if tbTemp == nil then
--         logerror("schedule system register instance failed: template is nil ", nType)
--         return
--     end
--     if not tbTemp.bEnable then
--         log("schedule system register instance failed: file is nil ", nType)
--         return
--     end

--     local Class = require(szFileName)
--     local Instance = Class()
--     if Instance:Init(self, tbTemp, szFileName) then
--         self.tbInstances[nType] = Instance
--     else
--         log(string.format("schedule system register instance init failed ", nType))
--     end
-- end

local function Register(self, nId)
    local tbTemp = ScheduleTable:GetTemplate(nId)
    if tbTemp == nil then
        logerror("schedule system register instance failed: template is nil ", nId)
        return
    end
    -- if not tbTemp.bEnable then
    --     log("schedule system register instance failed: file is nil ", nId)
    --     return
    -- end

    local Class = require(tbTemp.szLuaFile)
    if Class ~= nil then
        local Instance = Class()
        if Instance:Init(self, tbTemp, tbTemp.szLuaFile) then
            Instance:Activate()
            self.tbInstances[tbTemp.szType] = Instance
        else
            log(string.format("schedule system register instance init failed ", nId))
        end

        return Instance
    else
        logerror("schedule system register instance failed ", nId)
    end
end

local function Unregister(self, szType)
    local Instance = self.tbInstances[szType]
    if Instance ~= nil then
        Instance:Deactivate()
        Instance:Uninit()
        self.tbInstances[szType] = nil
    end
end

local function RegisterAll(self, tbSchedules)
    for i, v in ipairs(tbSchedules.id) do
        Register(self, v)
    end
    -- local T = ScheduleClassType
    -- Register(self, T.Schedule_Roulette, "ScheduleRoulette")
    -- Register(self, T.Schedule_Chest, "ScheduleChest")
end

local function UnregisterAll(self)
    for k, v in pairs(self.tbInstances) do
        Unregister(self, k)
    end
end

function ScheduleSystem:SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    Socket:SendPacket(szProto, tbPacket)    
end

local function ShowErrorCode(nReturnCode)
    local l10nErrorCode = Return_Code[nReturnCode]
    if l10nErrorCode ~= nil then
        UIUtils.ShowToast(l10nErrorCode)
    else
        log("ScheduleSystem invalid return code:", nReturnCode)
    end
end

-- 跨天timer
local function GetRemainTimeTo24(nTime)
    local nRemainTime = TimeUtil.CalRefreshRemainSeconds(nTime)
    log("GetRemainTimeTo24 remain seconds = ", nRemainTime)
    return nRemainTime
end

local function ClearNextDayTimer(self)
    if self.tbCrossDayTimerHandle ~= nil then 
        DelayTimer:ClearTimer(self.tbCrossDayTimerHandle)
        self.tbCrossDayTimerHandle = nil
    end
end

local function CreateNextDayTimer(self)
    ClearNextDayTimer(self)
    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    local nRemainTime = GetRemainTimeTo24(nCurTime)
    if nRemainTime > 0 then
        self.tbCrossDayTimerHandle = DelayTimer:DelayRun(function() RefreshNextDay(self) end, nRemainTime)
    else
        RefreshNextDay(self)
    end
end

RefreshNextDay = function(self)
    local Component = self:GetComponent()
    if Component == nil then
        logerror("schedule refresh next day but no component")
        return
    end
    local tbContainer = ScheduleUITable:GetContainer()
    for i, v in pairs(tbContainer) do
        local fn = ScheduleHelper[v.szIsOpen]
        if v.szIsOpen == nil or (fn ~= nil and fn(self, Component) == true) then
            if v.szNextDayProcess then
                ScheduleHelper[v.szNextDayProcess](self, Component)
            end
        end
    end
    CreateNextDayTimer(self)

    -- 
    for k, v in pairs(self.tbInstances) do
        v:NextDayProcess(Component)
    end
end


local function ClearBattleStarActivityTimer(self)
    if self.tbBattleStarTimerHandle ~= nil then
        DelayTimer:ClearTimer(self.tbBattleStarTimerHandle)
        self.tbBattleStarTimerHandle = nil
    end
end

local function SetNoobLogin(self, tbData)
    local Component = self:GetComponent()
    if Component == nil then
        logerror("schedule SetNoobLogin but no component")
        return
    end
    
    Component:SetNoobLogin(tbData)
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_NOOB_LOGIN_REFRESH)
end

local function CloseBattleStarActivity(self)
    ClearBattleStarActivityTimer(self)
    local Component = self:GetComponent()
    if Component == nil then
        logerror("CloseBattleStarActivity but no component")
        return
    end
    log("CloseBattleStarActivity")
    Component:SetBattleStarCloseTime()
end

local function VerifyBattleStarTimer(self)
    ClearBattleStarActivityTimer(self)
    local Component = self:GetComponent()
    if Component == nil then
        logerror("VerifyBattleStarTimer but no component")
        return
    end

    local nTime = Component:GetBattleStarCloseTime()
    if nTime == nil then
        return
    end
    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    local nLastTime = nTime - nCurTime
    if nLastTime > 0 then
        self.tbBattleStarTimerHandle = DelayTimer:DelayRun(function() CloseBattleStarActivity(self) end, nLastTime)
    else
        CloseBattleStarActivity(self)
    end
end

local function ClearMinTimer(self)
    if self.tbMinTimerHandle ~= nil then
        self.tbMinTimerHandle:Clear()
        self.tbMinTimerHandle = nil
    end
end

local function CreateMinTimer(self)
    local Component = self:GetComponent()
    if Component == nil then
        logerror("ScheduleSystem CreateMinTimer but no component")
        return
    end

    ClearMinTimer(self)
    local RefreshMinTime = function()
        local tbContainer = ScheduleUITable:GetContainer()
        for i, v in pairs(tbContainer) do
            if v.szTimerProcess ~= nil then
                ScheduleHelper[v.szTimerProcess](self, Component)
            end 
        end
    end
    self.tbMinTimerHandle = Timer.NewTimer(RefreshMinTime, 60, true)
end

local function OnEnterLobby(self)
    local bOld = self.bInLobby
    
    self.bInLobby = true
    local Component = self:GetComponent()
    if Component == nil then
        logerror("schedule OnEnterLobby but no component")
        return
    end    
    VerifyBattleStarTimer(self)
    CreateNextDayTimer(self)
    CreateMinTimer(self)

    if self.nBattleCount == nil then
        self.nBattleCount = ScheduleHelper:GetAndSetTodayBattleCount(0)
    end
    if bOld ~= nil then
        ScheduleHelper:VerifyShowNextNoobLoginAward(Component, self.nBattleCount)
    end

    for k, v in pairs(self.tbInstances) do
        v:OnEnterLobby(Component)
    end
end

local function OnLeaveLobby(self)
    ClearNextDayTimer(self)
    ClearBattleStarActivityTimer(self)
    ClearMinTimer(self)
    self.bInLobby = false

    for k, v in pairs(self.tbInstances) do
        v:OnEnterLobby()
    end    
end

local function OnPlayerDataSync(self, tbPlayerData, bReconnected)
        -- 重连需要重新请求数据，但是不需要弹窗
    self.bReconnected = bReconnected

    self:RequestNoobLoginSchedule()
    self:RequestGetCheckInInfo()
    self:RequestGetTimedAwardInfo()
    self:RequestGetContinuousSchedule()

    UnregisterAll(self)

    -- if SeaAdventureHelper.bTest == true then
    --     tbPlayerData.data.activity.id = {1003}
    -- end
    if tbPlayerData.data.activity ~= nil then
        RegisterAll(self, tbPlayerData.data.activity)
    end

    for k, v in pairs(self.tbInstances) do
        v:OnPlayerDataSync(tbPlayerData.data.activity or {}, bReconnected)
    end      
end

local function OnFFAProcessStateChanged(self, nState)
    if nState ~= ProtoDR.rFFAProcessState_EState.PARACHUTING then
        log("verify schedule enter battle ", nState)
        return
    end
    if self.bInLobby == nil then
        log("verify schedule enter battle and reconnect ")
        -- 杀进程，重新进入游戏
        return
    end
    log("verify schedule enter battle")
    self.nBattleCount = ScheduleHelper:GetAndSetTodayBattleCount(1)
end

local function OnItemUpdate(self, nTemplateId, bAdd)
    -- verify is schedule task item
    for k, v in pairs(self.tbInstances) do
        v:OnItemUpdate(nTemplateId, bAdd)
    end
end

local function OnItemAdd(self, tbItem)
    local nItemTemplateId = tbItem:GetTemplateId()
    OnItemUpdate(self, nItemTemplateId, true)
end

local function OnItemRemove(self, _, nTemplateId)
    OnItemUpdate(self, nTemplateId, false)
end

local function OnItemChange(self, nInstanceId, nStackCount, bAdd)
    local tbItem = ItemSystem:GetItem(nInstanceId)
    if tbItem then
        OnItemUpdate(self, tbItem:GetTemplateId(), bAdd)
    end
end

local function BindEvent(self, EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnEnterLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnItemAdd)
    EventHelper:RegisterEvent(ClientEventDef.EV_REMOVE_LOBBY_ITEM, self, OnItemRemove)
    EventHelper:RegisterEvent(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnItemChange)

    for k, v in pairs(self.tbInstances) do
        v:BindEvent(EventHelper)
    end
end

function ScheduleSystem:Init()
    self.tbInstances = {}
    -- RegisterAll(self)

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    BindEvent(self, self.EventHelper)
    -- self.nBattleCount = ScheduleHelper:GetAndSetTodayBattleCount(0)

    return true
end

function ScheduleSystem:Uninit()
    ClearNextDayTimer(self)
    ClearBattleStarActivityTimer(self)
    ClearMinTimer(self)
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.bInLobby = nil
    UnregisterAll(self)
    self.tbInstances = nil
end

function ScheduleSystem:GetComponent()
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf ~= nil then
        return tbPlayerSelf.ScheduleComponent
    end
end

--==============================--
-- request
--==============================-----------------
function ScheduleSystem:RequestSevenDayGetReward()
    self:SendPacket(Proto.c2s_CheckInAward)
end

function ScheduleSystem:RequestGetCheckInInfo()
    self:SendPacket(Proto.c2s_GetCheckInInfo)            
end

function ScheduleSystem:RequestNoobLoginSchedule()
    self:SendPacket(Proto.c2s_NoobLoginSchedule)
end

function ScheduleSystem:RequestGetNoobLoginAward(nIndex)
    local c2s_GetNoobLoginAward = {
        day = nIndex
    }
    self:SendPacket(Proto.c2s_GetNoobLoginAward, c2s_GetNoobLoginAward)
end

function ScheduleSystem:RequestGetTimedAwardInfo()
    self:SendPacket(Proto.c2s_GetTimedAwardInfo)
end

function ScheduleSystem:RequestTimedAward(nTemplateId)
    local c2s_TimedAward = {
        template_id = nTemplateId
    }
    self:SendPacket(Proto.c2s_TimedAward, c2s_TimedAward)
end

function ScheduleSystem:RequestGetContinuousSchedule()
    self:SendPacket(Proto.c2s_GetContinuousSchedule)
end

function ScheduleSystem:RequestReceiveContinuousAward(nDay)
    local c2s_ReceiveContinuousAward = {
        day = nDay
    }
    self:SendPacket(Proto.c2s_ReceiveContinuousAward, c2s_ReceiveContinuousAward)
end
--==============================--
-- recv
--==============================-----------------
function ScheduleSystem:RecvGetNoobLoginAward(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)

        if tbPacket.login_status ~= nil then
            -- 矫正状态
            local tbData = ScheduleHelper:ParseNoobLoginData(tbPacket.login_status)
            SetNoobLogin(self, tbData)
        end
        return
    end

    local Component = self:GetComponent()
    if Component == nil then
        logerror("ScheduleSystem RecvGetNoobLoginAward but no component")
        return
    end

    Component:SetGetNoobLoginAward(tbPacket.day)
    local tbNoobData = Component:GetNoobLogin()
    if tbNoobData ~= nil and tbPacket.day == #tbNoobData then 
        -- 领取了今天的奖励，立刻弹出下一天的奖励展示
        if #tbNoobData < NoobLoginDataTable:GetCount() then
            if #tbNoobData == 1 then
                UIManager:OpenWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN_SECOND_DAY, {nDay = #tbNoobData})
            else
                UIManager:OpenWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN_NEXT_DAY, {nDay = #tbNoobData})
            end
        end
    end

    if (#tbNoobData >= NoobLoginDataTable:GetCount()) and (not Component:HasNoobLoginAward()) then
        log("ScheduleSystem:RecvGetNoobLoginAward is over", tbPacket.day)
        SetNoobLogin(self)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_NOOB_LOGIN_REFRESH)
    end
    
    if not Component:HasNoobLoginAward() then
        UIManager:CloseWnd(UIDef.UI_SCHEDULE_NOOB_LOGIN)
    end
end

function ScheduleSystem:RecvNoobLogin(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        logerror("ScheduleSystem RecvNoobLogin but no component")
        return
    end

    local tbData = ScheduleHelper:ParseNoobLoginData(tbPacket.login_status)
    if tbData ~= nil then
        SetNoobLogin(self, tbData)
    end

    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
end

function ScheduleSystem:RecvSevenDayCheckIn(tbPacket)
    local Component = self:GetComponent()
    if not Component then
        logerror("ScheduleSystem RecvSevenDayCheckIn but no component")
        return
    end
    Component:SetSevenDayCheckIn(tbPacket)
    
    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    EventManager:OnFireEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_CHECKIN, tbPacket.check_in_count, tbPacket.can_award)
end

function ScheduleSystem:RecvSevenDayGetReward(tbPacket)
    local nCode = tbPacket.return_code
    local Component = self:GetComponent()
    if Component == nil then
        logerror("ScheduleSystem:RecvSevenDayGetReward component is nil")
        return
    end
    Component:SetSevenDayCheckIn(tbPacket)
    if nCode == Proto.ReturnCode.CHECKIN_HAS_AWARD then
        UIUtils.ShowToast(UITextDef.SEVEN_DAY_HAS_AWARD)
    end
    UIManager:CloseWnd(UIDef.UI_SEVEN_DAY)
    EventManager:OnFireEvent(ClientEventDef.EV_ACTIVIEY_SEVENDAY_GETREWARD, tbPacket.check_in_count, tbPacket.can_award)
end

function ScheduleSystem:RecvBattleStar(tbPacket)
    if tbPacket.remain_seconds <= 0 then
        log("ScheduleSystem:RecvBattleStar and remain time: ", tbPacket.remain_seconds)
        return
    end
    local nCurTime = GlobalVariableSystem_C:GetServerTimeUtc()
    local nTime = nCurTime + tbPacket.remain_seconds
    log("ScheduleSystem:RecvBattleStar time", nCurTime, tbPacket.remain_seconds)

    local Component = self:GetComponent()
    if Component == nil then
        logerror("ScheduleSystem:RecvBattleStar component is nil")
        return
    end
    Component:SetBattleStarCloseTime(nTime)
    VerifyBattleStarTimer(self)
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_BATTLE_STAR_REFRESH)
end

function ScheduleSystem:RecvGetTimedAwardInfo(tbPacket)
    local Component = self:GetComponent()
    if not Component then
        log("ScheduleSystem RecvGetTimedAwardInfo but no component")
        return
    end

    Component:SetFixedTimeAwardInfo(tbPacket.timed_award)
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH)
end

function ScheduleSystem:RecvTimedAward(tbPacket)
    local Component = self:GetComponent()
    if not Component then
        logerror("ScheduleSystem RecvTimedAward but no component")
        return
    end

    local tbAwardState = Proto.s2c_GetTimedAwardInfo_TimedAwardFlag
    local tbCode = Proto.ReturnCode
    local nReturnCode = tbPacket.return_code 

    if nReturnCode ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        if nReturnCode == tbCode.TIMED_AWARD_BEFORE then
            Component:SetFixedTimeAwardState(tbPacket.template_id, tbAwardState.TIMED_BEFORE)
        elseif nReturnCode == tbCode.TIMED_AWARD_OUT then
            Component:SetFixedTimeAwardState(tbPacket.template_id, tbAwardState.TIMED_OUT)
        elseif nReturnCode == tbCode.TIMED_AWARDED then
            Component:SetFixedTimeAwardState(tbPacket.template_id, tbAwardState.TIMED_AWARDED)
        end
    else
        Component:SetFixedTimeAwardState(tbPacket.template_id, tbAwardState.TIMED_AWARDED)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_FIXED_TIME_AWARD_REFRESH)
end

function ScheduleSystem:GetAwardMultiple()
    local Component = self:GetComponent()
    if Component == nil or Component:GetBattleStarCloseTime() == nil then
        return 
    else
        local tbBattleStar = ScheduleIni.tbBattleStar
        return tbBattleStar.nTemplateId, tbBattleStar.nMultiple
    end
end

function ScheduleSystem:RecvGetContinuousSchedule(tbPacket)
    local Component = self:GetComponent()
    if not Component then
        logerror("ScheduleSystem RecvGetContinuousSchedule but no component")
        return
    end

    local tbData = ScheduleHelper:ParseContinuousData(tbPacket.login_days, tbPacket.award_status)   
    Component:SetContinuous(tbPacket.login_days, tbData)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_CONTINUOUS_REFRESH)
end

function ScheduleSystem:RecvReceiveContinuousAward(tbPacket)
    local Component = self:GetComponent()
    if not Component then
        logerror("ScheduleSystem RecvReceiveContinuousAward but no component")
        return
    end

    local tbData = ScheduleHelper:ParseContinuousData(tbPacket.login_days, tbPacket.award_status)    
    Component:SetContinuous(tbPacket.login_days, tbData)

    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
    end
    
    if not Component:HasContinuousAward() then
        UIManager:CloseWnd(UIDef.UI_SCHEDULE_CONTINUOUS)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_SCHEDULE_CONTINUOUS_REFRESH, tbPacket.day)
end

function ScheduleSystem:HasTips()
    local Component = self:GetComponent()
    local bHas = ScheduleHelper:HasTips(Component)
    if bHas then
        return true
    end
    for k, v in pairs(self.tbInstances) do
        if v:HasTip() then
            return true
        end
    end

    return false
end

function ScheduleSystem:HasTipsById(nId)
    local Component = self:GetComponent()
    if Component == nil then
        return false
    end
    local ScheduleUITemp = ScheduleUITable:GetTemplate(nId)
    if ScheduleUITemp == nil then
        return false
    end
    
    local tbScheduleTemp = ScheduleTable:GetTemplate(nId)
    if tbScheduleTemp == nil then
        local bHas = ScheduleHelper[ScheduleUITemp.szIsTip](self, Component, true)
        return bHas
    end

    for k, v in pairs(self.tbInstances) do
        if v.tbTemplate.nId == nId then
            return v:HasTip()
        end
    end   

    return false
end

function ScheduleSystem:IsOpen(nId)
    local Component = self:GetComponent()
    if Component == nil then
        return false
    end
    local ScheduleUITemp = ScheduleUITable:GetTemplate(nId)
    if ScheduleUITemp == nil then
        return false
    end
    local tbScheduleTemp = ScheduleTable:GetTemplate(nId)

    if tbScheduleTemp == nil then
        if ScheduleUITemp.szIsOpen == nil or (ScheduleHelper[ScheduleUITemp.szIsOpen] ~= nil and ScheduleHelper[ScheduleUITemp.szIsOpen](self, Component)) then
            return true
        end
    elseif tbScheduleTemp.szType ~= nil then
        local tbInstance = self:GetInstance(tbScheduleTemp.szType)
        if tbInstance ~= nil and tbInstance:IsOpen() then
            return true
        end
    end

    return false
end

function ScheduleSystem:GetInstance(szType)
    return self.tbInstances[szType]
end

function ScheduleSystem:OnRecvNotifyActivity(tbPacket)
    for i, v in ipairs(tbPacket.open_id) do
        Register(self, v)
    end
    
    local tbTemp = nil
    for i, v in ipairs(tbPacket.close_id) do
        tbTemp = ScheduleTable:GetTemplate(v)
        Unregister(self, tbTemp.szType)
    end
end

function ScheduleSystem:DispatchMessage(szMessageId, tbPacket)
    local szProcessFuncName = "Recv"..string.sub( szMessageId, 5, string.len(szMessageId))
    local bProcessed = false
    for k, v in pairs(self.tbInstances) do
        if v[szProcessFuncName] ~= nil then
            v[szProcessFuncName](v, tbPacket)
            bProcessed = true
        end
    end
    if not bProcessed then
        -- 因为服务器在playerdata 中有进行中的活动，客户端register了这个活动，并请求了该活动的信息，
        -- 在没收到该活动信息时，接着收到notifyclose 活动信息，客户端unregister了该活动
        -- 最后收到了服务器返回的该活动信息，发现没有这个活动了，所以没有处理该信息的地方。。。。
        -- 之后判断一下return_code如果为ACTIVITY_NOT_FOUND
        log(string.format("ScheduleSystem:DispatchMessage not find recv messageid=%s, processfunc=%s", szMessageId, szProcessFuncName))
    end
end

-- pop
function ScheduleSystem:ProcessUIPop(szUIName)
    local szFun = "Process"..string.sub(szUIName, 4, string.len(szUIName))

    if ScheduleHelper[szFun] ~= nil then
        local Component = self:GetComponent()
        if Component ~= nil then
            if ScheduleHelper[szFun](self, self, Component) then
                return
            end 
        end
    end

    for k, v in pairs(self.tbInstances) do
        if v[szFun] ~= nil then
            if v[szFun](v) then
                return
            end
        end
    end

    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_UI_POP)
end

function ScheduleSystem:CanSkip(szName)
    for k, v in pairs(self.tbInstances) do
        if v.szName == szName then
            if v:IsOpen() then
                return false
            end
        end
    end

    return true
end

function ScheduleSystem:GetScheduleAward(tbPacket)
    for k, v in pairs(self.tbInstances) do
        if v["OnGetScheduleAward"] ~= nil then
            v["OnGetScheduleAward"](v, tbPacket)
        end
    end
end

function ScheduleSystem:DeactivateByType(szType)
    Unregister(self, szType)
end

return ScheduleSystem