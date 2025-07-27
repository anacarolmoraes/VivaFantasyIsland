--[[
    ModelosItens.lua
    
    Sistema de modelos 3D para o jogo "Viva Fantasy Island"
    Gerencia o carregamento, cache, validação e otimização de modelos 3D para itens do jogo.
    
    Recursos:
    - Definição de modelos 3D para cada item do inventário
    - Carregamento dinâmico de modelos
    - Cache para otimização de performance
    - Configurações específicas por item (tamanho, offset, propriedades)
    - Sistema de materiais e texturas
    - Validação de modelos
    - Fallback para modelos simples
    - Sistema de LOD (Level of Detail)
    - Otimização de performance
    - Versionamento de modelos
    
    Autor: Factory AI
    Data: 27/07/2025
    Versão: 1.0.0
]]

-- Serviços do Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Constantes
local VERSAO_SISTEMA = "1.0.0"
local PASTA_MODELOS = ServerStorage:WaitForChild("Modelos")
local PASTA_MODELOS_FALLBACK = ServerStorage:WaitForChild("ModelosFallback")
local MAX_CACHE_SIZE = 50 -- Número máximo de modelos em cache
local TEMPO_CACHE = 300 -- Tempo em segundos para manter modelos em cache sem uso
local DISTANCIA_LOD = {
    ALTA = 20,    -- Distância para LOD alta qualidade
    MEDIA = 50,   -- Distância para LOD média qualidade
    BAIXA = 100,  -- Distância para LOD baixa qualidade
    MUITO_BAIXA = 200 -- Distância para LOD muito baixa qualidade
}

-- Tabelas de cache
local cacheModelos = {} -- Cache de modelos carregados
local cacheTempoUso = {} -- Registro do último uso de cada modelo
local cacheContadorUso = {} -- Contador de uso de cada modelo

-- Tabela de status de carregamento
local carregamentoPendente = {} -- Modelos em processo de carregamento

-- Módulo
local ModelosItens = {}

