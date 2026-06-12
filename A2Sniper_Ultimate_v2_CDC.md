# A2Sniper Ultimate v2.0
## Cahier des Charges Fonctionnel et Technique

## 1. Présentation du Projet

### Nom du produit
A2Sniper Ultimate

### Type
Expert Advisor (EA) MetaTrader 5 développé en MQL5.

### Mission
Analyser automatiquement les marchés Forex et Indices Synthétiques, identifier des opportunités de trading à forte probabilité selon une logique Smart Money / Price Action avancée, puis exécuter les positions automatiquement avec gestion professionnelle du risque.

---

# 2. Objectifs Stratégiques

- Détecter les retournements institutionnels.
- Identifier les prises de liquidité.
- Exploiter les déséquilibres du marché.
- Automatiser les entrées, sorties et la gestion des positions.
- Réduire les faux signaux.
- Maintenir un drawdown contrôlé.
- Produire des statistiques exploitables pour l'amélioration continue.

---

# 3. Marchés Supportés

## Forex
- EURUSD
- GBPUSD
- USDJPY
- USDCHF
- AUDUSD
- NZDUSD
- USDCAD
- Toutes les paires compatibles MT5

## Indices Synthétiques
### Volatility
- Volatility 10
- Volatility 25
- Volatility 50
- Volatility 75
- Volatility 100

### Boom & Crash
- Boom 300
- Boom 500
- Boom 1000
- Crash 300
- Crash 500
- Crash 1000

### Autres
- Step Index
- Range Break 100

---

# 4. Concept Central

## Formule de Retournement Institutionnel

```text
Sens du marché
+ Bougie d'indécision
+ Zone isolée
+ Clôture de fausse invalidation
+ Avalement
= FORT RETOURNEMENT
```

Cette formule constitue le cœur du système.

---

# 5. Architecture Générale

```text
A2Sniper Ultimate
│
├── Market Structure Engine
├── Strategic Reversal Engine
├── Smart Money Engine
├── Liquidity Engine
├── Wick Volume Engine
├── Volume Engine
├── Volatility Engine
├── AI Scoring Engine
├── Risk Manager
├── Trade Executor
├── Trade Manager
├── Dashboard Manager
├── Statistics Manager
└── Notification Manager
```

---

# 6. Market Structure Engine

## Objectif

Déterminer le contexte général du marché.

## Détection

### Tendance haussière
- Higher High
- Higher Low

### Tendance baissière
- Lower High
- Lower Low

### Range
- Marché sans direction claire

## Multi-Timeframe

| Usage | Timeframe |
|---------|---------|
| Direction principale | H4 |
| Confirmation | H1 |
| Exécution | M15 |

---

# 7. Strategic Reversal Engine (SRE)

## Rôle

Détecter les retournements institutionnels à très forte probabilité.

## Étape 1 : Sens du Marché

Score : 20

Conditions :
- HH + HL pour achat
- LH + LL pour vente

## Étape 2 : Bougie d'Indécision

Score : 15

Bougies reconnues :
- Doji
- Long Legged Doji
- Spinning Top
- Toupie

Condition :
- Corps ≤ 25% de la taille totale

## Étape 3 : Zone Isolée

Score : 20

Zones reconnues :
- Fair Value Gap
- Imbalance
- Order Block frais
- Breaker Block
- Mitigation Block

## Étape 4 : Clôture de Fausse Invalidation

Score : 25

Conditions :
- Cassure
- Prise de liquidité
- Réintégration
- Clôture opposée

## Étape 5 : Avalement

Score : 20

Types :
- Bullish Engulfing
- Bearish Engulfing

## Score Total

100 points

### Classification

| Score | Niveau |
|---------|---------|
| 70-79 | Faible |
| 80-89 | Standard |
| 90-99 | Sniper |
| 100 | Elite |

---

# 8. Smart Money Engine

## Fonctions

### Détection

- Order Blocks
- Fair Value Gaps
- Breaker Blocks
- Mitigation Blocks
- Premium Zones
- Discount Zones

## Validation

Le module doit confirmer les signaux du Strategic Reversal Engine.

---

# 9. Liquidity Engine

## Détection

- Equal High
- Equal Low
- Double Top
- Double Bottom
- Stop Hunt

## Validation

Le signal doit démontrer une récupération de liquidité.

---

# 10. Wick + Volume Engine

## Achat

- Grande mèche basse
- Volume supérieur à la moyenne
- Bougie de rejet haussière

## Vente

- Grande mèche haute
- Volume supérieur à la moyenne
- Bougie de rejet baissière

---

# 11. Volume Engine

## Analyses

- Tick Volume
- Relative Volume
- Volume Moyen
- Volume Extrême

### Seuils

Volume institutionnel :
- > 150% de la moyenne

