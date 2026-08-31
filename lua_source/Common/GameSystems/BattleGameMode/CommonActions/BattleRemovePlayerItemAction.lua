-----------------------------------------------------
--File Name    : BattleRemovePlayerItemAction.lua
--Author       : 
--Create Time  : 
--Description  : 移除Player Item
-----------------------------------------------------

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleRemovePlayerItemAction = luaclass("BattleRemovePlayerItemAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleItemSystemServer = require("BattleItemSystemServer")

BattleRemovePlayerItemAction.nItemTemplateId = nil
BattleRemovePlayerItemAction.bRemoveAll  = nil
BattleRemovePlayerItemAction.nCount      = 0
BattleRemovePlayerItemAction.szGetObjKey = nil
BattleRemovePlayerItemAction.bAffectTeam = nil

function BattleRemovePlayerItemAction:Parse(tbJsonData)
    self.nItemTemplateId = tbJsonData.ItemTemplateId
    self.bRemoveAll      = tbJsonData.RemoveAll or false
    self.nCount          = tbJsonData.Count
    self.szGetObjKey     = tbJsonData.GetObjKey
    self.bAffectTeam     = tbJsonData.AffectTeam or false

    return true
end

function BattleRemovePlayerItemAction:Execute()

    BattleOperationHelper:PrintLog(self,
        ", nItemTemplateId: "..self.nItemTemplateId..
        ", nCount: "..self.nCount..
        ", GetObjKey: "..(self.szGetObjKey or "")..
        ", bRemoveAll: "..(self.bRemoveAll and "true" or "false")..
        ", bAffectTeam: "..(self.bAffectTeam and "true" or "false"))

    local nCount = self.nCount
    if self.bRemoveAll then
        nCount = nil
    end

    if self.szGetObjKey and string.len(self.szGetObjKey) > 0 then 
        local tbPlayer = BattleBlackboard:GetTable(self.szGetObjKey)
        if tbPlayer then
            if self.bAffectTeam then
                local tbTeamMembers = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
                for _, curIterPlayer in ipairs(tbTeamMembers) do
                    if not curIterPlayer:IsDead() then
                        BattleItemSystemServer:DestroyUnequippedItemsByTemplate(curIterPlayer:GetServerInstanceId(),self.nItemTemplateId,nCount)
                    end
                end
            else
                BattleItemSystemServer:DestroyUnequippedItemsByTemplate(tbPlayer:GetServerInstanceId(),self.nItemTemplateId,nCount)
            end
        end
    end

    return true
end

return BattleRemovePlayerItemAction

