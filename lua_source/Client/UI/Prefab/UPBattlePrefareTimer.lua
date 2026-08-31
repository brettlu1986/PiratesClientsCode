-----------------------------------------------------
--File Name    : UPBattlePrefareTimer.lua
--Description  : FFABattle准备倒计时
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPGameMode = require("UPGameMode")
local UPBattlePrefareTimer = luaclass("UPBattlePrefareTimer", UPGameMode)
local ClientEventDef = require("ClientEventDef")


local DRProto = require("DungeonRepProtoNames")

local TIME_WANING = 5

function UPBattlePrefareTimer:StartGameCD(nTime, nTimeWarning)
    UPBattlePrefareTimer.super.StartGameCD(self, self.pWidgetRef.txtCoolTime, nTime, nTimeWarning)
end

-- 剩余时间同步
local function OnRecvStepRemainTime( self, rStepRemainTime )
    self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self:StartGameCD(rStepRemainTime.nTime, TIME_WANING)
end




local function OnFFATransportChanged(self, nState)
    log("OnFFATransportChanged, state=",nState)
    if nState == DRProto.rFFATransportState_EState.MOVING then
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
    
end

local function OnRecvTransportInfo(self, rTransportInfo)
    
    self.nMinOpenParachuteHeight = rTransportInfo.nMinJumpHeight
    self.nMaxOpenParachuteHeight = rTransportInfo.nMaxJumpHeight
    --logdebug("OnRecvTransportInfo,self.nMinOpenParachuteHeight,self.nMaxOpenParachuteHeight=",self.nMinOpenParachuteHeight,self.nMaxOpenParachuteHeight)
end

function  UPBattlePrefareTimer:OnLoad()
    -- body
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPBattlePrefareTimer:OnBindEvent( EventHelper )
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnRecvStepRemainTime)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_STATE_CHANGED, self, OnFFATransportChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_INFO, self, OnRecvTransportInfo)
end



return UPBattlePrefareTimer
