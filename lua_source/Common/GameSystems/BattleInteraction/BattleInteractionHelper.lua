local BattleInteractionHelper = {}

local BattleInteractionSystem = dynamic_require("BattleInteractionSystem")

------------------------------Matinee----------------------------------

-- 广播播放Matinee，对于单机副本，和LocalPlayMatinee(nMatineeId, nil, nil, bPause)语义相同
function BattleInteractionHelper:PlayMatinee(nMatineeId, bClientOnly, bPause)
	BattleInteractionSystem:PlayMatinee(nMatineeId, bClientOnly, bPause)
end

-- 单机副本本地播放动画
function BattleInteractionHelper:LocalPlayMatinee(nMatineeId, tbParent, fnOnComplete, bPause)
    BattleInteractionSystem:LocalPlayMatinee(nMatineeId, tbParent, fnOnComplete, bPause)
end

-- 通知指定玩家播放Matinee，一定是不Pause，ClientOnly的
function BattleInteractionHelper:PlayerPlayMatinee(tbPlayer, nMatineeId)
    BattleInteractionSystem:PlayerPlayMatinee(tbPlayer, nMatineeId)
end

-- 广播停止播放动画，可用于单机副本
function BattleInteractionHelper:StopMatinee()
    BattleInteractionSystem:StopMatinee()
end

-------------------------------Dialog-------------------------------------

-- 广播开始对话nDialogId，可用于单机副本
function BattleInteractionHelper:ShowDialog(nDialogId, bDialogBoard)
	BattleInteractionSystem:ShowDialog(nDialogId, bDialogBoard)
end

-- 指定某一玩家显示对话
function BattleInteractionHelper:PlayerShowDialog(tbPlayer, nDialogId)
    BattleInteractionSystem:PlayerShowDialog(tbPlayer, nDialogId)
end

-- 头上的气泡
function BattleInteractionHelper:ShowHeadDialog(tbShip, nDialogId)
    BattleInteractionSystem:ShowHeadDialog(tbShip, nDialogId)
end

return BattleInteractionHelper 