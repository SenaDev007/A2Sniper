//+------------------------------------------------------------------+
//|                                                      ShalomEA.mq5 |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"
#property version   "1.00"
#property description "Shalom EA - SystÃ¨me intelligent 95% - 10 trades/mois"

//+------------------------------------------------------------------+
//| Inclusions                                                       |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include "Include\PatternDetector.mqh"
#include "Include\HeikinAshiCalculator.mqh"

//+------------------------------------------------------------------+
//| ParamÃ¨tres d'entrÃ©e                                             |
//+------------------------------------------------------------------+
input int      InpFastMAPeriod = 50;        // PÃ©riode MA rapide
input int      InpSlowMAPeriod = 200;       // PÃ©riode MA lente
input double   InpRiskPercent = 2.0;        // Pourcentage de risque
input double   InpLotSize = 0.1;            // Taille du lot
input int      InpMaxPositions = 1;         // Positions max
input bool     InpUseTrailingStop = true;   // Trailing stop
input int      InpTrailingStopPips = 50;    // Pips trailing stop

//+------------------------------------------------------------------+
//| Variables globales                                              |
//+------------------------------------------------------------------+
CPatternDetector* pattern_detector = NULL;
CHeikinAshiCalculator* ha_calculator = NULL;
double ema_data[];
double volume_buffer[];
int ema_handle;
int volume_handle;

//+------------------------------------------------------------------+
//| Fonction d'initialisation                                       |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialisation des objets
   pattern_detector = new CPatternDetector();
   ha_calculator = new CHeikinAshiCalculator();
   
   if(pattern_detector == NULL || ha_calculator == NULL)
   {
      Print("Erreur: Impossible de crÃ©er les objets");
      return(INIT_FAILED);
   }
   
   // Initialisation du dÃ©tecteur de patterns
   pattern_detector.Initialize(0.3, 1.5, 1.5);
   
   // CrÃ©ation des handles
   ema_handle = iMA(_Symbol, PERIOD_CURRENT, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   volume_handle = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
   
   if(ema_handle < 0 || volume_handle < 0)
   {
      Print("Erreur: Impossible de crÃ©er les handles");
      return(INIT_FAILED);
   }
   
   Print("Shalom EA - SystÃ¨me intelligent 95% initialisÃ©");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Fonction de dÃ©sinitialisation                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(pattern_detector != NULL)
   {
      delete pattern_detector;
      pattern_detector = NULL;
   }
   
   if(ha_calculator != NULL)
   {
      delete ha_calculator;
      ha_calculator = NULL;
   }
   
   if(ema_handle >= 0)
   {
      IndicatorRelease(ema_handle);
   }
   
   if(volume_handle >= 0)
   {
      IndicatorRelease(volume_handle);
   }
   
   Print("Shalom EA - DÃ©sinitialisation complÃ¨te");
}

//+------------------------------------------------------------------+
//| Fonction principale - tick                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   // VÃ©rification des conditions de trading
   if(!CheckTradeConditions())
   {
      return;
   }
   
   // Mise Ã  jour des donnÃ©es
   if(!UpdateMarketData())
   {
      return;
   }
   
   // DÃ©tection des patterns
   DetectPatterns();
}

//+------------------------------------------------------------------+
//| VÃ©rification des conditions de trading                          |
//+------------------------------------------------------------------+
bool CheckTradeConditions()
{
   if(PositionsTotal() >= InpMaxPositions)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Mise Ã  jour des donnÃ©es de marchÃ©                              |
//+------------------------------------------------------------------+
bool UpdateMarketData()
{
   // RÃ©cupÃ©ration des donnÃ©es EMA
   if(CopyBuffer(ema_handle, 0, 0, 100, ema_data) < 0)
   {
      Print("Erreur: Impossible de copier les donnÃ©es EMA");
      return false;
   }
   
   // RÃ©cupÃ©ration des donnÃ©es de volume
   if(CopyBuffer(volume_handle, 0, 0, 100, volume_buffer) < 0)
   {
      Print("Erreur: Impossible de copier les donnÃ©es de volume");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| DÃ©tection des patterns                                          |
//+------------------------------------------------------------------+
void DetectPatterns()
{
   if(pattern_detector == NULL || ha_calculator == NULL)
   {
      return;
   }
   
   // Mise Ã  jour du calculateur Heikin-Ashi
   ha_calculator.Update();
   
   // DÃ©tection des patterns d'achat
   if(pattern_detector.DetectBuyPattern(ha_calculator, ema_data, volume_buffer))
   {
      Print("Pattern d'achat dÃ©tectÃ© - exÃ©cution du trade");
      ExecuteTrade(ORDER_TYPE_BUY);
   }
   
   // DÃ©tection des patterns de vente
   if(pattern_detector.DetectSellPattern(ha_calculator, ema_data, volume_buffer))
   {
      Print("Pattern de vente dÃ©tectÃ© - exÃ©cution du trade");
      ExecuteTrade(ORDER_TYPE_SELL);
   }
}

//+------------------------------------------------------------------+
//| ExÃ©cution d'un trade                                            |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE order_type)
{
   double lot_size = CalculateLotSize();
   double price = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Calcul des SL/TP
   double sl = (order_type == ORDER_TYPE_BUY) ? 
      price - InpTrailingStopPips * _Point : 
      price + InpTrailingStopPips * _Point;
   
   double tp = (order_type == ORDER_TYPE_BUY) ? 
      price + InpTrailingStopPips * 2 * _Point : 
      price - InpTrailingStopPips * 2 * _Point;
   
   // CrÃ©ation de l'ordre
   CTrade trade;
   trade.SetExpertMagicNumber(123456);
   trade.SetDeviationInPoints(10);
   
   if(order_type == ORDER_TYPE_BUY)
   {
      trade.Buy(lot_size, _Symbol, price, sl, tp);
   }
   else
   {
      trade.Sell(lot_size, _Symbol, price, sl, tp);
   }
   
   Print("Trade exÃ©cutÃ©: ", order_type == ORDER_TYPE_BUY ? "ACHAT" : "VENTE", 
         " - Lot: ", lot_size, " - Prix: ", price);
}

//+------------------------------------------------------------------+
//| Calcul de la taille de lot                                      |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount = account_balance * InpRiskPercent / 100.0;
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   double lot_size = risk_amount / (InpTrailingStopPips * tick_value);
   lot_size = MathMax(lot_size, InpLotSize);
   lot_size = MathMin(lot_size, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   
   return NormalizeDouble(lot_size, 2);
}

