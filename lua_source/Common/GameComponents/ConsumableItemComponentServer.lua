local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local ConsumableItemComponentServer = luaclass("ConsumableItemComponentServer", GameComponentBaseClass)

local PropName = require("PropName")
local Proto = require("DungeonCommonProtoNames")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local PropUtil = require("PropUtil")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelperClass = require("SelfEventHelper")
local NetworkManager = dynamic_require("NetworkManager")
local ConsumableItemDef = require("ConsumableItemDef")
local EventManager = require("EventManager")

ConsumableItemComponentServer.EventHelper = nil
ConsumableItemComponentServer.nConsumableItemInstanceId = nil
ConsumableItemComponentServer.tbConsumableBuffInfos = nil
ConsumableItemComponentServer.tbBuffRemoveDelegate = nil

local function SendToClient(self, szMessageType, tbMessageBody)
    local RPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
    RPCNetworkProxy:SendToClient(self.Owner:GetUEControllerUniqueId(), szMessageType, tbMessageBody)
end

local function Reset(self)
    self.nConsumableItemInstanceId = nil
    self.EventHelper:UnregisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER)
end

local function CheckPlayerAlive(self)
    local tbCharacter = self.Owner
    if tbCharacter and tbCharacter:IsDead() then
        return false
    end
    return true
end

local function CheckPlayerDying(self)
    local tbCharacter = self.Owner
    if tbCharacter then
        return tbCharacter:IsDying()
    end
    return false
end

local function CheckHpLimit(self, tbItem)
    local tbCharacter = self.Owner
    local tbTemplate = tbItem:GetTemplate()
    local nPercentageCap = tbTemplate.nHpLimit
    if nPercentageCap == nil then
        return true
    end
    if PropUtil.GetHpPercent(tbCharacter) * 100 >= nPercentageCap then
        return false
    end
    return true
end

-- local function CheckCrawlLimit(self)
--     local Owner = self.Owner
--     if Owner:IsHuman() then
--         local HumanMovementStateComponent = Owner.HumanMovementStateComponent
--         if HumanMovementStateComponent
--         and HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Crawl_State then
--             local CharacterMovement = Owner.pUEActor.CharacterMovement
--             if CharacterMovement and CharacterMovement.IsHumanMoving
--             and CharacterMovement:IsHumanMoving() then
--                 return false
--             end
--         end
--     end
--     return true
-- end

local function CheckTargetType(self, tbItem)
    local tbTemplate = tbItem:GetTemplate()
    local TargetTypeDef = ConsumableItemDef.ValidTargetType
    if tbTemplate.nValidTargetType == TargetTypeDef.SHIP and self.Owner:IsHuman() then
        return false
    end
    if tbTemplate.nValidTargetType == TargetTypeDef.HUMAN and self.Owner:IsShip() then
        return false
    end
    return true
end

local function AbortProgressBar(self)
    local ProgressBarComponent = self.Owner.ProgressBarComponent
    if ProgressBarComponent then
        ProgressBarComponent:Abort()
    else
        logwarning("ConsumableItemComponentServer interrupt failed. ProgressBarComponent not found. nPlayerId:", self.Owner:GetPlayerId())
    end
end

local function OnCharacterBuffRemoved(self, nBuffTemplateId, nBuffInstanceId)
    log("[ConsumableItemComponentServer] OnCharacterBuffRemoved", nBuffTemplateId, nBuffInstanceId)
    for i, tbConsumableBuffInfo in ipairs(self.tbConsumableBuffInfos) do
        local tbBuffInstances = tbConsumableBuffInfo.tbBuffInstances
        for ii, tbBuffInfo in ipairs(tbBuffInstances) do
            if (nBuffTemplateId == tbBuffInfo.nBuffTemplateId)
            and (nBuffInstanceId == tbBuffInfo.nBuffInstanceId) then
                table.remove(tbBuffInstances, ii)
                break
            end
        end
        if #tbBuffInstances <= 0 then
            local d2c_ConsumeItemEnd = {
                instance_id = tbConsumableBuffInfo.nConsumableItemInstanceId
            }
            SendToClient(self, Proto.d2c_ConsumeItemEnd, d2c_ConsumeItemEnd)
            table.remove(self.tbConsumableBuffInfos, i)
            break
        end
    end

    if #self.tbConsumableBuffInfos <= 0 then
        local BuffComponentServer = self.Owner.BuffComponentServer
        if BuffComponentServer and self.tbBuffRemoveDelegate then
            self.EventHelper:UnregisterLuaDelegate(BuffComponentServer.OnBuffRemoveDelegate, OnCharacterBuffRemoved, self)
            self.tbBuffRemoveDelegate = nil
        end
    end
end

