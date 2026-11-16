-- Загрузка библиотеки WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Основная палитра цветов для Visuals
local ColorMap = {
    ["Green"] = Color3.fromRGB(0, 255, 100),
    ["Blue"]  = Color3.fromRGB(0, 140, 255),
    ["Red"]   = Color3.fromRGB(255, 45, 45)
}

-- Палитра цветов для Net Trails (трейлы на сетке)
local NetTrailColorMap = {
    ["White"]  = Color3.fromRGB(255, 255, 255),
    ["Black"]  = Color3.fromRGB(0, 0, 0),
    ["Red"]    = Color3.fromRGB(255, 45, 45),
    ["Blue"]   = Color3.fromRGB(0, 140, 255),
    ["Green"]  = Color3.fromRGB(0, 255, 100),
    ["Orange"] = Color3.fromRGB(255, 140, 0)
}

-- Кастомные темы (Black — черно-прозрачная по умолчанию, Red, Purple)
WindUI:AddTheme({
    Name = "Black",
    Accent = "#18181b",
    Outline = "#27272a",
    Text = "#ffffff",
    Placeholder = "#71717a",
    Background = "#09090b",
    Button = "#18181b",
    Icon = "#a1a1aa"
})

WindUI:AddTheme({
    Name = "Red",
    Accent = "#dc2626",
    Outline = "#7f1d1d",
    Text = "#ffffff",
    Placeholder = "#fca5a5",
    Background = "#1a0505",
    Button = "#991b1b",
    Icon = "#f87171"
})

WindUI:AddTheme({
    Name = "Purple",
    Accent = "#9333ea",
    Outline = "#581c87",
    Text = "#ffffff",
    Placeholder = "#d8b4fe",
    Background = "#11051c",
    Button = "#6b21a8",
    Icon = "#c084fc"
})

-- Создание окна ProHub
local Window = WindUI:CreateWindow({
    Title = "ProHub",
    Icon = "zap",
    Author = "Cath An Egg",
    Folder = "ProHub_CathAnEgg",
    Size = UDim2.fromOffset(580, 440),
    Transparent = true,
    Theme = "Black",
    SideBarWidth = 175,
    User = {
        Enabled = true,
        Anonymous = false
    }
})

-- Закругленная черная плашка открытия с иконкой молнии
Window:EditOpenButton({
    Title = "ProHub",
    Icon = "zap",
    CornerRadius = UDim.new(1, 0),
    StrokeThickness = 1.5,
    Color = ColorSequence.new(
        Color3.fromRGB(8, 8, 10),
        Color3.fromRGB(22, 22, 26)
    ),
    Draggable = true
})

--------------------------------------------------------------------
-- ОКНО ПРОФИЛЯ (ВСЕГДА В ПОЗИЦИИ КАК НА СКРИНШОТЕ + ИКОНКА СКИНА)
--------------------------------------------------------------------
local ProfileGui = nil
local ProfileNameLabel = nil
local ProfileSubLabel = nil
local ProfileAvatarImage = nil
local ProfileStroke = nil

-- Ссылки на нижний виджет профиля внутри самого меню WindUI
local SidebarNameLabel = nil
local SidebarSubLabel = nil
local SidebarAvatarImage = nil

-- ID скинов для Skinchanger и иконок: "2" = Roblox (1), "3" = Jandel (26108573)
local SkinUserIds = {
    ["2"] = 1,
    ["3"] = 26108573
}

local AvatarThumbCache = {}

local function GetHeadShotUrl(userId)
    if AvatarThumbCache[userId] then
        return AvatarThumbCache[userId]
    end
    local fallback = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
    AvatarThumbCache[userId] = fallback
    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and content and content ~= "" then
            AvatarThumbCache[userId] = content
        end
    end)
    return fallback
end

GetHeadShotUrl(LocalPlayer.UserId)
GetHeadShotUrl(SkinUserIds["2"])
GetHeadShotUrl(SkinUserIds["3"])

-- Находит виджет игрока в левом нижнем углу меню WindUI (не затрагивая Dropdown списки)
local function BindWindUISidebarUserWidget()
    task.spawn(function()
        task.wait(0.4)
        local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:FindFirstChild("PlayerGui")
        if not parentGui then return end

        local myName = LocalPlayer.Name
        local myDisplay = LocalPlayer.DisplayName

        for _, img in ipairs(parentGui:GetDescendants()) do
            if img:IsA("ImageLabel") and img ~= ProfileAvatarImage then
                local imageStr = tostring(img.Image or "")
                if string.find(imageStr, tostring(LocalPlayer.UserId), 1, true)
                    or string.find(imageStr, "AvatarHeadShot", 1, true)
                    or string.find(imageStr, "headshot", 1, true) then

                    local container = img.Parent
                    if container and container.Parent then
                        local labels = {}
                        for _, obj in ipairs(container.Parent:GetDescendants()) do
                            if obj:IsA("TextLabel") and (obj.Text == myName or obj.Text == myDisplay or obj.Text == "@" .. myName) then
                                table.insert(labels, obj)
                            end
                        end

                        if #labels >= 2 then
                            table.sort(labels, function(a, b)
                                return a.AbsolutePosition.Y < b.AbsolutePosition.Y
                            end)
                            SidebarAvatarImage = img
                            SidebarNameLabel = labels[1]
                            SidebarSubLabel = labels[2]
                            SidebarSubLabel.Text = "ProHubUser"
                            break
                        elseif #labels == 1 then
                            SidebarAvatarImage = img
                            SidebarNameLabel = labels[1]
                            break
                        end
                    end
                end
            end
        end
    end)
end

local function CreateFixedProfileWindow()
    local parentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    local old = parentGui:FindFirstChild("ProHub_ShitaroProfile")
    if old then old:Destroy() end

    ProfileGui = Instance.new("ScreenGui")
    ProfileGui.Name = "ProHub_ShitaroProfile"
    ProfileGui.ResetOnSpawn = false
    ProfileGui.IgnoreGuiInset = true
    ProfileGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ProfileGui.Parent = parentGui

    -- Фиксированная позиция слева сверху под кнопками топбара Roblox (как на скриншоте)
    local card = Instance.new("Frame")
    card.Name = "ProfileCard"
    card.Size = UDim2.fromOffset(215, 58)
    card.Position = UDim2.fromOffset(18, 56)
    card.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.Active = false
    card.Parent = ProfileGui

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent = card

    ProfileStroke = Instance.new("UIStroke")
    ProfileStroke.Color = Color3.fromRGB(45, 45, 52)
    ProfileStroke.Thickness = 1.5
    ProfileStroke.Transparency = 0.2
    ProfileStroke.Parent = card

    local avatarHolder = Instance.new("Frame")
    avatarHolder.Name = "AvatarHolder"
    avatarHolder.Size = UDim2.fromOffset(42, 42)
    avatarHolder.Position = UDim2.fromOffset(8, 8)
    avatarHolder.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    avatarHolder.BorderSizePixel = 0
    avatarHolder.Parent = card

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = avatarHolder

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Color3.fromRGB(70, 70, 80)
    avatarStroke.Thickness = 1.2
    avatarStroke.Parent = avatarHolder

    ProfileAvatarImage = Instance.new("ImageLabel")
    ProfileAvatarImage.Name = "Avatar"
    ProfileAvatarImage.Size = UDim2.fromScale(1, 1)
    ProfileAvatarImage.BackgroundTransparency = 1
    ProfileAvatarImage.Image = GetHeadShotUrl(LocalPlayer.UserId)
    ProfileAvatarImage.Parent = avatarHolder

    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(1, 0)
    imgCorner.Parent = ProfileAvatarImage

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusDot"
    statusDot.Size = UDim2.fromOffset(11, 11)
    statusDot.Position = UDim2.new(1, -11, 1, -11)
    statusDot.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
    statusDot.BorderSizePixel = 0
    statusDot.Parent = avatarHolder

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.fromRGB(10, 10, 14)
    dotStroke.Thickness = 2
    dotStroke.Parent = statusDot

    ProfileNameLabel = Instance.new("TextLabel")
    ProfileNameLabel.Name = "Nickname"
    ProfileNameLabel.Size = UDim2.new(1, -66, 0, 22)
    ProfileNameLabel.Position = UDim2.fromOffset(58, 9)
    ProfileNameLabel.BackgroundTransparency = 1
    ProfileNameLabel.Font = Enum.Font.GothamBold
    ProfileNameLabel.TextSize = 15
    ProfileNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ProfileNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    ProfileNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    ProfileNameLabel.Text = LocalPlayer.DisplayName
    ProfileNameLabel.Parent = card

    ProfileSubLabel = Instance.new("TextLabel")
    ProfileSubLabel.Name = "SubTitle"
    ProfileSubLabel.Size = UDim2.new(1, -66, 0, 16)
    ProfileSubLabel.Position = UDim2.fromOffset(58, 30)
    ProfileSubLabel.BackgroundTransparency = 1
    ProfileSubLabel.Font = Enum.Font.GothamMedium
    ProfileSubLabel.TextSize = 12
    ProfileSubLabel.TextColor3 = Color3.fromRGB(160, 160, 175)
    ProfileSubLabel.TextXAlignment = Enum.TextXAlignment.Left
    ProfileSubLabel.TextTruncate = Enum.TextTruncate.AtEnd
    ProfileSubLabel.Text = "ProHubUser"
    ProfileSubLabel.Parent = card
end

