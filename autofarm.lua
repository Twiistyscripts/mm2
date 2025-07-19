local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local checkInterval = 0.5
local tweenTime = 0.5
local safeVoidPos = Vector3.new(0, -500, 0)

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

local hasResetForFull = false

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    hasResetForFull = false
    moveBlock.CFrame = char:WaitForChild("HumanoidRootPart").CFrame - Vector3.new(0,3,0)
end)

RunService.Heartbeat:Connect(function()
    local hrp = getHRP()
    if hrp then
        -- keep player exactly on top of moveBlock
        hrp.CFrame = moveBlock.CFrame + Vector3.new(0,3,0)
    end
end)

task.spawn(function()
    while task.wait(checkInterval) do
        local hrp = getHRP()
        if not hrp then continue end

        -- Reset ONCE if GUI shows full
        if isFullGUIVisible() and not hasResetForFull then
            hasResetForFull = true
            local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
            continue
        end

        local coin = getClosestCoin()
        if coin then
            -- go directly UNDER coin so player's head touches it
            local target = coin.Position - Vector3.new(0, 2.5, 0) 
            tweenMove(target)
        else
            -- No coins, go to void and wait
            goToVoidSafe()
        end
    end
end)
