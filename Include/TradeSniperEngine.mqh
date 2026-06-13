//+------------------------------------------------------------------+
//| TradeSniperEngine.mqh - Moteur d'Entree Precision Sniper         |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| Precision entry engine with micro-timing, sniper validation,      |
//| institutional entry detection, and sub-pip accuracy              |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_TRADE_SNIPER_ENGINE_MQH
#define A2SNIPER_TRADE_SNIPER_ENGINE_MQH

#include <A2Sniper\CommonTypes.mqh>
#include <A2Sniper\MarketStructureEngine.mqh>
#include <A2Sniper\OrderBlockEngine.mqh>
#include <A2Sniper\FVGEngine.mqh>
#include <A2Sniper\LiquidityEngine.mqh>
#include <A2Sniper\VolatilityEngine.mqh>
#include <A2Sniper\SessionEngine.mqh>
#include <A2Sniper\VolumeEngine.mqh>

//+------------------------------------------------------------------+
//| Enumerations Sniper                                              |
//+------------------------------------------------------------------+
enum ENUM_SNIPER_ZONE
  {
   SNIPER_ZONE_NONE = 0,         // Pas dans une zone sniper
   SNIPER_ZONE_OB = 1,           // Sur un Order Block
   SNIPER_ZONE_FVG = 2,          // Dans un Fair Value Gap
   SNIPER_ZONE_LIQUIDITY = 3,    // Zone de liquidite (sweep)
   SNIPER_ZONE_CONFLUENCE = 4    // Confluence multiple
  };

enum ENUM_SNIPER_TIMING
  {
   SNIPER_TIMING_NONE = 0,       // Pas de timing optimal
   SNIPER_TIMING_KILLZONE = 1,   // Kill Zone de session
   SNIPER_TIMING_OPEN = 2,       // Ouverture de session
   SNIPER_TIMING_CLOSE = 3,      // Fermeture de session
   SNIPER_TIMING_OVERLAP = 4     // Overlap Londres/NY
  };

enum ENUM_SNIPER_QUALITY
  {
   SNIPER_QUALITY_REJECT = 0,    // Score < 70 - Rejeter
   SNIPER_QUALITY_BRONZE = 1,    // Score 70-79 - Observateur
   SNIPER_QUALITY_SILVER = 2,    // Score 80-89 - Standard
   SNIPER_QUALITY_GOLD = 3,      // Score 90-94 - Sniper
   SNIPER_QUALITY_DIAMOND = 4    // Score 95-100 - Elite
  };

enum ENUM_ENTRY_TECHNIQUE
  {
   ENTRY_MARKET = 0,             // Market order immediat
   ENTRY_LIMIT_OB = 1,           // Limit order sur OB
   ENTRY_LIMIT_FVG = 2,          // Limit order sur FVG
   ENTRY_BREAKOUT = 3,           // Sur breakout de structure
   ENTRY_PULLBACK = 4            // Sur pullback dans la tendance
  };

//+------------------------------------------------------------------+
//| Structure du signal sniper                                       |
//+------------------------------------------------------------------+
struct SSniperSignal
  {
   ENUM_SIGNAL_TYPE    direction;            // Direction
   double              entry_price;          // Prix d'entree precis
   double              stop_loss;            // SL calcule structurellement
   double              tp1;                  // TP1 (1R)
   double              tp2;                  // TP2 (2R)
   double              tp3;                  // TP3 (3R+)
   double              risk_reward;          // Ratio R:R
   int                 sniper_score;         // Score sniper (0-100)
   ENUM_SNIPER_QUALITY quality;              // Qualite du signal
   ENUM_SNIPER_ZONE    zone_type;            // Type de zone
   ENUM_SNIPER_TIMING  timing;               // Timing optimal
   ENUM_ENTRY_TECHNIQUE entry_technique;     // Technique d'entree
   double              confluence_count;     // Nombre de confluences
   double              confidence;           // Confiance (0-100)
   bool                is_valid;             // Signal valide
   datetime            signal_time;          // Heure du signal
   string              description;          // Description detaillee

   //--- Scores detailles
   int                 score_structure;      // Score structure (0-25)
   int                 score_zone;           // Score zone (0-25)
   int                 score_timing;         // Score timing (0-20)
   int                 score_confluence;     // Score confluence (0-15)
   int                 score_volume;         // Score volume (0-15)
  };