-- Меняет ТОЛЬКО ник в окне профиля и в нижнем углу меню (не трогая выпадающий список)
local function SetWindowNicknameMode(mode)
    local displayNick = LocalPlayer.DisplayName
    if mode == "ProUser" then
        displayNick = "ProUser"
    elseif mode == "Lipton" then
        displayNick = "Lipton"
    elseif mode == "Anonym" then
        displayNick = "Anonym"
    end

    if ProfileNameLabel then
        ProfileNameLabel.Text = displayNick
    end
    if ProfileSubLabel then
        ProfileSubLabel.Text = "ProHubUser"
    end
    if SidebarNameLabel and SidebarNameLabel.Parent then
        SidebarNameLabel.Text = displayNick
    end
    if SidebarSubLabel and SidebarSubLabel.Parent then
        SidebarSubLabel.Text = "ProHubUser"
    end
end

-- Меняет ТОЛЬКО аватарку в окне профиля в зависимости от выбранного скина в Skinchanger
local function UpdateProfileAvatarBySkin(skinOption, isSkinchangerActive)
    local targetUserId = LocalPlayer.UserId
    if skinOption ~= "You" and SkinUserIds[skinOption] and isSkinchangerActive then
        targetUserId = SkinUserIds[skinOption]
    end

    local url = GetHeadShotUrl(targetUserId)
    if ProfileAvatarImage then
        ProfileAvatarImage.Image = url
    end
    if SidebarAvatarImage and SidebarAvatarImage.Parent then
        SidebarAvatarImage.Image = url
    end
end

CreateFixedProfileWindow()
BindWindUISidebarUserWidget()

-- Вкладки
local Tabs = {
    Misc      = Window:Tab({ Title = "Misc", Icon = "layers" }),
    Teleports = Window:Tab({ Title = "Teleports", Icon = "map-pin" }),
    Visuals   = Window:Tab({ Title = "Visuals", Icon = "eye" }),
    Player    = Window:Tab({ Title = "Player", Icon = "user" }),
    Settings  = Window:Tab({ Title = "Settings", Icon = "settings" })
}

--------------------------------------------------------------------
-- ТОЧНЫЙ ПОИСК ОБЪЕКТОВ И БЕЗОПАСНЫЕ ТЕЛЕПОРТЫ
--------------------------------------------------------------------
local SavedStrongPart = nil
local CachedLobbyFloorY = nil

local function IsInsideAnyPlayerCharacter(obj)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then
            return true
        end
    end
    return false
end

local function GetObjectWorldPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true) end

    local surfGui = obj:FindFirstAncestorOfClass("SurfaceGui")
    if surfGui and surfGui.Adornee and surfGui.Adornee:IsA("BasePart") then
        return surfGui.Adornee
    end

    local billGui = obj:FindFirstAncestorOfClass("BillboardGui")
    if billGui and billGui.Adornee then
        if billGui.Adornee:IsA("BasePart") then return billGui.Adornee end
        if billGui.Adornee:IsA("Model") then
            return billGui.Adornee.PrimaryPart or billGui.Adornee:FindFirstChildWhichIsA("BasePart", true)
        end
    end

    local part = obj:FindFirstAncestorWhichIsA("BasePart")
    if part then return part end

    local mdl = obj:FindFirstAncestorOfClass("Model")
    if mdl and mdl ~= workspace then
        return mdl.PrimaryPart or mdl:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function GetCombinedGuiText(lbl)
    local raw = string.lower(lbl.Text or "")
    local content = ""
    pcall(function() content = string.lower(lbl.ContentText or "") end)
    local loc = ""
    pcall(function() loc = string.lower(lbl.LocalizedText or "") end)
    return raw .. " " .. content .. " " .. loc
end

