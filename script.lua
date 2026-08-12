-- AIMDEX V9 - ESP Jarvis com FOV NO CENTRO EXATO (SCRIPT COMPLETO)
local success, err = pcall(function()

local Rayfield
local ok, result = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if ok and result then
    Rayfield = result
else
    ok, result = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
    if ok and result then Rayfield = result end
end

if not Rayfield then
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Erro", Text="Não foi possível carregar o painel.", Duration=5})
    return
end

local Window = Rayfield:CreateWindow({
    Name = "AIMDEX V9",
    LoadingTitle = "AIMDEX V9",
    LoadingSubtitle = "Bernardo Pereira Carvalho",
    TouchCompatible = true
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Variáveis
local aimbot = false
local aimassist = false
local showfov = false
local spin = false
local fov = 150
local spinspeed = 10
local esp = false
local tracer = false
local espcolor = Color3.fromRGB(255,255,255)
local noclip = false

-- Pasta organizadora
local ESP_Folder = Instance.new("Folder")
ESP_Folder.Name = "AIMDEX_ESP_System"
pcall(function() ESP_Folder.Parent = game.CoreGui end)
if not ESP_Folder.Parent then
    ESP_Folder.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local TracerGui = Instance.new("ScreenGui")
TracerGui.Name = "Tracers"
TracerGui.Parent = ESP_Folder
TracerGui.IgnoreGuiInset = true

-- Altura desejada da barra de vida em studs (mesmo tamanho do boneco)
local BAR_WORLD_HEIGHT = 5

local espObjects = {}

local function criarESP(player)
    if player == LocalPlayer then return end

    -- Limpa ESP anterior
    if espObjects[player] then
        local obj = espObjects[player]
        if obj.connection then obj.connection:Disconnect() end
        if obj.highlight then obj.highlight:Destroy() end
        if obj.billboardInfo then obj.billboardInfo:Destroy() end
        if obj.billboardHealth then obj.billboardHealth:Destroy() end
        if obj.tracerLine then obj.tracerLine:Destroy() end
        espObjects[player] = nil
    end

    -- Highlight (contorno)
    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name .. "_Highlight"
    highlight.FillTransparency = 1
    highlight.OutlineColor = espcolor
    highlight.OutlineTransparency = 0
    highlight.Enabled = esp
    highlight.Parent = ESP_Folder

    -- Billboard de informações (nome + distância)
    local billboardInfo = Instance.new("BillboardGui")
    billboardInfo.Name = player.Name .. "_Info"
    billboardInfo.Size = UDim2.new(0, 200, 0, 48)      -- largura x altura
    billboardInfo.StudsOffset = Vector3.new(0, 2.5, 0) -- acima da cabeça
    billboardInfo.AlwaysOnTop = true
    billboardInfo.MaxDistance = 2000
    billboardInfo.Enabled = false
    billboardInfo.Parent = ESP_Folder

    local nameLabel = Instance.new("TextLabel", billboardInfo)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = espcolor
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextSize = 14
    nameLabel.TextScaled = false
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local distLabel = Instance.new("TextLabel", billboardInfo)
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = espcolor
    distLabel.Font = Enum.Font.Code
    distLabel.TextSize = 14
    distLabel.TextScaled = false
    distLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- Billboard da barra de vida (tamanho adaptável)
    local billboardHealth = Instance.new("BillboardGui")
    billboardHealth.Name = player.Name .. "_HealthBar"
    billboardHealth.AlwaysOnTop = true
    billboardHealth.MaxDistance = 2000
    billboardHealth.Enabled = false
    billboardHealth.Parent = ESP_Folder

    local healthBg = Instance.new("Frame", billboardHealth)
    healthBg.Name = "HealthBg"
    healthBg.Size = UDim2.new(1, 0, 1, 0)           -- preencherá todo o billboard
    healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBg.BorderSizePixel = 0

    local healthBar = Instance.new("Frame", healthBg)
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)          -- será ajustado via script
    healthBar.Position = UDim2.new(0, 0, 1, 0)      -- ancora no fundo
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.AnchorPoint = Vector2.new(0, 1)       -- cresce para cima

    -- Linha tracer
    local tracerLine = Instance.new("Frame")
    tracerLine.Name = "TracerLine"                  -- nome para identificação
    tracerLine.AnchorPoint = Vector2.new(0.5, 0.5)
    tracerLine.BackgroundColor3 = espcolor
    tracerLine.BorderSizePixel = 0
    tracerLine.Parent = TracerGui

    -- Atualização contínua
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            local hrp = character.HumanoidRootPart
            local humanoid = character.Humanoid
            local head = character:FindFirstChild("Head") or hrp

            billboardInfo.Adornee = head
            billboardHealth.Adornee = head
            highlight.Parent = character

            -- Calcula tamanho visual da barra (proporcional ao jogador)
            local barBottom = head.Position
            local barTop = head.Position + Vector3.new(0, BAR_WORLD_HEIGHT, 0)
            local screenBottom, onBottom = Camera:WorldToViewportPoint(barBottom)
            local screenTop, onTop = Camera:WorldToViewportPoint(barTop)
            if onBottom and onTop then
                local barPixelHeight = math.abs(screenTop.Y - screenBottom.Y)
                billboardHealth.Size = UDim2.new(0, 4, 0, math.max(barPixelHeight, 1))
                -- Ajusta offset para centralizar a barra no boneco
                billboardHealth.StudsOffset = Vector3.new(1.5, -BAR_WORLD_HEIGHT/2, 0)
            end

            -- Atualiza barra de vida
            local healthPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            healthBar.Size = UDim2.new(1, 0, healthPct, 0)
            healthBar.BackgroundColor3 = Color3.new(1 - healthPct, healthPct, 0)

            -- Distância
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                distLabel.Text = dist .. " studs"
            end

            -- Visibilidade geral (Master ESP)
            highlight.Enabled = esp
            billboardInfo.Enabled = esp
            billboardHealth.Enabled = esp
            highlight.OutlineColor = espcolor
            nameLabel.TextColor3 = espcolor
            distLabel.TextColor3 = espcolor

            -- Tracers
            if tracer and esp then
                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    tracerLine.Visible = true
                    local bottomCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local targetPos = Vector2.new(vector.X, vector.Y)
                    local distance = (bottomCenter - targetPos).Magnitude
                    tracerLine.Size = UDim2.new(0, 2, 0, distance)
                    local center = (bottomCenter + targetPos) / 2
                    tracerLine.Position = UDim2.new(0, center.X, 0, center.Y)
                    local angle = math.atan2(targetPos.Y - bottomCenter.Y, targetPos.X - bottomCenter.X)
                    tracerLine.Rotation = math.deg(angle) + 90
                else
                    tracerLine.Visible = false
                end
            else
                tracerLine.Visible = false
            end
        else
            billboardInfo.Adornee = nil
            billboardHealth.Adornee = nil
            highlight.Parent = ESP_Folder
            tracerLine.Visible = false
        end
    end)

    espObjects[player] = {
        highlight = highlight,
        billboardInfo = billboardInfo,
        billboardHealth = billboardHealth,
        tracerLine = tracerLine,
        connection = connection
    }
end

-- Inicializa jogadores existentes
for _, player in ipairs(Players:GetPlayers()) do criarESP(player) end
Players.PlayerAdded:Connect(criarESP)
Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] then
        local obj = espObjects[player]
        if obj.connection then obj.connection:Disconnect() end
        if obj.highlight then obj.highlight:Destroy() end
        if obj.billboardInfo then obj.billboardInfo:Destroy() end
        if obj.billboardHealth then obj.billboardHealth:Destroy() end
        if obj.tracerLine then obj.tracerLine:Destroy() end
        espObjects[player] = nil
    end
