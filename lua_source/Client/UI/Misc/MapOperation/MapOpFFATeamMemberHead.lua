-----------------------------------------------------
--File Name    : MapOpFFATeamMemberHead.lua
--Author       : Ran Jie
--Create Time  : 2018-9-12
--Description  : MapOpFFATeamMemberHead 队友玩家头顶名字片在屏幕边缘的显示
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFATeamMemberHead = luaclass("MapOpFFATeamMemberHead", MapOpBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local MapObjType = require("MapObjType")
local TeamHeadNameSystem = require("TeamHeadNameSystem")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanMovementStateType = require("HumanMovementStateType")
local DCProto = require("DungeonCommonProtoNames")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local UISetUtils = require("UISetUtils")

--local ANCHOR_CENTER = Anchors{Minimum=Vector2D{X=0.0, Y=0.0}, Maximum=Vector2D{X=0.0, Y=0.0}}
local ANCHOR_CENTER = Anchors{Minimum=Vector2D{X=0.5, Y=0.5}, Maximum=Vector2D{X=0.5, Y=0.5}}
local LEFT_OFFSET = 110
local TOP_OFFSET = 40
local BOTTOM_OFFSET = 130
local RIGHT_OFFSET = 60
local BORDER_LEFT_TOP = Vector2D{X = LEFT_OFFSET, Y = TOP_OFFSET}
local BORDER_RIGHT_BOTTOM = Vector2D{X = 1920, Y = 1080}
local SHOW_DISTANCE_MAX = 1000
local HEAD_OFFSET = 100


--local GET_ACTOR_UNIQUE_ID_FUNC = EngineExtActorShell.GetActorUniqueId
local HIT_TEST_IN_VISIBLE = ESlateVisibility.HitTestInvisible
local COLLAPSED = ESlateVisibility.Collapsed
local Divide_Vector2DFloat = KismetMathLibrary.Divide_Vector2DFloat

MapOpFFATeamMemberHead.tbMemberObjs = {}

local function CheckTeamMemberExist(self)
    local tbRemoveTeamMember = {}
    for k, v in pairs(self.tbMemberObjs) do
        local tbMemberHeadNameData = TeamHeadNameSystem:GetMemberObjByInstanceId(k)
        if not tbMemberHeadNameData then
            table.insert(tbRemoveTeamMember, k)
        end
    end
    for k, v in ipairs(tbRemoveTeamMember) do
        local tbData = self.tbMemberObjs[v]
        if tbData.nPointIndex then
            self.MapOpObj:RemoveContentPoint(tbData.nPointIndex)
        end
        if tbData.Obj then
            tbData.Obj:HideContent()
        end
        self.tbMemberObjs[v] = nil
    end
end

local function TryResetPointActor(self, pUEActor)
    for k, v in pairs(self.tbMemberObjs) do
        --if v.pUEActor == pUEActor then
            v.pUEActor = nil
            v.nPointIndex = nil
        --end
    end
end

local function OnFFATeamInfoUpdated(self, tbFlagPoints)
    if not self.MapOpObj then
        return
    end
    local tbSelfObj = GamePlayerSelfHelper:Get()
    local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo()
    if not tbTeamInfo then
        return
    end
    self:TryMirrorMap()
    local HeadNameCanvasPanel = self.pWidgetRef.cvsHeadName
    local PlaneHeadNameCanvasPanel = self.pWidgetRef.cvsPlaneHeadName
    --self:ResetObjPool(MapObjType.FFA_TEAM_MEMBER)
    CheckTeamMemberExist(self)
    local bPlaneState = false
    local pSelfAttachUEActor = nil
    if tbSelfObj:IsHuman() and tbSelfObj.HumanMovementStateComponent and tbSelfObj.HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.InPlane_State then
        bPlaneState = true
        pSelfAttachUEActor = tbSelfObj.pUEActor:GetAttachParentActor()
    end
    
    for k, v in ipairs(tbTeamInfo) do
        
        local nInstanceId = v.nInstanceId
        local tbMemberHeadNameData = TeamHeadNameSystem:GetMemberObjByInstanceId(nInstanceId)
        if tbMemberHeadNameData then
            local tbData = self.tbMemberObjs[nInstanceId]
            local ObjWidget = nil
            if not tbData and v.nState ~= DCProto.TeamInfo_EState.DEAD then
                tbData = {}
                tbData.Obj = self:GetOneObj(MapObjType.FFA_TEAM_MEMBER, false, 10, HeadNameCanvasPanel)
                tbData.Obj.pWidgetRef.cvsRotation:SetVisibility(HIT_TEST_IN_VISIBLE)
                self.tbMemberObjs[nInstanceId] = tbData

                tbData.PlaneObj = self:CreateOneObj(MapObjType.FFA_TEAM_MEMBER, false, 10, PlaneHeadNameCanvasPanel)
                tbData.PlaneObj.pWidgetRef.Slot:SetAnchors(ANCHOR_CENTER)
                tbData.PlaneObj.pWidgetRef.cvsRotation:SetVisibility(COLLAPSED)
                tbData.PlaneObj:HideContent()
            end
            if tbData then
                ObjWidget = tbData.Obj.pWidgetRef
                tbData.nIndex               = v.nIndex
                tbData.nState               = v.nState
                tbData.bTransparentColor    = true
            
                local pUEActor = nil
                local pHeadInfoWidgetRef = nil
                if tbMemberHeadNameData.tbGameObject then
                    pUEActor = tbMemberHeadNameData.tbGameObject.pUEActor
                    local HeadWidget = tbMemberHeadNameData.tbGameObject.HeadInfoComponent:GetTeammateHeadWidget()
                    if HeadWidget then
                        pHeadInfoWidgetRef =  HeadWidget.pWidgetRef
                    else
                        log("MapOpFFATeamMemberHead:OnFFATeamInfoUpdated:HeadWidget is nil, nInstanceId=",nInstanceId, tbMemberHeadNameData.tbGameObject:GetName())
                    end
                else
                    pUEActor = tbMemberHeadNameData.tbDummyObject.pUEActor
                    local HeadWidget = tbMemberHeadNameData.tbDummyObject.HeadInfoComponent:GetTeammateHeadWidget()
                    if HeadWidget then
                        pHeadInfoWidgetRef = HeadWidget.pWidgetRef
                    else
                        log("MapOpFFATeamMemberHead:OnFFATeamInfoUpdated:HeadWidget is nil, nInstanceId=",nInstanceId, tbMemberHeadNameData.tbDummyObject:GetName())
                    end
                end
                if bPlaneState and pUEActor and pUEActor:GetAttachParentActor() == pSelfAttachUEActor then
                    --logdebug("111111111111111111111111111")
                    tbData.UILocation = {X = 0, Y = 200}
                    tbData.PlaneObj:ShowContent(tbData)
                    tbData.PlaneObj:SetName(v.name)
                    ObjWidget.vbxHead:SetVisibility(ESlateVisibility_Collapsed)
                else
                    if tbData.PlaneObj:GetUseState() then
                        tbData.PlaneObj:HideContent()
                    end
                    if pUEActor and pHeadInfoWidgetRef and (not tbData.pUEActor or tbData.pUEActor ~= pUEActor) then
                        --logdebug("22222222222222222222")
                        tbData.pUEActor = pUEActor
                        if tbData.nPointIndex then
                            self.MapOpObj:RemoveContentPoint(tbData.nPointIndex)
                        end
                        local OldPointIndex = tbData.nPointIndex
                        tbData.nPointIndex = self.MapOpObj:AddContentPoint(pUEActor, ObjWidget, ObjWidget.bdrDistanceBg, ObjWidget.txtDistance, pHeadInfoWidgetRef, pHeadInfoWidgetRef.bdrDistanceBg, pHeadInfoWidgetRef.txtDistance, ObjWidget.cvsRotation, false)
                        log("OnFFATeamInfoUpdated:AddContentPoint tbData.nPointIndex=",tbData.nPointIndex, OldPointIndex,v.name)
                    end
                    ObjWidget.vbxHead:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
                end
                tbData.Obj:ShowContent(tbData)
            end
        end
    end
end

local function OnMemberHeadNameObjChanged(self, nInstanceId, tbGameObject)
    local tbData = self.tbMemberObjs[nInstanceId]
    if self.MapOpObj and tbData and tbData.nPointIndex then
        --logdebug("OnMemberHeadNameObjChanged,objtype=",tbGameObject:GetObjectType())
        --local OldPointIndex = tbData.nPointIndex
        log("OnMemberHeadNameObjChanged,objtype=",tbGameObject:GetObjectType(),tbData.nPointIndex,tbGameObject:GetName())
        self.MapOpObj:RemoveContentPoint(tbData.nPointIndex)
        tbData.pUEActor = tbGameObject.pUEActor
        local ObjWidget = tbData.Obj.pWidgetRef
        local HeadWidget = tbGameObject.HeadInfoComponent:GetTeammateHeadWidget()
        if not HeadWidget then
            log("MapOpFFATeamMemberHead:OnMemberHeadNameObjChanged:HeadWidget is nil, nInstanceId=",nInstanceId, tbGameObject:GetName())
            return
        end
        local pHeadInfoWidgetRef = HeadWidget.pWidgetRef
        tbData.nPointIndex = self.MapOpObj:AddContentPoint(tbData.pUEActor, ObjWidget, ObjWidget.bdrDistanceBg, ObjWidget.txtDistance, pHeadInfoWidgetRef, pHeadInfoWidgetRef.bdrDistanceBg, pHeadInfoWidgetRef.txtDistance, ObjWidget.cvsRotation, false)
        --logdebug("OnMemberHeadNameObjChanged:AddContentPoint tbData.nPointIndex=",tbData.nPointIndex,OldPointIndex)
    end
end

local function HideTeamMemberDistance(self, bHideDistance, nInstanceId)
    local tbMemberObj = self.tbMemberObjs[nInstanceId]
    if tbMemberObj then
        tbMemberObj.Obj:HideDistance(bHideDistance)
    end
end

local function OnMovementStateChanged(self, tbCharacter, nOldState, nNewState)
    if not tbCharacter or tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    if nNewState == HumanMovementStateType.InPlane_State then
        --TeamHeadNameSystem:HideName(true)
        TeamHeadNameSystem:HideDistance(true)
        for k, v in pairs(self.tbMemberObjs) do
            local tbObjPrefab = v.Obj
            tbObjPrefab:HideDistance(true)
        end
    elseif nNewState == HumanMovementStateType.Falling_State then
        --TeamHeadNameSystem:HideName(false)
        TeamHeadNameSystem:HideDistance(false)
        for k, v in pairs(self.tbMemberObjs) do
            local tbObjPrefab = v.Obj
            tbObjPrefab:HideDistance(false)
        end
    end
end

local function OnTeamHeadNameRemoved(self, nInstanceId)
    local tbData = self.tbMemberObjs[nInstanceId]
    if self.MapOpObj and tbData and tbData.nPointIndex then
        log("MapOpFFATeamMemberHead:OnTeamHeadNameRemoved,objtype=",nInstanceId)
        self.MapOpObj:RemoveContentPoint(tbData.nPointIndex)
        tbData.Obj:HideContent()
        self.tbMemberObjs[nInstanceId] = nil
    end
end

-- local function OnClearAllTeamHeadName(self)
--     if not self.tbMemberObjs then
--         return
--     end
--     local nViewerInstanceId = nil
--     local nViewerUniqueId = nil
--     local tbViewePlayer = TeamWatchClientHelper.GetCurrentWatchPlayer()
    
--     if tbViewePlayer then
--         nViewerInstanceId = tbViewePlayer:GetServerInstanceId()
--         nViewerUniqueId = GET_ACTOR_UNIQUE_ID_FUNC(tbViewePlayer:GetModelActor())
--     end
--     local tbViewerData = nil
--     for k, tbData in pairs(self.tbMemberObjs) do
--         if tbData.nPointIndex == nViewerUniqueId then
--             tbViewerData = tbData
--         else
--             self.MapOpObj:RemoveContentPoint(tbData.nPointIndex)
--             tbData.Obj:HideContent()
--         end
--     end
--     self.tbMemberObjs = {}
--     if nViewerInstanceId then
--         self.tbMemberObjs[nViewerInstanceId] = tbViewerData
--         logdebug("OnClearAllTeamHeadName:nViewerInstanceId, nViewerUniqueId=",nViewerInstanceId, nViewerUniqueId)
--     end
-- end
local function OnWatchBattleMovementStateChanged(self, nCurrentState)
    if not self.MapOpObj then
        return
    end
    if nCurrentState == HumanMovementStateType.Crawl_State then
        self.MapOpObj:SetHeadOffset(0)
    else
        self.MapOpObj:SetHeadOffset(HEAD_OFFSET)
    end
end

function MapOpFFATeamMemberHead:Init(Parent)
    MapOpFFATeamMemberHead.super.Init(self, Parent)
    local nViewPortScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    local pViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    local pRealViewPortSize = Divide_Vector2DFloat(pViewportSize, nViewPortScale)
    BORDER_RIGHT_BOTTOM.X = pRealViewPortSize.X - RIGHT_OFFSET
    BORDER_RIGHT_BOTTOM.Y = pRealViewPortSize.Y - BOTTOM_OFFSET
    self.tbMemberObjs = {}
    local pWidgetRef = self.pWidgetRef
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        logerror("MapOpFFATeamMemberHead:Init,ViewerActor is nil")
        return
    end
    local MapOpFFAObj = self:GetOpObj(UIMapOpFFATeamMemberHead)
    MapOpFFAObj:InitParam(pWidgetRef, pViewerActor, pWidgetRef.cvsHeadName, BORDER_LEFT_TOP, BORDER_RIGHT_BOTTOM, SHOW_DISTANCE_MAX, HEAD_OFFSET, self.Parent.Owner.nCutoutSpacerWidth)
    MapOpFFAObj:SetDistanceFormatText(UISetUtils.GetTextByKey("FFA_FLAG_DISTANCE"))
    TryResetPointActor(self, pViewerActor)
    self.pWidgetRef:RegisterOperation(MapOpFFAObj)
    -- self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_UPDATED, self, OnFFATeamInfoUpdated)
    -- self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, self, OnMemberHeadNameObjChanged)
    -- self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
    -- self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_REMOVED, self, OnTeamHeadNameRemoved)
    OnFFATeamInfoUpdated(self)
