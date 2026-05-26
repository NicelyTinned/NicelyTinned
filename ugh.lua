local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MESH_DATA = {
	{
		BodyPart = "Torso", MeshId = "123826306477155", TextureId = "88688267255542",
		Size = 1.01, Opacity = 0.02, Color = Color3.fromRGB(0, 0, 0),
		Position = Vector3.zero, Rotation = Vector3.new(0, -90, 0),
	},
	{
		BodyPart = "Torso", MeshId = "123826306477155", TextureId = "88688267255542",
		Size = 0.95, Opacity = 1, Color = Color3.fromRGB(159, 161, 172),
		Position = Vector3.zero, Rotation = Vector3.new(0, -90, 0),
	},
	{
		BodyPart = "Torso", MeshId = "114977119770915", TextureId = "102627144635898",
		Size = 0.7, Opacity = 1, Color = Color3.fromRGB(47, 47, 47),
		Position = Vector3.new(0.5, -1, -1), Rotation = Vector3.new(0, 180, 0),
		RotationalDrag = {MaxDownAngle = 20, MaxUpAngle = 20, Pivot = CFrame.new(0, -1, 0) * CFrame.Angles(0,math.rad(180),0), Strength = 0.2, Damp = 0.78}
	},
	{
		BodyPart = "Torso", MeshId = "102005630554650", TextureId = "102627144635898",
		Size = 0.7, Opacity = 1, Color = Color3.fromRGB(47, 47, 47),
		Position = Vector3.new(-0.5, -1, -1), Rotation = Vector3.new(0, 180, 0),
		RotationalDrag = {MaxDownAngle = 20, MaxUpAngle = 20, Pivot = CFrame.new(0, -1, 0) * CFrame.Angles(0,math.rad(180),0), Strength = 0.2, Damp = 0.78}
	},
	{
		BodyPart = "Torso", MeshId = "7606070501", TextureId = "88688267255542", 
		Size = 1.375, Opacity = 1, Color = Color3.fromRGB(47, 47, 47), 
		Position = Vector3.new(0, 0.15, 0.75), Rotation = Vector3.new(0, -90, 0), 
		RotationalDrag = {MaxDownAngle = 15, MaxUpAngle = 37.5, Pivot = CFrame.new(0, 1, -0.5), Strength = 0.2, Damp = 0.82}
	},
	{BodyPart = "Right Leg", MeshId = "71665474693582", TextureId = "11335685730", Size = 1, Opacity = 1, Color = Color3.fromRGB(163, 75, 75), Position = Vector3.new(0.05, 0, 0), Rotation = Vector3.new(0, 180, 0)},
	{BodyPart = "Left Leg", MeshId = "107817600592761", TextureId = "11335685730", Size = 1, Opacity = 1, Color = Color3.fromRGB(163, 75, 75), Position = Vector3.new(-0.05, 0, 0), Rotation = Vector3.new(0, 180, 0)},
	{BodyPart = "Left Arm", MeshId = "108790881235134", TextureId = nil, Size = 1, Opacity = 1, Color = Color3.fromRGB(0, 0, 0), Position = Vector3.new(0.2, 0, 0), Rotation = Vector3.new(0, -180, 0)},
	{BodyPart = "Right Arm", MeshId = "108790881235134", TextureId = nil, Size = 1, Opacity = 1, Color = Color3.fromRGB(0, 0, 0), Position = Vector3.new(-0.2, 0, 0), Rotation = Vector3.new(0, 180, 0)},
	{BodyPart = "Head", MeshId = "116853927011404", TextureId = "107382646514419", Size = 1, Opacity = 1, Color = Color3.fromRGB(163, 75, 75), Position = Vector3.new(0, 0.05, 0), Rotation = Vector3.zero},
	{BodyPart = "Head", MeshId = "17260008146", TextureId = "17259865086", Size = 1, Opacity = 1, Color = Color3.fromRGB(163, 75, 75), Position = Vector3.new(0, -0.25, 0), Rotation = Vector3.zero},
	{BodyPart = "Head", MeshId = "125408165091592", TextureId = "97874566232499", Size = 1, Opacity = 1, Color = Color3.fromRGB(163, 75, 75), Position = Vector3.new(0, 0.05, 0), Rotation = Vector3.new(0, 180, 0)},
	{BodyPart = "Head", MeshId = "17636295387", TextureId = "17636614874", Size = 1, Opacity = 1, Color = Color3.fromRGB(163, 75, 75), Position = Vector3.new(0, 0.5, -0.2), Rotation = Vector3.new(0, 180, 0)}
}

