-- 公告
local luaclass = require("luaclass")
local ProcedureBase = require("ProcedureBase")
local Procedure_Announcemenet = luaclass("Procedure_Announcemenet", ProcedureBase)


function Procedure_Announcemenet:Begin()
    Procedure_Announcemenet.super.Begin(self)
end

function Procedure_Announcemenet:End()
    Procedure_Announcemenet.super.End(self)
end


return Procedure_Announcemenet
