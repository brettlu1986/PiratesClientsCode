-----------------------------------------------------
--File Name    : TeamHeadNameSystem.lua
--Author       : Ran Jie
--Create Time  : 2019-01-23
--Description  : 组队头顶名字片
-----------------------------------------------------
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local SelfEventHelper = require("SelfEventHelper")
local UEActorHelper = require("UEActorHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local DummyResDataTable = require("DummyResDataTable")
local DCProto = require("DungeonCommonProtoNames")
local HumanMovementStateType = require("HumanMovementStateType")
local DelayTimer = require("DelayTimer")
local GameObjectTypeDef = require("GameObjectTypeDef")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local HeadInfoDef = require("HeadInfoDef")
local FriendSystem = require("FriendSystem")
local Timer = require("Timer")

local TeamHeadNameSystem = {}

local TEAM_HEAD_DUMMY_TEMPLATE_ID = 3002
local TEAM_HEAD_DUMMY_BP_CLASS = ""
local DUMMY_INSTANCE_ID_START = -1000000
local ATTACHMENT_RULE = EAttachmentRule.KeepRelative
local DEAD_DISAPPEAR_DELAY_TIMER = 15
local WAIT_TIMER = "FinishTimer"

-- local tbNameWidgetLocationConfig = {}
-- tbNameWidgetLocationConfig[HumanMovementStateType.UpRight_State] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Crouch_State] = "HeadInfoCrouchLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Crawl_State] = "HeadInfoCrawlLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Dying_State] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.InPlane_State] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Parachutine_State] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Falling_State] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Roll_State] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Driving_State] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Jumping_SpeelWall] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Swimming] = "HeadInfoUpRightLoc"
-- tbNameWidgetLocationConfig[HumanMovementStateType.Vehicle] = "HeadInfoRideLoc"

TeamHeadNameSystem.tbTeamMembers = nil
TeamHeadNameSystem.EventHelper = nil
TeamHeadNameSystem.nMemberCount = 0
TeamHeadNameSystem.nDummyIndex = DUMMY_INSTANCE_ID_START
TeamHeadNameSystem.bHideAll = nil
TeamHeadNameSystem.bHideName = nil
TeamHeadNameSystem.bHideDistance = nil
TeamHeadNameSystem.tbMemberDeadHandles = nil

TeamHeadNameSystem.bReadyCheckRelation = false
TeamHeadNameSystem.nModeTeamCount = nil
-- local function RefreshHeadInfoLocation(self, tbPlayer, nNewState)
--     if tbPlayer:IsHuman() then
--         local pUEActor = tbPlayer.pUEActor
--         local nServerInstanceId = tbPlayer:GetServerInstanceId()
--         if tbPlayer.HeadInfoComponent and self.tbTeamMembers[nServerInstanceId]then
--             local szConfigName = tbNameWidgetLocationConfig[nNewState]
--             local pVector = pUEActor[szConfigName]
--             tbPlayer.HeadInfoComponent:SetRelativeLoaction(pVector)
--         end
--     end
-- end

local function ChangeHeadNameObject(self, tbOldObj, tbNewObj, nInstanceId)
    if tbOldObj then
        tbOldObj.HeadInfoComponent:SetVisibility(false)
    end
    if tbNewObj and tbNewObj.bValid and tbNewObj.pUEActor then
        tbNewObj.HeadInfoComponent:SetVisibility(true)
        self.EventHelper:FireEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, nInstanceId, tbNewObj)
    end

end

local function GetGameObjectByDummyInstanceId(self, nDummyInstanceId)
    for k, v in pairs(self.tbTeamMembers) do
        if v.tbDummyObject and v.tbDummyObject:GetServerInstanceId() == nDummyInstanceId then
            return k, v
        end
    end
end

