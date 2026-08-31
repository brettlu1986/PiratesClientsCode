-----------------------------------------------------
--File Name    : SailorComponent.lua
--Author       : Song Fuhao
--Create Time  : 2019-02-19
--Description  : 水手系统，客户端逻辑处理
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local SailorComponent = luaclass("SailorComponent", GameComponentBase)

local DelayTimer = require("DelayTimer")
local ItemSystem = require("ItemSystem")
local Proto = require("ClientProtoNames")
local EventManager = require("EventManager")
local CurrencySystem = require("CurrencySystem")
local ClientEventDef = require("ClientEventDef")
local SailorRedDotDef = require("SailorRedDotDef")
local ItemCategoryDef = require("ItemCategoryDef")
local SailorCategoryDef = require("SailorCategoryDef")
local NetworkManager = dynamic_require("NetworkManager")
local PropertyComboSystem = require("PropertyComboSystem")
local SailorSlotDataTable = require("SailorSlotDataTable")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local SailorSummonDataTable = require("SailorSummonDataTable")

local MAX_GRADE = 4
local MAX_SLOT_PER_TYPE = 10
local INVALID_ID = -1
local CURRENCY_ID = 1400003
local MAX_SAILOR_GRADE = 5

SailorComponent.tbCreateData = nil
SailorComponent.tbRedDotVisibles = nil -- 水手红点信息 {[SailorRedDotDef.EQUIPPING] = true, [SailorRedDotDef.BACKPACK] = false, [SailorRedDotDef.SUMMONING] = false}
SailorComponent.tbSailorSlotData = nil -- 水手槽位信息 { [1] = {{ nSailorId = nil, bUnlocked = false}, ...}, [2] = {{ nSailorId = nil, bUnlocked = false}, ...}, [3] = {{ nSailorId = nil, bUnlocked = false}, ...} }
SailorComponent.tbSailorEquippedData = nil -- 已装备水手个数信息 { { [nSailorId] = nCount }, ... }
SailorComponent.tbSailorFreeSummonDatas = nil -- 水手免费抽取的信息 {[1]={bIsFree = true, nNextFreeTime = 1291208}, [1]={bIsFree = true, nNextFreeTime = 1291208}}
SailorComponent.tbFreeSummonTimers = nil -- 水手免费抽取的timer列表
SailorComponent.tbNextHighGradeAwardCounts = nil -- 下次高级奖励获取还需要多少次的Map
SailorComponent.nOneKeyEquipDelayTime = 0
SailorComponent.bOneKeyEquipWithAnim = false
SailorComponent.bFirstEnterLobby = false

