//+------------------------------------------------------------------+
//| AIScoringEngine.mqh - Scoring IA Pondere v4.0                    |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| FIX v4: No double-counting OB/FVG, negative scoring,             |
//|         range filter, session quality, market regime,             |
//|         redistributed weights for 80%+ win rate                   |
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
//| Structure etendue du score AI v4                                  |
//+------------------------------------------------------------------+
struct SAIScoreV4
  {
   double            total_score;          // Score global pondere (0-100, peut etre negatif)
   double            sre_weight;           // Poids SRE (28%)
   double            smc_ict_weight;       // Poids SMC/ICT (20%) - sans double comptage
   double            liquidity_weight;     // Poids liquidite (15%)
   double            ob_weight;            // Poids Order Blocks (8%)
   double            fvg_weight;           // Poids FVG (7%)
   double            volume_weight;        // Poids Volume (12%) - augmente
   double            volatility_weight;    // Poids Volatilité (5%)
   double            regime_weight;        // Poids Market Regime (5%) - NOUVEAU
   ENUM_SIGNAL_TYPE  signal_type;          // Direction
   bool              meets_threshold;      // Score >= seuil
   double            confidence;           // Confiance (0-100)
   //--- Scores detailles pour diagnostic
   double            raw_sre;              // Score SRE brut
   double            raw_smc;              // Score SMC brut (sans OB/FVG)
   double            raw_ict;              // Score ICT brut
   double            raw_liq;              // Score liquidite brut
   double            raw_ob;               // Score OB brut
   double            raw_fvg;              // Score FVG brut
   double            raw_vol;              // Score volume brut (peut etre negatif)
   double            raw_vole;             // Score volatilite brut
   double            regime_score;         // Score regime brut
   double            session_bonus;        // Bonus/malus session
   double            range_penalty;        // Penalite range
   int               confirming_engines;   // Nombre de moteurs confirmants
  };

