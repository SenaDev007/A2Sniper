# A2Sniper Ultimate v3.0
# Cahier des Charges Fonctionnel, Technique et Architecture

## Vision
A2Sniper Ultimate est un Expert Advisor institutionnel MT5 destiné au Forex, Indices Synthétiques, Métaux, Indices Boursiers et Crypto-actifs. Il combine SMC, ICT, Price Action, gestion quantitative du risque et apprentissage adaptatif.

---

# 1. Périmètre

## Marchés supportés
- Forex
- Indices Synthétiques Deriv
- Or (XAUUSD)
- Argent (XAGUSD)
- Indices boursiers
- Crypto-monnaies

## Timeframes
- D1
- H4
- H1
- M15
- M5

---

# 2. Formule Centrale

```text
Sens du marché
+ Bougie d'indécision
+ Zone isolée
+ Clôture de fausse invalidation
+ Avalement
= FORT RETOURNEMENT
```

Le Strategic Reversal Engine constitue le cœur décisionnel du système.

---

# 3. Architecture Générale

```text
A2Sniper Ultimate
│
├── Market Structure Engine
├── Strategic Reversal Engine
├── Smart Money Engine
├── ICT Engine
├── Liquidity Engine
├── Fair Value Gap Engine
├── Order Block Engine
├── Session Engine
├── News Filter Engine
├── Volume Engine
├── Volatility Engine
├── AI Scoring Engine
├── Machine Learning Engine
├── Risk Manager
├── Trade Executor
├── Trade Manager
├── Statistics Database
├── Intelligent Journal
├── Dashboard Prop Firm
└── Backtest Intelligence Engine
```

---

# 4. Architecture SMC / ICT

## Market Structure

Détection :
- HH
- HL
- LH
- LL
- BOS
- CHOCH
- MSS

### Conditions

BOS :
Cassure valide de structure.

CHOCH :
Changement de caractère.

MSS :
Début probable d'un retournement.

---

## Smart Money Concepts

### Order Blocks
### Fair Value Gaps
### Liquidity Sweeps
### Premium / Discount
### Mitigation Blocks
### Breaker Blocks

---

## ICT Concepts

### Judas Swing
### Kill Zones
### Liquidity Raid
### Optimal Trade Entry (OTE)
### New York Reversal
### London Manipulation

---

# 5. Strategic Reversal Engine

## Étape 1
Sens du marché

## Étape 2
Bougie d'indécision

## Étape 3
Zone isolée

## Étape 4
Fausse invalidation

## Étape 5
Avalement

### Score

| Critère | Points |
|----------|----------|
| Sens marché | 20 |
| Indécision | 15 |
| Zone isolée | 20 |
| Fausse invalidation | 25 |
| Avalement | 20 |

Total = 100

Signal Sniper ≥ 90

---

# 6. Spécifications Complètes des Order Blocks

## Bullish Order Block

Dernière bougie baissière avant impulsion haussière.

Conditions :
- BOS haussier
- Impulsion forte
- Volume supérieur à la moyenne
- Zone non mitigée

## Bearish Order Block

Dernière bougie haussière avant impulsion baissière.

Conditions :
- BOS baissier
- Impulsion forte
- Volume supérieur à la moyenne
- Zone non mitigée

## Scoring

Fresh OB = 100%
Mitigated OB = 50%
Consumed OB = 0%

---

# 7. Spécifications Complètes des Fair Value Gaps

Détection sur 3 bougies.

```text
Bougie A
Bougie B
Bougie C
```

Condition haussière :

Low(C) > High(A)

Condition baissière :

High(C) < Low(A)

## Classification

- Micro FVG
- Standard FVG
- Institutional FVG

## Priorité

Institutional FVG > Standard FVG > Micro FVG

---

# 8. Détection Avancée des Liquidités

## BSL

Buy Side Liquidity

Zones :
- Equal High
- Double Top
- Sommets majeurs

## SSL

Sell Side Liquidity

Zones :
- Equal Low
- Double Bottom
- Creux majeurs

## Liquidity Sweep

Conditions :
- Cassure
- Prise de liquidité
- Réintégration
- Rejet

---

# 9. Gestion des Sessions

## Session Asiatique

00h00 - 09h00 UTC

## Londres

07h00 - 16h00 UTC

## New York

13h00 - 22h00 UTC

## Priorité

1. Londres
2. Londres-New York Overlap
3. New York

---

# 10. Filtre Économique Forex

## Sources

Calendrier économique.

## Événements critiques

