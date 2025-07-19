local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local checkInterval = 0.5
local tweenTime = 0.5
local safeVoidPos = Vector3.new(0, -500, 0)
local headHeightOffset = 1.5 -- Half of typical head height (3 units)

if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart
    end
    return nil
end

-- movement block
local moveBlock = Instance.new("Part")
moveBlock.Anchored = true
moveBlock.CanCollide = false
moveBlock.Size = Vector3.new(5,1,5)
moveBlock.Transparency = 1
moveBlock.Parent = workspace

local function tweenMove(pos)
    local tween = TweenService:Create(moveBlock, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
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

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    moveBlock.CFrame = char:WaitForChild("HumanoidRootPart").CFrame - Vector3.new(0,3,0)
end)

RunService.Heartbeat:Connect(function()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = moveBlock.CFrame + Vector3.new(0,3,0)
    end
end)

task.spawn(function()
    while task.wait(checkInterval) do
        local hrp = getHRP()
        if not hrp then continue end

        local coin = getClosestCoin()
        if coin then
            -- Position player lower (half head height below coin)
            local target = Vector3.new(
                coin.Position.X,
                coin.Position.Y - headHeightOffset,
                coin.Position.Z
            )
            tweenMove(target - Vector3.new(0, 3, 0)) -- Additional 3 unit offset for HRP
        else
            goToVoidSafe()
        end
    end
end)
