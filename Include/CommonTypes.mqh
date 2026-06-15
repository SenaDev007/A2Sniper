//+------------------------------------------------------------------+
//| CommonTypes.mqh - Types, Enums, Structures Partages              |
//| A2Sniper Ultimate v3.1 - Professional Trading System             |
//| FIX: Partial close on REMAINING volume, added missing constants   |
//| v6.3: Smart partial close - skip when volume=min_lot (can't split) |
//| Copyright 2024, A2Sniper Development Team                        |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_COMMON_TYPES_MQH
#define A2SNIPER_COMMON_TYPES_MQH

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+

//--- Direction du marche
enum ENUM_MARKET_DIRECTION
  {
   MARKET_DIRECTION_BULLISH = 1,    // Tendance haussiere
   MARKET_DIRECTION_BEARISH = -1,   // Tendance baissiere
   MARKET_DIRECTION_RANGE   = 0     // Range / indetermine
  };

//--- Type de structure
enum ENUM_STRUCTURE_TYPE
  {
   STRUCTURE_HH = 1,   // Higher High
   STRUCTURE_HL = 2,   // Higher Low
   STRUCTURE_LH = 3,   // Lower High
   STRUCTURE_LL = 4,   // Lower Low
   STRUCTURE_BOS_BULLISH = 5,  // Break of Structure haussier
   STRUCTURE_BOS_BEARISH = 6,  // Break of Structure baissier
   STRUCTURE_CHOCH_BULLISH = 7, // Change of Character haussier
   STRUCTURE_CHOCH_BEARISH = 8, // Change of Character baissier
   STRUCTURE_MSS_BULLISH = 9,   // Market Structure Shift haussier
   STRUCTURE_MSS_BEARISH = 10   // Market Structure Shift baissier
  };

//--- Type de signal
enum ENUM_SIGNAL_TYPE
  {
   SIGNAL_NONE   = 0,    // Pas de signal
   SIGNAL_BUY    = 1,    // Signal d'achat
   SIGNAL_SELL   = -1    // Signal de vente
  };

//--- Classification du signal SRE
enum ENUM_SIGNAL_CLASS
  {
   SIGNAL_CLASS_NONE    = 0,    // Pas de signal
   SIGNAL_CLASS_WEAK    = 1,    // Score 70-79
   SIGNAL_CLASS_STANDARD = 2,   // Score 80-89
   SIGNAL_CLASS_SNIPER  = 3,    // Score 90-99
   SIGNAL_CLASS_ELITE   = 4     // Score 100
  };

//--- Type d'Order Block
enum ENUM_OB_TYPE
  {
   OB_NONE         = 0,   // Pas d'OB
   OB_BULLISH      = 1,   // Order Block haussier
   OB_BEARISH      = -1   // Order Block baissier
  };

//--- Etat de l'Order Block
enum ENUM_OB_STATE
  {
   OB_STATE_FRESH    = 100,   // Fresh OB - 100%
   OB_STATE_MITIGATED = 50,   // Mitigated OB - 50%
   OB_STATE_CONSUMED  = 0     // Consumed OB - 0%
  };

//--- Type de Fair Value Gap
enum ENUM_FVG_TYPE
  {
   FVG_NONE      = 0,    // Pas de FVG
   FVG_BULLISH   = 1,    // FVG haussier
   FVG_BEARISH   = -1    // FVG baissier
  };

//--- Classification FVG
enum ENUM_FVG_CLASS
  {
   FVG_CLASS_MICRO         = 1,   // Micro FVG
   FVG_CLASS_STANDARD      = 2,   // Standard FVG
   FVG_CLASS_INSTITUTIONAL = 3    // Institutional FVG
  };

//--- Type de liquidite
enum ENUM_LIQUIDITY_TYPE
  {
   LIQUIDITY_NONE       = 0,
   LIQUIDITY_BSL        = 1,   // Buy Side Liquidity
   LIQUIDITY_SSL        = -1,  // Sell Side Liquidity
   LIQUIDITY_EQUAL_HIGH = 2,
   LIQUIDITY_EQUAL_LOW  = -2,
   LIQUIDITY_DOUBLE_TOP = 3,
   LIQUIDITY_DOUBLE_BOTTOM = -3
  };

//--- Session de trading
enum ENUM_TRADING_SESSION
  {
   SESSION_ASIAN  = 0,   // 00:00 - 09:00 UTC
   SESSION_LONDON = 1,   // 07:00 - 16:00 UTC
   SESSION_NEWYORK = 2,  // 13:00 - 22:00 UTC
   SESSION_OVERLAP_LN = 3, // London-NY Overlap
   SESSION_NONE   = -1
  };

