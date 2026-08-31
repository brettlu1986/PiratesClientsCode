local ProcedureRegister = {}

function ProcedureRegister:Register(ProcedureManager)
    -- 正常进入游戏顺序如下
    ProcedureManager.Procedure_StartGame = ProcedureManager:RegistProcedure("Procedure_StartGame")
    ProcedureManager.Procedure_PreLogin = ProcedureManager:RegistProcedure("Procedure_PreLogin")
    -- ProcedureManager.Procedure_VersionCheck = ProcedureManager:RegistProcedure("Procedure_VersionCheck")
    -- ProcedureManager.Procedure_Update = ProcedureManager:RegistProcedure("Procedure_Update")
    -- ProcedureManager.Procedure_Dispatcher = ProcedureManager:RegistProcedure("Procedure_Dispatcher")
    --ProcedureManager.Procedure_Config = ProcedureManager:RegistProcedure("Procedure_Config")
    --ProcedureManager.Procedure_ServerList = ProcedureManager:RegistProcedure("Procedure_ServerList")
    -- ProcedureManager.Procedure_Announcemenet = ProcedureManager:RegistProcedure("Procedure_Announcemenet")
    
    ProcedureManager.Procedure_Login = ProcedureManager:RegistProcedure("Procedure_Login")
    -- ProcedureManager.Procedure_SelectRole = ProcedureManager:RegistProcedure("Procedure_SelectRole")
    ProcedureManager.Procedure_CreateRole = ProcedureManager:RegistProcedure("Procedure_CreateRole")
    ProcedureManager.Procedure_Lobby = ProcedureManager:RegistProcedure("Procedure_Lobby")
    ProcedureManager.Procedure_Lobby3D = ProcedureManager:RegistProcedure("Procedure_Lobby3D")
    -- ProcedureManager.Procedure_NewPlayer = ProcedureManager:RegistProcedure("Procedure_NewPlayer")
    -- ProcedureManager.Procedure_WildWorld = ProcedureManager:RegistProcedure("Procedure_WildWorld")
    ProcedureManager.Procedure_Battle = ProcedureManager:RegistProcedure("Procedure_Battle")
    ProcedureManager.Procedure_Homeland = ProcedureManager:RegistProcedure("Procedure_Homeland")
    
    ProcedureManager.Procedure_Mock = ProcedureManager:RegistProcedure("Procedure_Mock")
end

return ProcedureRegister