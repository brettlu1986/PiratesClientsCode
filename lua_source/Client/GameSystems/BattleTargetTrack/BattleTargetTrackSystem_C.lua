local luaclass = require("luaclass")
local BattleTargetTrackSystem_C = luaclass("BattleTargetTrackSystem_C")

local EventManager = require("EventManager")
local UIManager = require("UIManager")
local ClientEventDef = require ("ClientEventDef")
local UIDef = require("UIDef")
local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")


BattleTargetTrackSystem_C.nServerInstanceId = nil
BattleTargetTrackSystem_C.bTargetTrackVisible = false

function BattleTargetTrackSystem_C:Init()
    self.pLocation = Vector()
    EventManager:BindEventMethod(ClientEventDef.EV_BATTLE_SHOW_TARGETTRACK, self, self.SetTargetTrackInfoAndIsShow)    
end

function BattleTargetTrackSystem_C:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_BATTLE_SHOW_TARGETTRACK, self, self.SetTargetTrackInfoAndIsShow)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnNewObjectCreate)
end

function BattleTargetTrackSystem_C:SetTargetTrackInfoAndIsShow(nEffectInstanceId, nTargetInstanceId, nX, nY, nZ, bIsvisible)
    local tbWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
    if tbWnd and tbWnd.tbBattleInteraction then
        self.bTargetTrackVisible = bIsvisible
        local PlayerSelf = GamePlayerSelfHelper:Get()
        if (nEffectInstanceId == nil or nEffectInstanceId == 0)
            or (nEffectInstanceId > 0 and PlayerSelf:GetServerInstanceId() == nEffectInstanceId) then
            if not tbWnd.tbBattleInteraction:SetTargetTrackInfoAndIsShow(nTargetInstanceId, nX, nY, nZ, bIsvisible) then
                self.nServerInstanceId = nTargetInstanceId
                EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnNewObjectCreate)
            end
        end
    end
end

function BattleTargetTrackSystem_C:OnNewObjectCreate(tbGameObj)
    if tbGameObj:GetServerInstanceId() == self.nServerInstanceId then
        local tbWnd = UIManager:GetWnd(UIDef.UI_BATTLE_MAIN)
        if tbWnd and tbWnd.tbBattleInteraction then
            self.bTargetTrackVisible = true
            tbWnd.tbBattleInteraction:SetTargetTrackInfoAndIsShow(self.nServerInstanceId, 0, 0, 0 , true)
            EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, self.OnNewObjectCreate)
        end
    end
end

return BattleTargetTrackSystem_C()