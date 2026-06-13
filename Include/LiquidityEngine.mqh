//+------------------------------------------------------------------+
//| LiquidityEngine.mqh - Détection de Zones de Liquidité v4.0      |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| v4: Dynamic ATR-based tolerance, liquidity void detection,        |
//|     instrument-aware tolerance, enhanced sweep validation         |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_LIQUIDITY_MQH
#define A2SNIPER_LIQUIDITY_MQH

#include <A2Sniper\CommonTypes.mqh>

//+------------------------------------------------------------------+
//| Classe CLiquidityEngine                                          |
//+------------------------------------------------------------------+
class CLiquidityEngine
  {
private:
   bool              m_initialized;
   int               m_lookback;
   double            m_equal_tolerance;      // Tolérance en pips pour equal highs/lows
   bool              m_dynamic_tolerance;    // v4: Tolérance dynamique basée ATR
   int               m_atr_handle;
   double            m_current_atr;          // v4: ATR actuel pour tolérance dynamique

   //--- Zones de liquidité
   SLiquidityZone    m_zones[];
   int               m_zone_count;

   //--- v4: Vides de liquidité (liquidity voids)
   double            m_void_high[];          // Limite haute du vide
   double            m_void_low[];           // Limite basse du vide
   datetime          m_void_time[];          // Heure du vide
   int               m_void_count;

   //--- Sweeps détectés
   bool              m_last_bsl_sweep;       // Dernier sweep BSL
   bool              m_last_ssl_sweep;       // Dernier sweep SSL
   datetime          m_last_sweep_time;      // Heure du dernier sweep
   ENUM_LIQUIDITY_TYPE m_last_sweep_type;    // Type du dernier sweep
   int               m_sweep_persist_bars;   // How many bars to keep sweep state
   int               m_bsl_sweep_bar;        // Bar index when BSL sweep was detected
   int               m_ssl_sweep_bar;        // Bar index when SSL sweep was detected

   //--- Méthodes privées
   bool              DetectEqualHighs();
   bool              DetectEqualLows();
   bool              DetectDoubleTop();
   bool              DetectDoubleBottom();
   bool              DetectLiquiditySweep(const double current_price);
   bool              DetectLiquidityVoids();  // v4: Détection des vides
   bool              ArePricesEqual(const double price1, const double price2) const;
   double            GetDynamicTolerance() const;  // v4: Tolérance ATR-aware
   void              CleanupOldZones();
   double            GetATRValue(const int shift);

public:
   //--- Constructeur / Destructeur
                     CLiquidityEngine();
                    ~CLiquidityEngine();

   //--- Initialisation
   bool              Initialize(int lookback = LIQUIDITY_LOOKBACK, double equal_tolerance_pips = EQUAL_TOLERANCE_PIPS);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   int               GetZoneCount() const { return m_zone_count; }
   SLiquidityZone    GetZone(const int index) const;
   bool              HasBSLSweep() const { return m_last_bsl_sweep; }
   bool              HasSSLSweep() const { return m_last_ssl_sweep; }
   ENUM_LIQUIDITY_TYPE GetLastSweepType() const { return m_last_sweep_type; }

   //--- Vérifications
   bool              IsPriceNearLiquidity(const double price, const double tolerance_pips) const;
   SLiquidityZone    GetNearestLiquidityZone(const double price) const;
   double            GetLiquidityScore(const ENUM_SIGNAL_TYPE direction) const;
   bool              HasLiquiditySweepForDirection(const ENUM_SIGNAL_TYPE direction) const;

   //--- v4: Liquidity Voids
   int               GetVoidCount() const { return m_void_count; }
   bool              IsPriceInVoid(const double price) const;
   double            GetVoidScore(const ENUM_SIGNAL_TYPE direction) const;

   //--- Info
   string            GetZoneInfo(const SLiquidityZone &zone) const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CLiquidityEngine::CLiquidityEngine() :
   m_initialized(false),
   m_lookback(LIQUIDITY_LOOKBACK),
   m_equal_tolerance(EQUAL_TOLERANCE_PIPS),
   m_dynamic_tolerance(true),
   m_atr_handle(INVALID_HANDLE),
   m_current_atr(0),
   m_zone_count(0),
   m_void_count(0),
   m_last_bsl_sweep(false),
   m_last_ssl_sweep(false),
   m_last_sweep_time(0),
   m_last_sweep_type(LIQUIDITY_NONE),
   m_sweep_persist_bars(10),
   m_bsl_sweep_bar(-1),
   m_ssl_sweep_bar(-1)
  {
   ArrayResize(m_zones, 0);
   ArrayResize(m_void_high, 0);
   ArrayResize(m_void_low, 0);
   ArrayResize(m_void_time, 0);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CLiquidityEngine::~CLiquidityEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CLiquidityEngine::Initialize(int lookback, double equal_tolerance_pips)
  {
   m_lookback = (lookback > 10) ? lookback : LIQUIDITY_LOOKBACK;
   m_equal_tolerance = (equal_tolerance_pips > 0) ? equal_tolerance_pips : EQUAL_TOLERANCE_PIPS;

   m_atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(m_atr_handle == INVALID_HANDLE)
     {
      Print("A2Sniper LE: Erreur création ATR - ", GetLastError());
      return false;
     }

   m_initialized = true;
   Print("A2Sniper LE: Liquidity Engine v4 initialisé (dynamic tolerance + voids)");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CLiquidityEngine::Deinitialize()
  {
   if(m_atr_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_atr_handle);
      m_atr_handle = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Tolérance dynamique basée sur l'ATR et l'instrument              |
//| JPY pairs: tolérance plus large (ATR ~0.50-1.00)                 |
//| Forex standard: tolérance normale (ATR ~0.0005-0.0020)           |
//| Crypto: tolérance très large (ATR très variable)                  |
//+------------------------------------------------------------------+
double CLiquidityEngine::GetDynamicTolerance() const
  {
   if(!m_dynamic_tolerance || m_current_atr <= 0)
      return m_equal_tolerance;    // Fallback: tolérance fixe

   //--- Tolérance = 15% de l'ATR (en pips)
   //--- Cela s'adapte automatiquement à la volatilité de l'instrument
   double atr_pips = m_current_atr / _Point;
   double dynamic_tol = atr_pips * 0.15;

   //--- Plancher et plafond pour éviter les extrêmes
   double min_tol = 1.0;      // Au minimum 1 pip
   double max_tol = 15.0;     // Au maximum 15 pips

   dynamic_tol = MathMax(dynamic_tol, min_tol);
   dynamic_tol = MathMin(dynamic_tol, max_tol);

   return dynamic_tol;
  }

//+------------------------------------------------------------------+
//| Vérifier si deux prix sont "égaux" (dans la tolérance)          |
//| v4: Utilise la tolérance dynamique si disponible                  |
//+------------------------------------------------------------------+
bool CLiquidityEngine::ArePricesEqual(const double price1, const double price2) const
  {
   double tolerance = m_equal_tolerance;
   //--- Si tolérance dynamique disponible, l'utiliser
   if(m_dynamic_tolerance && m_current_atr > 0)
     {
      double dyn_tol = GetDynamicTolerance();
      tolerance = dyn_tol;
     }
   return (MathAbs(price1 - price2) / _Point) <= tolerance;
  }

//+------------------------------------------------------------------+
//| Détection Equal Highs (v4: ATR-based strength scoring)           |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectEqualHighs()
  {
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if(bars < m_lookback)
      return false;

   //--- Scanner les swing highs pour trouver des égalités
   double prev_high = 0;
   int prev_high_bar = -1;

   for(int i = 5; i < MathMin(m_lookback, bars - 5); i++)
     {
      //--- Swing High simple (plus haut que les 4 barres adjacentes)
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      bool is_swing = true;
      for(int j = 1; j <= 4; j++)
        {
         if(iHigh(_Symbol, PERIOD_CURRENT, i - j) > high ||
            iHigh(_Symbol, PERIOD_CURRENT, i + j) > high)
           {
            is_swing = false;
            break;
           }
        }

      if(is_swing)
        {
         //--- Comparer avec le swing high précédent
         if(prev_high_bar > 0 && ArePricesEqual(high, prev_high))
           {
            //--- Equal High détecté = BSL (Buy Side Liquidity)
            //--- v4: Force basée sur la proximité temporelle
            int bar_distance = prev_high_bar - i;
            double strength = 80.0;
            if(bar_distance <= 10) strength = 95.0;    // Equal highs proches = plus fort
            else if(bar_distance <= 20) strength = 85.0;
            else strength = 70.0;                        // Equal highs éloignés

            SLiquidityZone zone;
            zone.price = (high + prev_high) / 2.0;
            zone.time = iTime(_Symbol, PERIOD_CURRENT, i);
            zone.type = LIQUIDITY_EQUAL_HIGH;
            zone.strength = strength;
            zone.is_swept = false;
            zone.is_valid = true;

            m_zone_count++;
            ArrayResize(m_zones, m_zone_count);
            m_zones[m_zone_count - 1] = zone;
           }

         prev_high = high;
         prev_high_bar = i;
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Détection Equal Lows                                             |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectEqualLows()
  {
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if(bars < m_lookback)
      return false;

   double prev_low = 0;
   int prev_low_bar = -1;

   for(int i = 5; i < MathMin(m_lookback, bars - 5); i++)
     {
      double low = iLow(_Symbol, PERIOD_CURRENT, i);
      bool is_swing = true;
      for(int j = 1; j <= 4; j++)
        {
         if(iLow(_Symbol, PERIOD_CURRENT, i - j) < low ||
            iLow(_Symbol, PERIOD_CURRENT, i + j) < low)
           {
            is_swing = false;
            break;
           }
        }

      if(is_swing)
        {
         if(prev_low_bar > 0 && ArePricesEqual(low, prev_low))
           {
            //--- Equal Low = SSL (Sell Side Liquidity)
            SLiquidityZone zone;
            zone.price = (low + prev_low) / 2.0;
            zone.time = iTime(_Symbol, PERIOD_CURRENT, i);
            zone.type = LIQUIDITY_EQUAL_LOW;
            zone.strength = 80.0;
            zone.is_swept = false;
            zone.is_valid = true;

            m_zone_count++;
            ArrayResize(m_zones, m_zone_count);
            m_zones[m_zone_count - 1] = zone;
           }

         prev_low = low;
         prev_low_bar = i;
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Détection Double Top                                             |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectDoubleTop()
  {
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if(bars < 20)
      return false;

   //--- Chercher deux sommets proches avec un creux entre les deux
   for(int i = 10; i < MathMin(m_lookback, bars - 10); i++)
     {
      double high1 = iHigh(_Symbol, PERIOD_CURRENT, i);
      double high2 = iHigh(_Symbol, PERIOD_CURRENT, i - 5);

      //--- Les deux sommets doivent être égaux
      if(!ArePricesEqual(high1, high2))
         continue;

      //--- Le creux entre les deux doit être significatif
      double low_between = iLow(_Symbol, PERIOD_CURRENT, i - 2);
      double atr = GetATRValue(i);
      if(atr <= 0) continue;

      if(high1 - low_between < 0.5 * atr)
         continue;

      //--- Double Top détecté = BSL
      SLiquidityZone zone;
      zone.price = (high1 + high2) / 2.0;
      zone.time = iTime(_Symbol, PERIOD_CURRENT, i);
      zone.type = LIQUIDITY_DOUBLE_TOP;
      zone.strength = 90.0;
      zone.is_swept = false;
      zone.is_valid = true;

      m_zone_count++;
      ArrayResize(m_zones, m_zone_count);
      m_zones[m_zone_count - 1] = zone;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Détection Double Bottom                                          |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectDoubleBottom()
  {
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if(bars < 20)
      return false;

   for(int i = 10; i < MathMin(m_lookback, bars - 10); i++)
     {
      double low1 = iLow(_Symbol, PERIOD_CURRENT, i);
      double low2 = iLow(_Symbol, PERIOD_CURRENT, i - 5);

      if(!ArePricesEqual(low1, low2))
         continue;

      double high_between = iHigh(_Symbol, PERIOD_CURRENT, i - 2);
      double atr = GetATRValue(i);
      if(atr <= 0) continue;

      if(high_between - low1 < 0.5 * atr)
         continue;

      SLiquidityZone zone;
      zone.price = (low1 + low2) / 2.0;
      zone.time = iTime(_Symbol, PERIOD_CURRENT, i);
      zone.type = LIQUIDITY_DOUBLE_BOTTOM;
      zone.strength = 90.0;
      zone.is_swept = false;
      zone.is_valid = true;

      m_zone_count++;
      ArrayResize(m_zones, m_zone_count);
      m_zones[m_zone_count - 1] = zone;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Détection Liquidity Sweep                                        |
//| Conditions: Cassure + Prise de liquidité + Réintégration + Rejet |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectLiquiditySweep(const double current_price)
  {
   //--- Check if sweep persistence has expired
   int current_bar = iBars(_Symbol, PERIOD_CURRENT);
   if(m_bsl_sweep_bar >= 0 && (current_bar - m_bsl_sweep_bar) > m_sweep_persist_bars)
      m_last_bsl_sweep = false;
   if(m_ssl_sweep_bar >= 0 && (current_bar - m_ssl_sweep_bar) > m_sweep_persist_bars)
      m_last_ssl_sweep = false;

   //--- Vérifier les 3 dernières bougies pour un sweep
   for(int i = 0; i < 3; i++)
     {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low  = iLow(_Symbol, PERIOD_CURRENT, i);
      double open = iOpen(_Symbol, PERIOD_CURRENT, i);
      double close = iClose(_Symbol, PERIOD_CURRENT, i);

      //--- BSL Sweep: le prix a cassé au-dessus d'une zone BSL puis a clôturé en-dessous
      for(int j = 0; j < m_zone_count; j++)
        {
         if(!m_zones[j].is_valid || m_zones[j].is_swept)
            continue;

         //--- BSL (Equal High, Double Top)
         if(m_zones[j].type == LIQUIDITY_EQUAL_HIGH || m_zones[j].type == LIQUIDITY_DOUBLE_TOP)
           {
            //--- La mèche haute a dépassé la zone, mais la clôture est revenue en-dessous
            if(high > m_zones[j].price && close < m_zones[j].price)
              {
               m_zones[j].is_swept = true;
               m_last_bsl_sweep = true;
               m_bsl_sweep_bar = current_bar;
               m_last_sweep_type = LIQUIDITY_BSL;
               m_last_sweep_time = iTime(_Symbol, PERIOD_CURRENT, i);
               return true;
              }
           }

         //--- SSL (Equal Low, Double Bottom)
         if(m_zones[j].type == LIQUIDITY_EQUAL_LOW || m_zones[j].type == LIQUIDITY_DOUBLE_BOTTOM)
           {
            //--- La mèche basse a dépassé la zone, mais la clôture est revenue au-dessus
            if(low < m_zones[j].price && close > m_zones[j].price)
              {
               m_zones[j].is_swept = true;
               m_last_ssl_sweep = true;
               m_ssl_sweep_bar = current_bar;
               m_last_sweep_type = LIQUIDITY_SSL;
               m_last_sweep_time = iTime(_Symbol, PERIOD_CURRENT, i);
               return true;
              }
           }
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Nettoyer les anciennes zones                                     |
//+------------------------------------------------------------------+
void CLiquidityEngine::CleanupOldZones()
  {
   SLiquidityZone temp[];
   int new_count = 0;
   int max_zones = 50;

   for(int i = m_zone_count - 1; i >= 0 && new_count < max_zones; i--)
     {
      if(m_zones[i].is_valid)
        {
         new_count++;
         ArrayResize(temp, new_count);
         temp[new_count - 1] = m_zones[i];
        }
     }

   m_zone_count = new_count;
   ArrayResize(m_zones, m_zone_count);
   for(int i = 0; i < m_zone_count; i++)
      m_zones[i] = temp[m_zone_count - 1 - i];
  }

//+------------------------------------------------------------------+
//| Obtenir ATR                                                      |
//+------------------------------------------------------------------+
double CLiquidityEngine::GetATRValue(const int shift)
  {
   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(m_atr_handle, 0, shift, 1, buffer) > 0)
      return buffer[0];
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Détection des vides de liquidité (Liquidity Voids)               |
//| Un vide = zone où le prix a bougé très vite sans échange         |
//| Gaps entre les bougies, grandes bougies avec peu de mèches        |
//| Ces zones attirent le prix comme un aimant pour combler le vide   |
//+------------------------------------------------------------------+
bool CLiquidityEngine::DetectLiquidityVoids()
  {
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   if(bars < 10) return false;

   double atr = m_current_atr;
   if(atr <= 0) return false;

   m_void_count = 0;
   ArrayResize(m_void_high, 0);
   ArrayResize(m_void_low, 0);
   ArrayResize(m_void_time, 0);

   for(int i = 1; i < MathMin(m_lookback, bars - 1); i++)
     {
      double prev_high = iHigh(_Symbol, PERIOD_CURRENT, i + 1);
      double prev_low = iLow(_Symbol, PERIOD_CURRENT, i + 1);
      double curr_high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double curr_low = iLow(_Symbol, PERIOD_CURRENT, i);

      //--- Void: gap entre le low actuel et le high précédent (bullish void)
      if(curr_low > prev_high)
        {
         double gap = curr_low - prev_high;
         if(gap >= atr * 0.3)   // Gap significatif
           {
            m_void_count++;
            ArrayResize(m_void_high, m_void_count);
            ArrayResize(m_void_low, m_void_count);
            ArrayResize(m_void_time, m_void_count);
            m_void_high[m_void_count - 1] = curr_low;
            m_void_low[m_void_count - 1] = prev_high;
            m_void_time[m_void_count - 1] = iTime(_Symbol, PERIOD_CURRENT, i);
           }
        }

      //--- Void: gap entre le high actuel et le low précédent (bearish void)
      if(curr_high < prev_low)
        {
         double gap = prev_low - curr_high;
         if(gap >= atr * 0.3)
           {
            m_void_count++;
            ArrayResize(m_void_high, m_void_count);
            ArrayResize(m_void_low, m_void_count);
            ArrayResize(m_void_time, m_void_count);
            m_void_high[m_void_count - 1] = prev_low;
            m_void_low[m_void_count - 1] = curr_high;
            m_void_time[m_void_count - 1] = iTime(_Symbol, PERIOD_CURRENT, i);
           }
        }
     }

   return (m_void_count > 0);
  }

//+------------------------------------------------------------------+
//| Le prix est-il dans un vide de liquidité ?                       |
//+------------------------------------------------------------------+
bool CLiquidityEngine::IsPriceInVoid(const double price) const
  {
   for(int i = 0; i < m_void_count; i++)
     {
      if(price >= m_void_low[i] && price <= m_void_high[i])
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Score des vides de liquidité pour une direction                   |
//| Les vides attirent le prix - bonus s'il y a un void dans le TP    |
//| Pénalité si le SL est dans un void (le prix peut y retourner)     |
//+------------------------------------------------------------------+
double CLiquidityEngine::GetVoidScore(const ENUM_SIGNAL_TYPE direction) const
  {
   if(m_void_count == 0) return 0;

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
   double score = 0;

   for(int i = 0; i < m_void_count; i++)
     {
      double void_mid = (m_void_high[i] + m_void_low[i]) / 2.0;
      double distance = MathAbs(current_price - void_mid) / _Point;

      //--- Void à portée (dans les 200 pips)
      if(distance < 200)
        {
         //--- Bonus si le void est dans la direction du signal
         if(direction == SIGNAL_BUY && void_mid > current_price)
            score += 10.0;
         else if(direction == SIGNAL_SELL && void_mid < current_price)
            score += 10.0;
        }
     }

   return MathMin(score, 30.0);  // Max 30 pts de bonus
  }

//+------------------------------------------------------------------+
//| Mise à jour principale v4                                       |
//+------------------------------------------------------------------+
bool CLiquidityEngine::Update()
  {
   if(!m_initialized)
      return false;

   //--- v4: Mettre à jour l'ATR pour tolérance dynamique
   double atr_buffer[];
   ArraySetAsSeries(atr_buffer, true);
   if(CopyBuffer(m_atr_handle, 0, 0, 1, atr_buffer) > 0)
      m_current_atr = atr_buffer[0];

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- Détecter les sweeps en premier (priorité)
   DetectLiquiditySweep(current_price);

   //--- Détecter les zones de liquidité
   DetectEqualHighs();
   DetectEqualLows();
   DetectDoubleTop();
   DetectDoubleBottom();

   //--- v4: Détecter les vides de liquidité
   DetectLiquidityVoids();

   //--- Nettoyer
   CleanupOldZones();

   return true;
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
SLiquidityZone CLiquidityEngine::GetZone(const int index) const
  {
   if(index >= 0 && index < m_zone_count)
      return m_zones[index];
   SLiquidityZone empty;
   ZeroMemory(empty);
   return empty;
  }

//+------------------------------------------------------------------+
//| Le prix est-il près d'une zone de liquidité ?                    |
//+------------------------------------------------------------------+
bool CLiquidityEngine::IsPriceNearLiquidity(const double price, const double tolerance_pips) const
  {
   double tolerance = tolerance_pips * _Point;
   for(int i = 0; i < m_zone_count; i++)
     {
      if(m_zones[i].is_valid && MathAbs(price - m_zones[i].price) <= tolerance)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Zone de liquidité la plus proche                                 |
//+------------------------------------------------------------------+
SLiquidityZone CLiquidityEngine::GetNearestLiquidityZone(const double price) const
  {
   SLiquidityZone nearest;
   ZeroMemory(nearest);
   double min_dist = DBL_MAX;

   for(int i = 0; i < m_zone_count; i++)
     {
      if(!m_zones[i].is_valid) continue;
      double dist = MathAbs(price - m_zones[i].price);
      if(dist < min_dist)
        { min_dist = dist; nearest = m_zones[i]; }
     }

   return nearest;
  }

//+------------------------------------------------------------------+
//| Score de liquidité pour une direction donnée                     |
//+------------------------------------------------------------------+
double CLiquidityEngine::GetLiquidityScore(const ENUM_SIGNAL_TYPE direction) const
  {
   double score = 0.0;

   for(int i = 0; i < m_zone_count; i++)
     {
      if(!m_zones[i].is_valid) continue;

      if(direction == SIGNAL_BUY)
        {
         //--- Pour un achat, on cherche SSL sweep (liquidité vendeuse captée)
         if(m_zones[i].type == LIQUIDITY_EQUAL_LOW || m_zones[i].type == LIQUIDITY_DOUBLE_BOTTOM)
           {
            if(m_zones[i].is_swept)
               score += m_zones[i].strength;
            else
               score += m_zones[i].strength * 0.3;
           }
        }
      else if(direction == SIGNAL_SELL)
        {
         if(m_zones[i].type == LIQUIDITY_EQUAL_HIGH || m_zones[i].type == LIQUIDITY_DOUBLE_TOP)
           {
            if(m_zones[i].is_swept)
               score += m_zones[i].strength;
            else
               score += m_zones[i].strength * 0.3;
           }
        }
     }

   //--- Normaliser entre 0 et 100
   return MathMin(score, 100.0);
  }

//+------------------------------------------------------------------+
//| Y a-t-il un sweep de liquidité pour la direction ?               |
//+------------------------------------------------------------------+
bool CLiquidityEngine::HasLiquiditySweepForDirection(const ENUM_SIGNAL_TYPE direction) const
  {
   if(direction == SIGNAL_BUY && m_last_ssl_sweep)
      return true;
   if(direction == SIGNAL_SELL && m_last_bsl_sweep)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Info zone                                                        |
//+------------------------------------------------------------------+
string CLiquidityEngine::GetZoneInfo(const SLiquidityZone &zone) const
  {
   string type_str = "";
   switch(zone.type)
     {
      case LIQUIDITY_BSL:            type_str = "BSL"; break;
      case LIQUIDITY_SSL:            type_str = "SSL"; break;
      case LIQUIDITY_EQUAL_HIGH:     type_str = "EQ_HIGH"; break;
      case LIQUIDITY_EQUAL_LOW:      type_str = "EQ_LOW"; break;
      case LIQUIDITY_DOUBLE_TOP:     type_str = "DBL_TOP"; break;
      case LIQUIDITY_DOUBLE_BOTTOM:  type_str = "DBL_BOT"; break;
      default:                       type_str = "NONE"; break;
     }
   return StringFormat("Liq[%s]: %.5f | Str=%.0f | Swept=%s",
                       type_str, zone.price, zone.strength, zone.is_swept ? "Y" : "N");
  }

#endif // A2SNIPER_LIQUIDITY_MQH
//+------------------------------------------------------------------+