end)

-- Círculo de FOV
local fovGui = Instance.new("ScreenGui", game.CoreGui)
local fovCircle = Instance.new("Frame", fovGui)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
local uiCorner = Instance.new("UICorner", fovCircle)
uiCorner.CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = Color3.new(1,1,1)
fovStroke.Thickness = 1
fovStroke.Transparency = 0.3

-- Funções auxiliares
local function toScreen(pos)
    local v, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), v.Z > 0
end

local function isTargetVisible(head)
    local camPos = Camera.CFrame.Position
    local targetPos = head.Position
    local dir = (targetPos - camPos).Unit
    local dist = (targetPos - camPos).Magnitude - 0.1
    local ignoreList = { LocalPlayer.Character, head.Parent }
    local hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(camPos, dir * dist), ignoreList)
    return hit == nil
end

-- Loop principal
RunService.RenderStepped:Connect(function(delta)
    if aimbot or aimassist then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local closest = nil
            local minDist = fov
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    local head = p.Character.Head
                    local pos, on = toScreen(head.Position)
                    if on then
                        local d = (Vector2.new(pos.X, pos.Y) - Camera.ViewportSize/2).Magnitude
                        if d < minDist and isTargetVisible(head) then
                            minDist = d
                            closest = head
                        end
                    end
                end
            end
            if closest then
                local targetPos = closest.Position
                if aimbot then Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
                elseif aimassist then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), 0.3) end
            end
        end
    end

    if spin then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                if hum.AutoRotate then hum.AutoRotate = false end
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinspeed * 60 * delta), 0)
            end
        end
    else
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and not hum.AutoRotate then hum.AutoRotate = true end
        end
    end

    if showfov then
        local diameter = fov * 2
        fovCircle.Size = UDim2.new(0, diameter, 0, diameter)
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

