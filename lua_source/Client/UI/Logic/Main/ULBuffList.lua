-----------------------------------------------------
--File Name    : ULBuffList.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-10
--Description  : 战斗界面Buff面板
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBuffList = luaclass("ULBuffList", UILogicBase)

local UIDef = require("UIDef")
local BattleBuffDataTable = require("BattleBuffDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

ULBuffList.tbItemList = nil
ULBuffList.tbFreeItemList = nil

local function Log(...)
    log("[ULBuffList]", ...)
end

local function AcquireBuffItem(self)
    local BuffItem = self.tbFreeItemList[1]
    if BuffItem then
        table.remove(self.tbFreeItemList, 1)
    else
        BuffItem = self.PrefabHelper:CreatePrefab(UIDef.UP_FFA_BUFF_ITEM)
    end
    self.pWidgetRef.rbBuffList:AddChild(BuffItem.pWidgetRef)
    Log("AcquireBuffItem", BuffItem, self.pWidgetRef.rbBuffList:GetChildrenCount())
    return BuffItem
end

local function ReleaseBuffItem(self, BuffItem)
    self.pWidgetRef.rbBuffList:RemoveChild(BuffItem.pWidgetRef)
    table.insert(self.tbFreeItemList, BuffItem)
    Log("ReleaseBuffItem", BuffItem, self.pWidgetRef.rbBuffList:GetChildrenCount())
end

-- 配置了Buff图标才显示
local function IsValidDisplayBuff(nTemplateId)
    local tbResTemplate = BattleBuffDataTable:GetResTemplate(nTemplateId)
    return tbResTemplate and tbResTemplate.szIconRes
end

local function OnBuffAdded(self, nInstanceId, nTemplateId, nLevel, nOverlapCount, nUpdateTime)
    if IsValidDisplayBuff(nTemplateId) then
        local BuffItem = AcquireBuffItem(self)
        Log(string.format("OnBuffAdded nInstanceId=%d, nTemplateId=%d", nInstanceId, nTemplateId))
        BuffItem:Start(nInstanceId, nTemplateId, nLevel, nOverlapCount, nUpdateTime)
        self.tbItemList[nInstanceId] = BuffItem
    end
end

local function OnBuffUpdated(self, nInstanceId, nOverlapCount, nUpdateTime)
    local BuffItem = self.tbItemList[nInstanceId]
    if BuffItem then
        Log(string.format("OnBuffUpdated nInstanceId=%d", nInstanceId))
        BuffItem:Update(nOverlapCount, nUpdateTime)
    end
end

local function OnBuffRemoved(self, nInstanceId)
    local BuffItem = self.tbItemList[nInstanceId]
    if BuffItem then
        BuffItem:Clear()
        Log(string.format("OnBuffRemoved nInstanceId=%d", nInstanceId))
        ReleaseBuffItem(self, BuffItem)
        self.tbItemList[nInstanceId] = nil
    end
end

function ULBuffList:OnBindEvent(EventHelper)
    local BuffComponentClient = GamePlayerSelfHelper:Get().BuffComponentClient
    EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffAddDelegate, OnBuffAdded, self)
    EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffRemoveDelegate, OnBuffRemoved, self)
    EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffRefreshDelegate, OnBuffUpdated, self)
end

function ULBuffList:OnLoad()
    self.tbItemList = {}
    self.tbFreeItemList = {}

    -- UI打开时恢复已添加的Buff
    local BuffComponentClient = GamePlayerSelfHelper:Get().BuffComponentClient
    local tbBuffs = BuffComponentClient:GetAllBuffs()
    for _, tbBuff in pairs(tbBuffs) do
        OnBuffAdded(self, tbBuff.nInstanceId, tbBuff.nTemplateId, tbBuff.nLevel, tbBuff.nOverlapCount, tbBuff.nUpdateTime)
    end
end

function ULBuffList:OnPawnDie()
    Log("OnPawnDie")
    for nInstanceId,_ in pairs(self.tbItemList) do
        OnBuffRemoved(self, nInstanceId)
    end
end

return ULBuffList
