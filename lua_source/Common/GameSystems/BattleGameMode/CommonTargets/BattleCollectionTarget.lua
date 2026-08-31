--采集完成

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleCollectionTarget = luaclass("BattleCollectionTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectSystem =  dynamic_require("GameObjectSystem")
local BattleNpcHelper = require("BattleNpcHelper")
local BattleBlackboard = require("BattleBlackboard")


BattleCollectionTarget.nRequireNumber = nil
BattleCollectionTarget.nCollectionNowNum = 0
BattleCollectionTarget.szSetObjKey = nil

function BattleCollectionTarget:Init()
    BattleCollectionTarget.super.Init(self)
    self.szName = "BattleCollectionTarget"
end

function BattleCollectionTarget:Uninit()
    BattleCollectionTarget.super.Uninit(self)
    self.nCollectionNowNum = 0
    self.nRequireNumber = nil
end

function BattleCollectionTarget:RegisterEvent()
    BattleCollectionTarget.super.RegisterEvent(self)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_END, self, self.OnCollectionEnd)
    self.nCollectionNowNum = 0
end


function BattleCollectionTarget:Parse(tbJsonData)
    BattleNpcHelper:ParseIdentifier(self, tbJsonData) 
    self.nRequireNumber = tbJsonData.RequireNumber
    self.szSetObjKey = tbJsonData.SetObjKey
    return true
end

function BattleCollectionTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_END, self, self.OnCollectionEnd)
end

function BattleCollectionTarget:OnCollectionEnd(nNpcServerInstanceId, nPlayerServerInstanceId)
    local tbNpc = GameObjectSystem:FindByInstanceId(nNpcServerInstanceId)
    
    if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then
        local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
        if tbPlayer then 
            BattleBlackboard:SetTable(self.szSetObjKey, tbPlayer)
        end
    end

    if tbNpc ~= nil and  BattleNpcHelper:CheckIdentifier(self, tbNpc) then
        if self.nRequireNumber == nil then
             self:Complete()
        else
            if self.nRequireNumber == 0 then
                self:Complete()
            else
                self.nCollectionNowNum = self.nCollectionNowNum + 1
                if  self.nRequireNumber == self.nCollectionNowNum then
                    self:Complete()
                end
            end
        end
    end

end

function BattleCollectionTarget:Complete()
     BattleCollectionTarget.super.Complete(self)
     self.nCollectionNowNum = 0
end


return BattleCollectionTarget