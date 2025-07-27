--[[
    TesteMinimo.lua
    
    Script ultra-simplificado para diagnóstico
    Apenas verifica se consegue encontrar elementos básicos e responder a cliques
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Imprimir mensagem inicial para verificar se o script está rodando
print("🔍 TESTE MÍNIMO: Script iniciado")

-- Obter referência ao jogador local
local Players = game:GetService("Players")
local jogador = Players.LocalPlayer
print("🔍 TESTE MÍNIMO: Jogador local encontrado: " .. jogador.Name)

-- Obter referência ao MainGui
local mainGui = script.Parent
if mainGui then
    print("🔍 TESTE MÍNIMO: MainGui encontrado")
else
    print("❌ TESTE MÍNIMO: MainGui não encontrado!")
    return -- Encerrar script se não encontrar
end

-- Verificar se o InventarioFrame existe
local inventarioFrame = mainGui:FindFirstChild("InventarioFrame")
if inventarioFrame then
    print("🔍 TESTE MÍNIMO: InventarioFrame encontrado")
else
    print("❌ TESTE MÍNIMO: InventarioFrame não encontrado!")
    -- Não encerrar, pois queremos tentar conectar ao botão mesmo assim
end

-- Tentar encontrar o botão de inventário
local hudFrame = mainGui:WaitForChild("HUD", 5) -- Esperar até 5 segundos
if not hudFrame then
    print("❌ TESTE MÍNIMO: HUD não encontrado após 5 segundos!")
    return
end

print("🔍 TESTE MÍNIMO: HUD encontrado, procurando BotoesMenu")
local botoesMenu = hudFrame:FindFirstChild("BotoesMenu")
if not botoesMenu then
    print("❌ TESTE MÍNIMO: BotoesMenu não encontrado no HUD!")
    return
end

print("🔍 TESTE MÍNIMO: BotoesMenu encontrado, procurando BotaoInventario")
local botaoInventario = botoesMenu:FindFirstChild("BotaoInventario")
if not botaoInventario then
    print("❌ TESTE MÍNIMO: BotaoInventario não encontrado!")
    return
end

print("✅ TESTE MÍNIMO: BotaoInventario encontrado! Conectando evento de clique...")

-- Conectar ao evento de clique
botaoInventario.MouseButton1Click:Connect(function()
    print("🎯 TESTE MÍNIMO: Botão inventário foi CLICADO!")
    
    -- Verificar novamente se o InventarioFrame existe
    if inventarioFrame then
        print("🔍 TESTE MÍNIMO: Tentando tornar InventarioFrame visível")
        inventarioFrame.Visible = true
        print("✅ TESTE MÍNIMO: InventarioFrame.Visible = true definido")
    else
        -- Tentar encontrar novamente, talvez tenha sido criado depois
        inventarioFrame = mainGui:FindFirstChild("InventarioFrame")
        if inventarioFrame then
            print("🔍 TESTE MÍNIMO: InventarioFrame encontrado agora! Tornando visível")
            inventarioFrame.Visible = true
            print("✅ TESTE MÍNIMO: InventarioFrame.Visible = true definido")
        else
            print("❌ TESTE MÍNIMO: InventarioFrame ainda não encontrado após clique!")
        end
    end
end)

print("✅ TESTE MÍNIMO: Script inicializado com sucesso! Aguardando clique no botão inventário...")
