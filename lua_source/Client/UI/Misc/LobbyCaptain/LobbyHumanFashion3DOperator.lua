-----------------------------------------------------
--File Name    : LobbyHumanFashion3DOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyHumanFashion3DOperator = luaclass("LobbyHumanFashion3DOperator")

local ActorLocationHelper               = require("ActorLocationHelper")
local GameAvatarHelper                  = require("GameAvatarHelper")
local HumanAvatarData                   = require("HumanAvatarData")
local UEActorHelper                     = require("UEActorHelper")
local HumanDataTable                    = require("HumanDataTable")
local UIActorMouseOperator              = require("UIActorMouseOperator")
local SelfAnimationHelper               = require("SelfAnimationHelper")
local CppDelegate                       = require("CppDelegate")
local LobbyCaptainMiscDef               = require("LobbyCaptainMiscDef")
local LobbyWeaponMiscDataTable          = require("LobbyWeaponMiscDataTable")
local LobbyHumanWeapon3DOperator        = require("LobbyHumanWeapon3DOperator")
local ItemSystem                        = require("ItemSystem")
local HumanAvatarDef                    = require("HumanAvatarDef")
local HumanArmorDef                     = require("HumanArmorDef")
local HumanAvatarHelper                 = require("HumanAvatarHelper")
local UILobbyCaptainHelper              = require("UILobbyCaptainHelper")


LobbyHumanFashion3DOperator.tbLightChannelData = {false, true, false}
LobbyHumanFashion3DOperator.pLocation = Vector()
LobbyHumanFashion3DOperator.pRotator = Rotator()
LobbyHumanFashion3DOperator.pScale = Vector{ X= 1, Y = 1, Z = 1}
LobbyHumanFashion3DOperator.pHumanActor = nil
LobbyHumanFashion3DOperator.HumanAvatarData = nil
LobbyHumanFashion3DOperator.nArmorLevel = nil
LobbyHumanFashion3DOperator.nArmorType = nil
LobbyHumanFashion3DOperator.nAvatarId = nil
LobbyHumanFashion3DOperator.szAnimKey = nil
LobbyHumanFashion3DOperator.bInit = false
LobbyHumanFashion3DOperator.nWeaponInstanceType = nil
LobbyHumanFashion3DOperator.nFashionItemTemplateId = nil
LobbyHumanFashion3DOperator.Weapon3DOperator = nil
LobbyHumanFashion3DOperator.bUseDefaultWeaponAnim = true
LobbyHumanFashion3DOperator.tbArmorFlag = nil

local FashionType = HumanAvatarDef.FashionType

local function LogInternal(szLog)
    -- luacheck: push ignore 113
    log("LobbyHumanFashion3DOperator", szLog)
    -- luacheck: pop
end


local function UpdateWeapon(self)
    if self.nWeaponInstanceType then
        if self.nWeaponInstanceType ~= LobbyCaptainMiscDef.UnarmedWeaponInstanceType then
            self.Weapon3DOperator:SetUseDummyBP(false)
            self.Weapon3DOperator:Display(self.nWeaponInstanceType, self.nFashionItemTemplateId)
            self.Weapon3DOperator:SetWeaponVisible(true)
        else
            self.Weapon3DOperator:SetWeaponVisible(false)
        end
    end
end

