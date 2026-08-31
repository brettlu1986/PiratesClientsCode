
--复活

local luaclass = require("luaclass")
local BattleReviveSystemClass = require("BattleReviveSystem")
local BattleReviveSystem_C = luaclass("BattleReviveSystem_C", BattleReviveSystemClass)


local ClientEventDef = require("ClientEventDef")
local SelfEventHelper = require("SelfEventHelper")
local DGProto= require("DungeonRepProtoNames")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local DCProto= require("DungeonCommonProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")
local EventManager = require("EventManager")



function BattleReviveSystem_C:Init()
    BattleReviveSystem_C.super.Init(self)
    self.EventHelper = SelfEventHelper()

    self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_RESET_CHOOSEREVIVE, self, self.ReviveChoose)
    
    return true
end

function BattleReviveSystem_C:Uninit()
    BattleReviveSystem_C.super.Uninit(self)
    self.EventHelper:UnregisterAll()
end

function BattleReviveSystem_C:RevivePanlShow(nReviveType, bIsDie, nWaitReviveTime, bIsCanRevive, nCostType, nCostNum)
    if nReviveType == DGProto.rReviveInfoAndShow_EReviveType.BACKCITY_NOWREVIVE 
        or nReviveType == DGProto.rReviveInfoAndShow_EReviveType.WAIT_NOW then
        if bIsDie then
            local tbOpenArgs = {}
            tbOpenArgs.nWaitReviveTime = nWaitReviveTime
            tbOpenArgs.bIsCanRevive = bIsCanRevive
            tbOpenArgs.nCostType = nCostType
            tbOpenArgs.nCostNum = nCostNum
            tbOpenArgs.nReviveType = nReviveType
            UIManager:OpenWnd(UIDef.UI_REVIVE, tbOpenArgs)
        else
            EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_REVIVE_REST)
        end

    else
        if bIsDie then
            local WndBattleResult = UIManager:GetWnd(UIDef.UI_BATTLE_RESULT)
            if WndBattleResult == nil then
                UIManager:OpenWnd(UIDef.UI_BATTLE_REBORN_WAIT)
            end
         else
            UIManager:CloseWnd(UIDef.UI_BATTLE_REBORN_WAIT)
         end
        
    end
end

function BattleReviveSystem_C:WaitReset(_nType, nWaitTime)
    local WndRevive = UIManager:GetWnd(UIDef.UI_REVIVE)
    if WndRevive then
        UIManager:CloseWnd(UIDef.UI_REVIVE)
    end
    local WndCountDown = UIManager:GetWnd(UIDef.UI_COUNTDOWN)
    if WndCountDown then
        UIManager:CloseWnd(UIDef.UI_COUNTDOWN)
    end

    local WndRebornWait = UIManager:GetWnd(UIDef.UI_BATTLE_REBORN_WAIT)
    if WndRebornWait == nil then
        WndRebornWait = UIManager:OpenWnd(UIDef.UI_BATTLE_REBORN_WAIT)           
    end
    WndRebornWait:CreateResetWaitTime(nWaitTime)
end

function BattleReviveSystem_C:ReviveChoose(nReviveType, bBackCity)
    if nReviveType == DGProto.rReviveInfoAndShow_EReviveType.WAIT_NOW and bBackCity == true then
        UIManager:OpenWnd(UIDef.UI_BATTLE_REBORN_WAIT)        
        return 
    end
    
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    NetworkManager:GetRPCNetworkProxy():SendToServer(DCProto.c2d_ReviveMode, 
    {player_instanceId = tbPlayerSelf.nServerInstanceId,  backcity = bBackCity})
end

return BattleReviveSystem_C()