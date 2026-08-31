--File Name    : InteractionExplore.lua
--Author       : Zuo Kun
--Create Time  : 2017-04-11
--Description  : 采集
-----------------------------------------------------

local luaclass = require("luaclass")
local InteractionBase = require("InteractionBase")
local InteractionExplore = luaclass("InteractionExplore", InteractionBase)
local InteractionDef = require("InteractionDef")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ProgressBarTable = require("ProgressBarTable")
local SelfTimerHelper = require("SelfTimerHelper")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local AbortTypeDef = require("AbortTypeDef")

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameWorldSystem = require("GameWorldSystem")
local SoundManager = require("SoundManager")
local SelfAnimationHelper = require("SelfAnimationHelper")

InteractionExplore.nInteractionType = InteractionDef.InteractionMode.EXPLORE
InteractionExplore.nProgressBarID = 0
InteractionExplore.TimerHelper = nil
--是否正在采集
InteractionExplore.IsCollectioning = false
InteractionExplore.tbCurrentSound = nil 
InteractionExplore.bIsStart = false 

--[[    local tbTemp = {} 
    tbTemp.nID = 1
    tbTemp.bNeedSendToServerOnEnd = true
    EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_START, InteractionDef.InteractionMode.EXPLORE, tbTemp)]]

local function OnCommonAbortEvent( self, AbortType )
    if not self.bIsStart then 
        return 
    end 
    local tbSelectNpc = self:GetSelectNpc()
    if AbortType == AbortTypeDef.MOVE and self.IsCollectioning then
        self:Clear()
        if tbSelectNpc then
            EventManager:OnFireEvent(ClientEventDef.EV_UI_COLLECTION_BREAK, tbSelectNpc.nServerInstanceId)
        else 
            EventManager:OnFireEvent(ClientEventDef.EV_UI_COLLECTION_BREAK)
        end
        EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_ABORT)
    end
end

local function OnNavMoveStart(self)
    OnCommonAbortEvent(self, AbortTypeDef.MOVE)
end 

function InteractionExplore:DoInteraction(tbSelectedNpc, tbParams)
    self.bControlUIByState = false
    self:Clear()
    self:StopMove()
    InteractionExplore.super.DoInteraction(self, tbSelectedNpc, tbParams)
    -- UIManager:OpenWnd(UIDef.UI_INTERACTION, {tbSelectedNpc = tbSelectedNpc, tbParams = tbParams, bIsShowAvatar = false})
    self.nProgressBarID = tbParams.nID
    local tbDatas = ProgressBarTable:GetTemplate(self.nProgressBarID)
    if not tbDatas then 
        logerror("Error Progress Id " .. self.nProgressBarID)
        EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_END)
        return 
    end 
    EventManager:OnFireEvent(ClientEventDef.EV_REQUEST_PROGRESS, tbDatas)
    if not self.TimerHelper then 
        self.TimerHelper = SelfTimerHelper()
    end
    local nTimer = tbDatas.nTime
    if tbParams.nSecond and tbParams.nSecond ~= 0 then 
        nTimer = tbParams.nSecond
    end 
    -- self:PlayAnimation(tbDatas.szAnimKey)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    SelfAnimationHelper:PlayHumanAnimation(PlayerSelf, tbDatas.szAnimKey)
    if tbDatas.nSoundID > 0 then 
        self.tbCurrentSound = SoundManager:PlaySoundEffect(tbDatas.nSoundID)
    end 
    
    self.TimerHelper:NewTimerMethod(self, self.OnProgressEnd, nTimer, false)
    if tbDatas.nInterruptMove then
        self.IsCollectioning = true
        EventManager:BindEventMethod(ClientEventDef.EV_COMMON_ABORT, self, OnCommonAbortEvent)
        EventManager:BindEventMethod(ClientEventDef.EV_NAVIGATION_MOVE_START, self, OnNavMoveStart)
    end
    -- UEClientActorHelper:FaceToPlayer(tbSelectedNpc.pUEActor)
    
    self.bIsStart = true
end

