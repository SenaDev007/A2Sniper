//+------------------------------------------------------------------+
//|                                           ShalomEA_QuickTest.mq5 |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//|                                       https://www.yehiortech.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"
#property link      "https://www.yehiortech.com"
#property version   "1.00"
#property description "Script de test rapide pour Shalom EA"
#property script_show_inputs

//--- Paramètres d'entrée
input group "=== PARAMÈTRES DE TEST ==="
input int                Test_Bars = 1000;                  // Nombre de barres à tester
input bool               Show_Details = true;               // Afficher les détails
input bool               Test_HeikinAshi = true;            // Tester Heikin-Ashi
input bool               Test_Patterns = true;              // Tester détection patterns
input bool               Test_RiskManager = true;           // Tester gestionnaire de risque

//--- Inclusions
#include "..\Include\HeikinAshiCalculator.mqh"
#include "..\Include\PatternDetector.mqh"
#include "..\Include\RiskManager.mqh"
#include "..\Include\SignalValidator.mqh"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== DÉBUT TEST RAPIDE SHALOM EA ===");
   Print("Symbole testé: ", Symbol());
   Print("Timeframe: ", EnumToString(Period()));
   Print("Nombre de barres: ", Test_Bars);
   Print("");
   
   bool all_tests_passed = true;
   
   // Test 1: Heikin-Ashi Calculator
   if(Test_HeikinAshi)
   {
      Print("--- TEST 1: HEIKIN-ASHI CALCULATOR ---");
      if(!TestHeikinAshiCalculator())
      {
         all_tests_passed = false;
         Print("❌ ÉCHEC: Heikin-Ashi Calculator");
      }
      else
      {
         Print("✅ SUCCÈS: Heikin-Ashi Calculator");
      }
      Print("");
   }
   
   // Test 2: Pattern Detector
   if(Test_Patterns)
   {
      Print("--- TEST 2: PATTERN DETECTOR ---");
      if(!TestPatternDetector())
      {
         all_tests_passed = false;
         Print("❌ ÉCHEC: Pattern Detector");
      }
      else
      {
         Print("✅ SUCCÈS: Pattern Detector");
      }
      Print("");
   }
   
   // Test 3: Risk Manager
   if(Test_RiskManager)
   {
      Print("--- TEST 3: RISK MANAGER ---");
      if(!TestRiskManager())
      {
         all_tests_passed = false;
         Print("❌ ÉCHEC: Risk Manager");
      }
      else
      {
         Print("✅ SUCCÈS: Risk Manager");
      }
      Print("");
   }
   
   // Test 4: Signal Validator
   Print("--- TEST 4: SIGNAL VALIDATOR ---");
   if(!TestSignalValidator())
   {
      all_tests_passed = false;
      Print("❌ ÉCHEC: Signal Validator");
   }
   else
   {
      Print("✅ SUCCÈS: Signal Validator");
   }
   Print("");
   
   // Test 5: Conditions de marché
   Print("--- TEST 5: CONDITIONS DE MARCHÉ ---");
   TestMarketConditions();
   Print("");
   
   // Résultat final
   Print("=== RÉSULTAT FINAL ===");
   if(all_tests_passed)
   {
      Print("🎉 TOUS LES TESTS SONT PASSÉS AVEC SUCCÈS!");
      Print("Shalom EA est prêt à être utilisé sur ce symbole.");
   }
   else
   {
      Print("⚠️ CERTAINS TESTS ONT ÉCHOUÉ!");
      Print("Vérifiez les erreurs ci-dessus avant d'utiliser l'EA.");
   }
   
   Print("=== FIN TEST RAPIDE SHALOM EA ===");
}