Volume extrême :
- > 250% de la moyenne

---

# 12. Volatility Engine

## Forex

- ATR 14
- Volatilité moyenne
- Volatilité extrême

## Indices Synthétiques

- Fréquence des spikes
- Amplitude des spikes

---

# 13. AI Scoring Engine

## Pondération

| Module | Poids |
|----------|----------|
| Strategic Reversal Engine | 40% |
| Smart Money Engine | 20% |
| Liquidity Engine | 15% |
| Market Structure | 10% |
| Wick + Volume | 10% |
| Volatility | 5% |

---

# 14. Conditions d'Entrée

L'ouverture d'une position nécessite :

- Strategic Reversal Score ≥ 90
- Confirmation Smart Money
- Confirmation Volume
- Confirmation Volatilité
- Risque autorisé
- Drawdown autorisé

---

# 15. Filtres Anti-Faux Signaux

Blocage automatique si :

- Marché en range étroit
- Spread excessif
- Volatilité insuffisante
- Volume insuffisant
- Signal SRE < 90

---

# 16. Risk Manager

## Gestion du Risque

Risque paramétrable :
- 0,5%
- 1%
- 2%
- 3%

## Drawdown Maximum

Journalier :
- 5%

Hebdomadaire :
- 10%

Mensuel :
- 20%

## Sécurité

Arrêt automatique des prises de position si les seuils sont atteints.

---

# 17. Money Management

## Calcul automatique du lot

Variables :
- Capital
- Risque
- Distance Stop Loss

## Limites

- Nombre maximum de positions
- Exposition maximale globale

---

# 18. Trade Executor

## Fonctions

- Buy Market
- Sell Market
- Placement automatique du SL
- Placement automatique du TP
- Gestion des erreurs d'exécution

---

# 19. Trade Manager

## Fonctions

### Break Even

Activation à partir de 1R.

### Trailing Stop

Modes :
- ATR
- Structure
- Swing

### Partial Close

- TP1 : 50%
- TP2 : 30%
- TP3 : 20%

---

# 20. Dashboard

## Informations

- Balance
- Equity
- Profit
- Drawdown
- Win Rate
- Profit Factor
- Nombre de trades
- Score du signal actif

---

# 21. Notifications

## Canaux

- MetaTrader 5
- Push Mobile
- Email
- Telegram
- WhatsApp via API

---

# 22. Statistiques

## KPI

- Win Rate
- Profit Factor
- Sharpe Ratio
- Recovery Factor
- Drawdown
- Expectancy
- Average R

---

# 23. Paramètres Utilisateur

```text
RiskPercent
MaxDailyDD
MaxWeeklyDD
MaxMonthlyDD
EnableForex
EnableSynthetic
EnableAutoTrading
EnableTelegram
EnableEmail
EnableTrailing
EnableBreakEven
MinSignalScore
ATRMultiplier
LotMode
FixedLot
MagicNumber
```

---

# 24. Architecture Logicielle MQL5

```text
/Experts
    A2SniperUltimate.mq5

/Include
    MarketStructureEngine.mqh
    StrategicReversalEngine.mqh
    SmartMoneyEngine.mqh
    LiquidityEngine.mqh
    WickVolumeEngine.mqh
    VolumeEngine.mqh
    VolatilityEngine.mqh
    AIScoringEngine.mqh
    RiskManager.mqh
    TradeExecutor.mqh
    TradeManager.mqh
    DashboardManager.mqh
    StatisticsManager.mqh
    NotificationManager.mqh
```

---

# 25. Classes Principales

```cpp
CMarketStructureEngine
CStrategicReversalEngine
CSmartMoneyEngine
CLiquidityEngine
CWickVolumeEngine
CVolumeEngine
CVolatilityEngine
CAIScoringEngine
CRiskManager
CTradeExecutor
CTradeManager
CDashboardManager
CStatisticsManager
CNotificationManager
```

---

# 26. Objectifs de Performance

| Indicateur | Cible |
|------------|--------|
| Win Rate | 65% - 80% |
| Profit Factor | > 2 |
| Drawdown | < 10% |
| Risk Reward Moyen | ≥ 1:3 |

---

# 27. Feuille de Route

1. Architecture de base
2. Market Structure Engine
3. Strategic Reversal Engine
4. Smart Money Engine
5. Liquidity Engine
6. Wick + Volume Engine
7. AI Scoring Engine
8. Risk Manager
9. Trade Manager
10. Dashboard
11. Backtesting
12. Optimisation
13. Validation Forex
14. Validation Indices Synthétiques

---

# 28. Livrables

- Code source MQL5 complet
- Documentation technique
- Documentation utilisateur
- Fichiers de configuration
- Rapports de backtests
- Rapports d'optimisation
