-----------------------------------------------------
--Author       : Ran Jie
--Create Time  : 2019-01-29
--Description  : UPFFAFlagInfo
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPMapObj = require("UPMapObj")
local UPFFAFlagInfo = luaclass("UPFFAFlagInfo", UPMapObj)

-- import require
local UIResourceDef = require("UIResourceDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UISetUtils = require("UISetUtils")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleCoreAreaSystem = require("BattleCoreAreaSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local DungeonDataTable = require("DungeonDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")

local SELF_HIT_TEST_IN_VISIBLE = ESlateVisibility.SelfHitTestInvisible

--member veriable
UPFFAFlagInfo.bIsInUse = false
UPFFAFlagInfo.tbData = nil
UPFFAFlagInfo.nFlagLineId = nil
UPFFAFlagInfo.nFlagPointId = nil
UPFFAFlagInfo.MapOpFlagLineObj = nil
--debug
UPFFAFlagInfo.MapOpScript = nil
UPFFAFlagInfo.tbImageCache = {}
UPFFAFlagInfo.nImageIndex = 1

local ANCHOR_FULL_SCREEN = Anchors{Minimum=Vector2D{X=0, Y=0}, Maximum=Vector2D{X=1, Y=1}}
local GRID_TYPE_LAND = EPiratesGridRegionType.Land
-- local GRID_TYPE_OCEAN = EPiratesGridRegionType.Ocean
-- local GRID_TYPE_PORT = EPiratesGridRegionType.Port
-- local GRID_TYPE_SHORE = EPiratesGridRegionType.Shore
-- local NODE_POS_LIST = {Vector(), Vector(), Vector()}
local L10N_DISTANCE_FORMAT_TEXT = UISetUtils.GetTextByKey("FFA_FLAG_DISTANCE")
local pFlagLocation = Vector()

local function ShowShoreMark(self, tbMarkPosList, pSlateColor)
    for k, v in pairs(tbMarkPosList) do
        local pWidget = self.tbImageCache[self.nImageIndex]
        if not pWidget then
            pWidget = self.WidgetHelper:CreateWidget(Image)
            self.pWidgetRef.cvsFlag:AddChildToCanvas(pWidget)
            table.insert(self.tbImageCache, pWidget)
        end
        pWidget:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        local nX, nY = self.MapOpScript:CalculateUIMapLocation(v)
        self.pWidgetRef.cvsFlag:AddChildToCanvas(pWidget)
        pWidget.Slot:SetPosition(Vector2D{X = nX, Y = nY})
        pWidget.Slot:SetSize(Vector2D{X = 10, Y = 10})
        UISetUtils.SetImageBrushTint(pWidget, pSlateColor)
        self.nImageIndex = self.nImageIndex + 1
    end
end

local function DebugInfo(self, tbData)
    for k, v in pairs(self.tbImageCache) do
        v:SetVisibility(ESlateVisibility_Collapsed)
    end
    self.nImageIndex = 1
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local pSelfLocation = GamePlayerSelfHelper:Get():GetLocation()
    local nSelfRegionType = GridTypeManager:GetRegionType(pSelfLocation.X, pSelfLocation.Y)
    local nSelfLandId = nil
    local nTargetLandId = nil 

    if nSelfRegionType == GRID_TYPE_LAND then
        nSelfLandId = GridTypeManager:GetLandID(pSelfLocation.X, pSelfLocation.Y)
    end
    local nTargetRegionType = GridTypeManager:GetRegionType(tbData.X, tbData.Y)
    if nTargetRegionType == GRID_TYPE_LAND then
        nTargetLandId = GridTypeManager:GetLandID(tbData.X, tbData.Y)
    end
    log("nSelfLandId,nSelfRegionType,nTargetLandId,nTargetRegionType=",nSelfLandId,nSelfRegionType,nTargetLandId,nTargetRegionType)
    if nSelfLandId ~= nil and nSelfLandId > 0 then
        local bResult, tbSelfMarkPosList = GridTypeManager:GetMarkPositions(nSelfLandId, nSelfRegionType)
        if bResult then
            --debug
            ShowShoreMark(self, tbSelfMarkPosList, UIResourceDef.COLOR.RED.SLATE_COLOR)
            --
        end
        
    end
    if nTargetLandId ~= nil and nTargetLandId > 0 then
        local bResult, tbTargetMarkPosList = GridTypeManager:GetMarkPositions(nTargetLandId, nTargetRegionType)
        if bResult then
            --debug
            ShowShoreMark(self, tbTargetMarkPosList, UIResourceDef.COLOR.GREEN.SLATE_COLOR)
            --
        end
    end
end

local function CheckIsInCoreArea(self, nTargetX, nTargetY)
    local nDungeonId = BattleGameModeSystem.nDungeonId
    local tbDungeonTemplate = DungeonDataTable:GetTemplate(nDungeonId)
    local tbMapResData = UIMapResDataTable:GetTemplate(tbDungeonTemplate.nUIMapId)
    --logdebug("nTargetX, nTargetY=",nTargetX, nTargetY,tbMapResData.nCoreAreaSizeX / 2,tbMapResData.nCoreAreaSizeY / 2)
    return math.abs(nTargetX) <= tbMapResData.nCoreAreaSizeX / 2 and math.abs(nTargetY) <= tbMapResData.nCoreAreaSizeY / 2
end

--member function
function UPFFAFlagInfo:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    if(self.pWidgetRef == nil) then
        return
    end
    local pWidgetRef = self.pWidgetRef
    local ObjWidgetSlot = pWidgetRef.Slot
    --ObjWidgetSlot:SetAlignment(Vector2D{X = 0.5, Y = 0.5})
    ObjWidgetSlot:SetAnchors(ANCHOR_FULL_SCREEN)
    ObjWidgetSlot:SetAutoSize(false)
    pWidgetRef:SetVisibility(SELF_HIT_TEST_IN_VISIBLE)
    
    
    pFlagLocation.X = tbData.X
    pFlagLocation.Y = tbData.Y

    if GlobalVariableSystem.bDebugMapPath and self.MapOpScript then
        DebugInfo(self, tbData)
    end

    if tbData.bShowLine then
        self.pWidgetRef.dlFlagLine:SetVisibility(ESlateVisibility_HitTestInvisible)
        self.pWidgetRef.dlFlagLine:SetColorAndOpacity(tbData.pLinearColor)
        self.nFlagLineId = self.MapOpFlagLineObj:SetFlagLine(pFlagLocation, self.pWidgetRef.dlFlagLine)
        local bRegionVisible = true
        if CheckIsInCoreArea(self, tbData.X, tbData.Y) then
            bRegionVisible = BattleCoreAreaSystem:IsShowCoreArea()
        end
        local nCurrentMode = ControlModeSystem:GetCurrentModeType()
        bRegionVisible = nCurrentMode ~= ControlModeDef.TRANSPORTNEW and bRegionVisible or false
        self.MapOpFlagLineObj:SetTargetRegionVisible(bRegionVisible)
    else
        self.pWidgetRef.dlFlagLine:SetVisibility(ESlateVisibility_Collapsed)
    end
    if tbData.bShowPoint then
        self.pbFFAFlagPoint:ShowContent(tbData)
        self.nFlagPointId = self.MapOpFlagLineObj:AddFlagPoint(pWidgetRef.pbFFAFlagPoint, pFlagLocation, pWidgetRef.pbFFAFlagPoint.txtDistance, L10N_DISTANCE_FORMAT_TEXT)
    
    else
        self.pbFFAFlagPoint:HideContent()
    end
end

function UPFFAFlagInfo:HideContent()
    self.bIsInUse = false
    self.tbData = nil
    if(self.pWidgetRef == nil) then
        return
    end    
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    self.MapOpFlagLineObj:RemoveFlagLine()
    if self.nFlagPointId then
        self.MapOpFlagLineObj:RemoveFlagPoint(self.nFlagPointId)
        self.nFlagPointId = nil
    end
end

function UPFFAFlagInfo:GetUseState()
    return self.bIsInUse
end

function UPFFAFlagInfo:SetMapOp(pMapOpFlagLineObj)
    self.MapOpFlagLineObj = pMapOpFlagLineObj
end

---------------
function UPFFAFlagInfo:OnLoad()
    self.pbFFAFlagPoint = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbFFAFlagPoint)
end

return UPFFAFlagInfo
