//+------------------------------------------------------------------+
//| AIScoringEngine.mqh - Scoring IA Pondere                        |
//| A2Sniper Ultimate v3.1                                           |
//| FIX: MeetsAllCriteria real implementation, minimum per-module     |
//|      scores, avoid double SRE call, minimum engines confirming    |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_AI_SCORING_MQH
#define A2SNIPER_AI_SCORING_MQH

#include "CommonTypes.mqh"
#include "StrategicReversalEngine.mqh"
#include "SmartMoneyEngine.mqh"
#include "ICTEngine.mqh"
#include "OrderBlockEngine.mqh"
#include "FVGEngine.mqh"
#include "LiquidityEngine.mqh"
#include "VolumeEngine.mqh"
#include "VolatilityEngine.mqh"
#include "SessionEngine.mqh"

//+------------------------------------------------------------------+
//| Classe CAIScoringEngine                                          |
//+------------------------------------------------------------------+
class CAIScoringEngine
  {
private:
   bool              m_initialized;

   //--- References aux moteurs
   CStrategicReversalEngine *m_sre;
   CSmartMoneyEngine        *m_smc;
   CICTEngine               *m_ict;
   COrderBlockEngine        *m_obe;
   CFVGEngine               *m_fvge;
   CLiquidityEngine         *m_le;
   CVolumeEngine            *m_ve;
   CVolatilityEngine        *m_vole;
   CSessionEngine           *m_se;

   //--- Ponderations (CDC v3)
   double            m_weight_sre;           // 30%
   double            m_weight_smc_ict;       // 25%
   double            m_weight_liquidity;     // 15%
   double            m_weight_ob;            // 10%
   double            m_weight_fvg;           // 10%
   double            m_weight_volume;        // 5%
   double            m_weight_volatility;    // 5%

   //--- Seuil minimum de signal
   double            m_min_score_threshold;  // Score minimum pour ouvrir un trade

   //--- Dernier score et cache
   SAIScore          m_last_score;
   SStrategicReversalSignal m_last_sre_signal;  // FIX: Cache du signal SRE
   double            m_last_smc_score;
   double            m_last_ict_score;
   double            m_last_liq_score;
   double            m_last_ob_score;
   double            m_last_fvg_score;
   double            m_last_vol_score;
   double            m_last_vole_score;

public:
   //--- Constructeur / Destructeur
                     CAIScoringEngine();
                    ~CAIScoringEngine();

   //--- Initialisation
   bool              Initialize(CStrategicReversalEngine *sre, CSmartMoneyEngine *smc,
                                 CICTEngine *ict, COrderBlockEngine *obe, CFVGEngine *fvge,
                                 CLiquidityEngine *le, CVolumeEngine *ve, CVolatilityEngine *vole,
                                 CSessionEngine *se,
                                 double min_threshold = 75.0);
   void              Deinitialize();

   //--- Calcul du score
   SAIScore          CalculateScore(const ENUM_SIGNAL_TYPE direction);

   //--- Accesseurs
   SAIScore          GetLastScore() const { return m_last_score; }
   double            GetMinThreshold() const { return m_min_score_threshold; }
   void              SetMinThreshold(double threshold) { m_min_score_threshold = threshold; }
   SStrategicReversalSignal GetLastSRESignal() const { return m_last_sre_signal; }

   //--- Verifications rapides
   bool              IsSignalValid(const ENUM_SIGNAL_TYPE direction);
   bool              MeetsAllCriteria(const ENUM_SIGNAL_TYPE direction) const;

   //--- Info
   string            GetScoreInfo(const SAIScore &score) const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CAIScoringEngine::CAIScoringEngine() :
   m_initialized(false),
   m_sre(NULL), m_smc(NULL), m_ict(NULL), m_obe(NULL), m_fvge(NULL),
   m_le(NULL), m_ve(NULL), m_vole(NULL), m_se(NULL),
   m_weight_sre(0.30),
   m_weight_smc_ict(0.25),
   m_weight_liquidity(0.15),
   m_weight_ob(0.10),
   m_weight_fvg(0.10),
   m_weight_volume(0.05),
   m_weight_volatility(0.05),
   m_min_score_threshold(75.0),
   m_last_smc_score(0),
   m_last_ict_score(0),
   m_last_liq_score(0),
   m_last_ob_score(0),
   m_last_fvg_score(0),
   m_last_vol_score(0),
   m_last_vole_score(0)
  {
   ZeroMemory(m_last_score);
   ZeroMemory(m_last_sre_signal);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CAIScoringEngine::~CAIScoringEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CAIScoringEngine::Initialize(CStrategicReversalEngine *sre, CSmartMoneyEngine *smc,
                                    CICTEngine *ict, COrderBlockEngine *obe, CFVGEngine *fvge,
                                    CLiquidityEngine *le, CVolumeEngine *ve, CVolatilityEngine *vole,
                                    CSessionEngine *se, double min_threshold)
  {
   if(sre == NULL || smc == NULL || ict == NULL || obe == NULL ||
      fvge == NULL || le == NULL || ve == NULL || vole == NULL || se == NULL)
     {
      Print("A2Sniper AI: Erreur - moteurs dependants NULL");
      return false;
     }

   m_sre = sre; m_smc = smc; m_ict = ict; m_obe = obe;
   m_fvge = fvge; m_le = le; m_ve = ve; m_vole = vole; m_se = se;
   m_min_score_threshold = min_threshold;

   //--- Verifier que les poids totalisent 100%
   double total = m_weight_sre + m_weight_smc_ict + m_weight_liquidity +
                  m_weight_ob + m_weight_fvg + m_weight_volume + m_weight_volatility;

   if(MathAbs(total - 1.0) > 0.01)
     {
      Print("A2Sniper AI: Erreur - poids total = ", total, " (devrait etre 1.0)");
      return false;
     }

   m_initialized = true;
   Print("A2Sniper AI: AI Scoring Engine initialise (seuil: ", m_min_score_threshold, "%)");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CAIScoringEngine::Deinitialize()
  {
   m_sre = NULL; m_smc = NULL; m_ict = NULL; m_obe = NULL;
   m_fvge = NULL; m_le = NULL; m_ve = NULL; m_vole = NULL; m_se = NULL;
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Calculer le score global pondere                                 |
//| FIX: Sauvegarder les sous-scores pour eviter de recalculer       |
//+------------------------------------------------------------------+
SAIScore CAIScoringEngine::CalculateScore(const ENUM_SIGNAL_TYPE direction)
  {
   SAIScore score;
   ZeroMemory(score);
   score.signal_type = direction;
   score.meets_threshold = false;

   if(!m_initialized)
      return score;

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- 1. Strategic Reversal Engine (30%)
   //--- FIX: Sauvegarder le signal SRE pour eviter un double appel
   m_last_sre_signal = m_sre->AnalyzeSignal(direction);
   double sre_score = (double)m_last_sre_signal.total_score;
   score.sre_weight = sre_score * m_weight_sre;

   //--- 2. Smart Money / ICT (25%)
   m_last_smc_score = m_smc->GetSMCScore(direction);
   m_last_ict_score = m_ict->GetICTScore(direction);
   double combined_smc_ict = (m_last_smc_score * 0.6 + m_last_ict_score * 0.4);
   score.smc_ict_weight = combined_smc_ict * m_weight_smc_ict;

   //--- 3. Liquidite (15%)
   m_last_liq_score = m_le->GetLiquidityScore(direction);
   score.liquidity_weight = m_last_liq_score * m_weight_liquidity;

   //--- 4. Order Blocks (10%)
   m_last_ob_score = m_obe->GetOBScoreAtPrice(current_price,
                     (direction == SIGNAL_BUY) ? OB_BULLISH : OB_BEARISH);
   score.ob_weight = m_last_ob_score * m_weight_ob;

   //--- 5. FVG (10%)
   m_last_fvg_score = m_fvge->GetFVGScoreAtPrice(current_price,
                      (direction == SIGNAL_BUY) ? FVG_BULLISH : FVG_BEARISH);
   score.fvg_weight = m_last_fvg_score * m_weight_fvg;

   //--- 6. Volume (5%)
   m_last_vol_score = m_ve->GetVolumeScoreForDirection(direction);
   score.volume_weight = m_last_vol_score * m_weight_volume;

   //--- 7. Volatilite (5%)
   m_last_vole_score = m_vole->GetVolatilityScore();
   score.volatility_weight = m_last_vole_score * m_weight_volatility;

   //--- Score total
   score.total_score = score.sre_weight + score.smc_ict_weight +
                        score.liquidity_weight + score.ob_weight +
                        score.fvg_weight + score.volume_weight +
                        score.volatility_weight;

   //--- Confiance (basee sur le nombre de moteurs qui confirment)
   int confirming_engines = 0;
   if(sre_score >= MIN_SIGNAL_SCORE_SNIPER) confirming_engines++;
   if(m_last_smc_score >= 50) confirming_engines++;
   if(m_last_ict_score >= 50) confirming_engines++;
   if(m_last_liq_score >= 50) confirming_engines++;
   if(m_last_ob_score >= 50) confirming_engines++;
   if(m_last_fvg_score >= 50) confirming_engines++;
   if(m_last_vol_score >= 50) confirming_engines++;
   if(m_last_vole_score >= 50) confirming_engines++;

   score.confidence = ((double)confirming_engines / 8.0) * 100.0;

   //--- Seuil: score total + SRE Sniper + assez de moteurs qui confirment
   //--- FIX: Ajouter des conditions supplementaires pour la fiabilite
   score.meets_threshold = (score.total_score >= m_min_score_threshold &&
                            m_last_sre_signal.total_score >= MIN_SIGNAL_SCORE_SNIPER &&
                            confirming_engines >= MIN_ENGINES_CONFIRMING);

   m_last_score = score;
   return score;
  }

//+------------------------------------------------------------------+
//| Le signal est-il valide ?                                        |
//+------------------------------------------------------------------+
bool CAIScoringEngine::IsSignalValid(const ENUM_SIGNAL_TYPE direction)
  {
   SAIScore score = CalculateScore(direction);
   return score.meets_threshold;
  }

//+------------------------------------------------------------------+
//| FIX: Implementation reelle de MeetsAllCriteria                   |
//| Verifie que TOUS les criteres minimums sont remplis              |
//+------------------------------------------------------------------+
bool CAIScoringEngine::MeetsAllCriteria(const ENUM_SIGNAL_TYPE direction) const
  {
   if(m_sre == NULL || m_smc == NULL || m_ve == NULL || m_vole == NULL)
      return false;

   //--- 1. SRE doit etre Sniper (>= 90)
   if(m_last_sre_signal.total_score < MIN_SIGNAL_SCORE_SNIPER)
      return false;

   //--- 2. SMC doit avoir un score minimum
   if(m_last_smc_score < MIN_MODULE_SCORE_SMC)
      return false;

   //--- 3. Liquidite doit etre presente
   if(m_last_liq_score < MIN_MODULE_SCORE_LIQ)
      return false;

   //--- 4. Volume doit etre present
   if(m_last_vol_score < MIN_MODULE_SCORE_VOL)
      return false;

   //--- 5. Volatilite acceptable
   if(m_last_vole_score < 10) // Au moins un score de volatilite
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Info du score                                                    |
//+------------------------------------------------------------------+
string CAIScoringEngine::GetScoreInfo(const SAIScore &score) const
  {
   string dir_str = (score.signal_type == SIGNAL_BUY) ? "BUY" :
                     (score.signal_type == SIGNAL_SELL) ? "SELL" : "NONE";

   return StringFormat("AI[%s]: Total=%.1f | SRE=%.1f(30%%) SMC/ICT=%.1f(25%%) Liq=%.1f(15%%) OB=%.1f(10%%) FVG=%.1f(10%%) Vol=%.1f(5%%) Vole=%.1f(5%%) | Conf=%.0f%% | Valid=%s",
                       dir_str, score.total_score,
                       score.sre_weight / m_weight_sre,
                       score.smc_ict_weight / m_weight_smc_ict,
                       score.liquidity_weight / m_weight_liquidity,
                       score.ob_weight / m_weight_ob,
                       score.fvg_weight / m_weight_fvg,
                       score.volume_weight / m_weight_volume,
                       score.volatility_weight / m_weight_volatility,
                       score.confidence,
                       score.meets_threshold ? "Y" : "N");
  }

#endif // A2SNIPER_AI_SCORING_MQH
//+------------------------------------------------------------------+
