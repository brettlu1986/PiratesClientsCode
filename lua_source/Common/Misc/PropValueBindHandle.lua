-----------------------------------------------------
--File Name    : PropValueBindHandle.lua
--Author       : Song Fuhao
--Create Time  : 2020-08-11
--Description  : 用于让EventHelper统一解绑PropertyComponent属性改变事件
-----------------------------------------------------

local luaclass = require("luaclass")
local PropValueBindHandleImpl = luaclass("PropValueBindHandleImpl")

PropValueBindHandleImpl.PropComponent = nil
PropValueBindHandleImpl.nPropId = nil
PropValueBindHandleImpl.fnCallback = nil
PropValueBindHandleImpl.tbObject = nil

function PropValueBindHandleImpl:Bind(PropComponent, nPropId, fnCallback, tbObject)
    if not PropComponent then
        return
    end
    self.PropComponent = PropComponent
    self.nPropId = nPropId
    self.fnCallback = fnCallback
    self.tbObject = tbObject
    PropComponent:BindPropChanged(nPropId, fnCallback, tbObject)
end

function PropValueBindHandleImpl:Unbind()
    if not self.PropComponent then
        return
    end
    self.PropComponent:UnbindPropChanged(self.nPropId, self.fnCallback, self.tbObject)
end

local PropValueBindHandle = {}

function PropValueBindHandle:Bind(PropComponent, nPropId, fnCallback, tbObject)
    local Impl = PropValueBindHandleImpl()
    Impl:Bind(PropComponent, nPropId, fnCallback, tbObject)
    return Impl
end

return PropValueBindHandle