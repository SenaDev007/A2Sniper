//+------------------------------------------------------------------+
//| Méthodes de validation intelligente pour haute précision        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Validation Multi-Timeframe Alignment                            |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::ValidateMultiTimeframeAlignment(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool is_buy_signal)
{
    Print("[MTF VALIDATOR] Validation de l'alignement multi-timeframe...");
    
    // Récupération des données du timeframe supérieur (M5)
    double higher_tf_ema[];
    ArraySetAsSeries(higher_tf_ema, true);
    
    int ema_handle_m5 = iMA(Symbol(), PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);
    if(ema_handle_m5 == INVALID_HANDLE)
    {
        Print("[MTF VALIDATOR] ❌ Impossible de créer l'indicateur EMA M5");
        return false;
    }
    
    if(CopyBuffer(ema_handle_m5, 0, 0, 3, higher_tf_ema) < 3)
    {
        Print("[MTF VALIDATOR] ❌ Impossible de copier les données EMA M5");
        return false;
    }
    
    // Vérification de l'alignement des tendances
    bool m1_trend_bullish = (ha_calc.GetHAClose(0) > ema_data[0]) && (ema_data[0] > ema_data[1]);
    bool m5_trend_bullish = (higher_tf_ema[0] > higher_tf_ema[1]) && (higher_tf_ema[1] > higher_tf_ema[2]);
    
    bool alignment_valid = false;
    
    if(is_buy_signal)
    {
        // Pour un signal d'achat, les deux timeframes doivent être haussiers
        alignment_valid = m1_trend_bullish && m5_trend_bullish;
        Print("[MTF VALIDATOR] Tendance M1: ", (m1_trend_bullish ? "Haussière" : "Baissière"));
        Print("[MTF VALIDATOR] Tendance M5: ", (m5_trend_bullish ? "Haussière" : "Baissière"));
    }
    else
    {
        // Pour un signal de vente, les deux timeframes doivent être baissiers
        bool m1_trend_bearish = (ha_calc.GetHAClose(0) < ema_data[0]) && (ema_data[0] < ema_data[1]);
        bool m5_trend_bearish = (higher_tf_ema[0] < higher_tf_ema[1]) && (higher_tf_ema[1] < higher_tf_ema[2]);
        alignment_valid = m1_trend_bearish && m5_trend_bearish;
        Print("[MTF VALIDATOR] Tendance M1: ", (m1_trend_bearish ? "Baissière" : "Haussière"));
        Print("[MTF VALIDATOR] Tendance M5: ", (m5_trend_bearish ? "Baissière" : "Haussière"));
    }
    
    return alignment_valid;
}

//+------------------------------------------------------------------+
//| Validation Momentum Confirmation                                |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::ValidateMomentumConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    Print("[MOMENTUM VALIDATOR] Validation de la confirmation de momentum...");
    
    // Calcul du momentum sur les 5 dernières bougies
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
                // Pour un signal d'achat, on veut des bougies haussières avec des corps importants
                if(ha_calc.GetHAClose(i) > ha_calc.GetHAOpen(i))
                {
                    momentum_score += body_ratio * (5 - i); // Pondération décroissante
                }
                else
                {
                    momentum_score -= body_ratio * (5 - i); // Pénalité pour les bougies baissières
                }
            }
            else
            {
                // Pour un signal de vente, on veut des bougies baissières avec des corps importants
                if(ha_calc.GetHAClose(i) < ha_calc.GetHAOpen(i))
                {
                    momentum_score += body_ratio * (5 - i); // Pondération décroissante
                }
                else
                {
                    momentum_score -= body_ratio * (5 - i); // Pénalité pour les bougies haussières
                }
            }
        }
    }
    
    // Normalisation du score
    momentum_score /= 15.0; // (5+4+3+2+1 = 15)
    
    Print("[MOMENTUM VALIDATOR] Score de momentum: ", momentum_score);
    Print("[MOMENTUM VALIDATOR] Seuil requis: ", m_momentum_threshold);
    
    bool momentum_confirmed = momentum_score >= m_momentum_threshold;
    return momentum_confirmed;
}

