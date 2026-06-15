//+------------------------------------------------------------------+
//|                                                      A2SniperTrading.mq5 |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//| A2Sniper Ultimate v4.0 - Wall Street Level Trading System        |
//| Full integration: Sniper + State Machine + Adaptive Risk         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"
#property version   "6.20"
#property description "A2Sniper Trading v6.2 - Qualite avant Quantite"
#property description "v6.2: Seuil composite 45 (55 trop restrictif), Min 2 confirmations"
#property description "TP1 serre 0.5R, BE rapide 0.5R, R:R minimum 1.0"
#property description "SMC/ICT + Strategic Reversal + Smart Money"
#property description "80%+ Win Rate Target"

//+------------------------------------------------------------------+
//| Includes - Full Ultimate Architecture                            |
//+------------------------------------------------------------------+
#include <A2Sniper\CommonTypes.mqh>
#include <A2Sniper\MarketStructureEngine.mqh>
#include <A2Sniper\OrderBlockEngine.mqh>
#include <A2Sniper\FVGEngine.mqh>
#include <A2Sniper\LiquidityEngine.mqh>
#include <A2Sniper\SessionEngine.mqh>
#include <A2Sniper\VolumeEngine.mqh>
#include <A2Sniper\VolatilityEngine.mqh>
#include <A2Sniper\StrategicReversalEngine.mqh>
#include <A2Sniper\SmartMoneyEngine.mqh>
#include <A2Sniper\ICTEngine.mqh>
#include <A2Sniper\AIScoringEngine.mqh>
#include <A2Sniper\RiskManager.mqh>
#include <A2Sniper\AdaptiveRiskEngine.mqh>
#include <A2Sniper\TradeExecutor.mqh>
#include <A2Sniper\PositionStateMachine.mqh>
#include <A2Sniper\TradeSniperEngine.mqh>
#include <A2Sniper\DashboardManager.mqh>
#include <A2Sniper\StatisticsDatabase.mqh>
#include <A2Sniper\NewsFilterEngine.mqh>
#include <A2Sniper\MachineLearningEngine.mqh>
#include <A2Sniper\BacktestIntelligenceEngine.mqh>
#include <A2Sniper\OrderBookEngine.mqh>

//+------------------------------------------------------------------+
//| Parametres d'entree                                              |
//+------------------------------------------------------------------+

//--- General
input group           "=== General Settings ==="
input bool            EnableAutoTrading = true;        // Activer le trading automatique
input ulong           MagicNumber = A2SNIPER_MAGIC;    // Numero magique
input int             GMT_Offset = 0;                   // Decalage GMT du broker

//--- Risk Management (Adaptatif)
input group           "=== Adaptive Risk Management ==="
input double          RiskPercent = 1.0;                // Risque de base par trade (%)
input double          MaxDailyDD = 5.0;                 // Drawdown journalier max (%)
input double          MaxWeeklyDD = 10.0;               // Drawdown hebdomadaire max (%)
input double          MaxMonthlyDD = 20.0;              // Drawdown mensuel max (%)
input int             MaxPositions = 3;                 // Positions simultanees max
input int             MaxDailyTrades = 5;               // Maximum trades par jour
input bool            UseAdaptiveRisk = true;           // Utiliser le Risk Engine Adaptatif

//--- Trade Sniper
input group           "=== Trade Sniper Settings ==="
input int             MinSniperScore = 70;              // Score sniper minimum (70=Bronze, 80=Silver, 90=Gold)
input double          MinRiskReward = 1.0;              // R:R minimum (1.0 - v6: TP3=1.5R donc R:R effectif bon)
input bool            RequireKillzone = false;          // Exiger zone Kill Zone (desactive - score gre)
input bool            RequireStructure = false;          // Exiger structure alignee (desactive - score gre)
input bool            RequireInstitutional = false;      // Exiger empreinte institutionnelle (desactive - score gre)

//--- Signal
input group           "=== Signal Settings ==="
input double          MinSignalScore = 60.0;            // Score AI minimum (60 au lieu de 80)
input int             MinSREScore = 65;                  // Score SRE minimum (65 au lieu de 85)
input bool            RequireSMEConfirmation = false;   // Confirmation Smart Money (desactive - bonus score)
input bool            RequireSessionFilter = false;     // Filtre de session (desactive - score gre)
input bool            RequireNewsFilter = true;         // Filtre economique

//--- Trade Management (State Machine)
input group           "=== Position State Machine ==="
input bool            EnableBreakEven = true;           // Break Even dynamique
input bool            EnableTrailingStop = true;        // Trailing Stop progressif
input bool            EnablePartialClose = true;        // Fermeture partielle TP1/TP2/TP3
input bool            EnableStructuralSL = true;        // SL ajuste sur structure
input ENUM_TRAILING_MODE TrailingMode = TRAILING_ATR;  // Mode Trailing

//--- Timeframes
input group           "=== Timeframe Settings ==="
input ENUM_TIMEFRAMES HTF_Timeframe = PERIOD_H4;       // Timeframe superieur
input ENUM_TIMEFRAMES MTF_Timeframe = PERIOD_H1;       // Timeframe moyen
input ENUM_TIMEFRAMES LTF_Timeframe = PERIOD_M15;      // Timeframe execution

//--- Order Book
input group           "=== Order Book (Carnet d'Ordres) ==="
input bool            EnableOrderBook = true;           // Activer l'analyse du carnet d'ordres
input bool            RequireBookConfirmation = false;   // Exiger confirmation du carnet (strict)
input bool            UseBookSLAdjust = true;            // Ajuster SL sur les murs d'ordres

//--- Dashboard
input group           "=== Dashboard ==="
input bool            EnableDashboard = true;           // Afficher le dashboard

//+------------------------------------------------------------------+
//| Objets globaux                                                   |
//+------------------------------------------------------------------+
//--- Moteurs d'analyse
CMarketStructureEngine  g_market_structure;
COrderBlockEngine       g_order_blocks;
CFVGEngine              g_fvg_engine;
CLiquidityEngine        g_liquidity_engine;
CSessionEngine          g_session_engine;
CVolumeEngine           g_volume_engine;
CVolatilityEngine       g_volatility_engine;

