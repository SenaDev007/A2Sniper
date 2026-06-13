//+------------------------------------------------------------------+
//| StrategicReversalEngine.mqh - Moteur de Retournement Strategique |
//| A2Sniper Ultimate v3.1                                           |
//| FIX: CHOCH direction bug, signal validity consistency,            |
//|      enhanced false breakout detection, minimum ATR filter        |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_SRE_MQH
#define A2SNIPER_SRE_MQH

#include "CommonTypes.mqh"
#include "MarketStructureEngine.mqh"
#include "OrderBlockEngine.mqh"
#include "FVGEngine.mqh"
#include "LiquidityEngine.mqh"

//+------------------------------------------------------------------+
//| Classe CStrategicReversalEngine                                   |
//+------------------------------------------------------------------+
class CStrategicReversalEngine
  {
private:
   bool              m_initialized;

   //--- References aux moteurs dependants
   CMarketStructureEngine *m_market_structure;
   COrderBlockEngine      *m_order_blocks;
   CFVGEngine             *m_fvg_engine;
   CLiquidityEngine       *m_liquidity_engine;
   int               m_atr_handle;            // Handle ATR persistant

   //--- Parametres
   double            m_indecision_body_ratio;   // Ratio max corps/total pour indecision (25%)
   int               m_false_break_lookback;    // Lookback pour fausse invalidation
   double            m_engulfing_min_ratio;     // Ratio min pour engulfing (1.2x)

   //--- Dernier signal
   SStrategicReversalSignal m_last_signal;

   //--- Methodes privees (5 etapes du SRE)
   int               EvaluateMarketDirection(const ENUM_SIGNAL_TYPE direction);  // Etape 1: 20 pts
   int               EvaluateIndecision(const ENUM_SIGNAL_TYPE direction);      // Etape 2: 15 pts
   int               EvaluateIsolatedZone(const ENUM_SIGNAL_TYPE direction);    // Etape 3: 20 pts
   int               EvaluateFalseInvalidation(const ENUM_SIGNAL_TYPE direction); // Etape 4: 25 pts
   int               EvaluateEngulfing(const ENUM_SIGNAL_TYPE direction);       // Etape 5: 20 pts

   //--- Sous-verifications
   bool              IsDojiCandle(const int bar_index) const;
   bool              IsSpinningTop(const int bar_index) const;
   bool              IsLongLeggedDoji(const int bar_index) const;
   ENUM_ENGULFING_TYPE DetectEngulfingPattern(const int bar_index) const;
   bool              HasFalseBreakout(const ENUM_SIGNAL_TYPE direction) const;
   bool              IsPriceInIsolatedZone(const ENUM_SIGNAL_TYPE direction) const;

public:
   //--- Constructeur / Destructeur
                     CStrategicReversalEngine();
                    ~CStrategicReversalEngine();

   //--- Initialisation
   bool              Initialize(CMarketStructureEngine *mse, COrderBlockEngine *obe,
                                 CFVGEngine *fvge, CLiquidityEngine *le);
   void              Deinitialize();

   //--- Analyse principale
   SStrategicReversalSignal AnalyzeSignal(const ENUM_SIGNAL_TYPE direction);

   //--- Accesseurs
   SStrategicReversalSignal GetLastSignal() const { return m_last_signal; }
   ENUM_SIGNAL_CLASS  ClassifySignal(const int score) const;

   //--- Info
   string            GetSignalInfo(const SStrategicReversalSignal &signal) const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CStrategicReversalEngine::CStrategicReversalEngine() :
   m_initialized(false),
   m_market_structure(NULL),
   m_order_blocks(NULL),
   m_fvg_engine(NULL),
   m_liquidity_engine(NULL),
   m_atr_handle(INVALID_HANDLE),
   m_indecision_body_ratio(INDECISION_BODY_RATIO),
   m_false_break_lookback(10),
   m_engulfing_min_ratio(1.2)
  {
   ZeroMemory(m_last_signal);
   m_last_signal.is_valid = false;
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CStrategicReversalEngine::~CStrategicReversalEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CStrategicReversalEngine::Initialize(CMarketStructureEngine *mse,
                                            COrderBlockEngine *obe,
                                            CFVGEngine *fvge,
                                            CLiquidityEngine *le)
  {
   if(mse == NULL || obe == NULL || fvge == NULL || le == NULL)
     {
      Print("A2Sniper SRE: Erreur - moteurs dependants NULL");
      return false;
     }

   m_market_structure = mse;
   m_order_blocks = obe;
   m_fvg_engine = fvge;
   m_liquidity_engine = le;

   m_atr_handle = iATR(_Symbol, PERIOD_CURRENT, DEFAULT_ATR_PERIOD);
   if(m_atr_handle == INVALID_HANDLE)
     {
      Print("A2Sniper SRE: Erreur creation ATR handle");
      return false;
     }

   m_initialized = true;
   Print("A2Sniper SRE: Strategic Reversal Engine initialise");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CStrategicReversalEngine::Deinitialize()
  {
   m_market_structure = NULL;
   m_order_blocks = NULL;
   m_fvg_engine = NULL;
   m_liquidity_engine = NULL;
   if(m_atr_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_atr_handle);
      m_atr_handle = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Etape 1: Sens du Marche (20 points)                              |
//| FIX: CHOCH ne doit donner 20 pts que si dans la bonne direction  |
//+------------------------------------------------------------------+
int CStrategicReversalEngine::EvaluateMarketDirection(const ENUM_SIGNAL_TYPE direction)
  {
   if(m_market_structure == NULL)
      return 0;

   //--- Verifier la direction sur le timeframe d'execution (M15)
   ENUM_MARKET_DIRECTION m15_dir = m_market_structure->GetDirection(PERIOD_M15);
   ENUM_MARKET_DIRECTION h1_dir  = m_market_structure->GetDirection(PERIOD_H1);
   ENUM_MARKET_DIRECTION h4_dir  = m_market_structure->GetDirection(PERIOD_H4);

   int score = 0;

   //--- FIX: CHOCH/MSS dans la bonne direction = score maximum
   //--- Un CHOCH haussier pour un signal BUY, un CHOCH baissier pour un signal SELL
   if(direction == SIGNAL_BUY)
     {
      //--- CHOCH haussier = signal fort d'achat
      if(m_market_structure->HasCHOCH(PERIOD_M15))
        {
         SMarketStructure m15_struct = m_market_structure->GetStructure(PERIOD_M15);
         if(m15_struct.last_event == STRUCTURE_CHOCH_BULLISH || m15_struct.last_event == STRUCTURE_MSS_BULLISH)
            return 20;  // Score maximum
        }

      //--- Structure haussiere sur M15
      if(m15_dir == MARKET_DIRECTION_BULLISH)
         score += 8;

      //--- Confirmation H1
      if(h1_dir == MARKET_DIRECTION_BULLISH)
         score += 6;

      //--- Confirmation H4 (bonus)
      if(h4_dir == MARKET_DIRECTION_BULLISH)
         score += 4;

      //--- BOS haussier detecte
      if(m_market_structure->HasBOS(PERIOD_M15))
         score += 2;
     }
   else if(direction == SIGNAL_SELL)
     {
      //--- CHOCH baissier = signal fort de vente
      if(m_market_structure->HasCHOCH(PERIOD_M15))
        {
         SMarketStructure m15_struct = m_market_structure->GetStructure(PERIOD_M15);
         if(m15_struct.last_event == STRUCTURE_CHOCH_BEARISH || m15_struct.last_event == STRUCTURE_MSS_BEARISH)
            return 20;  // Score maximum
        }

      if(m15_dir == MARKET_DIRECTION_BEARISH)
         score += 8;
      if(h1_dir == MARKET_DIRECTION_BEARISH)
         score += 6;
      if(h4_dir == MARKET_DIRECTION_BEARISH)
         score += 4;
      if(m_market_structure->HasBOS(PERIOD_M15))
         score += 2;
     }

   return MathMin(score, 20);
  }

//+------------------------------------------------------------------+
//| Etape 2: Bougie d'Indecision (15 points)                         |
//+------------------------------------------------------------------+
int CStrategicReversalEngine::EvaluateIndecision(const ENUM_SIGNAL_TYPE direction)
  {
   //--- Verifier les 3 dernieres bougies pour un pattern d'indecision
   for(int i = 1; i <= 3; i++)
     {
      if(IsDojiCandle(i))
         return 15; // Doji parfait
      if(IsLongLeggedDoji(i))
         return 15; // Long Legged Doji
      if(IsSpinningTop(i))
         return 12; // Spinning Top (score legerement inferieur)
     }

   //--- Verifier simplement le ratio corps/total
   double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);

   double total_range = high1 - low1;
   double body = MathAbs(close1 - open1);

   if(total_range > 0 && body / total_range <= m_indecision_body_ratio)
      return 10; // Indecision partielle

   return 0;
  }

//+------------------------------------------------------------------+
//| Etape 3: Zone Isolee (20 points)                                 |
//| FVG, Imbalance, Order Block frais, Breaker Block, Mitigation     |
//+------------------------------------------------------------------+
int CStrategicReversalEngine::EvaluateIsolatedZone(const ENUM_SIGNAL_TYPE direction)
  {
   if(m_order_blocks == NULL || m_fvg_engine == NULL)
      return 0;

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
   int score = 0;

   //--- Verifier Order Block frais
   ENUM_OB_TYPE ob_type = (direction == SIGNAL_BUY) ? OB_BULLISH : OB_BEARISH;
   if(m_order_blocks->IsPriceAtOB(current_price, ob_type))
     {
      double ob_score = m_order_blocks->GetOBScoreAtPrice(current_price, ob_type);
      score += (int)(ob_score * 0.12); // Max 12 points pour OB
     }

   //--- Verifier FVG
   ENUM_FVG_TYPE fvg_type = (direction == SIGNAL_BUY) ? FVG_BULLISH : FVG_BEARISH;
   if(m_fvg_engine->IsPriceInFVG(current_price, fvg_type))
     {
      double fvg_score = m_fvg_engine->GetFVGScoreAtPrice(current_price, fvg_type);
      score += (int)(fvg_score * 0.08); // Max 8 points pour FVG
     }

   return MathMin(score, 20);
  }

//+------------------------------------------------------------------+
//| Etape 4: Fausse Invalidation (25 points)                         |
//| Cassure + Prise de liquidite + Reintegration + Cloture opposee  |
//+------------------------------------------------------------------+
int CStrategicReversalEngine::EvaluateFalseInvalidation(const ENUM_SIGNAL_TYPE direction)
  {
   int score = 0;

   //--- Verifier le sweep de liquidite (composante majeure)
   if(m_liquidity_engine != NULL && m_liquidity_engine->HasLiquiditySweepForDirection(direction))
      score += 15;

   //--- Verifier la fausse cassure sur la structure recente
   if(HasFalseBreakout(direction))
      score += 10;

   return MathMin(score, 25);
  }

//+------------------------------------------------------------------+
//| Etape 5: Avalement (20 points)                                   |
//| Bullish Engulfing / Bearish Engulfing                            |
//+------------------------------------------------------------------+
int CStrategicReversalEngine::EvaluateEngulfing(const ENUM_SIGNAL_TYPE direction)
  {
   ENUM_ENGULFING_TYPE engulfing = DetectEngulfingPattern(1);

   if(direction == SIGNAL_BUY && engulfing == ENGULFING_BULLISH)
      return 20;
   if(direction == SIGNAL_SELL && engulfing == ENGULFING_BEARISH)
      return 20;

   //--- Verifier une bougie forte dans la direction (pas exactement engulfing mais forte)
   double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double open2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
   double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);

   if(direction == SIGNAL_BUY && close1 > open1)
     {
      double body1 = close1 - open1;
      double body2 = MathAbs(close2 - open2);
      if(body2 > 0 && body1 / body2 >= 1.5)
         return 12; // Forte bougie haussiere (pas engulfing complet)
     }
   if(direction == SIGNAL_SELL && close1 < open1)
     {
      double body1 = open1 - close1;
      double body2 = MathAbs(close2 - open2);
      if(body2 > 0 && body1 / body2 >= 1.5)
         return 12;
     }

   return 0;
  }

//+------------------------------------------------------------------+
//| Verifier si la bougie est un Doji                                |
//+------------------------------------------------------------------+
bool CStrategicReversalEngine::IsDojiCandle(const int bar_index) const
  {
   double open_p = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close_p = iClose(_Symbol, PERIOD_CURRENT, bar_index);
   double high_p = iHigh(_Symbol, PERIOD_CURRENT, bar_index);
   double low_p = iLow(_Symbol, PERIOD_CURRENT, bar_index);

   double total_range = high_p - low_p;
   double body = MathAbs(close_p - open_p);

   if(total_range <= 0) return false;

   //--- Doji: corps tres petit par rapport a la range
   return (body / total_range <= 0.1);
  }

//+------------------------------------------------------------------+
//| Verifier Spinning Top                                            |
//+------------------------------------------------------------------+
bool CStrategicReversalEngine::IsSpinningTop(const int bar_index) const
  {
   double open_p = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close_p = iClose(_Symbol, PERIOD_CURRENT, bar_index);
   double high_p = iHigh(_Symbol, PERIOD_CURRENT, bar_index);
   double low_p = iLow(_Symbol, PERIOD_CURRENT, bar_index);

   double total_range = high_p - low_p;
   double body = MathAbs(close_p - open_p);

   if(total_range <= 0) return false;

   //--- Spinning Top: petit corps au milieu, meches des deux cotes
   if(body / total_range > m_indecision_body_ratio)
      return false;

   double upper_wick = high_p - MathMax(open_p, close_p);
   double lower_wick = MathMin(open_p, close_p) - low_p;

   //--- Les deux meches doivent etre significatives
   return (upper_wick > body * 1.5 && lower_wick > body * 1.5);
  }

//+------------------------------------------------------------------+
//| Verifier Long Legged Doji                                        |
//+------------------------------------------------------------------+
bool CStrategicReversalEngine::IsLongLeggedDoji(const int bar_index) const
  {
   double open_p = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close_p = iClose(_Symbol, PERIOD_CURRENT, bar_index);
   double high_p = iHigh(_Symbol, PERIOD_CURRENT, bar_index);
   double low_p = iLow(_Symbol, PERIOD_CURRENT, bar_index);

   double total_range = high_p - low_p;
   double body = MathAbs(close_p - open_p);

   if(total_range <= 0) return false;

   //--- Long Legged Doji: corps minuscule, longues meches
   if(body / total_range > 0.05)
      return false;

   double upper_wick = high_p - MathMax(open_p, close_p);
   double lower_wick = MathMin(open_p, close_p) - low_p;

   //--- Longues meches relativement au corps
   return (upper_wick > body * 5 && lower_wick > body * 5);
  }

//+------------------------------------------------------------------+
//| Detection du pattern Engulfing                                   |
//+------------------------------------------------------------------+
ENUM_ENGULFING_TYPE CStrategicReversalEngine::DetectEngulfingPattern(const int bar_index) const
  {
   if(bar_index < 1)
      return ENGULFING_NONE;

   double open1 = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, bar_index);
   double open2 = iOpen(_Symbol, PERIOD_CURRENT, bar_index + 1);
   double close2 = iClose(_Symbol, PERIOD_CURRENT, bar_index + 1);

   double body1 = MathAbs(close1 - open1);
   double body2 = MathAbs(close2 - open2);

   if(body2 <= 0)
      return ENGULFING_NONE;

   //--- Bullish Engulfing: bougie 2 baissiere, bougie 1 haussiere et englobe
   if(close2 < open2 && // Bougie 2 baissiere
      close1 > open1 && // Bougie 1 haussiere
      close1 > open2 && // Cloture au-dessus de l'ouverture de 2
      open1 < close2 && // Ouverture en-dessous de la cloture de 2
      body1 / body2 >= m_engulfing_min_ratio) // Corps plus grand
     {
      return ENGULFING_BULLISH;
     }

   //--- Bearish Engulfing: bougie 2 haussiere, bougie 1 baissiere et englobe
   if(close2 > open2 && // Bougie 2 haussiere
      close1 < open1 && // Bougie 1 baissiere
      close1 < open2 && // Cloture en-dessous de l'ouverture de 2
      open1 > close2 && // Ouverture au-dessus de la cloture de 2
      body1 / body2 >= m_engulfing_min_ratio)
     {
      return ENGULFING_BEARISH;
     }

   return ENGULFING_NONE;
  }

//+------------------------------------------------------------------+
//| Verifier fausse cassure                                          |
//| FIX: Detection amelioree - verifier la reintegration complete    |
//+------------------------------------------------------------------+
bool CStrategicReversalEngine::HasFalseBreakout(const ENUM_SIGNAL_TYPE direction) const
  {
   double current_close = iClose(_Symbol, PERIOD_CURRENT, 0);
   double atr = 0;

   //--- Obtenir ATR pour le filtrage
   double atr_buf[];
   ArraySetAsSeries(atr_buf, true);
   if(m_atr_handle != INVALID_HANDLE && CopyBuffer(m_atr_handle, 0, 0, 1, atr_buf) > 0)
      atr = atr_buf[0];

   for(int i = 1; i <= m_false_break_lookback; i++)
     {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);
      double close = iClose(_Symbol, PERIOD_CURRENT, i);
      double open = iOpen(_Symbol, PERIOD_CURRENT, i);

      if(direction == SIGNAL_BUY)
        {
         //--- Fausse cassure baissiere: le prix a casse un support mais a clotre au-dessus
         //--- FIX: Verifier que la cassure est significative (au moins 0.3 ATR sous le support)
         if(i + 1 < iBars(_Symbol, PERIOD_CURRENT))
           {
            double prev_low = iLow(_Symbol, PERIOD_CURRENT, i + 1);
            //--- La meche basse a depasse le precedent low, mais cloture au-dessus
            if(low < prev_low && close > prev_low)
              {
               //--- Verifier que la cassure etait significative (pas juste un pic)
               double break_distance = prev_low - low;
               if(atr > 0 && break_distance >= atr * 0.2)
                  return true;
               else if(atr <= 0)  // Pas d'ATR, utiliser la detection simple
                  return true;
              }
           }
        }
      else
        {
         if(i + 1 < iBars(_Symbol, PERIOD_CURRENT))
           {
            double prev_high = iHigh(_Symbol, PERIOD_CURRENT, i + 1);
            if(high > prev_high && close < prev_high)
              {
               double break_distance = high - prev_high;
               if(atr > 0 && break_distance >= atr * 0.2)
                  return true;
               else if(atr <= 0)
                  return true;
              }
           }
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Prix dans une zone isolee ?                                      |
//+------------------------------------------------------------------+
bool CStrategicReversalEngine::IsPriceInIsolatedZone(const ENUM_SIGNAL_TYPE direction) const
  {
   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   ENUM_OB_TYPE ob_type = (direction == SIGNAL_BUY) ? OB_BULLISH : OB_BEARISH;
   if(m_order_blocks != NULL && m_order_blocks->IsPriceAtOB(current_price, ob_type))
      return true;

   ENUM_FVG_TYPE fvg_type = (direction == SIGNAL_BUY) ? FVG_BULLISH : FVG_BEARISH;
   if(m_fvg_engine != NULL && m_fvg_engine->IsPriceInFVG(current_price, fvg_type))
      return true;

   return false;
  }

//+------------------------------------------------------------------+
//| Analyse principale - Genere le signal                            |
//| FIX: Validite coherente avec la classification                   |
//+------------------------------------------------------------------+
SStrategicReversalSignal CStrategicReversalEngine::AnalyzeSignal(const ENUM_SIGNAL_TYPE direction)
  {
   SStrategicReversalSignal signal;
   ZeroMemory(signal);
   signal.signal_type = SIGNAL_NONE;
   signal.is_valid = false;

   if(!m_initialized)
      return signal;

   //--- FIX: Verifier le filtre ATR minimum (eviter les signaux en basse volatilite)
   double atr_value = 0;
   if(m_atr_handle != INVALID_HANDLE)
     {
      double atr_buf[];
      ArraySetAsSeries(atr_buf, true);
      if(CopyBuffer(m_atr_handle, 0, 0, 1, atr_buf) > 0)
         atr_value = atr_buf[0];
     }

   //--- Evaluer les 5 etapes
   signal.score_sens = EvaluateMarketDirection(direction);
   signal.score_indecision = EvaluateIndecision(direction);
   signal.score_zone = EvaluateIsolatedZone(direction);
   signal.score_false_break = EvaluateFalseInvalidation(direction);
   signal.score_engulfing = EvaluateEngulfing(direction);

   //--- Score total
   signal.total_score = signal.score_sens + signal.score_indecision +
                         signal.score_zone + signal.score_false_break +
                         signal.score_engulfing;

   //--- CRITICAL: La Fausse Invalidation (sweep de liquidite) est OBLIGATOIRE
   //--- pour un signal Sniper (SRE >= 90). Sans sweep, le score max est plafonne.
   if(signal.score_false_break < 10) // Pas de sweep significatif
     {
      signal.total_score = MathMin(signal.total_score, MIN_SIGNAL_SCORE_STANDARD - 1); // Max 79
     }
   else if(signal.score_false_break < 15) // Sweep partiel
     {
      signal.total_score = MathMin(signal.total_score, 89); // Max Standard
     }

   //--- FIX: Filtre ATR minimum - ne pas generer de signal si volatilite trop basse
   if(atr_value > 0 && atr_value < MIN_ATR_FOR_TRADE)
     {
      signal.total_score = 0;
      signal.is_valid = false;
      signal.signal_type = SIGNAL_NONE;
      return signal;
     }

   //--- Classification
   signal.classification = ClassifySignal(signal.total_score);

   //--- FIX: Validite coherente avec la classification
   //--- Sniper/Elite = valide, Standard = valide si score >= 80, Weak = invalide
   if(signal.total_score >= MIN_SIGNAL_SCORE_SNIPER)
      signal.is_valid = true;
   else if(signal.total_score >= MIN_SIGNAL_SCORE_STANDARD)
      signal.is_valid = true;   // FIX: Standard est aussi valide (mais avec caution)
   else
      signal.is_valid = false;  // Weak n'est pas valide

   //--- Direction: signal_type est defini si le score est >= STANDARD
   if(signal.total_score >= MIN_SIGNAL_SCORE_STANDARD)
      signal.signal_type = direction;

   //--- Calculer les niveaux SL/TP
   if(signal.signal_type != SIGNAL_NONE)
     {
      double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
      signal.entry_price = current_price;
      signal.time = TimeCurrent();

      //--- SL base sur ATR
      if(m_atr_handle != INVALID_HANDLE)
        {
         double atr_buf[];
         ArraySetAsSeries(atr_buf, true);
         if(CopyBuffer(m_atr_handle, 0, 0, 1, atr_buf) > 0)
           {
            double atr = atr_buf[0];
            double sl_distance = atr * DEFAULT_ATR_MULTIPLIER;

            if(direction == SIGNAL_BUY)
              {
               signal.stop_loss = current_price - sl_distance;
               signal.take_profit_1 = current_price + sl_distance * TP1_R_MULT;
               signal.take_profit_2 = current_price + sl_distance * TP2_R_MULT;
               signal.take_profit_3 = current_price + sl_distance * TP3_R_MULT;
              }
            else
              {
               signal.stop_loss = current_price + sl_distance;
               signal.take_profit_1 = current_price - sl_distance * TP1_R_MULT;
               signal.take_profit_2 = current_price - sl_distance * TP2_R_MULT;
               signal.take_profit_3 = current_price - sl_distance * TP3_R_MULT;
              }
           }
        }
     }

   //--- Sauvegarder
   m_last_signal = signal;

   return signal;
  }

//+------------------------------------------------------------------+
//| Classification du signal                                         |
//+------------------------------------------------------------------+
ENUM_SIGNAL_CLASS CStrategicReversalEngine::ClassifySignal(const int score) const
  {
   if(score >= 100)
      return SIGNAL_CLASS_ELITE;
   if(score >= 90)
      return SIGNAL_CLASS_SNIPER;
   if(score >= 80)
      return SIGNAL_CLASS_STANDARD;
   if(score >= 70)
      return SIGNAL_CLASS_WEAK;
   return SIGNAL_CLASS_NONE;
  }

//+------------------------------------------------------------------+
//| Info signal                                                      |
//+------------------------------------------------------------------+
string CStrategicReversalEngine::GetSignalInfo(const SStrategicReversalSignal &signal) const
  {
   string class_str = "";
   switch(signal.classification)
     {
      case SIGNAL_CLASS_ELITE:    class_str = "ELITE"; break;
      case SIGNAL_CLASS_SNIPER:   class_str = "SNIPER"; break;
      case SIGNAL_CLASS_STANDARD: class_str = "STANDARD"; break;
      case SIGNAL_CLASS_WEAK:     class_str = "WEAK"; break;
      default:                    class_str = "NONE"; break;
     }

   string dir_str = (signal.signal_type == SIGNAL_BUY) ? "BUY" :
                     (signal.signal_type == SIGNAL_SELL) ? "SELL" : "NONE";

   return StringFormat("SRE[%s %s]: Score=%d/100 (Sens=%d Indec=%d Zone=%d FalseBrk=%d Engulf=%d) | SL=%.5f TP1=%.5f TP2=%.5f TP3=%.5f | Valid=%s",
                       dir_str, class_str, signal.total_score,
                       signal.score_sens, signal.score_indecision, signal.score_zone,
                       signal.score_false_break, signal.score_engulfing,
                       signal.stop_loss, signal.take_profit_1, signal.take_profit_2,
                       signal.take_profit_3, signal.is_valid ? "Y" : "N");
  }

#endif // A2SNIPER_SRE_MQH
//+------------------------------------------------------------------+