local function FindStationPart(keywords, rejectKeywords, checkPrompts)
    local bestPart = nil
    local bestScore = -math.huge

    if checkPrompts then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and not IsInsideAnyPlayerCharacter(obj) then
                local pText = string.lower((obj.ObjectText or "") .. " " .. (obj.ActionText or "") .. " " .. obj.Name)
                local rejected = false
                if rejectKeywords then
                    for _, rk in ipairs(rejectKeywords) do
                        if string.find(pText, rk, 1, true) then rejected = true break end
                    end
                end
                if not rejected then
                    for _, kw in ipairs(keywords) do
                        if string.find(pText, kw, 1, true) then
                            local part = GetObjectWorldPart(obj)
                            if part then return part end
                        end
                    end
                end
            end
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not IsInsideAnyPlayerCharacter(obj) then
            local fullTxt = GetCombinedGuiText(obj)
            if #fullTxt > 0 then
                local rejected = false
                if rejectKeywords then
                    for _, rk in ipairs(rejectKeywords) do
                        if string.find(fullTxt, rk, 1, true) then
                            rejected = true
                            break
                        end
                    end
                end

                if not rejected then
                    for idx, kw in ipairs(keywords) do
                        if string.find(fullTxt, kw, 1, true) then
                            local part = GetObjectWorldPart(obj)
                            if part then
                                local score = (#keywords - idx) * 15
                                if score > bestScore then
                                    bestScore = score
                                    bestPart = part
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    if bestPart then return bestPart end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("Model")) and obj ~= workspace and not IsInsideAnyPlayerCharacter(obj) then
            local combined = string.lower(obj.Name .. " " .. (obj.Parent and obj.Parent.Name or ""))
            local rejected = false
            if rejectKeywords then
                for _, rk in ipairs(rejectKeywords) do
                    if string.find(combined, rk, 1, true) then
                        rejected = true
                        break
                    end
                end
            end

            if not rejected then
                for idx, kw in ipairs(keywords) do
                    if string.find(combined, kw, 1, true) then
                        local part = GetObjectWorldPart(obj)
                        if part then
                            local score = (#keywords - idx) * 10
                            if score > bestScore then
                                bestScore = score
                                bestPart = part
                            end
                        end
                        break
                    end
                end
            end
        end
    end

    return bestPart
end

local function GetMainArenaFloor(refPos)
    if CachedLobbyFloorY then
        return CachedLobbyFloorY, refPos or Vector3.new(0, CachedLobbyFloorY, 0), nil
    end

    local ignoreList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then table.insert(ignoreList, plr.Character) end
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation", true)
    if spawnLoc then
        local hit = workspace:Raycast(spawnLoc.Position + Vector3.new(0, 8, 0), Vector3.new(0, -25, 0), rayParams)
        if hit and hit.Instance then
            CachedLobbyFloorY = hit.Position.Y
            return CachedLobbyFloorY, spawnLoc.Position, hit.Instance
        end
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local hit = workspace:Raycast(hrp.Position + Vector3.new(0, 5, 0), Vector3.new(0, -35, 0), rayParams)
        if hit and hit.Instance then
            CachedLobbyFloorY = hit.Position.Y
            return CachedLobbyFloorY, hrp.Position, hit.Instance
        end
    end

    local fallbackY = hrp and (hrp.Position.Y - 3) or 0
    return fallbackY, Vector3.new(0, fallbackY, 0), nil
end

local function GetOutwardWallDirection(anchorPos, floorY, mapCenter, toRingVec)
    local cardinalDirs = {
        Vector3.new(1, 0, 0),
        Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(0, 0, -1)
    }

    local rayParams = RaycastParams.new()
    local ignoreChars = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then table.insert(ignoreChars, plr.Character) end
    end
    rayParams.FilterDescendantsInstances = ignoreChars
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local bestFrontDir = cardinalDirs[1]
    local bestDirScore = -math.huge
    local toMapCenter = Vector3.new(mapCenter.X - anchorPos.X, 0, mapCenter.Z - anchorPos.Z)
    if toMapCenter.Magnitude > 0.1 then
        toMapCenter = toMapCenter.Unit
    end

    local wallCheckOrigin = Vector3.new(anchorPos.X, floorY + 14, anchorPos.Z)
    for _, dir in ipairs(cardinalDirs) do
        local score = 0
        local hitForward = workspace:Raycast(wallCheckOrigin, dir * 45, rayParams)
        local hitBackward = workspace:Raycast(wallCheckOrigin, (-dir) * 25, rayParams)

        local forwardClearDist = hitForward and hitForward.Distance or 45
        local backwardWallDist = hitBackward and hitBackward.Distance or 25

        score = score + (forwardClearDist * 1.5) - (backwardWallDist * 2.0)
        score = score + (dir:Dot(toMapCenter) * 25)

        if toRingVec then
            score = score + (dir:Dot(toRingVec) * 40)
        end

        if score > bestDirScore then
            bestDirScore = score
            bestFrontDir = dir
        end
    end

    return bestFrontDir, ignoreChars
end

local function BuildStationTeleportCFrame(stationPart, ringColorType, customDistance)
    if not stationPart then return nil end

    local anchorPos = stationPart.Position
    local floorY, mapCenter, floorPart = GetMainArenaFloor(anchorPos)

    local ringParts = {}
    if ringColorType then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj ~= floorPart and not IsInsideAnyPlayerCharacter(obj) then
                local dy = math.abs(obj.Position.Y - floorY)
                local dist2D = (Vector2.new(obj.Position.X, obj.Position.Z) - Vector2.new(anchorPos.X, anchorPos.Z)).Magnitude

                if dy <= 2.6 and dist2D <= 15 and obj.Size.Y <= 3 and obj.Size.X <= 12 and obj.Size.Z <= 12 then
                    local c = obj.Color
                    if ringColorType == "Red" then
                        if c.R > 0.65 and c.G < 0.35 and c.B < 0.35 then
                            table.insert(ringParts, obj)
                        end
                    elseif ringColorType == "Blue" then
                        if c.B > 0.6 and c.G > 0.35 and c.R < 0.45 then
                            table.insert(ringParts, obj)
                        end
                    end
                end
            end
        end
    end

    local ringCenter2D = nil
    if #ringParts > 0 then
        local minX, maxX = math.huge, -math.huge
        local minZ, maxZ = math.huge, -math.huge
        for _, rp in ipairs(ringParts) do
            if rp.Position.X < minX then minX = rp.Position.X end
            if rp.Position.X > maxX then maxX = rp.Position.X end
            if rp.Position.Z < minZ then minZ = rp.Position.Z end
            if rp.Position.Z > maxZ then maxZ = rp.Position.Z end
        end
        ringCenter2D = Vector2.new((minX + maxX) * 0.5, (minZ + maxZ) * 0.5)
    end

    local toRingVec = nil
    if ringCenter2D then
        local v = Vector3.new(ringCenter2D.X - anchorPos.X, 0, ringCenter2D.Y - anchorPos.Z)
        if v.Magnitude > 0.5 then
            toRingVec = v.Unit
        end
    end

    local bestFrontDir, ignoreChars = GetOutwardWallDirection(anchorPos, floorY, mapCenter, toRingVec)

    local standX, standZ
    if ringCenter2D then
        standX = ringCenter2D.X
        standZ = ringCenter2D.Y
    else
        local dist = customDistance or 5.5
        standX = anchorPos.X + (bestFrontDir.X * dist)
        standZ = anchorPos.Z + (bestFrontDir.Z * dist)
    end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = ignoreChars
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude

    for _ = 1, 5 do
        local checkCF = CFrame.new(standX, floorY + 3.2, standZ)
        local partsInBox = workspace:GetPartBoundsInBox(checkCF, Vector3.new(2.2, 3.5, 2.2), overlapParams)
        local blocked = false
        for _, p in ipairs(partsInBox) do
            if p ~= floorPart and p.CanCollide and p.Transparency < 0.95 and (p.Position.Y + p.Size.Y * 0.5) > (floorY + 0.8) then
                blocked = true
                break
            end
        end
        if not blocked then break end
        standX = standX + (bestFrontDir.X * 0.8)
        standZ = standZ + (bestFrontDir.Z * 0.8)
    end

    local standPos = Vector3.new(standX, floorY + 3.1, standZ)
    local lookAtPos = standPos - (bestFrontDir * 10)

    return CFrame.lookAt(standPos, lookAtPos)
end

local function TeleportPlayerFacing(targetCF)
    if not targetCF then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end

    hrp.Velocity = Vector3.zero
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    if hum and hum.SeatPart then
        hum.Sit = false
    end

    hrp.CFrame = targetCF

    if Camera then
        local lookDir = targetCF.LookVector
        local camPos = targetCF.Position - (lookDir * 8.5) + Vector3.new(0, 3.2, 0)
        local camLook = targetCF.Position + (lookDir * 8) + Vector3.new(0, 1.2, 0)
        Camera.CFrame = CFrame.lookAt(camPos, camLook)
    end
end

-- 1. ТОЧНЫЙ ПОИСК ОТЖИМАЛКИ
local function GetMyStrongZoneCenterCFrame()
    local floorY = GetMainArenaFloor()

    if SavedStrongPart and SavedStrongPart.Parent and math.abs(SavedStrongPart.Position.Y - floorY) <= 10 then
        return CFrame.new(SavedStrongPart.Position.X, floorY + 3.1, SavedStrongPart.Position.Z)
    end

    local myName = string.lower(LocalPlayer.Name)
    local myDisplay = string.lower(LocalPlayer.DisplayName)

    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not IsInsideAnyPlayerCharacter(obj) then
            local txt = GetCombinedGuiText(obj)
            if (string.find(txt, myName, 1, true) or string.find(txt, myDisplay, 1, true))
                and not string.find(txt, "top", 1, true)
                and not string.find(txt, "strongest", 1, true)
                and not string.find(txt, "richest", 1, true) then

                local baseModel = obj:FindFirstAncestorOfClass("Model")
                if baseModel and baseModel ~= workspace then
                    for _, sub in ipairs(baseModel:GetDescendants()) do
                        if sub:IsA("ProximityPrompt") then
                            local pPart = GetObjectWorldPart(sub)
                            if pPart and math.abs(pPart.Position.Y - floorY) <= 9 then
                                SavedStrongPart = pPart
                                return CFrame.new(pPart.Position.X, floorY + 3.1, pPart.Position.Z)
                            end
                        elseif (sub:IsA("TextLabel") or sub:IsA("TextButton")) then
                            local sTxt = GetCombinedGuiText(sub)
                            if string.find(sTxt, "отжим", 1, true) or string.find(sTxt, "push", 1, true) then
                                local pPart = GetObjectWorldPart(sub)
                                if pPart and math.abs(pPart.Position.Y - floorY) <= 9 then
                                    SavedStrongPart = pPart
                                    return CFrame.new(pPart.Position.X, floorY + 3.1, pPart.Position.Z)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local bestMat = nil
    local bestDist = math.huge
    local refPos = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position) or Vector3.zero

    for _, obj in ipairs(workspace:GetDescendants()) do
        if not IsInsideAnyPlayerCharacter(obj) then
            local isMatch = false
            if obj:IsA("ProximityPrompt") then
                local pTxt = string.lower((obj.ObjectText or "") .. " " .. (obj.ActionText or "") .. " " .. obj.Name)
                if string.find(pTxt, "отжим", 1, true) or string.find(pTxt, "push", 1, true) or string.find(pTxt, "train", 1, true) or string.find(pTxt, "workout", 1, true) then
                    isMatch = true
                end
            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local lTxt = GetCombinedGuiText(obj)
                if (string.find(lTxt, "отжимания", 1, true) or string.find(lTxt, "pushup", 1, true) or string.find(lTxt, "push-up", 1, true))
                    and not string.find(lTxt, "top power", 1, true)
                    and not string.find(lTxt, "strongest", 1, true)
                    and not string.find(lTxt, "top money", 1, true) then
                    isMatch = true
                end
            end

            if isMatch then
                local part = GetObjectWorldPart(obj)
                if part and math.abs(part.Position.Y - floorY) <= 9 then
                    local d = (part.Position - refPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestMat = part
                    end
                end
            end
        end
    end

    if bestMat then
        SavedStrongPart = bestMat
        return CFrame.new(bestMat.Position.X, floorY + 3.1, bestMat.Position.Z)
    end

    return nil
end

-- 2. ПРОДАТЬ
local function GetSellerPart()
    return FindStationPart(
        { "продать", "sell", "seller", "продажа", "скупщик" },
        { "магазин", "shop", "free gift", "free!", "подарок", "отжимания", "индекс", "питомцы", "top money", "top power" },
        false
    )
end

local function GetSellerCFrame()
    return BuildStationTeleportCFrame(GetSellerPart(), "Red")
end

-- 3. МАГАЗИН
local function GetShopPart()
    return FindStationPart(
        { "магазин", "shop", "gun shop", "net shop", "store" },
        { "продать", "sell", "free gift", "free!", "подарок", "отжимания", "индекс", "питомцы", "свободная база", "top money", "top power" },
        false
    )
end

local function GetShopCFrame()
    return BuildStationTeleportCFrame(GetShopPart(), "Blue")
end

-- 4. ПОДАРОК
local function GetGiftPart()
    return FindStationPart(
        { "free gift", "free!", "cash + 2x luck", "подарок", "gift" },
        { "продать", "sell", "магазин", "shop", "отжимания", "индекс", "питомцы", "top money", "top power" },
        true
    )
end

local function GetGiftCFrame()
    return BuildStationTeleportCFrame(GetGiftPart(), "Blue")
end

-- 5. ТАБЛИЦА ЛИДЕРОВ
local function GetLeaderboardCFrame()
    local topMoneyPart = FindStationPart(
        { "top money", "richest players", "топ денег" },
        { "продать", "магазин", "free gift", "live spawns", "wanted egg" },
        false
    )
    local topPowerPart = FindStationPart(
        { "top power", "strongest players", "топ силы" },
        { "продать", "магазин", "free gift", "live spawns", "wanted egg", "отжимания" },
        false
    )

    local refPart = topMoneyPart or topPowerPart
    if not refPart then return nil end

    local centerPos = refPart.Position
    if topMoneyPart and topPowerPart then
        centerPos = (topMoneyPart.Position + topPowerPart.Position) * 0.5
    end

    local floorY, mapCenter = GetMainArenaFloor(centerPos)
    local frontDir = GetOutwardWallDirection(centerPos, floorY, mapCenter, nil)

    local standPos = Vector3.new(
        centerPos.X + (frontDir.X * 7.5),
        floorY + 3.1,
        centerPos.Z + (frontDir.Z * 7.5)
    )
    local lookAtPos = standPos - (frontDir * 10)
    return CFrame.lookAt(standPos, lookAtPos)
end

-- 6. ТАБЛО LIVE SPAWNS
local function GetLiveSpawnsCFrame()
    local livePart = FindStationPart(
        { "live spawns", "wanted egg", "nobody caught", "other server" },
        { "продать", "sell", "free gift", "top money", "top power", "strongest players", "richest players" },
        false
    )
    if not livePart then return nil end

    local centerPos = livePart.Position
    local floorY, mapCenter = GetMainArenaFloor(centerPos)
    local frontDir = GetOutwardWallDirection(centerPos, floorY, mapCenter, nil)

    local standPos = Vector3.new(
        centerPos.X + (frontDir.X * 8.5),
        floorY + 3.1,
        centerPos.Z + (frontDir.Z * 8.5)
    )
    local lookAtPos = standPos - (frontDir * 10)
    return CFrame.lookAt(standPos, lookAtPos)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer then
        local pName = string.lower(prompt.Name .. " " .. prompt.ActionText .. " " .. (prompt.ObjectText or "") .. " " .. (prompt.Parent and prompt.Parent.Name or ""))
        local part = GetObjectWorldPart(prompt)
        if string.find(pName, "push") or string.find(pName, "train") or string.find(pName, "workout") or string.find(pName, "отжим") then
            if part then SavedStrongPart = part end
        end
    end
end)

