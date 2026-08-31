-- 队伍某项物品产生改变时完成

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTeamItemChangeTarget = luaclass("BattleTeamItemChangeTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleBlackboard = require("BattleBlackboard")
local BattleItemSystemServer = require("BattleItemSystemServer")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleTeamItemChangeTarget.nItemTemplateId = nil
BattleTeamItemChangeTarget.szSetCountKey   = nil
BattleTeamItemChangeTarget.szSetObjKey     = nil

local function OnAddItem(self, tbItem)
    if self:CheckAll(tbItem:GetTemplateId(),tbItem:GetOwnerCharacter()) then
        self:Complete()
    end
end

local function OnRemoveItem(self, nItemInstanceId, nItemTemplateId, nCharacterId, _nRoomType, _nOwnerInstanceId, _nSlotIndex)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterId)    
    if self:CheckAll(nItemTemplateId,tbPlayer) then
        self:Complete()
    end
end

local function OnItemStackCountChanged(self, tbItem)
    if self:CheckAll(tbItem:GetTemplateId(),tbItem:GetOwnerCharacter()) then
        self:Complete()
    end
end

function BattleTeamItemChangeTarget:Init()
    BattleTeamItemChangeTarget.super.Init(self)
    self.szName = "BattleTeamItemChangeTarget"    
end

function BattleTeamItemChangeTarget:Parse(tbJsonData)
    self.nItemTemplateId = tbJsonData.ItemTemplateId
    self.szSetCountKey  = tbJsonData.SetCountKey
    self.szSetObjKey  = tbJsonData.SetObjKey

    return true
end

local function CheckItemCountByTeamId(self,TeamId,tbItemPlayer)
    local nTotalCount = 0

    local tbTeamMembers = BattleTeamSystem:GetTeamMembers(TeamId)
    for _, tbPlayer in ipairs(tbTeamMembers) do
        if not tbPlayer:IsDead() then
            local nInstanceId = tbPlayer:GetServerInstanceId()
            if nInstanceId then
                nTotalCount = nTotalCount + BattleItemSystemServer:GetUnequippedItemCount(nInstanceId,self.nItemTemplateId)
            end
        end
    end

    if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then
        BattleBlackboard:SetTable(self.szSetObjKey,tbItemPlayer)
    end
    
    if self.szSetCountKey and string.len(self.szSetCountKey) > 0 then
        BattleBlackboard:SetNumber(self.szSetCountKey,nTotalCount)
    end

    return true
end

function BattleTeamItemChangeTarget:CheckAll(nTemplateId,tbPlayer)

    if not self.nItemTemplateId then
        return false
     end

    local nNeedCheckTeamId = -1

    if tbPlayer then
        if nTemplateId == self.nItemTemplateId then
            nNeedCheckTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
        else
            return false
        end

        return CheckItemCountByTeamId(self,nNeedCheckTeamId,tbPlayer)
    end

    return false
end

function BattleTeamItemChangeTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, OnAddItem)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnRemoveItem)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER, self, OnItemStackCountChanged)

end

function BattleTeamItemChangeTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, OnAddItem)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnRemoveItem)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER, self, OnItemStackCountChanged)
end

function BattleTeamItemChangeTarget:Start()
    BattleTeamItemChangeTarget.super.Start(self)
end

return BattleTeamItemChangeTarget
