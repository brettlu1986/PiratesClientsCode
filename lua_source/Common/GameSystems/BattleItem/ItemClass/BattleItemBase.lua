-----------------------------------------------------
--File Name    : BattleItemBase.lua
--Author       : zhiyuan
--Create Time  : 2018-08-21
--Description  : 战斗物品的基类
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemBase = luaclass("BattleItemBase")

local BattleItemDataTable = require("BattleItemDataTable")
local FFAItemIni = require("FFAItemIni")

BattleItemBase.tbOwnerCharacter = nil -- 物品的拥有者character
BattleItemBase.nLastOwnerCharacterInstanceId = 0 -- 上一个物品的拥有者character的nServerInstanceId
BattleItemBase.nInstanceId = -1
BattleItemBase.tbTemplate = nil
BattleItemBase.nStackCount = 1
BattleItemBase.tbSceneActor = nil -- 场景中的GameObject
BattleItemBase.tbStorageLocation = nil -- 物品的存储位置
BattleItemBase.bOnServer = false -- 是否为Server上的Item实例

-- 这个字段客户端没有做同步，以后有需求再同步
BattleItemBase.bOnceOwned = nil -- 曾经有拥有者，false表示从来没被拾取过，true表示曾经被拾取过

BattleItemBase.tbDebugInfo = nil -- debug用数据


local function RandomOffSet(offSetMin, offSetMax)
    return (offSetMin + math.random() * (offSetMax - offSetMin)) * (math.random() > 0.5 and 1 or -1)
end

local function CheckStackCount(tbTemplate, nStackCount)
    if nStackCount == nil or nStackCount <= 0 then
        nStackCount = 1
    end
    local nStackLimit = tbTemplate.nStackLimit
    if nStackLimit == nil or nStackLimit < 1 then
        nStackLimit = 1
    end
    if nStackCount > nStackLimit then
        --logerror("CheckStackCount error!nStackCount > nStackLimit", nStackCount, nStackLimit)
        nStackCount = nStackLimit
    end
    return nStackCount
end

function BattleItemBase:Init(nInstanceId, tbTemplate, nStackCount, bOnServer)
    self.nInstanceId = nInstanceId
    self:SetTemplate(tbTemplate)
    nStackCount = CheckStackCount(tbTemplate, nStackCount)
    self:SetStackCount(nStackCount)
    self:OnCreate()
    self.tbDebugInfo.nInstanceId = nInstanceId
    self.bOnServer = bOnServer == true
end

function BattleItemBase:OnCreate()
end

function BattleItemBase:OnDestroy()
end

function BattleItemBase:PreRemoveFromPlayer(bRemoveAll)
end

function BattleItemBase:GetOwnerUEControllerUniqueId()
    return self.tbOwnerCharacter:GetUEControllerUniqueId()
end

function BattleItemBase:SetOwnerCharacter(tbOwnerCharacter)
    self.tbOwnerCharacter = tbOwnerCharacter
end

function BattleItemBase:GetOwnerCharacter()
    return self.tbOwnerCharacter
end

function BattleItemBase:HasOwnerCharacter()
    return self.tbOwnerCharacter ~= nil
end

function BattleItemBase:GetOwnerCharacterInstanceId()
    return self.tbOwnerCharacter and self.tbOwnerCharacter:GetServerInstanceId() or -1
end

function BattleItemBase:GetInstanceId()
    return self.nInstanceId
end

function BattleItemBase:GetTemplate()
    return self.tbTemplate
end

function BattleItemBase:SetTemplate(tbTemplate)
    self.tbTemplate = tbTemplate
    if self.tbDebugInfo == nil then
        self.tbDebugInfo = {}
    end
    local tbDebugInfo = self.tbDebugInfo
    tbDebugInfo.nTemplateId = tbTemplate.nId
end

function BattleItemBase:GetTemplateId()
    return self.tbTemplate.nId
end

function BattleItemBase:GetCategory()
    if self.tbTemplate == nil then
        local tbDebugInfo = self.tbDebugInfo
        error("Template is nil!".. tbDebugInfo.nInstanceId..","..tbDebugInfo.nTemplateId..","..self:GetOwnerCharacterInstanceId())
    end
    return self.tbTemplate.nCategory
end

function BattleItemBase:GetSubCategory()
    return self.tbTemplate.nSubCategory
end

function BattleItemBase:GetCategoryAfterAddToCharacter()
    return self:GetCategory()
end

function BattleItemBase:GetTemplateIdAfterAddToCharacter()
    return self:GetTemplateId()
end

function BattleItemBase:GetGrade()
    return self.tbTemplate.nGrade
end

function BattleItemBase:IsStackable()
    return self.tbTemplate.bStackable
end

function BattleItemBase:SetStackCount(nStackCount)
    self.nStackCount = nStackCount
end

function BattleItemBase:GetStackCount()
    return self.nStackCount
end

function BattleItemBase:SetLastOwnerCharacterInstanceId(nLastOwnerCharacterInstanceId)
    self.nLastOwnerCharacterInstanceId = nLastOwnerCharacterInstanceId
end

function BattleItemBase:GetLastOwnerCharacterInstanceId()
    return self.nLastOwnerCharacterInstanceId
end

