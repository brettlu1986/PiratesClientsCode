-----------------------------------------------------
--File Name    : BattleAddPlayerItemAction.lua
--Author       : 
--Create Time  : 
--Description  : 添加Player Item
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleAddPlayerItemAction = luaclass("BattleAddPlayerItemAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleItemSystemServer = require("BattleItemSystemServer")

BattleAddPlayerItemAction.nItemTemplateId = nil
BattleAddPlayerItemAction.nCount      = 0
BattleAddPlayerItemAction.szGetObjKey = nil
BattleAddPlayerItemAction.bAffectTeam = nil

function BattleAddPlayerItemAction:Parse(tbJsonData)
    self.nItemTemplateId = tbJsonData.ItemTemplateId
    self.nCount          = tbJsonData.Count
    self.szGetObjKey     = tbJsonData.GetObjKey
    self.bAffectTeam     = tbJsonData.AffectTeam or false

    return true
end

function BattleAddPlayerItemAction:Execute()

    BattleOperationHelper:PrintLog(self,
        ", nItemTemplateId: "..self.nItemTemplateId..
        ", nCount: "..self.nCount..
        ", GetObjKey: "..(self.szGetObjKey or "")..
        ", bAffectTeam: "..(self.bAffectTeam and "true" or "false"))

    if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then 
        local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbPlayer then
            if self.bAffectTeam then
                local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
                for _, curIterPlayer in ipairs(tbTeamMembers) do
                    if not curIterPlayer:IsDead() then
                        BattleItemSystemServer:AddItemByTemplate(curIterPlayer:GetServerInstanceId(),self.nItemTemplateId,self.nCount)
                    end
                end
            else
                BattleItemSystemServer:AddItemByTemplate(tbPlayer:GetServerInstanceId(),self.nItemTemplateId,self.nCount)
            end
        end
    end

    return true
end

return BattleAddPlayerItemAction