//+------------------------------------------------------------------+
//| Validation Support/Resistance Level                             |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::ValidateSupportResistanceLevel(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    Print("[S/R VALIDATOR] Validation des niveaux de support/résistance...");
    
    double current_price = ha_calc.GetHAClose(0);
    double price_levels[20];
    int level_count = 0;
    
    // Collecte des niveaux de prix significatifs sur les 50 dernières bougies
    for(int i = 2; i < 50; i++)
    {
        double high = ha_calc.GetHAHigh(i);
        double low = ha_calc.GetHALow(i);
        
        // Recherche de pics et de creux
        bool is_peak = (ha_calc.GetHAHigh(i) > ha_calc.GetHAHigh(i-1)) && 
                       (ha_calc.GetHAHigh(i) > ha_calc.GetHAHigh(i+1)) &&
                       (ha_calc.GetHAHigh(i) > ha_calc.GetHAHigh(i-2)) && 
                       (ha_calc.GetHAHigh(i) > ha_calc.GetHAHigh(i+2));
                       
        bool is_trough = (ha_calc.GetHALow(i) < ha_calc.GetHALow(i-1)) && 
                         (ha_calc.GetHALow(i) < ha_calc.GetHALow(i+1)) &&
                         (ha_calc.GetHALow(i) < ha_calc.GetHALow(i-2)) && 
                         (ha_calc.GetHALow(i) < ha_calc.GetHALow(i+2));
        
        if(is_peak && level_count < 20)
        {
            price_levels[level_count] = high;
            level_count++;
        }
        else if(is_trough && level_count < 20)
        {
            price_levels[level_count] = low;
            level_count++;
        }
    }
    
    // Vérification de la proximité avec un niveau significatif
    double min_distance = 1000000.0;
    bool near_significant_level = false;
    
    for(int i = 0; i < level_count; i++)
    {
        double distance = MathAbs(current_price - price_levels[i]);
        double distance_pips = distance / Point();
        
        if(distance < min_distance)
        {
            min_distance = distance;
        }
        
        // Si on est à moins de 5 pips d'un niveau significatif
        if(distance_pips <= 5.0)
        {
            near_significant_level = true;
            
            if(is_buy_signal)
            {
                // Pour un achat, on veut être près d'un support
                if(current_price >= price_levels[i])
                {
                    Print("[S/R VALIDATOR] ✅ Prix près d'un niveau de support: ", price_levels[i]);
                    return true;
                }
            }
            else
            {
                // Pour une vente, on veut être près d'une résistance
                if(current_price <= price_levels[i])
                {
                    Print("[S/R VALIDATOR] ✅ Prix près d'un niveau de résistance: ", price_levels[i]);
                    return true;
                }
            }
        }
    }
    
    Print("[S/R VALIDATOR] Distance minimale d'un niveau significatif: ", min_distance/Point(), " pips");
    return false;
}

//+------------------------------------------------------------------+
//| Validation Volume Surge                                         |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::ValidateVolumeSurge(double& volume_buffer[], int current_index)
{
    Print("[VOLUME VALIDATOR] Validation du surge de volume...");
    
    if(ArraySize(volume_buffer) < 20)
    {
        Print("[VOLUME VALIDATOR] ❌ Données de volume insuffisantes");
        return false;
    }
    
    // Calcul du volume moyen sur les 20 dernières bougies
    double avg_volume = 0.0;
    for(int i = current_index + 1; i <= current_index + 20; i++)
    {
        if(i < ArraySize(volume_buffer))
            avg_volume += volume_buffer[i];
    }
    avg_volume /= 20.0;
    
    // Vérification du surge de volume
    double current_volume = volume_buffer[current_index];
    double volume_ratio = current_volume / avg_volume;
    
    Print("[VOLUME VALIDATOR] Volume actuel: ", current_volume);
    Print("[VOLUME VALIDATOR] Volume moyen: ", avg_volume);
    Print("[VOLUME VALIDATOR] Ratio: ", volume_ratio);
    Print("[VOLUME VALIDATOR] Seuil requis: ", m_volume_surge_ratio);
    
    bool surge_detected = volume_ratio >= m_volume_surge_ratio;
    return surge_detected;
}

//+------------------------------------------------------------------+
//| Validation Market Structure                                     |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::ValidateMarketStructure(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    Print("[STRUCTURE VALIDATOR] Validation de la structure de marché...");
    
    // Analyse de la structure sur les 10 dernières bougies
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
    
    Print("[STRUCTURE VALIDATOR] Higher Highs: ", higher_highs, ", Lower Highs: ", lower_highs);
    Print("[STRUCTURE VALIDATOR] Higher Lows: ", higher_lows, ", Lower Lows: ", lower_lows);
    
    if(is_buy_signal)
    {
        // Pour un signal d'achat, on veut une structure haussière
        bool bullish_structure = (higher_highs >= 6) && (higher_lows >= 6);
        return bullish_structure;
    }
    else
    {
        // Pour un signal de vente, on veut une structure baissière
        bool bearish_structure = (lower_highs >= 6) && (lower_lows >= 6);
        return bearish_structure;
    }
}

