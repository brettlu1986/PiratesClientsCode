-----------------------------------------------------
--File Name    : HomelandSystem.lua
--Author       : zhiyuan
--Create Time  : 2019-04-16
--Description  : 家园系统
-----------------------------------------------------
local HomelandSystem = {}

local PlayerSelfHelper = require("GamePlayerSelfHelper")
local HomelandSceneDataTable = require("HomelandSceneDataTable")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local HomelandModeDef = require("HomelandModeDef")
local ProcedureTool = require("ProcedureTool")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local DelayTimer = require("DelayTimer")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local LandmarkStatusDef = require("LandmarkStatusDef")
local BlockTypeDataTable = require("BlockTypeDataTable")
local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")

local tbSubSystems = {}

HomelandSystem.bHasLoadData = nil
HomelandSystem.nMode = nil

HomelandSystem.tbLandmarkUpgradeTimers = nil
HomelandSystem.bIsInHomeland = nil

local tbHomelandSceneSystem = nil

-----------------------------------------subsystem local function---------------------------------------------

local function GetHomelandSceneSystem()
    if tbHomelandSceneSystem == nil then
        tbHomelandSceneSystem = require("HomelandSceneSystem")
    end
    return tbHomelandSceneSystem
end

local function Register(szSubSystemName)
    local SubSystem = require(szSubSystemName)
    if SubSystem == nil then
        error("Homeland subSystem is invalid! "..szSubSystemName)
    end
    tbSubSystems[szSubSystemName] = SubSystem
    return SubSystem
end

local function RegisterAllSubSystem(self)
    Register("HomelandTestSubSystem")
    Register("HomelandPlayerStateSystem")
    Register("HomelandExchangeSystem")
    Register("HomelandItemSystem")
    Register("HomelandBuildingAppearanceSystem")
    Register("HomelandTreasureSystem")
    Register("HomelandCGSystem")
    Register("HomelandSubProcedureSystem")
end

local function InitAllSubSystem(self)
    for k, v in pairs(tbSubSystems) do
        if v.Init ~= nil then
            v:Init()
            v.OwnerSystem = self
        end
    end
end

local function UninitAllSubSystem(self)
    for k, v in pairs(tbSubSystems) do
        if v.Uninit ~= nil then
            v:Uninit()
        end
    end
end

local function AllSubSystemsEnterHomeland()
    for k, v in pairs(tbSubSystems) do
        if v.OnEnterHomeland ~= nil then
            v:OnEnterHomeland()
        end
    end
end

local function AllSubSystemsLeaveHomeland()
    for k, v in pairs(tbSubSystems) do
        if v.OnLeaveHomeland ~= nil then
            v:OnLeaveHomeland()
        end
    end
end

-----------------------------------------logic local function---------------------------------------------

local function GetHomelandComponent()
    local PlayerSelf = PlayerSelfHelper:Get()
    local HomelandComponent = PlayerSelf.HomelandComponent
    if HomelandComponent == nil then
        error("GetHomelandComponent failed!HomelandComponent == nil!")
    end
    return HomelandComponent
end

local function GetCurrentSceneId()
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetCurrentSceneId()
end

local function GetCurrentSceneData()
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetCurrentSceneData()
end

local function GetSceneData(nSceneId)
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetSceneData(nSceneId)
end

local function GetBlockData(nBlockId)
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetBlockData(nBlockId)
end

-- local function IsBlockBought(nBlockId)
--     local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
--     if not tbBlockTemplate then
--         error("Cannot find block template!"..nBlockId)
--     end
--     local HomelandComponent = GetHomelandComponent()
--     return HomelandComponent:IsBlockBought(nBlockId)
-- end

local function RequestEnterHomeland(self)
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_EnterHomeland)
end