-- 根据TemplateId获取InstanceId
local function GetSailorInstanceId(nSailorId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nSailorId)
    if tbItems and (#tbItems > 0) then
        return tbItems[1]:GetInstanceId()
    end
    return INVALID_ID
end

-- 根据InstanceId获取TemplateId
local function GetSailorId(nSailorInstanceId)
    local Item = ItemSystem:GetItem(nSailorInstanceId)
    return Item and Item:GetTemplateId() or INVALID_ID
end

-- 根据等级获取水手所有的Template
local function GetSailorTemplatesByGrade(self, nGrade)
    local tbTemplates = {}
    local tbSailorTemplates = ItemSystem:GetItemTemplatesByCategory(ItemCategoryDef.SAILOR)
    for nSailorId, tbTemplate in pairs(tbSailorTemplates) do
        if tbTemplate.nGrade == nGrade then
            tbTemplates[nSailorId] = tbTemplate
        end
    end
    return tbTemplates
end

-- 获取指定水手已装备个数
local function GetSailorEquippedCount(self, nSailorId)
    return self.tbSailorEquippedData[nSailorId] or 0
end

-- 根据差值更新指定水手已装备个数
local function UpdateSailorEquippedCount(self, nSailorId, nDelta)
    if nSailorId > 0 then
        self.tbSailorEquippedData[nSailorId] = GetSailorEquippedCount(self, nSailorId) + nDelta
    end
end

-- 等级优先，然后按ID顺序排序
local function SortSailorList(tbRetList)
    table.sort(tbRetList, function(A, B)
        if A.tbTemplate.nGrade ~= B.tbTemplate.nGrade then
            return A.tbTemplate.nGrade > B.tbTemplate.nGrade
        end
        return A.nSailorId < B.nSailorId
    end)
end

-- 获取当前水手升级降级前后水手信息
local function GetSailorSeriesInfos(nSailorId)
    local tbSailorSeriesInfos = {}
    repeat
        local tbSailorTemplate = ItemSystem:GetItemTemplate(nSailorId)
        local nGrade = tbSailorTemplate.nGrade + 1
        tbSailorSeriesInfos[nGrade] = {
            nSailorId = nSailorId,
            nCount = ItemSystem:GetItemCount(nSailorId)
        }
        nSailorId = tbSailorTemplate.nUpgradeTo
    until (nSailorId == 0)
    return tbSailorSeriesInfos
end

-- 获取最优的推荐水手id
local function GetOptimalRecommendedSailorId(tbCacheInfo, nOriginSailorId)
    local tbSailorSeriesInfos = tbCacheInfo[nOriginSailorId]
    if not tbSailorSeriesInfos then
        tbSailorSeriesInfos = GetSailorSeriesInfos(nOriginSailorId)
        tbCacheInfo[nOriginSailorId] = tbSailorSeriesInfos
    end
    for nGrade = MAX_SAILOR_GRADE, 1, -1 do
        local tbSailorInfo = tbSailorSeriesInfos[nGrade]
        if tbSailorInfo and tbSailorInfo.nCount > 0 then
            tbSailorInfo.nCount = tbSailorInfo.nCount - 1
            return tbSailorInfo.nSailorId
        end
    end
    return INVALID_ID
end

-----------------------Init Logic Begin-------------------------

local function ChangeRedDot(self, bVisible, nSailorRedDotDef)
    self.tbRedDotVisibles[nSailorRedDotDef] = bVisible
    EventManager:OnFireEvent(ClientEventDef.EV_ON_SAILOR_RED_DOT_VISIBLE_CHANGED, bVisible, nSailorRedDotDef)
end

local function AddFreeSummonTimer(self, nSummonId, nRemainSeconds)
    if self.tbFreeSummonTimers and self.tbFreeSummonTimers[nSummonId] ~= nil then
        error("free summon timer already exist!"..nSummonId)
    end
    log("[Summon]AddFreeSummonTimer", nSummonId, nRemainSeconds)
    local FunFreeSummonTimerCallback = function()
        log("[Summon]FunFreeSummonTimerCallback", nSummonId)
        self.tbFreeSummonTimers[nSummonId] = nil
        local tbSailorFreeSummonData = self.tbSailorFreeSummonDatas[nSummonId]
        if not tbSailorFreeSummonData then
            tbSailorFreeSummonData = {}
            self.tbSailorFreeSummonDatas[nSummonId] = tbSailorFreeSummonData
        end
        tbSailorFreeSummonData.bIsFree = true
        tbSailorFreeSummonData.nNextFreeTime = 0
        ChangeRedDot(self, true, SailorRedDotDef.SUMMONING)
    end
    local DelayHandle = DelayTimer:DelayRun(FunFreeSummonTimerCallback, nRemainSeconds)
    self.tbFreeSummonTimers[nSummonId] = DelayHandle
end

local function ClearAllFreeSummonTimer(self)
    if self.tbFreeSummonTimers ~= nil then
        for k, v in pairs(self.tbFreeSummonTimers) do
            if v then
                DelayTimer:ClearTimer(v)
                self.tbFreeSummonTimers[k] = nil
            end
        end
    end
    self.tbFreeSummonTimers = {}
    log("[Summon]ClearAllFreeSummonTimer")
end

local function InitSailorSlotData(self)
    local tbSailorSlotData = {}
    for i = 1, SailorCategoryDef.MAX_COUNT do
        tbSailorSlotData[i] = {}
        for k = 1, MAX_SLOT_PER_TYPE do
            tbSailorSlotData[i][k] = {}
        end
    end
    self.tbSailorSlotData = tbSailorSlotData
end

local function InitSailorFreeSummonData(self, tbFreeSummonSailors)
    self.tbSailorFreeSummonDatas = {}
    local tbTemplates = SailorSummonDataTable:GetAllTemplates()
    local now = GlobalVariableSystem:GetServerTimeUtc()
    for _, v1 in pairs(tbTemplates) do
        if v1.bCanFree then
            local nId = v1.nId
            local bIsFree = true
            local nCooldownSeconds = 0
            for _, v2 in ipairs(tbFreeSummonSailors) do
                if nId == v2.summon_id then
                    nCooldownSeconds = v2.cooldown_seconds
                    if nCooldownSeconds > 0 then
                        bIsFree = false
                    end
                end
            end
            local tbSailorFreeSummonData = {}
            tbSailorFreeSummonData.bIsFree = bIsFree
            self.tbSailorFreeSummonDatas[nId] = tbSailorFreeSummonData
            if not bIsFree then
                tbSailorFreeSummonData.nNextFreeTime = now + nCooldownSeconds
                log("[Summon]InitSailorFreeSummonData", nId, nCooldownSeconds, now, tbSailorFreeSummonData.nNextFreeTime)
                AddFreeSummonTimer(self, nId, nCooldownSeconds)
            end
        end
    end
end

local function RefreshSailorFreeSummonData(self)
    local now = GlobalVariableSystem:GetServerTimeUtc()
    for nId, tbSailorFreeSummonData in pairs(self.tbSailorFreeSummonDatas) do
        if not tbSailorFreeSummonData.bIsFree then
            if now >= tbSailorFreeSummonData.nNextFreeTime then
                tbSailorFreeSummonData.bIsFree = true
                tbSailorFreeSummonData.nNextFreeTime = 0
                ChangeRedDot(self, true, SailorRedDotDef.SUMMONING)
            else
                AddFreeSummonTimer(self, nId, tbSailorFreeSummonData.nNextFreeTime - now)
            end
        end
    end
end

local function UpdateNextSailorHighGradeAwardCounts(self, tbSummonGroupCount)
    self.tbNextHighGradeAwardCounts = {}
    for _, tbInfo in ipairs(tbSummonGroupCount) do
        self.tbNextHighGradeAwardCounts[tbInfo.group_id] = tbInfo.high_grade_frequency_left
    end
end

local function ParseCreateData(self)
    local tbCreateData = self.tbCreateData
    local tbSailorSlotData = self.tbSailorSlotData
    for k, v in pairs(tbCreateData.unlocked_sailor_slot) do
        tbSailorSlotData[v.sub_category][v.slot_index].bUnlocked = true
    end

    self.tbSailorEquippedData = {}
    for k, v in pairs(tbCreateData.equipped_sailor) do
        local tbSailorSlotInfo = tbSailorSlotData[v.sailor_slot.sub_category][v.sailor_slot.slot_index]
        local nSailorId = GetSailorId(v.sailor_instance_id)
        if nSailorId ~= INVALID_ID then
            tbSailorSlotInfo.nSailorId = nSailorId
            UpdateSailorEquippedCount(self, nSailorId, 1)
        end
    end
end

local function RefreshEquippingRedDotVisible(self)
    local bRedDotVisible = false
    for nCategory, tbSlotInfoList in ipairs(self.tbSailorSlotData) do
        for nIndex, tbSlotInfo in pairs(tbSlotInfoList) do
            if tbSlotInfo.bUnlocked and (tbSlotInfo.nSailorId == nil) then
                bRedDotVisible = true
                break
            end
        end
    end
    ChangeRedDot(self, bRedDotVisible, SailorRedDotDef.EQUIPPING)
end

local function RefreshSummonRedDotVisible(self)
    for nSummonId, tbSailorFreeSummonData in pairs(self.tbSailorFreeSummonDatas) do
        if tbSailorFreeSummonData.bIsFree then
            ChangeRedDot(self, true, SailorRedDotDef.SUMMONING)
            return
        end
    end
    ChangeRedDot(self, false, SailorRedDotDef.SUMMONING)
end

local function RefreshRedDotVisible(self)
    RefreshEquippingRedDotVisible(self)
    RefreshSummonRedDotVisible(self)
end

-- 免费抽取结束
local function HandleFreeSummonComplete(self, tbFreeResult)
    if tbFreeResult and tbFreeResult.free then
        local nSummonId = tbFreeResult.id
        local tbSailorFreeSummonData = self.tbSailorFreeSummonDatas[nSummonId]
        if not tbSailorFreeSummonData then
            tbSailorFreeSummonData = {}
            self.tbSailorFreeSummonDatas[nSummonId] = tbSailorFreeSummonData
        end
        tbSailorFreeSummonData.bIsFree = false
        local now = GlobalVariableSystem:GetServerTimeUtc()
        local tbSummonTemplate = SailorSummonDataTable:GetTemplate(nSummonId)
        local nFreeSeconds = tbSummonTemplate.nFreeSeconds
        tbSailorFreeSummonData.nNextFreeTime = now + nFreeSeconds
        log("[Summon]HandleFreeSummonComplete", nSummonId, nFreeSeconds, now, tbSailorFreeSummonData.nNextFreeTime)
        AddFreeSummonTimer(self, nSummonId, nFreeSeconds)
        RefreshSummonRedDotVisible(self)
    end
end

local function OnEnterLobby(self)
    log("[Summon]SailorComponent OnEnterLobby")
    if self.bFirstEnterLobby then
        self.bFirstEnterLobby = false
        return
    end
    ClearAllFreeSummonTimer(self)
    RefreshSailorFreeSummonData(self)
end

local function OnEnterBattle(self)
    log("[Summon]SailorComponent OnEnterBattle")
    ClearAllFreeSummonTimer(self)
end

local function OnLeaveLobby(self)
    log("[Summon]SailorComponent OnLeaveLobby")
    ClearAllFreeSummonTimer(self)
end

function SailorComponent:OnCreate(Owner, tbParams)
    SailorComponent.super.OnCreate(self, Owner, tbParams)
    self.tbRedDotVisibles = {}
    self.bFirstEnterLobby = true
    ClearAllFreeSummonTimer(self)
    InitSailorSlotData(self)
    InitSailorFreeSummonData(self, tbParams.free_summon_sailors)
    UpdateNextSailorHighGradeAwardCounts(self, tbParams.summon_group_count)
    self.tbCreateData = tbParams
    EventManager:BindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    EventManager:BindEventMethod(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventManager:BindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
end

function SailorComponent:OnPostCreate()
    ParseCreateData(self)
    RefreshRedDotVisible(self)
    self.tbCreateData = nil
end

function SailorComponent:OnDestroy()
    ClearAllFreeSummonTimer(self)
    EventManager:UnBindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    EventManager:UnBindEventMethod(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventManager:UnBindEventMethod(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    SailorComponent.super.OnDestroy(self)
end

-----------------------Init Logic End-------------------------

-- 获取各水手槽位信息
function SailorComponent:GetSailorSlotInfo()
    return self.tbSailorSlotData
end

-- 获取已经装备的水手SailorId及其数量
function SailorComponent:GetSailorEquippedData()
    return self.tbSailorEquippedData
end

-- 根据等级获取所有水手列表
-- @param nGrade 从0开始
function SailorComponent:GetSailorListByGrade(nGrade)
    local tbRetList = {}
    local tbTemplates = GetSailorTemplatesByGrade(self, nGrade)
    for nSailorId, tbTemplate in pairs(tbTemplates) do
        local tbSailorData = {}
        tbSailorData.nSailorId = nSailorId
        tbSailorData.tbTemplate = tbTemplate
        tbSailorData.nCount = ItemSystem:GetItemCount(nSailorId)
        table.insert(tbRetList, tbSailorData)
    end
    SortSailorList(tbRetList)
    return tbRetList
end

-- 根据水手类型获取空闲的水手列表
-- @param nSailorCategory   水手类型
-- @param nFilteredSailorId 需要被过滤掉的水手Id
function SailorComponent:GetFreeSailorListByType(nSailorCategory, nFilteredSailorId)
    local tbRetList = {}
    local tbSailorItems = ItemSystem:GetItemsByCategory(ItemCategoryDef.SAILOR)
    for i, SailorItem in ipairs(tbSailorItems) do
        local tbTemplate = SailorItem:GetTemplate()
        local nSailorId = tbTemplate.nId
        if (tbTemplate.nSubCategory == nSailorCategory) and (nFilteredSailorId ~= nSailorId) then
            local nCount = SailorItem:GetStackCount() - GetSailorEquippedCount(self, nSailorId)
            if nCount > 0 then
                local tbSailorData = {}
                tbSailorData.nSailorId = nSailorId
                tbSailorData.tbTemplate = tbTemplate
                tbSailorData.nCount = nCount
                table.insert(tbRetList, tbSailorData)
            end
        end
    end
    SortSailorList(tbRetList)
    return tbRetList
end

-- 获取当前Category所有水手列表
-- @param nSailorCategory   水手类型
function SailorComponent:GetSailorListByType(nSailorCategory, nExcludeSailorId)
    local tbRetList = {}
    local tbSailorItems = ItemSystem:GetItemsByCategory(ItemCategoryDef.SAILOR)
    for i, SailorItem in ipairs(tbSailorItems) do
        local tbTemplate = SailorItem:GetTemplate()
        local nSailorId = tbTemplate.nId
        if (tbTemplate.nSubCategory == nSailorCategory) then
            local nCount = SailorItem:GetStackCount() - GetSailorEquippedCount(self, nSailorId)
            local bIsExcludeItem = nSailorId == nExcludeSailorId
            if nCount > 0 or bIsExcludeItem then
                local tbSailorData = {}
                tbSailorData.nSailorId = nSailorId
                tbSailorData.tbTemplate = tbTemplate
                tbSailorData.nCount = bIsExcludeItem and 1 or nCount
                table.insert(tbRetList, tbSailorData)
            end
        end
    end
    SortSailorList(tbRetList)
    return tbRetList
end

-- 获取拥有的同类水手的id（优先高级别，再看低级别）
function SailorComponent:GetOtherSameSailorId(nOrginSailorId)
    local bHighGrade = true
    local nCount = 0
    -- 先查高等级水手
    local nSailorId = nOrginSailorId
    repeat
        nSailorId = ItemSystem:GetItemTemplate(nSailorId).nUpgradeTo
        nCount = ItemSystem:GetItemCount(nSailorId)
    until (nCount > 0) or (nSailorId == 0)
    -- 再查低等级水手
    if nCount <= 0 then
        nSailorId = nOrginSailorId
        bHighGrade = false
        repeat
            nSailorId = ItemSystem:GetItemTemplate(nSailorId).nDegradeTo
            nCount = ItemSystem:GetItemCount(nSailorId)
        until (nCount > 0) or (nSailorId == 0)
    end
    return nSailorId, bHighGrade
end


function SailorComponent:GetEquippedSailorUpgradeData(nSailorCategory)
    local tbEquippedSailorUpgradeData = {}
    local nMinGrade = 0

    -- 构建基本的升级数据
    for nCategory, tbSlotInfoList in ipairs(self.tbSailorSlotData) do
        if nSailorCategory == nil or nCategory == nSailorCategory then
            for nIndex, tbSlotInfo in pairs(tbSlotInfoList) do
                local nId = tbSlotInfo.nSailorId
                if tbSlotInfo.nSailorId then
                    local nGrade = ItemSystem:GetItemTemplate(nId).nGrade
                    nMinGrade = math.min(nMinGrade, nGrade)
                    table.insert(tbEquippedSailorUpgradeData, {
                        nSailorId       = nId,          -- 默认的水手ID
                        nSailorCategory = nCategory,    -- 水手的类型
                        nSlotIndex      = nIndex,       -- 水手所在槽位Index
                        nBaseGrade      = nGrade,       -- 未升级前水手等级，用于计算最后累计升级级数量
                        nGradeUpgradeTo = nGrade,       -- 要把水手升到几级（用于排序）
                        nIdUpgradeTo    = nId,          -- 要把水手升到哪个水手ID
                    })
                end
            end
        end
    end

    -- 计算当前货币余额可以升级到几级
    local nTotalCurrency = 0
    local nCurrentCurrency = CurrencySystem:GetCurrencyCount(CURRENCY_ID)
    local bCurrencyEnough = true
    local bHasAnyUpgrade = false
    for nCurrentGrade = nMinGrade, MAX_GRADE - 1 do
        -- 每次重新遍历前，先根据分类排序，再根据当前的升级等级升序排序
        table.sort(tbEquippedSailorUpgradeData, function(A, B)
            if A.nSailorCategory ~= B.nSailorCategory then
                return A.nSailorCategory < B.nSailorCategory
            end
            if A.nGradeUpgradeTo ~= B.nGradeUpgradeTo then

                return A.nGradeUpgradeTo < B.nGradeUpgradeTo
            end
            return A.nSlotIndex < B.nSlotIndex
        end)

        -- 遍历当前列表
        for _, tbData in ipairs(tbEquippedSailorUpgradeData) do
            if nCurrentGrade == tbData.nGradeUpgradeTo then
                local tbTemplate = ItemSystem:GetItemTemplate(tbData.nIdUpgradeTo)
                local nUpgradeCurrencyAmount = tbTemplate.nUpgradeCurrencyAmount

                -- 钱不够了跳出循环
                bCurrencyEnough = nCurrentCurrency >= nTotalCurrency + nUpgradeCurrencyAmount
                if not bCurrencyEnough then
                    if not bHasAnyUpgrade then
                        -- 跳出循环的时候没有任何升级，加入本次数据
                        nTotalCurrency = nTotalCurrency + nUpgradeCurrencyAmount
                        tbData.nIdUpgradeTo = tbTemplate.nUpgradeTo
                        tbData.nGradeUpgradeTo = tbTemplate.nGrade + 1
                    end
                    break
                end
                bHasAnyUpgrade = true
                nTotalCurrency = nTotalCurrency + nUpgradeCurrencyAmount
                tbData.nIdUpgradeTo = tbTemplate.nUpgradeTo
                tbData.nGradeUpgradeTo = tbTemplate.nGrade + 1
            end
        end

        -- 钱不够了还需要打断外部循环
        if not bCurrencyEnough then
            break
        end
    end

    -- 整理数据
    local nTotalGrade = 0
    local nTotalGradeUpgradeTo = 0
    for i = #tbEquippedSailorUpgradeData, 1, -1 do
        local tbData = tbEquippedSailorUpgradeData[i]
        nTotalGrade = nTotalGrade + tbData.nBaseGrade + 1
        nTotalGradeUpgradeTo = nTotalGradeUpgradeTo + tbData.nGradeUpgradeTo + 1
        if tbData.nGradeUpgradeTo <= tbData.nBaseGrade then
            table.remove(tbEquippedSailorUpgradeData, i)
        end
    end
    return nTotalGrade, nTotalGradeUpgradeTo, nTotalCurrency, tbEquippedSailorUpgradeData
end

-- 获取红点是否显示
function SailorComponent:GetSailorRedDotVisible(nSailorRedDotDef)
    if not nSailorRedDotDef then
        for _, v in pairs(self.tbRedDotVisibles) do
            if v then
                return true
            end
        end
        return false
    else
        local bVisible = self.tbRedDotVisibles[nSailorRedDotDef]
        if bVisible then
            return true
        else
            return false
        end
    end
end

-- 获取水手的介绍文本
function SailorComponent:GetSailorIntroduce(nSailorId)
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    local nComboId = tbTemplate and tbTemplate.nPropertyComboId or INVALID_ID
    return PropertyComboSystem:GetPropertyComboDisplayString(nComboId)
end

function SailorComponent:GetSailorIntroduceWithColor(nSailorId, szColor)
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    local nComboId = tbTemplate and tbTemplate.nPropertyComboId or INVALID_ID
    return PropertyComboSystem:GetPropertyComboDisplayStringWithColor(nComboId, szColor)
end

-- 获取水手抽取是否免费的信息
-- return bCanFree, bIsFree, nNextFreeTime
function SailorComponent:GetFreeSummonData(nSummonId)
    local tbSummonTemplate = SailorSummonDataTable:GetTemplate(nSummonId)
    if not tbSummonTemplate.bCanFree then
        return false, false
    else
        local tbSummonFreeData = self.tbSailorFreeSummonDatas[nSummonId]
        if not tbSummonFreeData then
            return true, true
        end
        return true, tbSummonFreeData.bIsFree, tbSummonFreeData.nNextFreeTime
    end
end

-- 获取下次水手高级奖励需要的抽取次数
-- param nSummonGroupId
-- return nCount
function SailorComponent:GetNextHighGradeAwardCount(nSummonGroupId)
    return self.tbNextHighGradeAwardCounts[nSummonGroupId] or 0
end

---------------------------------------------------------------
-- 以下为s2c回包处理逻辑
---------------------------------------------------------------
-- 收到招募水手回包
function SailorComponent:ReceiveSailorSummonResult(bSummonSucceeded, tbSummonResult, tbFreeResult, tbSummonGroupCount, bReturnCode, bAutoExchange)
    if bSummonSucceeded then
        HandleFreeSummonComplete(self, tbFreeResult)
        UpdateNextSailorHighGradeAwardCounts(self, tbSummonGroupCount)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_SUMMON_RESULT, bSummonSucceeded, tbSummonResult, bReturnCode, bAutoExchange)
end

-- 收到装备/更换水手回包
function SailorComponent:ReceiveSailorEquipResult(nCategory, nSailorSlot, nEquippedInstanceId, nUnequippedInstanceId)

    local nEquippedSailorId = GetSailorId(nEquippedInstanceId)
    local nUnequippedSailorId = GetSailorId(nUnequippedInstanceId)
    UpdateSailorEquippedCount(self, nEquippedSailorId, 1)
    UpdateSailorEquippedCount(self, nUnequippedSailorId, -1)

    local tbSailorSlotInfo = self.tbSailorSlotData[nCategory][nSailorSlot]
    tbSailorSlotInfo.nSailorId = nEquippedSailorId
    RefreshEquippingRedDotVisible(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_EQUIP_RESULT, nCategory, nSailorSlot, nEquippedSailorId, nUnequippedSailorId)
end

-- 收到水手升级回包
function SailorComponent:ReceiveSailorUpgradeResult(nLastSailorId, nCount, nUpgradedSailorId, tbUpgradedSailorSlotInfos)
    local nEquippedCount = #tbUpgradedSailorSlotInfos
    UpdateSailorEquippedCount(self, nLastSailorId, -nEquippedCount)
    UpdateSailorEquippedCount(self, nUpgradedSailorId, nEquippedCount)

    local tbSailorSlotData = self.tbSailorSlotData
    for i, tbSlotInfo in ipairs(tbUpgradedSailorSlotInfos) do
        local tbSailorSlotInfo = tbSailorSlotData[tbSlotInfo.sub_category][tbSlotInfo.slot_index]
        tbSailorSlotInfo.nSailorId = nUpgradedSailorId
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UPGRADE_RESULT, nLastSailorId, nUpgradedSailorId)
end

-- 收到重置水手（至最低级）回包
function SailorComponent:ReceiveSailorDegradeResult(nLastSailorId, nCount, nDegradedSailorId, tbDegradedSailorSlotInfos)
    local nEquippedCount = #tbDegradedSailorSlotInfos
    UpdateSailorEquippedCount(self, nLastSailorId, -nEquippedCount)
    UpdateSailorEquippedCount(self, nDegradedSailorId, nEquippedCount)

    local tbSailorSlotData = self.tbSailorSlotData
    for i, tbSlotInfo in ipairs(tbDegradedSailorSlotInfos) do
        local tbSailorSlotInfo = tbSailorSlotData[tbSlotInfo.sub_category][tbSlotInfo.slot_index]
        tbSailorSlotInfo.nSailorId = nDegradedSailorId
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, nLastSailorId, nDegradedSailorId)
end

-- 收到一键升级已装备水手回包
function SailorComponent:ReceiveUpgradeEquippedSailorResult(tbRawUpgradedSailorInfos, bOneKeyUpgrade)
    local tbUpgradedSailorInfos = {}
    local tbSailorSlotData = self.tbSailorSlotData
    for i, tbUpgradedInfo in ipairs(tbRawUpgradedSailorInfos) do
        local tbSlotInfo = tbUpgradedInfo.sailor_slot
        local tbSailorSlotInfo = tbSailorSlotData[tbSlotInfo.sub_category][tbSlotInfo.slot_index]
        local nLastSailorId = tbSailorSlotInfo.nSailorId
        local nUpgradedSailorId = GetSailorId(tbUpgradedInfo.sailor_instance_id)
        tbSailorSlotInfo.nSailorId = nUpgradedSailorId
        UpdateSailorEquippedCount(self, nLastSailorId, -1)
        UpdateSailorEquippedCount(self, nUpgradedSailorId, 1)
        tbUpgradedSailorInfos[i] = {
            nSailorCategory = tbSlotInfo.sub_category,
            nSlotIndex = tbSlotInfo.slot_index,
            nSailorId = nLastSailorId,
            nUpgradeTo = nUpgradedSailorId,
        }
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_UPGRADE_EQUIPPED_SAILOR_RESULT, tbUpgradedSailorInfos, bOneKeyUpgrade)
end