//--- Moteurs composites
CStrategicReversalEngine g_sre;
CSmartMoneyEngine       g_smart_money;
CICTEngine              g_ict_engine;
CAIScoringEngine        g_ai_scoring;

//--- Gestion du risque
CRiskManager            g_risk_manager;          // Risk Manager classique
CAdaptiveRiskEngine     g_adaptive_risk;         // Risk Engine Adaptatif (Wall Street)

//--- Execution et gestion
CTradeExecutor          g_trade_executor;
CPositionStateMachine   g_position_sm;            // Position State Machine (Wall Street)

//--- Trade Sniper
CTradeSniperEngine      g_sniper_engine;

//--- Support
CDashboardManager       g_dashboard;
CStatisticsDatabase     g_statistics;
CNewsFilterEngine       g_news_filter;
CMachineLearningEngine  g_ml_engine;
CBacktestIntelligenceEngine g_bt_intelligence;
COrderBookEngine           g_order_book;

//--- Etat global
bool              g_all_initialized = false;
datetime          g_last_analysis_time = 0;
int               g_last_signal_direction = 0;
double            g_last_score = 0;
int               g_ticks_processed = 0;
int               g_last_sniper_score = 0;

//+------------------------------------------------------------------+
//| Initialisation de l'Expert                                       |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("========================================");
   Print("  A2Sniper Trading v6.2 - Qualite avant Quantite");
   Print("  v6.2: Min 2 confirmations, TP1=0.5R, BE=0.5R");
   Print("  Composite>=45, R:R>=1.0, Confluence prime");
   Print("========================================");

   //--- 1. Initialiser le Risk Manager
   //--- FIX v5.1: Toujours initialiser g_risk_manager car TradeExecutor l'utilise
   //--- pour ValidateOrder/CalculateLotSize en fallback
   if(!g_risk_manager.Initialize(RiskPercent, MaxDailyDD, MaxWeeklyDD, MaxMonthlyDD, MaxPositions, MagicNumber))
     { Print("A2Sniper Trading: ERREUR - Risk Manager"); return INIT_FAILED; }

   if(UseAdaptiveRisk)
     {
      if(!g_adaptive_risk.Initialize(RiskPercent, MaxDailyDD, MaxWeeklyDD, MaxMonthlyDD, MaxPositions, MaxDailyTrades, MagicNumber))
        { Print("A2Sniper Trading: ERREUR - Adaptive Risk Engine"); return INIT_FAILED; }
     }

   //--- 2. Initialiser les moteurs d'analyse
   if(!g_market_structure.Initialize(10, 0, 100))
     { Print("A2Sniper Trading: ERREUR - Market Structure Engine"); return INIT_FAILED; }
   if(!g_order_blocks.Initialize(OB_LOOKBACK, 1.5, 20))
     { Print("A2Sniper Trading: ERREUR - Order Block Engine"); return INIT_FAILED; }
   if(!g_fvg_engine.Initialize(FVG_LOOKBACK, 30))
     { Print("A2Sniper Trading: ERREUR - FVG Engine"); return INIT_FAILED; }
   if(!g_liquidity_engine.Initialize(LIQUIDITY_LOOKBACK, EQUAL_TOLERANCE_PIPS))
     { Print("A2Sniper Trading: ERREUR - Liquidity Engine"); return INIT_FAILED; }
   if(!g_session_engine.Initialize(GMT_Offset))
     { Print("A2Sniper Trading: ERREUR - Session Engine"); return INIT_FAILED; }
   if(!g_volume_engine.Initialize(20, 1.5, 2.5))
     { Print("A2Sniper Trading: ERREUR - Volume Engine"); return INIT_FAILED; }
   if(!g_volatility_engine.Initialize(DEFAULT_ATR_PERIOD, 0.5, 3.0))
     { Print("A2Sniper Trading: ERREUR - Volatility Engine"); return INIT_FAILED; }

   //--- 3. Moteurs composites
   if(!g_sre.Initialize(&g_market_structure, &g_order_blocks, &g_fvg_engine, &g_liquidity_engine, &g_session_engine))
     { Print("A2Sniper Trading: ERREUR - Strategic Reversal Engine"); return INIT_FAILED; }
   if(!g_smart_money.Initialize(&g_market_structure, &g_order_blocks, &g_fvg_engine, &g_liquidity_engine))
     { Print("A2Sniper Trading: ERREUR - Smart Money Engine"); return INIT_FAILED; }
   if(!g_ict_engine.Initialize(&g_session_engine, &g_market_structure))
     { Print("A2Sniper Trading: ERREUR - ICT Engine"); return INIT_FAILED; }
   if(!g_ai_scoring.Initialize(&g_sre, &g_smart_money, &g_ict_engine, &g_order_blocks,
                                &g_fvg_engine, &g_liquidity_engine, &g_volume_engine,
                                &g_volatility_engine, &g_session_engine, MinSignalScore))
     { Print("A2Sniper Trading: ERREUR - AI Scoring Engine"); return INIT_FAILED; }

   //--- 4. Trade Executor
   //--- FIX v5.1: Utiliser le BON RiskManager selon UseAdaptiveRisk
   //--- L'ancien code utilisait toujours g_risk_manager meme quand UseAdaptiveRisk=true
   //--- Ca causait "Trade refuse par Risk Manager" sur TOUS les trades car g_risk_manager
   //--- n'etait pas initialise!
   if(UseAdaptiveRisk)
     {
      //--- v5.1: On ne peut pas passer CAdaptiveRiskEngine* a Initialize(CRiskManager*)
      //--- Solution: Le TradeExecutor n'utilise le RM que pour CanOpenTrade/HasEnoughMargin
      //--- On initialise avec g_risk_manager MAIS on override les checks dans le pipeline
      if(!g_trade_executor.Initialize(&g_risk_manager, MagicNumber))
        { Print("A2Sniper Trading: ERREUR - Trade Executor"); return INIT_FAILED; }
      //--- Les verifications de risque sont deja faites dans TryExecuteSniperSignal
      //--- via g_adaptive_risk.CanOpenTrade() avant l'appel a ExecuteBuy/Sell
     }
   else
     {
      if(!g_trade_executor.Initialize(&g_risk_manager, MagicNumber))
        { Print("A2Sniper Trading: ERREUR - Trade Executor"); return INIT_FAILED; }
     }

   //--- FIX v4.2: Trade Manager removed - PSM handles all trade management

   //--- 6. Position State Machine (Wall Street)
   if(!g_position_sm.Initialize(&g_trade_executor, &g_volatility_engine, &g_market_structure,
                                  EnableBreakEven, EnableTrailingStop, EnablePartialClose,
                                  EnableStructuralSL, TrailingMode))
     { Print("A2Sniper Trading: ERREUR - Position State Machine"); return INIT_FAILED; }

   //--- 7. Trade Sniper Engine (Wall Street)
   if(!g_sniper_engine.Initialize(&g_market_structure, &g_order_blocks, &g_fvg_engine,
                                    &g_liquidity_engine, &g_volatility_engine,
                                    &g_session_engine, &g_volume_engine, MinSniperScore))
     { Print("A2Sniper Trading: ERREUR - Trade Sniper Engine"); return INIT_FAILED; }
   g_sniper_engine.SetRequireKillzone(RequireKillzone);

   //--- 8. Support
   if(!g_dashboard.Initialize(10, 30, EnableDashboard))
     { Print("A2Sniper Trading: ERREUR - Dashboard"); return INIT_FAILED; }
   if(!g_statistics.Initialize())
     { Print("A2Sniper Trading: ERREUR - Statistics Database"); return INIT_FAILED; }
   if(!g_news_filter.Initialize(RequireNewsFilter, 30, 30))
     { Print("A2Sniper Trading: ERREUR - News Filter"); return INIT_FAILED; }
   if(!g_ml_engine.Initialize(500, 30))
     { Print("A2Sniper Trading: ERREUR - ML Engine"); return INIT_FAILED; }
   if(!g_bt_intelligence.Initialize(50))
     { Print("A2Sniper Trading: ERREUR - Backtest Intelligence"); return INIT_FAILED; }

   //--- 9. Order Book Engine
   if(EnableOrderBook)
     {
      if(!g_order_book.Initialize(_Symbol, OB_BOOK_WALL_MULTIPLIER, OB_BOOK_IMBALANCE_THRESH,
                                   OB_BOOK_EXTREME_IMBALANCE, 10, OB_BOOK_MIN_LIQUIDITY, OB_BOOK_MAX_LEVELS))
        { Print("A2Sniper Trading: ERREUR - Order Book Engine"); return INIT_FAILED; }
     }
   else
      g_order_book.SetEnabled(false);

   g_statistics.LoadFromHistory();
   g_all_initialized = true;

   Print("A2Sniper Trading: Tous les moteurs initialises avec succes");
   Print("A2Sniper Trading: Risk=", RiskPercent, "% | Sniper>=", MinSniperScore,
         " | R:R>=", MinRiskReward, " | AdaptiveRisk=", UseAdaptiveRisk ? "ON" : "OFF",
         " | StructuralSL=", EnableStructuralSL ? "ON" : "OFF",
         " | OrderBook=", EnableOrderBook ? (g_order_book.IsAvailable() ? "ON" : "DEGRADE") : "OFF");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   g_bt_intelligence.Deinitialize();
   g_ml_engine.Deinitialize();
   g_news_filter.Deinitialize();
   g_statistics.Deinitialize();
   g_dashboard.Deinitialize();
   g_sniper_engine.Deinitialize();
   g_position_sm.Deinitialize();
   g_trade_executor.Deinitialize();
   g_adaptive_risk.Deinitialize();
   g_ai_scoring.Deinitialize();
   g_ict_engine.Deinitialize();
   g_smart_money.Deinitialize();
   g_sre.Deinitialize();
   g_volatility_engine.Deinitialize();
   g_volume_engine.Deinitialize();
   g_session_engine.Deinitialize();
   g_liquidity_engine.Deinitialize();
   g_fvg_engine.Deinitialize();
   g_order_blocks.Deinitialize();
   g_market_structure.Deinitialize();
   g_risk_manager.Deinitialize();
   g_order_book.Deinitialize();

   g_all_initialized = false;
   Print("A2Sniper Trading: Expert desinitialise - Raison: ", reason);
  }

