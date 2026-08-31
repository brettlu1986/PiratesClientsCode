-----------------------------------------------------
--File Name    : BattleAddPlayerBuffAction.lua
--Author       : 
--Create Time  : 
--Description  : 添加playerbuff
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleAddPlayerBuffAction = luaclass("BattleAddPlayerBuffAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleBlackboard = require("BattleBlackboard")
local BattleTeamSystem = require("BattleTeamSystem")

BattleAddPlayerBuffAction.nBuffId = nil
BattleAddPlayerBuffAction.bRemoveBuff = nil
BattleAddPlayerBuffAction.szGetObjKey = nil
BattleAddPlayerBuffAction.nCampType = nil
BattleAddPlayerBuffAction.nOverlapCount = 0
BattleAddPlayerBuffAction.bAffectTeam = nil

function BattleAddPlayerBuffAction:Parse(tbJsonData)
    self.nBuffId = tbJsonData.BuffId
    self.bRemoveBuff = tbJsonData.RemoveBuff
    self.nCampType = tbJsonData.CampType
    self.szGetObjKey = tbJsonData.GetObjKey
    self.nOverlapCount = tbJsonData.OverlapCount
    self.bAffectTeam = tbJsonData.AffectTeam or false

    return self.nBuffId > 0
end

function BattleAddPlayerBuffAction:Execute()

    BattleOperationHelper:PrintLog(self,
        ", BuffId: "..self.nBuffId..
        ", OverlapCount: "..self.nOverlapCount..
        ", GetObjKey: "..(self.szGetObjKey or "")..
        ", RemoveBuff: "..(self.bRemoveBuff and "true" or "false"))

    if self.nOverlapCount < 1 then 
        self.nOverlapCount = 1
    end

    if not self.bRemoveBuff  then 
        if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then 
            local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
            if tbPlayer then
                if self.bAffectTeam then
                    local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
                    for _, curIterPlayer in ipairs(tbTeamMembers) do
                        if not curIterPlayer:IsDead() then
                            curIterPlayer.BuffComponentServer:AddBuffById(self.nBuffId, self.nOverlapCount)
                        end
                    end
                else
                    tbPlayer.BuffComponentServer:AddBuffById(self.nBuffId, self.nOverlapCount)
                end
            end
        elseif self.nCampType and self.nCampType > 0 then 
            local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
            for Object, _ in pairs(tbObjects) do
                if Object.BattleCampComponent and self.nCampType == Object.BattleCampComponent:GetCampType() then
                    Object.BuffComponentServer:AddBuffById(self.nBuffId, self.nOverlapCount)
                end
            end
        else
            local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
            for Object, _ in pairs(tbObjects) do
                Object.BuffComponentServer:AddBuffById(self.nBuffId, self.nOverlapCount)
            end
        end
    else
        if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then 
            local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
            if tbPlayer then
                if self.bAffectTeam then
                    local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
                    for _, curIterPlayer in ipairs(tbTeamMembers) do
                        if not curIterPlayer:IsDead() then
                            curIterPlayer.BuffComponentServer:RemoveBuffById(self.nBuffId)
                        end
                    end
                else
                    tbPlayer.BuffComponentServer:RemoveBuffById(self.nBuffId)
                end
            end
        elseif self.nCampType and self.nCampType > 0 then 
            local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
            for Object, _ in pairs(tbObjects) do
                if Object.BattleCampComponent and self.nCampType == Object.BattleCampComponent:GetCampType() then
                    Object.BuffComponentServer:RemoveBuffById(self.nBuffId)
                end
            end
        else
            local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
            for Object, _ in pairs(tbObjects) do
                Object.BuffComponentServer:RemoveBuffById(self.nBuffId)
            end
        end 
    end

    return true
end

return BattleAddPlayerBuffAction

