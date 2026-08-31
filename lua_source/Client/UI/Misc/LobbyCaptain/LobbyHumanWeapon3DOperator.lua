-----------------------------------------------------
--File Name    : LobbyHumanWeapon3DOperator.lua
--Description  :
-----------------------------------------------------

local luaclass = require("luaclass")
local LobbyHumanWeapon3DOperator = luaclass("LobbyHumanWeapon3DOperator")

local UEActorHelper                 = require("UEActorHelper")
local LobbyCaptainMiscDef           = require("LobbyCaptainMiscDef")
local HumanWeaponAvatarResPartDef   = require("HumanWeaponAvatarResPartDef")
local GameAvatarHelper              = require("GameAvatarHelper")
local UIActorMouseOperator          = require("UIActorMouseOperator")
local LobbyWeaponMiscDataTable      = require("LobbyWeaponMiscDataTable")
local ItemSystem                    = require("ItemSystem")
local HumanWeaponFashionDataTable   = require("HumanWeaponFashionDataTable")
local HumanWeaponDef                = require("HumanWeaponDef")
local HumanWeaponDefaultDataTable   = require("HumanWeaponDefaultDataTable")


local DisplayMiscDataField = LobbyWeaponMiscDataTable.DisplayMiscDataField

local DUMMY_WEAPON_BP = "Blueprint'/Game/Game/CharacterEx/Weapon/BP_LobbyHumanWeapon.BP_LobbyHumanWeapon_C'"

LobbyHumanWeapon3DOperator.nCurrentWeaponInstanceType = nil
LobbyHumanWeapon3DOperator.pRelativeLocation = Vector()
LobbyHumanWeapon3DOperator.pRelativeRotation = Rotator()
LobbyHumanWeapon3DOperator.pRelativeScale = Vector()
LobbyHumanWeapon3DOperator.tbLightChannelData = {true, false, false}
LobbyHumanWeapon3DOperator.pLocation = Vector()
LobbyHumanWeapon3DOperator.pRotator = Rotator()
LobbyHumanWeapon3DOperator.pScale = Vector{ X= 1, Y = 1, Z = 1}
LobbyHumanWeapon3DOperator.pWeaponActor = nil
LobbyHumanWeapon3DOperator.nItemTemplateId = nil
LobbyHumanWeapon3DOperator.bUseDummyBP = true



local function RefreshRelativePosition(self, pActor, tbMiscData)
    if tbMiscData then
        local tbLocation = tbMiscData[DisplayMiscDataField.Location]
        if tbLocation then
            self.pRelativeLocation.X = tbLocation[1]
            self.pRelativeLocation.Y = tbLocation[2]
            self.pRelativeLocation.Z = tbLocation[3]
            pActor:K2_SetActorRelativeLocation(self.pRelativeLocation, false, false)
        end
          
        local tbRotation = tbMiscData[DisplayMiscDataField.Rotation]
        if tbRotation then
            self.pRelativeRotation.Roll = tbRotation[1]
            self.pRelativeRotation.Pitch = tbRotation[2]
            self.pRelativeRotation.Yaw = tbRotation[3]
            pActor:K2_SetActorRelativeRotation(self.pRelativeRotation, false, false)
        end
        
        local nScale = tbMiscData[DisplayMiscDataField.Scale]
        self.pRelativeScale.X = nScale
        self.pRelativeScale.Y = nScale
        self.pRelativeScale.Z = nScale
        pActor:SetActorScale3D(self.pRelativeScale)
    end
end

local function UpdateWeaponAvatar(self, nPartId)
    if nPartId then
    local tbPartData = {}
        tbPartData[HumanWeaponAvatarResPartDef.Trunk] = nPartId
        EngineExtActorShell.SetActorSkeletalMeshLightChannel(self.pWeaponActor, self.tbLightChannelData[1], self.tbLightChannelData[2], self.tbLightChannelData[3])
        
        if self.bUseDummyBP then
            local tbTemplate = LobbyWeaponMiscDataTable:GetTemplate(self.nCurrentWeaponInstanceType)
            local szWeaponSocket = tbTemplate.szWeaponCenterSocket
            self.pWeaponActor.CurrentCenterSocketName = szWeaponSocket
        end
        GameAvatarHelper.UpdateWeaponAvatar(self.pWeaponActor.AvatarComponent, tbPartData)
    else
        logwarning("LobbyCaptainWeapon", "weapon part id does not exist, instance type is ", self.nCurrentWeaponInstanceType)
    end
end

local function CreateWeaponActor(self, tbDisplayMiscData)
    if self.nCurrentWeaponInstanceType == LobbyCaptainMiscDef.UnarmedWeaponInstanceType then
        return
    end
    local szBPClassName
    if self.bUseDummyBP then
        szBPClassName = DUMMY_WEAPON_BP
    else
        local tbWeaponData = HumanWeaponDefaultDataTable:GetAllLevelData(self.nCurrentWeaponInstanceType)
        szBPClassName = tbWeaponData.szBPClassName
    end
    -- spawn bp weapon for instance type
    local _, pWeaponActor = UEActorHelper:CreateActor(szBPClassName, self.pLocation, self.pRotator, self.pScale)
    RefreshRelativePosition(self, pWeaponActor, tbDisplayMiscData)
    return pWeaponActor
end

local function DestroyWeaponActor(self)
    if self.pWeaponActor then
        UEActorHelper:DestroyActor(self.pWeaponActor)
        self.pWeaponActor = nil
    end
end

