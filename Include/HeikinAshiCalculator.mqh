//+------------------------------------------------------------------+
//|                                         HeikinAshiCalculator.mqh |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"

//+------------------------------------------------------------------+
//| Structure pour les données Heikin-Ashi                          |
//+------------------------------------------------------------------+
struct SHeikinAshiData
{
   double ha_open;
   double ha_high;
   double ha_low;
   double ha_close;
   datetime time;
   long volume;
   bool is_bullish;
   bool is_doji;
   double body_size;
   double upper_wick;
   double lower_wick;
};

//+------------------------------------------------------------------+
//| Classe calculateur Heikin-Ashi                                  |
//+------------------------------------------------------------------+
class CHeikinAshiCalculator
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   SHeikinAshiData   m_ha_data[];
   int               m_data_size;
   bool              m_initialized;
   
   // Buffers pour les calculs
   double            m_open[];
   double            m_high[];
   double            m_low[];
   double            m_close[];
   long              m_volume[];
   datetime          m_time[];

public:
   // Constructeur/Destructeur
                     CHeikinAshiCalculator();
                    ~CHeikinAshiCalculator();
   
   // Méthodes d'initialisation
   bool              Initialize(string symbol, ENUM_TIMEFRAMES timeframe, int data_size = 1000);
   void              Deinitialize();
   
   // Méthodes de calcul
   bool              Update();
   bool              Calculate(int start_pos = 0, int count = -1);
   
   // Méthodes d'accès aux données
   SHeikinAshiData   GetHAData(int index = 0);
   double            GetHAOpen(int index = 0);
   double            GetHAHigh(int index = 0);
   double            GetHALow(int index = 0);
   double            GetHAClose(int index = 0);
   bool              IsHABullish(int index = 0);
   bool              IsHADoji(int index = 0, double doji_ratio = 0.3);
   
   // Méthodes d'analyse
   int               CountConsecutiveBullish(int start_index = 0);
   int               CountConsecutiveBearish(int start_index = 0);
   bool              HasSignificantWick(int index = 0, bool upper = true, double threshold = 0.1);
   double            GetBodySize(int index = 0);
   double            GetWickSize(int index = 0, bool upper = true);
   
   // Méthodes utilitaires
   bool              IsInitialized() { return m_initialized; }
   int               GetDataSize() { return m_data_size; }
   string            GetSymbol() { return m_symbol; }
   ENUM_TIMEFRAMES   GetTimeframe() { return m_timeframe; }
};

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CHeikinAshiCalculator::CHeikinAshiCalculator()
{
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_data_size = 0;
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CHeikinAshiCalculator::~CHeikinAshiCalculator()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CHeikinAshiCalculator::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, int data_size = 1000)
{
   if(data_size <= 0)
   {
      Print("ERREUR HeikinAshi: Taille de données invalide");
      return false;
   }
   
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_data_size = data_size;
   
   // Redimensionnement des arrays
   ArrayResize(m_ha_data, m_data_size);
   ArrayResize(m_open, m_data_size);
   ArrayResize(m_high, m_data_size);
   ArrayResize(m_low, m_data_size);
   ArrayResize(m_close, m_data_size);
   ArrayResize(m_volume, m_data_size);
   ArrayResize(m_time, m_data_size);
   
   // Configuration des arrays
   ArraySetAsSeries(m_ha_data, true);
   ArraySetAsSeries(m_open, true);
   ArraySetAsSeries(m_high, true);
   ArraySetAsSeries(m_low, true);
   ArraySetAsSeries(m_close, true);
   ArraySetAsSeries(m_volume, true);
   ArraySetAsSeries(m_time, true);
   
   // Récupération des données historiques
   int copied_open = CopyOpen(m_symbol, m_timeframe, 0, m_data_size, m_open);
   int copied_high = CopyHigh(m_symbol, m_timeframe, 0, m_data_size, m_high);
   int copied_low = CopyLow(m_symbol, m_timeframe, 0, m_data_size, m_low);
   int copied_close = CopyClose(m_symbol, m_timeframe, 0, m_data_size, m_close);
   int copied_volume = CopyTickVolume(m_symbol, m_timeframe, 0, m_data_size, m_volume);
   int copied_time = CopyTime(m_symbol, m_timeframe, 0, m_data_size, m_time);
   
   // Vérifier si les données ont été correctement récupérées
   if(copied_open <= 0 || copied_high <= 0 || copied_low <= 0 || copied_close <= 0 || copied_volume <= 0 || copied_time <= 0)
   {
      Print("ERREUR HeikinAshi: Impossible de récupérer les données historiques. Vérifiez le symbole et le timeframe.");
      Print("Données copiées: Open=", copied_open, ", High=", copied_high, ", Low=", copied_low, ", Close=", copied_close, ", Volume=", copied_volume, ", Time=", copied_time);
      return false;
   }
   
   // Calcul initial
   if(!Calculate())
   {
      Print("ERREUR HeikinAshi: Échec du calcul initial");
      return false;
   }
   
   m_initialized = true;
   Print("HeikinAshi initialisé pour ", m_symbol, " ", EnumToString(m_timeframe), " avec ", copied_close, " bougies");
   
   return true;
}

