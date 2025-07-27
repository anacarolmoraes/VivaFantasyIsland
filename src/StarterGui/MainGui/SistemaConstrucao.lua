--[[
    SistemaConstrucao.lua
    
    Sistema de construção para o jogo "Viva Fantasy Island"
    Permite aos jogadores colocar e remover itens na ilha com preview 3D,
    validação de posicionamento, e integração com o inventário.
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

-- Jogador local
local jogador = Players.LocalPlayer
local personagem = jogador.Character or jogador.CharacterAdded:Wait()
local mouse = jogador:GetMouse()

-- Referências à GUI
local mainGui = script.Parent
local construcaoFrame = mainGui:WaitForChild("ConstrucaoFrame")
local inventarioFrame = mainGui:WaitForChild("InventarioFrame")

-- Eventos Remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local colocarDecoracaoEvent = RemoteEvents:WaitForChild("ColocarDecoracao")
local removerDecoracaoEvent = RemoteEvents:WaitForChild("RemoverDecoracao")
local atualizarInventarioEvent = RemoteEvents:WaitForChild("AtualizarInventario")

-- Configurações
local CONFIG = {
    ALTURA_PADRAO = 1,           -- Altura padrão acima do solo
    DISTANCIA_MAXIMA = 50,       -- Distância máxima para colocar itens
    ROTACAO_INCREMENTO = 15,     -- Incremento de rotação em graus
    ALTURA_INCREMENTO = 0.25,    -- Incremento de altura
    COR_VALIDO = Color3.fromRGB(0, 255, 0),      -- Verde para posição válida
    COR_INVALIDO = Color3.fromRGB(255, 0, 0),    -- Vermelho para posição inválida
    TRANSPARENCIA_PREVIEW = 0.5, -- Transparência do preview
    HISTORICO_MAXIMO = 20,       -- Número máximo de ações no histórico
    GRID_SNAP = 0.5,             -- Tamanho do grid para snap
    GRID_ENABLED = true          -- Grid ativado por padrão
}

-- Estado do sistema de construção
local estado = {
    modoConstrucao = false,      -- Se está no modo construção
    modoRemocao = false,         -- Se está no modo remoção
    itemSelecionado = nil,       -- Item atualmente selecionado para colocação
    previewAtual = nil,          -- Objeto de preview atual
    posicaoValida = false,       -- Se a posição atual é válida
    rotacaoAtual = 0,            -- Rotação atual em graus
    alturaAdicional = 0,         -- Altura adicional para ajuste fino
    gridAtivado = CONFIG.GRID_ENABLED, -- Se o snap ao grid está ativado
    historico = {                -- Histórico para undo/redo
        acoes = {},
        posicaoAtual = 0
    },
    ultimosItensColocados = {},  -- Cache dos últimos itens colocados
    elementosUI = {}             -- Referências a elementos da UI
}

-- Mapeamento de itens para modelos 3D
local modelosItens = {
    cerca_madeira = {
        modelo = "rbxassetid://6797380005",
        tamanho = Vector3.new(2, 1, 0.2),
        offset = Vector3.new(0, 0.5, 0),
        rotacionavel = true
    },
    arvore_pequena = {
        modelo = "rbxassetid://6797380656",
        tamanho = Vector3.new(2, 3, 2),
        offset = Vector3.new(0, 1.5, 0),
        rotacionavel = false
    },
    mesa_madeira = {
        modelo = "rbxassetid://6797380329",
        tamanho = Vector3.new(2, 1, 2),
        offset = Vector3.new(0, 0.5, 0),
        rotacionavel = true
    },
    cadeira_simples = {
        modelo = "rbxassetid://6797380438",
        tamanho = Vector3.new(1, 1.5, 1),
        offset = Vector3.new(0, 0.75, 0),
        rotacionavel = true
    },
    flor_azul = {
        modelo = "rbxassetid://6797380765",
        tamanho = Vector3.new(0.5, 0.5, 0.5),
        offset = Vector3.new(0, 0.25, 0),
        rotacionavel = false
    },
    estatua_pequena = {
        modelo = "rbxassetid://6797380223",
        tamanho = Vector3.new(1, 2, 1),
        offset = Vector3.new(0, 1, 0),
        rotacionavel = true
    }
}

-- Funções de utilidade

-- Função para aplicar snap ao grid
local function AplicarSnapGrid(posicao)
    if not estado.gridAtivado then return posicao end
    
    local x = math.round(posicao.X / CONFIG.GRID_SNAP) * CONFIG.GRID_SNAP
    local y = posicao.Y -- Não aplicamos snap na altura
    local z = math.round(posicao.Z / CONFIG.GRID_SNAP) * CONFIG.GRID_SNAP
    
    return Vector3.new(x, y, z)
end

-- Função para verificar se uma posição é válida para colocação
local function VerificarPosicaoValida(posicao, tamanho)
    -- Verificar se está dentro dos limites da ilha
    local limiteIlha = workspace:FindFirstChild("LimitesIlha")
    if limiteIlha then
        local min = limiteIlha.Min.Position
        local max = limiteIlha.Max.Position
        
        if posicao.X < min.X or posicao.X > max.X or
           posicao.Z < min.Z or posicao.Z > max.Z then
            return false
        end
    end
    
    -- Verificar colisão com outros objetos
    local tamanhoBusca = tamanho * 0.9 -- Um pouco menor para permitir objetos próximos
    local partes = workspace:GetPartBoundsInBox(
        CFrame.new(posicao),
        tamanhoBusca,
        OverlapParams.new()
    )
    
    -- Filtrar partes que não são decorações ou terreno
    local colisoes = 0
    for _, parte in ipairs(partes) do
        if not parte:IsDescendantOf(personagem) and 
           not parte.Name:match("^Terreno") and
           CollectionService:HasTag(parte, "Decoracao") then
            colisoes = colisoes + 1
        end
    end
    
    return colisoes == 0
end

-- Função para criar uma animação de tween
local function CriarTween(objeto, propriedades, duracao, estilo, direcao)
    local info = TweenInfo.new(
        duracao or 0.3,
        estilo or Enum.EasingStyle.Quad,
        direcao or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(objeto, info, propriedades)
    return tween
end

-- Função para mostrar notificação
local function MostrarNotificacao(titulo, mensagem, tipo, duracao)
    duracao = duracao or 3 -- Duração padrão de 3 segundos
    
    -- Criar notificação na interface
    local notificacoesFrame = mainGui:WaitForChild("NotificacoesFrame")
    local templateNotificacao = notificacoesFrame:WaitForChild("TemplateNotificacao"):Clone()
    templateNotificacao.Name = "Notificacao_" .. os.time()
    templateNotificacao.Visible = true
    
    -- Configurar aparência baseado no tipo
    if tipo == "sucesso" then
        templateNotificacao.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
    elseif tipo == "erro" then
        templateNotificacao.BackgroundColor3 = Color3.fromRGB(211, 47, 47) -- Vermelho
    else
        templateNotificacao.BackgroundColor3 = Color3.fromRGB(33, 150, 243) -- Azul (info)
    end
    
    -- Configurar texto
    local tituloLabel = Instance.new("TextLabel")
    tituloLabel.Name = "Titulo"
    tituloLabel.Size = UDim2.new(1, 0, 0, 20)
    tituloLabel.Position = UDim2.new(0, 0, 0, 0)
    tituloLabel.BackgroundTransparency = 1
    tituloLabel.TextColor3 = Color3.new(1, 1, 1)
    tituloLabel.TextSize = 14
    tituloLabel.Font = Enum.Font.SourceSansBold
    tituloLabel.Text = titulo
    tituloLabel.Parent = templateNotificacao
    
    local mensagemLabel = Instance.new("TextLabel")
    mensagemLabel.Name = "Mensagem"
    mensagemLabel.Size = UDim2.new(1, 0, 0, 40)
    mensagemLabel.Position = UDim2.new(0, 0, 0, 20)
    mensagemLabel.BackgroundTransparency = 1
    mensagemLabel.TextColor3 = Color3.new(1, 1, 1)
    mensagemLabel.TextSize = 12
    mensagemLabel.Font = Enum.Font.SourceSans
    mensagemLabel.Text = mensagem
    mensagemLabel.TextWrapped = true
    mensagemLabel.Parent = templateNotificacao
    
    -- Posicionar notificação
    templateNotificacao.Position = UDim2.new(1, 300, 1, -80) -- Começa fora da tela
    templateNotificacao.AnchorPoint = Vector2.new(1, 1)
    templateNotificacao.Parent = notificacoesFrame
    
    -- Animação de entrada
    local tweenEntrada = CriarTween(templateNotificacao, {Position = UDim2.new(1, -20, 1, -80)}, 0.5)
    tweenEntrada:Play()
    
    -- Animação de saída após duração
    task.delay(duracao, function()
        local tweenSaida = CriarTween(templateNotificacao, {Position = UDim2.new(1, 300, 1, -80)}, 0.5)
        tweenSaida:Play()
        tweenSaida.Completed:Connect(function()
            templateNotificacao:Destroy()
        end)
    end)
end

-- Funções principais do sistema de construção

-- Função para criar a interface de construção
local function CriarInterfaceConstrucao()
    print("🏗️ CONSTRUÇÃO: Criando interface...")
    
    -- Limpar interface existente
    for _, item in pairs(construcaoFrame:GetChildren()) do
        if item:IsA("Frame") or item:IsA("TextButton") and item.Name ~= "BotaoFechar" then
            item:Destroy()
        end
    end
    
    -- Criar título
    local tituloConstrucao = Instance.new("TextLabel")
    tituloConstrucao.Name = "TituloConstrucao"
    tituloConstrucao.Size = UDim2.new(1, 0, 0, 50)
    tituloConstrucao.Position = UDim2.new(0, 0, 0, 0)
    tituloConstrucao.BackgroundTransparency = 1
    tituloConstrucao.TextColor3 = Color3.new(1, 1, 1)
    tituloConstrucao.TextSize = 24
    tituloConstrucao.Font = Enum.Font.SourceSansBold
    tituloConstrucao.Text = "Modo Construção"
    tituloConstrucao.Parent = construcaoFrame
    
    -- Criar painel de controles
    local painelControles = Instance.new("Frame")
    painelControles.Name = "PainelControles"
    painelControles.Size = UDim2.new(1, -40, 0, 120)
    painelControles.Position = UDim2.new(0, 20, 0, 60)
    painelControles.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    painelControles.BorderSizePixel = 0
    painelControles.Parent = construcaoFrame
    
    -- Título do painel
    local tituloPainel = Instance.new("TextLabel")
    tituloPainel.Name = "TituloPainel"
    tituloPainel.Size = UDim2.new(1, 0, 0, 30)
    tituloPainel.Position = UDim2.new(0, 0, 0, 0)
    tituloPainel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    tituloPainel.TextColor3 = Color3.new(1, 1, 1)
    tituloPainel.TextSize = 16
    tituloPainel.Font = Enum.Font.SourceSansBold
    tituloPainel.Text = "Controles"
    tituloPainel.BorderSizePixel = 0
    tituloPainel.Parent = painelControles
    
    -- Botão de rotação
    local botaoRotacao = Instance.new("TextButton")
    botaoRotacao.Name = "BotaoRotacao"
    botaoRotacao.Size = UDim2.new(0.23, 0, 0, 30)
    botaoRotacao.Position = UDim2.new(0.02, 0, 0, 40)
    botaoRotacao.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    botaoRotacao.TextColor3 = Color3.new(1, 1, 1)
    botaoRotacao.TextSize = 14
    botaoRotacao.Font = Enum.Font.SourceSansBold
    botaoRotacao.Text = "Rotacionar (R)"
    botaoRotacao.BorderSizePixel = 0
    botaoRotacao.Parent = painelControles
    
    -- Botão de altura
    local botaoAltura = Instance.new("TextButton")
    botaoAltura.Name = "BotaoAltura"
    botaoAltura.Size = UDim2.new(0.23, 0, 0, 30)
    botaoAltura.Position = UDim2.new(0.27, 0, 0, 40)
    botaoAltura.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    botaoAltura.TextColor3 = Color3.new(1, 1, 1)
    botaoAltura.TextSize = 14
    botaoAltura.Font = Enum.Font.SourceSansBold
    botaoAltura.Text = "Altura (↑↓)"
    botaoAltura.BorderSizePixel = 0
    botaoAltura.Parent = painelControles
    
    -- Botão de grid
    local botaoGrid = Instance.new("TextButton")
    botaoGrid.Name = "BotaoGrid"
    botaoGrid.Size = UDim2.new(0.23, 0, 0, 30)
    botaoGrid.Position = UDim2.new(0.52, 0, 0, 40)
    botaoGrid.BackgroundColor3 = estado.gridAtivado and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(150, 150, 150)
    botaoGrid.TextColor3 = Color3.new(1, 1, 1)
    botaoGrid.TextSize = 14
    botaoGrid.Font = Enum.Font.SourceSansBold
    botaoGrid.Text = "Grid: " .. (estado.gridAtivado and "ON" or "OFF")
    botaoGrid.BorderSizePixel = 0
    botaoGrid.Parent = painelControles
    
    -- Botão de cancelar
    local botaoCancelar = Instance.new("TextButton")
    botaoCancelar.Name = "BotaoCancelar"
    botaoCancelar.Size = UDim2.new(0.23, 0, 0, 30)
    botaoCancelar.Position = UDim2.new(0.77, 0, 0, 40)
    botaoCancelar.BackgroundColor3 = Color3.fromRGB(211, 47, 47)
    botaoCancelar.TextColor3 = Color3.new(1, 1, 1)
    botaoCancelar.TextSize = 14
    botaoCancelar.Font = Enum.Font.SourceSansBold
    botaoCancelar.Text = "Cancelar (ESC)"
    botaoCancelar.BorderSizePixel = 0
    botaoCancelar.Parent = painelControles
    
    -- Botão de confirmar
    local botaoConfirmar = Instance.new("TextButton")
    botaoConfirmar.Name = "BotaoConfirmar"
    botaoConfirmar.Size = UDim2.new(0.48, 0, 0, 30)
    botaoConfirmar.Position = UDim2.new(0.02, 0, 0, 80)
    botaoConfirmar.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    botaoConfirmar.TextColor3 = Color3.new(1, 1, 1)
    botaoConfirmar.TextSize = 14
    botaoConfirmar.Font = Enum.Font.SourceSansBold
    botaoConfirmar.Text = "Confirmar Colocação (ENTER)"
    botaoConfirmar.BorderSizePixel = 0
    botaoConfirmar.Parent = painelControles
    
    -- Botão de remoção
    local botaoRemocao = Instance.new("TextButton")
    botaoRemocao.Name = "BotaoRemocao"
    botaoRemocao.Size = UDim2.new(0.48, 0, 0, 30)
    botaoRemocao.Position = UDim2.new(0.52, 0, 0, 80)
    botaoRemocao.BackgroundColor3 = Color3.fromRGB(255, 152, 0)
    botaoRemocao.TextColor3 = Color3.new(1, 1, 1)
    botaoRemocao.TextSize = 14
    botaoRemocao.Font = Enum.Font.SourceSansBold
    botaoRemocao.Text = "Modo Remoção (DEL)"
    botaoRemocao.BorderSizePixel = 0
    botaoRemocao.Parent = painelControles
    
    -- Painel de histórico
    local painelHistorico = Instance.new("Frame")
    painelHistorico.Name = "PainelHistorico"
    painelHistorico.Size = UDim2.new(1, -40, 0, 80)
    painelHistorico.Position = UDim2.new(0, 20, 0, 190)
    painelHistorico.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    painelHistorico.BorderSizePixel = 0
    painelHistorico.Parent = construcaoFrame
    
    -- Título do painel histórico
    local tituloHistorico = Instance.new("TextLabel")
    tituloHistorico.Name = "TituloHistorico"
    tituloHistorico.Size = UDim2.new(1, 0, 0, 30)
    tituloHistorico.Position = UDim2.new(0, 0, 0, 0)
    tituloHistorico.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    tituloHistorico.TextColor3 = Color3.new(1, 1, 1)
    tituloHistorico.TextSize = 16
    tituloHistorico.Font = Enum.Font.SourceSansBold
    tituloHistorico.Text = "Histórico"
    tituloHistorico.BorderSizePixel = 0
    tituloHistorico.Parent = painelHistorico
    
    -- Botão de desfazer
    local botaoDesfazer = Instance.new("TextButton")
    botaoDesfazer.Name = "BotaoDesfazer"
    botaoDesfazer.Size = UDim2.new(0.48, 0, 0, 30)
    botaoDesfazer.Position = UDim2.new(0.02, 0, 0, 40)
    botaoDesfazer.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    botaoDesfazer.TextColor3 = Color3.new(1, 1, 1)
    botaoDesfazer.TextSize = 14
    botaoDesfazer.Font = Enum.Font.SourceSansBold
    botaoDesfazer.Text = "Desfazer (CTRL+Z)"
    botaoDesfazer.BorderSizePixel = 0
    botaoDesfazer.Parent = painelHistorico
    
    -- Botão de refazer
    local botaoRefazer = Instance.new("TextButton")
    botaoRefazer.Name = "BotaoRefazer"
    botaoRefazer.Size = UDim2.new(0.48, 0, 0, 30)
    botaoRefazer.Position = UDim2.new(0.52, 0, 0, 40)
    botaoRefazer.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    botaoRefazer.TextColor3 = Color3.new(1, 1, 1)
    botaoRefazer.TextSize = 14
    botaoRefazer.Font = Enum.Font.SourceSansBold
    botaoRefazer.Text = "Refazer (CTRL+Y)"
    botaoRefazer.BorderSizePixel = 0
    botaoRefazer.Parent = painelHistorico
    
    -- Painel de inventário rápido
    local painelInventario = Instance.new("Frame")
    painelInventario.Name = "PainelInventario"
    painelInventario.Size = UDim2.new(1, -40, 0.4, -40)
    painelInventario.Position = UDim2.new(0, 20, 0, 280)
    painelInventario.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    painelInventario.BorderSizePixel = 0
    painelInventario.Parent = construcaoFrame
    
    -- Título do painel inventário
    local tituloInventario = Instance.new("TextLabel")
    tituloInventario.Name = "TituloInventario"
    tituloInventario.Size = UDim2.new(1, 0, 0, 30)
    tituloInventario.Position = UDim2.new(0, 0, 0, 0)
    tituloInventario.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    tituloInventario.TextColor3 = Color3.new(1, 1, 1)
    tituloInventario.TextSize = 16
    tituloInventario.Font = Enum.Font.SourceSansBold
    tituloInventario.Text = "Inventário Rápido"
    tituloInventario.BorderSizePixel = 0
    tituloInventario.Parent = painelInventario
    
    -- Grid de inventário rápido
    local gridInventario = Instance.new("ScrollingFrame")
    gridInventario.Name = "GridInventario"
    gridInventario.Size = UDim2.new(1, -20, 1, -40)
    gridInventario.Position = UDim2.new(0, 10, 0, 35)
    gridInventario.BackgroundTransparency = 0.9
    gridInventario.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    gridInventario.BorderSizePixel = 0
    gridInventario.ScrollBarThickness = 6
    gridInventario.ScrollingDirection = Enum.ScrollingDirection.Y
    gridInventario.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gridInventario.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridInventario.Parent = painelInventario
    
    -- Guardar referências para uso futuro
    estado.elementosUI = {
        botaoRotacao = botaoRotacao,
        botaoAltura = botaoAltura,
        botaoGrid = botaoGrid,
        botaoCancelar = botaoCancelar,
        botaoConfirmar = botaoConfirmar,
        botaoRemocao = botaoRemocao,
        botaoDesfazer = botaoDesfazer,
        botaoRefazer = botaoRefazer,
        gridInventario = gridInventario
    }
    
    -- Conectar eventos dos botões
    botaoRotacao.MouseButton1Click:Connect(function()
        RotacionarPreview()
    end)
    
    botaoAltura.MouseButton1Click:Connect(function()
        AjustarAlturaPreview(CONFIG.ALTURA_INCREMENTO)
    end)
    
    botaoGrid.MouseButton1Click:Connect(function()
        AlternarGrid()
    end)
    
    botaoCancelar.MouseButton1Click:Connect(function()
        CancelarConstrucao()
    end)
    
    botaoConfirmar.MouseButton1Click:Connect(function()
        ConfirmarColocacao()
    end)
    
    botaoRemocao.MouseButton1Click:Connect(function()
        AlternarModoRemocao()
    end)
    
    botaoDesfazer.MouseButton1Click:Connect(function()
        Desfazer()
    end)
    
    botaoRefazer.MouseButton1Click:Connect(function()
        Refazer()
    end)
    
    print("🏗️ CONSTRUÇÃO: Interface criada com sucesso!")
end

-- Função para carregar itens do inventário no painel rápido
local function CarregarItensInventario(itens)
    local gridInventario = estado.elementosUI.gridInventario
    
    -- Limpar grid atual
    for _, item in pairs(gridInventario:GetChildren()) do
        if item:IsA("Frame") then
            item:Destroy()
        end
    end
    
    -- Configurações do grid
    local colunas = 4
    local tamanhoCelula = 60
    local espacamento = 10
    
    -- Criar células para cada item
    for i, item in ipairs(itens) do
        -- Calcular posição no grid
        local coluna = (i - 1) % colunas
        local linha = math.floor((i - 1) / colunas)
        local posX = coluna * (tamanhoCelula + espacamento)
        local posY = linha * (tamanhoCelula + espacamento)
        
        -- Criar célula do grid
        local celula = Instance.new("Frame")
        celula.Name = "Celula_" .. item.id
        celula.Size = UDim2.new(0, tamanhoCelula, 0, tamanhoCelula)
        celula.Position = UDim2.new(0, posX, 0, posY)
        celula.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        celula.BorderSizePixel = 0
        celula.Parent = gridInventario
        
        -- Imagem do item
        local itemImagem = Instance.new("ImageLabel")
        itemImagem.Name = "Imagem"
        itemImagem.Size = UDim2.new(0.8, 0, 0.8, 0)
        itemImagem.Position = UDim2.new(0.1, 0, 0.1, -10)
        itemImagem.BackgroundTransparency = 1
        itemImagem.Image = item.icone
        itemImagem.Parent = celula
        
        -- Quantidade do item
        local itemQuantidade = Instance.new("TextLabel")
        itemQuantidade.Name = "Quantidade"
        itemQuantidade.Size = UDim2.new(0.5, 0, 0.25, 0)
        itemQuantidade.Position = UDim2.new(0.5, 0, 0.75, 0)
        itemQuantidade.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        itemQuantidade.BackgroundTransparency = 0.3
        itemQuantidade.TextColor3 = Color3.new(1, 1, 1)
        itemQuantidade.TextSize = 14
        itemQuantidade.Font = Enum.Font.SourceSansBold
        itemQuantidade.Text = tostring(item.quantidade)
        itemQuantidade.Parent = celula
        
        -- Botão para selecionar o item
        local botaoSelecionar = Instance.new("TextButton")
        botaoSelecionar.Name = "BotaoSelecionar"
        botaoSelecionar.Size = UDim2.new(1, 0, 1, 0)
        botaoSelecionar.BackgroundTransparency = 1
        botaoSelecionar.Text = ""
        botaoSelecionar.Parent = celula
        
        -- Conectar evento de clique
        botaoSelecionar.MouseButton1Click:Connect(function()
            SelecionarItemConstrucao(item.id, item.nome)
        end)
    end
    
    -- Atualizar tamanho do canvas
    local linhas = math.ceil(#itens / colunas)
    gridInventario.CanvasSize = UDim2.new(0, 0, 0, linhas * (tamanhoCelula + espacamento) + espacamento)
end

-- Função para iniciar o modo de construção
local function IniciarModoConstrucao()
    print("🏗️ CONSTRUÇÃO: Iniciando modo construção...")
    
    -- Atualizar estado
    estado.modoConstrucao = true
    estado.modoRemocao = false
    
    -- Mostrar interface de construção
    construcaoFrame.Visible = true
    
    -- Criar interface se não existir
    if not estado.elementosUI.botaoRotacao then
        CriarInterfaceConstrucao()
    end
    
    -- Carregar itens do inventário
    -- Aqui você faria uma chamada ao servidor para obter os itens do inventário
    -- Por enquanto, vamos usar dados de exemplo
    local itensExemplo = {
        {id = "cerca_madeira", nome = "Cerca de Madeira", quantidade = 5, icone = "rbxassetid://6797380005"},
        {id = "arvore_pequena", nome = "Árvore Pequena", quantidade = 3, icone = "rbxassetid://6797380656"},
        {id = "mesa_madeira", nome = "Mesa de Madeira", quantidade = 2, icone = "rbxassetid://6797380329"},
        {id = "cadeira_simples", nome = "Cadeira Simples", quantidade = 4, icone = "rbxassetid://6797380438"},
        {id = "flor_azul", nome = "Flores Azuis", quantidade = 7, icone = "rbxassetid://6797380765"},
        {id = "estatua_pequena", nome = "Estátua de Pedra", quantidade = 1, icone = "rbxassetid://6797380223"}
    }
    
    CarregarItensInventario(itensExemplo)
    
    -- Mostrar instruções
    MostrarNotificacao(
        "Modo Construção Ativado",
        "Selecione um item do inventário para começar a construir. Use R para rotacionar, setas para ajustar altura.",
        "info",
        5
    )
    
    print("🏗️ CONSTRUÇÃO: Modo construção iniciado!")
end

-- Função para selecionar um item para construção
local function SelecionarItemConstrucao(itemId, nomeItem)
    print("🏗️ CONSTRUÇÃO: Item selecionado: " .. itemId)
    
    -- Verificar se o item já está selecionado
    if estado.itemSelecionado == itemId and estado.previewAtual then
        return
    end
    
    -- Limpar preview anterior se existir
    if estado.previewAtual then
        estado.previewAtual:Destroy()
        estado.previewAtual = nil
    end
    
    -- Atualizar estado
    estado.itemSelecionado = itemId
    estado.rotacaoAtual = 0
    estado.alturaAdicional = 0
    
    -- Obter configurações do modelo
    local configModelo = modelosItens[itemId]
    if not configModelo then
        MostrarNotificacao("Erro", "Modelo para " .. nomeItem .. " não encontrado.", "erro")
        return
    end
    
    -- Criar preview do item
    local preview = Instance.new("Part")
    preview.Name = "Preview_" .. itemId
    preview.Anchored = true
    preview.CanCollide = false
    preview.Size = configModelo.tamanho
    preview.Transparency = CONFIG.TRANSPARENCIA_PREVIEW
    preview.Material = Enum.Material.Neon
    preview.BrickColor = BrickColor.new("Bright green")
    
    -- Adicionar textura/modelo se disponível
    if configModelo.modelo then
        local textura = Instance.new("Decal")
        textura.Texture = configModelo.modelo
        textura.Face = Enum.NormalId.Front
        textura.Parent = preview
    end
    
    preview.Parent = workspace
    estado.previewAtual = preview
    
    -- Iniciar atualização contínua da posição
    if not estado.conexaoPreview then
        estado.conexaoPreview = RunService.RenderStepped:Connect(AtualizarPosicaoPreview)
    end
    
    MostrarNotificacao(
        "Item Selecionado",
        nomeItem .. " selecionado para construção. Clique para posicionar ou pressione ENTER para confirmar.",
        "info",
        3
    )
end

-- Função para atualizar a posição do preview
function AtualizarPosicaoPreview()
    if not estado.modoConstrucao or not estado.previewAtual or not estado.itemSelecionado then
        return
    end
    
    -- Raycasting para encontrar onde o mouse está apontando
    local raio = workspace:Raycast(
        personagem.Head.Position,
        (mouse.Hit.Position - personagem.Head.Position).Unit * CONFIG.DISTANCIA_MAXIMA,
        RaycastParams.new()
    )
    
    if raio then
        -- Obter configurações do modelo
        local configModelo = modelosItens[estado.itemSelecionado]
        if not configModelo then return end
        
        -- Calcular posição com offset e altura adicional
        local posicaoBase = raio.Position
        local posicaoComOffset = posicaoBase + configModelo.offset + Vector3.new(0, estado.alturaAdicional, 0)
        
        -- Aplicar snap ao grid se ativado
        local posicaoFinal = AplicarSnapGrid(posicaoComOffset)
        
        -- Verificar se a posição é válida
        estado.posicaoValida = VerificarPosicaoValida(posicaoFinal, configModelo.tamanho)
        
        -- Atualizar cor do preview baseado na validade
        estado.previewAtual.BrickColor = estado.posicaoValida 
            and BrickColor.new("Bright green") 
            or BrickColor.new("Really red")
        
        -- Atualizar posição e rotação
        local cframe = CFrame.new(posicaoFinal) * CFrame.Angles(0, math.rad(estado.rotacaoAtual), 0)
        estado.previewAtual.CFrame = cframe
    end
end

-- Função para rotacionar o preview
function RotacionarPreview()
    if not estado.modoConstrucao or not estado.previewAtual or not estado.itemSelecionado then
        return
    end
    
    -- Verificar se o item é rotacionável
    local configModelo = modelosItens[estado.itemSelecionado]
    if not configModelo or not configModelo.rotacionavel then
        MostrarNotificacao("Aviso", "Este item não pode ser rotacionado.", "info", 2)
        return
    end
    
    -- Incrementar rotação
    estado.rotacaoAtual = (estado.rotacaoAtual + CONFIG.ROTACAO_INCREMENTO) % 360
    
    -- Atualizar interface
    if estado.elementosUI.botaoRotacao then
        estado.elementosUI.botaoRotacao.Text = "Rotação: " .. estado.rotacaoAtual .. "°"
    end
end

-- Função para ajustar a altura do preview
function AjustarAlturaPreview(incremento)
    if not estado.modoConstrucao or not estado.previewAtual then
        return
    end
    
    -- Ajustar altura
    estado.alturaAdicional = estado.alturaAdicional + incremento
    
    -- Atualizar interface
    if estado.elementosUI.botaoAltura then
        estado.elementosUI.botaoAltura.Text = "Altura: " .. string.format("%.2f", estado.alturaAdicional)
    end
end

-- Função para alternar o grid
function AlternarGrid()
    estado.gridAtivado = not estado.gridAtivado
    
    -- Atualizar interface
    if estado.elementosUI.botaoGrid then
        estado.elementosUI.botaoGrid.Text = "Grid: " .. (estado.gridAtivado and "ON" or "OFF")
        estado.elementosUI.botaoGrid.BackgroundColor3 = estado.gridAtivado 
            and Color3.fromRGB(76, 175, 80) 
            or Color3.fromRGB(150, 150, 150)
    end
    
    MostrarNotificacao(
        "Grid " .. (estado.gridAtivado and "Ativado" or "Desativado"),
        estado.gridAtivado 
            and "Os itens serão alinhados automaticamente ao grid." 
            or "Os itens podem ser colocados em qualquer posição.",
        "info",
        2
    )
end

-- Função para alternar modo de remoção
function AlternarModoRemocao()
    estado.modoRemocao = not estado.modoRemocao
    
    -- Limpar preview se estiver no modo remoção
    if estado.modoRemocao and estado.previewAtual then
        estado.previewAtual:Destroy()
        estado.previewAtual = nil
        estado.itemSelecionado = nil
    end
    
    -- Atualizar interface
    if estado.elementosUI.botaoRemocao then
        estado.elementosUI.botaoRemocao.Text = estado.modoRemocao 
            and "Modo Remoção: ATIVO" 
            or "Modo Remoção (DEL)"
        estado.elementosUI.botaoRemocao.BackgroundColor3 = estado.modoRemocao 
            and Color3.fromRGB(211, 47, 47) 
            or Color3.fromRGB(255, 152, 0)
    end
    
    -- Atualizar cursor
    if estado.modoRemocao then
        mouse.Icon = "rbxassetid://6797380983" -- Ícone de remoção
        MostrarNotificacao(
            "Modo Remoção Ativado",
            "Clique em um item para removê-lo da sua ilha.",
            "info",
            3
        )
    else
        mouse.Icon = ""
        MostrarNotificacao(
            "Modo Remoção Desativado",
            "Voltando ao modo de colocação normal.",
            "info",
            2
        )
    end
end

-- Função para confirmar colocação do item
function ConfirmarColocacao()
    if not estado.modoConstrucao or not estado.previewAtual or not estado.itemSelecionado then
        return
    end
    
    -- Verificar se a posição é válida
    if not estado.posicaoValida then
        MostrarNotificacao(
            "Posição Inválida",
            "Não é possível colocar o item nesta posição. Tente outro local.",
            "erro",
            3
        )
        return
    end
    
    -- Obter dados do item e posição
    local itemId = estado.itemSelecionado
    local posicao = estado.previewAtual.Position
    local rotacao = estado.rotacaoAtual
    
    -- Enviar evento para o servidor
    colocarDecoracaoEvent:FireServer(itemId, posicao, rotacao)
    
    -- Adicionar ao histórico
    AdicionarAoHistorico({
        tipo = "colocar",
        itemId = itemId,
        posicao = posicao,
        rotacao = rotacao
    })
    
    -- Feedback visual temporário
    MostrarNotificacao(
        "Item Colocado",
        "O item foi colocado com sucesso na sua ilha!",
        "sucesso",
        2
    )
    
    -- Resetar estado para permitir colocar outro item do mesmo tipo
    local itemAtual = estado.itemSelecionado
    local nomeItem = "Item"
    
    for _, item in ipairs(estado.ultimosItensColocados) do
        if item.id == itemAtual then
            nomeItem = item.nome
            break
        end
    end
    
    -- Manter o mesmo item selecionado para colocar vários
    SelecionarItemConstrucao(itemAtual, nomeItem)
end

-- Função para remover um item
local function RemoverItem()
    if not estado.modoConstrucao or not estado.modoRemocao then
        return
    end
    
    -- Raycasting para encontrar o item sob o mouse
    local raio = workspace:Raycast(
        personagem.Head.Position,
        (mouse.Hit.Position - personagem.Head.Position).Unit * CONFIG.DISTANCIA_MAXIMA,
        RaycastParams.new()
    )
    
    if raio and raio.Instance then
        -- Verificar se é uma decoração
        local decoracao = raio.Instance
        while decoracao and not CollectionService:HasTag(decoracao, "Decoracao") do
            decoracao = decoracao.Parent
        end
        
        if decoracao then
            -- Obter ID do item
            local itemId = decoracao:GetAttribute("ItemId")
            if not itemId then
                MostrarNotificacao("Erro", "Não foi possível identificar este item.", "erro", 2)
                return
            end
            
            -- Enviar evento para o servidor
            removerDecoracaoEvent:FireServer(decoracao:GetAttribute("ItemUID"))
            
            -- Adicionar ao histórico
            AdicionarAoHistorico({
                tipo = "remover",
                itemId = itemId,
                posicao = decoracao.Position,
                rotacao = decoracao.Orientation.Y,
                uid = decoracao:GetAttribute("ItemUID")
            })
            
            -- Feedback visual
            MostrarNotificacao(
                "Item Removido",
                "O item foi removido com sucesso da sua ilha!",
                "sucesso",
                2
            )
        else
            MostrarNotificacao(
                "Nenhum Item Encontrado",
                "Clique diretamente em um item para removê-lo.",
                "info",
                2
            )
        end
    end
end

-- Função para cancelar construção
function CancelarConstrucao()
    print("🏗️ CONSTRUÇÃO: Cancelando modo construção...")
    
    -- Limpar preview
    if estado.previewAtual then
        estado.previewAtual:Destroy()
        estado.previewAtual = nil
    end
    
    -- Desconectar eventos
    if estado.conexaoPreview then
        estado.conexaoPreview:Disconnect()
        estado.conexaoPreview = nil
    end
    
    -- Resetar estado
    estado.modoConstrucao = false
    estado.modoRemocao = false
    estado.itemSelecionado = nil
    estado.rotacaoAtual = 0
    estado.alturaAdicional = 0
    
    -- Resetar cursor
    mouse.Icon = ""
    
    -- Esconder interface
    construcaoFrame.Visible = false
    
    MostrarNotificacao(
        "Modo Construção Encerrado",
        "Você saiu do modo de construção.",
        "info",
        2
    )
    
    print("🏗️ CONSTRUÇÃO: Modo construção cancelado!")
end

-- Funções de histórico (undo/redo)

-- Função para adicionar uma ação ao histórico
function AdicionarAoHistorico(acao)
    -- Se estamos no meio do histórico, remover ações futuras
    if estado.historico.posicaoAtual < #estado.historico.acoes then
        -- Remover todas as ações após a posição atual
        for i = #estado.historico.acoes, estado.historico.posicaoAtual + 1, -1 do
            table.remove(estado.historico.acoes, i)
        end
    end
    
    -- Adicionar nova ação
    table.insert(estado.historico.acoes, acao)
    estado.historico.posicaoAtual = #estado.historico.acoes
    
    -- Limitar tamanho do histórico
    if #estado.historico.acoes > CONFIG.HISTORICO_MAXIMO then
        table.remove(estado.historico.acoes, 1)
        estado.historico.posicaoAtual = estado.historico.posicaoAtual - 1
    end
    
    -- Atualizar interface
    AtualizarBotoesHistorico()
end

-- Função para desfazer a última ação
function Desfazer()
    if estado.historico.posicaoAtual < 1 then
        MostrarNotificacao("Histórico", "Não há ações para desfazer.", "info", 2)
        return
    end
    
    local acao = estado.historico.acoes[estado.historico.posicaoAtual]
    estado.historico.posicaoAtual = estado.historico.posicaoAtual - 1
    
    -- Executar ação inversa
    if acao.tipo == "colocar" then
        -- Se colocou, agora remove
        removerDecoracaoEvent:FireServer(acao.uid)
        MostrarNotificacao("Desfazer", "Colocação de item desfeita.", "info", 2)
    elseif acao.tipo == "remover" then
        -- Se removeu, agora coloca de volta
        colocarDecoracaoEvent:FireServer(acao.itemId, acao.posicao, acao.rotacao, acao.uid)
        MostrarNotificacao("Desfazer", "Remoção de item desfeita.", "info", 2)
    end
    
    -- Atualizar interface
    AtualizarBotoesHistorico()
end

-- Função para refazer a última ação desfeita
function Refazer()
    if estado.historico.posicaoAtual >= #estado.historico.acoes then
        MostrarNotificacao("Histórico", "Não há ações para refazer.", "info", 2)
        return
    end
    
    estado.historico.posicaoAtual = estado.historico.posicaoAtual + 1
    local acao = estado.historico.acoes[estado.historico.posicaoAtual]
    
    -- Executar ação
    if acao.tipo == "colocar" then
        -- Recolocar o item
        colocarDecoracaoEvent:FireServer(acao.itemId, acao.posicao, acao.rotacao)
        MostrarNotificacao("Refazer", "Colocação de item refeita.", "info", 2)
    elseif acao.tipo == "remover" then
        -- Remover o item novamente
        removerDecoracaoEvent:FireServer(acao.uid)
        MostrarNotificacao("Refazer", "Remoção de item refeita.", "info", 2)
    end
    
    -- Atualizar interface
    AtualizarBotoesHistorico()
end

-- Função para atualizar os botões de histórico
function AtualizarBotoesHistorico()
    if not estado.elementosUI.botaoDesfazer or not estado.elementosUI.botaoRefazer then
        return
    end
    
    -- Atualizar botão desfazer
    estado.elementosUI.botaoDesfazer.BackgroundColor3 = estado.historico.posicaoAtual > 0
        and Color3.fromRGB(33, 150, 243)
        or Color3.fromRGB(100, 100, 100)
    
    -- Atualizar botão refazer
    estado.elementosUI.botaoRefazer.BackgroundColor3 = estado.historico.posicaoAtual < #estado.historico.acoes
        and Color3.fromRGB(33, 150, 243)
        or Color3.fromRGB(100, 100, 100)
end

-- Conexões de entrada

-- Função para gerenciar entrada do teclado
local function GerenciarEntradaTeclado(input, gameProcessed)
    if gameProcessed then return end
    
    -- Verificar se está no modo construção
    if not estado.modoConstrucao then return end
    
    -- Teclas para modo construção
    if input.KeyCode == Enum.KeyCode.R then
        -- Rotacionar item
        RotacionarPreview()
    elseif input.KeyCode == Enum.KeyCode.Up then
        -- Aumentar altura
        AjustarAlturaPreview(CONFIG.ALTURA_INCREMENTO)
    elseif input.KeyCode == Enum.KeyCode.Down then
        -- Diminuir altura
        AjustarAlturaPreview(-CONFIG.ALTURA_INCREMENTO)
    elseif input.KeyCode == Enum.KeyCode.G then
        -- Alternar grid
        AlternarGrid()
    elseif input.KeyCode == Enum.KeyCode.Delete then
        -- Alternar modo remoção
        AlternarModoRemocao()
    elseif input.KeyCode == Enum.KeyCode.Return then
        -- Confirmar colocação
        ConfirmarColocacao()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        -- Cancelar construção
        CancelarConstrucao()
    end
    
    -- Teclas de atalho para histórico
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
        if input.KeyCode == Enum.KeyCode.Z then
            -- Desfazer
            Desfazer()
        elseif input.KeyCode == Enum.KeyCode.Y then
            -- Refazer
            Refazer()
        end
    end
end

-- Função para gerenciar clique do mouse
local function GerenciarCliqueMouse(input, gameProcessed)
    if gameProcessed then return end
    
    -- Verificar se está no modo construção
    if not estado.modoConstrucao then return end
    
    -- Clique esquerdo
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if estado.modoRemocao then
            -- Remover item
            RemoverItem()
        else
            -- Confirmar colocação
            ConfirmarColocacao()
        end
    end
end

-- Inicialização e conexões de eventos

-- Função para inicializar o sistema de construção
local function Inicializar()
    print("🏗️ CONSTRUÇÃO: Inicializando sistema...")
    
    -- Conectar eventos de entrada
    UserInputService.InputBegan:Connect(GerenciarEntradaTeclado)
    UserInputService.InputBegan:Connect(GerenciarCliqueMouse)
    
    -- Conectar botão de construção no HUD
    local hudFrame = mainGui:WaitForChild("HUD")
    local botoesMenu = hudFrame:WaitForChild("BotoesMenu")
    local botaoConstrucao = botoesMenu:WaitForChild("BotaoConstrucao")
    
    botaoConstrucao.MouseButton1Click:Connect(function()
        print("🏗️ CONSTRUÇÃO: Botão construção clicado")
        if not estado.modoConstrucao then
            IniciarModoConstrucao()
        end
    end)
    
    -- Conectar eventos remotos
    atualizarInventarioEvent.OnClientEvent:Connect(function(dadosInventario)
        -- Atualizar dados do inventário rápido se estiver no modo construção
        if estado.modoConstrucao and estado.elementosUI.gridInventario then
            CarregarItensInventario(dadosInventario)
        end
    end)
    
    -- Esconder frame de construção inicialmente
    construcaoFrame.Visible = false
    
    print("🏗️ CONSTRUÇÃO: Sistema inicializado com sucesso!")
end

-- Iniciar quando o script carregar
Inicializar()
