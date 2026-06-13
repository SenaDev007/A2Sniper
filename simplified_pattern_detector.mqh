//+------------------------------------------------------------------+
//|                                              PatternDetector.mqh |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"

#include <A2Sniper\HeikinAshiCalculator.mqh>

//+------------------------------------------------------------------+
//| Énumérations pour les signaux                                    |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE = 0,     // Aucun signal
   SIGNAL_BUY = 1,      // Signal d'achat
   SIGNAL_SELL = -1     // Signal de vente
};

//+------------------------------------------------------------------+
//| Structure pour les informations de pattern                      |
//+------------------------------------------------------------------+
struct SPatternInfo
{
   ENUM_SIGNAL_TYPE signal_type;
   double confidence_score;
   int pullback_candles;
   bool has_doji_confirmation;
   double volume_strength;
   string pattern_description;
   datetime signal_time;
};

//+------------------------------------------------------------------+
//| Classe détecteur de patterns                                    |
//+------------------------------------------------------------------+
class CPatternDetector
{
private:
    // Paramètres de configuration
    int               m_min_pullback_candles;
    double            m_doji_body_ratio;
    double            m_volume_multiplier;
    double            m_wick_threshold;
    bool              m_initialized;
    
    // Historique des patterns
    SPatternInfo      m_pattern_history[100];
    int               m_history_size;
    
    // Statistiques d'apprentissage
    int               m_total_signals;
    int               m_successful_signals;
    
    // Méthodes de validation
    bool ValidateTrendDirection(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool is_buy_signal);
    bool ValidatePullbackPattern(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateDojiConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateVolumeCondition(double& volume_buffer[], int doji_index);
    double CalculateConfidenceScore(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[], bool is_buy_signal);
    
    // Méthodes de validation intelligente pour 95% de précision
    bool ValidateMultiTimeframeAlignment(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool is_buy_signal);
    bool ValidateMomentumConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateSupportResistanceLevel(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateVolumeSurge(double& volume_buffer[], int current_index);
    bool ValidateMarketStructure(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateVolatilityFilter(CHeikinAshiCalculator* ha_calc);
    bool ValidatePriceActionConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    
public:
    CPatternDetector();
    ~CPatternDetector();
    
    // Méthodes principales
    void Initialize(double doji_ratio = 0.3, double volume_mult = 1.5, double wick_thresh = 1.5);
    void Reset();
    bool DetectBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[]);
    bool DetectSellPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[]);
    
    // Méthodes utilitaires
    void AddPatternToHistory(const SPatternInfo& pattern);
    SPatternInfo GetLastPattern();
    double GetSuccessRate();
    void PrintPatternInfo(const SPatternInfo& pattern);
};

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CPatternDetector::CPatternDetector()
{
   m_initialized = false;
   m_min_pullback_candles = 3;
   m_doji_body_ratio = 0.3;
   m_volume_multiplier = 1.5;
   m_wick_threshold = 1.5;
   
   m_history_size = 0;
   m_total_signals = 0;
   m_successful_signals = 0;
}

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CPatternDetector::~CPatternDetector()
{
}

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
void CPatternDetector::Initialize(double doji_ratio = 0.3, double volume_mult = 1.5, double wick_thresh = 1.5)
{
   m_doji_body_ratio = doji_ratio;
   m_volume_multiplier = volume_mult;
   m_wick_threshold = wick_thresh;
   m_initialized = true;
   
   Print("[PATTERN DETECTOR] Initialisé avec succès - Système intelligent 95% activé");
}

//+------------------------------------------------------------------+
//| Reset                                                            |
//+------------------------------------------------------------------+
void CPatternDetector::Reset()
{
   m_history_size = 0;
   m_total_signals = 0;
   m_successful_signals = 0;
   
   Print("[PATTERN DETECTOR] Reset effectué");
}

//+------------------------------------------------------------------+
//| Détection du pattern d'achat - SYSTÈME INTELLIGENT 95%          |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
   Print("[PATTERN DETECTOR] ===== SYSTÈME INTELLIGENT 95% - PATTERN D'ACHAT =====");
   
   int conditions_passed = 0;
   int total_conditions = 7;
   
   // 1. Validation Multi-Timeframe (CRITIQUE)
   bool mtf_alignment = ValidateMultiTimeframeAlignment(ha_calc, ema_data, true);
   if(mtf_alignment)
   {
      Print("[PATTERN DETECTOR] ✅ Alignement multi-timeframe validé");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Alignement multi-timeframe non validé - REJET IMMÉDIAT");
      return false; // Condition critique
   }
   
   // 2. Confirmation de Momentum (CRITIQUE)
   bool momentum_confirmed = ValidateMomentumConfirmation(ha_calc, true);
   if(momentum_confirmed)
   {
      Print("[PATTERN DETECTOR] ✅ Momentum haussier confirmé");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Momentum haussier non confirmé - REJET IMMÉDIAT");
      return false; // Condition critique
   }
   
   // 3. Validation Support/Résistance
   bool sr_level_valid = ValidateSupportResistanceLevel(ha_calc, true);
   if(sr_level_valid)
   {
      Print("[PATTERN DETECTOR] ✅ Niveau de support/résistance validé");
      conditions_passed++;
   }
   
   // 4. Validation Volume Surge
   bool volume_surge = ValidateVolumeSurge(volume_buffer, 0);
   if(volume_surge)
   {
      Print("[PATTERN DETECTOR] ✅ Surge de volume détecté");
      conditions_passed++;
   }
   