--------------------------------------------------------------------
-- ВКЛАДКА: MISC (Auto Best Cath, Anti Afk, Infinite Yeld)
--------------------------------------------------------------------
local autoBestCatchEnabled = false
local antiAfkEnabled = false
local lastBestCatchClick = 0
local hookedGuiLabels = {}

local function IsGuiReallyVisible(guiObj)
    if not (guiObj and guiObj:IsA("GuiObject") and guiObj.Visible) then return false end
    local fullName = guiObj:GetFullName()
    if string.find(fullName, "WindUI", 1, true) or string.find(fullName, "ProHub", 1, true) then
        return false
    end
    local curr = guiObj.Parent
    while curr do
        if curr:IsA("GuiObject") and not curr.Visible then
            return false
        elseif curr:IsA("ScreenGui") then
            return curr.Enabled
        elseif curr:IsA("BillboardGui") or curr:IsA("SurfaceGui") then
            return false
        end
        curr = curr.Parent
    end
    return true
end

local function FireScreenTap()
    if (tick() - lastBestCatchClick) < 0.35 then return end
    lastBestCatchClick = tick()

    local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
    local clickX = vp.X * 0.5
    local clickY = vp.Y * 0.35

    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
        end)

        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(clickX, clickY))
        end)
    end)
end

local function CheckIfLabelIsPlus19(lbl)
    if not autoBestCatchEnabled then return end
    if not IsGuiReallyVisible(lbl) then return end
    local cleanText = string.gsub(lbl.Text or "", "%s+", "")
    if cleanText == "+19" then
        FireScreenTap()
    end
end

local function HookGuiLabel(obj)
    if hookedGuiLabels[obj] then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        hookedGuiLabels[obj] = true
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            if autoBestCatchEnabled then CheckIfLabelIsPlus19(obj) end
        end)
        obj:GetPropertyChangedSignal("Visible"):Connect(function()
            if obj.Visible and autoBestCatchEnabled then
                CheckIfLabelIsPlus19(obj)
            end
        end)
    end
end

task.spawn(function()
    local pGui = LocalPlayer:WaitForChild("PlayerGui", 10)
    if pGui then
        for _, obj in ipairs(pGui:GetDescendants()) do
            HookGuiLabel(obj)
        end
        pGui.DescendantAdded:Connect(HookGuiLabel)
    end
end)

-- 1. Auto Best Cath
Tabs.Misc:Toggle({
    Title = "Auto Best Cath",
    Desc = "Автоматически нажимает на экран, как только полоска шкалы на +19",
    Default = false,
    Callback = function(state)
        autoBestCatchEnabled = state
    end
})

-- 2. Anti Afk
Tabs.Misc:Toggle({
    Title = "Anti Afk",
    Default = false,
    Callback = function(state)
        antiAfkEnabled = state
        if state then
            for _, conn in pairs(getconnections and getconnections(LocalPlayer.Idled) or {}) do
                conn:Disable()
            end
        end
        task.spawn(function()
            while antiAfkEnabled do
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
                task.wait(30)
            end
        end)
    end
})

LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

