//+------------------------------------------------------------------+
//| MachineLearningEngine.mqh - Apprentissage Adaptatif              |
//| A2Sniper Ultimate v3.0                                           |
//| Évaluation des performances réelles des signaux                  |
//| Ajustement: pondérations, scores, priorités selon l'historique   |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_ML_ENGINE_MQH
#define A2SNIPER_ML_ENGINE_MQH

#include <A2Sniper\CommonTypes.mqh>

//+------------------------------------------------------------------+
//| Structure d'un pattern de signal pour le ML                       |
//+------------------------------------------------------------------+
struct SSignalPattern
  {
   ENUM_TRADING_SESSION session;          // Session du trade
   string               symbol;           // Symbole
   ENUM_MARKET_DIRECTION structure;       // Structure du marché
   int                  sre_score;        // Score SRE
   double               ai_score;         // Score AI
   double               ob_score;         // Score OB
   double               fvg_score;        // Score FVG
   double               volume_score;     // Score volume
   double               volatility_score; // Score volatilité
   double               liquidity_score;  // Score liquidité
   bool                 was_win;          // Trade gagnant ?
   double               rr_achieved;      // R:R obtenu
   double               profit;           // Profit
   datetime             time;             // Heure
  };

//+------------------------------------------------------------------+
//| Facteurs d'ajustement ML                                         |
//+------------------------------------------------------------------+
struct SMLAdjustments
  {
   double               session_weight[4];    // Poids par session (0=Asian, 1=London, 2=NY, 3=Overlap)
   double               sre_threshold;        // Seuil SRE ajusté
   double               volume_threshold;     // Seuil volume ajusté
   double               ob_weight;            // Poids OB ajusté
   double               fvg_weight;           // Poids FVG ajusté
   double               liquidity_weight;     // Poids liquidité ajusté
   double               confidence_multiplier;// Multiplicateur de confiance
   bool                 is_calibrated;        // ML calibré avec assez de données
   int                  sample_count;         // Nombre d'échantillons
  };

