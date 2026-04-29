# Checklist de Desenvolvimento - MindCash

App financeiro pessoal em Flutter, offline-first, simples de usar e preparado para sincronizacao futura.

## Principios do projeto

- [ ] Banco local como fonte principal dos dados
- [ ] Funcionar bem sem internet
- [ ] UX simples, rapida e focada no uso diario
- [ ] Arquitetura clara, sem overengineering
- [ ] Poucas dependencias e com proposito claro
- [ ] Dados preparados para sincronizacao futura

---

## 1. Setup inicial

- [x] Criar projeto Flutter
- [x] Definir nome final do app: MindCash
- [x] Configurar package name: `com.devbatista.mindcash`
- [ ] Rodar app base no Android
- [ ] Rodar app base no iOS
- [x] Remover template padrao do contador
- [x] Configurar titulo do app
- [x] Definir tema base com Material 3
- [ ] Configurar icone do app
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
- [ ] Adicionar dependencias do Drift
- [ ] Configurar banco local
- [ ] Criar arquivo principal do banco
- [ ] Configurar geracao de codigo
- [ ] Criar migracao inicial
- [ ] Criar helper para abrir banco no app
- [ ] Criar estrategia simples para testes com banco em memoria

### Campos padrao para sync futura

- [ ] `uuid`
- [ ] `created_at`
- [ ] `updated_at`
- [ ] `deleted_at` opcional para soft delete
- [ ] `sync_status` opcional

---

## 4. Models e tabelas do MVP

### Account

- [ ] Criar tabela/model de conta
- [ ] Nome
- [ ] Tipo: corrente, carteira, poupanca, investimento, PJ, outro
- [ ] Saldo inicial
- [ ] Ativa/inativa
- [ ] Campos de sync

### Category

- [ ] Criar tabela/model de categoria
- [ ] Nome
- [ ] Tipo: receita ou despesa
- [ ] Cor/icone simples
- [ ] Categoria padrao do sistema
- [ ] Ativa/inativa
- [ ] Campos de sync

### Transaction

- [ ] Criar tabela/model de transacao
- [ ] Tipo: receita, despesa ou transferencia
- [ ] Valor
- [ ] Descricao
- [ ] Data
- [ ] Conta de origem
- [ ] Conta de destino para transferencia
- [ ] Categoria
- [ ] Observacao opcional
- [ ] Campos de sync

---

## 5. Repositories e regras do MVP

- [ ] Criar `AccountRepository`
- [ ] Criar `CategoryRepository`
- [ ] Criar `TransactionRepository`
- [ ] Criar categorias iniciais
- [ ] Criar conta inicial opcional
- [ ] Criar transacao
- [ ] Editar transacao
- [ ] Deletar transacao
- [ ] Listar transacoes por data
- [ ] Filtrar por tipo
- [ ] Buscar por descricao
- [ ] Calcular saldo por conta
- [ ] Calcular saldo total
- [ ] Calcular entradas do mes
- [ ] Calcular saidas do mes
- [ ] Calcular resultado do mes
- [ ] Implementar transferencia entre contas

---

## 6. Design system simples

- [ ] Definir paleta principal
- [ ] Definir cores semanticas:
  - [ ] Receita
  - [ ] Despesa
  - [ ] Transferencia
  - [ ] Alerta/erro
- [ ] Definir tipografia base
- [ ] Definir espacamentos padrao
- [x] Criar tema claro
- [ ] Criar componentes reutilizaveis:
  - [ ] Botao primario
  - [ ] Campo de texto
  - [ ] Campo monetario
  - [ ] Seletor de data
  - [ ] Item de lista de transacao
  - [ ] Empty state
  - [ ] Loading state

---

## 7. Navegacao

- [x] Criar bottom navigation
- [ ] Criar rotas principais:
  - [ ] Dashboard
  - [ ] Transacoes
  - [ ] Nova transacao
  - [ ] Contas
  - [ ] Cartoes
  - [ ] Mais/configuracoes
- [ ] Definir comportamento do botao de nova transacao

---