-- 3. Infinite Yeld
Tabs.Misc:Button({
    Title = "Infinite Yeld",
    Desc = "Запуск по клику",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

--------------------------------------------------------------------
-- ВКЛАДКА: TELEPORTS
--------------------------------------------------------------------
Tabs.Teleports:Button({
    Title = "Teleport To Strong Zone",
    Desc = "Телепорт к вашей отжималке",
    Callback = function()
        local targetCF = GetMyStrongZoneCenterCFrame()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and targetCF then
            hrp.Velocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = targetCF
        end
    end
})

Tabs.Teleports:Button({
    Title = "Teleport To Shop",
    Desc = "В голубой круг прямо лицом к Магазину",
    Callback = function()
        TeleportPlayerFacing(GetShopCFrame())
    end
})

Tabs.Teleports:Button({
    Title = "Teleport To Seller",
    Desc = "В красный круг прямо лицом к Продаже",
    Callback = function()
        TeleportPlayerFacing(GetSellerCFrame())
    end
})

Tabs.Teleports:Button({
    Title = "Teleport To Gift",
    Desc = "В голубой круг прямо лицом к Подарку (Free Gift)",
    Callback = function()
        TeleportPlayerFacing(GetGiftCFrame())
    end
})

Tabs.Teleports:Button({
    Title = "Teleport To Leaderboard",
    Desc = "Прямо лицом к таблицам лидеров (TOP MONEY / TOP POWER)",
    Callback = function()
        TeleportPlayerFacing(GetLeaderboardCFrame())
    end
})

Tabs.Teleports:Button({
    Title = "Teleport To Live Spawns",
    Desc = "Прямо лицом к табло спавна яиц (LIVE SPAWNS)",
    Callback = function()
        TeleportPlayerFacing(GetLiveSpawnsCFrame())
    end
})

--------------------------------------------------------------------
-- ВКЛАДКА: VISUALS (Мгновенный Xray без зависаний, Skinchanger, ESP)
--------------------------------------------------------------------
local rainbowVisualsEnabled = false
local currentRainbowColor = Color3.fromRGB(255, 0, 0)

local espEnabled = false
local espColor = ColorMap["Green"]

-- Состояния и кэш для мгновенного Xray (0 лагов)
local xrayBasesEnabled = false
local xrayZonesEnabled = false
local xrayDealersEnabled = false
local XRAY_ALPHA = 0.65

local xrayCacheBuilt = false
local xrayCacheBuilding = false
local xrayUpdateToken = 0

local origTransparencyMap = {}
local xrayBasesParts = {}
local xrayZonesParts = {}
local xrayDealersParts = {}
local xraySubFloorParts = {}

local netTrailsEnabled = false
local netTrailColorName = "White"
local netTrailColor = NetTrailColorMap["White"]
local trackedNetTrails = {}
local modifiedNetTrails = {}

local chinaHatEnabled = false
local chinaHatColor = ColorMap["Green"]
local chinaHatFolder = nil

local trailEnabled = false
local trailColor = ColorMap["Green"]
local activeTrail = nil

local footstepsEnabled = false
local footstepsColor = ColorMap["Green"]
local lastFootstepTime = 0
local activeFootsteps = {}

local jumpCircleEnabled = false
local jumpCircleColor = ColorMap["Green"]
local lastJumpCircleTime = 0
local activeJumpCircles = {}

--------------------------------------------------------------------
-- БЫСТРАЯ ОДНОПРОХОДНАЯ ИНДЕКСАЦИЯ XRAY (БЕЗ ФРИЗОВ)
--------------------------------------------------------------------
local function IsVisualProHubPart(obj)
    local n = obj.Name
    if string.find(n, "ProHub_", 1, true) or n == "HatCone" then
        return true
    end
    if chinaHatFolder and obj:IsDescendantOf(chinaHatFolder) then
        return true
    end
    return false
end

local function IsFloorOrUndergroundPart(part, floorY)
    local topY = part.Position.Y + (part.Size.Y * 0.5)
    if topY <= (floorY + 0.48) then
        return true
    end
    if topY <= (floorY + 0.95) and part.Size.Y <= 0.8 and part.Material == Enum.Material.Neon then
        return true
    end
    return false
end

local function AddPartWithDecalsFast(part, targetSet)
    targetSet[part] = true
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            targetSet[child] = true
        end
    end
end

-- Собирает все категории Xray за ОДИН проход по Workspace с анти-фриз паузами
local function BuildXrayCacheOnce()
    if xrayCacheBuilt or xrayCacheBuilding then return end
    xrayCacheBuilding = true

    table.clear(xrayDealersParts)
    table.clear(xrayBasesParts)
    table.clear(xrayZonesParts)
    table.clear(xraySubFloorParts)

    local floorY, mapCenter = GetMainArenaFloor()
    local allDescendants = workspace:GetDescendants()

    local dealerCenters = {}
    local baseCenters = {}
    local protectedBoardParts = {}
    local allBaseParts = {}

    -- Проход 1: Находим центры лавок, баз и защищенных табло (Leaderboard / Live Spawns)
    for i = 1, #allDescendants do
        if i % 1500 == 0 then RunService.Heartbeat:Wait() end
        local obj = allDescendants[i]
        if obj and obj.Parent and not IsInsideAnyPlayerCharacter(obj) then
            if obj:IsA("BasePart") then
                if not IsVisualProHubPart(obj) then
                    table.insert(allBaseParts, obj)
                end
            elseif obj:IsA("ProximityPrompt") then
                local pTxt = string.lower((obj.ObjectText or "") .. " " .. (obj.ActionText or "") .. " " .. obj.Name)
                local part = GetObjectWorldPart(obj)
                if part then
                    if string.find(pTxt, "отжим", 1, true) or string.find(pTxt, "push", 1, true) or string.find(pTxt, "train", 1, true) or string.find(pTxt, "workout", 1, true) then
                        if math.abs(part.Position.Y - floorY) <= 14 then
                            table.insert(baseCenters, part.Position)
                        end
                    elseif string.find(pTxt, "gift", 1, true) or string.find(pTxt, "подар", 1, true) or string.find(pTxt, "free", 1, true) then
                        table.insert(dealerCenters, part.Position)
                    end
                end
            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local txt = GetCombinedGuiText(obj)
                if #txt > 0 then
                    local part = GetObjectWorldPart(obj)
                    if part then
                        if string.find(txt, "top money", 1, true)
                            or string.find(txt, "top power", 1, true)
                            or string.find(txt, "live spawns", 1, true)
                            or string.find(txt, "wanted egg", 1, true) then
                            protectedBoardParts[part] = true
                        elseif string.find(txt, "продать", 1, true)
                            or string.find(txt, "магазин", 1, true)
                            or string.find(txt, "free gift", 1, true)
                            or string.find(txt, "free!", 1, true)
                            or string.find(txt, "gun shop", 1, true)
                            or string.find(txt, "net shop", 1, true) then
                            table.insert(dealerCenters, part.Position)
                        elseif (string.find(txt, "отжимания", 1, true)
                            or string.find(txt, "отжимани", 1, true)
                            or string.find(txt, "свободная база", 1, true)
                            or string.find(txt, "free base", 1, true)
                            or string.find(txt, "pushup", 1, true))
                            and math.abs(part.Position.Y - floorY) <= 14 then
                            table.insert(baseCenters, part.Position)
                        end
                    end
                end
            end
        end
    end

    -- Вычисляем прямоугольник всех 6 баз (включая заборы до задней стены)
    local hasBaseBox = false
    local baseMinX, baseMaxX, baseMinZ, baseMaxZ = 0, 0, 0, 0
    if #baseCenters > 0 then
        hasBaseBox = true
        local avgX, avgZ = 0, 0
        local minX, maxX = math.huge, -math.huge
        local minZ, maxZ = math.huge, -math.huge
        for _, pos in ipairs(baseCenters) do
            avgX = avgX + pos.X
            avgZ = avgZ + pos.Z
            if pos.X < minX then minX = pos.X end
            if pos.X > maxX then maxX = pos.X end
            if pos.Z < minZ then minZ = pos.Z end
            if pos.Z > maxZ then maxZ = pos.Z end
        end
        avgX = avgX / #baseCenters
        avgZ = avgZ / #baseCenters

        local frontDir = GetOutwardWallDirection(Vector3.new(avgX, floorY, avgZ), floorY, mapCenter, nil)
        local backDir = -frontDir

        local p1 = Vector3.new(minX, floorY, minZ) + (backDir * 60) - Vector3.new(18, 0, 18)
        local p2 = Vector3.new(maxX, floorY, maxZ) + (backDir * 60) + Vector3.new(18, 0, 18)
        baseMinX = math.min(minX - 18, p1.X, p2.X)
        baseMaxX = math.max(maxX + 18, p1.X, p2.X)
        baseMinZ = math.min(minZ - 18, p1.Z, p2.Z)
        baseMaxZ = math.max(maxZ + 18, p1.Z, p2.Z)
    end

    -- Вычисляем границы пола Лобби
    local lobbyMinX, lobbyMaxX = baseMinX - 15, baseMaxX + 15
    local lobbyMinZ, lobbyMaxZ = baseMinZ - 15, baseMaxZ + 15
    for _, dPos in ipairs(dealerCenters) do
        if (dPos.X - 15) < lobbyMinX then lobbyMinX = dPos.X - 15 end
        if (dPos.X + 15) > lobbyMaxX then lobbyMaxX = dPos.X + 15 end
        if (dPos.Z - 15) < lobbyMinZ then lobbyMinZ = dPos.Z - 15 end
        if (dPos.Z + 15) > lobbyMaxZ then lobbyMaxZ = dPos.Z + 15 end
    end

    -- Проход 2: Быстро распределяем все BasePart по категориям (Dealers, Bases, Zones)
    for i = 1, #allBaseParts do
        if i % 1200 == 0 then RunService.Heartbeat:Wait() end
        local part = allBaseParts[i]
        if part and part.Parent and not protectedBoardParts[part] and not IsInsideAnyPlayerCharacter(part) then
            local pos = part.Position
            local sz = part.Size
            local topY = pos.Y + (sz.Y * 0.5)
            local c = part.Color
            local isFloorPart = IsFloorOrUndergroundPart(part, floorY)

            -- 1. Проверка Dealers (Продать, Магазин, Подарок)
            local isDealer = false
            if not isFloorPart and sz.X < 32 and sz.Z < 32 and pos.Y <= (floorY + 18) then
                for _, dCenter in ipairs(dealerCenters) do
                    local dx = pos.X - dCenter.X
                    local dz = pos.Z - dCenter.Z
                    if (dx * dx + dz * dz) <= 169 then -- радиус 13 стадов
                        isDealer = true
                        break
                    end
                end
            end

            if isDealer then
                AddPartWithDecalsFast(part, xrayDealersParts)
            else
                -- 2. Проверка Bases (Все 6 баз и отжималки)
                local isBase = false
                if hasBaseBox and not isFloorPart and sz.Y <= 15 and sz.X <= 65 and sz.Z <= 65 and pos.Y <= (floorY + 15) then
                    if pos.X >= baseMinX and pos.X <= baseMaxX and pos.Z >= baseMinZ and pos.Z <= baseMaxZ then
                        isBase = true
                    end
                end

                if isBase then
                    AddPartWithDecalsFast(part, xrayBasesParts)
                else
                    -- 3. Проверка Zones (Все зоны ловли яиц на карте)
                    local pName = string.lower(part.Name)
                    local parentName = part.Parent and string.lower(part.Parent.Name) or ""
                    local isSmallEgg = (sz.X < 10 and sz.Y < 10 and sz.Z < 10)
                        and (string.find(pName, "egg", 1, true) or string.find(parentName, "egg", 1, true) or string.find(pName, "яйц", 1, true))

                    if not isSmallEgg then
                        local isBlueUnderplate = (topY <= floorY - 0.15)
                            or (sz.X >= 40 and sz.Z >= 40 and topY <= floorY + 0.1 and c.B > 0.5 and c.R < 0.45)

                        if isBlueUnderplate then
                            xraySubFloorParts[part] = true
                        else
                            local isGreenLobbyTile = false
                            if topY <= (floorY + 0.48) and topY >= (floorY - 0.5) then
                                local isBrightGreen = (c.G > 0.52 and c.G > (c.R * 1.18) and c.B < 0.45)
                                if isBrightGreen and hasBaseBox then
                                    if pos.X >= lobbyMinX and pos.X <= lobbyMaxX and pos.Z >= lobbyMinZ and pos.Z <= lobbyMaxZ then
                                        isGreenLobbyTile = true
                                    end
                                end
                            end

                            if not isGreenLobbyTile then
                                AddPartWithDecalsFast(part, xrayZonesParts)
                            end
                        end
                    end
                end
            end
        end
    end

    xrayCacheBuilt = true
    xrayCacheBuilding = false
end

-- Запускаем фоновую индексацию сразу при старте скрипта, чтобы кнопки Xray срабатывали мгновенно
task.spawn(BuildXrayCacheOnce)

local function ApplyOrRestoreXrayPart(obj)
    if not (obj and obj.Parent) then return end

    if xrayZonesEnabled and xraySubFloorParts[obj] then
        if origTransparencyMap[obj] == nil then
            origTransparencyMap[obj] = obj.Transparency
        end
        obj.Transparency = 1
        return
    end

    local shouldXray = (xrayBasesEnabled and xrayBasesParts[obj])
        or (xrayZonesEnabled and xrayZonesParts[obj])
        or (xrayDealersEnabled and xrayDealersParts[obj])

    if shouldXray then
        if origTransparencyMap[obj] == nil then
            origTransparencyMap[obj] = obj.Transparency
        end
        if origTransparencyMap[obj] < XRAY_ALPHA then
            obj.Transparency = XRAY_ALPHA
        end
    else
        local orig = origTransparencyMap[obj]
        if orig ~= nil then
            obj.Transparency = orig
            origTransparencyMap[obj] = nil
        end
    end
end

local function RefreshAllXrayAsync()
    xrayUpdateToken = xrayUpdateToken + 1
    local myToken = xrayUpdateToken

    task.spawn(function()
        if not xrayCacheBuilt then
            BuildXrayCacheOnce()
            while xrayCacheBuilding do
                RunService.Heartbeat:Wait()
            end
        end
        if myToken ~= xrayUpdateToken then return end

        local affectedList = {}
        local seen = {}

        local function CollectFromSet(setTbl)
            for k in pairs(setTbl) do
                if not seen[k] then
                    seen[k] = true
                    table.insert(affectedList, k)
                end
            end
        end

        CollectFromSet(origTransparencyMap)
        if xrayBasesEnabled then CollectFromSet(xrayBasesParts) end
        if xrayDealersEnabled then CollectFromSet(xrayDealersParts) end
        if xrayZonesEnabled then
            CollectFromSet(xrayZonesParts)
            CollectFromSet(xraySubFloorParts)
        end

        for i = 1, #affectedList do
            if myToken ~= xrayUpdateToken then return end
            ApplyOrRestoreXrayPart(affectedList[i])
            if i % 800 == 0 then
                RunService.Heartbeat:Wait()
            end
        end
    end)
end

--------------------------------------------------------------------
-- ЛОГИКА SKINCHANGER (Визуальная смена скина: You, 2, 3)
--------------------------------------------------------------------
local skinchangerEnabled = false
local selectedSkinName = "You"
local skinChangeToken = 0

local savedCharOriginalData = {}
local activeCustomSkinObjects = {}
local cachedSkinModels = {}

local function SaveOriginalCharacterAppearance(char)
    if not char or savedCharOriginalData[char] then return end

    local data = {
        PartColors = {},
        PartMeshes = {},
        AccessoryHandles = {},
        ShirtTemplate = nil,
        PantsTemplate = nil,
        GraphicTemplate = nil,
        FaceTexture = nil,
        BodyColors = nil
    }

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("BasePart") then
            data.PartColors[child] = child.Color
            if child:IsA("MeshPart") then
                data.PartMeshes[child] = { MeshId = child.MeshId, TextureID = child.TextureID }
            end
        elseif child:IsA("Shirt") then
            data.ShirtTemplate = child.ShirtTemplate
        elseif child:IsA("Pants") then
            data.PantsTemplate = child.PantsTemplate
        elseif child:IsA("ShirtGraphic") then
            data.GraphicTemplate = child.Graphic
        elseif child:IsA("BodyColors") then
            data.BodyColors = {
                HeadColor3 = child.HeadColor3,
                TorsoColor3 = child.TorsoColor3,
                LeftArmColor3 = child.LeftArmColor3,
                RightArmColor3 = child.RightArmColor3,
                LeftLegColor3 = child.LeftLegColor3,
                RightLegColor3 = child.RightLegColor3
            }
        elseif child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                data.AccessoryHandles[handle] = handle.Transparency
            end
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChildOfClass("Decal")
        if face then
            data.FaceTexture = face.Texture
        end
    end

    savedCharOriginalData[char] = data
end

local function CleanupActiveCustomSkin()
    for _, obj in ipairs(activeCustomSkinObjects) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(activeCustomSkinObjects)
end

local function RestoreOriginalCharacterAppearance(char)
    CleanupActiveCustomSkin()
    if not char then return end

    local data = savedCharOriginalData[char]
    if not data then return end

    for part, col in pairs(data.PartColors) do
        if part and part.Parent then
            part.Color = col
        end
    end

    for handle, trans in pairs(data.AccessoryHandles) do
        if handle and handle.Parent then
            handle.Transparency = trans
        end
    end

    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc and data.BodyColors then
        bc.HeadColor3 = data.BodyColors.HeadColor3
        bc.TorsoColor3 = data.BodyColors.TorsoColor3
        bc.LeftArmColor3 = data.BodyColors.LeftArmColor3
        bc.RightArmColor3 = data.BodyColors.RightArmColor3
        bc.LeftLegColor3 = data.BodyColors.LeftLegColor3
        bc.RightLegColor3 = data.BodyColors.RightLegColor3
    end

    local shirt = char:FindFirstChildOfClass("Shirt")
    if data.ShirtTemplate then
        if not shirt then
            shirt = Instance.new("Shirt")
            shirt.Parent = char
        end
        shirt.ShirtTemplate = data.ShirtTemplate
    elseif shirt then
        shirt.ShirtTemplate = ""
    end

    local pants = char:FindFirstChildOfClass("Pants")
    if data.PantsTemplate then
        if not pants then
            pants = Instance.new("Pants")
            pants.Parent = char
        end
        pants.PantsTemplate = data.PantsTemplate
    elseif pants then
        pants.PantsTemplate = ""
    end

    local graphic = char:FindFirstChildOfClass("ShirtGraphic")
    if data.GraphicTemplate then
        if not graphic then
            graphic = Instance.new("ShirtGraphic")
            graphic.Parent = char
        end
        graphic.Graphic = data.GraphicTemplate
    elseif graphic then
        graphic.Graphic = ""
    end

    local head = char:FindFirstChild("Head")
    if head and data.FaceTexture then
        local face = head:FindFirstChildOfClass("Decal")
        if face then
            face.Texture = data.FaceTexture
        end
    end
end

local function HideOriginalClothingAndAccessories(char)
    SaveOriginalCharacterAppearance(char)
    local data = savedCharOriginalData[char]
    if data then
        for handle in pairs(data.AccessoryHandles) do
            if handle and handle.Parent then
                handle.Transparency = 1
            end
        end
    end

    local shirt = char:FindFirstChildOfClass("Shirt")
    if shirt then shirt.ShirtTemplate = "" end

    local pants = char:FindFirstChildOfClass("Pants")
    if pants then pants.PantsTemplate = "" end

    local graphic = char:FindFirstChildOfClass("ShirtGraphic")
    if graphic then graphic.Graphic = "" end
end

local function SetCharacterBodyColors(char, headCol, torsoCol, armCol, legCol)
    local bc = char:FindFirstChildOfClass("BodyColors")
    if not bc then
        bc = Instance.new("BodyColors")
        bc.Parent = char
        table.insert(activeCustomSkinObjects, bc)
    end

    bc.HeadColor3 = headCol
    bc.TorsoColor3 = torsoCol
    bc.LeftArmColor3 = armCol
    bc.RightArmColor3 = armCol
    bc.LeftLegColor3 = legCol
    bc.RightLegColor3 = legCol

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local nm = part.Name
            if nm == "Head" then
                part.Color = headCol
            elseif nm == "Torso" or nm == "UpperTorso" or nm == "LowerTorso" then
                part.Color = torsoCol
            elseif string.find(nm, "Arm") or string.find(nm, "Hand") then
                part.Color = armCol
            elseif string.find(nm, "Leg") or string.find(nm, "Foot") then
                part.Color = legCol
            end
        end
    end
end

local function AttachDonorAccessoryToChar(acc, donorModel, char)
    local handle = acc:FindFirstChild("Handle")
    if not (handle and handle:IsA("BasePart")) then return end

    local accClone = acc:Clone()
    local cloneHandle = accClone:FindFirstChild("Handle")
    if not cloneHandle then return end

    cloneHandle.Anchored = false
    cloneHandle.CanCollide = false
    cloneHandle.Massless = true
    cloneHandle.Transparency = 0

    for _, v in ipairs(cloneHandle:GetChildren()) do
        if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("Motor6D") then
            v:Destroy()
        end
    end

    local accAttachment = cloneHandle:FindFirstChildOfClass("Attachment")
    local charAttachment = nil
    if accAttachment then
        charAttachment = char:FindFirstChild(accAttachment.Name, true)
    end

    if charAttachment and charAttachment.Parent and charAttachment.Parent:IsA("BasePart") then
        local targetPart = charAttachment.Parent
        cloneHandle.CFrame = targetPart.CFrame * charAttachment.CFrame * accAttachment.CFrame:Inverse()

        local weld = Instance.new("Weld")
        weld.Name = "ProHub_SkinWeld"
        weld.Part0 = targetPart
        weld.Part1 = cloneHandle
        weld.C0 = charAttachment.CFrame
        weld.C1 = accAttachment.CFrame
        weld.Parent = cloneHandle
    else
        local charHead = char:FindFirstChild("Head")
        local donorHead = donorModel and donorModel:FindFirstChild("Head")
        if charHead then
            local relCF = (donorHead and donorHead.CFrame:ToObjectSpace(handle.CFrame)) or CFrame.new(0, 0.5, 0)
            cloneHandle.CFrame = charHead.CFrame * relCF

            local weld = Instance.new("Weld")
            weld.Name = "ProHub_SkinWeld"
            weld.Part0 = charHead
            weld.Part1 = cloneHandle
            weld.C0 = relCF
            weld.C1 = CFrame.new()
            weld.Parent = cloneHandle
        end
    end

    accClone.Parent = char
    table.insert(activeCustomSkinObjects, accClone)
end

local function ApplyDonorModelToChar(donorModel, char)
    if not (donorModel and char) then return end

    local dBC = donorModel:FindFirstChildOfClass("BodyColors")
    if dBC then
        SetCharacterBodyColors(char, dBC.HeadColor3, dBC.TorsoColor3, dBC.LeftArmColor3, dBC.LeftLegColor3)
    end

    local dShirt = donorModel:FindFirstChildOfClass("Shirt")
    if dShirt and dShirt.ShirtTemplate ~= "" then
        local cShirt = char:FindFirstChildOfClass("Shirt")
        if not cShirt then
            cShirt = Instance.new("Shirt")
            cShirt.Parent = char
            table.insert(activeCustomSkinObjects, cShirt)
        end
        cShirt.ShirtTemplate = dShirt.ShirtTemplate
    end

    local dPants = donorModel:FindFirstChildOfClass("Pants")
    if dPants and dPants.PantsTemplate ~= "" then
        local cPants = char:FindFirstChildOfClass("Pants")
        if not cPants then
            cPants = Instance.new("Pants")
            cPants.Parent = char
            table.insert(activeCustomSkinObjects, cPants)
        end
        cPants.PantsTemplate = dPants.PantsTemplate
    end

    local dGraphic = donorModel:FindFirstChildOfClass("ShirtGraphic")
    if dGraphic and dGraphic.Graphic ~= "" then
        local cGraphic = char:FindFirstChildOfClass("ShirtGraphic")
        if not cGraphic then
            cGraphic = Instance.new("ShirtGraphic")
            cGraphic.Parent = char
            table.insert(activeCustomSkinObjects, cGraphic)
        end
        cGraphic.Graphic = dGraphic.Graphic
    end

    local dHead = donorModel:FindFirstChild("Head")
    local cHead = char:FindFirstChild("Head")
    if dHead and cHead then
        local dFace = dHead:FindFirstChildOfClass("Decal")
        local cFace = cHead:FindFirstChildOfClass("Decal")
        if dFace and cFace then
            cFace.Texture = dFace.Texture
        end
    end

    for _, child in ipairs(donorModel:GetChildren()) do
        if child:IsA("Accessory") then
            AttachDonorAccessoryToChar(child, donorModel, char)
        end
    end
end

local function ApplySelectedVisualSkin()
    skinChangeToken = skinChangeToken + 1
    local myToken = skinChangeToken

    -- Обновляем иконку в окне профиля в соответствии с выбранным скином
    UpdateProfileAvatarBySkin(selectedSkinName, skinchangerEnabled or selectedSkinName ~= "You")

    local char = LocalPlayer.Character
    if not char then return end

    SaveOriginalCharacterAppearance(char)
    RestoreOriginalCharacterAppearance(char)

    if not skinchangerEnabled or selectedSkinName == "You" then
        if not skinchangerEnabled then
            UpdateProfileAvatarBySkin("You", false)
        end
        return
    end

    local targetUserId = SkinUserIds[selectedSkinName]
    if not targetUserId then return end

    HideOriginalClothingAndAccessories(char)

    task.spawn(function()
        local donorModel = cachedSkinModels[selectedSkinName]
        if not donorModel then
            local ok, mdl = pcall(function()
                return Players:CreateHumanoidModelFromUserId(targetUserId)
            end)
            if ok and mdl then
                cachedSkinModels[selectedSkinName] = mdl
                donorModel = mdl
            end
        end

        if myToken ~= skinChangeToken or not skinchangerEnabled then return end
        if LocalPlayer.Character ~= char then return end

        if donorModel then
            ApplyDonorModelToChar(donorModel, char)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.8)
    if skinchangerEnabled and selectedSkinName ~= "You" and LocalPlayer.Character == newChar then
        ApplySelectedVisualSkin()
    end
end)

--------------------------------------------------------------------
-- ЭЛЕМЕНТЫ ВКЛАДКИ VISUALS
--------------------------------------------------------------------
Tabs.Visuals:Toggle({
    Title = "Rainbow Visuals",
    Desc = "Делает все визуалы радужными (кроме Esp)",
    Default = false,
    Callback = function(state)
        rainbowVisualsEnabled = state
        if not state then
            if activeTrail and activeTrail.Parent then
                activeTrail.Color = ColorSequence.new(trailColor)
            end
            if chinaHatFolder then
                local cone = chinaHatFolder:FindFirstChild("HatCone")
                if cone then cone.Color = chinaHatColor end
            end
            if netTrailsEnabled then
                for trail in pairs(trackedNetTrails) do
                    if trail and trail.Parent then
                        trail.Color = ColorSequence.new(netTrailColor)
                        if netTrailColorName == "Black" then
                            trail.LightEmission = 0
                            trail.LightInfluence = 0
                        else
                            trail.LightEmission = 1
                        end
                    end
                end
            end
        end
    end
})

local function UpdatePlayerESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local hl = plr.Character:FindFirstChild("ProHub_ESP")
            if espEnabled then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ProHub_ESP"
                    hl.Adornee = plr.Character
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = plr.Character
                end
                hl.Adornee = plr.Character
                hl.FillColor = espColor
                hl.OutlineColor = espColor
                hl.FillTransparency = 0.45
                hl.OutlineTransparency = 0
            else
                if hl then hl:Destroy() end
            end
        end
    end
end

Tabs.Visuals:Toggle({
    Title = "Esp",
    Desc = "Заливка с контуром (включая вашего персонажа)",
    Default = false,
    Callback = function(state)
        espEnabled = state
        UpdatePlayerESP()
    end
})

Tabs.Visuals:Dropdown({
    Title = "Color Esp",
    Values = { "Green", "Blue", "Red" },
    Value = "Green",
    Callback = function(option)
        espColor = ColorMap[option] or ColorMap["Green"]
        UpdatePlayerESP()
    end
})

Tabs.Visuals:Toggle({
    Title = "Xray Bases",
    Desc = "Делает все базы и зону отжиманий полупрозрачными",
    Default = false,
    Callback = function(state)
        xrayBasesEnabled = state
        RefreshAllXrayAsync()
    end
})

Tabs.Visuals:Toggle({
    Title = "Xray Zones",
    Desc = "Делает все зоны ловли яиц на карте полупрозрачными",
    Default = false,
    Callback = function(state)
        xrayZonesEnabled = state
        RefreshAllXrayAsync()
    end
})

Tabs.Visuals:Toggle({
    Title = "Xray Dealers",
    Desc = "Делает домик продажи, магазин пушек и подарок полупрозрачными",
    Default = false,
    Callback = function(state)
        xrayDealersEnabled = state
        RefreshAllXrayAsync()
    end
})

-- Skinchanger и выбор скина (You, 2, 3)
Tabs.Visuals:Toggle({
    Title = "Skinchanger",
    Desc = "Визуально надевает выбранный скин (только 1 скин разом)",
    Default = false,
    Callback = function(state)
        skinchangerEnabled = state
        ApplySelectedVisualSkin()
    end
})

Tabs.Visuals:Dropdown({
    Title = "Select Skin",
    Values = { "You", "2", "3" },
    Value = "You",
    Callback = function(option)
        selectedSkinName = option
        UpdateProfileAvatarBySkin(selectedSkinName, true)
        if skinchangerEnabled then
            ApplySelectedVisualSkin()
        end
    end
})

local function ApplyToSingleNetTrail(trail)
    if not trail or not trail:IsA("Trail") then return end
    if trail.Name == "ProHub_Trail" or IsInsideAnyPlayerCharacter(trail) then return end

    trackedNetTrails[trail] = true

    if not modifiedNetTrails[trail] then
        modifiedNetTrails[trail] = {
            Color = trail.Color,
            LightEmission = trail.LightEmission,
            LightInfluence = trail.LightInfluence
        }
    end

    local useColor = rainbowVisualsEnabled and currentRainbowColor or netTrailColor
    trail.Color = ColorSequence.new(useColor)

    if not rainbowVisualsEnabled and netTrailColorName == "Black" then
        trail.LightEmission = 0
        trail.LightInfluence = 0
    else
        trail.LightEmission = 1
    end
end

local function RestoreNetTrails()
    for trail, orig in pairs(modifiedNetTrails) do
        if trail and trail.Parent then
            trail.Color = orig.Color
            trail.LightEmission = orig.LightEmission
            trail.LightInfluence = orig.LightInfluence
        end
    end
    table.clear(modifiedNetTrails)
    table.clear(trackedNetTrails)
end

local function ScanAllNetTrailsOnce()
    if not netTrailsEnabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Trail") and obj.Name ~= "ProHub_Trail" and not IsInsideAnyPlayerCharacter(obj) then
            ApplyToSingleNetTrail(obj)
        end
    end
end

local function UpdateCachedNetTrailsColor()
    if not netTrailsEnabled then return end
    for trail in pairs(trackedNetTrails) do
        if trail and trail.Parent then
            ApplyToSingleNetTrail(trail)
        else
            trackedNetTrails[trail] = nil
            modifiedNetTrails[trail] = nil
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if netTrailsEnabled and obj:IsA("Trail") and obj.Name ~= "ProHub_Trail" then
        task.defer(function()
            if netTrailsEnabled and obj.Parent and not IsInsideAnyPlayerCharacter(obj) then
                ApplyToSingleNetTrail(obj)
            end
        end)
    end
end)

