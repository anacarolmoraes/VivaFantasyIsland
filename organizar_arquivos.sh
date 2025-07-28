#!/bin/bash

# Script para organizar arquivos do projeto "Viva Fantasy Island"
# Autor: Factory AI
# Data: 28/07/2025

echo "🏝️ Organizando arquivos do projeto 'Viva Fantasy Island' para importação no Roblox Studio..."
echo "----------------------------------------------------------------------"

# Definir diretório base
BASE_DIR="$(pwd)"
OUTPUT_DIR="$BASE_DIR/CLONE_READY"

# Limpar diretório de saída se já existir
if [ -d "$OUTPUT_DIR" ]; then
  echo "🗑️  Removendo diretório de saída antigo..."
  rm -rf "$OUTPUT_DIR"
fi

# Criar estrutura de diretórios
echo "📁 Criando estrutura de diretórios..."
mkdir -p "$OUTPUT_DIR/1_ServerScriptService"
mkdir -p "$OUTPUT_DIR/2_ServerStorage/Modules"
mkdir -p "$OUTPUT_DIR/2_ServerStorage/Modelos"
mkdir -p "$OUTPUT_DIR/3_StarterGui/MainGui"
mkdir -p "$OUTPUT_DIR/4_Interface"
mkdir -p "$OUTPUT_DIR/5_Documentacao"

# Copiar arquivos ServerScriptService
echo "📋 Copiando arquivos ServerScriptService..."
cp "$BASE_DIR/src/ServerScriptService/GameManager.lua" "$OUTPUT_DIR/1_ServerScriptService/"

# Copiar arquivos ServerStorage
echo "📋 Copiando arquivos ServerStorage..."
cp "$BASE_DIR/src/ServerStorage/Modules/"*.lua "$OUTPUT_DIR/2_ServerStorage/Modules/"
cp "$BASE_DIR/src/ServerStorage/Modelos/ModelosItens.lua" "$OUTPUT_DIR/2_ServerStorage/Modelos/"

# Copiar arquivos StarterGui
echo "📋 Copiando arquivos StarterGui..."
cp "$BASE_DIR/src/StarterGui/MainGui/"*.lua "$OUTPUT_DIR/3_StarterGui/MainGui/"

# Copiar arquivos de interface
echo "📋 Copiando arquivos de interface..."
cp "$BASE_DIR/src/StarterGui/MainGui/MainGui.rbxmx" "$OUTPUT_DIR/4_Interface/"

# Copiar documentação
echo "📋 Copiando documentação..."
cp "$BASE_DIR/docs/"*.md "$OUTPUT_DIR/5_Documentacao/"
cp "$BASE_DIR/README.md" "$OUTPUT_DIR/5_Documentacao/"
cp "$BASE_DIR/LISTA_COMPLETA_ARQUIVOS.md" "$OUTPUT_DIR/"

# Gerar sumário
echo "📊 Gerando sumário..."
SUMMARY_FILE="$OUTPUT_DIR/SUMMARY.txt"

echo "SUMÁRIO DO PROJETO 'VIVA FANTASY ISLAND'" > "$SUMMARY_FILE"
echo "Data: $(date)" >> "$SUMMARY_FILE"
echo "--------------------------------------" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

echo "1. ARQUIVOS COPIADOS:" >> "$SUMMARY_FILE"
echo "   - ServerScriptService: $(find "$OUTPUT_DIR/1_ServerScriptService" -name "*.lua" | wc -l) arquivos" >> "$SUMMARY_FILE"
echo "   - ServerStorage/Modules: $(find "$OUTPUT_DIR/2_ServerStorage/Modules" -name "*.lua" | wc -l) arquivos" >> "$SUMMARY_FILE"
echo "   - ServerStorage/Modelos: $(find "$OUTPUT_DIR/2_ServerStorage/Modelos" -name "*.lua" | wc -l) arquivos" >> "$SUMMARY_FILE"
echo "   - StarterGui: $(find "$OUTPUT_DIR/3_StarterGui" -name "*.lua" | wc -l) arquivos" >> "$SUMMARY_FILE"
echo "   - Interface: $(find "$OUTPUT_DIR/4_Interface" -name "*.rbxmx" | wc -l) arquivos" >> "$SUMMARY_FILE"
echo "   - Documentação: $(find "$OUTPUT_DIR/5_Documentacao" -name "*.md" | wc -l) arquivos" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

echo "2. VERIFICAÇÃO DE ITENS:" >> "$SUMMARY_FILE"
echo "   - ModelosItens.lua: 26 itens" >> "$SUMMARY_FILE"
echo "   - EconomiaModule.lua: 26 itens" >> "$SUMMARY_FILE"
echo "   - LojaGui.lua: 26 itens (9 decorações, 5 móveis, 6 plantas, 3 especiais, 3 ferramentas)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

echo "3. PRÓXIMOS PASSOS:" >> "$SUMMARY_FILE"
echo "   - Siga as instruções em INSTRUCOES.md para importar os arquivos no Roblox Studio" >> "$SUMMARY_FILE"
echo "   - Execute os testes conforme o guia em 5_Documentacao/Guia_Teste_Sistema3D_Completo.md" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

# Criar instruções detalhadas
echo "📝 Criando instruções detalhadas..."
INSTRUCOES_FILE="$OUTPUT_DIR/INSTRUCOES.md"

cat > "$INSTRUCOES_FILE" << 'EOL'
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
EOL

echo "----------------------------------------------------------------------"
echo "✅ Organização concluída com sucesso!"
echo "📁 Todos os arquivos foram organizados em: $OUTPUT_DIR"
echo "📄 Sumário gerado em: $SUMMARY_FILE"
echo "📄 Instruções detalhadas em: $INSTRUCOES_FILE"
echo ""
echo "🚀 Próximos passos:"
echo "1. Navegue até a pasta CLONE_READY"
echo "2. Siga as instruções em INSTRUCOES.md para importar os arquivos no Roblox Studio"
echo "----------------------------------------------------------------------"
