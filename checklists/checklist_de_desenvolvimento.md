# Checklist de Desenvolvimento - MindCash

App financeiro pessoal em Flutter, offline-first, simples de usar e preparado para sincronização futura.

## Princípios do projeto

- [ ] Banco local como fonte principal dos dados
- [ ] Funcionar bem sem internet
- [ ] UX simples, rápida e focada no uso diário
- [ ] Arquitetura clara, sem overengineering
- [ ] Poucas dependências e com propósito claro
- [ ] Dados preparados para sincronização futura

---

## 1. Setup inicial

- [x] Criar projeto Flutter
- [x] Definir nome final do app: MindCash
- [x] Configurar package name: `com.devbatista.mindcash`
- [ ] Rodar app base no Android
- [ ] Rodar app base no iOS
- [x] Remover template padrão do contador
- [x] Configurar título do app
- [x] Definir tema base com Material 3
- [ ] Configurar ícone do app
- [ ] Configurar splash screen

---

## 2. Estrutura do projeto

- [x] Criar estrutura base:
  - [x] `lib/core`
  - [x] `lib/data`
  - [x] `lib/domain`
  - [x] `lib/presentation`

- [x] Organizar responsabilidades:
  - [x] `core/theme`
  - [x] `core/utils`
  - [x] `data/database`
  - [x] `data/repositories`
  - [x] `domain/models`
  - [x] `domain/services`
  - [x] `presentation/screens`
  - [x] `presentation/widgets`

---

## 3. Banco local

- [x] Escolher banco local: Drift
- [x] Adicionar dependências do Drift
- [x] Configurar banco local
- [x] Criar arquivo principal do banco
- [x] Configurar geração de código
- [x] Criar migração inicial
- [x] Criar helper para abrir banco no app
- [x] Criar estratégia simples para testes com banco em memória

### Campos padrão para sync futura

- [x] `uuid`
- [x] `created_at`
- [x] `updated_at`
- [x] `deleted_at` opcional para soft delete
- [x] `sync_status` opcional

---

## 4. Models e tabelas do MVP

### Account

- [x] Criar tabela/model de conta
- [x] Nome
- [x] Tipo: corrente, carteira, poupança, investimento, PJ, outro
- [x] Saldo inicial
- [x] Ativa/inativa
- [x] Campos de sync

### Category

- [x] Criar tabela/model de categoria
- [x] Nome
- [x] Tipo: receita ou despesa
- [x] Cor/ícone simples
- [x] Categoria padrão do sistema
- [x] Ativa/inativa
- [x] Campos de sync

### Transaction

- [x] Criar tabela/model de transação
- [x] Tipo: receita, despesa ou transferência
- [x] Valor
- [x] Descrição
- [x] Data
- [x] Conta de origem
- [x] Conta de destino para transferência
- [x] Categoria
- [x] Observação opcional
- [x] Campos de sync

---

## 5. Repositories e regras do MVP

- [x] Criar `AccountRepository`
- [x] Criar `CategoryRepository`
- [ ] Criar `TransactionRepository`
- [ ] Criar categorias iniciais
- [ ] Criar conta inicial opcional
- [ ] Criar transação
- [ ] Editar transação
- [ ] Deletar transação
- [ ] Listar transações por data
- [ ] Filtrar por tipo
- [ ] Buscar por descrição
- [ ] Calcular saldo por conta
- [ ] Calcular saldo total
- [ ] Calcular entradas do mês
- [ ] Calcular saídas do mês
- [ ] Calcular resultado do mês
- [ ] Implementar transferência entre contas

---

## 6. Design system simples

- [ ] Definir paleta principal
- [ ] Definir cores semânticas:
  - [ ] Receita
  - [ ] Despesa
  - [ ] Transferência
  - [ ] Alerta/erro
- [ ] Definir tipografia base
- [ ] Definir espaçamentos padrão
- [x] Criar tema claro
- [ ] Criar componentes reutilizáveis:
  - [ ] Botão primário
  - [ ] Campo de texto
  - [ ] Campo monetário
  - [ ] Seletor de data
  - [ ] Item de lista de transação
  - [ ] Empty state
  - [ ] Loading state

---

## 7. Navegação

- [x] Criar bottom navigation
- [ ] Criar rotas principais:
  - [ ] Dashboard
  - [ ] Transações
  - [ ] Nova transação
  - [ ] Contas
  - [ ] Cartões
  - [ ] Mais/configurações
- [ ] Definir comportamento do botão de nova transação

---

## 8. Tela: Dashboard

