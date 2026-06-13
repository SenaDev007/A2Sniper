# A2Sniper Trading - Historique des Versions

## Version 4.1 (2026-06-13) - Order Book Engine

### 🔥 Mise à jour majeure : Carnet d'Ordres (Order Book)

Cette version ajoute l'analyse du carnet d'ordres en temps réel pour une validation institutionnelle des signaux sniper.

### ✨ Nouvelles Fonctionnalités

#### Order Book Engine (`OrderBookEngine.mqh`)
- ✅ **Analyse du carnet d'ordres** via `MarketBookGet()` de MT5
- ✅ **Détection des murs d'ordres** (bid/ask walls) - identification des niveaux de support/résistance institutionnels
- ✅ **Imbalance bid/ask** - calcul de la pression acheteur/vendeur en temps réel
- ✅ **Validation sniper** - le carnet confirme ou rejette les signaux de précision
- ✅ **Ajustement dynamique du SL** - placement du stop loss derrière les murs d'ordres détectés
- ✅ **Détection d'absorption** - identification des murs d'absorption institutionnels (volume massif)
- ✅ **Mode strict/optionnel** - RequireBookConfirmation pour exiger la validation du carnet
- ✅ **Graceful degradation** - fonctionne même si le broker ne fournit pas le carnet

#### Intégration dans le Pipeline Sniper
- ✅ Phase 7 ajoutée : **ORDER BOOK VALIDATION** entre Session Filter et Risk Check
- ✅ Score de confiance du carnet (0-100) basé sur liquidité + imbalance + murs
- ✅ Ajustement automatique du SL si un mur d'ordres est détecté
- ✅ Rejet automatique en mode strict si imbalance extreme contre le signal
- ✅ Paramètres configurables : `EnableOrderBook`, `RequireBookConfirmation`, `UseBookSLAdjust`

#### Constantes Order Book (CommonTypes.mqh)
- `OB_BOOK_WALL_MULTIPLIER = 3.0` - Seuil de détection des murs
- `OB_BOOK_IMBALANCE_THRESH = 1.5` - Seuil d'imbalance significatif
- `OB_BOOK_EXTREME_IMBALANCE = 2.5` - Seuil d'imbalance extreme
- `OB_BOOK_MIN_LIQUIDITY = 0.3` - Ratio liquidité minimum
- `OB_BOOK_CONFIDENCE_BOOST = 5.0` - Bonus score si OrderBook confirme

### 🔧 Modifications

- Renommage complet : Shalom EA → A2Sniper Trading
  - Tous les fichiers, références, logs, alerts, et documentation mis à jour
  - `ShalomEA.mq5` → `A2SniperTrading.mq5`
  - Préfixe dashboard `ShalomEA_` → `A2SniperTrading_`
  - Préfixe indicateurs `ShalomHA_` → `A2SniperHA_`

### ⚠️ Notes de compatibilité

- L'OrderBook Engine nécessite un broker ECN/STP avec profondeur de marché
- Si le carnet n'est pas disponible, le bot fonctionne normalement (mode dégradé)
- `RequireBookConfirmation = false` par défaut (recommandé pour la compatibilité)

---

## Version 1.00 (2024-07-20) - Version Initiale

### 🎉 Première Release

Cette version initiale implémente toutes les fonctionnalités principales définies dans le cahier des charges.

### ✨ Nouvelles Fonctionnalités

#### Core Trading Engine
- ✅ **Calculateur Heikin-Ashi** complet avec toutes les métriques
- ✅ **Détecteur de Patterns** avancé pour les signaux de retracement
- ✅ **Gestionnaire de Risque** avec contrôle multi-niveaux
- ✅ **Validateur de Signaux** avec filtres intelligents

#### Stratégie de Trading
- ✅ **Scalping M1** optimisé pour haute fréquence
- ✅ **Patterns de Retracement** : Détection automatique des pullbacks
- ✅ **Confirmation Doji** : Validation par bougies d'indécision
- ✅ **Filtres EMA** : Direction de tendance principale
- ✅ **Analyse de Volume** : Validation par l'activité du marché

