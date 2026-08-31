-- 各种逻辑载体的基类
-- 所有的GameObject都通过GameObjectManger来创建销毁

local luaclass = require("luaclass")
local GameObject = luaclass("GameObject")

local UEActorHelper = require("UEActorHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

-- Component相关
GameObject.tbComponents = nil

--UE相关
GameObject.nUniqueId = nil
GameObject.pUEActor = nil

-- 初始化相关
GameObject.szInitProtoName = nil
GameObject.tbInitProtoData = nil
GameObject.bCreateUEActor = true
GameObject.bCreateComponents = true
GameObject.nServerInstanceId = nil
GameObject.nTemplateId = 0
GameObject.ObjectType = nil
GameObject.szName = ""
GameObject.tbCustomData = nil
GameObject.Location = nil
GameObject.Rotation = nil
GameObject.Scale    = nil
GameObject.szTag = nil
GameObject.bValid = true
GameObject.tbComponentTags = nil
GameObject.bCreateNativeComponentAsyn = false
GameObject.bHasActorCreated = false

------------------------------------------------------------------------------------------------------------------------------------
local function CallFunctionInComponents(self, szFunc, pUEActor)
    local tbComponents = self.tbComponents
    for k, v in ipairs(tbComponents) do
        self:BeforeCallFunctionInComponent(szFunc, v)
        v[szFunc](v, pUEActor)
        self:AfterCallFunctionInComponent(szFunc, v)
    end
end

------------------------------------------------------------------------------------------------------------------------------------

--todo 调查下性能问题，将来记得注释掉
function GameObject:BeforeCallFunctionInComponent(szFunc, tbComponent)
end

function GameObject:AfterCallFunctionInComponent(szFunc, tbComponent)
end

function GameObject:GetActorClassByTemplateId(nTemplateId)
    -- 子类继承
    return nil
end



function GameObject:CreateUEActor(nTemplateId)
    local szClass = self:GetActorClassByTemplateId(nTemplateId)
    if(szClass == nil) then
        return nil
    end

    self.nUniqueId, self.pUEActor = UEActorHelper:CreateActor(szClass,
        self.Location, self.Rotation, self.Scale,
        self.szInitProtoName, self.tbInitProtoData,
        self.nServerInstanceId,
        self.tbComponentTags,
        self.bCreateNativeComponentAsyn)

    local pActor = self.pUEActor
    if(pActor == nil) then
        logerror("GameObject:CreateUEActor failed: TemplateId: ", self.nTemplateId)
    end

    return pActor
end

-- PreBeginPlay触发
function GameObject:OnActorPreCreated(pUEActor)
    CallFunctionInComponents(self, "OnActorPreCreated", pUEActor)
end

-- PostBeginPlay触发
function GameObject:OnActorCreated(pUEActor)
    self.bHasActorCreated = true
    CallFunctionInComponents(self, "OnActorCreated", pUEActor)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self)
end

function GameObject:UnbindUEActor()
    local pUEActor = self.pUEActor
    if(pUEActor) then
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self)
        CallFunctionInComponents(self, "OnActorDestroyed", pUEActor)
        self.pUEActor = nil
        self.nUniqueId = nil
        self.bHasActorCreated = false
    end
end

function GameObject:BindUEActor(pUEActor)
    if (pUEActor ~= nil) then
        self.pUEActor = pUEActor
        self.nUniqueId = UEActorHelper:GetActorUniqueId(pUEActor)
        return true
    end
    logerror("BindUEActor failed, the input actor is nil")
    return false
end

function GameObject:DestroyUEActor()
    if(self.pUEActor) then
        local pUEActor = self.pUEActor
        self:UnbindUEActor()
        UEActorHelper:DestroyActor(pUEActor)
    end
end

-- 创建所有component调用其OnCreate函数
-- function GameObject:CreateComponent(NewComponentClass, tbCustomData)
--     if(NewComponentClass == nil) then
--         logerror("GameObject:CreateComponent failed: NewComponentClass is nil")
--         return nil
--     end

--     local NewComponent = NewComponentClass()
--     table.insert(self.tbComponents, NewComponent)
--     NewComponent:OnCreate(self, tbCustomData)
--     return NewComponent
-- end

function GameObject:CreateComponent(NewComponentClassName, bDynamicRequire)
    if(NewComponentClassName == nil or NewComponentClassName == "") then
        logerror("GameObject:CreateComponent failed: NewComponentClassName is invalid")
        return nil
    end

    local NewComponentClass = nil
    if(bDynamicRequire) then
        NewComponentClass = dynamic_require(NewComponentClassName)
    else
        NewComponentClass = require(NewComponentClassName)
    end

    if(NewComponentClass == nil) then
        logerror("GameObject:CreateComponent failed: NewComponentClass is nil")
        return nil
    end

    local NewComponent = NewComponentClass()
    NewComponent.szClassName = NewComponentClassName
    table.insert(self.tbComponents, NewComponent)

    return NewComponent
