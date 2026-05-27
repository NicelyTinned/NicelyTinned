local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Load LiteUI
local LiteUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NicelyTinned/lite-ui/refs/heads/main/src/init.luau"))()

local trackedMeshes = {}
local renderConnection = nil

-- Custom Accessory Welder
local function weldCustomAccessory(character, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end
    
    local accAtt = handle:FindFirstChildWhichIsA("Attachment")
    if not accAtt then return end

    local charAtt = character:FindFirstChild(accAtt.Name, true)
    if not charAtt then return end

    -- Ensure handle is unanchored to move with the character
    handle.Anchored = false

    local weld = Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = charAtt.Parent
    weld.Part1 = handle
    weld.C0 = charAtt.CFrame
    weld.C1 = accAtt.CFrame
    weld.Parent = handle
    
    accessory.Parent = character
end

-- Dynamic Avatar Loader
local function loadPlayerAvatar(userId)
    local character = Players.LocalPlayer.Character
    if not character then return end

    -- Clean up previous custom skin, accessories, clothing, and body colors
    for _, obj in pairs(character:GetChildren()) do
        if obj.Name:match("^CustomMesh_") or 
           obj:IsA("Accessory") or 
           obj:IsA("Shirt") or 
           obj:IsA("Pants") or 
           obj:IsA("BodyColors") then
            obj:Destroy()
        end
    end
    trackedMeshes = {}

    -- Fetch Avatar Data
    local success, appearanceModel = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)
    
    if not success or not appearanceModel then return end

    local shirtTemplate = nil
    local pantsTemplate = nil
    local bodyColors = nil

    -- Extract, Clone, and Import to Character
    for _, item in pairs(appearanceModel:GetChildren()) do
        if item:IsA("Shirt") then
            shirtTemplate = item.ShirtTemplate
            item:Clone().Parent = character
        elseif item:IsA("Pants") then
            pantsTemplate = item.PantsTemplate
            item:Clone().Parent = character
        elseif item:IsA("BodyColors") then
            item:Clone().Parent = character
            bodyColors = item
        elseif item:IsA("Accessory") then
            weldCustomAccessory(character, item:Clone())
        end
    end

    -- Setup Visibility (Exclude Accessory parts so they stay visible)
    for _, obj in character:GetDescendants() do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" and not obj.Parent:IsA("Accessory") then
            if obj.Name:match("Arm") or obj.Name == "Head" then
                obj.Transparency = 0
            else
                obj.Transparency = 1
            end
        elseif obj:IsA("Decal") and obj.Parent.Name ~= "Head" and not obj.Parent:IsA("Accessory") then
            obj.Transparency = 1
        end
    end

    -- Construct Dynamic MESH_DATA mapping
    local DYNAMIC_MESH_DATA = {
        -- First 2 non-rotational (Texture: Shirt)
        {BodyPart = "Torso", MeshId = "123826306477155", TextureId = shirtTemplate, Size = 1.01, Opacity = 0.02, Position = Vector3.zero, Rotation = Vector3.new(0, -90, 0)},
        {BodyPart = "Torso", MeshId = "123826306477155", TextureId = shirtTemplate, Size = 0.95, Opacity = 1, Position = Vector3.zero, Rotation = Vector3.new(0, -90, 0)},
        
        -- First 2 rotational (Texture: Pants)
        {BodyPart = "Torso", MeshId = "114977119770915", TextureId = pantsTemplate, Size = 0.8, Opacity = 1, Position = Vector3.new(0.5, -1, -0.4), Rotation = Vector3.new(0, 180, 0), RotationalDrag = {MaxDownAngle = 20, MaxUpAngle = 20, Pivot = CFrame.new(0, -1, -0.5) * CFrame.Angles(0,math.rad(180),0), Strength = 0.2, Damp = 0.7}},
        {BodyPart = "Torso", MeshId = "102005630554650", TextureId = pantsTemplate, Size = 0.8, Opacity = 1, Position = Vector3.new(-0.5, -1, -0.4), Rotation = Vector3.new(0, 180, 0), RotationalDrag = {MaxDownAngle = 20, MaxUpAngle = 20, Pivot = CFrame.new(0, -1, -0.5) * CFrame.Angles(0,math.rad(180),0), Strength = 0.2, Damp = 0.7}},
        
        -- Last rotational (Texture: Shirt)
        {BodyPart = "Torso", MeshId = "7606070501", TextureId = shirtTemplate, Size = 1.15, Opacity = 1, Position = Vector3.new(0, 0.2, 0.75), Rotation = Vector3.new(0, -90, 0), RotationalDrag = {MaxDownAngle = 25, MaxUpAngle = 80, Pivot = CFrame.new(0, 1, -0.5), Strength = 0.2, Damp = 0.45}},
        
        -- Legs (Texture: Pants)
        {BodyPart = "Right Leg", MeshId = "71665474693582", TextureId = pantsTemplate, Size = 1, Opacity = 1, Position = Vector3.new(0.05, 0, 0), Rotation = Vector3.new(0, 180, 0)},
        {BodyPart = "Left Leg", MeshId = "107817600592761", TextureId = pantsTemplate, Size = 1, Opacity = 1, Position = Vector3.new(-0.05, 0, 0), Rotation = Vector3.new(0, 180, 0)}
    }

    local R15_MAP = {
        ["Torso"] = "UpperTorso", ["Left Leg"] = "LeftUpperLeg", ["Right Leg"] = "RightUpperLeg"
    }

    -- Apply MeshParts with SurfaceAppearance
    for _, data in ipairs(DYNAMIC_MESH_DATA) do
        local targetPart = character:FindFirstChild(data.BodyPart) or character:FindFirstChild(R15_MAP[data.BodyPart])
        if not targetPart then continue end

        local customPart = Instance.new("MeshPart")
        customPart.Name = "CustomMesh_" .. data.BodyPart
        customPart.CanCollide = false
        customPart.CanTouch = false
        customPart.CanQuery = false
        customPart.Massless = true
        customPart.Anchored = true
        if bodyColors then customPart.Color = bodyColors[data.BodyPart:gsub("%s", "") .. "Color3"] end
        customPart.Transparency = 1 - (data.Opacity or 1)
        
        -- MeshId assignment is usually restricted, but executors bypass this.
        -- Wrapped in a pcall to prevent the loop from breaking if the executor throws.
        pcall(function()
            customPart.MeshId = "rbxassetid://" .. data.MeshId
            
            if data.TextureId then
                local surfaceApp = Instance.new("SurfaceAppearance")
                surfaceApp.ColorMap = data.TextureId
                surfaceApp.AlphaMode = Enum.AlphaMode.Overlay -- Eliminates the black background
                surfaceApp.Parent = customPart
            end
        end)
        
        customPart.Size = Vector3.new(data.Size, data.Size, data.Size)

        local offsetCFrame = CFrame.new(data.Position.X, data.Position.Y, -data.Position.Z) * CFrame.Angles(math.rad(data.Rotation.X), math.rad(data.Rotation.Y), math.rad(data.Rotation.Z))
        customPart.CFrame = targetPart.CFrame * offsetCFrame
        customPart.Parent = character

        local entry = { CustomPart = customPart, TargetPart = targetPart, Offset = offsetCFrame, RotationalDrag = data.RotationalDrag }
        
        if data.RotationalDrag then
            entry.CurrentAngleX = 0
            entry.AngularVelocity = 0
            entry.LastPosition = targetPart.Position
        end
        
        table.insert(trackedMeshes, entry)
    end
