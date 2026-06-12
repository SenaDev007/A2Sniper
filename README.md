# 🚀 Shalom EA - Expert Advisor MT5

## Stratégie de Scalping Heikin-Ashi Multi-Marchés

[![Version](https://img.shields.io/badge/Version-1.00-blue.svg)](https://github.com/yehiortech/shalom-ea)
[![Platform](https://img.shields.io/badge/Platform-MetaTrader%205-green.svg)](https://www.metatrader5.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

**Développé par YEHI OR Tech Solutions**  
**Copyright © 2024 - Tous droits réservés**

---

## 📋 Description

Shalom EA est un Expert Advisor avancé conçu pour le trading automatique haute précision sur MetaTrader 5. Il utilise une stratégie sophistiquée basée sur l'analyse des bougies Heikin-Ashi, combinée à des filtres de marché intelligents et un système de gestion de risque robuste.

### 🎯 Objectifs de Performance
- **Taux de Réussite Visé** : 95-100%
- **Stratégie** : Scalping sur timeframe M1
- **Marchés Supportés** : Forex, Cryptomonnaies, Actions, Indices, Matières Premières
- **Ratio Risk/Reward** : Configurable (défaut 1:2)

---

## ✨ Caractéristiques Principales

### 🔍 Analyse Technique Avancée
- **Bougies Heikin-Ashi** : Calcul et analyse automatique des patterns
- **EMA (Moyenne Mobile Exponentielle)** : Filtre directionnel principal
- **VWAP** : Volume Weighted Average Price (optionnel)
- **ATR** : Average True Range pour la volatilité

### 🎯 Détection de Patterns
- **Patterns de Retracement** : Identification automatique des pullbacks
- **Confirmation Doji** : Validation par bougies d'indécision
- **Analyse de Volume** : Filtrage basé sur l'activité du marché
- **Filtres de Mèches** : Évitement des faux signaux

### 🛡️ Gestion de Risque Complète
- **Risk Management Adaptatif** : Calcul automatique des lots
- **Stop Loss Multiple** : Fixe, ATR, ou Support/Résistance
- **Take Profit Intelligent** : Basé sur le ratio Risk/Reward
- **Trailing Stop** : Protection des profits
- **Contrôle du Drawdown** : Limitation des pertes maximales

### 🕒 Filtres de Marché
- **Heures de Trading** : Configuration flexible des sessions
- **Filtre de Spread** : Évitement des conditions défavorables
- **Filtre de Volatilité** : Adaptation aux conditions de marché
- **Protection News** : Évitement des événements à fort impact

### 📊 Interface et Monitoring
- **Panel de Contrôle Graphique** : Surveillance en temps réel
- **Statistiques Détaillées** : Performance et métriques
- **Notifications Multi-Canal** : Alertes, Push, Email
- **Logs Complets** : Traçabilité et debugging

---

## 📁 Structure du Projet

```
Shalom EA/
├── ShalomEA.mq5                    # Fichier principal de l'Expert Advisor
├── Include/                        # Classes et modules
│   ├── HeikinAshiCalculator.mqh   # Calculateur Heikin-Ashi
│   ├── PatternDetector.mqh        # Détecteur de patterns
│   ├── RiskManager.mqh            # Gestionnaire de risque
│   └── SignalValidator.mqh        # Validateur de signaux
├── Config/                         # Configurations prédéfinies
│   ├── ShalomEA_Default.set       # Configuration par défaut
│   ├── ShalomEA_Forex.set         # Optimisée pour Forex
│   └── ShalomEA_Crypto.set        # Optimisée pour Crypto
├── Documentation/                  # Documentation complète
│   ├── Manuel_Utilisateur.md      # Guide d'utilisation
│   └── Guide_Installation.md      # Instructions d'installation
└── README.md                       # Ce fichier
```

---

## 🚀 Installation Rapide

### Prérequis
- MetaTrader 5 (version 3400+)
- Balance minimum : 1000 USD/EUR
- Autorisations de trading automatique

### Étapes d'Installation

1. **Télécharger les fichiers** du projet
2. **Copier dans MT5** :
   ```
   ShalomEA.mq5 → MQL5/Experts/
   Include/*.mqh → MQL5/Experts/Include/
   Config/*.set → MQL5/Profiles/Templates/
   ```
3. **Compiler l'EA** dans MetaEditor (F7)
4. **Attacher à un graphique M1**
5. **Configurer les paramètres** selon vos besoins

📖 **Guide détaillé** : [Documentation/Guide_Installation.md](Documentation/Guide_Installation.md)

---

## ⚙️ Configuration

### Configuration Rapide par Marché

#### 🏦 Forex (Majeurs)
```ini
EMA_Period = 21
Risk_Percent = 0.8
SL_Method = ATR
Max_Spread = 2.5
Max_Positions = 2
```

#### 🪙 Cryptomonnaies
```ini
EMA_Period = 18
Risk_Percent = 1.5
Volume_Multiplier = 1.3
Max_Spread = 5.0
Trading_Hours = 00:00-23:59
```

#### 📈 Indices
```ini
Min_Pullback_Candles = 3
RR_Ratio = 2.5
ATR_Multiplier = 2.2
Max_Daily_Loss = 4.0
```

### Chargement d'une Configuration
1. Clic droit sur l'EA → Propriétés
2. Onglet "Paramètres d'entrée"
3. Bouton "Charger" → Sélectionner le fichier .set approprié

---

## 📊 Paramètres Principaux

| Catégorie | Paramètre | Description | Défaut |
|-----------|-----------|-------------|--------|
| **Indicateurs** | `EMA_Period` | Période de la moyenne mobile | 21 |
| | `Use_VWAP` | Utiliser le VWAP | true |
| **Patterns** | `Min_Pullback_Candles` | Bougies de retracement min | 2 |
| | `Doji_Body_Ratio` | Ratio pour détecter un Doji | 0.3 |
| **Risque** | `Risk_Percent` | Risque par trade (%) | 1.0 |
| | `Max_Drawdown` | Drawdown maximum (%) | 10.0 |
| **Filtres** | `Trading_Hours` | Heures de trading | "08:00-18:00" |
| | `Max_Spread` | Spread maximum (pips) | 3.0 |

📖 **Liste complète** : [Documentation/Manuel_Utilisateur.md](Documentation/Manuel_Utilisateur.md)

---

## 📈 Performance et Backtesting

### Métriques Cibles
- **Profit Factor** : > 1.5
- **Win Rate** : > 60%
- **Maximum Drawdown** : < 15%
- **Sharpe Ratio** : > 1.0
- **Trades par jour** : 3-8

### Recommandations de Test
1. **Backtest** : Minimum 3 mois de données
2. **Forward Test** : 2 semaines en démo
3. **Démarrage progressif** : Commencer avec risk faible

---

## 🛠️ Utilisation

### Démarrage
1. **Ouvrir un graphique M1** du symbole choisi
2. **Attacher Shalom EA** depuis le Navigateur
3. **Vérifier le smiley vert** (EA actif)
4. **Surveiller les logs** pour les premiers signaux

### Surveillance
- **Quotidienne** : Vérifier les performances et logs
- **Hebdomadaire** : Analyser les statistiques détaillées
- **Mensuelle** : Optimiser les paramètres si nécessaire

### Signaux Typiques
```
TRADE EXÉCUTÉ: BUY | Lot: 0.10 | SL: 1.1234 | TP: 1.1254
Pattern ACHAT: 3 bougies rouges + Doji confirmation
Trailing Stop appliqué: 12345 | Nouveau SL: 1.1240
```

---

## 🔧 Dépannage

### Problèmes Courants

| Problème | Cause Probable | Solution |
|----------|----------------|----------|
| EA ne démarre pas | Fichiers manquants | Vérifier l'installation complète |
| Pas de signaux | Conditions non réunies | Vérifier spread, heures, marché |
| Performance faible | Paramètres inadaptés | Utiliser config prédéfinie |
| Erreurs de compilation | Fichiers .mqh absents | Copier tous les fichiers Include |

### Support
- 📧 **Email** : support@yehiortech.com
- 📖 **Documentation** : Dossier Documentation/
- 🕒 **Support initial** : 30 jours inclus

---

## ⚠️ Avertissements

**RISQUES IMPORTANTS** :
- Le trading automatique comporte des risques de perte
- Les performances passées ne garantissent pas les résultats futurs
- Toujours tester en démo avant utilisation réelle
- Ne jamais risquer plus que ce que vous pouvez perdre

**RECOMMANDATIONS** :
- Commencer avec des paramètres conservateurs
- Surveiller régulièrement les performances
- Maintenir une diversification des stratégies
- Comprendre parfaitement le fonctionnement avant usage

---

## 📄 Licence et Copyright

**Copyright © 2024 YEHI OR Tech Solutions**  
Tous droits réservés.

Ce logiciel est propriétaire et protégé par les lois sur le droit d'auteur. Toute reproduction, distribution ou modification non autorisée est strictement interdite.

### Conditions d'Utilisation
- ✅ Usage personnel et commercial autorisé
- ❌ Redistribution interdite
- ❌ Reverse engineering interdit
- ❌ Modification du code source interdite

---

## 🚀 Versions et Mises à Jour

### Version Actuelle : 1.00
- ✅ Implémentation complète de la stratégie Heikin-Ashi
- ✅ Système de gestion de risque avancé
- ✅ Interface utilisateur graphique
- ✅ Support multi-marchés
- ✅ Documentation complète

### Roadmap
- 🔄 **v1.1** : Optimisations de performance
- 🔄 **v1.2** : Nouveaux filtres de marché
- 🔄 **v1.3** : Intelligence artificielle avancée
- 🔄 **v2.0** : Support multi-timeframes

---

## 🤝 Contact et Support

**YEHI OR Tech Solutions**  
Experts en Solutions de Trading Automatisé

- 🌐 **Site Web** : https://www.yehiortech.com
- 📧 **Email** : contact@yehiortech.com
- 📞 **Support** : support@yehiortech.com
- 📱 **LinkedIn** : [YEHI OR Tech Solutions](https://linkedin.com/company/yehiortech)

---

**Shalom EA - Votre Partenaire pour un Trading Automatisé de Précision**

*Développé avec ❤️ par l'équipe YEHI OR Tech*
