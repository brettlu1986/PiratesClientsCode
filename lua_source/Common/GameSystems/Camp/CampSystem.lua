-- 阵营系统，现在只是空架子
local CampDef = require("CampDefine")
local CampTypeRelationDataTable = require("CampTypeRelationDataTable")

local CampSystem = {}

function CampSystem:Init()
    
end

function CampSystem:Uninit()
    
end

-- 因为存在全敌对Camp，所以如果用这个借口需要判断是不是自己，自己和自己肯定是队友
function CampSystem:GetRelation(CampTypeA, CampTypeB)
    return CampTypeRelationDataTable:GetRelation(CampTypeA, CampTypeB)
end

function CampSystem:GetRelationByCharacter(CharacterA, CharacterB)
    if CharacterA == CharacterB then
        return CampDef.Relation.RELATION_FRIEND
    end
    local CampTypeA = CampDef.Type.CAMP_NONE
    local CampTypeB = CampDef.Type.CAMP_NONE
    if CharacterA and CharacterA.BattleCampComponent then
        CampTypeA = CharacterA.BattleCampComponent:GetCampType()
    end
    if CharacterB and CharacterB.BattleCampComponent then
        CampTypeB = CharacterB.BattleCampComponent:GetCampType()
    end
    return self:GetRelation(CampTypeA, CampTypeB)
end

function CampSystem:IsFriendRelation(CharacterA, CharacterB)
    local Relation = self:GetRelationByCharacter(CharacterA, CharacterB)
    return Relation == CampDef.Relation.RELATION_FRIEND
end

function CampSystem:IsEnemyRelation(CharacterA, CharacterB)
    local Relation = self:GetRelationByCharacter(CharacterA, CharacterB)
    return Relation == CampDef.Relation.RELATION_ENEMY
end


return CampSystem
