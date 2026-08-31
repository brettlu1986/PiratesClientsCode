local Proto = require("ClientProtoNames")
local AwardSessionType = require("AwardSessionType")
local ClientEventDef = require("ClientEventDef")
local SelfEventHelper = require("SelfEventHelper")
local DisplayItemHelper = require("DisplayItemHelper")
local AwardSessionRegister = dynamic_require("AwardSessionRegister")
local HomelandSystem = require("HomelandSystem")
local EventManager = require("EventManager")
local LobbyChatSystem = require("LobbyChatSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")

local AwardSystem = {}
AwardSystem.tbClasses = nil
AwardSystem.tbAlivedInstances = nil

AwardSystem.tbAwardDatas = nil
AwardSystem.bNotInDungeon = nil
AwardSystem.bNotInLoading = nil
AwardSystem.bIsLobbyReady = nil

AwardSystem.tbLevelUpAwardDatas = nil

local function ShowAwardWnd(tbAwardDatas)
    LobbyChatSystem:OnAwardNotification(tbAwardDatas)
    local szWndName = UIDef.UI_LOBBY_AWARD_ITEM
    if UIManager:IsWndOpen(szWndName) then
        EventManager:OnFireEvent(ClientEventDef.EV_UI_PUSH_AWARD, tbAwardDatas)
    else
        local tbItemDatas = tbAwardDatas[1]
        table.remove(tbAwardDatas, 1)
        local tbItemQueue = nil
        if #tbAwardDatas > 0 then
            tbItemQueue = {}
            for i, v in ipairs(tbAwardDatas) do
                table.insert(tbItemQueue, v.tbAwardDatas)
            end
        end
        UIManager:OpenWnd(UIDef.UI_LOBBY_AWARD_ITEM,{tbItemDatas = tbItemDatas.tbAwardDatas, tbItemQueue = tbItemQueue})
    end
end

local function ShowAward(tbAwardDatas, szSourceWndName)
    local tbActivateSub = LobbySystem:GetActiveSub()

    if tbActivateSub.nSubType == LobbySubTypeDef.SEASON 
        or tbActivateSub.nSubType == LobbySubTypeDef.SAILOR then
        if not DisplayItemHelper.CheckNeedDisplayItems(tbAwardDatas[1].tbAwardDatas) then
            ShowAwardWnd(tbAwardDatas)
            return
        end
    end

    local nCallerLobbySub = nil
    if tbActivateSub then
        nCallerLobbySub = tbActivateSub.nSubType
    end
    if nCallerLobbySub ~= LobbySubTypeDef.AWARD then
        local tbParam = {
            nCallerLobbySub = nCallerLobbySub,
            tbAwardDatas = tbAwardDatas,
            szSourceWndName = szSourceWndName,
        }
        LobbySystem:ActivateNextSub(LobbySubTypeDef.AWARD, tbParam)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_PUSH_LOBBY_AWARD, tbAwardDatas)
    end
end

local function VerfiyShowAward(self, szSourceWndName)
    if self.bNotInDungeon == false then
        return 
    end

    if self.bNotInLoading == false then
        return 
    end
    
    if self.tbAwardDatas ~= nil and #self.tbAwardDatas > 0 then
        local bShow = true
        for k, v in pairs(self.tbAlivedInstances) do
            if not k:CheckShowAward(self.tbAwardDatas[1].nSourceType) then
                bShow = false
                break
            end
        end
        if not bShow then
            return
        end
    end

    if self.tbAwardDatas ~= nil and #self.tbAwardDatas > 0 then
        ShowAward(self.tbAwardDatas, szSourceWndName)
    end
    self.tbAwardDatas = nil        

    for k, v in pairs(self.tbAlivedInstances) do
        k:TryFinish()
    end         
end

local function OnNotInBattle(self)
    self.bNotInDungeon = true
    self.bIsLobbyReady = true
    VerfiyShowAward(self)
end

local function OnEnterBattle(self)
    self.bNotInDungeon = false
end

local function OnDisconnected(self)
    for k, v in pairs(self.tbAlivedInstances) do
        self:CancelSession(k)
    end
end

local function AddHomelandAward(self, tbItemDatas)
    if self.tbHomelandAwardData == nil then
        self.tbHomelandAwardData = {}
    end
    for _, v in ipairs(tbItemDatas) do
        table.insert(self.tbHomelandAwardData, v)
    end
end

local function OnEnterHomeland(self)
    if self.tbHomelandAwardData ~= nil then
        local tbAwardDatas = {}
        table.insert(tbAwardDatas, self.tbHomelandAwardData)
        ShowAward(tbAwardDatas)
        self.tbHomelandAwardData = nil
    end
