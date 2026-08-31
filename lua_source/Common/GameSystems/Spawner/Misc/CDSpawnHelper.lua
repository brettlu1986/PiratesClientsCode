local CDSpawnHelper = {}

local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")

local tbItemDropIdToCallbackInfo = nil
local tbItemDropSpawnerToIds     = nil

local function AddItemInstanceId(tbSpawner, fnCallback, nInstanceId, bDestoryIfFire)
    local tbCallbackInfo = {}
    tbCallbackInfo.fnCallback = fnCallback
    tbCallbackInfo.tbSpawner = tbSpawner
    tbCallbackInfo.bDestoryIfFire = bDestoryIfFire
    tbItemDropIdToCallbackInfo[nInstanceId] = tbCallbackInfo
    tbItemDropSpawnerToIds[tbSpawner] = tbItemDropSpawnerToIds[tbSpawner] or {}
    tbItemDropSpawnerToIds[tbSpawner][nInstanceId] = true
end

local function RemoveItemInstanceId(tbSpawner, nInstanceId)
    tbItemDropSpawnerToIds[tbSpawner][nInstanceId] = nil
    tbItemDropIdToCallbackInfo[nInstanceId] = nil
end

local function OnAfterPickUpItem(self, _, nInstanceId)
    local tbCallbackInfo = tbItemDropIdToCallbackInfo[nInstanceId]
    if tbCallbackInfo and tbCallbackInfo.fnCallback then
        tbCallbackInfo.fnCallback(tbCallbackInfo.tbSpawner, nInstanceId)

        if tbCallbackInfo.bDestoryIfFire then
            RemoveItemInstanceId(tbCallbackInfo.tbSpawner, nInstanceId)
        end
    end
end

function CDSpawnHelper:Init()
    tbItemDropIdToCallbackInfo = {}
    tbItemDropSpawnerToIds = {}

    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_ITEM_AFTER_PICK_UP_SERVER, self, OnAfterPickUpItem)
end

function CDSpawnHelper:Uninit()
    tbItemDropIdToCallbackInfo = nil
    tbItemDropSpawnerToIds = nil

    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_ITEM_AFTER_PICK_UP_SERVER, self, OnAfterPickUpItem)
end

function CDSpawnHelper:ItemBind(tbSpawner, fnCallback, nInstanceId, bDestoryIfFire)
    AddItemInstanceId(tbSpawner, fnCallback, nInstanceId, bDestoryIfFire)
end

function CDSpawnHelper:ItemUnBind(tbSpawner, nInstanceId)
    RemoveItemInstanceId(tbSpawner, nInstanceId)
end

function CDSpawnHelper:ItemUnBindAll(tbSpawner)
    local Ids = tbItemDropSpawnerToIds[tbSpawner]

    if Ids then
        for _, nInstanceId in pairs(Ids) do
            RemoveItemInstanceId(tbSpawner, nInstanceId)
        end

        tbItemDropSpawnerToIds[tbSpawner] = nil
    end
end

return CDSpawnHelper