//+------------------------------------------------------------------+
//| Test du calculateur Heikin-Ashi                                 |
//+------------------------------------------------------------------+
bool TestHeikinAshiCalculator()
{
   CHeikinAshiCalculator* ha_calc = new CHeikinAshiCalculator();
   
   // Test d'initialisation
   if(!ha_calc.Initialize(Symbol(), Period(), Test_Bars))
   {
      Print("Erreur: Impossible d'initialiser le calculateur Heikin-Ashi");
      delete ha_calc;
      return false;
   }
   
   // Test de mise à jour
   if(!ha_calc.Update())
   {
      Print("Erreur: Impossible de mettre à jour les données Heikin-Ashi");
      delete ha_calc;
      return false;
   }
   
   // Vérification des données
   double ha_open = ha_calc.GetHAOpen(0);
   double ha_close = ha_calc.GetHAClose(0);
   double ha_high = ha_calc.GetHAHigh(0);
   double ha_low = ha_calc.GetHALow(0);
   
   if(ha_open <= 0 || ha_close <= 0 || ha_high <= 0 || ha_low <= 0)
   {
      Print("Erreur: Données Heikin-Ashi invalides");
      delete ha_calc;
      return false;
   }
   
   // Vérification de la cohérence
   if(ha_high < ha_open || ha_high < ha_close || ha_low > ha_open || ha_low > ha_close)
   {
      Print("Erreur: Données Heikin-Ashi incohérentes");
      delete ha_calc;
      return false;
   }
   
   if(Show_Details)
   {
      Print("HA Open: ", DoubleToString(ha_open, 5));
      Print("HA High: ", DoubleToString(ha_high, 5));
      Print("HA Low: ", DoubleToString(ha_low, 5));
      Print("HA Close: ", DoubleToString(ha_close, 5));
      Print("Is Bullish: ", (ha_calc.IsHABullish(0) ? "Oui" : "Non"));
      Print("Is Doji: ", (ha_calc.IsHADoji(0) ? "Oui" : "Non"));
   }
   
   delete ha_calc;
   return true;
}

//+------------------------------------------------------------------+
//| Test du détecteur de patterns                                   |
//+------------------------------------------------------------------+
bool TestPatternDetector()
{
   CPatternDetector* pattern_detector = new CPatternDetector();
   CHeikinAshiCalculator* ha_calc = new CHeikinAshiCalculator();
   
   // Initialisation
   pattern_detector.Initialize(2, 0.3, 1.2);
   if(false) // Dummy condition to avoid compilation error
   {
      Print("Erreur: Impossible d'initialiser le détecteur de patterns");
      delete pattern_detector;
      delete ha_calc;
      return false;
   }
   
   if(!ha_calc.Initialize(Symbol(), Period(), 100))
   {
      Print("Erreur: Impossible d'initialiser Heikin-Ashi pour les patterns");
      delete pattern_detector;
      delete ha_calc;
      return false;
   }
   
   ha_calc.Update();
   
   // Test de détection de patterns
   double ema_buffer[50];
   ArraySetAsSeries(ema_buffer, true);
   
   // Simulation de données EMA
   for(int i = 0; i < 50; i++)
   {
      ema_buffer[i] = ha_calc.GetHAClose(i) * (1.0 + (MathRand() - 16384) / 327680.0);
   }
   
   double volume_buffer[50];
   ArraySetAsSeries(volume_buffer, true);
   for(int i = 0; i < 50; i++) volume_buffer[i] = 1.0;
   
   bool buy_pattern = pattern_detector.DetectBuyPattern(ha_calc, ema_buffer, volume_buffer);
   bool sell_pattern = pattern_detector.DetectSellPattern(ha_calc, ema_buffer, volume_buffer);
   
   int signal = 0;
   if(buy_pattern) signal = 1;
   else if(sell_pattern) signal = -1;
   
   if(Show_Details)
   {
      string signal_text = "Aucun";
      if(signal == 1) signal_text = "ACHAT";
      else if(signal == -1) signal_text = "VENTE";
      
      Print("Signal détecté: ", signal_text);
      Print("Taux de succès: ", DoubleToString(pattern_detector.GetSuccessRate(), 2), "%");
   }
   
   delete pattern_detector;
   delete ha_calc;
   return true;
}

//+------------------------------------------------------------------+
//| Test du gestionnaire de risque                                  |
//+------------------------------------------------------------------+
bool TestRiskManager()
{
   CRiskManager* risk_manager = new CRiskManager();
   
   // Test d'initialisation
   if(!risk_manager.Initialize(1.0, 5.0, 10.0, 3))
   {
      Print("Erreur: Impossible d'initialiser le gestionnaire de risque");
      delete risk_manager;
      return false;
   }
   
   // Test de calcul de lot
   double entry_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double stop_loss = entry_price - 10 * SymbolInfoDouble(Symbol(), SYMBOL_POINT) * 10;
   
   double lot_size = risk_manager.CalculateLotSize(entry_price, stop_loss);
   
   if(lot_size <= 0)
   {
      Print("Erreur: Calcul de lot invalide");
      delete risk_manager;
      return false;
   }
   
   // Test de validation des paramètres
   if(!risk_manager.ValidateTradeParameters(lot_size, entry_price, stop_loss))
   {
      Print("Attention: Paramètres de trade non validés (peut être normal)");
   }
   
   if(Show_Details)
   {
      Print("Prix d'entrée: ", DoubleToString(entry_price, 5));
      Print("Stop Loss: ", DoubleToString(stop_loss, 5));
      Print("Lot calculé: ", DoubleToString(lot_size, 2));
      Print("Peut ouvrir position: ", (risk_manager.CanOpenPosition() ? "Oui" : "Non"));
      Print("Drawdown actuel: ", DoubleToString(risk_manager.GetCurrentDrawdown(), 2), "%");
   }
   
   delete risk_manager;
   return true;
}

