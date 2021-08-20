
local ParentFolder              = script.Parent
local MainFolder                = ParentFolder.Parent
local UtilFolder                = MainFolder.Util
local ModulesFolder             = MainFolder.MainModules

local Logic                     = require(ModulesFolder.Logic)
local ContainerHandler          = require(ModulesFolder.ContainerHandler)
local Maid                      = require(UtilFolder.Maid)

local newMaid                   = Maid.new()

local DEFAULT_OUTLINE_THICKNESS = settings().Studio["Line Thickness"]
local DEFAULT_SELECTION_COLOR   = settings().Studio["Select Color"]
local MATH_HUGE                 = math.huge




local Visualizer = {}


    --//Private Methods:

        function Visualizer:_VisualizeCut(Object: BasePart)
            assert(Object ~= nil, "Missing arguments!")

                local selectionBox = Instance.new("SelectionBox")
                selectionBox.Parent = Object
                selectionBox.Adornee = Object
                selectionBox.LineThickness = DEFAULT_OUTLINE_THICKNESS
                selectionBox.Color3 = DEFAULT_SELECTION_COLOR
        end


        function Visualizer:_ApplyVisualizationsIn(Parent)
            for Index = 1, #Parent:GetChildren() do
                local Object = Parent:GetChildren()[Index]
                self:_VisualizeCut(Object)
            end
        end


        function Visualizer:ClearVisualizer()
            newMaid:DoCleaning()
            ContainerHandler:DestroyContainer()
        end


    --//Public Methods:

        function Visualizer:RefreshVisualizer()
            local containerData = ContainerHandler:ReturnData()
            if containerData.container ~= nil then
                ContainerHandler:ClearContainer()
            else
                ContainerHandler:CreateContainer()
            end
        end


        function Visualizer:VisualizeDivisions(obj: BasePart, numOfDivisions: number)
            assert(obj ~= nil and obj:IsA("BasePart"), "Object either nil or of incorrect type!")
            assert(numOfDivisions ~= nil and typeof(numOfDivisions) == "number", "numOfDivisions either nil or of incorrect type!")

            local containerData = ContainerHandler:ReturnData()

            if containerData.previousSelections[obj] == nil then
                newMaid:DoCleaning()
                newMaid:GiveTask(
                    obj.Changed:Connect(function()
                        ContainerHandler:ClearContainer()
                    end)
                )
                containerData.previousSelections[obj] = true
            end

            local partToClone = Instance.new("Part")
            partToClone.Locked = true
            partToClone.Anchored = true
            partToClone.CastShadow = false
            partToClone.CanCollide = false
            partToClone.CanTouch = false
            partToClone.Transparency = 1
            partToClone.Parent = containerData.container
            partToClone.Position = Vector3.new(MATH_HUGE, MATH_HUGE, MATH_HUGE)

            Logic:_Subdivide(containerData.container, obj, numOfDivisions, partToClone)
            self:_ApplyVisualizationsIn(containerData.container)
        end


return Visualizer