local function EnterHomeland(self)
    local nSceneId = self:GetCurrentSceneId()
    local tbTemplate = HomelandSceneDataTable:GetSceneTemplate(nSceneId)
    local tbParam = {szHomelandBg = tbTemplate.szBackground}
    
    if ProcedureTool:EnterHomeland(tbParam) then
        RequestEnterHomeland(self)
        AllSubSystemsEnterHomeland()
        self.bIsInHomeland = true
    end
end

local function DoLeaveHomeland(self)
    AllSubSystemsLeaveHomeland(self)
    local HomelandComponent = GetHomelandComponent()
    HomelandComponent:SetNotFirstEntry()
    ProcedureTool:EnterLobby()
    self.bIsInHomeland = false
end

local function LeaveHomeland(self)
    EventManager:OnFireEvent(ClientEventDef.EV_HOMELAND_PRE_LEAVE_PROCEDURE_BEGIN)
end

local function RefreshOneBlockInNormalMode(self, tbBlockData)
    local HomelandSceneSystem = GetHomelandSceneSystem()
    local nBlockId = tbBlockData.nBlockId
    local nBlockType = tbBlockData.nBlockType
    local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
    if tbBlockData.bIsLandmark then
        local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
        local tbLandmarkTemplate = LandmarkBuildingTypeDataTable:GetTemplate(tbBlockTemplate.nDefaultLandmarkType)
        HomelandSceneSystem:SetBlockEnable(nBlockId, tbLandmarkTemplate.bCanTrigger)
    elseif tbBlockTypeTemplate.bIsDork then
        HomelandSceneSystem:SetBlockEnable(nBlockId, true)
    else
        HomelandSceneSystem:SetBlockEnable(nBlockId, false)
    end
    HomelandSceneSystem:ShowBlock(nBlockId, false)
end


local function RefreshOneBlockInBuildMode(self, tbBlockData)
    local HomelandSceneSystem = GetHomelandSceneSystem()
    local nBlockId = tbBlockData.nBlockId
    local nBlockType = tbBlockData.nBlockType
    local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
    if tbBlockData.bIsLandmark then
        local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
        local tbLandmarkTemplate = LandmarkBuildingTypeDataTable:GetTemplate(tbBlockTemplate.nDefaultLandmarkType)
        HomelandSceneSystem:SetBlockEnable(nBlockId, tbLandmarkTemplate.bCanTrigger)

        HomelandSceneSystem:ShowBlock(nBlockId, tbBlockTypeTemplate.bShowColor)
    elseif tbBlockTypeTemplate.bIsDork then
        HomelandSceneSystem:SetBlockEnable(nBlockId, true)
        HomelandSceneSystem:ShowBlock(nBlockId, tbBlockTypeTemplate.bShowColor)
    else
        if tbBlockData.bUnlock then
            HomelandSceneSystem:SetBlockEnable(nBlockId, true)
            HomelandSceneSystem:ShowBlock(nBlockId, true)
        else
            HomelandSceneSystem:SetBlockEnable(nBlockId, false)
            HomelandSceneSystem:ShowBlock(nBlockId, false)
        end
    end
end

local function CheckBlockDisplay(self, nBlockId)
    local nMode = self.nMode
    local tbBlockData = GetBlockData(nBlockId)
    if nMode == HomelandModeDef.NORMAL then
        RefreshOneBlockInNormalMode(self, tbBlockData)
    elseif nMode == HomelandModeDef.BUILD then
        RefreshOneBlockInBuildMode(self, tbBlockData)
    end
end


local function SetBlockBought(self, nBlockId)
    local nCurrentSceneId = GetCurrentSceneId()
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    if not tbBlockTemplate then
        error("Cannot find block template!"..nBlockId)
    end
    if tbBlockTemplate.bHasDefaultLandmark then
        error("block has landmark! not need buy!"..nBlockId)
    end
    if not tbBlockTemplate.bNeedBuy then
        error("block is free, not need buy!"..nBlockId)
    end
    if tbBlockTemplate.nSceneId ~= nCurrentSceneId then
        error("Cannot change block ! not current scene! nSceneId:"..tbBlockTemplate.nSceneId..", nBlockId: "..nBlockId)
    end
    local HomelandComponent = GetHomelandComponent()
    HomelandComponent:SetBlockBought(nBlockId)
    EventManager:OnFireEvent(ClientEventDef.EV_HOMELAND_BUY_BLOCK, nBlockId)
    CheckBlockDisplay(self, nBlockId)
