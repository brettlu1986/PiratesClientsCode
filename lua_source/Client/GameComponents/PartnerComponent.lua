-----------------------------------------------------
--File Name    : PartnerComponent.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-05
--Description  : 水手系统，客户端逻辑处理
--               代码中nPartnerId即为TemplateId，凡InstanceId均写作PartnerInstanceId
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local PartnerComponent = luaclass("PartnerComponent", GameComponentBase)

local Proto = require("ClientProtoNames")
local ItemSystem = require("ItemSystem")
local EventManager = require("EventManager")
local ItemDataTable = require("ItemDataTable")
local CurrencySystem = require("CurrencySystem")
local ClientEventDef = require("ClientEventDef")
local ItemCategoryDef = require("ItemCategoryDef")
local PartnerGradeDataTable = require("PartnerGradeDataTable")
local PartnerRelationDataTable = require("PartnerRelationDataTable")
local NetworkManager = dynamic_require("NetworkManager")

local INVALID_INSTANCE_ID = -1
local PARTNER_SUMMON_TYPE = {
    [1] = Proto.c2s_SummonPartner_SummonType.ONE_TIME,
    [10] = Proto.c2s_SummonPartner_SummonType.TEN_TIMES
}

PartnerComponent.bRedDotVisible = false
PartnerComponent.tbCreateData = nil
PartnerComponent.tbOwnedPartnerData = nil       -- { [nPartnerInstanceId] = { nLevel = 1, nSkinIndex = -1 }, ... }
PartnerComponent.tbPartnerEquippedData = nil    -- { [nSlotId] = nPartnerInstanceId, ... }

-- 根据TemplateId获取InstanceId
local function GetPartnerInstanceId(nPartnerId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nPartnerId)
    if tbItems and (#tbItems > 0) then
        return tbItems[1]:GetInstanceId()
    end
    return INVALID_INSTANCE_ID
end

-- 根据InstanceId获取TemplateId
local function GetPartnerId(nPartnerInstanceId)
    local Item = ItemSystem:GetItem(nPartnerInstanceId)
    return Item and Item:GetTemplateId()
end

-- 获取伙伴碎片个数
local function GetPartnerFragmentCount(nPartnerId)
    local tbTemplate = ItemSystem:GetItemTemplate(nPartnerId)
    local nFragmentId = tbTemplate.nCurrencyId
    return CurrencySystem:GetCurrencyCount(nFragmentId)
end

-- 对伙伴列表进行排序
local function SortPartnerInfoList(self, tbPartnerInfoList)
    table.sort(tbPartnerInfoList, function(A, B)
        -- 按是否可升星、合成排序
        local bCanLevelUpOrSummonA = self:IsPartnerCanUpLevelOrSummon(A.nPartnerId)
        local bCanLevelUpOrSummonB = self:IsPartnerCanUpLevelOrSummon(B.nPartnerId)
        if bCanLevelUpOrSummonA and (not bCanLevelUpOrSummonB) then
            return true
        elseif bCanLevelUpOrSummonB and (not bCanLevelUpOrSummonA) then
            return false
        elseif bCanLevelUpOrSummonA and bCanLevelUpOrSummonB then
            -- 合成优先于升星
            local bSummonA = A.nLevel <= 0
            local bSummonB = B.nLevel <= 0
            if bSummonA and (not bSummonB) then
                return true
            elseif bSummonB and (not bSummonA) then
                return false
            end
        end
        -- 先按是否拥有排序
        local bOwnedA = self:IsOwnedPartner(A.nPartnerId)
        local bOwnedB = self:IsOwnedPartner(B.nPartnerId)
        if bOwnedA and (not bOwnedB) then
            return true
        elseif bOwnedB and (not bOwnedA) then
            return false
        end
        -- 按品质排序
        if A.tbTemplate.nGrade ~= B.tbTemplate.nGrade then
            return A.tbTemplate.nGrade > B.tbTemplate.nGrade
        end
        -- 星级排序
        if A.nLevel ~= B.nLevel then
            return A.nLevel > B.nLevel
        end
        -- 按ID排序
        return A.nPartnerId < B.nPartnerId
    end)
end

-- 获取所有的伙伴列表
local function GetAllPartnerList()
    local tbTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.PARTNER)
    local tbPartnerList = {}
    for nPartnerId,tbTemplate in pairs(tbTemplates) do
        local tbPartnerInfo = {}
        tbPartnerInfo.nPartnerId = nPartnerId
        tbPartnerInfo.tbTemplate = tbTemplate
        tbPartnerInfo.tbResTemplate = ItemSystem:GetItemResTemplate(nPartnerId)
        table.insert(tbPartnerList, tbPartnerInfo)
    end
    return tbPartnerList
