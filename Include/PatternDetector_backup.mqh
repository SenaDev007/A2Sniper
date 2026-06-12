//+------------------------------------------------------------------+
//|                                              PatternDetector.mqh |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"

//+------------------------------------------------------------------+
//| Énumérations pour les signaux                                   |
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
   SPatternInfo      m_pattern_history[];
   int               m_history_size;
   
   // Statistiques d'apprentissage
   int               m_successful_patterns;
   int               m_failed_patterns;
   double            m_success_rate;

public:
   // Constructeur/Destructeur
                     CPatternDetector();
                    ~CPatternDetector();
   
   // Méthodes d'initialisation
   bool              Initialize(int min_pullback, double doji_ratio, double volume_mult, double wick_thresh = 0.1);
   void              Deinitialize();
   
   // Méthodes principales d'analyse
   int               AnalyzePattern(CHeikinAshiCalculator* ha_calc, double& ema_buffer[]);
   SPatternInfo      GetDetailedPattern(CHeikinAshiCalculator* ha_calc, double& ema_buffer[], double& volume_buffer[]);
   
   // Méthodes de détection spécifiques
   bool              DetectBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_buffer[], double& volume_buffer[]);
   bool              DetectSellPattern(CHeikinAshiCalculator* ha_calc, double& ema_buffer[], double& volume_buffer[]);
   
   // Validation des conditions
   bool              ValidateTrendDirection(CHeikinAshiCalculator* ha_calc, double& ema_buffer[], bool bullish_trend);
   bool              ValidatePullbackPattern(CHeikinAshiCalculator* ha_calc, bool looking_for_bullish);
   bool              ValidateDojiConfirmation(CHeikinAshiCalculator* ha_calc, bool expected_bullish);
   bool              ValidateVolumeCondition(double& volume_buffer[], int doji_index);
   
   // Méthodes d'apprentissage et statistiques
   void              RecordPatternResult(SPatternInfo &pattern, bool success);
   double            GetSuccessRate() { return m_success_rate; }
   void              UpdateStatistics();
   
   // Méthodes utilitaires
   double            CalculateConfidenceScore(CHeikinAshiCalculator* ha_calc, double& ema_buffer[], double& volume_buffer[], bool is_buy_signal);
   string            GetPatternDescription(ENUM_SIGNAL_TYPE signal, int pullback_count, bool has_doji);
   bool              IsInitialized() { return m_initialized; }
};

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CPatternDetector::CPatternDetector()
{
   m_min_pullback_candles = 2;
   m_doji_body_ratio = 0.3;
   m_volume_multiplier = 1.2;
   m_wick_threshold = 0.1;
   m_initialized = false;
   m_history_size = 100;
   m_successful_patterns = 0;
   m_failed_patterns = 0;
   m_success_rate = 0.0;
}

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CPatternDetector::~CPatternDetector()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CPatternDetector::Initialize(int min_pullback, double doji_ratio, double volume_mult, double wick_thresh = 0.1)
{
   if(min_pullback < 1 || doji_ratio <= 0 || doji_ratio >= 1 || volume_mult <= 0)
   {
      Print("ERREUR PatternDetector: Paramètres invalides");
      return false;
   }
   
   m_min_pullback_candles = min_pullback;
   m_doji_body_ratio = doji_ratio;
   m_volume_multiplier = volume_mult;
   m_wick_threshold = wick_thresh;
   
   // Initialisation de l'historique
   ArrayResize(m_pattern_history, m_history_size);
   // Initialize pattern history elements individually
   for(int i = 0; i < m_history_size; i++)
   {
      m_pattern_history[i].signal_type = SIGNAL_NONE;
      m_pattern_history[i].confidence_score = 0.0;
      m_pattern_history[i].pullback_candles = 0;
      m_pattern_history[i].has_doji_confirmation = false;
      m_pattern_history[i].volume_strength = 0.0;
      m_pattern_history[i].pattern_description = "";
      m_pattern_history[i].signal_time = 0;
   }
   
   m_initialized = true;
   
   Print("PatternDetector initialisé - Min Pullback: ", m_min_pullback_candles, 
         " | Doji Ratio: ", m_doji_body_ratio, 
         " | Volume Mult: ", m_volume_multiplier);
   
   return true;
}