//+------------------------------------------------------------------+
//| Classe CTradeSniperEngine                                        |
//+------------------------------------------------------------------+
class CTradeSniperEngine
  {
private:
   bool                m_initialized;

   //--- Pointeurs vers les moteurs
   CMarketStructureEngine *m_market_structure;
   COrderBlockEngine      *m_order_blocks;
   CFVGEngine             *m_fvg_engine;
   CLiquidityEngine       *m_liquidity_engine;
   CVolatilityEngine      *m_volatility_engine;
   CSessionEngine         *m_session_engine;
   CVolumeEngine          *m_volume_engine;

   //--- Parametres sniper
   int                 m_min_sniper_score;        // Score minimum (95 pour Diamond)
   double              m_min_rr_ratio;            // R:R minimum (2.0)
   bool                m_require_killzone;        // Exiger zone killzone
   bool                m_require_structure;       // Exiger structure alignee
   bool                m_require_volume_surge;    // Exiger surge de volume

   //--- Statistiques sniper
   int                 m_total_signals;
   int                 m_sniper_signals;          // Gold+
   int                 m_diamond_signals;         // Diamond
   int                 m_executed_trades;
   int                 m_winning_trades;

   //--- Cache du dernier signal
   SSniperSignal       m_last_signal;

   //--- Methodes de scoring
   int                 ScoreStructure(ENUM_SIGNAL_TYPE direction);
   int                 ScoreZone(ENUM_SIGNAL_TYPE direction, double &entry, double &sl);
   int                 ScoreTiming();
   int                 ScoreConfluence(ENUM_SIGNAL_TYPE direction);
   int                 ScoreVolume();

   //--- Methodes de validation sniper
   bool                ValidateSniperEntry(ENUM_SIGNAL_TYPE direction, double entry_price);
   bool                ValidateMicroTiming(ENUM_SIGNAL_TYPE direction);
   bool                ValidateInstitutionalFootprint(ENUM_SIGNAL_TYPE direction);
   ENUM_SNIPER_ZONE    IdentifySniperZone(ENUM_SIGNAL_TYPE direction, double &zone_price);
   ENUM_SNIPER_TIMING  IdentifyOptimalTiming();
   ENUM_ENTRY_TECHNIQUE DetermineEntryTechnique(ENUM_SIGNAL_TYPE direction, ENUM_SNIPER_ZONE zone);

   //--- Calcul des niveaux
   double              CalculateSniperSL(ENUM_SIGNAL_TYPE direction, double entry_price);
   double              CalculateSniperTP(ENUM_SIGNAL_TYPE direction, double entry_price, double sl, double r_multiple);
   double              CalculatePrecisionEntry(ENUM_SIGNAL_TYPE direction, ENUM_SNIPER_ZONE zone, double zone_price);

public:
   //--- Constructeur / Destructeur
                       CTradeSniperEngine();
                      ~CTradeSniperEngine();

   //--- Initialisation
   bool                Initialize(CMarketStructureEngine *ms, COrderBlockEngine *ob,
                                   CFVGEngine *fvg, CLiquidityEngine *liq,
                                   CVolatilityEngine *vol, CSessionEngine *sess,
                                   CVolumeEngine *vol_eng, int min_score = 90);
   void                Deinitialize();

   //--- Detection sniper
   SSniperSignal       HuntSniperSignal(ENUM_SIGNAL_TYPE direction);
   bool                IsSniperEntryReady(ENUM_SIGNAL_TYPE direction);

   //--- Accesseurs
   SSniperSignal       GetLastSignal() const { return m_last_signal; }
   int                 GetTotalSignals() const { return m_total_signals; }
   int                 GetSniperCount() const { return m_sniper_signals; }
   int                 GetDiamondCount() const { return m_diamond_signals; }
   double              GetSniperWinRate() const;

   //--- Configuration
   void                SetMinScore(int score) { m_min_sniper_score = score; }
   void                SetMinRR(double rr) { m_min_rr_ratio = rr; }
   void                SetRequireKillzone(bool require) { m_require_killzone = require; }

   //--- Info
   string              GetSniperInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CTradeSniperEngine::CTradeSniperEngine() :
   m_initialized(false),
   m_market_structure(NULL),
   m_order_blocks(NULL),
   m_fvg_engine(NULL),
   m_liquidity_engine(NULL),
   m_volatility_engine(NULL),
   m_session_engine(NULL),
   m_volume_engine(NULL),
   m_min_sniper_score(90),
   m_min_rr_ratio(2.0),
   m_require_killzone(true),
   m_require_structure(true),
   m_require_volume_surge(true),
   m_total_signals(0),
   m_sniper_signals(0),
   m_diamond_signals(0),
   m_executed_trades(0),
   m_winning_trades(0)
  {
   ZeroMemory(m_last_signal);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CTradeSniperEngine::~CTradeSniperEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CTradeSniperEngine::Initialize(CMarketStructureEngine *ms, COrderBlockEngine *ob,
                                      CFVGEngine *fvg, CLiquidityEngine *liq,
                                      CVolatilityEngine *vol, CSessionEngine *sess,
                                      CVolumeEngine *vol_eng, int min_score)
  {
   if(ms == NULL || ob == NULL || fvg == NULL || liq == NULL ||
      vol == NULL || sess == NULL || vol_eng == NULL)
     {
      Print("A2Sniper SE: Pointeurs NULL detectes");
      return false;
     }

   m_market_structure = ms;
   m_order_blocks = ob;
   m_fvg_engine = fvg;
   m_liquidity_engine = liq;
   m_volatility_engine = vol;
   m_session_engine = sess;
   m_volume_engine = vol_eng;
   m_min_sniper_score = min_score;

   m_initialized = true;
   Print("A2Sniper SE: Trade Sniper Engine initialise (MinScore=", m_min_sniper_score,
         ", MinRR=", m_min_rr_ratio, ", Killzone=", m_require_killzone ? "ON" : "OFF", ")");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CTradeSniperEngine::Deinitialize()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Score de structure de marche (0-25)                              |
//| Un sniper entre seulement quand la structure confirme             |
//+------------------------------------------------------------------+
int CTradeSniperEngine::ScoreStructure(ENUM_SIGNAL_TYPE direction)
  {
   if(m_market_structure == NULL) return 0;

   int score = 0;
   SMarketStructure m15_struct = m_market_structure.GetStructure(PERIOD_M15);
   SMarketStructure h1_struct = m_market_structure.GetStructure(PERIOD_H1);
   SMarketStructure h4_struct = m_market_structure.GetStructure(PERIOD_H4);

   //--- M15 structure alignee (8 pts)
   if(direction == SIGNAL_BUY)
     {
      if(m15_struct.direction == MARKET_DIRECTION_BULLISH) score += 5;
      if(m15_struct.last_event == STRUCTURE_BOS_BULLISH || m15_struct.last_event == STRUCTURE_CHOCH_BULLISH) score += 3;
     }
   else
     {
      if(m15_struct.direction == MARKET_DIRECTION_BEARISH) score += 5;
      if(m15_struct.last_event == STRUCTURE_BOS_BEARISH || m15_struct.last_event == STRUCTURE_CHOCH_BEARISH) score += 3;
     }

   //--- H1 tendance alignee (7 pts)
   if(direction == SIGNAL_BUY && h1_struct.direction == MARKET_DIRECTION_BULLISH) score += 7;
   if(direction == SIGNAL_SELL && h1_struct.direction == MARKET_DIRECTION_BEARISH) score += 7;

   //--- H4 pas de contradiction (5 pts)
   if(direction == SIGNAL_BUY && h4_struct.direction != MARKET_DIRECTION_BEARISH) score += 5;
   if(direction == SIGNAL_SELL && h4_struct.direction != MARKET_DIRECTION_BULLISH) score += 5;

   //--- Force de tendance (5 pts)
   if(m15_struct.trend_strength >= 70) score += 5;
   else if(m15_struct.trend_strength >= 50) score += 3;
   else if(m15_struct.trend_strength >= 30) score += 1;

   return MathMin(score, 25);
  }

//+------------------------------------------------------------------+
//| Score de zone institutionnelle (0-25)                            |
//| Un sniper entre dans les zones ou les institutionnels operent     |
//+------------------------------------------------------------------+
int CTradeSniperEngine::ScoreZone(ENUM_SIGNAL_TYPE direction, double &entry, double &sl)
  {
   if(m_order_blocks == NULL || m_fvg_engine == NULL || m_liquidity_engine == NULL)
      return 0;

   int score = 0;
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = m_volatility_engine.GetCurrentATR();
   if(atr <= 0) atr = current_price * 0.001;  // Fallback

   //--- Proximite avec Order Block (10 pts)
   double best_ob_price = 0;
   double ob_score = 0;
   for(int i = 0; i < m_order_blocks.GetBullishCount() + m_order_blocks.GetBearishCount(); i++)
     {
      bool is_bullish = (i < m_order_blocks.GetBullishCount());
      SOrderBlock ob = is_bullish ? m_order_blocks.GetBullishOB(i) :
                       m_order_blocks.GetBearishOB(i - m_order_blocks.GetBullishCount());
      if(!ob.is_valid || ob.state == OB_STATE_CONSUMED) continue;

      double distance = MathAbs(current_price - (ob.high + ob.low) / 2.0);
      double proximity = distance / atr;

      if(proximity <= 0.5)  // Tres proche de l'OB
        {
         if((direction == SIGNAL_BUY && ob.type == OB_BULLISH) ||
            (direction == SIGNAL_SELL && ob.type == OB_BEARISH))
           {
            if(ob_score < 10 - proximity * 4)
              {
               ob_score = 10 - proximity * 4;
               best_ob_price = (ob.high + ob.low) / 2.0;
              }
           }
        }
     }
   score += (int)MathMax(ob_score, 0);

   //--- Proximite avec FVG (8 pts)
   double best_fvg_price = 0;
   double fvg_score = 0;
   for(int i = 0; i < m_fvg_engine.GetBullishCount() + m_fvg_engine.GetBearishCount(); i++)
     {
      bool is_bullish = (i < m_fvg_engine.GetBullishCount());
      SFVG fvg = is_bullish ? m_fvg_engine.GetBullishFVG(i) :
                  m_fvg_engine.GetBearishFVG(i - m_fvg_engine.GetBullishCount());
      if(!fvg.is_valid || fvg.is_filled) continue;

      double fvg_mid = (fvg.high + fvg.low) / 2.0;
      double distance = MathAbs(current_price - fvg_mid);
      double proximity = distance / atr;

      if(proximity <= 1.0)
        {
         if((direction == SIGNAL_BUY && fvg.type == FVG_BULLISH) ||
            (direction == SIGNAL_SELL && fvg.type == FVG_BEARISH))
           {
            if(fvg_score < 8 - proximity * 3)
              {
               fvg_score = 8 - proximity * 3;
               best_fvg_price = fvg_mid;
              }
           }
        }
     }
   score += (int)MathMax(fvg_score, 0);

   //--- Sweep de liquidite (7 pts)
   bool has_sweep = false;
   for(int i = 0; i < m_liquidity_engine.GetZoneCount(); i++)
     {
      SLiquidityZone zone = m_liquidity_engine.GetZone(i);
      if(!zone.is_valid) continue;

      if(zone.is_swept)
        {
         if((direction == SIGNAL_BUY && (zone.type == LIQUIDITY_SSL || zone.type == LIQUIDITY_EQUAL_LOW)) ||
            (direction == SIGNAL_SELL && (zone.type == LIQUIDITY_BSL || zone.type == LIQUIDITY_EQUAL_HIGH)))
           {
            has_sweep = true;
            score += 7;
            break;
           }
        }
     }

   //--- Determiner le prix d'entree optimal
   if(best_ob_price > 0 && best_fvg_price > 0)
      entry = (best_ob_price + best_fvg_price) / 2.0;  // Confluence
   else if(best_ob_price > 0)
      entry = best_ob_price;
   else if(best_fvg_price > 0)
      entry = best_fvg_price;
   else
      entry = current_price;  // Market order si pas de zone precise

   return MathMin(score, 25);
  }

//+------------------------------------------------------------------+
//| Score de timing (0-20)                                           |
//| Un sniper entre aux moments ou les institutionnels sont actifs    |
//+------------------------------------------------------------------+
int CTradeSniperEngine::ScoreTiming()
  {
   if(m_session_engine == NULL) return 0;

   int score = 0;
   ENUM_TRADING_SESSION session = m_session_engine.GetActiveSession();
   bool is_killzone = m_session_engine.IsKillZone();

   //--- Session de trading (10 pts)
   if(session == SESSION_OVERLAP_LN) score += 10;     // Overlap Londres/NY - le meilleur
   else if(session == SESSION_LONDON) score += 7;     // Session Londres
   else if(session == SESSION_NEWYORK) score += 5;    // Session NY
   else if(session == SESSION_ASIAN) score += 2;      // Asie (faible)

   //--- Kill Zone (10 pts)
   if(is_killzone) score += 10;

   return MathMin(score, 20);
  }

//+------------------------------------------------------------------+
//| Score de confluence (0-15)                                       |
//| Plus il y a de confluences, plus le signal est fiable            |
//+------------------------------------------------------------------+
int CTradeSniperEngine::ScoreConfluence(ENUM_SIGNAL_TYPE direction)
  {
   int confluences = 0;

   //--- Confluences institutionnelles
   if(m_order_blocks != NULL)
     {
      //--- OB dans la direction du trade
      if(direction == SIGNAL_BUY && m_order_blocks.GetBullishCount() > 0) confluences++;
      if(direction == SIGNAL_SELL && m_order_blocks.GetBearishCount() > 0) confluences++;
     }

   if(m_fvg_engine != NULL)
     {
      if(direction == SIGNAL_BUY && m_fvg_engine.GetBullishCount() > 0) confluences++;
      if(direction == SIGNAL_SELL && m_fvg_engine.GetBearishCount() > 0) confluences++;
     }

   if(m_liquidity_engine != NULL)
     {
      //--- Liquidite sweep dans la direction opposee
      for(int i = 0; i < m_liquidity_engine.GetZoneCount(); i++)
        {
         SLiquidityZone zone = m_liquidity_engine.GetZone(i);
         if(!zone.is_valid || !zone.is_swept) continue;
         if(direction == SIGNAL_BUY && (zone.type == LIQUIDITY_SSL || zone.type == LIQUIDITY_EQUAL_LOW)) confluences++;
         if(direction == SIGNAL_SELL && (zone.type == LIQUIDITY_BSL || zone.type == LIQUIDITY_EQUAL_HIGH)) confluences++;
         if(confluences >= 5) break;  // Pas besoin de plus
        }
     }

   //--- Multi-timeframe alignement
   if(m_market_structure != NULL && m_market_structure.IsMultiTimeframeAligned())
      confluences++;

   //--- Convertir en score (max 15)
   if(confluences >= 5) return 15;
   if(confluences >= 4) return 12;
   if(confluences >= 3) return 9;
   if(confluences >= 2) return 6;
   if(confluences >= 1) return 3;
   return 0;
  }

//+------------------------------------------------------------------+
//| Score de volume (0-15)                                           |
//| Le volume doit confirmer l'entree institutionnelle               |
//+------------------------------------------------------------------+
int CTradeSniperEngine::ScoreVolume()
  {
   if(m_volume_engine == NULL) return 5;  // Neutre si pas disponible

   int score = 0;

   //--- Volume au-dessus de la moyenne
   if(m_volume_engine.IsVolumeAboveAverage()) score += 5;

   //--- Volume institutionnel (2.5x la moyenne)
   //--- Utilise la methode disponible
   double volume_ratio = m_volume_engine.GetRelativeVolume();
   if(volume_ratio >= INSTITUTIONAL_VOL_MULT) score += 10;
   else if(volume_ratio >= DEFAULT_VOLUME_MULTIPLIER) score += 5;

   return MathMin(score, 15);
  }

//+------------------------------------------------------------------+
//| Calculer le SL structurel (pas juste ATR)                        |
//| Un sniper place son SL sous la structure, pas sous un indicateur |
//+------------------------------------------------------------------+
double CTradeSniperEngine::CalculateSniperSL(ENUM_SIGNAL_TYPE direction, double entry_price)
  {
   double sl = 0;
   double atr = (m_volatility_engine != NULL) ? m_volatility_engine.GetCurrentATR() : 0;
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   //--- 1. Essayer le SL structurel (sous le dernier swing)
   if(m_market_structure != NULL)
     {
      SMarketStructure m15 = m_market_structure.GetStructure(PERIOD_M15);

      if(direction == SIGNAL_BUY && m15.last_swing_low > 0)
        {
         //--- SL sous le swing low + buffer ATR
         double buffer = (atr > 0) ? atr * 0.2 : BE_MIN_OFFSET_PIPS * _Point;
         sl = NormalizeDouble(m15.last_swing_low - buffer, digits);
        }
      else if(direction == SIGNAL_SELL && m15.last_swing_high > 0)
        {
         double buffer = (atr > 0) ? atr * 0.2 : BE_MIN_OFFSET_PIPS * _Point;
         sl = NormalizeDouble(m15.last_swing_high + buffer, digits);
        }
     }

   //--- 2. Fallback: SL base sur ATR (1.5x ATR)
   if(sl <= 0 && atr > 0)
     {
      if(direction == SIGNAL_BUY)
         sl = NormalizeDouble(entry_price - atr * DEFAULT_ATR_MULTIPLIER, digits);
      else
         sl = NormalizeDouble(entry_price + atr * DEFAULT_ATR_MULTIPLIER, digits);
     }

   //--- 3. Dernier fallback: SL fixe
   if(sl <= 0)
     {
      double fixed_sl = MIN_SL_DISTANCE_PIPS * _Point;
      if(direction == SIGNAL_BUY)
         sl = NormalizeDouble(entry_price - fixed_sl, digits);
      else
         sl = NormalizeDouble(entry_price + fixed_sl, digits);
     }

   //--- Verifier la distance minimum
   double sl_distance = MathAbs(entry_price - sl);
   double min_distance = MIN_SL_DISTANCE_PIPS * _Point;
   long stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double broker_min = (double)MathMax(stops_level, (long)MIN_SL_DISTANCE_PIPS) * _Point;

   if(sl_distance < broker_min)
     {
      if(direction == SIGNAL_BUY)
         sl = NormalizeDouble(entry_price - broker_min, digits);
      else
         sl = NormalizeDouble(entry_price + broker_min, digits);
     }

   return sl;
  }

//+------------------------------------------------------------------+
//| Calculer les TP sniper                                           |
//+------------------------------------------------------------------+
double CTradeSniperEngine::CalculateSniperTP(ENUM_SIGNAL_TYPE direction, double entry_price, double sl, double r_multiple)
  {
   double risk = MathAbs(entry_price - sl);
   if(risk <= 0) return 0;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double tp;

   if(direction == SIGNAL_BUY)
      tp = NormalizeDouble(entry_price + risk * r_multiple, digits);
   else
      tp = NormalizeDouble(entry_price - risk * r_multiple, digits);

   return tp;
  }

//+------------------------------------------------------------------+
//| Calculer l'entree precise (sub-pip accuracy)                     |
//+------------------------------------------------------------------+
double CTradeSniperEngine::CalculatePrecisionEntry(ENUM_SIGNAL_TYPE direction, ENUM_SNIPER_ZONE zone, double zone_price)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double current_price = (direction == SIGNAL_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                           SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- Si on est dans une zone institutionnelle, utiliser le prix de la zone
   if(zone == SNIPER_ZONE_OB || zone == SNIPER_ZONE_FVG || zone == SNIPER_ZONE_CONFLUENCE)
     {
      //--- Ajuster legerement pour etre du bon cote de la zone
      double atr = (m_volatility_engine != NULL) ? m_volatility_engine.GetCurrentATR() : 0;
      double micro_offset = (atr > 0) ? atr * 0.05 : _Point;  // 5% de l'ATR = micro-offset

      if(direction == SIGNAL_BUY)
         return NormalizeDouble(zone_price + micro_offset, digits);  // Juste au-dessus
      else
         return NormalizeDouble(zone_price - micro_offset, digits);  // Juste en-dessous
     }

   //--- Sinon, prix actuel du marche
   return NormalizeDouble(current_price, digits);
  }

//+------------------------------------------------------------------+
//| Identifier la zone sniper                                        |
//+------------------------------------------------------------------+
ENUM_SNIPER_ZONE CTradeSniperEngine::IdentifySniperZone(ENUM_SIGNAL_TYPE direction, double &zone_price)
  {
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = (m_volatility_engine != NULL) ? m_volatility_engine.GetCurrentATR() : current_price * 0.001;
   zone_price = 0;

   bool has_ob = false, has_fvg = false, has_liq = false;
   double ob_price = 0, fvg_price = 0, liq_price = 0;

   //--- Verifier OB
   if(m_order_blocks != NULL)
     {
      int count = (direction == SIGNAL_BUY) ? m_order_blocks.GetBullishCount() : m_order_blocks.GetBearishCount();
      for(int i = 0; i < count; i++)
        {
         SOrderBlock ob = (direction == SIGNAL_BUY) ? m_order_blocks.GetBullishOB(i) :
                          m_order_blocks.GetBearishOB(i);
         if(!ob.is_valid || ob.state == OB_STATE_CONSUMED) continue;

         double ob_mid = (ob.high + ob.low) / 2.0;
         double distance = MathAbs(current_price - ob_mid) / atr;
         if(distance <= 1.0 && (ob_price == 0 || distance < MathAbs(current_price - ob_price) / atr))
           {
            has_ob = true;
            ob_price = ob_mid;
           }
        }
     }

   //--- Verifier FVG
   if(m_fvg_engine != NULL)
     {
      int count = (direction == SIGNAL_BUY) ? m_fvg_engine.GetBullishCount() : m_fvg_engine.GetBearishCount();
      for(int i = 0; i < count; i++)
        {
         SFVG fvg = (direction == SIGNAL_BUY) ? m_fvg_engine.GetBullishFVG(i) :
                     m_fvg_engine.GetBearishFVG(i);
         if(!fvg.is_valid || fvg.is_filled) continue;

         double fvg_mid = (fvg.high + fvg.low) / 2.0;
         double distance = MathAbs(current_price - fvg_mid) / atr;
         if(distance <= 1.0 && (fvg_price == 0 || distance < MathAbs(current_price - fvg_price) / atr))
           {
            has_fvg = true;
            fvg_price = fvg_mid;
           }
        }
     }

   //--- Verifier Liquidite
   if(m_liquidity_engine != NULL)
     {
      for(int i = 0; i < m_liquidity_engine.GetZoneCount(); i++)
        {
         SLiquidityZone zone = m_liquidity_engine.GetZone(i);
         if(!zone.is_valid) continue;

         double distance = MathAbs(current_price - zone.price) / atr;
         if(distance <= 1.5)
           {
            if((direction == SIGNAL_BUY && (zone.type == LIQUIDITY_SSL || zone.type == LIQUIDITY_EQUAL_LOW) && zone.is_swept) ||
               (direction == SIGNAL_SELL && (zone.type == LIQUIDITY_BSL || zone.type == LIQUIDITY_EQUAL_HIGH) && zone.is_swept))
              {
               has_liq = true;
               liq_price = zone.price;
               break;
              }
           }
        }
     }

   //--- Determiner la zone (confluence = multiple)
   int zone_count = (has_ob ? 1 : 0) + (has_fvg ? 1 : 0) + (has_liq ? 1 : 0);

   if(zone_count >= 2)
     {
      zone_price = (ob_price > 0 ? ob_price : fvg_price > 0 ? fvg_price : liq_price);
      return SNIPER_ZONE_CONFLUENCE;
     }
   if(has_ob) { zone_price = ob_price; return SNIPER_ZONE_OB; }
   if(has_fvg) { zone_price = fvg_price; return SNIPER_ZONE_FVG; }
   if(has_liq) { zone_price = liq_price; return SNIPER_ZONE_LIQUIDITY; }

   return SNIPER_ZONE_NONE;
  }

//+------------------------------------------------------------------+
//| Identifier le timing optimal                                     |
//+------------------------------------------------------------------+
ENUM_SNIPER_TIMING CTradeSniperEngine::IdentifyOptimalTiming()
  {
   if(m_session_engine == NULL) return SNIPER_TIMING_NONE;

   if(m_session_engine.IsKillZone())
     {
      ENUM_TRADING_SESSION session = m_session_engine.GetActiveSession();
      if(session == SESSION_OVERLAP_LN) return SNIPER_TIMING_OVERLAP;
      if(session == SESSION_LONDON) return SNIPER_TIMING_OPEN;
      if(session == SESSION_NEWYORK) return SNIPER_TIMING_OPEN;
     }

   return SNIPER_TIMING_KILLZONE;
  }

//+------------------------------------------------------------------+
//| Determiner la technique d'entree                                 |
//+------------------------------------------------------------------+
ENUM_ENTRY_TECHNIQUE CTradeSniperEngine::DetermineEntryTechnique(ENUM_SIGNAL_TYPE direction, ENUM_SNIPER_ZONE zone)
  {
   switch(zone)
     {
      case SNIPER_ZONE_OB:        return ENTRY_LIMIT_OB;
      case SNIPER_ZONE_FVG:       return ENTRY_LIMIT_FVG;
      case SNIPER_ZONE_CONFLUENCE: return ENTRY_LIMIT_OB;
      default:                     return ENTRY_MARKET;
     }
  }

//+------------------------------------------------------------------+
//| Valider l'entree sniper                                          |
//+------------------------------------------------------------------+
bool CTradeSniperEngine::ValidateSniperEntry(ENUM_SIGNAL_TYPE direction, double entry_price)
  {
   //--- Verifier que le spread est acceptable
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   if(spread > MAX_SPREAD_POINTS * _Point) return false;

   //--- v5: ATR minimum reduit - l'ancien seuil 0.0005 bloquait trop de signaux
   //--- EURUSD M15 ATR peut descendre a 0.0003 en periode calme
   if(m_volatility_engine != NULL)
     {
      double atr = m_volatility_engine.GetCurrentATR();
      //--- v5: ATR minimum reduit de 0.0005 a 0.0001
      if(atr <= 0 || atr < 0.0001) return false;
      //--- v5: Ne plus bloquer sur IsVolatilityAcceptable()
      //--- La volatilité basse n'est pas un motif de blocage,
      //--- c'est un motif de réduction de score (déjà géré dans le scoring)
     }

   //--- Verifier qu'on n'a pas deja une position
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic != (long)A2SNIPER_MAGIC) continue;
      long pos_type = PositionGetInteger(POSITION_TYPE);
      if(direction == SIGNAL_BUY && pos_type == POSITION_TYPE_BUY) return false;
      if(direction == SIGNAL_SELL && pos_type == POSITION_TYPE_SELL) return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Valider le micro-timing                                          |
//+------------------------------------------------------------------+
bool CTradeSniperEngine::ValidateMicroTiming(ENUM_SIGNAL_TYPE direction)
  {
   if(!m_require_killzone) return true;
   if(m_session_engine == NULL) return true;

   //--- FIX v4.3: Assouplir le filtre Kill Zone
   //--- L'ancienne version bloquait TOUT en dehors des Kill Zones
   //--- Maintenant: accepter pendant Kill Zone OU session de trading active
   //--- Les sessions London + NY sont aussi valides (pas seulement Kill Zones)
   bool is_killzone = m_session_engine.IsKillZone();
   bool is_optimal = m_session_engine.IsOptimalTradingTime();
   bool is_london = m_session_engine.IsLondonSession();
   bool is_newyork = m_session_engine.IsNewYorkSession();
   bool is_asian = m_session_engine.IsAsianSession();

   //--- Kill Zone = toujours OK
   if(is_killzone || is_optimal) return true;

   //--- FIX v4.3: Sessions London/NY aussi acceptees (meme hors Kill Zone)
   if(is_london || is_newyork) return true;

   //--- Session asiatique: seulement pour paires JPY/AUD/NZD
   if(is_asian)
     {
      string sym = _Symbol;
      if(StringFind(sym, "JPY") >= 0 || StringFind(sym, "AUD") >= 0 || StringFind(sym, "NZD") >= 0)
         return true;
      return false;  // Asie sans paire asiatique = bloquer
     }

   //--- Hors session: bloquer
   return false;
  }

//+------------------------------------------------------------------+
//| Valider l'empreinte institutionnelle v4                           |
//| FIX v4: Exige OB OU FVG + HTF confluence de preference           |
//| Un signal sans OB/FVG = entree aveugle = perte probable          |
//+------------------------------------------------------------------+
bool CTradeSniperEngine::ValidateInstitutionalFootprint(ENUM_SIGNAL_TYPE direction)
  {
   bool has_ob = false, has_fvg = false, has_liq_sweep = false;
   bool has_htf_ob = false;
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- FIX v4.2: Price must BE at OB, not just OB exist somewhere
   if(m_order_blocks != NULL)
     {
      ENUM_OB_TYPE ob_type = (direction == SIGNAL_BUY) ? OB_BULLISH : OB_BEARISH;
      has_ob = m_order_blocks.IsPriceAtOB(current_price, ob_type);

      //--- v4: Verifier aussi OB HTF (H1/H4) - beaucoup plus puissant
      has_htf_ob = m_order_blocks.IsPriceAtHTFOB(current_price, ob_type);
     }

   //--- FIX v4.2: Price must BE in FVG, not just FVG exist somewhere
   if(m_fvg_engine != NULL)
     {
      ENUM_FVG_TYPE fvg_type = (direction == SIGNAL_BUY) ? FVG_BULLISH : FVG_BEARISH;
      has_fvg = m_fvg_engine.IsPriceInFVG(current_price, fvg_type);
     }

   //--- Verifier liquidity sweep
   if(m_liquidity_engine != NULL)
     {
      for(int i = 0; i < m_liquidity_engine.GetZoneCount(); i++)
        {
         SLiquidityZone zone = m_liquidity_engine.GetZone(i);
         if(!zone.is_valid || !zone.is_swept) continue;
         if((direction == SIGNAL_BUY && (zone.type == LIQUIDITY_SSL || zone.type == LIQUIDITY_EQUAL_LOW)) ||
            (direction == SIGNAL_SELL && (zone.type == LIQUIDITY_BSL || zone.type == LIQUIDITY_EQUAL_HIGH)))
           {
            has_liq_sweep = true;
            break;
           }
        }
     }

   //--- v4: Exiger au minimum OB ou FVG (pas juste un sweep)
   //--- Un signal sans zone institutionnelle = entree aveugle
   bool has_zone = (has_ob || has_fvg);

   //--- Si on a un OB HTF, c'est un bonus majeur
   if(has_htf_ob && has_zone)
      return true;   // Confluence M15 + HTF = tres fort

   //--- Si on a OB + FVG + sweep = confluence maximale
   if(has_ob && has_fvg && has_liq_sweep)
      return true;   // Triple confluence

   //--- Si on a seulement une zone + sweep = acceptable
   if(has_zone && has_liq_sweep)
      return true;

   //--- Si on a seulement un OB ou FVG (sans sweep) = acceptable mais moins fort
   if(has_zone)
      return true;   // Minimum acceptable

   //--- Si on a seulement un sweep sans zone = dangereux
   //--- Le prix peut continuer dans la direction du sweep
   if(has_liq_sweep && !has_zone)
      return false;  // v4: REJET - sweep sans zone = piege

   return false;
  }

//+------------------------------------------------------------------+
//| Chasser un signal sniper - FONCTION PRINCIPALE                   |
//+------------------------------------------------------------------+
SSniperSignal CTradeSniperEngine::HuntSniperSignal(ENUM_SIGNAL_TYPE direction)
  {
   SSniperSignal signal;
   ZeroMemory(signal);
   signal.direction = direction;
   signal.is_valid = false;
   signal.signal_time = TimeCurrent();

   if(!m_initialized) return signal;

   m_total_signals++;

   //--- 1. Validation prealable (seuls les filtres durs restent bloquants)
   //--- v5: ValidateSniperEntry verifie spread/ATR/volatilité - reste bloquant
   if(!ValidateSniperEntry(direction, SymbolInfoDouble(_Symbol, SYMBOL_BID)))
      return signal;

   //--- v5: ValidateMicroTiming et ValidateInstitutionalFootprint ne sont PLUS bloquants
   //--- Ils affectent le score (bonus/malus) mais ne bloquent plus le signal
   bool has_micro_timing = ValidateMicroTiming(direction);
   bool has_institutional = ValidateInstitutionalFootprint(direction);

   //--- 2. Calcul des scores detailles
   double zone_price = 0;
   signal.score_structure = ScoreStructure(direction);
   signal.score_zone = ScoreZone(direction, zone_price, signal.stop_loss);
   signal.score_timing = ScoreTiming();
   signal.score_confluence = ScoreConfluence(direction);
   signal.score_volume = ScoreVolume();

   //--- v5: Appliquer les bonus/malus pour micro-timing et empreinte institutionnelle
   //--- Au lieu de bloquer, on ajuste le score
   if(!has_micro_timing)     signal.score_timing -= 5;    // Pas de timing optimal = -5
   if(!has_institutional)    signal.score_zone -= 8;      // Pas d'empreinte inst. = -8
   if(has_institutional)     signal.score_zone += 3;      // Empreinte inst. = +3 bonus
   if(has_micro_timing)      signal.score_timing += 3;    // Timing optimal = +3 bonus

   //--- Clamper les scores
   signal.score_structure = MathMax(0, MathMin(25, signal.score_structure));
   signal.score_zone = MathMax(0, MathMin(25, signal.score_zone));
   signal.score_timing = MathMax(0, MathMin(20, signal.score_timing));
   signal.score_confluence = MathMax(0, MathMin(15, signal.score_confluence));
   signal.score_volume = MathMax(0, MathMin(15, signal.score_volume));

   //--- 3. Score total
   signal.sniper_score = signal.score_structure + signal.score_zone +
                          signal.score_timing + signal.score_confluence + signal.score_volume;

   //--- 4. Identification de la zone
   double identified_zone_price = 0;
   signal.zone_type = IdentifySniperZone(direction, identified_zone_price);
   if(zone_price <= 0) zone_price = identified_zone_price;

   //--- 5. Identification du timing
   signal.timing = IdentifyOptimalTiming();

   //--- v5: Si pas de timing institutionnel, mettre le timing identifie
   if(!has_micro_timing && signal.timing == SNIPER_TIMING_NONE)
     {
      //--- Essayer de trouver au moins un timing de session
      if(m_session_engine != NULL)
        {
         if(m_session_engine.IsLondonSession()) signal.timing = SNIPER_TIMING_OPEN;
         else if(m_session_engine.IsNewYorkSession()) signal.timing = SNIPER_TIMING_OPEN;
        }
     }

   //--- 6. Calcul de l'entree precise
   signal.entry_price = CalculatePrecisionEntry(direction, signal.zone_type, zone_price);
   if(signal.entry_price <= 0)
      signal.entry_price = (direction == SIGNAL_BUY) ?
                            SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                            SymbolInfoDouble(_Symbol, SYMBOL_BID);

   //--- 7. Technique d'entree
   signal.entry_technique = DetermineEntryTechnique(direction, signal.zone_type);

   //--- 8. Calcul du SL structurel
   signal.stop_loss = CalculateSniperSL(direction, signal.entry_price);

   //--- v5: Si SL invalide, calculer un SL par defaut base sur l'ATR
   if(signal.stop_loss <= 0 || MathAbs(signal.entry_price - signal.stop_loss) < _Point * MIN_SL_DISTANCE_PIPS)
     {
      double atr = 0;
      if(m_volatility_engine != NULL) atr = m_volatility_engine.GetCurrentATR();
      if(atr > 0)
        {
         double sl_distance = atr * 1.5;
         if(direction == SIGNAL_BUY)
            signal.stop_loss = NormalizeDouble(signal.entry_price - sl_distance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
         else
            signal.stop_loss = NormalizeDouble(signal.entry_price + sl_distance, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
        }
      else
        {
         //--- Dernier recours: SL fixe de 30 pips
         double fixed_sl = 30 * _Point * 10;
         if(direction == SIGNAL_BUY)
            signal.stop_loss = NormalizeDouble(signal.entry_price - fixed_sl, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
         else
            signal.stop_loss = NormalizeDouble(signal.entry_price + fixed_sl, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
        }
     }

   //--- 9. Calcul des TP (1R, 2R, 3R)
   signal.tp1 = CalculateSniperTP(direction, signal.entry_price, signal.stop_loss, TP1_R_MULT);
   signal.tp2 = CalculateSniperTP(direction, signal.entry_price, signal.stop_loss, TP2_R_MULT);
   signal.tp3 = CalculateSniperTP(direction, signal.entry_price, signal.stop_loss, TP3_R_MULT);

   //--- 10. Ratio R:R
   double risk = MathAbs(signal.entry_price - signal.stop_loss);
   double reward = MathAbs(signal.tp2 - signal.entry_price);
   signal.risk_reward = (risk > 0) ? reward / risk : 0;

   //--- v5: Si R:R < 1.0, recalculer les TP pour assurer au minimum 1.5R
   if(signal.risk_reward < 1.0 && risk > 0)
     {
      signal.tp1 = CalculateSniperTP(direction, signal.entry_price, signal.stop_loss, 1.0);
      signal.tp2 = CalculateSniperTP(direction, signal.entry_price, signal.stop_loss, 1.5);
      signal.tp3 = CalculateSniperTP(direction, signal.entry_price, signal.stop_loss, 2.0);
      signal.risk_reward = 1.5;
     }

   //--- 11. Classification du signal
   if(signal.sniper_score >= 95)
      signal.quality = SNIPER_QUALITY_DIAMOND;
   else if(signal.sniper_score >= 90)
      signal.quality = SNIPER_QUALITY_GOLD;
   else if(signal.sniper_score >= 80)
      signal.quality = SNIPER_QUALITY_SILVER;
   else if(signal.sniper_score >= 70)
      signal.quality = SNIPER_QUALITY_BRONZE;
   else
      signal.quality = SNIPER_QUALITY_REJECT;

   //--- 12. Validation finale v5 - ASSOPLIE
   //--- v5: Seuil minimum = 30 (tres bas) au lieu de 70+
   //--- Le score composite dans le pipeline principal fera le tri
   bool score_ok = (signal.sniper_score >= 30);  // v5: Seuil tres bas, le composite decide
   bool has_sl = (signal.stop_loss > 0);
   bool has_entry = (signal.entry_price > 0);

   signal.is_valid = score_ok && has_sl && has_entry;

   signal.confidence = (signal.sniper_score >= 90) ? 95.0 :
                       (signal.sniper_score >= 80) ? 85.0 :
                       (signal.sniper_score >= 70) ? 75.0 :
                       (signal.sniper_score >= 50) ? 60.0 : 40.0;

   //--- 13. Description
   signal.description = StringFormat("Sniper %s | Score=%d (%s) | R:R=%.1f | Zone=%s | Timing=%s | Tech=%s",
                                      (direction == SIGNAL_BUY) ? "BUY" : "SELL",
                                      signal.sniper_score,
                                      (signal.quality == SNIPER_QUALITY_DIAMOND) ? "DIAMOND" :
                                      (signal.quality == SNIPER_QUALITY_GOLD) ? "GOLD" :
                                      (signal.quality == SNIPER_QUALITY_SILVER) ? "SILVER" :
                                      (signal.quality == SNIPER_QUALITY_BRONZE) ? "BRONZE" : "WEAK",
                                      signal.risk_reward,
                                      (signal.zone_type == SNIPER_ZONE_CONFLUENCE) ? "Confluence" :
                                      (signal.zone_type == SNIPER_ZONE_OB) ? "OB" :
                                      (signal.zone_type == SNIPER_ZONE_FVG) ? "FVG" : "None",
                                      (signal.timing == SNIPER_TIMING_OVERLAP) ? "Overlap" :
                                      (signal.timing == SNIPER_TIMING_KILLZONE) ? "KillZone" : "Session",
                                      (signal.entry_technique == ENTRY_LIMIT_OB) ? "LimitOB" :
                                      (signal.entry_technique == ENTRY_LIMIT_FVG) ? "LimitFVG" : "Market");

   //--- Statistiques
   if(signal.is_valid)
     {
      if(signal.quality >= SNIPER_QUALITY_GOLD) m_sniper_signals++;
      if(signal.quality >= SNIPER_QUALITY_DIAMOND) m_diamond_signals++;
     }

   m_last_signal = signal;

   return signal;
  }

//+------------------------------------------------------------------+
//| Verifier si une entree sniper est prete                          |
//+------------------------------------------------------------------+
bool CTradeSniperEngine::IsSniperEntryReady(ENUM_SIGNAL_TYPE direction)
  {
   if(!m_initialized) return false;

   //--- Verification rapide sans calcul complet
   if(!ValidateSniperEntry(direction, SymbolInfoDouble(_Symbol, SYMBOL_BID))) return false;
   if(!ValidateMicroTiming(direction)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Taux de reussite sniper                                          |
//+------------------------------------------------------------------+
double CTradeSniperEngine::GetSniperWinRate() const
  {
   if(m_executed_trades <= 0) return 0;
   return (double)m_winning_trades / m_executed_trades * 100.0;
  }

//+------------------------------------------------------------------+
//| Info sniper                                                      |
//+------------------------------------------------------------------+
string CTradeSniperEngine::GetSniperInfo() const
  {
   return StringFormat("Sniper: Total=%d Sniper=%d Diamond=%d WinRate=%.1f%% | MinScore=%d MinRR=%.1f",
                       m_total_signals, m_sniper_signals, m_diamond_signals,
                       GetSniperWinRate(), m_min_sniper_score, m_min_rr_ratio);
  }

#endif // A2SNIPER_TRADE_SNIPER_ENGINE_MQH
//+------------------------------------------------------------------+
