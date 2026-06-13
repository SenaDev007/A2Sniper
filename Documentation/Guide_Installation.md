# Guide d'Installation - A2Sniper Trading

## Installation Complète pour MetaTrader 5

---

## Prérequis Système

### Logiciels Requis
- **MetaTrader 5** (version 3400 ou supérieure)
- **Windows 10/11** ou **Windows Server 2016+**
- **Connexion Internet** stable (minimum 1 Mbps)

### Compte de Trading
- **Balance minimum** : 1000 USD/EUR recommandée
- **Type de compte** : ECN, STP ou Market Maker
- **Autorisations** : Trading automatique activé
- **Spread** : Préférablement < 3 pips sur les majeurs

---

## Étape 1 : Préparation de MetaTrader 5

### 1.1 Vérification de la Version
1. Ouvrir MetaTrader 5
2. Menu **Aide** → **À propos**
3. Vérifier que la version est ≥ 3400
4. Si nécessaire, mettre à jour via **Aide** → **Mise à jour**

### 1.2 Configuration des Autorisations
1. Menu **Outils** → **Options**
2. Onglet **Expert Advisors**
3. Cocher les options suivantes :
   - ✅ **Autoriser le trading automatique**
   - ✅ **Autoriser l'importation de DLL**
   - ✅ **Confirmer les appels de fonctions DLL**
   - ✅ **Autoriser l'importation de fonctions externes**

