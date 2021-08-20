--[[

        Credits to the good chap in: https://devforum.roblox.com/t/edge-detection-from-mouse/705054/22
        :_Subdivide method is a bit dirty, if you've got a more elegant solution, feel free to post up!

]]

local Selection                 = game:GetService("Selection")
local ChangeHistoryService      = game:GetService("ChangeHistoryService")

local MIN_DIVISIONS             = 2

local storedVariables = {
    numOfDivisions = MIN_DIVISIONS;
    previousPosition = nil;
    previousSelection = nil;
    previousSelectionAxis = nil;
    selectionAxis = nil;
}



local LogicHandler = {}


    --//Private Methods:

        function LogicHandler:SetAxisOfAction(axis: string)
            storedVariables.previousSelectionAxis = storedVariables.selectionAxis
            storedVariables.selectionAxis = axis
        end


        function LogicHandler:_WhichFaces(part: BasePart, pos: Position, epsilon: number)
            epsilon = epsilon or .5
            pos = part.CFrame:ToObjectSpace(CFrame.new(pos))
            local halfSize = part.Size / 2
            if math.abs(pos.Y) < halfSize.Y + epsilon
                and math.abs(pos.Z) < halfSize.Z + epsilon
                and math.abs(pos.X) < halfSize.X + epsilon
            then
                local faces = {}
                -- check if we're close to an edge
                if pos.Y > halfSize.Y - epsilon then 
                    table.insert(faces, Enum.NormalId.Top) 
                end
                if pos.Y < epsilon - halfSize.Y then 
                    table.insert(faces, Enum.NormalId.Bottom) 
                end

                if pos.Z > halfSize.Z - epsilon then 
                    table.insert(faces, Enum.NormalId.Back) 
                end
                if pos.Z < epsilon - halfSize.Z then 
                    table.insert(faces, Enum.NormalId.Front) 
                end

                if pos.X > halfSize.X - epsilon then 
                    table.insert(faces, Enum.NormalId.Right) 
                end
                if pos.X < epsilon - halfSize.X then 
                    table.insert(faces, Enum.NormalId.Left) 
                end

                return Faces.new(unpack(faces))
            else
                return 
            end
        end


        function LogicHandler:_RaycastFromScreenPoint(mousePos: Vector3, whitelist)
            local camera = workspace.CurrentCamera
            local screenRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

            local params = RaycastParams.new()
            params.CollisionGroup = "Default"
            if whitelist then
                params.FilterType = Enum.RaycastFilterType.Whitelist
                params.FilterDescendantsInstances = whitelist
            end

            local result = workspace:Raycast(
                screenRay.Origin, screenRay.Direction * 1000, params
            )

            return result
        end


        function LogicHandler:_GetPositionAndPartFromScreenPoint(pos: Vector3)
            local result = self:_RaycastFromScreenPoint(pos, Selection:Get())

            if not result or result.Instance.Locked then
                result = self:_RaycastFromScreenPoint(pos)

                if not result or result.Instance.Locked then
                    return nil, nil
                end
            end

            local part = result.Instance
            local position = result.Position

            return part, position
        end


    --//Public Methods:

        --//Intended to be semi-private
        function LogicHandler:_Subdivide(Parent, obj: BasePart, divisionNum: number, partToClone: BasePart)
            local axisOfAction = storedVariables.selectionAxis
            if axisOfAction == nil then
                return
            end

            if partToClone == nil then
                partToClone = obj
            end

            local absoluteSize = obj.Size
            local absolutePos = obj.Position
            local absoluteCFrame = obj.CFrame

            local INDIVIDUAL_SIZE = absoluteSize[axisOfAction]/divisionNum
            local STARTING_POS = absolutePos[axisOfAction] - absoluteSize[axisOfAction]/2
            local SIZE_VECTOR

            if axisOfAction == "X" then
                SIZE_VECTOR = Vector3.new(INDIVIDUAL_SIZE, absoluteSize.Y, absoluteSize.Z)
            elseif axisOfAction == "Y" then
                SIZE_VECTOR = Vector3.new(absoluteSize.X, INDIVIDUAL_SIZE, absoluteSize.Z)
            elseif axisOfAction == "Z" then
                SIZE_VECTOR = Vector3.new(absoluteSize.X, absoluteSize.Y, INDIVIDUAL_SIZE)
            end

            for Index = 1, divisionNum do
                local OFFSET = STARTING_POS - INDIVIDUAL_SIZE/2 + INDIVIDUAL_SIZE*Index
                local VECTOR_POSITION

                if axisOfAction == "X" then
                    VECTOR_POSITION = Vector3.new(OFFSET, absolutePos.Y, absolutePos.Z)
                elseif axisOfAction == "Y" then
                    VECTOR_POSITION = Vector3.new(absolutePos.X, OFFSET, absolutePos.Z)
                elseif axisOfAction == "Z" then
                    VECTOR_POSITION = Vector3.new(absolutePos.X, absolutePos.Y, OFFSET)
                end

                --//Convert to object space (For the purpose of applying object's rotation)
                local OBJECT_SPACE = CFrame.new(absolutePos):ToObjectSpace(CFrame.new(VECTOR_POSITION))
                local APPLIED_CFRAME = absoluteCFrame:ToWorldSpace(OBJECT_SPACE)

                local newObj = partToClone:Clone()
                newObj.Parent = Parent
                newObj.Size = SIZE_VECTOR
                newObj.CFrame = APPLIED_CFRAME
            end
        end


        --//In case the responsiveness feels wonky - you may want to fiddle around with this:
        function LogicHandler:DetectFaceAndEdge(mousePos: Vector3)
            local part, position = self:_GetPositionAndPartFromScreenPoint(mousePos)
            if part == nil or position == nil then
                return
            end

            local faces = self:_WhichFaces(part, position)
            if faces.Top or faces.Bottom then
                if faces.Back then
                    self:SetAxisOfAction("Y")
                else
                    self:SetAxisOfAction("X")
                end
            elseif faces.Front or faces.Back then
                self:SetAxisOfAction("Y")
            elseif faces.Right or faces.Left then
                self:SetAxisOfAction("Z")
            end

            storedVariables.previousSelection = part
            storedVariables.previousPosition = position

            return true
        end


        function LogicHandler:SubdivideSelection()
            --local objectToSelect = table.create(storedVariables.numOfDivisions)
            local selectedObjects = self:ValidateSelection()
            if not selectedObjects or #selectedObjects == 0 then
                return
            end

            for Index = 1, #selectedObjects do
                local selectedObject = selectedObjects[Index]
                local model = Instance.new("Model")
                model.Parent = selectedObject.Parent
                self:_Subdivide(model, selectedObject, storedVariables.numOfDivisions)
                selectedObject.Parent = nil
            end

            ChangeHistoryService:SetWaypoint("Subdivision complete")
            return true
        end


        function LogicHandler:ValidateSelection()
            if #Selection:Get() == 0 then
                return
            end

            local selectedObjects = table.create(#Selection:Get())
            for Index = 1, #Selection:Get() do
                local selectedObject = Selection:Get()[Index]
                if selectedObject:IsA("BasePart") then
                    table.insert(selectedObjects, selectedObject)
                end
            end

            return selectedObjects
        end


        function LogicHandler:SetNumOfDivisions(num: number)
            assert(num ~= nil and typeof(num) == "number", "Missing argument or incorrect type!")

            local selectedObj = Selection:Get()[1]
            if selectedObj == nil or not selectedObj:IsA("BasePart") then
                return
            end

            storedVariables.numOfDivisions = math.max(MIN_DIVISIONS, num)
        end


        function LogicHandler:IncrementNumOfDivisions(num: number)
            num += storedVariables.numOfDivisions
            self:SetNumOfDivisions(num)
        end


        function LogicHandler:RetrieveDivisions()
            return storedVariables.numOfDivisions
        end


        function LogicHandler:RetrieveSelectionAxis()
            return storedVariables.previousSelectionAxis, storedVariables.selectionAxis
        end


return LogicHandler