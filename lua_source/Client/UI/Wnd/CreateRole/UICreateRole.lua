-----------------------------------------------------
--File Name    : UICreateRole.lua
--Author       : WuJizhou
--Create Time  : 4/22/2020, 4:25:19 PM
--Description  : UICreateRole
-----------------------------------------------------
local luaclass             = require("luaclass")
local WndBase              = require("WndBase")
local UICreateRole         = luaclass("UICreateRole", WndBase)

local L10N                 = require("L10N")
local Proto                = require("ClientProtoNames")
local UIDef                = require("UIDef")
local UIUtils              = require("UIUtils")
local UITextDef            = require("UITextDef")
local ClientEventDef       = require("ClientEventDef")
local CreateRoleData       = require("CreateRoleData")
local CreateRoleUIDef      = require("CreateRoleUIDef")
local GenderTypeDefine     = require("GenderTypeDefine")
local SensitiveWordsSystem = require("SensitiveWordsSystem")
local UTF8NameValidatorHelper = require("UTF8NameValidatorHelper")
local SelfTabBarHelper          = require("SelfTabBarHelper")

local NetworkManager       = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")


local SlotType = CreateRoleUIDef.SlotType
local DEFAULT_GENDER = GenderTypeDefine.FEMALE
local DELAY_SELECTED_TIMER = 1

UICreateRole.pActor = nil

UICreateRole.nCurrentGender = nil
UICreateRole.nCurrentRace = nil
UICreateRole.nCurrentAvatarId = nil
UICreateRole.ulCreateRoleAvatar = nil
UICreateRole.ulCreateRoleName = nil
UICreateRole.ulSelectors = nil


local tbULSelectorParams = {}
tbULSelectorParams[SlotType.Face]      = {WrapBoxWidgetName = "wrapboxFace"     , ItemPrefabKey = UIDef.UP_CREATE_ROLE_FACE_ITEM   }
tbULSelectorParams[SlotType.Hair]      = {WrapBoxWidgetName = "wrapboxHair"     , ItemPrefabKey = UIDef.UP_CREATE_ROLE_HAIR_ITEM   }
tbULSelectorParams[SlotType.HairColor] = {WrapBoxWidgetName = "wrapboxHairColor", ItemPrefabKey = UIDef.UP_CREATE_ROLE_COLOR_ITEM  }
tbULSelectorParams[SlotType.SkinColor] = {WrapBoxWidgetName = "wrapboxSkinColor", ItemPrefabKey = UIDef.UP_CREATE_ROLE_COLOR_ITEM  }
tbULSelectorParams[SlotType.Costume]   = {WrapBoxWidgetName = "wrapboxCostume"  , ItemPrefabKey = UIDef.UP_CREATE_ROLE_COSTUME_ITEM}

local function InitULAppearanceSelector(self)
    local ulSelectors = self.ulSelectors
    if not ulSelectors then
        ulSelectors = {}
        self.ulSelectors = ulSelectors
    end

    for nSlotType, tbParam in pairs(tbULSelectorParams) do
        local ulSelector = self.UILogicHelper:CreateUILogic("ULAppearanceSelector")
        ulSelector:Init(nSlotType, tbParam.ItemPrefabKey, tbParam.WrapBoxWidgetName)
        table.insert(ulSelectors, ulSelector)
    end
end

local function InitULCreateRoleAvatar(self)
    self.ulCreateRoleAvatar = self.UILogicHelper:CreateUILogic("ULCreateRoleAvatar")
    local tbParams = {}
    tbParams.nCurrentAvatarId = self.nCurrentAvatarId
    tbParams.pLocation = self.tbOpenArgs.pLocation
    tbParams.pRotation = self.tbOpenArgs.pRotation
    tbParams.nGender = self.nCurrentGender
    self.ulCreateRoleAvatar:Init(tbParams)
end

local function InitULCreateRoleName(self)
    self.ulCreateRoleName = self.UILogicHelper:CreateUILogic("ULCreateRoleName")
    self.ulCreateRoleName:Init(self.nCurrentGender)
end

local function InitULCreateRoleCamera(self)
    self.ulCreateRoleCamera = self.UILogicHelper:CreateUILogic("ULCreateRoleCamera")
end


local function OnAppearanceChanged(self, nAppearanceId)
    self.ulCreateRoleAvatar:FittingAppearance(nAppearanceId)
end

local function UpdateAvatarId(self)
    local tbTemplate = CreateRoleData:GetTemplate(self.nCurrentGender)
    self.nCurrentAvatarId = tbTemplate.nAvatarID
end

