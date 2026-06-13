//+------------------------------------------------------------------+
//| OrderBlockEngine.mqh - Détection et Scoring des Order Blocks v4  |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| v4: Multi-timeframe OB scoring (H4>H1>M15), HTF priority,       |
//|     confluence detection, improved impulse validation             |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_ORDER_BLOCK_MQH
#define A2SNIPER_ORDER_BLOCK_MQH

#include <A2Sniper\CommonTypes.mqh>

//+------------------------------------------------------------------+
//| Classe COrderBlockEngine v4                                       |
//+------------------------------------------------------------------+
class COrderBlockEngine
  {
private:
   bool              m_initialized;
   int               m_lookback;             // Nombre de barres à analyser
   double            m_impulse_min_ratio;    // Ratio minimum pour impulsion (corps/ATR)
   int               m_max_ob_count;         // Max OB à stocker
   int               m_atr_handle;           // Handle ATR pour filtrage impulsion

   //--- Handles ATR multi-timeframe
   int               m_atr_h4;               // ATR H4
   int               m_atr_h1;               // ATR H1

   //--- Stockage des Order Blocks par timeframe
   SOrderBlock       m_bullish_obs[];        // OB haussiers M15
   SOrderBlock       m_bearish_obs[];        // OB baissiers M15
   int               m_bullish_count;
   int               m_bearish_count;

   //--- OB H1 (timeframe superieur)
   SOrderBlock       m_bullish_obs_h1[];     // OB haussiers H1
   SOrderBlock       m_bearish_obs_h1[];     // OB baissiers H1
   int               m_bullish_count_h1;
   int               m_bearish_count_h1;

   //--- OB H4 (timeframe superieur)
   SOrderBlock       m_bullish_obs_h4[];     // OB haussiers H4
   SOrderBlock       m_bearish_obs_h4[];     // OB baissiers H4
   int               m_bullish_count_h4;
   int               m_bearish_count_h4;

   //--- Méthodes privées
   bool              DetectBullishOB(const int bar_index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   bool              DetectBearishOB(const int bar_index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   bool              IsImpulsiveMove(const int bar_index, const ENUM_OB_TYPE direction, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   double            GetATRValue(const int shift, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   void              UpdateOBState(SOrderBlock &ob, const double current_price);
   bool              IsPriceInOB(const double price, const SOrderBlock &ob) const;
   double            CalculateOBScore(const SOrderBlock &ob) const;
   void              CleanupOldOBs();
   bool              HasBOSNearby(const int bar_index, const ENUM_OB_TYPE direction, ENUM_TIMEFRAMES tf = PERIOD_CURRENT);
   int               CountHTFConfluence(const double price, const ENUM_OB_TYPE type) const;

public:
   //--- Constructeur / Destructeur
                     COrderBlockEngine();
                    ~COrderBlockEngine();

   //--- Initialisation
   bool              Initialize(int lookback = OB_LOOKBACK, double impulse_ratio = 1.5, int max_count = 20);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   int               GetBullishCount() const { return m_bullish_count; }
   int               GetBearishCount() const { return m_bearish_count; }
   SOrderBlock       GetBullishOB(const int index) const;
   SOrderBlock       GetBearishOB(const int index) const;
   int               GetBullishCountH1() const { return m_bullish_count_h1; }
   int               GetBearishCountH1() const { return m_bearish_count_h1; }
   int               GetBullishCountH4() const { return m_bullish_count_h4; }
   int               GetBearishCountH4() const { return m_bearish_count_h4; }

   //--- Vérifications
   bool              IsPriceAtOB(const double price, const ENUM_OB_TYPE type) const;
   SOrderBlock       GetNearestOB(const double price, const ENUM_OB_TYPE type) const;
   double            GetOBScoreAtPrice(const double price, const ENUM_OB_TYPE type) const;
   bool              HasFreshOB(const ENUM_OB_TYPE type) const;

   //--- v4: Multi-timeframe scoring
   double            GetMTFOBScore(const double price, const ENUM_OB_TYPE type) const;
   bool              IsPriceAtHTFOB(const double price, const ENUM_OB_TYPE type) const;
   int               GetHTFConfluenceCount(const double price, const ENUM_OB_TYPE type) const;

   //--- Information
   string            GetOBInfo(const SOrderBlock &ob) const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
COrderBlockEngine::COrderBlockEngine() :
   m_initialized(false),
   m_lookback(OB_LOOKBACK),
   m_impulse_min_ratio(1.5),
   m_max_ob_count(20),
   m_atr_handle(INVALID_HANDLE),
   m_atr_h4(INVALID_HANDLE),
   m_atr_h1(INVALID_HANDLE),
   m_bullish_count(0),
   m_bearish_count(0),
   m_bullish_count_h1(0),
   m_bearish_count_h1(0),
   m_bullish_count_h4(0),
   m_bearish_count_h4(0)
  {
   ArrayResize(m_bullish_obs, 0);
   ArrayResize(m_bearish_obs, 0);
   ArrayResize(m_bullish_obs_h1, 0);
   ArrayResize(m_bearish_obs_h1, 0);
   ArrayResize(m_bullish_obs_h4, 0);
   ArrayResize(m_bearish_obs_h4, 0);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
COrderBlockEngine::~COrderBlockEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool COrderBlockEngine::Initialize(int lookback, double impulse_ratio, int max_count)
  {
   m_lookback = (lookback > 10) ? lookback : OB_LOOKBACK;
   m_impulse_min_ratio = (impulse_ratio > 0.5) ? impulse_ratio : 1.5;
   m_max_ob_count = (max_count > 5) ? max_count : 20;

   m_atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(m_atr_handle == INVALID_HANDLE)
     {
      Print("A2Sniper OBE: Erreur creation ATR handle - ", GetLastError());
      return false;
     }

   //--- ATR multi-timeframe
   m_atr_h1 = iATR(_Symbol, PERIOD_H1, 14);
   m_atr_h4 = iATR(_Symbol, PERIOD_H4, 14);

   if(m_atr_h1 == INVALID_HANDLE)
      Print("A2Sniper OBE: ATR H1 non disponible");
   if(m_atr_h4 == INVALID_HANDLE)
      Print("A2Sniper OBE: ATR H4 non disponible");

   m_initialized = true;
   Print("A2Sniper OBE: Order Block Engine v4 initialise (Multi-TF: M15+H1+H4)");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void COrderBlockEngine::Deinitialize()
  {
   if(m_atr_handle != INVALID_HANDLE)
     { IndicatorRelease(m_atr_handle); m_atr_handle = INVALID_HANDLE; }
   if(m_atr_h1 != INVALID_HANDLE)
     { IndicatorRelease(m_atr_h1); m_atr_h1 = INVALID_HANDLE; }
   if(m_atr_h4 != INVALID_HANDLE)
     { IndicatorRelease(m_atr_h4); m_atr_h4 = INVALID_HANDLE; }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Détection Order Block Haussier (multi-timeframe)                 |
//+------------------------------------------------------------------+
bool COrderBlockEngine::DetectBullishOB(const int bar_index, ENUM_TIMEFRAMES tf)
  {
   if(bar_index < 2)
      return false;

   double open_price = iOpen(_Symbol, tf, bar_index);
   double close_price = iClose(_Symbol, tf, bar_index);

   if(close_price >= open_price)
      return false;

   double impulse_open = iOpen(_Symbol, tf, bar_index - 1);
   double impulse_close = iClose(_Symbol, tf, bar_index - 1);

   if(impulse_close <= impulse_open)
      return false;

   if(!IsImpulsiveMove(bar_index - 1, OB_BULLISH, tf))
      return false;

   if(!HasBOSNearby(bar_index, OB_BULLISH, tf))
      return false;

   SOrderBlock ob;
   ob.high = MathMax(open_price, close_price);
   ob.low = MathMin(open_price, close_price);
   ob.time = iTime(_Symbol, tf, bar_index);
   ob.bar_index = bar_index;
   ob.type = OB_BULLISH;
   ob.state = OB_STATE_FRESH;
   ob.score = 100.0;
   ob.is_valid = true;

   //--- Stocker dans le bon tableau selon le timeframe
   if(tf == PERIOD_H4)
     {
      m_bullish_count_h4++;
      ArrayResize(m_bullish_obs_h4, m_bullish_count_h4);
      m_bullish_obs_h4[m_bullish_count_h4 - 1] = ob;
     }
   else if(tf == PERIOD_H1)
     {
      m_bullish_count_h1++;
      ArrayResize(m_bullish_obs_h1, m_bullish_count_h1);
      m_bullish_obs_h1[m_bullish_count_h1 - 1] = ob;
     }
   else
     {
      m_bullish_count++;
      ArrayResize(m_bullish_obs, m_bullish_count);
      m_bullish_obs[m_bullish_count - 1] = ob;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Détection Order Block Baissier (multi-timeframe)                 |
//+------------------------------------------------------------------+
bool COrderBlockEngine::DetectBearishOB(const int bar_index, ENUM_TIMEFRAMES tf)
  {
   if(bar_index < 2)
      return false;

   double open_price = iOpen(_Symbol, tf, bar_index);
   double close_price = iClose(_Symbol, tf, bar_index);

   if(close_price <= open_price)
      return false;

   double impulse_open = iOpen(_Symbol, tf, bar_index - 1);
   double impulse_close = iClose(_Symbol, tf, bar_index - 1);

   if(impulse_close >= impulse_open)
      return false;

   if(!IsImpulsiveMove(bar_index - 1, OB_BEARISH, tf))
      return false;

   if(!HasBOSNearby(bar_index, OB_BEARISH, tf))
      return false;

   SOrderBlock ob;
   ob.high = MathMax(open_price, close_price);
   ob.low = MathMin(open_price, close_price);
   ob.time = iTime(_Symbol, tf, bar_index);
   ob.bar_index = bar_index;
   ob.type = OB_BEARISH;
   ob.state = OB_STATE_FRESH;
   ob.score = 100.0;
   ob.is_valid = true;

   if(tf == PERIOD_H4)
     {
      m_bearish_count_h4++;
      ArrayResize(m_bearish_obs_h4, m_bearish_count_h4);
      m_bearish_obs_h4[m_bearish_count_h4 - 1] = ob;
     }
   else if(tf == PERIOD_H1)
     {
      m_bearish_count_h1++;
      ArrayResize(m_bearish_obs_h1, m_bearish_count_h1);
      m_bearish_obs_h1[m_bearish_count_h1 - 1] = ob;
     }
   else
     {
      m_bearish_count++;
      ArrayResize(m_bearish_obs, m_bearish_count);
      m_bearish_obs[m_bearish_count - 1] = ob;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Vérifier si le mouvement est impulsif (multi-timeframe)          |
//+------------------------------------------------------------------+
bool COrderBlockEngine::IsImpulsiveMove(const int bar_index, const ENUM_OB_TYPE direction, ENUM_TIMEFRAMES tf)
  {
   double atr = GetATRValue(1, tf);
   if(atr <= 0)
      return false;

   double body = MathAbs(iClose(_Symbol, tf, bar_index) -
                         iOpen(_Symbol, tf, bar_index));

   return (body >= m_impulse_min_ratio * atr);
  }

//+------------------------------------------------------------------+
//| Obtenir la valeur ATR (multi-timeframe)                          |
//+------------------------------------------------------------------+
double COrderBlockEngine::GetATRValue(const int shift, ENUM_TIMEFRAMES tf)
  {
   int handle = m_atr_handle;

   if(tf == PERIOD_H4 && m_atr_h4 != INVALID_HANDLE)
      handle = m_atr_h4;
   else if(tf == PERIOD_H1 && m_atr_h1 != INVALID_HANDLE)
      handle = m_atr_h1;

   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(handle, 0, shift, 1, buffer) > 0)
      return buffer[0];
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Vérifier BOS à proximité de l'OB (multi-timeframe)               |
//+------------------------------------------------------------------+
bool COrderBlockEngine::HasBOSNearby(const int bar_index, const ENUM_OB_TYPE direction, ENUM_TIMEFRAMES tf)
  {
   int bars_available = iBars(_Symbol, tf);
   int look_ahead = MathMin(5, bars_available - bar_index - 1);

   for(int i = 1; i <= look_ahead; i++)
     {
      double close = iClose(_Symbol, tf, bar_index - i);

      if(direction == OB_BULLISH)
        {
         double ob_high = MathMax(iOpen(_Symbol, tf, bar_index),
                                  iClose(_Symbol, tf, bar_index));
         if(close > ob_high)
            return true;
        }
      else
        {
         double ob_low = MathMin(iOpen(_Symbol, tf, bar_index),
                                 iClose(_Symbol, tf, bar_index));
         if(close < ob_low)
            return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Mettre à jour l'état d'un OB                                     |
//+------------------------------------------------------------------+
void COrderBlockEngine::UpdateOBState(SOrderBlock &ob, const double current_price)
  {
   if(!ob.is_valid)
      return;

   if(ob.type == OB_BULLISH)
     {
      if(current_price >= ob.low && current_price <= ob.high)
        {
         double penetration = (ob.high - current_price) / (ob.high - ob.low);
         if(penetration < OB_MITIGATION_THRESHOLD)
           { ob.state = OB_STATE_MITIGATED; ob.score = 50.0; }
         else
           { ob.state = OB_STATE_CONSUMED; ob.score = 0.0; ob.is_valid = false; }
        }
      else if(current_price < ob.low)
        { ob.state = OB_STATE_CONSUMED; ob.score = 0.0; ob.is_valid = false; }
     }
   else
     {
      if(current_price <= ob.high && current_price >= ob.low)
        {
         double penetration = (current_price - ob.low) / (ob.high - ob.low);
         if(penetration < OB_MITIGATION_THRESHOLD)
           { ob.state = OB_STATE_MITIGATED; ob.score = 50.0; }
         else
           { ob.state = OB_STATE_CONSUMED; ob.score = 0.0; ob.is_valid = false; }
        }
      else if(current_price > ob.high)
        { ob.state = OB_STATE_CONSUMED; ob.score = 0.0; ob.is_valid = false; }
     }
  }

//+------------------------------------------------------------------+
//| Nettoyer les anciens OB                                          |
//+------------------------------------------------------------------+
void COrderBlockEngine::CleanupOldOBs()
  {
   //--- M15
   SOrderBlock temp_bull[];
   int new_bull_count = 0;
   for(int i = m_bullish_count - 1; i >= 0 && new_bull_count < m_max_ob_count; i--)
     {
      if(m_bullish_obs[i].is_valid)
        { new_bull_count++; ArrayResize(temp_bull, new_bull_count); temp_bull[new_bull_count - 1] = m_bullish_obs[i]; }
     }
   m_bullish_count = new_bull_count;
   ArrayResize(m_bullish_obs, m_bullish_count);
   for(int i = 0; i < m_bullish_count; i++)
      m_bullish_obs[i] = temp_bull[m_bullish_count - 1 - i];

   SOrderBlock temp_bear[];
   int new_bear_count = 0;
   for(int i = m_bearish_count - 1; i >= 0 && new_bear_count < m_max_ob_count; i--)
     {
      if(m_bearish_obs[i].is_valid)
        { new_bear_count++; ArrayResize(temp_bear, new_bear_count); temp_bear[new_bear_count - 1] = m_bearish_obs[i]; }
     }
   m_bearish_count = new_bear_count;
   ArrayResize(m_bearish_obs, m_bearish_count);
   for(int i = 0; i < m_bearish_count; i++)
      m_bearish_obs[i] = temp_bear[m_bearish_count - 1 - i];

   //--- H1 (max 15)
   SOrderBlock temp_bull_h1[];
   int new_bull_h1 = 0;
   for(int i = m_bullish_count_h1 - 1; i >= 0 && new_bull_h1 < 15; i--)
     {
      if(m_bullish_obs_h1[i].is_valid)
        { new_bull_h1++; ArrayResize(temp_bull_h1, new_bull_h1); temp_bull_h1[new_bull_h1 - 1] = m_bullish_obs_h1[i]; }
     }
   m_bullish_count_h1 = new_bull_h1;
   ArrayResize(m_bullish_obs_h1, m_bullish_count_h1);
   for(int i = 0; i < m_bullish_count_h1; i++)
      m_bullish_obs_h1[i] = temp_bull_h1[m_bullish_count_h1 - 1 - i];

   SOrderBlock temp_bear_h1[];
   int new_bear_h1 = 0;
   for(int i = m_bearish_count_h1 - 1; i >= 0 && new_bear_h1 < 15; i--)
     {
      if(m_bearish_obs_h1[i].is_valid)
        { new_bear_h1++; ArrayResize(temp_bear_h1, new_bear_h1); temp_bear_h1[new_bear_h1 - 1] = m_bearish_obs_h1[i]; }
     }
   m_bearish_count_h1 = new_bear_h1;
   ArrayResize(m_bearish_obs_h1, m_bearish_count_h1);
   for(int i = 0; i < m_bearish_count_h1; i++)
      m_bearish_obs_h1[i] = temp_bear_h1[m_bearish_count_h1 - 1 - i];

   //--- H4 (max 10)
   SOrderBlock temp_bull_h4[];
   int new_bull_h4 = 0;
   for(int i = m_bullish_count_h4 - 1; i >= 0 && new_bull_h4 < 10; i--)
     {
      if(m_bullish_obs_h4[i].is_valid)
        { new_bull_h4++; ArrayResize(temp_bull_h4, new_bull_h4); temp_bull_h4[new_bull_h4 - 1] = m_bullish_obs_h4[i]; }
     }
   m_bullish_count_h4 = new_bull_h4;
   ArrayResize(m_bullish_obs_h4, m_bullish_count_h4);
   for(int i = 0; i < m_bullish_count_h4; i++)
      m_bullish_obs_h4[i] = temp_bull_h4[m_bullish_count_h4 - 1 - i];

   SOrderBlock temp_bear_h4[];
   int new_bear_h4 = 0;
   for(int i = m_bearish_count_h4 - 1; i >= 0 && new_bear_h4 < 10; i--)
     {
      if(m_bearish_obs_h4[i].is_valid)
        { new_bear_h4++; ArrayResize(temp_bear_h4, new_bear_h4); temp_bear_h4[new_bear_h4 - 1] = m_bearish_obs_h4[i]; }
     }
   m_bearish_count_h4 = new_bear_h4;
   ArrayResize(m_bearish_obs_h4, m_bearish_count_h4);
   for(int i = 0; i < m_bearish_count_h4; i++)
      m_bearish_obs_h4[i] = temp_bear_h4[m_bearish_count_h4 - 1 - i];
  }

//+------------------------------------------------------------------+
//| Compter les confluences HTF (H1+H4 OB au meme prix)             |
//+------------------------------------------------------------------+
int COrderBlockEngine::CountHTFConfluence(const double price, const ENUM_OB_TYPE type) const
  {
   int count = 0;
   double tolerance = 10 * _Point; // 10 pips de tolerance pour confluence

   //--- Verifier H1
   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count_h1; i++)
        {
         if(m_bullish_obs_h1[i].is_valid &&
            price >= m_bullish_obs_h1[i].low - tolerance &&
            price <= m_bullish_obs_h1[i].high + tolerance)
            count++;
        }
     }
   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count_h1; i++)
        {
         if(m_bearish_obs_h1[i].is_valid &&
            price >= m_bearish_obs_h1[i].low - tolerance &&
            price <= m_bearish_obs_h1[i].high + tolerance)
            count++;
        }
     }

   //--- Verifier H4
   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count_h4; i++)
        {
         if(m_bullish_obs_h4[i].is_valid &&
            price >= m_bullish_obs_h4[i].low - tolerance &&
            price <= m_bullish_obs_h4[i].high + tolerance)
            count++;
        }
     }
   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count_h4; i++)
        {
         if(m_bearish_obs_h4[i].is_valid &&
            price >= m_bearish_obs_h4[i].low - tolerance &&
            price <= m_bearish_obs_h4[i].high + tolerance)
            count++;
        }
     }

   return count;
  }

//+------------------------------------------------------------------+
//| Mise à jour principale (multi-timeframe)                         |
//+------------------------------------------------------------------+
bool COrderBlockEngine::Update()
  {
   if(!m_initialized)
      return false;

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- Mettre a jour l'etat des OB existants (M15)
   for(int i = 0; i < m_bullish_count; i++)
      UpdateOBState(m_bullish_obs[i], current_price);
   for(int i = 0; i < m_bearish_count; i++)
      UpdateOBState(m_bearish_obs[i], current_price);

   //--- Mettre a jour l'etat des OB H1
   for(int i = 0; i < m_bullish_count_h1; i++)
      UpdateOBState(m_bullish_obs_h1[i], current_price);
   for(int i = 0; i < m_bearish_count_h1; i++)
      UpdateOBState(m_bearish_obs_h1[i], current_price);

   //--- Mettre a jour l'etat des OB H4
   for(int i = 0; i < m_bullish_count_h4; i++)
      UpdateOBState(m_bullish_obs_h4[i], current_price);
   for(int i = 0; i < m_bearish_count_h4; i++)
      UpdateOBState(m_bearish_obs_h4[i], current_price);

   //--- Detecter nouveaux OB M15
   int start_bar = 3;
   int end_bar = MathMin(m_lookback, iBars(_Symbol, PERIOD_CURRENT) - 1);
   for(int i = start_bar; i < end_bar; i++)
     {
      bool already_detected = false;
      for(int j = 0; j < m_bullish_count && !already_detected; j++)
         if(m_bullish_obs[j].bar_index == i) already_detected = true;
      for(int j = 0; j < m_bearish_count && !already_detected; j++)
         if(m_bearish_obs[j].bar_index == i) already_detected = true;

      if(!already_detected)
        {
         DetectBullishOB(i, PERIOD_CURRENT);
         DetectBearishOB(i, PERIOD_CURRENT);
        }
     }

   //--- Detecter nouveaux OB H1 (seulement toutes les 4 bougies H1)
   static int last_h1_bar = -1;
   int current_h1_bar = iBars(_Symbol, PERIOD_H1);
   if(current_h1_bar != last_h1_bar)
     {
      last_h1_bar = current_h1_bar;
      int end_h1 = MathMin(50, iBars(_Symbol, PERIOD_H1) - 1);
      for(int i = 3; i < end_h1; i++)
        {
         DetectBullishOB(i, PERIOD_H1);
         DetectBearishOB(i, PERIOD_H1);
        }
     }

   //--- Detecter nouveaux OB H4 (seulement toutes les 4 bougies H4)
   static int last_h4_bar = -1;
   int current_h4_bar = iBars(_Symbol, PERIOD_H4);
   if(current_h4_bar != last_h4_bar)
     {
      last_h4_bar = current_h4_bar;
      int end_h4 = MathMin(30, iBars(_Symbol, PERIOD_H4) - 1);
      for(int i = 3; i < end_h4; i++)
        {
         DetectBullishOB(i, PERIOD_H4);
         DetectBearishOB(i, PERIOD_H4);
        }
     }

   CleanupOldOBs();
   return true;
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
SOrderBlock COrderBlockEngine::GetBullishOB(const int index) const
  {
   if(index >= 0 && index < m_bullish_count)
      return m_bullish_obs[index];
   SOrderBlock empty; ZeroMemory(empty); return empty;
  }

SOrderBlock COrderBlockEngine::GetBearishOB(const int index) const
  {
   if(index >= 0 && index < m_bearish_count)
      return m_bearish_obs[index];
   SOrderBlock empty; ZeroMemory(empty); return empty;
  }

//+------------------------------------------------------------------+
//| Le prix est-il dans un OB ?                                       |
//+------------------------------------------------------------------+
bool COrderBlockEngine::IsPriceAtOB(const double price, const ENUM_OB_TYPE type) const
  {
   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
         if(m_bullish_obs[i].is_valid && price >= m_bullish_obs[i].low && price <= m_bullish_obs[i].high)
            return true;
     }
   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
         if(m_bearish_obs[i].is_valid && price >= m_bearish_obs[i].low && price <= m_bearish_obs[i].high)
            return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Le prix est-il dans un OB HTF ? (H1 ou H4)                       |
//+------------------------------------------------------------------+
bool COrderBlockEngine::IsPriceAtHTFOB(const double price, const ENUM_OB_TYPE type) const
  {
   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count_h1; i++)
         if(m_bullish_obs_h1[i].is_valid && price >= m_bullish_obs_h1[i].low && price <= m_bullish_obs_h1[i].high)
            return true;
      for(int i = 0; i < m_bullish_count_h4; i++)
         if(m_bullish_obs_h4[i].is_valid && price >= m_bullish_obs_h4[i].low && price <= m_bullish_obs_h4[i].high)
            return true;
     }
   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count_h1; i++)
         if(m_bearish_obs_h1[i].is_valid && price >= m_bearish_obs_h1[i].low && price <= m_bearish_obs_h1[i].high)
            return true;
      for(int i = 0; i < m_bearish_count_h4; i++)
         if(m_bearish_obs_h4[i].is_valid && price >= m_bearish_obs_h4[i].low && price <= m_bearish_obs_h4[i].high)
            return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Nombre de confluences HTF                                         |
//+------------------------------------------------------------------+
int COrderBlockEngine::GetHTFConfluenceCount(const double price, const ENUM_OB_TYPE type) const
  {
   return CountHTFConfluence(price, type);
  }

//+------------------------------------------------------------------+
//| Obtenir l'OB le plus proche                                      |
//+------------------------------------------------------------------+
SOrderBlock COrderBlockEngine::GetNearestOB(const double price, const ENUM_OB_TYPE type) const
  {
   SOrderBlock nearest; ZeroMemory(nearest);
   double min_distance = DBL_MAX;

   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(!m_bullish_obs[i].is_valid) continue;
         double distance = MathMin(MathAbs(price - m_bullish_obs[i].high), MathAbs(price - m_bullish_obs[i].low));
         if(distance < min_distance) { min_distance = distance; nearest = m_bullish_obs[i]; }
        }
      //--- H1
      for(int i = 0; i < m_bullish_count_h1; i++)
        {
         if(!m_bullish_obs_h1[i].is_valid) continue;
         double distance = MathMin(MathAbs(price - m_bullish_obs_h1[i].high), MathAbs(price - m_bullish_obs_h1[i].low));
         if(distance < min_distance) { min_distance = distance; nearest = m_bullish_obs_h1[i]; }
        }
      //--- H4
      for(int i = 0; i < m_bullish_count_h4; i++)
        {
         if(!m_bullish_obs_h4[i].is_valid) continue;
         double distance = MathMin(MathAbs(price - m_bullish_obs_h4[i].high), MathAbs(price - m_bullish_obs_h4[i].low));
         if(distance < min_distance) { min_distance = distance; nearest = m_bullish_obs_h4[i]; }
        }
     }

   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(!m_bearish_obs[i].is_valid) continue;
         double distance = MathMin(MathAbs(price - m_bearish_obs[i].high), MathAbs(price - m_bearish_obs[i].low));
         if(distance < min_distance) { min_distance = distance; nearest = m_bearish_obs[i]; }
        }
      for(int i = 0; i < m_bearish_count_h1; i++)
        {
         if(!m_bearish_obs_h1[i].is_valid) continue;
         double distance = MathMin(MathAbs(price - m_bearish_obs_h1[i].high), MathAbs(price - m_bearish_obs_h1[i].low));
         if(distance < min_distance) { min_distance = distance; nearest = m_bearish_obs_h1[i]; }
        }
      for(int i = 0; i < m_bearish_count_h4; i++)
        {
         if(!m_bearish_obs_h4[i].is_valid) continue;
         double distance = MathMin(MathAbs(price - m_bearish_obs_h4[i].high), MathAbs(price - m_bearish_obs_h4[i].low));
         if(distance < min_distance) { min_distance = distance; nearest = m_bearish_obs_h4[i]; }
        }
     }

   return nearest;
  }

//+------------------------------------------------------------------+
//| Score OB au prix donné (M15 seulement - compatibilité)            |
//+------------------------------------------------------------------+
double COrderBlockEngine::GetOBScoreAtPrice(const double price, const ENUM_OB_TYPE type) const
  {
   double best_score = 0.0;

   if(type == OB_BULLISH)
     {
      for(int i = 0; i < m_bullish_count; i++)
         if(m_bullish_obs[i].is_valid && price >= m_bullish_obs[i].low && price <= m_bullish_obs[i].high)
            if(m_bullish_obs[i].score > best_score) best_score = m_bullish_obs[i].score;
     }
   else
     {
      for(int i = 0; i < m_bearish_count; i++)
         if(m_bearish_obs[i].is_valid && price >= m_bearish_obs[i].low && price <= m_bearish_obs[i].high)
            if(m_bearish_obs[i].score > best_score) best_score = m_bearish_obs[i].score;
     }

   return best_score;
  }

//+------------------------------------------------------------------+
//| Score OB multi-timeframe v4                                       |
//| H4 OB = x2.5 poids, H1 OB = x1.5, M15 = x1.0                    |
//| Confluence HTF = bonus supplementaire                             |
//+------------------------------------------------------------------+
double COrderBlockEngine::GetMTFOBScore(const double price, const ENUM_OB_TYPE type) const
  {
   double weighted_score = 0.0;
   double tolerance = 5 * _Point; // 5 pips de tolerance

   //--- M15 OB (poids 1.0)
   if(type == OB_BULLISH)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(!m_bullish_obs[i].is_valid) continue;
         if(price >= m_bullish_obs[i].low - tolerance && price <= m_bullish_obs[i].high + tolerance)
            weighted_score = MathMax(weighted_score, m_bullish_obs[i].score * 1.0);
        }
     }
   else
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(!m_bearish_obs[i].is_valid) continue;
         if(price >= m_bearish_obs[i].low - tolerance && price <= m_bearish_obs[i].high + tolerance)
            weighted_score = MathMax(weighted_score, m_bearish_obs[i].score * 1.0);
        }
     }

   //--- H1 OB (poids 1.5)
   if(type == OB_BULLISH)
     {
      for(int i = 0; i < m_bullish_count_h1; i++)
        {
         if(!m_bullish_obs_h1[i].is_valid) continue;
         if(price >= m_bullish_obs_h1[i].low - tolerance && price <= m_bullish_obs_h1[i].high + tolerance)
            weighted_score = MathMax(weighted_score, m_bullish_obs_h1[i].score * 1.5);
        }
     }
   else
     {
      for(int i = 0; i < m_bearish_count_h1; i++)
        {
         if(!m_bearish_obs_h1[i].is_valid) continue;
         if(price >= m_bearish_obs_h1[i].low - tolerance && price <= m_bearish_obs_h1[i].high + tolerance)
            weighted_score = MathMax(weighted_score, m_bearish_obs_h1[i].score * 1.5);
        }
     }

   //--- H4 OB (poids 2.5) - institutionnel
   if(type == OB_BULLISH)
     {
      for(int i = 0; i < m_bullish_count_h4; i++)
        {
         if(!m_bullish_obs_h4[i].is_valid) continue;
         if(price >= m_bullish_obs_h4[i].low - tolerance && price <= m_bullish_obs_h4[i].high + tolerance)
            weighted_score = MathMax(weighted_score, m_bullish_obs_h4[i].score * 2.5);
        }
     }
   else
     {
      for(int i = 0; i < m_bearish_count_h4; i++)
        {
         if(!m_bearish_obs_h4[i].is_valid) continue;
         if(price >= m_bearish_obs_h4[i].low - tolerance && price <= m_bearish_obs_h4[i].high + tolerance)
            weighted_score = MathMax(weighted_score, m_bearish_obs_h4[i].score * 2.5);
        }
     }

   //--- Confluence bonus (M15 + H1 + H4 au meme prix)
   int htf_confluence = CountHTFConfluence(price, type);
   if(htf_confluence >= 2)
      weighted_score = MathMin(weighted_score * 1.3, 100.0); // +30% bonus confluence

   return MathMin(weighted_score, 100.0);
  }

