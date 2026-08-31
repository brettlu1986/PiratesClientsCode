-----------------------------------------------------
--File Name    : UPBattleTeamMemberInfo.lua
--Description  : Prefab UPBattleTeamMemberInfo
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPBattleTeamMemberInfo = luaclass("UPBattleTeamMemberInfo", ListItemBase)

local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local GenderTypeDefine = require("GenderTypeDefine")
local DCProto = require("DungeonCommonProtoNames")
local HeadHpIni = require("HeadHpIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local MathUtil = require("MathUtil")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local ClientEventDef = require("ClientEventDef")

local DEFAULT_HP_LEVEL = -1

UPBattleTeamMemberInfo.tbGamePlayer = nil
UPBattleTeamMemberInfo.nIndex = nil
UPBattleTeamMemberInfo.bSign = false
UPBattleTeamMemberInfo.nCurrentHpLevel = nil
UPBattleTeamMemberInfo.tbGameObj = nil
UPBattleTeamMemberInfo.tbHpDelegateHandle = nil
UPBattleTeamMemberInfo.tbSetVoiceLevelHandle = nil

local OnSelfHpChanged = nil

local function UnregisterSelfHpHandle(self)
    if self.tbHpDelegateHandle then
        self.EventHelper:UnregisterLuaDelegate(self.tbHpDelegateHandle, OnSelfHpChanged, self)
        self.tbHpDelegateHandle = nil
    end
end

local function GetCurrentHpLevel(self, nHpPercent)
    local nCurrentHpLevel = DEFAULT_HP_LEVEL
    if self.tbData and self.tbData.nState ~= DCProto.TeamInfo_EState.DYING then
        local tbHpLevelPercents = HeadHpIni.tbUiHpColors.tbHpLevelPercents
        for i,v in ipairs(tbHpLevelPercents) do
            if nHpPercent >= v then
                nCurrentHpLevel = i
                break
            end
        end
    end
    
    return nCurrentHpLevel
end

local function UpdateHP(self, nHpPercent)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbgHp:SetPercent(nHpPercent)
    local nCurrentHpLevel = GetCurrentHpLevel(self, nHpPercent)
    if nCurrentHpLevel ~= self.nCurrentHpLevel then
        self.nCurrentHpLevel = nCurrentHpLevel
        if nCurrentHpLevel == DEFAULT_HP_LEVEL then
            pWidgetRef.pbgHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(HeadHpIni.tbUiHpColors.szDyingHpColor))
            --pWidgetRef.pbgHp:SetRenderOpacity(HeadHpIni.tbUiHpColors.nDyingHpBgOpacity)
        else
            local tbHpLevelColors = HeadHpIni.tbUiHpColors.tbHpLevelColors
            pWidgetRef.pbgHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(tbHpLevelColors[nCurrentHpLevel]))
            --local tbHpLevelBgOpacities = HeadHpIni.tbUiHpColors.tbHpLevelBgOpacities
            --pWidgetRef.pbgHp:SetRenderOpacity(tbHpLevelBgOpacities[nCurrentHpLevel])
        end
    end
end

OnSelfHpChanged = function(self, nHp, nMaxHp, nHpPercent)
    if not self.tbData or self.tbData.nInstanceId ~= GamePlayerSelfHelper:GetServerInstanceId() then
        UnregisterSelfHpHandle(self)
        return
    end
    local PropertyComponent = GamePlayerSelfHelper:Get():GetCurrentPropertyComponent()
    if PropertyComponent:GetIsDead() then
        nHp = 0
        nHpPercent = 0
    else
        nHp = math.ceil(nHp or PropertyComponent:GetHp())
        nHpPercent = nHpPercent or PropertyComponent:GetHpPercent()
    end
    nMaxHp = MathUtil.Round(nMaxHp or PropertyComponent:GetMaxHp())

    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbgHp:SetPercent(nHpPercent)

    local nCurrentHpLevel = GetCurrentHpLevel(self, nHpPercent)
    if nCurrentHpLevel ~= self.nCurrentHpLevel then
        self.nCurrentHpLevel = nCurrentHpLevel
        if nCurrentHpLevel == DEFAULT_HP_LEVEL then
            pWidgetRef.pbgHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(HeadHpIni.tbUiHpColors.szDyingHpColor))
        else
            local tbHpLevelColors = HeadHpIni.tbUiHpColors.tbHpLevelColors
            pWidgetRef.pbgHp:SetFillColorAndOpacity(KMUMGLibrary.GetLinearColorFromHex(tbHpLevelColors[nCurrentHpLevel]))
        end
    end
