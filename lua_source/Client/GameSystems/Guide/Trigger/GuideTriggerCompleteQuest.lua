-----------------------------------------------------
--File Name    : GuideTriggerCompleteQuest.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerCompleteQuest = luaclass("GuideTriggerCompleteQuest",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override
function GuideTriggerCompleteQuest:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_ACCEPT_QUEST, self, self.OnRefreshQuest)
end

function GuideTriggerCompleteQuest:OnRefreshQuest(nQuestId, nQuestSubId, nNewSubQuestID)
    self:DebugLog("OnRefreshQuest,nQuestId="..tostring(nQuestId).." nQuestSubId="..tostring(nQuestSubId))
    if(self.tbTemplate.tbQuestId == nil)then
        return
    end
    if(self.tbTemplate.tbQuestId[1] == nQuestId and self.tbTemplate.tbQuestId[2] == nQuestSubId)then
        self:Trigger()
    end
    
end

return GuideTriggerCompleteQuest
