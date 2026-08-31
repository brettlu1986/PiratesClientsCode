local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSettingChatLib = luaclass("UPSettingChatLib", ListItemBase)
local SoundManager = require("SoundManager")
local L10N = require("L10N")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GenderTypeDefine = require("GenderTypeDefine")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local HumanDataTable = require("HumanDataTable")

UPSettingChatLib.tbData = nil
-- {tbParent = , tbQuickData = , bInQuickList = , bShowOper = }

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local tbData = self.tbData
    if not tbData.bShowOper then
        pWidgetRef.btnAdd:SetVisibility(ESlateVisibility_Hidden)
        pWidgetRef.imgAdded:SetVisibility(ESlateVisibility_Hidden)
    else
        if tbData.bInQuickList then 
            pWidgetRef.btnAdd:SetVisibility(ESlateVisibility_Hidden)
            pWidgetRef.imgAdded:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        else
            pWidgetRef.btnAdd:SetVisibility(ESlateVisibility_Visible)
            pWidgetRef.imgAdded:SetVisibility(ESlateVisibility_Collapsed)
        end
    end
    pWidgetRef.txtTitle:SetText(L10N:ToString(tbData.tbQuickData.l10nMsg))
end

local function OnClickedAdd(self)
    local tbData = self.tbData
    if tbData.bShowOper then
        tbData.tbParent:OnAdd(tbData.tbQuickData)
    end
end

local function OnClickedSound(self)
    local nGender
    if GlobalVariableSystem_C.bIsInDungeon then
        nGender = GamePlayerSelfHelper:GetGenderInBattle()
    else
        local tbSelfObj = GamePlayerSelfHelper:Get()
        local LobbyPropertyComponent = tbSelfObj.LobbyPropertyComponent
        if LobbyPropertyComponent then
            local nAvatarId = LobbyPropertyComponent.nAvatarTemplateId
            if nAvatarId ~= nil then
                local tbHumanTemplate = HumanDataTable:GetTemplate(nAvatarId)
                if tbHumanTemplate == nil then
                    logerror("setting chat not find avatarid ", nAvatarId)
                else
                    nGender = tbHumanTemplate.nGender
                end
            end
        end
    end
    if nGender ~= nil then 
        local nSoundId = nGender == GenderTypeDefine.MALE and self.tbData.tbQuickData.nMaleSoundId or self.tbData.tbQuickData.nFemaleSoundId
        if nSoundId > 0 then
            SoundManager:PlaySoundEffect(nSoundId)
        end
    end
end

function UPSettingChatLib:OnLoad()
end

function UPSettingChatLib:OnCreate()
end

function UPSettingChatLib:OnDestroy()
end

function UPSettingChatLib:OnShow()
end

function UPSettingChatLib:OnRefresh(tbData)
    self.tbData = tbData
    RefreshUI(self)
end

function UPSettingChatLib:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSound.OnClicked, self, OnClickedSound)
end

return UPSettingChatLib