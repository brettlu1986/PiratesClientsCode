-----------------------------------------------------
--File Name    : UILobby.lua
--Create Time  : 2018-08-30
--Description  : 吃鸡大厅界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIRenamePlayer = luaclass("UIRenamePlayer", WndBase)

-- import require
-- local ClientEventDef = require("ClientEventDef")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local RenameCardDataTable = require("RenameCardDataTable")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UTF8NameValidatorHelper = require("UTF8NameValidatorHelper")
local UITextDef = require("UITextDef")
local SensitiveWordsSystem = require("SensitiveWordsSystem")
local ItemSystem = require("ItemSystem")
local PlayerNameIni = require("PlayerNameIni")

UIRenamePlayer.nLastUseTime = 0
UIRenamePlayer.nRenameAgainTime = 0 --可以再次改名时间间隔
UIRenamePlayer.tbNameValidator = nil
UIRenamePlayer.tbItem = nil 
UIRenamePlayer.nRenameCost = 0

local UNRENAME_COST = 1

local function OnClickedRename(self)
    local szAvatarName = L10N:ToString(self.pWidgetRef.txtRename:GetText())

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

    local bRet = SensitiveWordsSystem:Check(szAvatarName)
    if bRet then
        UIUtils.ShowToast(UITextDef.NAME_ILLEGAL)
        return
    end

    local now = GlobalVariableSystem:GetServerTimeUtc()
    if self.nLastUseTime > now - self.nRenameAgainTime and self.nLastUseTime < now then   
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("RENAME_RECENTLY"))
        return 
    end

    if self.tbItem == nil then   
        return
    end

    ItemSystem:RequestUseItem(self.tbItem:GetInstanceId(), self.nRenameCost, szAvatarName)

    self:CloseSelf()
end

local function OnClickedBack(self)
    self:CloseSelf()
end


local function RestrictMaxLength(self, szName)
    local tbNameValidator = self.tbNameValidator
    if not tbNameValidator then
        tbNameValidator = UTF8NameValidatorHelper:CreatePlayerNameValidator()
        self.tbNameValidator = tbNameValidator
    end
    local _, nIdx = tbNameValidator:GetLegalNameLength(szName, PlayerNameIni.nMaxDisplayWidth)
    return string.sub(szName, 1, nIdx)
end

local function OnUsernameCommit(self, l10nText)
    local szName = L10N:ToString(l10nText)
    local szText = RestrictMaxLength(self, szName)
    self.pWidgetRef.txtRename:SetText(szText)
end

local function OnTextChanged(self, l10nText)
    local szName = L10N:ToString(l10nText)
    local szText = RestrictMaxLength(self, szName)
    self.pWidgetRef.txtRename:SetText(szText)
end

function UIRenamePlayer:OnLoad()
end

function UIRenamePlayer:OnEnter()
    local tbOpenArgs = self.tbOpenArgs
    self:SetItem(tbOpenArgs.Item)
    self:SetData(tbOpenArgs.nLastUseTime, tbOpenArgs.nRenameTimes)
end

function UIRenamePlayer:OnShow()
    self.tbNameValidator = UTF8NameValidatorHelper:CreatePlayerNameValidator()
end

function UIRenamePlayer:OnExit()
end

function UIRenamePlayer:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnDone.OnClicked, self, OnClickedRename)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, OnClickedBack)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtRename.OnTextChanged, self, OnTextChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.txtRename.OnTextCommitted, self, OnUsernameCommit)
end

function UIRenamePlayer:SetData(nLastUseTime, nRenameTimes)
    if nLastUseTime == nil or nLastUseTime == 0 then  
        self.nLastUseTime = 0
    else  
        self.nLastUseTime = nLastUseTime
    end
    
    local pWidgetRef = self.pWidgetRef
    --当前次 是在已改名次数上+1
    if nRenameTimes == nil or nRenameTimes == 0 then   
        nRenameTimes = UNRENAME_COST
    else  
        nRenameTimes = nRenameTimes + 1
    end
    self.nRenameCost = RenameCardDataTable:GetTemplate(nRenameTimes).nCount
    local l10nCost = L10N:Format(UISetUtils.GetL10NTextByKey("RENAME_COST"), self.nRenameCost)
    pWidgetRef.txtRenameCost:SetText(l10nCost)
    self.pWidgetRef.txtRename:SetText("")
end

function UIRenamePlayer:SetItem(tbItem)
    self.tbItem = tbItem
    local tbCardData = self.tbItem:GetTemplate()
    self.nRenameAgainTime = tbCardData.nRenameDuration or 0
end

function UIRenamePlayer:Collapse()
    self:SetVisible(false)
end

function UIRenamePlayer:SetVisible(bShow)
    self.pWidgetRef:SetVisibility(bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

return UIRenamePlayer
