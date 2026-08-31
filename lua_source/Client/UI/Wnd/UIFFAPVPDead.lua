-----------------------------------------------------
--File Name    : UIFFAPVPDead.lua
--Author       : Ran jie
--Create Time  : 2018-11-8
--Description  : ffa非吃鸡玩法的死亡界面
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UIFFAPVPDead = luaclass("UIFFAPVPDead", WndBase)

local CampSystem = require("CampSystem")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")


local function SwitchViewer( self, fnFailedFunc )
    local nIndex = self.nIndex + 1
    local tbPlayer = self.tbTeammateList[nIndex]
    if tbPlayer:IsDead() then
        if nIndex ~= 1 then
            table.remove(self.tbTeammateList, nIndex)
        end
        if #self.tbTeammateList > 1 then
            fnFailedFunc(self)
            return
        else
            tbPlayer = self.tbTeammateList[1]
            self.nIndex = 0
        end
    end
    self.tbCurrentPlayer = tbPlayer
    self.pPlayerController:SetShipViewer(tbPlayer.pUEActor)
end

local function OnClickedBtnPrev( self )
    self.nIndex = (self.nIndex - 1) % #self.tbTeammateList
    SwitchViewer(self, OnClickedBtnPrev)
end

local function OnClickedBtnNext( self )
    self.nIndex = (self.nIndex + 1) % #self.tbTeammateList
    SwitchViewer(self, OnClickedBtnNext)
end

local function OnAnyShipDie( self, tbDeadShip )
    if (self.nIndex ~= 0) and (self.tbCurrentPlayer == tbDeadShip) then
        OnClickedBtnNext(self)
    end
end



UIFFAPVPDead.pPlayerController = nil
UIFFAPVPDead.tbTeammateList = nil
UIFFAPVPDead.nIndex = 0
UIFFAPVPDead.tbCurrentPlayer = nil
UIFFAPVPDead.nWaitTime = nil
UIFFAPVPDead.DleyTime = nil

function UIFFAPVPDead:OnLoad()
    EventManager:OnFireEvent(ClientEventDef.EV_UI_BATTLE_DEAD_STATE, true)
    self.pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    self.tbTeammateList = { tbPlayerSelf }
    self.tbCurrentPlayer = tbPlayerSelf
    self.nIndex = 0

    -- 初始化队友列表
    local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    for _, tbObject in pairs(tbGameObjects) do
        if (tbObject.ObjectType == GameObjectTypeDef.PlayerOther) then
            if CampSystem:IsFriendRelation(tbPlayerSelf, tbObject) then
                table.insert(self.tbTeammateList, tbObject)
            end
        end
    end
end

function UIFFAPVPDead:OnUnbindEvent( EventHelper )
    if self.DleyTime ~= nil then
        self.TimerHelper:ClearTimer(self.DleyTime)
    end
    self.DleyTime = nil
    self.nWaitTime = nil
end

function UIFFAPVPDead:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnPrev.OnClicked, self, OnClickedBtnPrev)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnNext.OnClicked, self, OnClickedBtnNext)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnAnyShipDie)
end




return UIFFAPVPDead
