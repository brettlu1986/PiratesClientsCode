-----------------------------------------------------
--File Name    : MapOpFFATeamMember.lua
--Author       : Ran Jie
--Description  : ffa队友显示
-----------------------------------------------------

local luaclass = require ("luaclass")
local MapOpBase = require("MapOpBase")
local MapOpFFATeamMember = luaclass("MapOpFFATeamMember",MapOpBase)


local MapObjType = require("MapObjType")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TeamHeadNameSystem = require("TeamHeadNameSystem")
local DCProto = require("DungeonCommonProtoNames")
local TeamWatchClientHelper = require("TeamWatchClientHelper")


local GET_ACTOR_UNIQUE_ID_FUNC = EngineExtActorShell.GetActorUniqueId

local SHOW_RANGE = Vector2D{X = 150, Y = 150}
local SHOW_OFFSET = Vector2D{X = -10, Y = 0}
local COLLAPSED = ESlateVisibility.Collapsed
local HIT_TEST_IN_VISIBLE = ESlateVisibility.HitTestInvisible

MapOpFFATeamMember.tbMemberObjs = {}
MapOpFFATeamMember.tbStaticData = {}

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
        if tbData.pUEActor then
            self.MapOpObj:RemoveContentPoint(GET_ACTOR_UNIQUE_ID_FUNC(tbData.pUEActor))
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

local function RefreshMemberObjPos(self)
    local SelfObj = GamePlayerSelfHelper:Get()
    local SelfInstanceId = SelfObj:GetServerInstanceId()
    local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo() 
    if not tbTeamInfo or not self.MapOpObj then
        return
    end
    --self:ResetObjPool(MapObjType.FFA_TEAM_MEMBER)
    CheckTeamMemberExist(self)
    for k, v in ipairs(tbTeamInfo) do
        local nInstanceId = v.nInstanceId
        if nInstanceId ~= SelfInstanceId then
            local tbMemberHeadNameData = TeamHeadNameSystem:GetMemberObjByInstanceId(nInstanceId)
            if tbMemberHeadNameData then
                local tbData = self.tbMemberObjs[nInstanceId]
                if not tbData then
                    tbData = {}
                    tbData.Obj = self:GetOneObj(MapObjType.FFA_TEAM_MEMBER)
                    self.tbMemberObjs[nInstanceId] = tbData
                end
                tbData.nIndex = v.nIndex
                tbData.nState = v.nState
                local ObjWidgetRef = tbData.Obj.pWidgetRef

                if tbData.nState == DCProto.TeamInfo_EState.DEAD then
                    ObjWidgetRef.ovlStateExParent:SetVisibility(COLLAPSED)
                    ObjWidgetRef.cvsRotation:SetVisibility(COLLAPSED)
                else
                    ObjWidgetRef.cvsRotation:SetVisibility(HIT_TEST_IN_VISIBLE)
                end
                local pUEActor = nil
                if tbMemberHeadNameData.tbGameObject then
                    pUEActor = tbMemberHeadNameData.tbGameObject.pUEActor
                else
                    pUEActor = tbMemberHeadNameData.tbDummyObject.pUEActor
                end
                if pUEActor then
                    if tbData.pUEActor and pUEActor ~= tbData.pUEActor then
                        self.MapOpObj:RemoveContentPoint(tbData.nUEActorId)
                        tbData.pUEActor = pUEActor
                        tbData.nUEActorId = self.MapOpObj:AddContentPoint(pUEActor, ObjWidgetRef, ObjWidgetRef.cvsRotation, ObjWidgetRef.ovlState, ObjWidgetRef.ovlStateEx, true)
                    elseif not tbData.pUEActor then
                        tbData.pUEActor = pUEActor
                        tbData.nUEActorId = self.MapOpObj:AddContentPoint(pUEActor, ObjWidgetRef, ObjWidgetRef.cvsRotation, ObjWidgetRef.ovlState, ObjWidgetRef.ovlStateEx, true)
                    end
                end 
                -- if not tbData.pUEActor and pUEActor then
                --     tbData.pUEActor = pUEActor
                --     self.MapOpObj:AddContentPoint(pUEActor, ObjWidgetRef, ObjWidgetRef.cvsRotation, ObjWidgetRef.ovlState, ObjWidgetRef.ovlStateEx, true)
                -- end
                tbData.Obj:ShowContent(tbData)
            end
        end
    end
