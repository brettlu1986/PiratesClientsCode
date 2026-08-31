local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_PreLogin = luaclass("Procedure_PreLogin", ProcedureBase)

local ProcedureManager = require("ProcedureManager")
local ManagerRoot = require("ManagerRoot")
local ManagerGroupDef = require("ManagerGroupDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")

local FAKE_PERCENT = 0.5

function Procedure_PreLogin:Uninit()
    Procedure_PreLogin.super.Uninit(self)
end

function Procedure_PreLogin:Begin()
    Procedure_PreLogin.super.Begin(self)
    -- 重置本地数据存储保存的UserId
	ClientShell.GetClient(GWorld):GetSaveGameManager():ResetToDefaultSlot()
    ManagerRoot:InitGroup(ManagerGroupDef.nDefaultGroupID, true)
	local GameInstance = GameplayStatics.GetGameInstance(GWorld)
    local UpdateUI = GameInstance.UpdateUI
    if not UpdateUI then
        local tbParam = {bOpenWithAnim = true}
        local tbLoadingWnd = UIManager:OpenWnd(UIDef.UI_LOADING,tbParam)
        tbLoadingWnd:AddPercent(FAKE_PERCENT)
    end
    self:Complete(ProcedureManager.Procedure_Login)
end

function Procedure_PreLogin:End()
	Procedure_PreLogin.super.End(self)
end

return Procedure_PreLogin