end

-- Render Loop Hook
if renderConnection then renderConnection:Disconnect() end

renderConnection = RunService.PreRender:Connect(function(dt)
    for i = #trackedMeshes, 1, -1 do
        local data = trackedMeshes[i]
        
        if not (data.TargetPart and data.TargetPart.Parent and data.CustomPart and data.CustomPart.Parent) then
            if data.CustomPart then data.CustomPart:Destroy() end
            table.remove(trackedMeshes, i)
            continue
        end

        local targetCFrame = data.TargetPart.CFrame * data.Offset

        if data.RotationalDrag then
            local dragParams = data.RotationalDrag
            local targetAngleX = 0
            
            local currentPosition = data.TargetPart.Position
            local worldVelocity = (currentPosition - data.LastPosition) / dt
            data.LastPosition = currentPosition 
            
            local localVel = data.TargetPart.CFrame:VectorToObjectSpace(worldVelocity)
            local dragForce = (localVel.Z * 2.5) - (localVel.Y * 1.5)
            
            if dragForce < 0 then
                targetAngleX = math.max(dragForce, -dragParams.MaxDownAngle)
            else
                targetAngleX = math.min(dragForce, dragParams.MaxUpAngle)
            end

            local stiffness = (dragParams.Strength or 0.2) * 800
            local damping = (dragParams.Damp or 0.78) * 15
            
            local displacement = data.CurrentAngleX - targetAngleX
            local springAcceleration = (-stiffness * displacement) - (damping * data.AngularVelocity)
            
            data.AngularVelocity = data.AngularVelocity + (springAcceleration * dt)
            data.CurrentAngleX = data.CurrentAngleX + (data.AngularVelocity * dt)
            
            if data.CurrentAngleX < 0 then
                data.CurrentAngleX = math.max(data.CurrentAngleX, -dragParams.MaxDownAngle)
            else
                data.CurrentAngleX = math.min(data.CurrentAngleX, dragParams.MaxUpAngle)
            end

            local pivotCFrame = data.TargetPart.CFrame * dragParams.Pivot
            local originalCFrame = data.TargetPart.CFrame * data.Offset
            local offsetFromPivot = pivotCFrame:Inverse() * originalCFrame
            local rotationCFrame = CFrame.Angles(math.rad(data.CurrentAngleX), 0, 0)
            
            data.CustomPart.CFrame = pivotCFrame * rotationCFrame * offsetFromPivot
        else
            data.CustomPart.CFrame = targetCFrame
        end
    end
end)

