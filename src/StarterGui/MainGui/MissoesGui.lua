--[[
    MissoesGui.lua
    
    Script cliente para a interface de missões do jogo "Viva Fantasy Island"
    Gerencia a exibição de missões diárias e semanais, progresso, recompensas
    e interação com o sistema de economia.
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Jogador local
local jogador = Players.LocalPlayer
local personagem = jogador.Character or jogador.CharacterAdded:Wait()

-- Referências à GUI
local mainGui = script.Parent
local missoesFrame = mainGui:WaitForChild("MissoesFrame")

-- Eventos Remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local atualizarMissoesEvent = RemoteEvents:WaitForChild("AtualizarMissoes")
local completarMissaoEvent = RemoteEvents:WaitForChild("CompletarMissao")

-- Configurações de animação
local configAnimacao = {
    duracao = 0.3,
    estilo = Enum.EasingStyle.Quad,
    direcao = Enum.EasingDirection.Out
}

-- Variáveis de estado para missões
local estadoMissoes = {
    missoesDiarias = {},
    missoesSemanais = {},
    missoesConcluidas = {},
    abaAtual = "diarias", -- diarias, semanais, concluidas
    tempoRestanteDiarias = 0,
    tempoRestanteSemanais = 0,
    elementosUI = {}
}

-- Ícones para tipos de missões
local iconesMissoes = {
    plantar_arvores = "rbxassetid://6797380656", -- Árvore
    visitar_ilhas = "rbxassetid://6797380765", -- Ilha
    coletar_recursos = "rbxassetid://6797380874", -- Recursos
    construir_casa = "rbxassetid://6797380329", -- Casa
    decorar_ilha = "rbxassetid://6797380005", -- Decoração
    default = "rbxassetid://6797380223" -- Ícone padrão
}

-- Cores para status de missões
local coresMissoes = {
    pendente = Color3.fromRGB(150, 150, 150),
    progresso = Color3.fromRGB(33, 150, 243),
    completa = Color3.fromRGB(76, 175, 80),
    coletada = Color3.fromRGB(156, 39, 176)
}

-- Função para formatar números grandes (ex: 1000 -> 1.000)
local function FormatarNumero(numero)
    local formatado = tostring(numero)
    local pos = string.len(formatado) - 3
    
    while pos > 0 do
        formatado = string.sub(formatado, 1, pos) .. "." .. string.sub(formatado, pos + 1)
        pos = pos - 3
    end
    
    return formatado
end

-- Função para formatar tempo restante
local function FormatarTempoRestante(segundos)
    if segundos <= 0 then
        return "Disponível agora"
    end
    
    local horas = math.floor(segundos / 3600)
    local minutos = math.floor((segundos % 3600) / 60)
    local segs = segundos % 60
    
    if horas > 0 then
        return string.format("%02d:%02d:%02d", horas, minutos, segs)
    else
        return string.format("%02d:%02d", minutos, segs)
    end
end

-- Função para criar animação de tween
local function CriarTween(objeto, propriedades, duracao, estilo, direcao)
    local info = TweenInfo.new(
        duracao or configAnimacao.duracao,
        estilo or configAnimacao.estilo,
        direcao or configAnimacao.direcao
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
    templateNotificacao.Position = UDim2.new(1, -20, 1, -80)
    templateNotificacao.AnchorPoint = Vector2.new(1, 1)
    templateNotificacao.Parent = notificacoesFrame
    
    -- Animação de entrada
    templateNotificacao.Position = UDim2.new(1, 300, 1, -80) -- Começa fora da tela
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

-- Função para criar a interface básica de missões
local function CriarInterfaceMissoes()
    -- Limpar interface existente
    for _, item in pairs(missoesFrame:GetChildren()) do
        if item:IsA("Frame") or item:IsA("ScrollingFrame") or item:IsA("TextButton") then
            item:Destroy()
        end
    end
    
    -- Criar título
    local tituloMissoes = Instance.new("TextLabel")
    tituloMissoes.Name = "TituloMissoes"
    tituloMissoes.Size = UDim2.new(1, 0, 0, 50)
    tituloMissoes.Position = UDim2.new(0, 0, 0, 0)
    tituloMissoes.BackgroundTransparency = 1
    tituloMissoes.TextColor3 = Color3.new(1, 1, 1)
    tituloMissoes.TextSize = 24
    tituloMissoes.Font = Enum.Font.SourceSansBold
    tituloMissoes.Text = "Missões"
    tituloMissoes.Parent = missoesFrame
    
    -- Criar abas
    local abasFrame = Instance.new("Frame")
    abasFrame.Name = "AbasFrame"
    abasFrame.Size = UDim2.new(1, 0, 0, 50)
    abasFrame.Position = UDim2.new(0, 0, 0, 60)
    abasFrame.BackgroundTransparency = 1
    abasFrame.Parent = missoesFrame
    
    local abas = {"diarias", "semanais", "concluidas"}
    local nomesAbas = {
        diarias = "Diárias",
        semanais = "Semanais",
        concluidas = "Concluídas"
    }
    
    local botoesAbas = {}
    
    for i, aba in ipairs(abas) do
        local botaoAba = Instance.new("TextButton")
        botaoAba.Name = "Aba_" .. aba
        botaoAba.Size = UDim2.new(1/3, -10, 1, -10)
        botaoAba.Position = UDim2.new((i-1)/3, 5, 0, 5)
        botaoAba.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        botaoAba.TextColor3 = Color3.new(1, 1, 1)
        botaoAba.TextSize = 16
        botaoAba.Font = Enum.Font.SourceSansBold
        botaoAba.Text = nomesAbas[aba] or aba
        botaoAba.BorderSizePixel = 0
        botaoAba.Parent = abasFrame
        
        botoesAbas[aba] = botaoAba
        
        -- Conectar evento de clique
        botaoAba.MouseButton1Click:Connect(function()
            SelecionarAba(aba, botoesAbas)
        end)
    end
    
    estadoMissoes.elementosUI.botoesAbas = botoesAbas
    
    -- Criar contador de tempo restante
    local tempoFrame = Instance.new("Frame")
    tempoFrame.Name = "TempoFrame"
    tempoFrame.Size = UDim2.new(1, 0, 0, 30)
    tempoFrame.Position = UDim2.new(0, 0, 0, 120)
    tempoFrame.BackgroundTransparency = 1
    tempoFrame.Parent = missoesFrame
    
    local tempoIcon = Instance.new("ImageLabel")
    tempoIcon.Name = "TempoIcon"
    tempoIcon.Size = UDim2.new(0, 20, 0, 20)
    tempoIcon.Position = UDim2.new(0, 10, 0.5, -10)
    tempoIcon.BackgroundTransparency = 1
    tempoIcon.Image = "rbxassetid://6797381092" -- Ícone de relógio
    tempoIcon.Parent = tempoFrame
    
    local tempoLabel = Instance.new("TextLabel")
    tempoLabel.Name = "TempoLabel"
    tempoLabel.Size = UDim2.new(0, 200, 0, 20)
    tempoLabel.Position = UDim2.new(0, 40, 0.5, -10)
    tempoLabel.BackgroundTransparency = 1
    tempoLabel.TextColor3 = Color3.new(1, 1, 1)
    tempoLabel.TextSize = 14
    tempoLabel.Font = Enum.Font.SourceSans
    tempoLabel.Text = "Próxima atualização em: 00:00:00"
    tempoLabel.TextXAlignment = Enum.TextXAlignment.Left
    tempoLabel.Parent = tempoFrame
    
    estadoMissoes.elementosUI.tempoLabel = tempoLabel
    
    -- Criar frame de conteúdo para as missões
    local conteudoFrame = Instance.new("ScrollingFrame")
    conteudoFrame.Name = "ConteudoFrame"
    conteudoFrame.Size = UDim2.new(1, -20, 1, -160)
    conteudoFrame.Position = UDim2.new(0, 10, 0, 160)
    conteudoFrame.BackgroundTransparency = 0.9
    conteudoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    conteudoFrame.BorderSizePixel = 0
    conteudoFrame.ScrollBarThickness = 6
    conteudoFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    conteudoFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    conteudoFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    conteudoFrame.Parent = missoesFrame
    
    estadoMissoes.elementosUI.conteudoFrame = conteudoFrame
    
    -- Botão para fechar as missões
    local botaoFechar = Instance.new("TextButton")
    botaoFechar.Name = "BotaoFechar"
    botaoFechar.Size = UDim2.new(0, 40, 0, 40)
    botaoFechar.Position = UDim2.new(1, -50, 0, 10)
    botaoFechar.BackgroundTransparency = 0.5
    botaoFechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    botaoFechar.TextColor3 = Color3.new(1, 1, 1)
    botaoFechar.TextSize = 20
    botaoFechar.Font = Enum.Font.SourceSansBold
    botaoFechar.Text = "X"
    botaoFechar.BorderSizePixel = 0
    botaoFechar.Parent = missoesFrame
    
    botaoFechar.MouseButton1Click:Connect(function()
        missoesFrame.Visible = false
    end)
    
    -- Selecionar aba inicial
    SelecionarAba("diarias", botoesAbas)
end

-- Função para selecionar uma aba
function SelecionarAba(aba, botoesAbas)
    -- Atualizar visual dos botões
    for id, botao in pairs(botoesAbas) do
        if id == aba then
            botao.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde para selecionado
        else
            botao.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Cinza para não selecionado
        end
    end
    
    estadoMissoes.abaAtual = aba
    
    -- Atualizar contador de tempo
    if aba == "diarias" then
        estadoMissoes.elementosUI.tempoLabel.Text = "Próxima atualização em: " .. FormatarTempoRestante(estadoMissoes.tempoRestanteDiarias)
    elseif aba == "semanais" then
        estadoMissoes.elementosUI.tempoLabel.Text = "Próxima atualização em: " .. FormatarTempoRestante(estadoMissoes.tempoRestanteSemanais)
    else
        estadoMissoes.elementosUI.tempoLabel.Text = ""
    end
    
    -- Atualizar conteúdo
    AtualizarConteudoMissoes()
end

-- Função para atualizar o conteúdo das missões baseado na aba selecionada
function AtualizarConteudoMissoes()
    local conteudoFrame = estadoMissoes.elementosUI.conteudoFrame
    
    -- Limpar conteúdo atual
    for _, item in pairs(conteudoFrame:GetChildren()) do
        if item:IsA("Frame") then
            item:Destroy()
        end
    end
    
    -- Selecionar lista de missões baseado na aba
    local missoes = {}
    if estadoMissoes.abaAtual == "diarias" then
        missoes = estadoMissoes.missoesDiarias
    elseif estadoMissoes.abaAtual == "semanais" then
        missoes = estadoMissoes.missoesSemanais
    elseif estadoMissoes.abaAtual == "concluidas" then
        missoes = estadoMissoes.missoesConcluidas
    end
    
    -- Criar elementos para cada missão
    for i, missao in ipairs(missoes) do
        local missaoFrame = CriarElementoMissao(missao, i)
        missaoFrame.Parent = conteudoFrame
    end
    
    -- Atualizar tamanho do canvas
    local totalAltura = #missoes * 110 + 10
    conteudoFrame.CanvasSize = UDim2.new(0, 0, 0, totalAltura)
end

-- Função para criar um elemento de missão
function CriarElementoMissao(missao, indice)
    -- Calcular posição
    local posY = (indice - 1) * 110 + 10
    
    -- Criar frame da missão
    local missaoFrame = Instance.new("Frame")
    missaoFrame.Name = "Missao_" .. missao.id
    missaoFrame.Size = UDim2.new(1, -20, 0, 100)
    missaoFrame.Position = UDim2.new(0, 10, 0, posY)
    missaoFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    missaoFrame.BorderSizePixel = 0
    
    -- Ícone da missão
    local icone = iconesMissoes[missao.id] or iconesMissoes.default
    local missaoIcone = Instance.new("ImageLabel")
    missaoIcone.Name = "Icone"
    missaoIcone.Size = UDim2.new(0, 60, 0, 60)
    missaoIcone.Position = UDim2.new(0, 10, 0, 10)
    missaoIcone.BackgroundTransparency = 1
    missaoIcone.Image = icone
    missaoIcone.Parent = missaoFrame
    
    -- Título da missão
    local missaoTitulo = Instance.new("TextLabel")
    missaoTitulo.Name = "Titulo"
    missaoTitulo.Size = UDim2.new(1, -90, 0, 25)
    missaoTitulo.Position = UDim2.new(0, 80, 0, 10)
    missaoTitulo.BackgroundTransparency = 1
    missaoTitulo.TextColor3 = Color3.new(1, 1, 1)
    missaoTitulo.TextSize = 16
    missaoTitulo.Font = Enum.Font.SourceSansBold
    missaoTitulo.Text = missao.titulo
    missaoTitulo.TextXAlignment = Enum.TextXAlignment.Left
    missaoTitulo.Parent = missaoFrame
    
    -- Descrição da missão
    local missaoDescricao = Instance.new("TextLabel")
    missaoDescricao.Name = "Descricao"
    missaoDescricao.Size = UDim2.new(1, -90, 0, 20)
    missaoDescricao.Position = UDim2.new(0, 80, 0, 35)
    missaoDescricao.BackgroundTransparency = 1
    missaoDescricao.TextColor3 = Color3.fromRGB(200, 200, 200)
    missaoDescricao.TextSize = 14
    missaoDescricao.Font = Enum.Font.SourceSans
    missaoDescricao.Text = missao.descricao
    missaoDescricao.TextXAlignment = Enum.TextXAlignment.Left
    missaoDescricao.TextWrapped = true
    missaoDescricao.Parent = missaoFrame
    
    -- Frame da barra de progresso
    local progressoFrame = Instance.new("Frame")
    progressoFrame.Name = "ProgressoFrame"
    progressoFrame.Size = UDim2.new(0.7, 0, 0, 15)
    progressoFrame.Position = UDim2.new(0, 80, 0, 65)
    progressoFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    progressoFrame.BorderSizePixel = 0
    progressoFrame.Parent = missaoFrame
    
    -- Barra de progresso
    local progressoAtual = math.min(missao.progresso, missao.objetivo)
    local porcentagemProgresso = progressoAtual / missao.objetivo
    
    local progressoBarra = Instance.new("Frame")
    progressoBarra.Name = "ProgressoBarra"
    progressoBarra.Size = UDim2.new(porcentagemProgresso, 0, 1, 0)
    progressoBarra.Position = UDim2.new(0, 0, 0, 0)
    progressoBarra.BorderSizePixel = 0
    
    -- Definir cor baseado no status
    local corBarra
    if missao.completada and missao.recompensaReclamada then
        corBarra = coresMissoes.coletada
    elseif missao.completada then
        corBarra = coresMissoes.completa
    elseif progressoAtual > 0 then
        corBarra = coresMissoes.progresso
    else
        corBarra = coresMissoes.pendente
    end
    
    progressoBarra.BackgroundColor3 = corBarra
    progressoBarra.Parent = progressoFrame
    
    -- Texto de progresso
    local progressoTexto = Instance.new("TextLabel")
    progressoTexto.Name = "ProgressoTexto"
    progressoTexto.Size = UDim2.new(0, 100, 0, 15)
    progressoTexto.Position = UDim2.new(0.7, 10, 0, 65)
    progressoTexto.BackgroundTransparency = 1
    progressoTexto.TextColor3 = Color3.new(1, 1, 1)
    progressoTexto.TextSize = 14
    progressoTexto.Font = Enum.Font.SourceSans
    progressoTexto.Text = progressoAtual .. "/" .. missao.objetivo
    progressoTexto.TextXAlignment = Enum.TextXAlignment.Left
    progressoTexto.Parent = missaoFrame
    
    -- Recompensa
    local recompensaFrame = Instance.new("Frame")
    recompensaFrame.Name = "RecompensaFrame"
    recompensaFrame.Size = UDim2.new(0, 100, 0, 25)
    recompensaFrame.Position = UDim2.new(0, 80, 0, 85)
    recompensaFrame.BackgroundTransparency = 1
    recompensaFrame.Parent = missaoFrame
    
    local recompensaIcone = Instance.new("ImageLabel")
    recompensaIcone.Name = "RecompensaIcone"
    recompensaIcone.Size = UDim2.new(0, 20, 0, 20)
    recompensaIcone.Position = UDim2.new(0, 0, 0, 0)
    recompensaIcone.BackgroundTransparency = 1
    recompensaIcone.Image = "rbxassetid://6797380983" -- Ícone de moeda
    recompensaIcone.Parent = recompensaFrame
    
    local recompensaValor = Instance.new("TextLabel")
    recompensaValor.Name = "RecompensaValor"
    recompensaValor.Size = UDim2.new(0, 80, 0, 20)
    recompensaValor.Position = UDim2.new(0, 25, 0, 0)
    recompensaValor.BackgroundTransparency = 1
    recompensaValor.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
    recompensaValor.TextSize = 16
    recompensaValor.Font = Enum.Font.SourceSansBold
    recompensaValor.Text = FormatarNumero(missao.recompensa)
    recompensaValor.TextXAlignment = Enum.TextXAlignment.Left
    recompensaValor.Parent = recompensaFrame
    
    -- Botão de coletar recompensa
    if missao.completada and not missao.recompensaReclamada then
        local botaoColetar = Instance.new("TextButton")
        botaoColetar.Name = "BotaoColetar"
        botaoColetar.Size = UDim2.new(0, 100, 0, 30)
        botaoColetar.Position = UDim2.new(1, -110, 0, 65)
        botaoColetar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
        botaoColetar.TextColor3 = Color3.new(1, 1, 1)
        botaoColetar.TextSize = 14
        botaoColetar.Font = Enum.Font.SourceSansBold
        botaoColetar.Text = "COLETAR"
        botaoColetar.BorderSizePixel = 0
        botaoColetar.Parent = missaoFrame
        
        -- Conectar evento de clique
        botaoColetar.MouseButton1Click:Connect(function()
            ColetarRecompensa(missao)
        end)
    elseif missao.completada and missao.recompensaReclamada then
        local statusColetado = Instance.new("TextLabel")
        statusColetado.Name = "StatusColetado"
        statusColetado.Size = UDim2.new(0, 100, 0, 30)
        statusColetado.Position = UDim2.new(1, -110, 0, 65)
        statusColetado.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Cinza
        statusColetado.TextColor3 = Color3.new(1, 1, 1)
        statusColetado.TextSize = 14
        statusColetado.Font = Enum.Font.SourceSansBold
        statusColetado.Text = "COLETADO"
        statusColetado.BorderSizePixel = 0
        statusColetado.Parent = missaoFrame
    end
    
    return missaoFrame
end

-- Função para coletar recompensa de uma missão
function ColetarRecompensa(missao)
    -- Verificar se a missão está completa e não foi reclamada ainda
    if not missao.completada or missao.recompensaReclamada then
        return
    end
    
    -- Enviar solicitação para o servidor
    completarMissaoEvent:FireServer(missao.id)
    
    -- Feedback visual temporário (será atualizado pelo servidor)
    MostrarNotificacao("Processando", "Coletando recompensa...", "info", 1)
}

-- Função para processar resposta de coleta de recompensa
local function ProcessarRespostaRecompensa(sucesso, missaoId, novasMoedas, mensagem)
    if sucesso then
        -- Atualizar moedas localmente (o servidor também enviará uma atualização)
        mainGui.HUD.MoedasFrame.ValorMoedas.Text = tostring(novasMoedas)
        
        -- Mostrar notificação de sucesso
        MostrarNotificacao("Recompensa Coletada", mensagem or "Recompensa coletada com sucesso!", "sucesso")
        
        -- Atualizar status da missão localmente
        for _, lista in pairs({estadoMissoes.missoesDiarias, estadoMissoes.missoesSemanais}) do
            for _, missao in ipairs(lista) do
                if missao.id == missaoId then
                    missao.recompensaReclamada = true
                    break
                end
            end
        end
        
        -- Atualizar interface
        AtualizarConteudoMissoes()
        
        -- Efeito visual de celebração
        CriarEfeitoCelebracao()
    else
        -- Mostrar notificação de erro
        MostrarNotificacao("Erro", mensagem or "Não foi possível coletar a recompensa.", "erro")
    end
end

-- Função para criar efeito visual de celebração
function CriarEfeitoCelebracao()
    -- Esta função criaria um efeito visual quando uma recompensa é coletada
    -- Por exemplo, partículas, sons, ou animações na interface
    
    -- Implementação simples: animação de pulso no HUD de moedas
    local moedasFrame = mainGui.HUD.MoedasFrame
    local escalaOriginal = moedasFrame.Size
    
    -- Animar crescendo
    local tweenCrescer = CriarTween(
        moedasFrame, 
        {Size = UDim2.new(escalaOriginal.X.Scale, escalaOriginal.X.Offset * 1.2, escalaOriginal.Y.Scale, escalaOriginal.Y.Offset * 1.2)}, 
        0.2
    )
    
    -- Animar voltando ao normal
    local tweenNormal = CriarTween(
        moedasFrame, 
        {Size = escalaOriginal}, 
        0.2
    )
    
    -- Executar sequência
    tweenCrescer:Play()
    tweenCrescer.Completed:Connect(function()
        tweenNormal:Play()
    end)
}

-- Função para atualizar o contador de tempo restante
local function AtualizarTempoRestante()
    -- Esta função seria chamada periodicamente para atualizar os contadores
    -- de tempo para reset das missões diárias e semanais
    
    -- Atualizar label se estiver na aba correspondente
    if estadoMissoes.abaAtual == "diarias" then
        estadoMissoes.elementosUI.tempoLabel.Text = "Próxima atualização em: " .. FormatarTempoRestante(estadoMissoes.tempoRestanteDiarias)
    elseif estadoMissoes.abaAtual == "semanais" then
        estadoMissoes.elementosUI.tempoLabel.Text = "Próxima atualização em: " .. FormatarTempoRestante(estadoMissoes.tempoRestanteSemanais)
    end
    
    -- Decrementar contadores
    if estadoMissoes.tempoRestanteDiarias > 0 then
        estadoMissoes.tempoRestanteDiarias = estadoMissoes.tempoRestanteDiarias - 1
    end
    
    if estadoMissoes.tempoRestanteSemanais > 0 then
        estadoMissoes.tempoRestanteSemanais = estadoMissoes.tempoRestanteSemanais - 1
    end
}

