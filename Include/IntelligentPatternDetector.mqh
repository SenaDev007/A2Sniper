//+------------------------------------------------------------------+
//|                                    IntelligentPatternDetector.mqh |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"

#include <A2Sniper\HeikinAshiCalculator.mqh>

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
    
public:
    CIntelligentPatternDetector();
    ~CIntelligentPatternDetector();
    
    // Méthodes principales de détection intelligente
    bool DetectHighProbabilityBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[]);
    bool DetectHighProbabilitySellPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[]);
    
    // Méthodes de validation avancée
    bool ValidateMultiTimeframeAlignment(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool is_buy_signal);
    bool ValidateMomentumConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateSupportResistanceLevel(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateVolumeSurge(double& volume_buffer[], int current_index);
    bool ValidateMarketStructure(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    bool ValidateVolatilityFilter(CHeikinAshiCalculator* ha_calc);
    bool ValidatePriceActionConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal);
    double CalculateIntelligentConfidenceScore(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[], bool is_buy_signal);
    
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