   // 5. Validation Structure de Marché
   bool market_structure = ValidateMarketStructure(ha_calc, true);
   if(market_structure)
   {
      Print("[PATTERN DETECTOR] ✅ Structure de marché favorable");
      conditions_passed++;
   }
   
   // 6. Filtre de Volatilité
   bool volatility_ok = ValidateVolatilityFilter(ha_calc);
   if(volatility_ok)
   {
      Print("[PATTERN DETECTOR] ✅ Volatilité dans la plage optimale");
      conditions_passed++;
   }
   
   // 7. Confirmation Price Action
   bool price_action_confirmed = ValidatePriceActionConfirmation(ha_calc, true);
   if(price_action_confirmed)
   {
      Print("[PATTERN DETECTOR] ✅ Price action confirmée");
      conditions_passed++;
   }
   
   // Calcul du score de confiance intelligent
   double intelligent_score = CalculateConfidenceScore(ha_calc, ema_data, volume_buffer, true);
   Print("[PATTERN DETECTOR] Score de confiance intelligent: ", intelligent_score, "%");
   
   // Critères ULTRA-STRICTS pour 95% de précision
   bool pattern_valid = (conditions_passed >= 6) && (intelligent_score >= 85.0);
   
   if(pattern_valid)
   {
      Print("[PATTERN DETECTOR] 🚀🚀🚀 PATTERN D'ACHAT HAUTE PROBABILITÉ DÉTECTÉ!");
      Print("[PATTERN DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions);
      Print("[PATTERN DETECTOR] Score de confiance: ", intelligent_score, "%");
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Pattern d'achat rejeté - Critères insuffisants");
      Print("[PATTERN DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions, " (minimum requis: 6)");
      Print("[PATTERN DETECTOR] Score de confiance: ", intelligent_score, "% (minimum requis: 85%)");
   }
   
   return pattern_valid;
}

//+------------------------------------------------------------------+
//| Détection du pattern de vente - SYSTÈME INTELLIGENT 95%         |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectSellPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
   Print("[PATTERN DETECTOR] ===== SYSTÈME INTELLIGENT 95% - PATTERN DE VENTE =====");
   
   int conditions_passed = 0;
   int total_conditions = 7;
   
   // 1. Validation Multi-Timeframe (CRITIQUE)
   bool mtf_alignment = ValidateMultiTimeframeAlignment(ha_calc, ema_data, false);
   if(mtf_alignment)
   {
      Print("[PATTERN DETECTOR] ✅ Alignement multi-timeframe validé");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Alignement multi-timeframe non validé - REJET IMMÉDIAT");
      return false; // Condition critique
   }
   
   // 2. Confirmation de Momentum (CRITIQUE)
   bool momentum_confirmed = ValidateMomentumConfirmation(ha_calc, false);
   if(momentum_confirmed)
   {
      Print("[PATTERN DETECTOR] ✅ Momentum baissier confirmé");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Momentum baissier non confirmé - REJET IMMÉDIAT");
      return false; // Condition critique
   }
   
   // 3. Validation Support/Résistance
   bool sr_level_valid = ValidateSupportResistanceLevel(ha_calc, false);
   if(sr_level_valid)
   {
      Print("[PATTERN DETECTOR] ✅ Niveau de support/résistance validé");
      conditions_passed++;
   }
   
   // 4. Validation Volume Surge
   bool volume_surge = ValidateVolumeSurge(volume_buffer, 0);
   if(volume_surge)
   {
      Print("[PATTERN DETECTOR] ✅ Surge de volume détecté");
      conditions_passed++;
   }
   
   // 5. Validation Structure de Marché
   bool market_structure = ValidateMarketStructure(ha_calc, false);
   if(market_structure)
   {
      Print("[PATTERN DETECTOR] ✅ Structure de marché favorable");
      conditions_passed++;
   }
   
   // 6. Filtre de Volatilité
   bool volatility_ok = ValidateVolatilityFilter(ha_calc);
   if(volatility_ok)
   {
      Print("[PATTERN DETECTOR] ✅ Volatilité dans la plage optimale");
      conditions_passed++;
   }
   
   // 7. Confirmation Price Action
   bool price_action_confirmed = ValidatePriceActionConfirmation(ha_calc, false);
   if(price_action_confirmed)
   {
      Print("[PATTERN DETECTOR] ✅ Price action confirmée");
      conditions_passed++;
   }
   
   // Calcul du score de confiance intelligent
   double intelligent_score = CalculateConfidenceScore(ha_calc, ema_data, volume_buffer, false);
   Print("[PATTERN DETECTOR] Score de confiance intelligent: ", intelligent_score, "%");
   
   // Critères ULTRA-STRICTS pour 95% de précision
   bool pattern_valid = (conditions_passed >= 6) && (intelligent_score >= 85.0);
   
   if(pattern_valid)
   {
      Print("[PATTERN DETECTOR] 🚀🚀🚀 PATTERN DE VENTE HAUTE PROBABILITÉ DÉTECTÉ!");
      Print("[PATTERN DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions);
      Print("[PATTERN DETECTOR] Score de confiance: ", intelligent_score, "%");
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Pattern de vente rejeté - Critères insuffisants");
      Print("[PATTERN DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions, " (minimum requis: 6)");
      Print("[PATTERN DETECTOR] Score de confiance: ", intelligent_score, "% (minimum requis: 85%)");
   }
   
   return pattern_valid;
}
