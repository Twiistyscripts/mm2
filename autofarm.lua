local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Faster settings
local checkInterval = 0.2  -- Faster checking
local tweenTime = 0.3      -- Faster movement
local safeVoidPos = Vector3.new(0, -500, 0)
local coinDropHeight = 1   -- Exactly 1 unit below coin

-- Ensure anchor block exists and is properly placed
local anchorBlock = workspace:FindFirstChild("PlayerAnchor") or Instance.new("Part")
anchorBlock.Name = "PlayerAnchor"
anchorBlock.Anchored = true
anchorBlock.CanCollide = false
anchorBlock.Size = Vector3.new(5, 1, 5)
anchorBlock.Transparency = 1
anchorBlock.Parent = workspace

-- Initialize character tracking
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Stronger player anchoring
local function anchorPlayer()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = anchorBlock.CFrame + Vector3.new(0, 3, 0)
        -- Force velocity to zero to prevent falling
        if hrp:FindFirstChildOfClass("BodyVelocity") then
            hrp:FindFirstChildOfClass("BodyVelocity"):Destroy()
        end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = hrp
    end
end

-- Faster movement with improved pathing
local function tweenMove(pos)
    anchorBlock.CFrame = CFrame.new(pos)
    -- Immediate position update
    anchorPlayer()
end

-- Improved coin detection that ignores transparent parts
local function getClosestCoin()
    local hrp = getHRP()
    if not hrp then return nil end
    
    local closest, dist = nil, math.huge
    for _, coin in ipairs(workspace:GetDescendants()) do
        if coin:IsA("BasePart") and coin.Name == "Coin_Server" then
            -- Skip if collected or transparent
            local collected = coin:FindFirstChild("Collected")
            if collected and (collected.Value == true or collected.Value == "true") then
                continue
            end
            if coin.Transparency >= 0.5 then  -- Skip transparent parts
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

-- Main loop
RunService.Heartbeat:Connect(function()
    anchorPlayer()
    
    local hrp = getHRP()
    if not hrp then return end
    
    local coin = getClosestCoin()
    if coin then
        -- Position exactly 1 unit below coin
        local target = Vector3.new(
            coin.Position.X,
            coin.Position.Y - coinDropHeight,
            coin.Position.Z
        )
        tweenMove(target - Vector3.new(0, 3, 0))  -- Account for HRP offset
    else
        tweenMove(safeVoidPos)
    end
end)