Tabs.Visuals:Toggle({
    Title = "Net Trails",
    Desc = "Заменяет цвет трейлов на летящей сетке (без лагов)",
    Default = false,
    Callback = function(state)
        netTrailsEnabled = state
        if state then
            ScanAllNetTrailsOnce()
        else
            RestoreNetTrails()
        end
    end
})

Tabs.Visuals:Dropdown({
    Title = "Net Trails Color",
    Values = { "White", "Black", "Red", "Blue", "Green", "Orange" },
    Value = "White",
    Callback = function(option)
        netTrailColorName = option
        netTrailColor = NetTrailColorMap[option] or NetTrailColorMap["White"]
        if netTrailsEnabled then
            UpdateCachedNetTrailsColor()
        end
    end
})

local function RemoveChinaHat()
    if chinaHatFolder then chinaHatFolder:Destroy() chinaHatFolder = nil end
end

local function CreateOrUpdateChinaHat()
    if not chinaHatEnabled then RemoveChinaHat() return end
    local char = LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    if not chinaHatFolder or not chinaHatFolder.Parent then
        RemoveChinaHat()
        chinaHatFolder = Instance.new("Folder")
        chinaHatFolder.Name = "ProHub_ChinaHat"
        chinaHatFolder.Parent = workspace

        local cone = Instance.new("Part")
        cone.Name = "HatCone"
        cone.Anchored = true
        cone.CanCollide = false
        cone.CastShadow = false
        cone.Material = Enum.Material.Neon
        cone.Transparency = 0.35
        cone.Size = Vector3.new(3.2, 1.1, 3.2)

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://1033714"
        mesh.Scale = Vector3.new(1.75, 1.1, 1.75)
        mesh.Parent = cone

        cone.Parent = chinaHatFolder
    end

    local cone = chinaHatFolder:FindFirstChild("HatCone")
    if cone then
        cone.Color = rainbowVisualsEnabled and currentRainbowColor or chinaHatColor
        cone.CFrame = head.CFrame * CFrame.new(0, 1.15, 0)
    end
