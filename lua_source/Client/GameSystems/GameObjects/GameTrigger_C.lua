local luaclass = require("luaclass")
local GameTriggerClass = require("GameTrigger")
local GameTrigger_C = luaclass("GameTrigger_C", GameTriggerClass)
local TriggerResDataTable = require("TriggerResDataTable")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local BattleItemDataTable = require("BattleItemDataTable")
local GameTriggerType = require("GameTriggerType")
local FFAItemIni = require("FFAItemIni")
local BattleItemResDataTable = require("BattleItemResDataTable")

local BattleGameModeSystem_C = nil
local GRID_TYPE_OCEAN = EPiratesGridRegionType.Ocean
local GRID_TYPE_PORT = EPiratesGridRegionType.Port
GameTrigger_C.tbCustomProtoData = nil
-- local GameObjectSystem = nil

function GameTrigger_C:ParseCreateData(tbCreateData)
    local bRet = GameTrigger_C.super.ParseCreateData(self, tbCreateData)
    self.tbCustomProtoData = tbCreateData.tbCustomData
    return bRet
end

local function IsOcean(tbTransform)
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRegionType = GridTypeManager:GetRegionType(tbTransform.X, tbTransform.Y)
    local bIsOcean = nRegionType == GRID_TYPE_OCEAN or nRegionType == GRID_TYPE_PORT
    return bIsOcean
end

-- 场景中掉落物品，因为respath字符串太长，不适合在蓝图中RepNotify
local function ParseInitCustomData(self, tbInitCustomProtoData)
    if self.pUEActor == nil then
        logerror("GameTrigger_C ParseInitCustomData failed, pUEActor is nil")
        return
    end

    if(tbInitCustomProtoData == nil) then
        return
    end

    if BattleGameModeSystem_C == nil then
        BattleGameModeSystem_C = require("BattleGameModeSystem_C")
    end

    if self.nType == GameTriggerType.SceneItem then
        local tbItemResInfo = tbInitCustomProtoData.scene_item_info
        if(tbItemResInfo and tbItemResInfo.template_id > 0) then
            local tbItemData = BattleItemDataTable:GetTemplate(tbItemResInfo.template_id)
            local tbItemResData = BattleItemResDataTable:GetTemplate(tbItemData and tbItemData.nResId or 0, BattleGameModeSystem_C:GetDungeonId())
            
            if tbItemResData == nil then
                logerror("gametrigger set mesh failed, not find res ", tbItemResInfo.template_id)
                return
            end

            local szPawnClassName = tbItemResData.szDisplayClassName
            local szPawnMeshName
            if IsOcean(self.Location) then
                szPawnMeshName = tbItemResData.szOceanDisplayMeshName ~= nil and tbItemResData.szOceanDisplayMeshName ~= ""  
                    and tbItemResData.szOceanDisplayMeshName or tbItemResData.szDisplayMeshName
            else
                szPawnMeshName = tbItemResData.szDisplayMeshName
            end

            -- 单机本
            if GlobalVariableSystem_C:IsStandalone() then
                local Location = self:GetLocation()
                local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
                local nRegionType = GridTypeManager:GetRegionType(Location.X, Location.Y)
                
                local tbSceneItemIni  = FFAItemIni.tbSceneItem
                local nScale = (nRegionType == EPiratesGridRegionType.Land or nRegionType == EPiratesGridRegionType.Shore) 
                    and tbSceneItemIni.nLandMeshScale or tbSceneItemIni.nOceanMeshScale 
                self.pUEActor:SetScale(nScale)
            end
            self.pUEActor:SetMeshAndActor(szPawnMeshName, szPawnClassName)
        end
    end
end

function GameTrigger_C:OnActorCreated(pUEActor)
    GameTrigger_C.super.OnActorCreated(self, pUEActor)

    local nResId = self.nResId
    local tbTemplate = nil
    if nResId >= 0 and pUEActor then
        tbTemplate = TriggerResDataTable:GetTemplate(nResId)
        if(tbTemplate == nil) then
            log("GameTrigger_C:OnActorCreated failed, nTemplateId:", nResId)
            return
        end
        if pUEActor.SetEffectScale then
            pUEActor:SetEffectScale(tbTemplate.nScaleSize, tbTemplate.ScaleType)
        end
    end

    ParseInitCustomData(self, self.tbCustomProtoData)
    if not GlobalVariableSystem_C.bShowCharacter  then
        pUEActor:SetActorHiddenInGame(true)
    end
end

function GameTrigger_C:OnDelayDestroy()
	self.pUEActor:SetActorHiddenInGame(true)
end

function GameTrigger_C:OnRestoreObject(tbParam)
	self.pUEActor:SetActorHiddenInGame(false)
end

function GameTrigger_C:OnDestroy()
    GameTrigger_C.super.OnDestroy(self)
end

function GameTrigger_C:UnbindUEActor()
    -- log(string.format("GameTrigger_C:UnbindUEActor uniqueid = %d, instanceid=%d", self.nUniqueId, self:GetServerInstanceId()))
    GameTrigger_C.super.UnbindUEActor(self)
end

return GameTrigger_C
