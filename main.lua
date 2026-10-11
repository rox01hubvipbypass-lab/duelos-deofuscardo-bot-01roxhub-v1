local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
while not player do task.wait() player = Players.LocalPlayer end

local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local fovVisiblePreference = false
local fovRadius = 120
local autoShootEnabled = false
local autoShootAgresivoEnabled = false
local autoShootTargetPart = "Cabeza"
local silentAimManualEnabled = false
local silentAimFovEnabled = false
local silentAimTargetPart = "Cabeza"
local teamCheckEnabled = true
local espEnabled = false
local espColor = Color3.fromRGB(255, 255, 255)
local espSettings = { Glow = true }

local UIElements = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NexvyrHub_Overlays"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = player:WaitForChild("PlayerGui")

local espFolder = Instance.new("Folder")
espFolder.Name = "NexvyrESPFolder"
espFolder.Parent = screenGui

local WindUI
local _version = "1.6.66"
local uiFileName = "WindUI_Cache_v" .. _version .. ".txt"
local timeFileName = "WindUI_Cache_v" .. _version .. "_Time.txt"

local ok, result = pcall(function()
    local cacheValido = false
    if isfile and isfile(timeFileName) and readfile then
        local savedTime = tonumber(readfile(timeFileName))
        if savedTime and (os.time() - savedTime) < 86400 then
            cacheValido = true
        end
    end
    if cacheValido and isfile and isfile(uiFileName) then
        return loadstring(readfile(uiFileName))()
    else
        local codigoUi = game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua")
        if writefile then
            writefile(uiFileName, codigoUi)
            writefile(timeFileName, tostring(os.time()))
        end
        return loadstring(codigoUi)()
    end
end)

if ok and result then
    WindUI = result
else
    warn("Error al cargar WindUI: " .. tostring(result))
    return
end

local COLORES_NEUTROS = {
    ["White"] = true,
    ["Medium stone grey"] = true,
    ["Medium Stone Grey"] = true,
    ["Really black"] = true,
    ["Really Black"] = true,
    ["Institutional white"] = true,
    ["Institutional White"] = true,
    ["Ghost grey"] = true,
    ["Ghost Grey"] = true,
}

local function esColorVerde(c)
    if typeof(c) ~= "Color3" then return false end
    return c.G >= 0.55 and c.G > c.R and c.G > c.B and (c.G - c.R) >= 0.15 and (c.G - c.B) >= 0.15
end

local function guiTieneVerde(obj)
    if not obj then return false end
    local okBg, bg = pcall(function() return obj.BackgroundColor3 end)
    if okBg and bg and esColorVerde(bg) then return true end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        local okT, tc = pcall(function() return obj.TextColor3 end)
        if okT and tc and esColorVerde(tc) then return true end
    end
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        local okI, ic = pcall(function() return obj.ImageColor3 end)
        if okI and ic and esColorVerde(ic) then return true end
    end
    return false
end

local function contenedorTieneVerde(container)
    if not container then return false end
    for _, desc in ipairs(container:GetDescendants()) do
        if desc:IsA("GuiObject") and guiTieneVerde(desc) then return true end
        if desc:IsA("Highlight") and (esColorVerde(desc.FillColor) or esColorVerde(desc.OutlineColor)) then return true end
        if desc:IsA("ParticleEmitter") then
            local ok2, cs = pcall(function() return desc.Color end)
            if ok2 and cs then
                local c0 = cs.Keypoints and cs.Keypoints[1] and cs.Keypoints[1].Value
                if c0 and esColorVerde(c0) then return true end
            end
        end
        if desc:IsA("PointLight") or desc:IsA("SpotLight") then
            local ok2, c = pcall(function() return desc.Color end)
            if ok2 and esColorVerde(c) then return true end
        end
        if desc:IsA("BillboardGui") then
            for _, sub in ipairs(desc:GetDescendants()) do
                if sub:IsA("GuiObject") and guiTieneVerde(sub) then return true end
            end
        end
    end
    return false
end

local marcaAliadoCache = {}
local MARCA_CACHE_TTL = 1.0
local function invalidarMarcaAliado(targetPlayer)
    if targetPlayer then marcaAliadoCache[targetPlayer] = nil end
end

local ATTRS_ALIADO = {
    "IsAlly","Ally","AllyMarker","isAlly","is_ally","ally",
    "Teammate","isTeammate","is_teammate","IsTeammate",
    "Friendly","isFriendly","IsFriendly","is_friendly"
}

