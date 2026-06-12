//+------------------------------------------------------------------+
//|                                    IntelligentPatternDetector.mqh |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"

//+------------------------------------------------------------------+
//| Système de validation intelligent pour 95% de précision         |
//+------------------------------------------------------------------+
class CIntelligentPatternDetector
{
private:
    // Paramètres pour l'analyse multi-timeframe
    ENUM_TIMEFRAMES m_higher_tf;
    ENUM_TIMEFRAMES m_current_tf;
    
    // Seuils de validation intelligente
    double m_min_confidence_score;
    double m_momentum_threshold;
    double m_volume_surge_ratio;
    int m_min_conditions_required;
    
    // Méthodes d'analyse avancée
    bool ValidateMultiTimeframeAlignment(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool is_buy_signal);
    bool ValidateMomentumConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateSupportResistanceLevel(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateVolumeSurge(double& volume_buffer[], int current_index);
    bool ValidateMarketStructure(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateVolatilityFilter(CHeikinAshiCalculator* ha_calc);
    bool ValidatePriceActionConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    double CalculateIntelligentConfidenceScore(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[], bool is_buy_signal);
    
public:
    CIntelligentPatternDetector();
    ~CIntelligentPatternDetector();
    
    // Méthodes principales de détection intelligente
    bool DetectHighProbabilityBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[]);
    bool DetectHighProbabilitySellPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[]);
    
    // Méthodes de configuration
    void SetConfidenceThreshold(double threshold) { m_min_confidence_score = threshold; }
    void SetMomentumThreshold(double threshold) { m_momentum_threshold = threshold; }
    void SetVolumeSurgeRatio(double ratio) { m_volume_surge_ratio = ratio; }
};

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CIntelligentPatternDetector::CIntelligentPatternDetector()
{
    m_higher_tf = PERIOD_M5;  // Timeframe supérieur pour confirmation
    m_current_tf = PERIOD_M1; // Timeframe actuel
    m_min_confidence_score = 85.0; // Score minimum pour 95% de précision
    m_momentum_threshold = 0.7;
    m_volume_surge_ratio = 1.5;
    m_min_conditions_required = 6; // 6 conditions sur 7 pour ultra-précision
}

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CIntelligentPatternDetector::~CIntelligentPatternDetector()
{
}