//+------------------------------------------------------------------+
//| Fonction principale - tick                                      |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!g_all_initialized || !EnableAutoTrading)
      return;

   g_ticks_processed++;

   //--- 1. Mise a jour temps reel (chaque tick)
   g_session_engine.Update();
   g_news_filter.Update();

   if(UseAdaptiveRisk)
      g_adaptive_risk.Update();
   else
      g_risk_manager.Update();

   //--- 2. Mise a jour technique (nouvelle bougie)
   bool new_bar = IsNewBar(LTF_Timeframe);

   if(new_bar)
     {
      double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
      bool spread_ok = (spread <= MAX_SPREAD_POINTS * _Point);

      g_market_structure.Update(HTF_Timeframe);
      g_market_structure.Update(MTF_Timeframe);
      g_market_structure.Update(LTF_Timeframe);
      g_order_blocks.Update();
      g_fvg_engine.Update();
      g_liquidity_engine.Update();
      g_volume_engine.Update();
      g_volatility_engine.Update();
      g_smart_money.Update();
      g_ict_engine.Update();

      //--- Order Book update (chaque nouvelle bougie)
      if(EnableOrderBook)
         g_order_book.Update();

      //--- 3. Analyser les signaux (seulement si spread acceptable)
      bool can_trade = UseAdaptiveRisk ? g_adaptive_risk.CanOpenTrade(SIGNAL_BUY) : g_risk_manager.CanOpenTrade(SIGNAL_BUY);
      bool news_ok = g_news_filter.CanTrade();
      if(spread_ok && can_trade && news_ok)
         AnalyzeAndExecute();
      else if(!spread_ok)
         Print("A2Sniper Trading: Spread trop eleve - Analyse sautee");

      g_last_analysis_time = TimeCurrent();
     }

   //--- 4. Gerer les positions ouvertes (chaque tick)
   g_position_sm.Update();

   //--- 5. Protection news
   if(RequireNewsFilter && g_news_filter.ShouldTightenStopLoss())
      TightenSLForNews();

   //--- 6. Dashboard
   if(EnableDashboard && g_ticks_processed % 10 == 0)
      UpdateDashboard();
  }