local function CreateDummyObj(self, szName, bVisible)
    local nDummyIndex = self.nDummyIndex
    local _, pDummyActor = UEActorHelper:CreateActor(TEAM_HEAD_DUMMY_BP_CLASS, nil,
                            nil, nil, nil, nil, nDummyIndex)
    if not pDummyActor then
        error("TeamHeadNameSystem:CreateDummyObj failed! pDummyActor is nil")
    end
    local tbInitProtoData = {}
    tbInitProtoData.nTemplateId = TEAM_HEAD_DUMMY_TEMPLATE_ID
    local tbDummyObject = GameObjectSystem:BindDummyByReplicatedData(pDummyActor, nDummyIndex, tbInitProtoData)
    tbDummyObject:SetName(szName)
    local PlayerHeadInfo2DComponent = tbDummyObject.HeadInfoComponent
    PlayerHeadInfo2DComponent:CreateWidget()
    PlayerHeadInfo2DComponent:CreateTeammateHeadWidget()
    PlayerHeadInfo2DComponent:SetVisibility(bVisible)
    log("TeamHeadNameSystem:CreateDummyObj, tbDummyObject, nDummyIndex, Name=", tbDummyObject, nDummyIndex, szName,ExtendBlueprintFunctions.GetObjectUniqueID(tbDummyObject.pUEActor))
    nDummyIndex = nDummyIndex - 1
    self.nDummyIndex = nDummyIndex
    return tbDummyObject
end


local function RequestToRefreshRelation(self)
    self.bReadyCheckRelation = true
    Timer.StopOwnerTimer(self, WAIT_TIMER)
    local BattleTeamComponent = GamePlayerSelfHelper:Get().BattleTeamComponent
    local tbTeamPlayersInfo = BattleTeamComponent.tbTeamPlayersInfo
    self.EventHelper:FireEvent(ClientEventDef.EV_UPDATE_TEAMMATE_RELATION, tbTeamPlayersInfo.tbPlayerIds)
end

local function RefreshRelationWidgetParam(self, tbObject, tbInfo)
    if tbObject and tbObject.HeadInfoComponent then 
        local HeadInfoComponent = tbObject.HeadInfoComponent
        if not HeadInfoComponent:GetTeammateHeadWidget() then
            HeadInfoComponent:CreateTeammateHeadWidget()
        end 
        local tbParams = {}
        tbParams.nType = HeadInfoDef.Type.RELATION
        tbParams.tbInfo = tbInfo
        HeadInfoComponent:RefreshHeadWidget(tbParams)
    end
end

local function OnUpdateHeadRelationVisible(self)
    
    local FriendComponent = FriendSystem:GetComponent()
    if not FriendComponent then return end

    local BattleTeamComponent = GamePlayerSelfHelper:Get().BattleTeamComponent
    local tbTeamRelation = FriendComponent:GetTeamRelationInfo()
    if tbTeamRelation == nil then return end
    for nPlayerId, tbInfo in pairs(tbTeamRelation) do  
        local nInstanceId = BattleTeamComponent:GetInstanceIdByPlayerId(nPlayerId)
        for nMemberServerInsId, tbMemberData in pairs(self.tbTeamMembers) do
            if nInstanceId and nInstanceId == nMemberServerInsId then  
                RefreshRelationWidgetParam(self, tbMemberData.tbGameObject, tbInfo)
                RefreshRelationWidgetParam(self, tbMemberData.tbDummyObject, tbInfo)
            end
        end
    end
end


