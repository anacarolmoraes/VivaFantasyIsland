--[[
    InventarioSimples.lua
    
    Versão simplificada do inventário para testes
    NÃO depende de RemoteEvents e usa dados fixos
    
    Autor: Factory AI
    Data: 27/07/2025
]]

-- Serviços do Roblox
local Players = game:GetService("Players")

-- Jogador local
local jogador = Players.LocalPlayer
print("🧪 INVENTÁRIO SIMPLES: Script iniciado para " .. jogador.Name)

-- Referências à GUI
local mainGui = script.Parent
local inventarioFrame = mainGui:WaitForChild("InventarioFrame")

print("🧪 INVENTÁRIO SIMPLES: Obtendo referência ao frame do inventário")

-- Dados de teste fixos
local dadosTeste = {
    {
        id = "cerca_madeira",
        nome = "Cerca de Madeira",
        descricao = "Uma cerca rústica para delimitar sua propriedade.",
        preco = 50,
        icone = "rbxassetid://6797380005",
        categoria = "decoracoes",
        quantidade = 5
    },
    {
        id = "arvore_pequena",
        nome = "Árvore Pequena",
        descricao = "Uma árvore jovem para sua ilha.",
        preco = 100,
        icone = "rbxassetid://6797380656",
        categoria = "plantas",
        quantidade = 3
    },
    {
        id = "mesa_madeira",
        nome = "Mesa de Madeira",
        descricao = "Uma mesa robusta para sua casa.",
        preco = 120,
        icone = "rbxassetid://6797380329",
        categoria = "moveis",
        quantidade = 2
    },
    {
        id = "cadeira_simples",
        nome = "Cadeira Simples",
        descricao = "Uma cadeira básica e confortável.",
        preco = 80,
        icone = "rbxassetid://6797380438",
        categoria = "moveis",
        quantidade = 4
    },
    {
        id = "flor_azul",
        nome = "Flores Azuis",
        descricao = "Um canteiro de belas flores azuis.",
        preco = 50,
        icone = "rbxassetid://6797380765",
        categoria = "plantas",
        quantidade = 7
    },
    {
        id = "estatua_pequena",
        nome = "Estátua de Pedra",
        descricao = "Uma pequena estátua decorativa.",
        preco = 150,
        icone = "rbxassetid://6797380223",
        categoria = "decoracoes",
        quantidade = 1
    }
}

-- Variáveis de estado
local estadoInventario = {
    categoriaAtual = "todos",
    termoPesquisa = "",
    itensFiltrados = {},
    itemSelecionado = nil,
    elementos = {}
}

-- Função para criar a interface básica do inventário
local function CriarInterfaceInventario()
    print("🧪 INVENTÁRIO SIMPLES: Criando interface básica")
    
    -- Limpar interface existente
    for _, item in pairs(inventarioFrame:GetChildren()) do
        if item:IsA("Frame") or item:IsA("ScrollingFrame") or item:IsA("TextButton") or item:IsA("TextLabel") then
            if item.Name ~= "BotaoFechar" then -- Não remover botão de fechar se existir
                item:Destroy()
            end
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
    tituloInventario.Text = "Meu Inventário (TESTE)"
    tituloInventario.Parent = inventarioFrame
    
    -- Criar barra de pesquisa
    local barraPesquisa = Instance.new("Frame")
    barraPesquisa.Name = "BarraPesquisa"
    barraPesquisa.Size = UDim2.new(0.8, 0, 0, 40)
    barraPesquisa.Position = UDim2.new(0.1, 0, 0, 60)
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
    campoPesquisa:GetPropertyChangedSignal("Text"):Connect(function()
        print("🧪 INVENTÁRIO SIMPLES: Pesquisando: " .. campoPesquisa.Text)
        estadoInventario.termoPesquisa = campoPesquisa.Text:lower()
        AtualizarItensFiltrados()
        AtualizarGridInventario()
    end)
    
    -- Criar botões de categorias
    local categoriaFrame = Instance.new("Frame")
    categoriaFrame.Name = "CategoriaFrame"
    categoriaFrame.Size = UDim2.new(1, 0, 0, 50)
    categoriaFrame.Position = UDim2.new(0, 0, 0, 110)
    categoriaFrame.BackgroundTransparency = 1
    categoriaFrame.Parent = inventarioFrame
    
    local categorias = {
        {id = "todos", nome = "Todos os Itens"},
        {id = "decoracoes", nome = "Decorações"},
        {id = "moveis", nome = "Móveis"},
        {id = "plantas", nome = "Plantas"}
    }
    
    local botoesCategorias = {}
    
    for i, categoria in ipairs(categorias) do
        local botaoCategoria = Instance.new("TextButton")
        botaoCategoria.Name = "Categoria_" .. categoria.id
        botaoCategoria.Size = UDim2.new(0.25, -10, 1, -10)
        botaoCategoria.Position = UDim2.new(0.25 * (i-1), 5, 0, 5)
        botaoCategoria.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        botaoCategoria.TextColor3 = Color3.new(1, 1, 1)
        botaoCategoria.TextSize = 16
        botaoCategoria.Font = Enum.Font.SourceSansBold
        botaoCategoria.Text = categoria.nome
        botaoCategoria.BorderSizePixel = 0
        botaoCategoria.Parent = categoriaFrame
        
        botoesCategorias[categoria.id] = botaoCategoria
        
        -- Conectar evento de clique
        botaoCategoria.MouseButton1Click:Connect(function()
            print("🧪 INVENTÁRIO SIMPLES: Categoria selecionada: " .. categoria.nome)
            SelecionarCategoria(categoria.id, botoesCategorias)
        end)
    end
    
    estadoInventario.elementos.botoesCategorias = botoesCategorias
    
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
    
    estadoInventario.elementos.gridFrame = gridFrame
    
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
    
    -- Botão para fechar o inventário (se não existir)
    if not inventarioFrame:FindFirstChild("BotaoFechar") then
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
        
        botaoFechar.MouseButton1Click:Connect(function()
            print("🧪 INVENTÁRIO SIMPLES: Fechando inventário")
            inventarioFrame.Visible = false
        end)
    end
    
    -- Salvar referências importantes
    estadoInventario.elementos.detalhesFrame = detalhesFrame
    estadoInventario.elementos.itemImagem = itemImagem
    estadoInventario.elementos.itemNome = itemNome
    estadoInventario.elementos.itemDescricao = itemDescricao
    estadoInventario.elementos.itemQuantidade = itemQuantidade
    
    -- Selecionar categoria inicial
    SelecionarCategoria("todos", botoesCategorias)
    
    print("🧪 INVENTÁRIO SIMPLES: Interface criada com sucesso")
