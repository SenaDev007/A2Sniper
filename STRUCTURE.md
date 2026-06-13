# Structure du Projet A2Sniper Trading

## Vue d'Ensemble

Le projet A2Sniper Trading est organisé de manière modulaire pour faciliter la maintenance, les tests et les extensions futures. Voici la structure complète du projet :

```
A2Sniper Trading/
├── 📄 A2SniperTrading.mq5                     # Expert Advisor principal
├── 📄 README.md                        # Documentation principale
├── 📄 LICENSE.txt                      # Licence propriétaire
├── 📄 VERSION.md                       # Historique des versions
├── 📄 STRUCTURE.md                     # Ce fichier
│
├── 📁 Include/                         # Classes et modules MQL5
│   ├── 📄 HeikinAshiCalculator.mqh    # Calculateur Heikin-Ashi
│   ├── 📄 PatternDetector.mqh         # Détecteur de patterns
│   ├── 📄 RiskManager.mqh             # Gestionnaire de risque
│   ├── 📄 SignalValidator.mqh         # Validateur de signaux
│   └── 📄 OrderBookEngine.mqh         # Moteur d'analyse du carnet d'ordres
│
├── 📁 Config/                          # Configurations prédéfinies
│   ├── 📄 A2SniperTrading_Default.set        # Configuration par défaut
│   ├── 📄 A2SniperTrading_Forex.set          # Optimisée pour Forex
│   └── 📄 A2SniperTrading_Crypto.set         # Optimisée pour Crypto
│
├── 📁 Documentation/                   # Documentation complète
│   ├── 📄 Manuel_Utilisateur.md       # Guide d'utilisation
│   └── 📄 Guide_Installation.md       # Instructions d'installation
│
├── 📁 Scripts/                         # Utilitaires et tests
│   └── 📄 A2SniperTrading_QuickTest.mq5      # Script de test rapide
│
└── 📁 Indicators/                      # Indicateurs complémentaires
    └── 📄 A2SniperTrading_HeikinAshi.mq5     # Indicateur Heikin-Ashi visuel
```

---

## Description Détaillée des Fichiers

### 🎯 Fichier Principal

#### `A2SniperTrading.mq5`
- **Rôle** : Expert Advisor principal
- **Taille** : ~12.7 KB
- **Fonctions** :
  - Point d'entrée principal de l'EA
  - Gestion des événements MT5 (OnInit, OnTick, OnDeinit)
  - Orchestration des différents modules
  - Interface utilisateur et paramètres d'entrée
  - Logique de trading principale

### 📚 Classes et Modules (`Include/`)

#### `HeikinAshiCalculator.mqh`
- **Rôle** : Calcul et analyse des bougies Heikin-Ashi
- **Taille** : ~15.2 KB
- **Classes** :
  - `CHeikinAshiCalculator` : Classe principale
  - `SHeikinAshiData` : Structure de données
- **Fonctionnalités** :
  - Calcul des valeurs HA (Open, High, Low, Close)
  - Détection des patterns (Doji, tendances)
  - Analyse des mèches et corps de bougies
  - Comptage de bougies consécutives

#### `PatternDetector.mqh`
- **Rôle** : Détection des patterns de trading
- **Taille** : ~18.5 KB
- **Classes** :
  - `CPatternDetector` : Classe principale
  - `SPatternInfo` : Structure d'information de pattern
- **Fonctionnalités** :
  - Détection des patterns de retracement
  - Validation des conditions d'entrée
  - Calcul du score de confiance
  - Apprentissage et statistiques

#### `RiskManager.mqh`
- **Rôle** : Gestion complète du risque
- **Taille** : ~16.8 KB
- **Classes** :
  - `CRiskManager` : Classe principale
  - `SRiskStatistics` : Structure de statistiques
- **Fonctionnalités** :
  - Calcul automatique des lots
  - Contrôle du drawdown
  - Limites quotidiennes
  - Suspension automatique du trading

#### `SignalValidator.mqh`
- **Rôle** : Validation des signaux de trading
- **Taille** : ~14.3 KB
- **Classes** :
  - `CSignalValidator` : Classe principale
  - `STradingHours` : Structure des heures
- **Fonctionnalités** :
  - Filtres d'heures de trading
  - Validation du spread
  - Contrôle de la volatilité
  - Filtres d'événements news

### ⚙️ Configurations (`Config/`)

#### `A2SniperTrading_Default.set`
- **Usage** : Configuration équilibrée pour tous marchés
- **Paramètres** :
  - Risk_Percent = 1.0%
  - EMA_Period = 21
  - Max_Spread = 3.0 pips
  - Max_Positions = 3

#### `A2SniperTrading_Forex.set`
- **Usage** : Optimisée pour les paires de devises majeures
- **Paramètres** :
  - Risk_Percent = 0.8%
  - SL_Method = ATR
  - Max_Spread = 2.5 pips
  - Trading_Hours = "08:00-17:00"

#### `A2SniperTrading_Crypto.set`
- **Usage** : Adaptée aux cryptomonnaies
- **Paramètres** :
  - Risk_Percent = 1.5%
  - Trading_Hours = "00:00-23:59"
  - Max_Spread = 5.0 pips
  - Volume_Multiplier = 1.3

### 📖 Documentation (`Documentation/`)

#### `Manuel_Utilisateur.md`
- **Contenu** : Guide complet d'utilisation
- **Sections** :
  - Installation et configuration
  - Paramètres détaillés
  - Utilisation quotidienne
  - Optimisation par marché
  - Dépannage