- [x] Exibir saldo total
- [x] Exibir entradas do mês
- [x] Exibir saídas do mês
- [x] Exibir resultado do mês
- [ ] Exibir cards de contas
- [ ] Exibir últimas transações
- [ ] Exibir empty state quando não houver dados
- [x] Exibir feedback visual para valores positivos/negativos
- [x] Adicionar gráfico simples por categoria depois do MVP inicial

---

## 9. Tela: Transações

- [ ] Listar transações recentes
- [ ] Agrupar por data
- [ ] Filtro por tipo
- [ ] Filtro por período
- [ ] Busca por descrição
- [ ] Abrir detalhes da transação
- [ ] Editar transação
- [ ] Deletar transação com confirmação
- [ ] Swipe para deletar opcional

---

## 10. Tela: Nova transação

- [ ] Selecionar tipo: despesa, receita ou transferência
- [ ] Informar valor
- [ ] Informar descrição
- [ ] Selecionar categoria
- [ ] Selecionar conta
- [ ] Selecionar conta de destino em transferência
- [ ] Selecionar data
- [ ] Adicionar observação opcional
- [ ] Validar campos obrigatórios
- [ ] Salvar e voltar para lista/dashboard
- [ ] Exibir feedback de sucesso/erro

---

## 11. Tela: Contas

- [ ] Listar contas
- [ ] Exibir saldo atual por conta
- [ ] Criar conta
- [ ] Editar conta
- [ ] Inativar conta
- [ ] Definir tipo da conta
- [ ] Validar se conta com transações pode ser removida

---

## 12. Cartão de crédito

- [ ] Criar tabela/model de cartão
- [ ] Criar tabela/model de fatura
- [ ] Listar cartões
- [ ] Criar cartão
- [ ] Editar cartão
- [ ] Definir limite
- [ ] Definir dia de fechamento
- [ ] Definir dia de vencimento
- [ ] Calcular fatura atual
- [ ] Listar lançamentos da fatura
- [ ] Registrar pagamento de fatura

---

## 13. Parcelamento

- [ ] Criar tabela/model de parcelas
- [ ] Criar compra parcelada
- [ ] Gerar parcelas automaticamente
- [ ] Associar parcelas ao cartão ou conta
- [ ] Exibir parcela atual
- [ ] Permitir cancelar parcelas futuras

---

## 14. Recorrências

- [ ] Criar tabela/model de recorrência
- [ ] Criar recorrência mensal
- [ ] Executar recorrências pendentes ao abrir app
- [ ] Evitar duplicidade de lançamentos
- [ ] Ativar/desativar recorrência
- [ ] Editar recorrência

---

## 15. Relatórios

- [ ] Gastos por categoria
- [ ] Resumo mensal
- [ ] Evolução do saldo
- [ ] Comparativo entre meses
- [ ] Filtro por conta
- [ ] Filtro por categoria

---

## 16. Backup local

- [ ] Exportar JSON
- [ ] Importar JSON
- [ ] Exportar CSV
- [ ] Validar arquivo antes de importar
- [ ] Criar backup antes de importar dados

---

## 17. Configurações

- [ ] Nome do usuário
- [ ] Moeda padrão: BRL
- [ ] Gerenciar categorias
- [ ] Gerenciar dados locais
- [ ] Exportar backup
- [ ] Resetar dados com confirmação
- [ ] Sobre o app

---

## 18. Testes

- [ ] Testar criação de conta
- [ ] Testar criação de categoria
- [ ] Testar criação de transação
- [ ] Testar saldo por conta
- [ ] Testar saldo total
- [ ] Testar transferência entre contas
- [ ] Testar resumo mensal
- [ ] Testar regras de fatura
- [ ] Testar parcelamento
- [ ] Testar recorrência

---

## 19. Polimento

- [ ] Melhorar loading states
- [ ] Melhorar empty states
- [ ] Revisar mensagens de erro
- [ ] Revisar feedback visual
- [ ] Revisar fluxo com uma mão
- [ ] Revisar performance com muitos registros
- [ ] Revisar acessibilidade básica

---

## Ordem recomendada de desenvolvimento

1. Setup inicial do app
2. Estrutura de pastas
3. Drift e banco local
4. Models/tabelas do MVP: contas, categorias e transações
5. Repositories e regras de saldo
6. Tema base e componentes mínimos
7. Navegação principal
8. CRUD de transações
9. Dashboard
10. Contas
11. Cartão de crédito
12. Parcelamento
13. Recorrências
14. Relatórios
15. Backup local
16. Polimento
