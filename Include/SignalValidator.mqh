//+------------------------------------------------------------------+
//|                                             SignalValidator.mqh |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"

//+------------------------------------------------------------------+
//| Structure pour les heures de trading                            |
//+------------------------------------------------------------------+
struct STradingHours
{
   int start_hour;
   int start_minute;
   int end_hour;
   int end_minute;
   bool is_valid;
};

//+------------------------------------------------------------------+
//| Classe validateur de signaux                                    |
//+------------------------------------------------------------------+
class CSignalValidator
{
private:
   // Paramètres de configuration
   STradingHours     m_trading_hours;
   double            m_max_spread;
   bool              m_initialized;
   
   // Filtres de marché
   bool              m_check_trading_hours;
   bool              m_check_spread;
   bool              m_check_volatility;
   bool              m_check_news_events;
   
   // Statistiques de validation
   int               m_signals_received;
   int               m_signals_accepted;
   int               m_signals_rejected;
   
   // Raisons de rejet
   int               m_rejected_hours;
   int               m_rejected_spread;
   int               m_rejected_volatility;
   int               m_rejected_news;

public:
   // Constructeur/Destructeur
                     CSignalValidator();
                    ~CSignalValidator();
   
   // Méthodes d'initialisation
   bool              Initialize(string trading_hours, double max_spread);
   void              Deinitialize();
   
   // Méthodes principales de validation
   bool              ValidateSignal(int signal_type, string symbol);
   bool              ValidateMarketConditions(string symbol);
   
   // Méthodes de validation spécifiques
   bool              IsWithinTradingHours(datetime check_time);
   bool              IsSpreadAcceptable(string symbol);
   bool              IsVolatilityAcceptable(string symbol);
   bool              IsNewsEventSafe(datetime check_time);
   
   // Méthodes de configuration
   void              SetTradingHours(string hours_string);
   void              SetMaxSpread(double max_spread);
   void              EnableFilter(string filter_name, bool enable);
   
   // Méthodes d'accès aux statistiques
   double            GetAcceptanceRate();
   int               GetSignalsReceived() { return m_signals_received; }
   int               GetSignalsAccepted() { return m_signals_accepted; }
   int               GetSignalsRejected() { return m_signals_rejected; }
   
   // Méthodes utilitaires
   bool              IsInitialized() { return m_initialized; }
   void              PrintValidationReport();
   string            GetRejectionReason(int signal_type, string symbol);
};

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CSignalValidator::CSignalValidator()
{
   m_max_spread = 3.0;
   m_initialized = false;
   
   // Configuration par défaut des filtres
   m_check_trading_hours = true;
   m_check_spread = true;
   m_check_volatility = false;
   m_check_news_events = false;
   
   // Initialisation des statistiques
   m_signals_received = 0;
   m_signals_accepted = 0;
   m_signals_rejected = 0;
   
   m_rejected_hours = 0;
   m_rejected_spread = 0;
   m_rejected_volatility = 0;
   m_rejected_news = 0;
   
   // Heures de trading par défaut
   m_trading_hours.start_hour = 8;
   m_trading_hours.start_minute = 0;
   m_trading_hours.end_hour = 18;
   m_trading_hours.end_minute = 0;
   m_trading_hours.is_valid = true;
}

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CSignalValidator::~CSignalValidator()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CSignalValidator::Initialize(string trading_hours, double max_spread)
{
   if(max_spread <= 0 || max_spread > 100)
   {
      Print("ERREUR SignalValidator: Spread maximum invalide");
      return false;
   }
   
   m_max_spread = max_spread;
   
   // Configuration des heures de trading
   SetTradingHours(trading_hours);
   
   m_initialized = true;
   
   Print("SignalValidator initialisé - Heures: ", trading_hours, " | Max Spread: ", max_spread, " pips");
   
   return true;
}