local function AddBuffToCharacter(self, nConsumableItemInstanceId, tbConsumedItem)
    log("[ConsumableItemComponentServer] AddBuffToCharacter", nConsumableItemInstanceId, tbConsumedItem)
    local BuffComponentServer = self.Owner.BuffComponentServer
    if BuffComponentServer then
        local tbTemplate = tbConsumedItem:GetTemplate()
        local tbBuffs = self.Owner:IsShip() and tbTemplate.tbShipBuffs or tbTemplate.tbHumanBuffs
        local tbBuffInstances = {}
        for _, nBuffTemplateId in ipairs(tbBuffs) do
            log("[ConsumableItemComponentServer] AddBuffWithInstigator", nBuffTemplateId)
            local nBuffInstanceId = BuffComponentServer:AddBuffWithInstigator(self.Owner, nBuffTemplateId, 1)
            table.insert(tbBuffInstances, {
                nBuffTemplateId = nBuffTemplateId,
                nBuffInstanceId = nBuffInstanceId
            })
        end
        if #tbBuffInstances > 0 then
            local tbConsumableBuffInfo = {}
            tbConsumableBuffInfo.nConsumableItemInstanceId = nConsumableItemInstanceId
            tbConsumableBuffInfo.tbBuffInstances = tbBuffInstances
            table.insert(self.tbConsumableBuffInfos, tbConsumableBuffInfo)

            -- 移除已经结束的Buff
            for i = #tbBuffInstances, 1, -1 do
                local tbBuffInfo = tbBuffInstances[i]
                if not BuffComponentServer:IsExistBuffByInstanceId(tbBuffInfo.nBuffTemplateId, tbBuffInfo.nBuffInstanceId) then
                    OnCharacterBuffRemoved(self, tbBuffInfo.nBuffTemplateId, tbBuffInfo.nBuffInstanceId)
                end
            end

            if not self.tbBuffRemoveDelegate then
                self.tbBuffRemoveDelegate = self.EventHelper:RegisterLuaDelegate(BuffComponentServer.OnBuffRemoveDelegate, OnCharacterBuffRemoved, self)
            end
        end
    end
end

------------------------------------------------------------------------------
-- 检测打断逻辑 开始
------------------------------------------------------------------------------

local function OnBattleItemRemove(self, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    local tbItem = BattleItemSystemHelper:GetItem(nItemInstanceId, false)
    if tbItem and nCharacterInstanceId == self.Owner:GetServerInstanceId()
    and nItemInstanceId == self.nConsumableItemInstanceId then
        AbortProgressBar(self)
    end
end

local function RegisterInterruptEvent(self)
    self.EventHelper:UnregisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, self, OnBattleItemRemove)
end

---------------------------------------------------------------------------------------
-- 检测打断逻辑 结束
----------------------------------------------------------------------------------------

function ConsumableItemComponentServer:OnCreate(Owner, tbParams)
    ConsumableItemComponentServer.super.OnCreate(self, Owner, tbParams)
    self.tbConsumableBuffInfos = {}
    self.EventHelper = SelfEventHelperClass()
    return true
end

function ConsumableItemComponentServer:OnDestroy()
    if self.EventHelper then
        self.EventHelper:UnregisterAll()
    end
    self.tbBuffRemoveDelegate = nil
end

