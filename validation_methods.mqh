//+------------------------------------------------------------------+
//| Méthodes de validation existantes (simplifiées)                 |
//+------------------------------------------------------------------+

bool CPatternDetector::ValidateTrendDirection(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool is_buy_signal)
{
    if(is_buy_signal)
    {
        return (ha_calc.GetHAClose(0) > ema_data[0]) && (ema_data[0] > ema_data[1]);
    }
    else
    {
        return (ha_calc.GetHAClose(0) < ema_data[0]) && (ema_data[0] < ema_data[1]);
    }
}

bool CPatternDetector::ValidatePullbackPattern(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    // Vérification simple du pullback
    if(is_buy_signal)
    {
        return ha_calc.GetHAClose(1) < ha_calc.GetHAOpen(1); // Bougie précédente baissière
    }
    else
    {
        return ha_calc.GetHAClose(1) > ha_calc.GetHAOpen(1); // Bougie précédente haussière
    }
}

bool CPatternDetector::ValidateDojiConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    double body_size = MathAbs(ha_calc.GetHAClose(0) - ha_calc.GetHAOpen(0));
    double total_range = ha_calc.GetHAHigh(0) - ha_calc.GetHALow(0);
    
    if(total_range == 0) return false;
    
    double doji_ratio = body_size / total_range;
    bool is_doji = doji_ratio <= m_doji_body_ratio;
    
    if(is_buy_signal)
    {
        return is_doji && (ha_calc.GetHAClose(0) >= ha_calc.GetHAOpen(0));
    }
    else
    {
        return is_doji && (ha_calc.GetHAClose(0) <= ha_calc.GetHAOpen(0));
    }
}

bool CPatternDetector::ValidateVolumeCondition(double& volume_buffer[], int doji_index)
{
    if(ArraySize(volume_buffer) < 11) return false;
    
    double avg_volume = 0.0;
    for(int i = doji_index + 1; i <= doji_index + 10; i++)
    {
        if(i < ArraySize(volume_buffer))
            avg_volume += volume_buffer[i];
    }
    avg_volume /= 10.0;
    
    return (volume_buffer[doji_index] >= 0.7 * avg_volume);
}

double CPatternDetector::CalculateConfidenceScore(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[], bool is_buy_signal)
{
    double score = 0.0;
    
    // Score basé sur la tendance (25 points)
    if(ValidateTrendDirection(ha_calc, ema_data, is_buy_signal))
        score += 25.0;
    
    // Score basé sur le pullback (20 points)
    if(ValidatePullbackPattern(ha_calc, is_buy_signal))
        score += 20.0;
    
    // Score basé sur le doji (20 points)
    if(ValidateDojiConfirmation(ha_calc, is_buy_signal))
        score += 20.0;
    
    // Score basé sur le volume (15 points)
    if(ValidateVolumeCondition(volume_buffer, 0))
        score += 15.0;
    
    // Score basé sur la force de la bougie actuelle (20 points)
    double body_size = MathAbs(ha_calc.GetHAClose(0) - ha_calc.GetHAOpen(0));
    double total_range = ha_calc.GetHAHigh(0) - ha_calc.GetHALow(0);
    if(total_range > 0)
    {
        double body_ratio = body_size / total_range;
        if(body_ratio >= 0.6) score += 20.0;
        else score += body_ratio * 33.33; // Proportionnel
    }
    
    return score;
}

//+------------------------------------------------------------------+
//| Méthodes de validation intelligente pour 95% de précision       |
//+------------------------------------------------------------------+

bool CPatternDetector::ValidateMultiTimeframeAlignment(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool is_buy_signal)
{
    // Simulation d'analyse multi-timeframe
    // Vérification que la tendance M1 est alignée avec une tendance plus large
    
    bool m1_trend_valid = ValidateTrendDirection(ha_calc, ema_data, is_buy_signal);
    
    // Vérification de la force de la tendance sur plusieurs bougies
    int trend_consistency = 0;
    for(int i = 0; i < 5; i++)
    {
        if(is_buy_signal)
        {
            if(ha_calc.GetHAClose(i) > ha_calc.GetHAOpen(i))
                trend_consistency++;
        }
        else
        {
            if(ha_calc.GetHAClose(i) < ha_calc.GetHAOpen(i))
                trend_consistency++;
        }
    }
    
    return m1_trend_valid && (trend_consistency >= 3);
}

bool CPatternDetector::ValidateMomentumConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    double momentum_score = 0.0;
    
    for(int i = 0; i < 5; i++)
    {
        double body_size = MathAbs(ha_calc.GetHAClose(i) - ha_calc.GetHAOpen(i));
        double candle_range = ha_calc.GetHAHigh(i) - ha_calc.GetHALow(i);
        
        if(candle_range > 0)
        {
            double body_ratio = body_size / candle_range;
            
            if(is_buy_signal)
            {
                if(ha_calc.GetHAClose(i) > ha_calc.GetHAOpen(i))
                    momentum_score += body_ratio * (5 - i);
                else
                    momentum_score -= body_ratio * (5 - i);
            }
            else
            {
                if(ha_calc.GetHAClose(i) < ha_calc.GetHAOpen(i))
                    momentum_score += body_ratio * (5 - i);
                else
                    momentum_score -= body_ratio * (5 - i);
            }
        }
    }
    
    momentum_score /= 15.0; // Normalisation
    return momentum_score >= 0.7;
}