end

local function PlaceItemBuilding(nBlockId, nItemInstanceId, nRotationId)
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    if not tbBlockTemplate then
        error("Cannot find block template!"..nBlockId)
    end
    if tbBlockTemplate.bHasDefaultLandmark then
        error("block has landmark! cannot place item!"..nBlockId)
    end
    local HomelandComponent = GetHomelandComponent()
    local tbBlockData = GetBlockData(nBlockId)
    if tbBlockData == nil then
        error("Cannot find block data!"..nBlockId)
    end
    if tbBlockTemplate.bNeedBuy then
        if not tbBlockData.bBought then
            error("block need buy!"..nBlockId)
        end
    end
    if tbBlockData.nItemInstanceId ~= nil then
        error("block already has building!nBlockId:"..nBlockId..", item instanceid:"..tbBlockData.nItemInstanceId..", building id"..", tbBlockData.nBuildingId")
    end
    HomelandComponent:PlaceItemBuilding(nBlockId, nItemInstanceId, nRotationId)
    EventManager:OnFireEvent(ClientEventDef.EV_PLACE_ITEM_BUILDING, nBlockId, nItemInstanceId, nRotationId)
end

local function CheckSceneUnlock(nLandmarkType, nGrade)
    local HomelandComponent = GetHomelandComponent()
    local tbSceneTemplates = HomelandSceneDataTable:GetAllSceneTemplates()
    for _, tbSceneTemplate in pairs(tbSceneTemplates) do
        local nUnlockLandmarkType = tbSceneTemplate.nUnlockLandmarkType
        local nUnlockLandmarkGrade = tbSceneTemplate.nUnlockLandmarkGrade
        local nPrice = tbSceneTemplate.nPrice
        if nUnlockLandmarkType == nLandmarkType and nUnlockLandmarkGrade == nGrade and (nPrice == nil or nPrice <= 0 )then
            HomelandComponent:InitSceneData(tbSceneTemplate.nId, nil)
        end
    end
end

local function CheckBlockUnlock(self, nLandmarkType, nGrade)
    local HomelandComponent = GetHomelandComponent()
    local tbSceneAllBlockTemplates = HomelandSceneDataTable:GetAllSceneBlockTemplates()
    for nSceneId, tbSceneBlockTemplates in pairs(tbSceneAllBlockTemplates) do
        for _, tbBlockTemplate in ipairs(tbSceneBlockTemplates) do
            local nBlockId = tbBlockTemplate.nId
            if tbBlockTemplate.bNeedUnlock then
                local nUnlockLandmarkType = tbBlockTemplate.nUnlockLandmarkType
                local nUnlockLandmarkGrade = tbBlockTemplate.nUnlockLandmarkGrade
                if nLandmarkType == nUnlockLandmarkType and nGrade == nUnlockLandmarkGrade
                    and (not HomelandComponent:IsBlockUnlock(nBlockId)) then
                    HomelandComponent:SetBlockUnlock(nBlockId)
                    CheckBlockDisplay(self, nBlockId)
                end
            end
        end
    end
end

