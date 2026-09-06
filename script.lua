--// AlignPosition 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    STOP_DISTANCE = 1,
    PULL_SPEED = 80,
    MAX_DISTANCE = 500,
    TEMPO_LIMITE = 2,
    TAG_LOBO = "WolfTag"
}

local puxando = false
local conn = nil
local alignPosition = nil
local attachment0 = nil
local tempoInicio = 0

--// ============================================
--// FUNÇÃO: VERIFICA SE É LOBO
--// ============================================

local function isWolf()
    local char = LocalPlayer.Character
    if not char then return false end
    local wolfTag = char:FindFirstChild(CONFIG.TAG_LOBO, true)
    return wolfTag ~= nil
end

--// ============================================
--// INTERFACE
--// ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AlignPullTimer"
screenGui.Parent = CoreGui
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 80)
frame.Position = UDim2.new(0, 20, 0, 300)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- TÍTULO
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(150, 150, 180)
title.Text = "Nearest Player"
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame

-- BOTÃO
local pullBtn = Instance.new("TextButton")
pullBtn.Size = UDim2.new(0.85, 0, 0, 38)
pullBtn.Position = UDim2.new(0.075, 0, 0.35, 0)
pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pullBtn.Text = "▶ To Pull"
pullBtn.Font = Enum.Font.GothamBold
pullBtn.TextSize = 15
pullBtn.BorderSizePixel = 0
pullBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = pullBtn

--// ============================================
--// UTILS
--// ============================================

local function getCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

local function getNearestPlayer()
    local _, hrp, _ = getCharacter()
    if not hrp then return nil end

    local nearest = nil
    local minDist = CONFIG.MAX_DISTANCE

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char then continue end

        local otherHrp = char:FindFirstChild("HumanoidRootPart")
        local otherHum = char:FindFirstChildOfClass("Humanoid")
        if not otherHrp or not otherHum then continue end
        if otherHum.Health <= 0 then continue end

        local dist = (otherHrp.Position - hrp.Position).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = player
        end
    end

    return nearest
end

local function cleanup()
    puxando = false
    tempoInicio = 0

    if conn then
        conn:Disconnect()
        conn = nil
    end

    if alignPosition then
        alignPosition:Destroy()
        alignPosition = nil
    end

    if attachment0 then
        attachment0:Destroy()
        attachment0 = nil
    end

    if isWolf() then
        pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
        pullBtn.Text = "To Pull"
        pullBtn.Active = true
        pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        pullBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        pullBtn.Text = "🔒 BLOQUEADO"
        pullBtn.Active = false
        pullBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function atualizarUI(estado, tempoRestante)
    if estado then
        pullBtn.Text = "⏹ " .. string.format("%.1f", tempoRestante) .. "s"
        pullBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    else
        if isWolf() then
            pullBtn.Text = "To Pull"
            pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
            pullBtn.Active = true
            pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            pullBtn.Text = "🔒 BLOQUEADO"
            pullBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            pullBtn.Active = false
            pullBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

--// ============================================
--// PULL COM TIMER (SÓ LOBO)
--// ============================================

