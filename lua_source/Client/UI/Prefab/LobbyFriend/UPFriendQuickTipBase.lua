
local luaclass              = require("luaclass")
local PrefabBase            = require("PrefabBase")
local UPFriendQuickTipBase   = luaclass("UPFriendQuickTipBase", PrefabBase)
local Timer = require("Timer")

UPFriendQuickTipBase.tbData = nil 
local AUTO_CLOSE = "autoCloseTimer"
local nClostTime = 15

function UPFriendQuickTipBase:Activate(tbData)
    self.tbData = tbData
    Timer.StartOwnerTimer(self, AUTO_CLOSE, function() 
        self:Deactivate()
    end, nClostTime)
end

function UPFriendQuickTipBase:Deactivate()
    Timer.StopOwnerTimer(self, AUTO_CLOSE)
    if self.tbData.fnDeactivate then  
        self.tbData.fnDeactivate(self)
    end
end

return UPFriendQuickTipBase