local function HideWeaponActor(self)
    if self.pWeaponActor then
        self.pWeaponActor:SetActorHiddenInGame(true)
        local ChildActors = self.pWeaponActor:GetAttachedActors()
        for i,v in ipairs(ChildActors) do
            v:SetActorHiddenInGame(true)
        end
    end
end

local function ShowWeaponActor(self)
    if self.pWeaponActor then
        self.pWeaponActor:SetActorHiddenInGame(false)
        local ChildActors = self.pWeaponActor:GetAttachedActors()
        for i,v in ipairs(ChildActors) do
            v:SetActorHiddenInGame(false)
        end
    end
end


local function ParseToWeaponInstanceTypeAndPartId(nWeaponInstanceType, nItemTemplateId)
    local nPartId
    if not nItemTemplateId then
        assert(nWeaponInstanceType)
        local tbWeaponData = HumanWeaponDefaultDataTable:GetAllLevelData(nWeaponInstanceType)
        nPartId = tbWeaponData[HumanWeaponDef.MAX_LEVEL].nDefaultTrunkPartId
    else
        local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
        nWeaponInstanceType = tbItemTemplate.nSubCategory
        local nFashionId = tbItemTemplate.nFashionId
        -- wow~ refresh fashion avatar
        local tbFashionTemplate = HumanWeaponFashionDataTable:GetFashionTemplate(nFashionId, HumanWeaponDef.MAX_LEVEL)
        nPartId = tbFashionTemplate.nTrunkPartId
    end
    return nWeaponInstanceType, nPartId
end

local function GetAvatarPartIdByLevel(self, nLevel)
    local nPartId
    if not self.nItemTemplateId then
        local tbWeaponData = HumanWeaponDefaultDataTable:GetAllLevelData(self.nCurrentWeaponInstanceType)
        nPartId = tbWeaponData[nLevel].nDefaultTrunkPartId
    else
        local tbItemTemplate = ItemSystem:GetItemTemplate(self.nItemTemplateId)
        local nFashionId = tbItemTemplate.nFashionId
        -- wow~ refresh fashion avatar
        local tbFashionTemplate = HumanWeaponFashionDataTable:GetFashionTemplate(nFashionId, nLevel)
        nPartId = tbFashionTemplate.nTrunkPartId
    end
    return nPartId
end

function LobbyHumanWeapon3DOperator:SetActorLocation(pVector)
    self.pLocation = pVector
end

function LobbyHumanWeapon3DOperator:SetActorRotator(pRotator)
    self.pRotator = pRotator
end

function LobbyHumanWeapon3DOperator:SetActorScale(pVector)
    self.pScale = pVector
end

function LobbyHumanWeapon3DOperator:SetLightChannel(tbData)
    self.tbLightChannelData = tbData
end

function LobbyHumanWeapon3DOperator:GetWeaponActor()
    return self.pWeaponActor
end

function LobbyHumanWeapon3DOperator:SetUseDummyBP(bUse)
    self.bUseDummyBP = bUse
end

function LobbyHumanWeapon3DOperator:SetWeaponVisible(bVisible)
    if bVisible then
        ShowWeaponActor(self)
    else
        HideWeaponActor(self)
    end
end
-- nItemTemplateId不为nil 可以不传nWeaponInstanceType
-- nItemTemplateId为nil 则必须传nWeaponInstanceType, 此时显示default
function LobbyHumanWeapon3DOperator:Display(nWeaponInstanceType, nItemTemplateId, tbDisplayMiscData)
    if not nWeaponInstanceType and not nItemTemplateId then
        logerror("LobbyHumanWeapon3DOperator:Display Error! WeaponInstanceType and TemplateId are nil")
        return
    end

    local nPartId
    nWeaponInstanceType, nPartId = ParseToWeaponInstanceTypeAndPartId(nWeaponInstanceType, nItemTemplateId)
    self.nItemTemplateId = nItemTemplateId
    if nWeaponInstanceType ~= self.nCurrentWeaponInstanceType then
        DestroyWeaponActor(self)
        self.nCurrentWeaponInstanceType = nWeaponInstanceType
        self.pWeaponActor = CreateWeaponActor(self, tbDisplayMiscData)
        if self.UIActorMouseOperator then
            self.UIActorMouseOperator:UpdateActor(self.pWeaponActor)
        end
    end
    UpdateWeaponAvatar(self, nPartId)
end

function LobbyHumanWeapon3DOperator:UpdateDisplayByLevel(nLevel)
    if not self.nCurrentWeaponInstanceType then
        return
    end
    local nPartId = GetAvatarPartIdByLevel(self, nLevel)
    UpdateWeaponAvatar(self, nPartId)
end

function LobbyHumanWeapon3DOperator:Init(tbParam)
    if tbParam then
        local bdrWidget = tbParam.bdrWidget
        if bdrWidget then
            self.UIActorMouseOperator = UIActorMouseOperator()
            self.UIActorMouseOperator:Init(bdrWidget, nil)
        end
    end
end

function LobbyHumanWeapon3DOperator:Uninit()
    if self.UIActorMouseOperator then
        self.UIActorMouseOperator:Uninit()
    end
    DestroyWeaponActor(self)
end

function LobbyHumanWeapon3DOperator:Activate()
    if self.UIActorMouseOperator then
        self.UIActorMouseOperator:Activate()
    end
    ShowWeaponActor(self)
end

function LobbyHumanWeapon3DOperator:Deactivate()
    if self.UIActorMouseOperator then
        self.UIActorMouseOperator:Deactivate()
    end
    HideWeaponActor(self)
end


return LobbyHumanWeapon3DOperator