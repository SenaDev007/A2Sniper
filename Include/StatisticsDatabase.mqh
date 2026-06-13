//+------------------------------------------------------------------+
//| StatisticsDatabase.mqh - Statistiques et Journal de Trading      |
//| A2Sniper Ultimate v3.0                                           |
//| KPI: Win Rate, PF, Sharpe, Recovery Factor, DD, Expectancy, Avg R|
//+------------------------------------------------------------------+
#ifndef A2SNIPER_STATS_MQH
#define A2SNIPER_STATS_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Classe CStatisticsDatabase                                       |
//+------------------------------------------------------------------+
class CStatisticsDatabase
  {
private:
   bool              m_initialized;

   //--- Historique des trades
   STradeResult      m_trades[];
   int               m_trade_count;

   //--- Statistiques calculées
   SStatistics       m_stats;

   //--- Méthodes privées
   void              RecalculateStats();
   double            CalculateSharpeRatio() const;
   double            CalculateRecoveryFactor() const;
   double            CalculateExpectancy() const;
   double            CalculateMaxDrawdown() const;

public:
   //--- Constructeur / Destructeur
                     CStatisticsDatabase();
                    ~CStatisticsDatabase();

   //--- Initialisation
   bool              Initialize();
   void              Deinitialize();

   //--- Enregistrement
   bool              RecordTrade(const STradeResult &trade);
   void              LoadFromHistory();       // Charger depuis l'historique MT5

   //--- Accesseurs
   SStatistics        GetStatistics() const { return m_stats; }
   int               GetTradeCount() const { return m_trade_count; }
   STradeResult      GetTrade(const int index) const;

   //--- Info
   string            GetStatsInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CStatisticsDatabase::CStatisticsDatabase() :
   m_initialized(false),
   m_trade_count(0)
  {
   ZeroMemory(m_stats);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CStatisticsDatabase::~CStatisticsDatabase()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CStatisticsDatabase::Initialize()
  {
   ZeroMemory(m_stats);
   m_initialized = true;
   Print("A2Sniper StatsDB: Statistics Database initialisée");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CStatisticsDatabase::Deinitialize()
  {
   m_trade_count = 0;
   ArrayResize(m_trades, 0);
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Enregistrer un trade                                             |
//+------------------------------------------------------------------+
bool CStatisticsDatabase::RecordTrade(const STradeResult &trade)
  {
   m_trade_count++;
   ArrayResize(m_trades, m_trade_count);
   m_trades[m_trade_count - 1] = trade;

   RecalculateStats();
   return true;
  }

//+------------------------------------------------------------------+
//| Charger depuis l'historique MT5                                  |
//+------------------------------------------------------------------+
void CStatisticsDatabase::LoadFromHistory()
  {
   //--- Charger l'historique des deals pour ce symbole et ce magic number
   HistorySelect(0, TimeCurrent());

   int total_deals = HistoryDealsTotal();
   for(int i = 0; i < total_deals; i++)
     {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket <= 0) continue;

      long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(magic != A2SNIPER_MAGIC) continue;

      long entry = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT) continue; // Seulement les sorties

      double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
      double volume = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
      datetime deal_time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
      string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);

      if(deal_symbol != _Symbol) continue;

      STradeResult result;
      result.ticket = (int)deal_ticket;
      long deal_type = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
      result.direction = (deal_type == DEAL_TYPE_BUY) ? SIGNAL_BUY : SIGNAL_SELL;
      result.profit = profit;
      result.close_time = deal_time;
      result.pips = 0; // Approximatif depuis l'historique
      result.rr_achieved = 0;

      m_trade_count++;
      ArrayResize(m_trades, m_trade_count);
      m_trades[m_trade_count - 1] = result;
     }

   if(m_trade_count > 0)
      RecalculateStats();
  }

//+------------------------------------------------------------------+
//| Recalculer les statistiques                                      |
//+------------------------------------------------------------------+
void CStatisticsDatabase::RecalculateStats()
  {
   if(m_trade_count == 0)
     {
      ZeroMemory(m_stats);
      return;
     }

   m_stats.total_trades = m_trade_count;
   m_stats.winning_trades = 0;
   m_stats.losing_trades = 0;
   m_stats.total_profit = 0;
   m_stats.total_loss = 0;
   double total_win = 0;
   double total_loss = 0;

   for(int i = 0; i < m_trade_count; i++)
     {
      if(m_trades[i].profit >= 0)
        {
         m_stats.winning_trades++;
         total_win += m_trades[i].profit;
        }
      else
        {
         m_stats.losing_trades++;
         total_loss += MathAbs(m_trades[i].profit);
        }
     }

   m_stats.total_profit = total_win;
   m_stats.total_loss = total_loss;

   //--- Win Rate
   m_stats.win_rate = (m_trade_count > 0) ? ((double)m_stats.winning_trades / m_trade_count) * 100.0 : 0;

   //--- Profit Factor
   m_stats.profit_factor = (total_loss > 0) ? total_win / total_loss : (total_win > 0 ? 999.9 : 0);

   //--- Average Win/Loss
   m_stats.avg_win = (m_stats.winning_trades > 0) ? total_win / m_stats.winning_trades : 0;
   m_stats.avg_loss = (m_stats.losing_trades > 0) ? total_loss / m_stats.losing_trades : 0;

   //--- Average R:R
   if(m_stats.avg_loss > 0)
      m_stats.avg_rr = m_stats.avg_win / m_stats.avg_loss;
   else
      m_stats.avg_rr = 0;

   //--- Max Drawdown
   m_stats.max_drawdown = CalculateMaxDrawdown();

   //--- Sharpe Ratio
   m_stats.sharpe_ratio = CalculateSharpeRatio();

   //--- Recovery Factor
   m_stats.recovery_factor = CalculateRecoveryFactor();

   //--- Expectancy
   m_stats.expectancy = CalculateExpectancy();
  }

//+------------------------------------------------------------------+
//| Calculer le Sharpe Ratio                                         |
//+------------------------------------------------------------------+
double CStatisticsDatabase::CalculateSharpeRatio() const
  {
   if(m_trade_count < 2)
      return 0;

   //--- Calculer la moyenne des rendements
   double mean = 0;
   for(int i = 0; i < m_trade_count; i++)
      mean += m_trades[i].profit;
   mean /= m_trade_count;

   //--- Calculer l'écart-type
   double variance = 0;
   for(int i = 0; i < m_trade_count; i++)
      variance += MathPow(m_trades[i].profit - mean, 2);
   variance /= (m_trade_count - 1);

   double std_dev = MathSqrt(variance);
   return (std_dev > 0) ? mean / std_dev : 0;
  }

//+------------------------------------------------------------------+
//| Calculer le Recovery Factor                                       |
//+------------------------------------------------------------------+
double CStatisticsDatabase::CalculateRecoveryFactor() const
  {
   if(m_stats.max_drawdown <= 0)
      return 0;

   double net_profit = m_stats.total_profit - m_stats.total_loss;
   return net_profit / m_stats.max_drawdown;
  }

//+------------------------------------------------------------------+
//| Calculer l'Expectancy                                            |
//+------------------------------------------------------------------+
double CStatisticsDatabase::CalculateExpectancy() const
  {
   if(m_trade_count == 0)
      return 0;

   double win_prob = (double)m_stats.winning_trades / m_trade_count;
   double loss_prob = (double)m_stats.losing_trades / m_trade_count;

   return (win_prob * m_stats.avg_win) - (loss_prob * m_stats.avg_loss);
  }

//+------------------------------------------------------------------+
//| Calculer le Drawdown Maximum                                     |
//+------------------------------------------------------------------+
double CStatisticsDatabase::CalculateMaxDrawdown() const
  {
   if(m_trade_count == 0)
      return 0;

   double peak_balance = 0;
   double max_dd = 0;
   double equity = 0;
   double running_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   for(int i = 0; i < m_trade_count; i++)
     {
      equity += m_trades[i].profit;
      double current_balance = running_balance + equity;
      if(current_balance > peak_balance)
         peak_balance = current_balance;

      double dd = peak_balance - current_balance;
      if(dd > max_dd)
         max_dd = dd;
     }

   return (peak_balance > 0) ? (max_dd / peak_balance) * 100.0 : 0;
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
STradeResult CStatisticsDatabase::GetTrade(const int index) const
  {
   if(index >= 0 && index < m_trade_count)
      return m_trades[index];
   STradeResult empty;
   ZeroMemory(empty);
   return empty;
  }

//+------------------------------------------------------------------+
//| Info statistiques                                                |
//+------------------------------------------------------------------+
string CStatisticsDatabase::GetStatsInfo() const
  {
   return StringFormat("Stats: Trades=%d WR=%.1f%% PF=%.2f DD=%.1f Sharpe=%.2f RF=%.2f Exp=%.2f AvgRR=%.2f",
                       m_stats.total_trades, m_stats.win_rate, m_stats.profit_factor,
                       m_stats.max_drawdown, m_stats.sharpe_ratio, m_stats.recovery_factor,
                       m_stats.expectancy, m_stats.avg_rr);
  }

#endif // A2SNIPER_STATS_MQH
//+------------------------------------------------------------------+