end

-- Função para selecionar uma categoria
function SelecionarCategoria(categoriaId, botoesCategorias)
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
    print("🧪 INVENTÁRIO SIMPLES: Atualizando itens filtrados")
    estadoInventario.itensFiltrados = {}
    
    -- Aplicar filtro de categoria e pesquisa
    for _, item in ipairs(dadosTeste) do
        if estadoInventario.categoriaAtual == "todos" or item.categoria == estadoInventario.categoriaAtual then
            -- Aplicar filtro de pesquisa
            if estadoInventario.termoPesquisa == "" or 
               string.find(item.nome:lower(), estadoInventario.termoPesquisa) or 
               string.find(item.descricao:lower(), estadoInventario.termoPesquisa) then
                table.insert(estadoInventario.itensFiltrados, item)
            end
        end
    end
    
    print("🧪 INVENTÁRIO SIMPLES: " .. #estadoInventario.itensFiltrados .. " itens após filtro")
end

-- Função para atualizar o grid visual do inventário
function AtualizarGridInventario()
    local gridFrame = estadoInventario.elementos.gridFrame
    
    -- Limpar grid atual
    for _, item in pairs(gridFrame:GetChildren()) do
        if item:IsA("Frame") then
            item:Destroy()
        end
    end
    
    -- Configurações do grid
    local colunas = 3
    local tamanhoCelula = 80
    local espacamento = 10
    
    -- Criar células para cada item
    for i, item in ipairs(estadoInventario.itensFiltrados) do
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
        botaoSelecionar.MouseButton1Click:Connect(function()
            print("🧪 INVENTÁRIO SIMPLES: Item selecionado: " .. item.nome)
            SelecionarItem(item)
        end)
    end
    
    -- Atualizar tamanho do canvas
    local linhas = math.ceil(#estadoInventario.itensFiltrados / colunas)
    gridFrame.CanvasSize = UDim2.new(0, 0, 0, linhas * (tamanhoCelula + espacamento) + espacamento)
    
    print("🧪 INVENTÁRIO SIMPLES: Grid atualizado com " .. #estadoInventario.itensFiltrados .. " itens")
end

-- Função para selecionar um item
function SelecionarItem(item)
    estadoInventario.itemSelecionado = item
    
    -- Atualizar detalhes
    estadoInventario.elementos.itemImagem.Image = item.icone
    estadoInventario.elementos.itemNome.Text = item.nome
    estadoInventario.elementos.itemDescricao.Text = item.descricao
    estadoInventario.elementos.itemQuantidade.Text = "Quantidade: " .. item.quantidade
    
    -- Mostrar frame de detalhes
    estadoInventario.elementos.detalhesFrame.Visible = true
    
    print("🧪 INVENTÁRIO SIMPLES: Detalhes do item atualizados")
end

-- Função para inicializar o inventário
local function Inicializar()
    print("🧪 INVENTÁRIO SIMPLES: Inicializando...")
    
    -- Criar a interface básica
    CriarInterfaceInventario()
    
    -- Conectar ao botão de inventário no HUD para garantir que funcione
    local hudFrame = mainGui:WaitForChild("HUD")
    local botoesMenu = hudFrame:WaitForChild("BotoesMenu")
    local botaoInventario = botoesMenu:WaitForChild("BotaoInventario")
    
    -- Garantir que o botão abra o inventário
    botaoInventario.MouseButton1Click:Connect(function()
        print("🧪 INVENTÁRIO SIMPLES: Botão inventário clicado")
        inventarioFrame.Visible = true
    end)
    
    print("🧪 INVENTÁRIO SIMPLES: Inicializado com sucesso!")
end

-- Iniciar quando o script carregar
Inicializar()