-- Definições de modelos
local definicoes = {
    -- Cerca de Madeira
    cerca_madeira = {
        nome = "Cerca de Madeira",
        descricao = "Uma cerca rústica para delimitar sua propriedade.",
        categoria = "decoracoes",
        
        -- Configurações do modelo 3D
        modelo = {
            path = "cerca_madeira_v1", -- Nome do modelo no ServerStorage/Modelos
            versao = "1.0.0",
            tamanho = Vector3.new(2, 1, 0.2),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            
            -- Materiais e texturas
            materiais = {
                principal = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(133, 94, 66),
                    textura = "rbxassetid://6797380005",
                    propriedades = {
                        Roughness = 0.8,
                        Metalness = 0.1
                    }
                },
                secundario = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(120, 120, 120),
                    textura = "rbxassetid://6797380105",
                    propriedades = {
                        Roughness = 0.6,
                        Metalness = 0.7
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "cerca_madeira_v1_lod0",
                    triangulos = 1200,
                    texturaResolucao = 512
                },
                media = {
                    path = "cerca_madeira_v1_lod1",
                    triangulos = 600,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "cerca_madeira_v1_lod2",
                    triangulos = 300,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "cerca_madeira_v1_lod3",
                    triangulos = 100,
                    texturaResolucao = 64
                }
            },
            
            -- Configurações de fallback
            fallback = {
                tipo = "parte",
                tamanho = Vector3.new(2, 1, 0.2),
                cor = Color3.fromRGB(133, 94, 66),
                material = Enum.Material.Wood
            },
            
            -- Configurações de física
            fisica = {
                massa = 10,
                tipo = "block",
                anchored = true,
                canCollide = true
            },
            
            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 0.5
            }
        }
    },
    
    -- Árvore Pequena
    arvore_pequena = {
        nome = "Árvore Pequena",
        descricao = "Uma árvore jovem para sua ilha.",
        categoria = "plantas",
        
        -- Configurações do modelo 3D
        modelo = {
            path = "arvore_pequena_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 3, 2),
            offset = Vector3.new(0, 1.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0), -- Rotação aleatória para variedade
            
            -- Materiais e texturas
            materiais = {
                tronco = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(121, 85, 58),
                    textura = "rbxassetid://6797380656",
                    propriedades = {
                        Roughness = 0.9,
                        Metalness = 0
                    }
                },
                folhas = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(67, 140, 50),
                    textura = "rbxassetid://6797380756",
                    propriedades = {
                        Roughness = 1.0,
                        Metalness = 0
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "arvore_pequena_v1_lod0",
                    triangulos = 3000,
                    texturaResolucao = 512
                },
                media = {
                    path = "arvore_pequena_v1_lod1",
                    triangulos = 1500,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "arvore_pequena_v1_lod2",
                    triangulos = 800,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "arvore_pequena_v1_lod3",
                    triangulos = 300,
                    texturaResolucao = 64
                }
            },
            
            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    tronco = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.5, 2, 0.5),
                        posicao = Vector3.new(0, 1, 0),
                        cor = Color3.fromRGB(121, 85, 58),
                        material = Enum.Material.Wood
                    },
                    copa = {
                        tipo = "esfera",
                        tamanho = Vector3.new(2, 2, 2),
                        posicao = Vector3.new(0, 2.5, 0),
                        cor = Color3.fromRGB(67, 140, 50),
                        material = Enum.Material.Grass
                    }
                }
            },
            
            -- Configurações de física
            fisica = {
                massa = 100,
                tipo = "mesh",
                anchored = true,
                canCollide = true
            },
            
            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 2
            },
            
            -- Efeitos especiais
            efeitos = {
                vento = {
                    ativo = true,
                    intensidade = 0.1,
                    frequencia = 0.5
                },
                particulas = {
                    tipo = "folhas",
                    taxa = 0.1,
                    tamanho = 0.1,
                    cor = Color3.fromRGB(67, 140, 50)
                }
            }
        }
    },
    
    -- Mesa de Madeira
    mesa_madeira = {
        nome = "Mesa de Madeira",
        descricao = "Uma mesa robusta para sua casa.",
        categoria = "moveis",
        
        -- Configurações do modelo 3D
        modelo = {
            path = "mesa_madeira_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 1, 2),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            
            -- Materiais e texturas
            materiais = {
                principal = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(160, 120, 80),
                    textura = "rbxassetid://6797380329",
                    propriedades = {
                        Roughness = 0.7,
                        Metalness = 0.1
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "mesa_madeira_v1_lod0",
                    triangulos = 1800,
                    texturaResolucao = 512
                },
                media = {
                    path = "mesa_madeira_v1_lod1",
                    triangulos = 900,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "mesa_madeira_v1_lod2",
                    triangulos = 450,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "mesa_madeira_v1_lod3",
                    triangulos = 200,
                    texturaResolucao = 64
                }
            },
            
            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    tampo = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.1, 2),
                        posicao = Vector3.new(0, 0.95, 0),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    },
                    perna1 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.9, 0.1),
                        posicao = Vector3.new(0.9, 0.45, 0.9),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    },
                    perna2 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.9, 0.1),
                        posicao = Vector3.new(-0.9, 0.45, 0.9),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    },
                    perna3 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.9, 0.1),
                        posicao = Vector3.new(0.9, 0.45, -0.9),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    },
                    perna4 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.9, 0.1),
                        posicao = Vector3.new(-0.9, 0.45, -0.9),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    }
                }
            },
            
            -- Configurações de física
            fisica = {
                massa = 50,
                tipo = "block",
                anchored = true,
                canCollide = true
            },
            
            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 1
            },
            
            -- Interações
            interacoes = {
                sentarAoRedor = true,
                colocarItens = true
            }
        }
    },
    
    -- Cadeira Simples
    cadeira_simples = {
        nome = "Cadeira Simples",
        descricao = "Uma cadeira básica e confortável.",
        categoria = "moveis",
        
        -- Configurações do modelo 3D
        modelo = {
            path = "cadeira_simples_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(1, 1.5, 1),
            offset = Vector3.new(0, 0.75, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            
            -- Materiais e texturas
            materiais = {
                estrutura = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(160, 120, 80),
                    textura = "rbxassetid://6797380438",
                    propriedades = {
                        Roughness = 0.7,
                        Metalness = 0.1
                    }
                },
                estofado = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(180, 160, 140),
                    textura = "rbxassetid://6797380538",
                    propriedades = {
                        Roughness = 0.9,
                        Metalness = 0
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "cadeira_simples_v1_lod0",
                    triangulos = 1500,
                    texturaResolucao = 512
                },
                media = {
                    path = "cadeira_simples_v1_lod1",
                    triangulos = 750,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "cadeira_simples_v1_lod2",
                    triangulos = 375,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "cadeira_simples_v1_lod3",
                    triangulos = 150,
                    texturaResolucao = 64
                }
            },
            
            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    assento = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1, 0.1, 1),
                        posicao = Vector3.new(0, 0.5, 0),
                        cor = Color3.fromRGB(180, 160, 140),
                        material = Enum.Material.Fabric
                    },
                    encosto = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1, 0.8, 0.1),
                        posicao = Vector3.new(0, 0.95, -0.45),
                        cor = Color3.fromRGB(180, 160, 140),
                        material = Enum.Material.Fabric
                    },
                    perna1 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.5, 0.1),
                        posicao = Vector3.new(0.4, 0.25, 0.4),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    },
                    perna2 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.5, 0.1),
                        posicao = Vector3.new(-0.4, 0.25, 0.4),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    },
                    perna3 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.5, 0.1),
                        posicao = Vector3.new(0.4, 0.25, -0.4),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    },
                    perna4 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.5, 0.1),
                        posicao = Vector3.new(-0.4, 0.25, -0.4),
                        cor = Color3.fromRGB(160, 120, 80),
                        material = Enum.Material.Wood
                    }
                }
            },
            
            -- Configurações de física
            fisica = {
                massa = 15,
                tipo = "block",
                anchored = true,
                canCollide = true
            },
            
            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 0.5
            },
            
            -- Interações
            interacoes = {
                sentarEm = true,
                posicaoSentar = Vector3.new(0, 0.6, 0)
            }
        }
    },
    
    -- Flores Azuis
    flor_azul = {
        nome = "Flores Azuis",
        descricao = "Um canteiro de belas flores azuis.",
        categoria = "plantas",
        
        -- Configurações do modelo 3D
        modelo = {
            path = "flor_azul_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.5, 0.5, 0.5),
            offset = Vector3.new(0, 0.25, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0), -- Rotação aleatória para variedade
            
            -- Materiais e texturas
            materiais = {
                petalas = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(50, 100, 255),
                    textura = "rbxassetid://6797380765",
                    propriedades = {
                        Roughness = 0.9,
                        Metalness = 0
                    }
                },
                caule = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(70, 160, 70),
                    textura = "rbxassetid://6797380865",
                    propriedades = {
                        Roughness = 0.9,
                        Metalness = 0
                    }
                },
                terra = {
                    material = Enum.Material.Ground,
                    cor = Color3.fromRGB(120, 85, 55),
                    textura = "rbxassetid://6797380965",
                    propriedades = {
                        Roughness = 1.0,
                        Metalness = 0
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "flor_azul_v1_lod0",
                    triangulos = 800,
                    texturaResolucao = 512
                },
                media = {
                    path = "flor_azul_v1_lod1",
                    triangulos = 400,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "flor_azul_v1_lod2",
                    triangulos = 200,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "flor_azul_v1_lod3",
                    triangulos = 100,
                    texturaResolucao = 64
                }
            },
            
            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.5, 0.1, 0.5),
                        posicao = Vector3.new(0, 0.05, 0),
                        cor = Color3.fromRGB(120, 85, 55),
                        material = Enum.Material.Ground
                    },
                    caule = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.05, 0.3, 0.05),
                        posicao = Vector3.new(0, 0.2, 0),
                        cor = Color3.fromRGB(70, 160, 70),
                        material = Enum.Material.Grass
                    },
                    flor = {
                        tipo = "esfera",
                        tamanho = Vector3.new(0.2, 0.1, 0.2),
                        posicao = Vector3.new(0, 0.35, 0),
                        cor = Color3.fromRGB(50, 100, 255),
                        material = Enum.Material.Fabric
                    }
                }
            },
            
            -- Configurações de física
            fisica = {
                massa = 2,
                tipo = "mesh",
                anchored = true,
                canCollide = false
            },
            
            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "grama"},
                angulos = {0},
                altura = 0,
                distanciaMinima = 0.3
            },
            
            -- Efeitos especiais
            efeitos = {
                vento = {
                    ativo = true,
                    intensidade = 0.2,
                    frequencia = 0.7
                },
                particulas = {
                    tipo = "polen",
                    taxa = 0.05,
                    tamanho = 0.05,
                    cor = Color3.fromRGB(255, 255, 150)
                },
                brilho = {
                    ativo = true,
                    cor = Color3.fromRGB(200, 200, 255),
                    intensidade = 0.1,
                    alcance = 1
                }
            }
        }
    },
    
    -- Estátua de Pedra
    estatua_pequena = {
        nome = "Estátua de Pedra",
        descricao = "Uma pequena estátua decorativa.",
        categoria = "decoracoes",
        
        -- Configurações do modelo 3D
        modelo = {
            path = "estatua_pequena_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(1, 2, 1),
            offset = Vector3.new(0, 1, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            
            -- Materiais e texturas
            materiais = {
                principal = {
                    material = Enum.Material.Slate,
                    cor = Color3.fromRGB(180, 180, 180),
                    textura = "rbxassetid://6797380223",
                    propriedades = {
                        Roughness = 0.8,
                        Metalness = 0.1
                    }
                },
                base = {
                    material = Enum.Material.Concrete,
                    cor = Color3.fromRGB(150, 150, 150),
                    textura = "rbxassetid://6797380323",
                    propriedades = {
                        Roughness = 0.7,
                        Metalness = 0.05
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "estatua_pequena_v1_lod0",
                    triangulos = 5000,
                    texturaResolucao = 1024
                },
                media = {
                    path = "estatua_pequena_v1_lod1",
                    triangulos = 2500,
                    texturaResolucao = 512
                },
                baixa = {
                    path = "estatua_pequena_v1_lod2",
                    triangulos = 1000,
                    texturaResolucao = 256
                },
                muito_baixa = {
                    path = "estatua_pequena_v1_lod3",
                    triangulos = 500,
                    texturaResolucao = 128
                }
            },
            
            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1, 0.3, 1),
                        posicao = Vector3.new(0, 0.15, 0),
                        cor = Color3.fromRGB(150, 150, 150),
                        material = Enum.Material.Concrete
                    },
                    corpo = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.6, 1.5, 0.6),
                        posicao = Vector3.new(0, 1, 0),
                        cor = Color3.fromRGB(180, 180, 180),
                        material = Enum.Material.Slate
                    },
                    cabeca = {
                        tipo = "esfera",
                        tamanho = Vector3.new(0.4, 0.4, 0.4),
                        posicao = Vector3.new(0, 1.85, 0),
                        cor = Color3.fromRGB(180, 180, 180),
                        material = Enum.Material.Slate
                    }
                }
            },
            
            -- Configurações de física
            fisica = {
                massa = 200,
                tipo = "mesh",
                anchored = true,
                canCollide = true
            },
            
            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 45, 90, 135, 180, 225, 270, 315},
                altura = 0,
                distanciaMinima = 1
            },
            
            -- Efeitos especiais
            efeitos = {
                envelhecimento = {
                    ativo = true,
                    textura = "rbxassetid://6797380423",
                    intensidade = 0.3
                }
            }
        }
    }
}

