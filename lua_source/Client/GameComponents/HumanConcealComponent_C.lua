local luaclass = require("luaclass")
local HumanConcealComponent = require("HumanConcealComponent")
local HumanConcealComponent_C = luaclass("HumanConcealComponent_C", HumanConcealComponent)
local ClientEventDef = require("ClientEventDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

local function OnHumanAvatarCommitFinished(self, nInstanceId)
    if nInstanceId ~= self.Owner:GetServerInstanceId() then 
        return 
    end 

    self.BPConcealComponent:UpdatePrimitiveAlpha()
end 

function HumanConcealComponent_C:OnActorCreated(pUEActor)
    HumanConcealComponent_C.super.OnActorCreated(self, pUEActor)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_AVATAR_COMMIT_FINISHED, self, OnHumanAvatarCommitFinished)

    -- EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_ARMOR_ON_EQUIPED_CLIENT, self, self.OnArmorEquip)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_ARMOR_ON_UNEQUIPED_CLIENT, self, self.OnArmorUnEquip)    
end

function HumanConcealComponent_C:GetCurrentArmorLevel()
    local nCharacterInstanceId = self.Owner:GetServerInstanceId()
    local tbArmors = BattleItemSystemClient:GetEquippedItems(BattleItemCategoryDef.HUMAN_ARMOR, nCharacterInstanceId)
    if tbArmors then
        local tbArmor = tbArmors[1] 
        if tbArmor then  
            return tbArmor:GetGrade()
        end
    end
    return 1
end
return HumanConcealComponent_C