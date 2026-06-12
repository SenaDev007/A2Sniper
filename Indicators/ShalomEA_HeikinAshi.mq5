//+------------------------------------------------------------------+
//|                                        ShalomEA_HeikinAshi.mq5 |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//|                                       https://www.yehiortech.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"
#property link      "https://www.yehiortech.com"
#property version   "1.00"
#property description "Indicateur Heikin-Ashi pour Shalom EA avec signaux visuels"

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   4

//--- Paramètres d'affichage des bougies Heikin-Ashi
#property indicator_label1  "HA Open;HA High;HA Low;HA Close"
#property indicator_type1   DRAW_CANDLES
#property indicator_color1  clrDodgerBlue,clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- Paramètres d'affichage de l'EMA
#property indicator_label2  "EMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrYellow
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- Paramètres d'affichage des signaux d'achat
#property indicator_label3  "Signal Achat"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrLime
#property indicator_width3  3

//--- Paramètres d'affichage des signaux de vente
#property indicator_label4  "Signal Vente"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrRed
#property indicator_width4  3

//--- Paramètres d'entrée
input group "=== PARAMÈTRES HEIKIN-ASHI ==="
input bool               Show_HA_Candles = true;            // Afficher bougies Heikin-Ashi
input bool               Show_EMA = true;                   // Afficher EMA
input int                EMA_Period = 21;                  // Période EMA

input group "=== DÉTECTION SIGNAUX ==="
input bool               Show_Signals = true;              // Afficher signaux
input int                Min_Pullback_Candles = 2;         // Min bougies de retracement
input double             Doji_Body_Ratio = 0.3;            // Ratio corps Doji
input double             Volume_Multiplier = 1.2;          // Multiplicateur volume

input group "=== AFFICHAGE ==="
input color              Bullish_Color = clrDodgerBlue;    // Couleur bougies haussières
input color              Bearish_Color = clrRed;           // Couleur bougies baissières
input color              EMA_Color = clrYellow;            // Couleur EMA
input bool               Show_Info_Panel = true;           // Afficher panel d'informations

//--- Buffers d'indicateur
double HAOpenBuffer[];
double HAHighBuffer[];
double HALowBuffer[];
double HACloseBuffer[];
double EMABuffer[];
double SignalBuyBuffer[];
double SignalSellBuffer[];
double VolumeBuffer[];

//--- Handles des indicateurs
int ema_handle;
int volume_handle;

//--- Variables globales
datetime last_signal_time;
int total_signals;
int buy_signals;
int sell_signals;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Assignation des buffers
   SetIndexBuffer(0, HAOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HAHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, HALowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, HACloseBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, EMABuffer, INDICATOR_DATA);
   SetIndexBuffer(5, SignalBuyBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, SignalSellBuffer, INDICATOR_DATA);
   SetIndexBuffer(7, VolumeBuffer, INDICATOR_CALCULATIONS);
   
   //--- Configuration des buffers
   ArraySetAsSeries(HAOpenBuffer, true);
   ArraySetAsSeries(HAHighBuffer, true);
   ArraySetAsSeries(HALowBuffer, true);
   ArraySetAsSeries(HACloseBuffer, true);
   ArraySetAsSeries(EMABuffer, true);
   ArraySetAsSeries(SignalBuyBuffer, true);
   ArraySetAsSeries(SignalSellBuffer, true);
   ArraySetAsSeries(VolumeBuffer, true);
   
   //--- Configuration des plots
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, Show_HA_Candles ? DRAW_CANDLES : DRAW_NONE);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, Bullish_Color);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, Bearish_Color);
   
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, Show_EMA ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, EMA_Color);
   
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, Show_Signals ? DRAW_ARROW : DRAW_NONE);
   PlotIndexSetInteger(2, PLOT_ARROW, 233); // Flèche vers le haut
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, Show_Signals ? DRAW_ARROW : DRAW_NONE);
   PlotIndexSetInteger(3, PLOT_ARROW, 234); // Flèche vers le bas
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   
   //--- Initialisation des handles
   if(Show_EMA)
   {
      ema_handle = iMA(Symbol(), Period(), EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
      if(ema_handle == INVALID_HANDLE)
      {
         Print("Erreur création handle EMA");
         return INIT_FAILED;
      }
   }
   
   volume_handle = iVolumes(Symbol(), Period(), VOLUME_TICK);
   if(volume_handle == INVALID_HANDLE)
   {
      Print("Erreur création handle Volume");
      return INIT_FAILED;
   }
   
   //--- Initialisation des variables
   last_signal_time = 0;
   total_signals = 0;
   buy_signals = 0;
   sell_signals = 0;
   
   //--- Nom de l'indicateur
   IndicatorSetString(INDICATOR_SHORTNAME, "Shalom EA Heikin-Ashi");
   
   Print("Indicateur Shalom EA Heikin-Ashi initialisé");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Libération des handles
   if(ema_handle != INVALID_HANDLE)
      IndicatorRelease(ema_handle);
   if(volume_handle != INVALID_HANDLE)
      IndicatorRelease(volume_handle);
   
   //--- Suppression des objets graphiques
   ObjectsDeleteAll(0, "ShalomHA_");
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- Vérification des données
   if(rates_total < EMA_Period + 10)
      return 0;
   
   //--- Détermination de l'index de début
   int start = prev_calculated;
   if(start == 0)
      start = rates_total - 1;
   
   //--- Copie des données EMA si nécessaire
   if(Show_EMA && ema_handle != INVALID_HANDLE)
   {
      if(CopyBuffer(ema_handle, 0, 0, rates_total, EMABuffer) != rates_total)
         return prev_calculated;
   }
   
   //--- Copie des données de volume
   if(CopyBuffer(volume_handle, 0, 0, rates_total, VolumeBuffer) != rates_total)
      return prev_calculated;
   
   //--- Calcul des bougies Heikin-Ashi
   for(int i = start; i >= 0; i--)
   {
      CalculateHeikinAshi(i, rates_total, open, high, low, close);
      
      //--- Détection des signaux
      if(Show_Signals && i < rates_total - 10)
      {
         DetectSignals(i, rates_total);
      }
   }
   
   //--- Mise à jour du panel d'informations
   if(Show_Info_Panel && prev_calculated != rates_total)
   {
      UpdateInfoPanel();
   }
   
   return rates_total;
}

