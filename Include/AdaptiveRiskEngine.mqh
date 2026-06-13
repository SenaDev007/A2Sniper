//+------------------------------------------------------------------+
//| AdaptiveRiskEngine.mqh - Risk Management Adaptatif               |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| Adapts risk based on: market regime, win/loss streaks,           |
//| time of day, volatility, correlation, and account health         |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_ADAPTIVE_RISK_ENGINE_MQH
#define A2SNIPER_ADAPTIVE_RISK_ENGINE_MQH

#include <A2Sniper\CommonTypes.mqh>
#include <A2Sniper\VolatilityEngine.mqh>
#include <A2Sniper\SessionEngine.mqh>

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
  {
   REGIME_TRENDING_STRONG = 1,    // Tendance forte
   REGIME_TRENDING_NORMAL = 2,    // Tendance normale
   REGIME_RANGING = 3,            // Range/consolidation
   REGIME_VOLATILE = 4,           // Marche volatil
   REGIME_CHOPPY = 5              // Marche irregulier
  };

enum ENUM_RISK_MODE
  {
   RISK_MODE_AGGRESSIVE = 1,      // 150% du risque de base
   RISK_MODE_NORMAL = 2,          // 100% du risque de base
   RISK_MODE_CONSERVATIVE = 3,    // 50% du risque de base
   RISK_MODE_DEFENSIVE = 4,       // 25% du risque de base
   RISK_MODE_LOCKDOWN = 5         // 0% - pas de trading
  };

//+------------------------------------------------------------------+
//| Structure du regime de marche                                    |
//+------------------------------------------------------------------+
struct SMarketRegime
  {
   ENUM_MARKET_REGIME regime;           // Regime actuel
   double             trend_strength;   // Force de la tendance (0-100)
   double             volatility_level; // Niveau de volatilite (0-100)
   double             regime_score;     // Score de confiance (0-100)
   bool               is_tradeable;     // Marche tradeable
   string             description;      // Description
  };

//+------------------------------------------------------------------+
//| Structure des metriques de risque                                |
//+------------------------------------------------------------------+
struct SRiskMetrics
  {
   double             base_risk_pct;           // Risque de base (%)
   double             effective_risk_pct;      // Risque effectif (%)
   double             regime_adjustment;       // Ajustement regime (-50% a +50%)
   double             streak_adjustment;       // Ajustement streak (-75% a +0%)
   double             volatility_adjustment;   // Ajustement volatilite (-50% a +0%)
   double             session_adjustment;      // Ajustement session (-30% a +0%)
   double             correlation_adjustment;  // Ajustement correlation (-50% a +0%)
   double             daily_dd_pct;            // DD journalier (%)
   double             weekly_dd_pct;           // DD hebdomadaire (%)
   double             monthly_dd_pct;          // DD mensuel (%)
   double             exposure_pct;            // Exposition (%)
   ENUM_RISK_MODE     risk_mode;               // Mode de risque
   SMarketRegime      market_regime;           // Regime de marche
   bool               can_trade;               // Peut trader
   string             reason;                  // Raison si ne peut pas trader
  };