//+------------------------------------------------------------------+
//| Analyser et Executer - PIPELINE v5                               |
//+------------------------------------------------------------------+
void AnalyzeAndExecute()
  {
   SMarketStructure m15_struct = g_market_structure.GetStructure(LTF_Timeframe);

   //--- v5: Assouplir la condition de direction
   //--- Ancien code: exigeait direction BULLISH/BEARISH sur M15
   //--- Nouveau: accepte aussi les CHoCH/MSS et meme le RANGE si le score composite est bon
   //--- Le score composite dans TryExecuteSniperSignal fera le tri final

   //--- Analyser ACHATS (direction haussiere OU signal de retournement haussier)
   bool buy_allowed = (m15_struct.direction == MARKET_DIRECTION_BULLISH ||
                       m15_struct.last_event == STRUCTURE_CHOCH_BULLISH ||
                       m15_struct.last_event == STRUCTURE_MSS_BULLISH ||
                       m15_struct.has_bos || m15_struct.has_choch || m15_struct.has_mss);
   //--- v5: Toujours analyser les deux directions - le score composite decidra
   //--- Si le marché est en range, on peut trader dans les deux sens
   if(m15_struct.direction == MARKET_DIRECTION_RANGE)
     {
      buy_allowed = true;  // En range, on autorise les deux sens
     }

   //--- Analyser VENTES (direction baissiere OU signal de retournement baissier)
   bool sell_allowed = (m15_struct.direction == MARKET_DIRECTION_BEARISH ||
                        m15_struct.last_event == STRUCTURE_CHOCH_BEARISH ||
                        m15_struct.last_event == STRUCTURE_MSS_BEARISH ||
                        m15_struct.has_bos || m15_struct.has_choch || m15_struct.has_mss);
   if(m15_struct.direction == MARKET_DIRECTION_RANGE)
     {
      sell_allowed = true;  // En range, on autorise les deux sens
     }

   if(buy_allowed)
     {
      if(CheckMultiTimeframeAlignment(SIGNAL_BUY))
         TryExecuteSniperSignal(SIGNAL_BUY);
     }

   if(sell_allowed)
     {
      if(CheckMultiTimeframeAlignment(SIGNAL_SELL))
         TryExecuteSniperSignal(SIGNAL_SELL);
     }
  }

//+------------------------------------------------------------------+
//| Verifier l'alignement multi-timeframe v5                          |
//| v5: Assoupli - si HTF neutre, on n' bloque pas                   |
//+------------------------------------------------------------------+
bool CheckMultiTimeframeAlignment(ENUM_SIGNAL_TYPE direction)
  {
   ENUM_MARKET_DIRECTION h4_dir = g_market_structure.GetDirection(HTF_Timeframe);
   ENUM_MARKET_DIRECTION h1_dir = g_market_structure.GetDirection(MTF_Timeframe);

   if(direction == SIGNAL_BUY)
      //--- v5: Ne bloquer que si H4 ou H1 est explicitement BEARISH
      //--- RANGE sur HTF n'est plus bloquant
      return (h4_dir != MARKET_DIRECTION_BEARISH) && (h1_dir != MARKET_DIRECTION_BEARISH);

   if(direction == SIGNAL_SELL)
      return (h4_dir != MARKET_DIRECTION_BULLISH) && (h1_dir != MARKET_DIRECTION_BULLISH);

   return false;
  }

//+------------------------------------------------------------------+
//| Tenter d'executer un signal sniper v5                             |
//| Pipeline v5: SCORING APPROACH - le score decide, pas les portes   |
//|                                                                    |
//| Ancienne approche (v4): 15+ portes sequentielles ET                |
//| = probabilite combinee quasi nulle = 0 trades                     |
//|                                                                    |
//| Option A: Qualite avant Quantite (v6)                            |
//| = score_sniper*0.35 + score_ai*0.30 + score_sre*0.15             |
//|   + bonus confirmations (plus genereux)                            |
//|   - penalties (plus severes pour signaux faibles)                  |
//| + Exiger MIN 2 confirmations fortes parmi OB/FVG/BOS/KillZone    |
//| + TP1 serre a 0.5R (prendre profit vite = plus de wins)          |
//| Si score_composite >= MIN_COMPOSITE_SCORE (45) => trade           |
//+------------------------------------------------------------------+
#define MIN_COMPOSITE_SCORE  45.0   // v6.2: Baisse a 45 (55 trop restrictif, trop peu de trades)
#define MIN_CONFIRMATIONS    2      // v6: Minimum 2 confirmations fortes requises

