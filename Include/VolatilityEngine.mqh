//+------------------------------------------------------------------+
//| VolatilityEngine.mqh - Analyse de la Volatilité v4.0              |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| v4: Graduated scoring, volatility momentum, expansion/contraction  |
//|     detection, negative scoring for dangerous conditions           |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_VOLATILITY_MQH
#define A2SNIPER_VOLATILITY_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Classe CVolatilityEngine v4                                       |
//+------------------------------------------------------------------+
class CVolatilityEngine
  {
private:
   bool              m_initialized;
   int               m_atr_period;
   int               m_atr_handle;
   double            m_atr_buffer[];

   //--- Seuils
   double            m_min_atr_multiplier;   // Volatilité minimale pour trader
   double            m_max_atr_multiplier;   // Volatilité maximale (trop volatile = danger)
   int               m_avg_atr_period;       // Période pour ATR moyen

   //--- État
   double            m_current_atr;
   double            m_average_atr;
   double            m_atr_ratio;            // ATR actuel / ATR moyen

   //--- v4: Momentum de volatilité (expansion vs contraction)
   double            m_prev_atr_ratio;       // Ratio ATR précédent
   double            m_atr_momentum;         // Taux de changement de l'ATR
   bool              m_expanding;            // Volatilité en expansion
   bool              m_contracting;          // Volatilité en contraction

   //--- v4: Percentile de volatilité
   double            m_atr_percentile;       // Où se situe l'ATR actuel (0-100)

public:
   //--- Constructeur / Destructeur
                     CVolatilityEngine();
                    ~CVolatilityEngine();

   //--- Initialisation
   bool              Initialize(int atr_period = 14, double min_mult = 0.5, double max_mult = 3.0);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   double            GetCurrentATR() const { return m_current_atr; }
   double            GetAverageATR() const { return m_average_atr; }
   double            GetATRRatio() const { return m_atr_ratio; }
   double            GetATRMomentum() const { return m_atr_momentum; }
   double            GetATRPercentile() const { return m_atr_percentile; }
   bool              IsExpanding() const { return m_expanding; }
   bool              IsContracting() const { return m_contracting; }

   //--- Vérifications
   bool              IsVolatilityAcceptable() const;
   bool              IsVolatilityTooLow() const;
   bool              IsVolatilityTooHigh() const;
   bool              IsVolatilityAverage() const;
   bool              IsVolatilityExtreme() const;
   double            GetVolatilityScore() const;

   //--- Calcul SL/TP basé sur ATR
   double            CalculateATRStopLoss(const ENUM_SIGNAL_TYPE direction, double multiplier = 1.5) const;
   double            CalculateATRTakeProfit(const ENUM_SIGNAL_TYPE direction, double rr_ratio = 3.0, double sl_distance = 0.0) const;

   //--- Info
   string            GetVolatilityInfo() const;

private:
   double            CalculateATRPercentile();
   void              UpdateMomentum();
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CVolatilityEngine::CVolatilityEngine() :
   m_initialized(false),
   m_atr_period(DEFAULT_ATR_PERIOD),
   m_atr_handle(INVALID_HANDLE),
   m_min_atr_multiplier(0.5),
   m_max_atr_multiplier(3.0),
   m_avg_atr_period(50),
   m_current_atr(0),
   m_average_atr(0),
   m_atr_ratio(1.0),
   m_prev_atr_ratio(1.0),
   m_atr_momentum(0),
   m_expanding(false),
   m_contracting(false),
   m_atr_percentile(50.0)
  {
   ArraySetAsSeries(m_atr_buffer, true);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CVolatilityEngine::~CVolatilityEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CVolatilityEngine::Initialize(int atr_period, double min_mult, double max_mult)
  {
   m_atr_period = (atr_period > 5) ? atr_period : DEFAULT_ATR_PERIOD;
   m_min_atr_multiplier = (min_mult > 0) ? min_mult : 0.5;
   m_max_atr_multiplier = (max_mult > min_mult) ? max_mult : 3.0;

   m_atr_handle = iATR(_Symbol, PERIOD_CURRENT, m_atr_period);
   if(m_atr_handle == INVALID_HANDLE)
     {
      Print("A2Sniper VolE: Erreur création ATR - ", GetLastError());
      return false;
     }

   ArraySetAsSeries(m_atr_buffer, true);
   m_initialized = true;
   Print("A2Sniper VolE: Volatility Engine v4 initialisé (graduated scoring + momentum)");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CVolatilityEngine::Deinitialize()
  {
   if(m_atr_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_atr_handle);
      m_atr_handle = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Calculer le percentile de l'ATR actuel                           |
//| Compare l'ATR actuel aux N derniers ATR pour situer sa position  |
//+------------------------------------------------------------------+
double CVolatilityEngine::CalculateATRPercentile()
  {
   if(m_avg_atr_period < 10 || m_current_atr <= 0)
      return 50.0;

   //--- On utilise le buffer déjà chargé
   int count_above = 0;
   int total = MathMin(m_avg_atr_period, ArraySize(m_atr_buffer) - 1);

   for(int i = 1; i <= total; i++)
     {
      if(m_atr_buffer[i] <= m_current_atr)
         count_above++;
     }

   return ((double)count_above / (double)total) * 100.0;
  }

//+------------------------------------------------------------------+
//| Mettre à jour le momentum de volatilité                           |
//+------------------------------------------------------------------+
void CVolatilityEngine::UpdateMomentum()
  {
   //--- Momentum = taux de changement du ratio ATR
   if(m_prev_atr_ratio > 0)
      m_atr_momentum = (m_atr_ratio - m_prev_atr_ratio) / m_prev_atr_ratio * 100.0;
   else
      m_atr_momentum = 0;

   //--- Expansion/Contraction
   m_expanding = (m_atr_momentum > 5.0);    // +5% = expansion
   m_contracting = (m_atr_momentum < -5.0);  // -5% = contraction

   m_prev_atr_ratio = m_atr_ratio;
  }

//+------------------------------------------------------------------+
//| Mise à jour                                                      |
//+------------------------------------------------------------------+
bool CVolatilityEngine::Update()
  {
   if(!m_initialized)
      return false;

   int needed = (int)m_avg_atr_period + 1;
   if(CopyBuffer(m_atr_handle, 0, 0, needed, m_atr_buffer) < needed)
      return false;

   m_current_atr = m_atr_buffer[0];

   //--- Calculer l'ATR moyen sur la période
   double sum = 0;
   for(int i = 1; i <= (int)m_avg_atr_period; i++)
      sum += m_atr_buffer[i];
   m_average_atr = sum / m_avg_atr_period;

   //--- Ratio ATR
   if(m_average_atr > 0)
      m_atr_ratio = m_current_atr / m_average_atr;
   else
      m_atr_ratio = 1.0;

   //--- v4: Percentile et momentum
   m_atr_percentile = CalculateATRPercentile();
   UpdateMomentum();

   return true;
  }

//+------------------------------------------------------------------+
//| Volatilité acceptable ?                                          |
//+------------------------------------------------------------------+
bool CVolatilityEngine::IsVolatilityAcceptable() const
  {
   return !IsVolatilityTooLow() && !IsVolatilityTooHigh();
  }

//+------------------------------------------------------------------+
//| Volatilité trop basse ?                                          |
//+------------------------------------------------------------------+
bool CVolatilityEngine::IsVolatilityTooLow() const
  {
   return m_atr_ratio < m_min_atr_multiplier;
  }

//+------------------------------------------------------------------+
//| Volatilité trop haute ?                                          |
//+------------------------------------------------------------------+
bool CVolatilityEngine::IsVolatilityTooHigh() const
  {
   return m_atr_ratio > m_max_atr_multiplier;
  }

//+------------------------------------------------------------------+
//| Volatilité moyenne ?                                             |
//+------------------------------------------------------------------+
bool CVolatilityEngine::IsVolatilityAverage() const
  {
   return m_atr_ratio >= 0.8 && m_atr_ratio <= 1.3;
  }

//+------------------------------------------------------------------+
//| Volatilité extrême ?                                             |
//+------------------------------------------------------------------+
bool CVolatilityEngine::IsVolatilityExtreme() const
  {
   return m_atr_ratio >= EXTREME_VOL_MULT;
  }

//+------------------------------------------------------------------+
//| Score de volatilité v4 - GRADUE (pas binaire)                    |
//| Utilise une interpolation continue au lieu de seuils durs        |
//| Score peut être NEGATIF si conditions dangereuses                |
//+------------------------------------------------------------------+
double CVolatilityEngine::GetVolatilityScore() const
  {
   double score = 0;

   //--- 1. Score basé sur le percentile (0-60 pts)
   //--- Le sweet spot est entre 40-70 percentile (ni trop calme, ni trop fou)
   if(m_atr_percentile >= 35 && m_atr_percentile <= 75)
      score = 60.0;                                     // Zone idéale
   else if(m_atr_percentile >= 25 && m_atr_percentile <= 85)
      score = 45.0;                                     // Zone acceptable
   else if(m_atr_percentile >= 15 && m_atr_percentile <= 92)
      score = 30.0;                                     // Zone médiocre
   else if(m_atr_percentile < 10)
      score = -10.0;                                    // PENALITÉ: Marché mort
   else if(m_atr_percentile > 95)
      score = -15.0;                                    // PANALITÉ: Trop volatile, spreads explosent

   //--- 2. Score basé sur l'ATR ratio (0-40 pts, interpolation linéaire)
   //--- Zone optimale: ratio 1.0 à 1.8 (mouvement sain sans chaos)
   double ratio_score = 0;
   if(m_atr_ratio >= 1.0 && m_atr_ratio <= 1.8)
      ratio_score = 40.0;                               // Zone idéale
   else if(m_atr_ratio >= 0.8 && m_atr_ratio < 1.0)
      ratio_score = 20.0 + (m_atr_ratio - 0.8) * 100.0; // 20-40 interpolation
   else if(m_atr_ratio >= 1.8 && m_atr_ratio <= 2.2)
      ratio_score = 40.0 - (m_atr_ratio - 1.8) * 50.0;   // 40-20 interpolation
   else if(m_atr_ratio >= 0.6 && m_atr_ratio < 0.8)
      ratio_score = 10.0 + (m_atr_ratio - 0.6) * 50.0;   // 10-20 interpolation
   else if(m_atr_ratio > 2.2 && m_atr_ratio <= 2.8)
      ratio_score = 10.0 - (m_atr_ratio - 2.2) * 16.6;   // 10-0 interpolation
   else if(m_atr_ratio < 0.5)
      ratio_score = -10.0;                              // Pas de mouvement = pas de trade
   else if(m_atr_ratio > 3.5)
      ratio_score = -20.0;                              // Chaos = danger
   else
      ratio_score = 0.0;

   score += ratio_score;

   //--- 3. Momentum bonus/malus (-15 à +15 pts)
   if(m_expanding && m_atr_ratio < 2.0)
      score += 10.0;       // Expansion modérée = bon pour les breakouts
   else if(m_expanding && m_atr_ratio >= 2.0)
      score -= 15.0;       // Expansion depuis déjà haut = risque d'épuisement
   else if(m_contracting && m_atr_ratio < 0.7)
      score -= 5.0;        // Contraction déjà bas = marché en sommeil
   else if(m_contracting && m_atr_ratio >= 0.7)
      score += 5.0;        // Contraction depuis normal = calme avant la tempête (setup)

   return MathMax(score, -30.0);  // Plafond minimum à -30
  }

//+------------------------------------------------------------------+
//| Calculer SL basé sur ATR                                         |
//+------------------------------------------------------------------+
double CVolatilityEngine::CalculateATRStopLoss(const ENUM_SIGNAL_TYPE direction, double multiplier) const
  {
   if(m_current_atr <= 0)
      return 0;

   double sl_distance = m_current_atr * multiplier;
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(direction == SIGNAL_BUY)
      return price - sl_distance;
   else
      return price + sl_distance;
  }

//+------------------------------------------------------------------+
//| Calculer TP basé sur ATR et RR                                   |
//+------------------------------------------------------------------+
double CVolatilityEngine::CalculateATRTakeProfit(const ENUM_SIGNAL_TYPE direction, double rr_ratio, double sl_distance) const
  {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(sl_distance <= 0)
      sl_distance = m_current_atr * DEFAULT_ATR_MULTIPLIER;

   double tp_distance = sl_distance * rr_ratio;

   if(direction == SIGNAL_BUY)
      return price + tp_distance;
   else
      return price - tp_distance;
  }

//+------------------------------------------------------------------+
//| Info volatilité                                                  |
//+------------------------------------------------------------------+
string CVolatilityEngine::GetVolatilityInfo() const
  {
   return StringFormat("ATR: %.5f | AvgATR: %.5f | Ratio: %.2f | Pctl: %.0f | Mom: %+.1f%% | %s | Score=%.0f",
                       m_current_atr, m_average_atr, m_atr_ratio, m_atr_percentile,
                       m_atr_momentum,
                       m_expanding ? "EXPANDING" : (m_contracting ? "CONTRACTING" : "STABLE"),
                       GetVolatilityScore());
  }

#endif // A2SNIPER_VOLATILITY_MQH
//+------------------------------------------------------------------+
