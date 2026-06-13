//+------------------------------------------------------------------+
//| VolatilityEngine.mqh - Analyse de la Volatilité                  |
//| A2Sniper Ultimate v3.0                                           |
//| ATR 14, Volatilité moyenne/extrême, Filtre Forex/Synthétiques   |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_VOLATILITY_MQH
#define A2SNIPER_VOLATILITY_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Classe CVolatilityEngine                                         |
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
   m_atr_ratio(1.0)
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
   Print("A2Sniper VolE: Volatility Engine initialisé");
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
//| Score de volatilité (0-100)                                      |
//+------------------------------------------------------------------+
double CVolatilityEngine::GetVolatilityScore() const
  {
   //--- Volatilité extrême = DANGEREUX, score le plus bas
   if(IsVolatilityExtreme())
      return 10.0;
   //--- Volatilité trop haute = risqué, score bas
   if(IsVolatilityTooHigh())
      return 20.0;
   //--- Volatilité trop basse = pas assez de mouvement
   if(IsVolatilityTooLow())
      return 20.0;
   //--- Zone idéale: ATR ratio entre 1.0 et 2.0
   if(m_atr_ratio >= 1.0 && m_atr_ratio <= 2.0)
      return 100.0;
   //--- Zone acceptable
   if(m_atr_ratio >= 0.7 && m_atr_ratio <= 2.5)
      return 60.0;
   return 40.0;
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
   return StringFormat("ATR: %.5f | AvgATR: %.5f | Ratio: %.2f | OK=%s | Score=%.0f",
                       m_current_atr, m_average_atr, m_atr_ratio,
                       IsVolatilityAcceptable() ? "Y" : "N",
                       GetVolatilityScore());
  }

#endif // A2SNIPER_VOLATILITY_MQH
//+------------------------------------------------------------------+