local R15_MAP = {
	["Torso"] = "UpperTorso", ["Left Arm"] = "LeftUpperArm", ["Right Arm"] = "RightUpperArm",
	["Left Leg"] = "LeftUpperLeg", ["Right Leg"] = "RightUpperLeg", ["Head"] = "Head"
}

local trackedMeshes = {}

local function applySkin(character)
	if character:GetAttribute("CustomSkinApplied") then return end
	character:SetAttribute("CustomSkinApplied", true)
	
	task.wait(0.5)

	for _, obj in character:GetDescendants() do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			obj.Transparency = 1
		elseif obj:IsA("Decal") then
			obj.Transparency = 1
		end
	end

	for _, data in ipairs(MESH_DATA) do
		local targetPart = character:FindFirstChild(data.BodyPart) or character:FindFirstChild(R15_MAP[data.BodyPart])
		if not targetPart then continue end

		local customPart = Instance.new("Part")
		customPart.Name = "CustomMesh_" .. data.BodyPart
		customPart.Size = Vector3.new(1, 1, 1)
		customPart.CanCollide = false
		customPart.CanTouch = false
		customPart.CanQuery = false
		customPart.Massless = true
		customPart.Anchored = true
		customPart.Color = data.Color
		customPart.Transparency = 1 - (data.Opacity or 1)
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://" .. data.MeshId
		if data.TextureId then
			mesh.TextureId = "rbxassetid://" .. data.TextureId
		end
		mesh.Scale = Vector3.new(data.Size, data.Size, data.Size)
		mesh.Parent = customPart

		local offsetCFrame = CFrame.new(Vector3.new(
			(data.Position or Vector3.zero).X,
			(data.Position or Vector3.zero).Y,
			-(data.Position or Vector3.zero).Z
		)) * CFrame.Angles(
			math.rad((data.Rotation or Vector3.zero).X),
			math.rad((data.Rotation or Vector3.zero).Y),
			math.rad((data.Rotation or Vector3.zero).Z)
		)

		customPart.CFrame = targetPart.CFrame * offsetCFrame
		customPart.Parent = character

		local entry = {
			CustomPart = customPart,
			TargetPart = targetPart,
			Offset = offsetCFrame,
			RotationalDrag = data.RotationalDrag
		}

		if data.RotationalDrag then
			entry.CurrentAngleX = 0
			entry.AngularVelocity = 0
		end

		table.insert(trackedMeshes, entry)
	end
end

RunService.PostSimulation:Connect(function(dt)
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
			local root = data.TargetPart.Parent:FindFirstChild("HumanoidRootPart")
			local targetAngleX = 0
			
			if root then
				local localVel = data.TargetPart.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
				local dragForce = (localVel.Z * 2.5) + (localVel.Y * 1.5)
				
				-- Asymmetric Target Clamping based on movement direction
				if dragForce < 0 then
					targetAngleX = math.max(dragForce, -dragParams.MaxDownAngle)
				else
					targetAngleX = math.min(dragForce, dragParams.MaxUpAngle)
				end
			end

			local strength = (dragParams.Strength or 0.15) * 350
			local damp = math.clamp(dragParams.Damp or 0.8, 0, 1)

			data.AngularVelocity = (data.AngularVelocity * math.pow(damp, dt * 60)) + ((targetAngleX - data.CurrentAngleX) * strength * dt)
			data.CurrentAngleX = data.CurrentAngleX + (data.AngularVelocity * dt)
			
			-- Asymmetric Dynamic Angle Clamping
			if data.CurrentAngleX < 0 then
				data.CurrentAngleX = math.max(data.CurrentAngleX, -dragParams.MaxDownAngle)
			else
				data.CurrentAngleX = math.min(data.CurrentAngleX, dragParams.MaxUpAngle)
			end

			-- Pivot point transformations
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

applySkin(Players.LocalPlayer.Character)