local luaclass           = require("luaclass")
local ListItemBase       = require("ListItemBase")
local UPFriendRelationItem  = luaclass("UPFriendRelationItem", ListItemBase)

local FriendRelationShipLevelDataTable = require("FriendRelationShipLevelDataTable")
local FriendRelationShipDataTable = require("FriendRelationShipDataTable")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GenderTypeDefine = require("GenderTypeDefine")
local AvatarDataTable = require("AvatarDataTable")
local HumanDataTable = require("HumanDataTable")
local UIResourceDef = require("UIResourceDef")
local RankDataTable = require("RankDataTable")
local FriendSystem = require("FriendSystem")
local Proto = require("ClientProtoNames")
local TimeUtil = require("TimeUtil")
local UISetUtils = require("UISetUtils")
local FriendIni = require("FriendIni")
local UITextDef = require("UITextDef")
local UIUtils = require("UIUtils")
local SeasonHelper = require("SeasonHelper")

local L10N = require("L10N")

UPFriendRelationItem.pbHead = nil
UPFriendRelationItem.nSelectRelationType = -1

local DEFAULT_RANK = 11

local MIN_RELATION = 1
local MAX_RELATION = 4

local function GetGenderRes(nAvatarId)
    local tbAvatarData = AvatarDataTable:GetTemplate(nAvatarId)
    if tbAvatarData == nil then 
        return UIResourceDef.GENDER_MALE
    end 
    local tbHumanData = HumanDataTable:GetTemplate(tbAvatarData.nHumanId)
    if tbHumanData == nil then
        return UIResourceDef.GENDER_MALE
    end
    return tbHumanData.nGender == GenderTypeDefine.MALE and UIResourceDef.GENDER_MALE or UIResourceDef.GENDER_FEMALE
end

local function RefreshBaseInfo(self)
    local tbData = self.tbData
    if tbData.player_summary == nil then return end
    local pWidgetRef = self.pWidgetRef
    local tbPlayerSummary = tbData.player_summary or tbData
    local nId = tbPlayerSummary.id or tbData.nId
    local nAvatarId = tbPlayerSummary.avatar_id or tbData.nAvatarId
    local szName = tbPlayerSummary.name or tbData.szName
    local nLevel = tbPlayerSummary.level or 1
     -- 头像，等级
    self.pbHead:SetPlayerHead(nAvatarId, nLevel)
    self.pbHead:SetPlayerId(nId)
    -- 性别
    local szGender = GetGenderRes(nAvatarId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgSex, szGender:load(), true)
    -- 名字
    pWidgetRef.txtName:SetText(szName)
    -- 段位
    local tbRankTemp = RankDataTable:GetTemplate(tbPlayerSummary.rank)
    if tbRankTemp == nil then
        tbRankTemp = RankDataTable:GetTemplate(DEFAULT_RANK)
    end
    local szRankName = L10N:ToString(tbRankTemp.l10nName)..tbRankTemp.szRankLevelName
    pWidgetRef.ktxtRank:SetText(szRankName)
    local szRankImg, szRankNumImg = SeasonHelper.GetIcon(tbPlayerSummary.rank)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgRank, szRankImg:load())
    if szRankNumImg ~= nil then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, szRankNumImg:load())
    else
        pWidgetRef.imgRankNumber:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function HasRelation(self)
    local tbRelationShip = self.tbData.relationship
    if not tbRelationShip then  
        return false
    end
    local nState = tbRelationShip.state
    local nLevel = tbRelationShip.relationship_level
    if nState > Proto.RelationshipState.APPLYING and nLevel ~= nil then  
        return true
    end
    return false
end

local function GetRelationState(self)
    local tbRelationShip = self.tbData.relationship
    return tbRelationShip.state or 0
end

local function RefreshRelationSelections(self)
    local FriendComponent = FriendSystem:GetComponent()
    for type = MIN_RELATION, MAX_RELATION do  
        local pTxtName = self.pWidgetRef[string.format("txtRelationName_%d", type)]
        local l10nName = FriendRelationShipDataTable:GetTemplate(type).l10nName
        local formatStr = L10N:ToString(l10nName) .. "%d/%d"
        pTxtName:SetText(string.format(formatStr, FriendComponent:GetRelationCount(type), FriendComponent:GetRelationLimit(type)))
    end
end

