//+------------------------------------------------------------------+
//| SessionEngine.mqh - Gestion des Sessions de Trading              |
//| A2Sniper Ultimate v3.0                                           |
//| Sessions: Asian, London, New York, Overlap LN                    |
//| Kill Zones ICT, Priorités de session                             |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_SESSION_MQH
#define A2SNIPER_SESSION_MQH

#include <A2Sniper\CommonTypes.mqh>

//+------------------------------------------------------------------+
//| Classe CSessionEngine                                            |
//+------------------------------------------------------------------+
class CSessionEngine
  {
private:
   bool              m_initialized;
   int               m_gmt_offset;           // Décalage GMT du broker

   //--- Heures de session (en heures UTC)
   int               m_asian_start;          // Début session asiatique
   int               m_asian_end;            // Fin session asiatique
   int               m_london_start;         // Début session Londres
   int               m_london_end;           // Fin session Londres
   int               m_ny_start;             // Début session New York
   int               m_ny_end;               // Fin session New York

   //--- Kill Zones (fenêtres à haute probabilité)
   int               m_kz_london_start;      // Kill Zone Londres début
   int               m_kz_london_end;        // Kill Zone Londres fin
   int               m_kz_ny_start;          // Kill Zone NY début
   int               m_kz_ny_end;            // Kill Zone NY fin

   //--- État actuel
   SSessionInfo      m_current_session;

   //--- Méthodes privées
   int               GetCurrentHourUTC() const;
   bool              IsTimeInRange(const int hour, const int start, const int end) const;

public:
   //--- Constructeur / Destructeur
                     CSessionEngine();
                    ~CSessionEngine();

   //--- Initialisation
   bool              Initialize(int gmt_offset = 0);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   SSessionInfo      GetCurrentSession() const { return m_current_session; }
   ENUM_TRADING_SESSION GetActiveSession() const { return m_current_session.active_session; }
   ENUM_SESSION_PRIORITY GetPriority() const { return m_current_session.priority; }
   bool              IsLondonSession() const { return m_current_session.is_london; }
   bool              IsNewYorkSession() const { return m_current_session.is_newyork; }
   bool              IsAsianSession() const { return m_current_session.is_asian; }
   bool              IsOverlapLN() const { return m_current_session.is_overlap; }
   bool              IsKillZone() const { return m_current_session.is_killzone; }

   //--- Vérifications avancées
   bool              IsOptimalTradingTime() const;
   bool              IsJudasSwingTime() const;
   bool              IsLondonManipulation() const;
   bool              IsNYReversalTime() const;
   string            GetSessionName() const;
   string            GetSessionInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CSessionEngine::CSessionEngine() :
   m_initialized(false),
   m_gmt_offset(0),
   m_asian_start(0),
   m_asian_end(9),
   m_london_start(7),
   m_london_end(16),
   m_ny_start(13),
   m_ny_end(22),
   m_kz_london_start(7),
   m_kz_london_end(10),
   m_kz_ny_start(13),
   m_kz_ny_end(16)
  {
   ZeroMemory(m_current_session);
   m_current_session.active_session = SESSION_NONE;
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CSessionEngine::~CSessionEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CSessionEngine::Initialize(int gmt_offset)
  {
   m_gmt_offset = gmt_offset;
   m_initialized = true;
   Print("A2Sniper SE: Session Engine initialisé (GMT offset: ", m_gmt_offset, ")");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CSessionEngine::Deinitialize()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Obtenir l'heure UTC actuelle                                     |
//+------------------------------------------------------------------+
int CSessionEngine::GetCurrentHourUTC() const
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   //--- Ajuster selon le décalage GMT du broker
   int utc_hour = dt.hour - m_gmt_offset;
   if(utc_hour < 0) utc_hour += 24;
   if(utc_hour >= 24) utc_hour -= 24;
   return utc_hour;
  }

//+------------------------------------------------------------------+
//| Vérifier si l'heure est dans un intervalle                       |
//+------------------------------------------------------------------+
bool CSessionEngine::IsTimeInRange(const int hour, const int start, const int end) const
  {
   if(start <= end)
      return (hour >= start && hour < end);
   else // Interval qui passe minuit
      return (hour >= start || hour < end);
  }

//+------------------------------------------------------------------+
//| Mise à jour                                                      |
//+------------------------------------------------------------------+
bool CSessionEngine::Update()
  {
   if(!m_initialized)
      return false;

   int utc_hour = GetCurrentHourUTC();

   //--- Déterminer la session active
   m_current_session.hour_utc = utc_hour;
   m_current_session.is_london = IsTimeInRange(utc_hour, m_london_start, m_london_end);
   m_current_session.is_newyork = IsTimeInRange(utc_hour, m_ny_start, m_ny_end);
   m_current_session.is_asian = IsTimeInRange(utc_hour, m_asian_start, m_asian_end);
   m_current_session.is_overlap = m_current_session.is_london && m_current_session.is_newyork;

   //--- Kill Zone
   m_current_session.is_killzone = IsTimeInRange(utc_hour, m_kz_london_start, m_kz_london_end) ||
                                    IsTimeInRange(utc_hour, m_kz_ny_start, m_kz_ny_end);

   //--- Session active (par priorité)
   if(m_current_session.is_overlap)
     {
      m_current_session.active_session = SESSION_OVERLAP_LN;
      m_current_session.priority = SESSION_PRIORITY_HIGH;
     }
   else if(m_current_session.is_london)
     {
      m_current_session.active_session = SESSION_LONDON;
      m_current_session.priority = SESSION_PRIORITY_HIGH;
     }
   else if(m_current_session.is_newyork)
     {
      m_current_session.active_session = SESSION_NEWYORK;
      m_current_session.priority = SESSION_PRIORITY_MEDIUM;
     }
   else if(m_current_session.is_asian)
     {
      m_current_session.active_session = SESSION_ASIAN;
      m_current_session.priority = SESSION_PRIORITY_LOW;
     }
   else
     {
      m_current_session.active_session = SESSION_NONE;
      m_current_session.priority = SESSION_PRIORITY_LOW;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Heure optimale de trading ?                                      |
//+------------------------------------------------------------------+
bool CSessionEngine::IsOptimalTradingTime() const
  {
   //--- Kill Zones = meilleur moment
   if(m_current_session.is_killzone)
      return true;
   //--- Overlap London-NY
   if(m_current_session.is_overlap)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Heure du Judas Swing ICT ?                                       |
//+------------------------------------------------------------------+
bool CSessionEngine::IsJudasSwingTime() const
  {
   //--- Judas Swing: faux mouvement au début de Londres (07:00-09:00 UTC)
   return IsTimeInRange(m_current_session.hour_utc, 7, 9) && m_current_session.is_london;
  }

//+------------------------------------------------------------------+
//| London Manipulation ?                                            |
//+------------------------------------------------------------------+
bool CSessionEngine::IsLondonManipulation() const
  {
   //--- Manipulation de Londres: 07:00-09:00 UTC
   return IsTimeInRange(m_current_session.hour_utc, 7, 9);
  }

//+------------------------------------------------------------------+
//| NY Reversal Time ?                                               |
//+------------------------------------------------------------------+
bool CSessionEngine::IsNYReversalTime() const
  {
   //--- NY Reversal: 13:00-15:00 UTC (ouverture NY + overlap)
   return IsTimeInRange(m_current_session.hour_utc, 13, 15);
  }

//+------------------------------------------------------------------+
//| Nom de la session                                                |
//+------------------------------------------------------------------+
string CSessionEngine::GetSessionName() const
  {
   switch(m_current_session.active_session)
     {
      case SESSION_ASIAN:     return "Asian";
      case SESSION_LONDON:    return "London";
      case SESSION_NEWYORK:   return "New York";
      case SESSION_OVERLAP_LN: return "London-NY Overlap";
      default:                return "Off-Session";
     }
  }

//+------------------------------------------------------------------+
//| Info session                                                     |
//+------------------------------------------------------------------+
string CSessionEngine::GetSessionInfo() const
  {
   return StringFormat("Session: %s | UTC=%d | KZ=%s | Priority=%d | Optimal=%s",
                       GetSessionName(), m_current_session.hour_utc,
                       m_current_session.is_killzone ? "Y" : "N",
                       m_current_session.priority,
                       IsOptimalTradingTime() ? "Y" : "N");
  }

#endif // A2SNIPER_SESSION_MQH
//+------------------------------------------------------------------+