#### `Guide_Installation.md`
- **Contenu** : Instructions d'installation pas à pas
- **Sections** :
  - Prérequis système
  - Étapes d'installation
  - Configuration MT5
  - Tests de validation
  - Résolution de problèmes

### 🛠️ Utilitaires (`Scripts/`)

#### `A2SniperTrading_QuickTest.mq5`
- **Rôle** : Script de test et validation
- **Taille** : ~12.1 KB
- **Fonctionnalités** :
  - Test de tous les modules
  - Validation de l'installation
  - Vérification des conditions de marché
  - Rapport de compatibilité

### 📊 Indicateurs (`Indicators/`)

#### `A2SniperTrading_HeikinAshi.mq5`
- **Rôle** : Indicateur visuel Heikin-Ashi
- **Taille** : ~15.7 KB
- **Fonctionnalités** :
  - Affichage des bougies Heikin-Ashi
  - Signaux visuels d'achat/vente
  - Panel d'informations en temps réel
  - Statistiques de performance

---

## Architecture Logicielle

### 🏗️ Design Patterns Utilisés

#### Pattern Strategy
- Différentes méthodes de Stop Loss (Fixe, ATR, S/R)
- Stratégies de validation de signaux
- Méthodes de calcul de lots

#### Pattern Observer
- Notifications multi-canal (Alertes, Push, Email)
- Mise à jour des statistiques en temps réel
- Synchronisation des modules

#### Pattern Factory
- Création d'objets selon les paramètres
- Initialisation des handles d'indicateurs
- Configuration des filtres

### 🔄 Flux de Données

```
MarketData → HeikinAshi → PatternDetector → SignalValidator → RiskManager → Trade Execution
     ↓              ↓             ↓              ↓              ↓
  Indicators    Calculations   Patterns      Filters       Position
                                                           Management
```

### 🧩 Dépendances entre Modules

```
A2SniperTrading.mq5
├── HeikinAshiCalculator.mqh
├── PatternDetector.mqh
│   └── HeikinAshiCalculator.mqh
├── RiskManager.mqh
│   └── Trade.mqh (MT5)
└── SignalValidator.mqh
```

---

## Installation dans MT5

### 📂 Mapping des Dossiers

```
Projet A2Sniper Trading/              →  MetaTrader 5/
├── A2SniperTrading.mq5              →  MQL5/Experts/
├── Include/*.mqh             →  MQL5/Experts/Include/
├── Config/*.set              →  MQL5/Profiles/Templates/
├── Scripts/*.mq5             →  MQL5/Scripts/
├── Indicators/*.mq5          →  MQL5/Indicators/
└── Documentation/            →  MQL5/Files/A2SniperTrading/Documentation/
```

### 🔧 Compilation

1. **Ordre de Compilation** :
   ```
   1. Include/*.mqh (automatique)
   2. A2SniperTrading.mq5
   3. Scripts/A2SniperTrading_QuickTest.mq5
   4. Indicators/A2SniperTrading_HeikinAshi.mq5
   ```

2. **Fichiers Générés** :
   ```
   A2SniperTrading.ex5
   A2SniperTrading_QuickTest.ex5
   A2SniperTrading_HeikinAshi.ex5
   ```

---

## Maintenance et Évolution

### 🔄 Versioning

- **Version Format** : MAJOR.MINOR.PATCH
- **Branches** :
  - `main` : Version stable
  - `develop` : Développement
  - `feature/*` : Nouvelles fonctionnalités
  - `hotfix/*` : Corrections urgentes

### 📊 Métriques de Code

| Fichier | Lignes | Classes | Fonctions | Complexité |
|---------|--------|---------|-----------|------------|
| A2SniperTrading.mq5 | ~400 | 0 | 15 | Moyenne |
| HeikinAshiCalculator.mqh | ~500 | 1 | 20 | Faible |
| PatternDetector.mqh | ~600 | 1 | 25 | Élevée |
| RiskManager.mqh | ~550 | 1 | 22 | Moyenne |
| SignalValidator.mqh | ~450 | 1 | 18 | Faible |

### 🧪 Tests

- **Tests Unitaires** : Chaque classe individuellement
- **Tests d'Intégration** : Interaction entre modules
- **Tests de Performance** : Optimisation et latence
- **Tests de Régression** : Non-régression des fonctionnalités

---

## Sécurité et Conformité

### 🔒 Sécurité

- **Validation des Entrées** : Tous les paramètres utilisateur
- **Gestion d'Erreurs** : Try-catch et récupération
- **Logs Sécurisés** : Pas d'informations sensibles
- **Accès Contrôlé** : Permissions MT5 requises

### 📋 Conformité

- **MQL5 Standards** : Respect des conventions
- **MT5 Guidelines** : Compatibilité assurée
- **Performance** : Optimisation mémoire et CPU
- **Documentation** : Code entièrement commenté

---

## Support et Contact

### 📞 Informations de Support

- **Email** : support@yehiortech.com
- **Site Web** : https://www.yehiortech.com
- **Documentation** : Dossier Documentation/
- **Licence** : LICENSE.txt

### 🔄 Mises à Jour

- **Automatiques** : Corrections de bugs
- **Manuelles** : Nouvelles fonctionnalités
- **Notifications** : Via email et site web
- **Backward Compatibility** : Maintenue autant que possible

---

*Structure créée le 2024-07-20*  
*Copyright © 2024 YEHI OR Tech Solutions*