-- Função para atualizar as missões com dados do servidor
local function AtualizarMissoes(dadosMissoes)
    if not dadosMissoes then return end
    
    -- Atualizar dados locais
    estadoMissoes.missoesDiarias = dadosMissoes.diarias or {}
    estadoMissoes.missoesSemanais = dadosMissoes.semanais or {}
    estadoMissoes.missoesConcluidas = dadosMissoes.concluidas or {}
    
    -- Atualizar tempos restantes
    local tempoAtual = os.time()
    
    -- Calcular tempo até meia-noite para missões diárias
    local dataAtual = os.date("*t")
    local proximaMeiaNoite = os.time({
        year = dataAtual.year,
        month = dataAtual.month,
        day = dataAtual.day + 1,
        hour = 0,
        min = 0,
        sec = 0
    })
    
    estadoMissoes.tempoRestanteDiarias = proximaMeiaNoite - tempoAtual
    
    -- Calcular tempo até próximo domingo para missões semanais
    local diasAteDomingo = 7 - dataAtual.wday
    if diasAteDomingo == 0 then diasAteDomingo = 7 end -- Se hoje for domingo, próximo domingo é em 7 dias
    
    local proximoDomingo = os.time({
        year = dataAtual.year,
        month = dataAtual.month,
        day = dataAtual.day + diasAteDomingo,
        hour = 0,
        min = 0,
        sec = 0
    })
    
    estadoMissoes.tempoRestanteSemanais = proximoDomingo - tempoAtual
    
    -- Atualizar interface
    AtualizarConteudoMissoes()
}

