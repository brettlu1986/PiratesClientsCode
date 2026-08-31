-- 这里只发起更新流程，更新成功后lua会重启，在Procedure_StartGame::GotoNextProcedure()会直接进入ServerList

local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Update = luaclass("Procedure_Update", ProcedureBase)

--Procedure_Update.UpdateFailedDelegate = nil

-- local function ShowFailedDialog(szContent, szOK, fnFunc)
--     UIDialogHelper:ShowOKMessageDialog("Failed", szContent, "", szOK, fnFunc, false)
-- end

-- local function OnUpdateFailed(self, nErrorCode)
--     logwarning("Procedure_Update OnUpdateFailed", tonumber(nErrorCode))
--     if(nErrorCode == EUpdateErrorCode.InvalidService) then
--         -- 弹出下载失败，重试的提示框
--         ShowFailedDialog("Download failed", "Retry", function()
--             ProcedureManager:ActiveProcedure(ProcedureManager.Procedure_Update, self.Param, true)
--         end)
--     elseif(nErrorCode == EUpdateErrorCode.NoEnoughStorageSpace) then
--         -- 弹出存储容量不足的提示
--         ShowFailedDialog("There is not enough storage space", "ExitGame", function()
--             ProcedureTool:ExitGame()
--         end)
--     elseif(nErrorCode == EUpdateErrorCode.CanNotSaveToFile) then
--         -- 弹出无法存储的提示，有可能是权限不足
--         ShowFailedDialog("Can not save to file", "ExitGame", function()
--             ProcedureTool:ExitGame()
--         end)        
--     else
--         -- 弹出通用提示框，退出
--         ShowFailedDialog("UnkownError "..tonumber(nErrorCode), "ExitGame", function()
--             ProcedureTool:ExitGame()
--         end)
--     end
-- end

function Procedure_Update:Begin()  
    Procedure_Update.super.Begin(self)
 
    local pLevelActor = EngineExtActorShell:FindFirstLevelScriptActor(GWorld)
    if(pLevelActor == nil) then
        logerror("Procedure_Update failed to find level script actor")
        return
    end

    local pProcedure = pLevelActor.UpdateProcedure
    if(pProcedure == nil) then
        logerror("Procedure_Update the UpdateProcedure in level is invalid")
        return
    end

    --self.UpdateFailedDelegate = CppDelegate:BindMethod(pProcedure.OnUpdateFailed, self, OnUpdateFailed)
    
    local szUpdateInfo = self.Param.szUpdateInfo
    log("Procedure_Update start update", szUpdateInfo)
    pProcedure:StartUpdate(szUpdateInfo)
end

-- local function UnbindDelegate(self)
--     if (self.UpdateFailedDelegate) then
--         self.UpdateFailedDelegate:Unbind()
--         self.UpdateFailedDelegate = nil
--     end
-- end

function Procedure_Update:Uninit()
    --UnbindDelegate(self)
    Procedure_Update.super.Uninit(self)
end

function Procedure_Update:End()
    --UnbindDelegate(self)
    Procedure_Update.super.End(self)
end

return Procedure_Update