local function LandmarkUpgradeComplete(self, nLandmarkType, nGrade, nStatus, nRemainSeconds)
    local HomelandComponent = GetHomelandComponent()
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nCompleteTime = now + nRemainSeconds
    HomelandComponent:LandmarkUpgradeComplete(nLandmarkType, nGrade, nStatus, nCompleteTime)
    CheckSceneUnlock(nLandmarkType, nGrade)
    CheckBlockUnlock(self, nLandmarkType, nGrade)
    EventManager:OnFireEvent(ClientEventDef.EV_LANDMARK_UPGRADE_COMPLETE, nLandmarkType, nGrade)

    --logdebug("self.tbLandmarkUpgradeTimers size", #self.tbLandmarkUpgradeTimers)
end

local function ClearScene(self, nSceneId)
    local tbSceneData = GetCurrentSceneData()
    for _, tbBlockData in pairs(tbSceneData) do
        if tbBlockData.nItemInstanceId ~= nil and tbBlockData.nItemInstanceId > 0 then
            self:RemoveItemBuildingOnBlock(tbBlockData.nBlockId)
        end
    end
end

local function SetCurrentSceneId(self, nSceneId, bRecover)
    local HomelandComponent = GetHomelandComponent()

    HomelandComponent:SetCurrentSceneId(nSceneId)
    if not bRecover then
        ClearScene(self, nSceneId)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_SWITCH_HOMELAND_SCENE, nSceneId)
end

local function RequestHomelandData(self)
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GetHomeland)
end

local function RefreshNormalModeTrigger(self)
    local tbSceneData = GetCurrentSceneData()
    for _, tbBlockData in pairs(tbSceneData) do
        RefreshOneBlockInNormalMode(self, tbBlockData)
    end
end

local function RefreshBuildModeTrigger(self)
    local tbSceneData = GetCurrentSceneData()
    for _, tbBlockData in pairs(tbSceneData) do
        RefreshOneBlockInBuildMode(self, tbBlockData)
    end
end

local function ChangeMode(self, nMode)
    self.nMode = nMode
    if nMode == HomelandModeDef.NORMAL then
        RefreshNormalModeTrigger(self)
    elseif nMode == HomelandModeDef.BUILD then
        RefreshBuildModeTrigger(self)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_CHANGE_HOMELAND_MODE, nMode)
end

local function CheckUpgradeSuccess(self)
    local HomelandComponent = GetHomelandComponent()
    local tbLandmarkDatas = HomelandComponent:GetAllLandmarkData()
    for k, v in pairs(tbLandmarkDatas) do
        if v.nStatus == LandmarkStatusDef.UPGRADING then
            self:CheckLandmarkBuilding(k, v.nCompleteTime)
        end
    end
end

local function OnSceneLoadEnd(self)
    ChangeMode(self, HomelandModeDef.NORMAL)
    CheckUpgradeSuccess(self)
end

local function AddLandmarkUpgradeTimer(self, nLandmarkType, nRemainSecond)
    if self.tbLandmarkUpgradeTimers[nLandmarkType] ~= nil then
        return
    end
    local FunUpgradeCallback = function()
        self:RequestLandmarkUpgradeComplete(nLandmarkType)
        self.tbLandmarkUpgradeTimers[nLandmarkType] = nil
    end
    local DelayHandle = DelayTimer:DelayRun(FunUpgradeCallback, nRemainSecond)
    self.tbLandmarkUpgradeTimers[nLandmarkType] = DelayHandle
end

local function ClearAllLandmarkUpgradeTimer(self)
    if self.tbLandmarkUpgradeTimers ~= nil then
        for k, v in pairs(self.tbLandmarkUpgradeTimers) do
            if v then
                DelayTimer:ClearTimer(v)
                self.tbLandmarkUpgradeTimers[k] = nil
            end
        end
    end
    self.tbLandmarkUpgradeTimers = {}
end

-----------------------------------------System Init UnInit---------------------------------------------

function HomelandSystem:Init()
    self.bIsInHomeland = false
    self.bHasLoadData = false
    self.tbLandmarkUpgradeTimers = {}
    RegisterAllSubSystem(self)
    InitAllSubSystem(self)
    self.nMode = HomelandModeDef.NORMAL
    EventManager:BindEventMethod(ClientEventDef.EV_HOMELAND_LOADED, self, OnSceneLoadEnd)
    EventManager:BindEventMethod(ClientEventDef.EV_HOMELAND_PRE_LEAVE_PROCEDURE_FINISHED, self, DoLeaveHomeland)
    return true
