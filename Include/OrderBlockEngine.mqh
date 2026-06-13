//+------------------------------------------------------------------+
//| OrderBlockEngine.mqh - Détection et Scoring des Order Blocks     |
//| A2Sniper Ultimate v3.0                                           |
//| Bullish/Bearish OB, Fresh/Mitigated/Consumed scoring             |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_ORDER_BLOCK_MQH
#define A2SNIPER_ORDER_BLOCK_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Classe COrderBlockEngine                                         |
//+------------------------------------------------------------------+
class COrderBlockEngine
  {
private:
   bool              m_initialized;
   int               m_lookback;             // Nombre de barres à analyser
   double            m_impulse_min_ratio;    // Ratio minimum pour impulsion (corps/ATR)
   int               m_max_ob_count;         // Max OB à stocker
   int               m_atr_handle;           // Handle ATR pour filtrage impulsion

   //--- Stockage des Order Blocks
   SOrderBlock       m_bullish_obs[];        // OB haussiers
   SOrderBlock       m_bearish_obs[];        // OB baissiers
   int               m_bullish_count;
   int               m_bearish_count;

   //--- Méthodes privées
   bool              DetectBullishOB(const int bar_index);
   bool              DetectBearishOB(const int bar_index);
   bool              IsImpulsiveMove(const int bar_index, const ENUM_OB_TYPE direction);
   double            GetATRValue(const int shift);
   void              UpdateOBState(SOrderBlock &ob, const double current_price);
   bool              IsPriceInOB(const double price, const SOrderBlock &ob) const;
   double            CalculateOBScore(const SOrderBlock &ob) const;
   void              CleanupOldOBs();
   bool              HasBOSNearby(const int bar_index, const ENUM_OB_TYPE direction);

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

   //--- Vérifications
   bool              IsPriceAtOB(const double price, const ENUM_OB_TYPE type) const;
   SOrderBlock       GetNearestOB(const double price, const ENUM_OB_TYPE type) const;
   double            GetOBScoreAtPrice(const double price, const ENUM_OB_TYPE type) const;
   bool              HasFreshOB(const ENUM_OB_TYPE type) const;

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
   m_bullish_count(0),
   m_bearish_count(0)
  {
   ArrayResize(m_bullish_obs, 0);
   ArrayResize(m_bearish_obs, 0);
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
      Print("A2Sniper OBE: Erreur création ATR handle - ", GetLastError());
      return false;
     }

   m_initialized = true;
   Print("A2Sniper OBE: Order Block Engine initialisé");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void COrderBlockEngine::Deinitialize()
  {
   if(m_atr_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_atr_handle);
      m_atr_handle = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Détection Order Block Haussier                                   |
//| Dernière bougie baissière avant une impulsion haussière          |
//+------------------------------------------------------------------+
bool COrderBlockEngine::DetectBullishOB(const int bar_index)
  {
   if(bar_index < 2)
      return false;

   //--- La bougie à bar_index doit être baissière
   double open_price = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close_price = iClose(_Symbol, PERIOD_CURRENT, bar_index);

   if(close_price >= open_price) // Pas baissière
      return false;

   //--- Vérifier l'impulsion haussière qui suit (bar_index-1 est la bougie d'impulsion)
   double impulse_open = iOpen(_Symbol, PERIOD_CURRENT, bar_index - 1);
   double impulse_close = iClose(_Symbol, PERIOD_CURRENT, bar_index - 1);

   //--- L'impulsion doit être haussière
   if(impulse_close <= impulse_open)
      return false;

   //--- Vérifier que l'impulsion est suffisamment forte
   if(!IsImpulsiveMove(bar_index - 1, OB_BULLISH))
      return false;

   //--- Vérifier BOS à proximité (la cassure doit être validée)
   if(!HasBOSNearby(bar_index, OB_BULLISH))
      return false;

   //--- Créer l'Order Block
   SOrderBlock ob;
   ob.high = MathMax(open_price, close_price); // Haut de la bougie baissière
   ob.low = MathMin(open_price, close_price);  // Bas de la bougie baissière
   ob.time = iTime(_Symbol, PERIOD_CURRENT, bar_index);
   ob.bar_index = bar_index;
   ob.type = OB_BULLISH;
   ob.state = OB_STATE_FRESH;
   ob.score = 100.0;
   ob.is_valid = true;

   //--- Ajouter à la liste
   m_bullish_count++;
   ArrayResize(m_bullish_obs, m_bullish_count);
   m_bullish_obs[m_bullish_count - 1] = ob;

   return true;
  }

//+------------------------------------------------------------------+
//| Détection Order Block Baissier                                   |
//| Dernière bougie haussière avant une impulsion baissière          |
//+------------------------------------------------------------------+
bool COrderBlockEngine::DetectBearishOB(const int bar_index)
  {
   if(bar_index < 2)
      return false;

   //--- La bougie à bar_index doit être haussière
   double open_price = iOpen(_Symbol, PERIOD_CURRENT, bar_index);
   double close_price = iClose(_Symbol, PERIOD_CURRENT, bar_index);

   if(close_price <= open_price) // Pas haussière
      return false;

   //--- Vérifier l'impulsion baissière qui suit
   double impulse_open = iOpen(_Symbol, PERIOD_CURRENT, bar_index - 1);
   double impulse_close = iClose(_Symbol, PERIOD_CURRENT, bar_index - 1);

   if(impulse_close >= impulse_open)
      return false;

   if(!IsImpulsiveMove(bar_index - 1, OB_BEARISH))
      return false;

   if(!HasBOSNearby(bar_index, OB_BEARISH))
      return false;

   //--- Créer l'Order Block
   SOrderBlock ob;
   ob.high = MathMax(open_price, close_price);
   ob.low = MathMin(open_price, close_price);
   ob.time = iTime(_Symbol, PERIOD_CURRENT, bar_index);
   ob.bar_index = bar_index;
   ob.type = OB_BEARISH;
   ob.state = OB_STATE_FRESH;
   ob.score = 100.0;
   ob.is_valid = true;

   m_bearish_count++;
   ArrayResize(m_bearish_obs, m_bearish_count);
   m_bearish_obs[m_bearish_count - 1] = ob;

   return true;
  }

//+------------------------------------------------------------------+
//| Vérifier si le mouvement est impulsif                            |
//+------------------------------------------------------------------+
bool COrderBlockEngine::IsImpulsiveMove(const int bar_index, const ENUM_OB_TYPE direction)
  {
   double atr = GetATRValue(1);
   if(atr <= 0)
      return false;

   double body = MathAbs(iClose(_Symbol, PERIOD_CURRENT, bar_index) -
                         iOpen(_Symbol, PERIOD_CURRENT, bar_index));

   //--- Le corps doit être au moins impulse_ratio * ATR
   return (body >= m_impulse_min_ratio * atr);
  }

//+------------------------------------------------------------------+
//| Obtenir la valeur ATR                                            |
//+------------------------------------------------------------------+
double COrderBlockEngine::GetATRValue(const int shift)
  {
   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(m_atr_handle, 0, shift, 1, buffer) > 0)
      return buffer[0];
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Vérifier BOS à proximité de l'OB                                 |
//+------------------------------------------------------------------+
bool COrderBlockEngine::HasBOSNearby(const int bar_index, const ENUM_OB_TYPE direction)
  {
   //--- Chercher une cassure de structure dans les 5 barres suivantes
   int look_ahead = MathMin(5, iBars(_Symbol, PERIOD_CURRENT) - bar_index - 1);

   for(int i = 1; i <= look_ahead; i++)
     {
      double high = iHigh(_Symbol, PERIOD_CURRENT, bar_index - i);
      double low = iLow(_Symbol, PERIOD_CURRENT, bar_index - i);
      double close = iClose(_Symbol, PERIOD_CURRENT, bar_index - i);

      if(direction == OB_BULLISH)
        {
         //--- BOS haussier: le prix clôture au-dessus du haut de l'OB
         double ob_high = MathMax(iOpen(_Symbol, PERIOD_CURRENT, bar_index),
                                  iClose(_Symbol, PERIOD_CURRENT, bar_index));
         if(close > ob_high)
            return true;
        }
      else
        {
         //--- BOS baissier: le prix clôture en-dessous du bas de l'OB
         double ob_low = MathMin(iOpen(_Symbol, PERIOD_CURRENT, bar_index),
                                 iClose(_Symbol, PERIOD_CURRENT, bar_index));
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
      //--- OB haussier: si le prix est descendu dans la zone
      if(current_price >= ob.low && current_price <= ob.high)
        {
         //--- Partiellement mitigé
         double penetration = (ob.high - current_price) / (ob.high - ob.low);
         if(penetration < OB_MITIGATION_THRESHOLD)
           {
            ob.state = OB_STATE_MITIGATED;
            ob.score = 50.0;
           }
         else
           {
            ob.state = OB_STATE_CONSUMED;
            ob.score = 0.0;
            ob.is_valid = false;
           }
        }
      //--- Si le prix a cassé en-dessous de l'OB
      else if(current_price < ob.low)
        {
         ob.state = OB_STATE_CONSUMED;
         ob.score = 0.0;
         ob.is_valid = false;
        }
     }
   else // OB_BEARISH
     {
      if(current_price <= ob.high && current_price >= ob.low)
        {
         double penetration = (current_price - ob.low) / (ob.high - ob.low);
         if(penetration < OB_MITIGATION_THRESHOLD)
           {
            ob.state = OB_STATE_MITIGATED;
            ob.score = 50.0;
           }
         else
           {
            ob.state = OB_STATE_CONSUMED;
            ob.score = 0.0;
            ob.is_valid = false;
           }
        }
      else if(current_price > ob.high)
        {
         ob.state = OB_STATE_CONSUMED;
         ob.score = 0.0;
         ob.is_valid = false;
        }
     }
  }

//+------------------------------------------------------------------+
//| Nettoyer les anciens OB                                          |
//+------------------------------------------------------------------+
void COrderBlockEngine::CleanupOldOBs()
  {
   //--- Supprimer les OB invalides et limiter le nombre
   //--- Bullish
   SOrderBlock temp_bull[];
   int new_bull_count = 0;
   for(int i = m_bullish_count - 1; i >= 0 && new_bull_count < m_max_ob_count; i--)
     {
      if(m_bullish_obs[i].is_valid)
        {
         new_bull_count++;
         ArrayResize(temp_bull, new_bull_count);
         temp_bull[new_bull_count - 1] = m_bullish_obs[i];
        }
     }
   m_bullish_count = new_bull_count;
   ArrayResize(m_bullish_obs, m_bullish_count);
   for(int i = 0; i < m_bullish_count; i++)
      m_bullish_obs[i] = temp_bull[m_bullish_count - 1 - i]; // Ordre chronologique

   //--- Bearish
   SOrderBlock temp_bear[];
   int new_bear_count = 0;
   for(int i = m_bearish_count - 1; i >= 0 && new_bear_count < m_max_ob_count; i--)
     {
      if(m_bearish_obs[i].is_valid)
        {
         new_bear_count++;
         ArrayResize(temp_bear, new_bear_count);
         temp_bear[new_bear_count - 1] = m_bearish_obs[i];
        }
     }
   m_bearish_count = new_bear_count;
   ArrayResize(m_bearish_obs, m_bearish_count);
   for(int i = 0; i < m_bearish_count; i++)
      m_bearish_obs[i] = temp_bear[m_bearish_count - 1 - i];
  }

//+------------------------------------------------------------------+
//| Mise à jour principale                                          |
//+------------------------------------------------------------------+
bool COrderBlockEngine::Update()
  {
   if(!m_initialized)
      return false;

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- Mettre à jour l'état des OB existants
   for(int i = 0; i < m_bullish_count; i++)
      UpdateOBState(m_bullish_obs[i], current_price);
   for(int i = 0; i < m_bearish_count; i++)
      UpdateOBState(m_bearish_obs[i], current_price);

   //--- Détecter de nouveaux OB (scanner les dernières barres)
   int start_bar = 3; // On laisse 3 barres pour confirmation
   int end_bar = MathMin(m_lookback, iBars(_Symbol, PERIOD_CURRENT) - 1);

   for(int i = start_bar; i < end_bar; i++)
     {
      //--- Éviter de scanner les barres déjà traitées
      bool already_detected = false;
      for(int j = 0; j < m_bullish_count; j++)
        {
         if(m_bullish_obs[j].bar_index == i)
           {
            already_detected = true;
            break;
           }
        }
      if(!already_detected)
        {
         for(int j = 0; j < m_bearish_count; j++)
           {
            if(m_bearish_obs[j].bar_index == i)
              {
               already_detected = true;
               break;
              }
           }
        }

      if(!already_detected)
        {
         DetectBullishOB(i);
         DetectBearishOB(i);
        }
     }

   //--- Nettoyer les OB trop anciens ou invalides
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
   SOrderBlock empty;
   ZeroMemory(empty);
   return empty;
  }

SOrderBlock COrderBlockEngine::GetBearishOB(const int index) const
  {
   if(index >= 0 && index < m_bearish_count)
      return m_bearish_obs[index];
   SOrderBlock empty;
   ZeroMemory(empty);
   return empty;
  }

//+------------------------------------------------------------------+
//| Le prix est-il dans un OB ?                                      |
//+------------------------------------------------------------------+
bool COrderBlockEngine::IsPriceAtOB(const double price, const ENUM_OB_TYPE type) const
  {
   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(m_bullish_obs[i].is_valid && price >= m_bullish_obs[i].low && price <= m_bullish_obs[i].high)
            return true;
        }
     }
   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(m_bearish_obs[i].is_valid && price >= m_bearish_obs[i].low && price <= m_bearish_obs[i].high)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Obtenir l'OB le plus proche                                      |
//+------------------------------------------------------------------+
SOrderBlock COrderBlockEngine::GetNearestOB(const double price, const ENUM_OB_TYPE type) const
  {
   SOrderBlock nearest;
   ZeroMemory(nearest);
   double min_distance = DBL_MAX;

   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(!m_bullish_obs[i].is_valid)
            continue;
         double distance = MathMin(MathAbs(price - m_bullish_obs[i].high),
                                   MathAbs(price - m_bullish_obs[i].low));
         if(distance < min_distance)
           {
            min_distance = distance;
            nearest = m_bullish_obs[i];
           }
        }
     }

   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(!m_bearish_obs[i].is_valid)
            continue;
         double distance = MathMin(MathAbs(price - m_bearish_obs[i].high),
                                   MathAbs(price - m_bearish_obs[i].low));
         if(distance < min_distance)
           {
            min_distance = distance;
            nearest = m_bearish_obs[i];
           }
        }
     }

   return nearest;
  }