-- 收到卸载所有水手回包
function SailorComponent:ReceiveSailorUnequipAllResult()
    self.tbSailorEquippedData = {}
    for i, v in ipairs(self.tbSailorSlotData) do
        for j, tbSailorSlotInfo in ipairs(v) do
            tbSailorSlotInfo.nSailorId = nil
        end
    end
    RefreshEquippingRedDotVisible(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UNEQUIP_ALL_RESULT)
end

function SailorComponent:ReceiveSailorUnequipCategoryResult(nSubCategory)
    for nSailorId, _ in pairs(self.tbSailorEquippedData) do
        local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
        if tbTemplate.nSubCategory == nSubCategory then
            self.tbSailorEquippedData[nSailorId] = 0
        end
    end

    for nCategory, tbSlotInfoList in ipairs(self.tbSailorSlotData) do
        if nSubCategory == nCategory then
            for j, tbSailorSlotInfo in ipairs(tbSlotInfoList) do
                tbSailorSlotInfo.nSailorId = nil
            end
        end
    end
    RefreshEquippingRedDotVisible(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UNEQUIP_PART_RESULT, nSubCategory)
end

-- 解锁水手槽位回包
function SailorComponent:ReceiveUnlockSailorSlotResult(tbSlotInfo)
    local nSailorCategory = tbSlotInfo.sub_category
    local nSlotIndex = tbSlotInfo.slot_index
    self.tbSailorSlotData[nSailorCategory][nSlotIndex] = { bUnlocked = true }
    RefreshEquippingRedDotVisible(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SAILOR_SLOT_RESULT, true, nSailorCategory, nSlotIndex)