RunService.Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end)

-- Interface
local t1 = Window:CreateTab("⚔️ Combate")
t1:CreateToggle({Name="AIMBOT Principal", Callback=function(v) aimbot=v end})
t1:CreateToggle({Name="Assistência de Mira (Aim)", Callback=function(v) aimassist=v end})
t1:CreateSlider({Name="FOV do Aimbot", Range={0,300}, Increment=1, Suffix=" studs", CurrentValue=150, Callback=function(v) fov=v end})
t1:CreateToggle({Name="Mostrar FOV", Callback=function(v) showfov=v end})
t1:CreateToggle({Name="Spin Bot (Giro)", Callback=function(v) spin=v end})
t1:CreateSlider({Name="Velocidade do Spin", Range={1,50}, Increment=1, Suffix="x", CurrentValue=10, Callback=function(v) spinspeed=v end})

local t2 = Window:CreateTab("👁️ Visuais")
t2:CreateToggle({Name="Master ESP", Callback=function(v) esp=v end})
t2:CreateToggle({Name="ESP Tracer (Linhas)", Callback=function(v) tracer=v end})
t2:CreateColorPicker({Name="Cor do ESP", Color=espcolor, Callback=function(v) 
    espcolor=v 
    -- Atualiza contornos e textos já existentes
    for _, obj in pairs(ESP_Folder:GetDescendants()) do
        if obj:IsA("Highlight") then obj.OutlineColor = v end
        if obj:IsA("TextLabel") then obj.TextColor3 = v end
    end
    -- Atualiza todas as linhas tracer (dentro do TracerGui)
    for _, line in pairs(TracerGui:GetDescendants()) do
        if line:IsA("Frame") and line.Name == "TracerLine" then
            line.BackgroundColor3 = v
        end
    end
end})

local t3 = Window:CreateTab("🏃 Movimentação")
t3:CreateToggle({Name="Noclip", Callback=function(v) noclip=v end})
t3:CreateButton({Name="Ajustar Colisão", Callback=function()
    if not noclip then Rayfield:Notify({Title="Aviso", Content="Ative o Noclip primeiro.", Duration=3}) return end
    if LocalPlayer.Character then for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
    Rayfield:Notify({Title="OK", Content="Colisão ajustada.", Duration=2})
end})

-- SEÇÃO ADICIONADA SEPARADAMENTE (LIMITES CORRIGIDOS)
local customSpeed = 16
local customJump = 50
local infJumpEnabled = false