end

--[[
    public function
]]
function UPBattleTeamMemberInfo:SetVoiceLevel(nIndex, nState)
    -- logdebug("======UPBattleTeamMemberInfo:SetVoiceLevel====== nIndex = " .. tostring(nIndex) .. " self.nIndex = " .. tostring(self.nIndex) .. " nState = " .. nState )
    if nIndex ~= self.nIndex then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbgVoiceLevel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if nState == 0 then
        self:StopAnimation("animMic")
        pWidgetRef.pbgVoiceLevel:SetPercent(0)
    elseif nState == 1 then
        self:PlayAnimation("animMic", 0, 3, EUMGSequencePlayMode.Forward, 1)
    elseif nState == 2 then
        self:PlayAnimation("animMic", 0, 3, EUMGSequencePlayMode.Forward, 1)
    end
end

function UPBattleTeamMemberInfo:InitData(tbBaseData, nIndex)
    local pWidgetRef = self.pWidgetRef
    local SelfHitTestInvisible =  ESlateVisibility.SelfHitTestInvisible
    pWidgetRef:SetVisibility(SelfHitTestInvisible)

    pWidgetRef.txtName:SetText(tbBaseData.name)

    local szGenderIcon = UIResourceDef.GENDER_FEMALE
    if tbBaseData.nGenderType == GenderTypeDefine.MALE then
        szGenderIcon = UIResourceDef.GENDER_MALE
    end

    UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGenderIcon:load(), true)

    pWidgetRef.imgNumberBgColour:SetIsEnabled(false)
    pWidgetRef.imgStats:SetIsEnabled(false)
    pWidgetRef.imgSex:SetIsEnabled(false)
    pWidgetRef.imgPoint:SetIsEnabled(false)
    pWidgetRef.pbgHp:SetIsEnabled(false)
    pWidgetRef.txtName:SetIsEnabled(false)
    pWidgetRef.pbgVoiceLevel:SetPercent(0)

    pWidgetRef.imgStats:SetVisibility(SelfHitTestInvisible)
    local szStateIcon = UIResourceDef.TEAM_MEMBER_STATE_ICON[DCProto.TeamInfo_EState.OFFLINE]
    if szStateIcon then
        local pStateIcon = szStateIcon:load()
        if pStateIcon then
            UISetUtils.SetImageBrushRes(pWidgetRef.imgStats, pStateIcon, true)
        end
    end

    local pLinearColor = UIResourceDef.TEAM_INDEX_COLOR[nIndex]
    if not pLinearColor then
        logerror("UPBattleTeamMemberInfo:SetData error index, ", nIndex)
        pLinearColor = UIResourceDef.COLOR.WHITE.LINEAR_COLOR
    end
    
    pWidgetRef.imgNumberBgColour:SetColorAndOpacity(pLinearColor)
    pWidgetRef.txtNameNumber:SetText(nIndex)
    self.nIndex = nIndex
end

