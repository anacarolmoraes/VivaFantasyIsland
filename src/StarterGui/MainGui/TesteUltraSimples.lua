--[[
    TesteUltraSimples.lua
    
    Script ultra simplificado apenas para testar se o botão inventário está funcionando
    Não cria ou modifica nenhum elemento, apenas mostra mensagens no Output
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Mensagem inicial para verificar se o script está rodando
print("🔬 TESTE ULTRA SIMPLES: Script iniciado!")

-- Obter referência ao jogador local
local Players = game:GetService("Players")
local jogador = Players.LocalPlayer
print("🔬 TESTE ULTRA SIMPLES: Jogador local encontrado: " .. jogador.Name)

-- Obter referência ao MainGui
local mainGui = script.Parent
print("🔬 TESTE ULTRA SIMPLES: MainGui encontrado")

-- Tentar encontrar o botão de inventário
print("🔬 TESTE ULTRA SIMPLES: Procurando HUD...")
local hudFrame = mainGui:FindFirstChild("HUD")
if not hudFrame then
    print("❌ TESTE ULTRA SIMPLES: HUD não encontrado!")
    return
end

print("🔬 TESTE ULTRA SIMPLES: Procurando BotoesMenu...")
local botoesMenu = hudFrame:FindFirstChild("BotoesMenu")
if not botoesMenu then
    print("❌ TESTE ULTRA SIMPLES: BotoesMenu não encontrado no HUD!")
    return
end

print("🔬 TESTE ULTRA SIMPLES: Procurando BotaoInventario...")
local botaoInventario = botoesMenu:FindFirstChild("BotaoInventario")
if not botaoInventario then
    print("❌ TESTE ULTRA SIMPLES: BotaoInventario não encontrado!")
    return
end

print("✅ TESTE ULTRA SIMPLES: BotaoInventario encontrado! Conectando evento de clique...")

-- Conectar ao evento de clique
botaoInventario.MouseButton1Click:Connect(function()
    print("🎯 TESTE ULTRA SIMPLES: BOTÃO INVENTÁRIO FOI CLICADO!")
    print("✅ TESTE ULTRA SIMPLES: Evento de clique está funcionando corretamente!")
end)

print("✅ TESTE ULTRA SIMPLES: Script inicializado com sucesso! Aguardando clique no botão inventário...")
