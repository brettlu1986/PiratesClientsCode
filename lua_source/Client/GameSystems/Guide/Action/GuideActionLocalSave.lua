-----------------------------------------------------
--File Name    : GuideActionLocalSave.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionLocalSave      = luaclass("GuideActionLocalSave", GuideActionFunctional)

--import
--local 

function GuideActionLocalSave:DoAction(tbTemplate)
    GuideActionLocalSave.super.DoAction(self, tbTemplate)
    local szSaveKey = self.tbTemplate.tbParam[1]
    local szValue = self.tbTemplate.tbParam[2]
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:AddStringData(szSaveKey, szValue)
    pSaveGameMgr:Save()
end

return GuideActionLocalSave