//+------------------------------------------------------------------+
//| Désinitialisation                                               |
//+------------------------------------------------------------------+
void CPatternDetector::Deinitialize()
{
   ArrayFree(m_pattern_history);
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Analyse principale des patterns                                 |
//+------------------------------------------------------------------+
int CPatternDetector::AnalyzePattern(CHeikinAshiCalculator* ha_calc, double& ema_data[])
{
   Print("[PATTERN DETECTOR] Début de l'analyse des patterns");
   
   if(!m_initialized || !ha_calc.IsInitialized())
   {
      Print("[PATTERN DETECTOR] Erreur: PatternDetector ou HeikinAshiCalculator non initialisé");
      return SIGNAL_NONE;
   }
   
   // Vérification des données suffisantes
   if(ArraySize(ema_data) < 10)
   {
      Print("[PATTERN DETECTOR] Erreur: Données EMA insuffisantes (", ArraySize(ema_data), " < 10)");
      return SIGNAL_NONE;
   }
   
   double volume_buffer[];
   ArrayResize(volume_buffer, 20);
   
   // Analyse pour signal d'achat
   Print("[PATTERN DETECTOR] Analyse d'un potentiel signal d'achat...");
   if(DetectBuyPattern(ha_calc, ema_data, volume_buffer))
   {
      Print("[PATTERN DETECTOR] Signal d'achat détecté avec succès!");
      return SIGNAL_BUY;
   }
   else
   {
      Print("[PATTERN DETECTOR] Aucun signal d'achat valide détecté");
   }
   
   // Analyse pour signal de vente
   Print("[PATTERN DETECTOR] Analyse d'un potentiel signal de vente...");
   if(DetectSellPattern(ha_calc, ema_data, volume_buffer))
   {
      Print("[PATTERN DETECTOR] Signal de vente détecté avec succès!");
      return SIGNAL_SELL;
   }
   else
   {
      Print("[PATTERN DETECTOR] Aucun signal de vente valide détecté");
   }
   
   Print("[PATTERN DETECTOR] Aucun signal de trading détecté");
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Obtenir pattern détaillé                                        |
//+------------------------------------------------------------------+
SPatternInfo CPatternDetector::GetDetailedPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
   SPatternInfo pattern_info;
   pattern_info.signal_type = SIGNAL_NONE;
   pattern_info.confidence_score = 0.0;
   pattern_info.pullback_candles = 0;
   pattern_info.has_doji_confirmation = false;
   pattern_info.volume_strength = 0.0;
   pattern_info.pattern_description = "Aucun pattern détecté";
   pattern_info.signal_time = TimeCurrent();
   
   if(!m_initialized || !ha_calc.IsInitialized())
      return pattern_info;
   
   // Détection du signal
   if(DetectBuyPattern(ha_calc, ema_data, volume_buffer))
   {
      pattern_info.signal_type = SIGNAL_BUY;
   }
   else if(DetectSellPattern(ha_calc, ema_data, volume_buffer))
   {
      pattern_info.signal_type = SIGNAL_SELL;
   }
   
   if(pattern_info.signal_type != SIGNAL_NONE)
   {
      // Calcul du score de confiance
      pattern_info.confidence_score = CalculateConfidenceScore(ha_calc, ema_data, volume_buffer, pattern_info.signal_type);
      
      // Comptage des bougies de pullback
      if(pattern_info.signal_type == SIGNAL_BUY)
         pattern_info.pullback_candles = ha_calc.CountConsecutiveBearish(1);
      else
         pattern_info.pullback_candles = ha_calc.CountConsecutiveBullish(1);
      
      // Vérification Doji
      pattern_info.has_doji_confirmation = ha_calc.IsHADoji(0, m_doji_body_ratio);
      
      // Force du volume
      if(ArraySize(volume_buffer) > 10)
      {
         double avg_volume = 0.0;
         for(int i = 1; i <= 10; i++)
            avg_volume += volume_buffer[i];
         avg_volume /= 10.0;
         
         if(avg_volume > 0)
            pattern_info.volume_strength = volume_buffer[0] / avg_volume;
      }
      
      // Description
      pattern_info.pattern_description = GetPatternDescription(pattern_info.signal_type, 
                                                              pattern_info.pullback_candles, 
                                                              pattern_info.has_doji_confirmation);
   }
   
   return pattern_info;
}

//+------------------------------------------------------------------+
//| Détection pattern d'achat                                       |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectBuyPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
   Print("[PATTERN DETECTOR] ===== Début de l'analyse pour un pattern d'achat =====");
   
   // Variables pour suivre les conditions validées et calculer un score de confiance
   int conditions_passed = 0;
   int total_conditions = 5;
   
   // 1. Vérification que le prix est au-dessus de l'EMA
   bool price_above_ema = (ha_calc.GetHAClose(0) > ema_data[0]);
   if(price_above_ema)
   {
      Print("[PATTERN DETECTOR] Prix (", ha_calc.GetHAClose(0), ") > EMA (", ema_data[0], ") - Condition validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] Prix (", ha_calc.GetHAClose(0), ") <= EMA (", ema_data[0], ") - Condition non validée");
      // Condition assouplie: on continue même si le prix n'est pas au-dessus de l'EMA
      Print("[PATTERN DETECTOR] Condition ignorée pour augmenter la fréquence des trades");
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
   
   // Calcul du score de confiance
   double confidence_score = (double)conditions_passed / total_conditions * 100.0;
   Print("[PATTERN DETECTOR] Score de confiance: ", confidence_score, "% (", conditions_passed, "/", total_conditions, " conditions validées)");
   
   // Condition ULTRA assouplie: on accepte le pattern si au moins 3 conditions sur 5 sont validées
   bool pattern_valid = (conditions_passed >= 3);
   
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

//+------------------------------------------------------------------+
//| Détection pattern de vente                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectSellPattern(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[])
{
   Print("[PATTERN DETECTOR] ===== Début de l'analyse pour un pattern de vente =====");
   
   // Variables pour suivre les conditions validées et calculer un score de confiance
   int conditions_passed = 0;
   int total_conditions = 5;
   
   // 1. Vérification que le prix est en-dessous de l'EMA
   bool price_below_ema = (ha_calc.GetHAClose(0) < ema_data[0]);
   if(price_below_ema)
   {
      Print("[PATTERN DETECTOR] ✅ Prix (", ha_calc.GetHAClose(0), ") < EMA (", ema_data[0], ") - Condition validée");
      conditions_passed++;
   }
   else
   {
      Print("[PATTERN DETECTOR] ❌ Prix (", ha_calc.GetHAClose(0), ") >= EMA (", ema_data[0], ") - Condition non validée");
      // Condition assouplie: on continue même si le prix n'est pas en-dessous de l'EMA
      Print("[PATTERN DETECTOR] Condition ignorée pour augmenter la fréquence des trades");
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
   
   // Calcul du score de confiance
   double confidence_score = (double)conditions_passed / total_conditions * 100.0;
   Print("[PATTERN DETECTOR] Score de confiance: ", confidence_score, "% (", conditions_passed, "/", total_conditions, " conditions validées)");
   
   // Condition ULTRA assouplie: on accepte le pattern si au moins 3 conditions sur 5 sont validées
   bool pattern_valid = (conditions_passed >= 3);
   
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

//+------------------------------------------------------------------+
//| Validation direction de tendance                                |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidateTrendDirection(CHeikinAshiCalculator* ha_calc, double& ema_data[], bool bullish_trend)
{
   Print("[PATTERN DETECTOR] Vérification de la tendance ", (bullish_trend ? "haussière" : "baissière"));
   
   // Vérification que l'EMA confirme la tendance
   if(ArraySize(ema_data) < 3) // Réduit de 5 à 3 pour assouplir
   {
      Print("[PATTERN DETECTOR] Données EMA insuffisantes: ", ArraySize(ema_data), " < 3");
      return false;
   }
   
   if(bullish_trend)
   {
      // Tendance haussière : condition très assouplie
      // On vérifie juste que la dernière valeur est supérieure à celle d'il y a 2 périodes
      // ou que le prix actuel est au-dessus de l'EMA
      bool ema_trend = (ema_data[0] > ema_data[2]);
      bool price_above_ema = (ha_calc.GetHAClose(0) > ema_data[0]);
      bool result = ema_trend || price_above_ema; // Accepte l'une OU l'autre condition
      
      Print("[PATTERN DETECTOR] Tendance haussière: EMA actuelle (", ema_data[0], ") vs EMA-2 (", ema_data[2], ") = ", (ema_trend ? "Validée" : "Non validée"));
      Print("[PATTERN DETECTOR] Prix (", ha_calc.GetHAClose(0), ") vs EMA (", ema_data[0], ") = ", (price_above_ema ? "Au-dessus" : "En-dessous"));
      Print("[PATTERN DETECTOR] Tendance globale = ", (result ? "Validée" : "Non validée"));
      
      return result;
   }
   else
   {
      // Tendance baissière : condition très assouplie
      // On vérifie juste que la dernière valeur est inférieure à celle d'il y a 2 périodes
      // ou que le prix actuel est en-dessous de l'EMA
      bool ema_trend = (ema_data[0] < ema_data[2]);
      bool price_below_ema = (ha_calc.GetHAClose(0) < ema_data[0]);
      bool result = ema_trend || price_below_ema; // Accepte l'une OU l'autre condition
      
      Print("[PATTERN DETECTOR] Tendance baissière: EMA actuelle (", ema_data[0], ") vs EMA-2 (", ema_data[2], ") = ", (ema_trend ? "Validée" : "Non validée"));
      Print("[PATTERN DETECTOR] Prix (", ha_calc.GetHAClose(0), ") vs EMA (", ema_data[0], ") = ", (price_below_ema ? "En-dessous" : "Au-dessus"));
      Print("[PATTERN DETECTOR] Tendance globale = ", (result ? "Validée" : "Non validée"));
      
      return result;
   }
}

//+------------------------------------------------------------------+
//| Validation pattern de pullback                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidatePullbackPattern(CHeikinAshiCalculator* ha_calc, bool looking_for_bullish)
{
   Print("[PATTERN DETECTOR] Vérification du pattern de pullback pour signal ", (looking_for_bullish ? "d'achat" : "de vente"));
   
   // Condition ULTRA assouplie: on vérifie simplement si la dernière bougie est dans la direction opposée
   // Pour un signal d'achat (bullish), on cherche une bougie baissière (rouge) ou neutre
   // Pour un signal de vente (bearish), on cherche une bougie haussière (verte) ou neutre
   
   bool last_candle_opposite;
   
   if(looking_for_bullish)
   {
      // Pour un signal d'achat, on vérifie si la dernière bougie n'est PAS haussière
      // (donc soit baissière, soit neutre/doji)
      last_candle_opposite = !ha_calc.IsHABullish(1);
      Print("[PATTERN DETECTOR] Dernière bougie avant le signal d'achat: ", 
            (ha_calc.IsHABullish(1) ? "Haussière (non idéal)" : "Baissière ou neutre (idéal)"));
   }
   else
   {
      // Pour un signal de vente, on vérifie si la dernière bougie n'est PAS baissière
      // (donc soit haussière, soit neutre/doji)
      last_candle_opposite = ha_calc.IsHABullish(1);
      Print("[PATTERN DETECTOR] Dernière bougie avant le signal de vente: ", 
            (ha_calc.IsHABullish(1) ? "Haussière (idéal)" : "Baissière ou neutre (non idéal)"));
   }
   
   // On accepte même si la condition n'est pas parfaite, mais on ajoute un log pour information
   bool result = true; // On accepte toujours pour maximiser les opportunités de trade
   
   if(last_candle_opposite)
   {
      Print("[PATTERN DETECTOR] Pullback idéal détecté: la dernière bougie est dans la direction opposée");
   }
   else
   {
      Print("[PATTERN DETECTOR] Pullback non idéal mais accepté: la dernière bougie n'est pas dans la direction opposée");
   }
   // Condition assouplie - on ne vérifie plus les mèches significatives
   // pour permettre plus d'opportunités de trading
   Print("[PATTERN DETECTOR] Vérification des mèches ignorée (condition assouplie)");
   
   return true;
}

//+------------------------------------------------------------------+
//| Validation confirmation Doji                                    |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidateDojiConfirmation(CHeikinAshiCalculator* ha_calc, bool expected_bullish)
{
   Print("[PATTERN DETECTOR] Vérification de la confirmation par doji ", (expected_bullish ? "haussier" : "baissier"));
   
   // Vérification ULTRA assouplie : on accepte n'importe quelle bougie avec un ratio jusqu'à 0.6
   // (ce n'est plus vraiment un doji mais plutôt une bougie standard)
   bool is_doji = ha_calc.IsHADoji(0, 0.6);
   
   // Vérification de la couleur de la bougie (vert pour achat, rouge pour vente)
   bool is_bullish_doji = ha_calc.IsHABullish(0);
   
   Print("[PATTERN DETECTOR] Est-ce une bougie valide (ratio <= 0.6): ", (is_doji ? "Oui" : "Non"));
   Print("[PATTERN DETECTOR] Couleur de la bougie: ", (is_bullish_doji ? "Haussier (vert)" : "Baissier (rouge)"));
   Print("[PATTERN DETECTOR] Couleur attendue: ", (expected_bullish ? "Haussier (vert)" : "Baissier (rouge)"));
   
   // Condition très assouplie : on accepte même si la couleur ne correspond pas parfaitement
   // mais on ajoute un log pour information
   bool color_match = (is_bullish_doji == expected_bullish);
   
   if(!color_match)
   {
      Print("[PATTERN DETECTOR] ATTENTION: La couleur de la bougie ne correspond pas à la direction attendue");
      Print("[PATTERN DETECTOR] Signal de qualité inférieure mais accepté pour augmenter la fréquence des trades");
   }
   
   // On accepte si c'est une bougie valide, même si la couleur ne correspond pas
   bool result = is_doji;
   
   Print("[PATTERN DETECTOR] Confirmation par bougie ", (result ? "validée" : "non validée"));
   
   return result;
}

//+------------------------------------------------------------------+
//| Validation condition de volume                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidateVolumeCondition(double& volume_buffer[], int doji_index)
{
   Print("[PATTERN DETECTOR] Vérification de la condition de volume pour l'index ", doji_index);
   
   if(ArraySize(volume_buffer) < 11)
   {
      Print("[PATTERN DETECTOR] Données de volume insuffisantes: ", ArraySize(volume_buffer), " < 11, condition ignorée");
      return true; // Si pas assez de données, on accepte
   }
   
   // Calcul du volume moyen des 10 dernières bougies
   double avg_volume = 0.0;
   for(int i = doji_index + 1; i <= doji_index + 10; i++)
   {
      if(i < ArraySize(volume_buffer))
         avg_volume += volume_buffer[i];
   }
   avg_volume /= 10.0;
   
   // Condition ULTRA assouplie - on accepte un volume très faible (0.5 fois la moyenne au lieu de 0.8)
   // Ce qui permet de prendre beaucoup plus de trades même avec un volume très faible
   double volume_ratio = volume_buffer[doji_index] / avg_volume;
   bool result = (volume_buffer[doji_index] > avg_volume * 0.5);
   
   Print("[PATTERN DETECTOR] Volume actuel: ", volume_buffer[doji_index], ", Volume moyen: ", avg_volume, ", Ratio: ", volume_ratio);
   Print("[PATTERN DETECTOR] Seuil minimum très assoupli: 0.5 * volume moyen = ", avg_volume * 0.5);
   
   if(!result)
   {
      // Si même avec un seuil très bas le volume est insuffisant, on accepte quand même
      // mais on ajoute un log pour information
      Print("[PATTERN DETECTOR] ATTENTION: Volume très faible mais signal accepté quand même pour maximiser les opportunités");
      result = true;
   }
   else
   {
      Print("[PATTERN DETECTOR] Condition de volume validée");
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Calcul du score de confiance                                   |
//+------------------------------------------------------------------+
// Version avec paramètre is_buy_signal
double CPatternDetector::CalculateConfidenceScore(CHeikinAshiCalculator* ha_calc, double& ema_data[], double& volume_buffer[], bool is_buy_signal)
{
   Print("[PATTERN DETECTOR] Calcul du score de confiance pour un signal ", is_buy_signal ? "d'achat" : "de vente");
   
   double score = 0.0;
   double max_score = 100.0;
   
   // Facteur 1: Force de la tendance (20%)
   double trend_factor = 0.0;
   bool price_vs_ema = is_buy_signal ? (ha_calc.GetHAClose(0) > ema_data[0]) : (ha_calc.GetHAClose(0) < ema_data[0]);
   bool ema_trend = is_buy_signal ? (ema_data[0] > ema_data[2]) : (ema_data[0] < ema_data[2]);
   
   if(price_vs_ema && ema_trend)
      trend_factor = 20.0;
   else if(price_vs_ema || ema_trend)
      trend_factor = 10.0;
   else
      trend_factor = 5.0; // Même si aucune condition n'est remplie, on donne un score minimal
   
   Print("[PATTERN DETECTOR] Facteur tendance: ", trend_factor, "/20 (Prix vs EMA: ", price_vs_ema ? "OK" : "NOK", ", Tendance EMA: ", ema_trend ? "OK" : "NOK", ")");
   
   // Facteur 2: Qualité du pullback (30%) - Version assouplie
   double pullback_factor = 0.0;
   int consecutive_opposite = 0;
   
   if(is_buy_signal)
   {
      // Pour un signal d'achat, on cherche des bougies baissières ou neutres avant le signal
      bool last_candle_bearish = !ha_calc.IsHABullish(1);
      if(last_candle_bearish)
         consecutive_opposite++;
      
      // On vérifie les bougies précédentes pour un meilleur score
      for(int i = 2; i < 5; i++)
      {
         if(!ha_calc.IsHABullish(i))
            consecutive_opposite++;
         else
            break;
      }
   }
   else
   {
      // Pour un signal de vente, on cherche des bougies haussières ou neutres avant le signal
      bool last_candle_bullish = ha_calc.IsHABullish(1);
      if(last_candle_bullish)
         consecutive_opposite++;
      
      // On vérifie les bougies précédentes pour un meilleur score
      for(int i = 2; i < 5; i++)
      {
         if(ha_calc.IsHABullish(i))
            consecutive_opposite++;
         else
            break;
      }
   }
   
   // Attribution du score en fonction du nombre de bougies opposées
   if(consecutive_opposite >= 3)
      pullback_factor = 30.0;
   else if(consecutive_opposite >= 2)
      pullback_factor = 20.0;
   else if(consecutive_opposite >= 1)
      pullback_factor = 10.0;
   else
      pullback_factor = 5.0; // Score minimal même sans pullback
   
   Print("[PATTERN DETECTOR] Facteur pullback: ", pullback_factor, "/30 (", consecutive_opposite, " bougies opposées détectées)");
   
   // Facteur 3: Qualité du Doji/bougie (25%) - Version assouplie
   double doji_factor = 0.0;
   double body_size = ha_calc.GetBodySize(0);
   double candle_size = ha_calc.GetHAHigh(0) - ha_calc.GetHALow(0);
   double body_ratio = 1.0; // Valeur par défaut
   
   if(candle_size > 0)
   {
      body_ratio = body_size / candle_size;
      
      if(body_ratio < 0.2)
         doji_factor = 25.0; // Doji parfait
      else if(body_ratio < 0.4)
         doji_factor = 20.0; // Bon Doji
      else if(body_ratio < 0.6)
         doji_factor = 15.0; // Doji acceptable
      else if(body_ratio < 0.8)
         doji_factor = 10.0; // Bougie standard
      else
         doji_factor = 5.0;  // Bougie avec grand corps
      
      // Bonus si la couleur de la bougie correspond à la direction du signal
      bool correct_color = (is_buy_signal && ha_calc.IsHABullish(0)) || (!is_buy_signal && !ha_calc.IsHABullish(0));
      if(correct_color)
         doji_factor += 5.0;
   }
   
   Print("[PATTERN DETECTOR] Facteur bougie: ", doji_factor, "/25 (Ratio corps/bougie: ", body_ratio, ", Couleur correcte: ", 
         (is_buy_signal && ha_calc.IsHABullish(0)) || (!is_buy_signal && !ha_calc.IsHABullish(0)) ? "OUI" : "NON", ")");
   
   // Facteur 4: Volume (25%) - Version assouplie
   double volume_factor = 0.0;
   if(ArraySize(volume_buffer) > 10)
   {
      double avg_volume = 0.0;
      for(int i = 1; i <= 10; i++)
         avg_volume += volume_buffer[i];
      
      avg_volume /= 10.0;
      double volume_ratio = volume_buffer[0] / avg_volume;
      
      if(volume_buffer[0] > avg_volume * 1.5)
         volume_factor = 25.0;
      else if(volume_buffer[0] > avg_volume * 1.2)
         volume_factor = 20.0;
      else if(volume_buffer[0] > avg_volume)
         volume_factor = 15.0;
      else if(volume_buffer[0] > avg_volume * 0.5)
         volume_factor = 10.0;
      else
         volume_factor = 5.0; // Score minimal même avec un volume très faible
      
      Print("[PATTERN DETECTOR] Facteur volume: ", volume_factor, "/25 (Volume actuel: ", volume_buffer[0], ", Moyenne: ", avg_volume, ", Ratio: ", volume_ratio, ")");
   }
   else
   {
      volume_factor = 10.0; // Score par défaut si pas assez de données de volume
      Print("[PATTERN DETECTOR] Facteur volume: ", volume_factor, "/25 (Données insuffisantes, score par défaut)");
   }
   
   // Calcul du score total
   score = trend_factor + pullback_factor + doji_factor + volume_factor;
   
   Print("[PATTERN DETECTOR] Score de confiance final: ", score, "/", max_score, " (Tendance: ", trend_factor, 
         ", Pullback: ", pullback_factor, ", Bougie: ", doji_factor, ", Volume: ", volume_factor, ")");
   
   return score;
}

//+------------------------------------------------------------------+
//| Obtenir description du pattern                                  |
//+------------------------------------------------------------------+
string CPatternDetector::GetPatternDescription(ENUM_SIGNAL_TYPE signal, int pullback_count, bool has_doji)
{
   string description = "";
   
   if(signal == SIGNAL_BUY)
   {
      description = "Pattern ACHAT: " + IntegerToString(pullback_count) + " bougies rouges";
   }
   else if(signal == SIGNAL_SELL)
   {
      description = "Pattern VENTE: " + IntegerToString(pullback_count) + " bougies vertes";
   }
   
   if(has_doji)
      description += " + Doji confirmation";
   
   return description;
}

//+------------------------------------------------------------------+
//| Enregistrer résultat de pattern                                |
//+------------------------------------------------------------------+
void CPatternDetector::RecordPatternResult(SPatternInfo &pattern, bool success)
{
   if(success)
      m_successful_patterns++;
   else
      m_failed_patterns++;
   
   UpdateStatistics();
   
   // Ajouter à l'historique
   for(int i = m_history_size - 1; i > 0; i--)
   {
      m_pattern_history[i] = m_pattern_history[i - 1];
   }
   m_pattern_history[0] = pattern;
}

//+------------------------------------------------------------------+
//| Mise à jour des statistiques                                   |
//+------------------------------------------------------------------+
void CPatternDetector::UpdateStatistics()
{
   int total_patterns = m_successful_patterns + m_failed_patterns;
   if(total_patterns > 0)
   {
      m_success_rate = (double)m_successful_patterns / (double)total_patterns;
   }
   else
   {
      m_success_rate = 0.0;
   }
}