local function TeamInfoChangeForCheckRelation(self)
    local bMembersReady = true
    for nMemberServerInsId, tbMemberData in pairs(self.tbTeamMembers) do
        local HeadInfoComponent = nil
        if tbMemberData and tbMemberData.tbGameObject then
            HeadInfoComponent = tbMemberData.tbGameObject.HeadInfoComponent
        else  
            HeadInfoComponent = tbMemberData.tbDummyObject.HeadInfoComponent
        end
        if not HeadInfoComponent or not HeadInfoComponent:IsReady() then
            bMembersReady = false 
            break
        end
    end
    local BattleTeamComponent = GamePlayerSelfHelper:Get().BattleTeamComponent
    local tbBattleTeamInfo = BattleTeamComponent.tbBattleTeamInfo 
    if bMembersReady and tbBattleTeamInfo and self.bReadyCheckRelation == false then
        Timer.StartOwnerTimer(self, WAIT_TIMER, function()
            RequestToRefreshRelation(self)
        end, HeadInfoDef.WaitTeamMaxTime, false)

        if tbBattleTeamInfo.nPlayerCount and self.nModeTeamCount == nil then  
            self.nModeTeamCount = tbBattleTeamInfo.nPlayerCount
        end
        if tbBattleTeamInfo.TeamInfos then  
            local nRepTeamCount = #tbBattleTeamInfo.TeamInfos
            if nRepTeamCount == self.nModeTeamCount then
                RequestToRefreshRelation(self)
            end
        end
    end

    if self.bReadyCheckRelation then  
        OnUpdateHeadRelationVisible(self)
    end
end

local function OnMemberActorCreate(self, tbGameObject)

    if self.bHideAll  then
        return
    end

    if tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerOther then 
        local nServerInstanceId = tbGameObject:GetServerInstanceId()
        local tbMemberData = self.tbTeamMembers[nServerInstanceId]
        if tbMemberData and not tbMemberData.tbGameObject then
            log("TeamHeadNameSystem:OnMemberActorCreate:nServerInstanceId=", nServerInstanceId, tbGameObject:GetName())
            if  (tbGameObject:IsDead() or tbMemberData.nState == DCProto.TeamInfo_EState.DEAD) --[[and not self.tbMemberDeadHandles[tbGameObject:GetServerInstanceId()] --]]then
                return
            end
            --logdebug("OnMemberActorCreate:nServerInstanceId=",nServerInstanceId,tbGameObject:GetObjectType())
            tbMemberData.tbGameObject = tbGameObject
            if tbGameObject and tbGameObject.HeadInfoComponent then
                local HeadInfoComponent = tbGameObject.HeadInfoComponent
                --logdebug("HeadInfoComponent:CreateHeadWidget1,objecttype=",tbGameObject:GetObjectType())
                if not HeadInfoComponent:GetTeammateHeadWidget() then
                    HeadInfoComponent:CreateTeammateHeadWidget()
                end
                HeadInfoComponent:SetVisibility(true)
                local tbParams = {}
                tbParams.nType = HeadInfoDef.Type.NAME
                tbParams.nInstanceId = tbGameObject:GetServerInstanceId()
                tbParams.nIndex = tbMemberData.nIndex
                tbParams.szName = tbMemberData.szName
                tbParams.nState = tbMemberData.nState
                HeadInfoComponent:RefreshHeadWidget(tbParams)
                --HeadInfoComponent:HideTeammateName(self.bHideName)
                HeadInfoComponent:HideTeammateDistance(self.bHideDistance)
            end

            local tbDummyObject = tbMemberData.tbDummyObject
            if not tbDummyObject or not isvalidhandle(tbDummyObject.pUEActor) then
                log("TeamHeadNameSystem:OnMemberActorCreate,CreateDummyObj=", nServerInstanceId, tbGameObject:GetName())
                local pLocation = tbGameObject:GetLocation()
                local pRotation = tbGameObject:GetRotation()
                tbDummyObject = CreateDummyObj(self, tbMemberData.szName, false)
                tbDummyObject:SetLocation(pLocation.X, pLocation.Y, pLocation.Z)
                tbDummyObject:SetRotation(0, pRotation.Yaw, 0)
                tbMemberData.tbDummyObject = tbDummyObject
            end
            tbDummyObject.HeadInfoComponent:SetVisibility(false)
            TeamInfoChangeForCheckRelation(self)
            self.EventHelper:FireEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, nServerInstanceId, tbGameObject)
        end
    end

    -- if tbGameObject:IsHuman() then
    --     local nState = tbGameObject.HumanMovementStateComponent:GetCurrentState()
    --     RefreshHeadInfoLocation(self, tbGameObject, nState)
    -- end