-- Funções auxiliares

-- Função para criar um modelo fallback simples
local function CriarModeloFallback(itemId)
    local definicao = definicoes[itemId]
    if not definicao then return nil end
    
    local configFallback = definicao.modelo.fallback
    local modelo = Instance.new("Model")
    modelo.Name = itemId .. "_fallback"
    
    if configFallback.tipo == "parte" then
        -- Criar uma parte simples
        local parte = Instance.new("Part")
        parte.Size = configFallback.tamanho
        parte.Color = configFallback.cor
        parte.Material = configFallback.material
        parte.Anchored = true
        parte.CanCollide = true
        parte.Parent = modelo
        modelo.PrimaryPart = parte
        
    elseif configFallback.tipo == "composto" then
        -- Criar um modelo composto de várias partes
        local primaryPartSet = false
        
        for nome, config in pairs(configFallback.componentes) do
            local parte
            
            if config.tipo == "bloco" then
                parte = Instance.new("Part")
                parte.Shape = Enum.PartType.Block
            elseif config.tipo == "esfera" then
                parte = Instance.new("Part")
                parte.Shape = Enum.PartType.Ball
            elseif config.tipo == "cilindro" then
                parte = Instance.new("Part")
                parte.Shape = Enum.PartType.Cylinder
            else
                parte = Instance.new("Part")
            end
            
            parte.Name = nome
            parte.Size = config.tamanho
            parte.Position = config.posicao
            parte.Color = config.cor
            parte.Material = config.material
            parte.Anchored = true
            parte.CanCollide = true
            parte.Parent = modelo
            
            if not primaryPartSet then
                modelo.PrimaryPart = parte
                primaryPartSet = true
            end
        end
    end
    
    return modelo
