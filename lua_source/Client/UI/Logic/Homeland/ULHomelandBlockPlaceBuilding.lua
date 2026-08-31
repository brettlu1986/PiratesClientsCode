-----------------------------------------------------
--File Name    : ULHomelandBlockPlaceBuilding.lua
--Author       : WuJizhou
--Create Time  : 5/13/2019, 5:38:13 PM
--Description  : ULHomelandBlockPlaceBuilding
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULHomelandBlockPlaceBuilding = luaclass("ULHomelandBlockPlaceBuilding", UILogicBase)
local HomelandSceneSystem = require("HomelandSceneSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BlockTypeDataTable = require("BlockTypeDataTable")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UIStateDef = require("UIStateDef")
local HomelandSceneDataTable = require("HomelandSceneDataTable")
local HomelandSystem = require("HomelandSystem")
local UITextDef = require("UITextDef")

local UNIT = 100

local function RotatePosition(nX, nY, nYaw)
    local PI = math.pi
    local nCosYaw = math.cos(nYaw * PI/ 180)
    local nSinYaw = math.sin(nYaw * PI/ 180)
    local X =  nCosYaw * nX + nSinYaw * nY
    local Y =  nCosYaw * nY - nSinYaw * nX
    return X, Y
end

local function CheckPlayerPosition(self, tbBlockData)
    local nBlockType = tbBlockData.nBlockType
    local nBlockId = tbBlockData.nBlockId
    local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
    assert(tbBlockTypeTemplate)
    local nLength = tbBlockTypeTemplate.nLength
    local nWidth = tbBlockTypeTemplate.nWidth
    local tbBlockGO = HomelandSceneSystem:GetBlock(nBlockId)
    local Location = tbBlockGO:GetLocation()
    local Player = GamePlayerSelfHelper:Get()
    local PlayerLocation = Player:GetLocation()
    local tbDescriptor = HomelandSceneDataTable:GetSceneDescriptor(HomelandSystem:GetCurrentSceneId())
    local tbHomelandBlock = tbDescriptor.HomelandBlock
    local tbBlockDescriptorData = tbHomelandBlock[nBlockId]
    local nYaw = tbBlockDescriptorData.Transform.Yaw
    local nX, nY = RotatePosition(PlayerLocation.X, PlayerLocation.Y, nYaw)
    local nXC, nYC = RotatePosition(Location.X, Location.Y, nYaw)
    if math.abs(nX - nXC) <= nLength * UNIT / 2 and math.abs(nY - nYC) <= nWidth * UNIT / 2 then
        UIUtils.ShowToast(UITextDef.HOMELAND_MOVE_OUT_OF_BLOCK)
        return false
    end
    return true
end

function ULHomelandBlockPlaceBuilding:Do(tbBlockData)
    if CheckPlayerPosition(self, tbBlockData) then
        UIManager:PushState(UIStateDef.StateName.UI_HOMELAND_BUILD_STATE, { nBlockId = tbBlockData.nBlockId })
    end
end


return ULHomelandBlockPlaceBuilding