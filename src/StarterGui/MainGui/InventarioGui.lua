--[[
    InventarioGui.lua
    
    Script cliente para a interface de inventário do jogo "Viva Fantasy Island"
    Gerencia a exibição de itens possuídos pelo jogador, categorização,
    pesquisa, e interação com o sistema de construção.
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Jogador local
local jogador = Players.LocalPlayer
local personagem = jogador.Character or jogador.CharacterAdded:Wait()

-- Referências à GUI
local mainGui = script.Parent
local inventarioFrame = mainGui:WaitForChild("InventarioFrame")

-- Referência ao sistema de construção
local sistemaConstrucao = script.Parent:FindFirstChild("SistemaConstrucao")

-- Eventos Remotos
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local atualizarInventarioEvent = RemoteEvents:WaitForChild("AtualizarInventario")
local colocarDecoracaoEvent = RemoteEvents:WaitForChild("ColocarDecoracao")
local removerDecoracaoEvent = RemoteEvents:WaitForChild("RemoverDecoracao")

-- Configurações de animação
local configAnimacao = {
    duracao = 0.3,
    estilo = Enum.EasingStyle.Quad,
    direcao = Enum.EasingDirection.Out
}

-- Variáveis de estado para o inventário
local estadoInventario = {
    itens = {}, -- Itens no inventário {[itemId] = {info do item, quantidade}}
    itensFiltrados = {}, -- Itens após aplicar filtros
    categoriaAtual = "todos", -- Categoria selecionada
    termoPesquisa = "", -- Termo de pesquisa atual
    ordenacao = "alfabetica", -- Método de ordenação atual
    itemSelecionado = nil, -- Item atualmente selecionado
    modoConstrucao = false, -- Se está em modo de construção
    itemArrastando = nil, -- Item sendo arrastado
    gridCelulas = {}, -- Células do grid visual
    slotSelecionado = nil, -- Slot atualmente selecionado
    previewItem = nil, -- Referência ao preview do item
    conexoes = {} -- Armazena conexões para limpeza
}

-- Mapeamento de categorias
local categorias = {
    todos = "Todos os Itens",
    decoracoes = "Decorações",
    moveis = "Móveis",
    plantas = "Plantas",
    especiais = "Especiais"
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
    local notificacoesFrame = mainGui:FindFirstChild("NotificacoesFrame")
    if not notificacoesFrame then
        -- Criar frame de notificações se não existir
        notificacoesFrame = Instance.new("Frame")
        notificacoesFrame.Name = "NotificacoesFrame"
        notificacoesFrame.Size = UDim2.new(0.3, 0, 1, 0)
        notificacoesFrame.Position = UDim2.new(0.7, 0, 0, 0)
        notificacoesFrame.BackgroundTransparency = 1
        notificacoesFrame.Parent = mainGui
    end
    
    local templateNotificacao = notificacoesFrame:FindFirstChild("TemplateNotificacao")
    if not templateNotificacao then
        -- Criar template se não existir
        templateNotificacao = Instance.new("Frame")
        templateNotificacao.Name = "TemplateNotificacao"
        templateNotificacao.Size = UDim2.new(0.9, 0, 0, 70)
        templateNotificacao.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
        templateNotificacao.BorderSizePixel = 0
        templateNotificacao.Visible = false
        templateNotificacao.Parent = notificacoesFrame
    end
    
    local novaNotificacao = templateNotificacao:Clone()
    novaNotificacao.Name = "Notificacao_" .. os.time()
    novaNotificacao.Visible = true
    
    -- Configurar aparência baseado no tipo
    if tipo == "sucesso" then
        novaNotificacao.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
    elseif tipo == "erro" then
        novaNotificacao.BackgroundColor3 = Color3.fromRGB(211, 47, 47) -- Vermelho
    else
        novaNotificacao.BackgroundColor3 = Color3.fromRGB(33, 150, 243) -- Azul (info)
    end
    
    -- Configurar texto
    local tituloLabel = novaNotificacao:FindFirstChild("Titulo")
    if not tituloLabel then
        tituloLabel = Instance.new("TextLabel")
        tituloLabel.Name = "Titulo"
        tituloLabel.Size = UDim2.new(1, 0, 0, 20)
        tituloLabel.Position = UDim2.new(0, 0, 0, 0)
        tituloLabel.BackgroundTransparency = 1
        tituloLabel.TextColor3 = Color3.new(1, 1, 1)
        tituloLabel.TextSize = 14
        tituloLabel.Font = Enum.Font.SourceSansBold
        tituloLabel.Parent = novaNotificacao
    end
    tituloLabel.Text = titulo
    
    local mensagemLabel = novaNotificacao:FindFirstChild("Mensagem")
    if not mensagemLabel then
        mensagemLabel = Instance.new("TextLabel")
        mensagemLabel.Name = "Mensagem"
        mensagemLabel.Size = UDim2.new(1, 0, 0, 40)
        mensagemLabel.Position = UDim2.new(0, 0, 0, 20)
        mensagemLabel.BackgroundTransparency = 1
        mensagemLabel.TextColor3 = Color3.new(1, 1, 1)
        mensagemLabel.TextSize = 12
        mensagemLabel.Font = Enum.Font.SourceSans
        mensagemLabel.TextWrapped = true
        mensagemLabel.Parent = novaNotificacao
    end
    mensagemLabel.Text = mensagem
    
    -- Posicionar notificação
    novaNotificacao.Position = UDim2.new(1, 300, 1, -80) -- Começa fora da tela
    novaNotificacao.AnchorPoint = Vector2.new(1, 1)
    novaNotificacao.Parent = notificacoesFrame
    
    -- Animação de entrada
    local tweenEntrada = CriarTween(novaNotificacao, {Position = UDim2.new(1, -20, 1, -80)}, 0.5)
    tweenEntrada:Play()
    
    -- Animação de saída após duração
    task.delay(duracao, function()
        local tweenSaida = CriarTween(novaNotificacao, {Position = UDim2.new(1, 300, 1, -80)}, 0.5)
        tweenSaida:Play()
        tweenSaida.Completed:Connect(function()
            novaNotificacao:Destroy()
        end)
    end)
end

-- Função para criar a interface básica do inventário
local function CriarInterfaceInventario()
    -- Verificar se o inventarioFrame existe
    if not inventarioFrame then
        warn("InventarioGui: Frame do inventário não encontrado!")
        return
    end
    
    -- Limpar interface existente
    for _, item in pairs(inventarioFrame:GetChildren()) do
        if item:IsA("Frame") or item:IsA("ScrollingFrame") or item:IsA("TextButton") then
            item:Destroy()
        end
    end
    
    -- Criar título
    local tituloInventario = Instance.new("TextLabel")
    tituloInventario.Name = "TituloInventario"
    tituloInventario.Size = UDim2.new(1, 0, 0, 50)
    tituloInventario.Position = UDim2.new(0, 0, 0, 0)
    tituloInventario.BackgroundTransparency = 1
    tituloInventario.TextColor3 = Color3.new(1, 1, 1)
    tituloInventario.TextSize = 24
    tituloInventario.Font = Enum.Font.SourceSansBold
    tituloInventario.Text = "Meu Inventário"
    tituloInventario.Parent = inventarioFrame
    
    -- Criar barra de pesquisa
    local barraPesquisa = Instance.new("Frame")
    barraPesquisa.Name = "BarraPesquisa"
    barraPesquisa.Size = UDim2.new(0.6, 0, 0, 40)
    barraPesquisa.Position = UDim2.new(0.05, 0, 0, 60)
    barraPesquisa.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    barraPesquisa.BorderSizePixel = 0
    barraPesquisa.Parent = inventarioFrame
    
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
    local conexaoPesquisa = campoPesquisa:GetPropertyChangedSignal("Text"):Connect(function()
        estadoInventario.termoPesquisa = campoPesquisa.Text:lower()
        AtualizarItensFiltrados()
        AtualizarGridInventario()
    end)
    table.insert(estadoInventario.conexoes, conexaoPesquisa)
    
    -- Criar dropdown de ordenação
    local dropdownOrdenacao = Instance.new("Frame")
    dropdownOrdenacao.Name = "DropdownOrdenacao"
    dropdownOrdenacao.Size = UDim2.new(0.3, 0, 0, 40)
    dropdownOrdenacao.Position = UDim2.new(0.65, 0, 0, 60)
    dropdownOrdenacao.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    dropdownOrdenacao.BorderSizePixel = 0
    dropdownOrdenacao.Parent = inventarioFrame
    
    local labelOrdenacao = Instance.new("TextLabel")
    labelOrdenacao.Name = "LabelOrdenacao"
    labelOrdenacao.Size = UDim2.new(0.4, 0, 1, 0)
    labelOrdenacao.Position = UDim2.new(0, 0, 0, 0)
    labelOrdenacao.BackgroundTransparency = 1
    labelOrdenacao.TextColor3 = Color3.new(1, 1, 1)
    labelOrdenacao.TextSize = 14
    labelOrdenacao.Font = Enum.Font.SourceSans
    labelOrdenacao.Text = "Ordenar por:"
    labelOrdenacao.Parent = dropdownOrdenacao
    
    local botaoOrdenacao = Instance.new("TextButton")
    botaoOrdenacao.Name = "BotaoOrdenacao"
    botaoOrdenacao.Size = UDim2.new(0.6, -10, 1, -10)
    botaoOrdenacao.Position = UDim2.new(0.4, 5, 0, 5)
    botaoOrdenacao.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    botaoOrdenacao.TextColor3 = Color3.new(1, 1, 1)
    botaoOrdenacao.TextSize = 14
    botaoOrdenacao.Font = Enum.Font.SourceSans
    botaoOrdenacao.Text = "Alfabética ▼"
    botaoOrdenacao.Parent = dropdownOrdenacao
    
    -- Menu de opções de ordenação
    local menuOrdenacao = Instance.new("Frame")
    menuOrdenacao.Name = "MenuOrdenacao"
    menuOrdenacao.Size = UDim2.new(0.6, -10, 0, 90)
    menuOrdenacao.Position = UDim2.new(0.4, 5, 1, 0)
    menuOrdenacao.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    menuOrdenacao.BorderSizePixel = 0
    menuOrdenacao.Visible = false
    menuOrdenacao.ZIndex = 5
    menuOrdenacao.Parent = dropdownOrdenacao
    
    local opcoesOrdenacao = {
        {id = "alfabetica", nome = "Alfabética"},
        {id = "quantidade", nome = "Quantidade"},
        {id = "preco", nome = "Preço"}
    }
    
    for i, opcao in ipairs(opcoesOrdenacao) do
        local botaoOpcao = Instance.new("TextButton")
        botaoOpcao.Name = "Opcao_" .. opcao.id
        botaoOpcao.Size = UDim2.new(1, 0, 0, 30)
        botaoOpcao.Position = UDim2.new(0, 0, 0, (i-1) * 30)
        botaoOpcao.BackgroundTransparency = 0.5
        botaoOpcao.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        botaoOpcao.TextColor3 = Color3.new(1, 1, 1)
        botaoOpcao.TextSize = 14
        botaoOpcao.Font = Enum.Font.SourceSans
        botaoOpcao.Text = opcao.nome
        botaoOpcao.ZIndex = 6
        botaoOpcao.Parent = menuOrdenacao
        
        local conexaoOpcao = botaoOpcao.MouseButton1Click:Connect(function()
            estadoInventario.ordenacao = opcao.id
            botaoOrdenacao.Text = opcao.nome .. " ▼"
            menuOrdenacao.Visible = false
            AtualizarItensFiltrados()
            AtualizarGridInventario()
        end)
        table.insert(estadoInventario.conexoes, conexaoOpcao)
    end
    
    local conexaoOrdenacao = botaoOrdenacao.MouseButton1Click:Connect(function()
        menuOrdenacao.Visible = not menuOrdenacao.Visible
    end)
    table.insert(estadoInventario.conexoes, conexaoOrdenacao)
    
    -- Criar botões de categorias
    local categoriaFrame = Instance.new("Frame")
    categoriaFrame.Name = "CategoriaFrame"
    categoriaFrame.Size = UDim2.new(1, 0, 0, 50)
    categoriaFrame.Position = UDim2.new(0, 0, 0, 110)
    categoriaFrame.BackgroundTransparency = 1
    categoriaFrame.Parent = inventarioFrame
    
    local botoesCategorias = {}
    local categoriasList = {"todos", "decoracoes", "moveis", "plantas", "especiais"}
    
    for i, categoriaId in ipairs(categoriasList) do
        local larguraBotao = 1 / #categoriasList
        
        local botaoCategoria = Instance.new("TextButton")
        botaoCategoria.Name = "Categoria_" .. categoriaId
        botaoCategoria.Size = UDim2.new(larguraBotao, -10, 1, -10)
        botaoCategoria.Position = UDim2.new(larguraBotao * (i-1), 5, 0, 5)
        botaoCategoria.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        botaoCategoria.TextColor3 = Color3.new(1, 1, 1)
        botaoCategoria.TextSize = 14
        botaoCategoria.Font = Enum.Font.SourceSansBold
        botaoCategoria.Text = categorias[categoriaId] or categoriaId
        botaoCategoria.BorderSizePixel = 0
        botaoCategoria.Parent = categoriaFrame
        
        botoesCategorias[categoriaId] = botaoCategoria
        
        -- Conectar evento de clique
        local conexaoCategoria = botaoCategoria.MouseButton1Click:Connect(function()
            SelecionarCategoria(categoriaId, botoesCategorias)
        end)
        table.insert(estadoInventario.conexoes, conexaoCategoria)
    end
    
    -- Criar grid de inventário com scroll
    local gridFrame = Instance.new("ScrollingFrame")
    gridFrame.Name = "GridFrame"
    gridFrame.Size = UDim2.new(0.7, 0, 1, -170)
    gridFrame.Position = UDim2.new(0, 10, 0, 170)
    gridFrame.BackgroundTransparency = 0.9
    gridFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    gridFrame.BorderSizePixel = 0
    gridFrame.ScrollBarThickness = 6
    gridFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    gridFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gridFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    gridFrame.Parent = inventarioFrame
    
    -- Criar frame de detalhes do item
    local detalhesFrame = Instance.new("Frame")
    detalhesFrame.Name = "DetalhesFrame"
    detalhesFrame.Size = UDim2.new(0.3, -20, 1, -170)
    detalhesFrame.Position = UDim2.new(0.7, 10, 0, 170)
    detalhesFrame.BackgroundTransparency = 0.5
    detalhesFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    detalhesFrame.BorderSizePixel = 0
    detalhesFrame.Visible = false
    detalhesFrame.Parent = inventarioFrame
    
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
    
    local itemQuantidade = Instance.new("TextLabel")
    itemQuantidade.Name = "ItemQuantidade"
    itemQuantidade.Size = UDim2.new(1, -20, 0, 30)
    itemQuantidade.Position = UDim2.new(0, 10, 0, 240)
    itemQuantidade.BackgroundTransparency = 1
    itemQuantidade.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
    itemQuantidade.TextSize = 18
    itemQuantidade.Font = Enum.Font.SourceSansBold
    itemQuantidade.Text = ""
    itemQuantidade.Parent = detalhesFrame
    
    local botaoColocar = Instance.new("TextButton")
    botaoColocar.Name = "BotaoColocar"
    botaoColocar.Size = UDim2.new(0.8, 0, 0, 40)
    botaoColocar.Position = UDim2.new(0.1, 0, 0, 280)
    botaoColocar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
    botaoColocar.TextColor3 = Color3.new(1, 1, 1)
    botaoColocar.TextSize = 18
    botaoColocar.Font = Enum.Font.SourceSansBold
    botaoColocar.Text = "COLOCAR NA ILHA"
    botaoColocar.BorderSizePixel = 0
    botaoColocar.Parent = detalhesFrame
    
    -- Botão para fechar o inventário
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
    botaoFechar.Parent = inventarioFrame
    
    local conexaoFechar = botaoFechar.MouseButton1Click:Connect(function()
        inventarioFrame.Visible = false
        if estadoInventario.modoConstrucao then
            DesativarModoConstrucao()
        end
    end)
    table.insert(estadoInventario.conexoes, conexaoFechar)
    
    -- Conectar botão de colocar item
    local conexaoColocar = botaoColocar.MouseButton1Click:Connect(function()
        if estadoInventario.itemSelecionado then
            AtivarModoConstrucao(estadoInventario.itemSelecionado)
        end
    end)
    table.insert(estadoInventario.conexoes, conexaoColocar)
    
    -- Salvar referências importantes
    estadoInventario.gridFrame = gridFrame
    estadoInventario.detalhesFrame = detalhesFrame
    estadoInventario.itemImagem = itemImagem
    estadoInventario.itemNome = itemNome
    estadoInventario.itemDescricao = itemDescricao
    estadoInventario.itemQuantidade = itemQuantidade
    estadoInventario.botaoColocar = botaoColocar
    estadoInventario.botoesCategorias = botoesCategorias
    
    -- Selecionar categoria inicial
    SelecionarCategoria("todos", botoesCategorias)
end

-- Função para selecionar uma categoria
function SelecionarCategoria(categoriaId, botoesCategorias)
    -- Verificar se os botões existem
    if not botoesCategorias then return end
    
    -- Atualizar visual dos botões
    for id, botao in pairs(botoesCategorias) do
        if id == categoriaId then
            botao.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde para selecionado
        else
            botao.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Cinza para não selecionado
        end
    end
    
    estadoInventario.categoriaAtual = categoriaId
    AtualizarItensFiltrados()
    AtualizarGridInventario()
end

-- Função para atualizar a lista de itens filtrados
function AtualizarItensFiltrados()
    estadoInventario.itensFiltrados = {}
    
    -- Aplicar filtro de categoria
    for id, item in pairs(estadoInventario.itens) do
        if estadoInventario.categoriaAtual == "todos" or item.categoria == estadoInventario.categoriaAtual then
            -- Aplicar filtro de pesquisa
            if estadoInventario.termoPesquisa == "" or 
               string.find(item.nome:lower(), estadoInventario.termoPesquisa) or 
               string.find(item.descricao:lower(), estadoInventario.termoPesquisa) then
                table.insert(estadoInventario.itensFiltrados, {id = id, item = item})
            end
        end
    end
    
    -- Aplicar ordenação
    if estadoInventario.ordenacao == "alfabetica" then
        table.sort(estadoInventario.itensFiltrados, function(a, b)
            return a.item.nome < b.item.nome
        end)
    elseif estadoInventario.ordenacao == "quantidade" then
        table.sort(estadoInventario.itensFiltrados, function(a, b)
            return a.item.quantidade > b.item.quantidade
        end)
    elseif estadoInventario.ordenacao == "preco" then
        table.sort(estadoInventario.itensFiltrados, function(a, b)
            return (a.item.preco or 0) > (b.item.preco or 0)
        end)
    end
end

-- Função para atualizar o grid visual do inventário
function AtualizarGridInventario()
    local gridFrame = estadoInventario.gridFrame
    if not gridFrame then return end
    
    -- Limpar grid atual
    for _, celula in pairs(estadoInventario.gridCelulas) do
        celula:Destroy()
    end
    estadoInventario.gridCelulas = {}
    
    -- Configurações do grid
    local colunas = 4
    local tamanhoCelula = 80
    local espacamento = 10
    local larguraTotal = (tamanhoCelula + espacamento) * colunas
    
    -- Criar células para cada item
    for i, itemInfo in ipairs(estadoInventario.itensFiltrados) do
        local item = itemInfo.item
        local itemId = itemInfo.id
        
        -- Calcular posição no grid
        local coluna = (i - 1) % colunas
        local linha = math.floor((i - 1) / colunas)
        local posX = coluna * (tamanhoCelula + espacamento)
        local posY = linha * (tamanhoCelula + espacamento)
        
        -- Criar célula do grid
        local celula = Instance.new("Frame")
        celula.Name = "Celula_" .. itemId
        celula.Size = UDim2.new(0, tamanhoCelula, 0, tamanhoCelula)
        celula.Position = UDim2.new(0, posX, 0, posY)
        celula.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        celula.BorderSizePixel = 0
        celula.Parent = gridFrame
        
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
        local conexaoSelecionar = botaoSelecionar.MouseButton1Click:Connect(function()
            SelecionarItem(itemId, item)
        end)
        table.insert(estadoInventario.conexoes, conexaoSelecionar)
        
        -- Configurar drag and drop
        ConfigurarDragDrop(celula, itemId, item)
        
        -- Adicionar à lista de células
        table.insert(estadoInventario.gridCelulas, celula)
        
        -- Adicionar atributos para uso pelo DragDropSystem
        celula:SetAttribute("ItemId", itemId)
        celula:SetAttribute("Nome", item.nome)
        celula:SetAttribute("Descricao", item.descricao)
        celula:SetAttribute("Categoria", item.categoria)
    end
    
    -- Atualizar tamanho do canvas
    local linhas = math.ceil(#estadoInventario.itensFiltrados / colunas)
    gridFrame.CanvasSize = UDim2.new(0, 0, 0, linhas * (tamanhoCelula + espacamento) + espacamento)
end

-- Função para selecionar um item
function SelecionarItem(itemId, item)
    estadoInventario.itemSelecionado = {id = itemId, info = item}
    
    -- Verificar se os elementos da interface existem
    if not estadoInventario.detalhesFrame or not estadoInventario.itemImagem or 
       not estadoInventario.itemNome or not estadoInventario.itemDescricao or 
       not estadoInventario.itemQuantidade or not estadoInventario.botaoColocar then
        warn("InventarioGui: Elementos da interface de detalhes não encontrados!")
        return
    end
    
    -- Atualizar detalhes
    estadoInventario.itemImagem.Image = item.icone
    estadoInventario.itemNome.Text = item.nome
    estadoInventario.itemDescricao.Text = item.descricao
    estadoInventario.itemQuantidade.Text = "Quantidade: " .. item.quantidade
    
    -- Mostrar frame de detalhes
    estadoInventario.detalhesFrame.Visible = true
    
    -- Atualizar botão de colocar
    if item.quantidade > 0 then
        estadoInventario.botaoColocar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Verde
        estadoInventario.botaoColocar.Text = "COLOCAR NA ILHA"
    else
        estadoInventario.botaoColocar.BackgroundColor3 = Color3.fromRGB(150, 150, 150) -- Cinza
        estadoInventario.botaoColocar.Text = "SEM UNIDADES"
    end
    
    -- Destacar célula selecionada
    for _, celula in pairs(estadoInventario.gridCelulas) do
        if celula.Name == "Celula_" .. itemId then
            celula.BackgroundColor3 = Color3.fromRGB(100, 180, 100) -- Verde mais claro
        else
            celula.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Cinza padrão
        end
    end
end

-- Função para configurar drag and drop em uma célula
function ConfigurarDragDrop(celula, itemId, item)
    local dragando = false
    local dragOffset = Vector2.new(0, 0)
    local dragIcone = nil
    
    -- Criar ícone de drag
    local function CriarDragIcone()
        local icone = Instance.new("ImageLabel")
        icone.Size = UDim2.new(0, 60, 0, 60)
        icone.Image = item.icone
        icone.BackgroundTransparency = 0.5
        icone.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        icone.BorderSizePixel = 0
        icone.Visible = false
        icone.Parent = mainGui
        
        return icone
    end
    
    -- Eventos de drag
    local conexaoMouseDown = celula.BotaoSelecionar.MouseButton1Down:Connect(function(x, y)
        if item.quantidade <= 0 then return end
        
        dragando = true
        dragOffset = Vector2.new(x, y) - celula.AbsolutePosition
        
        -- Criar ícone de drag se não existir
        if not dragIcone then
            dragIcone = CriarDragIcone()
        end
        
        -- Mostrar ícone de drag
        dragIcone.Position = UDim2.new(0, x - dragOffset.X, 0, y - dragOffset.Y)
        dragIcone.Visible = true
        
        -- Selecionar o item
        SelecionarItem(itemId, item)
        estadoInventario.itemArrastando = {id = itemId, info = item}
    end)
    table.insert(estadoInventario.conexoes, conexaoMouseDown)
    
    -- Finalizar drag é gerenciado globalmente pelo UserInputService
end

-- Função para ativar o modo de construção
function AtivarModoConstrucao(itemInfo)
    if estadoInventario.modoConstrucao then
        DesativarModoConstrucao()
    end
    
    if itemInfo.info.quantidade <= 0 then
        MostrarNotificacao("Sem Unidades", "Você não possui unidades deste item para colocar.", "erro")
        return
    end
    
    estadoInventario.modoConstrucao = true
    estadoInventario.itemSelecionado = itemInfo
    
    -- Fechar o inventário
    if inventarioFrame then
        inventarioFrame.Visible = false
    end
    
    -- Usar o sistema de construção avançado se disponível
    if sistemaConstrucao and sistemaConstrucao.AtivarModoConstrucao then
        -- Chamar a função do sistema de construção avançado
        sistemaConstrucao.AtivarModoConstrucao(itemInfo.id)
        return
    end
    
    -- Fallback para sistema básico se o avançado não estiver disponível
    MostrarNotificacao("Modo Construção", "Clique em qualquer lugar da sua ilha para colocar " .. itemInfo.info.nome, "info", 5)
    
    -- Criar preview do item
    CriarPreviewItem(itemInfo)
    
    -- Conectar evento de clique para colocar o item
    local conexaoClique = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            TentarColocarItem(itemInfo.id)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.Escape then
            DesativarModoConstrucao()
        end
    end)
    
    -- Salvar conexão para desconectar depois
    table.insert(estadoInventario.conexoes, conexaoClique)
end

-- Função para desativar o modo de construção
function DesativarModoConstrucao()
    if not estadoInventario.modoConstrucao then return end
    
    estadoInventario.modoConstrucao = false
    
    -- Usar o sistema de construção avançado se disponível
    if sistemaConstrucao and sistemaConstrucao.DesativarModoConstrucao then
        sistemaConstrucao.DesativarModoConstrucao()
        return
    end
    
    -- Fallback para sistema básico
    -- Desconectar eventos
    for i, conexao in ipairs(estadoInventario.conexoes) do
        if conexao.Connected then
            conexao:Disconnect()
        end
    end
    estadoInventario.conexoes = {}
    
    -- Remover preview do item
    RemoverPreviewItem()
    
    -- Mostrar notificação
    MostrarNotificacao("Modo Construção Desativado", "Você saiu do modo de construção.", "info")
end

-- Função para criar preview do item
function CriarPreviewItem(itemInfo)
    -- Usar o sistema de construção avançado se disponível
    if sistemaConstrucao and sistemaConstrucao.CriarPreviewItem then
        sistemaConstrucao.CriarPreviewItem(itemInfo.id)
        return
    end
    
    -- Sistema básico de preview fallback
    print("Preview criado para: " .. itemInfo.info.nome)
    
    -- Tentar criar um modelo 3D básico
    local ServerStorage = game:GetService("ServerStorage")
    local modeloItem = nil
    
    -- Verificar se existe um módulo ModelosItens para obter o modelo
    local ModelosItens = require(ServerStorage:FindFirstChild("Modelos"):FindFirstChild("ModelosItens"))
    if ModelosItens then
        modeloItem = ModelosItens:ObterModelo(itemInfo.id, 10)
    end
    
    -- Se não conseguir obter o modelo, criar um cubo básico
    if not modeloItem then
        modeloItem = Instance.new("Part")
        modeloItem.Size = Vector3.new(2, 1, 2)
        modeloItem.Anchored = true
        modeloItem.CanCollide = false
        modeloItem.Transparency = 0.5
        modeloItem.Material = Enum.Material.SmoothPlastic
        modeloItem.BrickColor = BrickColor.new("Bright green")
    else
        -- Configurar transparência para todos os componentes do modelo
        for _, parte in pairs(modeloItem:GetDescendants()) do
            if parte:IsA("BasePart") then
                parte.Transparency = 0.5
                parte.CanCollide = false
                parte.Anchored = true
            end
        end
    end
    
    -- Adicionar ao workspace
    modeloItem.Parent = workspace
    estadoInventario.previewItem = modeloItem
    
    -- Atualizar posição do preview com o mouse
    local conexaoRender = game:GetService("RunService").RenderStepped:Connect(function()
        if not estadoInventario.previewItem then return end
        
        local mouse = jogador:GetMouse()
        local raio = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 500)
        
        if raio then
            local posicao = raio.Position + Vector3.new(0, 1, 0)
            
            if modeloItem:IsA("Model") and modeloItem.PrimaryPart then
                modeloItem:SetPrimaryPartCFrame(CFrame.new(posicao))
            else
                modeloItem.Position = posicao
            end
            
            -- Verificar se a posição é válida
            local valido = true -- Implementar verificação real
            
            -- Atualizar cor baseado na validade
            local cor = valido and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            
            if modeloItem:IsA("Model") then
                for _, parte in pairs(modeloItem:GetDescendants()) do
                    if parte:IsA("BasePart") then
                        parte.Color = cor
                    end
                end
            else
                modeloItem.Color = cor
            end
        end
    end)
    
    table.insert(estadoInventario.conexoes, conexaoRender)
end

-- Função para remover preview do item
function RemoverPreviewItem()
    -- Usar o sistema de construção avançado se disponível
    if sistemaConstrucao and sistemaConstrucao.RemoverPreviewItem then
        sistemaConstrucao.RemoverPreviewItem()
        return
    end
    
    -- Sistema básico de preview fallback
    if estadoInventario.previewItem and estadoInventario.previewItem.Parent then
        estadoInventario.previewItem:Destroy()
        estadoInventario.previewItem = nil
    end
end

-- Função para tentar colocar um item
function TentarColocarItem(itemId)
    -- Usar o sistema de construção avançado se disponível
    if sistemaConstrucao and sistemaConstrucao.TentarColocarItem then
        sistemaConstrucao.TentarColocarItem(itemId)
        return
    end
    
    -- Sistema básico fallback
    if not estadoInventario.modoConstrucao then return end
    
    local item = estadoInventario.itens[itemId]
    if not item or item.quantidade <= 0 then
        MostrarNotificacao("Sem Unidades", "Você não possui unidades deste item para colocar.", "erro")
        return
    end
    
    -- Obter posição do mouse em 3D
    local mouse = jogador:GetMouse()
    local raio = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 500)
    
    if not raio then
        MostrarNotificacao("Posição Inválida", "Não foi possível colocar o item nessa posição.", "erro")
        return
    end
    
    local posicao = raio.Position
    local rotacao = 0 -- Rotação padrão
    
    -- Enviar solicitação para o servidor
    print("Tentando colocar item: " .. itemId .. " na posição: " .. tostring(posicao))
    colocarDecoracaoEvent:FireServer(itemId, posicao, rotacao)
    
    -- Desativar modo construção após colocar
    DesativarModoConstrucao()
end

-- Função para atualizar o inventário com dados do servidor
local function AtualizarInventario(dadosInventario)
    estadoInventario.itens = dadosInventario or {}
    
    -- Atualizar interface
    AtualizarItensFiltrados()
    AtualizarGridInventario()
    
    -- Se um item estava selecionado, atualizá-lo
    if estadoInventario.itemSelecionado then
        local itemId = estadoInventario.itemSelecionado.id
        if estadoInventario.itens[itemId] then
            SelecionarItem(itemId, estadoInventario.itens[itemId])
        else
            if estadoInventario.detalhesFrame then
                estadoInventario.detalhesFrame.Visible = false
            end
            estadoInventario.itemSelecionado = nil
        end
    end
end

-- Função para processar resposta de colocação de item
local function ProcessarRespostaColocacao(sucesso, itemId, novoInventario, mensagem)
    if sucesso then
        MostrarNotificacao("Item Colocado", mensagem or "Item colocado com sucesso!", "sucesso")
        
        -- Atualizar inventário com novos dados
        if novoInventario then
            AtualizarInventario(novoInventario)
        end
    else
        MostrarNotificacao("Erro", mensagem or "Não foi possível colocar o item.", "erro")
    end
end

-- Função para limpar conexões e recursos
local function LimparRecursos()
    -- Desconectar todos os eventos
    for _, conexao in ipairs(estadoInventario.conexoes) do
        if conexao.Connected then
            conexao:Disconnect()
        end
    end
    estadoInventario.conexoes = {}
    
    -- Remover preview se existir
    RemoverPreviewItem()
    
    print("📱 Inventário: Recursos limpos com sucesso!")
end

-- Função para inicializar o inventário
local function Inicializar()
    print("📱 Inventário: Inicializando interface...")
    
    -- Verificar se o inventarioFrame existe
    if not inventarioFrame then
        warn("InventarioGui: Frame do inventário não encontrado! Criando um novo...")
        inventarioFrame = Instance.new("Frame")
        inventarioFrame.Name = "InventarioFrame"
        inventarioFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
        inventarioFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
        inventarioFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        inventarioFrame.BorderSizePixel = 0
        inventarioFrame.Visible = false
        inventarioFrame.Parent = mainGui
    end
    
    -- Criar a interface básica
    CriarInterfaceInventario()
    
    -- Conectar eventos remotos
    atualizarInventarioEvent.OnClientEvent:Connect(AtualizarInventario)
    colocarDecoracaoEvent.OnClientEvent:Connect(ProcessarRespostaColocacao)
    
    -- Dados de teste para desenvolvimento
    local dadosTeste = {
        cerca_madeira = {
            id = "cerca_madeira",
            nome = "Cerca de Madeira",
            descricao = "Uma cerca rústica para delimitar sua propriedade.",
            preco = 50,
            icone = "rbxassetid://6797380005",
            categoria = "decoracoes",
            quantidade = 5
        },
        arvore_pequena = {
            id = "arvore_pequena",
            nome = "Árvore Pequena",
            descricao = "Uma árvore jovem para sua ilha.",
            preco = 100,
            icone = "rbxassetid://6797380656",
            categoria = "plantas",
            quantidade = 3
        },
        mesa_madeira = {
            id = "mesa_madeira",
            nome = "Mesa de Madeira",
            descricao = "Uma mesa robusta para sua casa.",
            preco = 120,
            icone = "rbxassetid://6797380329",
            categoria = "moveis",
            quantidade = 2
        },
        cadeira_simples = {
            id = "cadeira_simples",
            nome = "Cadeira Simples",
            descricao = "Uma cadeira básica e confortável.",
            preco = 80,
            icone = "rbxassetid://6797380438",
            categoria = "moveis",
            quantidade = 4
        },
        flor_azul = {
            id = "flor_azul",
            nome = "Flores Azuis",
            descricao = "Um canteiro de belas flores azuis.",
            preco = 30,
            icone = "rbxassetid://6797380765",
            categoria = "plantas",
            quantidade = 10
        },
        estatua_pequena = {
            id = "estatua_pequena",
            nome = "Estátua de Pedra",
            descricao = "Uma pequena estátua decorativa.",
            preco = 200,
            icone = "rbxassetid://6797380223",
            categoria = "decoracoes",
            quantidade = 1
        }
    }
    
    -- Usar dados de teste temporariamente
    AtualizarInventario(dadosTeste)
    
    -- Solicitar dados reais ao servidor
    -- Isso seria implementado quando o servidor tiver o sistema pronto
    -- atualizarInventarioEvent:FireServer()
    
    -- Limpar recursos quando o script for destruído
    script.Destroyed:Connect(LimparRecursos)
    
    print("📱 Inventário: Interface inicializada com sucesso!")
end

-- Iniciar quando o script carregar
Inicializar()