end

-- 从ItemSystem中刷新tbOwnedPartnerData数据
-- 因为现在服务器掉落伙伴时获取不到InstanceId，所以只能自己从ItemSystem拿
local function UpdateOwnedPartnerData(self)
    local tbPartnerItems = ItemSystem:GetItemsByCategory(ItemCategoryDef.PARTNER)
    for i, Item in ipairs(tbPartnerItems) do
        local nPartnerId = Item:GetTemplateId()
        if self.tbOwnedPartnerData[nPartnerId] == nil then
            self.tbOwnedPartnerData[nPartnerId] = {
                nLevel = 1,
                nSkinIndex = -1
            }
        end
    end
end

-- 初始化已拥有伙伴数据
local function InitPartnerOwnedData(self, tbOwnedPartnerInfos)
    local tbOwnedPartnerData = {}
    for i, v in ipairs(tbOwnedPartnerInfos) do
        local nInstanceId = v.instance_id
        local nPartnerId = ItemSystem:GetItem(nInstanceId):GetTemplateId()
        tbOwnedPartnerData[nPartnerId] = {
            nLevel = v.level,
            nSkinIndex = -1
        }
    end
    self.tbOwnedPartnerData = tbOwnedPartnerData
end

-- 初始化伙伴上阵数据
local function InitPartnerEquippedData(self, tbEquippedInfos)
    local tbPartnerEquippedData = {}
    for i, v in ipairs(tbEquippedInfos) do
        -- 服务器的position从0开始
        tbPartnerEquippedData[v.position + 1] = GetPartnerId(v.instance_id)
    end
    self.tbPartnerEquippedData = tbPartnerEquippedData
end

local function RefreshRedDotVisible(self)
    -- self.bRedDotVisible = false
    -- local tbPartnerList = GetAllPartnerList()
    -- for _, tbPartnerInfo in ipairs(tbPartnerList) do
    --     if self:IsPartnerCanUpLevelOrSummon(tbPartnerInfo.nPartnerId) then
    --         self.bRedDotVisible = true
    --         break
    --     end
    -- end
    -- EventManager:OnFireEvent(ClientEventDef.EV_ON_PARTNER_RED_DOT_VISIBLE_CHANGED, self.bRedDotVisible)
end

local function OnLobbyItemAdded(self, Item)
    RefreshRedDotVisible(self)
    if Item:GetCategory() == ItemCategoryDef.PARTNER then
        UpdateOwnedPartnerData(self)
    end
end

function PartnerComponent:OnCreate(Owner, tbParams)
    PartnerComponent.super.OnCreate(self, Owner, tbParams)
    self.tbCreateData = tbParams
end

function PartnerComponent:OnDestroy()
    EventManager:UnBindEventMethod(ClientEventDef.EV_CURRENCY_COUNT_SYNC            , self, RefreshRedDotVisible)
    EventManager:UnBindEventMethod(ClientEventDef.EV_ADD_LOBBY_ITEM                 , self, OnLobbyItemAdded)
    EventManager:UnBindEventMethod(ClientEventDef.EV_REMOVE_LOBBY_ITEM              , self, RefreshRedDotVisible)
    EventManager:UnBindEventMethod(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT  , self, RefreshRedDotVisible)
end

function PartnerComponent:OnPostCreate()
    local tbCreateData = self.tbCreateData
    if tbCreateData then
        InitPartnerOwnedData(self, tbCreateData.partner)
        InitPartnerEquippedData(self, tbCreateData.hired_partner)
        RefreshRedDotVisible(self)
        EventManager:BindEventMethod(ClientEventDef.EV_CURRENCY_COUNT_SYNC          , self, RefreshRedDotVisible)
        EventManager:BindEventMethod(ClientEventDef.EV_ADD_LOBBY_ITEM               , self, OnLobbyItemAdded)
        EventManager:BindEventMethod(ClientEventDef.EV_REMOVE_LOBBY_ITEM            , self, RefreshRedDotVisible)
        EventManager:BindEventMethod(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, RefreshRedDotVisible)
    end
end