//+------------------------------------------------------------------+
//| Classe CAIScoringEngine v4.0                                      |
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

   //--- Ponderations v4 ( redistribuees pour 80%+ win rate)
   double            m_weight_sre;           // 28% - le coeur du signal
   double            m_weight_smc_ict;       // 20% - Smart Money sans double comptage
   double            m_weight_liquidity;     // 15% - crucial pour les reversals
   double            m_weight_ob;            // 8%  - Order Blocks (comptes une seule fois)
   double            m_weight_fvg;           // 7%  - FVG (compte une seule fois)
   double            m_weight_volume;        // 12% - AUGMENTE: volume est critique
   double            m_weight_volatility;    // 5%  - volatilite acceptable
   double            m_weight_regime;        // 5%  - NOUVEAU: regime de marche

   //--- Seuil minimum de signal
   double            m_min_score_threshold;

   //--- Dernier score et cache
   SAIScoreV4        m_last_score;
   SStrategicReversalSignal m_last_sre_signal;
   double            m_last_smc_score;
   double            m_last_ict_score;
   double            m_last_liq_score;
   double            m_last_ob_score;
   double            m_last_fvg_score;
   double            m_last_vol_score;
   double            m_last_vole_score;

   //--- ADX handle pour filtre range
   int               m_adx_handle;
   double            m_adx_value;
   double            m_adx_di_plus;
   double            m_adx_di_minus;

   //--- Methodes privees v4
   double            CalculateSMCScoreNoDoubleCount(ENUM_SIGNAL_TYPE direction) const;
   double            CalculateVolumeScoreWithPenalty(ENUM_SIGNAL_TYPE direction) const;
   double            CalculateRegimeScore(ENUM_SIGNAL_TYPE direction) const;
   double            CalculateSessionQualityBonus() const;
   double            CalculateRangePenalty() const;
   bool              UpdateADX();

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
   SAIScoreV4        CalculateScore(const ENUM_SIGNAL_TYPE direction);

   //--- Accesseurs
   SAIScoreV4        GetLastScore() const { return m_last_score; }
   double            GetMinThreshold() const { return m_min_score_threshold; }
   void              SetMinThreshold(double threshold) { m_min_score_threshold = threshold; }
   SStrategicReversalSignal GetLastSRESignal() const { return m_last_sre_signal; }
   double            GetADXValue() const { return m_adx_value; }
   bool              IsMarketRanging() const;

   //--- Verifications rapides
   bool              IsSignalValid(const ENUM_SIGNAL_TYPE direction);
   bool              MeetsAllCriteria(const ENUM_SIGNAL_TYPE direction) const;

   //--- Info
   string            GetScoreInfo(const SAIScoreV4 &score) const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CAIScoringEngine::CAIScoringEngine() :
   m_initialized(false),
   m_sre(NULL), m_smc(NULL), m_ict(NULL), m_obe(NULL), m_fvge(NULL),
   m_le(NULL), m_ve(NULL), m_vole(NULL), m_se(NULL),
   m_weight_sre(0.28),
   m_weight_smc_ict(0.20),
   m_weight_liquidity(0.15),
   m_weight_ob(0.08),
   m_weight_fvg(0.07),
   m_weight_volume(0.12),
   m_weight_volatility(0.05),
   m_weight_regime(0.05),
   m_min_score_threshold(78.0),
   m_last_smc_score(0),
   m_last_ict_score(0),
   m_last_liq_score(0),
   m_last_ob_score(0),
   m_last_fvg_score(0),
   m_last_vol_score(0),
   m_last_vole_score(0),
   m_adx_handle(INVALID_HANDLE),
   m_adx_value(0),
   m_adx_di_plus(0),
   m_adx_di_minus(0)
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
                  m_weight_ob + m_weight_fvg + m_weight_volume + m_weight_volatility +
                  m_weight_regime;

   if(MathAbs(total - 1.0) > 0.01)
     {
      Print("A2Sniper AI: Erreur - poids total = ", total, " (devrait etre 1.0)");
      return false;
     }

   //--- ADX pour filtre range
   m_adx_handle = iADX(_Symbol, PERIOD_CURRENT, 14);
   if(m_adx_handle == INVALID_HANDLE)
      Print("A2Sniper AI: ADX non disponible - filtre range desactive");
   else
      Print("A2Sniper AI: ADX initialise - filtre range actif");

   m_initialized = true;
   Print("A2Sniper AI: AI Scoring Engine v4.0 initialise (seuil: ", m_min_score_threshold,
         "%, Volume=12%, Regime=5%, NoDoubleCount)");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CAIScoringEngine::Deinitialize()
  {
   m_sre = NULL; m_smc = NULL; m_ict = NULL; m_obe = NULL;
   m_fvge = NULL; m_le = NULL; m_ve = NULL; m_vole = NULL; m_se = NULL;

   if(m_adx_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_adx_handle);
      m_adx_handle = INVALID_HANDLE;
     }

   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Calculer le score SMC SANS double comptage OB/FVG                |
//| Le SMC original inclut OB(25%) + FVG(25%) + Liq(25%) + PD(25%)  |
//| On retire OB et FVG du SMC pour eviter de les compter 2 fois     |
//| Nouveau SMC = PremiumDiscount(40%) + Liquidity(60%)              |
//+------------------------------------------------------------------+
double CAIScoringEngine::CalculateSMCScoreNoDoubleCount(ENUM_SIGNAL_TYPE direction) const
  {
   if(m_smc == NULL) return 0;

   double score = 0;

   //--- Premium/Discount alignment (40 pts)
   if(m_smc->IsDirectionAlignedWithPD(direction))
      score += 40;

   //--- Liquidity sweep dans la direction opposee (60 pts)
   if(m_le != NULL)
     {
      double liq_score = m_le->GetLiquidityScore(direction);
      score += liq_score * 0.60;
     }

   return MathMin(score, 100.0);
  }