//--- Priorite de session
enum ENUM_SESSION_PRIORITY
  {
   SESSION_PRIORITY_HIGH   = 3,   // Londres + Overlap
   SESSION_PRIORITY_MEDIUM = 2,   // New York
   SESSION_PRIORITY_LOW    = 1    // Asie
  };

//--- Type de bougie d'indecision
enum ENUM_INDECISION_TYPE
  {
   INDECISION_NONE       = 0,
   INDECISION_DOJI       = 1,
   INDECISION_LONG_LEG   = 2,
   INDECISION_SPINNING   = 3,
   INDECISION_HAMMER     = 4,
   INDECISION_SHOOTING   = 5
  };

//--- Type d'engulfing
enum ENUM_ENGULFING_TYPE
  {
   ENGULFING_NONE         = 0,
   ENGULFING_BULLISH      = 1,
   ENGULFING_BEARISH      = -1
  };

//--- Mode de trailing stop
enum ENUM_TRAILING_MODE
  {
   TRAILING_ATR      = 0,   // Base sur ATR
   TRAILING_STRUCTURE = 1,  // Base sur la structure
   TRAILING_SWING    = 2    // Base sur les swing points
  };

//--- Mode de calcul du lot
enum ENUM_LOT_MODE
  {
   LOT_MODE_FIXED    = 0,   // Lot fixe
   LOT_MODE_RISK     = 1,   // Base sur le risque
   LOT_MODE_PROGRESSIVE = 2 // Progressif
  };

//--- Mode de fermeture partielle
enum ENUM_PARTIAL_CLOSE_MODE
  {
   PARTIAL_CLOSE_DISABLED = 0,
   PARTIAL_CLOSE_TP1_TP2_TP3 = 1   // 50% / 30% / 20%
  };

//--- Note du backtest
enum ENUM_BACKTEST_GRADE
  {
   GRADE_A_PLUS = 5,
   GRADE_A      = 4,
   GRADE_B      = 3,
   GRADE_C      = 2,
   GRADE_D      = 1
  };

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+

//--- Point de structure (swing high/low)
struct SStructurePoint
  {
   double            price;           // Prix du point
   datetime          time;            // Heure
   int               bar_index;       // Index de la barre
   ENUM_STRUCTURE_TYPE type;          // Type de structure
   bool              is_valid;        // Point valide
  };

//--- Donnees d'Order Block
struct SOrderBlock
  {
   double            high;            // Limite haute
   double            low;             // Limite basse
   datetime          time;            // Heure de formation
   int               bar_index;       // Index de la barre
   ENUM_OB_TYPE      type;            // Type haussier/baissier
   ENUM_OB_STATE     state;           // Etat (fresh/mitigated/consumed)
   double            score;           // Score de qualite (0-100)
   bool              is_valid;        // OB toujours actif
  };

//--- Donnees de Fair Value Gap
struct SFVG
  {
   double            high;            // Limite haute du gap
   double            low;             // Limite basse du gap
   datetime          time;            // Heure de formation
   int               bar_index;       // Index
   ENUM_FVG_TYPE     type;            // Type haussier/baissier
   ENUM_FVG_CLASS    classification;  // Classification
   double            size;            // Taille en pips
   bool              is_filled;       // Gap rempli
   bool              is_valid;        // Toujours actif
  };

//--- Donnees de liquidite
struct SLiquidityZone
  {
   double            price;           // Niveau de liquidite
   datetime          time;            // Heure
   ENUM_LIQUIDITY_TYPE type;          // Type
   double            strength;        // Force (0-100)
   bool              is_swept;        // Liquidite captee
   bool              is_valid;        // Toujours actif
  };

//--- Point de Market Structure
struct SMarketStructure
  {
   ENUM_MARKET_DIRECTION direction;      // Direction actuelle
   ENUM_STRUCTURE_TYPE   last_event;     // Dernier evenement structurel
   double                last_swing_high;// Dernier swing high
   double                last_swing_low; // Dernier swing low
   int                   swing_high_bar; // Barre du dernier SH
   int                   swing_low_bar;  // Barre du dernier SL
   double                trend_strength; // Force de la tendance (0-100)
   bool                  has_bos;        // BOS detecte
   bool                  has_choch;      // CHOCH detecte
   bool                  has_mss;        // MSS detecte
  };