local function tieneMarcaAliado(targetPlayer)
    if not targetPlayer then return false end
    local now = os.clock()
    local cached = marcaAliadoCache[targetPlayer]
    if cached and (now - cached.time) < MARCA_CACHE_TTL then return cached.value end

    local resultado = false
    local char = targetPlayer.Character

    for _, attrName in ipairs(ATTRS_ALIADO) do
        local v1 = targetPlayer:GetAttribute(attrName)
        if v1 == true or v1 == "true" or v1 == "Ally" or v1 == "ally" then resultado = true break end
        if char then
            local v2 = char:GetAttribute(attrName)
            if v2 == true or v2 == "true" or v2 == "Ally" or v2 == "ally" then resultado = true break end
        end
    end

    if not resultado then
        local myAttr = player:GetAttribute("Team") or player:GetAttribute("team")
        local otherAttr = targetPlayer:GetAttribute("Team") or targetPlayer:GetAttribute("team")
        if myAttr ~= nil and otherAttr ~= nil and myAttr ~= "" and otherAttr ~= "" and myAttr == otherAttr then
            resultado = true
        end
    end

    if not resultado and char then
        local head = char:FindFirstChild("Head")
        if head then
            for _, child in ipairs(head:GetChildren()) do
                if child:IsA("BillboardGui") and contenedorTieneVerde(child) then resultado = true break end
                if child:IsA("Highlight") and (esColorVerde(child.FillColor) or esColorVerde(child.OutlineColor)) then resultado = true break end
                if child:IsA("Attachment") and contenedorTieneVerde(child) then resultado = true break end
            end
        end
    end

    if not resultado and char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BillboardGui") and contenedorTieneVerde(child) then resultado = true break end
                if child:IsA("Attachment") and contenedorTieneVerde(child) then resultado = true break end
                if child:IsA("Highlight") and (esColorVerde(child.FillColor) or esColorVerde(child.OutlineColor)) then resultado = true break end
            end
        end
    end

    if not resultado and char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Highlight") and (esColorVerde(child.FillColor) or esColorVerde(child.OutlineColor)) then resultado = true break end
        end
    end

    if not resultado and char then
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if head and contenedorTieneVerde(head) then resultado = true end
        if not resultado and hrp and contenedorTieneVerde(hrp) then resultado = true end
    end

    marcaAliadoCache[targetPlayer] = { value = resultado, time = now }
    return resultado
end