end

-- local function OnLobbySubSystemActivate(self, nType)
--     if nType ~= LobbySubTypeDef.MAIN then
--         return
--     end

--     local tbLobbyAward = LobbySystem:GetSub(LobbySubTypeDef.AWARD)
--     if tbLobbyAward and tbLobbyAward:NeedShowDisplayWnd() then
--         LobbySystem:ActivateNextSub(tbLobbyAward.nSubType)
--     end
-- end

local function OnUseLobbyItemSuccessId(self, nId)
    local tbDisplayItemTemplates = DisplayItemHelper.GetExperienceCardDisplayTemplate(nId)
    if not tbDisplayItemTemplates or #tbDisplayItemTemplates <= 0 then
        return
    end
    local tbAwardDatas = {}
    table.insert(tbAwardDatas, {tbAwardDatas = tbDisplayItemTemplates})
    local nCallerLobbySub = LobbySystem:GetActiveSub().nSubType
    local tbParam = {
        tbAwardDatas = tbAwardDatas, 
        nCallerLobbySub = nCallerLobbySub,
    }
    LobbySystem:ActivateNextSub(LobbySubTypeDef.AWARD, tbParam)
end

local function OnOpenUI(self, szWndName)
    if szWndName == UIDef.UI_LOADING then
        self.bNotInLoading = false
    end
end

local function OnPostExitUI(self, szWndName)
    if szWndName == UIDef.UI_LOADING then
        self.bNotInLoading = true
        if self.bNotInDungeon and self.bIsLobbyReady then
            VerfiyShowAward(self)
        end
    end
end
    
function AwardSystem:Init()
    self.tbClasses = {}
    self.tbAlivedInstances = {}
    AwardSessionRegister:Register(self)

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_HOMELAND, self, OnEnterHomeland)
    EventHelper:RegisterEvent(ClientEventDef.EV_DISCONNECTED, self, OnDisconnected)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_READY, self, OnNotInBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnNotInBattle)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_SUB_SYSTEM_ACTIVATE, self, OnLobbySubSystemActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_USE_LOBBY_ITEM_SUCCESS_ID, self, OnUseLobbyItemSuccessId)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnOpenUI)
    EventHelper:RegisterEvent(ClientEventDef.EV_POST_EXIT_UI, self, OnPostExitUI)
    

    self.bNotInDungeon = true
    self.bNotInLoading = true
    self.bIsLobbyReady = false
    self.tbLevelUpAwardDatas = {}

    return true
end

function AwardSystem:Uninit()

    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    for k, v in pairs(self.tbAlivedInstances) do
        self:CancelSession(k)
    end

    self.tbClasses = nil
    self.tbAlivedInstances = nil
    self.tbAwardDatas = nil
    self.bNotInDungeon = nil
    self.bNotInLoading = nil
    self.bIsLobbyReady = nil
end

function AwardSystem:Register(nType, szFileName)
    local Class = require(szFileName)
    assert(Class)
    assert(self.tbClasses[nType] == nil)
    self.tbClasses[nType] = Class
end

function AwardSystem:StartSession(nType, tbParams, tbSelf, fnOnFinished)
    local Class = self.tbClasses[nType]
    if Class == nil then
        error(string.format("Award StartSession failed, invalid type: %d", nType))
    end

    local Instance = Class()
    Instance.nType = nType
    Instance.fnNotifyFinishedToParent = function(EndInstance)
        self:FinishSession(EndInstance)
    end

    local tbInfo = {}
    tbInfo.tbSelf = tbSelf
    tbInfo.fnOnFinished = fnOnFinished
    self.tbAlivedInstances[Instance] = tbInfo

    Instance:OnStarted(tbParams)
    return Instance
end

function AwardSystem:CancelSession(Instance)
    local tbInfo = self.tbAlivedInstances[Instance]
    if not tbInfo then
        error("Invalid award session instance")
        return false
    end
    Instance:OnCanceled()

    self.tbAlivedInstances[Instance] = nil

    return true
end

function AwardSystem:FinishSession(Instance)
    local tbInfo = self.tbAlivedInstances[Instance]
    if not tbInfo then
        error("Invalid award session instance")
        return false
    end
    self.tbAlivedInstances[Instance] = nil

    Instance:OnFinished()

    if tbInfo.fnOnFinished then
        if tbInfo.tbSelf then
            tbInfo.fnOnFinished(tbInfo.tbSelf, Instance)
        else
            tbInfo.fnOnFinished(Instance)
        end
    end    
    return true