end

function HomelandSystem:Uninit()
    self.bHasLoadData = false
    EventManager:UnBindEventMethod(ClientEventDef.EV_HOMELAND_LOADED, self, OnSceneLoadEnd)
    EventManager:UnBindEventMethod(ClientEventDef.EV_HOMELAND_PRE_LEAVE_PROCEDURE_FINISHED, self, DoLeaveHomeland)
    UninitAllSubSystem(self)
    ClearAllLandmarkUpgradeTimer(self)
end

-----------------------------------------给外部模块的调用接口---------------------------------------------

-- 获得一个子系统
-- @param 子系统名字
-- @return 子系统
function HomelandSystem:GetSubSystem(szSubSystemName)
    local SubSystem = tbSubSystems[szSubSystemName]
    if SubSystem == nil then
        error("HomelandSystem GetSubSystem failed!".. szSubSystemName)
    end
    return SubSystem
end

-- 获得当前场景的所有地块数据
-- @return tbCurrentSceneData
-- local tbBlockData = {}
-- tbBlockData.nBlockId = 1
-- tbBlockData.nBlockType = 1
-- tbBlockData.bIsLandmark = true
-- tbBlockData.bCanPlaceBuilding = true
-- tbBlockData.bUnlock = true
-- tbBlockData.bBought = true
-- tbBlockData.nBuildingId = 1
-- tbBlockData.nItemInstanceId = 1
-- tbBlockData.nRotationId = 1
-- tbBlockData.nStatus = 1
-- tbCurrentSceneData[tbBlockData.nBlockId] = tbBlockData
function HomelandSystem:GetCurrentSceneData()
    return GetCurrentSceneData()
end

-- 获得某个场景的所有地块数据
function HomelandSystem:GetSceneData(nSceneId)
    return GetSceneData(nSceneId)
end

-- 获得当前场景id
-- @return 当前场景id
function HomelandSystem:GetCurrentSceneId()
    return GetCurrentSceneId()
end

-- 获得某个地块的数据
-- @param nBlockId 地块id
-- @return tbBlockData 地块数据
-- local tbBlockData = {}
-- tbBlockData.nBlockId = 1
-- tbBlockData.nBlockType = 1
-- tbBlockData.bIsLandmark = true
-- tbBlockData.bCanPlaceBuilding = true
-- tbBlockData.bUnlock = true
-- tbBlockData.bBought = true
-- tbBlockData.nBuildingId = 1
-- tbBlockData.nItemInstanceId = 1
-- tbBlockData.nRotationId = 1
-- tbBlockData.nStatus = 1
function HomelandSystem:GetBlockData(nBlockId)
    return GetBlockData(nBlockId)
end

-- 获得当前家园模式
-- @return 当前模式 见HomelandModeDef
function HomelandSystem:GetCurrentMode()
    return self.nMode
end

-- 地块是否在当前场景中
function HomelandSystem:IsBlockInCurrentScene(nBlockId)
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    local nCurrentSceneId = GetCurrentSceneId()
    return tbBlockTemplate.nSceneId == nCurrentSceneId
end

-- 获得标志性建筑数据
function HomelandSystem:GetLandmarkData(nLandmarkType)
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetLandmarkData(nLandmarkType)
end

-- 获得标志性建筑等级
function HomelandSystem:GetLandmarkGrade(nLandmarkType)
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetLandmarkGrade(nLandmarkType)
end


-- 检查标志性建筑升级
function HomelandSystem:CheckLandmarkBuilding(nLandmarkType, nCompleteTime)

    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRemainSecond = nCompleteTime - now
    if nRemainSecond > 0 then
        AddLandmarkUpgradeTimer(self, nLandmarkType, nRemainSecond)
    else
        self:RequestLandmarkUpgradeComplete(nLandmarkType)
    end