end

local function OnMemberHeadNameObjChanged(self, nInstanceId, tbGameObject)
    local tbData = self.tbMemberObjs[nInstanceId]
    if self.MapOpObj and tbData and tbData.nUEActorId then
        --logdebug("OnMemberHeadNameObjChanged,objtype=",tbGameObject:GetObjectType())
        self.MapOpObj:RemoveContentPoint(tbData.nUEActorId)
        tbData.pUEActor = tbGameObject.pUEActor
        local ObjWidgetRef = tbData.Obj.pWidgetRef
        tbData.nUEActorId = self.MapOpObj:AddContentPoint(tbData.pUEActor, ObjWidgetRef, ObjWidgetRef.cvsRotation, ObjWidgetRef.ovlState, ObjWidgetRef.ovlStateEx, true)
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
--         if tbData.nUEActorId == nViewerUniqueId then
--             tbViewerData = tbData
--         else
--             self.MapOpObj:RemoveContentPoint(tbData.nUEActorId)
--             tbData.Obj:HideContent()
--         end
--     end
--     self.tbMemberObjs = {}
--     if nViewerInstanceId then
--         self.tbMemberObjs[nViewerInstanceId] = tbViewerData
--         logdebug("OnClearAllTeamHeadName:nViewerInstanceId, nViewerUniqueId=",nViewerInstanceId, nViewerUniqueId)
--     end
-- end

function MapOpFFATeamMember:Init(Parent)
    MapOpFFATeamMember.super.Init(self, Parent)
    
    local bShowInRange = true
    if self.bMMap then
        bShowInRange = false
    end
    local pViewerActor = self:GetCurrentViewerActor()
    if not pViewerActor then
        logerror("MapOpFFATeamMember:Init,ViewerActor is nil")
        return
    end
    local MapFFATeamMemberOp = self:GetOpObj(UIMapOpFFATeamMember)
    MapFFATeamMemberOp:InitParam(self.pWidgetRef, pViewerActor, self.pWidgetRef.cvsMapContent, bShowInRange, SHOW_RANGE, SHOW_OFFSET)
    TryResetPointActor(self, pViewerActor)
    self.pWidgetRef:RegisterOperation(MapFFATeamMemberOp)
    self.tbMemberObjs = {}
    -- self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_UPDATED, self, RefreshMemberObjPos)
    -- self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, self, OnMemberHeadNameObjChanged)

    RefreshMemberObjPos(self)
end

function MapOpFFATeamMember:Uninit()
    MapOpFFATeamMember.super.Uninit(self)
end

function MapOpFFATeamMember:Reinit()
    MapOpFFATeamMember.super.Reinit(self)
    if self.MapOpObj then
        local bShowInRange = true
        if self.bMMap then
            bShowInRange = false
        end
        local pViewerActor = self:GetCurrentViewerActor()
        if not pViewerActor then
            logerror("MapOpFFATeamMember:Reinit,ViewerActor is nil")
            return
        end
        self.MapOpObj:InitParam(self.pWidgetRef, pViewerActor, self.pWidgetRef.cvsMapContent, bShowInRange, SHOW_RANGE, SHOW_OFFSET)
        TryResetPointActor(self, pViewerActor)
    end
    self:TryMirrorMap()
    RefreshMemberObjPos(self)
    
end

function MapOpFFATeamMember:BindEvent()
    MapOpFFATeamMember.super.BindEvent(self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_UPDATED, self, RefreshMemberObjPos)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, self, OnMemberHeadNameObjChanged)
    --self.EventHelper:RegisterEvent(ClientEventDef.EV_CLEAR_ALL_TEAM_HEAD_NAME, self, OnClearAllTeamHeadName)
end

return MapOpFFATeamMember