end

-- Função para aplicar materiais e texturas a um modelo
local function AplicarMateriaisETexturas(modelo, itemId)
    local definicao = definicoes[itemId]
    if not definicao or not definicao.modelo.materiais then return end
    
    -- Iterar sobre todas as partes do modelo
    for _, parte in pairs(modelo:GetDescendants()) do
        if parte:IsA("BasePart") then
            local materialConfig
            
            -- Tentar encontrar a configuração de material correspondente
            if parte.Name:lower():find("principal") then
                materialConfig = definicao.modelo.materiais.principal
            elseif parte.Name:lower():find("secundario") then
                materialConfig = definicao.modelo.materiais.secundario
            else
                -- Procurar por correspondência específica
                for nomeMaterial, config in pairs(definicao.modelo.materiais) do
                    if parte.Name:lower():find(nomeMaterial:lower()) then
                        materialConfig = config
                        break
                    end
                end
                
                -- Se não encontrou, usar o principal
                if not materialConfig and definicao.modelo.materiais.principal then
                    materialConfig = definicao.modelo.materiais.principal
                end
            end
            
            -- Aplicar configurações de material se encontrado
            if materialConfig then
                parte.Material = materialConfig.material
                parte.Color = materialConfig.cor
                
                -- Aplicar textura se especificada
                if materialConfig.textura then
                    local textura = Instance.new("Decal")
                    textura.Texture = materialConfig.textura
                    textura.Face = Enum.NormalId.Front
                    textura.Parent = parte
                end
                
                -- Aplicar propriedades avançadas de material
                if materialConfig.propriedades then
                    for prop, valor in pairs(materialConfig.propriedades) do
                        pcall(function()
                            parte[prop] = valor
                        end)
                    end
                end
            end
        end
    end