local function pullToNearest()
    if puxando then return end
    
    if not isWolf() then
        pullBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        pullBtn.Text = "🔒 BLOQUEADO"
        pullBtn.Active = false
        pullBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        return
    end

    local char, hrp, hum = getCharacter()
    if not hrp or not hum then
        warn("❌ Personagem não encontrado")
        return
    end

    local target = getNearestPlayer()
    if not target or not target.Character then
        pullBtn.Text = "❌ SEM ALVO"
        task.delay(0.8, function()
            if not puxando and isWolf() then
                pullBtn.Text = "To Pull"
            end
        end)
        return
    end

    local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then
        pullBtn.Text = "❌ ALVO INVÁLIDO"
        task.delay(0.8, function()
            if not puxando and isWolf() then
                pullBtn.Text = "To Pull"
            end
        end)
        return
    end

    puxando = true
    tempoInicio = os.clock()

    attachment0 = Instance.new("Attachment")
    attachment0.Name = "AlignPullAtt"
    attachment0.Parent = hrp

    alignPosition = Instance.new("AlignPosition")
    alignPosition.Name = "AlignPull"
    alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPosition.Attachment0 = attachment0
    alignPosition.Position = targetHrp.Position
    alignPosition.RigidityEnabled = false
    alignPosition.Responsiveness = CONFIG.PULL_SPEED
    alignPosition.MaxForce = math.huge
    alignPosition.Parent = hrp

    local targetCache = target

    conn = RunService.Heartbeat:Connect(function()
        if not puxando then
            cleanup()
            return
        end

        if not isWolf() then
            cleanup()
            pullBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            pullBtn.Text = "🔒 BLOQUEADO"
            pullBtn.Active = false
            pullBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            return
        end

        local tempoDecorrido = os.clock() - tempoInicio
        local tempoRestante = CONFIG.TEMPO_LIMITE - tempoDecorrido

        if tempoRestante <= 0 then
            cleanup()
            pullBtn.Text = "⏰ FIM"
            pullBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
            task.delay(0.8, function()
                if not puxando and isWolf() then
                    pullBtn.Text = "To Pull"
                    pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
                    pullBtn.Active = true
                    pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
            print("⏹️ Tempo esgotado!")
            return
        end

        atualizarUI(true, tempoRestante)

        if not targetCache or not targetCache.Character then
            cleanup()
            pullBtn.Text = "❌ PERDIDO"
            task.delay(0.8, function()
                if not puxando and isWolf() then
                    pullBtn.Text = "To Pull"
                end
            end)
            return
        end

        local tHrp = targetCache.Character:FindFirstChild("HumanoidRootPart")
        local tHum = targetCache.Character:FindFirstChildOfClass("Humanoid")

        if not tHrp or not tHum or tHum.Health <= 0 then
            cleanup()
            pullBtn.Text = "❌ MORTO"
            task.delay(0.8, function()
                if not puxando and isWolf() then
                    pullBtn.Text = "To Pull"
                end
            end)
            return
        end

        local _, charHrp, _ = getCharacter()
        if not charHrp then
            cleanup()
            return
        end

        local dist = (charHrp.Position - tHrp.Position).Magnitude
        alignPosition.Position = tHrp.Position

        if dist <= CONFIG.STOP_DISTANCE then
            cleanup()
            pullBtn.Text = "✅ CHEGOU!"
            pullBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            task.delay(0.8, function()
                if not puxando and isWolf() then
                    pullBtn.Text = "To Pull"
                    pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
                    pullBtn.Active = true
                    pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
        end
    end)
end

--// ============================================
--// EVENTOS
--// ============================================

-- Atualiza quando o personagem muda
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if isWolf() then
        pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
        pullBtn.Text = "To Pull"
        pullBtn.Active = true
        pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        pullBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        pullBtn.Text = "🔒 BLOQUEADO"
        pullBtn.Active = false
        pullBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

-- Botão
pullBtn.MouseButton1Click:Connect(function()
    if not isWolf() then
        pullBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        pullBtn.Text = "🔒 BLOQUEADO"
        pullBtn.Active = false
        pullBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        return
    end
    
    if puxando then
        cleanup()
        pullBtn.Text = "⏹ CANCELADO"
        task.delay(0.5, function()
            if not puxando and isWolf() then
                pullBtn.Text = "To Pull"
                pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
                pullBtn.Active = true
                pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end)
        print("⏹️ Pull cancelado!")
    else
        pullToNearest()
    end
end)

-- Atualiza estado inicial
task.wait(0.5)
if isWolf() then
    pullBtn.BackgroundColor3 = Color3.fromRGB(255, 229, 143)
    pullBtn.Text = "To Pull"
    pullBtn.Active = true
    pullBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
else
    pullBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    pullBtn.Text = "🔒 BLOQUEADO"
    pullBtn.Active = false
    pullBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end

print("✅ AlignPosition com Timer (2s) — Só Lobo carregado!")
print("🐺 O script só funciona se você for LOBO (sem status visível)")
