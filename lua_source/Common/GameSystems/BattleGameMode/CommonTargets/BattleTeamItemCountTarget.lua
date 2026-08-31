-- 存在队伍(包括单人模式)成员的某种Item数量和 大于等于 指定数量 就算完成目标

local luaclass = require("luaclass")
local BattleTargetBaseClass = require("BattleTargetBase")
local BattleTeamItemCountTarget = luaclass("BattleTeamItemCountTarget", BattleTargetBaseClass)

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleBlackboard = require("BattleBlackboard")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleOperationHelper = require("BattleOperationHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

BattleTeamItemCountTarget.nItemTemplateId = nil
BattleTeamItemCountTarget.nTargetCount    = nil
BattleTeamItemCountTarget.szOperator = nil
BattleTeamItemCountTarget.szSetObjKey     = nil

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

function BattleTeamItemCountTarget:Init()
    BattleTeamItemCountTarget.super.Init(self)
    self.szName = "BattleTeamItemCountTarget"
end

function BattleTeamItemCountTarget:Parse(tbJsonData)
    self.nItemTemplateId = tbJsonData.ItemTemplateId
    self.nTargetCount = tbJsonData.TargetCount
    self.szOperator = tbJsonData.Operator
    self.szSetObjKey  = tbJsonData.SetObjKey

    return true
end

local function CheckItemCountByTeamId(self, TeamId)
    local nTotalCount = 0
    local tbLastPlayer = nil

    local tbTeamMembers = BattleTeamSystem:GetTeamMembers(TeamId)
    for _, tbPlayer in ipairs(tbTeamMembers) do
        if not tbPlayer:IsDead() then
            local nInstanceId = tbPlayer:GetServerInstanceId()
            if nInstanceId then
                nTotalCount = nTotalCount + BattleItemSystemServer:GetItemCount(nInstanceId, self.nItemTemplateId)
                tbLastPlayer = tbPlayer
            end
        end
    end

    if BattleOperationHelper:CallOperator(self.szOperator, nTotalCount, self.nTargetCount) then
        if self.szSetObjKey and string.len(self.szSetObjKey) > 0 then
            BattleBlackboard:SetTable(self.szSetObjKey,tbLastPlayer)
        end

        return true
    end

    return false
end

--Return: true表示完成了条件，false表示条件不满足
function BattleTeamItemCountTarget:CheckAll(nTemplateId, tbPlayer)

    if not self.nItemTemplateId or
       not self.nTargetCount
       then
        return false
     end

    local nNeedCheckTeamId = -1

    if tbPlayer then
        if nTemplateId == self.nItemTemplateId then
            nNeedCheckTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
        else
            return false
        end
    end

    if nNeedCheckTeamId == -1 then
        --检查所有队伍的情况
        local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
        for nTeamId, tbTeam in pairs(tbAllTeamsInfo) do
            if CheckItemCountByTeamId(self, nTeamId) then
                return true
            end
        end
    else
        return CheckItemCountByTeamId(self, nNeedCheckTeamId)
    end

    return false
end

function BattleTeamItemCountTarget:RegisterEvent()
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, OnAddItem)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnRemoveItem)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER, self, OnItemStackCountChanged)

end

function BattleTeamItemCountTarget:UnregisterEvent()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, self, OnAddItem)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnRemoveItem)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER, self, OnItemStackCountChanged)
end

function BattleTeamItemCountTarget:Start()
    BattleTeamItemCountTarget.super.Start(self)

    if self:CheckAll(nil) then
        self:Complete()
    end
end

return BattleTeamItemCountTarget
