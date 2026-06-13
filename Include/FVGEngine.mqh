//+------------------------------------------------------------------+
//| FVGEngine.mqh - Fair Value Gap Detection & Classification       |
//| A2Sniper Ultimate v3.0                                           |
//| Détection sur 3 bougies: Micro/Standard/Institutional            |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_FVG_ENGINE_MQH
#define A2SNIPER_FVG_ENGINE_MQH

#include <A2Sniper\CommonTypes.mqh>

//+------------------------------------------------------------------+
//| Classe CFVGEngine                                                |
//+------------------------------------------------------------------+
class CFVGEngine
  {
private:
   bool              m_initialized;
   int               m_lookback;
   int               m_max_fvg_count;
   int               m_atr_handle;

   //--- Stockage des FVG
   SFVG              m_bullish_fvgs[];
   SFVG              m_bearish_fvgs[];
   int               m_bullish_count;
   int               m_bearish_count;

   //--- Seuils de classification (en multiples d'ATR)
   double            m_micro_threshold;      // En-dessous = Micro FVG
   double            m_standard_threshold;   // En-dessous = Standard, au-dessus = Institutional

   //--- Méthodes privées
   bool              DetectBullishFVG(const int bar_b);
   bool              DetectBearishFVG(const int bar_b);
   ENUM_FVG_CLASS    ClassifyFVG(const double gap_size) const;
   double            GetATRValue(const int shift);
   void              UpdateFVGState(SFVG &fvg, const double current_price);
   void              CleanupOldFVGs();

public:
   //--- Constructeur / Destructeur
                     CFVGEngine();
                    ~CFVGEngine();

   //--- Initialisation
   bool              Initialize(int lookback = FVG_LOOKBACK, int max_count = 30);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   int               GetBullishCount() const { return m_bullish_count; }
   int               GetBearishCount() const { return m_bearish_count; }
   SFVG              GetBullishFVG(const int index) const;
   SFVG              GetBearishFVG(const int index) const;

   //--- Vérifications
   bool              IsPriceInFVG(const double price, const ENUM_FVG_TYPE type) const;
   SFVG              GetNearestFVG(const double price, const ENUM_FVG_TYPE type) const;
   double            GetFVGScoreAtPrice(const double price, const ENUM_FVG_TYPE type) const;
   bool              HasUnfilledFVG(const ENUM_FVG_TYPE type) const;
   double            GetFVGFillingPercent(const SFVG &fvg, const double current_price) const;

   //--- Info
   string            GetFVGInfo(const SFVG &fvg) const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CFVGEngine::CFVGEngine() :
   m_initialized(false),
   m_lookback(FVG_LOOKBACK),
   m_max_fvg_count(30),
   m_atr_handle(INVALID_HANDLE),
   m_bullish_count(0),
   m_bearish_count(0),
   m_micro_threshold(0.5),
   m_standard_threshold(1.5)
  {
   ArrayResize(m_bullish_fvgs, 0);
   ArrayResize(m_bearish_fvgs, 0);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CFVGEngine::~CFVGEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CFVGEngine::Initialize(int lookback, int max_count)
  {
   m_lookback = (lookback > 5) ? lookback : FVG_LOOKBACK;
   m_max_fvg_count = (max_count > 5) ? max_count : 30;

   m_atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(m_atr_handle == INVALID_HANDLE)
     {
      Print("A2Sniper FVGE: Erreur création ATR - ", GetLastError());
      return false;
     }

   m_initialized = true;
   Print("A2Sniper FVGE: FVG Engine initialisé");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CFVGEngine::Deinitialize()
  {
   if(m_atr_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_atr_handle);
      m_atr_handle = INVALID_HANDLE;
     }
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Détection FVG haussier                                           |
//| Condition: Low(C) > High(A) sur 3 bougies A, B, C              |
//| Bar B = bar_index (bougie du milieu)                             |
//+------------------------------------------------------------------+
bool CFVGEngine::DetectBullishFVG(const int bar_b)
  {
   if(bar_b < 1 || bar_b >= iBars(_Symbol, PERIOD_CURRENT) - 1)
      return false;

   int bar_a = bar_b + 1; // Bougie A (plus ancienne)
   int bar_c = bar_b - 1; // Bougie C (plus récente)

   double high_a = iHigh(_Symbol, PERIOD_CURRENT, bar_a);
   double low_c  = iLow(_Symbol, PERIOD_CURRENT, bar_c);

   //--- Condition FVG haussier: Low(C) > High(A)
   if(low_c <= high_a)
      return false;

   //--- Calculer la taille du gap
   double gap_size = (low_c - high_a) / _Point;

   //--- La taille doit être significative (au moins quelques pips)
   if(gap_size < 1.0)
      return false;

   //--- Créer le FVG
   SFVG fvg;
   fvg.high = low_c;               // Limite haute = Low de C
   fvg.low = high_a;                // Limite basse = High de A
   fvg.time = iTime(_Symbol, PERIOD_CURRENT, bar_b);
   fvg.bar_index = bar_b;
   fvg.type = FVG_BULLISH;
   fvg.size = gap_size;
   fvg.is_filled = false;
   fvg.is_valid = true;
   fvg.classification = ClassifyFVG(gap_size * _Point);

   m_bullish_count++;
   ArrayResize(m_bullish_fvgs, m_bullish_count);
   m_bullish_fvgs[m_bullish_count - 1] = fvg;

   return true;
  }

//+------------------------------------------------------------------+
//| Détection FVG baissier                                           |
//| Condition: High(C) < Low(A) sur 3 bougies A, B, C              |
//+------------------------------------------------------------------+
bool CFVGEngine::DetectBearishFVG(const int bar_b)
  {
   if(bar_b < 1 || bar_b >= iBars(_Symbol, PERIOD_CURRENT) - 1)
      return false;

   int bar_a = bar_b + 1;
   int bar_c = bar_b - 1;

   double low_a  = iLow(_Symbol, PERIOD_CURRENT, bar_a);
   double high_c = iHigh(_Symbol, PERIOD_CURRENT, bar_c);

   //--- Condition FVG baissier: High(C) < Low(A)
   if(high_c >= low_a)
      return false;

   double gap_size = (low_a - high_c) / _Point;

   if(gap_size < 1.0)
      return false;

   SFVG fvg;
   fvg.high = low_a;
   fvg.low = high_c;
   fvg.time = iTime(_Symbol, PERIOD_CURRENT, bar_b);
   fvg.bar_index = bar_b;
   fvg.type = FVG_BEARISH;
   fvg.size = gap_size;
   fvg.is_filled = false;
   fvg.is_valid = true;
   fvg.classification = ClassifyFVG(gap_size * _Point);

   m_bearish_count++;
   ArrayResize(m_bearish_fvgs, m_bearish_count);
   m_bearish_fvgs[m_bearish_count - 1] = fvg;

   return true;
  }

//+------------------------------------------------------------------+
//| Classification du FVG                                            |
//+------------------------------------------------------------------+
ENUM_FVG_CLASS CFVGEngine::ClassifyFVG(const double gap_size) const
  {
   double atr = 0;
   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(m_atr_handle, 0, 0, 1, buffer) > 0)
      atr = buffer[0];

   if(atr <= 0)
      return FVG_CLASS_STANDARD; // Par défaut

   double ratio = gap_size / atr;

   if(ratio < m_micro_threshold)
      return FVG_CLASS_MICRO;
   else if(ratio < m_standard_threshold)
      return FVG_CLASS_STANDARD;
   else
      return FVG_CLASS_INSTITUTIONAL;
  }

//+------------------------------------------------------------------+
//| Obtenir valeur ATR                                               |
//+------------------------------------------------------------------+
double CFVGEngine::GetATRValue(const int shift)
  {
   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(m_atr_handle, 0, shift, 1, buffer) > 0)
      return buffer[0];
   return 0.0;
  }

//+------------------------------------------------------------------+
//| Mettre à jour l'état du FVG                                      |
//+------------------------------------------------------------------+
void CFVGEngine::UpdateFVGState(SFVG &fvg, const double current_price)
  {
   if(!fvg.is_valid)
      return;

   if(fvg.type == FVG_BULLISH)
     {
      //--- FVG haussier rempli si le prix redescend dans le gap et le remplit
      double fill_percent = GetFVGFillingPercent(fvg, current_price);
      if(fill_percent >= 0.8) // 80% rempli = considéré comme rempli
        {
         fvg.is_filled = true;
         fvg.is_valid = false;
        }
     }
   else
     {
      double fill_percent = GetFVGFillingPercent(fvg, current_price);
      if(fill_percent >= 0.8)
        {
         fvg.is_filled = true;
         fvg.is_valid = false;
        }
     }
  }

//+------------------------------------------------------------------+
//| Pourcentage de remplissage du FVG                                |
//+------------------------------------------------------------------+
double CFVGEngine::GetFVGFillingPercent(const SFVG &fvg, const double current_price) const
  {
   double gap_height = fvg.high - fvg.low;
   if(gap_height <= 0)
      return 0.0;

   if(fvg.type == FVG_BULLISH)
     {
      //--- Le prix est-il redescendu dans le gap ?
      if(current_price <= fvg.high && current_price >= fvg.low)
         return (fvg.high - current_price) / gap_height;
      if(current_price < fvg.low)
         return 1.0; // Complètement rempli
     }
   else
     {
      if(current_price >= fvg.low && current_price <= fvg.high)
         return (current_price - fvg.low) / gap_height;
      if(current_price > fvg.high)
         return 1.0;
     }

   return 0.0;
  }

//+------------------------------------------------------------------+
//| Nettoyer les anciens FVG                                         |
//+------------------------------------------------------------------+
void CFVGEngine::CleanupOldFVGs()
  {
   //--- Bullish
   SFVG temp_bull[];
   int new_bull = 0;
   for(int i = m_bullish_count - 1; i >= 0 && new_bull < m_max_fvg_count; i--)
     {
      if(m_bullish_fvgs[i].is_valid)
        {
         new_bull++;
         ArrayResize(temp_bull, new_bull);
         temp_bull[new_bull - 1] = m_bullish_fvgs[i];
        }
     }
   m_bullish_count = new_bull;
   ArrayResize(m_bullish_fvgs, m_bullish_count);
   for(int i = 0; i < m_bullish_count; i++)
      m_bullish_fvgs[i] = temp_bull[m_bullish_count - 1 - i];

   //--- Bearish
   SFVG temp_bear[];
   int new_bear = 0;
   for(int i = m_bearish_count - 1; i >= 0 && new_bear < m_max_fvg_count; i--)
     {
      if(m_bearish_fvgs[i].is_valid)
        {
         new_bear++;
         ArrayResize(temp_bear, new_bear);
         temp_bear[new_bear - 1] = m_bearish_fvgs[i];
        }
     }
   m_bearish_count = new_bear;
   ArrayResize(m_bearish_fvgs, m_bearish_count);
   for(int i = 0; i < m_bearish_count; i++)
      m_bearish_fvgs[i] = temp_bear[m_bearish_count - 1 - i];
  }

//+------------------------------------------------------------------+
//| Mise à jour principale                                          |
//+------------------------------------------------------------------+
bool CFVGEngine::Update()
  {
   if(!m_initialized)
      return false;

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- Mettre à jour les FVG existants
   for(int i = 0; i < m_bullish_count; i++)
      UpdateFVGState(m_bullish_fvgs[i], current_price);
   for(int i = 0; i < m_bearish_count; i++)
      UpdateFVGState(m_bearish_fvgs[i], current_price);

   //--- Détecter de nouveaux FVG
   int start_bar = 2;
   int end_bar = MathMin(m_lookback, iBars(_Symbol, PERIOD_CURRENT) - 2);

   for(int i = start_bar; i < end_bar; i++)
     {
      //--- Vérifier si déjà détecté
      bool found = false;
      for(int j = 0; j < m_bullish_count; j++)
        {
         if(m_bullish_fvgs[j].bar_index == i)
           { found = true; break; }
        }
      if(!found)
        {
         for(int j = 0; j < m_bearish_count; j++)
           {
            if(m_bearish_fvgs[j].bar_index == i)
              { found = true; break; }
           }
        }

      if(!found)
        {
         DetectBullishFVG(i);
         DetectBearishFVG(i);
        }
     }

   CleanupOldFVGs();
   return true;
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
SFVG CFVGEngine::GetBullishFVG(const int index) const
  {
   if(index >= 0 && index < m_bullish_count)
      return m_bullish_fvgs[index];
   SFVG empty;
   ZeroMemory(empty);
   return empty;
  }

SFVG CFVGEngine::GetBearishFVG(const int index) const
  {
   if(index >= 0 && index < m_bearish_count)
      return m_bearish_fvgs[index];
   SFVG empty;
   ZeroMemory(empty);
   return empty;
  }

//+------------------------------------------------------------------+
//| Le prix est-il dans un FVG ?                                     |
//+------------------------------------------------------------------+
bool CFVGEngine::IsPriceInFVG(const double price, const ENUM_FVG_TYPE type) const
  {
   if(type == FVG_BULLISH || type == FVG_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(m_bullish_fvgs[i].is_valid && price >= m_bullish_fvgs[i].low && price <= m_bullish_fvgs[i].high)
            return true;
        }
     }
   if(type == FVG_BEARISH || type == FVG_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(m_bearish_fvgs[i].is_valid && price >= m_bearish_fvgs[i].low && price <= m_bearish_fvgs[i].high)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| FVG le plus proche                                               |
//+------------------------------------------------------------------+
SFVG CFVGEngine::GetNearestFVG(const double price, const ENUM_FVG_TYPE type) const
  {
   SFVG nearest;
   ZeroMemory(nearest);
   double min_dist = DBL_MAX;

   if(type == FVG_BULLISH || type == FVG_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(!m_bullish_fvgs[i].is_valid) continue;
         double mid = (m_bullish_fvgs[i].high + m_bullish_fvgs[i].low) / 2.0;
         double dist = MathAbs(price - mid);
         if(dist < min_dist)
           { min_dist = dist; nearest = m_bullish_fvgs[i]; }
        }
     }
   if(type == FVG_BEARISH || type == FVG_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(!m_bearish_fvgs[i].is_valid) continue;
         double mid = (m_bearish_fvgs[i].high + m_bearish_fvgs[i].low) / 2.0;
         double dist = MathAbs(price - mid);
         if(dist < min_dist)
           { min_dist = dist; nearest = m_bearish_fvgs[i]; }
        }
     }

   return nearest;
  }

//+------------------------------------------------------------------+
//| Score FVG au prix                                                |
//+------------------------------------------------------------------+
double CFVGEngine::GetFVGScoreAtPrice(const double price, const ENUM_FVG_TYPE type) const
  {
   double best = 0.0;

   //--- Note: on ne peut pas utiliser de pointeur sur tableau direct en MQL5
   //   donc on fait la boucle manuellement
   if(type == FVG_BULLISH)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(m_bullish_fvgs[i].is_valid && price >= m_bullish_fvgs[i].low && price <= m_bullish_fvgs[i].high)
           {
            double score = 0;
            switch(m_bullish_fvgs[i].classification)
              {
               case FVG_CLASS_INSTITUTIONAL: score = 100; break;
               case FVG_CLASS_STANDARD:      score = 70; break;
               case FVG_CLASS_MICRO:         score = 40; break;
              }
            if(score > best) best = score;
           }
        }
     }
   else
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(m_bearish_fvgs[i].is_valid && price >= m_bearish_fvgs[i].low && price <= m_bearish_fvgs[i].high)
           {
            double score = 0;
            switch(m_bearish_fvgs[i].classification)
              {
               case FVG_CLASS_INSTITUTIONAL: score = 100; break;
               case FVG_CLASS_STANDARD:      score = 70; break;
               case FVG_CLASS_MICRO:         score = 40; break;
              }
            if(score > best) best = score;
           }
        }
     }

   return best;
  }

