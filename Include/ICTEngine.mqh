//+------------------------------------------------------------------+
//| ICTEngine.mqh - Inner Circle Trader Concepts                     |
//| A2Sniper Ultimate v3.0                                           |
//| Judas Swing, Kill Zones, OTE, NY Reversal, London Manipulation   |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_ICT_MQH
#define A2SNIPER_ICT_MQH

#include "CommonTypes.mqh"
#include "SessionEngine.mqh"
#include "MarketStructureEngine.mqh"

//+------------------------------------------------------------------+
//| Classe CICTEngine                                                |
//+------------------------------------------------------------------+
class CICTEngine
  {
private:
   bool              m_initialized;

   //--- Références
   CSessionEngine         *m_session_engine;
   CMarketStructureEngine *m_market_structure;

   //--- Paramètres
   double            m_ote_lower;             // OTE zone lower (61.8% Fib)
   double            m_ote_upper;             // OTE zone upper (78.6% Fib)
   int               m_swing_period;          // Période pour calcul swing

   //--- État ICT
   bool              m_judas_swing_detected;
   bool              m_kill_zone_active;
   bool              m_ote_zone_bullish;
   bool              m_ote_zone_bearish;
   double            m_fib_618_level;         // Niveau Fibonacci 61.8%
   double            m_fib_786_level;         // Niveau Fibonacci 78.6%
   double            m_equilibrium;            // Equilibrium (midpoint swing_high/swing_low)

   //--- Méthodes privées
   void              CalculateFibonacciLevels();
   bool              DetectJudasSwing();
   bool              CheckOTEZone();

public:
   //--- Constructeur / Destructeur
                     CICTEngine();
                    ~CICTEngine();

   //--- Initialisation
   bool              Initialize(CSessionEngine *se, CMarketStructureEngine *mse);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   bool              IsJudasSwingDetected() const { return m_judas_swing_detected; }
   bool              IsKillZoneActive() const { return m_kill_zone_active; }
   bool              IsOTEZoneBullish() const { return m_ote_zone_bullish; }
   bool              IsOTEZoneBearish() const { return m_ote_zone_bearish; }
   double            GetFib618Level() const { return m_fib_618_level; }
   double            GetFib786Level() const { return m_fib_786_level; }

   //--- Vérifications ICT
   bool              HasICTConfirmation(const ENUM_SIGNAL_TYPE direction) const;
   double            GetICTScore(const ENUM_SIGNAL_TYPE direction) const;
   bool              IsOptimalTradeEntry(const ENUM_SIGNAL_TYPE direction) const;

   //--- Info
   string            GetICTInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CICTEngine::CICTEngine() :
   m_initialized(false),
   m_session_engine(NULL),
   m_market_structure(NULL),
   m_ote_lower(0.618),
   m_ote_upper(0.786),
   m_swing_period(20),
   m_judas_swing_detected(false),
   m_kill_zone_active(false),
   m_ote_zone_bullish(false),
   m_ote_zone_bearish(false),
   m_fib_618_level(0),
   m_fib_786_level(0),
   m_equilibrium(0)
  {
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CICTEngine::~CICTEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CICTEngine::Initialize(CSessionEngine *se, CMarketStructureEngine *mse)
  {
   if(se == NULL || mse == NULL)
     {
      Print("A2Sniper ICT: Erreur - moteurs dépendants NULL");
      return false;
     }

   m_session_engine = se;
   m_market_structure = mse;

   m_initialized = true;
   Print("A2Sniper ICT: ICT Engine initialisé");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CICTEngine::Deinitialize()
  {
   m_session_engine = NULL;
   m_market_structure = NULL;
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Calculer les niveaux Fibonacci                                   |
//+------------------------------------------------------------------+
void CICTEngine::CalculateFibonacciLevels()
  {
   //--- Obtenir le swing high et swing low récents
   double swing_high = 0;
   double swing_low = DBL_MAX;

   for(int i = 1; i < m_swing_period; i++)
     {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      double l = iLow(_Symbol, PERIOD_CURRENT, i);
      if(h > swing_high) swing_high = h;
      if(l < swing_low && l > 0) swing_low = l;
     }

   if(swing_high <= swing_low)
      return;

   double range = swing_high - swing_low;

   //--- Equilibrium = midpoint
   m_equilibrium = (swing_high + swing_low) / 2.0;

   //--- Niveaux Fibonacci (depuis le bas)
   m_fib_618_level = swing_low + range * m_ote_lower;
   m_fib_786_level = swing_low + range * m_ote_upper;
  }

//+------------------------------------------------------------------+
//| Détection du Judas Swing                                         |
//| Faux mouvement au début de la session Londres                    |
//+------------------------------------------------------------------+
bool CICTEngine::DetectJudasSwing()
  {
   if(m_session_engine == NULL)
      return false;

   //--- Le Judas Swing se produit pendant les 2 premières heures de Londres
   if(!m_session_engine->IsJudasSwingTime())
     {
      m_judas_swing_detected = false;
      return false;
     }

   //--- Détecter un faux mouvement: le prix monte puis descend (ou inverse)
   //--- Sur les dernières bougies de la session
   double open_london = iOpen(_Symbol, PERIOD_CURRENT, 0); // Approximation
   double current = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- Le Judas Swing est détecté si le prix a fait un mouvement dans une direction
   //--- puis a commencé à se retourner
   //--- On vérifie les 3 dernières bougies
   double h1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double h2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
   double h3 = iHigh(_Symbol, PERIOD_CURRENT, 3);
   double l1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double l2 = iLow(_Symbol, PERIOD_CURRENT, 2);
   double l3 = iLow(_Symbol, PERIOD_CURRENT, 3);

   //--- Judas Swing haussier: faux mouvement haussier puis retournement baissier
   bool bullish_then_reversal = (h2 > h3 && current < h2);
   bool bearish_then_reversal = (l2 < l3 && current > l2);

   m_judas_swing_detected = (bullish_then_reversal || bearish_then_reversal);
   return m_judas_swing_detected;
  }

//+------------------------------------------------------------------+
//| Vérifier la zone OTE (Optimal Trade Entry)                       |
//+------------------------------------------------------------------+
bool CICTEngine::CheckOTEZone()
  {
   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- Bullish OTE: price in discount zone (below equilibrium) and within Fib zone
   m_ote_zone_bullish = (current_price >= m_fib_618_level && current_price <= m_fib_786_level && current_price < m_equilibrium);
   //--- Bearish OTE: price in premium zone (above equilibrium) and within Fib zone
   m_ote_zone_bearish = (current_price >= m_fib_618_level && current_price <= m_fib_786_level && current_price > m_equilibrium);

   return m_ote_zone_bullish || m_ote_zone_bearish;
  }

//+------------------------------------------------------------------+
//| Mise à jour                                                      |
//+------------------------------------------------------------------+
bool CICTEngine::Update()
  {
   if(!m_initialized)
      return false;

   //--- Kill Zone active ?
   m_kill_zone_active = (m_session_engine != NULL) ? m_session_engine->IsKillZone() : false;

   //--- Calculer Fibonacci
   CalculateFibonacciLevels();

   //--- Détection Judas Swing
   DetectJudasSwing();

   //--- Vérification OTE
   CheckOTEZone();

   return true;
  }

//+------------------------------------------------------------------+
//| Confirmation ICT pour une direction                               |
//+------------------------------------------------------------------+
bool CICTEngine::HasICTConfirmation(const ENUM_SIGNAL_TYPE direction) const
  {
   int confirmations = 0;

   //--- Kill Zone active
   if(m_kill_zone_active)
      confirmations++;

   //--- OTE Zone
   if(direction == SIGNAL_BUY && m_ote_zone_bullish)
      confirmations++;
   if(direction == SIGNAL_SELL && m_ote_zone_bearish)
      confirmations++;

   //--- Judas Swing détecté
   if(m_judas_swing_detected)
      confirmations++;

   //--- NY Reversal Time
   if(m_session_engine != NULL && m_session_engine->IsNYReversalTime())
      confirmations++;

   return (confirmations >= 2);
  }

//+------------------------------------------------------------------+
//| Score ICT (0-100)                                                |
//+------------------------------------------------------------------+
double CICTEngine::GetICTScore(const ENUM_SIGNAL_TYPE direction) const
  {
   double score = 0;

   //--- Kill Zone (30 pts)
   if(m_kill_zone_active)
      score += 30;

   //--- OTE Zone (30 pts)
   if(IsOptimalTradeEntry(direction))
      score += 30;

   //--- Judas Swing (20 pts)
   if(m_judas_swing_detected)
      score += 20;

   //--- Session optimale (20 pts)
   if(m_session_engine != NULL && m_session_engine->IsOptimalTradingTime())
      score += 20;

   return MathMin(score, 100.0);
  }

//+------------------------------------------------------------------+
//| Optimal Trade Entry ?                                            |
//+------------------------------------------------------------------+
bool CICTEngine::IsOptimalTradeEntry(const ENUM_SIGNAL_TYPE direction) const
  {
   if(direction == SIGNAL_BUY) return m_ote_zone_bullish;
   if(direction == SIGNAL_SELL) return m_ote_zone_bearish;
   return false;
  }

//+------------------------------------------------------------------+
//| Info ICT                                                         |
//+------------------------------------------------------------------+
string CICTEngine::GetICTInfo() const
  {
   return StringFormat("ICT: KZ=%s Judas=%s OTE_Bull=%s OTE_Bear=%s Fib61.8=%.5f Fib78.6=%.5f",
                       m_kill_zone_active ? "Y" : "N",
                       m_judas_swing_detected ? "Y" : "N",
                       m_ote_zone_bullish ? "Y" : "N",
                       m_ote_zone_bearish ? "Y" : "N",
                       m_fib_618_level, m_fib_786_level);
  }

#endif // A2SNIPER_ICT_MQH
//+------------------------------------------------------------------+