end

-- Função para aplicar configurações de física a um modelo
local function AplicarConfiguracoesDeDisica(modelo, itemId)
    local definicao = definicoes[itemId]
    if not definicao or not definicao.modelo.fisica then return end
    
    local configFisica = definicao.modelo.fisica
    
    for _, parte in pairs(modelo:GetDescendants()) do
        if parte:IsA("BasePart") then
            parte.Anchored = configFisica.anchored
            parte.CanCollide = configFisica.canCollide
            
            -- Tentar definir outras propriedades físicas
            pcall(function()
                parte.CustomPhysicalProperties = PhysicalProperties.new(
                    configFisica.densidade or 0.7,
                    configFisica.friccao or 0.3,
                    configFisica.elasticidade or 0.5,
                    configFisica.peso or 1,
                    configFisica.friccaoDeRotacao or 0.1
                )
            end)
        end
    end
end

-- Função para aplicar efeitos especiais a um modelo
local function AplicarEfeitosEspeciais(modelo, itemId)
    local definicao = definicoes[itemId]
    if not definicao or not definicao.modelo.efeitos then return end
    
    local configEfeitos = definicao.modelo.efeitos
    
    -- Aplicar efeito de vento
    if configEfeitos.vento and configEfeitos.vento.ativo then
        -- Implementação simplificada do efeito de vento
        local script = Instance.new("Script")
        script.Name = "EfeitoVento"
        script.Source = [[
            local modelo = script.Parent
            local intensidade = ]] .. configEfeitos.vento.intensidade .. [[
            local frequencia = ]] .. configEfeitos.vento.frequencia .. [[
            
            while true do
                for _, parte in pairs(modelo:GetDescendants()) do
                    if parte:IsA("BasePart") and not parte.Name:lower():find("base") then
                        local offset = math.sin(tick() * frequencia) * intensidade
                        parte.CFrame = parte.CFrame * CFrame.Angles(offset/10, 0, offset/10)
                    end
                end
                wait(0.1)
            end
        ]]
        script.Parent = modelo
    end
    
    -- Aplicar efeito de partículas
    if configEfeitos.particulas then
        local emitter = Instance.new("ParticleEmitter")
        emitter.Rate = configEfeitos.particulas.taxa * 10 -- Taxa por segundo
        emitter.Size = NumberSequence.new(configEfeitos.particulas.tamanho)
        emitter.Color = ColorSequence.new(configEfeitos.particulas.cor)
        emitter.Lifetime = NumberRange.new(2, 5)
        emitter.Speed = NumberRange.new(0.1, 0.5)
        emitter.SpreadAngle = Vector2.new(0, 180)
        emitter.Parent = modelo.PrimaryPart
    end
    
    -- Aplicar efeito de brilho
    if configEfeitos.brilho and configEfeitos.brilho.ativo then
        local brilho = Instance.new("PointLight")
        brilho.Color = configEfeitos.brilho.cor
        brilho.Brightness = configEfeitos.brilho.intensidade
        brilho.Range = configEfeitos.brilho.alcance
        brilho.Parent = modelo.PrimaryPart
    end
    
    -- Aplicar efeito de envelhecimento
    if configEfeitos.envelhecimento and configEfeitos.envelhecimento.ativo then
        for _, parte in pairs(modelo:GetDescendants()) do
            if parte:IsA("BasePart") then
                local textura = Instance.new("Decal")
                textura.Texture = configEfeitos.envelhecimento.textura
                textura.Transparency = 1 - configEfeitos.envelhecimento.intensidade
                textura.Face = Enum.NormalId.Front
                textura.Parent = parte
            end
        end
    end
