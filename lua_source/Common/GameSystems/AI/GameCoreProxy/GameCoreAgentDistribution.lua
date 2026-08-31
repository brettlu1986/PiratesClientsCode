local GameCoreAgentDistribution = {}
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleTeamSystem = require("BattleTeamSystem")


GameCoreAgentDistribution.bOneTeamPerIsLand = false
GameCoreAgentDistribution.bBotLocationProportion = false
GameCoreAgentDistribution.nBotLocationProportionOfShip = 0

local tbOpenIslandsInfos = {
    { X = 20060,    Y = -350083,    Radius = 1000},  -- 浪木贩子
    { X = 68349,    Y = 151503,     Radius = 1000},  -- 灯塔岛
    { X = 21736,    Y = 316048,     Radius = 1000},  -- 避风湾
    { X = -157687,  Y = -115114,    Radius = 1000},  -- 风帆港
    { X = -233012 , Y = 214334,     Radius = 1000},  -- 龟岛
    { X = 6523  ,   Y = -139989,    Radius = 1000},  -- 要塞岛
    { X = -189898 , Y = 92405,      Radius = 1000},  -- 荒废渔村
    { X = -310549 , Y = -303652,    Radius = 1000},  -- 矿山遗迹
    { X = -428395 , Y = 49623,      Radius = 1000},  -- 隐蔽森林
    { X = -390532 , Y = 451578,     Radius = 1000},  -- 食人魔
    { X = 165803 ,  Y = 429420,     Radius = 1000},  -- 伐木
    { X = 417778 ,  Y = 419549,     Radius = 1000},  -- 总督花园
    { X = 398759 ,  Y = 225517,     Radius = 1000},  -- 皇家港
    { X = 394627 ,  Y = -132205,    Radius = 1000},  -- 海军基地
    { X = 141792 ,  Y = -254262,    Radius = 1000},  -- 蛇岛
    { X = 225378 ,  Y = -108141,    Radius = 1000},  -- 前哨岛
    { X = -67344 ,  Y = -422568,    Radius = 1000},  -- 沉船岛
}

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCoreAgentDistribution:", ...)
end
-- luacheck: pop


local function GetBornPos(nIslandIndex)
    local tbIslandInfo = tbOpenIslandsInfos[nIslandIndex]
    local nRandomRadius = tbIslandInfo.Radius
    local nX = tbIslandInfo.X + math.random(-nRandomRadius, nRandomRadius)
    local nY = tbIslandInfo.Y + math.random(-nRandomRadius, nRandomRadius)
    local pLocation = ExtendBlueprintFunctions.GetAISafePosition(GWorld, Vector{X = nX, Y = nY, Z = 0},
    nRandomRadius, 10000, -50000)
    return pLocation.X, pLocation.Y, pLocation.Z
end

local function OnBotSelectionPointStart(self, SelectionPointHelper)
    if self.bOneTeamPerIsLand then
        local nIslandIndex = 1
        for k,v in pairs(BattleTeamSystem:GetAllTeamInfo()) do
            local tbTeamInfo = v
            for _, tbObject in pairs(tbTeamInfo.tbGameObjects) do
                local nX, nY, nZ = GetBornPos(nIslandIndex)
                SelectionPointHelper:SetBornPos(tbObject:GetServerInstanceId(), nX, nY, nZ)
                LOG("on one team per island ", tbObject.szName, tbTeamInfo.nTeamId, nX, nY, nZ)
            end
            nIslandIndex = nIslandIndex + 1
            if nIslandIndex > #tbOpenIslandsInfos then
                nIslandIndex = 1
            end
        end
    elseif self.bBotLocationProportion then
        local nShipCount = math.tointeger(BattleTeamSystem:GetTeamCount() * self.nBotLocationProportionOfShip)
        local nCount = 1
        for k,v in pairs(BattleTeamSystem:GetAllTeamInfo()) do
            local tbTeamInfo = v
            for _, tbObject in pairs(tbTeamInfo.tbGameObjects) do
                local nX, nY, nZ = SelectionPointHelper:GetRandomBornPosByRegionType(nCount <= nShipCount)
                SelectionPointHelper:SetBornPos(tbObject:GetServerInstanceId(), nX, nY, nZ)
                LOG("bot location proportion ", tbObject.szName, tbTeamInfo.nTeamId, nX, nY, nZ)
            end
            nCount = nCount + 1
        end
    end
end

local function OnBotSelectionPointEnd(self, SelectionPointHelper)

end

function GameCoreAgentDistribution:ShouldChangeToAgent(tbGameObject)
    return true
end

function GameCoreAgentDistribution:Reset()
    self.bOneTeamPerIsLand = false
    self.bBotLocationProportion = false
    self.nBotLocationProportionOfShip = 0
end

function GameCoreAgentDistribution:Init()
    EventManager:BindEventMethod(CommonEventDef.EV_FFA_BOT_AUTO_SELECTION_POINT_START, self, OnBotSelectionPointStart)
    EventManager:BindEventMethod(CommonEventDef.EV_FFA_BOT_AUTO_SELECTION_POINT_END, self, OnBotSelectionPointEnd)

end

function GameCoreAgentDistribution:UnInit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_BOT_AUTO_SELECTION_POINT_START, self, OnBotSelectionPointStart)
    EventManager:UnBindEventMethod(CommonEventDef.EV_FFA_BOT_AUTO_SELECTION_POINT_END, self, OnBotSelectionPointEnd)
end



return GameCoreAgentDistribution