local function isEnemy(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    if tieneMarcaAliado(targetPlayer) then return false end
    if not teamCheckEnabled then return true end

    local myColorName = player.TeamColor and player.TeamColor.Name or "White"
    local otherColorName = targetPlayer.TeamColor and targetPlayer.TeamColor.Name or "White"
    local myColorNeutral = COLORES_NEUTROS[myColorName] == true
    local otherColorNeutral = COLORES_NEUTROS[otherColorName] == true
    if not myColorNeutral and not otherColorNeutral then
        return player.TeamColor ~= targetPlayer.TeamColor
    end

    if player.Team ~= nil and targetPlayer.Team ~= nil then
        return player.Team ~= targetPlayer.Team
    end

    local myAttr = player:GetAttribute("Team") or player:GetAttribute("team")
    local otherAttr = targetPlayer:GetAttribute("Team") or targetPlayer:GetAttribute("team")
    if myAttr ~= nil and otherAttr ~= nil and myAttr ~= "" and otherAttr ~= "" then
        return myAttr ~= otherAttr
    end

    return true
end

local function estaEnLobby()
    local char = player.Character
    if not char then return true end
    if char:FindFirstChildOfClass("ForceField") then return true end
    if player.Team then
        local tName = string.lower(player.Team.Name)
        if string.find(tName, "lobby") or string.find(tName, "spectat") or string.find(tName, "espectador") or string.find(tName, "menu") or string.find(tName, "dead") then
            return true
        end
    end
    return false
end

local function IsInMatchStrict()
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return false end
    local main = gui:FindFirstChild("Main") or gui
    local gameFrame = main:FindFirstChild("MainGameFrame")
    if not gameFrame or not gameFrame.Visible then return false end
    local score = gameFrame:FindFirstChild("IngameScore")
    local timer = score and score:FindFirstChild("Timer")
    if not timer then return false end
    if not (timer:IsA("TextLabel") or timer:IsA("TextButton") or timer:IsA("TextBox")) then return false end
    local txt = tostring(timer.Text or ""):gsub("%s", "")
    if txt == "" or string.find(txt, "-") then return false end
    if txt == "0:00" or txt == "00:00" or txt == "0:0" then return false end
    return txt:match("^%d+:%d%d$") ~= nil
end

local function esEnemigoValido(targetPlayer)
    if not targetPlayer or targetPlayer == player then return false end
    if not isEnemy(targetPlayer) then return false end
    local char = targetPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if char:FindFirstChildOfClass("ForceField") then return false end
    if targetPlayer.Team then
        local tName = string.lower(targetPlayer.Team.Name)
        if string.find(tName, "lobby") or string.find(tName, "spectat") or string.find(tName, "espectador") or string.find(tName, "menu") or string.find(tName, "dead") then
            return false
        end
    end
    return true
end

local function esCuchillo(item)
    if not item or not item:IsA("Tool") then return false end
    if item:FindFirstChild("Slash") or item:FindFirstChild("SlashStart") then return true end
    local nombre = string.lower(item.Name)
    if string.find(nombre, "knife") or string.find(nombre, "cuchillo") or string.find(nombre, "dagger") then return true end
    return false
end

local function esPistola(item)
    if not item or not item:IsA("Tool") then return false end
    if item:FindFirstChild("Throw", true) or item:FindFirstChild("KnifeClient", true) or item:FindFirstChild("KnifeServer", true) then return false end
    if esCuchillo(item) then return false end
    local nombre = string.lower(item.Name)
    local ignorar = {"combat","fist","wallet","phone","punch","boombox","radio","knife","blade","cuchillo","dagger","kunai","sword","toy","juguete","pizza","burger","teddy","balloon","drink","food"}
    for _, palabra in ipairs(ignorar) do if string.find(nombre, palabra) then return false end end
    return true
end

local function obtenerPistola()
    local char = player.Character
    if not char then return nil end
    local backpack = player:FindFirstChildOfClass("Backpack")
    if char then for _, item in ipairs(char:GetChildren()) do if esPistola(item) then return item end end end
    if backpack then for _, item in ipairs(backpack:GetChildren()) do if esPistola(item) then return item end end end
    return nil
end

local function estaRecargando(arma)
    if not arma or not arma:IsA("Tool") then return false end
    for _, name in ipairs({"Reloading","IsReloading","reloading","isReloading","Reload","reload"}) do
        local v = arma:GetAttribute(name)
        if v == true or v == "true" then return true end
    end
    for _, child in ipairs(arma:GetChildren()) do
        if child:IsA("BoolValue") and child.Value == true then
            local n = string.lower(child.Name)
            if string.find(n, "reload") or string.find(n, "recarg") then return true end
        end
    end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local animId = track.Animation and track.Animation.AnimationId or ""
            if string.find(string.lower(animId), "reload") then return true end
        end
    end
    for _, s in ipairs(arma:GetDescendants()) do
        if s:IsA("Sound") and s.Playing then
            local n = string.lower(s.Name)
            if string.find(n, "reload") or string.find(n, "recarg") then return true end
        end
    end
    return false
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then
        p.CharacterAdded:Connect(function() invalidarMarcaAliado(p) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= player then p.CharacterAdded:Connect(function() invalidarMarcaAliado(p) end) end
end)
Players.PlayerRemoving:Connect(function(p) invalidarMarcaAliado(p) end)
player.CharacterAdded:Connect(function() for p in pairs(marcaAliadoCache) do marcaAliadoCache[p] = nil end end)

local Window = WindUI:CreateWindow({
    Title = "NEXVYRHUB | DUELS <font color='#FFD700'>[v2.8] </font>",
    Author = "By 7.dui🇲🇽",
    Folder = "Nexvyr_WindUI",
    Acrylic = false,
    Transparent = false,
    NewElements = true,
    HideSearchBar = false,
    Background = "rbxthumb://type=Asset&id=14653905878&w=420&h=420",
    BackgroundImageTransparency = 0.35,
    OpenButton = {
        Title = "Open HUB",
        Icon = "rbxthumb://type=Asset&id=118232139384203&w=420&h=420",
        IconSize = 9,
        CornerRadius = UDim.new(1),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Scale = 0.9,
        Color = ColorSequence.new(Color3.fromHex("#110070"), Color3.fromHex("#300364"))
    },
    Topbar = { Height = 44, ButtonsType = "Default" }
})

local MainSection = Window:Section({ Title = "Funciones Principales", Icon = "solar:star-bold", Opened = true })

local Tabs = {
    Aim = MainSection:Tab({ Title = "Aimbot", Icon = "solar:target-bold" }),
    Esp = MainSection:Tab({ Title = "ESP", Icon = "solar:eye-bold" }),
    Farm = MainSection:Tab({ Title = "Farm Evento", Icon = "solar:dollar-bold" }),
    Sonidos = MainSection:Tab({ Title = "Sonidos", Icon = "solar:speaker-bold" }),
}

Tabs.Aim:Section({ Title = "Auto Shoot", Icon = "solar:target-bold" })

UIElements.TogAutoShoot = Tabs.Aim:Toggle({
    Title = "Auto Shoot (Normal - Cabeza/Torso)",
    Desc = "Dispara automáticamente al torso o cabeza sin fallar.",
    Callback = function(Value)
        autoShootEnabled = Value
        if not Value and not autoShootAgresivoEnabled then getgenv().NexvyrTargetPart = nil end
    end
})

UIElements.TogAutoShootAgr = Tabs.Aim:Toggle({
    Title = "Auto Shoot (Agresivo - Hitbox Completa)",
    Desc = "Dispara a cualquier píxel visible del cuerpo del enemigo.",
    Callback = function(Value)
        autoShootAgresivoEnabled = Value
        if not Value and not autoShootEnabled then getgenv().NexvyrTargetPart = nil end
    end
})

UIElements.DropAutoShootPart = Tabs.Aim:Dropdown({
    Title = "Target: Parte del cuerpo",
    Values = { "Cabeza", "Torso", "Cuerpo Completo" },
    Value = "Cabeza",
    Callback = function(Value) autoShootTargetPart = Value end
})

local equipGunEnabled = false
UIElements.TogEquipGun = Tabs.Aim:Toggle({
    Title = "Equipar pistola",
    Desc = "Equipa rápidamente la pistola.",
    Value = false,
    Callback = function(Value) equipGunEnabled = Value end
})

task.spawn(function()
    local gunRayParams = RaycastParams.new()
    gunRayParams.FilterType = Enum.RaycastFilterType.Exclude

    while task.wait(0.1) do
        if not equipGunEnabled then continue end
        if not IsInMatchStrict() then continue end

        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not hrp then continue end
        local originPos = head and head.Position or hrp.Position

        local hayEnemigoVisible = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and esEnemigoValido(p) then
                local pChar = p.Character
                if pChar then
                    local targetPart = pChar:FindFirstChild("Head") or pChar:FindFirstChild("UpperTorso") or pChar:FindFirstChild("Torso") or pChar:FindFirstChild("HumanoidRootPart")
                    if targetPart and targetPart:IsA("BasePart") then
                        gunRayParams.FilterDescendantsInstances = { char, pChar }
                        local result = workspace:Raycast(originPos, targetPart.Position - originPos, gunRayParams)
                        if not result and IsInMatchStrict() then
                            hayEnemigoVisible = true
                            break
                        end
                    end
                end
            end
        end
        if not hayEnemigoVisible then continue end

        local pistola = obtenerPistola()
        if not pistola then continue end

        char = player.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum then continue end
        pistola = obtenerPistola()
        if not pistola then continue end

        if pistola.Parent ~= char then
            pcall(function() hum:EquipTool(pistola) end)
        end
        task.wait(0.35)

        char = player.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        if char and hum then pcall(function() hum:UnequipTools() end) end
        task.wait(1.9)
    end
end)

Tabs.Aim:Space(); Tabs.Aim:Divider(); Tabs.Aim:Space()
Tabs.Aim:Section({ Title = "Silent Aim + Fov", Icon = "solar:radar-bold" })

UIElements.TogSilentAimManual = Tabs.Aim:Toggle({
    Title = "Silent Aim",
    Desc = "Redirige las balas al enemigo.",
    Callback = function(Value)
        silentAimManualEnabled = Value
        if not Value and not autoShootEnabled and not autoShootAgresivoEnabled then getgenv().NexvyrTargetPart = nil end
    end
})

UIElements.DropSilentAimPart = Tabs.Aim:Dropdown({
    Title = "Target: Parte del cuerpo",
    Values = { "Cabeza", "Torso", "Cuerpo Completo" },
    Value = "Cabeza",
    Callback = function(Value) silentAimTargetPart = Value end
})

UIElements.TogSilentAimFOV = Tabs.Aim:Toggle({
    Title = "Silent Aim (Con FOV)",
    Desc = "Igual que el Silent Aim, pero solo afecta a los enemigos dentro del círculo.",
    Callback = function(Value)
        silentAimFovEnabled = Value
        if not Value and not silentAimManualEnabled and not autoShootEnabled and not autoShootAgresivoEnabled then getgenv().NexvyrTargetPart = nil end
    end
})

UIElements.TogShowFOV = Tabs.Aim:Toggle({
    Title = "Mostrar Círculo FOV",
    Desc = "Dibuja un círculo en pantalla.",
    Callback = function(Value) fovVisiblePreference = Value end
})

UIElements.SliFOVSize = Tabs.Aim:Slider({
    Title = "Tamaño del FOV",
    Step = 1,
    Value = { Min = 10, Max = 800, Default = 120 },
    Callback = function(v) fovRadius = v end
})

getgenv().NexvyrTargetPart = nil

local oldNamecall
if hookmetamethod and getnamecallmethod and checkcaller then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and getgenv().NexvyrTargetPart then
            if method == "Raycast" and self == workspace then
                local target = getgenv().NexvyrTargetPart
                if target and target.Parent then
                    local origin, direction, p3 = ...
                    if typeof(direction) == "Vector3" and direction.Magnitude > 20 then
                        local cameraOrigin = workspace.CurrentCamera.CFrame.Position
                        if (origin - cameraOrigin).Magnitude >= 1 then
                            local newDir = (target.Position - origin).Unit * 5000
                            return oldNamecall(self, origin, newDir, p3)
                        end
                    end
                else
                    getgenv().NexvyrTargetPart = nil
                end
            elseif self == workspace and typeof(method) == "string" and method:sub(1, 13) == "FindPartOnRay" then
                local target = getgenv().NexvyrTargetPart
                if target and target.Parent then
                    local ray, p2, p3, p4 = ...
                    if typeof(ray) == "Ray" and ray.Direction.Magnitude > 20 then
                        local cameraOrigin = workspace.CurrentCamera.CFrame.Position
                        if (ray.Origin - cameraOrigin).Magnitude >= 1 then
                            local newRay = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * 5000)
                            return oldNamecall(self, newRay, p2, p3, p4)
                        end
                    end
                else
                    getgenv().NexvyrTargetPart = nil
                end
            end
        end
        return oldNamecall(self, ...)
    end)