-- Multi-Platform UI Dragging Logic
local function initializeDrag(frame)
    local dragging, dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- UI Construction
local isMinimized = false
local defaultSize = UDim2.new(0.9, 0, 0, 160)
local minSize = UDim2.new(0, 45, 0, 45)

local ScreenGui = LiteUI.new("ScreenGui", {
    Parent = game.CoreGui,
    Name = "AstralAvatarHub",
    ResetOnSpawn = false,
    Children = {
        MainFrame = {"Frame", {
            Size = defaultSize,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = Color3.fromRGB(30, 30, 35),
            ClipsDescendants = true,
            Children = {
                UICorner = {"UICorner", {CornerRadius = UDim.new(0, 8)}},
                UISizeConstraint = {"UISizeConstraint", {MaxSize = Vector2.new(350, 160)}},
                
                -- Header & Minimize Button
                Header = {"Frame", {
                    Size = UDim2.new(1, 0, 0, 45),
                    BackgroundTransparency = 1,
                    Children = {
                        Title = {"TextLabel", {
                            Size = UDim2.new(1, -50, 1, 0),
                            Position = UDim2.new(0, 15, 0, 0),
                            BackgroundTransparency = 1,
                            Text = "Avatar Importer",
                            TextColor3 = Color3.new(1, 1, 1),
                            Font = Enum.Font.GothamBold,
                            TextSize = 16,
                            TextXAlignment = Enum.TextXAlignment.Left
                        }},
                        MinButton = {"TextButton", {
                            Size = UDim2.new(0, 45, 0, 45),
                            Position = UDim2.new(1, -45, 0, 0),
                            BackgroundTransparency = 1,
                            Text = "-",
                            TextColor3 = Color3.new(1, 1, 1),
                            Font = Enum.Font.GothamBold,
                            TextSize = 20,
                            Events = {
                                MouseButton1Click = function(self)
                                    local mainFrame = self.Instance.Parent.Parent
                                    local content = mainFrame.Content
                                    
                                    if isMinimized then
                                        isMinimized = false
                                        self.Instance.Text = "-"
                                        mainFrame.Header.Title.Visible = true
                                        content.Visible = true
                                        LiteUI.Element(mainFrame):Tween({Size = defaultSize}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
                                    else
                                        isMinimized = true
                                        self.Instance.Text = "+"
                                        mainFrame.Header.Title.Visible = false
                                        content.Visible = false
                                        LiteUI.Element(mainFrame):Tween({Size = minSize}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
                                    end
                                end
                            }
                        }}
                    }
                }},
                
                -- Main Content area
                Content = {"Frame", {
                    Size = UDim2.new(1, 0, 1, -45),
                    Position = UDim2.new(0, 0, 0, 45),
                    BackgroundTransparency = 1,
                    Children = {
                        UsernameInput = {"TextBox", {
                            Size = UDim2.new(1, -30, 0, 40),
                            Position = UDim2.new(0, 15, 0, 5),
                            BackgroundColor3 = Color3.fromRGB(45, 45, 50),
                            PlaceholderText = "Enter Username",
                            Text = "",
                            TextColor3 = Color3.new(1, 1, 1),
                            Font = Enum.Font.Gotham,
                            TextSize = 14,
                            Children = {
                                UICorner = {"UICorner", {CornerRadius = UDim.new(0, 6)}}
                            }
                        }},
                        LoadButton = {"TextButton", {
                            Size = UDim2.new(1, -30, 0, 40),
                            Position = UDim2.new(0, 15, 0, 55),
                            BackgroundColor3 = Color3.fromRGB(80, 120, 200),
                            Text = "Load Skin",
                            TextColor3 = Color3.new(1, 1, 1),
                            Font = Enum.Font.GothamBold,
                            TextSize = 14,
                            Children = {
                                UICorner = {"UICorner", {CornerRadius = UDim.new(0, 6)}}
                            },
                            Events = {
                                MouseButton1Click = function(self)
                                    local inputBox = self.Instance.Parent.UsernameInput
                                    local username = inputBox.Text
                                    
                                    if username and username ~= "" then
                                        self.Instance.Text = "Fetching ID..."
                                        
                                        local nameSuccess, targetId = pcall(function()
                                            return Players:GetUserIdFromNameAsync(username)
                                        end)
                                        
                                        if nameSuccess and targetId then
                                            self.Instance.Text = "Loading Assets..."
                                            loadPlayerAvatar(targetId)
                                            self.Instance.Text = "Load Skin"
                                        else
                                            self.Instance.Text = "User Not Found"
                                            task.wait(1.5)
                                            self.Instance.Text = "Load Skin"
                                        end
                                    else
                                        self.Instance.Text = "Enter a name!"
                                        task.wait(1)
                                        self.Instance.Text = "Load Skin"
                                    end
                                end
                            }
                        }}
                    }
                }}
            }
        }}
    }
})

-- Initialize dragging on CoreGui tree instantiation
local targetMainFrame = game.CoreGui:WaitForChild("AstralAvatarHub"):WaitForChild("MainFrame")
initializeDrag(targetMainFrame)