local function OnSelectRelationClicked(self, nType)
    local pWidgetRef = self.pWidgetRef
    local FriendComponent = FriendSystem:GetComponent()
    local nCurrentCount = FriendComponent:GetRelationCount(nType)
    local nLimitCount = FriendComponent:GetRelationLimit(nType)
    local bCanSelect = nCurrentCount < nLimitCount 
    if bCanSelect then  
        pWidgetRef.btnCancel:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtYes:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_OK"))
        pWidgetRef.txtCurRelation:SetText(FriendRelationShipDataTable:GetTemplate(nType).l10nName)
        self.nSelectRelationType = nType
    else  
        UIUtils.ShowToast(UITextDef.FRIEND_RELATION_MAX_COUNT)
        pWidgetRef.txtCurRelation:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_SELECT_RELATION"))
        self.nSelectRelationType = -1
    end
    pWidgetRef.bdSelectRelationItems:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.cbSelectRelation:SetCheckedState(ECheckBoxState.Unchecked)
end

local function OnCheckSelectRelation(self, bChecked)
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.Visible, ESlateVisibility.Collapsed
    pWidgetRef.bdSelectRelationItems:SetVisibility(bChecked and Visible or Collapsed)
    if bChecked then  
        RefreshRelationSelections(self)
    end
end

local function RefreshHasRelationInfo(self)
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.olSelectRelation:SetVisibility(Collapsed)
    pWidgetRef.bdrCurRelation:SetVisibility(Visible)
    
    local nRelationType = self.tbData.relationship.relationship_id
    local l10nName = FriendRelationShipDataTable:GetTemplate(nRelationType).l10nName
    pWidgetRef.txtRelationName:SetText(l10nName)
    pWidgetRef.txtRelationName:SetColorAndOpacity(UIResourceDef.FRIEND_RELATION_TXT_COLOR[nRelationType])

    local nRelationLevel = self.tbData.relationship.relationship_level
    pWidgetRef.txtRelationLevel:SetText(nRelationLevel)
    UISetUtils.SetBorderBrushRes(pWidgetRef.bdrRelation, UIResourceDef.FRIEND_RELATION_IMG[nRelationType]:load())
    
    local nRelationState = GetRelationState(self)
    if nRelationState == Proto.RelationshipState.CANCELING then
        local nPlayerSelfId = GamePlayerSelfHelper:Get():GetPlayerId()
        local nSenderPlayerId = self.tbData.relationship.applicant_id
        
        if nPlayerSelfId == nSenderPlayerId then 
            pWidgetRef.txtAlreadyShowFirst:SetVisibility(Visible)
            pWidgetRef.txtAlreadyShowFirst:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_RELATION_CANCLING"))
        else  
            pWidgetRef.txtAlreadyShowFirst:SetVisibility(Collapsed)
            pWidgetRef.bdrCurRelation:SetVisibility(Collapsed)
            pWidgetRef.olSelectRelation:SetVisibility(Visible)
            pWidgetRef.bdSelectRelationItems:SetVisibility(Collapsed)
            pWidgetRef.cbSelectRelation:SetVisibility(Collapsed)
            pWidgetRef.ImgTextBg:SetVisibility(Visible)

            local l10nTypeName = FriendRelationShipDataTable:GetTemplate(nRelationType).l10nName
            local l10nStr = UISetUtils.GetL10NTextByKey("UI_LOBBY_FRIEND_CANCEL_RELATION")
            l10nStr = L10N:Format(l10nStr, UITextDef.RELATION_COLOR_KEY[nRelationType], l10nTypeName)
            pWidgetRef.txtCurRelation:SetText(L10N:ToString(l10nStr))
        end
    end
end

local function RefreshNoRelationEmpty(self)
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.olSelectRelation:SetVisibility(Visible)
    pWidgetRef.bdrCurRelation:SetVisibility(Collapsed)
    pWidgetRef.ImgTextBg:SetVisibility(Collapsed)
    pWidgetRef.cbSelectRelation:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtCurRelation:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_SELECT_RELATION"))
    pWidgetRef.txtAlreadyShowFirst:SetVisibility(Collapsed)
    pWidgetRef.bdSelectRelationItems:SetVisibility(Collapsed)
    pWidgetRef.bdrCurRelation:SetVisibility(Collapsed)
end