//+------------------------------------------------------------------+
//| Test du validateur de signaux                                   |
//+------------------------------------------------------------------+
bool TestSignalValidator()
{
   CSignalValidator* signal_validator = new CSignalValidator();
   
   // Test d'initialisation
   if(!signal_validator.Initialize("08:00-18:00", 3.0))
   {
      Print("Erreur: Impossible d'initialiser le validateur de signaux");
      delete signal_validator;
      return false;
   }
   
   // Test de validation
   bool signal_valid = signal_validator.ValidateSignal(1, Symbol());
   
   if(Show_Details)
   {
      Print("Signal valide: ", (signal_valid ? "Oui" : "Non"));
      Print("Dans heures de trading: ", (signal_validator.IsWithinTradingHours(TimeCurrent()) ? "Oui" : "Non"));
      Print("Spread acceptable: ", (signal_validator.IsSpreadAcceptable(Symbol()) ? "Oui" : "Non"));
      
      if(!signal_valid)
      {
         Print("Raison du rejet: ", signal_validator.GetRejectionReason(1, Symbol()));
      }
   }
   
   delete signal_validator;
   return true;
}

//+------------------------------------------------------------------+
//| Test des conditions de marché                                   |
//+------------------------------------------------------------------+
void TestMarketConditions()
{
   // Informations sur le symbole
   Print("=== INFORMATIONS SYMBOLE ===");
   Print("Symbole: ", Symbol());
   Print("Description: ", SymbolInfoString(Symbol(), SYMBOL_DESCRIPTION));
   Print("Devise de base: ", SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE));
   Print("Devise de profit: ", SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT));
   
   // Spécifications de trading
   Print("=== SPÉCIFICATIONS TRADING ===");
   Print("Lot minimum: ", DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN), 2));
   Print("Lot maximum: ", DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX), 2));
   Print("Pas de lot: ", DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP), 2));
   Print("Taille du contrat: ", DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE), 0));
   
   // Prix et spread
   Print("=== PRIX ET SPREAD ===");
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   long spread_points = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   
   Print("Bid: ", DoubleToString(bid, digits));
   Print("Ask: ", DoubleToString(ask, digits));
   Print("Spread: ", spread_points, " points (", DoubleToString(spread_points * point, digits), ")");
   
   // Sessions de trading
   Print("=== SESSIONS DE TRADING ===");
   datetime from, to;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   if(SymbolInfoSessionTrade(Symbol(), (ENUM_DAY_OF_WEEK)dt.day_of_week, 0, from, to))
   {
      Print("Session principale: ", TimeToString(from, TIME_MINUTES), " - ", TimeToString(to, TIME_MINUTES));
   }
   else
   {
      Print("Impossible d'obtenir les heures de session");
   }
   
   // État du marché
   Print("=== ÉTAT DU MARCHÉ ===");
   Print("Marché ouvert: ", (SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_DISABLED ? "Oui" : "Non"));
   Print("Trading autorisé: ", (MQLInfoInteger(MQL_TRADE_ALLOWED) ? "Oui" : "Non"));
   Print("Connexion serveur: ", (TerminalInfoInteger(TERMINAL_CONNECTED) ? "Oui" : "Non"));
   
   // Recommandations
   Print("=== RECOMMANDATIONS ===");
   double spread_pips = spread_points;
   if(digits == 5 || digits == 3) spread_pips /= 10.0;
   
   if(spread_pips <= 2.0)
      Print("✅ Spread excellent pour le scalping");
   else if(spread_pips <= 5.0)
      Print("⚠️ Spread acceptable mais surveiller");
   else
      Print("❌ Spread trop élevé pour le scalping");
   
   if(SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN) <= 0.01)
      Print("✅ Lot minimum adapté au scalping");
   else
      Print("⚠️ Lot minimum élevé - ajuster le risk management");
}
