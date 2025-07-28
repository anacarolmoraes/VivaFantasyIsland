# 🏝️ INSTRUÇÕES DE IMPORTAÇÃO - VIVA FANTASY ISLAND

Este guia explica como importar corretamente os arquivos do projeto no Roblox Studio.

## 📋 PASSO A PASSO

### 1️⃣ PREPARAÇÃO

1. Abra o Roblox Studio
2. Crie um novo lugar ou abra um existente
3. Certifique-se de que o Explorer está visível (View > Explorer)

### 2️⃣ IMPORTAR INTERFACE (.rbxmx)

1. No menu, selecione **File > Import...**
2. Navegue até a pasta **4_Interface**
3. Selecione o arquivo **MainGui.rbxmx**
4. Clique em **Open**
5. Confirme que a interface foi importada em **StarterGui > MainGui**

### 3️⃣ CRIAR SCRIPTS (.lua)

#### ServerScriptService:
1. Clique com o botão direito em **ServerScriptService** no Explorer
2. Selecione **Insert Object > Script**
3. Renomeie para **GameManager**
4. Abra o script e substitua o conteúdo pelo arquivo **1_ServerScriptService/GameManager.lua**

#### ServerStorage:
1. Crie uma pasta chamada **Modules** dentro de **ServerStorage**
2. Crie uma pasta chamada **Modelos** dentro de **ServerStorage**
3. Para cada arquivo em **2_ServerStorage/Modules**:
   - Crie um ModuleScript dentro de **ServerStorage/Modules**
   - Renomeie para o nome do arquivo (sem .lua)
   - Substitua o conteúdo pelo arquivo correspondente
4. Para ModelosItens:
   - Crie um ModuleScript dentro de **ServerStorage/Modelos**
   - Renomeie para **ModelosItens**
   - Substitua o conteúdo pelo arquivo **2_ServerStorage/Modelos/ModelosItens.lua**

#### StarterGui:
1. Certifique-se de que **MainGui** existe dentro de **StarterGui** (da importação da interface)
2. Para cada arquivo em **3_StarterGui/MainGui**:
   - Crie um LocalScript dentro de **StarterGui/MainGui**
   - Renomeie para o nome do arquivo (sem .lua)
   - Substitua o conteúdo pelo arquivo correspondente
   - **IMPORTANTE**: O arquivo **init.lua** deve ser um LocalScript chamado **init**

### 4️⃣ CONFIGURAR REMOTEEVENTS

1. Clique com o botão direito em **ReplicatedStorage** no Explorer
2. Selecione **Insert Object > Folder**
3. Renomeie para **RemoteEvents**
4. Dentro da pasta **RemoteEvents**, crie os seguintes RemoteEvents:
   - ComprarItem
   - AtualizarDreamCoins
   - AtualizarInventario
   - AtualizarMissoes
   - ColocarItem
   - RemoverItem

### 5️⃣ TESTAR

1. Clique em **Play** (modo Solo) para testar o jogo
2. Verifique se a interface aparece corretamente
3. Teste a loja, inventário e sistema de construção
4. Verifique se todos os 26 itens estão disponíveis nas 5 categorias

## ⚠️ SOLUÇÃO DE PROBLEMAS

Se encontrar erros:
1. Verifique o Output para mensagens de erro
2. Confirme que todos os scripts foram colocados nos locais corretos
3. Verifique se os RemoteEvents foram criados corretamente
4. Consulte a documentação em **5_Documentacao** para mais detalhes

## 🔍 VERIFICAÇÃO FINAL

- [ ] Interface visível e responsiva
- [ ] Loja mostra 26 itens em 5 categorias
- [ ] Sistema de compra funcional
- [ ] Inventário mostra itens comprados
- [ ] Sistema de construção permite colocar itens
- [ ] Sem erros no console de saída

Boa sorte e divirta-se com o Viva Fantasy Island! 🏝️