function UPBattleTeamMemberInfo:SetData(tbData)
    local pWidgetRef = self.pWidgetRef
    local SelfHitTestInvisible, Collapsed =  ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    if not tbData or tbData.nMaxHp == 0 then
        pWidgetRef:SetVisibility(Collapsed)
        return
    end

    -- if not self.tbGameObj or tbData.nInstanceId ~= self.tbGameObj:GetServerInstanceId() then
    --     self.tbGameObj = GameObjectSystem:FindByInstanceId(tbData.nInstanceId)
    -- end
    if tbData.nState == DCProto.TeamInfo_EState.OFFLINE or tbData.nState == DCProto.TeamInfo_EState.DEAD then
        if tbData.nState == DCProto.TeamInfo_EState.OFFLINE then
            pWidgetRef.imgPoint:SetIsEnabled(false)
        else
            pWidgetRef.imgPoint:SetIsEnabled(true)
        end
    else
        pWidgetRef.imgNumberBgColour:SetIsEnabled(true)
        pWidgetRef.imgStats:SetIsEnabled(true)
        pWidgetRef.imgSex:SetIsEnabled(true)
        pWidgetRef.imgPoint:SetIsEnabled(true)
        pWidgetRef.pbgHp:SetIsEnabled(true)
        pWidgetRef.txtName:SetIsEnabled(true)
    end

    if tbData.nState == DCProto.TeamInfo_EState.NONE or 
       tbData.nState == DCProto.TeamInfo_EState.ADDITIONALSUCCESS then
        pWidgetRef.imgStats:SetVisibility(Collapsed)
    elseif tbData.nState then
        pWidgetRef.imgStats:SetVisibility(SelfHitTestInvisible)
        local szStateIcon = UIResourceDef.TEAM_MEMBER_STATE_ICON[tbData.nState]
        if szStateIcon then
            local pStateIcon = szStateIcon:load()
            if pStateIcon then
                UISetUtils.SetImageBrushRes(pWidgetRef.imgStats, pStateIcon, true)
            else
                logerror("UPBattleTeamMemberInfo:SetData, state icon is nil ", tbData.nState)
            end
        else
            logerror("UPBattleTeamMemberInfo:SetData, szStateIcon is nil ", tbData.nState)
        end
    else
        logerror("UPBattleTeamMemberInfo:SetData, tbData.nState is nil")
    end
    --("tbData.SignType,self.bSign=",tbData.SignType,self.bSign, GamePlayerSelfHelper:Get():GetName())
    if TeamWatchClientHelper.IsOtherTeamWatch() then
        pWidgetRef.imgPoint:SetVisibility(Collapsed)
        self.bSign = false
    elseif tbData.SignType == DCProto.ESignType.SIGN then
        pWidgetRef.imgPoint:SetVisibility(SelfHitTestInvisible)
        local pLinearColor = UIResourceDef.TEAM_INDEX_COLOR[self.nIndex]
        pWidgetRef.imgPoint:SetColorAndOpacity(pLinearColor)
        self.bSign = true
    elseif self.bSign and tbData.SignType == DCProto.ESignType.DELETE then
        pWidgetRef.imgPoint:SetVisibility(Collapsed)
        self.bSign = false
    end
    local bStateChanged = self.tbData == nil or self.tbData.nState ~= tbData.nState
    self.tbData = tbData
    
    --logdebug("tbData.nHp,tbData.nMaxHp=",tbData.nHp,tbData.nMaxHp)
    
    if tbData.nInstanceId == GamePlayerSelfHelper:GetServerInstanceId() then
        if not self.tbHpDelegateHandle then
            local tbPlayerSelf = GamePlayerSelfHelper:Get()
            local PropertyComponent = tbPlayerSelf:GetCurrentPropertyComponent()
            self.tbHpDelegateHandle = self.EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnSelfHpChanged, self)
            OnSelfHpChanged(self)
        elseif bStateChanged then
            OnSelfHpChanged(self)
        end
    else
        UnregisterSelfHpHandle(self)
        local bDead = tbData.nState == DCProto.TeamInfo_EState.DEAD
        local nHpPercent = math.ceil(tbData.nHp) / tbData.nMaxHp
        if bDead and nHpPercent ~= 0 then  
            nHpPercent = 0
        end
        UpdateHP(self, nHpPercent)
    end
    if not self.tbSetVoiceLevelHandle then
        self.tbSetVoiceLevelHandle = self.EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_STATE, self, self.SetVoiceLevel)
    end
end

function UPBattleTeamMemberInfo:HideData()
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    self.EventHelper:UnregisterAll()
    self.tbHpDelegateHandle = nil
    self.tbSetVoiceLevelHandle = nil
    self.tbData = nil
end

function UPBattleTeamMemberInfo:Activate()
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    
    if self.tbData and self.tbData.nInstanceId == tbPlayerSelf:GetServerInstanceId() then
        --logdebug("self.tbData.nInstanceId=",self.tbData.nInstanceId,tbPlayerSelf:GetServerInstanceId(),tbPlayerSelf:GetName())
        UnregisterSelfHpHandle(self)
        local PropertyComponent = tbPlayerSelf:GetCurrentPropertyComponent()
        self.tbHpDelegateHandle = self.EventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnSelfHpChanged, self)
        OnSelfHpChanged(self)
    end
    if not self.tbSetVoiceLevelHandle then
        self.tbSetVoiceLevelHandle = self.EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_STATE, self, self.SetVoiceLevel)
    end
end

function UPBattleTeamMemberInfo:Deactivate()
    UnregisterSelfHpHandle(self)
end

return UPBattleTeamMemberInfo