//+------------------------------------------------------------------+
//| Classe CAdaptiveRiskEngine                                       |
//+------------------------------------------------------------------+
class CAdaptiveRiskEngine
  {
private:
   bool                   m_initialized;
   CVolatilityEngine     *m_volatility;
   CSessionEngine        *m_session;

   //--- Parametres de base
   double                 m_base_risk_pct;          // Risque de base (%)
   double                 m_max_daily_dd;           // DD journalier max (%)
   double                 m_max_weekly_dd;          // DD hebdomadaire max (%)
   double                 m_max_monthly_dd;         // DD mensuel max (%)
   int                    m_max_positions;          // Positions max
   int                    m_max_daily_trades;       // Trades/jour max
   double                 m_max_exposure_pct;       // Exposition max (%)
   ulong                  m_magic_number;

   //--- Suivi du drawdown
   double                 m_start_day_equity;
   double                 m_start_week_equity;
   double                 m_start_month_equity;
   double                 m_peak_day_equity;
   double                 m_peak_week_equity;
   double                 m_peak_month_equity;
   datetime               m_last_day_check;
   datetime               m_last_week_check;

   //--- Streaks et adaptation
   int                    m_consecutive_wins;
   int                    m_consecutive_losses;
   int                    m_daily_trade_count;
   datetime               m_daily_trade_reset;

   //--- Etat
   bool                   m_trading_suspended;
   string                 m_suspension_reason;
   datetime               m_suspension_start_time;

   //--- Metriques actuelles
   SRiskMetrics           m_metrics;

   //--- Methodes de calcul adaptatif
   double                 CalculateRegimeAdjustment() const;
   double                 CalculateStreakAdjustment() const;
   double                 CalculateVolatilityAdjustment() const;
   double                 CalculateSessionAdjustment() const;
   double                 CalculateCorrelationAdjustment() const;
   ENUM_RISK_MODE         DetermineRiskMode() const;
   SMarketRegime          DetectMarketRegime() const;

   //--- Methodes de suivi
   void                   UpdateEquityReferences();
   void                   CheckDrawdownLimits();
   void                   CheckDailyTradeReset();

public:
   //--- Constructeur / Destructeur
                          CAdaptiveRiskEngine();
                         ~CAdaptiveRiskEngine();

   //--- Initialisation
   bool                   Initialize(double base_risk = DEFAULT_RISK_PERCENT,
                                      double daily_dd = DEFAULT_DAILY_DD,
                                      double weekly_dd = DEFAULT_WEEKLY_DD,
                                      double monthly_dd = DEFAULT_MONTHLY_DD,
                                      int max_positions = MAX_OPEN_POSITIONS,
                                      int max_daily_trades = MAX_DAILY_TRADES,
                                      ulong magic = A2SNIPER_MAGIC);
   void                   Deinitialize();

   //--- Mise a jour
   bool                   Update();

   //--- Calcul du lot adaptatif
   double                 CalculateAdaptiveLotSize(double sl_distance_pips) const;
   double                 CalculateLotSize(double sl_distance_pips) const;

   //--- Verifications
   bool                   CanOpenTrade(ENUM_SIGNAL_TYPE direction) const;
   bool                   HasEnoughMargin(double lot) const;

   //--- Enregistrement
   void                   RecordTradeResult(bool is_win, double profit = 0);
   void                   RecordTradeOpened();

   //--- Accesseurs
   double                 GetEffectiveRiskPercent() const;
   double                 GetDailyDrawdownPct() const;
   double                 GetWeeklyDrawdownPct() const;
   double                 GetMonthlyDrawdownPct() const;
   double                 GetCurrentExposure() const;
   int                    GetDailyTradeCount() const;
   bool                   IsTradingSuspended() const { return m_trading_suspended; }
   string                 GetSuspensionReason() const { return m_suspension_reason; }
   int                    GetMaxPositions() const { return m_max_positions; }
   SMarketRegime          GetMarketRegime() const;
   SRiskMetrics           GetRiskMetrics() const;

   //--- Info
   string                 GetAdaptiveRiskInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CAdaptiveRiskEngine::CAdaptiveRiskEngine() :
   m_initialized(false),
   m_volatility(NULL),
   m_session(NULL),
   m_base_risk_pct(DEFAULT_RISK_PERCENT),
   m_max_daily_dd(DEFAULT_DAILY_DD),
   m_max_weekly_dd(DEFAULT_WEEKLY_DD),
   m_max_monthly_dd(DEFAULT_MONTHLY_DD),
   m_max_positions(MAX_OPEN_POSITIONS),
   m_max_daily_trades(MAX_DAILY_TRADES),
   m_max_exposure_pct(MAX_EXPOSURE_PERCENT),
   m_magic_number(A2SNIPER_MAGIC),
   m_start_day_equity(0),
   m_start_week_equity(0),
   m_start_month_equity(0),
   m_peak_day_equity(0),
   m_peak_week_equity(0),
   m_peak_month_equity(0),
   m_last_day_check(0),
   m_last_week_check(0),
   m_consecutive_wins(0),
   m_consecutive_losses(0),
   m_daily_trade_count(0),
   m_daily_trade_reset(0),
   m_trading_suspended(false),
   m_suspension_start_time(0)
  {
   ZeroMemory(m_metrics);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CAdaptiveRiskEngine::~CAdaptiveRiskEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CAdaptiveRiskEngine::Initialize(double base_risk, double daily_dd, double weekly_dd,
                                       double monthly_dd, int max_positions,
                                       int max_daily_trades, ulong magic)
  {
   m_base_risk_pct = (base_risk > 0 && base_risk <= 5.0) ? base_risk : DEFAULT_RISK_PERCENT;

   //--- FIX v4.2: Adaptive risk for small accounts (200-500 USD)
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > 0 && equity < 500.0)
     {
      //--- Scale down risk proportionally for small accounts
      //--- 200 USD -> 0.4% max, 300 USD -> 0.6%, 500 USD -> 1.0%
      double adaptive_risk = MathMax(0.3, (equity / 500.0) * m_base_risk_pct);
      m_base_risk_pct = MathMin(m_base_risk_pct, adaptive_risk);
      Print("A2Sniper ARE: Small account detected (", DoubleToString(equity, 0),
            " USD) - Risk adjusted to ", DoubleToString(m_base_risk_pct, 1), "%");
     }

   m_max_daily_dd = (daily_dd > 0 && daily_dd <= 20.0) ? daily_dd : DEFAULT_DAILY_DD;
   m_max_weekly_dd = (weekly_dd > daily_dd && weekly_dd <= 30.0) ? weekly_dd : DEFAULT_WEEKLY_DD;
   m_max_monthly_dd = (monthly_dd > weekly_dd && monthly_dd <= 50.0) ? monthly_dd : DEFAULT_MONTHLY_DD;
   m_max_positions = (max_positions > 0) ? max_positions : MAX_OPEN_POSITIONS;
   m_max_daily_trades = (max_daily_trades > 0) ? max_daily_trades : MAX_DAILY_TRADES;
   m_magic_number = (magic > 0) ? magic : A2SNIPER_MAGIC;

   //--- FIX v4.2: Limit positions for small accounts
   if(equity > 0 && equity < 300.0)
     {
      m_max_positions = MathMin(m_max_positions, 2);    // Max 2 positions for <300 USD
      m_max_daily_trades = MathMin(m_max_daily_trades, 3); // Max 3 trades/day for <300 USD
      Print("A2Sniper ARE: Small account limits - MaxPos=", m_max_positions,
            " MaxTrades=", m_max_daily_trades);
     }
   else if(equity > 0 && equity < 500.0)
     {
      m_max_positions = MathMin(m_max_positions, 3);    // Max 3 positions for <500 USD
      m_max_daily_trades = MathMin(m_max_daily_trades, 4); // Max 4 trades/day for <500 USD
     }

   double init_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(init_equity <= 0) init_equity = AccountInfoDouble(ACCOUNT_BALANCE);
   m_start_day_equity = init_equity;
   m_start_week_equity = init_equity;
   m_start_month_equity = init_equity;
   m_peak_day_equity = init_equity;
   m_peak_week_equity = init_equity;
   m_peak_month_equity = init_equity;
   m_last_day_check = TimeCurrent();
   m_last_week_check = TimeCurrent();
   m_daily_trade_reset = TimeCurrent();

   m_initialized = true;
   Print("A2Sniper ARE: Adaptive Risk Engine initialise (BaseRisk=", m_base_risk_pct,
         "%, DD=", m_max_daily_dd, "/", m_max_weekly_dd, "/", m_max_monthly_dd,
         "%, MaxTrades/Day=", m_max_daily_trades, ")");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CAdaptiveRiskEngine::Deinitialize()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Calculer l'ajustement du regime de marche                        |
//| Tendance forte = risque normal a leger                           |
//| Range = risque reduit                                            |
//| Volatile = risque tres reduit                                    |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::CalculateRegimeAdjustment() const
  {
   SMarketRegime regime = DetectMarketRegime();

   switch(regime.regime)
     {
      case REGIME_TRENDING_STRONG:  return 1.0;    // Risque normal (tendance forte = bonne opportunite)
      case REGIME_TRENDING_NORMAL:  return 0.85;   // Legere reduction
      case REGIME_RANGING:          return 0.5;     // Reduction significative (range = dangereux)
      case REGIME_VOLATILE:         return 0.35;    // Forte reduction (volatil = imprvisible)
      case REGIME_CHOPPY:           return 0.15;    // Tres forte reduction (choppy = eviter)
      default:                      return 0.75;
     }
  }

//+------------------------------------------------------------------+
//| Calculer l'ajustement des streaks                                |
//| Apres pertes consecutives: reduire le risque progressivement     |
//| Apres gains consecutifs: rester prudent (ne pas augmenter)       |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::CalculateStreakAdjustment() const
  {
   if(m_consecutive_losses >= 5) return 0.15;   // 85% de reduction - presque arret
   if(m_consecutive_losses >= 4) return 0.25;   // 75% de reduction
   if(m_consecutive_losses >= 3) return 0.40;   // 60% de reduction
   if(m_consecutive_losses >= 2) return 0.65;   // 35% de reduction
   if(m_consecutive_losses >= 1) return 0.80;   // 20% de reduction

   //--- Apres gains: rester prudent
   if(m_consecutive_wins >= 5) return 0.90;     // Legere reduction (eviter l'euphorie)
   if(m_consecutive_wins >= 3) return 0.95;     // Tres legere reduction

   return 1.0;  // Pas d'ajustement
  }

//+------------------------------------------------------------------+
//| Calculer l'ajustement de volatilite                              |
//| Haute volatilite = risque reduit (stops plus larges)             |
//| Basse volatilite = risque normal                                 |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::CalculateVolatilityAdjustment() const
  {
   if(m_volatility == NULL) return 0.85;

   double vol_pct = 0;
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = m_volatility.GetCurrentATR();

   if(current_price > 0 && atr > 0)
      vol_pct = (atr / current_price) * 100.0;

   if(vol_pct > 2.0)   return 0.4;     // Tres haute volatilite
   if(vol_pct > 1.5)   return 0.55;    // Haute volatilite
   if(vol_pct > 1.0)   return 0.75;    // Volatilite elevee
   if(vol_pct > 0.5)   return 0.90;    // Volatilite normale
   return 1.0;                          // Basse volatilite
  }

//+------------------------------------------------------------------+
//| Calculer l'ajustement de session                                 |
//| Kill Zones = risque normal                                       |
//| Hors session = risque reduit                                     |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::CalculateSessionAdjustment() const
  {
   if(m_session == NULL) return 0.85;

   if(m_session.IsKillZone()) return 1.0;

   ENUM_TRADING_SESSION session = m_session.GetActiveSession();
   if(session == SESSION_OVERLAP_LN) return 1.0;
   if(session == SESSION_LONDON) return 0.95;
   if(session == SESSION_NEWYORK) return 0.90;
   if(session == SESSION_ASIAN) return 0.60;     // Asie = risque reduit

   return 0.40;  // Hors session = risque tres reduit
  }

//+------------------------------------------------------------------+
//| Calculer l'ajustement de correlation                             |
//| Si positions deja correlees = risque reduit                      |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::CalculateCorrelationAdjustment() const
  {
   double exposure = GetCurrentExposure();
   if(exposure >= m_max_exposure_pct * 0.8) return 0.3;   // Trop expose
   if(exposure >= m_max_exposure_pct * 0.5) return 0.6;   // Moyennement expose
   if(exposure >= m_max_exposure_pct * 0.3) return 0.8;   // Faiblement expose
   return 1.0;                                              // Pas d'exposition
  }

//+------------------------------------------------------------------+
//| Detecter le regime de marche                                     |
//+------------------------------------------------------------------+
SMarketRegime CAdaptiveRiskEngine::DetectMarketRegime() const
  {
   SMarketRegime regime;
   regime.regime = REGIME_RANGING;
   regime.trend_strength = 0;
   regime.volatility_level = 0;
   regime.regime_score = 0;
   regime.is_tradeable = true;
   regime.description = "";

   //--- Analyser la structure des bougies recentes
   double atr = 0;
   if(m_volatility != NULL)
      atr = m_volatility.GetCurrentATR();

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(current_price <= 0) return regime;

   //--- Calculer la tendance sur les dernieres bougies
   int trend_bars = 20;
   double price_change = 0;
   double total_range = 0;
   int directional_bars = 0;

   for(int i = trend_bars; i >= 1; i--)
     {
      double close_i = iClose(_Symbol, PERIOD_CURRENT, i);
      double close_prev = iClose(_Symbol, PERIOD_CURRENT, i + 1);
      double high_i = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low_i = iLow(_Symbol, PERIOD_CURRENT, i);

      price_change += (close_i - close_prev);
      total_range += (high_i - low_i);

      if((close_i > close_prev)) directional_bars++;
     }

   //--- Force de la tendance
   if(total_range > 0)
      regime.trend_strength = MathAbs(price_change) / total_range * 100.0;
   else
      regime.trend_strength = 0;

   //--- Niveau de volatilite
   if(atr > 0 && current_price > 0)
      regime.volatility_level = (atr / current_price) * 100.0 * 10;  // Normalise

   //--- Direction des barres
   double direction_ratio = (double)directional_bars / trend_bars;

   //--- Determiner le regime
   if(regime.trend_strength >= 60 && direction_ratio >= 0.7)
     {
      regime.regime = REGIME_TRENDING_STRONG;
      regime.description = "Tendance forte - Risque normal";
     }
   else if(regime.trend_strength >= 30 && direction_ratio >= 0.55)
     {
      regime.regime = REGIME_TRENDING_NORMAL;
      regime.description = "Tendance normale - Risque legerement reduit";
     }
   else if(regime.volatility_level >= 3.0)
     {
      regime.regime = REGIME_VOLATILE;
      regime.description = "Marche volatil - Risque fortement reduit";
     }
   else if(regime.volatility_level >= 2.0 && regime.trend_strength < 20)
     {
      regime.regime = REGIME_CHOPPY;
      regime.description = "Marche irregulier - Risque tres reduit";
     }
   else
     {
      regime.regime = REGIME_RANGING;
      regime.description = "Range/Consolidation - Risque reduit";
     }

   //--- Score de confiance
   regime.regime_score = MathMin(100, regime.trend_strength + direction_ratio * 50);
   regime.is_tradeable = (regime.regime != REGIME_CHOPPY);

   return regime;
  }

//+------------------------------------------------------------------+
//| Determiner le mode de risque                                     |
//+------------------------------------------------------------------+
ENUM_RISK_MODE CAdaptiveRiskEngine::DetermineRiskMode() const
  {
   double effective_risk = GetEffectiveRiskPercent();
   double ratio = effective_risk / m_base_risk_pct;

   if(ratio <= 0) return RISK_MODE_LOCKDOWN;
   if(ratio <= 0.25) return RISK_MODE_DEFENSIVE;
   if(ratio <= 0.60) return RISK_MODE_CONSERVATIVE;
   if(ratio <= 1.10) return RISK_MODE_NORMAL;
   return RISK_MODE_AGGRESSIVE;
  }

//+------------------------------------------------------------------+
//| Mettre a jour les references d'equity                            |
//+------------------------------------------------------------------+
void CAdaptiveRiskEngine::UpdateEquityReferences()
  {
   datetime current = TimeCurrent();
   MqlDateTime dt_now, dt_last;
   TimeToStruct(current, dt_now);
   TimeToStruct(m_last_day_check, dt_last);

   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(current_equity <= 0) current_equity = AccountInfoDouble(ACCOUNT_BALANCE);

   if(dt_now.day != dt_last.day || dt_now.mon != dt_last.mon)
     {
      m_start_day_equity = current_equity;
      m_peak_day_equity = current_equity;
      m_last_day_check = current;
     }

   if((current - m_last_week_check) > 7 * 24 * 3600 ||
       (dt_now.day_of_week == 1 && dt_last.day_of_week >= 5))
     {
      m_start_week_equity = current_equity;
      m_peak_week_equity = current_equity;
      m_last_week_check = current;
     }

   if(dt_now.mon != dt_last.mon)
     {
      m_start_month_equity = current_equity;
      m_peak_month_equity = current_equity;
     }

   if(current_equity > m_peak_day_equity) m_peak_day_equity = current_equity;
   if(current_equity > m_peak_week_equity) m_peak_week_equity = current_equity;
   if(current_equity > m_peak_month_equity) m_peak_month_equity = current_equity;
  }

//+------------------------------------------------------------------+
//| Verifier les limites de drawdown                                 |
//+------------------------------------------------------------------+
void CAdaptiveRiskEngine::CheckDrawdownLimits()
  {
   double daily_dd = GetDailyDrawdownPct();
   double weekly_dd = GetWeeklyDrawdownPct();
   double monthly_dd = GetMonthlyDrawdownPct();

   if(monthly_dd >= m_max_monthly_dd)
     {
      if(!m_trading_suspended) m_suspension_start_time = TimeCurrent();
      m_trading_suspended = true;
      m_suspension_reason = StringFormat("DD mensuel %.1f%% >= %.1f%%", monthly_dd, m_max_monthly_dd);
      return;
     }

   if(weekly_dd >= m_max_weekly_dd)
     {
      if(!m_trading_suspended) m_suspension_start_time = TimeCurrent();
      m_trading_suspended = true;
      m_suspension_reason = StringFormat("DD hebdo %.1f%% >= %.1f%%", weekly_dd, m_max_weekly_dd);
      return;
     }

   if(daily_dd >= m_max_daily_dd)
     {
      if(!m_trading_suspended) m_suspension_start_time = TimeCurrent();
      m_trading_suspended = true;
      m_suspension_reason = StringFormat("DD journalier %.1f%% >= %.1f%%", daily_dd, m_max_daily_dd);
      return;
     }

   if(m_trading_suspended)
     {
      MqlDateTime dt_suspend, dt_now;
      TimeToStruct(m_suspension_start_time, dt_suspend);
      TimeToStruct(TimeCurrent(), dt_now);
      bool new_day = (dt_now.day != dt_suspend.day || dt_now.mon != dt_suspend.mon);
      bool dd_recovered = (daily_dd < m_max_daily_dd && weekly_dd < m_max_weekly_dd && monthly_dd < m_max_monthly_dd);
      if(new_day && dd_recovered)
        {
         m_trading_suspended = false;
         m_suspension_reason = "";
        }
     }
   else
      m_suspension_reason = "";
  }

//+------------------------------------------------------------------+
//| Reset du compteur de trades journaliers                          |
//+------------------------------------------------------------------+
void CAdaptiveRiskEngine::CheckDailyTradeReset()
  {
   datetime current = TimeCurrent();
   MqlDateTime dt_now, dt_reset;
   TimeToStruct(current, dt_now);
   TimeToStruct(m_daily_trade_reset, dt_reset);

   if(dt_now.day != dt_reset.day || dt_now.mon != dt_reset.mon)
     {
      m_daily_trade_count = 0;
      m_daily_trade_reset = current;
     }
  }

//+------------------------------------------------------------------+
//| Mise a jour                                                      |
//+------------------------------------------------------------------+
bool CAdaptiveRiskEngine::Update()
  {
   if(!m_initialized) return false;

   UpdateEquityReferences();
   CheckDrawdownLimits();
   CheckDailyTradeReset();

   //--- Mettre a jour les metriques
   m_metrics.base_risk_pct = m_base_risk_pct;
   m_metrics.regime_adjustment = CalculateRegimeAdjustment();
   m_metrics.streak_adjustment = CalculateStreakAdjustment();
   m_metrics.volatility_adjustment = CalculateVolatilityAdjustment();
   m_metrics.session_adjustment = CalculateSessionAdjustment();
   m_metrics.correlation_adjustment = CalculateCorrelationAdjustment();
   m_metrics.effective_risk_pct = GetEffectiveRiskPercent();
   m_metrics.daily_dd_pct = GetDailyDrawdownPct();
   m_metrics.weekly_dd_pct = GetWeeklyDrawdownPct();
   m_metrics.monthly_dd_pct = GetMonthlyDrawdownPct();
   m_metrics.exposure_pct = GetCurrentExposure();
   m_metrics.risk_mode = DetermineRiskMode();
   m_metrics.market_regime = DetectMarketRegime();
   m_metrics.can_trade = !m_trading_suspended;
   m_metrics.reason = m_suspension_reason;

   return true;
  }

//+------------------------------------------------------------------+
//| Calculer le risque effectif - COMBINAISON DE TOUS LES AJUSTEMENTS|
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::GetEffectiveRiskPercent() const
  {
   double regime_adj = CalculateRegimeAdjustment();
   double streak_adj = CalculateStreakAdjustment();
   double vol_adj = CalculateVolatilityAdjustment();
   double session_adj = CalculateSessionAdjustment();
   double corr_adj = CalculateCorrelationAdjustment();

   //--- Le risque effectif est le produit de tous les ajustements
   //--- Chaque ajustement est un multiplicateur entre 0 et 1
   double effective = m_base_risk_pct * regime_adj * streak_adj * vol_adj * session_adj * corr_adj;

   //--- Plafonner a 1.5x le risque de base (jamais plus)
   effective = MathMin(effective, m_base_risk_pct * 1.5);

   //--- Minimum absolu: 0.1% (jamais 0 pour eviter les erreurs de calcul)
   effective = MathMax(effective, 0.1);

   return effective;
  }

//+------------------------------------------------------------------+
//| Calcul du lot adaptatif                                          |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::CalculateAdaptiveLotSize(double sl_distance_pips) const
  {
   if(sl_distance_pips <= 0) return 0;

   double effective_risk = GetEffectiveRiskPercent();
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount = balance * (effective_risk / 100.0);

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tick_value <= 0 || tick_size <= 0) return 0;

   double point_value = tick_value * (_Point / tick_size);
   double sl_points = sl_distance_pips * _Point;

   if(point_value <= 0 || sl_points <= 0) return 0;

   double lot_size = risk_amount / (sl_points / _Point * point_value);

   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot_size = MathFloor(lot_size / lot_step) * lot_step;
   lot_size = MathMax(lot_size, min_lot);
   lot_size = MathMin(lot_size, max_lot);

   double max_lot_exposure = (balance * m_max_exposure_pct / 100.0) /
                              (iClose(_Symbol, PERIOD_CURRENT, 0) * tick_value / tick_size);
   lot_size = MathMin(lot_size, max_lot_exposure);

   return NormalizeDouble(lot_size, 2);
  }

//+------------------------------------------------------------------+
//| Calcul du lot (compatible avec l'interface existante)            |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::CalculateLotSize(double sl_distance_pips) const
  {
   return CalculateAdaptiveLotSize(sl_distance_pips);
  }

//+------------------------------------------------------------------+
//| Peut-on ouvrir un trade ?                                        |
//+------------------------------------------------------------------+
bool CAdaptiveRiskEngine::CanOpenTrade(ENUM_SIGNAL_TYPE direction) const
  {
   if(!m_initialized) return false;
   if(m_trading_suspended) return false;

   if(m_daily_trade_count >= m_max_daily_trades) return false;

   int open_positions = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == (long)m_magic_number)
         open_positions++;
     }

   if(open_positions >= m_max_positions) return false;
   if(GetCurrentExposure() >= m_max_exposure_pct) return false;

   //--- Verifier le regime de marche
   SMarketRegime regime = DetectMarketRegime();
   if(!regime.is_tradeable) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Verifier la marge                                                |