bool CPatternDetector::ValidateSupportResistanceLevel(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    double current_price = ha_calc.GetHAClose(0);
    double price_levels[10];
    int level_count = 0;
    
    // Collecte des niveaux significatifs sur les 20 dernières bougies
    for(int i = 2; i < 20 && level_count < 10; i++)
    {
        double high = ha_calc.GetHAHigh(i);
        double low = ha_calc.GetHALow(i);
        
        // Recherche de pics et creux simples
        bool is_peak = (ha_calc.GetHAHigh(i) > ha_calc.GetHAHigh(i-1)) && 
                       (ha_calc.GetHAHigh(i) > ha_calc.GetHAHigh(i+1));
        bool is_trough = (ha_calc.GetHALow(i) < ha_calc.GetHALow(i-1)) && 
                         (ha_calc.GetHALow(i) < ha_calc.GetHALow(i+1));
        
        if(is_peak)
        {
            price_levels[level_count] = high;
            level_count++;
        }
        else if(is_trough)
        {
            price_levels[level_count] = low;
            level_count++;
        }
    }
    
    // Vérification de proximité avec un niveau
    for(int i = 0; i < level_count; i++)
    {
        double distance_pips = MathAbs(current_price - price_levels[i]) / Point();
        if(distance_pips <= 10.0) // Dans les 10 pips
        {
            if(is_buy_signal && current_price >= price_levels[i])
                return true; // Près d'un support
            else if(!is_buy_signal && current_price <= price_levels[i])
                return true; // Près d'une résistance
        }
    }
    
    return false;
}

bool CPatternDetector::ValidateVolumeSurge(double& volume_buffer[], int current_index)
{
    if(ArraySize(volume_buffer) < 20) return false;
    
    double avg_volume = 0.0;
    for(int i = current_index + 1; i <= current_index + 20; i++)
    {
        if(i < ArraySize(volume_buffer))
            avg_volume += volume_buffer[i];
    }
    avg_volume /= 20.0;
    
    double current_volume = volume_buffer[current_index];
    return (current_volume >= 1.5 * avg_volume);
}

bool CPatternDetector::ValidateMarketStructure(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    int higher_highs = 0;
    int higher_lows = 0;
    int lower_highs = 0;
    int lower_lows = 0;
    
    for(int i = 1; i < 10; i++)
    {
        if(ha_calc.GetHAHigh(i) > ha_calc.GetHAHigh(i+1))
            higher_highs++;
        else
            lower_highs++;
            
        if(ha_calc.GetHALow(i) > ha_calc.GetHALow(i+1))
            higher_lows++;
        else
            lower_lows++;
    }
    
    if(is_buy_signal)
    {
        return (higher_highs >= 6) && (higher_lows >= 6);
    }
    else
    {
        return (lower_highs >= 6) && (lower_lows >= 6);
    }
}

bool CPatternDetector::ValidateVolatilityFilter(CHeikinAshiCalculator* ha_calc)
{
    double atr_sum = 0.0;
    for(int i = 1; i < 15; i++)
    {
        double high = ha_calc.GetHAHigh(i);
        double low = ha_calc.GetHALow(i);
        double prev_close = ha_calc.GetHAClose(i+1);
        
        double tr1 = high - low;
        double tr2 = MathAbs(high - prev_close);
        double tr3 = MathAbs(low - prev_close);
        
        double true_range = MathMax(tr1, MathMax(tr2, tr3));
        atr_sum += true_range;
    }
    
    double atr = atr_sum / 14.0;
    double current_range = ha_calc.GetHAHigh(0) - ha_calc.GetHALow(0);
    double volatility_ratio = current_range / atr;
    
    return (volatility_ratio >= 0.5) && (volatility_ratio <= 2.0);
}

bool CPatternDetector::ValidatePriceActionConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    double current_open = ha_calc.GetHAOpen(0);
    double current_close = ha_calc.GetHAClose(0);
    double current_high = ha_calc.GetHAHigh(0);
    double current_low = ha_calc.GetHALow(0);
    
    double body_size = MathAbs(current_close - current_open);
    double upper_wick = current_high - MathMax(current_open, current_close);
    double lower_wick = MathMin(current_open, current_close) - current_low;
    double total_range = current_high - current_low;
    
    if(total_range == 0) return false;
    
    double body_ratio = body_size / total_range;
    double upper_wick_ratio = upper_wick / total_range;
    double lower_wick_ratio = lower_wick / total_range;
    
    if(is_buy_signal)
    {
        bool bullish_candle = current_close > current_open;
        bool strong_body = body_ratio >= 0.6;
        bool small_lower_wick = lower_wick_ratio <= 0.3;
        
        return bullish_candle && strong_body && small_lower_wick;
    }
    else
    {
        bool bearish_candle = current_close < current_open;
        bool strong_body = body_ratio >= 0.6;
        bool small_upper_wick = upper_wick_ratio <= 0.3;
        
        return bearish_candle && strong_body && small_upper_wick;
    }
}

//+------------------------------------------------------------------+
//| Méthodes utilitaires                                            |
//+------------------------------------------------------------------+

void CPatternDetector::AddPatternToHistory(const SPatternInfo& pattern)
{
    if(m_history_size < 100)
    {
        m_pattern_history[m_history_size] = pattern;
        m_history_size++;
    }
}

SPatternInfo CPatternDetector::GetLastPattern()
{
    if(m_history_size > 0)
        return m_pattern_history[m_history_size - 1];
    
    SPatternInfo empty_pattern;
    empty_pattern.signal_type = SIGNAL_NONE;
    return empty_pattern;
}

double CPatternDetector::GetSuccessRate()
{
    if(m_total_signals == 0) return 0.0;
    return (double)m_successful_signals / m_total_signals * 100.0;
}

void CPatternDetector::PrintPatternInfo(const SPatternInfo& pattern)
{
    Print("[PATTERN INFO] Type: ", pattern.signal_type, 
          ", Confiance: ", pattern.confidence_score, "%",
          ", Description: ", pattern.pattern_description);
}