end

---------------------------------------------------------------
-- 以下为c2s协议请求接口
---------------------------------------------------------------
-- 请求招募水手
function SailorComponent:RequestSailorSummon(nSummonId, bFree, bAutoExchange)
    local c2s_SailorSummon = {
        id = nSummonId,
        free = bFree,
        currency_auto_exchange = bAutoExchange
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SailorSummon, c2s_SailorSummon)
end

-- 请求装备/更换水手
function SailorComponent:RequestSailorEquip(nSailorCategory, nSailorIndex, nSailorId)
    local nSailorInstanceId = GetSailorInstanceId(nSailorId)
    if nSailorInstanceId == INVALID_ID then
        logerror("RequestSailorEquip failed, cannot find sailor item, sailor_template_id =", nSailorId)
        return
    end
    local c2s_SailorEquip = {
        sailor_slot = {
            sub_category = nSailorCategory,
            slot_index = nSailorIndex
        },
        sailor_instance_id = nSailorInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SailorEquip, c2s_SailorEquip)
end

-- 请求水手升级
function SailorComponent:RequestSailorUpgrade(nSailorId, nCount, bUpgradeToTopLevel)
    local nSailorInstanceId = GetSailorInstanceId(nSailorId)
    local c2s_SailorUpgrade = {
        sailor_instance_id = nSailorInstanceId,
        count = nCount,
        upgrade_to_top_level = bUpgradeToTopLevel
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SailorUpgrade, c2s_SailorUpgrade)
end