-- 是否未被人拾取过, 服务器方法
function BattleItemBase:IsInitialItem()
    return not self.bOnceOwned
end

-- 是否为Server端实例
function BattleItemBase:IsServerInstance()
    return self.bOnServer
end

-- 设置为被拾取过, 服务器方法
function BattleItemBase:SetOnceOwned()
    self.bOnceOwned = true
end

function BattleItemBase:AddStackCount(nDelta)
    assert(nDelta > 0, "AddStackCount nDelta <= 0 !!!!")
    self.nStackCount = self.nStackCount + nDelta
end

function BattleItemBase:DecreaseStackCount(nDelta)
    assert(nDelta > 0, "DecreaseStackCount nDelta <= 0 !!!!")
    self.nStackCount = self.nStackCount - nDelta
    assert(self.nStackCount > 0, "nStackCount <= 0 !!!!")
end

function BattleItemBase:GetWeight()
    local nWeight = self.tbTemplate.nWeight
    return nWeight * self:GetStackCount()
end

function BattleItemBase:GetStorageLocation()
    return self.tbStorageLocation
end

function BattleItemBase:SplitAndGetStorageLocation()
    return self.tbStorageLocation.nRoomType, self.tbStorageLocation.nOwnerInstanceId, self.tbStorageLocation.nSlotIndex
end

function BattleItemBase:SetStorageLocation(nRoomType, nOwnerInstanceId, nSlotIndex)
    self.tbStorageLocation = {}
    self.tbStorageLocation.nRoomType = nRoomType
    self.tbStorageLocation.nOwnerInstanceId = nOwnerInstanceId
    self.tbStorageLocation.nSlotIndex = nSlotIndex
end

function BattleItemBase:ClearStorageLocationAndOwner()
    self:ClearStorageLocation()
    self:SetOwnerCharacter(nil)
end

function BattleItemBase:ClearStorageLocation()
    self:SetStorageLocation(nil, nil, nil)
end

function BattleItemBase:GetProtoData()
    local tbData = {}
    tbData.instance_id = self.nInstanceId
    tbData.template_id = self:GetTemplateId()
    tbData.stack_count = self.nStackCount
    local tbStorageLocation = self:GetStorageLocationProtoData()
    tbData.storage_location = tbStorageLocation
    tbData.last_owner_character_instance_id = self.nLastOwnerCharacterInstanceId
    return tbData
end

-- run on client
function BattleItemBase:InitWithProtoData(tbPlayer, tbItemProtoData)
    local nInstanceId = tbItemProtoData.instance_id
    local nTemplateId = tbItemProtoData.template_id
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate == nil then
        error("BattleItemBase:InitWithProtoData() item template is nil, templateId: " .. nTemplateId)
    end
    self.tbOwnerCharacter = tbPlayer
    self:ParseStorageLocation(tbItemProtoData.storage_location)
    self:Init(nInstanceId, tbTemplate, tbItemProtoData.stack_count, false)
    self.nLastOwnerCharacterInstanceId = tbItemProtoData.last_owner_character_instance_id
end

function BattleItemBase:GetStorageLocationProtoData()
    local tbStorageLocation = {}
    tbStorageLocation.room_type = self.tbStorageLocation.nRoomType
    tbStorageLocation.owner_instance_id = self.tbStorageLocation.nOwnerInstanceId
    tbStorageLocation.slot_index = self.tbStorageLocation.nSlotIndex
    return tbStorageLocation
end

function BattleItemBase:ParseStorageLocation(tbStorageLocationData)
    self:SetStorageLocation(tbStorageLocationData.room_type, tbStorageLocationData.owner_instance_id, tbStorageLocationData.slot_index)
end

function BattleItemBase:GetSceneActor()
    return self.tbSceneActor
end

function BattleItemBase:SetSceneActor(tbSceneActor)
    self.tbSceneActor = tbSceneActor
end

function BattleItemBase:AfterAddedToCharacterOnServer(nBattleItemSource, bSyncToClient)
end

function BattleItemBase:GetCreateActorPosition(tbTransform)
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(tbTransform.X, tbTransform.Y)
    local bIsOcean =  nRegionType == EPiratesGridRegionType.Ocean or nRegionType == EPiratesGridRegionType.Port
    local tbPositionOffset  = FFAItemIni.tbPositionOffset
    local offSetMin = tbPositionOffset.nOffsetMinLand
    local offSetMax = tbPositionOffset.nOffsetMaxLand
    if bIsOcean then
        offSetMin = tbPositionOffset.nOffsetMinSea
        offSetMax = tbPositionOffset.nOffsetMaxSea
    end
    local offSetX = 0
    local offSetY = 0
    if math.random() > 0.5 then
        offSetX = RandomOffSet(offSetMin, offSetMax)
        if math.random() > 0.5 then
            offSetY = RandomOffSet(offSetMin, offSetMax)
        else
            offSetY = RandomOffSet(0, offSetMax)
        end
    else
        offSetX = RandomOffSet(0, offSetMax)
        offSetY = RandomOffSet(offSetMin, offSetMax)
    end

    local tbTranformAfterRandom = {X = tbTransform.X + offSetX, Y = tbTransform.Y + offSetY, Z = tbTransform.Z}
    return tbTranformAfterRandom, nil
end

return BattleItemBase