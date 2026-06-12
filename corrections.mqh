// Correction pour DetectBuyPattern
bool CPatternDetector::DetectBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
   Print("[PATTERN DETECTOR] ===== Début de l'analyse pour un pattern d'achat =====");
   
   // Variables pour suivre les conditions validées et calculer un score de confiance
   int conditions_passed = 0;
   int total_conditions = 5;
   
   // 1. Vérification que le prix est au-dessus de l'EMA - CONDITION RENFORCÉE
   bool price_above_ema = (ha_calc.GetHAClose(0) > ema_data[0]);
   if(price_above_ema)
   {
      Print("[PATTERN DETECTOR] Prix (", ha_calc.GetHAClose(0), ") > EMA (", ema_data[0], ") - Condition validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] Prix (", ha_calc.GetHAClose(0), ") <= EMA (", ema_data[0], ") - Condition non validée");
      // Condition renforcée: cette condition est maintenant obligatoire
      Print("[PATTERN DETECTOR] Condition essentielle non validée - Pattern rejeté");
      return false; // Rejet immédiat si le prix n'est pas au-dessus de l'EMA
   }
   
   // 2. Vérification de la tendance haussière
   bool trend_valid = ValidateTrendDirection(ha_calc, ema_data, true);
   if(trend_valid)
   {
      Print("[PATTERN DETECTOR] Tendance haussière validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] Tendance haussière non validée");
      // Condition assouplie: on continue même si la tendance n'est pas parfaitement haussière
      Print("[PATTERN DETECTOR] Condition ignorée pour augmenter la fréquence des trades");
   }
   
   // 3. Vérification du pattern de pullback
   bool pullback_valid = ValidatePullbackPattern(ha_calc, true);
   if(pullback_valid)
   {
      Print("[PATTERN DETECTOR] Pattern de pullback validé");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] Pattern de pullback non validé");
      // Cette condition est déjà très assouplie et devrait toujours être validée
   }
   
   // 4. Vérification de la confirmation par doji/bougie
   bool doji_valid = ValidateDojiConfirmation(ha_calc, true);
   if(doji_valid)
   {
      Print("[PATTERN DETECTOR] Confirmation par bougie validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] Confirmation par bougie non validée");
      // Cette condition est déjà très assouplie et devrait toujours être validée
   }
   
   // 5. Vérification de la condition de volume
   bool volume_valid = ValidateVolumeCondition(volume_buffer, 0);
   if(volume_valid)
   {
      Print("[PATTERN DETECTOR] Condition de volume validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] Condition de volume non validée");
      // Cette condition est déjà très assouplie et devrait toujours être validée
   }
   
   // Calcul du score de confiance simple
   double confidence_score = (double)conditions_passed / total_conditions * 100.0;
   Print("[PATTERN DETECTOR] Score de confiance simple: ", confidence_score, "% (", conditions_passed, "/", total_conditions, " conditions validées)");
   
   // Calcul du score de confiance détaillé avec les poids
   double detailed_score = CalculateConfidenceScore(ha_calc, ema_data, volume_buffer, true);
   Print("[PATTERN DETECTOR] Score de confiance détaillé: ", detailed_score, "%");
   
   // Condition RENFORCÉE: on accepte le pattern si au moins 4 conditions sur 5 sont validées
   // ET si le score de confiance détaillé est supérieur à 70%
   bool pattern_valid = (conditions_passed >= 4) && (detailed_score >= 70.0);
   
   if(pattern_valid)
   {
      Print("[PATTERN DETECTOR] Pattern d'achat détecté avec un score de confiance de ", confidence_score, "%");
   }
   else
   {
      Print("[PATTERN DETECTOR] Pattern d'achat rejeté avec un score de confiance insuffisant de ", confidence_score, "%");
   }
   
   return pattern_valid;
}

// Correction pour DetectSellPattern
bool CPatternDetector::DetectSellPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
   Print("[PATTERN DETECTOR] ===== Début de l'analyse pour un pattern de vente =====");
   
   // Variables pour suivre les conditions validées et calculer un score de confiance
   int conditions_passed = 0;
   int total_conditions = 5;
   
   // 1. Vérification que le prix est en-dessous de l'EMA - CONDITION RENFORCÉE
   bool price_below_ema = (ha_calc.GetHAClose(0) < ema_data[0]);
   if(price_below_ema)
   {
      Print("[PATTERN DETECTOR] ✅ Prix (", ha_calc.GetHAClose(0), ") < EMA (", ema_data[0], ") - Condition validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Prix (", ha_calc.GetHAClose(0), ") >= EMA (", ema_data[0], ") - Condition non validée");
      // Condition renforcée: cette condition est maintenant obligatoire
      Print("[PATTERN DETECTOR] Condition essentielle non validée - Pattern rejeté");
      return false; // Rejet immédiat si le prix n'est pas en-dessous de l'EMA
   }
   
   // 2. Vérification de la tendance baissière
   bool trend_valid = ValidateTrendDirection(ha_calc, ema_data, false);
   if(trend_valid)
   {
      Print("[PATTERN DETECTOR] ✅ Tendance baissière validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Tendance baissière non validée");
      // Condition assouplie: on continue même si la tendance n'est pas parfaitement baissière
      Print("[PATTERN DETECTOR] Condition ignorée pour augmenter la fréquence des trades");
   }
   
   // 3. Vérification du pattern de pullback
   bool pullback_valid = ValidatePullbackPattern(ha_calc, false);
   if(pullback_valid)
   {
      Print("[PATTERN DETECTOR] ✅ Pattern de pullback validé");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Pattern de pullback non validé");
      // Cette condition est déjà très assouplie et devrait toujours être validée
   }
   
   // 4. Vérification de la confirmation par doji/bougie
   bool doji_valid = ValidateDojiConfirmation(ha_calc, false);
   if(doji_valid)
   {
      Print("[PATTERN DETECTOR] ✅ Confirmation par bougie validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Confirmation par bougie non validée");
      // Cette condition est déjà très assouplie et devrait toujours être validée
   }
   
   // 5. Vérification de la condition de volume
   bool volume_valid = ValidateVolumeCondition(volume_buffer, 0);
   if(volume_valid)
   {
      Print("[PATTERN DETECTOR] ✅ Condition de volume validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Condition de volume non validée");
      // Cette condition est déjà très assouplie et devrait toujours être validée
   }
   
   // Calcul du score de confiance simple
   double confidence_score = (double)conditions_passed / total_conditions * 100.0;
   Print("[PATTERN DETECTOR] Score de confiance simple: ", confidence_score, "% (", conditions_passed, "/", total_conditions, " conditions validées)");
   
   // Calcul du score de confiance détaillé avec les poids
   double detailed_score = CalculateConfidenceScore(ha_calc, ema_data, volume_buffer, false);
   Print("[PATTERN DETECTOR] Score de confiance détaillé: ", detailed_score, "%");
   
   // Condition RENFORCÉE: on accepte le pattern si au moins 4 conditions sur 5 sont validées
   // ET si le score de confiance détaillé est supérieur à 70%
   bool pattern_valid = (conditions_passed >= 4) && (detailed_score >= 70.0);
   
   if(pattern_valid)
   {
      Print("[PATTERN DETECTOR] ✅✅✅ Pattern de vente détecté avec un score de confiance de ", confidence_score, "%");
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌❌❌ Pattern de vente rejeté avec un score de confiance insuffisant de ", confidence_score, "%");
   }
   
   return pattern_valid;
}