end

function AwardSystem:GetAlivedSession(nType)
    for k, v in pairs(self.tbAlivedInstances) do
        if k.nType == nType then
            return k
        end
    end
    return nil
end

local function VerifyAwardSession(self, nSourceType, tbPacket)
    local AwardSourceType = Proto.AwardSourceType
    if nSourceType == AwardSourceType.SEASON_CHALLENGE
        or nSourceType == AwardSourceType.SEASON_BATTLE_PASS then
        if self:GetAlivedSession(AwardSessionType.SeasonAwardSession) == nil then 
            self:StartSession(AwardSessionType.SeasonAwardSession)
        end
    elseif nSourceType == AwardSourceType.SEASON then
        if self:GetAlivedSession(AwardSessionType.SeasonResultAwardSession) == nil then 
            self:StartSession(AwardSessionType.SeasonResultAwardSession)
        end
    elseif nSourceType == AwardSourceType.DRAW_ACTIVITY_AWARD 
        or nSourceType == AwardSourceType.BOX_ACTIVITY_AWARD 
        or nSourceType == AwardSourceType.ROLL_TILE_AWARD then
        if self:GetAlivedSession(AwardSessionType.ScheduleRouletteAwardSession) == nil then 
            self:StartSession(AwardSessionType.ScheduleRouletteAwardSession, tbPacket)
        end
    end
end

local function VerifyBuySession(self, nSourceType, tbAwardDatas)
    local AwardSourceType = Proto.AwardSourceType
    if nSourceType ~= AwardSourceType.SHOPPING then
        return
    end
    local tbBuySession = self:GetAlivedSession(AwardSessionType.BuyAwardSession)
    if not tbBuySession then
        return
    end

    tbBuySession:TryFinish()
end

function AwardSystem:OnRecvAwardNotification(tbPacket)
    local nSourceType = tbPacket.source_type
    local AwardSourceType = Proto.AwardSourceType
    if nSourceType == AwardSourceType.SUMMON_PARTNER
        or nSourceType == AwardSourceType.ITEM_UNLOCK_CARD
        or nSourceType == AwardSourceType.SUMMON_SAILOR
        or nSourceType == AwardSourceType.ACCOUNT_REGULAR_AWARD
        or nSourceType == AwardSourceType.UNLOCK_SHIP 
        or nSourceType == AwardSourceType.DRAW_TASK_AWARD
        or nSourceType == AwardSourceType.BOX_TASK_AWARD 
        or nSourceType == AwardSourceType.ROLL_TASK_AWARD then
        return
    end

    local tbAddedItemDatas = tbPacket.award_addition
    if nSourceType == AwardSourceType.PLAYER_LEVEL_UP_AWARD then
        for _, v in ipairs(tbAddedItemDatas) do
            local nCount = v.count
            if nCount > 0 then
                local tbItemData = {}
                tbItemData.nItemTemplateId = v.template_id
                tbItemData.nCount = nCount
                table.insert(self.tbLevelUpAwardDatas, tbItemData)
            end
        end
        return
    end

    local tbAwardDatas = {}
    for _, v in ipairs(tbAddedItemDatas) do
        local nCount = v.count
        if nCount > 0 then
            local tbItemData = {}
            tbItemData.nItemTemplateId = v.template_id
            tbItemData.nCount = nCount
            EventManager:OnFireEvent(ClientEventDef.EV_CLIENT_LOG_EVENT_AWARD_GAIN, nSourceType, v)
            table.insert(tbAwardDatas, tbItemData)
        end
    end

    if #tbAwardDatas == 0 then
        return
    end

    if nSourceType == AwardSourceType.RESEARCH then
        if not HomelandSystem:IsInHomeland() then
            AddHomelandAward(self, tbAwardDatas)
        else
            ShowAward(self)
        end
        return
    end

    VerifyAwardSession(self, nSourceType, tbPacket)
    if self.tbAwardDatas == nil then
        self.tbAwardDatas = {}
    end
    table.insert( self.tbAwardDatas, {tbAwardDatas = tbAwardDatas, nSourceType = nSourceType} )
    VerifyBuySession(self, nSourceType, tbAwardDatas)
    VerfiyShowAward(self)
end

function AwardSystem:ShowCacheAward(szSourceWndName)
    VerfiyShowAward(self, szSourceWndName)
end

function AwardSystem:GetAndDeleteLevelUpAwardDatas()
    local tbLevelUpAwardDatas = self.tbLevelUpAwardDatas
    self.tbLevelUpAwardDatas = {}
    return tbLevelUpAwardDatas
end

return AwardSystem