//+------------------------------------------------------------------+
//| RiskManager.mqh - Gestion du Risque Professionnelle              |
//| A2Sniper Ultimate v3.1                                           |
//| FIX: Margin check, daily trade limit, exposure calculation,       |
//|      progressive risk recovery                                    |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_RISK_MQH
#define A2SNIPER_RISK_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Classe CRiskManager                                              |
//+------------------------------------------------------------------+
class CRiskManager
  {
private:
   bool              m_initialized;

   //--- Parametres de risque
   double            m_risk_percent;          // Risque par trade (%)
   double            m_max_daily_dd;          // Drawdown journalier max (%)
   double            m_max_weekly_dd;         // Drawdown hebdomadaire max (%)
   double            m_max_monthly_dd;        // Drawdown mensuel max (%)
   int               m_max_positions;         // Positions simultanees max
   double            m_max_exposure_pct;      // Exposition max (% du capital)
   int               m_max_daily_trades;      // FIX: Maximum trades par jour

   //--- Suivi du drawdown (base sur l'Equity pour refleter le PnL flottant)
   double            m_start_day_equity;      // Equity debut de journee
   double            m_start_week_equity;     // Equity debut de semaine
   double            m_start_month_equity;    // Equity debut de mois
   double            m_peak_day_equity;       // Pic equity de la journee
   double            m_peak_week_equity;      // Pic equity de la semaine
   double            m_peak_month_equity;     // Pic equity du mois
   datetime          m_last_day_check;        // Derniere verification journaliere
   datetime          m_last_week_check;       // Derniere verification hebdomadaire
   datetime          m_suspension_start_time; // Heure de debut de suspension

   //--- Etat
   bool              m_trading_suspended;     // Trading suspendu
   string            m_suspension_reason;     // Raison de la suspension
   int               m_consecutive_losses;    // Pertes consecutives
   double            m_risk_reduction_factor; // Facteur de reduction apres pertes
   ulong             m_magic_number;          // Numero magique configurable

   //--- FIX: Suivi du nombre de trades par jour
   int               m_daily_trade_count;     // Nombre de trades aujourd'hui
   datetime          m_daily_trade_reset;     // Derniere reset du compteur journalier

   //--- Methodes privees
   void              CheckDrawdownLimits();
   void              UpdateEquityReferences();
   double            GetDailyDrawdown() const;
   double            GetWeeklyDrawdown() const;
   double            GetMonthlyDrawdown() const;
   double            GetCurrentExposure() const;
   double            GetCurrencyExposure(const string currency) const;
   void              CheckDailyTradeReset();

public:
   //--- Constructeur / Destructeur
                     CRiskManager();
                    ~CRiskManager();

   //--- Initialisation
   bool              Initialize(double risk_pct = DEFAULT_RISK_PERCENT,
                                 double daily_dd = DEFAULT_DAILY_DD,
                                 double weekly_dd = DEFAULT_WEEKLY_DD,
                                 double monthly_dd = DEFAULT_MONTHLY_DD,
                                 int max_positions = MAX_OPEN_POSITIONS,
                                 ulong magic = A2SNIPER_MAGIC);
   void              Deinitialize();

   //--- Mise a jour
   bool              Update();

   //--- Calcul du lot
   double            CalculateLotSize(double sl_distance_pips) const;

   //--- Verifications de risque
   bool              CanOpenTrade(const ENUM_SIGNAL_TYPE direction) const;
   bool              HasEnoughMargin(double lot) const;   // FIX: Verification marge
   bool              IsTradingSuspended() const { return m_trading_suspended; }
   string            GetSuspensionReason() const { return m_suspension_reason; }

   //--- Enregistrement des resultats
   void              RecordTradeResult(bool is_win);
   void              RecordTradeOpened();                  // FIX: Enregistrer ouverture trade
   void              ResetConsecutiveLosses() { m_consecutive_losses = 0; }

   //--- Accesseurs
   double            GetRiskPercent() const;
   double            GetEffectiveRiskPercent() const;
   double            GetDailyDrawdownPct() const;
   double            GetWeeklyDrawdownPct() const;
   double            GetMonthlyDrawdownPct() const;
   int               GetMaxPositions() const { return m_max_positions; }
   int               GetDailyTradeCount() const { return m_daily_trade_count; }
   int               GetMaxDailyTrades() const { return m_max_daily_trades; }

   //--- Info
   string            GetRiskInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager() :
   m_initialized(false),
   m_risk_percent(DEFAULT_RISK_PERCENT),
   m_max_daily_dd(DEFAULT_DAILY_DD),
   m_max_weekly_dd(DEFAULT_WEEKLY_DD),
   m_max_monthly_dd(DEFAULT_MONTHLY_DD),
   m_max_positions(MAX_OPEN_POSITIONS),
   m_max_exposure_pct(MAX_EXPOSURE_PERCENT),
   m_max_daily_trades(MAX_DAILY_TRADES),
   m_start_day_equity(0),
   m_start_week_equity(0),
   m_start_month_equity(0),
   m_peak_day_equity(0),
   m_peak_week_equity(0),
   m_peak_month_equity(0),
   m_last_day_check(0),
   m_last_week_check(0),
   m_trading_suspended(false),
   m_suspension_reason(""),
   m_consecutive_losses(0),
   m_risk_reduction_factor(1.0),
   m_magic_number(A2SNIPER_MAGIC),
   m_daily_trade_count(0),
   m_daily_trade_reset(0)
  {
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(double risk_pct, double daily_dd, double weekly_dd,
                                double monthly_dd, int max_positions, ulong magic)
  {
   m_risk_percent = (risk_pct > 0 && risk_pct <= 5.0) ? risk_pct : DEFAULT_RISK_PERCENT;
   m_max_daily_dd = (daily_dd > 0 && daily_dd <= 20.0) ? daily_dd : DEFAULT_DAILY_DD;
   m_max_weekly_dd = (weekly_dd > daily_dd && weekly_dd <= 30.0) ? weekly_dd : DEFAULT_WEEKLY_DD;
   m_max_monthly_dd = (monthly_dd > weekly_dd && monthly_dd <= 50.0) ? monthly_dd : DEFAULT_MONTHLY_DD;
   m_max_positions = (max_positions > 0) ? max_positions : MAX_OPEN_POSITIONS;
   m_magic_number = (magic > 0) ? magic : A2SNIPER_MAGIC;

   //--- Initialiser les references d'equity (pas Balance !)
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
   Print("A2Sniper RM: Risk Manager initialise (Risk=", m_risk_percent,
         "%, DD=", m_max_daily_dd, "/", m_max_weekly_dd, "/", m_max_monthly_dd,
         "%, MaxTrades/Day=", m_max_daily_trades, ") [Equity-based DD]");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CRiskManager::Deinitialize()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| FIX: Reset du compteur de trades journaliers                     |
//+------------------------------------------------------------------+
void CRiskManager::CheckDailyTradeReset()
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
//| Mettre a jour les references d'equity                            |
//+------------------------------------------------------------------+
void CRiskManager::UpdateEquityReferences()
  {
   datetime current = TimeCurrent();
   MqlDateTime dt_now, dt_last;
   TimeToStruct(current, dt_now);
   TimeToStruct(m_last_day_check, dt_last);

   //--- Mettre a jour les pics d'equity (pour calcul DD depuis le plus haut)
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(current_equity <= 0) current_equity = AccountInfoDouble(ACCOUNT_BALANCE);

   //--- Nouveau jour
   if(dt_now.day != dt_last.day || dt_now.mon != dt_last.mon)
     {
      m_start_day_equity = current_equity;
      m_peak_day_equity = current_equity;
      m_last_day_check = current;
     }

   //--- Nouvelle semaine
   if((current - m_last_week_check) > 7 * 24 * 3600 ||
       (dt_now.day_of_week == 1 && dt_last.day_of_week >= 5))
     {
      m_start_week_equity = current_equity;
      m_peak_week_equity = current_equity;
      m_last_week_check = current;
     }

   //--- Nouveau mois
   if(dt_now.mon != dt_last.mon)
     {
      m_start_month_equity = current_equity;
      m_peak_month_equity = current_equity;
     }

   //--- Mettre a jour les pics (meme sans changement de jour)
   if(current_equity > m_peak_day_equity) m_peak_day_equity = current_equity;
   if(current_equity > m_peak_week_equity) m_peak_week_equity = current_equity;
   if(current_equity > m_peak_month_equity) m_peak_month_equity = current_equity;
  }

//+------------------------------------------------------------------+
//| Verifier les limites de drawdown                                 |
//+------------------------------------------------------------------+
void CRiskManager::CheckDrawdownLimits()
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

   //--- Lever la suspension seulement si nouveau jour ET DD recupere
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
     {
      m_suspension_reason = "";
     }
  }

//+------------------------------------------------------------------+
//| Obtenir drawdown journalier (base sur Equity)                    |
//+------------------------------------------------------------------+
double CRiskManager::GetDailyDrawdown() const
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(m_peak_day_equity <= 0) return 0;
   double dd = m_peak_day_equity - equity;
   return (dd > 0) ? dd : 0;
  }

//+------------------------------------------------------------------+
//| Obtenir drawdown hebdomadaire (base sur Equity)                  |
//+------------------------------------------------------------------+
double CRiskManager::GetWeeklyDrawdown() const
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(m_peak_week_equity <= 0) return 0;
   double dd = m_peak_week_equity - equity;
   return (dd > 0) ? dd : 0;
  }

