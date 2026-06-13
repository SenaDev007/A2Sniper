//+------------------------------------------------------------------+
//| VolumeEngine.mqh - Analyse des Volumes v4.0                      |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| v4: VSA concepts, graduated scoring, negative scoring,            |
//|     volume trend detection, effort vs result analysis             |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_VOLUME_MQH
#define A2SNIPER_VOLUME_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Classe CVolumeEngine v4                                           |
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

   //--- v4: Volume trend
   double            m_vol_3bar_avg;         // Moyenne 3 dernières bougies
   double            m_vol_10bar_avg;        // Moyenne 10 dernières bougies
   bool              m_volume_increasing;    // Tendance du volume

   //--- v4: Effort vs Résultat (VSA)
   double            m_effort_result_ratio;  // Volume vs mouvement de prix

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
   double            GetVolumeTrend3() const { return m_vol_3bar_avg; }
   double            GetVolumeTrend10() const { return m_vol_10bar_avg; }
   bool              IsVolumeIncreasing() const { return m_volume_increasing; }
   double            GetEffortResultRatio() const { return m_effort_result_ratio; }

   //--- Vérifications
   bool              IsVolumeAboveAverage() const;
   bool              IsInstitutionalVolume() const;
   bool              IsExtremeVolume() const;
   double            GetVolumeScore() const;
   double            GetVolumeScoreForDirection(const ENUM_SIGNAL_TYPE direction) const;

   //--- v4: VSA Analysis
   bool              IsClimaxVolume() const;
   bool              IsChurnVolume() const;         // Volume fort + petite bougie = indécision
   double            CalculateVSAScore(const ENUM_SIGNAL_TYPE direction) const;

   //--- Info
   string            GetVolumeInfo() const;

private:
   void              CalculateVolumeTrends();
   void              CalculateEffortResult();
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
   m_relative_volume(0),
   m_vol_3bar_avg(0),
   m_vol_10bar_avg(0),
   m_volume_increasing(false),
   m_effort_result_ratio(1.0)
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
   Print("A2Sniper VE: Volume Engine v4 initialisé (VSA + graduated scoring)");
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
//| Calculer les tendances de volume                                  |
//+------------------------------------------------------------------+
void CVolumeEngine::CalculateVolumeTrends()
  {
   int buf_size = ArraySize(m_vol_buffer);
   if(buf_size < 11) return;

   //--- Moyenne 3 dernières bougies
   double sum3 = 0;
   int count3 = MathMin(3, buf_size);
   for(int i = 0; i < count3; i++)
      sum3 += m_vol_buffer[i];
   m_vol_3bar_avg = (count3 > 0) ? sum3 / count3 : 0;

   //--- Moyenne 10 dernières bougies
   double sum10 = 0;
   int count10 = MathMin(10, buf_size);
   for(int i = 0; i < count10; i++)
      sum10 += m_vol_buffer[i];
   m_vol_10bar_avg = (count10 > 0) ? sum10 / count10 : 0;

   //--- Tendance: volume récent > volume plus large
   if(m_vol_10bar_avg > 0)
      m_volume_increasing = (m_vol_3bar_avg > m_vol_10bar_avg * 1.1);
   else
      m_volume_increasing = false;
  }