end

-- 场景是否已解锁
function HomelandSystem:IsSceneUnlock(nSceneId)
    local bUnlock = false
    local tbSceneTemplate = HomelandSceneDataTable:GetSceneTemplate(nSceneId)
    local nUnlockLandmarkType = tbSceneTemplate.nUnlockLandmarkType
    local nUnlockLandmarkGrade = tbSceneTemplate.nUnlockLandmarkGrade
    if nUnlockLandmarkGrade ~= nil and nUnlockLandmarkGrade > 0 then
        local nCurrentGrade = self:GetLandmarkGrade(nUnlockLandmarkType)
        if nCurrentGrade >= nUnlockLandmarkGrade then
            bUnlock = true
        end
    else
        bUnlock = true
    end
    return bUnlock
end

-- 场景是否可以使用
function HomelandSystem:IsSceneCanUse(nSceneId)
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:IsSceneCanUse(nSceneId)
end

-- 获得当前场景标志性建筑的地块id
function HomelandSystem:GetLandmarkBlockIdInCurrentScene(nLandmarkType)
    local tbCurrentSceneDatas = GetCurrentSceneData()
    for nBlockId, tbBlockData in pairs(tbCurrentSceneDatas) do
        if tbBlockData.bIsLandmark then
            local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
            if tbBlockTemplate.nDefaultLandmarkType == nLandmarkType then
                return nBlockId
            end
        end
    end
    return nil
end

-- 移除一个地块上的建筑
function HomelandSystem:RemoveItemBuildingOnBlock(nBlockId)
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    if not tbBlockTemplate then
        error("Cannot find block template!"..nBlockId)
    end
    if tbBlockTemplate.bHasDefaultLandmark then
        error("block has landmark! cannot place item!"..nBlockId)
    end
    local HomelandComponent = GetHomelandComponent()
    local tbBlockData = GetBlockData(nBlockId)
    if tbBlockData == nil then
        error("Cannot find block data!"..nBlockId)
    end
    HomelandComponent:RemoveItemBuilding(nBlockId)
    EventManager:OnFireEvent(ClientEventDef.EV_REMOVE_ITEM_BUILDING, nBlockId)
end

-- 某场景是否有建造数据
function HomelandSystem:SceneHasBuildData(nSceneId)
    local tbDatas = GetSceneData(nSceneId)
    for nBlockId, tbBlockData in pairs(tbDatas) do
        if tbBlockData.nItemInstanceId then
            return true
        end
    end
    return false
end

-- 是否第一次进入
function HomelandSystem:IsFirstEntry()
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:IsFirstEntry()
end

-- 是否在家园里
function HomelandSystem:IsInHomeland()
    return self.bIsInHomeland
end

-----------------------------------------玩家不同的操作的方法---------------------------------------------

-- 进入家园场景
function HomelandSystem:EnterHomeland()
    if not self.bHasLoadData then
        RequestHomelandData(self)
    else
        EnterHomeland(self)
    end
end

-- 离开家园场景
function HomelandSystem:LeaveHomeland()
    LeaveHomeland(self)
end

-- 请求购买场景
-- @param nSceneId 场景id
function HomelandSystem:RequestPurchaseScene(nSceneId)
    local c2s_PurchaseScene =
    {
        scene_id = nSceneId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_PurchaseScene, c2s_PurchaseScene)
end

-- 请求切换场景
-- @param nSceneId 切换到的场景id
-- @param bRecover true表示恢复之前的场景布局，false表示不恢复
function HomelandSystem:RequestSetCurrentSceneId(nSceneId, bRecover)
    local c2s_SwitchScene =
    {
        scene_id = nSceneId,
        recover_layout = bRecover
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SwitchScene, c2s_SwitchScene)
end