//+------------------------------------------------------------------+
//| Obtenir drawdown mensuel (base sur Equity)                       |
//+------------------------------------------------------------------+
double CRiskManager::GetMonthlyDrawdown() const
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(m_peak_month_equity <= 0) return 0;
   double dd = m_peak_month_equity - equity;
   return (dd > 0) ? dd : 0;
  }

//+------------------------------------------------------------------+
//| Drawdown journalier en %                                         |
//+------------------------------------------------------------------+
double CRiskManager::GetDailyDrawdownPct() const
  {
   if(m_peak_day_equity <= 0) return 0;
   return (GetDailyDrawdown() / m_peak_day_equity) * 100.0;
  }

//+------------------------------------------------------------------+
//| Drawdown hebdomadaire en %                                       |
//+------------------------------------------------------------------+
double CRiskManager::GetWeeklyDrawdownPct() const
  {
   if(m_peak_week_equity <= 0) return 0;
   return (GetWeeklyDrawdown() / m_peak_week_equity) * 100.0;
  }

//+------------------------------------------------------------------+
//| Drawdown mensuel en %                                            |
//+------------------------------------------------------------------+
double CRiskManager::GetMonthlyDrawdownPct() const
  {
   if(m_peak_month_equity <= 0) return 0;
   return (GetMonthlyDrawdown() / m_peak_month_equity) * 100.0;
  }

