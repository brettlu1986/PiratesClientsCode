
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleTeamSystem  = require("BattleTeamSystem")
local RelationshipDef   = require("RelationshipDef")

local RelationshipSystem = {}

function RelationshipSystem:Init()

end

function RelationshipSystem:Uninit()

end

local function GetPlayerOwner(Character)
    if GameObjectTypeDef.PlayerSelf == Character.ObjectType then
        return Character
    end
    return nil
end

function RelationshipSystem:GetRelationByCharacter(CharacterA, CharacterB)
    if CharacterA == CharacterB then
        return RelationshipDef.RELATION_FRIEND
    end
    local PlayerA = GetPlayerOwner(CharacterA)
    local PlayerB = GetPlayerOwner(CharacterB)
    if PlayerA and PlayerB then
        assert(GameObjectTypeDef.PlayerSelf == PlayerA.ObjectType and
        GameObjectTypeDef.PlayerSelf == PlayerB.ObjectType)
        return BattleTeamSystem:CheckTeammate(PlayerA, PlayerB) and RelationshipDef.RELATION_FRIEND or
        RelationshipDef.RELATION_ENEMY
    end
    return RelationshipDef.RELATION_ENEMY
end

function RelationshipSystem:IsFriendRelation(CharacterA, CharacterB)
    local Relation = self:GetRelationByCharacter(CharacterA, CharacterB)
    return Relation == RelationshipDef.RELATION_FRIEND
end

function RelationshipSystem:IsEnemyRelation(CharacterA, CharacterB)
    local Relation = self:GetRelationByCharacter(CharacterA, CharacterB)
    return Relation == RelationshipDef.RELATION_ENEMY
end


return RelationshipSystem