-- 请求标志性建筑升级
function HomelandSystem:RequestLandmarkUpgrade(nLandmarkType)
    local c2s_LandmarkUpgrade =
    {
        landmark_id = nLandmarkType
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_LandmarkUpgrade, c2s_LandmarkUpgrade)
end

-- 请求标志性建筑升级成功
function HomelandSystem:RequestLandmarkUpgradeComplete(nLandmarkType)
    local c2s_LandmarkUpgradeComplete =
    {
        landmark_id = nLandmarkType
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_LandmarkUpgradeComplete, c2s_LandmarkUpgradeComplete)
end

-- 请求建造
function HomelandSystem:RequestPlaceItemBuilding(nBlockId, nItemInstanceId, nRotationId)
    local c2s_PlaceBuilding =
    {
        index = nBlockId,
        instance_id = nItemInstanceId,
        rotation_id = nRotationId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_PlaceBuilding, c2s_PlaceBuilding)
end

-- 请求拆除
function HomelandSystem:RequestRemoveItemBuilding(nBlockId)
    local c2s_DestroyBuilding =
    {
        index = nBlockId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_DestroyBuilding, c2s_DestroyBuilding)
end

-- 请求买地块
function HomelandSystem:RequestBuyBlock(nBlockId)
    local c2s_PurchaseBlock =
    {
        index = nBlockId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_PurchaseBlock, c2s_PurchaseBlock)
end

-- 切换模式
function HomelandSystem:ChangeMode(nModeId)
    ChangeMode(self, nModeId)
end

-----------------------------------------处理server发过来的道具数据同步---------------------------------------------------
-- 同步家园数据
function HomelandSystem:OnSyncHomeland(tbHomelandData)
    self.bHasLoadData = true
    local HomelandComponent = GetHomelandComponent()
    HomelandComponent:InitData(tbHomelandData)
    EnterHomeland(self)
end

-- 切换家园场景
function HomelandSystem:OnSwitchScene(nSceneId, bRecover)
    SetCurrentSceneId(self, nSceneId, bRecover)
end

-- 标志性建筑升级开始
function HomelandSystem:OnLandmarkUpgradeBegin(nLandmarkType, nRemainSeconds)
    local HomelandComponent = GetHomelandComponent()
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nCompleteTime = now + nRemainSeconds
    HomelandComponent:LandmarkBeginUpgrade(nLandmarkType, LandmarkStatusDef.UPGRADING, nCompleteTime)
    self:CheckLandmarkBuilding(nLandmarkType, nCompleteTime, true)
    EventManager:OnFireEvent(ClientEventDef.EV_LANDMARK_UPGRADE_BEGIN, nLandmarkType, nCompleteTime)
end

-- 标志性建筑升级完成
function HomelandSystem:OnLandmarkUpgradeComplete(tbLandmarkData)
    LandmarkUpgradeComplete(self, tbLandmarkData.id, tbLandmarkData.grade, tbLandmarkData.status, tbLandmarkData.remain_seconds)
end

-- 建造装饰物
function HomelandSystem:OnPlaceBuilding(nBlockId, nItemInstanceId, nRotationId)
    PlaceItemBuilding(nBlockId, nItemInstanceId, nRotationId)
end

-- 拆除装饰物
function HomelandSystem:OnDestroyBuilding(nBlockId)
    self:RemoveItemBuildingOnBlock(nBlockId)
    local HomelandSceneSystem = GetHomelandSceneSystem()
    HomelandSceneSystem:RemoveBuilding(nBlockId)
end

-- 购买场景
function HomelandSystem:OnPurchaseScene(nSceneId)
    local HomelandComponent = GetHomelandComponent()
    HomelandComponent:InitSceneData(nSceneId, nil)
    EventManager:OnFireEvent(ClientEventDef.EV_HOMELAND_PURCHASE_SCENE, nSceneId)
end

-- 购买地块
function HomelandSystem:OnPurchaseBlock(nBlockId)
    SetBlockBought(self, nBlockId)
end

return HomelandSystem
