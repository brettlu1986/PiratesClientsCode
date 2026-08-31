local GameComponentCreateHelper = {}

local GameObjectTypeDef = require("GameObjectTypeDef")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local tbEnvironmentType = GameComponentTypeDefine.tbEnvironmentType

GameComponentCreateHelper.tbClassTypeMap = nil
GameComponentCreateHelper.tbInfos = nil


-- GameComponentCreateHelper:Register(szClassName, nType, nEnvironmentType, nActorType, nLifeCycleType, bDynamicRequire, szComponentName)
-- szClassName: require的component名称
-- nObjectType: Object的类别，值参考GameComponentTypeDefine.tbObjectClassType
-- nEnvironmentType：战斗或者公海，值参考GameComponentTypeDefine.tbEnvironmentType
-- nActorType：船或者人，值参考GameComponentTypeDefine.tbActorType
-- nLifeCycleType：Component的生命周期，WithUEActor：随着UEActor创建和销毁，WithGameObject，随着GameObject创建和销毁，与UEActor的生命周期无关
-- bDynamicRequire：是否需要dynamic_require
-- szComponentName：生成的成员变量名称，默认nil，生成和szClassName一样的成员变量，GameObject创建完Component后可以直接使用GameObject.ComponentName访问

function GameComponentCreateHelper:Register(szClassName, nClassType, nEnvironmentType,
    nActorType, nLifeCycleType, bDynamicRequire, szComponentName)

    if(szClassName == nil or szClassName == "") then
        error("GameComponentCreateHelper:Register faield, the class name is invalid")
        return
    end

    local tbNewInfo = {}
    tbNewInfo.szClassName = szClassName
    tbNewInfo.nClassType = nClassType
    tbNewInfo.nEnvironmentType = nEnvironmentType
    tbNewInfo.nActorType = nActorType
    tbNewInfo.nLifeCycleType = nLifeCycleType
    tbNewInfo.bDynamicRequire = bDynamicRequire
    if(szComponentName == nil or szComponentName == "") then
        tbNewInfo.szComponentName = szClassName
    else
        tbNewInfo.szComponentName = szComponentName
    end
    table.insert(self.tbInfos, tbNewInfo)
end

local function CreateComponent(tbGameObject, szClassName, szComponentName, bDynamicRequire)
    local tbComponent = tbGameObject[szComponentName]
    if(tbComponent ~= nil) then
        --logerror("GameComponentCreateHelper:CreateComponent failed, the gameobject has duplicated component", szClassName, szComponentName)
        return tbComponent
    end

    tbComponent = tbGameObject:CreateComponent(szClassName, bDynamicRequire)
    tbGameObject[szComponentName] = tbComponent

    local tbComponentCreateData = nil
    local tbCustomData = tbGameObject.tbCustomData
    if(tbCustomData ~= nil and tbCustomData.tbComponentData ~= nil) then
        tbComponentCreateData = tbCustomData.tbComponentData[szClassName]
    end
    tbComponent:OnCreate(tbGameObject, tbComponentCreateData)
    return tbComponent
end

local function DestroyComponent(tbGameObject, szComponentName)
    local bRet = tbGameObject:DestroyComponent(tbGameObject[szComponentName])
    tbGameObject[szComponentName] = nil
    return bRet
end

local function CheckInfo(tbInfo, nClassType, nEnvironmentType,
    nActorType, nLifeCycleType)

    local bEnvMatched = false
    local nEnv = tbInfo.nEnvironmentType
    if(not GlobalVariableSystem:IsWithLobby()) then
        bEnvMatched = nEnv == tbEnvironmentType.Battle
            or (GlobalVariableSystem:IsClient() and nEnv == tbEnvironmentType.BattleClient)
            or (GlobalVariableSystem:IsServerLogic() and nEnv == tbEnvironmentType.BattleServer)
    else
        bEnvMatched = nEnv & nEnvironmentType > 0
    end

    return tbInfo.nClassType & nClassType > 0
        and bEnvMatched
        and tbInfo.nActorType & nActorType > 0
        and tbInfo.nLifeCycleType == nLifeCycleType
end

local function ConvertToClassType(self, nObjectType)
    return self.tbClassTypeMap[nObjectType]
end

