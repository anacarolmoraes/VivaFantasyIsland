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
    - Efeitos especiais por categoria
    - Sistema de preços balanceado
    - Validação automática de integridade
    
    Autor: Factory AI
    Data: 27/07/2025
    Versão: 2.0.0
]]

-- Serviços do Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Constantes
local VERSAO_SISTEMA = "2.0.0"
local PASTA_MODELOS = ServerStorage:WaitForChild("Modelos")
local PASTA_MODELOS_FALLBACK = ServerStorage:WaitForChild("ModelosFallback")
local MAX_CACHE_SIZE = 75 -- Aumentado para suportar mais itens
local TEMPO_CACHE = 600 -- Aumentado para 10 minutos
local DISTANCIA_LOD = {
    ALTA = 25,    -- Aumentado para melhor qualidade visual
    MEDIA = 60,   -- Distância para LOD média qualidade
    BAIXA = 120,  -- Distância para LOD baixa qualidade
    MUITO_BAIXA = 250 -- Distância para LOD muito baixa qualidade
}

--- Categorias de itens
local CATEGORIAS = {
    DECORACOES = "decoracoes",
    MOVEIS = "moveis",
    PLANTAS = "plantas",
    ESPECIAIS = "especiais",
    FERRAMENTAS = "ferramentas"
}

--- Faixas de preço balanceadas por categoria
local FAIXAS_PRECO = {
    [CATEGORIAS.DECORACOES] = {min = 50, max = 300},
    [CATEGORIAS.MOVEIS] = {min = 80, max = 500},
    [CATEGORIAS.PLANTAS] = {min = 30, max = 250},
    [CATEGORIAS.ESPECIAIS] = {min = 200, max = 1000},
    [CATEGORIAS.FERRAMENTAS] = {min = 40, max = 150}
}

-- Tabelas de cache
local cacheModelos = {} -- Cache de modelos carregados
local cacheTempoUso = {} -- Registro do último uso de cada modelo
local cacheContadorUso = {} -- Contador de uso de cada modelo
local cachePrioridade = {} -- Prioridade de cada modelo no cache (1-10)

-- Tabela de status de carregamento
local carregamentoPendente = {} -- Modelos em processo de carregamento

--- Estatísticas de uso
local estatisticas = {
    carregamentos = 0,
    cacheHits = 0,
    cacheMisses = 0,
    fallbacksUsados = 0,
    tempoTotalCarregamento = 0,
    iniciadoEm = os.time()
}

-- Módulo
local ModelosItens = {}