void TryExecuteSniperSignal(ENUM_SIGNAL_TYPE direction)
  {
   //--- 1. Verifier le spread (seul filtre dur - on ne negocie pas un spread fou)
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   if(spread > MAX_SPREAD_POINTS * _Point)
     {
      Print("A2Sniper v6: Spread trop eleve - signal ignore");
      return;
     }

   //--- 2. PHASE SNIPER: Calculer le score sniper (sans portes bloquantes)
   //--- v5: HuntSniperSignal calcule le score meme si is_valid=false
   //--- L'ancien code retournait ici si is_valid=false = perte totale du signal
   SSniperSignal sniper = g_sniper_engine.HuntSniperSignal(direction);
   g_last_sniper_score = sniper.sniper_score;

   //--- v5: Si le sniper n'a meme pas calcule de score, on abandonne
   if(sniper.sniper_score <= 0)
     {
      Print("A2Sniper v6: Score sniper=0 - aucun signal detecte");
      return;
     }

   //--- 3. PHASE AI SCORING: Calculer le score AI
   SAIScoreV4 ai_score = g_ai_scoring.CalculateScore(direction);
   g_last_score = ai_score.total_score;
   g_last_signal_direction = (int)direction;

   //--- 4. PHASE SRE: Score Strategic Reversal
   SStrategicReversalSignal sre_signal = g_ai_scoring.GetLastSRESignal();

   //--- 5. v6: VERIFICATION DES CONFIRMATIONS FORTES
   bool has_sme = g_smart_money.HasSmartMoneyConfirmation(direction);
   bool is_optimal_session = g_session_engine.IsOptimalTradingTime();
   bool is_killzone = g_session_engine.IsKillZone();
   bool has_institutional = (sniper.zone_type != SNIPER_ZONE_NONE);
   bool has_good_timing = (sniper.timing != SNIPER_TIMING_NONE);
   bool has_bos = g_market_structure.HasBOS(PERIOD_CURRENT);
   bool has_choch = g_market_structure.HasCHOCH(PERIOD_CURRENT);
   bool has_ob = (sniper.zone_type == SNIPER_ZONE_OB || sniper.zone_type == SNIPER_ZONE_CONFLUENCE);
   bool has_fvg = (sniper.zone_type == SNIPER_ZONE_FVG || sniper.zone_type == SNIPER_ZONE_CONFLUENCE);

   //--- v6: Compter les confirmations fortes (OB, FVG, BOS/CHOCH, KillZone)
   int strong_confirmations = 0;
   if(has_ob)               strong_confirmations++;     // Order Block detecte
   if(has_fvg)              strong_confirmations++;     // Fair Value Gap detecte
   if(has_bos || has_choch) strong_confirmations++;     // Structure break (BOS ou CHOCH)
   if(is_killzone)          strong_confirmations++;     // Kill Zone active

   //--- v6: EXIGER MINIMUM 2 CONFIRMATIONS FORTES
   if(strong_confirmations < MIN_CONFIRMATIONS)
     {
      Print("A2Sniper v6: Confirmations insuffisantes (", strong_confirmations, "/", MIN_CONFIRMATIONS,
            ") OB=", has_ob ? "Y" : "N", " FVG=", has_fvg ? "Y" : "N",
            " BOS=", has_bos ? "Y" : "N", " CHOCH=", has_choch ? "Y" : "N",
            " KZ=", is_killzone ? "Y" : "N");
      return;
     }

   //--- 6. CALCULER LE SCORE COMPOSITE v6
   //--- Pondération v6: Sniper 35%, AI 30%, SRE 15%, Confirmations 20%
   double composite = 0.0;

   //--- Score sniper normalise (0-100 -> 0-35 pts) - principal, plus pese
   composite += (sniper.sniper_score / 100.0) * 35.0;

   //--- Score AI normalise (0-100 -> 0-30 pts)
   double ai_normalized = MathMax(0.0, MathMin(100.0, ai_score.total_score));
   composite += (ai_normalized / 100.0) * 30.0;

   //--- Score SRE normalise (0-100 -> 0-15 pts) - moins pese
   double sre_normalized = MathMax(0.0, MathMin(100.0, (double)sre_signal.total_score));
   composite += (sre_normalized / 100.0) * 15.0;

   //--- v6: Bonus de confirmations (plus genereux pour rewader la qualite)
   if(has_ob)               composite += 5.0;    // Order Block
   if(has_fvg)              composite += 5.0;    // Fair Value Gap
   if(has_bos || has_choch) composite += 5.0;    // Structure break
   if(is_killzone)          composite += 3.0;    // Kill Zone
   if(has_sme)              composite += 3.0;    // Smart Money
   if(is_optimal_session)   composite += 2.0;    // Session optimale
   if(has_good_timing)      composite += 2.0;    // Bon timing

   //--- v6: Penalites (plus severes pour signaux faibles)
   if(!has_institutional)   composite -= 8.0;    // Pas de zone institutionnelle (grave)
   if(!has_sme)             composite -= 5.0;    // Pas de confirmation Smart Money
   if(!has_good_timing)     composite -= 3.0;    // Pas de bon timing

   //--- v6: Bonus pour confluence multiple (2+ confirmations = deja verifie)
   if(strong_confirmations >= 3) composite += 5.0;    // Triple confluence
   if(strong_confirmations >= 4) composite += 5.0;    // Confluence maximale

   //--- Session asiatique sans paire asiatique = penalite forte
   if(g_session_engine.IsAsianSession())
     {
      string sym = _Symbol;
      if(StringFind(sym, "JPY") < 0 && StringFind(sym, "AUD") < 0 && StringFind(sym, "NZD") < 0)
         composite -= 8.0;   // Asie hors paires asiatiques
     }

   //--- v6: AI negatif = penalite plus forte (on veut de la qualite)
   if(ai_score.total_score <= 0)
     {
      composite -= 5.0;   // Penalite pour AI negatif
      Print("A2Sniper v6: Score AI negatif (", DoubleToString(ai_score.total_score, 1), ") - penalite -5");
     }

   //--- 7. DECISION: Le score composite decide
   Print("A2Sniper v6: Composite=", DoubleToString(composite, 1), "/", MIN_COMPOSITE_SCORE,
         " | Sniper=", sniper.sniper_score, " AI=", DoubleToString(ai_score.total_score, 1),
         " SRE=", sre_signal.total_score,
         " | Conf=", strong_confirmations, "/", MIN_CONFIRMATIONS,
         " OB=", has_ob ? "Y" : "N", " FVG=", has_fvg ? "Y" : "N",
         " BOS=", has_bos ? "Y" : "N", " KZ=", is_killzone ? "Y" : "N",
         " SME=", has_sme ? "Y" : "N", " Sess=", is_optimal_session ? "Y" : "N");

   if(composite < MIN_COMPOSITE_SCORE)
     {
      Print("A2Sniper v6: Score composite insuffisant (", DoubleToString(composite, 1), " < ", MIN_COMPOSITE_SCORE, ")");
      return;
     }

   //--- 8. Verifier R:R minimum (avec tolerance flottante)
   if(sniper.risk_reward < MinRiskReward - 0.01)
     {
      Print("A2Sniper v6: R:R insuffisant (", DoubleToString(sniper.risk_reward, 1), " < ", MinRiskReward, ")");
      return;
     }

   //--- 9. PHASE ORDER BOOK: Validation du carnet d'ordres (bonus, pas bloqueur)
   double book_sl = sniper.stop_loss;
   if(EnableOrderBook && g_order_book.IsAvailable())
     {
      double atr = g_volatility_engine.GetCurrentATR();
      SOrderBookValidation book_val = g_order_book.ValidateSignal(direction, sniper.entry_price,
                                                                    sniper.stop_loss, atr);

      if(RequireBookConfirmation && !book_val.liquidity_ok)
        {
         Print("A2Sniper v6: OrderBook REJET - Liquidite insuffisante (", book_val.rejection_reason, ")");
         return;
        }

      if(RequireBookConfirmation && book_val.confidence_score < 30.0)
        {
         Print("A2Sniper v6: OrderBook REJET - Confiance trop faible (", DoubleToString(book_val.confidence_score, 1), "/100)");
         return;
        }

      if(UseBookSLAdjust && book_val.wall_sl_adjust > 0 && book_val.wall_sl_adjust != sniper.stop_loss)
        {
         book_sl = book_val.wall_sl_adjust;
         Print("A2Sniper v6: OrderBook SL ajuste - SL original=", sniper.stop_loss,
               " . SL carnet=", book_sl);
        }
     }

   //--- 10. PHASE RISK: Verification du risque adaptatif
   bool can_trade;
   if(UseAdaptiveRisk)
      can_trade = g_adaptive_risk.CanOpenTrade(direction);
   else
      can_trade = g_risk_manager.CanOpenTrade(direction);

   if(!can_trade)
     {
      Print("A2Sniper v6: Risk Manager bloque le trade");
      return;
     }

   //--- 11. Verifier qu'on n'a pas deja une position dans cette direction
   if(HasOpenPositionInDirection(direction)) return;

   //--- 12. Filtre de correlation inter-devises
   if(HasCorrelatedPosition(direction)) return;

   //--- 13. Calculer le lot adaptatif
   double sl_distance_pips = MathAbs(sniper.entry_price - book_sl) / _Point;

   //--- v5: Securiser le SL - si SL trop proche, elargir
   if(sl_distance_pips < MIN_SL_DISTANCE_PIPS)
     {
      double atr = g_volatility_engine.GetCurrentATR();
      if(atr > 0)
         sl_distance_pips = (atr * 1.5) / _Point;
      else
         sl_distance_pips = MIN_SL_DISTANCE_PIPS;
     }

   double lot;
   if(UseAdaptiveRisk)
      lot = g_adaptive_risk.CalculateAdaptiveLotSize(sl_distance_pips);
   else
      lot = g_risk_manager.CalculateLotSize(sl_distance_pips);

   //--- v5: Forcer un lot minimum pour les petits comptes
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(lot < min_lot && lot > 0)
     {
      Print("A2Sniper v6: Lot calcule (", lot, ") < min_lot (", min_lot, ") - ajustement au minimum");
      lot = min_lot;
     }

   //--- v5: Si lot=0, c'est que le calcul a echoue - essayer avec le minimum
   if(lot <= 0)
     {
      lot = min_lot;
      Print("A2Sniper v6: Lot=0 detecte - utilisation du lot minimum (", lot, ")");
     }

   //--- 14. Verifier la marge
   bool has_margin;
   if(UseAdaptiveRisk)
      has_margin = g_adaptive_risk.HasEnoughMargin(lot);
   else
      has_margin = g_risk_manager.HasEnoughMargin(lot);

   if(!has_margin)
     {
      Print("A2Sniper v6: Marge insuffisante pour lot=", lot);
      return;
     }

   //--- 15. EXECUTION
   Print("========================================");
   Print("A2Sniper Trading v6: SIGNAL ", (direction == SIGNAL_BUY) ? "ACHAT" : "VENTE");
   Print("  Composite Score: ", DoubleToString(composite, 1), "/", MIN_COMPOSITE_SCORE);
   Print("  Sniper Score: ", sniper.sniper_score, "/100 (", GetSniperQualityName(sniper.quality), ")");
   Print("  AI Score: ", DoubleToString(ai_score.total_score, 1), "/100 (Conf: ", ai_score.confirming_engines, "/9)");
   Print("  SRE Score: ", sre_signal.total_score, "/100");
   Print("  R:R: ", DoubleToString(sniper.risk_reward, 1));
   Print("  Zone: ", GetSniperZoneName(sniper.zone_type), " | Timing: ", GetSniperTimingName(sniper.timing));
   Print("  Entry: ", GetEntryTechName(sniper.entry_technique));
   Print("  SME: ", has_sme ? "CONFIRMED" : "NO", " | Session: ", is_optimal_session ? "OPTIMAL" : "SUBOPTIMAL");
   Print("  Risk: ", UseAdaptiveRisk ? g_adaptive_risk.GetEffectiveRiskPercent() : g_risk_manager.GetEffectiveRiskPercent(), "%");
   Print("  Range Penalty: ", DoubleToString(ai_score.range_penalty, 1));
   Print("  Session Bonus: ", DoubleToString(ai_score.session_bonus, 1));
   Print("  Lot: ", lot, " | SL dist: ", DoubleToString(sl_distance_pips, 0), " pts");
   Print("========================================");

   int ticket = -1;
   if(direction == SIGNAL_BUY)
      ticket = g_trade_executor.ExecuteBuy(sniper.entry_price, book_sl,
                                            sniper.tp1, sniper.tp2, sniper.tp3, lot);
   else
      ticket = g_trade_executor.ExecuteSell(sniper.entry_price, book_sl,
                                             sniper.tp1, sniper.tp2, sniper.tp3, lot);

   //--- Enregistrer dans les gestionnaires
   if(ticket > 0)
     {
      g_position_sm.RegisterPosition(ticket, direction, sniper.entry_price,
                                      book_sl, sniper.tp1, sniper.tp2, sniper.tp3,
                                      lot, ai_score.total_score, sniper.sniper_score);

      if(UseAdaptiveRisk)
         g_adaptive_risk.RecordTradeOpened();
      else
         g_risk_manager.RecordTradeOpened();

      if(EnableDashboard)
         g_dashboard.DrawTradeLevels(sniper.entry_price, book_sl,
                                      sniper.tp1, sniper.tp2, sniper.tp3, direction);

      Print("A2Sniper v6: Trade execute - Ticket=", ticket, " Lot=", lot,
            " Composite=", DoubleToString(composite, 1),
            " Sniper=", sniper.sniper_score, " AI=", DoubleToString(ai_score.total_score, 1));

      string notif = StringFormat("A2Sniper v5 %s | Comp=%.0f Sniper=%d AI=%.0f SRE=%d R:R=%.1f",
                                   (direction == SIGNAL_BUY) ? "BUY" : "SELL",
                                   composite, sniper.sniper_score, ai_score.total_score,
                                   sre_signal.total_score, sniper.risk_reward);
      SendNotification(notif);
      Alert("A2Sniper Trading v6: ", (direction == SIGNAL_BUY) ? "ACHAT" : "VENTE",
            " Composite=", DoubleToString(composite, 0));
     }
   else
     {
      Print("A2Sniper v6: ECHEC execution - ticket=", ticket, " lot=", lot);
     }
  }