//+------------------------------------------------------------------+
bool CAdaptiveRiskEngine::HasEnoughMargin(double lot) const
  {
   if(lot <= 0) return false;

   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin_required = 0;

   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK), margin_required))
      return false;

   //--- FIX v4.2: Lower margin buffer for small accounts (120% instead of 150%)
   //--- 200 USD accounts need less buffer to be able to trade at all
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin_buffer = (equity > 0 && equity < 500.0) ? 1.2 : 1.5;

   return (free_margin >= margin_required * margin_buffer);
  }

//+------------------------------------------------------------------+
//| Enregistrer le resultat d'un trade                               |
//+------------------------------------------------------------------+
void CAdaptiveRiskEngine::RecordTradeResult(bool is_win, double profit)
  {
   if(is_win)
     {
      m_consecutive_wins++;
      m_consecutive_losses = 0;
     }
   else
     {
      m_consecutive_losses++;
      m_consecutive_wins = 0;
     }
  }

//+------------------------------------------------------------------+
//| Enregistrer l'ouverture d'un trade                               |
//+------------------------------------------------------------------+
void CAdaptiveRiskEngine::RecordTradeOpened()
  {
   m_daily_trade_count++;
  }

//+------------------------------------------------------------------+
//| Drawdown journalier en %                                         |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::GetDailyDrawdownPct() const
  {
   if(m_peak_day_equity <= 0) return 0;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd = m_peak_day_equity - equity;
   return (dd > 0) ? (dd / m_peak_day_equity) * 100.0 : 0;
  }

