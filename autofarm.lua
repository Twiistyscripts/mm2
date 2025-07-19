local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Settings
local checkInterval = 0.5
local tweenTime = 0.5
local safeVoidPos = Vector3.new(0, -500, 0)

-- Wait for character
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart
    end
    return nil
end

-- Create movement block
local moveBlock = Instance.new("Part")
moveBlock.Anchored = true
moveBlock.CanCollide = false
moveBlock.Size = Vector3.new(5,1,5)
moveBlock.Transparency = 1
moveBlock.Parent = workspace

-- Smooth move
local function tweenMove(targetPos)
    local tween = TweenService:Create(moveBlock, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
end

-- Detect GUI with "full"
local function isFullGUIVisible()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local txt = gui.Text:lower()
            if txt:find("full") then
                return true
            end
        end
    end
    return false
end

-- Find closest valid coin
local function getClosestCoin()
    local closest, dist = nil, math.huge
    local hrp = getHRP()
    if not hrp then return nil end
    
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

-- Go to safe void platform
local function goToVoidSafe()
    tweenMove(safeVoidPos)
end

-- Track reset state so it only resets ONCE per “full”
local hasResetForFull = false

-- Respawn handler resets state
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    hasResetForFull = false
    moveBlock.CFrame = char:WaitForChild("HumanoidRootPart").CFrame - Vector3.new(0,3,0)
end)

-- Keep block under player
RunService.Heartbeat:Connect(function()
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = CFrame.new(moveBlock.Position + Vector3.new(0,3,0))
    end
end)

-- Main loop
task.spawn(function()
    while task.wait(checkInterval) do
        local hrp = getHRP()
        if not hrp then continue end

        -- If GUI says full and we haven't reset yet, do it ONCE
        if isFullGUIVisible() and not hasResetForFull then
            hasResetForFull = true
            hrp.Parent:FindFirstChildOfClass("Humanoid").Health = 0
            continue
        end
        
        local coin = getClosestCoin()
        if coin then
            local target = coin.Position + Vector3.new(0,3,0)
            tweenMove(target)
        else
            -- No coins, just wait safely in void
            goToVoidSafe()
        end
    end
end)
