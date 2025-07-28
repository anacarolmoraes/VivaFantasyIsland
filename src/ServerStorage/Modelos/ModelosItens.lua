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
    - Sistema de LOD (Level of Detail)
    - Otimização de performance
    - Versionamento de modelos
    - Efeitos especiais por categoria
    - Sistema de preços balanceado
    
    Autor: Factory AI
    Data: 28/07/2025
    Versão: 2.0.0
]]

-- Serviços do Roblox
local ServerStorage = game:GetService("ServerStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Constantes
local VERSAO_SISTEMA = "2.0.0"
local PASTA_MODELOS = ServerStorage:WaitForChild("Modelos")
local PASTA_MODELOS_FALLBACK = ServerStorage:WaitForChild("ModelosFallback")
local MAX_CACHE_SIZE = 75 -- Aumentado para suportar mais itens
local TEMPO_CACHE = 600 -- Aumentado para 10 minutos
local DISTANCIA_LOD = {
    ALTA = 25,    -- Distância para LOD alta qualidade
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
    -- CATEGORIA: DECORAÇÕES (9 itens)
    
    -- 1. Cerca de Madeira
    cerca_madeira = {
        nome = "Cerca de Madeira",
        descricao = "Uma cerca rústica para delimitar sua propriedade.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 50,
        modelo = {
            path = "cerca_madeira_v1",
            versao = "1.0.1",
            tamanho = Vector3.new(2, 1, 0.2),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                principal = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(133, 94, 66)
                }
            },
            lod = {
                alta = {path = "cerca_madeira_v1_lod0"},
                media = {path = "cerca_madeira_v1_lod1"},
                baixa = {path = "cerca_madeira_v1_lod2"},
                muito_baixa = {path = "cerca_madeira_v1_lod3"}
            },
            fallback = {
                tipo = "parte",
                tamanho = Vector3.new(2, 1, 0.2),
                cor = Color3.fromRGB(133, 94, 66),
                material = Enum.Material.Wood
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 0.5
            }
        }
    },
    
    -- 2. Pedra Decorativa
    pedra_decorativa = {
        nome = "Pedra Decorativa",
        descricao = "Uma pedra natural para decorar seu jardim.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 40,
        modelo = {
            path = "pedra_decorativa_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(1.2, 0.8, 1.2),
            offset = Vector3.new(0, 0.4, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                principal = {
                    material = Enum.Material.Rock,
                    cor = Color3.fromRGB(120, 120, 120)
                }
            },
            lod = {
                alta = {path = "pedra_decorativa_v1_lod0"},
                media = {path = "pedra_decorativa_v1_lod1"}
            },
            fallback = {
                tipo = "parte",
                tamanho = Vector3.new(1.2, 0.8, 1.2),
                cor = Color3.fromRGB(120, 120, 120),
                material = Enum.Material.Rock
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "grama"},
                angulos = {0, 45, 90, 135, 180, 225, 270, 315},
                distanciaMinima = 0.8
            }
        }
    },
    
    -- 3. Estátua Pequena
    estatua_pequena = {
        nome = "Estátua de Pedra",
        descricao = "Uma pequena estátua decorativa.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 200,
        modelo = {
            path = "estatua_pequena_v1",
            versao = "1.0.1",
            tamanho = Vector3.new(1, 2, 1),
            offset = Vector3.new(0, 1, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                principal = {
                    material = Enum.Material.Slate,
                    cor = Color3.fromRGB(180, 180, 180)
                }
            },
            lod = {
                alta = {path = "estatua_pequena_v1_lod0"},
                media = {path = "estatua_pequena_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 45, 90, 135, 180, 225, 270, 315},
                distanciaMinima = 1
            }
        }
    },
    
    -- 4. Fonte de Pedra
    fonte_pedra = {
        nome = "Fonte de Pedra",
        descricao = "Uma elegante fonte de água para embelezar seu jardim.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 280,
        modelo = {
            path = "fonte_pedra_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(3, 2.5, 3),
            offset = Vector3.new(0, 1.25, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                pedra = {
                    material = Enum.Material.Slate,
                    cor = Color3.fromRGB(170, 170, 170)
                },
                agua = {
                    material = Enum.Material.Glass,
                    cor = Color3.fromRGB(90, 140, 255),
                    propriedades = {
                        Transparency = 0.7,
                        Reflectance = 0.3
                    }
                }
            },
            lod = {
                alta = {path = "fonte_pedra_v1_lod0"},
                media = {path = "fonte_pedra_v1_lod1"}
            },
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
                    agua = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(2.2, 0.1, 2.2),
                        posicao = Vector3.new(0, 0.7, 0),
                        cor = Color3.fromRGB(90, 140, 255),
                        material = Enum.Material.Glass
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 2
            },
            efeitos = {
                particulas = {
                    tipo = "agua",
                    taxa = 20,
                    cor = Color3.fromRGB(255, 255, 255)
                },
                som = {
                    id = "rbxassetid://169380495",
                    volume = 0.5,
                    looping = true
                }
            }
        }
    },
    
    -- 5. Luminária de Jardim
    luminaria_jardim = {
        nome = "Luminária de Jardim",
        descricao = "Ilumina seu jardim com um brilho aconchegante.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 120,
        modelo = {
            path = "luminaria_jardim_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.5, 1.5, 0.5),
            offset = Vector3.new(0, 0.75, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                poste = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(40, 40, 40)
                },
                vidro = {
                    material = Enum.Material.Glass,
                    cor = Color3.fromRGB(255, 240, 200),
                    propriedades = {
                        Transparency = 0.5,
                        Reflectance = 0.2
                    }
                }
            },
            lod = {
                alta = {path = "luminaria_jardim_v1_lod0"},
                media = {path = "luminaria_jardim_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
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
                        material = Enum.Material.Glass
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "grama"},
                angulos = {0},
                distanciaMinima = 0.5
            },
            efeitos = {
                brilho = {
                    ativo = true,
                    cor = Color3.fromRGB(255, 240, 200),
                    intensidade = 1,
                    alcance = 12
                }
            }
        }
    },
    
    -- 6. Banco de Parque
    banco_parque = {
        nome = "Banco de Parque",
        descricao = "Um banco confortável para relaxar ao ar livre.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 150,
        modelo = {
            path = "banco_parque_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2.5, 1, 1),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                madeira = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 90, 60)
                },
                metal = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(80, 80, 80)
                }
            },
            lod = {
                alta = {path = "banco_parque_v1_lod0"},
                media = {path = "banco_parque_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 1
            },
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
    
    -- 7. Caixa de Correio
    caixa_correio = {
        nome = "Caixa de Correio",
        descricao = "Uma caixa de correio decorativa para sua ilha.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 70,
        modelo = {
            path = "caixa_correio_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.6, 1.2, 0.6),
            offset = Vector3.new(0, 0.6, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                metal = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(50, 120, 180)
                },
                poste = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 100, 80)
                }
            },
            lod = {
                alta = {path = "caixa_correio_v1_lod0"},
                media = {path = "caixa_correio_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "grama"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 0.5
            },
            interacoes = {
                abrir = true,
                guardarItens = true,
                capacidade = 5
            }
        }
    },
    
    -- 8. Estátua Grande
    estatua_grande = {
        nome = "Estátua Grande",
        descricao = "Uma estátua imponente para o centro da sua ilha.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 300,
        modelo = {
            path = "estatua_grande_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 4, 2),
            offset = Vector3.new(0, 2, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                marmore = {
                    material = Enum.Material.Marble,
                    cor = Color3.fromRGB(220, 220, 220),
                    propriedades = {
                        Reflectance = 0.1
                    }
                }
            },
            lod = {
                alta = {path = "estatua_grande_v1_lod0"},
                media = {path = "estatua_grande_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma"},
                angulos = {0, 45, 90, 135, 180, 225, 270, 315},
                distanciaMinima = 2
            }
        }
    },
    
    -- 9. Poste de Sinalização
    poste_sinalizacao = {
        nome = "Poste de Sinalização",
        descricao = "Um poste com placa para sinalizar áreas da sua ilha.",
        categoria = CATEGORIAS.DECORACOES,
        preco = 60,
        modelo = {
            path = "poste_sinalizacao_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.8, 2, 0.8),
            offset = Vector3.new(0, 1, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                madeira = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 100, 80)
                },
                placa = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(200, 200, 200)
                }
            },
            lod = {
                alta = {path = "poste_sinalizacao_v1_lod0"},
                media = {path = "poste_sinalizacao_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    poste = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.1, 2, 0.1),
                        posicao = Vector3.new(0, 1, 0),
                        cor = Color3.fromRGB(120, 100, 80),
                        material = Enum.Material.Wood
                    },
                    placa = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.6, 0.4, 0.05),
                        posicao = Vector3.new(0, 1.5, 0),
                        cor = Color3.fromRGB(200, 200, 200),
                        material = Enum.Material.Wood
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "grama", "plataforma"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 0.5
            },
            interacoes = {
                editar = true
            }
        }
    },
    
    -- CATEGORIA: MÓVEIS (5 itens)
    
    -- 10. Mesa de Madeira
    mesa_madeira = {
        nome = "Mesa de Madeira",
        descricao = "Uma mesa robusta para sua casa.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 120,
        modelo = {
            path = "mesa_madeira_v1",
            versao = "1.0.1",
            tamanho = Vector3.new(2, 1, 2),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                principal = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(160, 120, 80)
                }
            },
            lod = {
                alta = {path = "mesa_madeira_v1_lod0"},
                media = {path = "mesa_madeira_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 1
            },
            interacoes = {
                colocarItens = true
            }
        }
    },
    
    -- 11. Cadeira Simples
    cadeira_simples = {
        nome = "Cadeira Simples",
        descricao = "Uma cadeira básica e confortável.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 80,
        modelo = {
            path = "cadeira_simples_v1",
            versao = "1.0.1",
            tamanho = Vector3.new(1, 1.5, 1),
            offset = Vector3.new(0, 0.75, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                estrutura = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(160, 120, 80)
                },
                estofado = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(180, 160, 140)
                }
            },
            lod = {
                alta = {path = "cadeira_simples_v1_lod0"},
                media = {path = "cadeira_simples_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 0.5
            },
            interacoes = {
                sentarEm = true,
                posicaoSentar = Vector3.new(0, 0.6, 0)
            }
        }
    },
    
    -- 12. Sofá Moderno
    sofa_moderno = {
        nome = "Sofá Moderno",
        descricao = "Um sofá elegante e confortável para sua casa.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 250,
        modelo = {
            path = "sofa_moderno_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(3, 1, 1.2),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                estofado = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(60, 100, 160)
                },
                almofadas = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(240, 240, 240)
                }
            },
            lod = {
                alta = {path = "sofa_moderno_v1_lod0"},
                media = {path = "sofa_moderno_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 1.5
            },
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
    
    -- 13. Estante de Livros
    estante_livros = {
        nome = "Estante de Livros",
        descricao = "Uma estante elegante para exibir seus livros e decorações.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 180,
        modelo = {
            path = "estante_livros_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 3, 0.6),
            offset = Vector3.new(0, 1.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                madeira = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 80, 50)
                },
                livros = {
                    material = Enum.Material.Plastic,
                    cor = Color3.fromRGB(180, 180, 180)
                }
            },
            lod = {
                alta = {path = "estante_livros_v1_lod0"},
                media = {path = "estante_livros_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 3, 0.6),
                        posicao = Vector3.new(0, 1.5, 0),
                        cor = Color3.fromRGB(120, 80, 50),
                        material = Enum.Material.Wood
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 1
            },
            interacoes = {
                guardarItens = true,
                capacidade = 20
            }
        }
    },
    
    -- 14. Cama Simples
    cama_simples = {
        nome = "Cama Simples",
        descricao = "Uma cama confortável para descansar.",
        categoria = CATEGORIAS.MOVEIS,
        preco = 200,
        modelo = {
            path = "cama_simples_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 0.8, 3),
            offset = Vector3.new(0, 0.4, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                estrutura = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(140, 100, 70)
                },
                colchao = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(240, 240, 240)
                },
                cobertor = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(70, 130, 180)
                }
            },
            lod = {
                alta = {path = "cama_simples_v1_lod0"},
                media = {path = "cama_simples_v1_lod1"}
            },
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
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 1.5
            },
            interacoes = {
                deitar = true,
                dormir = true,
                recuperarEnergia = true
            }
        }
    },
    
    -- CATEGORIA: PLANTAS (6 itens)
    
    -- 15. Árvore Pequena
    arvore_pequena = {
        nome = "Árvore Pequena",
        descricao = "Uma árvore jovem para sua ilha.",
        categoria = CATEGORIAS.PLANTAS,
        preco = 100,
        modelo = {
            path = "arvore_pequena_v1",
            versao = "1.0.1",
            tamanho = Vector3.new(2, 3, 2),
            offset = Vector3.new(0, 1.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                tronco = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(121, 85, 58)
                },
                folhas = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(67, 140, 50)
                }
            },
            lod = {
                alta = {path = "arvore_pequena_v1_lod0"},
                media = {path = "arvore_pequena_v1_lod1"}
            },
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
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno"},
                angulos = {0},
                distanciaMinima = 2
            },
            efeitos = {
                vento = {
                    ativo = true,
                    intensidade = 0.1
                }
            }
        }
    },
    
    -- 16. Flores Azuis
    flor_azul = {
        nome = "Flores Azuis",
        descricao = "Um canteiro de belas flores azuis.",
        categoria = CATEGORIAS.PLANTAS,
        preco = 30,
        modelo = {
            path = "flor_azul_v1",
            versao = "1.0.1",
            tamanho = Vector3.new(0.5, 0.5, 0.5),
            offset = Vector3.new(0, 0.25, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                petalas = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(50, 100, 255)
                },
                caule = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(70, 160, 70)
                }
            },
            lod = {
                alta = {path = "flor_azul_v1_lod0"},
                media = {path = "flor_azul_v1_lod1"}
            },
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
                    flor = {
                        tipo = "esfera",
                        tamanho = Vector3.new(0.2, 0.1, 0.2),
                        posicao = Vector3.new(0, 0.35, 0),
                        cor = Color3.fromRGB(50, 100, 255),
                        material = Enum.Material.Fabric
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno", "grama"},
                angulos = {0},
                distanciaMinima = 0.3
            }
        }
    },
    
    -- 17. Árvore Grande
    arvore_grande = {
        nome = "Árvore Grande",
        descricao = "Uma árvore madura e volumosa.",
        categoria = CATEGORIAS.PLANTAS,
        preco = 180,
        modelo = {
            path = "arvore_grande_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(4, 6, 4),
            offset = Vector3.new(0, 3, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                tronco = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(100, 70, 50)
                },
                folhas = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(60, 130, 40)
                }
            },
            lod = {
                alta = {path = "arvore_grande_v1_lod0"},
                media = {path = "arvore_grande_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    tronco = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(1, 6, 1),
                        posicao = Vector3.new(0, 3, 0),
                        cor = Color3.fromRGB(100, 70, 50),
                        material = Enum.Material.Wood
                    },
                    copa = {
                        tipo = "esfera",
                        tamanho = Vector3.new(4, 3, 4),
                        posicao = Vector3.new(0, 5, 0),
                        cor = Color3.fromRGB(60, 130, 40),
                        material = Enum.Material.Grass
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno"},
                angulos = {0},
                distanciaMinima = 3
            },
            efeitos = {
                vento = {
                    ativo = true,
                    intensidade = 0.08
                }
            }
        }
    },
    
    -- 18. Arbusto Florido
    arbusto_flores = {
        nome = "Arbusto Florido",
        descricao = "Arbusto com pequenas flores.",
        categoria = CATEGORIAS.PLANTAS,
        preco = 60,
        modelo = {
            path = "arbusto_flores_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(1.5, 1, 1.5),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                folhas = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(50, 120, 50)
                },
                flores = {
                    material = Enum.Material.Fabric,
                    cor = Color3.fromRGB(255, 200, 200)
                }
            },
            lod = {
                alta = {path = "arbusto_flores_v1_lod0"},
                media = {path = "arbusto_flores_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    arbusto = {
                        tipo = "esfera",
                        tamanho = Vector3.new(1.5, 1, 1.5),
                        posicao = Vector3.new(0, 0.5, 0),
                        cor = Color3.fromRGB(50, 120, 50),
                        material = Enum.Material.Grass
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno", "grama"},
                angulos = {0},
                distanciaMinima = 1
            }
        }
    },
    
    -- 19. Palmeira
    palmeira = {
        nome = "Palmeira",
        descricao = "Palmeira tropical alta.",
        categoria = CATEGORIAS.PLANTAS,
        preco = 220,
        modelo = {
            path = "palmeira_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(3, 8, 3),
            offset = Vector3.new(0, 4, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                tronco = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(90, 70, 50)
                },
                folhas = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(80, 160, 60)
                }
            },
            lod = {
                alta = {path = "palmeira_v1_lod0"},
                media = {path = "palmeira_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    tronco = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(0.8, 8, 0.8),
                        posicao = Vector3.new(0, 4, 0),
                        cor = Color3.fromRGB(90, 70, 50),
                        material = Enum.Material.Wood
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno", "areia"},
                angulos = {0},
                distanciaMinima = 2
            },
            efeitos = {
                vento = {
                    ativo = true,
                    intensidade = 0.15
                }
            }
        }
    },
    
    -- 20. Jardim de Flores
    jardim_flores = {
        nome = "Jardim de Flores",
        descricao = "Canteiro com várias flores coloridas.",
        categoria = CATEGORIAS.PLANTAS,
        preco = 140,
        modelo = {
            path = "jardim_flores_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(3, 0.5, 3),
            offset = Vector3.new(0, 0.25, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                terra = {
                    material = Enum.Material.Ground,
                    cor = Color3.fromRGB(90, 50, 30)
                },
                flores = {
                    material = Enum.Material.Grass,
                    cor = Color3.fromRGB(255, 255, 255)
                }
            },
            lod = {
                alta = {path = "jardim_flores_v1_lod0"},
                media = {path = "jardim_flores_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(3, 0.2, 3),
                        posicao = Vector3.new(0, 0.1, 0),
                        cor = Color3.fromRGB(90, 50, 30),
                        material = Enum.Material.Ground
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno"},
                angulos = {0},
                distanciaMinima = 1.5
            }
        }
    },
    
    -- CATEGORIA: ESPECIAIS (3 itens)
    
    -- 21. Portal Mágico
    portal_magico = {
        nome = "Portal Mágico",
        descricao = "Teletransporte para outras dimensões.",
        categoria = CATEGORIAS.ESPECIAIS,
        preco = 800,
        modelo = {
            path = "portal_magico_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2, 3, 0.6),
            offset = Vector3.new(0, 1.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                estrutura = {
                    material = Enum.Material.Marble,
                    cor = Color3.fromRGB(80, 80, 80)
                },
                portal = {
                    material = Enum.Material.Neon,
                    cor = Color3.fromRGB(100, 0, 150),
                    propriedades = {
                        Transparency = 0.3,
                        Reflectance = 0.2
                    }
                }
            },
            lod = {
                alta = {path = "portal_magico_v1_lod0"},
                media = {path = "portal_magico_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    arco = {
                        tipo = "bloco",
                        tamanho = Vector3.new(2, 3, 0.3),
                        posicao = Vector3.new(0, 1.5, 0),
                        cor = Color3.fromRGB(80, 80, 80),
                        material = Enum.Material.Marble
                    },
                    centro = {
                        tipo = "bloco",
                        tamanho = Vector3.new(1.6, 2.6, 0.1),
                        posicao = Vector3.new(0, 1.5, 0),
                        cor = Color3.fromRGB(100, 0, 150),
                        material = Enum.Material.Neon
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno", "plataforma"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 3
            },
            efeitos = {
                particulas = {
                    tipo = "magico",
                    taxa = 10,
                    cor = Color3.fromRGB(150, 50, 200)
                },
                brilho = {
                    ativo = true,
                    cor = Color3.fromRGB(150, 50, 200),
                    intensidade = 1,
                    alcance = 8
                }
            },
            interacoes = {
                teleportar = true,
                configurarDestino = true
            }
        }
    },
    
    -- 22. Cristal de Energia
    cristal_energia = {
        nome = "Cristal de Energia",
        descricao = "Emite uma aura misteriosa.",
        categoria = CATEGORIAS.ESPECIAIS,
        preco = 400,
        modelo = {
            path = "cristal_energia_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(1, 1.8, 1),
            offset = Vector3.new(0, 0.9, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, math.rad(math.random(0, 359)), 0),
            materiais = {
                cristal = {
                    material = Enum.Material.Neon,
                    cor = Color3.fromRGB(50, 0, 200),
                    propriedades = {
                        Transparency = 0.2,
                        Reflectance = 0.5
                    }
                },
                base = {
                    material = Enum.Material.Slate,
                    cor = Color3.fromRGB(60, 60, 60)
                }
            },
            lod = {
                alta = {path = "cristal_energia_v1_lod0"},
                media = {path = "cristal_energia_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(1, 0.2, 1),
                        posicao = Vector3.new(0, 0.1, 0),
                        cor = Color3.fromRGB(60, 60, 60),
                        material = Enum.Material.Slate
                    },
                    cristal = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.5, 1.6, 0.5),
                        posicao = Vector3.new(0, 1, 0),
                        cor = Color3.fromRGB(50, 0, 200),
                        material = Enum.Material.Neon
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno", "plataforma", "piso"},
                angulos = {0},
                distanciaMinima = 1
            },
            efeitos = {
                brilho = {
                    ativo = true,
                    cor = Color3.fromRGB(100, 50, 255),
                    intensidade = 0.8,
                    alcance = 10
                },
                particulas = {
                    tipo = "energia",
                    taxa = 5,
                    cor = Color3.fromRGB(100, 50, 255)
                }
            }
        }
    },
    
    -- 23. Altar Místico
    altar_mistico = {
        nome = "Altar Místico",
        descricao = "Lugar de rituais antigos.",
        categoria = CATEGORIAS.ESPECIAIS,
        preco = 650,
        modelo = {
            path = "altar_mistico_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(2.5, 1, 2.5),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                pedra = {
                    material = Enum.Material.Slate,
                    cor = Color3.fromRGB(100, 100, 100)
                },
                simbolos = {
                    material = Enum.Material.Neon,
                    cor = Color3.fromRGB(200, 50, 50),
                    propriedades = {
                        Reflectance = 0.2
                    }
                }
            },
            lod = {
                alta = {path = "altar_mistico_v1_lod0"},
                media = {path = "altar_mistico_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    base = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(2.5, 0.3, 2.5),
                        posicao = Vector3.new(0, 0.15, 0),
                        cor = Color3.fromRGB(100, 100, 100),
                        material = Enum.Material.Slate
                    },
                    topo = {
                        tipo = "cilindro",
                        tamanho = Vector3.new(2, 0.2, 2),
                        posicao = Vector3.new(0, 0.4, 0),
                        cor = Color3.fromRGB(80, 80, 80),
                        material = Enum.Material.Slate
                    }
                }
            },
            fisica = {anchored = true, canCollide = true},
            colocacao = {
                superficie = {"terreno"},
                angulos = {0},
                distanciaMinima = 2
            },
            efeitos = {
                particulas = {
                    tipo = "fumaca",
                    taxa = 2,
                    cor = Color3.fromRGB(100, 100, 100)
                }
            },
            interacoes = {
                ritual = true,
                colocarItens = true
            }
        }
    },
    
    -- CATEGORIA: FERRAMENTAS (3 itens)
    
    -- 24. Martelo de Construção
    martelo_construcao = {
        nome = "Martelo de Construção",
        descricao = "Ferramenta essencial para obras.",
        categoria = CATEGORIAS.FERRAMENTAS,
        preco = 45,
        modelo = {
            path = "martelo_construcao_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.3, 0.8, 0.2),
            offset = Vector3.new(0, 0.4, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                cabo = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 100, 80)
                },
                cabeca = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(100, 100, 100)
                }
            },
            lod = {
                alta = {path = "martelo_construcao_v1_lod0"},
                media = {path = "martelo_construcao_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    cabo = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.6, 0.1),
                        posicao = Vector3.new(0, 0.3, 0),
                        cor = Color3.fromRGB(120, 100, 80),
                        material = Enum.Material.Wood
                    },
                    cabeca = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.3, 0.2, 0.2),
                        posicao = Vector3.new(0, 0.7, 0),
                        cor = Color3.fromRGB(100, 100, 100),
                        material = Enum.Material.Metal
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno", "plataforma", "mesa"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 0.2
            },
            interacoes = {
                equipar = true,
                construir = true
            }
        }
    },
    
    -- 25. Pá de Jardinagem
    pa_jardinagem = {
        nome = "Pá de Jardinagem",
        descricao = "Ideal para cavar a terra.",
        categoria = CATEGORIAS.FERRAMENTAS,
        preco = 40,
        modelo = {
            path = "pa_jardinagem_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.3, 1, 0.2),
            offset = Vector3.new(0, 0.5, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                cabo = {
                    material = Enum.Material.Wood,
                    cor = Color3.fromRGB(120, 100, 80)
                },
                lamina = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(90, 90, 90)
                }
            },
            lod = {
                alta = {path = "pa_jardinagem_v1_lod0"},
                media = {path = "pa_jardinagem_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    cabo = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.8, 0.1),
                        posicao = Vector3.new(0, 0.4, 0),
                        cor = Color3.fromRGB(120, 100, 80),
                        material = Enum.Material.Wood
                    },
                    lamina = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.3, 0.2, 0.2),
                        posicao = Vector3.new(0, 0.9, 0),
                        cor = Color3.fromRGB(90, 90, 90),
                        material = Enum.Material.Metal
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno", "plataforma", "mesa"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 0.2
            },
            interacoes = {
                equipar = true,
                cavar = true
            }
        }
    },
    
    -- 26. Regador
    regador = {
        nome = "Regador",
        descricao = "Mantém suas plantas saudáveis.",
        categoria = CATEGORIAS.FERRAMENTAS,
        preco = 35,
        modelo = {
            path = "regador_v1",
            versao = "1.0.0",
            tamanho = Vector3.new(0.4, 0.6, 0.4),
            offset = Vector3.new(0, 0.3, 0),
            rotacionavel = true,
            rotacaoPadrao = CFrame.Angles(0, 0, 0),
            materiais = {
                corpo = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(70, 100, 160)
                },
                alca = {
                    material = Enum.Material.Metal,
                    cor = Color3.fromRGB(70, 70, 70)
                }
            },
            lod = {
                alta = {path = "regador_v1_lod0"},
                media = {path = "regador_v1_lod1"}
            },
            fallback = {
                tipo = "composto",
                componentes = {
                    corpo = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.4, 0.4, 0.4),
                        posicao = Vector3.new(0, 0.2, 0),
                        cor = Color3.fromRGB(70, 100, 160),
                        material = Enum.Material.Metal
                    },
                    bico = {
                        tipo = "bloco",
                        tamanho = Vector3.new(0.1, 0.1, 0.3),
                        posicao = Vector3.new(0, 0.2, 0.3),
                        cor = Color3.fromRGB(70, 100, 160),
                        material = Enum.Material.Metal
                    }
                }
            },
            fisica = {anchored = true, canCollide = false},
            colocacao = {
                superficie = {"terreno", "plataforma", "mesa"},
                angulos = {0, 90, 180, 270},
                distanciaMinima = 0.2
            },
            interacoes = {
                equipar = true,
                regar = true
            },
            efeitos = {
                particulas = {
                    tipo = "agua",
                    taxa = 10,
                    cor = Color3.fromRGB(200, 200, 255)
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
            estatisticas.fallbacksUsados = estatisticas.fallbacksUsados + 1
            return CriarModeloFallback(itemId)
        end
    end
    
    -- Clonar o modelo para não modificar o original
    local modeloClone = modelo:Clone()
    
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
            categoria = definicao.categoria,
            preco = definicao.preco
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
                descricao = definicao.descricao,
                preco = definicao.preco
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
    
    -- Estatísticas
    estatisticas.carregamentos = estatisticas.carregamentos + 1
    local tempoInicio = tick()
    
    -- Verificar cache primeiro
    if cacheModelos[itemId] then
        -- Atualizar estatísticas de uso
        cacheTempoUso[itemId] = tick()
        cacheContadorUso[itemId] = (cacheContadorUso[itemId] or 0) + 1
        estatisticas.cacheHits = estatisticas.cacheHits + 1
        
        return cacheModelos[itemId]:Clone()
    end
    
    estatisticas.cacheMisses = estatisticas.cacheMisses + 1
    
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
    carregamentoP