//+------------------------------------------------------------------+
//| Resserrer le SL avant les news                                   |
//+------------------------------------------------------------------+
void TightenSLForNews()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double current_sl = PositionGetDouble(POSITION_SL);
      double current_tp = PositionGetDouble(POSITION_TP);
      double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
      long pos_type = PositionGetInteger(POSITION_TYPE);

      double atr = g_volatility_engine.GetCurrentATR();
      if(atr <= 0) continue;
      double tighter_sl_distance = atr * 1.0;
      double tighter_sl = 0;
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

      if(pos_type == POSITION_TYPE_BUY)
        {
         tighter_sl = NormalizeDouble(entry_price - tighter_sl_distance, digits);
         if(tighter_sl > current_sl && tighter_sl > 0)
            g_trade_executor.ModifyPosition(ticket, tighter_sl, current_tp);
        }
      else if(pos_type == POSITION_TYPE_SELL)
        {
         tighter_sl = NormalizeDouble(entry_price + tighter_sl_distance, digits);
         if((tighter_sl < current_sl || current_sl == 0) && tighter_sl > 0)
            g_trade_executor.ModifyPosition(ticket, tighter_sl, current_tp);
        }
     }
  }

//+------------------------------------------------------------------+
//| Mettre a jour le dashboard                                       |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   SStatistics stats = g_statistics.GetStatistics();
   string session = g_session_engine.GetSessionName();
   string signal = (g_last_signal_direction == 1) ? "BUY" :
                    (g_last_signal_direction == -1) ? "SELL" : "NONE";
   SStrategicReversalSignal sre_sig = g_sre.GetLastSignal();
   string sre_class = GetSignalClassName(sre_sig.classification);

   int open_positions = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == (long)MagicNumber)
         open_positions++;
     }

   double daily_dd = UseAdaptiveRisk ? g_adaptive_risk.GetDailyDrawdownPct() : g_risk_manager.GetDailyDrawdownPct();
   double weekly_dd = UseAdaptiveRisk ? g_adaptive_risk.GetWeeklyDrawdownPct() : g_risk_manager.GetWeeklyDrawdownPct();
   double eff_risk = UseAdaptiveRisk ? g_adaptive_risk.GetEffectiveRiskPercent() : g_risk_manager.GetEffectiveRiskPercent();
   bool suspended = UseAdaptiveRisk ? g_adaptive_risk.IsTradingSuspended() : g_risk_manager.IsTradingSuspended();

   g_dashboard.Update(stats, g_last_score, session, signal, sre_class,
                       daily_dd, weekly_dd, eff_risk, open_positions, suspended);
  }