//+------------------------------------------------------------------+
//| Calcul des valeurs Heikin-Ashi                                  |
//+------------------------------------------------------------------+
void CalculateHeikinAshi(int index, int rates_total, const double &open[], const double &high[], const double &low[], const double &close[])
{
   //--- HA_Close = (O + H + L + C) / 4
   HACloseBuffer[index] = (open[index] + high[index] + low[index] + close[index]) / 4.0;
   
   //--- HA_Open = (HA_Open[précédent] + HA_Close[précédent]) / 2
   if(index == rates_total - 1)
   {
      // Première bougie : utiliser les valeurs réelles
      HAOpenBuffer[index] = (open[index] + close[index]) / 2.0;
   }
   else
   {
      HAOpenBuffer[index] = (HAOpenBuffer[index + 1] + HACloseBuffer[index + 1]) / 2.0;
   }
   
   //--- HA_High = Max(H, HA_Open, HA_Close)
   HAHighBuffer[index] = MathMax(high[index], MathMax(HAOpenBuffer[index], HACloseBuffer[index]));
   
   //--- HA_Low = Min(L, HA_Open, HA_Close)
   HALowBuffer[index] = MathMin(low[index], MathMin(HAOpenBuffer[index], HACloseBuffer[index]));
   
   //--- Initialisation des buffers de signaux
   SignalBuyBuffer[index] = EMPTY_VALUE;
   SignalSellBuffer[index] = EMPTY_VALUE;
}

