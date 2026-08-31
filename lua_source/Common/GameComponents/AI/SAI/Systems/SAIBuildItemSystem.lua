
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIBuildItemSystem = luaclass("SAIBuildItemSystem", SAISystemBase)
local SelfEventHelperClass = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local SAISystemDef = require("SAISystemDef")
local CheckCanBuildItemHelper   = require("CheckCanBuildItemHelper")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
local ShipWeaponSlotDef         = require("ShipWeaponSlotDef")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local BattleItemDataTable       = require("BattleItemDataTable")
local HumanArmorSlotDef         = require("HumanArmorSlotDef")
local HumanWeaponSlotDef        = require("HumanWeaponSlotDef")

SAIBuildItemSystem.pAIController = nil
SAIBuildItemSystem.SelfEventHelper = nil
SAIBuildItemSystem.tbGoalSystem = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIBuildItemSystem:", ...)
end
-- luacheck: pop

local tbShipWeaponPriority = {
    [1] = ShipWeaponSlotDef.SIDE,
    [2] = ShipWeaponSlotDef.DECK,
    [3] = ShipWeaponSlotDef.HEAD,
}

local function GetCanBuildShipItemTemplateIds(nCharacterInstanceId, bClient)
    return CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, bClient)
end

local function GetCanBuildShipPartItemTemplateIds(nCharacterInstanceId, bClient)
    return CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIds(nCharacterInstanceId, bClient)
end

local function GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotId, bClient)
    return CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotId, bClient)
end

local function GetCanBuildHumanWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return CheckCanBuildItemHelper.GetCanBuildHumanWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
end

local function GetCanBuildHumanArmorItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return CheckCanBuildItemHelper.GetCanBuildHumanArmorItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
end


