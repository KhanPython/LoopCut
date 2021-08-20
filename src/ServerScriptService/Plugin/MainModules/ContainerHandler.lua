
local ParentFolder              = script.Parent
local MainFolder                = ParentFolder.Parent
local UtilFolder                = MainFolder.Util
local Maid                      = require(UtilFolder.Maid)
local newMaid                   = Maid.new()

local CONTAINER_NAME            = "LoopCut_SelectionBoxes"

--//Intentionally mutable
local containerData = {

    previousSelections = {};
    container = nil;

}


local Container = {}


    function Container:DestroyContainer()
        newMaid:DoCleaning()
        containerData.previousSelections = {}
        if containerData.container == nil then
            return
        end
        containerData.container:Destroy()
        containerData.container = nil
    end


    function Container:ClearContainer()
        if containerData.container == nil then
            return
        end
        containerData.container:ClearAllChildren()
    end


    function Container:CreateContainer()
        containerData.container = Instance.new("Folder")
        containerData.container.Parent = workspace.CurrentCamera
        containerData.container.Name = CONTAINER_NAME
    end


    function Container:ReturnData()
        return containerData
    end


return Container