//+------------------------------------------------------------------+
//| Drawdown hebdomadaire en %                                       |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::GetWeeklyDrawdownPct() const
  {
   if(m_peak_week_equity <= 0) return 0;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd = m_peak_week_equity - equity;
   return (dd > 0) ? (dd / m_peak_week_equity) * 100.0 : 0;
  }

//+------------------------------------------------------------------+
//| Drawdown mensuel en %                                            |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::GetMonthlyDrawdownPct() const
  {
   if(m_peak_month_equity <= 0) return 0;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dd = m_peak_month_equity - equity;
   return (dd > 0) ? (dd / m_peak_month_equity) * 100.0 : 0;
  }

//+------------------------------------------------------------------+
//| Exposition actuelle                                              |
//+------------------------------------------------------------------+
double CAdaptiveRiskEngine::GetCurrentExposure() const
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0) return 0;

   double total_margin = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         //--- FIX: Calculer la marge via OrderCalcMargin (POSITION_MARGIN n'existe pas en MQL5)
         double margin = 0;
         string sym = PositionGetString(POSITION_SYMBOL);
         double vol = PositionGetDouble(POSITION_VOLUME);
         double price = PositionGetDouble(POSITION_PRICE_OPEN);
         if(OrderCalcMargin(ORDER_TYPE_BUY, sym, vol, price, margin))
            total_margin += margin;
        }
     }

   return (total_margin / balance) * 100.0;
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
int CAdaptiveRiskEngine::GetDailyTradeCount() const { return m_daily_trade_count; }