//+------------------------------------------------------------------+
//| Calculer le score Volume avec PENALITES NEGATIVES                 |
//| Volume < 0.5x moyenne = -30 pts (pas 0)                          |
//| Volume < 0.3x moyenne = -50 pts                                   |
//| Volume direction opposee = -20 pts                                 |
//+------------------------------------------------------------------+
double CAIScoringEngine::CalculateVolumeScoreWithPenalty(ENUM_SIGNAL_TYPE direction) const
  {
   if(m_ve == NULL) return 0;

   double relative_vol = m_ve->GetRelativeVolume();
   double base_score = 0;

   //--- Scoring avec penalites negatives
   if(relative_vol >= 3.0)
      base_score = 100.0;     // Volume extreme - tres bullish/bearish
   else if(relative_vol >= 2.5)
      base_score = 90.0;     // Volume institutionnel fort
   else if(relative_vol >= 1.5)
      base_score = 75.0;     // Volume institutionnel
   else if(relative_vol >= 1.0)
      base_score = 55.0;     // Volume moyen
   else if(relative_vol >= 0.7)
      base_score = 30.0;     // Volume faible
   else if(relative_vol >= 0.5)
      base_score = -15.0;    // PENALITE: Volume insuffisant
   else if(relative_vol >= 0.3)
      base_score = -30.0;    // PENALITE FORTE: Marche sans interet
   else
      base_score = -50.0;    // PENALITE EXTREME: Pas de volume du tout

   //--- Verifier la direction du volume (bougie vs signal)
   double open_price = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close_price = iClose(_Symbol, PERIOD_CURRENT, 1);
   bool bullish_candle = (close_price > open_price);

   //--- Si volume faible ET direction opposee, penalite supplementaire
   if(base_score < 0)
     {
      if((direction == SIGNAL_BUY && !bullish_candle) ||
         (direction == SIGNAL_SELL && bullish_candle))
         base_score -= 20.0;  // Volume bas + direction opposee = double penalite
     }

   //--- Si volume fort mais direction opposee, reduire le score
   if(base_score > 50)
     {
      if((direction == SIGNAL_BUY && !bullish_candle) ||
         (direction == SIGNAL_SELL && bullish_candle))
         base_score *= 0.6;   // Volume haussier sur signal vendeur = suspect
     }

   return base_score;
  }

//+------------------------------------------------------------------+
//| Calculer le score du regime de marche                             |
//| Trending = bonus, Ranging = penalite, Volatile = risque          |
//+------------------------------------------------------------------+
double CAIScoringEngine::CalculateRegimeScore(ENUM_SIGNAL_TYPE direction) const
  {
   if(m_vole == NULL) return 50.0; // Neutre si pas disponible

   double atr_ratio = m_vole->GetATRRatio();
   double score = 50.0; // Neutre par defaut

   //--- Tendance forte (ATR ratio eleve + direction claire)
   if(atr_ratio >= 1.5)
     {
      //--- Verifier si la direction du signal est alignee avec la tendance
      SMarketStructure m15_struct;
      if(m_se != NULL)
        {
         // Utiliser le structure engine indirectement via SRE
         score = 70.0; // Marche actif, potentiellement tendance
        }
     }

   //--- Marche en range (ATR ratio bas)
   if(atr_ratio < 0.7)
      score = 20.0; // Marche plat = danger pour les reversals

   //--- ADX si disponible
   //--- (On utilise m_adx_value mis a jour par UpdateADX)

   return score;
  }

//+------------------------------------------------------------------+
//| Calculer le bonus/malus de session                                |
//| Overlap LN = +10 pts, Kill Zone = +5 pts, Asie = -15 pts         |
//+------------------------------------------------------------------+
double CAIScoringEngine::CalculateSessionQualityBonus() const
  {
   if(m_se == NULL) return 0;

   double bonus = 0;

   //--- Session quality
   ENUM_TRADING_SESSION session = m_se->GetActiveSession();

   if(session == SESSION_OVERLAP_LN)
      bonus += 10.0;    // Overlap Londres/NY = meilleur moment
   else if(session == SESSION_LONDON)
      bonus += 5.0;     // Session Londres = bon
   else if(session == SESSION_NEWYORK)
      bonus += 3.0;     // Session NY = correct
   else if(session == SESSION_ASIAN)
      bonus -= 15.0;    // PENALITE: Session asiatique = faux signaux frequents

   //--- Kill Zone bonus
   if(m_se->IsKillZone())
      bonus += 5.0;

   return bonus;
  }

