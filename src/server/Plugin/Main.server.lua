--[[

    You may have noticed that I'm running :_Subdivide method twice: once in the CutVisualizer and once in
    Logic module. Not the most efficient way of executing this functionality, and ideally you'd want to cache the stored objects
    from the container and re-parent them to the desired location without having to run :_Subdivide twice.

    With that being said, I've left a possibility to do so by abstracting container logic

    ~vertical alignment gang

]]

local ContextActionService = game:GetService("ContextActionService")
local Selection            = game:GetService("Selection")

local MainFolder           = script.Parent
local ModulesFolder        = MainFolder.MainModules
local UtilFolder           = MainFolder.Util

local Logic                = require(ModulesFolder.Logic)
local CutVisualizer        = require(ModulesFolder.CutVisualizer)
local Maid                 = require(UtilFolder.Maid)
local newMaid              = Maid.new()

local toolbar              = plugin:CreateToolbar("Loop cut Utility")
local newScriptButton      = toolbar:CreateButton("Toggle LoopCut", "Toggles LoopCut on and off", "rbxassetid://7166997540")

--//Plugin action creation (Binding relevant action to keys)
local executeCutAction     = plugin:CreatePluginAction("LoopCut Execute", "Execute LoopCut", "Executes loop-cuts on selection", "rbxassetid://7166997540", true)
local increaseCutsAction   = plugin:CreatePluginAction("LoopCut Increase", "Increase LoopCuts", "Increases number of loop-cuts", "rbxassetid://7166997540", true)
local decreaseCutsAction   = plugin:CreatePluginAction("LoopCut Decrease", "Decrease LoopCuts", "Decreases number of loop-cuts", "rbxassetid://7166997540", true)
local selectXAxisAction    = plugin:CreatePluginAction("LoopCut X", "X Axis Selection", "Sets loop-cuts along X axis of the selected object", "rbxassetid://7166997540", true)
local selectYAxisAction    = plugin:CreatePluginAction("LoopCut Y", "Y Axis Selection", "Sets loop-cuts along Y axis of the selected object", "rbxassetid://7166997540", true)
local selectZAxisAction    = plugin:CreatePluginAction("LoopCut Z", "Z Axis Selection", "Sets loop-cuts along Z axis of the selected object", "rbxassetid://7166997540", true)



local SCROLL_ACTION_NAME   = "Log scroll"
local MOVEMENT_ACTION_NAME = "Log mouse movement"
local isEnabled


local function displayVisuals()
    local selectedObjects = Logic:ValidateSelection()
    if not selectedObjects or #selectedObjects == 0 then
        return
    end

    CutVisualizer:RefreshVisualizer()
    for Index = 1, #selectedObjects do
        local selectedObject = selectedObjects[Index]
        CutVisualizer:VisualizeDivisions(selectedObject, Logic:RetrieveDivisions())
    end
end


local function reset()
    Logic:SetNumOfDivisions(2)
    displayVisuals()
end


local function logAction(actionName, _inputState, inputObject)
    local faceDetected = Logic:DetectFaceAndEdge(inputObject.Position)
    local previousSelectionAxis, currentSelectionAxis = Logic:RetrieveSelectionAxis()

    if actionName == SCROLL_ACTION_NAME then
        Logic:IncrementNumOfDivisions(inputObject.Position.Z)
        displayVisuals()
    elseif actionName == MOVEMENT_ACTION_NAME and faceDetected then
        if previousSelectionAxis == currentSelectionAxis then
            return
        end
        displayVisuals()
    end
end


local function connectActions()
    newMaid:GiveTask(
            executeCutAction.Triggered:Connect(function()
                if Logic:SubdivideSelection() then
                    CutVisualizer:ClearVisualizer()
                    updatePluginStatus(false)
                end
            end)
        )
    newMaid:GiveTask(
            Selection.SelectionChanged:Connect(function()
                local selectedObjects = Logic:ValidateSelection()
                if not selectedObjects or #selectedObjects == 0 then
                    updatePluginStatus(false)
                end
            end)
        )
    newMaid:GiveTask(
            increaseCutsAction.Triggered:Connect(function()
                Logic:IncrementNumOfDivisions(1)
                displayVisuals()
            end)
        )
    newMaid:GiveTask(
            decreaseCutsAction.Triggered:Connect(function()
                Logic:IncrementNumOfDivisions(-1)
                displayVisuals()
            end)
        )
    newMaid:GiveTask(
            selectXAxisAction.Triggered:Connect(function()
                Logic:SetAxisOfAction("X")
                displayVisuals()
            end)
        )
    newMaid:GiveTask(
            selectYAxisAction.Triggered:Connect(function()
                Logic:SetAxisOfAction("Y")
                displayVisuals()
            end)
        )
    newMaid:GiveTask(
            selectZAxisAction.Triggered:Connect(function()
                Logic:SetAxisOfAction("Z")
                displayVisuals()
            end)
        )
end


function updatePluginStatus(status: boolean?)
    if status ~= nil and typeof(status) == "boolean" then
        isEnabled = status
    else
        isEnabled = not isEnabled
    end
    newScriptButton:SetActive(isEnabled)

    if isEnabled then
        reset()
        connectActions()
        ContextActionService:BindAction(SCROLL_ACTION_NAME, logAction, true, Enum.UserInputType.MouseWheel)
        ContextActionService:BindAction(MOVEMENT_ACTION_NAME, logAction, true, Enum.UserInputType.MouseMovement)
    else
        newMaid:DoCleaning()
        CutVisualizer:ClearVisualizer()
        ContextActionService:UnbindAction(SCROLL_ACTION_NAME)
        ContextActionService:UnbindAction(MOVEMENT_ACTION_NAME)
    end
end


newScriptButton.Click:Connect(updatePluginStatus)
updatePluginStatus(false)
