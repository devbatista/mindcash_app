# 📱 Checklist de Desenvolvimento — App Financeiro (Offline-First)

## 🚀 1. Setup inicial do projeto
- [x] Criar projeto Flutter
- [x] Definir nome final do app
- [ ] Configurar package name (`com.devbatista.finance_app`)
- [ ] Rodar app base (Android/iOS)
- [ ] Configurar ícone + splash screen
- [ ] Definir tema base (Material 3)

---

## 🧱 2. Estrutura do projeto
- [ ] Criar estrutura de pastas:
lib/
core/
data/
domain/
presentation/


- [ ] Separar responsabilidades:
  - models
  - repositories
  - services
  - UI (screens/widgets)

---

## 💾 3. Banco de dados local
- [ ] Escolher banco:
  - [ ] isar
  - [ ] drift

- [ ] Configurar banco local

### Models principais:
- [ ] Account (conta)
- [ ] Category (categoria)
- [ ] Transaction (transação)
- [ ] CreditCard (cartão)
- [ ] Invoice (fatura)
- [ ] Installment (parcelas)
- [ ] Recurrence (recorrência)

---

## 🧠 4. Regras de negócio
- [ ] Entrada vs saída
- [ ] Transferência entre contas
- [ ] Cálculo de saldo por conta
- [ ] Cálculo de saldo total
- [ ] Lógica de cartão:
  - [ ] fechamento
  - [ ] vencimento
  - [ ] fatura atual
- [ ] Parcelamento automático
- [ ] Recorrência mensal

---

## 🎨 5. Design System
- [ ] Definir cores principais
- [ ] Definir tipografia
- [ ] Criar componentes:
  - [ ] botão padrão
  - [ ] input
  - [ ] card
  - [ ] lista de item
- [ ] Definir espaçamento
- [ ] Tema claro (dark opcional)

---

## 📱 6. Navegação
- [ ] Bottom Navigation

### Rotas:
- [ ] Dashboard
- [ ] Transações
- [ ] Nova transação
- [ ] Contas
- [ ] Cartões
- [ ] Mais/configurações

---

## 🏠 7. Tela: Dashboard
- [ ] Saldo total
- [ ] Entradas do mês
- [ ] Saídas do mês
- [ ] Resultado
- [ ] Gráfico por categoria
- [ ] Últimas transações

---

## 💸 8. Tela: Transações
- [ ] Listagem
- [ ] Filtros:
  - [ ] tipo (entrada/saída)
  - [ ] data
- [ ] Busca por descrição
- [ ] Swipe para deletar (opcional)

---

## ➕ 9. Tela: Nova transação
- [ ] Tipo (despesa / receita / transferência)
- [ ] Valor
- [ ] Descrição
- [ ] Categoria
- [ ] Conta
- [ ] Data
- [ ] Recorrente (toggle)
- [ ] Parcelado (toggle)

---

## 🏦 10. Tela: Contas
- [ ] Listar contas
- [ ] Criar conta
- [ ] Editar conta
- [ ] Saldo atual
- [ ] Tipo (corrente, carteira, PJ, etc)

---

## 💳 11. Tela: Cartão de crédito
- [ ] Listar cartões
- [ ] Limite
- [ ] Fechamento
- [ ] Vencimento
- [ ] Fatura atual
- [ ] Lançamentos da fatura

---

## 🔁 12. Recorrências
- [ ] Criar recorrência
- [ ] Execução automática por data
- [ ] Ativar/desativar

---

## 🎯 13. Metas (opcional)
- [ ] Criar meta
- [ ] Valor alvo
- [ ] Progresso

---

## 📊 14. Relatórios
- [ ] Gastos por categoria
- [ ] Resumo mensal
- [ ] Evolução

---

## 💾 15. Backup local
- [ ] Exportar JSON
- [ ] Importar JSON
- [ ] Exportar CSV

---

## ⚙️ 16. Configurações
- [ ] Nome do usuário
- [ ] Moeda (BRL)
- [ ] Resetar dados
- [ ] Exportar backup

---

## 🧪 17. Testes
- [ ] Criar transação
- [ ] Calcular saldo
- [ ] Recorrência
- [ ] Cartão/fatura

---

## 📦 18. Preparação para futuro (sync)
- [ ] Adicionar campos:
  - [ ] uuid
  - [ ] created_at
  - [ ] updated_at
- [ ] Separar camada de dados
- [ ] Preparar para API futura

---

## 🧹 19. Polimento
- [ ] Loading states
- [ ] Empty states
- [ ] Feedback visual
- [ ] UX fluida

---

## 🔥 Ordem recomendada
1. Banco local  
2. Models  
3. CRUD de transações  
4. Dashboard  
5. Contas  
6. Cartão  
7. Recorrência  