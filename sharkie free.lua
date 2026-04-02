-- ================================================
-- SHARKIE HUB - SOLO "delet walls" (Custom Tools)
-- Basado en la interfaz original de SHARKIE.lua
-- Solo el botón "delet walls" + 2 tools personalizados
-- ================================================

if getgenv and getgenv().SharkieDeleteWallsLoaded then return end
getgenv().SharkieDeleteWallsLoaded = true

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

print("[SHARKIE] Cargando solo delet walls con tools...")

-- ================================================
-- BYPASS BÁSICO (como en el original)
-- ================================================
pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        local blocked = {"Kick","kick","Ban","ban","TeleportDetect","AntiCheat","CHECKER","SPEEDCHECK","POSITIONCHECK","OneMoreTime","BR_KICKPC","KICKREMOTE","BANREMOTE","ExploitDetected","ReportCheat","Detect","Punish","Crash","Log","Flag"}
        if table.find(blocked, method) then return end
        if method == "FireServer" or method == "InvokeServer" then
            local name = tostring(self)
            for _, str in ipairs({"Kick","Ban","Anti","Exploit","Report","Detect","Punish","Crash","Log","Flag","Adonis","Byfron","AC"}) do
                if name:lower():find(str:lower()) then return end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
    hookfunction(player.Kick, function() end)
    player.Kick = function() end
    print("[BYPASS] Anti-kick cargado")
end)

-- ================================================
-- GUI (estilo idéntico al SharkieHub original)
-- ================================================
local sg = Instance.new("ScreenGui")
sg.Name = "SharkieDeleteWalls"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
sg.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 220)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -110)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(180, 100, 255)
stroke.Thickness = 3

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "sharkie hub"
title.TextColor3 = Color3.fromRGB(220, 100, 255)
title.TextSize = 32
title.Font = Enum.Font.GothamBlack
title.TextStrokeTransparency = 0.7
title.TextStrokeColor3 = Color3.fromRGB(100, 50, 150)

-- Botón ÚNICO: delet walls
local deletBtn = Instance.new("TextButton", mainFrame)
deletBtn.Size = UDim2.new(0.85, 0, 0, 70)
deletBtn.Position = UDim2.new(0.075, 0, 0.4, 0)
deletBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
deletBtn.Text = "delet walls [OFF]"
deletBtn.TextColor3 = Color3.new(1, 1, 1)
deletBtn.TextSize = 26
deletBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", deletBtn).CornerRadius = UDim.new(0, 12)

local btnStroke = Instance.new("UIStroke", deletBtn)
btnStroke.Color = Color3.fromRGB(180, 100, 255)
btnStroke.Thickness = 2

-- ================================================
-- VARIABLES Y TOOLS
-- ================================================
local deletedStack = {}  -- pila LIFO para undo
local deleteTool = nil
local repairTool = nil
local active = false

local function updateRepairName()
    if repairTool then
        repairTool.Name = "reparar (" .. #deletedStack .. ") 🟩"
    end
end

local function createTools()
    if deleteTool or repairTool then return end

    -- ==================== TOOL 1: delet ✖️ ====================
    deleteTool = Instance.new("Tool")
    deleteTool.Name = "delet ✖️"
    local delHandle = Instance.new("Part")
    delHandle.Name = "Handle"
    delHandle.Transparency = 1
    delHandle.CanCollide = false
    delHandle.Size = Vector3.new(0.2, 0.2, 3)
    delHandle.Parent = deleteTool
    deleteTool.Parent = player.Backpack

    local deleteInputConn
    deleteTool.Equipped:Connect(function()
        deleteInputConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode ~= Enum.KeyCode.E then return end

            local target = mouse.Target
            if not target then return end
            if target:IsDescendantOf(player.Character) then return end

            -- Guardar clon para poder restaurar después
            local success, clone = pcall(function() return target:Clone() end)
            if success and clone then
                table.insert(deletedStack, {
                    clone = clone,
                    originalParent = target.Parent,
                    originalName = target.Name
                })
                target:Destroy()
                updateRepairName()
                print("🗑️ Eliminado: " .. (clone.Name or "objeto"))
            end
        end)
    end)

    deleteTool.Unequipped:Connect(function()
        if deleteInputConn then deleteInputConn:Disconnect() end
    end)

    -- ==================== TOOL 2: reparar (N) 🟩 ====================
    repairTool = Instance.new("Tool")
    repairTool.Name = "reparar (0) 🟩"
    local repHandle = Instance.new("Part")
    repHandle.Name = "Handle"
    repHandle.Transparency = 1
    repHandle.CanCollide = false
    repHandle.Size = Vector3.new(0.2, 0.2, 3)
    repHandle.Parent = repairTool
    repairTool.Parent = player.Backpack

    local repairActivatedConn
    repairTool.Equipped:Connect(function()
        repairActivatedConn = repairTool.Activated:Connect(function()  -- click izquierdo en cualquier parte
            if #deletedStack == 0 then return end

            local data = table.remove(deletedStack)
            local success, restored = pcall(function()
                local r = data.clone:Clone()
                r.Parent = data.originalParent or workspace
                r.Name = data.originalName
                return r
            end)

            if success then
                updateRepairName()
                print("🟩 Restaurado: " .. (restored.Name or "objeto"))
            end
        end)
    end)

    repairTool.Unequipped:Connect(function()
        if repairActivatedConn then repairActivatedConn:Disconnect() end
    end)
end

-- ================================================
-- BOTÓN DE ACTIVACIÓN
-- ================================================
deletBtn.MouseButton1Click:Connect(function()
    active = not active

    if active then
        deletBtn.Text = "delet walls [ON]"
        deletBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
        createTools()
        print("✅ Tools creados en tu inventario:\n   • delet ✖️  (E para eliminar)\n   • reparar (N) 🟩  (click para restaurar)")
    else
        deletBtn.Text = "delet walls [OFF]"
        deletBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)

        -- Limpiar tools y pila
        if deleteTool then deleteTool:Destroy() end
        if repairTool then repairTool:Destroy() end
        deleteTool = nil
        repairTool = nil
        deletedStack = {}
        print("🛑 Tools eliminados")
    end
end)

-- Botón cerrar (estilo original)
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 28
closeBtn.Font = Enum.Font.GothamBold
closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
    print("[SHARKIE] GUI cerrada")
end)

print("[SHARKIE] Listo! Haz click en 'delet walls' para obtener los 2 tools.")