//+------------------------------------------------------------------+
//| Désinitialisation                                               |
//+------------------------------------------------------------------+
void CHeikinAshiCalculator::Deinitialize()
{
   ArrayFree(m_ha_data);
   ArrayFree(m_open);
   ArrayFree(m_high);
   ArrayFree(m_low);
   ArrayFree(m_close);
   ArrayFree(m_volume);
   ArrayFree(m_time);
   
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Mise à jour des données                                          |
//+------------------------------------------------------------------+
bool CHeikinAshiCalculator::Update()
{
   if(!m_initialized)
   {
      Print("ERREUR HeikinAshi: Non initialisé");
      return false;
   }
   
   // Copie des nouvelles données de marché avec gestion d'erreur plus souple
   int copied_open = CopyOpen(m_symbol, m_timeframe, 0, m_data_size, m_open);
   int copied_high = CopyHigh(m_symbol, m_timeframe, 0, m_data_size, m_high);
   int copied_low = CopyLow(m_symbol, m_timeframe, 0, m_data_size, m_low);
   int copied_close = CopyClose(m_symbol, m_timeframe, 0, m_data_size, m_close);
   int copied_volume = CopyTickVolume(m_symbol, m_timeframe, 0, m_data_size, m_volume);
   int copied_time = CopyTime(m_symbol, m_timeframe, 0, m_data_size, m_time);
   
   // Vérifier si nous avons au moins quelques données
   if(copied_open <= 0 || copied_high <= 0 || copied_low <= 0 || copied_close <= 0 || copied_volume <= 0 || copied_time <= 0)
   {
      Print("ERREUR HeikinAshi: Impossible de récupérer les données historiques dans Update()");
      Print("Données copiées: Open=", copied_open, ", High=", copied_high, ", Low=", copied_low, ", Close=", copied_close, ", Volume=", copied_volume, ", Time=", copied_time);
      return false;
   }
   
   // Si nous avons moins de données que demandé mais quand même des données, continuons
   if(copied_open < m_data_size || copied_high < m_data_size || copied_low < m_data_size || 
      copied_close < m_data_size || copied_volume < m_data_size || copied_time < m_data_size)
   {
      Print("AVERTISSEMENT HeikinAshi: Données historiques partielles dans Update() - Continuons avec ", copied_close, " bougies");
   }
   
   // Recalcul des données Heikin-Ashi
   return Calculate();
}

//+------------------------------------------------------------------+
//| Calcul des données Heikin-Ashi                                  |
//+------------------------------------------------------------------+
bool CHeikinAshiCalculator::Calculate(int start_pos = 0, int count = -1)
{
   // Lors du calcul initial, m_initialized est false, mais on doit quand même pouvoir calculer
   if(m_symbol == "" || m_timeframe == 0)
   {
      Print("ERREUR HeikinAshi: Symbole ou timeframe non défini");
      return false;
   }
   
   // Vérifier que nous avons des données valides
   int open_size = ArraySize(m_open);
   int high_size = ArraySize(m_high);
   int low_size = ArraySize(m_low);
   int close_size = ArraySize(m_close);
   int volume_size = ArraySize(m_volume);
   int time_size = ArraySize(m_time);
   
   // Trouver la taille minimum disponible
   int min_size = MathMin(open_size, MathMin(high_size, MathMin(low_size, MathMin(close_size, MathMin(volume_size, time_size)))));
   
   if(min_size <= 0)
   {
      Print("ERREUR HeikinAshi: Données insuffisantes pour le calcul. Tailles: Open=", open_size, ", High=", high_size, ", Low=", low_size, ", Close=", close_size);
      return false;
   }
   
   // Ajuster les paramètres en fonction des données disponibles
   int calc_count = (count == -1) ? min_size : count;
   if(calc_count > min_size) calc_count = min_size;
   
   int end_pos = start_pos + calc_count;
   if(end_pos > min_size) end_pos = min_size;
   
   // Calcul des valeurs Heikin-Ashi
   for(int i = min_size - 1; i >= 0; i--)
   {
      // Vérification de sécurité pour les indices
      if(i >= ArraySize(m_open) || i >= ArraySize(m_high) || i >= ArraySize(m_low) || 
         i >= ArraySize(m_close) || i >= ArraySize(m_volume) || i >= ArraySize(m_time) || 
         i >= ArraySize(m_ha_data))
      {
         Print("ERREUR HeikinAshi: Indice hors limites dans le calcul: ", i);
         continue; // Passer à l'itération suivante
      }
      
      // HA_Close = (O + H + L + C) / 4
      m_ha_data[i].ha_close = (m_open[i] + m_high[i] + m_low[i] + m_close[i]) / 4.0;
      
      // HA_Open = (HA_Open[précédent] + HA_Close[précédent]) / 2
      if(i == min_size - 1)
      {
         // Première bougie : utiliser les valeurs réelles
         m_ha_data[i].ha_open = (m_open[i] + m_close[i]) / 2.0;
      }
      else if(i+1 < ArraySize(m_ha_data)) // Vérification de sécurité
         m_ha_data[i].ha_open = (m_ha_data[i + 1].ha_open + m_ha_data[i + 1].ha_close) / 2.0;
      else
         m_ha_data[i].ha_open = (m_open[i] + m_close[i]) / 2.0; // Fallback si l'indice précédent n'est pas disponible
      
      // HA_High = Max(H, HA_Open, HA_Close)
      m_ha_data[i].ha_high = MathMax(m_high[i], MathMax(m_ha_data[i].ha_open, m_ha_data[i].ha_close));
      
      // HA_Low = Min(L, HA_Open, HA_Close)
      m_ha_data[i].ha_low = MathMin(m_low[i], MathMin(m_ha_data[i].ha_open, m_ha_data[i].ha_close));
      
      // Autres données
      m_ha_data[i].volume = m_volume[i];
      m_ha_data[i].time = m_time[i];
      
      // Détection Doji
      double total_range = m_ha_data[i].ha_high - m_ha_data[i].ha_low;
      if(total_range > 0)
      {
         double body_ratio = m_ha_data[i].body_size / total_range;
         m_ha_data[i].is_doji = (body_ratio <= 0.3);
      }
      else
      {
         m_ha_data[i].is_doji = true;
      }
   }
   
   // Enregistrer le succès du calcul
   if(min_size > 0)
   {
      Print("HeikinAshi: Calcul réussi pour ", min_size, " bougies");
      return true;
   }
   else
   {
      Print("ERREUR HeikinAshi: Aucune donnée calculée");
      return false;
   }
}

//+------------------------------------------------------------------+
//| Obtenir les données HA                                          |
//+------------------------------------------------------------------+
SHeikinAshiData CHeikinAshiCalculator::GetHAData(int index = 0)
{
   SHeikinAshiData empty_data = {0};
   
   if(!m_initialized || index < 0 || index >= m_data_size)
      return empty_data;
   
   return m_ha_data[index];
}

//+------------------------------------------------------------------+
//| Obtenir HA Open                                                 |
//+------------------------------------------------------------------+
double CHeikinAshiCalculator::GetHAOpen(int index = 0)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return 0.0;
   
   return m_ha_data[index].ha_open;
}