local function RefeshNoRelationApplying(self)
    local pWidgetRef = self.pWidgetRef
    local nRelationState = GetRelationState(self)
    if nRelationState == Proto.RelationshipState.APPLYING then  
        local nPlayerSelfId = GamePlayerSelfHelper:Get():GetPlayerId()
        local nSenderPlayerId = self.tbData.relationship.applicant_id

        pWidgetRef.cbSelectRelation:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ImgTextBg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        if nPlayerSelfId == nSenderPlayerId then  
            pWidgetRef.txtCurRelation:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_WAIT_CREATE_RELATION"))
        else  
            local nRelationType = self.tbData.relationship.relationship_id
            local l10nName = FriendRelationShipDataTable:GetTemplate(nRelationType).l10nName
            local l10nStr = UISetUtils.GetL10NTextByKey("UI_LOBBY_FRIEND_BECOME_RELATION")
            l10nStr = L10N:Format(l10nStr, UITextDef.RELATION_COLOR_KEY[nRelationType], l10nName)
            pWidgetRef.txtCurRelation:SetText(L10N:ToString(l10nStr))
        end
    end
end

local function RefreshRemainRecreateRelation(self, day)
    local Visible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnReselect:SetVisibility(Collapsed)
    pWidgetRef.btnCancel:SetVisibility(Collapsed)
    pWidgetRef.btnYes:SetVisibility(Collapsed)

    pWidgetRef.bdrCurRelation:SetVisibility(Collapsed)
    pWidgetRef.olSelectRelation:SetVisibility(Visible)
    pWidgetRef.cbSelectRelation:SetVisibility(Collapsed)
    pWidgetRef.bdSelectRelationItems:SetVisibility(Collapsed)
    pWidgetRef.ImgTextBg:SetVisibility(Visible)
    pWidgetRef.txtCurRelation:SetVisibility(Visible)

    local l10nStr = UISetUtils.GetL10NTextByKey("UI_LOBBY_FIREND_RECREATE_RELATION_DAY")
    l10nStr = L10N:Format(l10nStr, day)
    pWidgetRef.txtCurRelation:SetText(L10N:ToString(l10nStr))

    pWidgetRef.txtAlreadyShowFirst:SetVisibility(Visible)
    pWidgetRef.txtAlreadyShowFirst:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_RELATION_CANCLED"))
end

local function RefreshNoRelationInfo(self)
    local nRelationState = GetRelationState(self)
    local bShowValid1, bShowValid2, bShowValid3 = false, false, false 
    local nCoolDownTime = FriendIni.nCancelCoolDownDay * TimeUtil.GetOneDaySeconds()
    local now = GlobalVariableSystem:GetServerTimeUtc()

    local nLastEditTime = self.tbData.relationship.relationship_last_edit
    if nRelationState == Proto.RelationshipState.EMPTY then  
        if nLastEditTime == nil or nLastEditTime == 0 then  
            bShowValid1 = true
        end
        if nLastEditTime ~= nil and nLastEditTime > 0 then
            bShowValid2 = now - nLastEditTime >= nCoolDownTime
        end
    elseif  nRelationState == Proto.RelationshipState.APPLYING then  
        bShowValid3 = true
    end

    local bShowNoRelation = bShowValid1 or bShowValid2 or bShowValid3
    if bShowNoRelation then 
        RefreshNoRelationEmpty(self)
        RefeshNoRelationApplying(self)
    else 
        local nTimeLeft = nCoolDownTime - (now - nLastEditTime)
        local nDay = math.ceil(nTimeLeft / TimeUtil.GetOneDaySeconds())
        RefreshRemainRecreateRelation(self, nDay)
    end
end

