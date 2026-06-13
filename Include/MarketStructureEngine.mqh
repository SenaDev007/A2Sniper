//+------------------------------------------------------------------+
//| MarketStructureEngine.mqh - Détection de Structure de Marché     |
//| A2Sniper Ultimate v3.0                                           |
//| Détection: HH, HL, LH, LL, BOS, CHOCH, MSS                     |
//| Multi-Timeframe: D1, H4, H1, M15                                |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_MARKET_STRUCTURE_MQH
#define A2SNIPER_MARKET_STRUCTURE_MQH

#include <Trade\Trade.mqh>
#include <A2Sniper\CommonTypes.mqh>

//+------------------------------------------------------------------+
//| Classe CMarketStructureEngine                                    |
//+------------------------------------------------------------------+
class CMarketStructureEngine
  {
private:
   //--- Paramètres
   int               m_swing_lookback;        // Lookback pour swing detection
   double            m_break_threshold;       // Seuil de cassure (en pips)
   int               m_structure_lookback;    // Lookback pour analyse structurelle
   bool              m_initialized;           // Module initialisé

   //--- Données de structure par timeframe
   SMarketStructure  m_structure_htf;         // Structure timeframe supérieur (H4/D1)
   SMarketStructure  m_structure_mtf;         // Structure timeframe moyen (H1)
   SMarketStructure  m_structure_ltf;         // Structure timeframe inférieur (M15/M5)

   //--- Historique des swings
   SStructurePoint   m_swing_highs[];         // Derniers swing highs
   SStructurePoint   m_swing_lows[];          // Derniers swing lows
   int               m_swing_count;           // Nombre de swings détectés

   //--- Handles indicateurs
   int               m_ema_handle;            // Handle EMA pour confirmation tendance
   double            m_ema_buffer[];          // Buffer EMA

   //--- Méthodes privées
   bool              DetectSwingPoints(const ENUM_TIMEFRAMES tf, SStructurePoint &highs[], SStructurePoint &lows[], int &h_count, int &l_count);
   bool              IsSwingHigh(const int bar, const int lookback, const ENUM_TIMEFRAMES tf);
   bool              IsSwingLow(const int bar, const int lookback, const ENUM_TIMEFRAMES tf);
   bool              AnalyzeBOS(SStructurePoint &highs[], SStructurePoint &lows[], int h_count, int l_count, SMarketStructure &structure, const ENUM_TIMEFRAMES tf);
   bool              AnalyzeCHOCH(SStructurePoint &highs[], SStructurePoint &lows[], int h_count, int l_count, SMarketStructure &structure, const ENUM_TIMEFRAMES tf);
   bool              AnalyzeMSS(SMarketStructure &structure);
   double            CalculateTrendStrength(const ENUM_TIMEFRAMES tf);
   int               CountHigherHighs(SStructurePoint &highs[], int count);
   int               CountHigherLows(SStructurePoint &lows[], int count);
   int               CountLowerHighs(SStructurePoint &highs[], int count);
   int               CountLowerLows(SStructurePoint &lows[], int count);

public:
   //--- Constructeur / Destructeur
                     CMarketStructureEngine();
                    ~CMarketStructureEngine();

   //--- Initialisation
   bool              Initialize(int swing_lookback = 10, double break_threshold = 0.0, int structure_lookback = 100);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update(const ENUM_TIMEFRAMES tf);

   //--- Accesseurs structure
   SMarketStructure  GetStructure(const ENUM_TIMEFRAMES tf) const;
   ENUM_MARKET_DIRECTION GetDirection(const ENUM_TIMEFRAMES tf) const;
   double            GetTrendStrength(const ENUM_TIMEFRAMES tf) const;
   double            GetLastSwingHigh(const ENUM_TIMEFRAMES tf) const;
   double            GetLastSwingLow(const ENUM_TIMEFRAMES tf) const;

   //--- Vérifications structurelles
   bool              IsBullishStructure(const ENUM_TIMEFRAMES tf) const;
   bool              IsBearishStructure(const ENUM_TIMEFRAMES tf) const;
   bool              HasBOS(const ENUM_TIMEFRAMES tf) const;
   bool              HasCHOCH(const ENUM_TIMEFRAMES tf) const;
   bool              HasMSS(const ENUM_TIMEFRAMES tf) const;
   bool              IsMultiTimeframeAligned() const;

   //--- Informations debug
   string            GetStructureInfo(const ENUM_TIMEFRAMES tf) const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CMarketStructureEngine::CMarketStructureEngine() :
   m_swing_lookback(10),
   m_break_threshold(0.0),
   m_structure_lookback(100),
   m_initialized(false),
   m_swing_count(0),
   m_ema_handle(INVALID_HANDLE)
  {
   ArrayResize(m_swing_highs, 0);
   ArrayResize(m_swing_lows, 0);
   ZeroMemory(m_structure_htf);
   ZeroMemory(m_structure_mtf);
   ZeroMemory(m_structure_ltf);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CMarketStructureEngine::~CMarketStructureEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::Initialize(int swing_lookback, double break_threshold, int structure_lookback)
  {
   m_swing_lookback = (swing_lookback > 2) ? swing_lookback : 10;
   m_break_threshold = (break_threshold > 0) ? break_threshold : 0.0;
   m_structure_lookback = (structure_lookback > 20) ? structure_lookback : 100;

   //--- Créer l'EMA 50 pour confirmation tendance
   m_ema_handle = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(m_ema_handle == INVALID_HANDLE)
     {
      Print("A2Sniper MSE: Erreur création EMA handle - ", GetLastError());
      return false;
     }

   ArraySetAsSeries(m_ema_buffer, true);
   m_initialized = true;
   Print("A2Sniper MSE: Market Structure Engine initialisé avec succès");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CMarketStructureEngine::Deinitialize()
  {
   if(m_ema_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_ema_handle);
      m_ema_handle = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Détection des Swing Points                                       |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::DetectSwingPoints(const ENUM_TIMEFRAMES tf,
                                                SStructurePoint &highs[],
                                                SStructurePoint &lows[],
                                                int &h_count,
                                                int &l_count)
  {
   h_count = 0;
   l_count = 0;

   int bars_available = iBars(_Symbol, tf);
   if(bars_available < m_swing_lookback * 2 + 1)
      return false;

   //--- Tableaux temporaires
   SStructurePoint temp_highs[];
   SStructurePoint temp_lows[];
   ArrayResize(temp_highs, 0);
   ArrayResize(temp_lows, 0);

   //--- Scanner les barres pour trouver les swings
   int start_bar = m_swing_lookback + 1;
   int end_bar = MathMin(m_structure_lookback, bars_available - m_swing_lookback - 1);

   for(int i = start_bar; i < end_bar; i++)
     {
      //--- Swing High
      if(IsSwingHigh(i, m_swing_lookback, tf))
        {
         SStructurePoint point;
         point.price = iHigh(_Symbol, tf, i);
         point.time = iTime(_Symbol, tf, i);
         point.bar_index = i;
         point.is_valid = true;

         //--- Déterminer le type (HH ou LH)
         if(h_count > 0)
           {
            if(point.price > temp_highs[h_count - 1].price)
               point.type = STRUCTURE_HH;
            else
               point.type = STRUCTURE_LH;
           }
         else
            point.type = STRUCTURE_HH; // Premier point par défaut

         h_count++;
         ArrayResize(temp_highs, h_count);
         temp_highs[h_count - 1] = point;
        }

      //--- Swing Low
      if(IsSwingLow(i, m_swing_lookback, tf))
        {
         SStructurePoint point;
         point.price = iLow(_Symbol, tf, i);
         point.time = iTime(_Symbol, tf, i);
         point.bar_index = i;
         point.is_valid = true;

         //--- Déterminer le type (HL ou LL)
         if(l_count > 0)
           {
            if(point.price > temp_lows[l_count - 1].price)
               point.type = STRUCTURE_HL;
            else
               point.type = STRUCTURE_LL;
           }
         else
            point.type = STRUCTURE_HL; // Premier point par défaut

         l_count++;
         ArrayResize(temp_lows, l_count);
         temp_lows[l_count - 1] = point;
        }
     }

   //--- Copier vers les tableaux de sortie
   ArrayResize(highs, h_count);
   ArrayResize(lows, l_count);
   for(int i = 0; i < h_count; i++)
      highs[i] = temp_highs[i];
   for(int i = 0; i < l_count; i++)
      lows[i] = temp_lows[i];

   return (h_count >= 2 && l_count >= 2);
  }

//+------------------------------------------------------------------+
//| Vérifier si une barre est un Swing High                          |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::IsSwingHigh(const int bar, const int lookback, const ENUM_TIMEFRAMES tf)
  {
   double center_high = iHigh(_Symbol, tf, bar);
   if(center_high <= 0)
      return false;

   //--- Vérifier que le centre est plus haut que toutes les barres adjacentes
   for(int i = 1; i <= lookback; i++)
     {
      if(bar - i < 0 || bar + i < 0)
         return false;

      double left_high = iHigh(_Symbol, tf, bar - i);
      double right_high = iHigh(_Symbol, tf, bar + i);

      if(left_high <= 0 || right_high <= 0)
         return false;

      //--- Le centre doit être strictement supérieur (avec tolérance)
      double tolerance = m_break_threshold > 0 ? m_break_threshold * _Point : _Point * 5;
      if(center_high < left_high - tolerance || center_high < right_high - tolerance)
         return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Vérifier si une barre est un Swing Low                           |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::IsSwingLow(const int bar, const int lookback, const ENUM_TIMEFRAMES tf)
  {
   double center_low = iLow(_Symbol, tf, bar);
   if(center_low <= 0)
      return false;

   for(int i = 1; i <= lookback; i++)
     {
      if(bar - i < 0 || bar + i < 0)
         return false;

      double left_low = iLow(_Symbol, tf, bar - i);
      double right_low = iLow(_Symbol, tf, bar + i);

      if(left_low <= 0 || right_low <= 0)
         return false;

      double tolerance = m_break_threshold > 0 ? m_break_threshold * _Point : _Point * 5;
      if(center_low > left_low + tolerance || center_low > right_low + tolerance)
         return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Analyser Break of Structure                                      |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::AnalyzeBOS(SStructurePoint &highs[], SStructurePoint &lows[],
                                          int h_count, int l_count, SMarketStructure &structure, const ENUM_TIMEFRAMES tf)
  {
   structure.has_bos = false;

   //--- BOS Haussier: le prix casse au-dessus du dernier swing high
   if(h_count >= 2)
     {
      double current_price = iClose(_Symbol, tf, 0);
      double last_sh = highs[h_count - 1].price;
      double prev_sh = highs[h_count - 2].price;

      //--- BOS haussier si le prix casse au-dessus du dernier SH
      if(current_price > last_sh && last_sh > prev_sh)
        {
         structure.last_event = STRUCTURE_BOS_BULLISH;
         structure.has_bos = true;
         return true;
        }
     }

   //--- BOS Baissier: le prix casse en-dessous du dernier swing low
   if(l_count >= 2)
     {
      double current_price = iClose(_Symbol, tf, 0);
      double last_sl = lows[l_count - 1].price;
      double prev_sl = lows[l_count - 2].price;

      if(current_price < last_sl && last_sl < prev_sl)
        {
         structure.last_event = STRUCTURE_BOS_BEARISH;
         structure.has_bos = true;
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Analyser Change of Character                                     |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::AnalyzeCHOCH(SStructurePoint &highs[], SStructurePoint &lows[],
                                            int h_count, int l_count, SMarketStructure &structure, const ENUM_TIMEFRAMES tf)
  {
   structure.has_choch = false;

   //--- CHOCH nécessite au moins 3 swings pour confirmer le changement
   if(h_count < 2 || l_count < 2)
      return false;

   //--- CHOCH Haussier: après une tendance baissière, on forme HH + HL
   if(structure.direction == MARKET_DIRECTION_BEARISH || structure.direction == MARKET_DIRECTION_RANGE)
     {
      double current_price = iClose(_Symbol, tf, 0);

      //--- Le dernier swing high casse le précédent (HH) après une série de LH
      if(highs[h_count - 1].price > highs[h_count - 2].price &&
         lows[l_count - 1].price > lows[l_count - 2].price)
        {
         structure.last_event = STRUCTURE_CHOCH_BULLISH;
         structure.has_choch = true;
         structure.direction = MARKET_DIRECTION_BULLISH;
         return true;
        }
     }

   //--- CHOCH Baissier: après une tendance haussière, on forme LH + LL
   if(structure.direction == MARKET_DIRECTION_BULLISH || structure.direction == MARKET_DIRECTION_RANGE)
     {
      if(highs[h_count - 1].price < highs[h_count - 2].price &&
         lows[l_count - 1].price < lows[l_count - 2].price)
        {
         structure.last_event = STRUCTURE_CHOCH_BEARISH;
         structure.has_choch = true;
         structure.direction = MARKET_DIRECTION_BEARISH;
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Analyser Market Structure Shift                                  |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::AnalyzeMSS(SMarketStructure &structure)
  {
   structure.has_mss = false;

   //--- MSS = CHOCH + première confirmation (début de retournement)
   if(structure.has_choch)
     {
      if(structure.last_event == STRUCTURE_CHOCH_BULLISH)
        {
         structure.last_event = STRUCTURE_MSS_BULLISH;
         structure.has_mss = true;
         return true;
        }
      else if(structure.last_event == STRUCTURE_CHOCH_BEARISH)
        {
         structure.last_event = STRUCTURE_MSS_BEARISH;
         structure.has_mss = true;
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Calculer la force de la tendance                                 |
//+------------------------------------------------------------------+
double CMarketStructureEngine::CalculateTrendStrength(const ENUM_TIMEFRAMES tf)
  {
   //--- Compter les HH/HL pour tendance haussière, LH/LL pour baissière
   SStructurePoint highs[];
   SStructurePoint lows[];
   int h_count = 0, l_count = 0;

   if(!DetectSwingPoints(tf, highs, lows, h_count, l_count))
      return 50.0; // Neutre

   if(h_count < 2 || l_count < 2)
      return 50.0;

   int hh = CountHigherHighs(highs, h_count);
   int hl = CountHigherLows(lows, l_count);
   int lh = CountLowerHighs(highs, h_count);
   int ll = CountLowerLows(lows, l_count);

   //--- Force haussière = (HH + HL) / total
   int total_points = MathMax(h_count + l_count - 2, 1);
   double bullish_strength = ((double)(hh + hl) / (double)total_points) * 100.0;
   double bearish_strength = ((double)(lh + ll) / (double)total_points) * 100.0;

   //--- Confirmer avec EMA
   if(CopyBuffer(m_ema_handle, 0, 0, 1, m_ema_buffer) > 0)
     {
      double price = iClose(_Symbol, tf, 0);
      if(price > m_ema_buffer[0])
         bullish_strength += 10.0;
      else
         bearish_strength += 10.0;
     }

   return MathMax(bullish_strength, bearish_strength);
  }

//+------------------------------------------------------------------+
//| Compter les Higher Highs                                         |
//+------------------------------------------------------------------+
int CMarketStructureEngine::CountHigherHighs(SStructurePoint &highs[], int count)
  {
   int result = 0;
   for(int i = 1; i < count; i++)
     {
      if(highs[i].price > highs[i - 1].price)
         result++;
     }
   return result;
  }

//+------------------------------------------------------------------+
//| Compter les Higher Lows                                          |
//+------------------------------------------------------------------+
int CMarketStructureEngine::CountHigherLows(SStructurePoint &lows[], int count)
  {
   int result = 0;
   for(int i = 1; i < count; i++)
     {
      if(lows[i].price > lows[i - 1].price)
         result++;
     }
   return result;
  }

//+------------------------------------------------------------------+
//| Compter les Lower Highs                                          |
//+------------------------------------------------------------------+
int CMarketStructureEngine::CountLowerHighs(SStructurePoint &highs[], int count)
  {
   int result = 0;
   for(int i = 1; i < count; i++)
     {
      if(highs[i].price < highs[i - 1].price)
         result++;
     }
   return result;
  }

//+------------------------------------------------------------------+
//| Compter les Lower Lows                                           |
//+------------------------------------------------------------------+
int CMarketStructureEngine::CountLowerLows(SStructurePoint &lows[], int count)
  {
   int result = 0;
   for(int i = 1; i < count; i++)
     {
      if(lows[i].price < lows[i - 1].price)
         result++;
     }
   return result;
  }

//+------------------------------------------------------------------+
//| Mise à jour principale                                          |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::Update(const ENUM_TIMEFRAMES tf)
  {
   if(!m_initialized)
      return false;

   SStructurePoint highs[];
   SStructurePoint lows[];
   int h_count = 0, l_count = 0;

   //--- Détecter les swing points
   if(!DetectSwingPoints(tf, highs, lows, h_count, l_count))
      return false;

   //--- Stocker les swings pour référence
   ArrayResize(m_swing_highs, h_count);
   ArrayResize(m_swing_lows, l_count);
   for(int i = 0; i < h_count; i++)
      m_swing_highs[i] = highs[i];
   for(int i = 0; i < l_count; i++)
      m_swing_lows[i] = lows[i];
   m_swing_count = h_count + l_count;

   //--- Déterminer la direction
   int hh = CountHigherHighs(highs, h_count);
   int hl = CountHigherLows(lows, l_count);
   int lh = CountLowerHighs(highs, h_count);
   int ll = CountLowerLows(lows, l_count);

   //--- Direction basée sur la majorité des swings (plus souple que 6/10)
   int bullish_points = hh + hl;
   int bearish_points = lh + ll;
   int total_directional = bullish_points + bearish_points;

   ENUM_MARKET_DIRECTION new_direction = MARKET_DIRECTION_RANGE;
   if(total_directional > 0)
     {
      if(bullish_points > bearish_points && (double)bullish_points / total_directional > 0.65)
         new_direction = MARKET_DIRECTION_BULLISH;
      else if(bearish_points > bullish_points && (double)bearish_points / total_directional > 0.65)
         new_direction = MARKET_DIRECTION_BEARISH;
     }

   //--- Sélectionner la structure appropriée et mettre à jour directement
   if(tf >= PERIOD_H4)
     {
      m_structure_htf.direction = new_direction;
      if(h_count > 0)
        {
         m_structure_htf.last_swing_high = highs[h_count - 1].price;
         m_structure_htf.swing_high_bar = highs[h_count - 1].bar_index;
        }
      if(l_count > 0)
        {
         m_structure_htf.last_swing_low = lows[l_count - 1].price;
         m_structure_htf.swing_low_bar = lows[l_count - 1].bar_index;
        }
      AnalyzeBOS(highs, lows, h_count, l_count, m_structure_htf, tf);
      AnalyzeCHOCH(highs, lows, h_count, l_count, m_structure_htf, tf);
      AnalyzeMSS(m_structure_htf);
      m_structure_htf.trend_strength = CalculateTrendStrength(tf);
     }
   else if(tf >= PERIOD_H1)
     {
      m_structure_mtf.direction = new_direction;
      if(h_count > 0)
        {
         m_structure_mtf.last_swing_high = highs[h_count - 1].price;
         m_structure_mtf.swing_high_bar = highs[h_count - 1].bar_index;
        }
      if(l_count > 0)
        {
         m_structure_mtf.last_swing_low = lows[l_count - 1].price;
         m_structure_mtf.swing_low_bar = lows[l_count - 1].bar_index;
        }
      AnalyzeBOS(highs, lows, h_count, l_count, m_structure_mtf, tf);
      AnalyzeCHOCH(highs, lows, h_count, l_count, m_structure_mtf, tf);
      AnalyzeMSS(m_structure_mtf);
      m_structure_mtf.trend_strength = CalculateTrendStrength(tf);
     }
   else
     {
      m_structure_ltf.direction = new_direction;
      if(h_count > 0)
        {
         m_structure_ltf.last_swing_high = highs[h_count - 1].price;
         m_structure_ltf.swing_high_bar = highs[h_count - 1].bar_index;
        }
      if(l_count > 0)
        {
         m_structure_ltf.last_swing_low = lows[l_count - 1].price;
         m_structure_ltf.swing_low_bar = lows[l_count - 1].bar_index;
        }
      AnalyzeBOS(highs, lows, h_count, l_count, m_structure_ltf, tf);
      AnalyzeCHOCH(highs, lows, h_count, l_count, m_structure_ltf, tf);
      AnalyzeMSS(m_structure_ltf);
      m_structure_ltf.trend_strength = CalculateTrendStrength(tf);
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
SMarketStructure CMarketStructureEngine::GetStructure(const ENUM_TIMEFRAMES tf) const
  {
   if(tf >= PERIOD_H4)
      return m_structure_htf;
   else if(tf >= PERIOD_H1)
      return m_structure_mtf;
   else
      return m_structure_ltf;
  }

ENUM_MARKET_DIRECTION CMarketStructureEngine::GetDirection(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).direction;
  }

double CMarketStructureEngine::GetTrendStrength(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).trend_strength;
  }

double CMarketStructureEngine::GetLastSwingHigh(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).last_swing_high;
  }

double CMarketStructureEngine::GetLastSwingLow(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).last_swing_low;
  }

bool CMarketStructureEngine::IsBullishStructure(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).direction == MARKET_DIRECTION_BULLISH;
  }

bool CMarketStructureEngine::IsBearishStructure(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).direction == MARKET_DIRECTION_BEARISH;
  }

bool CMarketStructureEngine::HasBOS(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).has_bos;
  }

bool CMarketStructureEngine::HasCHOCH(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).has_choch;
  }

bool CMarketStructureEngine::HasMSS(const ENUM_TIMEFRAMES tf) const
  {
   return GetStructure(tf).has_mss;
  }

//+------------------------------------------------------------------+
//| Vérification multi-timeframe aligné                              |
//+------------------------------------------------------------------+
bool CMarketStructureEngine::IsMultiTimeframeAligned() const
  {
   //--- Les 3 timeframes doivent avoir la même direction
   ENUM_MARKET_DIRECTION dir_htf = m_structure_htf.direction;
   ENUM_MARKET_DIRECTION dir_mtf = m_structure_mtf.direction;
   ENUM_MARKET_DIRECTION dir_ltf = m_structure_ltf.direction;

   //--- Au moins HTF et MTF doivent être alignés
   if(dir_htf != MARKET_DIRECTION_RANGE && dir_htf == dir_mtf)
      return true;

   //--- Les 3 alignés = signal le plus fort
   if(dir_htf == dir_mtf && dir_mtf == dir_ltf && dir_htf != MARKET_DIRECTION_RANGE)
      return true;

   return false;
  }

//+------------------------------------------------------------------+
//| Information de debug                                             |
//+------------------------------------------------------------------+
string CMarketStructureEngine::GetStructureInfo(const ENUM_TIMEFRAMES tf) const
  {
   SMarketStructure s = GetStructure(tf);
   string dir = "";
   switch(s.direction)
     {
      case MARKET_DIRECTION_BULLISH: dir = "BULLISH"; break;
      case MARKET_DIRECTION_BEARISH: dir = "BEARISH"; break;
      case MARKET_DIRECTION_RANGE:   dir = "RANGE"; break;
     }
   string info = StringFormat("Structure[%s]: Dir=%s | Strength=%.1f | SH=%.5f | SL=%.5f | BOS=%s | CHOCH=%s | MSS=%s",
                              EnumToString(tf), dir, s.trend_strength,
                              s.last_swing_high, s.last_swing_low,
                              s.has_bos ? "Y" : "N", s.has_choch ? "Y" : "N", s.has_mss ? "Y" : "N");
   return info;
  }

#endif // A2SNIPER_MARKET_STRUCTURE_MQH
//+------------------------------------------------------------------+