end

Tabs.Visuals:Toggle({
    Title = "China Hat",
    Default = false,
    Callback = function(state)
        chinaHatEnabled = state
        if not state then RemoveChinaHat() end
    end
})

Tabs.Visuals:Dropdown({
    Title = "China Hat Color",
    Values = { "Green", "Blue", "Red" },
    Value = "Green",
    Callback = function(option)
        chinaHatColor = ColorMap[option] or ColorMap["Green"]
    end
})

local function UpdateTrail()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not trailEnabled or not hrp then
        if activeTrail then activeTrail:Destroy() activeTrail = nil end
        return
    end

    if not activeTrail or not activeTrail.Parent then
        local a0 = hrp:FindFirstChild("ProHub_TrailA0") or Instance.new("Attachment", hrp)
        a0.Name = "ProHub_TrailA0"
        a0.Position = Vector3.new(0, 1, 0)

        local a1 = hrp:FindFirstChild("ProHub_TrailA1") or Instance.new("Attachment", hrp)
        a1.Name = "ProHub_TrailA1"
        a1.Position = Vector3.new(0, -1, 0)

        activeTrail = Instance.new("Trail")
        activeTrail.Name = "ProHub_Trail"
        activeTrail.Attachment0 = a0
        activeTrail.Attachment1 = a1
        activeTrail.Lifetime = 0.65
        activeTrail.FaceCamera = true
        activeTrail.LightEmission = 1
        activeTrail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        activeTrail.Parent = hrp
    end

    local useColor = rainbowVisualsEnabled and currentRainbowColor or trailColor
    activeTrail.Color = ColorSequence.new(useColor)