//+------------------------------------------------------------------+
//| Désinitialisation                                               |
//+------------------------------------------------------------------+
void CSignalValidator::Deinitialize()
{
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Validation principale du signal                                 |
//+------------------------------------------------------------------+
bool CSignalValidator::ValidateSignal(int signal_type, string symbol)
{
   if(!m_initialized)
      return false;
   
   m_signals_received++;
   
   // Validation des conditions de marché
   if(!ValidateMarketConditions(symbol))
   {
      m_signals_rejected++;
      return false;
   }
   
   // Validation des heures de trading
   if(m_check_trading_hours && !IsWithinTradingHours(TimeCurrent()))
   {
      m_signals_rejected++;
      m_rejected_hours++;
      return false;
   }
   
   // Validation du spread
   if(m_check_spread && !IsSpreadAcceptable(symbol))
   {
      m_signals_rejected++;
      m_rejected_spread++;
      return false;
   }
   
   // Validation de la volatilité
   if(m_check_volatility && !IsVolatilityAcceptable(symbol))
   {
      m_signals_rejected++;
      m_rejected_volatility++;
      return false;
   }
   
   // Validation des événements news
   if(m_check_news_events && !IsNewsEventSafe(TimeCurrent()))
   {
      m_signals_rejected++;
      m_rejected_news++;
      return false;
   }
   
   m_signals_accepted++;
   return true;
}

//+------------------------------------------------------------------+
//| Validation des conditions de marché                            |
//+------------------------------------------------------------------+
bool CSignalValidator::ValidateMarketConditions(string symbol)
{
   // Vérification que le marché est ouvert
   if(!SymbolInfoInteger(symbol, SYMBOL_SELECT))
   {
      if(!SymbolSelect(symbol, true))
         return false;
   }
   
   // Vérification que le trading est autorisé
   ENUM_SYMBOL_TRADE_MODE trade_mode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
   if(trade_mode == SYMBOL_TRADE_MODE_DISABLED)
      return false;
   
   // Vérification des sessions de trading
   datetime current_time = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(current_time, dt);
   
   // Éviter les weekends
   if(dt.day_of_week == 0 || dt.day_of_week == 6)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Vérification des heures de trading                             |
//+------------------------------------------------------------------+
bool CSignalValidator::IsWithinTradingHours(datetime check_time)
{
   if(!m_trading_hours.is_valid)
      return true;
   
   MqlDateTime dt;
   TimeToStruct(check_time, dt);
   
   // Conversion en minutes depuis minuit
   int current_minutes = dt.hour * 60 + dt.min;
   int start_minutes = m_trading_hours.start_hour * 60 + m_trading_hours.start_minute;
   int end_minutes = m_trading_hours.end_hour * 60 + m_trading_hours.end_minute;
   
   // Gestion du cas où la session traverse minuit
   if(start_minutes <= end_minutes)
   {
      return (current_minutes >= start_minutes && current_minutes <= end_minutes);
   }
   else
   {
      return (current_minutes >= start_minutes || current_minutes <= end_minutes);
   }
}

//+------------------------------------------------------------------+
//| Vérification du spread                                         |
//+------------------------------------------------------------------+
bool CSignalValidator::IsSpreadAcceptable(string symbol)
{
   // Obtention du spread actuel
   long spread_points = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   // Conversion en pips
   double spread_pips;
   if(digits == 5 || digits == 3)
      spread_pips = spread_points / 10.0;
   else
      spread_pips = (double)spread_points;
   
   return (spread_pips <= m_max_spread);
}

//+------------------------------------------------------------------+
//| Vérification de la volatilité                                  |
//+------------------------------------------------------------------+
bool CSignalValidator::IsVolatilityAcceptable(string symbol)
{
   // Calcul simple de la volatilité basé sur l'ATR
   int atr_handle = iATR(symbol, PERIOD_CURRENT, 14);
   if(atr_handle == INVALID_HANDLE)
      return true; // Si pas d'ATR, on accepte
   
   double atr_buffer[1];
   if(CopyBuffer(atr_handle, 0, 0, 1, atr_buffer) != 1)
   {
      IndicatorRelease(atr_handle);
      return true;
   }
   
   IndicatorRelease(atr_handle);
   
   // Critères de volatilité (à adapter selon les besoins)
   double current_price = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(current_price <= 0)
      return true;
   
   double volatility_percent = (atr_buffer[0] / current_price) * 100.0;
   
   // Accepter si la volatilité est dans une fourchette raisonnable
   return (volatility_percent >= 0.1 && volatility_percent <= 5.0);
}

//+------------------------------------------------------------------+
//| Vérification des événements news                               |
//+------------------------------------------------------------------+
bool CSignalValidator::IsNewsEventSafe(datetime check_time)
{
   // Implémentation basique - peut être étendue avec un calendrier économique
   MqlDateTime dt;
   TimeToStruct(check_time, dt);
   
   // Éviter certaines heures critiques (exemple: 14:30 GMT pour les news US)
   if(dt.hour == 14 && dt.min >= 25 && dt.min <= 35)
      return false;
   
   // Éviter les heures de fermeture/ouverture des principales sessions
   if((dt.hour == 21 && dt.min >= 55) || (dt.hour == 22 && dt.min <= 5))
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Configuration des heures de trading                            |
//+------------------------------------------------------------------+
void CSignalValidator::SetTradingHours(string hours_string)
{
   m_trading_hours.is_valid = false;
   
   // Format attendu: "HH:MM-HH:MM" (exemple: "08:00-18:00")
   int separator_pos = StringFind(hours_string, "-");
   if(separator_pos < 0)
   {
      Print("ERREUR: Format d'heures invalide. Utilisez HH:MM-HH:MM");
      return;
   }
   
   string start_time = StringSubstr(hours_string, 0, separator_pos);
   string end_time = StringSubstr(hours_string, separator_pos + 1);
   
   // Parsing heure de début
   int colon_pos = StringFind(start_time, ":");
   if(colon_pos > 0)
   {
      m_trading_hours.start_hour = (int)StringToInteger(StringSubstr(start_time, 0, colon_pos));
      m_trading_hours.start_minute = (int)StringToInteger(StringSubstr(start_time, colon_pos + 1));
   }
   
   // Parsing heure de fin
   colon_pos = StringFind(end_time, ":");
   if(colon_pos > 0)
   {
      m_trading_hours.end_hour = (int)StringToInteger(StringSubstr(end_time, 0, colon_pos));
      m_trading_hours.end_minute = (int)StringToInteger(StringSubstr(end_time, colon_pos + 1));
   }
   
   // Validation
   if(m_trading_hours.start_hour >= 0 && m_trading_hours.start_hour <= 23 &&
      m_trading_hours.end_hour >= 0 && m_trading_hours.end_hour <= 23 &&
      m_trading_hours.start_minute >= 0 && m_trading_hours.start_minute <= 59 &&
      m_trading_hours.end_minute >= 0 && m_trading_hours.end_minute <= 59)
   {
      m_trading_hours.is_valid = true;
      Print("Heures de trading configurées: ", 
            StringFormat("%02d:%02d-%02d:%02d", 
                        m_trading_hours.start_hour, m_trading_hours.start_minute,
                        m_trading_hours.end_hour, m_trading_hours.end_minute));
   }
   else
   {
      Print("ERREUR: Heures de trading invalides");
   }
}

//+------------------------------------------------------------------+
//| Configuration du spread maximum                                |
//+------------------------------------------------------------------+
void CSignalValidator::SetMaxSpread(double max_spread)
{
   if(max_spread > 0 && max_spread <= 100)
   {
      m_max_spread = max_spread;
      Print("Spread maximum configuré: ", max_spread, " pips");
   }
   else
   {
      Print("ERREUR: Spread maximum invalide");
   }
}

//+------------------------------------------------------------------+
//| Activation/désactivation des filtres                           |
//+------------------------------------------------------------------+
void CSignalValidator::EnableFilter(string filter_name, bool enable)
{
   if(filter_name == "hours")
      m_check_trading_hours = enable;
   else if(filter_name == "spread")
      m_check_spread = enable;
   else if(filter_name == "volatility")
      m_check_volatility = enable;
   else if(filter_name == "news")
      m_check_news_events = enable;
   
   Print("Filtre ", filter_name, " ", (enable ? "activé" : "désactivé"));
}

//+------------------------------------------------------------------+
//| Calcul du taux d'acceptation                                   |
//+------------------------------------------------------------------+
double CSignalValidator::GetAcceptanceRate()
{
   if(m_signals_received == 0)
      return 0.0;
   
   return ((double)m_signals_accepted / (double)m_signals_received) * 100.0;
}

//+------------------------------------------------------------------+
//| Obtenir la raison du rejet                                     |
//+------------------------------------------------------------------+
string CSignalValidator::GetRejectionReason(int signal_type, string symbol)
{
   string reason = "";
   
   if(m_check_trading_hours && !IsWithinTradingHours(TimeCurrent()))
      reason += "Hors heures de trading; ";
   
   if(m_check_spread && !IsSpreadAcceptable(symbol))
      reason += "Spread trop élevé; ";
   
   if(m_check_volatility && !IsVolatilityAcceptable(symbol))
      reason += "Volatilité inadéquate; ";
   
   if(m_check_news_events && !IsNewsEventSafe(TimeCurrent()))
      reason += "Événement news proche; ";
   
   if(!ValidateMarketConditions(symbol))
      reason += "Conditions de marché défavorables; ";
   
   if(reason == "")
      reason = "Aucune raison spécifique";
   
   return reason;
}

//+------------------------------------------------------------------+
//| Imprimer rapport de validation                                 |
//+------------------------------------------------------------------+
void CSignalValidator::PrintValidationReport()
{
   Print("=== RAPPORT DE VALIDATION SIGNAUX ===");
   Print("Signaux reçus: ", m_signals_received);
   Print("Signaux acceptés: ", m_signals_accepted);
   Print("Signaux rejetés: ", m_signals_rejected);
   Print("Taux d'acceptation: ", DoubleToString(GetAcceptanceRate(), 2), "%");
   Print("");
   Print("Raisons de rejet:");
   Print("- Heures de trading: ", m_rejected_hours);
   Print("- Spread: ", m_rejected_spread);
   Print("- Volatilité: ", m_rejected_volatility);
   Print("- Événements news: ", m_rejected_news);
   Print("");
   Print("Configuration actuelle:");
   Print("- Vérification heures: ", (m_check_trading_hours ? "OUI" : "NON"));
   Print("- Vérification spread: ", (m_check_spread ? "OUI" : "NON"));
   Print("- Vérification volatilité: ", (m_check_volatility ? "OUI" : "NON"));
   Print("- Vérification news: ", (m_check_news_events ? "OUI" : "NON"));
   Print("- Spread maximum: ", m_max_spread, " pips");
   
   if(m_trading_hours.is_valid)
   {
      Print("- Heures de trading: ", 
            StringFormat("%02d:%02d-%02d:%02d", 
                        m_trading_hours.start_hour, m_trading_hours.start_minute,
                        m_trading_hours.end_hour, m_trading_hours.end_minute));
   }
   
   Print("=====================================");
}
