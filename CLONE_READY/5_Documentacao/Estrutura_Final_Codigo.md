# Estrutura Final do Código  
_Viva Fantasy Island – Julho 2025_

Este documento descreve a árvore de diretórios **após a limpeza** dos arquivos de teste/debug. Listamos apenas os scripts, módulos e recursos **de produção** que compõem a primeira versão completa do jogo.

---

## 1. Visão-geral

```
src/
├─ ServerScriptService/
│  └─ GameManager.lua
├─ ServerStorage/
│  ├─ Modules/
│  │  ├─ ConstrucaoModule.lua
│  │  ├─ DataStoreModule.lua
│  │  ├─ EconomiaModule.lua
│  │  └─ MissoesModule.lua
│  └─ Modelos/
│     └─ ModelosItens.lua
└─ StarterGui/
   └─ MainGui/
      ├─ DragDropSystem.lua
      ├─ InventarioGui.lua
      ├─ LojaGui.lua
      ├─ MissoesGui.lua
      ├─ SistemaConstrucao.lua
      ├─ MainGui.rbxmx
      └─ init.lua
docs/
└─ Teste_Melhoria_A_Funcionalidades.md
```

---

## 2. Descrição dos Componentes

### 2.1 ServerScriptService

| Arquivo | Função principal |
|---------|------------------|
| **GameManager.lua** | Entrada do lado servidor. Inicializa sistemas, gerencia _lifecycle_ dos jogadores, proxies para módulos (economia, dados, construção). |

### 2.2 ServerStorage

#### 2.2.1 Modules

| Módulo | Responsabilidade |
|--------|------------------|
| **EconomiaModule.lua** | Sistema de DreamCoins, compras, validação anti-exploit, hooks para inventário. |
| **DataStoreModule.lua** | Persistência de dados com salvamento em lote, cache e _back-off_ em falhas. |
| **MissoesModule.lua** | Lógica de missões diárias/semanais, progressão e distribuição de recompensas. |
| **ConstrucaoModule.lua** | API servidor para colocar/remover objetos na ilha, verificação de colisão, _undo/redo_. |

#### 2.2.2 Modelos

| Módulo | Responsabilidade |
|--------|------------------|
| **ModelosItens.lua** | Catálogo de modelos 3D, LOD dinâmico, cache, materiais, efeitos especiais. |

### 2.3 StarterGui / MainGui

| Script/Asset | Função |
|--------------|--------|
| **MainGui.rbxmx** | Estrutura XML da interface (HUD, menus). Importar em Roblox Studio. |
| **init.lua** | Controlador central do lado cliente; abre/fecha menus, roteia eventos de UI. |
| **LojaGui.lua** | Interface de loja com categorias, busca, compra e feedback de transação. |
| **InventarioGui.lua** | Inventário em grade, filtros, painel de detalhes. |
| **MissoesGui.lua** | Aba de missões com barras de progresso, coleta de prêmios. |
| **DragDropSystem.lua** | Arrastar-e-soltar avançado (multi-seleção, grid-snap, mobile support). |
| **SistemaConstrucao.lua** | Modo construção: preview 3D, raycast, rotação, _undo/redo_, integração com servidor. |

---

## 3. Fluxo de Dados & Comunicação

1. **Player joins** → `GameManager.lua` carrega dados via `DataStoreModule` e injeta saldo inicial em `EconomiaModule`.
2. Interface (`init.lua`) requisita inventário/loja ao servidor, popula `InventarioGui` e `LojaGui`.
3. Jogador **compra** item → `LojaGui.lua` chama `EconomiaModule` (RemoteEvent) → dados persistidos → inventário atualizado.
4. **Drag & Drop** em inventário → `DragDropSystem.lua` decide destino:  
   a. Reorganizar grade (evento local)  
   b. Construir na ilha → envia `ColocarDecoracao` ao servidor → `ConstrucaoModule.lua` valida e instancia modelo obtido de `ModelosItens.lua`.
5. **Missões** atualizam-se por progresso de construção, compras e tempo → `MissoesModule.lua` notifica `MissoesGui.lua`.

---

## 4. Padrões & Convenções

* **Prefixos**  
  `RemoteEvents` em `ReplicatedStorage/RemoteEvents` seguem verbo no infinitivo (`ColocarDecoracao`, `AtualizarInventario`).

* **Atributos**  
  Itens GUI possuem `ItemId`, `Nome`, `Descricao` para evitar chamadas adicionais.

* **Style-guide**  
  – Snake case para arquivos (`ModelosItens.lua`).  
  – PascalCase para serviços e eventos.  
  – Comentários em PT-BR.

---

## 5. Próximos Passos

1. Testar conforme `docs/Teste_Melhoria_A_Funcionalidades.md`.  
2. Implementar **Melhoria B** (modelos 3D restantes) ou escolher entre sistemas Social/Mini-jogos.  

> Para dúvidas ou bugs, abra _issue_ usando o template **Bug Report** e marque a _milestone_ correspondente.

---
_Versão da estrutura: 27 jul 2025_