//+------------------------------------------------------------------+
//| Classe CMachineLearningEngine                                     |
//+------------------------------------------------------------------+
class CMachineLearningEngine
  {
private:
   bool                 m_initialized;
   int                  m_max_patterns;        // Max patterns stockés
   int                  m_min_samples;         // Min échantillons pour calibration

   //--- Données
   SSignalPattern       m_patterns[];          // Historique des patterns
   int                  m_pattern_count;

   //--- Ajustements calculés
   SMLAdjustments       m_adjustments;

   //--- Statistiques par session
   int                  m_session_wins[4];
   int                  m_session_total[4];

   //--- Statistiques par plage de score
   int                  m_score_wins[5];       // 0: <70, 1: 70-79, 2: 80-89, 3: 90-99, 4: 100
   int                  m_score_total[5];

   //--- Méthodes privées
   void                 RecalculateAdjustments();
   int                  GetSessionIndex(ENUM_TRADING_SESSION session) const;
   int                  GetScoreIndex(int score) const;
   void                 TrimOldPatterns();
   double               CalculateWinRateForSession(int session_idx) const;
   double               CalculateWinRateForScore(int score_idx) const;

public:
   //--- Constructeur / Destructeur
                        CMachineLearningEngine();
                       ~CMachineLearningEngine();

   //--- Initialisation
   bool                 Initialize(int max_patterns = 500, int min_samples = 30);
   void                 Deinitialize();

   //--- Enregistrement d'un trade terminé
   bool                 RecordTrade(const SSignalPattern &pattern);

   //--- Ajustements ML
   SMLAdjustments       GetAdjustments() const { return m_adjustments; }
   double               GetAdjustedSREThreshold() const { return m_adjustments.sre_threshold; }
   double               GetAdjustedVolumeThreshold() const { return m_adjustments.volume_threshold; }
   double               GetSessionWeight(ENUM_TRADING_SESSION session) const;
   double               GetConfidenceMultiplier() const { return m_adjustments.confidence_multiplier; }
   bool                 IsCalibrated() const { return m_adjustments.is_calibrated; }

   //--- Score ML pour un signal potentiel
   double               EvaluateSignal(const SSignalPattern &pattern) const;

   //--- Info
   string               GetMLInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CMachineLearningEngine::CMachineLearningEngine() :
   m_initialized(false),
   m_max_patterns(500),
   m_min_samples(30),
   m_pattern_count(0)
  {
   ZeroMemory(m_adjustments);
   m_adjustments.sre_threshold = MIN_SIGNAL_SCORE_SNIPER;
   m_adjustments.volume_threshold = 1.0;
   m_adjustments.ob_weight = 1.0;
   m_adjustments.fvg_weight = 1.0;
   m_adjustments.liquidity_weight = 1.0;
   m_adjustments.confidence_multiplier = 1.0;
   m_adjustments.is_calibrated = false;

   ZeroMemory(m_session_wins);
   ZeroMemory(m_session_total);
   ZeroMemory(m_score_wins);
   ZeroMemory(m_score_total);
   ArrayResize(m_patterns, 0);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CMachineLearningEngine::~CMachineLearningEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CMachineLearningEngine::Initialize(int max_patterns, int min_samples)
  {
   m_max_patterns = (max_patterns > 50) ? max_patterns : 500;
   m_min_samples = (min_samples > 10) ? min_samples : 30;

   m_initialized = true;
   Print("A2Sniper ML: Machine Learning Engine initialisé (MaxPatterns=", m_max_patterns,
         " MinSamples=", m_min_samples, ")");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CMachineLearningEngine::Deinitialize()
  {
   m_pattern_count = 0;
   ArrayResize(m_patterns, 0);
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Index de session (0-3)                                           |
//+------------------------------------------------------------------+
int CMachineLearningEngine::GetSessionIndex(ENUM_TRADING_SESSION session) const
  {
   switch(session)
     {
      case SESSION_ASIAN:      return 0;
      case SESSION_LONDON:     return 1;
      case SESSION_NEWYORK:    return 2;
      case SESSION_OVERLAP_LN: return 3;
      default:                 return 0;
     }
  }

//+------------------------------------------------------------------+
//| Index de plage de score                                          |
//+------------------------------------------------------------------+
int CMachineLearningEngine::GetScoreIndex(int score) const
  {
   if(score >= 100) return 4;
   if(score >= 90)  return 3;
   if(score >= 80)  return 2;
   if(score >= 70)  return 1;
   return 0;
  }

//+------------------------------------------------------------------+
//| Enregistrer un trade                                             |
//+------------------------------------------------------------------+
bool CMachineLearningEngine::RecordTrade(const SSignalPattern &pattern)
  {
   if(!m_initialized)
      return false;

   //--- Ajouter le pattern
   m_pattern_count++;
   ArrayResize(m_patterns, m_pattern_count);
   m_patterns[m_pattern_count - 1] = pattern;

   //--- Mettre à jour les compteurs
   int sess_idx = GetSessionIndex(pattern.session);
   m_session_total[sess_idx]++;
   if(pattern.was_win)
      m_session_wins[sess_idx]++;

   int score_idx = GetScoreIndex(pattern.sre_score);
   m_score_total[score_idx]++;
   if(pattern.was_win)
      m_score_wins[score_idx]++;

   //--- Recalculer les ajustements
   RecalculateAdjustments();

   //--- Nettoyer les anciens patterns
   TrimOldPatterns();

   return true;
  }

//+------------------------------------------------------------------+
//| Recalculer les ajustements ML                                    |
//+------------------------------------------------------------------+
void CMachineLearningEngine::RecalculateAdjustments()
  {
   m_adjustments.sample_count = m_pattern_count;

   //--- Vérifier si on a assez de données
   if(m_pattern_count < m_min_samples)
     {
      m_adjustments.is_calibrated = false;
      return;
     }

   m_adjustments.is_calibrated = true;

   //--- 1. Ajuster les poids par session
   //--- Les sessions avec meilleur win rate obtiennent un poids plus élevé
   double global_wr = 0;
   int total_wins = 0;
   for(int i = 0; i < 4; i++)
      total_wins += m_session_wins[i];
   global_wr = (m_pattern_count > 0) ? (double)total_wins / m_pattern_count : 0.5;

   for(int i = 0; i < 4; i++)
     {
      double session_wr = CalculateWinRateForSession(i);
      //--- Poids = ratio de la WR session / WR globale
      if(global_wr > 0)
         m_adjustments.session_weight[i] = session_wr / global_wr;
      else
         m_adjustments.session_weight[i] = 1.0;

      //--- Borner entre 0.5 et 2.0
      m_adjustments.session_weight[i] = MathMax(0.5, MathMin(2.0, m_adjustments.session_weight[i]));
     }

   //--- 2. Ajuster le seuil SRE basé sur les performances
   //--- Si les signaux à 90+ ont un win rate < 50%, augmenter le seuil
   double sniper_wr = CalculateWinRateForScore(3); // Score 90-99
   if(sniper_wr < 0.50 && m_score_total[3] >= 10)
      m_adjustments.sre_threshold = 95.0; // Exiger 95 au lieu de 90
   else if(sniper_wr >= 0.70 && m_score_total[3] >= 10)
      m_adjustments.sre_threshold = 85.0; // Permettre 85
   else
      m_adjustments.sre_threshold = MIN_SIGNAL_SCORE_SNIPER; // 90 par défaut

   //--- 3. Ajuster le seuil de volume
   double high_vol_wr = 0;
   int high_vol_count = 0;
   for(int i = 0; i < m_pattern_count; i++)
     {
      if(m_patterns[i].volume_score >= 50)
        {
         high_vol_count++;
         if(m_patterns[i].was_win) high_vol_wr++;
        }
     }
   if(high_vol_count > 0)
      high_vol_wr /= high_vol_count;

   //--- Si le volume élevé ne corrèle pas avec les wins, exiger plus de volume
   if(high_vol_wr < 0.45 && high_vol_count >= 10)
      m_adjustments.volume_threshold = 1.5; // Plus strict
   else
      m_adjustments.volume_threshold = 1.0; // Normal

   //--- 4. Ajuster les poids OB/FVG/Liquidity basé sur leur corrélation avec les wins
   double ob_corr = 0, fvg_corr = 0, liq_corr = 0;
   int corr_count = 0;
   for(int i = 0; i < m_pattern_count; i++)
     {
      double direction = m_patterns[i].was_win ? 1.0 : -1.0;
      ob_corr += m_patterns[i].ob_score * direction;
      fvg_corr += m_patterns[i].fvg_score * direction;
      liq_corr += m_patterns[i].liquidity_score * direction;
      corr_count++;
     }

   if(corr_count > 0)
     {
      //--- Normaliser les corrélations
      ob_corr /= corr_count;
      fvg_corr /= corr_count;
      liq_corr /= corr_count;

      //--- Ajuster les poids (corrélation positive = poids plus élevé)
      m_adjustments.ob_weight = 1.0 + (ob_corr / 100.0) * 0.5; // Max 50% d'ajustement
      m_adjustments.fvg_weight = 1.0 + (fvg_corr / 100.0) * 0.5;
      m_adjustments.liquidity_weight = 1.0 + (liq_corr / 100.0) * 0.5;

      //--- Borner
      m_adjustments.ob_weight = MathMax(0.5, MathMin(1.5, m_adjustments.ob_weight));
      m_adjustments.fvg_weight = MathMax(0.5, MathMin(1.5, m_adjustments.fvg_weight));
      m_adjustments.liquidity_weight = MathMax(0.5, MathMin(1.5, m_adjustments.liquidity_weight));
     }

   //--- 5. Multiplicateur de confiance basé sur les performances globales
   if(global_wr >= 0.65)
      m_adjustments.confidence_multiplier = 1.2; // Plus confiant
   else if(global_wr >= 0.50)
      m_adjustments.confidence_multiplier = 1.0; // Normal
   else if(global_wr >= 0.40)
      m_adjustments.confidence_multiplier = 0.8; // Prudent
   else
      m_adjustments.confidence_multiplier = 0.6; // Très prudent
  }

//+------------------------------------------------------------------+
//| Calculer le win rate par session                                  |
//+------------------------------------------------------------------+
double CMachineLearningEngine::CalculateWinRateForSession(int session_idx) const
  {
   if(m_session_total[session_idx] <= 0) return 0.5;
   return (double)m_session_wins[session_idx] / m_session_total[session_idx];
  }

//+------------------------------------------------------------------+
//| Calculer le win rate par plage de score                          |
//+------------------------------------------------------------------+
double CMachineLearningEngine::CalculateWinRateForScore(int score_idx) const
  {
   if(m_score_total[score_idx] <= 0) return 0.5;
   return (double)m_score_wins[score_idx] / m_score_total[score_idx];
  }

//+------------------------------------------------------------------+
//| Nettoyer les anciens patterns                                    |
//+------------------------------------------------------------------+
void CMachineLearningEngine::TrimOldPatterns()
  {
   if(m_pattern_count <= m_max_patterns)
      return;

   //--- Garder les m_max_patterns plus récents
   int excess = m_pattern_count - m_max_patterns;
   SSignalPattern temp[];
   int new_count = m_max_patterns;
   ArrayResize(temp, new_count);

   for(int i = 0; i < new_count; i++)
      temp[i] = m_patterns[i + excess];

   m_pattern_count = new_count;
   ArrayResize(m_patterns, m_pattern_count);
   for(int i = 0; i < m_pattern_count; i++)
      m_patterns[i] = temp[i];
  }

//+------------------------------------------------------------------+
//| Poids de session                                                 |
//+------------------------------------------------------------------+
double CMachineLearningEngine::GetSessionWeight(ENUM_TRADING_SESSION session) const
  {
   if(!m_adjustments.is_calibrated)
      return 1.0;
   int idx = GetSessionIndex(session);
   return m_adjustments.session_weight[idx];
  }

//+------------------------------------------------------------------+
//| Évaluer un signal potentiel avec le ML                           |
//+------------------------------------------------------------------+
double CMachineLearningEngine::EvaluateSignal(const SSignalPattern &pattern) const
  {
   if(!m_initialized || !m_adjustments.is_calibrated)
      return 50.0; // Neutre si pas calibré

   double score = 50.0;

   //--- Bonus/malus basé sur la session
   int sess_idx = GetSessionIndex(pattern.session);
   double session_wr = CalculateWinRateForSession(sess_idx);
   if(session_wr > 0.6) score += 15;
   else if(session_wr > 0.5) score += 5;
   else if(session_wr < 0.4) score -= 15;
   else if(session_wr < 0.5) score -= 5;

   //--- Bonus/malus basé sur la plage de score
   int score_idx = GetScoreIndex(pattern.sre_score);
   double score_wr = CalculateWinRateForScore(score_idx);
   if(score_wr > 0.65) score += 10;
   else if(score_wr > 0.5) score += 5;
   else if(score_wr < 0.35) score -= 10;
   else if(score_wr < 0.5) score -= 5;

   //--- Ajustement basé sur les corrélations OB/FVG/Liquidity
   score += (pattern.ob_score * m_adjustments.ob_weight - 50) * 0.1;
   score += (pattern.fvg_score * m_adjustments.fvg_weight - 50) * 0.1;
   score += (pattern.liquidity_score * m_adjustments.liquidity_weight - 50) * 0.1;

   //--- Borner entre 0 et 100
   return MathMax(0, MathMin(100, score));
  }

//+------------------------------------------------------------------+
//| Info ML                                                          |
//+------------------------------------------------------------------+
string CMachineLearningEngine::GetMLInfo() const
  {
   return StringFormat("ML: Calibrated=%s Samples=%d SRE_Thresh=%.0f Vol_Thresh=%.1f OB_W=%.2f FVG_W=%.2f Liq_W=%.2f Conf=%.2f",
                       m_adjustments.is_calibrated ? "Y" : "N",
                       m_adjustments.sample_count,
                       m_adjustments.sre_threshold,
                       m_adjustments.volume_threshold,
                       m_adjustments.ob_weight,
                       m_adjustments.fvg_weight,
                       m_adjustments.liquidity_weight,
                       m_adjustments.confidence_multiplier);
  }

#endif // A2SNIPER_ML_ENGINE_MQH
//+------------------------------------------------------------------+