//--- Signal complet du SRE
struct SStrategicReversalSignal
  {
   int               total_score;         // Score total (0-100)
   int               score_sens;          // Score sens du marche (0-20)
   int               score_indecision;    // Score indecision (0-15)
   int               score_zone;          // Score zone isolee (0-20)
   int               score_false_break;   // Score fausse invalidation (0-25)
   int               score_engulfing;     // Score avalement (0-20)
   ENUM_SIGNAL_TYPE  signal_type;         // Type de signal
   ENUM_SIGNAL_CLASS classification;      // Classification
   double            entry_price;         // Prix d'entree
   double            stop_loss;           // Stop loss
   double            take_profit_1;       // TP1
   double            take_profit_2;       // TP2
   double            take_profit_3;       // TP3
   bool              is_valid;            // Signal valide
   datetime          time;                // Heure du signal
  };

//--- Resultat du scoring AI
struct SAIScore
  {
   double            total_score;         // Score global pondere (0-100)
   double            sre_weight;          // Poids SRE (30%)
   double            smc_ict_weight;      // Poids SMC/ICT (25%)
   double            liquidity_weight;    // Poids liquidite (15%)
   double            ob_weight;           // Poids Order Blocks (10%)
   double            fvg_weight;          // Poids FVG (10%)
   double            volume_weight;       // Poids Volume (5%)
   double            volatility_weight;   // Poids Volatilite (5%)
   ENUM_SIGNAL_TYPE  signal_type;         // Direction
   bool              meets_threshold;     // Score >= seuil
   double            confidence;          // Confiance (0-100)
   };

//--- Donnees de session
struct SSessionInfo
  {
   ENUM_TRADING_SESSION  active_session;     // Session active
   ENUM_SESSION_PRIORITY priority;           // Priorite
   bool                  is_london;          // Session Londres
   bool                  is_newyork;         // Session NY
   bool                  is_overlap;         // Overlap LN
   bool                  is_asian;           // Session Asie
   bool                  is_killzone;        // Kill Zone active
   int                   hour_utc;           // Heure UTC
  };

//--- Resultat de trade
struct STradeResult
  {
   int               ticket;            // Ticket du trade
   ENUM_SIGNAL_TYPE  direction;         // Direction
   double            entry_price;       // Prix d'entree
   double            exit_price;        // Prix de sortie
   double            profit;            // Profit/Perte
   double            pips;              // Pips gagnes/perdus
   double            rr_achieved;       // R:R atteint
   datetime          open_time;         // Heure d'ouverture
   datetime          close_time;        // Heure de cloture
   double            score_at_entry;    // Score a l'entree
   string            setup_type;        // Type de setup
   ENUM_TRADING_SESSION session;        // Session
  };

//--- Statistiques globales
struct SStatistics
  {
   int               total_trades;      // Nombre total de trades
   int               winning_trades;    // Trades gagnants
   int               losing_trades;     // Trades perdants
   double            win_rate;          // Taux de reussite (%)
   double            profit_factor;     // Profit Factor
   double            total_profit;      // Profit total
   double            total_loss;        // Perte totale
   double            max_drawdown;      // Drawdown max
   double            avg_win;           // Gain moyen
   double            avg_loss;          // Perte moyenne
   double            avg_rr;            // R:R moyen
   double            sharpe_ratio;      // Sharpe Ratio
   double            recovery_factor;   // Recovery Factor
   double            expectancy;        // Expectancy
  };

//+------------------------------------------------------------------+
//| Constantes                                                       |
//+------------------------------------------------------------------+
#define A2SNIPER_VERSION        "4.0.0"
#define A2SNIPER_MAGIC          20240101

//--- Scores minimums
#define MIN_SIGNAL_SCORE_SNIPER 90
#define MIN_SIGNAL_SCORE_STANDARD 80
#define MIN_SIGNAL_SCORE_WEAK   70

//--- Lookback
#define MAX_SWING_LOOKBACK      50
#define OB_LOOKBACK             100
#define FVG_LOOKBACK            50
#define LIQUIDITY_LOOKBACK      100

//--- Risque par defaut
#define DEFAULT_RISK_PERCENT    1.0
#define DEFAULT_DAILY_DD        5.0
#define DEFAULT_WEEKLY_DD       10.0
#define DEFAULT_MONTHLY_DD      20.0

//--- ATR et volatilite
#define DEFAULT_ATR_PERIOD      14
#define DEFAULT_ATR_MULTIPLIER  1.5
#define MIN_ATR_FOR_TRADE       0.0005   // FIX: ATR minimum pour eviter spreads trop grands
#define DEFAULT_VOLUME_MULTIPLIER 1.5
#define INSTITUTIONAL_VOL_MULT  2.5
#define EXTREME_VOL_MULT        3.5

//--- Break Even dynamique (base ATR)
#define BE_ACTIVATION_R         0.5      // v6: Activer BE a 0.5R (plus rapide)
//--- v6.3: Quand volume=min_lot, BE reste a 0.5R (protection), TP a 1R (objectif)
#define BE_ATR_OFFSET_MULT      0.2      // FIX: Offset BE = 0.2 * ATR (au lieu de 2 pips fixe)
#define BE_MIN_OFFSET_PIPS      1.0      // Offset minimum en pips

