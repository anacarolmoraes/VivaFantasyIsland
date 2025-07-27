--[[
    LojaGui.lua
    
    Script cliente para a interface da loja do jogo "Viva Fantasy Island"
    Gerencia a exibição de itens, categorias, compras e feedback visual
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Jogador local
local jogador = Players.LocalPlayer
local personagem = jogador.Character or jogador.CharacterAdded:Wait()

-- Referências à GUI
local mainGui = script.Parent
local lojaFrame = mainGui:WaitForChild("LojaFrame")

-- Eventos Remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local comprarItemEvent = RemoteEvents:WaitForChild("ComprarItem") -- Criar este RemoteEvent
local atualizarHUDEvent = RemoteEvents:WaitForChild("AtualizarHUD")

-- Configurações de animação
local configAnimacao = {
    duracao = 0.3,
    estilo = Enum.EasingStyle.Quad,
    direcao = Enum.EasingDirection.Out
}

-- Catálogo completo de itens da loja
local catalogoItens = {
    decoracoes = {
        {
            id = "cerca_madeira",
            nome = "Cerca de Madeira",
            descricao = "Uma cerca rústica para delimitar sua propriedade.",
            preco = 50,
            icone = "rbxassetid://6797380005", -- ID de um asset no Roblox (placeholder)
            categoria = "decoracoes",
            modelo3d = "cerca_madeira" -- ID do modelo no ServerStorage
        },
        {
            id = "fonte_agua",
            nome = "Fonte de Água",
            descricao = "Uma bela fonte que adiciona charme à sua ilha.",
            preco = 250,
            icone = "rbxassetid://6797380117",
            categoria = "decoracoes",
            modelo3d = "fonte_agua"
        },
        {
            id = "estatua_pequena",
            nome = "Estátua de Pedra",
            descricao = "Uma pequena estátua decorativa.",
            preco = 150,
            icone = "rbxassetid://6797380223",
            categoria = "decoracoes",
            modelo3d = "estatua_pequena"
        }
    },
    moveis = {
        {
            id = "mesa_madeira",
            nome = "Mesa de Madeira",
            descricao = "Uma mesa robusta para sua casa.",
            preco = 120,
            icone = "rbxassetid://6797380329",
            categoria = "moveis",
            modelo3d = "mesa_madeira"
        },
        {
            id = "cadeira_simples",
            nome = "Cadeira Simples",
            descricao = "Uma cadeira básica e confortável.",
            preco = 80,
            icone = "rbxassetid://6797380438",
            categoria = "moveis",
            modelo3d = "cadeira_simples"
        },
        {
            id = "cama_madeira",
            nome = "Cama de Madeira",
            descricao = "Uma cama aconchegante para sua casa.",
            preco = 200,
            icone = "rbxassetid://6797380547",
            categoria = "moveis",
            modelo3d = "cama_madeira"
        }
    },
    plantas = {
        {
            id = "arvore_pequena",
            nome = "Árvore Pequena",
            descricao = "Uma árvore jovem para sua ilha.",
            preco = 100,
            icone = "rbxassetid://6797380656",
            categoria = "plantas",
            modelo3d = "arvore_pequena"
        },
        {
            id = "flor_azul",
            nome = "Flores Azuis",
            descricao = "Um canteiro de belas flores azuis.",
            preco = 50,
            icone = "rbxassetid://6797380765",
            categoria = "plantas",
            modelo3d = "flor_azul"
        },
        {
            id = "arbusto_decorativo",
            nome = "Arbusto Decorativo",
            descricao = "Um arbusto bem aparado para decoração.",
            preco = 75,
            icone = "rbxassetid://6797380874",
            categoria = "plantas",
            modelo3d = "arbusto_decorativo"
        }
    },
    especiais = {
        {
            id = "fonte_magica",
            nome = "Fonte Mágica",
            descricao = "Uma fonte que brilha com cores mágicas.",
            preco = 500,
            icone = "rbxassetid://6797380983",
            categoria = "especiais",
            modelo3d = "fonte_magica"
        },
        {
            id = "estatua_dragao",
            nome = "Estátua de Dragão",
            descricao = "Uma impressionante estátua de dragão.",
            preco = 750,
            icone = "rbxassetid://6797381092",
            categoria = "especiais",
            modelo3d = "estatua_dragao"
        }
    }
}

-- Elementos da interface
local elementosLoja = {
    categorias = {},
    botoesCategorias = {},
    itensVisiveis = {},
    itemSelecionado = nil,
    categoriaAtual = "decoracoes",
    termoPesquisa = ""
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

-- Função para criar a interface básica da loja
local function CriarInterfaceLoja()
    -- Limpar interface existente
    for _, item in pairs(lojaFrame:GetChildren()) do
        if item:IsA("Frame") or item:IsA("ScrollingFrame") or item:IsA("TextButton") then
            item:Destroy()
        end
    end
    
    -- Criar título
    local tituloLoja = Instance.new("TextLabel")
    tituloLoja.Name = "TituloLoja"
    tituloLoja.Size = UDim2.new(1, 0, 0, 50)
    tituloLoja.Position = UDim2.new(0, 0, 0, 0)
    tituloLoja.BackgroundTransparency = 1
    tituloLoja.TextColor3 = Color3.new(1, 1, 1)
    tituloLoja.TextSize = 24
    tituloLoja.Font = Enum.Font.SourceSansBold
    tituloLoja.Text = "Loja de Decorações"
    tituloLoja.Parent = lojaFrame
    
    -- Criar barra de pesquisa
    local barraPesquisa = Instance.new("Frame")
    barraPesquisa.Name = "BarraPesquisa"
    barraPesquisa.Size = UDim2.new(0.8, 0, 0, 40)
    barraPesquisa.Position = UDim2.new(0.1, 0, 0, 60)
    barraPesquisa.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    barraPesquisa.BorderSizePixel = 0
    barraPesquisa.Parent = lojaFrame
    
    local campoPesquisa = Instance.new("TextBox")
    campoPesquisa.Name = "CampoPesquisa"
    campoPesquisa.Size = UDim2.new(1, -20, 1, -10)
    campoPesquisa.Position = UDim2.new(0, 10, 0, 5)
    campoPesquisa.BackgroundTransparency = 1
    campoPesquisa.TextColor3 = Color3.new(1, 1, 1)
    campoPesquisa.TextSize = 16
    campoPesquisa.Font = Enum.Font.SourceSans
    campoPesquisa.PlaceholderText = "Pesquisar itens..."
    campoPesquisa.Text = ""
    campoPesquisa.ClearTextOnFocus = false
    campoPesquisa.Parent = barraPesquisa
    
    -- Conectar evento de pesquisa
    campoPesquisa:GetPropertyChangedSignal("Text"):Connect(function()
        elementosLoja.termoPesquisa = campoPesquisa.Text:lower()
        AtualizarItensPorCategoria(elementosLoja.categoriaAtual)
    end)
    
    -- Criar botões de categorias
    local categoriaFrame = Instance.new("Frame")
    categoriaFrame.Name = "CategoriaFrame"
    categoriaFrame.Size = UDim2.new(1, 0, 0, 50)
    categoriaFrame.Position = UDim2.new(0, 0, 0, 110)
    categoriaFrame.BackgroundTransparency = 1
    categoriaFrame.Parent = lojaFrame
    
    local categorias = {"decoracoes", "moveis", "plantas", "especiais"}
    local nomesCategorias = {
        decoracoes = "Decorações",
        moveis = "Móveis",
        plantas = "Plantas",
        especiais = "Especiais"
    }
    
    for i, categoria in ipairs(categorias) do
        local botaoCategoria = Instance.new("TextButton")
        botaoCategoria.Name = "Categoria_" .. categoria
        botaoCategoria.Size = UDim2.new(0.25, -10, 1, -10)
        botaoCategoria.Position = UDim2.new(0.25 * (i-1), 5, 0, 5)
        botaoCategoria.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        botaoCategoria.TextColor3 = Color3.new(1, 1, 1)
        botaoCategoria.TextSize = 16
        botaoCategoria.Font = Enum.Font.SourceSansBold
        botaoCategoria.Text = nomesCategorias[categoria] or categoria
        botaoCategoria.BorderSizePixel = 0
        botaoCategoria.Parent = categoriaFrame
        
        elementosLoja.botoesCategorias[categoria] = botaoCategoria
        
        -- Conectar evento de clique
        botaoCategoria.MouseButton1Click:Connect(function()
            SelecionarCategoria(categoria)
        end)
    end
    
    -- Criar frame de itens com scroll
    local itensFrame = Instance.new("ScrollingFrame")
    itensFrame.Name = "ItensFrame"
    itensFrame.Size = UDim2.new(0.65, 0, 1, -170)
    itensFrame.Position = UDim2.new(0, 10, 0, 170)
    itensFrame.BackgroundTransparency = 0.9
    itensFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    itensFrame.BorderSizePixel = 0
    itensFrame.ScrollBarThickness = 6
    itensFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    itensFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    itensFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    itensFrame.Parent = lojaFrame
    
    elementosLoja.itensFrame = itensFrame
    
    -- Criar frame de detalhes do item
    local detalhesFrame = Instance.new("Frame")
    detalhesFrame.Name = "DetalhesFrame"
    detalhesFrame.Size = UDim2.new(0.35, -20, 1, -170)
    detalhesFrame.Position = UDim2.new(0.65, 10, 0, 170)
    detalhesFrame.BackgroundTransparency = 0.5
    detalhesFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    detalhesFrame.BorderSizePixel = 0
    detalhesFrame.Visible = false
    detalhesFrame.Parent = lojaFrame
    
    -- Elementos do frame de detalhes
    local itemImagem = Instance.new("ImageLabel")
    itemImagem.Name = "ItemImagem"
    itemImagem.Size = UDim2.new(0, 100, 0, 100)
    itemImagem.Position = UDim2.new(0.5, 0, 0, 20)
    itemImagem.AnchorPoint = Vector2.new(0.5, 0)
    itemImagem.BackgroundTransparency = 1
    itemImagem.Parent = detalhesFrame
    
    local itemNome = Instance.new("TextLabel")
    itemNome.Name = "ItemNome"
    itemNome.Size = UDim2.new(1, -20, 0, 30)
    itemNome.Position = UDim2.new(0, 10, 0, 130)
    itemNome.BackgroundTransparency = 1
    itemNome.TextColor3 = Color3.new(1, 1, 1)
    itemNome.TextSize = 18
    itemNome.Font = Enum.Font.SourceSansBold
    itemNome.Text = ""
    itemNome.TextWrapped = true
    itemNome.Parent = detalhesFrame
    
    local itemDescricao = Instance.new("TextLabel")
    itemDescricao.Name = "ItemDescricao"
    itemDescricao.Size = UDim2.new(1, -20, 0, 60)
    itemDescricao.Position = UDim2.new(0, 10, 0, 170)
    itemDescricao.BackgroundTransparency = 1
    itemDescricao.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    itemDescricao.TextSize = 14
    itemDescricao.Font = Enum.Font.SourceSans
    itemDescricao.Text = ""
    itemDescricao.TextWrapped = true
    itemDescricao.TextXAlignment = Enum.TextXAlignment.Left
    itemDescricao.TextYAlignment = Enum.TextYAlignment.Top
    itemDescricao.Parent = detalhesFrame
    
    local itemPreco = Instance.new("TextLabel")
    itemPreco.Name = "ItemPreco"
    itemPreco.Size = UDim2.new(1, -20, 0, 30)
    itemPreco.Position = UDim2.new(0, 10, 0, 240)
    itemPreco.BackgroundTransparency = 1
    itemPreco.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
    itemPreco.TextSize = 18
    itemPreco.Font = Enum.Font.SourceSansBold
    itemPreco.Text = ""
    itemPreco.Parent = detalhesFrame
    
    local botaoComprar = Instance.new("TextButton")
    botaoComprar.Name = "BotaoComprar"
    botaoComprar.Size = UDim2.new(0.8, 0, 0, 40)
    botaoComprar.Position = UDim2.new(0.1, 0, 0, 280)
    botaoComprar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
    botaoComprar.TextColor3 = Color3.new(1, 1, 1)
    botaoComprar.TextSize = 18
    botaoComprar.Font = Enum.Font.SourceSansBold
    botaoComprar.Text = "COMPRAR"
    botaoComprar.BorderSizePixel = 0
    botaoComprar.Parent = detalhesFrame
    
    elementosLoja.detalhesFrame = detalhesFrame
    elementosLoja.itemImagem = itemImagem
    elementosLoja.itemNome = itemNome
    elementosLoja.itemDescricao = itemDescricao
    elementosLoja.itemPreco = itemPreco
    elementosLoja.botaoComprar = botaoComprar
    
    -- Conectar evento de compra
    botaoComprar.MouseButton1Click:Connect(ComprarItemSelecionado)
    
    -- Botão para fechar a loja
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
    botaoFechar.Parent = lojaFrame
    
    botaoFechar.MouseButton1Click:Connect(function()
        lojaFrame.Visible = false
    end)
    
    -- Selecionar categoria inicial
    SelecionarCategoria("decoracoes")
end

-- Função para selecionar uma categoria
function SelecionarCategoria(categoria)
    -- Atualizar visual dos botões
    for cat, botao in pairs(elementosLoja.botoesCategorias) do
        if cat == categoria then
            botao.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde para selecionado
        else
            botao.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Cinza para não selecionado
        end
    end
    
    elementosLoja.categoriaAtual = categoria
    AtualizarItensPorCategoria(categoria)
end

-- Função para atualizar os itens exibidos por categoria
function AtualizarItensPorCategoria(categoria)
    -- Limpar itens atuais
    for _, item in pairs(elementosLoja.itensVisiveis) do
        item:Destroy()
    end
    elementosLoja.itensVisiveis = {}
    
    -- Obter itens da categoria
    local itens = catalogoItens[categoria] or {}
    local itensFiltrados = {}
    
    -- Aplicar filtro de pesquisa
    if elementosLoja.termoPesquisa and elementosLoja.termoPesquisa ~= "" then
        for _, item in ipairs(itens) do
            if string.find(item.nome:lower(), elementosLoja.termoPesquisa) or 
               string.find(item.descricao:lower(), elementosLoja.termoPesquisa) then
                table.insert(itensFiltrados, item)
            end
        end
    else
        itensFiltrados = itens
    end
    
    -- Criar elementos de interface para cada item
    for i, item in ipairs(itensFiltrados) do
        local itemFrame = CriarElementoItem(item, i)
        table.insert(elementosLoja.itensVisiveis, itemFrame)
    end
    
    -- Esconder detalhes se não houver itens
    if #itensFiltrados == 0 then
        elementosLoja.detalhesFrame.Visible = false
    end
end

-- Função para criar um elemento de item na lista
function CriarElementoItem(item, indice)
    local itensFrame = elementosLoja.itensFrame
    
    -- Calcular posição
    local posY = (indice - 1) * 110
    
    -- Criar frame do item
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "Item_" .. item.id
    itemFrame.Size = UDim2.new(1, -20, 0, 100)
    itemFrame.Position = UDim2.new(0, 10, 0, posY + 10)
    itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    itemFrame.BorderSizePixel = 0
    itemFrame.Parent = itensFrame
    
    -- Imagem do item
    local itemImagem = Instance.new("ImageLabel")
    itemImagem.Name = "Imagem"
    itemImagem.Size = UDim2.new(0, 80, 0, 80)
    itemImagem.Position = UDim2.new(0, 10, 0, 10)
    itemImagem.BackgroundTransparency = 1
    itemImagem.Image = item.icone
    itemImagem.Parent = itemFrame
    
    -- Nome do item
    local itemNome = Instance.new("TextLabel")
    itemNome.Name = "Nome"
    itemNome.Size = UDim2.new(1, -110, 0, 30)
    itemNome.Position = UDim2.new(0, 100, 0, 10)
    itemNome.BackgroundTransparency = 1
    itemNome.TextColor3 = Color3.new(1, 1, 1)
    itemNome.TextSize = 16
    itemNome.Font = Enum.Font.SourceSansBold
    itemNome.Text = item.nome
    itemNome.TextXAlignment = Enum.TextXAlignment.Left
    itemNome.Parent = itemFrame
    
    -- Descrição curta
    local itemDescricao = Instance.new("TextLabel")
    itemDescricao.Name = "Descricao"
    itemDescricao.Size = UDim2.new(1, -110, 0, 40)
    itemDescricao.Position = UDim2.new(0, 100, 0, 40)
    itemDescricao.BackgroundTransparency = 1
    itemDescricao.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    itemDescricao.TextSize = 14
    itemDescricao.Font = Enum.Font.SourceSans
    itemDescricao.Text = item.descricao
    itemDescricao.TextWrapped = true
    itemDescricao.TextXAlignment = Enum.TextXAlignment.Left
    itemDescricao.TextYAlignment = Enum.TextYAlignment.Top
    itemDescricao.Parent = itemFrame
    
    -- Preço
    local itemPreco = Instance.new("TextLabel")
    itemPreco.Name = "Preco"
    itemPreco.Size = UDim2.new(0, 100, 0, 20)
    itemPreco.Position = UDim2.new(1, -110, 0, 70)
    itemPreco.BackgroundTransparency = 1
    itemPreco.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
    itemPreco.TextSize = 16
    itemPreco.Font = Enum.Font.SourceSansBold
    itemPreco.Text = FormatarNumero(item.preco) .. " 💰"
    itemPreco.Parent = itemFrame
    
    -- Botão de seleção (todo o frame é clicável)
    local botaoSelecionar = Instance.new("TextButton")
    botaoSelecionar.Name = "BotaoSelecionar"
    botaoSelecionar.Size = UDim2.new(1, 0, 1, 0)
    botaoSelecionar.BackgroundTransparency = 1
    botaoSelecionar.Text = ""
    botaoSelecionar.Parent = itemFrame
    
    -- Conectar evento de clique
    botaoSelecionar.MouseButton1Click:Connect(function()
        SelecionarItem(item)
    end)
    
    return itemFrame
end

-- Função para selecionar um item
function SelecionarItem(item)
    elementosLoja.itemSelecionado = item
    
    -- Atualizar detalhes
    elementosLoja.itemImagem.Image = item.icone
    elementosLoja.itemNome.Text = item.nome
    elementosLoja.itemDescricao.Text = item.descricao
    elementosLoja.itemPreco.Text = FormatarNumero(item.preco) .. " DreamCoins"
    
    -- Mostrar frame de detalhes
    elementosLoja.detalhesFrame.Visible = true
    
    -- Atualizar botão de compra
    local moedas = tonumber(mainGui.HUD.MoedasFrame.ValorMoedas.Text) or 0
    
    if moedas >= item.preco then
        elementosLoja.botaoComprar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
        elementosLoja.botaoComprar.Text = "COMPRAR"
    else
        elementosLoja.botaoComprar.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Cinza
        elementosLoja.botaoComprar.Text = "MOEDAS INSUFICIENTES"
    end
end

-- Função para comprar o item selecionado
function ComprarItemSelecionado()
    local item = elementosLoja.itemSelecionado
    if not item then return end
    
    -- Verificar se tem moedas suficientes
    local moedas = tonumber(mainGui.HUD.MoedasFrame.ValorMoedas.Text) or 0
    
    if moedas < item.preco then
        MostrarNotificacao("Moedas Insuficientes", "Você não tem DreamCoins suficientes para comprar este item.", "erro")
        return
    end
    
    -- Enviar solicitação de compra para o servidor
    -- Enviamos **apenas** o itemId (o servidor não espera o segundo parâmetro)
    comprarItemEvent:FireServer(item.id)
    
    -- Feedback visual temporário (será atualizado pelo servidor)
    elementosLoja.botaoComprar.Text = "PROCESSANDO..."
    elementosLoja.botaoComprar.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Cinza
end

-- Função para processar resposta de compra do servidor
local function ProcessarRespostaCompra(sucesso, itemId, novasMoedas, mensagem)
    if sucesso then
        -- Atualizar moedas localmente (o servidor também enviará uma atualização)
        mainGui.HUD.MoedasFrame.ValorMoedas.Text = tostring(novasMoedas)
        
        -- Mostrar notificação de sucesso
        MostrarNotificacao("Compra Realizada", mensagem or "Item adquirido com sucesso!", "sucesso")
        
        -- Efeito visual de compra bem-sucedida
        local item = elementosLoja.itemSelecionado
        if item and item.id == itemId then
            -- Atualizar botão
            elementosLoja.botaoComprar.Text = "COMPRADO!"
            elementosLoja.botaoComprar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
            
            -- Após um tempo, voltar ao normal
            task.delay(2, function()
                if elementosLoja.itemSelecionado and elementosLoja.itemSelecionado.id == itemId then
                    elementosLoja.botaoComprar.Text = "COMPRAR"
                end
            end)
        end
    else
        -- Mostrar notificação de erro
        MostrarNotificacao("Erro na Compra", mensagem or "Não foi possível completar a compra.", "erro")
        
        -- Restaurar botão
        elementosLoja.botaoComprar.Text = "COMPRAR"
        elementosLoja.botaoComprar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
    end
end

-- Função para mostrar preview 3D do item
local function MostrarPreview3D(itemId)
    -- Esta função seria implementada para mostrar um modelo 3D
    -- Por enquanto, apenas um placeholder
    print("Mostrando preview 3D para o item: " .. itemId)
    
    -- Implementação futura:
    -- 1. Criar um ViewportFrame
    -- 2. Carregar o modelo 3D do item
    -- 3. Adicionar ao ViewportFrame com rotação automática
end

-- Inicializar a interface da loja
local function Inicializar()
    print("📱 Loja: Inicializando interface da loja...")
    
    -- Criar a interface básica
    CriarInterfaceLoja()
    
    -- Conectar eventos remotos
    comprarItemEvent.OnClientEvent:Connect(ProcessarRespostaCompra)
    
    print("📱 Loja: Interface inicializada com sucesso!")
end

-- Iniciar quando o script carregar
Inicializar()
