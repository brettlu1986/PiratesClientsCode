-----------------------------------------------------
--File Name    : SceneItemPackageRoom.lua
--Author       : zhiyuan
--Create Time  : 2018-08-21
--Description  : 场景中物品room
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemRoomBase = require("BattleItemRoomBase")
local SceneItemPackageRoom = luaclass("SceneItemPackageRoom", BattleItemRoomBase)
local BattleItemSystemHelper = require("BattleItemSystemHelper")

SceneItemPackageRoom.szLastOwnerName = nil

function SceneItemPackageRoom:GetLastOwnerName()
    return self.szLastOwnerName
end

function SceneItemPackageRoom:SetLastOwnerName(szName)
    self.szLastOwnerName = szName
end

function SceneItemPackageRoom:SetItemInstanceIds(tbItemInstanceIds)
    self.tbItemList = tbItemInstanceIds
end

function SceneItemPackageRoom:GetProtoDataOnServer()
    local tbSceneItemPackageRoom = {}
    local nInstanceId = self:GetRoomId()
    tbSceneItemPackageRoom.instance_id = nInstanceId
    tbSceneItemPackageRoom.last_owner_name = self.szLastOwnerName
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local BoxItem = BattleItemSystemServer:GetItem(nInstanceId)
    local tbBoxItemTemplateId = BoxItem:GetTemplateId()
    tbSceneItemPackageRoom.template_id = tbBoxItemTemplateId
    tbSceneItemPackageRoom.items = {}
    return tbSceneItemPackageRoom
end

return SceneItemPackageRoom