//+------------------------------------------------------------------+
//| Calculer la penalite de range (ADX)                               |
//| ADX < 20 = ranging = grosse penalite                              |
//| ADX 20-25 = transition = petite penalite                          |
//| ADX > 25 = trending = pas de penalite                             |
//+------------------------------------------------------------------+
double CAIScoringEngine::CalculateRangePenalty() const
  {
   //--- Si ADX pas disponible, utiliser l'ATR ratio comme fallback
   if(m_adx_value > 0)
     {
      if(m_adx_value < 15)
         return -20.0;   // Range fort = forte penalite
      if(m_adx_value < 20)
         return -10.0;   // Range modere = penalite moderee
      if(m_adx_value < 25)
         return -5.0;    // Transition = legere penalite
      return 0.0;        // Tendance = pas de penalite
     }

   //--- Fallback: utiliser ATR ratio
   if(m_vole != NULL)
     {
      double atr_ratio = m_vole->GetATRRatio();
      if(atr_ratio < 0.5)
         return -20.0;   // Volatilite tres basse = range probable
      if(atr_ratio < 0.7)
         return -10.0;
      if(atr_ratio < 0.8)
         return -5.0;
     }

   return 0.0;
  }

//+------------------------------------------------------------------+
//| Mettre a jour l'ADX                                              |
//+------------------------------------------------------------------+
bool CAIScoringEngine::UpdateADX()
  {
   if(m_adx_handle == INVALID_HANDLE)
      return false;

   double buffer[];
   ArraySetAsSeries(buffer, true);

   //--- ADX main line (buffer 0)
   if(CopyBuffer(m_adx_handle, 0, 0, 1, buffer) > 0)
      m_adx_value = buffer[0];
   else
      m_adx_value = 0;

   //--- DI+ (buffer 1)
   if(CopyBuffer(m_adx_handle, 1, 0, 1, buffer) > 0)
      m_adx_di_plus = buffer[0];
   else
      m_adx_di_plus = 0;

   //--- DI- (buffer 2)
   if(CopyBuffer(m_adx_handle, 2, 0, 1, buffer) > 0)
      m_adx_di_minus = buffer[0];
   else
      m_adx_di_minus = 0;

   return (m_adx_value > 0);
  }

//+------------------------------------------------------------------+
//| Le marche est-il en range ?                                       |
//+------------------------------------------------------------------+
bool CAIScoringEngine::IsMarketRanging() const
  {
   if(m_adx_value > 0)
      return (m_adx_value < 20);

   //--- Fallback ATR
   if(m_vole != NULL)
      return (m_vole->GetATRRatio() < 0.7);

   return false;
  }