end


function MapOpFFATeamMemberHead:Uninit()
    --logdebug("MapOpFFATeamMemberHead:Uninit")
    MapOpFFATeamMemberHead.super.Uninit(self)
    self.pWidgetRef:UnregisterAllOperation()
end

function MapOpFFATeamMemberHead:Reinit()
    MapOpFFATeamMemberHead.super.Reinit(self)
    if self.MapOpObj then
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            logerror("MapOpFFATeamMemberHead:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(self.pWidgetRef, pViewerActor, self.pWidgetRef.cvsHeadName, BORDER_LEFT_TOP, BORDER_RIGHT_BOTTOM, SHOW_DISTANCE_MAX, HEAD_OFFSET, self.Parent.Owner.nCutoutSpacerWidth)
        TryResetPointActor(self, pViewerActor)
        local nSelfInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
        local nViewerInstanceId = self:GetCurrentViewerObj():GetServerInstanceId()
        if nViewerInstanceId ~= nSelfInstanceId then
            HideTeamMemberDistance(self, true, nViewerInstanceId)
        end
        if self.Parent.tbLastWatchObj then
            HideTeamMemberDistance(self, false, self.Parent.tbLastWatchObj:GetServerInstanceId())
        end
    end
end

function MapOpFFATeamMemberHead:BindEvent()
    MapOpFFATeamMemberHead.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_UPDATED, self, OnFFATeamInfoUpdated)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, self, OnMemberHeadNameObjChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_REMOVED, self, OnTeamHeadNameRemoved)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BATTLE_MOVEMENT_STATE_CHANGE, self, OnWatchBattleMovementStateChanged)
    --self.EventHelper:RegisterEvent(ClientEventDef.EV_CLEAR_ALL_TEAM_HEAD_NAME, self, OnClearAllTeamHeadName)
end

return MapOpFFATeamMemberHead