-- Definições de modelos
local definicoes = {
    -- Cerca de Madeira
    cerca_madeira = {
        nome = "Cerca de Madeira",
        descricao = "Uma cerca rústica para delimitar sua propriedade.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 50,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "cerca_madeira_v1", -- Nome do modelo no ServerStorage/Modelos
            versao = "1.0.1", -- Versão atualizada
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
        categoria = CATEGORIAS.PLANTAS,
        preco = 100,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "arvore_pequena_v1",
            versao = "1.0.1", -- Versão atualizada
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
        categoria = CATEGORIAS.MOVEIS,
        preco = 120,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "mesa_madeira_v1",
            versao = "1.0.1", -- Versão atualizada
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
        categoria = CATEGORIAS.MOVEIS,
        preco = 80,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "cadeira_simples_v1",
            versao = "1.0.1", -- Versão atualizada
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
        categoria = CATEGORIAS.PLANTAS,
        preco = 30,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "flor_azul_v1",
            versao = "1.0.1", -- Versão atualizada
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
        categoria = CATEGORIAS.DECORACOES,
        preco = 200,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "estatua_pequena_v1",
            versao = "1.0.1", -- Versão atualizada
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
    },

    -- NOVOS ITENS: DECORAÇÕES

    -- Fonte de Pedra
    fonte_pedra = {
        nome = "Fonte de Pedra",
        descricao = "Uma elegante fonte de água para embelezar seu jardim.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 280,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "fonte_pedra_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(3, 2.5, 3),
            offset = Vector3.new(0, 1.25, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            
            -- Materiais e texturas
            materiais = {
                pedra = {
                    material = Enum.Material.Slate,
                    cor = Color3.fromRGB(170, 170, 170),
                    textura = "rbxassetid://6797381023",
                    propriedades = {
                        Roughness = 0.8,
                        Metalness = 0.1
                    }
                },
                agua = {
                    material = Enum.Material.Glass,
                    cor = Color3.fromRGB(90, 140, 255),
                    textura = "rbxassetid://6797381123",
                    propriedades = {
                        Roughness = 0.1,
                        Metalness = 0,
                        Transparency = 0.7,
                        Reflectance = 0.3
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "fonte_pedra_v1_lod0",
                    triangulos = 6000,
                    texturaResolucao = 1024
                },
                media = {
                    path = "fonte_pedra_v1_lod1",
                    triangulos = 3000,
                    texturaResolucao = 512
                },
                baixa = {
                    path = "fonte_pedra_v1_lod2",
                    triangulos = 1500,
                    texturaResolucao = 256
                },
                muito_baixa = {
                    path = "fonte_pedra_v1_lod3",
                    triangulos = 800,
                    texturaResolucao = 128
                }
            },
            
            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(3, 0.5, 3),
                        posicao = Vector3.new(0, 0.25, 0),
                        cor = Color3.fromRGB(170, 170, 170),
                        material = Enum.Material.Slate
                    },
                    bacia = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(2.5, 0.3, 2.5),
                        posicao = Vector3.new(0, 0.65, 0),
                        cor = Color3.fromRGB(170, 170, 170),
                        material = Enum.Material.Slate
                    },
                    agua = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(2.2, 0.1, 2.2),
                        posicao = Vector3.new(0, 0.7, 0),
                        cor = Color3.fromRGB(90, 140, 255),
                        material = Enum.Material.Glass,
                        transparencia = 0.7
                    },
                    pilar = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.6, 1.5, 0.6),
                        posicao = Vector3.new(0, 1.45, 0),
                        cor = Color3.fromRGB(170, 170, 170),
                        material = Enum.Material.Slate
                    },
                    topo = {
                        tipo = "esfera",
                        tamanho = Vector3.new(0.8, 0.8, 0.8),
                        posicao = Vector3.new(0, 2.1, 0),
                        cor = Color3.fromRGB(170, 170, 170),
                        material = Enum.Material.Slate
                    }
                }
            },
            
            -- Configurações de física
            fisica = {
                massa = 500,
                tipo = "mesh",
                anchored = true,
                canCollide = true
            },
            
            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 2
            },
            
            -- Efeitos especiais
            efeitos = {
                particulas = {
                    tipo = "agua",
                    taxa = 20,
                    tamanho = 0.1,
                    cor = Color3.fromRGB(255, 255, 255),
                    velocidade = 3,
                    aceleracao = Vector3.new(0, -10, 0)
                },
                som = {
                    id = "rbxassetid://169380495", -- Som de água corrente
                    volume = 0.5,
                    alcance = 15,
                    looping = true
                },
                brilho = {
                    ativo = true,
                    cor = Color3.fromRGB(200, 220, 255),
                    intensidade = 0.2,
                    alcance = 5
                }
            }
        }
    },

    -- Luminária de Jardim
    luminaria_jardim = {
        nome = "Luminária de Jardim",
        descricao = "Ilumina seu jardim com um brilho aconchegante.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 120,

        -- Configurações do modelo 3D
        modelo = {
            path = "luminaria_jardim_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.5, 1.5, 0.5),
            offset = Vector3.new(0, 0.75, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),

            -- Materiais e texturas
            materiais = {
                poste = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(40, 40, 40),
                    textura = "rbxassetid://6797381223",
                    propriedades = {
                        Roughness = 0.5,
                        Metalness = 0.8
                    }
                },
                vidro = {
                    material = Enum.Material.Glass,
                    cor = Color3.fromRGB(255, 240, 200),
                    textura = "rbxassetid://6797381323",
                    propriedades = {
                        Roughness = 0.1,
                        Metalness = 0,
                        Transparency = 0.5,
                        Reflectance = 0.2
                    }
                }
            },

            -- Configurações de LOD
            lod = {
                alta = {
                    path = "luminaria_jardim_v1_lod0",
                    triangulos = 1200,
                    texturaResolucao = 512
                },
                media = {
                    path = "luminaria_jardim_v1_lod1",
                    triangulos = 600,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "luminaria_jardim_v1_lod2",
                    triangulos = 300,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "luminaria_jardim_v1_lod3",
                    triangulos = 150,
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
                        cor = Color3.fromRGB(40, 40, 40),
                        material = Enum.Material.Metal
                    },
                    poste = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.1, 1.2, 0.1),
                        posicao = Vector3.new(0, 0.7, 0),
                        cor = Color3.fromRGB(40, 40, 40),
                        material = Enum.Material.Metal
                    },
                    lampada = {
                        tipo = "esfera",
                        tamanho = Vector3.new(0.4, 0.4, 0.4),
                        posicao = Vector3.new(0, 1.4, 0),
                        cor = Color3.fromRGB(255, 240, 200),
                        material = Enum.Material.Glass,
                        transparencia = 0.5
                    }
                }
            },

            -- Configurações de física
            fisica = {
                massa = 20,
                tipo = "mesh",
                anchored = true,
                canCollide = true
            },

            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma", "grama"},
                angulos = {0},
                altura = 0,
                distanciaMinima = 0.5
            },

            -- Efeitos especiais
            efeitos = {
                brilho = {
                    ativo = true,
                    cor = Color3.fromRGB(255, 240, 200),
                    intensidade = 1,
                    alcance = 12
                },
                ciclo = {
                    ativo = true,
                    tipo = "dia_noite",
                    intensidadeDia = 0,
                    intensidadeNoite = 1
                }
            }
        }
    },

    -- Banco de Parque
    banco_parque = {
        nome = "Banco de Parque",
        descricao = "Um banco confortável para relaxar ao ar livre.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 150,

        -- Configurações do modelo 3D
        modelo = {
            path = "banco_parque_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2.5, 1, 1),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),

            -- Materiais e texturas
            materiais = {
                madeira = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 90, 60),
                    textura = "rbxassetid://6797381423",
                    propriedades = {
                        Roughness = 0.8,
                        Metalness = 0
                    }
                },
                metal = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(80, 80, 80),
                    textura = "rbxassetid://6797381523",
                    propriedades = {
                        Roughness = 0.6,
                        Metalness = 0.7
                    }
                }
            },

            -- Configurações de LOD
            lod = {
                alta = {
                    path = "banco_parque_v1_lod0",
                    triangulos = 2000,
                    texturaResolucao = 512
                },
                media = {
                    path = "banco_parque_v1_lod1",
                    triangulos = 1000,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "banco_parque_v1_lod2",
                    triangulos = 500,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "banco_parque_v1_lod3",
                    triangulos = 200,
                    texturaResolucao = 64
                }
            },

            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    assento = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2.5, 0.1, 0.8),
                        posicao = Vector3.new(0, 0.5, 0),
                        cor = Color3.fromRGB(120, 90, 60),
                        material = Enum.Material.Wood
                    },
                    encosto = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2.5, 0.6, 0.1),
                        posicao = Vector3.new(0, 0.8, -0.4),
                        cor = Color3.fromRGB(120, 90, 60),
                        material = Enum.Material.Wood
                    },
                    perna1 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.5, 0.6),
                        posicao = Vector3.new(1, 0.25, 0),
                        cor = Color3.fromRGB(80, 80, 80),
                        material = Enum.Material.Metal
                    },
                    perna2 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.5, 0.6),
                        posicao = Vector3.new(-1, 0.25, 0),
                        cor = Color3.fromRGB(80, 80, 80),
                        material = Enum.Material.Metal
                    }
                }
            },

            -- Configurações de física
            fisica = {
                massa = 80,
                tipo = "mesh",
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
                sentarEm = true,
                posicoesSentar = {
                    Vector3.new(-0.8, 0.6, 0),
                    Vector3.new(0, 0.6, 0),
                    Vector3.new(0.8, 0.6, 0)
                }
            }
        }
    },

    -- Caixa de Correio
    caixa_correio = {
        nome = "Caixa de Correio",
        descricao = "Uma caixa de correio decorativa para sua ilha.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 70,

        -- Configurações do modelo 3D
        modelo = {
            path = "caixa_correio_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.6, 1.2, 0.6),
            offset = Vector3.new(0, 0.6, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),

            -- Materiais e texturas
            materiais = {
                metal = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(50, 120, 180),
                    textura = "rbxassetid://6797381623",
                    propriedades = {
                        Roughness = 0.5,
                        Metalness = 0.8
                    }
                },
                poste = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 100, 80),
                    textura = "rbxassetid://6797381723",
                    propriedades = {
                        Roughness = 0.8,
                        Metalness = 0
                    }
                }
            },

            -- Configurações de LOD
            lod = {
                alta = {
                    path = "caixa_correio_v1_lod0",
                    triangulos = 1000,
                    texturaResolucao = 512
                },
                media = {
                    path = "caixa_correio_v1_lod1",
                    triangulos = 500,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "caixa_correio_v1_lod2",
                    triangulos = 250,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path = "caixa_correio_v1_lod3",
                    triangulos = 100,
                    texturaResolucao = 64
                }
            },

            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    poste = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.1, 1, 0.1),
                        posicao = Vector3.new(0, 0.5, 0),
                        cor = Color3.fromRGB(120, 100, 80),
                        material = Enum.Material.Wood
                    },
                    caixa = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.5, 0.3, 0.3),
                        posicao = Vector3.new(0, 1, 0),
                        cor = Color3.fromRGB(50, 120, 180),
                        material = Enum.Material.Metal
                    },
                    bandeira = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.05, 0.15, 0.2),
                        posicao = Vector3.new(0.3, 1.1, 0),
                        cor = Color3.fromRGB(200, 50, 50),
                        material = Enum.Material.Plastic
                    }
                }
            },

            -- Configurações de física
            fisica = {
                massa = 15,
                tipo = "mesh",
                anchored = true,
                canCollide = true
            },

            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "grama"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 0.5
            },

            -- Interações
            interacoes = {
                abrir = true,
                guardarItens = true,
                capacidade = 5
            }
        }
    },

    -- Estátua Grande
    estatua_grande = {
        nome = "Estátua Grande",
        descricao = "Uma estátua imponente para o centro da sua ilha.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 300,

        -- Configurações do modelo 3D
        modelo = {
            path = "estatua_grande_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 4, 2),
            offset = Vector3.new(0, 2, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),

            -- Materiais e texturas
            materiais = {
                marmore = {
                    material = Enum.Material.Marble,
                    cor = Color3.fromRGB(220, 220, 220),
                    textura = "rbxassetid://6797381823",
                    propriedades = {
                        Roughness = 0.3,
                        Metalness = 0.1,
                        Reflectance = 0.1
                    }
                },
                base = {
                    material = Enum.Material.Granite,
                    cor = Color3.fromRGB(180, 180, 180),
                    textura = "rbxassetid://6797381923",
                    propriedades = {
                        Roughness = 0.6,
                        Metalness = 0.05
                    }
                }
            },

            -- Configurações de LOD
            lod = {
                alta = {
                    path = "estatua_grande_v1_lod0",
                    triangulos = 10000,
                    texturaResolucao = 1024
                },
                media = {
                    path = "estatua_grande_v1_lod1",
                    triangulos = 5000,
                    texturaResolucao = 512
                },
                baixa = {
                    path = "estatua_grande_v1_lod2",
                    triangulos = 2000,
                    texturaResolucao = 256
                },
                muito_baixa = {
                    path = "estatua_grande_v1_lod3",
                    triangulos = 800,
                    texturaResolucao = 128
                }
            },

            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.5, 2),
                        posicao = Vector3.new(0, 0.25, 0),
                        cor = Color3.fromRGB(180, 180, 180),
                        material = Enum.Material.Granite
                    },
                    corpo = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(1, 3, 1),
                        posicao = Vector3.new(0, 2, 0),
                        cor = Color3.fromRGB(220, 220, 220),
                        material = Enum.Material.Marble
                    },
                    cabeca = {
                        tipo = "esfera",
                        tamanho = Vector3.new(0.8, 0.8, 0.8),
                        posicao = Vector3.new(0, 3.4, 0),
                        cor = Color3.fromRGB(220, 220, 220),
                        material = Enum.Material.Marble
                    }
                }
            },

            -- Configurações de física
            fisica = {
                massa = 500,
                tipo = "mesh",
                anchored = true,
                canCollide = true
            },

            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma"},
                angulos = {0, 45, 90, 135, 180, 225, 270, 315},
                altura = 0,
                distanciaMinima = 2
            },

            -- Efeitos especiais
            efeitos = {
                envelhecimento = {
                    ativo = true,
                    textura = "rbxassetid://6797382023",
                    intensidade = 0.2
                },
                particulas = {
                    tipo = "poeira",
                    taxa = 0.5,
                    tamanho = 0.1,
                    cor = Color3.fromRGB(220, 220, 220)
                },
                brilho = {
                    ativo = true,
                    cor = Color3.fromRGB(220, 220, 255),
                    intensidade = 0.05,
                    alcance = 8
                }
            }
        }
    },

    -- NOVOS ITENS: MÓVEIS

    -- Sofá Moderno
    sofa_moderno = {
        nome = "Sofá Moderno",
        descricao = "Um sofá elegante e confortável para sua casa.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 250,

        -- Configurações do modelo 3D
        modelo = {
            path = "sofa_moderno_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(3, 1, 1.2),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),

            -- Materiais e texturas
            materiais = {
                estofado = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(60, 100, 160),
                    textura = "rbxassetid://6797382123",
                    propriedades = {
                        Roughness = 0.9,
                        Metalness = 0
                    }
                },
                estrutura = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(80, 70, 60),
                    textura = "rbxassetid://6797382223",
                    propriedades = {
                        Roughness = 0.7,
                        Metalness = 0.1
                    }
                },
                almofadas = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(240, 240, 240),
                    textura = "rbxassetid://6797382323",
                    propriedades = {
                        Roughness = 1.0,
                        Metalness = 0
                    }
                }
            },

            -- Configurações de LOD
            lod = {
                alta = {
                    path = "sofa_moderno_v1_lod0",
                    triangulos = 4000,
                    texturaResolucao = 1024
                },
                media = {
                    path = "sofa_moderno_v1_lod1",
                    triangulos = 2000,
                    texturaResolucao = 512
                },
                baixa = {
                    path = "sofa_moderno_v1_lod2",
                    triangulos = 1000,
                    texturaResolucao = 256
                },
                muito_baixa = {
                    path = "sofa_moderno_v1_lod3",
                    triangulos = 500,
                    texturaResolucao = 128
                }
            },

            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    assento = {
                        tipo = "bloco",
                        tamanho = Vector3.new(3, 0.4, 1.2),
                        posicao = Vector3.new(0, 0.2, 0),
                        cor = Color3.fromRGB(60, 100, 160),
                        material = Enum.Material.Fabric
                    },
                    encosto = {
                        tipo = "bloco",
                        tamanho = Vector3.new(3, 0.8, 0.3),
                        posicao = Vector3.new(0, 0.6, -0.45),
                        cor = Color3.fromRGB(60, 100, 160),
                        material = Enum.Material.Fabric
                    },
                    almofada1 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.6, 0.2, 0.6),
                        posicao = Vector3.new(-1, 0.5, 0),
                        cor = Color3.fromRGB(240, 240, 240),
                        material = Enum.Material.Fabric
                    },
                    almofada2 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.6, 0.2, 0.6),
                        posicao = Vector3.new(1, 0.5, 0),
                        cor = Color3.fromRGB(240, 240, 240),
                        material = Enum.Material.Fabric
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
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 1.5
            },

            -- Interações
            interacoes = {
                sentarEm = true,
                posicoesSentar = {
                    Vector3.new(-1, 0.6, 0),
                    Vector3.new(0, 0.6, 0),
                    Vector3.new(1, 0.6, 0)
                }
            }
        }
    },

    -- Estante de Livros
    estante_livros = {
        nome = "Estante de Livros",
        descricao = "Uma estante elegante para exibir seus livros e decorações.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 180,

        -- Configurações do modelo 3D
        modelo = {
            path = "estante_livros_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 3, 0.6),
            offset = Vector3.new(0, 1.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),

            -- Materiais e texturas
            materiais = {
                madeira = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 80, 50),
                    textura = "rbxassetid://6797382423",
                    propriedades = {
                        Roughness = 0.8,
                        Metalness = 0
                    }
                },
                livros = {
                    material = Enum.Material.Plastic,
                    cor = Color3.fromRGB(180, 180, 180),
                    textura = "rbxassetid://6797382523",
                    propriedades = {
                        Roughness = 0.9,
                        Metalness = 0
                    }
                }
            },

            -- Configurações de LOD
            lod = {
                alta = {
                    path = "estante_livros_v1_lod0",
                    triangulos = 3000,
                    texturaResolucao = 1024
                },
                media = {
                    path = "estante_livros_v1_lod1",
                    triangulos = 1500,
                    texturaResolucao = 512
                },
                baixa = {
                    path = "estante_livros_v1_lod2",
                    triangulos = 800,
                    texturaResolucao = 256
                },
                muito_baixa = {
                    path = "estante_livros_v1_lod3",
                    triangulos = 400,
                    texturaResolucao = 128
                }
            },

            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.1, 0.6),
                        posicao = Vector3.new(0, 0.05, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    },
                    topo = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.1, 0.6),
                        posicao = Vector3.new(0, 2.95, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    },
                    lateral1 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 3, 0.6),
                        posicao = Vector3.new(-0.95, 1.5, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    },
                    lateral2 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 3, 0.6),
                        posicao = Vector3.new(0.95, 1.5, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    },
                    prateleira1 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.05, 0.6),
                        posicao = Vector3.new(0, 0.75, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    },
                    prateleira2 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.05, 0.6),
                        posicao = Vector3.new(0, 1.5, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    },
                    prateleira3 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.05, 0.6),
                        posicao = Vector3.new(0, 2.25, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    },
                    livros1 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1.8, 0.6, 0.5),
                        posicao = Vector3.new(0, 0.4, 0),
                        cor = Color3.fromRGB(180, 180, 180),
                        material = Enum.Material.Plastic
                    },
                    livros2 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1.8, 0.6, 0.5),
                        posicao = Vector3.new(0, 1.1, 0),
                        cor = Color3.fromRGB(180, 180, 180),
                        material = Enum.Material.Plastic
                    },
                    livros3 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1.8, 0.6, 0.5),
                        posicao = Vector3.new(0, 1.85, 0),
                        cor = Color3.fromRGB(180, 180, 180),
                        material = Enum.Material.Plastic
                    },
                    livros4 = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1.8, 0.6, 0.5),
                        posicao = Vector3.new(0, 2.6, 0),
                        cor = Color3.fromRGB(180, 180, 180),
                        material = Enum.Material.Plastic
                    }
                }
            },

            -- Configurações de física
            fisica = {
                massa = 150,
                tipo = "mesh",
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
                guardarItens = true,
                capacidade = 20
            }
        }
    },

    -- Cama Simples
    cama_simples = {
        nome = "Cama Simples",
        descricao = "Uma cama confortável para descansar.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 200,

        -- Configurações do modelo 3D
        modelo = {
            path = "cama_simples_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 0.8, 3),
            offset = Vector3.new(0, 0.4, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),

            -- Materiais e texturas
            materiais = {
                estrutura = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(140, 100, 70),
                    textura = "rbxassetid://6797382623",
                    propriedades = {
                        Roughness = 0.7,
                        Metalness = 0
                    }
                },
                colchao = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(240, 240, 240),
                    textura = "rbxassetid://6797382723",
                    propriedades = {
                        Roughness = 1.0,
                        Metalness = 0
                    }
                },
                cobertor = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(70, 130, 180),
                    textura = "rbxassetid://6797382823",
                    propriedades = {
                        Roughness = 0.9,
                        Metalness = 0
                    }
                },
                travesseiro = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(255, 255, 255),
                    textura = "rbxassetid://6797382923",
                    propriedades = {
                        Roughness = 1.0,
                        Metalness = 0
                    }
                }
            },

            -- Configurações de LOD
            lod = {
                alta = {
                    path = "cama_simples_v1_lod0",
                    triangulos = 3000,
                    texturaResolucao = 1024
                },
                media = {
                    path = "cama_simples_v1_lod1",
                    triangulos = 1500,
                    texturaResolucao = 512
                },
                baixa = {
                    path = "cama_simples_v1_lod2",
                    triangulos = 800,
                    texturaResolucao = 256
                },
                muito_baixa = {
                    path = "cama_simples_v1_lod3",
                    triangulos = 400,
                    texturaResolucao = 128
                }
            },

            -- Configurações de fallback
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.3, 3),
                        posicao = Vector3.new(0, 0.15, 0),
                        cor = Color3.fromRGB(140, 100, 70),
                        material = Enum.Material.Wood
                    },
                    colchao = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1.9, 0.2, 2.8),
                        posicao = Vector3.new(0, 0.4, 0),
                        cor = Color3.fromRGB(240, 240, 240),
                        material = Enum.Material.Fabric
                    },
                    cobertor = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1.9, 0.05, 1.4),
                        posicao = Vector3.new(0, 0.525, 0.7),
                        cor = Color3.fromRGB(70, 130, 180),
                        material = Enum.Material.Fabric
                    },
                    travesseiro = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.6, 0.1, 0.4),
                        posicao = Vector3.new(0, 0.55, -1.2),
                        cor = Color3.fromRGB(255, 255, 255),
                        material = Enum.Material.Fabric
                    },
                    cabeceira = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 0.8, 0.1),
                        posicao = Vector3.new(0, 0.7, -1.45),
                        cor = Color3.fromRGB(140, 100, 70),
                        material = Enum.Material.Wood
                    }
                }
            },

            -- Configurações de física
            fisica = {
                massa = 120,
                tipo = "mesh",
                anchored = true,
                canCollide = true
            },

            -- Configurações de colocação
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                altura = 0,
                distanciaMinima = 1.5
            },

            -- Interações
            interacoes = {
                deitar = true,
                dormir = true,
                recuperarEnergia = true
            }
        }
    },

    -- Mesa de Centro
    mesa_centro = {
        nome = "Mesa de Centro",
        descricao = "Uma mesa elegante para sua sala de estar.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 110,
        
        -- Configurações do modelo 3D
        modelo = {
            path = "mesa_centro_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(1.5, 0.6, 1.5),
            offset = Vector3.new(0, 0.3, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            
            -- Materiais e texturas
            materiais = {
                tampo = {
                    material = Enum.Material.Glass,
                    cor = Color3.fromRGB(200, 200, 220),
                    textura = "rbxassetid://6797383023",
                    propriedades = {
                        Roughness = 0.1,
                        Metalness = 0,
                        Transparency = 0.3,
                        Reflectance = 0.2
                    }
                },
                estrutura = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(60, 60, 60),
                    textura = "rbxassetid://6797383123",
                    propriedades = {
                        Roughness = 0.4,
                        Metalness = 0.8
                    }
                }
            },
            
            -- Configurações de LOD
            lod = {
                alta = {
                    path = "mesa_centro_v1_lod0",
                    triangulos = 1500,
                    texturaResolucao = 512
                },
                media = {
                    path = "mesa_centro_v1_lod1",
                    triangulos = 750,
                    texturaResolucao = 256
                },
                baixa = {
                    path = "mesa_centro_v1_lod2",
                    triangulos = 375,
                    texturaResolucao = 128
                },
                muito_baixa = {
                    path