end

-- Função para determinar o nível de LOD com base na distância
local function DeterminarNivelLOD(distancia)
    if distancia <= DISTANCIA_LOD.ALTA then
        return "alta"
    elseif distancia <= DISTANCIA_LOD.MEDIA then
        return "media"
    elseif distancia <= DISTANCIA_LOD.BAIXA then
        return "baixa"
    else
        return "muito_baixa"
    end
end

-- Função para carregar um modelo com o nível de LOD apropriado
local function CarregarModeloComLOD(itemId, distancia)
    local definicao = definicoes[itemId]
    if not definicao then return nil end
    
    -- Determinar nível de LOD
    local nivelLOD = DeterminarNivelLOD(distancia)
    local pathModelo
    
    -- Obter o path do modelo para o nível de LOD
    if definicao.modelo.lod and definicao.modelo.lod[nivelLOD] then
        pathModelo = definicao.modelo.lod[nivelLOD].path
    else
        -- Se não tiver LOD específico, usar o modelo padrão
        pathModelo = definicao.modelo.path
    end
    
    -- Tentar carregar o modelo
    local modelo = PASTA_MODELOS:FindFirstChild(pathModelo)
    
    -- Se não encontrar o modelo, tentar o fallback
    if not modelo then
        -- Tentar modelo de LOD inferior
        if nivelLOD == "alta" then
            return CarregarModeloComLOD(itemId, DISTANCIA_LOD.MEDIA + 1) -- Forçar LOD média
        elseif nivelLOD == "media" then
            return CarregarModeloComLOD(itemId, DISTANCIA_LOD.BAIXA + 1) -- Forçar LOD baixa
        elseif nivelLOD == "baixa" then
            return CarregarModeloComLOD(itemId, DISTANCIA_LOD.MUITO_BAIXA + 1) -- Forçar LOD muito baixa
        else
            -- Criar modelo fallback
            return CriarModeloFallback(itemId)
        end
    end
    
    -- Clonar o modelo para não modificar o original
    local modeloClone = modelo:Clone()
    
    -- Aplicar materiais, física e efeitos
    AplicarMateriaisETexturas(modeloClone, itemId)
    AplicarConfiguracoesDeDisica(modeloClone, itemId)
    AplicarEfeitosEspeciais(modeloClone, itemId)
    
    return modeloClone
end