local function OnGenderChanged(self)
    UpdateAvatarId(self)
    for _, ulSelector in ipairs(self.ulSelectors) do
        ulSelector:OnGenderChanged(self.nCurrentGender)
    end
    self.ulCreateRoleName:OnGenderChanged(self.nCurrentGender)
    self.ulCreateRoleAvatar:UpdateAvatarById(self.nCurrentAvatarId)
    self.ulCreateRoleCamera:OnGenderChanged(self.nCurrentAvatarId)
end

local function _DelayProcessCheck(self)
    if GlobalVariableSystem:GetLocalTime() - self.nClickTime < DELAY_SELECTED_TIMER then
        if self.nCurrentGender == GenderTypeDefine.FEMALE then
            self.pWidgetRef.chkWoman:SetCheckedState(ECheckBoxState.Checked)
            self.pWidgetRef.chkMan:SetCheckedState(ECheckBoxState.Unchecked)
        else
            self.pWidgetRef.chkMan:SetCheckedState(ECheckBoxState.Checked)
            self.pWidgetRef.chkWoman:SetCheckedState(ECheckBoxState.Unchecked)
        end
        return false
    else
        return true
    end
end

local function Init(self)
    self.nCurrentGender = DEFAULT_GENDER
    self.nClickTime = GlobalVariableSystem:GetLocalTime()
    UpdateAvatarId(self)
end

local function OnConfirmBtnClicked(self)
    local szAvatarName = L10N:ToString(self.pWidgetRef.txtUserName:GetText())
    local nRet, _ = self.tbNameValidator:Validate(szAvatarName)
    if nRet == self.tbNameValidator.Result.InvalidUTF8 then
        UIUtils.ShowToast(UITextDef.USER_NAME_EMPTY)
        return
    elseif nRet == self.tbNameValidator.Result.InvalidLength then
        UIUtils.ShowToast(UITextDef.USER_NAME_LEN_ERROR)
        return
    elseif nRet == self.tbNameValidator.Result.InvalidCodePoint then
        UIUtils.ShowToast(UITextDef.NAME_ILLEGAL)
        return
    end

    self:SetGuideState()

    local bRet = SensitiveWordsSystem:Check(szAvatarName)
    if bRet then
        UIUtils.ShowToast(UITextDef.NAME_ILLEGAL)
        return
    end
    local tbAppearance = self.ulCreateRoleAvatar:GetAppearance()
    local tbIds = {}
    for k, nId in pairs(tbAppearance) do
        table.insert(tbIds, nId)
    end
    local Socket = NetworkManager:GetHubServerProxy()
    local c2s_CreatePlayer =
    {
        name = szAvatarName,
        avatar_id = self.nCurrentAvatarId,
        appearance = {template_id = tbIds}
    }
    UIUtils.ShowLoadingDialog()
    if(not Socket:SendPacket(Proto.c2s_CreatePlayer, c2s_CreatePlayer)) then
        UIUtils.ShowToastWithKey("SEND_LOGIN_PACKET_FAILED")
        logwarning("Send login packet failed.")
    end
end


local function OnReturnBack(self)
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_CREATE_ROLE_BACK)
end

local function OnGenderTabChanged(self, nSelectIndex)
    self.nCurrentGender = nSelectIndex
    OnGenderChanged(self)
end

function UICreateRole:SetGuideState()
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_ROLE_SKIP_GUIDE, true)
end

----------life cycle----------

function UICreateRole:OnCreate()
    Init(self)
end

function UICreateRole:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.hboxGender, DEFAULT_GENDER)
    InitULAppearanceSelector(self)
    InitULCreateRoleAvatar(self)
    InitULCreateRoleName(self)
    InitULCreateRoleCamera(self)
end


-- function UICreateRole:OnEnter()
-- end

function UICreateRole:OnShow()
    self.tbNameValidator = UTF8NameValidatorHelper:CreatePlayerNameValidator()
    self.tbTabBarHelper:SelectByIndex(DEFAULT_GENDER, true)
end
function UICreateRole:OnHide()
    self:PlayAnimation("animComeIn", 0, 1, EUMGSequencePlayMode.Reverse, 1, function ()
        self:HideFinished()
    end)
    return false
end

-- function UICreateRole:OnExit()
-- end

-- function UICreateRole:OnDestroy()
-- end

function UICreateRole:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UICreateRole:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEFAULT_APPEARANCE_SELECTED, self, OnAppearanceChanged)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.chkWoman.OnCheckStateChanged, self, OnFemaleGenderSelected)
    -- EventHelper:RegisterCppDelegate(self.pWidgetRef.chkMan.OnCheckStateChanged, self, OnMaleGenderSelected)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnStart.OnClicked, self, OnConfirmBtnClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBack.OnClicked, self, OnReturnBack)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnGenderTabChanged, self)
end

-- function UICreateRole:OnUnbindEvent(EventHelper)
-- end

-- function UICreateRole:OnLoadLevelFinished()
-- end


return UICreateRole