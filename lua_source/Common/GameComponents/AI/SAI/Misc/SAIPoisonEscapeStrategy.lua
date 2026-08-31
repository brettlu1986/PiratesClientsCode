local SAIPoisonEscapeStrategy = {}

local nSeaPercent  = 65
local nLandPercent = 35

local tbLandPositions = {
    { X = 20060,    Y = -350083, Z = 800  }, -- 朗姆贩子
    { X = 68349,    Y =  151503, Z = 3700 }, -- 灯塔岛
    { X = -314035,  Y = -305086, Z = 4500 }, -- 矿山遗迹
    { X = -157687,  Y = -115114, Z = 3100 }, -- 风帆港
    { X = -416259,  Y = 55272,   Z = 6450 }, -- 隐秘森林
    { X = -189152 , Y = 96768,   Z = 5200 }, -- 荒废渔村
    { X = -28506,   Y = 327379,  Z = 1470 }, -- 避风湾
    { X = -401143,  Y = 473817,  Z = 2620 }, -- 食人族岛
    { X =  165800,  Y = 429448,  Z = 4060 }, -- 伐木小镇
    { X =  417779,  Y = 419548,  Z = 5510 }, -- 总督花园
    { X =  390200,  Y = 231429,  Z = 1800 }, -- 皇家港
    { X = -233012,  Y = 214334,  Z = 5700 }, -- 龟岛
    { X =  394627,  Y = -132205, Z = 4290 }, -- 海军基地
    { X =  164308,  Y = -275615, Z = 6300 }, -- 蛇岛
    { X =  6523  ,  Y = -139989, Z = 4000 }, -- 要塞岛
    { X =  245489,  Y = -116071, Z = 3660 }, -- 前哨站
    { X =  -66101,  Y = -435392, Z = 933  }, -- 沉船岛
}

local tbLandInfos = nil

local function Init()
    if not tbLandInfos then
        tbLandInfos = { }
        local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        for i,v in ipairs(tbLandPositions) do
            local tbLandInfo = { }
            tbLandInfo.nLandId = GridTypeManager:GetLandID(v.X, v.Y)
            tbLandInfo.tbPos = v
            table.insert(tbLandInfos, tbLandInfo)
        end
    end
end

local function GetDistanceBetween(nSourceX, nSourceY, nTargetX, nTargetY)
    return math.sqrt((nTargetX - nSourceX) ^ 2 + (nTargetY - nSourceY) ^ 2)
end

function SAIPoisonEscapeStrategy.Select(tbGameObject, nPoisonX, nPoisonY, nPoisonRadius)
    Init()

    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local bToSea = math.random(1, nSeaPercent + nLandPercent) <= nSeaPercent
    if bToSea then
        return { X = nPoisonX, Y = nPoisonY, Z = 0 }
    else
        local tbCurrentPos = tbGameObject:GetLocation()
        local nCurrentX = tbCurrentPos.X
        local nCurrentY = tbCurrentPos.Y
        local nCurrentLandId = GridTypeManager:GetLandID(nCurrentX, nCurrentY)
        local nMaxDistance = GetDistanceBetween(nCurrentX, nCurrentY, nPoisonX, nPoisonY)
        local tbSelectedPosition = { }
        for i,v in ipairs(tbLandInfos) do
            local nDestX = v.tbPos.X
            local nDestY = v.tbPos.Y
            local nDistance = GetDistanceBetween(nCurrentX, nCurrentY, nDestX, nDestY)
            if nCurrentLandId ~= v.nLandId and nDistance < nMaxDistance and
            GetDistanceBetween(nDestX, nDestY, nPoisonX, nPoisonY) < nPoisonRadius then
                table.insert(tbSelectedPosition, v)
            end
        end
        if #tbSelectedPosition > 0 then
            local tbLandInfo = tbSelectedPosition[math.random( 1, #tbSelectedPosition)]
            return tbLandInfo.tbPos
        else
            return { X = nPoisonX, Y = nPoisonY, Z = 0 }
        end
    end
end


return SAIPoisonEscapeStrategy