function GameComponentCreateHelper:Create(tbGameObject, nEnvironmentType,
    nActorType, nLifeCycleType)

    if(tbGameObject.bCreateComponents == false) then
        return
    end

    local tbTempInfo
    local tbInfos = self.tbInfos
    local nCount = #tbInfos
    for i = 1, nCount do
        tbTempInfo = tbInfos[i]
        if(CheckInfo(tbTempInfo, ConvertToClassType(self, tbGameObject.ObjectType), nEnvironmentType, nActorType, nLifeCycleType)) then
            CreateComponent(tbGameObject, tbTempInfo.szClassName,
                    tbTempInfo.szComponentName, tbTempInfo.bDynamicRequire)
        end
    end
end

function GameComponentCreateHelper:Destroy(tbGameObject, nEnvironmentType,
    nActorType, nLifeCycleType)

    local tbTempInfo
    local tbInfos = self.tbInfos
    local nCount = #tbInfos
    for i = nCount, 1, -1 do
        tbTempInfo = tbInfos[i]
        if(CheckInfo(tbTempInfo, ConvertToClassType(self, tbGameObject.ObjectType), nEnvironmentType, nActorType, nLifeCycleType)) then
            DestroyComponent(tbGameObject, tbTempInfo.szComponentName)
        end
    end
end

function GameComponentCreateHelper:DestroyComponentByEnviromentType(tbGameObject, nEnvironmentType)
    local tbRet = {}
    local tbTempInfo
    local tbInfos = self.tbInfos
    local nCount = #tbInfos
    for i = 1, nCount do
        tbTempInfo = tbInfos[i]
        if (tbTempInfo.nEnvironmentType & nEnvironmentType > 0) then
            -- logerror("destroy [%s] component by environmentType [%d]", tbTempInfo.szComponentName, nEnvironmentType)
            if DestroyComponent(tbGameObject, tbTempInfo.szComponentName) then
                table.insert(tbRet, tbTempInfo.szClassName)
            end
        end
    end
    return tbRet
end

function GameComponentCreateHelper:CreateComponentByClassName(tbGameObject, nEnvironmentType,
    nActorType, nLifeCycleType, szClassName)
    local tbTempInfo
    local tbInfos = self.tbInfos
    local nCount = #tbInfos
    for i = 1, nCount do
        tbTempInfo = tbInfos[i]
        if (tbTempInfo.szClassName == szClassName and CheckInfo(tbTempInfo, ConvertToClassType(self, tbGameObject.ObjectType), nEnvironmentType, nActorType, nLifeCycleType)) then
            CreateComponent(tbGameObject, tbTempInfo.szClassName,
                    tbTempInfo.szComponentName, tbTempInfo.bDynamicRequire)
        end
    end
end

function GameComponentCreateHelper:GetComponentRegistInfo(szClassName)
    local tbTempInfo
    local tbInfos = self.tbInfos
    local nCount = #tbInfos
    for i = 1, nCount do
        tbTempInfo = tbInfos[i]
        if (tbTempInfo.szClassName == szClassName) then
            return tbTempInfo.nEnvironmentType,
                tbTempInfo.szComponentName
        end
    end
end

local function InitObjectTypeToClassType(self)
    local Def = GameComponentTypeDefine.tbClassType
    self.tbClassTypeMap =
    {
        [GameObjectTypeDef.PlayerSelf] = Def.PlayerSelf,
        [GameObjectTypeDef.PlayerOther] = Def.PlayerOther,
        [GameObjectTypeDef.Npc] = Def.Npc,
        [GameObjectTypeDef.Trigger] = Def.Trigger,
        [GameObjectTypeDef.Dummy] = Def.Dummy,
        [GameObjectTypeDef.AtmoSphereNpc] = Def.AtmoSphereNpc,
        [GameObjectTypeDef.AtmoSphereShipNpc] = Def.AtmoSphereShipNpc,
        [GameObjectTypeDef.Horse] = Def.Horse,
        [GameObjectTypeDef.DestructibleObject] = Def.DestructibleObject,
    }
end

function GameComponentCreateHelper:Init()
    self.tbInfos = {}
    InitObjectTypeToClassType(self)
    local GameComponentRegister = dynamic_require("GameComponentRegister")
    GameComponentRegister:RegisterComponents(self)
end

function GameComponentCreateHelper:Uninit()
    self.tbInfos = nil
    self.tbClassTypeMap = nil
end

return GameComponentCreateHelper