//+------------------------------------------------------------------+
//| Score OB au prix donné                                           |
//+------------------------------------------------------------------+
double COrderBlockEngine::GetOBScoreAtPrice(const double price, const ENUM_OB_TYPE type) const
  {
   double best_score = 0.0;

   if(type == OB_BULLISH)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(m_bullish_obs[i].is_valid && price >= m_bullish_obs[i].low && price <= m_bullish_obs[i].high)
           {
            if(m_bullish_obs[i].score > best_score)
               best_score = m_bullish_obs[i].score;
           }
        }
     }
   else
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(m_bearish_obs[i].is_valid && price >= m_bearish_obs[i].low && price <= m_bearish_obs[i].high)
           {
            if(m_bearish_obs[i].score > best_score)
               best_score = m_bearish_obs[i].score;
           }
        }
     }

   return best_score;
  }

//+------------------------------------------------------------------+
//| Y a-t-il un OB frais ?                                           |
//+------------------------------------------------------------------+
bool COrderBlockEngine::HasFreshOB(const ENUM_OB_TYPE type) const
  {
   if(type == OB_BULLISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(m_bullish_obs[i].is_valid && m_bullish_obs[i].state == OB_STATE_FRESH)
            return true;
        }
     }
   if(type == OB_BEARISH || type == OB_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(m_bearish_obs[i].is_valid && m_bearish_obs[i].state == OB_STATE_FRESH)
            return true;
        }
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
   return (double)ob.state; // Returns 100 for Fresh, 50 for Mitigated, 0 for Consumed
  }

#endif // A2SNIPER_ORDER_BLOCK_MQH
//+------------------------------------------------------------------+