//+------------------------------------------------------------------+
//| Y a-t-il un OB frais ?                                           |
//+------------------------------------------------------------------+
bool COrderBlockEngine::HasFreshOB(const ENUM_OB_TYPE type) const
  {
   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
         if(m_bullish_obs[i].is_valid && m_bullish_obs[i].state == OB_STATE_FRESH) return true;
      for(int i = 0; i < m_bullish_count_h1; i++)
         if(m_bullish_obs_h1[i].is_valid && m_bullish_obs_h1[i].state == OB_STATE_FRESH) return true;
      for(int i = 0; i < m_bullish_count_h4; i++)
         if(m_bullish_obs_h4[i].is_valid && m_bullish_obs_h4[i].state == OB_STATE_FRESH) return true;
     }
   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
         if(m_bearish_obs[i].is_valid && m_bearish_obs[i].state == OB_STATE_FRESH) return true;
      for(int i = 0; i < m_bearish_count_h1; i++)
         if(m_bearish_obs_h1[i].is_valid && m_bearish_obs_h1[i].state == OB_STATE_FRESH) return true;
      for(int i = 0; i < m_bearish_count_h4; i++)
         if(m_bearish_obs_h4[i].is_valid && m_bearish_obs_h4[i].state == OB_STATE_FRESH) return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Info OB                                                          |
//+------------------------------------------------------------------+
string COrderBlockEngine::GetOBInfo(const SOrderBlock &ob) const
  {
   string type_str = (ob.type == OB_BULLISH) ? "BULL" : "BEAR";
   string state_str = "";
   switch(ob.state)
     {
      case OB_STATE_FRESH:    state_str = "FRESH"; break;
      case OB_STATE_MITIGATED: state_str = "MITIG"; break;
      case OB_STATE_CONSUMED: state_str = "CONSUMED"; break;
     }
   return StringFormat("OB[%s %s]: %.5f - %.5f | Score=%.0f | Bar=%d",
                       type_str, state_str, ob.low, ob.high, ob.score, ob.bar_index);
  }

//+------------------------------------------------------------------+
//| Calcul du score d'un Order Block                                 |
//+------------------------------------------------------------------+
double COrderBlockEngine::CalculateOBScore(const SOrderBlock &ob) const
  {
   if(!ob.is_valid) return 0;
   return (double)ob.state;
  }

#endif // A2SNIPER_ORDER_BLOCK_MQH
//+------------------------------------------------------------------+