//+------------------------------------------------------------------+
//| Exposition actuelle (FIX: calcul correct base sur la marge)      |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentExposure() const
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0) return 0;

   double total_margin = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         //--- FIX: Utiliser la marge initiale au lieu de volume * prix
         double margin = PositionGetDouble(POSITION_MARGIN);
         total_margin += margin;
        }
     }

   return (total_margin / balance) * 100.0;
  }

//+------------------------------------------------------------------+
//| Exposition par devise                                            |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrencyExposure(const string currency) const
  {
   double total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         string symbol = PositionGetString(POSITION_SYMBOL);
         if(StringFind(symbol, currency) >= 0)
           {
            double volume = PositionGetDouble(POSITION_VOLUME);
            total += volume;
           }
        }
     }
   return total;
  }

//+------------------------------------------------------------------+
//| Mise a jour                                                      |
//+------------------------------------------------------------------+
bool CRiskManager::Update()
  {
   if(!m_initialized)
      return false;

   UpdateEquityReferences();
   CheckDrawdownLimits();
   CheckDailyTradeReset();  // FIX: Reset compteur trades/jour

   return true;
  }

//+------------------------------------------------------------------+
//| Calculer la taille du lot                                        |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double sl_distance_pips) const
  {
   if(sl_distance_pips <= 0)
      return 0;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double effective_risk = GetEffectiveRiskPercent();
   double risk_amount = balance * (effective_risk / 100.0);

   //--- Valeur du point
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tick_value <= 0 || tick_size <= 0)
      return 0;

   double point_value = tick_value * (_Point / tick_size);
   double sl_points = sl_distance_pips * _Point;

   if(point_value <= 0 || sl_points <= 0)
      return 0;

   double lot_size = risk_amount / (sl_points / _Point * point_value);

   //--- Normaliser le lot
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot_size = MathFloor(lot_size / lot_step) * lot_step;
   lot_size = MathMax(lot_size, min_lot);
   lot_size = MathMin(lot_size, max_lot);

   //--- Verifier l'exposition max
   double max_lot_exposure = (balance * m_max_exposure_pct / 100.0) /
                              (iClose(_Symbol, PERIOD_CURRENT, 0) * tick_value / tick_size);
   lot_size = MathMin(lot_size, max_lot_exposure);

   return NormalizeDouble(lot_size, 2);
  }

