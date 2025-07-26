--[[
    MainGui/init.lua
    
    Script cliente para gerenciar a interface principal do jogo "Viva Fantasy Island"
    Este script controla a GUI principal, mostra o saldo de DreamCoins e gerencia
    as interações do usuário com os diferentes menus e funcionalidades.
    
    Autor: Factory AI
    Data: 26/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Jogador local
local jogador = Players.LocalPlayer
local personagem = jogador.Character or jogador.CharacterAdded:Wait()

-- Referências à GUI
local playerGui = jogador:WaitForChild("PlayerGui")
local mainGui = script.Parent
local framesPrincipais = {
    hud = mainGui:WaitForChild("HUD"),
    loja = mainGui:WaitForChild("LojaFrame"),
    inventario = mainGui:WaitForChild("InventarioFrame"),
    missoes = mainGui:WaitForChild("MissoesFrame"),
    construcao = mainGui:WaitForChild("ConstrucaoFrame"),
    social = mainGui:WaitForChild("SocialFrame"),
    configuracoes = mainGui:WaitForChild("ConfiguracoesFrame")
}

-- Elementos específicos da HUD
local hudElements = {
    moedas = framesPrincipais.hud:WaitForChild("MoedasFrame"):WaitForChild("ValorMoedas"),
    nivel = framesPrincipais.hud:WaitForChild("NivelFrame"):WaitForChild("ValorNivel"),
    botaoLoja = framesPrincipais.hud:WaitForChild("BotoesMenu"):WaitForChild("BotaoLoja"),
    botaoInventario = framesPrincipais.hud:WaitForChild("BotoesMenu"):WaitForChild("BotaoInventario"),
    botaoMissoes = framesPrincipais.hud:WaitForChild("BotoesMenu"):WaitForChild("BotaoMissoes"),
    botaoConstrucao = framesPrincipais.hud:WaitForChild("BotoesMenu"):WaitForChild("BotaoConstrucao"),
    botaoSocial = framesPrincipais.hud:WaitForChild("BotoesMenu"):WaitForChild("BotaoSocial"),
    botaoConfiguracoes = framesPrincipais.hud:WaitForChild("BotoesMenu"):WaitForChild("BotaoConfiguracoes")
}

-- Eventos Remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local atualizarMoedasEvent = RemoteEvents:WaitForChild("AtualizarMoedas")
local completarMissaoEvent = RemoteEvents:WaitForChild("CompletarMissao")
local colocarDecoracaoEvent = RemoteEvents:WaitForChild("ColocarDecoracao")
local removerDecoracaoEvent = RemoteEvents:WaitForChild("RemoverDecoracao")
local comprarItemFunction = RemoteFunctions:WaitForChild("ComprarItem")
local visitarIlhaFunction = RemoteFunctions:WaitForChild("VisitarIlha")

-- Variáveis de estado
local estadoAtual = {
    moedas = 0,
    nivel = 1,
    menuAberto = nil,
    modoColocacao = false,
    itemSelecionado = nil,
    notificacoesPendentes = {}
}

-- Configurações de animação
local configAnimacao = {
    duracao = 0.3,
    estilo = Enum.EasingStyle.Quad,
    direcao = Enum.EasingDirection.Out
}

--[[
    Funções de Utilidade
]]

-- Função para formatar números grandes (ex: 1000 -> 1,000)
local function FormatarNumero(numero)
    local formatado = tostring(numero)
    local pos = string.len(formatado) - 3
    
    while pos > 0 do
        formatado = string.sub(formatado, 1, pos) .. "." .. string.sub(formatado, pos + 1)
        pos = pos - 3
    end
    
    return formatado
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
    duracao = duracao or 5 -- Duração padrão de 5 segundos
    
    -- Criar notificação na interface
    local notificacoesFrame = mainGui:WaitForChild("NotificacoesFrame")
    local templateNotificacao = notificacoesFrame:WaitForChild("TemplateNotificacao")
    
    local novaNotificacao = templateNotificacao:Clone()
    novaNotificacao.Name = "Notificacao_" .. os.time()
    novaNotificacao.Visible = true
    
    -- Configurar aparência baseado no tipo
    if tipo == "sucesso" then
        novaNotificacao.Barra.BackgroundColor3 = Color3.fromRGB(76, 209, 55) -- Verde
    elseif tipo == "erro" then
        novaNotificacao.Barra.BackgroundColor3 = Color3.fromRGB(209, 55, 55) -- Vermelho
    elseif tipo == "aviso" then
        novaNotificacao.Barra.BackgroundColor3 = Color3.fromRGB(209, 180, 55) -- Amarelo
    elseif tipo == "info" then
        novaNotificacao.Barra.BackgroundColor3 = Color3.fromRGB(55, 159, 209) -- Azul
    end
    
    -- Configurar texto
    novaNotificacao.Titulo.Text = titulo
    novaNotificacao.Mensagem.Text = mensagem
    
    -- Posicionar notificação
    local totalNotificacoes = #notificacoesFrame:GetChildren() - 1 -- Desconsiderar o template
    novaNotificacao.Position = UDim2.new(1, 0, 1 - (totalNotificacoes * 0.12), -10)
    novaNotificacao.Parent = notificacoesFrame
    
    -- Animar entrada
    local tweenEntrada = CriarTween(
        novaNotificacao, 
        {Position = UDim2.new(0.98, 0, novaNotificacao.Position.Y.Scale, -10)}, 
        0.5
    )
    tweenEntrada:Play()
    
    -- Configurar fechamento automático
    spawn(function()
        wait(duracao - 0.5) -- Tempo total menos tempo de animação de saída
        
        -- Animar saída
        local tweenSaida = CriarTween(
            novaNotificacao, 
            {Position = UDim2.new(1.1, 0, novaNotificacao.Position.Y.Scale, -10)}, 
            0.5
        )
        tweenSaida:Play()
        
        tweenSaida.Completed:Wait()
        novaNotificacao:Destroy()
    end)
    
    -- Configurar botão de fechar
    novaNotificacao.BotaoFechar.MouseButton1Click:Connect(function()
        -- Animar saída imediata
        local tweenSaida = CriarTween(
            novaNotificacao, 
            {Position = UDim2.new(1.1, 0, novaNotificacao.Position.Y.Scale, -10)}, 
            0.3
        )
        tweenSaida:Play()
        
        tweenSaida.Completed:Wait()
        novaNotificacao:Destroy()
    end)
end

--[[
    Funções de Gerenciamento da Interface
]]

-- Atualiza o display de moedas na HUD
local function AtualizarMoedasDisplay(quantidade)
    estadoAtual.moedas = quantidade
    hudElements.moedas.Text = FormatarNumero(quantidade)
    
    -- Animar mudança
    local tweenEscala = CriarTween(hudElements.moedas, {TextSize = 24}, 0.1)
    tweenEscala:Play()
    
    spawn(function()
        wait(0.1)
        local tweenNormal = CriarTween(hudElements.moedas, {TextSize = 20}, 0.1)
        tweenNormal:Play()
    end)
end

-- Atualiza o display de nível na HUD
local function AtualizarNivelDisplay(nivel)
    estadoAtual.nivel = nivel
    hudElements.nivel.Text = nivel
    
    -- Animar mudança
    local tweenEscala = CriarTween(hudElements.nivel, {TextSize = 24}, 0.1)
    tweenEscala:Play()
    
    spawn(function()
        wait(0.1)
        local tweenNormal = CriarTween(hudElements.nivel, {TextSize = 20}, 0.1)
        tweenNormal:Play()
    end)
end

-- Abre um menu específico
local function AbrirMenu(nomeMenu)
    -- Fechar menu atual se houver
    if estadoAtual.menuAberto then
        framesPrincipais[estadoAtual.menuAberto].Visible = false
    end
    
    -- Se clicar no mesmo menu, apenas fecha
    if estadoAtual.menuAberto == nomeMenu then
        estadoAtual.menuAberto = nil
        return
    end
    
    -- Abrir novo menu
    if framesPrincipais[nomeMenu] then
        framesPrincipais[nomeMenu].Visible = true
        estadoAtual.menuAberto = nomeMenu
        
        -- Animar abertura
        framesPrincipais[nomeMenu].Position = UDim2.new(0.5, 0, 1.1, 0)
        local tweenAbertura = CriarTween(
            framesPrincipais[nomeMenu], 
            {Position = UDim2.new(0.5, 0, 0.5, 0)}, 
            0.4
        )
        tweenAbertura:Play()
        
        -- Carregar dados específicos do menu
        if nomeMenu == "loja" then
            CarregarDadosLoja()
        elseif nomeMenu == "inventario" then
            CarregarDadosInventario()
        elseif nomeMenu == "missoes" then
            CarregarDadosMissoes()
        elseif nomeMenu == "social" then
            CarregarDadosSocial()
        end
    end
end

-- Fecha todos os menus
local function FecharTodosMenus()
    for nome, frame in pairs(framesPrincipais) do
        if nome ~= "hud" then
            frame.Visible = false
        end
    end
    estadoAtual.menuAberto = nil
end

--[[
    Funções de Carregamento de Dados
]]

-- Carrega dados da loja
local function CarregarDadosLoja()
    local lojaFrame = framesPrincipais.loja
    local containerItens = lojaFrame:WaitForChild("ContainerItens")
    local templateItem = containerItens:WaitForChild("TemplateItem")
    
    -- Limpar itens existentes
    for _, child in pairs(containerItens:GetChildren()) do
        if child:IsA("Frame") and child ~= templateItem then
            child:Destroy()
        end
    end
    
    -- Aqui você faria uma chamada ao servidor para obter os itens disponíveis
    -- Por enquanto, vamos criar alguns itens de exemplo
    local itensExemplo = {
        {id = "arvore_pequena", nome = "Árvore Pequena", preco = 50, imagem = "rbxassetid://123456"},
        {id = "arvore_grande", nome = "Árvore Grande", preco = 100, imagem = "rbxassetid://123457"},
        {id = "fogueira", nome = "Fogueira", preco = 75, imagem = "rbxassetid://123458"},
        {id = "ponte", nome = "Ponte", preco = 150, imagem = "rbxassetid://123459"},
        {id = "cerca", nome = "Cerca", preco = 30, imagem = "rbxassetid://123460"},
        {id = "flor_azul", nome = "Flor Azul", preco = 25, imagem = "rbxassetid://123461"},
        {id = "flor_vermelha", nome = "Flor Vermelha", preco = 25, imagem = "rbxassetid://123462"},
        {id = "pedra", nome = "Pedra", preco = 40, imagem = "rbxassetid://123463"}
    }
    
    -- Criar itens na loja
    for i, item in ipairs(itensExemplo) do
        local novoItem = templateItem:Clone()
        novoItem.Name = "Item_" .. item.id
        novoItem.Visible = true
        novoItem.LayoutOrder = i
        
        -- Configurar dados do item
        novoItem.NomeItem.Text = item.nome
        novoItem.PrecoItem.Text = FormatarNumero(item.preco) .. " DC"
        novoItem.ImagemItem.Image = item.imagem
        
        -- Configurar botão de compra
        novoItem.BotaoComprar.MouseButton1Click:Connect(function()
            ComprarItem(item.id, item.preco, item.nome)
        end)
        
        novoItem.Parent = containerItens
    end
    
    -- Mostrar mensagem de carregamento concluído
    lojaFrame.CarregandoLabel.Visible = false
end

-- Carrega dados do inventário
local function CarregarDadosInventario()
    local inventarioFrame = framesPrincipais.inventario
    local containerItens = inventarioFrame:WaitForChild("ContainerItens")
    local templateItem = containerItens:WaitForChild("TemplateItem")
    
    -- Limpar itens existentes
    for _, child in pairs(containerItens:GetChildren()) do
        if child:IsA("Frame") and child ~= templateItem then
            child:Destroy()
        end
    end
    
    -- Aqui você faria uma chamada ao servidor para obter os itens do inventário
    -- Por enquanto, vamos criar alguns itens de exemplo
    local itensExemplo = {
        {id = "arvore_pequena", nome = "Árvore Pequena", quantidade = 3, imagem = "rbxassetid://123456"},
        {id = "fogueira", nome = "Fogueira", quantidade = 1, imagem = "rbxassetid://123458"},
        {id = "flor_azul", nome = "Flor Azul", quantidade = 5, imagem = "rbxassetid://123461"}
    }
    
    -- Criar itens no inventário
    for i, item in ipairs(itensExemplo) do
        local novoItem = templateItem:Clone()
        novoItem.Name = "Item_" .. item.id
        novoItem.Visible = true
        novoItem.LayoutOrder = i
        
        -- Configurar dados do item
        novoItem.NomeItem.Text = item.nome
        novoItem.QuantidadeItem.Text = "x" .. item.quantidade
        novoItem.ImagemItem.Image = item.imagem
        
        -- Configurar botão de usar
        novoItem.BotaoUsar.MouseButton1Click:Connect(function()
            UsarItem(item.id, item.nome)
        end)
        
        novoItem.Parent = containerItens
    end
    
    -- Mostrar mensagem de carregamento concluído
    inventarioFrame.CarregandoLabel.Visible = false
end

-- Carrega dados das missões
local function CarregarDadosMissoes()
    local missoesFrame = framesPrincipais.missoes
    local containerMissoes = missoesFrame:WaitForChild("ContainerMissoes")
    local templateMissao = containerMissoes:WaitForChild("TemplateMissao")
    
    -- Limpar missões existentes
    for _, child in pairs(containerMissoes:GetChildren()) do
        if child:IsA("Frame") and child ~= templateMissao then
            child:Destroy()
        end
    end
    
    -- Aqui você faria uma chamada ao servidor para obter as missões disponíveis
    -- Por enquanto, vamos criar algumas missões de exemplo
    local missoesExemplo = {
        {id = "missao_1", titulo = "Plantar 3 árvores", descricao = "Plante 3 árvores na sua ilha", recompensa = 50, progresso = 1, total = 3},
        {id = "missao_2", titulo = "Visitar 2 ilhas", descricao = "Visite a ilha de 2 jogadores diferentes", recompensa = 75, progresso = 0, total = 2},
        {id = "missao_3", titulo = "Coletar recursos", descricao = "Colete 10 recursos da sua ilha", recompensa = 100, progresso = 5, total = 10}
    }
    
    -- Criar missões
    for i, missao in ipairs(missoesExemplo) do
        local novaMissao = templateMissao:Clone()
        novaMissao.Name = "Missao_" .. missao.id
        novaMissao.Visible = true
        novaMissao.LayoutOrder = i
        
        -- Configurar dados da missão
        novaMissao.TituloMissao.Text = missao.titulo
        novaMissao.DescricaoMissao.Text = missao.descricao
        novaMissao.RecompensaMissao.Text = "Recompensa: " .. FormatarNumero(missao.recompensa) .. " DC"
        novaMissao.ProgressoMissao.Text = missao.progresso .. "/" .. missao.total
        
        -- Configurar barra de progresso
        local percentualProgresso = missao.progresso / missao.total
        novaMissao.BarraProgresso.Preenchimento.Size = UDim2.new(percentualProgresso, 0, 1, 0)
        
        -- Configurar botão de reclamar recompensa
        if missao.progresso >= missao.total then
            novaMissao.BotaoReclamar.Visible = true
            novaMissao.BotaoReclamar.MouseButton1Click:Connect(function()
                ReclamarRecompensaMissao(missao.id, missao.recompensa)
            end)
        else
            novaMissao.BotaoReclamar.Visible = false
        end
        
        novaMissao.Parent = containerMissoes
    end
    
    -- Mostrar mensagem de carregamento concluído
    missoesFrame.CarregandoLabel.Visible = false
end

-- Carrega dados sociais
local function CarregarDadosSocial()
    local socialFrame = framesPrincipais.social
    local containerJogadores = socialFrame:WaitForChild("ContainerJogadores")
    local templateJogador = containerJogadores:WaitForChild("TemplateJogador")
    
    -- Limpar jogadores existentes
    for _, child in pairs(containerJogadores:GetChildren()) do
        if child:IsA("Frame") and child ~= templateJogador then
            child:Destroy()
        end
    end
    
    -- Obter lista de jogadores no servidor
    local jogadoresServidor = Players:GetPlayers()
    
    -- Criar entradas para cada jogador
    for i, player in ipairs(jogadoresServidor) do
        if player ~= jogador then -- Não incluir o próprio jogador
            local novoJogador = templateJogador:Clone()
            novoJogador.Name = "Jogador_" .. player.Name
            novoJogador.Visible = true
            novoJogador.LayoutOrder = i
            
            -- Configurar dados do jogador
            novoJogador.NomeJogador.Text = player.Name
            novoJogador.AvatarJogador.Image = Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
            
            -- Configurar botão de visitar
            novoJogador.BotaoVisitar.MouseButton1Click:Connect(function()
                VisitarIlha(player.UserId, player.Name)
            end)
            
            -- Configurar botão de curtir
            novoJogador.BotaoCurtir.MouseButton1Click:Connect(function()
                CurtirIlha(player.UserId, player.Name)
            end)
            
            novoJogador.Parent = containerJogadores
        end
    end
    
    -- Mostrar mensagem se não houver outros jogadores
    if #jogadoresServidor <= 1 then
        socialFrame.SemJogadoresLabel.Visible = true
    else
        socialFrame.SemJogadoresLabel.Visible = false
    end
    
    -- Mostrar mensagem de carregamento concluído
    socialFrame.CarregandoLabel.Visible = false
end

--[[
    Funções de Interação com o Servidor
]]

-- Compra um item da loja
local function ComprarItem(itemId, preco, nomeItem)
    -- Verificar se tem moedas suficientes localmente antes de chamar o servidor
    if estadoAtual.moedas < preco then
        MostrarNotificacao("Moedas Insuficientes", "Você não tem DreamCoins suficientes para comprar este item.", "erro")
        return
    end
    
    -- Chamar função remota para comprar o item
    local sucesso, mensagem = comprarItemFunction:InvokeServer(itemId, preco)
    
    if sucesso then
        MostrarNotificacao("Compra Realizada", "Você comprou " .. nomeItem .. " por " .. preco .. " DreamCoins!", "sucesso")
        -- Atualizar inventário se estiver aberto
        if estadoAtual.menuAberto == "inventario" then
            CarregarDadosInventario()
        end
    else
        MostrarNotificacao("Erro na Compra", mensagem or "Não foi possível completar a compra.", "erro")
    end
end

-- Usa um item do inventário (coloca na ilha)
local function UsarItem(itemId, nomeItem)
    -- Ativar modo de colocação
    estadoAtual.modoColocacao = true
    estadoAtual.itemSelecionado = itemId
    
    -- Fechar menus
    FecharTodosMenus()
    
    -- Mostrar instruções
    MostrarNotificacao("Modo Construção", "Clique para posicionar " .. nomeItem .. ". Pressione ESC para cancelar.", "info", 10)
    
    -- Criar preview do item
    local previewItem = Instance.new("Part")
    previewItem.Name = "PreviewItem"
    previewItem.Anchored = true
    previewItem.CanCollide = false
    previewItem.Transparency = 0.5
    previewItem.Size = Vector3.new(1, 1, 1) -- Tamanho padrão, ajustar conforme o item
    previewItem.Material = Enum.Material.Neon
    previewItem.BrickColor = BrickColor.new("Bright green")
    previewItem.Parent = workspace
    
    -- Função para atualizar posição do preview
    local function AtualizarPreview()
        -- Raycasting para encontrar onde o mouse está apontando
        local mouse = jogador:GetMouse()
        local raio = workspace:Raycast(
            personagem.Head.Position,
            (mouse.Hit.Position - personagem.Head.Position).Unit * 100,
            RaycastParams.new()
        )
        
        if raio then
            previewItem.Position = raio.Position + Vector3.new(0, 1, 0)
        end
    end
    
    -- Conectar função de atualização ao RenderStepped
    local conexaoPreview = RunService.RenderStepped:Connect(AtualizarPreview)
    
    -- Função para colocar o item
    local function ColocarItemNaIlha()
        if not estadoAtual.modoColocacao then return end
        
        -- Enviar evento para o servidor
        colocarDecoracaoEvent:FireServer(
            estadoAtual.itemSelecionado,
            previewItem.Position,
            previewItem.CFrame
        )
        
        -- Sair do modo de colocação
        estadoAtual.modoColocacao = false
        estadoAtual.itemSelecionado = nil
        
        if conexaoPreview then
            conexaoPreview:Disconnect()
        end
        
        if previewItem then
            previewItem:Destroy()
        end
        
        MostrarNotificacao("Item Colocado", nomeItem .. " foi colocado com sucesso!", "sucesso")
    end
    
    -- Conectar função de colocação ao clique do mouse
    local conexaoClique = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            ColocarItemNaIlha()
        elseif input.KeyCode == Enum.KeyCode.Escape then
            -- Cancelar colocação
            estadoAtual.modoColocacao = false
            estadoAtual.itemSelecionado = nil
            
            if conexaoPreview then
                conexaoPreview:Disconnect()
            end
            
            if previewItem then
                previewItem:Destroy()
            end
            
            MostrarNotificacao("Colocação Cancelada", "Modo de construção cancelado.", "info")
        end
    end)
    
    -- Limpar conexões quando o modo de colocação terminar
    spawn(function()
        while estadoAtual.modoColocacao do
            wait(0.1)
        end
        
        if conexaoClique then
            conexaoClique:Disconnect()
        end
    end)
end

-- Reclama recompensa de uma missão
local function ReclamarRecompensaMissao(missaoId, recompensa)
    -- Enviar evento para o servidor
    completarMissaoEvent:FireServer(missaoId)
    
    -- Mostrar notificação (o servidor enviará a atualização de moedas)
    MostrarNotificacao("Missão Concluída", "Você recebeu " .. recompensa .. " DreamCoins como recompensa!", "sucesso")
    
    -- Recarregar dados das missões
    CarregarDadosMissoes()
end

-- Visita a ilha de outro jogador
local function VisitarIlha(userId, nomeJogador)
    -- Chamar função remota para visitar a ilha
    local sucesso, mensagem = visitarIlhaFunction:InvokeServer(userId)
    
    if sucesso then
        MostrarNotificacao("Visitando Ilha", "Teleportando para a ilha de " .. nomeJogador .. "...", "info")
        FecharTodosMenus()
    else
        MostrarNotificacao("Erro ao Visitar", mensagem or "Não foi possível visitar esta ilha.", "erro")
    end
end

-- Curte a ilha de outro jogador
local function CurtirIlha(userId, nomeJogador)
    -- Enviar evento para o servidor (a ser implementado)
    -- Por enquanto apenas mostrar notificação
    MostrarNotificacao("Ilha Curtida", "Você curtiu a ilha de " .. nomeJogador .. "!", "sucesso")
    
    -- Desabilitar botão para evitar múltiplos likes
    local socialFrame = framesPrincipais.social
    local containerJogadores = socialFrame:WaitForChild("ContainerJogadores")
    local jogadorFrame = containerJogadores:FindFirstChild("Jogador_" .. nomeJogador)
    
    if jogadorFrame then
        jogadorFrame.BotaoCurtir.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        jogadorFrame.BotaoCurtir.Text = "Curtido"
        jogadorFrame.BotaoCurtir.Active = false
    end
end

--[[
    Conexões de Eventos
]]

-- Conectar evento de atualização de moedas
atualizarMoedasEvent.OnClientEvent:Connect(function(novoValor)
    AtualizarMoedasDisplay(novoValor)
end)

-- Conectar botões da HUD aos menus
hudElements.botaoLoja.MouseButton1Click:Connect(function()
    AbrirMenu("loja")
end)

hudElements.botaoInventario.MouseButton1Click:Connect(function()
    AbrirMenu("inventario")
end)

hudElements.botaoMissoes.MouseButton1Click:Connect(function()
    AbrirMenu("missoes")
end)

hudElements.botaoConstrucao.MouseButton1Click:Connect(function()
    AbrirMenu("construcao")
end)

hudElements.botaoSocial.MouseButton1Click:Connect(function()
    AbrirMenu("social")
end)

hudElements.botaoConfiguracoes.MouseButton1Click:Connect(function()
    AbrirMenu("configuracoes")
end)

-- Conectar botões de fechar em cada menu
for nome, frame in pairs(framesPrincipais) do
    if nome ~= "hud" and frame:FindFirstChild("BotaoFechar") then
        frame.BotaoFechar.MouseButton1Click:Connect(function()
            frame.Visible = false
            estadoAtual.menuAberto = nil
        end)
    end
end

-- Conectar tecla ESC para fechar menus
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Escape then
        if estadoAtual.menuAberto then
            FecharTodosMenus()
        end
    end
end)

--[[
    Inicialização
]]

-- Função de inicialização principal
local function Inicializar()
    print("Inicializando interface principal...")
    
    -- Esconder todos os menus exceto HUD
    for nome, frame in pairs(framesPrincipais) do
        if nome ~= "hud" then
            frame.Visible = false
        end
    end
    
    -- Esconder templates
    local notificacoesFrame = mainGui:WaitForChild("NotificacoesFrame")
    local templateNotificacao = notificacoesFrame:WaitForChild("TemplateNotificacao")
    templateNotificacao.Visible = false
    
    for _, frame in pairs(framesPrincipais) do
        for _, child in pairs(frame:GetDescendants()) do
            if child.Name:find("Template") and child:IsA("GuiObject") then
                child.Visible = false
            end
        end
    end
    
    -- Mostrar mensagem de boas-vindas
    spawn(function()
        wait(1)
        MostrarNotificacao(
            "Bem-vindo à Viva Fantasy Island!", 
            "Construa sua ilha dos sonhos, complete missões e visite outros jogadores!",
            "info",
            8
        )
    end)
    
    print("Interface principal inicializada com sucesso!")
end

-- Iniciar a interface
Inicializar()