//+------------------------------------------------------------------+
//| Validation Volatility Filter                                    |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::ValidateVolatilityFilter(CHeikinAshiCalculator* ha_calc)
{
    Print("[VOLATILITY VALIDATOR] Validation du filtre de volatilité...");
    
    // Calcul de l'ATR sur les 14 dernières bougies
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
    
    Print("[VOLATILITY VALIDATOR] ATR: ", atr);
    Print("[VOLATILITY VALIDATOR] Range actuel: ", current_range);
    Print("[VOLATILITY VALIDATOR] Ratio de volatilité: ", volatility_ratio);
    
    // On veut une volatilité modérée (ni trop faible, ni trop élevée)
    bool volatility_ok = (volatility_ratio >= 0.5) && (volatility_ratio <= 2.0);
    return volatility_ok;
}

//+------------------------------------------------------------------+
//| Validation Price Action Confirmation                            |
//+------------------------------------------------------------------+
bool CIntelligentPatternDetector::ValidatePriceActionConfirmation(CHeikinAshiCalculator* ha_calc, bool is_buy_signal)
{
    Print("[PRICE ACTION VALIDATOR] Validation de la confirmation price action...");
    
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
    
    Print("[PRICE ACTION VALIDATOR] Body ratio: ", body_ratio);
    Print("[PRICE ACTION VALIDATOR] Upper wick ratio: ", upper_wick_ratio);
    Print("[PRICE ACTION VALIDATOR] Lower wick ratio: ", lower_wick_ratio);
    
    if(is_buy_signal)
    {
        // Pour un signal d'achat, on veut:
        // - Une bougie haussière (close > open)
        // - Un corps significatif (au moins 60% de la range)
        // - Une mèche inférieure petite (rejection du bas)
        bool bullish_candle = current_close > current_open;
        bool strong_body = body_ratio >= 0.6;
        bool small_lower_wick = lower_wick_ratio <= 0.3;
        
        return bullish_candle && strong_body && small_lower_wick;
    }
    else
    {
        // Pour un signal de vente, on veut:
        // - Une bougie baissière (close < open)
        // - Un corps significatif (au moins 60% de la range)
        // - Une mèche supérieure petite (rejection du haut)
        bool bearish_candle = current_close < current_open;
        bool strong_body = body_ratio >= 0.6;
        bool small_upper_wick = upper_wick_ratio <= 0.3;
        
        return bearish_candle && strong_body && small_upper_wick;
    }
}

//+------------------------------------------------------------------+
//| Calcul du score de confiance intelligent                        |
//+------------------------------------------------------------------+
double CIntelligentPatternDetector::CalculateIntelligentConfidenceScore(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[], bool is_buy_signal)
{
    Print("[CONFIDENCE CALCULATOR] Calcul du score de confiance intelligent...");
    
    double total_score = 0.0;
    double max_score = 100.0;
    
    // 1. Score Multi-Timeframe (25 points)
    if(ValidateMultiTimeframeAlignment(ha_calc, ema_data, is_buy_signal))
        total_score += 25.0;
    
    // 2. Score Momentum (20 points)
    if(ValidateMomentumConfirmation(ha_calc, is_buy_signal))
        total_score += 20.0;
    
    // 3. Score Support/Résistance (15 points)
    if(ValidateSupportResistanceLevel(ha_calc, is_buy_signal))
        total_score += 15.0;
    
    // 4. Score Volume (15 points)
    if(ValidateVolumeSurge(volume_buffer, 0))
        total_score += 15.0;
    
    // 5. Score Structure de Marché (10 points)
    if(ValidateMarketStructure(ha_calc, is_buy_signal))
        total_score += 10.0;
    
    // 6. Score Volatilité (10 points)
    if(ValidateVolatilityFilter(ha_calc))
        total_score += 10.0;
    
    // 7. Score Price Action (5 points)
    if(ValidatePriceActionConfirmation(ha_calc, is_buy_signal))
        total_score += 5.0;
    
    Print("[CONFIDENCE CALCULATOR] Score total: ", total_score, "/", max_score);
    return total_score;
}