//+------------------------------------------------------------------+
//| Obtenir HA High                                                 |
//+------------------------------------------------------------------+
double CHeikinAshiCalculator::GetHAHigh(int index = 0)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return 0.0;
   
   return m_ha_data[index].ha_high;
}

//+------------------------------------------------------------------+
//| Obtenir HA Low                                                  |
//+------------------------------------------------------------------+
double CHeikinAshiCalculator::GetHALow(int index = 0)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return 0.0;
   
   return m_ha_data[index].ha_low;
}

//+------------------------------------------------------------------+
//| Obtenir HA Close                                                |
//+------------------------------------------------------------------+
double CHeikinAshiCalculator::GetHAClose(int index = 0)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return 0.0;
   
   return m_ha_data[index].ha_close;
}

//+------------------------------------------------------------------+
//| Vérifier si la bougie HA est haussière                         |
//+------------------------------------------------------------------+
bool CHeikinAshiCalculator::IsHABullish(int index = 0)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return false;
   
   return m_ha_data[index].is_bullish;
}

//+------------------------------------------------------------------+
//| Vérifier si la bougie HA est un Doji                           |
//+------------------------------------------------------------------+
bool CHeikinAshiCalculator::IsHADoji(int index = 0, double doji_ratio = 0.3)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return false;
   
   double total_range = m_ha_data[index].ha_high - m_ha_data[index].ha_low;
   if(total_range <= 0)
      return true;
   
   double body_ratio = m_ha_data[index].body_size / total_range;
   return (body_ratio <= doji_ratio);
}