function InteractionExplore:InteractionAbort()
    self.bIsStart = false 
    local tbSelectNpc = self:GetSelectNpc()
    if tbSelectNpc then
        EventManager:OnFireEvent(ClientEventDef.EV_UI_COLLECTION_BREAK, tbSelectNpc.nServerInstanceId)
    else 
        EventManager:OnFireEvent(ClientEventDef.EV_UI_COLLECTION_BREAK)
    end
    InteractionExplore.super.InteractionAbort(self)
end 

function InteractionExplore:Clear()
    self.bIsStart = false 
    self.IsCollectioning = false
    EventManager:UnBindEventMethod(ClientEventDef.EV_COMMON_ABORT, self, OnCommonAbortEvent)    
    EventManager:UnBindEventMethod(ClientEventDef.EV_NAVIGATION_MOVE_START, self, OnNavMoveStart)    
    if self.TimerHelper then 
        self.TimerHelper:ClearAllTimer()
        self.TimerHelper = nil 
    end 
end

function InteractionExplore:OnProgressEnd()
    self:Clear()
    if self.bNeedSendToServerOnEnd and not GlobalVariableSystem:IsInDungeon() then
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_FinishProgressBar)
    end 
    EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_END)  
    -- local tbDatas = ProgressBarTable:GetTemplate(self.nProgressBarID)
    -- if tbDatas ~= nil and tbDatas.nInterruptMove then
    --     EventManager:UnBindEventMethod(ClientEventDef.EV_COMMON_ABORT, self, OnCommonAbortEvent)
    -- end
end 

function InteractionExplore:OnInteractionEnd()
    self:Clear()
    -- local tbDatas = ProgressBarTable:GetTemplate(self.nProgressBarID)
    -- if tbDatas ~= nil and tbDatas.nInterruptMove then
    --     EventManager:UnBindEventMethod(ClientEventDef.EV_COMMON_ABORT, self, OnCommonAbortEvent)
    -- end
	local World = GameWorldSystem:GetWorld()
	local isOcean = false 
    if World and World.IsOcean then 
        isOcean = World:IsOcean()
    end 
    if not isOcean then 
        local PlayerSelf = GamePlayerSelfHelper:Get()
        if not PlayerSelf or not PlayerSelf.pUEActor then 
            return 
        end 
        PlayerSelf.pUEActor:StopAnimMontage(nil)    
    end 

    if self.tbCurrentSound then 
        self.tbCurrentSound:Stop()
    end 
end

-- function InteractionExplore:RefreshInteractionData(tbParams)
--     self:StopMove()
--     if self.TimerHelper then 
--         self.TimerHelper:ClearAllTimer()
--     end 

--     self.nProgressBarID = tbParams.nID
--     local tbDatas = ProgressBarTable:GetTemplate(self.nProgressBarID)
--     if not tbDatas then 
--         logdebug("Error Progress Id " .. self.nProgressBarID)
--         EventManager:OnFireEvent(ClientEventDef.EV_INTERACTION_END)
--         return 
--     end 

--     local nTimer = tbDatas.nTime
--     if tbParams.nSecond and tbParams.nSecond ~= 0 then 
--         nTimer = tbParams.nSecond
--     end 

--     local PlayerSelf = GamePlayerSelfHelper:Get()
--     PlayerSelf:PlayAnimation(tbDatas.szAnimKey)

--     if not self.TimerHelper then 
--         self.TimerHelper = SelfTimerHelper()
--     end
--     self.TimerHelper:NewTimerMethod(self, self.OnProgressEnd, nTimer, false)

--     EventManager:OnFireEvent(ClientEventDef.EV_REQUEST_PROGRESS, tbDatas)
-- end

function InteractionExplore:StopMove()
    local bNeedSendToServerOnEnd = self.bNeedSendToServerOnEnd
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf then 
        if PlayerSelf.pUEActor and PlayerSelf.pUEActor.PlayerInputComponent then 
            PlayerSelf.pUEActor.PlayerInputComponent:SetMoveEnabled(false)  
            PlayerSelf.pUEActor.PlayerInputComponent:SetMoveEnabled(true)  
        end
        -- if PlayerSelf.bIsShip and not GlobalVariableSystem:IsInDungeon() then 
        --     NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ShipStopImmediately)
        -- end 
        
    end 
    self.bNeedSendToServerOnEnd = bNeedSendToServerOnEnd
end 

return InteractionExplore