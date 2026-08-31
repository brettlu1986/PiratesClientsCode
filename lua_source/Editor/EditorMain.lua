log("Init Editor Logic....")

local EditorExportManager = require("EditorExportManager")

local function PlayInEditor()
    GLuaEditorHelper:SetIsDedicatedServer(false)
    EditorExportManager:Export()
end

local function PlayInCommandlet(szParams)
    GLuaEditorHelper:SetIsDedicatedServer(false)
    require("EditorLaunchParams"):Parse(szParams)

    EditorExportManager:Export()
end

if(GPlayInEditor) then
    PlayInEditor()
elseif(GPlayInCommandlet) then
    PlayInCommandlet(GLaunchParams)
end

log("Editor Logic Finished...")