local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local checkInterval = 0.5
local tweenTime = 0.5
local safeVoidPos = Vector3.new(0, -500, 0)
local coinDropOffset = 1 -- Lower than before (half head height + extra)

if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart
    end
    return nil
end

-- SAFE ANCHOR BLOCK (prevents falling)
local anchorBlock = Instance.new("Part")
anchorBlock.Name = "PlayerAnchor"
anchorBlock.Anchored = true
anchorBlock.CanCollide = false
anchorBlock.Size = Vector3.new(5, 1, 5)
anchorBlock.Transparency = 1
anchorBlock.Parent = workspace

-- Force player to stay on the anchor block
local function anchorPlayer()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = anchorBlock.CFrame + Vector3.new(0, 3, 0) -- Keeps player on top
    end
end

local function tweenMove(pos)
    local tween = TweenService:Create(anchorBlock, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
end

local function getClosestCoin()
    local hrp = getHRP()
    if not hrp then return nil end
    
    local closest, dist = nil, math.huge
    for _, coin in ipairs(workspace:GetDescendants()) do
        if coin.Name == "Coin_Server" and coin:IsA("BasePart") then
            local collected = coin:FindFirstChild("Collected")
            if collected and (collected.Value == true or collected.Value == "true") then
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

local function goToVoidSafe()
    tweenMove(safeVoidPos)
end

-- Update player position every frame
RunService.Heartbeat:Connect(function()
    anchorPlayer() -- Ensures player stays anchored
end)

-- Initialize anchor block on spawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hrp = char:WaitForChild("HumanoidRootPart")
    anchorBlock.CFrame = hrp.CFrame - Vector3.new(0, 3, 0) -- Sync position
end)

-- Main coin collection loop
task.spawn(function()
    while task.wait(checkInterval) do
        local hrp = getHRP()
        if not hrp then continue end

        local coin = getClosestCoin()
        if coin then
            -- Go VERY LOW below the coin (better collection)
            local target = Vector3.new(
                coin.Position.X,
                coin.Position.Y - coinDropOffset, -- Lower than before
                coin.Position.Z
            )
            tweenMove(target - Vector3.new(0, 3, 0)) -- Adjusts for HRP offset
        else
            goToVoidSafe() -- Safe waiting spot
        end
    end
end)