end

local function OnMemberActorDestroy(self, tbGameObject)
    local nGameObjectType = tbGameObject:GetObjectType()
    if self.bHideAll or nGameObjectType ~= GameObjectTypeDef.PlayerOther and nGameObjectType ~= GameObjectTypeDef.Dummy then
        return
    end
    local nServerInstanceId = tbGameObject:GetServerInstanceId()
    local tbMemberData = self.tbTeamMembers[nServerInstanceId]
    if tbMemberData and tbMemberData.tbGameObject and nGameObjectType == GameObjectTypeDef.PlayerOther then
        log("TeamHeadNameSystem:OnMemberActorDestroy PlayerOther:nServerInstanceId=", nServerInstanceId, tbGameObject:GetName())
        tbMemberData.tbGameObject = nil
        if  (tbGameObject:IsDead() or tbMemberData.nState == DCProto.TeamInfo_EState.DEAD) --[[and not self.tbMemberDeadHandles[tbGameObject:GetServerInstanceId()]--]] then
            return
        end
        local tbDummyObject = tbMemberData.tbDummyObject
        --logdebug("OnMemberActorDestroy,nServerInstanceId=",nServerInstanceId)
        if tbDummyObject and tbDummyObject.bValid and tbDummyObject.pUEActor then
            log("TeamHeadNameSystem:OnMemberActorDestroy, tbDummyObject is valid,nServerInstanceId=",nServerInstanceId)
            local CurrentLocation = tbGameObject:GetLocation()
            tbDummyObject:SetLocation(CurrentLocation.X, CurrentLocation.Y, CurrentLocation.Z)
            local CurrentRotation = tbGameObject:GetRotation()
            tbDummyObject:SetRotation(CurrentRotation.Pitch, CurrentRotation.Yaw, CurrentRotation.Roll)
            tbDummyObject.HeadInfoComponent:SetVisibility(true)
            self.EventHelper:FireEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_OBJ_CHANGED, nServerInstanceId, tbDummyObject)
        end
    elseif nGameObjectType == GameObjectTypeDef.Dummy then
        log("TeamHeadNameSystem:OnMemberActorDestroy Dummy:nServerInstanceId=", nServerInstanceId, tbGameObject:GetName())
        local _, tbGameObjectInvalidDummy = GetGameObjectByDummyInstanceId(self, nServerInstanceId)
        if tbGameObjectInvalidDummy then
            tbGameObjectInvalidDummy.tbDummyObject = nil
            log("TeamHeadNameSystem:OnMemberActorDestroy Dummy, tbDummyObject = nil",ExtendBlueprintFunctions.GetObjectUniqueID(tbGameObject.pUEActor))
        end
    end
    
end

local function HideObjHeadWidget(self, nInstanceId)
    local tbMemberData = self.tbTeamMembers[nInstanceId]
    local tbGameObject = tbMemberData.tbGameObject
    local tbDummyObject = tbMemberData.tbDummyObject
    if tbGameObject and tbGameObject.HeadInfoComponent then
        tbGameObject.HeadInfoComponent:SetVisibility(false)
    end
    if tbDummyObject then
        if GameObjectSystem:FindByInstanceId(tbDummyObject:GetServerInstanceId()) then
            --GameObjectSystem:DestroyByInstanceId(tbDummyObject:GetServerInstanceId(), false)
            GameObjectSystem:DestroyUEActorByServerId(tbDummyObject:GetServerInstanceId())
        end
        tbMemberData.tbDummyObject = nil
    end
end


local function CheckTeamMemberExistNow(self, nInstanceId)
    local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo()
    if not tbTeamInfo then
        return false
    end
    for k, v in ipairs(tbTeamInfo) do
        if v.nInstanceId == nInstanceId then
            return true
        end
    end
    return false
end

