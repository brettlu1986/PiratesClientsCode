-----------------------------------------------------
--File Name    : AbilityAction_Log.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-23
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_Log = luaclass("AbilityAction_Log", AbilityActionBase)

function AbilityAction_Log:OnDo(tbParams)
    if self.tbInitParams.Do then
        log("[AbilityAction_Log]", self.tbInitParams.Do)
    end
end

function AbilityAction_Log:OnUndo(tbParams)
    if self.tbInitParams.Undo then
        log("[AbilityAction_Log]", self.tbInitParams.Undo)
    end
end

return AbilityAction_Log
