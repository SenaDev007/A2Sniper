# Manuel d'Utilisation - A2Sniper Trading

## Expert Advisor de Scalping Heikin-Ashi Multi-Marchés

**Version:** 1.00  
**Copyright:** 2024, YEHI OR Tech Solutions  
**Plateforme:** MetaTrader 5 uniquement

---

## Table des Matières

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Paramètres](#paramètres)
5. [Utilisation](#utilisation)
6. [Optimisation](#optimisation)
7. [Dépannage](#dépannage)
8. [Support](#support)

---

## Introduction

A2Sniper Trading est un Expert Advisor avancé conçu pour le trading automatique sur MetaTrader 5. Il utilise une stratégie de scalping basée sur les bougies Heikin-Ashi, les moyennes mobiles exponentielles (EMA) et la détection de patterns de retracement spécifiques.

### Caractéristiques Principales

- ✅ **Stratégie Heikin-Ashi** : Analyse avancée des patterns de bougies
- ✅ **Multi-Marchés** : Compatible Forex, Crypto, Actions, Indices
- ✅ **Gestion de Risque** : Système complet de protection du capital
- ✅ **Scalping M1** : Optimisé pour le timeframe 1 minute
- ✅ **Filtres Avancés** : Heures, spread, volatilité
- ✅ **Interface Graphique** : Panel de contrôle intégré

### Objectif de Performance

- **Taux de Réussite Visé** : 95-100%
- **Ratio Risk/Reward** : Configurable (défaut 1:2)
- **Drawdown Maximum** : Contrôlé et limité

---

## Installation

### Prérequis

- MetaTrader 5 (version récente)
- Compte de trading avec autorisations EA
- Balance minimum recommandée : 1000 USD/EUR
- Connexion internet stable

### Étapes d'Installation

1. **Copier les fichiers** :
   ```
   A2SniperTrading.mq5 → MQL5/Experts/
   Include/*.mqh → MQL5/Experts/Include/
   Config/*.set → MQL5/Profiles/Templates/
   ```

2. **Compiler l'EA** :
   - Ouvrir MetaEditor
   - Ouvrir A2SniperTrading.mq5
   - Appuyer sur F7 pour compiler
   - Vérifier l'absence d'erreurs

3. **Autoriser le trading automatique** :
   - Dans MT5 : Outils → Options → Expert Advisors
   - Cocher "Autoriser le trading automatique"
   - Cocher "Autoriser l'importation de DLL"

4. **Attacher à un graphique** :
   - Ouvrir un graphique M1
   - Glisser-déposer A2SniperTrading depuis le Navigateur
   - Configurer les paramètres
   - Cliquer OK

---

## Configuration

### Configuration Rapide

Pour un démarrage rapide, utilisez les fichiers de configuration prédéfinis :

- **A2SniperTrading_Default.set** : Configuration équilibrée
- **A2SniperTrading_Forex.set** : Optimisée pour le Forex
- **A2SniperTrading_Crypto.set** : Optimisée pour les Cryptos

### Chargement d'une Configuration

1. Clic droit sur l'EA dans le graphique
2. Propriétés de l'Expert Advisor
3. Onglet "Paramètres d'entrée"
4. Bouton "Charger" → Sélectionner le fichier .set
5. OK pour appliquer

---

## Paramètres

### Indicateurs

| Paramètre | Description | Défaut | Plage |
|-----------|-------------|--------|-------|
| `EMA_Period` | Période de la moyenne mobile exponentielle | 21 | 5-100 |
| `Use_VWAP` | Utiliser le VWAP comme filtre | true | true/false |
| `Volume_Period` | Période pour le calcul du volume moyen | 10 | 5-50 |
| `ATR_Period` | Période de l'Average True Range | 14 | 5-50 |

### Détection de Patterns

| Paramètre | Description | Défaut | Plage |
|-----------|-------------|--------|-------|
| `Min_Pullback_Candles` | Minimum de bougies de retracement | 2 | 1-10 |
| `Doji_Body_Ratio` | Ratio corps/total pour détecter un Doji | 0.3 | 0.1-0.5 |
| `Volume_Multiplier` | Multiplicateur de volume minimum | 1.2 | 1.0-3.0 |

### Risk Management

| Paramètre | Description | Défaut | Plage |
|-----------|-------------|--------|-------|
| `Risk_Percent` | Risque par trade (% du capital) | 1.0 | 0.1-5.0 |
| `SL_Method` | Méthode de Stop Loss (1=Fixe, 2=ATR) | 1 | 1-2 |
| `SL_Pips` | Stop Loss en pips (si méthode fixe) | 10.0 | 5.0-50.0 |
| `ATR_Multiplier` | Multiplicateur ATR pour SL | 2.0 | 1.0-5.0 |
| `RR_Ratio` | Ratio Risk/Reward | 2.0 | 1.0-5.0 |
| `Use_Trailing` | Utiliser le Trailing Stop | true | true/false |

### Filtres

| Paramètre | Description | Défaut | Format |
|-----------|-------------|--------|--------|
| `Trading_Hours` | Heures de trading autorisées | "08:00-18:00" | "HH:MM-HH:MM" |
| `Monday_Trading` | Autoriser le trading le lundi | true | true/false |
| `Friday_Trading` | Autoriser le trading le vendredi | false | true/false |
| `Max_Spread` | Spread maximum autorisé (pips) | 3.0 | 0.5-10.0 |

### Limites

| Paramètre | Description | Défaut | Plage |
|-----------|-------------|--------|-------|
| `Max_Positions` | Nombre maximum de positions simultanées | 3 | 1-10 |
| `Max_Daily_Loss` | Perte quotidienne maximum (%) | 5.0 | 1.0-20.0 |
| `Max_Drawdown` | Drawdown maximum autorisé (%) | 10.0 | 5.0-30.0 |

---

## Utilisation

### Démarrage

1. **Vérification des prérequis** :
   - Balance suffisante (min. 1000)
   - Autorisations de trading activées
   - Connexion stable au serveur

2. **Sélection du symbole** :
   - Choisir un symbole liquide (EURUSD, BTCUSD, etc.)
   - Vérifier que le spread est acceptable
   - S'assurer que le marché est ouvert

3. **Configuration du timeframe** :
   - **Recommandé** : M1 (1 minute)
   - Possible : M5 (mais moins optimal)

4. **Lancement de l'EA** :
   - Attacher l'EA au graphique
   - Vérifier que le smiley est vert
   - Observer les premiers signaux

### Surveillance

#### Indicateurs Visuels

- **Smiley Vert** : EA actif et fonctionnel
- **Smiley Rouge** : EA arrêté ou erreur
- **Panel UI** : Informations en temps réel (si activé)

#### Logs à Surveiller

```
=== INITIALISATION A2SNIPER TRADING ===
Symbole: EURUSD
Timeframe: M1
Risque par trade: 1.0%
Méthode SL: ATR
=== A2SNIPER TRADING INITIALISÉ AVEC SUCCÈS ===
```

#### Signaux de Trading

```
TRADE EXÉCUTÉ: BUY | Lot: 0.10 | SL: 1.1234 | TP: 1.1254
```

### Arrêt de l'EA

1. **Arrêt Normal** :
   - Clic droit sur l'EA → Supprimer
   - Ou désactiver le trading automatique

2. **Arrêt d'Urgence** :
   - Fermer toutes les positions manuellement
   - Désactiver immédiatement l'EA

---

## Optimisation

### Par Type de Marché

#### Forex (Majeurs)
- `Risk_Percent`: 0.8-1.2%
- `SL_Method`: ATR (2)
- `ATR_Multiplier`: 1.8-2.2
- `Max_Spread`: 2.0-3.0 pips

#### Cryptomonnaies
- `Risk_Percent`: 1.0-2.0%
- `Volume_Multiplier`: 1.3-1.5
- `Max_Spread`: 3.0-8.0 pips
- `Trading_Hours`: 24/7

#### Indices
- `EMA_Period`: 15-25
- `Min_Pullback_Candles`: 2-4
- `RR_Ratio`: 1.5-2.5

### Optimisation des Paramètres

1. **Backtesting** :
   - Utiliser au minimum 3 mois de données
   - Tester sur différentes conditions de marché
   - Analyser le Profit Factor et le Drawdown

2. **Forward Testing** :
   - Commencer avec des lots minimums
   - Surveiller pendant 1-2 semaines
   - Ajuster progressivement

3. **Métriques Clés** :
   - **Profit Factor** : > 1.5
   - **Win Rate** : > 60%
   - **Max Drawdown** : < 15%
   - **Sharpe Ratio** : > 1.0

---

## Dépannage

### Problèmes Courants

#### L'EA ne s'initialise pas

**Symptômes** : Message d'erreur à l'initialisation

**Solutions** :
- Vérifier que tous les fichiers .mqh sont présents
- Recompiler l'EA
- Vérifier les autorisations de trading
- Contrôler la balance minimum

#### Aucun signal généré

**Symptômes** : EA actif mais pas de trades

**Solutions** :
- Vérifier les heures de trading
- Contrôler le spread (doit être < Max_Spread)
- S'assurer que le marché est ouvert
- Vérifier les filtres activés

#### Trades fermés immédiatement

**Symptômes** : Positions ouvertes puis fermées rapidement

**Solutions** :
- Vérifier la distance minimum des stops
- Contrôler la liquidité du symbole
- Ajuster les paramètres de SL/TP

#### Performance décevante

**Symptômes** : Résultats inférieurs aux attentes

**Solutions** :
- Réoptimiser les paramètres
- Changer de symbole ou timeframe
- Vérifier les conditions de marché
- Utiliser une configuration prédéfinie

### Messages d'Erreur

| Code | Message | Solution |
|------|---------|----------|
| 4051 | Invalid function parameter | Vérifier les paramètres d'entrée |
| 4108 | Invalid ticket | Position déjà fermée |
| 4109 | Trading not allowed | Activer le trading automatique |
| 4110 | Longs not allowed | Vérifier les restrictions du symbole |

---

## Support

### Informations de Contact

- **Site Web** : https://www.yehiortech.com
- **Email Support** : support@yehiortech.com
- **Documentation** : Dossier Documentation/

### Support Inclus

- **30 jours** de support initial gratuit
- **Mises à jour** de bugs et améliorations mineures
- **Documentation** complète et exemples

### Support Étendu

- **Formation personnalisée** : Configuration et optimisation
- **Développements sur mesure** : Nouvelles fonctionnalités
- **Support prioritaire** : Réponse sous 24h

---

## Avertissements et Disclaimers

⚠️ **AVERTISSEMENT IMPORTANT** ⚠️

Le trading automatique comporte des risques significatifs. Les performances passées ne garantissent pas les résultats futurs. Il est recommandé de :

- Tester en mode démo avant utilisation réelle
- Ne jamais risquer plus que ce que vous pouvez vous permettre de perdre
- Surveiller régulièrement les performances
- Comprendre parfaitement le fonctionnement avant utilisation

**YEHI OR Tech Solutions** ne peut être tenu responsable des pertes financières résultant de l'utilisation de ce logiciel.

---

*Copyright 2024 YEHI OR Tech Solutions. Tous droits réservés.*