### 1.3 Localisation du Dossier de Données
1. Menu **Fichier** → **Ouvrir le dossier de données**
2. Noter le chemin (exemple : `C:\Users\[User]\AppData\Roaming\MetaQuotes\Terminal\[ID]\`)

---

## Étape 2 : Installation des Fichiers

### 2.1 Structure des Dossiers
Créer la structure suivante dans le dossier de données MT5 :
```
MQL5/
├── Experts/
│   ├── A2SniperTrading.mq5
│   └── Include/
│       ├── HeikinAshiCalculator.mqh
│       ├── PatternDetector.mqh
│       ├── RiskManager.mqh
│       └── SignalValidator.mqh
├── Profiles/
│   └── Templates/
│       ├── A2SniperTrading_Default.set
│       ├── A2SniperTrading_Forex.set
│       └── A2SniperTrading_Crypto.set
└── Files/
    └── A2SniperTrading/
        └── Logs/
```

### 2.2 Copie des Fichiers

#### Fichier Principal
```bash
Copier : A2SniperTrading.mq5
Vers   : MQL5\Experts\A2SniperTrading.mq5
```

#### Fichiers d'Include
```bash
Copier : Include\*.mqh
Vers   : MQL5\Experts\Include\
```

#### Fichiers de Configuration
```bash
Copier : Config\*.set
Vers   : MQL5\Profiles\Templates\
```

#### Documentation
```bash
Copier : Documentation\*
Vers   : MQL5\Files\A2SniperTrading\Documentation\
```

---

## Étape 3 : Compilation

### 3.1 Ouverture de MetaEditor
1. Dans MT5 : **F4** ou **Outils** → **MetaQuotes Language Editor**
2. Ou directement depuis le menu Démarrer

### 3.2 Compilation de l'EA
1. **Fichier** → **Ouvrir** → Naviguer vers `MQL5\Experts\A2SniperTrading.mq5`
2. Appuyer sur **F7** ou **Compiler**
3. Vérifier l'onglet **Journal** :
   - ✅ **0 erreur(s), 0 avertissement(s)**
   - ❌ Si erreurs : vérifier les fichiers .mqh

### 3.3 Résolution des Erreurs de Compilation

#### Erreur : "Cannot open include file"
```
Solution :
1. Vérifier que tous les fichiers .mqh sont dans MQL5\Experts\Include\
2. Respecter la casse des noms de fichiers
3. Recompiler après correction
```

#### Erreur : "Undeclared identifier"
```
Solution :
1. Vérifier l'ordre des #include dans A2SniperTrading.mq5
2. S'assurer que tous les fichiers .mqh sont présents
3. Vérifier la syntaxe des déclarations
```

---

## Étape 4 : Configuration Initiale

### 4.1 Redémarrage de MetaTrader 5
1. Fermer complètement MT5
2. Redémarrer l'application
3. Vérifier que A2SniperTrading apparaît dans le **Navigateur** → **Expert Advisors**

### 4.2 Test de Base
1. Ouvrir un graphique **EURUSD M1**
2. Glisser-déposer **A2SniperTrading** sur le graphique
3. Dans la fenêtre de paramètres :
   - Onglet **Commun** : Cocher **Autoriser le trading automatique**
   - Onglet **Paramètres d'entrée** : Laisser les valeurs par défaut
4. Cliquer **OK**

### 4.3 Vérification du Fonctionnement
1. Vérifier le **smiley vert** en haut à droite du graphique
2. Consulter l'onglet **Journal** :
```
=== INITIALISATION A2SNIPER TRADING ===
HeikinAshi initialisé pour EURUSD M1
PatternDetector initialisé - Min Pullback: 2 | Doji Ratio: 0.3
RiskManager initialisé - Risque: 1.0%
SignalValidator initialisé - Heures: 08:00-18:00
=== A2SNIPER TRADING INITIALISÉ AVEC SUCCÈS ===
```

---

## Étape 5 : Configuration Avancée

### 5.1 Chargement d'une Configuration Prédéfinie
1. Clic droit sur l'EA dans le graphique
2. **Propriétés de l'Expert Advisor**
3. Onglet **Paramètres d'entrée**
4. Bouton **Charger**
5. Sélectionner le fichier approprié :
   - `A2SniperTrading_Forex.set` pour le Forex
   - `A2SniperTrading_Crypto.set` pour les Cryptos
   - `A2SniperTrading_Default.set` pour usage général

### 5.2 Paramètres Recommandés par Marché

#### Pour EURUSD, GBPUSD, USDJPY
```
EMA_Period = 21
Risk_Percent = 0.8
SL_Method = 2 (ATR)
ATR_Multiplier = 1.8
Max_Spread = 2.5
Max_Positions = 2
```

#### Pour BTCUSD, ETHUSD
```
EMA_Period = 18
Risk_Percent = 1.5
Volume_Multiplier = 1.3
Max_Spread = 5.0
Trading_Hours = 00:00-23:59
Max_Positions = 4
```

### 5.3 Activation du Panel UI
```
Show_UI_Panel = true
```
Cela affichera un panel de contrôle graphique avec :
- Statistiques en temps réel
- Boutons de contrôle
- Indicateurs de performance

---

## Étape 6 : Tests et Validation

### 6.1 Test en Mode Démo
1. **OBLIGATOIRE** : Tester d'abord sur compte démo
2. Laisser tourner minimum **1 semaine**
3. Surveiller les métriques :
   - Nombre de trades
   - Win rate
   - Drawdown maximum
   - Profit factor

### 6.2 Backtesting (Optionnel)
1. **Ctrl+R** pour ouvrir le testeur de stratégies
2. Sélectionner **A2SniperTrading**
3. Paramètres :
   - **Symbole** : EURUSD
   - **Période** : M1
   - **Dates** : 3 derniers mois minimum
   - **Modèle** : Tous les ticks
4. **Démarrer** le test

### 6.3 Métriques de Validation
Résultats acceptables :
- **Profit Factor** : > 1.3
- **Win Rate** : > 55%
- **Max Drawdown** : < 20%
- **Trades par jour** : 2-10

---

## Étape 7 : Passage en Réel

### 7.1 Vérifications Finales
- ✅ Tests démo concluants
- ✅ Compréhension complète des paramètres
- ✅ Capital suffisant (min. 1000)
- ✅ Surveillance possible

### 7.2 Démarrage Progressif
1. **Semaine 1** : Risk_Percent = 0.5%
2. **Semaine 2** : Risk_Percent = 0.8%
3. **Semaine 3+** : Risk_Percent = 1.0% (ou plus selon confort)

### 7.3 Surveillance Continue
- **Quotidienne** : Vérifier les logs et performances
- **Hebdomadaire** : Analyser les statistiques
- **Mensuelle** : Optimiser les paramètres si nécessaire

---

## Dépannage Installation

### Problème : EA n'apparaît pas dans le Navigateur
**Solution :**
1. Vérifier la compilation sans erreur
2. Redémarrer MT5
3. Vérifier l'emplacement du fichier .ex5

### Problème : Erreur "Trading not allowed"
**Solution :**
1. Vérifier les autorisations dans Options → Expert Advisors
2. S'assurer que le bouton "Trading Automatique" est activé
3. Vérifier les restrictions du broker

### Problème : Smiley rouge sur le graphique
**Solution :**
1. Consulter l'onglet Journal pour les erreurs
2. Vérifier la connexion au serveur
3. Contrôler les paramètres d'entrée

### Problème : Pas de trades générés
**Solution :**
1. Vérifier que le marché est ouvert
2. Contrôler les heures de trading configurées
3. Vérifier le spread (doit être < Max_Spread)
4. S'assurer que les conditions de pattern sont réunies

---

## Support Post-Installation

### Ressources Disponibles
- **Manuel Utilisateur** : Documentation complète
- **Fichiers de Log** : MQL5\Files\A2SniperTrading\Logs\
- **Support Email** : support@yehiortech.com

### Maintenance Recommandée
- **Hebdomadaire** : Vérifier les logs d'erreur
- **Mensuelle** : Nettoyer les fichiers de log anciens
- **Trimestrielle** : Recompiler avec les dernières versions

---

*Installation réussie ! Votre A2Sniper Trading est maintenant prêt à trader.*

**Copyright 2024 YEHI OR Tech Solutions**