else
    warn("Hook de raycast no disponible en este entorno.")
end

task.spawn(function()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    while task.wait(0.1) do
        if (autoShootEnabled or autoShootAgresivoEnabled) and not estaEnLobby() then
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            local arma = char:FindFirstChildOfClass("Tool")
            if not arma or not arma:FindFirstChild("Handle") then
                getgenv().NexvyrTargetPart = nil
                continue
            end
            if esCuchillo(arma) then
                getgenv().NexvyrTargetPart = nil
                continue
            end
            local closestTargetPart = nil
            local shortestDistance = math.huge
            local myPos = char.HumanoidRootPart.Position
            local headPos = char:FindFirstChild("Head") and char.Head.Position or myPos
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and isEnemy(p) and p.Character then
                    local enemyHum = p.Character:FindFirstChild("Humanoid")
                    if enemyHum and enemyHum.Health > 0 then
                        params.FilterDescendantsInstances = { char, p.Character }
                        local function ProcesarParte(part)
                            local dist = (part.Position - myPos).Magnitude
                            if dist < shortestDistance then
                                local size = part.Size
                                local offsets = { Vector3.new(0,0,0), Vector3.new(0, size.Y/2.1, 0), Vector3.new(0, -size.Y/2.1, 0) }
                                local isVisible = false
                                for _, offset in ipairs(offsets) do
                                    if not workspace:Raycast(headPos, (part.CFrame * offset) - headPos, params) then isVisible = true break end
                                end
                                if isVisible then
                                    shortestDistance = dist
                                    closestTargetPart = part
                                end
                            end
                        end
                        if autoShootAgresivoEnabled then
                            for _, part in ipairs(p.Character:GetChildren()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then ProcesarParte(part) end
                            end
                        elseif autoShootTargetPart == "Cabeza" then
                            local head = p.Character:FindFirstChild("Head")
                            if head and head:IsA("BasePart") then ProcesarParte(head) end
                        elseif autoShootTargetPart == "Torso" then
                            for _, partName in ipairs({"UpperTorso","Torso","HumanoidRootPart"}) do
                                local part = p.Character:FindFirstChild(partName)
                                if part and part:IsA("BasePart") then ProcesarParte(part) end
                            end
                        elseif autoShootTargetPart == "Cuerpo Completo" then
                            for _, part in ipairs(p.Character:GetChildren()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then ProcesarParte(part) end
                            end
                        end
                    end
                end
            end
            if closestTargetPart then
                getgenv().NexvyrTargetPart = closestTargetPart
                pcall(function()
                    arma:Activate()
                    task.delay(0.05, function()
                        if arma.Parent == char then arma:Deactivate() end
                    end)
                end)
                task.wait(0.2)
            else
                getgenv().NexvyrTargetPart = nil
            end
        end
    end
end)

task.spawn(function()
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    while task.wait(0.1) do
        if (silentAimManualEnabled or silentAimFovEnabled) and not estaEnLobby() then
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
            local closestTargetPart = nil
            local shortestDistToCenter = math.huge
            local shortestDistanceFisica = math.huge
            local myPos = char.HumanoidRootPart.Position
            local headPos = char:FindFirstChild("Head") and char.Head.Position or myPos
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and isEnemy(p) and p.Character then
                    local enemyHum = p.Character:FindFirstChild("Humanoid")
                    if enemyHum and enemyHum.Health > 0 then
                        local partesAEscanear = {}
                        if silentAimTargetPart == "Cabeza" then
                            local head = p.Character:FindFirstChild("Head")
                            if head then table.insert(partesAEscanear, head) end
                        elseif silentAimTargetPart == "Torso" then
                            for _, partName in ipairs({"UpperTorso","Torso","HumanoidRootPart"}) do
                                local part = p.Character:FindFirstChild(partName)
                                if part and part:IsA("BasePart") then table.insert(partesAEscanear, part) end
                            end
                        elseif silentAimTargetPart == "Cuerpo Completo" then
                            for _, part in ipairs(p.Character:GetChildren()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then table.insert(partesAEscanear, part) end
                            end
                        end
                        params.FilterDescendantsInstances = { char, p.Character }
                        for _, part in ipairs(partesAEscanear) do
                            local distFisica = (part.Position - myPos).Magnitude
                            local pos2D, onScreen = camera:WorldToViewportPoint(part.Position)
                            local distToCenter = (Vector2.new(pos2D.X, pos2D.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                            local pasaFiltro = false
                            if silentAimFovEnabled then
                                if onScreen and distToCenter <= fovRadius and distToCenter < shortestDistToCenter then pasaFiltro = true end
                            elseif silentAimManualEnabled then
                                if distFisica < shortestDistanceFisica then pasaFiltro = true end
                            end
                            if pasaFiltro then
                                local raycastResult = workspace:Raycast(headPos, part.Position - headPos, params)
                                if not raycastResult then
                                    if silentAimFovEnabled then
                                        shortestDistToCenter = distToCenter; closestTargetPart = part
                                    else
                                        shortestDistanceFisica = distFisica; closestTargetPart = part
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if closestTargetPart then
                getgenv().NexvyrTargetPart = closestTargetPart
            else
                if not autoShootEnabled and not autoShootAgresivoEnabled then
                    getgenv().NexvyrTargetPart = nil
                end
            end
        end
    end
end)

Tabs.Esp:Section({ Title = "Configuración de ESP", Icon = "solar:eye-bold" })

UIElements.TogEsp = Tabs.Esp:Toggle({
    Title = "ESP Jugadores",
    Callback = function(s) espEnabled = s end
})

UIElements.ColEsp = Tabs.Esp:Colorpicker({
    Title = "Color del ESP",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) espColor = c end
})

Tabs.Esp:Space(); Tabs.Esp:Divider(); Tabs.Esp:Space()
Tabs.Esp:Section({ Title = "Filtros de ESP", Icon = "solar:filter-bold" })

UIElements.TogEspGl = Tabs.Esp:Toggle({
    Title = "Mostrar Resplandor",
    Value = true,
    Callback = function(s) espSettings.Glow = s end
})

local activeESPs = {}
local MAX_ESP_DISTANCE = 1500
local serverDeadCharacters = setmetatable({}, { __mode = "k" })

local function cleanESP(targetPlayer)
    if activeESPs[targetPlayer] then
        if activeESPs[targetPlayer].Highlight then activeESPs[targetPlayer].Highlight:Destroy() end
        activeESPs[targetPlayer] = nil
    end
end

local function WatchServerDeath(char)
    if not char then return end
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        if hum.Health <= 0 then
            serverDeadCharacters[char] = true
            local p = Players:GetPlayerFromCharacter(char)
            if p then cleanESP(p) end
            return
        end
        hum.Died:Connect(function()
            serverDeadCharacters[char] = true
            local p = Players:GetPlayerFromCharacter(char)
            if p then cleanESP(p) end
        end)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then
        if p.Character then WatchServerDeath(p.Character) end
        p.CharacterAdded:Connect(function(c) WatchServerDeath(c) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= player then
        if p.Character then WatchServerDeath(p.Character) end
        p.CharacterAdded:Connect(function(c) WatchServerDeath(c) end)
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if espEnabled and IsInMatchStrict() then
            local myChar = player.Character
            local myHead = myChar and myChar:FindFirstChild("Head")
            local myPos = myHead and myHead.Position
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player then
                    local char = p.Character
                    local serverConfirmedDead = char and serverDeadCharacters[char] == true
                    if char and not serverConfirmedDead and char:FindFirstChild("Head") and isEnemy(p) then
                        local targetHead = char.Head
                        local dist = myPos and (targetHead.Position - myPos).Magnitude or 0
                        if dist <= MAX_ESP_DISTANCE then
                            if activeESPs[p] and activeESPs[p].Char ~= char then cleanESP(p) end
                            if not activeESPs[p] then
                                local highlight = Instance.new("Highlight")
                                highlight.Name = p.Name .. "_Glow"
                                highlight.FillTransparency = 1
                                highlight.OutlineTransparency = 0
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                highlight.Adornee = char
                                highlight.Parent = espFolder
                                activeESPs[p] = { Highlight = highlight, Char = char }
                            end
                            local espObj = activeESPs[p]
                            if espObj.Highlight.Enabled ~= espSettings.Glow then espObj.Highlight.Enabled = espSettings.Glow end
                            if espObj.Highlight.OutlineColor ~= espColor then espObj.Highlight.OutlineColor = espColor end
                        else
                            cleanESP(p)
                        end
                    else
                        cleanESP(p)
                    end
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do cleanESP(p) end
        end
    end
end)

local FOVCircle = nil
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    FOVCircle.Radius = fovRadius
    FOVCircle.Filled = false
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Visible = false
    FOVCircle.Thickness = 1
end

RunService.RenderStepped:Connect(function()
    if fovVisiblePreference and FOVCircle then
        FOVCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        FOVCircle.Radius = fovRadius
        FOVCircle.Visible = true
        if silentAimFovEnabled and getgenv().NexvyrTargetPart then
            FOVCircle.Color = Color3.fromRGB(0, 255, 0)
        else
            FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        end
    elseif FOVCircle then
        FOVCircle.Visible = false
    end
end)

Players.PlayerRemoving:Connect(function(p) cleanESP(p) end)

Tabs.Farm:Section({ Title = "Farmeo de Evento", Icon = "solar:gift-bold" })

getgenv().AutoEventFarm = false
local Networking = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")
local RemoteFarm = Networking and Networking:FindFirstChild("RE/Events/CollectEventSpawnable")

Tabs.Farm:Toggle({
    Title = "Auto Farmear Evento",
    Callback = function(s)
        getgenv().AutoEventFarm = s
        if s then
            task.spawn(function()
                while getgenv().AutoEventFarm do
                    pcall(function()
                        if RemoteFarm then RemoteFarm:FireServer()
                        else
                            Networking = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")
                            RemoteFarm = Networking and Networking:FindFirstChild("RE/Events/CollectEventSpawnable")
                        end
                    end)
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local container = workspace:FindFirstChild("SpawnablesClient")
                        if container then
                            for _, obj in ipairs(container:GetChildren()) do
                                if not getgenv().AutoEventFarm then break end
                                local touchPart = obj:FindFirstChild("Touch")
                                if touchPart then
                                    pcall(function()
                                        firetouchinterest(hrp, touchPart, 0)
                                        firetouchinterest(hrp, touchPart, 1)
                                    end)
                                end
                            end
                        end
                    end
                    task.wait(0.05)
                end
            end)
        end
    end
})

local KillSoundEnabled = false
local RecargaDisparoEnabled = false
local SelectedKillSound = "Onichaaan"
local KillSoundVolume = 1

local KillSounds = {
    { Name = "Onichaaan",       Id = "114361503583259" },
    { Name = "Omagaaa",         Id = "4496966777" },
    { Name = "korummm",         Id = "119896940405402" },
    { Name = "FAAAH XD",        Id = "92076037937225" },
    { Name = "Campana meme",    Id = "107378927201728" },
    { Name = "Enrique",         Id = "100688006999379" },
    { Name = "Magia de anime",  Id = "109296938403067" },
    { Name = "Risa anime",      Id = "93739527256723" },
    { Name = "Gemido",          Id = "94981264286350" },
    { Name = "Magic 2",         Id = "100507897550384" },
    { Name = "OwO",             Id = "71942674274967" },
    { Name = "SEMPAI >.<",      Id = "115498703521334" },
    { Name = "Ahhh:3",          Id = "83559496188823" },
    { Name = "ñyaa >//~//<",    Id = "78798011197804" },
}

local KillSoundPlayer = Instance.new("Sound")
KillSoundPlayer.Name = "NexvyrKillSound"
KillSoundPlayer.Volume = 1
KillSoundPlayer.Looped = false
KillSoundPlayer.Parent = SoundService

local ShootReloadOptions = {
    ["Revolver + Recarga"]     = { Shoot = "680140087",       Reload = "138084889" },
    ["Magia de Anime"]         = { Shoot = "109296938403067", Reload = nil },
    ["Láser + Recarga láser"]  = { Shoot = "4400449399",      Reload = "129456040607483" },
}
local SelectedShootReload = "Revolver + Recarga"

local SHOOT_SOUND_MAX_DURATION = 1.5
local shootSoundToken = 0
local lastShootSoundTime = 0
local SHOOT_SOUND_MIN_INTERVAL = 0.05

local ShootSoundPlayer = Instance.new("Sound")
ShootSoundPlayer.Name = "NexvyrShootSound"
ShootSoundPlayer.Volume = 1
ShootSoundPlayer.Looped = false
ShootSoundPlayer.Parent = SoundService

local ReloadSoundPlayer = Instance.new("Sound")
ReloadSoundPlayer.Name = "NexvyrReloadSound"
ReloadSoundPlayer.Volume = 1
ReloadSoundPlayer.Looped = false
ReloadSoundPlayer.Parent = SoundService

local function PlayShootSound()
    if not RecargaDisparoEnabled then return end
    local cfg = ShootReloadOptions[SelectedShootReload]
    if not cfg or not cfg.Shoot then return end
    local now = tick()
    if now - lastShootSoundTime < SHOOT_SOUND_MIN_INTERVAL then return end
    lastShootSoundTime = now
    shootSoundToken = shootSoundToken + 1
    local myToken = shootSoundToken
    ShootSoundPlayer:Stop()
    ShootSoundPlayer.SoundId = "rbxassetid://" .. cfg.Shoot
    ShootSoundPlayer.Volume = KillSoundVolume
    ShootSoundPlayer:Play()
    task.delay(SHOOT_SOUND_MAX_DURATION, function()
        if shootSoundToken == myToken and ShootSoundPlayer.Playing then
            ShootSoundPlayer:Stop()
        end
    end)
end

local function PlayReloadSound()
    if not RecargaDisparoEnabled then return end
    local cfg = ShootReloadOptions[SelectedShootReload]
    if not cfg or not cfg.Reload then return end
    ReloadSoundPlayer:Stop()
    ReloadSoundPlayer.SoundId = "rbxassetid://" .. cfg.Reload
    ReloadSoundPlayer.Volume = KillSoundVolume
    ReloadSoundPlayer:Play()
end

local FIRE_SOUND_KEYWORDS = {
    "fire","shoot","shot","gun","burst","shotgun","gunshot","muzzle","rifle","pistol","shooting","firing"
}

local function isFireSound(s)
    if not s:IsA("Sound") then return false end
    local n = string.lower(s.Name)
    for _, kw in ipairs(FIRE_SOUND_KEYWORDS) do
        if string.find(n, kw, 1, true) then return true end
    end
    return false
end

local function HookFireSound(s)
    if not s:IsA("Sound") then return end
    if not isFireSound(s) then return end
    if s:GetAttribute("NexvyrFireHooked") then return end
    s:SetAttribute("NexvyrFireHooked", true)
    s.Played:Connect(function()
        if not RecargaDisparoEnabled then return end
        local char = player.Character
        if not char then return end
        if s:IsDescendantOf(char) or s:IsDescendantOf(player:FindFirstChildOfClass("Backpack") or char) then
            PlayShootSound()
        end
    end)
end

local function HookShootOnTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    for _, d in ipairs(tool:GetDescendants()) do HookFireSound(d) end
    if not tool:GetAttribute("NexvyrToolHooked") then
        tool:SetAttribute("NexvyrToolHooked", true)
        tool.DescendantAdded:Connect(HookFireSound)
    end
end

local function HookShootOnRoot(root)
    if not root then return end
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("Tool") then HookShootOnTool(child) end
    end
    root.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then HookShootOnTool(child) end
    end)
end

task.spawn(function()
    local lastReloadState = false
    while task.wait(0.05) do
        if not RecargaDisparoEnabled then lastReloadState = false continue end
        local char = player.Character
        if not char then lastReloadState = false continue end
        local arma = char:FindFirstChildOfClass("Tool")
        if not arma or esCuchillo(arma) then lastReloadState = false continue end
        local recargando = estaRecargando(arma)
        if recargando and not lastReloadState then PlayReloadSound() end
        lastReloadState = recargando
    end
end)

local function GetKillSoundIdByName(soundName)
    for _, s in ipairs(KillSounds) do
        if s.Name == soundName then return s.Id end
    end
    return KillSounds[1].Id
end

local function PlayKillSound()
    if not KillSoundEnabled then return end
    KillSoundPlayer:Stop()
    KillSoundPlayer.SoundId = "rbxassetid://" .. GetKillSoundIdByName(SelectedKillSound)
    KillSoundPlayer.Volume = KillSoundVolume
    KillSoundPlayer:Play()
end

local lastKillSoundTime = 0
local KILL_SOUND_COOLDOWN = 0.08
local function TryPlayKillSound()
    if not KillSoundEnabled then return end
    local now = tick()
    if now - lastKillSoundTime < KILL_SOUND_COOLDOWN then return end
    lastKillSoundTime = now
    PlayKillSound()
end

local KILL_STAT_NAMES = { kos = true, kills = true, kill = true, ko = true, killed = true, eliminations = true, kills_count = true }

local function HookStatValue(stat)
    if not stat then return end
    if not (stat:IsA("IntValue") or stat:IsA("NumberValue")) then return end
    if not KILL_STAT_NAMES[string.lower(stat.Name)] then return end
    if stat:GetAttribute("NexvyrKOHooked") then return end
    stat:SetAttribute("NexvyrKOHooked", true)
    local lastVal = stat.Value
    stat:GetPropertyChangedSignal("Value"):Connect(function()
        if stat.Value > lastVal then TryPlayKillSound() end
        lastVal = stat.Value
    end)
end

local function HookLeaderstatsContainer(container)
    if not container then return end
    for _, stat in ipairs(container:GetChildren()) do HookStatValue(stat) end
    container.ChildAdded:Connect(HookStatValue)
end

local KILL_ATTR_NAMES = {"KOs","Kills","kos","kills","KO","killed","Eliminations"}
for _, attrName in ipairs(KILL_ATTR_NAMES) do
    local lastVal = tonumber(player:GetAttribute(attrName))
    player:GetAttributeChangedSignal(attrName):Connect(function()
        local newVal = tonumber(player:GetAttribute(attrName))
        if newVal ~= nil and lastVal ~= nil and newVal > lastVal then TryPlayKillSound() end
        lastVal = newVal
    end)
end

if player:FindFirstChild("leaderstats") then HookLeaderstatsContainer(player:FindFirstChild("leaderstats")) end
for _, containerName in ipairs({"Stats","stats","PlayerStats"}) do
    local cont = player:FindFirstChild(containerName)
    if cont then HookLeaderstatsContainer(cont) end
end
player.ChildAdded:Connect(function(child)
    if child.Name == "leaderstats" then HookLeaderstatsContainer(child) end
    for _, containerName in ipairs({"Stats","stats","PlayerStats"}) do
        if child.Name == containerName then HookLeaderstatsContainer(child) end
    end
end)

local function HookKillOnCharacter(targetPlayer, character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    humanoid.Died:Connect(function()
        if not KillSoundEnabled then return end
        local tag = humanoid:FindFirstChild("creator")
        if tag and tag.Value == player then TryPlayKillSound() end
    end)
end

local function HookKillPlayer(targetPlayer)
    if targetPlayer == player then return end
    if targetPlayer.Character then task.spawn(HookKillOnCharacter, targetPlayer, targetPlayer.Character) end
    targetPlayer.CharacterAdded:Connect(function(c) HookKillOnCharacter(targetPlayer, c) end)
end

for _, p in ipairs(Players:GetPlayers()) do HookKillPlayer(p) end
Players.PlayerAdded:Connect(HookKillPlayer)

local OriginalGunVolumes = {}
local HookedGunSounds = setmetatable({}, { __mode = "k" })

local function MuteOwnSound(s)
    if not s:IsA("Sound") then return end
    if s.Name == "NexvyrKillSound" or s.Name == "WindUI_MusicPlayer" or s.Name == "NexvyrShootSound" or s.Name == "NexvyrReloadSound" then return end
    if OriginalGunVolumes[s] == nil and s.Volume > 0 then OriginalGunVolumes[s] = s.Volume end
    if RecargaDisparoEnabled then s.Volume = 0 end
    if not HookedGunSounds[s] then
        HookedGunSounds[s] = true
        s:GetPropertyChangedSignal("Volume"):Connect(function()
            if RecargaDisparoEnabled and s.Volume ~= 0 then
                OriginalGunVolumes[s] = s.Volume
                s.Volume = 0
            end
        end)
        s.Played:Connect(function()
            if RecargaDisparoEnabled then s.Volume = 0 end
        end)
    end
end

local function HookOwnRoot(root)
    if not root then return end
    for _, d in ipairs(root:GetDescendants()) do MuteOwnSound(d) end
    root.DescendantAdded:Connect(MuteOwnSound)
end

local function ApplyMuteState(state)
    if state then
        for s in pairs(OriginalGunVolumes) do
            if s.Parent then s.Volume = 0 end
        end
        if player.Character then
            for _, d in ipairs(player.Character:GetDescendants()) do MuteOwnSound(d) end
        end
        local backpack = player:FindFirstChildOfClass("Backpack")
        if backpack then
            for _, d in ipairs(backpack:GetDescendants()) do MuteOwnSound(d) end
        end
    else
        for s, v in pairs(OriginalGunVolumes) do
            if s.Parent then s.Volume = v end
        end
    end
end

if player.Character then
    HookOwnRoot(player.Character)
    HookShootOnRoot(player.Character)
end
if player:FindFirstChildOfClass("Backpack") then
    HookOwnRoot(player:FindFirstChildOfClass("Backpack"))
    HookShootOnRoot(player:FindFirstChildOfClass("Backpack"))
end
player.CharacterAdded:Connect(function(c)
    HookOwnRoot(c)
    HookShootOnRoot(c)
    local bp = player:WaitForChild("Backpack", 5)
    if bp then
        HookOwnRoot(bp)
        HookShootOnRoot(bp)
    end
    task.wait(2)
    if RecargaDisparoEnabled then ApplyMuteState(true) end
end)

Tabs.Sonidos:Section({ Title = "Seleccionar sonido de muerte", Icon = "solar:speaker-bold" })

Tabs.Sonidos:Toggle({
    Title = "Sonido de Kill",
    Desc = "Reproduce un efecto cuando matas a un enemigo.",
    Value = false,
    Callback = function(v)
        KillSoundEnabled = v
        if not v then KillSoundPlayer:Stop() end
    end
})

local KillSoundDropdownValues = {}
for _, s in ipairs(KillSounds) do table.insert(KillSoundDropdownValues, s.Name) end

Tabs.Sonidos:Dropdown({
    Title = "Sonido de muerte",
    Desc = "Elige el efecto que suena al matar.",
    Values = KillSoundDropdownValues,
    Value = "Onichaaan",
    Callback = function(selected) SelectedKillSound = selected end
})

Tabs.Sonidos:Section({ Title = "Sonido de Disparo y Recarga", Icon = "solar:target-bold" })

Tabs.Sonidos:Toggle({
    Title = "Recarga + disparo",
    Desc = "Sonidos cambiados.",
    Value = false,
    Callback = function(v)
        RecargaDisparoEnabled = v
        if not v then
            ShootSoundPlayer:Stop()
            ReloadSoundPlayer:Stop()
        end
        ApplyMuteState(v)
    end
})

Tabs.Sonidos:Dropdown({
    Title = "Seleccionar sonido de disparo",
    Desc = "Elige el efecto que suena al disparar (y recargar si aplica).",
    Values = { "Revolver + Recarga", "Magia de Anime", "Láser + Recarga láser" },
    Value = "Revolver + Recarga",
    Callback = function(selected) SelectedShootReload = selected end
})

Tabs.Sonidos:Slider({
    Title = "Volumen del Sonido",
    Desc = "Ajusta qué tan fuerte suena el sonido al matar.",
    Step = 0.1,
    Value = { Min = 1, Max = 3, Default = 1 },
    Callback = function(v)
        KillSoundVolume = v
        KillSoundPlayer.Volume = v
        ShootSoundPlayer.Volume = v
        ReloadSoundPlayer.Volume = v
    end
})