-- 请求升级指定位置上水手
function SailorComponent:RequestEquippedSailorUpgrade(nSailorId, nCount, bUpgradeToTopLevel, nSailorCategory, nSlotIndex)
    local nGrade
    if bUpgradeToTopLevel then
        nGrade = MAX_GRADE
    else
        nGrade = ItemSystem:GetItemTemplate(nSailorId).nGrade + 1
    end
    local c2s_UpgradeEquippedSailor = {
        sailor = {{
            slot = {
                sub_category = nSailorCategory,
                slot_index = nSlotIndex
            },
            desired_grade = nGrade
        }},
        one_key_upgrade = false
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UpgradeEquippedSailor, c2s_UpgradeEquippedSailor)
end

-- 请求重置水手（至最低级）
function SailorComponent:RequestSailorDegrade(nSailorId, nCount)
    local nSailorInstanceId = GetSailorInstanceId(nSailorId)
    local c2s_SailorDegrade = {
        sailor_instance_id = nSailorInstanceId,
        count = nCount
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SailorDegrade, c2s_SailorDegrade)
end

-- 请求一键升级已装备水手
function SailorComponent:RequestUpgradeEquippedSailor(tbEquippedSailorUpgradeData)
    local tbSailors = {}
    for i, tbData in ipairs(tbEquippedSailorUpgradeData) do
        if tbData.nSailorId ~= tbData.nGradeUpgradeTo then
            table.insert(tbSailors, {
                slot = {
                    sub_category = tbData.nSailorCategory,
                    slot_index = tbData.nSlotIndex
                },
                desired_grade = tbData.nGradeUpgradeTo
            })
        end
    end
    local c2s_UpgradeEquippedSailor = {
        sailor = tbSailors,
        one_key_upgrade = true
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UpgradeEquippedSailor, c2s_UpgradeEquippedSailor)
end