function ConsumableItemComponentServer:ConsumeItemRequest(nItemInstanceId)
    local d2c_ConsumeItemStart = {}
    local ReturnCodeType = Proto.d2c_ConsumeItemStart_ReturnCode
    local tbItem = BattleItemSystemHelper:GetItem(nItemInstanceId, false)
    if self.nConsumableItemInstanceId == nItemInstanceId then
        log("ConsumableItemComponentServer:ConsumeItemRequest Use the same consumable. Do nothing. nPlayerId:", self.Owner:GetPlayerId(), ". nItemInstanceId:", nItemInstanceId)
        return
    end

    d2c_ConsumeItemStart.instance_id = nItemInstanceId

    if not tbItem then
        d2c_ConsumeItemStart.code = ReturnCodeType.NO_ITEM_FOUND
    elseif not CheckPlayerAlive(self) then
        d2c_ConsumeItemStart.code = ReturnCodeType.PLAYER_DIED
    elseif CheckPlayerDying(self) then
        d2c_ConsumeItemStart.code = ReturnCodeType.PLAYER_IN_DYING
    elseif tbItem:GetCategory() ~= BattleItemCategoryDef.HUMAN_CONSUMABLE then
        d2c_ConsumeItemStart.code = ReturnCodeType.ITEM_NOT_CONSUMABLE
    elseif not CheckHpLimit(self, tbItem) then
        d2c_ConsumeItemStart.code = ReturnCodeType.HP_LIMIT
        d2c_ConsumeItemStart.hp_percentage_cap = tbItem:GetTemplate().nHpLimit
    -- elseif not CheckCrawlLimit(self) then
    --     d2c_ConsumeItemStart.code = ReturnCodeType.CRAWL_CAN_NOT_USE
    elseif not CheckTargetType(self, tbItem) then
        if self.Owner:IsHuman() then
            d2c_ConsumeItemStart.code = ReturnCodeType.HUMAN_CAN_NOT_USE
        else
            d2c_ConsumeItemStart.code = ReturnCodeType.SHIP_CAN_NOT_USE
        end
    elseif tbItem:GetOwnerCharacter() ~= self.Owner then
        d2c_ConsumeItemStart.code = ReturnCodeType.NOT_OWNER
    else
        d2c_ConsumeItemStart.code = ReturnCodeType.OK
    end

    if d2c_ConsumeItemStart.code ~= ReturnCodeType.OK then
        SendToClient(self, Proto.d2c_ConsumeItemStart, d2c_ConsumeItemStart)
        return
    end

    if self.nConsumableItemInstanceId then
        AbortProgressBar(self)
    end

    local OnConsumeSuccess = function()
        local nConsumableItemInstanceId = self.nConsumableItemInstanceId
        assert(nConsumableItemInstanceId)
        Reset(self)
        local d2c_ConsumeItemSuccess = {
            instance_id = nConsumableItemInstanceId
        }
        SendToClient(self, Proto.d2c_ConsumeItemSuccess, d2c_ConsumeItemSuccess)

        local tbConsumedItem = BattleItemSystemHelper:GetItem(nConsumableItemInstanceId, false)
        if tbConsumedItem and tbConsumedItem:GetOwnerCharacter() == self.Owner
            and tbConsumedItem:GetCategory() == BattleItemCategoryDef.HUMAN_CONSUMABLE then
                AddBuffToCharacter(self, nConsumableItemInstanceId, tbConsumedItem)

                local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
                local nOwnerServerInstanceId = self.Owner:GetServerInstanceId()
                local nItemTemplateId = tbConsumedItem:GetTemplateId()
                BattleItemSystemServer:DecreasePlayerItemCount(nOwnerServerInstanceId, nConsumableItemInstanceId, 1)
                EventManager:OnFireEvent(CommonEventDef.EV_CONSUMABLE_ITEM_CONSUME_SUCCESS, self.Owner, nItemTemplateId, 1)
        else
            logwarning("Consumable item invaild. nConsumableItemInstanceId:", nConsumableItemInstanceId, "; nPlayerId:", self.Owner:GetPlayerId())
        end
    end

    local OnConsumeInterrupt = function()
        self:ConsumeItemInterrupt()
    end

    local ProgressBarComponent = self.Owner.ProgressBarComponent
    if ProgressBarComponent then
        local tbTemplate = tbItem:GetTemplate()
        local nProgressBar = self.Owner:IsShip() and tbTemplate.nShipProgressBar or tbTemplate.nHumanProgressBar
        local PropertyComponent = self.Owner:GetCurrentPropertyComponent()
        local nItemUsingTimePropId = self.Owner:IsShip() and PropName.nShipItemUsingTime or PropName.nHumanItemUsingTime
        local nOriginTime = ProgressBarComponent:GetTime(nProgressBar)
        local nNewTime = PropertyComponent:CalcPropOverlapValue(nItemUsingTimePropId, nOriginTime)
        if ProgressBarComponent:Start(nProgressBar, {}, OnConsumeSuccess, OnConsumeInterrupt, nNewTime) then
            self.nConsumableItemInstanceId = nItemInstanceId
            SendToClient(self, Proto.d2c_ConsumeItemStart, d2c_ConsumeItemStart)
            RegisterInterruptEvent(self)
        else
            log("ConsumableItemComponentServer:ConsumeItemRequest ProgressBarComponent:Start failed. nPlayerId:", self.Owner:GetPlayerId())
        end
    else
        logwarning("ConsumableItemComponentServer:ConsumeItemRequest failed. No ProgressBarComponent. nPlayerId:", self.Owner:GetPlayerId())
    end
end

function ConsumableItemComponentServer:ConsumeItemInterrupt()
    local d2c_ConsumeItemInterrupt =
    {
        instance_id = self.nConsumableItemInstanceId
    }
    SendToClient(self, Proto.d2c_ConsumeItemInterrupt, d2c_ConsumeItemInterrupt)
    Reset(self)
end

function ConsumableItemComponentServer:OnActorDestroyed(pUEActor)
    Reset(self)
    ConsumableItemComponentServer.super.OnActorDestroyed(self, pUEActor)
end

function ConsumableItemComponentServer:OnDestroy()
    Reset(self)
    ConsumableItemComponentServer.super.OnDestroy(self)
end

return ConsumableItemComponentServer