local function HideTeamMemberDistance(self, bHideDistance, nInstanceId)
    local tbMemberData = self.tbTeamMembers[nInstanceId]
    if tbMemberData then
        local tbGameObject = tbMemberData.tbGameObject
        local tbDummyObject = tbMemberData.tbDummyObject
        local HeadInfoComponent = nil
        if tbGameObject and tbGameObject.HeadInfoComponent then
            HeadInfoComponent = tbGameObject.HeadInfoComponent
            HeadInfoComponent:HideTeammateDistance(bHideDistance)
        end
        if tbDummyObject and tbDummyObject.HeadInfoComponent then
            HeadInfoComponent = tbDummyObject.HeadInfoComponent
            HeadInfoComponent:HideTeammateDistance(bHideDistance)
        end
    end

end

local function DeadDisappearDelayFunc(self, nInstanceId)
    local tbMemberData = self.tbTeamMembers[nInstanceId]
    if tbMemberData then
        local tbDummyObject = tbMemberData.tbDummyObject
        local tbGameObject = tbMemberData.tbGameObject
        if tbGameObject and tbGameObject.HeadInfoComponent then
            tbGameObject.HeadInfoComponent:SetVisibility(false)
        end
        if tbDummyObject and tbDummyObject.HeadInfoComponent then
            tbDummyObject.HeadInfoComponent:SetVisibility(false)
        end
    end
    self.tbMemberDeadHandles[nInstanceId] = nil
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_TEAM_HEAD_NAME_REMOVED, nInstanceId)
end

local function TryClearInvalidTeamMemberData(self)
    local tbRemoveMember = {}
    for k, v in pairs(self.tbTeamMembers) do
        if not CheckTeamMemberExistNow(self, k) then
            table.insert(tbRemoveMember, k)
        end
    end

    for k, v in pairs(tbRemoveMember) do
        HideObjHeadWidget(self, v)
        self.tbTeamMembers[v] = nil
    end
    self.nMemberCount = self.nMemberCount - #tbRemoveMember
end

local function ClearAllTeamMemberData(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_CLEAR_ALL_TEAM_HEAD_NAME)
    for k, v in pairs(self.tbTeamMembers) do
        HideObjHeadWidget(self, k)
    end
    self.tbTeamMembers = {}
end