//+------------------------------------------------------------------+
//| Y a-t-il un FVG non rempli ?                                     |
//+------------------------------------------------------------------+
bool CFVGEngine::HasUnfilledFVG(const ENUM_FVG_TYPE type) const
  {
   if(type == FVG_BULLISH || type == FVG_NONE)
     {
      for(int i = 0; i < m_bullish_count; i++)
        {
         if(m_bullish_fvgs[i].is_valid && !m_bullish_fvgs[i].is_filled)
            return true;
        }
     }
   if(type == FVG_BEARISH || type == FVG_NONE)
     {
      for(int i = 0; i < m_bearish_count; i++)
        {
         if(m_bearish_fvgs[i].is_valid && !m_bearish_fvgs[i].is_filled)
            return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Info FVG                                                         |
//+------------------------------------------------------------------+
string CFVGEngine::GetFVGInfo(const SFVG &fvg) const
  {
   string type_str = (fvg.type == FVG_BULLISH) ? "BULL" : "BEAR";
   string class_str = "";
   switch(fvg.classification)
     {
      case FVG_CLASS_MICRO:         class_str = "MICRO"; break;
      case FVG_CLASS_STANDARD:      class_str = "STANDARD"; break;
      case FVG_CLASS_INSTITUTIONAL: class_str = "INSTIT"; break;
     }
   return StringFormat("FVG[%s %s]: %.5f - %.5f | Size=%.1f pips | Bar=%d",
                       type_str, class_str, fvg.low, fvg.high, fvg.size, fvg.bar_index);
  }

#endif // A2SNIPER_FVG_ENGINE_MQH
//+------------------------------------------------------------------+
