-- 开始采集

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleCollectionStartTarget = luaclass("BattleCollectionStartTarget", BattleTargetBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectSystem =  dynamic_require("GameObjectSystem")
local BattleBlackboard = require("BattleBlackboard")
local BattleCollectionSystem =  require("BattleCollectionSystem")

BattleCollectionStartTarget.nInvalidTemplateId = nil
BattleCollectionStartTarget.bTheSameCampType = nil
BattleCollectionStartTarget.szSetCollectionStartResultKey = nil

function BattleCollectionStartTarget:Init()
    BattleCollectionStartTarget.super.Init(self)
    
    self.szName = "BattleCollectionStartTarget"
end

function BattleCollectionStartTarget:RegisterEvent()
    BattleCollectionStartTarget.super.RegisterEvent(self)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_START_NPC, self, self.OnCollectionStart)
end


function BattleCollectionStartTarget:Parse(tbJsonData)
    self.nInvalidTemplateId = tbJsonData.InvalidTemplateId
    self.bTheSameCampType = tbJsonData.TheSameCampType
    self.szSetCollectionStartResultKey = tbJsonData.SetCollectionStartResultKey

   return true
end

function BattleCollectionStartTarget:OnCollectionStart(nNpcServerInstanceId, nPlayerServerInstanceId)
    local tbNpc = GameObjectSystem:FindByInstanceId(nNpcServerInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
    local bCondition = false
    if tbNpc and tbPlayer then
        if self.nInvalidTemplateId > 0 then
            if tbNpc.nTemplateId == self.nInvalidTemplateId then
                bCondition = true
            end
        end 

        if self.szSetCollectionStartResultKey then
            if tbNpc.BattleCampComponent:GetCampType() == tbPlayer.BattleCampComponent:GetCampType() then
                bCondition = bCondition and true
            else
                bCondition = bCondition and false
            end
        end 

        if bCondition then
            BattleBlackboard:SetBool(self.szSetCollectionStartResultKey, false)
        else
            BattleBlackboard:SetBool(self.szSetCollectionStartResultKey, true)
            BattleCollectionSystem:OnCollectionStart(nNpcServerInstanceId, nPlayerServerInstanceId)
        end
        
    end

    self:Complete()    

end

function BattleCollectionStartTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_START_NPC, self, self.OnCollectionStart)
end

return BattleCollectionStartTarget