//+------------------------------------------------------------------+
//| FIX: Verifier si la marge est suffisante pour ouvrir un trade    |
//+------------------------------------------------------------------+
bool CRiskManager::HasEnoughMargin(double lot) const
  {
   if(lot <= 0)
      return false;

   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin_required = 0;

   //--- Calculer la marge necessaire
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK), margin_required))
     {
      Print("A2Sniper RM: Impossible de calculer la marge necessaire");
      return false;
     }

   //--- Il faut au moins 150% de la marge necessaire (securite)
   return (free_margin >= margin_required * 1.5);
  }

//+------------------------------------------------------------------+
//| Peut-on ouvrir un trade ?                                        |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenTrade(const ENUM_SIGNAL_TYPE direction) const
  {
   if(!m_initialized)
      return false;

   //--- Trading suspendu ?
   if(m_trading_suspended)
      return false;

   //--- FIX: Trop de trades aujourd'hui ?
   if(m_daily_trade_count >= m_max_daily_trades)
     {
      Print("A2Sniper RM: Limite trades journaliers atteinte (", m_daily_trade_count, "/", m_max_daily_trades, ")");
      return false;
     }

   //--- Trop de positions ouvertes ?
   int open_positions = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         long magic = PositionGetInteger(POSITION_MAGIC);
         if(magic == (long)m_magic_number)
            open_positions++;
        }
     }

   if(open_positions >= m_max_positions)
      return false;

   //--- Exposition trop elevee ?
   if(GetCurrentExposure() >= m_max_exposure_pct)
      return false;

   //--- Verifier l'exposition par devise (max 2 lots par devise)
   string base_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string profit_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   double max_currency_exposure = 2.0;
   if(GetCurrencyExposure(base_currency) >= max_currency_exposure)
      return false;
   if(GetCurrencyExposure(profit_currency) >= max_currency_exposure)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Enregistrer le resultat d'un trade                               |
//| FIX: Progression plus fine de la reduction de risque             |
//+------------------------------------------------------------------+
void CRiskManager::RecordTradeResult(bool is_win)
  {
   if(is_win)
     {
      m_consecutive_losses = 0;
      //--- FIX: Progression progressive du retour a la normale
      if(m_risk_reduction_factor < 1.0)
         m_risk_reduction_factor = MathMin(m_risk_reduction_factor + 0.1, 1.0);
      else
         m_risk_reduction_factor = 1.0;
     }
   else
     {
      m_consecutive_losses++;
      //--- Reduction progressive du risque apres pertes consecutives
      if(m_consecutive_losses >= 4)
         m_risk_reduction_factor = 0.25;    // Reduction de 75% (tres defensif)
      else if(m_consecutive_losses >= 3)
         m_risk_reduction_factor = 0.5;     // Reduction de 50%
      else if(m_consecutive_losses >= 2)
         m_risk_reduction_factor = 0.75;    // Reduction de 25%
     }
  }

//+------------------------------------------------------------------+
//| FIX: Enregistrer l'ouverture d'un trade                          |
//+------------------------------------------------------------------+
void CRiskManager::RecordTradeOpened()
  {
   m_daily_trade_count++;
  }

//+------------------------------------------------------------------+
//| Risque effectif (apres reduction)                                |
//+------------------------------------------------------------------+
double CRiskManager::GetEffectiveRiskPercent() const
  {
   return m_risk_percent * m_risk_reduction_factor;
  }

//+------------------------------------------------------------------+
//| Risque parametre                                                 |
//+------------------------------------------------------------------+
double CRiskManager::GetRiskPercent() const
  {
   return m_risk_percent;
  }

//+------------------------------------------------------------------+
//| Info risque                                                      |
//+------------------------------------------------------------------+
string CRiskManager::GetRiskInfo() const
  {
   return StringFormat("Risk: %.1f%% (Eff: %.1f%%) | DD: D=%.1f%% W=%.1f%% M=%.1f%% | Suspended=%s [%s] | ConsLoss=%d | Exp=%.1f%% | Trades/Day=%d/%d",
                       m_risk_percent, GetEffectiveRiskPercent(),
                       GetDailyDrawdownPct(), GetWeeklyDrawdownPct(),
                       GetMonthlyDrawdownPct(),
                       m_trading_suspended ? "Y" : "N", m_suspension_reason,
                       m_consecutive_losses, GetCurrentExposure(),
                       m_daily_trade_count, m_max_daily_trades);
  }

#endif // A2SNIPER_RISK_MQH
//+------------------------------------------------------------------+