local function OnItemChanged(self)
    if GlobalVariableSystem:IsServerLogic() then
        local fncCanBuildShipItemTemplateIds = self.fncCanBuildShipItemTemplateIds
        local fncCanBuildShipPartItemTemplateIds = self.fncCanBuildShipPartItemTemplateIds
        local fncCanBuildShipWeaponItemTemplateIdsOnSlot = self.fncCanBuildShipWeaponItemTemplateIdsOnSlot
        local fncCanBuildHumanWeaponItemTemplateIdsOnSlot = self.fncCanBuildHumanWeaponItemTemplateIdsOnSlot
        local fncCanBuildHumanArmorItemTemplateIdsOnSlot = self.fncCanBuildHumanArmorItemTemplateIdsOnSlot
        local bIsBuilding = self.tbGoalSystem:IsBuilding()
        if bIsBuilding then
            return
        end
        local nCharacterInstanceId = self.tbOwner.nServerInstanceId
        local nNextBuildLevel = CheckCanBuildItemHelper.GetNextCanBuildShipGrade(nCharacterInstanceId, false)
        local tbShipTemplates = fncCanBuildShipItemTemplateIds(nCharacterInstanceId, false)
        if #tbShipTemplates > 0 then
            local nIndex = math.random(1,#tbShipTemplates)
            self:StartBuildItem(tbShipTemplates[nIndex])
            LOG("start build ship ", tbShipTemplates[nIndex])
            return
        end
        if nNextBuildLevel > 1 then
            if self.bCanBuildShipPart then
                local tbShipPartTemplates = fncCanBuildShipPartItemTemplateIds(nCharacterInstanceId, false)
                if #tbShipPartTemplates > 0 then
                    local nIndex = math.random(1,#tbShipPartTemplates)
                    self:StartBuildItem(tbShipPartTemplates[nIndex])
                    LOG("start build ship part ", tbShipPartTemplates[nIndex])
                    return
                end
            end
            if self.bCanBuildShipWeapon then
                for i,v in ipairs(tbShipWeaponPriority) do
                    local tbWeapon = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON,
                        nCharacterInstanceId, v)
                    if not tbWeapon then
                        local tbShipWeaponTemplates = fncCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, v, false)
                        if #tbShipWeaponTemplates > 0 then
                            local nIndex = math.random(1,#tbShipWeaponTemplates)
                            self:StartBuildItem(tbShipWeaponTemplates[nIndex])
                            LOG("start build ship weapon ", tbShipWeaponTemplates[nIndex])
                            return
                        end
                    end
                end
            end
            if self.bCanBuildHumanWeapon then
                for i=1, HumanWeaponSlotDef:SlotCount() do
                    local tbHumanWeaponTemplates = fncCanBuildHumanWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, i, false)
                    if #tbHumanWeaponTemplates > 0 then
                        local nIndex = math.random(1,#tbHumanWeaponTemplates)
                        self:StartBuildItem(tbHumanWeaponTemplates[nIndex])
                        LOG("start build human weapon ", tbHumanWeaponTemplates[nIndex])
                        return
                    end
                end
            end
            if self.bCanBuildHumanArmor then
                for i=1, HumanArmorSlotDef:SlotCount() do
                    local tbHumanArmorTemplates = fncCanBuildHumanArmorItemTemplateIdsOnSlot(nCharacterInstanceId, i, false)
                    if #tbHumanArmorTemplates > 0 then
                        local nIndex = math.random(1,#tbHumanArmorTemplates)
                        self:StartBuildItem(tbHumanArmorTemplates[nIndex])
                        LOG("start build human armor ", tbHumanArmorTemplates[nIndex])
                        return
                    end
                end
            end
        end
        self:StartBuildItem(0)
    end
end

local function IsMaterialItem(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbTemplate then
        if tbTemplate.nCategory == BattleItemCategoryDef.MATERIAL then
            return true
        end
        if tbTemplate.nCategory == BattleItemCategoryDef.BUILD_KEY_ITEM then
            return true
        end
    end
    return false
end

local function OnItemRemove(self, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    if nCharacterInstanceId == self.tbOwner.nServerInstanceId and GlobalVariableSystem:IsServerLogic() and
    IsMaterialItem(nItemTemplateId) then
        OnItemChanged(self)
    end
end

local function OnItemAdd(self, tbItem)
    if tbItem.tbOwnerCharacter == self.tbOwner and GlobalVariableSystem:IsServerLogic() and
    IsMaterialItem(tbItem:GetTemplateId()) then
        OnItemChanged(self)
    end
end

local function OnItemStack(self, tbItem)
    if tbItem.tbOwnerCharacter == self.tbOwner and GlobalVariableSystem:IsServerLogic() and
    IsMaterialItem(tbItem:GetTemplateId()) then
        OnItemChanged(self)
    end
end

local function OnBuildOK(self, tbPlayer, nItemInstanceId, nItemTemplateId)
    if tbPlayer == self.tbOwner and GlobalVariableSystem:IsServerLogic() then
        self.tbGoalSystem:FinishBuild()
        OnItemChanged(self)
        LOG("build ok")
    end
end

local function OnBuildCancel(self, nCharacterInstanceId)
    if nCharacterInstanceId == self.tbOwner.nServerInstanceId and GlobalVariableSystem:IsServerLogic() then
        self.tbGoalSystem:FinishBuild()
        OnItemChanged(self)
        LOG("build cancel")
    end
end

function SAIBuildItemSystem:OnConfig(tbConfig)
    local tbBuildConfig = tbConfig.Build
    self.bEnabled = (tbBuildConfig ~= nil)
    if self.bEnabled then
        self.tbConfig = tbBuildConfig
        self.bCanBuildShipPart = tbBuildConfig.bCanBuildShipPart
        self.bCanBuildShipWeapon = tbBuildConfig.bCanBuildShipWeapon
        self.bCanBuildHumanWeapon = tbBuildConfig.bCanBuildHumanWeapon
        self.bCanBuildHumanArmor = tbBuildConfig.bCanBuildHumanArmor
        LOG("build list:", self.bCanBuildShipPart , self.bCanBuildShipWeapon, self.bCanBuildHumanWeapon, self.bCanBuildHumanArmor)
        self.fncCanBuildShipItemTemplateIds = tbBuildConfig.fncCanBuildShipItemTemplateIds or GetCanBuildShipItemTemplateIds
        self.fncCanBuildShipPartItemTemplateIds = tbBuildConfig.fncCanBuildShipPartItemTemplateIds or GetCanBuildShipPartItemTemplateIds
        self.fncCanBuildShipWeaponItemTemplateIdsOnSlot = tbBuildConfig.fncCanBuildShipWeaponItemTemplateIdsOnSlot or GetCanBuildShipWeaponItemTemplateIdsOnSlot
        self.fncCanBuildHumanWeaponItemTemplateIdsOnSlot = tbBuildConfig.fncCanBuildHumanWeaponItemTemplateIdsOnSlot or GetCanBuildHumanWeaponItemTemplateIdsOnSlot
        self.fncCanBuildHumanArmorItemTemplateIdsOnSlot = tbBuildConfig.fncCanBuildHumanArmorItemTemplateIdsOnSlot or GetCanBuildHumanArmorItemTemplateIdsOnSlot
    end
end


function SAIBuildItemSystem:OnStart()
    local tbOwner = self.tbOwner
    local AIComponent = tbOwner.SAIComponent
    local pAIController = AIComponent:GetAIController()
    self.pAIController = pAIController
    self.tbGoalSystem  = AIComponent:GetSystem(SAISystemDef.Goal)
    local SelfEventHelper = SelfEventHelperClass()
    self.SelfEventHelper = SelfEventHelper
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER,                self, OnItemAdd)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER,             self, OnItemRemove)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER,  self, OnItemStack)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_BUILD_FINISH_SERVER,       self, OnBuildOK)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_BUILD_CANCEL_SERVER,       self, OnBuildCancel)

end

function SAIBuildItemSystem:StartBuildItem(nTemplateId)
    self.tbGoalSystem:BuildItem(nTemplateId)
end


function SAIBuildItemSystem:OnStop()

    self.SelfEventHelper:UnregisterAll()
    self.tbGoalSystem:FinishBuild()
    self.pAIController = nil
    self.pBlackboard = nil
    self.tbGoalSystem = nil
end

function SAIBuildItemSystem:OnUninit()

end



return SAIBuildItemSystem