#### Gestion de Risque
- ✅ **Calcul de Lot Automatique** basé sur le pourcentage de risque
- ✅ **Stop Loss Multiple** : Fixe, ATR, Support/Résistance
- ✅ **Take Profit Intelligent** avec ratio Risk/Reward configurable
- ✅ **Trailing Stop** pour protection des profits
- ✅ **Contrôle du Drawdown** avec suspension automatique
- ✅ **Limites Quotidiennes** de perte et nombre de positions

#### Filtres de Marché
- ✅ **Heures de Trading** configurables par session
- ✅ **Filtre de Spread** pour éviter les conditions défavorables
- ✅ **Filtre de Jours** (Lundi/Vendredi optionnels)
- ✅ **Validation des Conditions** de marché en temps réel

#### Interface et Monitoring
- ✅ **Logs Détaillés** pour traçabilité complète
- ✅ **Statistiques en Temps Réel** de performance
- ✅ **Notifications Multi-Canal** (Alertes, Push, Email)
- ✅ **Gestion d'Erreurs** robuste avec récupération automatique

#### Outils Complémentaires
- ✅ **Configurations Prédéfinies** pour différents marchés
- ✅ **Script de Test Rapide** pour validation d'installation
- ✅ **Indicateur Heikin-Ashi Visuel** avec signaux
- ✅ **Documentation Complète** utilisateur et technique

### 🔧 Paramètres Configurables

#### Indicateurs
- `EMA_Period` : Période de la moyenne mobile (défaut: 21)
- `Use_VWAP` : Utilisation du VWAP (défaut: true)
- `Volume_Period` : Période de calcul du volume moyen (défaut: 10)
- `ATR_Period` : Période de l'ATR (défaut: 14)

#### Détection de Patterns
- `Min_Pullback_Candles` : Minimum de bougies de retracement (défaut: 2)
- `Doji_Body_Ratio` : Ratio corps/total pour Doji (défaut: 0.3)
- `Volume_Multiplier` : Multiplicateur de volume minimum (défaut: 1.2)

#### Risk Management
- `Risk_Percent` : Risque par trade en % (défaut: 1.0)
- `SL_Method` : Méthode de Stop Loss (défaut: ATR)
- `SL_Pips` : Stop Loss en pips si fixe (défaut: 10.0)
- `ATR_Multiplier` : Multiplicateur ATR (défaut: 2.0)
- `RR_Ratio` : Ratio Risk/Reward (défaut: 2.0)
- `Use_Trailing` : Utilisation du Trailing Stop (défaut: true)

#### Filtres
- `Trading_Hours` : Heures de trading (défaut: "08:00-18:00")
- `Monday_Trading` : Trading le lundi (défaut: true)
- `Friday_Trading` : Trading le vendredi (défaut: false)
- `Max_Spread` : Spread maximum en pips (défaut: 3.0)

#### Limites
- `Max_Positions` : Positions simultanées max (défaut: 3)
- `Max_Daily_Loss` : Perte quotidienne max en % (défaut: 5.0)
- `Max_Drawdown` : Drawdown max en % (défaut: 10.0)

### 📊 Métriques de Performance Visées

- **Taux de Réussite** : 95-100%
- **Profit Factor** : > 1.5
- **Win Rate** : > 60%
- **Maximum Drawdown** : < 15%
- **Sharpe Ratio** : > 1.0

### 🏗️ Architecture Technique

#### Structure Modulaire
```
A2SniperTrading.mq5                    # Expert Advisor principal
├── HeikinAshiCalculator.mqh    # Calculs Heikin-Ashi
├── PatternDetector.mqh         # Détection de patterns
├── RiskManager.mqh             # Gestion de risque
└── SignalValidator.mqh         # Validation de signaux
```

#### Classes Principales
- **CHeikinAshiCalculator** : Calcul et analyse des bougies Heikin-Ashi
- **CPatternDetector** : Détection des patterns de retracement
- **CRiskManager** : Gestion complète du risque et du capital
- **CSignalValidator** : Validation des signaux avec filtres

### 🧪 Tests et Validation

#### Tests Unitaires
- ✅ Validation de chaque classe individuellement
- ✅ Tests des calculs Heikin-Ashi
- ✅ Vérification de la logique de détection
- ✅ Tests de gestion d'erreurs