//+------------------------------------------------------------------+
//| Verifier s'il y a deja une position dans la direction            |
//+------------------------------------------------------------------+
bool HasOpenPositionInDirection(ENUM_SIGNAL_TYPE direction)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      long pos_type = PositionGetInteger(POSITION_TYPE);
      if(direction == SIGNAL_BUY && pos_type == POSITION_TYPE_BUY) return true;
      if(direction == SIGNAL_SELL && pos_type == POSITION_TYPE_SELL) return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| v4: Filtre de correlation inter-devises                          |
//| Empeche d'ouvrir EURUSD + GBPUSD en meme direction              |
//| (paires correlees = double exposition reelle)                    |
//+------------------------------------------------------------------+
bool HasCorrelatedPosition(ENUM_SIGNAL_TYPE direction)
  {
   string current_symbol = _Symbol;
   string current_base = SymbolInfoString(current_symbol, SYMBOL_CURRENCY_BASE);
   string current_profit = SymbolInfoString(current_symbol, SYMBOL_CURRENCY_PROFIT);

   //--- Paires fortement correlees
   string correlated_pairs[] = {"EURUSD", "GBPUSD", "AUDUSD", "NZDUSD",  // USD quote
                                 "USDCAD", "USDCHF", "USDJPY",            // USD base
                                 "EURGBP", "EURCHF", "EURAUD",            // Cross
                                 "GBPCHF", "GBPAUD", "GBPCAD"};           // Cross

   int corr_count = 0;
   long pos_type = (direction == SIGNAL_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)MagicNumber) continue;

      string pos_symbol = PositionGetString(POSITION_SYMBOL);
      if(pos_symbol == current_symbol) continue; // Meme paire, deja verifie

      long pos_dir = PositionGetInteger(POSITION_TYPE);

      //--- Verifier si la paire est correlee
      string pos_base = SymbolInfoString(pos_symbol, SYMBOL_CURRENCY_BASE);
      string pos_profit = SymbolInfoString(pos_symbol, SYMBOL_CURRENCY_PROFIT);

      //--- Meme devise de cotation (ex: EURUSD + GBPUSD)
      bool same_quote = (current_profit == pos_profit);
      //--- Meme devise de base (ex: EURUSD + EURGBP)
      bool same_base = (current_base == pos_base);

      if(same_quote && pos_dir == pos_type)
        {
         corr_count++;
         if(corr_count >= 1)
           {
            Print("A2Sniper Trading v4: Position correlee detectee - ", pos_symbol,
                  " (meme cotation: ", current_profit, ")");
            return true;
           }
        }

      if(same_base && pos_dir == pos_type)
        {
         corr_count++;
         if(corr_count >= 1)
           {
            Print("A2Sniper Trading v4: Position correlee detectee - ", pos_symbol,
                  " (meme base: ", current_base, ")");
            return true;
           }
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Nouvelle bougie                                                  |
//+------------------------------------------------------------------+
bool IsNewBar(ENUM_TIMEFRAMES tf)
  {
   static datetime last_bar_time = 0;
   datetime current_bar_time = iTime(_Symbol, tf, 0);
   if(current_bar_time != last_bar_time)
     {
      last_bar_time = current_bar_time;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Noms d'enum pour les logs                                        |
//+------------------------------------------------------------------+
string GetSignalClassName(ENUM_SIGNAL_CLASS classification)
  {
   switch(classification)
     {
      case SIGNAL_CLASS_ELITE:    return "ELITE";
      case SIGNAL_CLASS_SNIPER:   return "SNIPER";
      case SIGNAL_CLASS_STANDARD: return "STANDARD";
      case SIGNAL_CLASS_WEAK:     return "WEAK";
      default:                    return "NONE";
     }
  }

string GetSniperQualityName(int quality)
  {
   switch(quality)
     {
      case 4: return "DIAMOND";
      case 3: return "GOLD";
      case 2: return "SILVER";
      case 1: return "BRONZE";
      default: return "REJECT";
     }
  }

string GetSniperZoneName(int zone)
  {
   switch(zone)
     {
      case 4: return "CONFLUENCE";
      case 3: return "LIQUIDITY";
      case 2: return "FVG";
      case 1: return "OB";
      default: return "NONE";
     }
  }

string GetSniperTimingName(int timing)
  {
   switch(timing)
     {
      case 4: return "OVERLAP";
      case 3: return "CLOSE";
      case 2: return "OPEN";
      case 1: return "KILLZONE";
      default: return "NONE";
     }
  }

string GetEntryTechName(int tech)
  {
   switch(tech)
     {
      case 4: return "PULLBACK";
      case 3: return "BREAKOUT";
      case 2: return "LIMIT_FVG";
      case 1: return "LIMIT_OB";
      default: return "MARKET";
     }
  }

//+------------------------------------------------------------------+
//| Gestion des evenements de trade                                  |
//+------------------------------------------------------------------+
void OnTrade()
  {
   static int last_deals_total = 0;

   HistorySelect(0, TimeCurrent());
   int current_deals = HistoryDealsTotal();

   if(current_deals > last_deals_total)
     {
      for(int i = last_deals_total; i < current_deals; i++)
        {
         ulong deal_ticket = HistoryDealGetTicket(i);
         if(deal_ticket <= 0) continue;

         long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
         if(magic != (long)MagicNumber) continue;

         long entry = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT) continue;

         double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);

         //--- Enregistrer dans les stats
         STradeResult result;
         result.ticket = (int)deal_ticket;
         result.profit = profit;
         result.close_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
         long deal_type = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
         result.direction = (deal_type == DEAL_TYPE_BUY) ? SIGNAL_BUY : SIGNAL_SELL;

         g_statistics.RecordTrade(result);

         //--- Mettre a jour le Risk Manager
         bool is_win = (profit >= 0);
         if(UseAdaptiveRisk)
            g_adaptive_risk.RecordTradeResult(is_win, profit);
         else
            g_risk_manager.RecordTradeResult(is_win);

         //--- ML Engine
         SSignalPattern ml_pattern;
         ZeroMemory(ml_pattern);
         ml_pattern.session = g_session_engine.GetActiveSession();
         ml_pattern.symbol = _Symbol;
         ml_pattern.was_win = is_win;
         ml_pattern.profit = profit;
         ml_pattern.ai_score = g_last_score;
         ml_pattern.time = result.close_time;
         g_ml_engine.RecordTrade(ml_pattern);

         //--- Backtest Intelligence
         string setup_type = (result.direction == SIGNAL_BUY) ? "Sniper_Bullish" : "Sniper_Bearish";
         g_bt_intelligence.UpdateSetupFromTrade(setup_type, is_win, profit, 0, 0);

         Print("A2Sniper Trading: Trade ferme - Ticket=", deal_ticket, " Profit=", profit,
               " (", is_win ? "WIN" : "LOSS", ")");

         //--- Notification
         string close_notif = StringFormat("A2Sniper Trading Close | %s | P&L=%.2f", is_win ? "WIN" : "LOSS", profit);
         SendNotification(close_notif);

         //--- Retirer des gestionnaires
         g_position_sm.RemovePosition((ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID));
         if(EnableDashboard)
            g_dashboard.ClearTradeLevels();
        }

      last_deals_total = current_deals;
     }
  }

//+------------------------------------------------------------------+
//| Tester les fonctions                                             |
//+------------------------------------------------------------------+
double OnTester()
  {
   double net_profit = g_statistics.GetStatistics().total_profit - g_statistics.GetStatistics().total_loss;
   return net_profit;
  }
//+------------------------------------------------------------------+