end

function GameObject:DestroyComponent(RemovedComponent)
    if(RemovedComponent == nil) then
        return
    end
    local tbComponents = self.tbComponents
    for k, v in ipairs(tbComponents) do
        if(v == RemovedComponent) then
            RemovedComponent:OnDestroy()
            table.remove(self.tbComponents, k)
            return true
        end
    end
end

function GameObject:DestroyAllComponents()
    local tbComponents = self.tbComponents
    for i = #tbComponents, 1, -1 do
        tbComponents[i]:OnDestroy()
    end
    self.tbComponents = {}
end

function GameObject:ParseCreateData(tbCreateData)
    if(tbCreateData == nil) then
        logerror("GameObject:ParseCreateData failed, the tbCreateData is nil")
        return false
    end

    self.bCreateUEActor = true
    if(tbCreateData.bCreateUEActor ~= nil) then
        self.bCreateUEActor = tbCreateData.bCreateUEActor
    end

    self.bCreateComponents = true
    if(tbCreateData.bCreateComponents ~= nil) then
        self.bCreateComponents = tbCreateData.bCreateComponents
    end

    self.tbComponentTags = tbCreateData.tbComponentTags
    self.bCreateNativeComponentAsyn = tbCreateData.bCreateNativeComponentAsyn

    self.szInitProtoName = tbCreateData.szInitProtoName
    self.tbInitProtoData = tbCreateData.tbInitProtoData
    self.nTemplateId = tbCreateData.nTemplateId
    self.nServerInstanceId = tbCreateData.nServerInstanceId
    self.szTag = tbCreateData.szTag
    if(tbCreateData.szName) then
        self.szName = tbCreateData.szName
    end

    local nX = tbCreateData.nLocationX
    local nY = tbCreateData.nLocationY
    local nZ = tbCreateData.nLocationZ
    local nYaw = tbCreateData.nRotationYaw
    local nScaleX = tbCreateData.nScaleX
    local nScaleY = tbCreateData.nScaleY
    local nScaleZ = tbCreateData.nScaleZ

    if(nX and nX and nZ) then
        self:SetLocation(nX, nY, nZ)
    end

    if(nYaw) then
        self:SetRotation(0, nYaw, 0)
    end

    if (nScaleX and nScaleY and nScaleZ) then
        self:SetScale3D(nScaleX, nScaleY, nScaleZ)
    end

    return true
end

-- 在真正创建前的预处理，未来可能会有自身的逻辑改变nTemplateId
function GameObject:OnPreCreate(tbCreateData, tbCustomData)
    self.tbComponents = {}
    self.Location = Vector()
    self.Rotation = Rotator()
    self.Scale    = Vector{X=1,Y=1,Z=1}
    self.tbCustomData = tbCustomData

    return self:ParseCreateData(tbCreateData)
end

function GameObject:OnCreateComponents()
    return true
end

-- 创建
function GameObject:OnCreate()
    if(self.bCreateComponents) then
        if(not self:OnCreateComponents()) then
            logerror("GameObject OnCreateComponents failed, ServerID: ", self.nServerInstanceId)
            return false
        end
    end

    if(self.bCreateUEActor) then
        self:CreateUEActor(self.nTemplateId)
    end
    return true
end

function GameObject:OnPostCreate()
    --EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_POST_CREATE, self)
end

function GameObject:Create(tbCreateData, tbCustomData)
    if(not self:OnPreCreate(tbCreateData, tbCustomData)) then
        return false
    end

    if (not self:OnCreate()) then
        logerror("NewGameObject:OnCreate failed.")
        return false
    end

    self:OnPostCreate()
    return true
end


function GameObject:Destroy()
    self:OnPreDestroy()
    self:OnDestroy()
end

-- 销毁前
function GameObject:OnPreDestroy()
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self)
end

-- 销毁
-- 一般在DestroyKMActor前会有个delegate，外部有些系统会关心此Actor的销毁
function GameObject:OnDestroy()
    self:DestroyUEActor()
    self:DestroyAllComponents()
end

function GameObject:GetModelActor()
    return self.pUEActor
end

function GameObject:GetServerInstanceId()
    return self.nServerInstanceId
end

function GameObject:GetUEActorUniqueId()
    return self.nUniqueId
end

function GameObject:GetObjectType()
    return self.ObjectType
end

function GameObject:GetTemplateId()
    return self.nTemplateId
end