#### Tests d'Intégration
- ✅ Tests sur compte démo multi-symboles
- ✅ Validation des performances en temps réel
- ✅ Tests de stabilité 24/7
- ✅ Vérification de la compatibilité MT5

### 📚 Documentation

#### Guides Utilisateur
- ✅ **Manuel d'Utilisation** complet avec exemples
- ✅ **Guide d'Installation** pas à pas
- ✅ **Configurations Prédéfinies** pour différents marchés
- ✅ **FAQ** et résolution de problèmes

#### Documentation Technique
- ✅ **Code Source** entièrement commenté
- ✅ **Architecture** et design patterns
- ✅ **API Reference** des classes
- ✅ **Exemples d'Utilisation** avancée

### 🔒 Sécurité et Stabilité

#### Gestion d'Erreurs
- ✅ **Validation des Paramètres** à l'initialisation
- ✅ **Gestion des Déconnexions** serveur
- ✅ **Recovery Automatique** après erreurs
- ✅ **Logs d'Erreurs** détaillés

#### Protection du Capital
- ✅ **Limites de Drawdown** strictes
- ✅ **Contrôle des Positions** multiples
- ✅ **Validation des Ordres** avant exécution
- ✅ **Suspension Automatique** en cas de problème

### 🌍 Compatibilité

#### Plateformes Supportées
- ✅ **MetaTrader 5** (version 3400+)
- ✅ **Windows 10/11**
- ✅ **Windows Server 2016+**

#### Marchés Supportés
- ✅ **Forex** (toutes paires majeures)
- ✅ **Cryptomonnaies** (BTC, ETH, etc.)
- ✅ **Actions** (CFD)
- ✅ **Indices** (DAX, S&P500, etc.)
- ✅ **Matières Premières** (Or, Pétrole, etc.)

#### Types de Comptes
- ✅ **ECN** (Electronic Communication Network)
- ✅ **STP** (Straight Through Processing)
- ✅ **Market Maker**

### 📞 Support

#### Support Inclus
- ✅ **30 jours** de support initial gratuit
- ✅ **Mises à jour** de bugs et sécurité
- ✅ **Documentation** complète
- ✅ **Configurations** prédéfinies

#### Canaux de Support
- 📧 **Email** : support@yehiortech.com
- 🌐 **Site Web** : https://www.yehiortech.com
- 📖 **Documentation** : Dossier Documentation/

---

## Roadmap Futur

### Version 1.1 (Prévue Q4 2024)
- 🔄 **Optimisations de Performance** pour réduction de latence
- 🔄 **Nouveaux Filtres** de volatilité avancés
- 🔄 **Interface Graphique** améliorée
- 🔄 **Backtesting Intégré** avec rapports détaillés

### Version 1.2 (Prévue Q1 2025)
- 🔄 **Intelligence Artificielle** pour apprentissage adaptatif
- 🔄 **Multi-Timeframes** pour confirmation croisée
- 🔄 **Calendrier Économique** intégré
- 🔄 **Optimisation Génétique** des paramètres

### Version 2.0 (Prévue Q2 2025)
- 🔄 **Portfolio Management** multi-symboles
- 🔄 **Machine Learning** avancé
- 🔄 **API REST** pour intégration externe
- 🔄 **Mobile App** pour monitoring

---

## Notes de Release

### Exigences Système
- **MetaTrader 5** version 3400 ou supérieure
- **Windows 10/11** ou Windows Server 2016+
- **RAM** : 4 GB minimum, 8 GB recommandé
- **Processeur** : Intel i5 ou équivalent AMD
- **Connexion Internet** : Stable, minimum 1 Mbps
- **Espace Disque** : 100 MB pour l'installation

### Installation
1. Télécharger tous les fichiers du package
2. Copier dans les dossiers MT5 appropriés
3. Compiler dans MetaEditor
4. Configurer les paramètres selon le marché
5. Tester en mode démo avant utilisation réelle

### Première Utilisation
1. Commencer avec les configurations prédéfinies
2. Utiliser un risque faible (0.5-1%)
3. Surveiller les performances pendant 1 semaine
4. Ajuster les paramètres selon les résultats
5. Augmenter progressivement le risque

---

**Développé avec ❤️ par YEHI OR Tech Solutions**  
*Copyright © 2024 - Tous droits réservés*
