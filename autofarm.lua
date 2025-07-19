local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Optimized settings
local checkInterval = 0.2  -- Faster checking
local tweenTime = 0.3      -- Faster movement
local safeVoidPos = Vector3.new(0, -500, 0)
local coinDropHeight = 1   -- Exactly 1 unit below coin

-- Create and configure anchor block
local anchorBlock = Instance.new("Part")
anchorBlock.Name = "PlayerAnchor"
anchorBlock.Anchored = true
anchorBlock.CanCollide = false
anchorBlock.Size = Vector3.new(5, 1, 5)
anchorBlock.Transparency = 1
anchorBlock.Parent = workspace

-- Initialize character
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Improved player anchoring
local function anchorPlayer()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = anchorBlock.CFrame + Vector3.new(0, 3, 0)
        -- Remove any existing velocity
        for _, v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyVelocity") then
                v:Destroy()
            end
        end
    end
end

-- Smooth movement with direct position setting
local function moveTo(pos)
    anchorBlock.CFrame = CFrame.new(pos)
    anchorPlayer()
    task.wait(tweenTime)
end

-- Optimized coin detection
local function getClosestCoin()
    local hrp = getHRP()
    if not hrp then return nil end
    
    local closest, dist = nil, math.huge
    for _, coin in ipairs(workspace:GetDescendants()) do
        if coin:IsA("BasePart") and coin.Name == "Coin_Server" then
            -- Skip collected coins
            local collected = coin:FindFirstChild("Collected")
            if collected and (collected.Value == true or collected.Value == "true") then
                continue
            end
            
            -- Skip transparent parts (threshold can be adjusted)
            if coin.Transparency >= 0.8 then
                continue
            end
            
            local d = (coin.Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                closest = coin
            end
        end
    end
    return closest
end

-- Initialize on character spawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hrp = char:WaitForChild("HumanoidRootPart")
    anchorBlock.CFrame = hrp.CFrame - Vector3.new(0, 3, 0)
    anchorPlayer()
end)

-- Main collection loop
task.spawn(function()
    while task.wait(checkInterval) do
        local hrp = getHRP()
        if not hrp then continue end
        
        local coin = getClosestCoin()
        if coin then
            -- Position exactly 1 unit below coin
            local targetPos = Vector3.new(
                coin.Position.X,
                coin.Position.Y - coinDropHeight,
                coin.Position.Z
            )
            moveTo(targetPos)
        else
            moveTo(safeVoidPos)
        end
    end
end)

-- Keep player anchored every frame
RunService.Heartbeat:Connect(anchorPlayer)