//+------------------------------------------------------------------+
//| Détection des signaux de trading                                |
//+------------------------------------------------------------------+
void DetectSignals(int index, int rates_total)
{
   //--- Vérification des données suffisantes
   if(index + Min_Pullback_Candles + 5 >= rates_total)
      return;
   
   //--- Variables pour l'analyse
   bool is_current_bullish = HACloseBuffer[index] > HAOpenBuffer[index];
   bool is_doji = IsDoji(index);
   
   //--- Détection signal d'achat
   if(is_current_bullish && is_doji && Show_EMA)
   {
      // Vérifier que le prix est au-dessus de l'EMA
      if(HACloseBuffer[index] > EMABuffer[index])
      {
         // Compter les bougies baissières précédentes
         int bearish_count = CountConsecutiveBearish(index + 1, rates_total);
         
         if(bearish_count >= Min_Pullback_Candles)
         {
            // Vérifier les conditions de volume
            if(ValidateVolumeCondition(index))
            {
               SignalBuyBuffer[index] = HALowBuffer[index] - 10 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
               
               // Éviter les signaux en double
               if(last_signal_time != iTime(Symbol(), Period(), index))
               {
                  last_signal_time = iTime(Symbol(), Period(), index);
                  total_signals++;
                  buy_signals++;
                  
                  if(index == 0) // Signal en temps réel
                  {
                     Alert("Shalom EA - Signal ACHAT détecté sur ", Symbol());
                  }
               }
            }
         }
      }
   }
   
   //--- Détection signal de vente
   if(!is_current_bullish && is_doji && Show_EMA)
   {
      // Vérifier que le prix est en-dessous de l'EMA
      if(HACloseBuffer[index] < EMABuffer[index])
      {
         // Compter les bougies haussières précédentes
         int bullish_count = CountConsecutiveBullish(index + 1, rates_total);
         
         if(bullish_count >= Min_Pullback_Candles)
         {
            // Vérifier les conditions de volume
            if(ValidateVolumeCondition(index))
            {
               SignalSellBuffer[index] = HAHighBuffer[index] + 10 * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
               
               // Éviter les signaux en double
               if(last_signal_time != iTime(Symbol(), Period(), index))
               {
                  last_signal_time = iTime(Symbol(), Period(), index);
                  total_signals++;
                  sell_signals++;
                  
                  if(index == 0) // Signal en temps réel
                  {
                     Alert("Shalom EA - Signal VENTE détecté sur ", Symbol());
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Vérifier si la bougie est un Doji                              |
//+------------------------------------------------------------------+
bool IsDoji(int index)
{
   double body_size = MathAbs(HACloseBuffer[index] - HAOpenBuffer[index]);
   double total_range = HAHighBuffer[index] - HALowBuffer[index];
   
   if(total_range <= 0)
      return true;
   
   double body_ratio = body_size / total_range;
   return (body_ratio <= Doji_Body_Ratio);
}

//+------------------------------------------------------------------+
//| Compter les bougies baissières consécutives                    |
//+------------------------------------------------------------------+
int CountConsecutiveBearish(int start_index, int rates_total)
{
   int count = 0;
   
   for(int i = start_index; i < rates_total && count < 10; i++)
   {
      if(HACloseBuffer[i] < HAOpenBuffer[i])
         count++;
      else
         break;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Compter les bougies haussières consécutives                    |
//+------------------------------------------------------------------+
int CountConsecutiveBullish(int start_index, int rates_total)
{
   int count = 0;
   
   for(int i = start_index; i < rates_total && count < 10; i++)
   {
      if(HACloseBuffer[i] > HAOpenBuffer[i])
         count++;
      else
         break;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Valider les conditions de volume                                |
//+------------------------------------------------------------------+
bool ValidateVolumeCondition(int index)
{
   if(index + 10 >= ArraySize(VolumeBuffer))
      return true; // Si pas assez de données, accepter
   
   // Calcul du volume moyen des 10 dernières bougies
   double avg_volume = 0.0;
   for(int i = index + 1; i <= index + 10; i++)
   {
      avg_volume += VolumeBuffer[i];
   }
   avg_volume /= 10.0;
   
   // Le volume actuel doit être supérieur à la moyenne * multiplicateur
   return (VolumeBuffer[index] > avg_volume * Volume_Multiplier);
}

//+------------------------------------------------------------------+
//| Mise à jour du panel d'informations                            |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
{
   if(!Show_Info_Panel)
      return;
   
   //--- Position du panel
   int x = 20;
   int y = 30;
   
   //--- Couleurs
   color panel_color = clrNavy;
   color text_color = clrWhite;
   
   //--- Création du panel de fond
   string panel_name = "ShalomHA_InfoPanel";
   if(ObjectFind(0, panel_name) < 0)
   {
      ObjectCreate(0, panel_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, panel_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, panel_name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, panel_name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, panel_name, OBJPROP_XSIZE, 200);
      ObjectSetInteger(0, panel_name, OBJPROP_YSIZE, 120);
      ObjectSetInteger(0, panel_name, OBJPROP_BGCOLOR, panel_color);
      ObjectSetInteger(0, panel_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, panel_name, OBJPROP_BORDER_COLOR, clrGray);
   }
   
   //--- Titre
   CreateLabel("ShalomHA_Title", x + 10, y + 5, "SHALOM EA SIGNALS", clrYellow, 9);
   
   //--- Statistiques
   CreateLabel("ShalomHA_TotalSignals", x + 10, y + 25, "Total Signaux: " + IntegerToString(total_signals), text_color, 8);
   CreateLabel("ShalomHA_BuySignals", x + 10, y + 40, "Signaux Achat: " + IntegerToString(buy_signals), clrLime, 8);
   CreateLabel("ShalomHA_SellSignals", x + 10, y + 55, "Signaux Vente: " + IntegerToString(sell_signals), clrRed, 8);
   
   //--- État actuel
   string current_trend = "Neutre";
   color trend_color = clrGray;
   
   if(ArraySize(HACloseBuffer) > 0 && ArraySize(HAOpenBuffer) > 0)
   {
      if(HACloseBuffer[0] > HAOpenBuffer[0])
      {
         current_trend = "Haussier";
         trend_color = clrLime;
      }
      else
      {
         current_trend = "Baissier";
         trend_color = clrRed;
      }
   }
   
   CreateLabel("ShalomHA_CurrentTrend", x + 10, y + 75, "Tendance: " + current_trend, trend_color, 8);
   
   //--- Dernière mise à jour
   CreateLabel("ShalomHA_LastUpdate", x + 10, y + 95, "MAJ: " + TimeToString(TimeCurrent(), TIME_MINUTES), clrSilver, 7);
}

//+------------------------------------------------------------------+
//| Créer un label                                                  |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int font_size)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   }
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
}