function GameObject:SetLocation(X, Y, Z)
    local Location = self.Location
    Location.X = X
    Location.Y = Y
    Location.Z = Z
    if(self.pUEActor) then
        UEActorHelper:SetActorLocation(self.pUEActor, Location)
    end
end

function GameObject:GetLocation()
    if(self.pUEActor) then
        self.Location = UEActorHelper:GetActorLocation(self.pUEActor)
    end
    return self.Location
end

function GameObject:GetLocationXYZ()
    local X, Y, Z
    local Location = self.Location
    if(self.pUEActor) then
        X, Y, Z = UEActorHelper:GetActorLocationXYZ(self.pUEActor)
        Location.X = X
        Location.Y = Y
        Location.Z = Z
    else
        X = Location.X
        Y = Location.Y
        Z = Location.Z
    end
    return X, Y, Z
end

function GameObject:SetRotation(Pitch, Yaw, Roll)
    local Rotation = self.Rotation
    Rotation.Pitch = Pitch
    Rotation.Yaw = Yaw
    Rotation.Roll = Roll
    if(self.pUEActor) then
        UEActorHelper:SetActorRotation(self.pUEActor, Rotation)
    end
end

function GameObject:GetRotation()
    if(self.pUEActor) then
        self.Rotation = UEActorHelper:GetActorRotation(self.pUEActor)
    end
    return self.Rotation
end

function GameObject:GetRotationYawPitchRoll()
    local nYaw, nPitch, nRoll
    local Rotation = self.Rotation
    if(self.pUEActor) then
        nYaw, nPitch, nRoll = UEActorHelper:GetActorRotationYawPitchRoll(self.pUEActor)
        Rotation.Pitch = nPitch
        Rotation.Yaw = nYaw
        Rotation.Roll = nRoll
    else
        nYaw = Rotation.Yaw
        nPitch = Rotation.Pitch
        nRoll = Rotation.Roll
    end
    return nYaw, nPitch, nRoll
end

function GameObject:SetScale3D(X, Y, Z)
    local Scale = self.Scale
    Scale.X = X
    Scale.Y = Y
    Scale.Z = Z
    if(self.pUEActor) then
        UEActorHelper:SetActorScale3D(self.pUEActor, Scale)
    end
end

function GameObject:SetScale(nScale)
    local Scale = self.Scale
    Scale.X = nScale
    Scale.Y = nScale
    Scale.Z = nScale
    if(self.pUEActor) then
        UEActorHelper:SetActorScale3D(self.pUEActor, Scale)
    end
end

function GameObject:GetScale3D()
    if(self.pUEActor) then
        self.Scale = UEActorHelper:GetActorScale3D(self.pUEActor)
    end
    return self.Scale
end

function GameObject:SetName(szNewName)
    self.szName = szNewName
end

function GameObject:GetName()
    return self.szName
end

function GameObject:SetTag(szTag)
    self.szTag = szTag
end

function GameObject:GetTag()
    return self.szTag
end

function GameObject:RestoreUEActor(tbCreateData, tbCustomData)
    if(self.pUEActor) then
        self:DestroyUEActor()
    end

    if(tbCreateData ~= nil) then
        if(not self:ParseCreateData(tbCreateData)) then
            logerror("GameObject:RestoreUEActor parse create data failed, ", self:GetServerInstanceId())
            return false
        end
    end

    self.tbCustomData = tbCustomData
    if(self.bCreateUEActor) then
        local pActor = self:CreateUEActor(self.nTemplateId)
        if(not pActor) then
            logerror("GameObject:RestoreUEActor failed, ServerId: ", self:GetServerInstanceId())
            return false
        end
    end
    return true
end

function GameObject:GetDebugInfo()
    local tbInfo = {}
    tbInfo.nServerInstanceId = self.nServerInstanceId
    tbInfo.tbInitProtoData = self.tbInitProtoData
    tbInfo.nTemplateId = self.nTemplateId
    tbInfo.ObjectType = self.ObjectType
    tbInfo.szName = self.szName
    local Location = self:GetLocation()
    tbInfo.tbLocation = { Location.X, Location.Y, Location.Z }
    local Rotation = self:GetRotation()
    tbInfo.RotationYaw = Rotation.Yaw
    tbInfo.nUniqueId = self.nUniqueId
    return tbInfo
end

function GameObject:DelayDestroy()
    self.bValid = false
    self:OnDelayDestroy()
end

function GameObject:RestoreObject(tbParam)
    self.bValid = true
    self:OnRestoreObject(tbParam)
end


function GameObject:OnDelayDestroy()
end

function GameObject:OnRestoreObject(tbParam)
end

function GameObject:NeedCache()
    if self.pUEActor then
        return true
    end

    return false
end

return GameObject