- NFP
- CPI
- FOMC
- Taux d'intérêt
- PIB
- Discours banques centrales

## Règles

Blocage :
- 30 min avant
- 30 min après

Paramétrable.

---

# 11. Gestion du Risque

## Risque par Trade

- 0,25%
- 0,50%
- 1%
- 2%

## Drawdown

Journalier : 5%
Hebdomadaire : 10%
Mensuel : 20%

## Exposition

Maximum :
- Par actif
- Par devise
- Globale

## Corrélation

Blocage des positions fortement corrélées.

---

# 12. Money Management

## Calcul Lot

Variables :
- Solde
- Risque
- Distance SL
- Valeur du point

## Gestion Adaptative

Réduction automatique du risque après série de pertes.

---

# 13. Machine Learning Adaptatif

## Objectif

Évaluer les performances réelles des signaux.

## Variables analysées

- Session
- Actif
- Structure
- Type d'OB
- Type de FVG
- Score global
- RR obtenu

## Fonctionnement

Le moteur ajuste :
- pondérations
- scores
- priorités

selon l'historique.

---

# 14. AI Scoring Engine

## Pondération

| Module | Poids |
|----------|----------|
| Strategic Reversal | 30% |
| SMC/ICT | 25% |
| Liquidité | 15% |
| Order Blocks | 10% |
| FVG | 10% |
| Volume | 5% |
| Volatilité | 5% |

---

# 15. Dashboard Style Prop Firm

## Affichage

- Balance
- Equity
- Drawdown
- Win Rate
- Profit Factor
- Trades ouverts
- Trades gagnants
- Trades perdants
- Score actif
- Session active
- Risque utilisé

---

# 16. Journal de Trading Intelligent

Enregistrement automatique :

- Capture du signal
- Capture écran
- Actif
- Heure
- Session
- Setup détecté
- Score
- Résultat

---

# 17. Base de Données des Signaux

Stockage :

- Signal ID
- Actif
- Setup
- Score
- Heure
- Session
- Résultat
- Profit
- Drawdown

Objectif :
Analyse statistique avancée.

---

# 18. Backtest Intelligence Engine

## Fonctions

- Backtests automatiques
- Comparaison de stratégies
- Classement des setups
- Notation automatique

### Note

A+
A
B
C
D

Critères :
- Win Rate
- Profit Factor
- Drawdown
- Stabilité

---

# 19. Diagramme UML - Cas d'Utilisation

```text
Trader
│
├── Configurer EA
├── Lancer Trading
├── Consulter Dashboard
├── Consulter Journal
├── Consulter Statistiques
└── Lancer Backtest
```

---

# 20. Diagramme UML - Classes

```text
A2SniperUltimate
│
├── CMarketStructureEngine
├── CStrategicReversalEngine
├── CSmartMoneyEngine
├── CICTEngine
├── CLiquidityEngine
├── COrderBlockEngine
├── CFVGEngine
├── CRiskManager
├── CMachineLearningEngine
├── CTradeExecutor
├── CTradeManager
├── CStatisticsDatabase
└── CDashboardManager
```

---

# 21. Diagramme UML - Séquence

```text
Tick
│
├── Analyse Structure
├── Analyse Liquidité
├── Analyse SMC/ICT
├── Analyse FVG
├── Analyse OB
├── Calcul Score
├── Validation Risque
├── Exécution
└── Journalisation
```

---

# 22. Structure Technique MQL5

```text
/Experts
  A2SniperUltimate.mq5

/Include
  MarketStructureEngine.mqh
  StrategicReversalEngine.mqh
  SmartMoneyEngine.mqh
  ICTEngine.mqh
  LiquidityEngine.mqh
  OrderBlockEngine.mqh
  FVGEngine.mqh
  SessionEngine.mqh
  NewsFilterEngine.mqh
  VolumeEngine.mqh
  VolatilityEngine.mqh
  MachineLearningEngine.mqh
  AIScoringEngine.mqh
  RiskManager.mqh
  TradeExecutor.mqh
  TradeManager.mqh
  StatisticsDatabase.mqh
  DashboardManager.mqh
```

---

# 23. Objectifs de Performance

Win Rate : 65% à 80%
Profit Factor : > 2
Drawdown : < 10%
RR Moyen : ≥ 1:3

---

# 24. Livrables

- Code source complet
- Documentation technique
- Documentation utilisateur
- Rapport de backtests
- Rapport d'optimisation
- Base de connaissances du système
- Guide d'exploitation
