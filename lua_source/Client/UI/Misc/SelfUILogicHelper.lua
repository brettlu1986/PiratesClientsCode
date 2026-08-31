-----------------------------------------------------
--File Name    : SelfUILogicHelper.lua
--Author       : Song Fuhao
--Create Time  : 2018-01-16
--Description  : SelfUILogicHelper
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfUILogicHelper = luaclass("SelfUILogicHelper")

-- member variable
SelfUILogicHelper.tbUILogicList = {}
SelfUILogicHelper.Owner = nil

-- publish function
function SelfUILogicHelper:SetOwner(Owner)
    self.Owner = Owner
end

function SelfUILogicHelper:CreateUILogic(szClassName)
    local tbClass = require(szClassName)
    local tbUILogic = tbClass()
    tbUILogic:Create(self.Owner)
    table.insert(self.tbUILogicList, tbUILogic)
    return tbUILogic
end

function SelfUILogicHelper:DestroyUILogic(tbUILogic)
    tbUILogic:Destroy()
    local nRemoveIndex = nil
    for k, v in pairs(self.tbUILogicList) do
        if v == tbUILogic then
            nRemoveIndex = k
        end
    end
    if nRemoveIndex then
        table.remove(self.tbUILogicList, nRemoveIndex)
    end
end

function SelfUILogicHelper:DestroyAllUILogic()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:Destroy()
        end
    end
    self.tbUILogicList = {}
end

function SelfUILogicHelper:BindEvent()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:BindEvent()
        end
    end
end

function SelfUILogicHelper:UnbindEvent()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:UnbindEvent()
        end
    end
end

function SelfUILogicHelper:OnLoad()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnLoad()
        end
    end
end

function SelfUILogicHelper:OnUnload()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnUnload()
        end
    end
end

function SelfUILogicHelper:OnEnter()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnEnter()
        end
    end
end

function SelfUILogicHelper:OnShow()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnShow()
        end
    end
end

function SelfUILogicHelper:OnHide()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnHide()
        end
    end
end

function SelfUILogicHelper:OnExit()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnExit()
        end
    end
end

function SelfUILogicHelper:OnPause()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnPause()
        end
    end
end

function SelfUILogicHelper:OnResume()
    for k,v in pairs(self.tbUILogicList) do
        if v then
            v:OnResume()
        end
    end
end

return SelfUILogicHelper