//--- Partial Close (pourcentages du VOLUME RESTANT, pas du lot original)
#define PARTIAL_TP1_PCT         60.0     // v6: Fermer 60% a TP1 (plus agressif = lock profit)
#define PARTIAL_TP2_PCT         50.0     // v6: Fermer 50% du reste a TP2
#define PARTIAL_TP3_PCT         100.0    // Fermer 100% du volume restant a TP3 (ou trailing)

//--- v6.3: Smart Partial Close - quand volume = min_lot, on ne peut pas splitter
//--- Au lieu de partial close, on utilise BE a 0.5R + close full a 1R (TP2)
#define SMART_PARTIAL_MIN_LOT_FACTOR  2.0   // v6.3: Partial close possible si volume >= min_lot * FACTOR
                                                  // Ex: min_lot=0.01, factor=2.0 => besoin de 0.02 pour splitter

//--- TP R-multiples
#define TP1_R_MULT              0.5      // v6: TP1 a 0.5R (serre pour plus de wins)
#define TP2_R_MULT              1.0      // v6: TP2 a 1R
#define TP3_R_MULT              1.5      // v6: TP3 a 1.5R

//--- v6.3: TP alternatifs quand volume = min_lot (pas de partial close possible)
//--- On vise 1R direct au lieu de 0.5R partiel -> R:R effectif 1:1 au lieu de 0.5:1
#define SMART_TP_R_MULT         1.0      // v6.3: TP unique a 1R quand volume=min_lot (pas de split)

//--- Trailing Stop
#define TRAILING_ATR_MULT       1.5      // Trailing ATR multiplicateur
#define TRAILING_STEP_PIPS      5        // Step trailing minimum en pips
#define TRAILING_ACTIVATION_R   0.5      // FIX: Trailing actif a 0.5R (pas besoin d'attendre BE)

//--- Broker limits
#define MIN_SL_DISTANCE_PIPS    10       // Distance SL minimum en pips
#define MIN_TP_DISTANCE_PIPS    10       // Distance TP minimum en pips
#define MAX_SPREAD_POINTS       30       // Spread maximum en points
#define MAX_SLIPPAGE_POINTS     30       // Slippage maximum en points
#define ORDER_RETRY_COUNT       3        // FIX: Nombre de retry si ordre echoue
#define ORDER_RETRY_DELAY_MS    500      // Delai entre retry en ms

//--- Trade limits
#define MAX_DAILY_TRADES        5        // FIX: Maximum trades par jour
#define MAX_TRADES_SAME_DIR     1        // Maximum trades dans la meme direction

//--- Position timeout
#define POSITION_TIMEOUT_BARS   96       // 96 bougies M15 = 24h
#define POSITION_STAGNANT_PIPS  5        // Position stagnante si profit < 5 pips

//--- Divers
#define INDECISION_BODY_RATIO   0.25
#define EQUAL_TOLERANCE_PIPS    3.0
#define OB_MITIGATION_THRESHOLD 0.5
#define MAX_OPEN_POSITIONS      5
#define MAX_EXPOSURE_PERCENT    10.0

//--- Scores minimums par module AI (FIX v4: seuils augmentes pour 80%+ win rate)
#define MIN_MODULE_SCORE_SMC    35.0     // SMC doit avoir au moins 35/100 (sans double comptage)
#define MIN_MODULE_SCORE_LIQ    25.0     // Liquidite doit avoir au moins 25/100
#define MIN_MODULE_SCORE_VOL    0.0      // Volume doit etre POSITIF (pas negatif)
#define MIN_ENGINES_CONFIRMING  6        // v4: Au moins 6 moteurs sur 9 doivent confirmer
#define MIN_ADX_FOR_TRADE       20.0     // ADX minimum pour eviter le ranging

//--- Order Book Engine (Carnet d'ordres)
#define OB_BOOK_WALL_MULTIPLIER 3.0      // Mur = x fois le volume moyen
#define OB_BOOK_IMBALANCE_THRESH 1.5     // Seuil imbalance significatif
#define OB_BOOK_EXTREME_IMBALANCE 2.5    // Seuil imbalance extreme
#define OB_BOOK_MIN_LIQUIDITY    0.3     // Ratio liquidite minimum
#define OB_BOOK_MAX_LEVELS       50      // Niveaux max a analyser
#define OB_BOOK_CONFIDENCE_BOOST 5.0     // Bonus score sniper si OrderBook confirme

#endif // A2SNIPER_COMMON_TYPES_MQH
//+------------------------------------------------------------------+
