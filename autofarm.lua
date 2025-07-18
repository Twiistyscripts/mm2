-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Local player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local COIN_NAME = "Coin_Server"
local COLLECTION_INTERVAL = 0.5
local TWEEN_DURATION = 0.3
local SAFE_SPACE_CFRAME = CFrame.new(0, -100, 0) -- Position in the void for reset

-- Create collection platform
local collectionPlatform = Instance.new("Part")
collectionPlatform.Name = "AutoCollectPlatform"
collectionPlatform.Anchored = true
collectionPlatform.CanCollide = true
collectionPlatform.Size = Vector3.new(4, 1, 4)
collectionPlatform.Transparency = 0.5
collectionPlatform.Color = Color3.fromRGB(0, 255, 0)
collectionPlatform.Parent = Workspace

-- Function to find all coins in the workspace
local function findCoins()
    local coins = {}
    
    local function searchDescendants(parent)
        for _, descendant in ipairs(parent:GetDescendants()) do
            if descendant.Name == COIN_NAME and descendant:IsA("BasePart") then
                table.insert(coins, descendant)
            end
        end
    end
    
    -- Search all top-level objects in workspace
    for _, item in ipairs(Workspace:GetChildren()) do
        searchDescendants(item)
    end
    
    return coins
end

-- Function to get the closest coin to a position
local function getClosestCoin(position, coins)
    local closestCoin = nil
    local closestDistance = math.huge
    
    for _, coin in ipairs(coins) do
        local distance = (position - coin.Position).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closestCoin = coin
        end
    end
    
    return closestCoin
end

-- Function to collect a coin
local function collectCoin(coin)
    -- Move platform under the coin
    local targetCFrame = CFrame.new(coin.Position) * CFrame.new(0, -5, 0)
    
    -- Create tween for smooth movement
    local tweenInfo = TweenInfo.new(
        TWEEN_DURATION,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(collectionPlatform, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    
    -- Wait for tween to complete
    tween.Completed:Wait()
    
    -- Small delay to ensure coin collection
    wait(0.1)
end

-- Function to reset position
local function resetPosition()
    collectionPlatform.CFrame = SAFE_SPACE_CFRAME
    humanoidRootPart.CFrame = SAFE_SPACE_CFRAME * CFrame.new(0, 5, 0)
end

-- Main collection loop
local function startCollection()
    while true do
        -- Find all coins
        local coins = findCoins()
        
        if #coins > 0 then
            -- Collect each coin in order of proximity
            while #coins > 0 do
                local currentPosition = collectionPlatform.Position
                local closestCoin = getClosestCoin(currentPosition, coins)
                
                if closestCoin then
                    collectCoin(closestCoin)
                    
                    -- Remove collected coin from list
                    for i, coin in ipairs(coins) do
                        if coin == closestCoin then
                            table.remove(coins, i)
                            break
                        end
                    end
                end
                
                wait(COLLECTION_INTERVAL)
            end
        end
        
        -- Reset position when no coins left
        resetPosition()
        
        -- Wait a bit before checking for coins again
        wait(2)
    end
end

-- Initialize
collectionPlatform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)

-- Start collection when character is ready
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    collectionPlatform.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
end)

-- Start the collection process
startCollection()