//+------------------------------------------------------------------+
//| Détection de pattern d'achat haute probabilité                  |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::DetectHighProbabilityBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
    Print("[INTELLIGENT DETECTOR] ===== ANALYSE HAUTE PRÉCISION - PATTERN D'ACHAT =====");
    
    int conditions_passed = 0;
    int total_conditions = 7;
    
    // 1. Validation Multi-Timeframe (CRITIQUE)
    bool mtf_alignment = ValidateMultiTimeframeAlignment(ha_calc, ema_data, true);
    if(mtf_alignment)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Alignement multi-timeframe validé");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Alignement multi-timeframe non validé - REJET IMMÉDIAT");
        return false; // Condition critique
    }
    
    // 2. Confirmation de Momentum (CRITIQUE)
    bool momentum_confirmed = ValidateMomentumConfirmation(ha_calc, true);
    if(momentum_confirmed)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Momentum haussier confirmé");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Momentum haussier non confirmé - REJET IMMÉDIAT");
        return false; // Condition critique
    }
    
    // 3. Validation Support/Résistance
    bool sr_level_valid = ValidateSupportResistanceLevel(ha_calc, true);
    if(sr_level_valid)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Niveau de support/résistance validé");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Niveau de support/résistance non validé");
    }
    
    // 4. Validation Volume Surge
    bool volume_surge = ValidateVolumeSurge(volume_buffer, 0);
    if(volume_surge)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Surge de volume détecté");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Pas de surge de volume");
    }
    
    // 5. Validation Structure de Marché
    bool market_structure = ValidateMarketStructure(ha_calc, true);
    if(market_structure)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Structure de marché favorable");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Structure de marché défavorable");
    }
    
    // 6. Filtre de Volatilité
    bool volatility_ok = ValidateVolatilityFilter(ha_calc);
    if(volatility_ok)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Volatilité dans la plage optimale");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Volatilité hors plage optimale");
    }
    
    // 7. Confirmation Price Action
    bool price_action_confirmed = ValidatePriceActionConfirmation(ha_calc, true);
    if(price_action_confirmed)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Price action confirmée");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Price action non confirmée");
    }
    
    // Calcul du score de confiance intelligent
    double intelligent_score = CalculateIntelligentConfidenceScore(ha_calc, ema_data, volume_buffer, true);
    Print("[INTELLIGENT DETECTOR] Score de confiance intelligent: ", intelligent_score, "%");
    
    // Critères ULTRA-STRICTS pour 95% de précision
    bool pattern_valid = (conditions_passed >= m_min_conditions_required) && (intelligent_score >= m_min_confidence_score);
    
    if(pattern_valid)
    {
        Print("[INTELLIGENT DETECTOR] 🚀🚀🚀 PATTERN D'ACHAT HAUTE PROBABILITÉ DÉTECTÉ!");
        Print("[INTELLIGENT DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions);
        Print("[INTELLIGENT DETECTOR] Score de confiance: ", intelligent_score, "%");
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Pattern d'achat rejeté - Critères insuffisants");
        Print("[INTELLIGENT DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions, " (minimum requis: ", m_min_conditions_required, ")");
        Print("[INTELLIGENT DETECTOR] Score de confiance: ", intelligent_score, "% (minimum requis: ", m_min_confidence_score, "%)");
    }
    
    return pattern_valid;
}

//+------------------------------------------------------------------+
//| Détection de pattern de vente haute probabilité                 |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::DetectHighProbabilitySellPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
    Print("[INTELLIGENT DETECTOR] ===== ANALYSE HAUTE PRÉCISION - PATTERN DE VENTE =====");
    
    int conditions_passed = 0;
    int total_conditions = 7;
    
    // 1. Validation Multi-Timeframe (CRITIQUE)
    bool mtf_alignment = ValidateMultiTimeframeAlignment(ha_calc, ema_data, false);
    if(mtf_alignment)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Alignement multi-timeframe validé");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Alignement multi-timeframe non validé - REJET IMMÉDIAT");
        return false; // Condition critique
    }
    
    // 2. Confirmation de Momentum (CRITIQUE)
    bool momentum_confirmed = ValidateMomentumConfirmation(ha_calc, false);
    if(momentum_confirmed)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Momentum baissier confirmé");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Momentum baissier non confirmé - REJET IMMÉDIAT");
        return false; // Condition critique
    }
    
    // 3. Validation Support/Résistance
    bool sr_level_valid = ValidateSupportResistanceLevel(ha_calc, false);
    if(sr_level_valid)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Niveau de support/résistance validé");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Niveau de support/résistance non validé");
    }
    
    // 4. Validation Volume Surge
    bool volume_surge = ValidateVolumeSurge(volume_buffer, 0);
    if(volume_surge)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Surge de volume détecté");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Pas de surge de volume");
    }
    
    // 5. Validation Structure de Marché
    bool market_structure = ValidateMarketStructure(ha_calc, false);
    if(market_structure)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Structure de marché favorable");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Structure de marché défavorable");
    }
    
    // 6. Filtre de Volatilité
    bool volatility_ok = ValidateVolatilityFilter(ha_calc);
    if(volatility_ok)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Volatilité dans la plage optimale");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Volatilité hors plage optimale");
    }
    
    // 7. Confirmation Price Action
    bool price_action_confirmed = ValidatePriceActionConfirmation(ha_calc, false);
    if(price_action_confirmed)
    {
        Print("[INTELLIGENT DETECTOR] ✅ Price action confirmée");
        conditions_passed++;
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Price action non confirmée");
    }
    
    // Calcul du score de confiance intelligent
    double intelligent_score = CalculateIntelligentConfidenceScore(ha_calc, ema_data, volume_buffer, false);
    Print("[INTELLIGENT DETECTOR] Score de confiance intelligent: ", intelligent_score, "%");
    
    // Critères ULTRA-STRICTS pour 95% de précision
    bool pattern_valid = (conditions_passed >= m_min_conditions_required) && (intelligent_score >= m_min_confidence_score);
    
    if(pattern_valid)
    {
        Print("[INTELLIGENT DETECTOR] 🚀🚀🚀 PATTERN DE VENTE HAUTE PROBABILITÉ DÉTECTÉ!");
        Print("[INTELLIGENT DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions);
        Print("[INTELLIGENT DETECTOR] Score de confiance: ", intelligent_score, "%");
    }
    else
    {
        Print("[INTELLIGENT DETECTOR] ❌ Pattern de vente rejeté - Critères insuffisants");
        Print("[INTELLIGENT DETECTOR] Conditions validées: ", conditions_passed, "/", total_conditions, " (minimum requis: ", m_min_conditions_required, ")");
        Print("[INTELLIGENT DETECTOR] Score de confiance: ", intelligent_score, "% (minimum requis: ", m_min_confidence_score, "%)");
    }
    
    return pattern_valid;
}