t3:CreateSlider({
    Name = "Velocidade (Speed)",
    Range = {16, 400},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        customSpeed = v
    end
})

t3:CreateSlider({
    Name = "Força do Pulo (Jump Power)",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        customJump = v
    end
})

t3:CreateToggle({
    Name = "Pulo Infinito (Infinite Jump)",
    Callback = function(v)
        infJumpEnabled = v
    end
})

RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = customSpeed
        LocalPlayer.Character.Humanoid.JumpPower = customJump
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local t4 = Window:CreateTab("⚙️ Sistema & IA")
t4:CreateButton({Name="Modo Rápido (Fast Mode)", Callback=function()
    pcall(function()
        local l = game:GetService("Lighting"); l.GlobalShadows=false; l.Brightness=2
        for _, v in ipairs(l:GetChildren()) do if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") then v.Enabled=false end end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled=false end
            if v:IsA("BasePart") and v.Material~=Enum.Material.SmoothPlastic then v.Material=Enum.Material.SmoothPlastic end
        end
    end)
    Rayfield:Notify({Title="Fast Mode", Content="Otimização aplicada.", Duration=3})
end})
t4:CreateButton({Name="MODO IA DEX", Callback=function()
    pcall(function()
        collectgarbage()
        local l = game:GetService("Lighting"); l.GlobalShadows=false; l.Brightness=2; l.FogEnd=10000; l.ClockTime=14
        l.Ambient=Color3.new(1,1,1); l.OutdoorAmbient=Color3.new(1,1,1)
        for _, v in ipairs(l:GetChildren()) do if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then v.Enabled=false end end
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end
            if v:IsA("BasePart") then v.Material=Enum.Material.SmoothPlastic end
            if v:IsA("Decal") or v:IsA("Texture") then v.Transparency=1 end
        end
    end)
    Rayfield:Notify({Title="IA DEX Ativado", Content="Otimização máxima estabelecida, senhor.", Duration=4})
end})

-- Monitor de FPS/Ping
local fpsGui = Instance.new("ScreenGui", game.CoreGui)
local fpsFrame = Instance.new("Frame", fpsGui)
fpsFrame.Size = UDim2.new(0,120,0,24)
fpsFrame.Position = UDim2.new(1,-130,0,10)
fpsFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
fpsFrame.BackgroundTransparency = 0.4
fpsFrame.BorderSizePixel = 0
Instance.new("UIStroke", fpsFrame).Color = Color3.fromRGB(255,255,255)
fpsFrame.UIStroke.Thickness = 1
fpsFrame.UIStroke.Transparency = 0.7
local fpsLabel = Instance.new("TextLabel", fpsFrame)
fpsLabel.Size = UDim2.new(1,-4,1,0)
fpsLabel.Position = UDim2.new(0,2,0,0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.TextColor3 = Color3.fromRGB(255,255,255)
fpsLabel.Font = Enum.Font.Code
fpsLabel.TextSize = 12
fpsLabel.TextXAlignment = Enum.TextXAlignment.Center
fpsLabel.Text = "FPS: -- | Ping: --"
fpsFrame.Visible = false
t4:CreateToggle({Name="Monitor de FPS", Callback=function(v) fpsFrame.Visible=v end})
local fc, tt = 0, 0
RunService.Heartbeat:Connect(function(delta)
    fc = fc + 1; tt = tt + delta
    if tt >= 0.5 then
        local fps = math.floor(fc / tt)
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        fpsLabel.Text = string.format("FPS: %d | Ping: %d ms", fps, ping)
        fc, tt = 0, 0
    end
end)

Rayfield:Notify({Title="AIMDEX V9", Content="AIMDEX V9 CRIADO POR BERNARDO PEREIRA CARVALHO EMPRESA DEX.", Duration=5})

end)

if not success then
    warn("Erro: "..tostring(err))
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Erro AIMDEX", Text=tostring(err), Duration=10})
end