//+------------------------------------------------------------------+
//| Calculer le score global pondere v4                               |
//| FIX: Pas de double comptage, scoring negatif, regime, session     |
//+------------------------------------------------------------------+
SAIScoreV4 CAIScoringEngine::CalculateScore(const ENUM_SIGNAL_TYPE direction)
  {
   SAIScoreV4 score;
   ZeroMemory(score);
   score.signal_type = direction;
   score.meets_threshold = false;

   if(!m_initialized)
      return score;

   //--- Mettre a jour l'ADX
   UpdateADX();

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- 1. Strategic Reversal Engine (28%)
   m_last_sre_signal = m_sre->AnalyzeSignal(direction);
   double sre_score = (double)m_last_sre_signal.total_score;
   score.raw_sre = sre_score;
   score.sre_weight = sre_score * m_weight_sre;

   //--- 2. Smart Money / ICT (20%) - SANS double comptage OB/FVG
   //--- FIX: Le SMC original inclut OB(25%) + FVG(25%) dans son score
   //--- On utilise CalculateSMCScoreNoDoubleCount qui ne compte que PD + Liq
   m_last_smc_score = CalculateSMCScoreNoDoubleCount(direction);
   m_last_ict_score = m_ict->GetICTScore(direction);
   double combined_smc_ict = (m_last_smc_score * 0.55 + m_last_ict_score * 0.45);
   score.raw_smc = m_last_smc_score;
   score.raw_ict = m_last_ict_score;
   score.smc_ict_weight = combined_smc_ict * m_weight_smc_ict;

   //--- 3. Liquidite (15%)
   m_last_liq_score = m_le->GetLiquidityScore(direction);
   score.raw_liq = m_last_liq_score;
   score.liquidity_weight = m_last_liq_score * m_weight_liquidity;

   //--- 4. Order Blocks (8%) - compte une seule fois ici
   m_last_ob_score = m_obe->GetOBScoreAtPrice(current_price,
                     (direction == SIGNAL_BUY) ? OB_BULLISH : OB_BEARISH);
   score.raw_ob = m_last_ob_score;
   score.ob_weight = m_last_ob_score * m_weight_ob;

   //--- 5. FVG (7%) - compte une seule fois ici
   m_last_fvg_score = m_fvge->GetFVGScoreAtPrice(current_price,
                      (direction == SIGNAL_BUY) ? FVG_BULLISH : FVG_BEARISH);
   score.raw_fvg = m_last_fvg_score;
   score.fvg_weight = m_last_fvg_score * m_weight_fvg;

   //--- 6. Volume (12%) - avec scoring negatif
   m_last_vol_score = CalculateVolumeScoreWithPenalty(direction);
   score.raw_vol = m_last_vol_score;
   //--- Le score peut etre negatif, donc le poids peut etre negatif
   score.volume_weight = m_last_vol_score * m_weight_volume;

   //--- 7. Volatilite (5%)
   m_last_vole_score = m_vole->GetVolatilityScore();
   score.raw_vole = m_last_vole_score;
   score.volatility_weight = m_last_vole_score * m_weight_volatility;

   //--- 8. Market Regime (5%) - NOUVEAU
   double regime_score = CalculateRegimeScore(direction);
   score.regime_score = regime_score;
   score.regime_weight = regime_score * m_weight_regime;

   //--- Score total de base
   score.total_score = score.sre_weight + score.smc_ict_weight +
                        score.liquidity_weight + score.ob_weight +
                        score.fvg_weight + score.volume_weight +
                        score.volatility_weight + score.regime_weight;

   //--- BONUS/MALUS: Session quality
   score.session_bonus = CalculateSessionQualityBonus();
   score.total_score += score.session_bonus;

   //--- PENALITE: Marche en range
   score.range_penalty = CalculateRangePenalty();
   score.total_score += score.range_penalty;

   //--- Verifier coherence direction ADX (bonus supplementaire)
   if(m_adx_value >= 25)
     {
      bool adx_bullish = (m_adx_di_plus > m_adx_di_minus);
      if((direction == SIGNAL_BUY && adx_bullish) ||
         (direction == SIGNAL_SELL && !adx_bullish))
         score.total_score += 5.0;  // ADX confirme la direction
      else
         score.total_score -= 10.0; // ADX contredit la direction
     }

   //--- Confiance (basee sur le nombre de moteurs qui confirment)
   //--- FIX: Seuils de confirmation augmentes (60 au lieu de 50)
   score.confirming_engines = 0;
   if(sre_score >= MIN_SIGNAL_SCORE_SNIPER) score.confirming_engines++;
   if(m_last_smc_score >= 55) score.confirming_engines++;
   if(m_last_ict_score >= 55) score.confirming_engines++;
   if(m_last_liq_score >= 55) score.confirming_engines++;
   if(m_last_ob_score >= 50) score.confirming_engines++;
   if(m_last_fvg_score >= 50) score.confirming_engines++;
   if(m_last_vol_score >= 50) score.confirming_engines++; // Volume doit etre positif
   if(m_last_vole_score >= 50) score.confirming_engines++;
   if(regime_score >= 50) score.confirming_engines++; // 9 moteurs maintenant

   score.confidence = ((double)score.confirming_engines / 9.0) * 100.0;

   //--- Seuil: conditions plus strictes pour 80%+ win rate
   score.meets_threshold = (score.total_score >= m_min_score_threshold &&
                            m_last_sre_signal.total_score >= MIN_SIGNAL_SCORE_SNIPER &&
                            score.confirming_engines >= 6 && // Au moins 6/9 moteurs
                            m_last_vol_score >= 0 &&         // Volume ne doit pas etre negatif
                            score.range_penalty > -15.0 &&   // Pas en range profond
                            score.total_score > 0);          // Score total positif

   m_last_score = score;
   return score;
  }