local function AttachWeaponToHuman(self)
    if not self.Weapon3DOperator then
        LogInternal("AttachWeaponToHuman, Weapon3DOperator is nil")
        return
    end
    local pWeaponActor = self.Weapon3DOperator:GetWeaponActor()
    local pHumanActor = self.pHumanActor
    if not pHumanActor then
        LogInternal("AttachWeaponToHuman, pHumanActor is nil")
        return
    end
    
    if not pWeaponActor then
        LogInternal("AttachWeaponToHuman, pWeaponActor is nil")
        return
    end

    local tbMisc
    if self.nWeaponInstanceType ~= LobbyCaptainMiscDef.UnarmedWeaponInstanceType then
        tbMisc = LobbyWeaponMiscDataTable:GetTemplate(self.nWeaponInstanceType)
        -- local szSocket = pHumanActor[tbMisc.szSocketName]
        -- attach to Human socket
        pWeaponActor:K2_AttachToComponent(pHumanActor.Mesh, tbMisc.szSocketName, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
    else
        tbMisc = LobbyWeaponMiscDataTable:GetTemplate(LobbyCaptainMiscDef.UnarmedWeaponInstanceType)
    end
    if self.bUseDefaultWeaponAnim then
        self.szAnimKey = tbMisc.szAnimKey
    end
end

local function DetachWeaponFromHuman(self)
    if self.Weapon3DOperator then
        local pWeaponActor = self.Weapon3DOperator:GetWeaponActor()
        if pWeaponActor then
            pWeaponActor:K2_DetachFromActor(EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative)
        end
    end
end

local function PlayAnimation(self)
    if self.pHumanActor and isvalidhandle(self.pHumanActor) and self.szAnimKey then
        SelfAnimationHelper:PlayActorAnimation(self.pHumanActor, self.nAvatarId, self.szAnimKey)
    end
end

local function OnUpdateCommit(self)
    UpdateWeapon(self)
    AttachWeaponToHuman(self)
    PlayAnimation(self)
end

local function UnbindCommitDelegate(self)
    if self.CommitDelegate then
        self.CommitDelegate:Unbind()
    end
    self.CommitDelegate = nil
end

local function BindCommitDelegate(self)
    UnbindCommitDelegate(self)
    self.CommitDelegate = CppDelegate:Bind(self.pHumanActor.HumanAvatarComponent.OnCommitFinishDelegate, function ()
        OnUpdateCommit(self)
    end)
end

local function DestroyHumanActor(self)
    if self.pHumanActor and isvalidhandle(self.pHumanActor) then
        DetachWeaponFromHuman(self)
        UnbindCommitDelegate(self)
        UEActorHelper:DestroyActor(self.pHumanActor)
        self.pHumanActor = nil
    end
end

local function OnPostCreateActor(self)
    ActorLocationHelper:SetHumanLocationBasedOnFoot(self.pHumanActor, self.pLocation)
    if self.UIActorMouseOperator then
        self.UIActorMouseOperator:UpdateActor(self.pHumanActor)
    end
end

local function CreateHumanActor(self, nAvatarId)
    local tbHumanData = HumanDataTable:GetResData(nAvatarId)
    if not tbHumanData then
        error(string.format("LobbyHumanFashion3DOperator error, nAvatarId is invalid, value is %d", nAvatarId))
		return
    end

	local szPawnClassName = tbHumanData.szPawnClassName
    local _, pHumanActor = UEActorHelper:CreateActor(szPawnClassName, self.pLocation, self.pRotator, self.pScale)
    pHumanActor.HumanAvatarComponent:SetForceLOD(1)
    return pHumanActor, nAvatarId
end


local function UpdateHumanActor(self, nAvatarId)
    if nAvatarId ~= self.nAvatarId then
        DestroyHumanActor(self)
        self.pHumanActor, self.nAvatarId = CreateHumanActor(self, nAvatarId)
        OnPostCreateActor(self)
    else
        if not self.pHumanActor then
            self.pHumanActor, self.nAvatarId = CreateHumanActor(self, nAvatarId)
            OnPostCreateActor(self)
        end
    end
end


local function UpdateHumanFashion(self, tbFashionItemTemplateIds, tbAppearanceIds, bNotParseAppearance)
    if not tbFashionItemTemplateIds then
        tbFashionItemTemplateIds = {}
    end
    assert(tbAppearanceIds)

    BindCommitDelegate(self)
    local pHumanActor = self.pHumanActor
    local tbAppearancePartData 
    if bNotParseAppearance then
        tbAppearancePartData = tbAppearanceIds
    else
        tbAppearancePartData = HumanAvatarHelper.ParseToPartDataFromAppearance(tbAppearanceIds)
    end
    local tbBasicFashionPartData, tbArmorFashionPartData = HumanAvatarHelper.ParseToPartDataFromFashionItemTemplate(tbFashionItemTemplateIds)

    self.HumanAvatarData:SetAppearanceData(tbAppearancePartData)
    self.HumanAvatarData:SetBasicFashionData(tbBasicFashionPartData)
    self.HumanAvatarData:SetArmorFashionData(tbArmorFashionPartData)
    self.HumanAvatarData:SetArmorFashionFlagTable(self.tbArmorFlag)
    self.HumanAvatarData:SetArmorTypeAndLevel(self.nArmorType, self.nArmorLevel)

    GameAvatarHelper.UpdateHumanAvatar(pHumanActor.HumanAvatarComponent, self.HumanAvatarData:GetPartDatas())
end

local function AppendHumanFashion(self, nFashionItemTemplateId)
    local tbTemplate = ItemSystem:GetItemTemplate(nFashionItemTemplateId)
    if  tbTemplate.nFashionType == FashionType.Basic then
        local tbDeltaData = HumanAvatarHelper.ParseToPartDataFromBasicFashionItemTemplate({nFashionItemTemplateId})
        self.HumanAvatarData:ModifyBasicFashionData(tbDeltaData)
        self.HumanAvatarData:SetArmorTypeAndLevel(nil, nil)
    else
        local tbDeltaData = HumanAvatarHelper.ParseToPartDataFromArmorFashionItemTemplate({nFashionItemTemplateId}, true)
        self.HumanAvatarData:ModifyArmorFashionData(tbDeltaData)
        local nArmorType = HumanAvatarHelper.FashionTypeToArmorType[tbTemplate.nFashionType]
        self.HumanAvatarData:SetArmorTypeAndLevel(nArmorType, HumanArmorDef.MAX_LEVEL)
    end
    GameAvatarHelper.UpdateHumanAvatar(self.pHumanActor.HumanAvatarComponent, self.HumanAvatarData:GetPartDatas())
end

local function InitWeapon3DOperator(self)
    local Weapon3DOperator = self.Weapon3DOperator
    if not Weapon3DOperator then
        Weapon3DOperator = LobbyHumanWeapon3DOperator()
        self.Weapon3DOperator = Weapon3DOperator
    end
    Weapon3DOperator:Init()
end


local function HideHumanActor(self)
    if self.pHumanActor then
        self.pHumanActor:SetActorHiddenInGame(true)
        local ChildActors = self.pHumanActor:GetAttachedActors()
        for i,v in ipairs(ChildActors) do
            v:SetActorHiddenInGame(true)
        end
    end
end

local function ShowHumanActor(self)
    if self.pHumanActor then
        self.pHumanActor:SetActorHiddenInGame(false)
        local ChildActors = self.pHumanActor:GetAttachedActors()
        for i,v in ipairs(ChildActors) do
            v:SetActorHiddenInGame(false)
        end
    end
end


local function HideWeaponActor(self)
    if self.Weapon3DOperator then
        self.Weapon3DOperator:SetWeaponVisible(false)
    end
end

local function ShowWeaponActor(self)
    if self.Weapon3DOperator then
        self.Weapon3DOperator:SetWeaponVisible(true)
    end
end

local function GetArmorFlagData(self)
    local tbArmorFlag = self.tbArmorFlag
    if not tbArmorFlag then
        tbArmorFlag = {}
        self.tbArmorFlag = tbArmorFlag
    end
    return tbArmorFlag
end

function LobbyHumanFashion3DOperator:SetVisible(bVisible)
    if bVisible then
        ShowHumanActor(self)
        ShowWeaponActor(self)
    else
        HideHumanActor(self)
        HideWeaponActor(self)
    end
end

-- tbFashionItemTemplateIds 可为空
-- tbAppearanceIds 可为空
function LobbyHumanFashion3DOperator:Display(nAvatarId, tbFashionItemTemplateIds, tbAppearanceIds, bResetRotator)
    if not self.bInit then
        self:Init()
    end
    UpdateHumanActor(self, nAvatarId)
    UpdateHumanFashion(self, tbFashionItemTemplateIds, tbAppearanceIds)
    if bResetRotator then
        self.pHumanActor:K2_SetActorRotation(self.pRotator)
    end
    return self.pHumanActor
end

function LobbyHumanFashion3DOperator:DisplaySuit(nAvatarId, tbFashionItemTemplateIds, tbAppearanceIds, bResetRotator)
    assert(#tbFashionItemTemplateIds > 1)
    local nTemplateId = tbFashionItemTemplateIds[1]
    local tbTemplate = ItemSystem:GetItemTemplate(nTemplateId)
    local szAnim = UILobbyCaptainHelper.GetHumanAnimationByFashionTemplateId(nTemplateId)
    self:SetAnimation(szAnim)
    if  tbTemplate.nFashionType == HumanAvatarDef.FashionType.Basic then
        self:SetArmorTypeAndLevel(nil, nil)
    else
        local nAmorType = HumanAvatarHelper.FashionTypeToArmorType[tbTemplate.nFashionType]
        self:SetArmorTypeAndLevel(nAmorType, HumanArmorDef.MAX_LEVEL)
    end
    return self:Display(nAvatarId, tbFashionItemTemplateIds, tbAppearanceIds, bResetRotator)
end


function LobbyHumanFashion3DOperator:DisplayOne(nAvatarId, nTemplateId, tbAppearanceIds, bResetRotator)
    local tbTemplate = ItemSystem:GetItemTemplate(nTemplateId)
    local szAnim = UILobbyCaptainHelper.GetHumanAnimationByFashionTemplateId(nTemplateId)
    self:SetAnimation(szAnim)
    if  tbTemplate.nFashionType == HumanAvatarDef.FashionType.Basic then
        self:SetArmorTypeAndLevel(nil, nil)
    else
        local nAmorType = HumanAvatarHelper.FashionTypeToArmorType[tbTemplate.nFashionType]
        self:SetArmorTypeAndLevel(nAmorType, HumanArmorDef.MAX_LEVEL)
    end
    return self:Display(nAvatarId, {nTemplateId}, tbAppearanceIds, bResetRotator)
end

function LobbyHumanFashion3DOperator:DisplayWithAppearanceData(nAvatarId, tbFashionItemTemplateIds, tbAppearancePartData, bResetRotator)
    if not self.bInit then
        self:Init()
    end
    UpdateHumanActor(self, nAvatarId)
    UpdateHumanFashion(self, tbFashionItemTemplateIds, tbAppearancePartData, true)
    if bResetRotator then
        self.pHumanActor:K2_SetActorRotation(self.pRotator)
    end
    return self.pHumanActor
end


function LobbyHumanFashion3DOperator:Append(nFashionItemTemplateId)
    AppendHumanFashion(self, nFashionItemTemplateId)
end

function LobbyHumanFashion3DOperator:SetActorLocation(pVector)
    self.pLocation = pVector
end

function LobbyHumanFashion3DOperator:SetActorRotator(pRotator)
    self.pRotator = pRotator
end

function LobbyHumanFashion3DOperator:SetActorScale(pVector)
    self.pScale = pVector
end

function LobbyHumanFashion3DOperator:SetActorNumberScale(nValue)
    self:SetActorScale(Vector{ X= nValue, Y = nValue, Z = nValue})
end

function LobbyHumanFashion3DOperator:SetLightChannel(tbData)
    self.tbLightChannelData = tbData
end

function LobbyHumanFashion3DOperator:SetArmorTypeAndLevel(nArmorType, nArmorLevel)
    self.nArmorType = nArmorType
    self.nArmorLevel = nArmorLevel
end

function LobbyHumanFashion3DOperator:SetArmorFashionFlag(nArmorType, bOverride)
    local tbArmorFlag = GetArmorFlagData(self)
    tbArmorFlag[nArmorType] = bOverride
end

function LobbyHumanFashion3DOperator:SetAnimation(szAnimKey)
    self.szAnimKey = szAnimKey
end

function LobbyHumanFashion3DOperator:SetWeapon(nWeaponInstanceType, nFashionItemTemplateId, bNotUseDefaultAnim)
    self.nWeaponInstanceType = nWeaponInstanceType
    self.nFashionItemTemplateId = nFashionItemTemplateId
    self.bUseDefaultWeaponAnim = not bNotUseDefaultAnim
end


function LobbyHumanFashion3DOperator:BindTouchWidget(pTouchWidget)
    local MouseOperator = self.UIActorMouseOperator
    if MouseOperator then
        MouseOperator:Uninit()
        self.UIActorMouseOperator = nil
    end
    MouseOperator = UIActorMouseOperator()
    self.UIActorMouseOperator = MouseOperator
    MouseOperator:Init(pTouchWidget, self.pHumanActor)
    MouseOperator:Activate()
end

function LobbyHumanFashion3DOperator:UpdateDisplayByArmorLevel(nArmorLevel)
    if not self.nArmorType then
        return
    end
    self.nArmorLevel = nArmorLevel
    local pHumanActor = self.pHumanActor
    if pHumanActor then
        BindCommitDelegate(self)
        -- self:SetAnimation(nil)
        self.HumanAvatarData:SetArmorTypeAndLevel(self.nArmorType, self.nArmorLevel)
        GameAvatarHelper.UpdateHumanAvatar(pHumanActor.HumanAvatarComponent, self.HumanAvatarData:GetPartDatas())
    end
end

function LobbyHumanFashion3DOperator:ChangeWeapon(nWeaponInstanceType, nFashionItemTemplateId)
    self:SetWeapon(nWeaponInstanceType, nFashionItemTemplateId)
    UpdateWeapon(self)
    AttachWeaponToHuman(self)
    PlayAnimation(self)
end


function LobbyHumanFashion3DOperator:GetHumanActor()
    return self.pHumanActor
end

function LobbyHumanFashion3DOperator:Init(tbParam)
    if not self.bInit then
        if tbParam then
            local bdrWidget = tbParam.bdrWidget
            if bdrWidget then
                self.UIActorMouseOperator = UIActorMouseOperator()
                self.UIActorMouseOperator:Init(bdrWidget, nil)
            end
        end
        self.HumanAvatarData = HumanAvatarData()
        InitWeapon3DOperator(self)
        self.bInit = true
    end
end

function LobbyHumanFashion3DOperator:Uninit()
    if self.UIActorMouseOperator then
        self.UIActorMouseOperator:Uninit()
    end
    UnbindCommitDelegate(self)
    if self.Weapon3DOperator then
        self.Weapon3DOperator:Uninit()
        self.Weapon3DOperator = nil
    end
    self.HumanAvatarData = nil
    DestroyHumanActor(self)
    self.bInit = false
end

function LobbyHumanFashion3DOperator:Activate()
    if self.UIActorMouseOperator then
        self.UIActorMouseOperator:Activate()
    end
    if self.Weapon3DOperator then
        self.Weapon3DOperator:Activate()
    end
    self:SetVisible(true)
end

function LobbyHumanFashion3DOperator:Deactivate()
    self:SetVisible(false)
    if self.UIActorMouseOperator then
        self.UIActorMouseOperator:Deactivate()
    end
    if self.Weapon3DOperator then
        self.Weapon3DOperator:Deactivate()
    end
end


return LobbyHumanFashion3DOperator