local function RefreshButtons(self)
    local pWidgetRef = self.pWidgetRef
    local nRelationState = GetRelationState(self)
    local Visible, Collapsed = ESlateVisibility.Visible, ESlateVisibility.Collapsed
    local FriendComponent = FriendSystem:GetComponent()
    local nPriorityId = FriendComponent:GetPriorityPlayer()
    if HasRelation(self) then
        pWidgetRef.btnCancel:SetVisibility(Collapsed)
        pWidgetRef.btnYes:SetVisibility(Collapsed) 
        pWidgetRef.btnReselect:SetVisibility(Collapsed)
        if nRelationState == Proto.RelationshipState.ESTABLISHED then  
            pWidgetRef.btnDeleteRelation:SetVisibility(Visible)
            if nPriorityId == self.tbData.player_id then  
                pWidgetRef.txtAlreadyShowFirst:SetVisibility(Visible)
                pWidgetRef.txtAlreadyShowFirst:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ALREADY_SHOW_FIRST"))
                pWidgetRef.btnShowFirst:SetVisibility(Collapsed)
            else  
                pWidgetRef.txtAlreadyShowFirst:SetVisibility(Collapsed)
                pWidgetRef.btnShowFirst:SetVisibility(Visible)
            end
        elseif nRelationState == Proto.RelationshipState.CANCELING then
            pWidgetRef.btnDeleteRelation:SetVisibility(Collapsed)
            pWidgetRef.btnShowFirst:SetVisibility(Collapsed)
            local nPlayerSelfId = GamePlayerSelfHelper:Get():GetPlayerId()
            local nSenderPlayerId = self.tbData.relationship.applicant_id
            if nPlayerSelfId ~= nSenderPlayerId then 
                pWidgetRef.btnYes:SetVisibility(Visible) 
                pWidgetRef.btnCancel:SetVisibility(Visible)
                pWidgetRef.txtYes:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_OK"))
                pWidgetRef.txtCancel:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_CANCEL"))
            end
        end
    else  
        pWidgetRef.btnDeleteRelation:SetVisibility(Collapsed)
        pWidgetRef.btnShowFirst:SetVisibility(Collapsed)
        pWidgetRef.btnCancel:SetVisibility(Collapsed)
        pWidgetRef.btnYes:SetVisibility(Collapsed)
        if nRelationState == Proto.RelationshipState.EMPTY then  
            pWidgetRef.btnReselect:SetVisibility(Collapsed)
        elseif nRelationState == Proto.RelationshipState.APPLYING then  
            local nPlayerSelfId = GamePlayerSelfHelper:Get():GetPlayerId()
            local nSenderPlayerId = self.tbData.relationship.applicant_id
            if nPlayerSelfId == nSenderPlayerId then 
                pWidgetRef.btnReselect:SetVisibility(Visible)
            else  
                pWidgetRef.btnCancel:SetVisibility(Visible)
                pWidgetRef.btnYes:SetVisibility(Visible)
                pWidgetRef.txtYes:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_COMMON_ACCEPT"))
                pWidgetRef.txtCancel:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_FRIEND_REFUSE"))
                pWidgetRef.btnReselect:SetVisibility(Collapsed)
            end
        end
    end
end

local function RequestToCreateRelation(self)
    if self.nSelectRelationType ~= -1 then 
        FriendSystem:RequestCreateRelation(self.tbData.player_id, self.nSelectRelationType)
    end
end

local function OnSelectYes(self)
    local nRelationState = GetRelationState(self)
    local nPlayerSelfId = GamePlayerSelfHelper:Get():GetPlayerId()
    local nSenderPlayerId = self.tbData.relationship.applicant_id
    
    if not HasRelation(self) then  
        if nRelationState == Proto.RelationshipState.EMPTY then 
            RequestToCreateRelation(self)
        elseif nRelationState == Proto.RelationshipState.APPLYING then    
            if nPlayerSelfId ~= nSenderPlayerId then 
                FriendSystem:RequestApplyRelation(nSenderPlayerId, true)
            else 
                RequestToCreateRelation(self)
            end
        end
    else  
        if nRelationState == Proto.RelationshipState.CANCELING then
            if nPlayerSelfId ~= nSenderPlayerId then 
                FriendSystem:RequestApplyCancelRelation(nSenderPlayerId, true)
            end
        end
    end
end

local function OnSelectCancel(self)
    local nRelationState = GetRelationState(self)
    local nPlayerSelfId = GamePlayerSelfHelper:Get():GetPlayerId()
    local nSenderPlayerId = self.tbData.relationship.applicant_id
    if not HasRelation(self) then
        if nRelationState == Proto.RelationshipState.APPLYING then    
            if nPlayerSelfId ~= nSenderPlayerId then 
                FriendSystem:RequestApplyRelation(nSenderPlayerId, false)
            end
        end
    else  
        if nRelationState == Proto.RelationshipState.CANCELING then
            if nPlayerSelfId ~= nSenderPlayerId then 
                FriendSystem:RequestApplyCancelRelation(nSenderPlayerId, false)
            end
        end
    end
end