//+------------------------------------------------------------------+
//| Compter les bougies haussières consécutives                    |
//+------------------------------------------------------------------+
int CHeikinAshiCalculator::CountConsecutiveBullish(int start_index = 0)
{
   if(!m_initialized)
      return 0;
   
   int count = 0;
   for(int i = start_index; i < m_data_size; i++)
   {
      if(m_ha_data[i].is_bullish)
         count++;
      else
         break;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Compter les bougies baissières consécutives                    |
//+------------------------------------------------------------------+
int CHeikinAshiCalculator::CountConsecutiveBearish(int start_index = 0)
{
   if(!m_initialized)
      return 0;
   
   int count = 0;
   for(int i = start_index; i < m_data_size; i++)
   {
      if(!m_ha_data[i].is_bullish)
         count++;
      else
         break;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Vérifier la présence de mèche significative                    |
//+------------------------------------------------------------------+
bool CHeikinAshiCalculator::HasSignificantWick(int index = 0, bool upper = true, double threshold = 0.1)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return false;
   
   double total_range = m_ha_data[index].ha_high - m_ha_data[index].ha_low;
   if(total_range <= 0)
      return false;
   
   double wick_size = upper ? m_ha_data[index].upper_wick : m_ha_data[index].lower_wick;
   double wick_ratio = wick_size / total_range;
   
   return (wick_ratio > threshold);
}

//+------------------------------------------------------------------+
//| Obtenir la taille du corps                                     |
//+------------------------------------------------------------------+
double CHeikinAshiCalculator::GetBodySize(int index = 0)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return 0.0;
   
   return m_ha_data[index].body_size;
}

//+------------------------------------------------------------------+
//| Obtenir la taille de la mèche                                  |
//+------------------------------------------------------------------+
double CHeikinAshiCalculator::GetWickSize(int index = 0, bool upper = true)
{
   if(!m_initialized || index < 0 || index >= m_data_size)
      return 0.0;
   
   return upper ? m_ha_data[index].upper_wick : m_ha_data[index].lower_wick;
}
