local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local checkInterval = 0.5
local tweenTime = 0.5
local safeVoidPos = Vector3.new(0, -500, 0)
local coinCollectionOffset = 2 -- how far below the coin to position

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

local function hasFullMessage()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
            local txt = gui.Text:lower()
            if txt:find("full") then
                return true
            end
        end
    end
    return false
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

        -- Only check for full message when not moving to a coin
        local coin = getClosestCoin()
        if not coin and hasFullMessage() then
            local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
            if hum then 
                hum.Health = 0 
            end
            continue
        end

        if coin then
            -- Position player slightly below the coin
            local target = Vector3.new(
                coin.Position.X,
                coin.Position.Y - coinCollectionOffset,
                coin.Position.Z
            )
            tweenMove(target - Vector3.new(0, 3, 0)) -- Additional 3 unit offset for HRP
        else
            goToVoidSafe()
        end
    end
end)
