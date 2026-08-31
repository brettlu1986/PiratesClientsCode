-----------------------------------------------------
--Description  : 状态基类
-----------------------------------------------------

local luaclass  = require("luaclass")
local BaseState = luaclass("BaseState")

BaseState.szName    = nil
BaseState.tbParams  = nil
BaseState.bActived  = false

function BaseState:Init(szName, tbParams)
    self.szName     = szName    
    self.tbParams   = tbParams
end

function BaseState:Uninit()
    self.szName  = nil    
    self.tbParams= nil
end

function BaseState:OnActive(tbParams)
    
end

function BaseState:Active(tbParams)
    if(not self.bActived) then
        self.bActived = true
        self:OnActive(tbParams)
    else
        error("BaseState:Active but is already active ".. self.szName)
    end
end

function BaseState:OnDeactive()
end

function BaseState:Deactive()
    if (self.bActived) then
        self.bActived = false
        self:OnDeactive()
    else
        error("BaseState:Deactive but is already deactive ".. self.szName)
    end
end

function BaseState:IsActived()
    return self.bActived
end

return BaseState