-- Função para limpar cache de modelos não utilizados
local function LimparCache()
    local tempoAtual = tick()
    local modelosParaRemover = {}
    
    -- Identificar modelos não utilizados por muito tempo
    for itemId, ultimoUso in pairs(cacheTempoUso) do
        if (tempoAtual - ultimoUso) > TEMPO_CACHE then
            table.insert(modelosParaRemover, itemId)
        end
    end
    
    -- Remover modelos do cache
    for _, itemId in ipairs(modelosParaRemover) do
        if cacheModelos[itemId] then
            cacheModelos[itemId] = nil
            cacheTempoUso[itemId] = nil
            cacheContadorUso[itemId] = nil
            print("ModelosItens: Removido do cache: " .. itemId)
        end
    end
    
    -- Se ainda tiver muitos modelos em cache, remover os menos usados
    if #modelosParaRemover < 5 and #cacheModelos > MAX_CACHE_SIZE then
        local modelosOrdenadosPorUso = {}
        
        for itemId, contador in pairs(cacheContadorUso) do
            table.insert(modelosOrdenadosPorUso, {id = itemId, usos = contador})
        end
        
        -- Ordenar por número de usos (crescente)
        table.sort(modelosOrdenadosPorUso, function(a, b)
            return a.usos < b.usos
        end)
        
        -- Remover os 10% menos usados
        local numParaRemover = math.ceil(#modelosOrdenadosPorUso * 0.1)
        for i = 1, numParaRemover do
            local itemId = modelosOrdenadosPorUso[i].id
            cacheModelos[itemId] = nil
            cacheTempoUso[itemId] = nil
            cacheContadorUso[itemId] = nil
            print("ModelosItens: Removido do cache por baixo uso: " .. itemId)
        end
    end
end

-- Função para validar um modelo
local function ValidarModelo(modelo, itemId)
    if not modelo then return false, "Modelo nulo" end
    
    -- Verificar se tem PrimaryPart
    if not modelo.PrimaryPart then
        -- Tentar definir PrimaryPart automaticamente
        for _, parte in pairs(modelo:GetChildren()) do
            if parte:IsA("BasePart") then
                modelo.PrimaryPart = parte
                break
            end
        end
        
        if not modelo.PrimaryPart then
            return false, "Modelo sem PrimaryPart"
        end
    end
    
    -- Verificar se tem partes
    local temPartes = false
    for _, parte in pairs(modelo:GetDescendants()) do
        if parte:IsA("BasePart") then
            temPartes = true
            break
        end
    end
    
    if not temPartes then
        return false, "Modelo sem partes"
    end
    
    return true, "Modelo válido"
end

-- Função para pré-carregar modelos frequentemente usados
local function PreCarregarModelosComuns()
    -- Lista de itens comuns para pré-carregar
    local itensComuns = {"cerca_madeira", "arvore_pequena", "flor_azul"}
    
    for _, itemId in ipairs(itensComuns) do
        spawn(function()
            ModelosItens:ObterModelo(itemId, 10) -- Carregar com LOD média
        end)
    end
end

-- API pública do módulo

-- Obter definição de um item
function ModelosItens:ObterDefinicao(itemId)
    return definicoes[itemId]
end

-- Verificar se um item existe
function ModelosItens:ItemExiste(itemId)
    return definicoes[itemId] ~= nil
end

-- Obter lista de todos os itens disponíveis
function ModelosItens:ObterListaItens()
    local lista = {}
    for itemId, definicao in pairs(definicoes) do
        table.insert(lista, {
            id = itemId,
            nome = definicao.nome,
            descricao = definicao.descricao,
            categoria = definicao.categoria
        })
    end
    return lista
end

-- Obter lista de itens por categoria
function ModelosItens:ObterItensPorCategoria(categoria)
    local lista = {}
    for itemId, definicao in pairs(definicoes) do
        if definicao.categoria == categoria then
            table.insert(lista, {
                id = itemId,
                nome = definicao.nome,
                descricao = definicao.descricao
            })
        end
    end
    return lista
end

-- Obter modelo de um item
function ModelosItens:ObterModelo(itemId, distancia)
    -- Verificar se o item existe
    if not definicoes[itemId] then
        warn("ModelosItens: Item não encontrado: " .. itemId)
        return nil
    end
    
    -- Usar distância padrão se não especificada
    distancia = distancia or 10
    
    -- Verificar cache primeiro
    if cacheModelos[itemId] then
        -- Atualizar estatísticas de uso
        cacheTempoUso[itemId] = tick()
        cacheContadorUso[itemId] = (cacheContadorUso[itemId] or 0) + 1
        
        return cacheModelos[itemId]:Clone()
    end
    
    -- Verificar se já está em processo de carregamento
    if carregamentoPendente[itemId] then
        -- Esperar até que o carregamento termine (com timeout)
        local tempoInicio = tick()
        while carregamentoPendente[itemId] and (tick() - tempoInicio) < 5 do
            wait(0.1)
        end
        
        -- Verificar novamente o cache após espera
        if cacheModelos[itemId] then
            cacheTempoUso[itemId] = tick()
            cacheContadorUso[itemId] = (cacheContadorUso[itemId] or 0) + 1
            return cacheModelos[itemId]:Clone()
        end
    end
    
    -- Marcar como em carregamento
    carregamentoPendente[itemId] = true
    
    -- Carregar modelo com LOD apropriado
    local modelo = CarregarModeloComLOD(itemId, distancia)
    
    -- Validar modelo
    local valido, mensagem = ValidarModelo(modelo, itemId)
    if not valido then
        warn("ModelosItens: Modelo inválido para " .. itemId .. ": " .. mensagem)
        -- Tentar criar fallback
        modelo = CriarModeloFallback(itemId)
        valido, mensagem = ValidarModelo(modelo, itemId)
        
        if not valido then
            warn("ModelosItens: Fallback também inválido para " .. itemId)
            carregamentoPendente[itemId] = false
            return nil
        end
    end
    
    -- Adicionar ao cache
    cacheModelos[itemId] = modelo
    cacheTempoUso[itemId] = tick()
    cacheContadorUso[itemId] = 1
    
    -- Marcar como não mais em carregamento
    carregamentoPendente[itemId] = false
    
    -- Limpar cache se necessário
    if #cacheModelos > MAX_CACHE_SIZE then
        spawn(LimparCache)
    end
    
    return modelo:Clone()
end

-- Obter configurações de colocação de um item
function ModelosItens:ObterConfiguracoesColocacao(itemId)
    local definicao = definicoes[itemId]
    if not definicao or not definicao.modelo.colocacao then
        return {
            superficie = {"terreno"},
            angulos = {0, 90, 180, 270},
            altura = 0,
            distanciaMinima = 1
        }
    end
    
    return definicao.modelo.colocacao
end

-- Obter tamanho e offset de um item
function ModelosItens:ObterTamanhoEOffset(itemId)
    local definicao = definicoes[itemId]
    if not definicao then
        return Vector3.new(1, 1, 1), Vector3.new(0, 0.5, 0)
    end
    
    return definicao.modelo.tamanho, definicao.modelo.offset
end

-- Verificar se um item é rotacionável
function ModelosItens:EhRotacionavel(itemId)
    local definicao = definicoes[itemId]
    if not definicao then return true end
    
    return definicao.modelo.rotacionavel
end

-- Obter rotação padrão de um item
function ModelosItens:ObterRotacaoPadrao(itemId)
    local definicao = definicoes[itemId]
    if not definicao or not definicao.modelo.rotacaoPadrao then
        return CFrame.Angles(0, 0, 0)
    end
    
    return definicao.modelo.rotacaoPadrao
end

-- Obter interações disponíveis para um item
function ModelosItens:ObterInteracoes(itemId)
    local definicao = definicoes[itemId]
    if not definicao or not definicao.modelo.interacoes then
        return {}
    end
    
    return definicao.modelo.interacoes
end

-- Obter versão de um modelo
function ModelosItens:ObterVersaoModelo(itemId)
    local definicao = definicoes[itemId]
    if not definicao then return "0.0.0" end
    
    return definicao.modelo.versao
end

-- Verificar se um modelo precisa de atualização
function ModelosItens:PrecisaAtualizar(itemId, versaoAtual)
    local definicao = definicoes[itemId]
    if not definicao then return false end
    
    -- Comparar versões (simplificado)
    return definicao.modelo.versao ~= versaoAtual
end

-- Limpar cache de um item específico
function ModelosItens:LimparCacheItem(itemId)
    if cacheModelos[itemId] then
        cacheModelos[itemId] = nil
        cacheTempoUso[itemId] = nil
        cacheContadorUso[itemId] = nil
        return true
    end
    return false
end

-- Limpar todo o cache
function ModelosItens:LimparTodoCache()
    cacheModelos = {}
    cacheTempoUso = {}
    cacheContadorUso = {}
    return true
end

-- Obter estatísticas do sistema
function ModelosItens:ObterEstatisticas()
    local numItensCache = 0
    for _ in pairs(cacheModelos) do
        numItensCache = numItensCache + 1
    end
    
    return {
        versaoSistema = VERSAO_SISTEMA,
        numItensDefinidos = #definicoes,
        numItensEmCache = numItensCache,
        maxCacheSize = MAX_CACHE_SIZE,
        tempoCacheSeg = TEMPO_CACHE
    }
end

-- Inicialização
do
    print("ModelosItens: Inicializando sistema de modelos 3D v" .. VERSAO_SISTEMA)
    
    -- Verificar pastas necessárias
    if not PASTA_MODELOS then
        PASTA_MODELOS = Instance.new("Folder")
        PASTA_MODELOS.Name = "Modelos"
        PASTA_MODELOS.Parent = ServerStorage
        warn("ModelosItens: Pasta de modelos não encontrada, criando pasta vazia")
    end
    
    if not PASTA_MODELOS_FALLBACK then
        PASTA_MODELOS_FALLBACK = Instance.new("Folder")
        PASTA_MODELOS_FALLBACK.Name = "ModelosFallback"
        PASTA_MODELOS_FALLBACK.Parent = ServerStorage
        warn("ModelosItens: Pasta de modelos fallback não encontrada, criando pasta vazia")
    end
    
    -- Configurar limpeza periódica de cache
    spawn(function()
        while true do
            wait(60) -- Verificar a cada minuto
            LimparCache()
        end
    end)
    
    -- Pré-carregar modelos comuns
    spawn(function()
        wait(5) -- Esperar um pouco para o jogo inicializar
        PreCarregarModelosComuns()
    end)
    
    print("ModelosItens: Sistema inicializado com " .. #definicoes .. " definições de itens")
end

return ModelosItens
