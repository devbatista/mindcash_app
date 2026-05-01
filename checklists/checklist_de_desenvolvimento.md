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
- [x] Criar `TransactionRepository`
- [x] Criar categorias iniciais
- [x] Criar conta inicial opcional
- [x] Criar transação
- [x] Editar transação
- [x] Deletar transação
- [x] Listar transações por data
- [x] Filtrar por tipo
- [x] Buscar por descrição
- [x] Calcular saldo por conta
- [x] Calcular saldo total
- [x] Calcular entradas do mês
- [x] Calcular saídas do mês
- [x] Calcular resultado do mês
- [x] Implementar transferência entre contas

---

## 6. Design system simples

- [x] Definir paleta principal
- [x] Definir cores semânticas:
  - [x] Receita
  - [x] Despesa
  - [x] Transferência
  - [x] Alerta/erro
- [x] Definir tipografia base
- [x] Definir espaçamentos padrão
- [x] Criar tema claro
- [x] Criar componentes reutilizáveis:
  - [x] Botão primário
  - [x] Campo de texto
  - [x] Campo monetário
  - [x] Seletor de data
  - [x] Item de lista de transação
  - [x] Empty state
  - [x] Loading state

---

## 7. Navegação

- [x] Criar bottom navigation
- [x] Criar rotas principais:
  - [x] Dashboard
  - [x] Transações
  - [x] Nova transação
  - [x] Contas
  - [x] Cartões
  - [x] Mais/configurações
- [x] Definir comportamento do botão de nova transação

---

## 8. Tela: Dashboard

- [x] Exibir saldo total
- [x] Exibir entradas do mês
- [x] Exibir saídas do mês
- [x] Exibir resultado do mês
- [x] Exibir cards de contas
- [x] Exibir últimas transações
- [x] Exibir empty state quando não houver dados
- [x] Exibir feedback visual para valores positivos/negativos
- [x] Adicionar gráfico simples por categoria depois do MVP inicial

---

## 9. Tela: Transações

- [x] Listar transações recentes
- [x] Agrupar por data
- [x] Filtro por tipo
- [x] Filtro por período
- [x] Busca por descrição
- [x] Abrir detalhes da transação
- [x] Editar transação
- [x] Deletar transação com confirmação
- [x] Swipe para deletar opcional

---

## 10. Tela: Nova transação

- [x] Selecionar tipo: despesa, receita ou transferência
- [x] Informar valor
- [x] Informar descrição
- [x] Selecionar categoria
- [x] Selecionar conta
- [x] Selecionar conta de destino em transferência
- [x] Selecionar data
- [x] Adicionar observação opcional
- [x] Validar campos obrigatórios
- [x] Salvar e voltar para lista/dashboard
- [x] Exibir feedback de sucesso/erro

---

## 11. Tela: Contas

- [x] Listar contas
- [x] Exibir saldo atual por conta
- [x] Criar conta
- [x] Editar conta
- [x] Inativar conta
- [x] Definir tipo da conta
- [x] Validar se conta com transações pode ser removida

---

## 12. Cartão de crédito

- [x] Criar tabela/model de cartão
- [x] Criar tabela/model de fatura
- [x] Listar cartões
- [x] Criar cartão
- [x] Editar cartão
- [x] Definir limite
- [x] Definir dia de fechamento
- [x] Definir dia de vencimento
- [x] Calcular fatura atual
- [x] Listar lançamentos da fatura
- [x] Registrar pagamento de fatura

---

## 13. Parcelamento

- [x] Criar tabela/model de parcelas
- [x] Criar compra parcelada
- [x] Gerar parcelas automaticamente
- [x] Associar parcelas ao cartão ou conta
- [x] Exibir parcela atual
- [x] Permitir cancelar parcelas futuras

---

## 14. Recorrências

- [x] Criar tabela/model de recorrência
- [x] Criar recorrência mensal
- [x] Executar recorrências pendentes ao abrir app
- [x] Evitar duplicidade de lançamentos
- [x] Ativar/desativar recorrência
- [x] Editar recorrência

---

## 15. Relatórios

- [x] Gastos por categoria
- [x] Resumo mensal
- [x] Evolução do saldo
- [x] Comparativo entre meses
- [x] Filtro por conta
- [x] Filtro por categoria

---

## 16. Backup local

- [x] Exportar JSON
- [x] Importar JSON
- [x] Exportar CSV
- [x] Validar arquivo antes de importar
- [x] Criar backup antes de importar dados

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