-- 请求卸载所有水手
function SailorComponent:RequestSailorUnequipAll()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SailorUnequipAll)
end

function SailorComponent:RequestSailorUnequipCategory(nSailorCategory)
    local c2s_TheSameSailorUnequip =
    {
        sub_category = nSailorCategory
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_TheSameSailorUnequip, c2s_TheSameSailorUnequip)
end

-- 解锁水手槽位
function SailorComponent:RequestUnlockSailorSlot(nSailorCategory, nSlotIndex, bAutoExchange)
    local c2s_UnlockSailorSlot = {
        sailor_slot = {
            sub_category = nSailorCategory,
            slot_index = nSlotIndex
        },
        currency_auto_exchange = bAutoExchange
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UnlockSailorSlot, c2s_UnlockSailorSlot)
end

-- 请求一键装备水手套装
function SailorComponent:RequestSailorEquipOneKey(nSuitId)
    if (not nSuitId) or (nSuitId < 0) or (nSuitId > SailorSlotDataTable.RECOMMENDED_SAILOR_SUIT_COUNT) then
        logerror("[SailorComponent] RequestSailorEquipOneKey failed, nSuitId =", nSuitId)
        return
    end
    log("[SailorComponent] RequestSailorEquipOneKey, nSuitId =", nSuitId)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_ONE_KEY_EQUIP_SAILOR_STARTED)
    -- 需要先下阵所有水手
    self:RequestSailorUnequipAll()
    local tbCacheInfo = {}
    for nCategory, tbSlotInfoList in ipairs(self.tbSailorSlotData) do
        for nIndex, tbSlotInfo in pairs(tbSlotInfoList) do
            if tbSlotInfo.bUnlocked then
                local nOriginSailorId = SailorSlotDataTable:GetRecommendedSailorId(nSuitId, nCategory, nIndex)
                local nRecommendedSailorId = GetOptimalRecommendedSailorId(tbCacheInfo, nOriginSailorId)
                if nRecommendedSailorId ~= INVALID_ID then
                    self:RequestSailorEquip(nCategory, nIndex, nRecommendedSailorId)
                end
            end
        end
    end
end

-- 请求一键解锁所有未解锁水手槽位
function SailorComponent:RequestUnlockSailorSlotOneKey()
    for nCategory, tbSlotInfoList in ipairs(self.tbSailorSlotData) do
        for nIndex, tbSlotInfo in pairs(tbSlotInfoList) do
            if not tbSlotInfo.bUnlocked then
                self:RequestUnlockSailorSlot(nCategory, nIndex, false)
            end
        end
    end
end

return SailorComponent