## 8. Tela: Dashboard

- [ ] Exibir saldo total
- [ ] Exibir entradas do mes
- [ ] Exibir saidas do mes
- [ ] Exibir resultado do mes
- [ ] Exibir cards de contas
- [ ] Exibir ultimas transacoes
- [ ] Exibir empty state quando nao houver dados
- [ ] Exibir feedback visual para valores positivos/negativos
- [ ] Adicionar grafico simples por categoria depois do MVP inicial

---

## 9. Tela: Transacoes

- [ ] Listar transacoes recentes
- [ ] Agrupar por data
- [ ] Filtro por tipo
- [ ] Filtro por periodo
- [ ] Busca por descricao
- [ ] Abrir detalhes da transacao
- [ ] Editar transacao
- [ ] Deletar transacao com confirmacao
- [ ] Swipe para deletar opcional

---

## 10. Tela: Nova transacao

- [ ] Selecionar tipo: despesa, receita ou transferencia
- [ ] Informar valor
- [ ] Informar descricao
- [ ] Selecionar categoria
- [ ] Selecionar conta
- [ ] Selecionar conta de destino em transferencia
- [ ] Selecionar data
- [ ] Adicionar observacao opcional
- [ ] Validar campos obrigatorios
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
- [ ] Validar se conta com transacoes pode ser removida

---

## 12. Cartao de credito

- [ ] Criar tabela/model de cartao
- [ ] Criar tabela/model de fatura
- [ ] Listar cartoes
- [ ] Criar cartao
- [ ] Editar cartao
- [ ] Definir limite
- [ ] Definir dia de fechamento
- [ ] Definir dia de vencimento
- [ ] Calcular fatura atual
- [ ] Listar lancamentos da fatura
- [ ] Registrar pagamento de fatura

---

## 13. Parcelamento

- [ ] Criar tabela/model de parcelas
- [ ] Criar compra parcelada
- [ ] Gerar parcelas automaticamente
- [ ] Associar parcelas ao cartao ou conta
- [ ] Exibir parcela atual
- [ ] Permitir cancelar parcelas futuras

---

## 14. Recorrencias

- [ ] Criar tabela/model de recorrencia
- [ ] Criar recorrencia mensal
- [ ] Executar recorrencias pendentes ao abrir app
- [ ] Evitar duplicidade de lancamentos
- [ ] Ativar/desativar recorrencia
- [ ] Editar recorrencia

---

## 15. Relatorios

- [ ] Gastos por categoria
- [ ] Resumo mensal
- [ ] Evolucao do saldo
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

## 17. Configuracoes

- [ ] Nome do usuario
- [ ] Moeda padrao: BRL
- [ ] Gerenciar categorias
- [ ] Gerenciar dados locais
- [ ] Exportar backup
- [ ] Resetar dados com confirmacao
- [ ] Sobre o app

---

## 18. Testes

- [ ] Testar criacao de conta
- [ ] Testar criacao de categoria
- [ ] Testar criacao de transacao
- [ ] Testar saldo por conta
- [ ] Testar saldo total
- [ ] Testar transferencia entre contas
- [ ] Testar resumo mensal
- [ ] Testar regras de fatura
- [ ] Testar parcelamento
- [ ] Testar recorrencia

---

## 19. Polimento

- [ ] Melhorar loading states
- [ ] Melhorar empty states
- [ ] Revisar mensagens de erro
- [ ] Revisar feedback visual
- [ ] Revisar fluxo com uma mao
- [ ] Revisar performance com muitos registros
- [ ] Revisar acessibilidade basica

---

## Ordem recomendada de desenvolvimento

1. Setup inicial do app
2. Estrutura de pastas
3. Drift e banco local
4. Models/tabelas do MVP: contas, categorias e transacoes
5. Repositories e regras de saldo
6. Tema base e componentes minimos
7. Navegacao principal
8. CRUD de transacoes
9. Dashboard
10. Contas
11. Cartao de credito
12. Parcelamento
13. Recorrencias
14. Relatorios
15. Backup local
16. Polimento
