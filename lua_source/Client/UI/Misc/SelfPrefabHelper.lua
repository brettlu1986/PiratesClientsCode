-----------------------------------------------------
--File Name    : SelfPrefabHelper.lua
--Author       : Song Fuhao
--Create Time  : 2016-09-07
--Description  : SelfPrefabHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfPrefabHelper = luaclass("SelfPrefabHelper")

-- import require
local PrefabConfig = require("PrefabDataTable")

-- const variable
local UOBJECT_CLASS_SUFFIX_PRE_INDEX    = -3       -- Uobject class name suffix must is '_C'
local fnGetObjectClass = GameplayStatics.GetObjectClass
local fnGetClassDisplayName = KismetSystemLibrary.GetClassDisplayName

-- member variable
SelfPrefabHelper.tbPrefabList           = {}
SelfPrefabHelper.Owner = nil
SelfPrefabHelper.WndCreator = nil


-- publish function
function SelfPrefabHelper:SetOwner(Owner)
    self.Owner = Owner
end

function SelfPrefabHelper:SetWndCreator(WndCreator)
    self.WndCreator = WndCreator
end
-- 创建一个不存在的Prefab，并进行绑定
-- @param   szPrefabName    Prefab在配置表中的名字
-- @return  PrefabScript    Prefab对应的脚本对象
-- @return  pWidgetRef      Prefab对应Widget的引用
function SelfPrefabHelper:CreatePrefab( szPrefabName )
    local PrefabScript = self:CreatePrefabScript(szPrefabName)
    return PrefabScript, PrefabScript.pWidgetRef
end

-- 绑定一个已存在的Prefab
-- @param   pWidgetRef      Prefab对应Widget的引用
-- @return  PrefabScript    Prefab对应的脚本对象
function SelfPrefabHelper:BindPrefab( pWidgetRef, szPrefabName )
    if not pWidgetRef then
        logerror('[UI] BindPrefab failed, pWidgetRef is nil, szPrefabName=', szPrefabName, debug.traceback())
        return nil
    end
    if not szPrefabName then
        szPrefabName = self:GetPrefabName(pWidgetRef)
    end
    return self:CreatePrefabScript(szPrefabName, pWidgetRef)
end

-- 解绑并释放一个Prefab
-- @param PrefabScript      Prefab对应的脚本对象
function SelfPrefabHelper:UnbindPrefab( PrefabScript )
    if self.tbPrefabList[PrefabScript] then
        PrefabScript:Destroy()
        self.tbPrefabList[PrefabScript] = nil
    end
end

function SelfPrefabHelper:UnbindAllPrefab()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:Destroy()
        end
    end
    self.tbPrefabList = {}
end

function SelfPrefabHelper:BindEvent()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:BindEvent()
        end
    end
end

function SelfPrefabHelper:UnbindEvent()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:UnbindEvent()
        end
    end
end

function SelfPrefabHelper:Enter()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:Enter()
        end
    end
end

function SelfPrefabHelper:Show()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:Show()
        end
    end
end

function SelfPrefabHelper:Hide()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:Hide()
        end
    end
end

function SelfPrefabHelper:Exit()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:Exit()
        end
    end
end

function SelfPrefabHelper:Pause()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:Pause()
        end
    end
end

function SelfPrefabHelper:Resume()
    for k,v in pairs(self.tbPrefabList) do
        if v then
            v:Resume()
        end
    end
end

-- private funtion
-- 获取Prefab对应的Class名
-- @param   pWidgetRef  Widget引用
-- @return  szPrefabClassName 类名
function SelfPrefabHelper:GetPrefabName( pWidgetRef )
    if not pWidgetRef then
        log('[UI] SelfPrefabHelper : GetPrefabName failed, pWidgetRef is nil.')
        return nil
    end

    local pWidgetClass = fnGetObjectClass(pWidgetRef)
    if not pWidgetClass then
        log('[UI] SelfPrefabHelper : GetPrefabName failed, pWidgetClass is nil.')
        return nil
    end
    
    local szWidgetClassName = fnGetClassDisplayName(pWidgetClass)
    return string.sub(szWidgetClassName, 0, UOBJECT_CLASS_SUFFIX_PRE_INDEX)             -- remove suffix, uobject is not nil, name must suffix with '_C'
end

function SelfPrefabHelper:CreatePrefabScript( szPrefabName, pWidgetRef )
    local tbTemplate = PrefabConfig:GetTemplate(szPrefabName)
    if not tbTemplate then
        logerror('[UI] CreatePrefabScript failed, tbTemplate is nil, please check config table, szPrefabName =', szPrefabName)
    end
    local ScriptClass = require(tbTemplate.szScriptName)
    local PrefabScript = ScriptClass()
    PrefabScript:SetOwner(self.Owner)
    PrefabScript:SetWndCreator(self.WndCreator)
    PrefabScript:Create(tbTemplate, pWidgetRef)
    if self.Owner then
        if self.Owner.bEntered then
            PrefabScript:Enter()
        end
        if self.Owner.bEventBinded then
            PrefabScript:BindEvent()
        end
        if self.Owner.bShowed then
            PrefabScript:Show()
        end
    end
    self.tbPrefabList[PrefabScript] = PrefabScript
    return PrefabScript
end

return SelfPrefabHelper