-- 根据伙伴TemplateId获取伙伴信息
function PartnerComponent:GetPartnerInfo(nPartnerId)
    local tbPartnerInfo = {}
    tbPartnerInfo.nPartnerId = nPartnerId
    tbPartnerInfo.tbTemplate = ItemSystem:GetItemTemplate(nPartnerId)
    tbPartnerInfo.tbResTemplate = ItemSystem:GetItemResTemplate(nPartnerId)
    local tbOwnedPartnerInfo = self.tbOwnedPartnerData[nPartnerId]
    tbPartnerInfo.nLevel = tbOwnedPartnerInfo and tbOwnedPartnerInfo.nLevel or 0
    tbPartnerInfo.nSkinIndex = tbOwnedPartnerInfo and tbOwnedPartnerInfo.nSkinIndex or -1
    tbPartnerInfo.nFragmentCount = GetPartnerFragmentCount(nPartnerId)
    return tbPartnerInfo
end

-- 获取所有的伙伴列表
function PartnerComponent:GetPartnerList(bOwned)
    local tbRetList = {}
    local tbPartnerList = GetAllPartnerList()
    for _,tbPartnerInfo in ipairs(tbPartnerList) do
        -- 需要补全Part是否拥有、碎片个数等信息
        local nPartnerId = tbPartnerInfo.nPartnerId
        local tbOwnedPartnerInfo = self.tbOwnedPartnerData[nPartnerId]
        local nFragmentCount = GetPartnerFragmentCount(nPartnerId)
        if (not bOwned) or tbOwnedPartnerInfo or (nFragmentCount > 0) then
            tbPartnerInfo.nLevel = tbOwnedPartnerInfo and tbOwnedPartnerInfo.nLevel or 0
            tbPartnerInfo.nSkinIndex = tbOwnedPartnerInfo and tbOwnedPartnerInfo.nSkinIndex or -1
            tbPartnerInfo.nFragmentCount = nFragmentCount
            table.insert(tbRetList, tbPartnerInfo)
        end
    end
    SortPartnerInfoList(self, tbRetList)
    return tbRetList
end

-- 获取已装备的伙伴列表
function PartnerComponent:GetEquippedPartnerList()
    return self.tbPartnerEquippedData
end

-- 获取已拥有且未装备的伙伴列表（按照等级、星级排序）
function PartnerComponent:GetUnequippedPartnerList()
    local tbRetList = {}
    for nPartnerId,tbOwnedPartnerInfo in pairs(self.tbOwnedPartnerData) do
        if not self:IsEquippedPartner(nPartnerId) then
            local tbPartnerInfo = {}
            tbPartnerInfo.nPartnerId = nPartnerId
            tbPartnerInfo.tbTemplate = ItemSystem:GetItemTemplate(nPartnerId)
            tbPartnerInfo.tbResTemplate = ItemSystem:GetItemResTemplate(nPartnerId)
            tbPartnerInfo.nLevel = tbOwnedPartnerInfo.nLevel
            tbPartnerInfo.nSkinIndex = tbOwnedPartnerInfo.nSkinIndex
            tbPartnerInfo.nFragmentCount = GetPartnerFragmentCount(nPartnerId)
            table.insert(tbRetList, tbPartnerInfo)
        end
    end
    table.sort(tbRetList, function(A, B)
        if A.tbTemplate.nGrade ~= B.tbTemplate.nGrade then
            return A.tbTemplate.nGrade > B.tbTemplate.nGrade
        end
        if A.nLevel ~= B.nLevel then
            return A.nLevel > B.nLevel
        end
        return A.nPartnerId < B.nPartnerId
    end)
    return tbRetList
end

function PartnerComponent:GetActiveRelationIds(nPartnerId)
    local tbRetList = {}
    local tbRelations = PartnerRelationDataTable:GetRelationsByPartnerId(nPartnerId)
    for _, tbGroupData in ipairs(tbRelations) do
        -- 遍历羁绊中的Partner，获取最小Level
        local nMinLevel = 6
        local tbPartnerIds = tbGroupData[1].tbPartnerIds
        for i, nId in ipairs(tbPartnerIds) do
            local nLevel = self:GetPartnerInfo(nId).nLevel
            if not self:IsEquippedPartner(nId) then
                nLevel = -1
            end
            nMinLevel = math.min(nMinLevel, nLevel)
        end
        for _, tbTemplate in ipairs(tbGroupData) do
            if nMinLevel >= tbTemplate.nLevel then
                table.insert(tbRetList, tbTemplate.nId)
            end
        end
    end
    return tbRetList
end

-- 是否为已拥有伙伴
function PartnerComponent:IsOwnedPartner(nPartnerId)
    return self.tbOwnedPartnerData[nPartnerId]
end