-- Função para inicializar a interface de missões
local function Inicializar()
    print("📱 Missões: Inicializando interface...")
    
    -- Criar a interface básica
    CriarInterfaceMissoes()
    
    -- Conectar eventos remotos
    atualizarMissoesEvent.OnClientEvent:Connect(AtualizarMissoes)
    completarMissaoEvent.OnClientEvent:Connect(ProcessarRespostaRecompensa)
    
    -- Iniciar contador de tempo
    spawn(function()
        while true do
            wait(1)
            AtualizarTempoRestante()
        end
    end)
    
    -- Dados de teste para desenvolvimento
    local dadosTeste = {
        diarias = {
            {
                id = "plantar_arvores",
                titulo = "Plantar Árvores",
                descricao = "Plante 3 árvores na sua ilha",
                tipo = "diaria",
                objetivo = 3,
                progresso = 1,
                recompensa = 25,
                completada = false,
                recompensaReclamada = false
            },
            {
                id = "visitar_ilhas",
                titulo = "Visitar Ilhas",
                descricao = "Visite a ilha de 2 jogadores diferentes",
                tipo = "diaria",
                objetivo = 2,
                progresso = 2,
                recompensa = 50,
                completada = true,
                recompensaReclamada = false
            },
            {
                id = "coletar_recursos",
                titulo = "Coletar Recursos",
                descricao = "Colete 10 recursos da sua ilha",
                tipo = "diaria",
                objetivo = 10,
                progresso = 5,
                recompensa = 35,
                completada = false,
                recompensaReclamada = false
            }
        },
        semanais = {
            {
                id = "construir_casa",
                titulo = "Construir Casa",
                descricao = "Construa uma casa completa na sua ilha",
                tipo = "semanal",
                objetivo = 1,
                progresso = 0,
                recompensa = 150,
                completada = false,
                recompensaReclamada = false
            },
            {
                id = "decorar_ilha",
                titulo = "Decorar Ilha",
                descricao = "Coloque 15 decorações na sua ilha",
                tipo = "semanal",
                objetivo = 15,
                progresso = 15,
                recompensa = 100,
                completada = true,
                recompensaReclamada = true
            }
        },
        concluidas = {
            {
                id = "plantar_arvores",
                titulo = "Plantar Árvores",
                descricao = "Plante 3 árvores na sua ilha",
                tipo = "diaria",
                objetivo = 3,
                progresso = 3,
                recompensa = 25,
                completada = true,
                recompensaReclamada = true,
                dataCompletada = os.time() - 86400 -- Ontem
            }
        }
    }
    
    -- Usar dados de teste temporariamente
    AtualizarMissoes(dadosTeste)
    
    -- Solicitar dados reais ao servidor
    -- Isso seria implementado quando o servidor tiver o sistema pronto
    -- atualizarMissoesEvent:FireServer()
    
    print("📱 Missões: Interface inicializada com sucesso!")
end

-- Iniciar quando o script carregar
Inicializar()
