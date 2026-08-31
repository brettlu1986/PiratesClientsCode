-----------------------------------------------------
--File Name    : ULCreateRoleAvatar.lua
--Author       : WuJizhou
--Create Time  : 4/22/2020, 5:24:23 PM
--Description  : ULCreateRoleAvatar
-----------------------------------------------------
local luaclass                   = require("luaclass")
local UILogicBase                = require("UILogicBase")
local ULCreateRoleAvatar         = luaclass("ULCreateRoleAvatar", UILogicBase)

local CreateRoleUIDef            = require("CreateRoleUIDef")
local DefaultAppearanceDataTable = require("DefaultAppearanceDataTable")
local CreateRoleData             = require("CreateRoleData")
local LobbyHumanFashion3DOperator= require("LobbyHumanFashion3DOperator")


ULCreateRoleAvatar.nCurrentAvatarId = nil
ULCreateRoleAvatar.pLocation = nil
ULCreateRoleAvatar.pRotation = nil
ULCreateRoleAvatar.tbAppearance = nil
ULCreateRoleAvatar.Human3DOperator = nil

local SlotType = CreateRoleUIDef.SlotType

local function InitAppearance(self)
    local tbRet = {}
    for _, nSlotType in pairs(SlotType) do
        local tbAppearanceId = DefaultAppearanceDataTable:GetIdsByType(nSlotType, self.nGender)
        tbRet[nSlotType] = tbAppearanceId[1]
    end
    return tbRet
end

function ULCreateRoleAvatar:FittingAppearance(nAppearanceId, bNotRefreshAvatar)
    local tbData = DefaultAppearanceDataTable:GetData(nAppearanceId)
    local nType = tbData.nType
    local nValue = self.tbAppearance[nType]
    if nValue > 0 and nValue ~= nAppearanceId then
        self.tbAppearance[nType] = nAppearanceId
        self.Human3DOperator:SetAnimation(nil)
        self.Human3DOperator:Display(self.nCurrentAvatarId, {}, self.tbAppearance)
    end
end


function ULCreateRoleAvatar:UpdateAvatarById(nAvatarId)
    self.nCurrentAvatarId = nAvatarId
    self.Human3DOperator:SetActorLocation(self.pLocation)
    self.Human3DOperator:SetActorRotator(self.pRotation)
    local tbTemplate = CreateRoleData:GetTemplate(self.nGender)
    self.Human3DOperator:SetAnimation(tbTemplate.szShowAnimation)
    self.tbAppearance = InitAppearance(self)
    self.Human3DOperator:Display(nAvatarId, {}, self.tbAppearance, true)
end


function ULCreateRoleAvatar:Init(tbParams)
    self.nCurrentAvatarId = tbParams.nCurrentAvatarId
    self.pLocation = tbParams.pLocation
    self.pRotation = tbParams.pRotation
    self.nGender = tbParams.nGender
    self.tbAppearance = InitAppearance(self)
end

function ULCreateRoleAvatar:GetAppearance()
    return self.tbAppearance
end

----------life cycle----------
function ULCreateRoleAvatar:OnLoad()
    if not self.Human3DOperator then
        self.Human3DOperator = LobbyHumanFashion3DOperator()
        self.Human3DOperator:Init({bdrWidget = self.pWidgetRef.bdrActorListener})
        self.Human3DOperator:Activate()
    end
end


function ULCreateRoleAvatar:OnUnload()
    if self.Human3DOperator then
        self.Human3DOperator:Deactivate()
        self.Human3DOperator:Uninit()
        self.Human3DOperator = nil
    end
end

return ULCreateRoleAvatar