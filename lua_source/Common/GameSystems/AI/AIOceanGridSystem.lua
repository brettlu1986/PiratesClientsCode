local luaclass = require("luaclass")
local AIOceanGridSystem = luaclass("AIOceanGridSystem")

local OCEAN_CELL_SIZE = 30000

AIOceanGridSystem.pOceanGridManager = nil


function AIOceanGridSystem:Init()
    self.pOceanGridManager = CommonShell.Get(GWorld):GetAIOceanGridManager()
    return true
end

function AIOceanGridSystem:Uninit()

end

function AIOceanGridSystem:InitMap(nWidth, nHeight, nCenterX, nCenterY)
    local pOceanGridManager = self.pOceanGridManager
    pOceanGridManager:InitCells(nWidth, nHeight, nCenterX, nCenterY, OCEAN_CELL_SIZE)
    log("init ai ocean grid system:", nWidth, nHeight, nCenterX, nCenterY, OCEAN_CELL_SIZE)
end

function AIOceanGridSystem:Dump()
    self.pOceanGridManager:Dump()
end


return AIOceanGridSystem()