local function ReselectRelation(self)
    local nRelationState = GetRelationState(self)
    if not HasRelation(self) and nRelationState == Proto.RelationshipState.APPLYING then
        RefreshNoRelationEmpty(self)
        local nApplyingRelation = self.tbData.relationship.relationship_id
        OnSelectRelationClicked(self, nApplyingRelation)
        OnCheckSelectRelation(self, true)
        self.pWidgetRef.cbSelectRelation:SetCheckedState(ECheckBoxState.Checked)
        self.pWidgetRef.btnReselect:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function CancelRelation(self)
    local nRelationState = GetRelationState(self)
    if nRelationState == Proto.RelationshipState.ESTABLISHED then  
        local l10nTitle = UISetUtils.GetL10NTextByKey("FRIEND_CACEL_RELATION_TITLE")
        local l10nMessage = UISetUtils.GetL10NTextByKey("FRIEND_CACEL_RELATION_CONFIRM")
        l10nMessage = L10N:Format(l10nMessage, FriendIni.nCancelCoolDownDay)
        UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
            FriendSystem:RequestCancelRelation(self.tbData.player_id)
        end)
    end
end

local function SelectShowFirst(self)
    FriendSystem:RequestShowFirst(self.tbData.player_id)
end

local function RefreshOnlyInfo(self)
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.olSelectRelation:SetVisibility(Collapsed)
    pWidgetRef.bdrCurRelation:SetVisibility(Visible)
    
    local nRelationType = self.tbData.relationship.relationship_id
    local nRelationLevel = self.tbData.relationship.relationship_level
    local l10nName = FriendRelationShipDataTable:GetTemplate(nRelationType).l10nName
    pWidgetRef.txtRelationName:SetText(l10nName)
    pWidgetRef.txtRelationName:SetColorAndOpacity(UIResourceDef.FRIEND_RELATION_TXT_COLOR[nRelationType])

    
    pWidgetRef.txtRelationLevel:SetText(nRelationLevel)
    UISetUtils.SetBorderBrushRes(pWidgetRef.bdrRelation, UIResourceDef.FRIEND_RELATION_IMG[nRelationType]:load())

    pWidgetRef.btnCancel:SetVisibility(Collapsed)
    pWidgetRef.btnYes:SetVisibility(Collapsed) 
    pWidgetRef.btnReselect:SetVisibility(Collapsed)
    pWidgetRef.btnDeleteRelation:SetVisibility(Collapsed)
    pWidgetRef.btnShowFirst:SetVisibility(Collapsed)
    pWidgetRef.txtAlreadyShowFirst:SetVisibility(Visible)

    local tbFriendIntimacy = self.tbData.player_intimacy
    local nTotalIntimacy = 0
    if tbFriendIntimacy then 
        nTotalIntimacy = tbFriendIntimacy.intimacy_total
    end

    local nNextLevelTotalIntimacy = FriendRelationShipLevelDataTable:GetNextLevelIntimacy(nRelationType, nRelationLevel)
    pWidgetRef.txtAlreadyShowFirst:SetText(string.format("%d/%d", nTotalIntimacy, nNextLevelTotalIntimacy))
end

function UPFriendRelationItem:OnRefresh(tbData)
    RefreshBaseInfo(self)
    if tbData.bOnlyShowInfo == true then  
        RefreshOnlyInfo(self)
    else 
        if HasRelation(self) then  
            RefreshHasRelationInfo(self)
        else  
            RefreshNoRelationInfo(self)
        end
        RefreshButtons(self)
    end
end

function UPFriendRelationItem:OnCreate()
end

function UPFriendRelationItem:OnDestroy()
    self.pbHead = nil
end

function UPFriendRelationItem:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbHead = PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
    self.pbHead:EnableClickHeadDefaultAction(true)
end

function UPFriendRelationItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.cbSelectRelation.OnCheckStateChanged, self, OnCheckSelectRelation)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnYes.OnClicked, self, OnSelectYes)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnCancel.OnClicked, self, OnSelectCancel)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnReselect.OnClicked, self, ReselectRelation)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnShowFirst.OnClicked, self, SelectShowFirst)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDeleteRelation.OnClicked, self, CancelRelation)
    for i = 1, MAX_RELATION do  
        EventHelper:RegisterCppDelegate(pWidgetRef[string.format("btnRelation%d", i)].OnClicked, self, function()
            OnSelectRelationClicked(self, i)
        end)
    end
end

return UPFriendRelationItem
                                  