local function OnFFATeamInfoChanged(self)
    if self.bHideAll then
        return
    end
    local tbTeamInfo = TeamWatchClientHelper.GetCurrentTeamInfo()
    if not tbTeamInfo then
        return
    end

    --logdebug("OnFFATeamInfoChanged,self.nMemberCount,#rTeamInfo=",self.nMemberCount,#tbTeamInfo)
    if self.nMemberCount > #tbTeamInfo - 1 then
        TryClearInvalidTeamMemberData(self)
    end
    local tbSelfObj = GamePlayerSelfHelper:Get()
    local nSelfInstanceId = tbSelfObj:GetServerInstanceId()


    local pSelfAttachUEActor = nil
    if tbSelfObj:IsHuman() and tbSelfObj.HumanMovementStateComponent and tbSelfObj.HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.InPlane_State then
        pSelfAttachUEActor = tbSelfObj.pUEActor:GetAttachParentActor()
    end
    --logdebug("OnFFATeamInfoChanged,nSelfInstanceId=",nSelfInstanceId,tbSelfObj:GetName())
    local tbTeamMembers = self.tbTeamMembers

    for k, v in ipairs(tbTeamInfo) do
        local nInstanceId = v.nInstanceId
        local nIndex = v.nIndex

        if nInstanceId ~= nSelfInstanceId then
            
            local tbMemberData = tbTeamMembers[nInstanceId]
            local HeadInfoComponent = nil
            --logdebug("OnFFATeamInfoChanged,nInstanceId=",nInstanceId,tbSelfObj:GetName(),nSelfInstanceId, v.nState)
            local tbParams = {}
            tbParams.nType = HeadInfoDef.Type.NAME
            tbParams.nInstanceId = nInstanceId
            tbParams.nIndex = nIndex
            tbParams.szName = v.name
            tbParams.nState = v.nState

            if not tbMemberData then
                tbMemberData = {}
                --队友object
                local tbFindGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
                --logdebug("OnFFATeamInfoChanged,tbGameObject=",tbFindGameObject,nInstanceId)
                --创建队友的dummy obj
                local bVisible = true
                if tbFindGameObject and tbFindGameObject.HeadInfoComponent and tbFindGameObject.pUEActor then
                    --logdebug("name=",tbFindGameObject:GetName())
                    bVisible = false
                end

                local tbDummyObject = CreateDummyObj(self, v.name, bVisible)
                tbDummyObject:SetLocation(v.nPlayerX, v.nPlayerY, v.nPlayerZ)
                tbDummyObject:SetRotation(0, v.nPlayerYaw, 0)
                tbMemberData.tbDummyObject = tbDummyObject

                --logdebug("OnFFATeamInfoChanged,tbGameObject=",tbGameObject,nInstanceId)
                if tbFindGameObject and tbFindGameObject.HeadInfoComponent then
                    HeadInfoComponent = tbFindGameObject.HeadInfoComponent
                    --logdebug("HeadInfoComponent:CreateTeammateHeadWidget,objecttype=",tbFindGameObject:GetObjectType())
                    HeadInfoComponent:CreateTeammateHeadWidget()
                    HeadInfoComponent:SetVisibility(true)
                    tbMemberData.tbGameObject = tbFindGameObject
                else
                    HeadInfoComponent = tbDummyObject.HeadInfoComponent
                end

                --index
                tbMemberData.nIndex = nIndex
                tbTeamMembers[nInstanceId] = tbMemberData
                self.nMemberCount = self.nMemberCount + 1
            --end
            else
                local tbGameObject = tbMemberData.tbGameObject
                local tbDummyObject = tbMemberData.tbDummyObject
                if tbDummyObject == nil then
                    log("OnFFATeamInfoChanged,tbDummyObject is nil, recreate dummy object")
                    local bCreateVisible = false
                    if not tbGameObject then
                        bCreateVisible = true
                    end
                    tbDummyObject = CreateDummyObj(self, v.name, bCreateVisible)
                    tbDummyObject:SetLocation(v.nPlayerX, v.nPlayerY, v.nPlayerZ)
                    tbDummyObject:SetRotation(0, v.nPlayerYaw, 0)
                    tbMemberData.tbDummyObject = tbDummyObject
                    
                    --return
                end
                if v.nState == DCProto.TeamInfo_EState.OFFLINE --[[or v.nState == DCProto.TeamInfo_EState.DEAD--]] then
                    if tbGameObject and tbGameObject.HeadInfoComponent then
                        HeadInfoComponent = tbGameObject.HeadInfoComponent
                    else
                        HeadInfoComponent = tbDummyObject.HeadInfoComponent
                    end
                    --HeadInfoComponent:SetVisibility(false)
                else
                    local nPlayerZ = v.nPlayerZ
                    if v.nState == DCProto.TeamInfo_EState.DEAD then
                        if tbMemberData.nState ~= v.nState then
                            tbMemberData.tbGameObject = nil
                            ChangeHeadNameObject(self, tbGameObject, tbDummyObject, nInstanceId)
                            tbGameObject = nil
                            self.tbMemberDeadHandles[nInstanceId] = DelayTimer:DelayRun(function()
                                DeadDisappearDelayFunc(self, nInstanceId)
                            end, DEAD_DISAPPEAR_DELAY_TIMER)
                        end
                    end
                    if tbGameObject then
                        HeadInfoComponent = tbGameObject.HeadInfoComponent
                    else
                        HeadInfoComponent = tbDummyObject.HeadInfoComponent
                    end
                    --logdebug("refresh dummy location,v.nPlayerX, v.nPlayerY, v.nPlayerZ v.nyaw=",v.nPlayerX, v.nPlayerY, nPlayerZ, v.nPlayerYaw, v.nPlayerZ)
                    tbDummyObject:SetLocation(v.nPlayerX, v.nPlayerY, nPlayerZ)
                    tbDummyObject:SetRotation(0, v.nPlayerYaw, 0)
                end
                tbDummyObject:SetName(v.name)
                if tbGameObject and tbGameObject.HumanMovementStateComponent and tbGameObject.HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.InPlane_State--[[and v.nState == DCProto.TeamInfo_EState.DRIVING and tbMemberData.tbGameObject --]]then
                    local pParentAttachActor = tbGameObject.pUEActor:GetAttachParentActor()
                    local pDummyParantAttachActor = tbDummyObject.pUEActor:GetAttachParentActor()
                    log("TeamHeadNameSystem:OnFFATeamInfoChanged,pParentAttachActor,pDummyParantAttachActor,pSelfAttachUEActor=",pParentAttachActor,pDummyParantAttachActor,pSelfAttachUEActor,v.name)
                    if pParentAttachActor and pSelfAttachUEActor and pParentAttachActor ~= pSelfAttachUEActor then
                        if not pDummyParantAttachActor then
                            --tbMemberData.tbGameObject = nil
                            ChangeHeadNameObject(self, tbGameObject, tbDummyObject, nInstanceId)
                            tbDummyObject.pUEActor:K2_AttachToActor(pParentAttachActor, "", ATTACHMENT_RULE, ATTACHMENT_RULE, ATTACHMENT_RULE, false)
                            HeadInfoComponent = tbDummyObject.HeadInfoComponent
                        end
                    elseif pParentAttachActor and pSelfAttachUEActor and pParentAttachActor == pSelfAttachUEActor then
                        tbGameObject.HeadInfoComponent:SetVisibility(false)
                        tbDummyObject.HeadInfoComponent:SetVisibility(false)
                    elseif pParentAttachActor then
                        ChangeHeadNameObject(self, tbDummyObject, tbGameObject, nInstanceId)
                        HeadInfoComponent = tbGameObject.HeadInfoComponent
                    else
                        tbGameObject.HeadInfoComponent:SetVisibility(false)
                        tbDummyObject.HeadInfoComponent:SetVisibility(false)
                    end
                elseif tbMemberData.nState ~= v.nState and v.nState ~= DCProto.TeamInfo_EState.DEAD and v.nState ~= DCProto.TeamInfo_EState.OFFLINE then
                    HeadInfoComponent:SetVisibility(true)
                    local pDummyParantAttachActor = tbDummyObject.pUEActor:GetAttachParentActor()
                    if pDummyParantAttachActor then
                        tbDummyObject.pUEActor:K2_DetachFromActor(EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative)
                    end
                end
                if v.nState == DCProto.TeamInfo_EState.PARACHUTING and tbMemberData.nState ~= v.nState--[[and not tbMemberData.tbGameObject--]] then
                    local pParentAttachActor = tbDummyObject.pUEActor:GetAttachParentActor()
                    if pParentAttachActor then
                        tbDummyObject.pUEActor:K2_DetachFromActor(EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative)
                    end
                    local tbFindGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
                    if tbFindGameObject and tbFindGameObject.pUEActor then
                        tbMemberData.tbGameObject = tbFindGameObject
                        ChangeHeadNameObject(self, tbDummyObject, tbMemberData.tbGameObject, nInstanceId)
                        HeadInfoComponent = tbMemberData.tbGameObject.HeadInfoComponent
                    end
                end
                
                if HeadInfoComponent then
                    HeadInfoComponent:RefreshHeadWidget(tbParams)
                end
            end
            tbMemberData.szName = v.name
            tbMemberData.nState = v.nState
        end
    end
    TeamInfoChangeForCheckRelation(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_TEAM_INFO_UPDATED, tbTeamMembers)
end

local function OnRefreshViewForNewMate(self, tbNewMateObj)
    if TeamWatchClientHelper.IsOtherTeamWatch() then
        ClearAllTeamMemberData(self)
        OnFFATeamInfoChanged(self)
    end
end

-- local function OnHumanMovementStateChanged(self, tbPlayer, nLastState, nNewState)
--     RefreshHeadInfoLocation(self, tbPlayer, nNewState)
-- end

--
function TeamHeadNameSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    self.tbTeamMembers = {}
    self.tbMemberDeadHandles = {}
    self.nModeTeamCount = nil
    self.bReadyCheckRelation = false
    local tbTemplate = DummyResDataTable:GetTemplate(TEAM_HEAD_DUMMY_TEMPLATE_ID)
    if tbTemplate then
        TEAM_HEAD_DUMMY_BP_CLASS = tbTemplate.szBPClass
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamInfoChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnMemberActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnMemberActorDestroy)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnRefreshViewForNewMate)
    EventHelper:RegisterEvent(ClientEventDef.EV_UPDATE_HEADRELATION, self, OnUpdateHeadRelationVisible)
    
    return true