//+------------------------------------------------------------------+
//| Calculer le ratio Effort/Résultat (VSA)                           |
//| Effort = Volume, Résultat = amplitude de la bougie               |
//| Volume fort + petite bougie = churn (pas de conviction)          |
//| Volume fort + grande bougie = climax (conviction réelle)         |
//+------------------------------------------------------------------+
void CVolumeEngine::CalculateEffortResult()
  {
   if(m_current_volume <= 0 || m_average_volume <= 0)
     {
      m_effort_result_ratio = 1.0;
      return;
     }

   //--- Amplitude de la dernière bougie complétée en pips
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double range = (high1 - low1) / _Point;

   //--- Amplitude moyenne des 20 dernières bougies
   double avg_range = 0;
   int count = MathMin(20, iBars(_Symbol, PERIOD_CURRENT) - 2);
   for(int i = 1; i <= count; i++)
     {
      avg_range += (iHigh(_Symbol, PERIOD_CURRENT, i) - iLow(_Symbol, PERIOD_CURRENT, i)) / _Point;
     }
   if(count > 0) avg_range /= count;

   //--- Ratio: volume relatif / amplitude relative
   double vol_relative = m_current_volume / m_average_volume;
   double range_relative = (avg_range > 0) ? range / avg_range : 1.0;

   if(range_relative > 0)
      m_effort_result_ratio = vol_relative / range_relative;
   else
      m_effort_result_ratio = vol_relative;
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

   //--- v4: Tendances et VSA
   CalculateVolumeTrends();
   CalculateEffortResult();

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
//| Volume climax ? (VSA)                                            |
//| Volume très élevé + grande bougie = point culminant              |
//+------------------------------------------------------------------+
bool CVolumeEngine::IsClimaxVolume() const
  {
   return m_relative_volume >= 2.5;
  }

//+------------------------------------------------------------------+
//| Volume churn ? (VSA)                                             |
//| Volume élevé + petite bougie = absorption, indécision           |
//| Souvent vu aux reversals ou aux zones de résistance              |
//+------------------------------------------------------------------+
bool CVolumeEngine::IsChurnVolume() const
  {
   //--- Volume au-dessus de la moyenne MAIS effort/result élevé
   //--- (= beaucoup de volume pour peu de mouvement)
   return (m_relative_volume >= 1.5 && m_effort_result_ratio >= 2.0);
  }

//+------------------------------------------------------------------+
//| Score de volume v4 - GRADUE (pas généreux)                       |
//| Avant: >= moyenne = déjà 50 pts (trop généreux)                  |
//| Maintenant: interpolation continue, seuils plus stricts          |
//+------------------------------------------------------------------+
double CVolumeEngine::GetVolumeScore() const
  {
   //--- Scoring gradué par interpolation
   double score = 0;

   if(m_relative_volume >= 3.0)
      score = 100.0;
   else if(m_relative_volume >= 2.5)
      score = 85.0 + (m_relative_volume - 2.5) * 30.0;  // 85-100 interpolation
   else if(m_relative_volume >= 2.0)
      score = 70.0 + (m_relative_volume - 2.0) * 30.0;  // 70-85 interpolation
   else if(m_relative_volume >= 1.5)
      score = 50.0 + (m_relative_volume - 1.5) * 40.0;  // 50-70 interpolation
   else if(m_relative_volume >= 1.2)
      score = 35.0 + (m_relative_volume - 1.2) * 50.0;  // 35-50 interpolation
   else if(m_relative_volume >= 1.0)
      score = 20.0 + (m_relative_volume - 1.0) * 75.0;  // 20-35 interpolation
   else if(m_relative_volume >= 0.7)
      score = 5.0 + (m_relative_volume - 0.7) * 50.0;   // 5-20 interpolation
   else if(m_relative_volume >= 0.5)
      score = -15.0 + (m_relative_volume - 0.5) * 100.0; // -15 to 5
   else
      score = -30.0;                                       // Volume quasi absent

   //--- v4: Malus churn (volume sans conviction)
   if(IsChurnVolume())
      score -= 20.0;    // Churn = signal d'indécision, pénaliser

   //--- v4: Bonus volume croissant
   if(m_volume_increasing && m_relative_volume >= 1.0)
      score += 10.0;    // Volume qui monte = momentum

   return MathMax(MathMin(score, 100.0), -30.0);
  }

//+------------------------------------------------------------------+
//| Score de volume pour une direction (v4 avec VSA)                  |
//+------------------------------------------------------------------+
double CVolumeEngine::GetVolumeScoreForDirection(const ENUM_SIGNAL_TYPE direction) const
  {
   double base_score = GetVolumeScore();

   //--- Pour un signal d'achat, vérifier la bougie de rejet haussière
   double open_price = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close_price = iClose(_Symbol, PERIOD_CURRENT, 1);
   double high_price = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low_price = iLow(_Symbol, PERIOD_CURRENT, 1);
   double body = MathAbs(close_price - open_price);
   double total_range = high_price - low_price;
   bool bullish_candle = (close_price > open_price);

   //--- VSA: Effort/Résultat directionnel
   if(m_effort_result_ratio >= 2.0 && m_relative_volume >= 1.5)
     {
      //--- Churn volume = beaucoup d'effort, peu de résultat
      //--- Pénalité forte si direction alignée (le marché résiste)
      base_score -= 15.0;
     }
   else if(m_effort_result_ratio <= 0.8 && m_relative_volume >= 1.5)
     {
      //--- Climax volume = beaucoup de résultat pour l'effort
      //--- Bonus si direction alignée (conviction réelle)
      base_score += 10.0;
     }

   //--- Direction du volume
   if(direction == SIGNAL_BUY)
     {
      if(bullish_candle)
         base_score = MathMin(base_score * 1.15, 100.0);  // Léger boost
      else
         base_score *= 0.65;                                // Pénalité direction opposée
     }
   else if(direction == SIGNAL_SELL)
     {
      if(!bullish_candle)
         base_score = MathMin(base_score * 1.15, 100.0);
      else
         base_score *= 0.65;
     }

   //--- v4: Vérifier la mèche de rejet (VSA: absorption)
   if(total_range > 0)
     {
      double upper_wick = high_price - MathMax(open_price, close_price);
      double lower_wick = MathMin(open_price, close_price) - low_price;
      double wick_ratio = MathMax(upper_wick, lower_wick) / total_range;

      //--- Mèche de rejet sur volume élevé = signal fort de reversal
      if(wick_ratio >= 0.6 && m_relative_volume >= 1.5)
        {
         if(direction == SIGNAL_BUY && lower_wick > upper_wick)
            base_score += 15.0;   // Rejection bas + volume = BUY signal
         else if(direction == SIGNAL_SELL && upper_wick > lower_wick)
            base_score += 15.0;   // Rejection haut + volume = SELL signal
        }
     }

   return MathMax(MathMin(base_score, 100.0), -30.0);
  }

//+------------------------------------------------------------------+
//| Score VSA complet pour une direction                              |
//| Combine volume, effort/résultat, mèches de rejet                  |
//+------------------------------------------------------------------+
double CVolumeEngine::CalculateVSAScore(const ENUM_SIGNAL_TYPE direction) const
  {
   return GetVolumeScoreForDirection(direction);
  }

//+------------------------------------------------------------------+
//| Info volume                                                      |
//+------------------------------------------------------------------+
string CVolumeEngine::GetVolumeInfo() const
  {
   return StringFormat("Vol: %.0f | Avg: %.0f | Rel: %.2fx | Trend3: %.0f | Trend10: %.0f | %s | E/R: %.1f | Churn=%s | Climax=%s | Score=%.0f",
                       m_current_volume, m_average_volume, m_relative_volume,
                       m_vol_3bar_avg, m_vol_10bar_avg,
                       m_volume_increasing ? "UP" : "DN",
                       m_effort_result_ratio,
                       IsChurnVolume() ? "Y" : "N",
                       IsClimaxVolume() ? "Y" : "N",
                       GetVolumeScore());
  }

#endif // A2SNIPER_VOLUME_MQH
//+------------------------------------------------------------------+
