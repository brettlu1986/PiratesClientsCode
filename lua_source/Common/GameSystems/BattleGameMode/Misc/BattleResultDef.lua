
local BattleResultDef = {}

BattleResultDef.WIN = 0
BattleResultDef.LOSE = 1
BattleResultDef.TIE = 2

BattleResultDef.ReslutType = {
    Escape = 0, --逃跑结算
    Escort = 1, --护送结算
    Kill   = 2 --击杀结算
}

return BattleResultDef