end

function TeamHeadNameSystem:Uninit()
    local EventHelper = self.EventHelper
    EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamInfoChanged)
    EventHelper:UnregisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnMemberActorCreate)
    EventHelper:UnregisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnMemberActorDestroy)
    EventHelper:UnregisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnRefreshViewForNewMate)
    EventHelper:UnregisterEvent(ClientEventDef.EV_UPDATE_HEADRELATION, self, OnUpdateHeadRelationVisible)
    for k, v in pairs(self.tbMemberDeadHandles) do
        DelayTimer:ClearTimer(v)
    end
    Timer.StopOwnerTimer(self, WAIT_TIMER)
    self.tbMemberDeadHandles = nil
    self.tbTeamMembers = nil
    self.EventHelper = nil
    self.bHideAll = nil
    self.bHideName = nil
    self.bHideDistance = nil
end

---------------------------------------------------------------------
function TeamHeadNameSystem:GetMemberObjByInstanceId(nInstanceId)
    return self.tbTeamMembers[nInstanceId]
end

function TeamHeadNameSystem:GetMemberNameByInstanceId(nInstanceId)
    local tbMemberData = self.tbTeamMembers[nInstanceId]
    if tbMemberData then
        return tbMemberData.tbDummyObject:GetName()
    end
end

function TeamHeadNameSystem:HideAll()
    self.bHideAll = true
    for k, v in pairs(self.tbTeamMembers) do
        local tbGameObject = v.tbGameObject
        local tbDummyObject = v.tbDummyObject
        if tbGameObject and tbGameObject.HeadInfoComponent then
            tbGameObject.HeadInfoComponent:SetVisibility(false)
        end
        if tbDummyObject and tbDummyObject.HeadInfoComponent then
            tbDummyObject.HeadInfoComponent:SetVisibility(false)
        end
    end
end

function TeamHeadNameSystem:HideName(bHideName)
    self.bHideName = bHideName
    for k, v in pairs(self.tbTeamMembers) do
        local tbGameObject = v.tbGameObject
        local tbDummyObject = v.tbDummyObject
        local HeadInfoComponent = nil
        if tbGameObject then
            HeadInfoComponent = tbGameObject.HeadInfoComponent
            HeadInfoComponent:HideTeammateName(bHideName)
        end
        if tbDummyObject then
            HeadInfoComponent = tbDummyObject.HeadInfoComponent
            HeadInfoComponent:HideTeammateName(bHideName)
        end
    end
end


function TeamHeadNameSystem:HideDistance(bHideDistance, nInstanceId)
    self.bHideDistance = bHideDistance
    if nInstanceId then
        HideTeamMemberDistance(self, bHideDistance, nInstanceId)
    else
        for k, v in pairs(self.tbTeamMembers) do
            HideTeamMemberDistance(self, bHideDistance, k)
        end
    end
end

function TeamHeadNameSystem:IsShowTeamHead()
    return not self.bHideAll
end

return TeamHeadNameSystem