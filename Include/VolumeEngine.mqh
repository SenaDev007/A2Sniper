//+------------------------------------------------------------------+
//| VolumeEngine.mqh - Analyse des Volumes                           |
//| A2Sniper Ultimate v3.0                                           |
//| Tick Volume, Relative Volume, Volume Institutionnel, Volume Extrême|
//+------------------------------------------------------------------+
#ifndef A2SNIPER_VOLUME_MQH
#define A2SNIPER_VOLUME_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Classe CVolumeEngine                                             |
//+------------------------------------------------------------------+
class CVolumeEngine
  {
private:
   bool              m_initialized;
   int               m_ma_period;            // Période de la moyenne du volume
   int               m_vol_handle;           // Handle volume
   double            m_vol_buffer[];         // Buffer volume

   //--- Seuils
   double            m_institutional_mult;   // Seuil volume institutionnel (> 150%)
   double            m_extreme_mult;         // Seuil volume extrême (> 250%)

   //--- État
   double            m_current_volume;
   double            m_average_volume;
   double            m_relative_volume;      // Volume actuel / moyenne

public:
   //--- Constructeur / Destructeur
                     CVolumeEngine();
                    ~CVolumeEngine();

   //--- Initialisation
   bool              Initialize(int ma_period = 20, double inst_mult = 1.5, double extreme_mult = 2.5);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   double            GetCurrentVolume() const { return m_current_volume; }
   double            GetAverageVolume() const { return m_average_volume; }
   double            GetRelativeVolume() const { return m_relative_volume; }

   //--- Vérifications
   bool              IsVolumeAboveAverage() const;
   bool              IsInstitutionalVolume() const;
   bool              IsExtremeVolume() const;
   double            GetVolumeScore() const;
   double            GetVolumeScoreForDirection(const ENUM_SIGNAL_TYPE direction) const;

   //--- Info
   string            GetVolumeInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CVolumeEngine::CVolumeEngine() :
   m_initialized(false),
   m_ma_period(20),
   m_vol_handle(INVALID_HANDLE),
   m_institutional_mult(DEFAULT_VOLUME_MULTIPLIER),
   m_extreme_mult(INSTITUTIONAL_VOL_MULT),
   m_current_volume(0),
   m_average_volume(0),
   m_relative_volume(0)
  {
   ArraySetAsSeries(m_vol_buffer, true);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CVolumeEngine::~CVolumeEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CVolumeEngine::Initialize(int ma_period, double inst_mult, double extreme_mult)
  {
   m_ma_period = (ma_period > 5) ? ma_period : 20;
   m_institutional_mult = (inst_mult > 1.0) ? inst_mult : 1.5;
   m_extreme_mult = (extreme_mult > inst_mult) ? extreme_mult : 2.5;

   //--- Utiliser iVolumes pour tick volume
   m_vol_handle = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
   if(m_vol_handle == INVALID_HANDLE)
     {
      Print("A2Sniper VE: Erreur création Volume handle - ", GetLastError());
      return false;
     }

   ArraySetAsSeries(m_vol_buffer, true);
   m_initialized = true;
   Print("A2Sniper VE: Volume Engine initialisé");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CVolumeEngine::Deinitialize()
  {
   if(m_vol_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_vol_handle);
      m_vol_handle = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Mise à jour                                                      |
//+------------------------------------------------------------------+
bool CVolumeEngine::Update()
  {
   if(!m_initialized)
      return false;

   //--- Obtenir les volumes récents
   if(CopyBuffer(m_vol_handle, 0, 0, m_ma_period + 1, m_vol_buffer) < m_ma_period + 1)
      return false;

   m_current_volume = m_vol_buffer[0];

   //--- Calculer la moyenne
   double sum = 0;
   for(int i = 1; i <= m_ma_period; i++)
      sum += m_vol_buffer[i];
   m_average_volume = sum / m_ma_period;

   //--- Volume relatif
   if(m_average_volume > 0)
      m_relative_volume = m_current_volume / m_average_volume;
   else
      m_relative_volume = 1.0;

   return true;
  }

//+------------------------------------------------------------------+
//| Volume au-dessus de la moyenne ?                                 |
//+------------------------------------------------------------------+
bool CVolumeEngine::IsVolumeAboveAverage() const
  {
   return m_relative_volume > 1.0;
  }

//+------------------------------------------------------------------+
//| Volume institutionnel ?                                          |
//+------------------------------------------------------------------+
bool CVolumeEngine::IsInstitutionalVolume() const
  {
   return m_relative_volume >= m_institutional_mult;
  }

//+------------------------------------------------------------------+
//| Volume extrême ?                                                 |
//+------------------------------------------------------------------+
bool CVolumeEngine::IsExtremeVolume() const
  {
   return m_relative_volume >= m_extreme_mult;
  }

//+------------------------------------------------------------------+
//| Score de volume (0-100)                                          |
//+------------------------------------------------------------------+
double CVolumeEngine::GetVolumeScore() const
  {
   if(m_relative_volume >= m_extreme_mult)
      return 100.0;
   if(m_relative_volume >= m_institutional_mult)
      return 75.0;
   if(m_relative_volume >= 1.0)
      return 50.0;
   if(m_relative_volume >= 0.7)
      return 25.0;
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Score de volume pour une direction                               |
//+------------------------------------------------------------------+
double CVolumeEngine::GetVolumeScoreForDirection(const ENUM_SIGNAL_TYPE direction) const
  {
   double base_score = GetVolumeScore();

   //--- Pour un signal d'achat, vérifier la bougie de rejet haussière
   double open_price = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close_price = iClose(_Symbol, PERIOD_CURRENT, 1);

   if(direction == SIGNAL_BUY)
     {
      if(close_price > open_price) // Bougie haussière
         base_score = MathMin(base_score * 1.2, 100.0);
      else
         base_score *= 0.7;
     }
   else if(direction == SIGNAL_SELL)
     {
      if(close_price < open_price)
         base_score = MathMin(base_score * 1.2, 100.0);
      else
         base_score *= 0.7;
     }

   return base_score;
  }

//+------------------------------------------------------------------+
//| Info volume                                                      |
//+------------------------------------------------------------------+
string CVolumeEngine::GetVolumeInfo() const
  {
   return StringFormat("Vol: %.0f | Avg: %.0f | Rel: %.2fx | Inst=%s | Extreme=%s | Score=%.0f",
                       m_current_volume, m_average_volume, m_relative_volume,
                       IsInstitutionalVolume() ? "Y" : "N",
                       IsExtremeVolume() ? "Y" : "N",
                       GetVolumeScore());
  }

#endif // A2SNIPER_VOLUME_MQH
//+------------------------------------------------------------------+