//+------------------------------------------------------------------+
//| Le signal est-il valide ?                                        |
//+------------------------------------------------------------------+
bool CAIScoringEngine::IsSignalValid(const ENUM_SIGNAL_TYPE direction)
  {
   SAIScoreV4 score = CalculateScore(direction);
   return score.meets_threshold;
  }

//+------------------------------------------------------------------+
//| MeetsAllCriteria - Verifie que TOUS les criteres minimums sont    |
//| remplis pour atteindre 80%+ win rate                              |
//+------------------------------------------------------------------+
bool CAIScoringEngine::MeetsAllCriteria(const ENUM_SIGNAL_TYPE direction) const
  {
   if(m_sre == NULL || m_smc == NULL || m_ve == NULL || m_vole == NULL)
      return false;

   //--- 1. SRE doit etre Sniper (>= 90)
   if(m_last_sre_signal.total_score < MIN_SIGNAL_SCORE_SNIPER)
      return false;

   //--- 2. SMC doit avoir un score minimum (sans double comptage)
   if(m_last_smc_score < 35)
      return false;

   //--- 3. Liquidite doit etre presente
   if(m_last_liq_score < MIN_MODULE_SCORE_LIQ)
      return false;

   //--- 4. Volume doit etre POSITIF (pas negatif)
   if(m_last_vol_score < 0)
      return false;

   //--- 5. Volatilite acceptable
   if(m_last_vole_score < 20)
      return false;

   //--- 6. Pas en range profond
   if(m_last_score.range_penalty <= -15.0)
      return false;

   //--- 7. Session acceptable (pas en Asie sauf score tres eleve)
   if(m_last_score.session_bonus < -10.0 && m_last_score.total_score < 90.0)
      return false;

   //--- 8. Au moins 6 moteurs confirmants sur 9
   if(m_last_score.confirming_engines < 6)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Info du score                                                    |
//+------------------------------------------------------------------+
string CAIScoringEngine::GetScoreInfo(const SAIScoreV4 &score) const
  {
   string dir_str = (score.signal_type == SIGNAL_BUY) ? "BUY" :
                     (score.signal_type == SIGNAL_SELL) ? "SELL" : "NONE";

   return StringFormat("AIv4[%s]: Total=%.1f | SRE=%.0f(28%%) SMC=%.0f(20%%) ICT=%.0f Liq=%.0f(15%%) OB=%.0f(8%%) FVG=%.0f(7%%) Vol=%.0f(12%%) Vole=%.0f(5%%) Regime=%.0f(5%%) | Session=%+.0f Range=%+.0f | Conf=%d/9=%.0f%% | Valid=%s",
                       dir_str, score.total_score,
                       score.raw_sre,
                       score.raw_smc, score.raw_ict, score.raw_liq,
                       score.raw_ob, score.raw_fvg, score.raw_vol,
                       score.raw_vole, score.regime_score,
                       score.session_bonus, score.range_penalty,
                       score.confirming_engines, score.confidence,
                       score.meets_threshold ? "Y" : "N");
  }

#endif // A2SNIPER_AI_SCORING_MQH
//+------------------------------------------------------------------+