end

Tabs.Visuals:Toggle({
    Title = "Trail",
    Default = false,
    Callback = function(state)
        trailEnabled = state
        UpdateTrail()
    end
})

Tabs.Visuals:Dropdown({
    Title = "Trail Color",
    Values = { "Green", "Blue", "Red" },
    Value = "Green",
    Callback = function(option)
        trailColor = ColorMap[option] or ColorMap["Green"]
        UpdateTrail()
    end
})

local function SpawnFootstep(position)
    local step = Instance.new("Part")
    step.Name = "ProHub_Footstep"
    step.Anchored = true
    step.CanCollide = false
    step.CastShadow = false
    step.Material = Enum.Material.Neon
    step.Color = rainbowVisualsEnabled and currentRainbowColor or footstepsColor
    step.Shape = Enum.PartType.Cylinder
    step.Size = Vector3.new(0.1, 1.2, 1.2)
    step.CFrame = CFrame.new(position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
    step.Transparency = 0.25
    step.Parent = workspace

    activeFootsteps[step] = true

    local tween = TweenService:Create(step, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.05, 3.2, 3.2), Transparency = 1 })
    tween:Play()
    tween.Completed:Connect(function()
        activeFootsteps[step] = nil
        step:Destroy()
    end)
end

Tabs.Visuals:Toggle({
    Title = "Footsteps",
    Default = false,
    Callback = function(state) footstepsEnabled = state end
})

Tabs.Visuals:Dropdown({
    Title = "Footsteps Color",
    Values = { "Green", "Blue", "Red" },
    Value = "Green",
    Callback = function(option)
        footstepsColor = ColorMap[option] or ColorMap["Green"]
    end
})

local function SpawnJumpCircle()
    if not jumpCircleEnabled or (tick() - lastJumpCircleTime) < 0.2 then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    lastJumpCircleTime = tick()

    local ring = Instance.new("Part")
    ring.Name = "ProHub_JumpCircle"
    ring.Anchored = true
    ring.CanCollide = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = rainbowVisualsEnabled and currentRainbowColor or jumpCircleColor
    ring.Size = Vector3.new(1, 1, 1)
    ring.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(math.rad(90), 0, 0)
    ring.Transparency = 0.15
    ring.Parent = workspace

    activeJumpCircles[ring] = true

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://3270017"
    mesh.Scale = Vector3.new(1.2, 1.2, 1.2)
    mesh.Parent = ring

    local tweenMesh = TweenService:Create(mesh, TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = Vector3.new(8.5, 8.5, 1.2) })
    local tweenPart = TweenService:Create(ring, TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Transparency = 1 })
    tweenMesh:Play()
    tweenPart:Play()
    tweenPart.Completed:Connect(function()
        activeJumpCircles[ring] = nil
        ring:Destroy()
    end)
end

local wasInAir = false
local function HookCharacterLanding(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Landed then SpawnJumpCircle() end
        end)
    end
end

if LocalPlayer.Character then HookCharacterLanding(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(HookCharacterLanding)

Tabs.Visuals:Toggle({
    Title = "Jump Circle",
    Desc = "Появляется при падении (приземлении)",
    Default = false,
    Callback = function(state) jumpCircleEnabled = state end
})

Tabs.Visuals:Dropdown({
    Title = "Jump Circle Color",
    Values = { "Green", "Blue", "Red" },
    Value = "Green",
    Callback = function(option)
        jumpCircleColor = ColorMap[option] or ColorMap["Green"]
    end
})

Tabs.Visuals:Button({
    Title = "Fps Boost",
    Desc = "Убирает текстуры, тени и частицы для повышения FPS",
    Callback = function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
            elseif v:IsA("ParticleEmitter") then v.Enabled = false end
        end
    end
})

--------------------------------------------------------------------
-- ВКЛАДКА: PLAYER (Spinbot Real / Visual со скоростью, Fly, Noclip)
--------------------------------------------------------------------
local spinbotEnabled = false
local spinbotMode = "Real"
local spinbotSpeed = 10
local currentYaw = 0

local flyEnabled = false
local flySpeed = 60
local flyBV = nil
local flyBG = nil
local infJumpEnabled = false
local noclipEnabled = false

local function StopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function UpdateFly()
    if not flyEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if not flyBV or not flyBV.Parent then
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "ProHub_FlyBV"
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
    end

    if not flyBG or not flyBG.Parent then
        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "ProHub_FlyBG"
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.P = 9e4
        flyBG.CFrame = Camera.CFrame
        flyBG.Parent = hrp
    end

    hum.PlatformStand = true
    flyBG.CFrame = Camera.CFrame

    local moveDir = hum.MoveDirection
    if moveDir.Magnitude > 0 then
        local camCF = Camera.CFrame
        local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
        if flatLook.Magnitude > 0.01 then
            flatLook = flatLook.Unit
            local forwardDot = moveDir:Dot(flatLook)
            local rightDot = moveDir:Dot(camCF.RightVector)
            flyBV.Velocity = (camCF.LookVector * forwardDot + camCF.RightVector * rightDot) * flySpeed
        else
            flyBV.Velocity = moveDir * flySpeed
        end
    else
        flyBV.Velocity = Vector3.zero
    end
end

Tabs.Player:Toggle({
    Title = "Spinbot",
    Desc = "Вращение персонажа",
    Default = false,
    Callback = function(state) spinbotEnabled = state end
})

Tabs.Player:Dropdown({
    Title = "Spinbot Mode",
    Values = { "Real", "Visual" },
    Value = "Real",
    Callback = function(option) spinbotMode = option end
})

Tabs.Player:Slider({
    Title = "Spinbot Speed",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = 10 },
    Callback = function(val) spinbotSpeed = val end
})

Tabs.Player:Toggle({
    Title = "Fly",
    Desc = "Полет (работает с джойстиком на телефоне и WASD на ПК)",
    Default = false,
    Callback = function(state)
        flyEnabled = state
        if not state then StopFly() end
    end
})

Tabs.Player:Slider({
    Title = "Fly Speed",
    Step = 1,
    Value = { Min = 20, Max = 200, Default = 60 },
    Callback = function(val) flySpeed = val end
})

Tabs.Player:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
})

Tabs.Player:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = { Min = 50, Max = 250, Default = 50 },
    Callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val
        end
    end
})

Tabs.Player:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(state) infJumpEnabled = state end
})

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

Tabs.Player:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(state) noclipEnabled = state end
})

--------------------------------------------------------------------
-- ВКЛАДКА: SETTINGS
--------------------------------------------------------------------
Tabs.Settings:Dropdown({
    Title = "Theme",
    Values = { "Black", "Red", "Purple" },
    Value = "Black",
    Callback = function(themeName)
        WindUI:SetTheme(themeName)
        if ProfileStroke then
            if themeName == "Red" then
                ProfileStroke.Color = Color3.fromRGB(220, 38, 38)
            elseif themeName == "Purple" then
                ProfileStroke.Color = Color3.fromRGB(147, 51, 234)
            else
                ProfileStroke.Color = Color3.fromRGB(45, 45, 52)
            end
        end
    end
})

Tabs.Settings:Dropdown({
    Title = "Window Nickname",
    Values = { "You", "ProUser", "Lipton", "Anonym" },
    Value = "You",
    Callback = function(option)
        SetWindowNicknameMode(option)
    end
})

Tabs.Settings:Button({
    Title = "Leave",
    Callback = function() game:Shutdown() end
})

Tabs.Settings:Button({
    Title = "Rejoin",
    Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end
})

Tabs.Settings:Button({
    Title = "Respawn",
    Callback = function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
})

--------------------------------------------------------------------
-- ГЛАВНЫЕ ЦИКЛЫ ОБНОВЛЕНИЯ
--------------------------------------------------------------------
RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end

    if spinbotEnabled and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if hrp then
            currentYaw = (currentYaw + (spinbotSpeed * 3.5)) % 360
            local rotCF = CFrame.Angles(0, math.rad(currentYaw), 0)

            if spinbotMode == "Real" then
                hrp.CFrame = CFrame.new(hrp.Position) * rotCF
            elseif spinbotMode == "Visual" then
                if head then head.CFrame = CFrame.new(head.Position) * rotCF end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if rainbowVisualsEnabled then
        currentRainbowColor = Color3.fromHSV((tick() * 0.45) % 1, 1, 1)

        for step in pairs(activeFootsteps) do
            if step and step.Parent then step.Color = currentRainbowColor end
        end
        for ring in pairs(activeJumpCircles) do
            if ring and ring.Parent then ring.Color = currentRainbowColor end
        end
        if netTrailsEnabled then
            UpdateCachedNetTrailsColor()
        end
    end

    if autoBestCatchEnabled then
        for lbl in pairs(hookedGuiLabels) do
            if lbl and lbl.Parent then
                CheckIfLabelIsPlus19(lbl)
            else
                hookedGuiLabels[lbl] = nil
            end
        end
    end

    if flyEnabled then UpdateFly() end
    if espEnabled then UpdatePlayerESP() end
    if chinaHatEnabled then CreateOrUpdateChinaHat() end
    if trailEnabled then UpdateTrail() end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if hum and hrp then
        local inAir = (hum.FloorMaterial == Enum.Material.Air)
        if wasInAir and not inAir and jumpCircleEnabled then SpawnJumpCircle() end
        wasInAir = inAir

        if footstepsEnabled and hum.MoveDirection.Magnitude > 0.1 and not inAir and (tick() - lastFootstepTime) > 0.22 then
            lastFootstepTime = tick()
            SpawnFootstep(hrp.Position)
        end
    end
end)
