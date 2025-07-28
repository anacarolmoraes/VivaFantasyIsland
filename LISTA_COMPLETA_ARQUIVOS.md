# 📦 LISTA COMPLETA DE ARQUIVOS

Guia rápido para clonar o repositório **Viva Fantasy Island** e importar cada arquivo na ordem correta no Roblox Studio.

---

## 1. ARQUIVOS PRINCIPAIS (.lua)

| ✅ | Ordem | Caminho no Repositório | Destino no Roblox Studio | Descrição |
|----|-------|-----------------------|--------------------------|-----------|
| [ ] | 1️⃣ | `src/ServerScriptService/GameManager.lua` | **ServerScriptService › GameManager** | Script mestre: ciclo de vida do jogador, init de sistemas. |
| [ ] | 2️⃣ | `src/ServerStorage/Modules/DataStoreModule.lua` | **ServerStorage › Modules › DataStoreModule** | Persistência de dados com cache & backup. |
| [ ] | 3️⃣ | `src/ServerStorage/Modules/EconomiaModule.lua` | **ServerStorage › Modules › EconomiaModule** | DreamCoins, inventário, anti-exploit. |
| [ ] | 4️⃣ | `src/ServerStorage/Modules/MissoesModule.lua` | **ServerStorage › Modules › MissoesModule** | Missões diárias/semanais, recompensas. |
| [ ] | 5️⃣ | `src/ServerStorage/Modules/ConstrucaoModule.lua` | **ServerStorage › Modules › ConstrucaoModule** | Lógica servidor da construção e validação. |
| [ ] | 6️⃣ | `src/ServerStorage/Modelos/ModelosItens.lua` | **ServerStorage › Modelos › ModelosItens** | 26 modelos 3D com LOD e propriedades. |
| [ ] | 7️⃣ | `src/StarterGui/MainGui/init.lua` | **StarterGui › MainGui › init (LocalScript)** | Controla HUD e alternância de menus. |
| [ ] | 8️⃣ | `src/StarterGui/MainGui/LojaGui.lua` | **StarterGui › MainGui › LojaGui** | Interface da Loja (5 categorias). |
| [ ] | 9️⃣ | `src/StarterGui/MainGui/InventarioGui.lua` | **StarterGui › MainGui › InventarioGui** | Inventário com drag & drop (6 categorias). |
| [ ] | 🔟 | `src/StarterGui/MainGui/MissoesGui.lua` | **StarterGui › MainGui › MissoesGui** | GUI de missões e progresso. |
| [ ] | 1️⃣1️⃣ | `src/StarterGui/MainGui/SistemaConstrucao.lua` | **StarterGui › MainGui › SistemaConstrucao** | Cliente: pré-visualização e colocação 3D. |
| [ ] | 1️⃣2️⃣ | `src/StarterGui/MainGui/DragDropSystem.lua` | **StarterGui › MainGui › DragDropSystem** | Multi-seleção e reorganização de itens. |

---

## 2. INTERFACE (.rbxmx)

| ✅ | Ordem | Caminho | Destino | Descrição |
|----|-------|---------|---------|-----------|
| [ ] | 1️⃣3️⃣ | `src/StarterGui/MainGui/MainGui.rbxmx` | **Importar via File › Import** <br>Cria pasta **StarterGui › MainGui** e objetos visuais | Estrutura de telas e botões. |

---

## 3. DOCUMENTAÇÃO (.md)

| 📄 Arquivo | Propósito Rápido |
|------------|------------------|
| `docs/Como_Configurar_Roblox_Studio.md` | Pré-requisitos do ambiente. |
| `docs/GUI_Setup_Manual.md` | Passo a passo para importar GUI. |
| `docs/Debug_Checklist.md` | Checklist de depuração comum. |
| `docs/RemoteEvents_Faltantes.md` | Lista de RemoteEvents esperados. |
| `docs/Teste_Melhoria_A_Funcionalidades.md` | Cenários de teste da Melhoria A. |
| `docs/Guia_Teste_Sistema3D_Completo.md` | Guia para validar todos os 26 itens. |
| `docs/Estrutura_Final_Codigo.md` | Visão geral da arquitetura final. |
| `README.md` | Visão geral do projeto. |

*Documentação não precisa ser importada no Roblox Studio; mantenha-a no repositório local.*

---

## 4. PASSOS DE CLONAGEM 🛠️

```bash
# 1. Clonar o repositório
git clone https://github.com/anacarolmoraes/VivaFantasyIsland.git
cd VivaFantasyIsland

# 2. Abrir o projeto no Roblox Studio
#    (File › Open Folder e selecione a pasta clonada)

# 3. Importar o arquivo .rbxmx
#    File › Import... › selecione src/StarterGui/MainGui/MainGui.rbxmx

# 4. Arrastar/copiar scripts .lua para os serviços indicados
#    Use o painel Explorer para posicionar conforme “Destino” na tabela.
```

---

## 5. VERIFICAÇÃO DE COMPLETUDE ✅

- [ ] **26/26** itens presentes em **ModelosItens.lua**  
- [ ] **26/26** itens no catálogo da **LojaGui.lua**  
- [ ] **26/26** itens no **EconomiaModule.lua**  
- [ ] Todas as 5 categorias visíveis na Loja (Decorações, Móveis, Plantas, Especiais, Ferramentas)  
- [ ] Inventário mostra 6 filtros (Todos + 5 categorias)  
- [ ] Sem erros no Output após Play Solo  
- [ ] Guia de teste executado sem falhas críticas  

> Marque cada caixa enquanto avança para garantir que o jogo está **100% pronto para testes finais**. Boa construção! 🏝️