-- 伙伴是否可升星或招募
function PartnerComponent:IsPartnerCanUpLevelOrSummon(nPartnerId)
    local tbPartnerInfo = self:GetPartnerInfo(nPartnerId)
    local nGrade = tbPartnerInfo.tbTemplate.nGrade
    local nNextLevel = tbPartnerInfo.nLevel + 1
    local nFragmentTotalCount = PartnerGradeDataTable:GetFragmentCountByGradeAndLevel(nGrade, nNextLevel)
    if nFragmentTotalCount then
        return tbPartnerInfo.nFragmentCount >= nFragmentTotalCount
    end
    return false
end

-- 是否为已上阵伙伴
function PartnerComponent:IsEquippedPartner(nPartnerId)
    for _,v in pairs(self.tbPartnerEquippedData) do
        if v == nPartnerId then
            return true
        end
    end
    return false
end

-- 获取红点是否显示
function PartnerComponent:GetPartnerRedDotVisible()
    return self.bRedDotVisible
end

---------------------------------------------------------------
-- 以下为s2c回包处理逻辑
---------------------------------------------------------------
-- 收到招募协议的回包
function PartnerComponent:ReceiveSummonPartner(tbSummonResults)
    UpdateOwnedPartnerData(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SUMMON_PARTNER_RESULT, tbSummonResults)
    RefreshRedDotVisible(self)
end

-- 收到升星协议的回包
function PartnerComponent:ReceiveUpLevelPartner(nPartnerInstanceId, nLevel)
    local nPartnerId = GetPartnerId(nPartnerInstanceId)
    self.tbOwnedPartnerData[nPartnerId].nLevel = nLevel
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_PARTNER_LEVEL_UP_RESULT, nPartnerId, nLevel)
    RefreshRedDotVisible(self)
end

-- 收到上阵协议的回包
function PartnerComponent:ReceiveEquipPartner(nPosition, nPartnerInstanceId)
    local nSlotId = nPosition + 1
    local nPartnerId = GetPartnerId(nPartnerInstanceId)
    self.tbPartnerEquippedData[nSlotId] = nPartnerId
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_EQUIP_PARTNER_RESULT, nSlotId, nPartnerId)
end

-- 收到下阵协议的回包
function PartnerComponent:ReceiveUnequipPartner(nPosition, nPartnerInstanceId)
    local nSlotId = nPosition + 1
    self.tbPartnerEquippedData[nSlotId] = nil
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_UNEQUIP_PARTNER_RESULT, nSlotId)
end

-- 收到合成协议的回包
function PartnerComponent:ReceiveCompoundPartner(nPartnerInstanceId)
    local nPartnerId = GetPartnerId(nPartnerInstanceId)
    UpdateOwnedPartnerData(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_COMPOUND_PARTNER_RESULT, nPartnerId)
    RefreshRedDotVisible(self)
end

-------------------------------------------
-- 以下为c2s协议接口
-------------------------------------------
-- 请求招募伙伴
function PartnerComponent:RequestSummonPartner(nPoolId, nCount)
    local c2s_SummonPartner = {
        pool_id = nPoolId,
        type = PARTNER_SUMMON_TYPE[nCount]
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SummonPartner, c2s_SummonPartner)
end

-- 请求升星
function PartnerComponent:RequestUpLevelPartner(nPartnerId)
    local nPartnerInstanceId = GetPartnerInstanceId(nPartnerId)
    local c2s_UpLevelPartner = {
        instance_id = nPartnerInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UpLevelPartner, c2s_UpLevelPartner)
end

-- 请求装备或者更换指定位置伙伴
function PartnerComponent:RequestEquipPartner(nSlotId, nPartnerId)
    local nPartnerInstanceId = GetPartnerInstanceId(nPartnerId)
    local c2s_HirePartner = {
        position = nSlotId - 1,
        instance_id = nPartnerInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_HirePartner, c2s_HirePartner)
end

-- 请求卸载指定位置伙伴
function PartnerComponent:RequestUnequipPartner(nSlotId)
    local nPartnerId = self.tbPartnerEquippedData[nSlotId]
    local nPartnerInstanceId = GetPartnerInstanceId(nPartnerId)
    local c2s_FirePartner = {
        position = nSlotId - 1,
        instance_id = nPartnerInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_FirePartner, c2s_FirePartner)
end

-- 请求通过碎片招募伙伴
function PartnerComponent:RequestCompoundPartner(nPartnerId)
    local c2s_CompoundPartner = {
        template_id = nPartnerId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_CompoundPartner, c2s_CompoundPartner)
end

return PartnerComponent