SMarketRegime CAdaptiveRiskEngine::GetMarketRegime() const
  {
   return DetectMarketRegime();
  }

SRiskMetrics CAdaptiveRiskEngine::GetRiskMetrics() const
  {
   return m_metrics;
  }

string CAdaptiveRiskEngine::GetAdaptiveRiskInfo() const
  {
   SMarketRegime regime = DetectMarketRegime();
   return StringFormat("ARE: BaseRisk=%.1f%% Eff=%.1f%% | Regime=%s(%d) Streak=L%d/W%d | DD=D%.1f%%/W%.1f%%/M%.1f%% | Mode=%s",
                       m_base_risk_pct, GetEffectiveRiskPercent(),
                       regime.description, regime.regime,
                       m_consecutive_losses, m_consecutive_wins,
                       GetDailyDrawdownPct(), GetWeeklyDrawdownPct(), GetMonthlyDrawdownPct(),
                       (DetermineRiskMode() == RISK_MODE_AGGRESSIVE) ? "AGG" :
                       (DetermineRiskMode() == RISK_MODE_NORMAL) ? "NORM" :
                       (DetermineRiskMode() == RISK_MODE_CONSERVATIVE) ? "CONS" :
                       (DetermineRiskMode() == RISK_MODE_DEFENSIVE) ? "DEF" : "LOCK");
  }

#endif // A2SNIPER_ADAPTIVE_RISK_ENGINE_MQH
//+------------------------------------------------------------------+
