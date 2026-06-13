//+------------------------------------------------------------------+
//| NewsFilterEngine.mqh - Filtre Économique                        |
//| A2Sniper Ultimate v3.0                                           |
//| Blocage autour des événements critiques: NFP, CPI, FOMC, etc.   |
//| Blocage 30 min avant / 30 min après                              |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_NEWS_FILTER_MQH
#define A2SNIPER_NEWS_FILTER_MQH

#include <A2Sniper\CommonTypes.mqh>

//+------------------------------------------------------------------+
//| Classe CNewsFilterEngine                                         |
//+------------------------------------------------------------------+
class CNewsFilterEngine
  {
private:
   bool              m_initialized;
   bool              m_enabled;
   int               m_minutes_before;        // Minutes de blocage avant l'événement
   int               m_minutes_after;         // Minutes de blocage après l'événement

   //--- État
   bool              m_is_news_time;           // Période de news active
   string            m_active_event;           // Nom de l'événement actif

public:
   //--- Constructeur / Destructeur
                     CNewsFilterEngine();
                    ~CNewsFilterEngine();

   //--- Initialisation
   bool              Initialize(bool enabled = true, int min_before = 30, int min_after = 30);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Vérifications
   bool              IsNewsTime() const { return m_is_news_time; }
   bool              CanTrade() const;
   string            GetActiveEvent() const { return m_active_event; }
   int               GetMinutesBeforeNews() const;
   bool              ShouldTightenStopLoss() const;

   //--- Configuration
   void              SetEnabled(bool enabled) { m_enabled = enabled; }
   void              SetBlockMinutes(int before, int after) { m_minutes_before = before; m_minutes_after = after; }

   //--- Info
   string            GetNewsFilterInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CNewsFilterEngine::CNewsFilterEngine() :
   m_initialized(false),
   m_enabled(true),
   m_minutes_before(30),
   m_minutes_after(30),
   m_is_news_time(false),
   m_active_event("")
  {
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CNewsFilterEngine::~CNewsFilterEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::Initialize(bool enabled, int min_before, int min_after)
  {
   m_enabled = enabled;
   m_minutes_before = (min_before > 0) ? min_before : 30;
   m_minutes_after = (min_after > 0) ? min_after : 30;

   m_initialized = true;
   Print("A2Sniper NF: News Filter initialisé (Enabled=", m_enabled,
         " Before=", m_minutes_before, "min After=", m_minutes_after, "min)");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CNewsFilterEngine::Deinitialize()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Mise à jour                                                      |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::Update()
  {
   if(!m_initialized || !m_enabled)
     {
      m_is_news_time = false;
      m_active_event = "";
      return true;
     }

   //--- Vérifier le calendrier économique MT5
   MqlCalendarValue values[];
   datetime from = TimeCurrent() - m_minutes_before * 60;
   datetime to = TimeCurrent() + m_minutes_after * 60;

   int count = CalendarValueHistory(values, from, to);

   if(count > 0)
     {
      //--- Vérifier si un événement à impact élevé concerne notre devise
      string base_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
      string profit_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);

      for(int i = 0; i < count; i++)
        {
         MqlCalendarEvent event;
         if(!CalendarEventById(values[i].event_id, event))
            continue;

         //--- Vérifier l'importance (High impact)
         if(event.importance != CALENDAR_IMPORTANCE_HIGH)
            continue;

         //--- Vérifier si la devise est concernée
         MqlCalendarCountry country;
         if(!CalendarCountryById(event.country_id, country))
            continue;

         string event_currency = country.currency;
         if(event_currency == base_currency || event_currency == profit_currency)
           {
            m_is_news_time = true;
            m_active_event = event.name;
            return true;
           }
        }
     }

   m_is_news_time = false;
   m_active_event = "";
   return true;
  }

//+------------------------------------------------------------------+
//| Peut-on trader ?                                                 |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::CanTrade() const
  {
   if(!m_enabled)
      return true;
   return !m_is_news_time;
  }

//+------------------------------------------------------------------+
//| Info filtre de news                                              |
//+------------------------------------------------------------------+
string CNewsFilterEngine::GetNewsFilterInfo() const
  {
   return StringFormat("NewsFilter: Enabled=%s NewsTime=%s Event=%s Block=%dm/%dm",
                       m_enabled ? "Y" : "N",
                       m_is_news_time ? "Y" : "N",
                       m_active_event,
                       m_minutes_before, m_minutes_after);
  }

//+------------------------------------------------------------------+
//| Vérifier si on doit resserrer le SL avant les news               |
//| Retourne le nombre de minutes avant la prochaine news            |
//+------------------------------------------------------------------+
int CNewsFilterEngine::GetMinutesBeforeNews() const
  {
   if(!m_initialized || !m_enabled)
      return 999; // Pas de news prévue

   //--- Vérifier le calendrier économique MT5
   MqlCalendarValue values[];
   datetime from = TimeCurrent();
   datetime to = TimeCurrent() + m_minutes_before * 60;

   int count = CalendarValueHistory(values, from, to);
   if(count <= 0)
      return 999;

   string base_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string profit_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);

   int min_minutes = 999;
   for(int i = 0; i < count; i++)
     {
      MqlCalendarEvent event;
      if(!CalendarEventById(values[i].event_id, event))
         continue;
      if(event.importance != CALENDAR_IMPORTANCE_HIGH)
         continue;

      MqlCalendarCountry country;
      if(!CalendarCountryById(event.country_id, country))
         continue;

      string event_currency = country.currency;
      if(event_currency == base_currency || event_currency == profit_currency)
        {
         int minutes_to_event = (int)((values[i].time - TimeCurrent()) / 60);
         if(minutes_to_event >= 0 && minutes_to_event < min_minutes)
            min_minutes = minutes_to_event;
        }
     }

   return min_minutes;
  }

//+------------------------------------------------------------------+
//| Devons-nous resserrer le SL avant les news ?                     |
//+------------------------------------------------------------------+
bool CNewsFilterEngine::ShouldTightenStopLoss() const
  {
   //--- Resserrer le SL si une news est prévue dans les 15 prochaines minutes
   return (GetMinutesBeforeNews() <= 15);
  }

#endif // A2SNIPER_NEWS_FILTER_MQH
//+------------------------------------------------------------------+
