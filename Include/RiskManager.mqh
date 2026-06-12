//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                        Copyright 2024, YEHI OR Tech Solutions    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, YEHI OR Tech Solutions"

#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Structure pour les statistiques de risque                       |
//+------------------------------------------------------------------+
struct SRiskStatistics
{
   double current_drawdown;
   double max_drawdown;
   double daily_pnl;
   double weekly_pnl;
   double monthly_pnl;
   int open_positions;
   double total_risk_exposure;
   double account_balance;
   double account_equity;
   double margin_level;
   datetime last_update;
};

//+------------------------------------------------------------------+
//| Classe gestionnaire de risque                                   |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   // Paramètres de configuration
   double            m_risk_percent;
   double            m_max_daily_loss;
   double            m_max_drawdown;
   int               m_max_positions;
   bool              m_initialized;
   
   // Objets MT5
   CAccountInfo      m_account;
   CPositionInfo     m_position;
   
   // Variables de suivi
   double            m_initial_balance;
   double            m_daily_start_balance;
   double            m_peak_balance;
   datetime          m_daily_reset_time;
   
   // Statistiques
   SRiskStatistics   m_risk_stats;
   
   // Limites de sécurité
   bool              m_trading_suspended;
   string            m_suspension_reason;
   datetime          m_suspension_time;

public:
   // Constructeur/Destructeur
                     CRiskManager();
                    ~CRiskManager();
   
   // Méthodes d'initialisation
   bool              Initialize(double risk_percent, double max_daily_loss, double max_drawdown, int max_positions);
   void              Deinitialize();
   
   // Méthodes principales de gestion du risque
   bool              CheckRiskLimits();
   double            CalculateLotSize(double entry_price, double stop_loss);
   bool              CanOpenPosition(string symbol = "");
   bool              ValidateTradeParameters(double lot_size, double entry_price, double stop_loss);
   
   // Méthodes de calcul
   double            CalculatePositionRisk(double lot_size, double entry_price, double stop_loss);
   double            GetCurrentDrawdown();
   double            GetDailyPnL();
   double            GetTotalRiskExposure();
   int               GetOpenPositionsCount(string symbol = "");
   
   // Méthodes de mise à jour
   void              UpdateRiskStatistics();
   void              ResetDailyCounters();
   bool              CheckDailyReset();
   
   // Méthodes de contrôle
   void              SuspendTrading(string reason);
   void              ResumeTrading();
   bool              IsTradingSuspended() { return m_trading_suspended; }
   string            GetSuspensionReason() { return m_suspension_reason; }
   
   // Méthodes d'accès aux données
   SRiskStatistics   GetRiskStatistics() { return m_risk_stats; }
   double            GetRiskPercent() { return m_risk_percent; }
   double            GetMaxDailyLoss() { return m_max_daily_loss; }
   double            GetMaxDrawdown() { return m_max_drawdown; }
   int               GetMaxPositions() { return m_max_positions; }
   
   // Méthodes utilitaires
   bool              IsInitialized() { return m_initialized; }
   void              PrintRiskReport();
};

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
   m_risk_percent = 1.0;
   m_max_daily_loss = 5.0;
   m_max_drawdown = 10.0;
   m_max_positions = 3;
   m_initialized = false;
   
   m_initial_balance = 0.0;
   m_daily_start_balance = 0.0;
   m_peak_balance = 0.0;
   m_daily_reset_time = 0;
   
   m_trading_suspended = false;
   m_suspension_reason = "";
   m_suspension_time = 0;
   
   // Initialisation des statistiques
   ZeroMemory(m_risk_stats);
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
bool CRiskManager::Initialize(double risk_percent, double max_daily_loss, double max_drawdown, int max_positions)
{
   if(risk_percent <= 0 || risk_percent > 10 || 
      max_daily_loss <= 0 || max_daily_loss > 50 ||
      max_drawdown <= 0 || max_drawdown > 50 ||
      max_positions <= 0 || max_positions > 20)
   {
      Print("ERREUR RiskManager: Paramètres invalides");
      return false;
   }
   
   m_risk_percent = risk_percent;
   m_max_daily_loss = max_daily_loss;
   m_max_drawdown = max_drawdown;
   m_max_positions = max_positions;
   
   // Initialisation des balances
   m_initial_balance = m_account.Balance();
   m_daily_start_balance = m_initial_balance;
   m_peak_balance = m_initial_balance;
   m_daily_reset_time = TimeCurrent();
   
   // Première mise à jour des statistiques
   UpdateRiskStatistics();
   
   m_initialized = true;
   
   Print("RiskManager initialisé - Risque: ", m_risk_percent, "% | Max Daily Loss: ", m_max_daily_loss, 
         "% | Max Drawdown: ", m_max_drawdown, "% | Max Positions: ", m_max_positions);
   
   return true;
}

//+------------------------------------------------------------------+
//| Désinitialisation                                               |
//+------------------------------------------------------------------+
void CRiskManager::Deinitialize()
{
   m_initialized = false;
}

//+------------------------------------------------------------------+
//| Vérification des limites de risque                             |
//+------------------------------------------------------------------+
bool CRiskManager::CheckRiskLimits()
{
   if(!m_initialized)
      return false;
   
   // Mise à jour des statistiques
   UpdateRiskStatistics();
   
   // Vérification reset quotidien
   CheckDailyReset();
   
   // Si déjà suspendu, vérifier les conditions de reprise
   if(m_trading_suspended)
   {
      // Conditions de reprise automatique (exemple: nouveau jour)
      MqlDateTime dt_current, dt_suspension;
      TimeToStruct(TimeCurrent(), dt_current);
      TimeToStruct(m_suspension_time, dt_suspension);
      
      if(dt_current.day != dt_suspension.day)
      {
         ResumeTrading();
      }
      else
      {
         return false; // Trading toujours suspendu
      }
   }
   
   // Vérification drawdown maximum
   double current_drawdown = GetCurrentDrawdown();
   if(current_drawdown >= m_max_drawdown)
   {
      SuspendTrading("Drawdown maximum atteint: " + DoubleToString(current_drawdown, 2) + "%");
      return false;
   }
   
   // Vérification perte quotidienne
   double daily_pnl_percent = GetDailyPnL();
   if(daily_pnl_percent <= -m_max_daily_loss)
   {
      SuspendTrading("Perte quotidienne maximum atteinte: " + DoubleToString(daily_pnl_percent, 2) + "%");
      return false;
   }
   
   // Vérification nombre maximum de positions
   int open_positions = GetOpenPositionsCount();
   if(open_positions >= m_max_positions)
   {
      return false; // Pas de suspension, juste pas de nouvelles positions
   }
   
   // Vérification niveau de marge
   double margin_level = m_account.MarginLevel();
   if(margin_level < 200.0 && margin_level > 0)
   {
      SuspendTrading("Niveau de marge trop bas: " + DoubleToString(margin_level, 2) + "%");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calcul de la taille de lot                                     |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double entry_price, double stop_loss)
{
   if(!m_initialized || entry_price <= 0 || stop_loss <= 0)
      return 0.0;
   
   // Calcul du risque en devise de base
   double balance = m_account.Balance();
   double risk_amount = balance * (m_risk_percent / 100.0);
   
   // Calcul de la distance du stop loss
   double stop_distance = MathAbs(entry_price - stop_loss);
   if(stop_distance <= 0)
      return 0.0;
   
   // Obtention des informations du symbole
   string symbol = Symbol();
   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   if(tick_size <= 0 || tick_value <= 0)
      return min_lot;
   
   // Calcul de la taille de lot
   double ticks = stop_distance / tick_size;
   double risk_per_lot = ticks * tick_value;
   
   if(risk_per_lot <= 0)
      return min_lot;
   
   double calculated_lot = risk_amount / risk_per_lot;
   
   // Normalisation selon les spécifications du symbole
   calculated_lot = MathMax(calculated_lot, min_lot);
   calculated_lot = MathMin(calculated_lot, max_lot);
   
   // Arrondi selon le pas de lot
   if(lot_step > 0)
   {
      calculated_lot = MathRound(calculated_lot / lot_step) * lot_step;
   }
   
   return calculated_lot;
}

//+------------------------------------------------------------------+
//| Vérifier si on peut ouvrir une position                        |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenPosition(string symbol = "")
{
   if(!CheckRiskLimits())
      return false;
   
   // Vérification nombre de positions
   int current_positions = GetOpenPositionsCount(symbol);
   if(current_positions >= m_max_positions)
      return false;
   
   // Vérification exposition totale
   double total_exposure = GetTotalRiskExposure();
   double max_exposure = m_account.Balance() * (m_risk_percent * m_max_positions / 100.0);
   
   if(total_exposure >= max_exposure)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Validation des paramètres de trade                             |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateTradeParameters(double lot_size, double entry_price, double stop_loss)
{
   if(lot_size <= 0 || entry_price <= 0 || stop_loss <= 0)
      return false;
   
   // Vérification taille de lot
   string symbol = Symbol();
   double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   
   if(lot_size < min_lot || lot_size > max_lot)
      return false;
   
   // Vérification distance minimale
   double min_distance = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) * 
                        SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(MathAbs(entry_price - stop_loss) < min_distance)
      return false;
   
   // Vérification risque de la position
   double position_risk = CalculatePositionRisk(lot_size, entry_price, stop_loss);
   double max_position_risk = m_account.Balance() * (m_risk_percent / 100.0);
   
   if(position_risk > max_position_risk * 1.5) // Tolérance de 50%
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Calcul du risque d'une position                                |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePositionRisk(double lot_size, double entry_price, double stop_loss)
{
   if(lot_size <= 0 || entry_price <= 0 || stop_loss <= 0)
      return 0.0;
   
   string symbol = Symbol();
   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(tick_size <= 0)
      return 0.0;
   
   double stop_distance = MathAbs(entry_price - stop_loss);
   double ticks = stop_distance / tick_size;
   
   return lot_size * ticks * tick_value;
}

//+------------------------------------------------------------------+
//| Obtenir le drawdown actuel                                     |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDrawdown()
{
   double current_equity = m_account.Equity();
   
   // Mise à jour du pic si nécessaire
   if(current_equity > m_peak_balance)
      m_peak_balance = current_equity;
   
   if(m_peak_balance <= 0)
      return 0.0;
   
   double drawdown = (m_peak_balance - current_equity) / m_peak_balance * 100.0;
   return MathMax(0.0, drawdown);
}

//+------------------------------------------------------------------+
//| Obtenir le PnL quotidien                                       |
//+------------------------------------------------------------------+
double CRiskManager::GetDailyPnL()
{
   if(m_daily_start_balance <= 0)
      return 0.0;
   
   double current_equity = m_account.Equity();
   double daily_change = current_equity - m_daily_start_balance;
   
   return (daily_change / m_daily_start_balance) * 100.0;
}

//+------------------------------------------------------------------+
//| Obtenir l'exposition totale au risque                          |
//+------------------------------------------------------------------+
double CRiskManager::GetTotalRiskExposure()
{
   double total_risk = 0.0;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(!m_position.SelectByIndex(i))
         continue;
      
      double position_risk = CalculatePositionRisk(
         m_position.Volume(),
         m_position.PriceOpen(),
         m_position.StopLoss()
      );
      
      total_risk += position_risk;
   }
   
   return total_risk;
}

//+------------------------------------------------------------------+
//| Obtenir le nombre de positions ouvertes                        |
//+------------------------------------------------------------------+
int CRiskManager::GetOpenPositionsCount(string symbol = "")
{
   int count = 0;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(!m_position.SelectByIndex(i))
         continue;
      
      if(symbol != "" && m_position.Symbol() != symbol)
         continue;
      
      count++;
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Mise à jour des statistiques de risque                         |
//+------------------------------------------------------------------+
void CRiskManager::UpdateRiskStatistics()
{
   m_risk_stats.current_drawdown = GetCurrentDrawdown();
   m_risk_stats.max_drawdown = MathMax(m_risk_stats.max_drawdown, m_risk_stats.current_drawdown);
   m_risk_stats.daily_pnl = GetDailyPnL();
   m_risk_stats.open_positions = GetOpenPositionsCount();
   m_risk_stats.total_risk_exposure = GetTotalRiskExposure();
   m_risk_stats.account_balance = m_account.Balance();
   m_risk_stats.account_equity = m_account.Equity();
   m_risk_stats.margin_level = m_account.MarginLevel();
   m_risk_stats.last_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Reset des compteurs quotidiens                                 |
//+------------------------------------------------------------------+
void CRiskManager::ResetDailyCounters()
{
   m_daily_start_balance = m_account.Equity();
   m_daily_reset_time = TimeCurrent();
   
   Print("RiskManager: Reset quotidien effectué - Balance de départ: ", m_daily_start_balance);
}

//+------------------------------------------------------------------+
//| Vérification du reset quotidien                                |
//+------------------------------------------------------------------+
bool CRiskManager::CheckDailyReset()
{
   MqlDateTime dt_current, dt_last_reset;
   TimeToStruct(TimeCurrent(), dt_current);
   TimeToStruct(m_daily_reset_time, dt_last_reset);
   
   // Reset si changement de jour
   if(dt_current.day != dt_last_reset.day)
   {
      ResetDailyCounters();
      
      // Reprise automatique du trading si suspendu pour perte quotidienne
      if(m_trading_suspended && StringFind(m_suspension_reason, "quotidienne") >= 0)
      {
         ResumeTrading();
      }
      
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Suspendre le trading                                            |
//+------------------------------------------------------------------+
void CRiskManager::SuspendTrading(string reason)
{
   m_trading_suspended = true;
   m_suspension_reason = reason;
   m_suspension_time = TimeCurrent();
   
   Print("TRADING SUSPENDU: ", reason);
   Alert("Shalom EA - Trading suspendu: ", reason);
}

//+------------------------------------------------------------------+
//| Reprendre le trading                                            |
//+------------------------------------------------------------------+
void CRiskManager::ResumeTrading()
{
   if(m_trading_suspended)
   {
      Print("TRADING REPRIS - Raison précédente: ", m_suspension_reason);
      
      m_trading_suspended = false;
      m_suspension_reason = "";
      m_suspension_time = 0;
   }
}

//+------------------------------------------------------------------+
//| Imprimer rapport de risque                                     |
//+------------------------------------------------------------------+
void CRiskManager::PrintRiskReport()
{
   UpdateRiskStatistics();
   
   Print("=== RAPPORT DE RISQUE SHALOM EA ===");
   Print("Balance: ", DoubleToString(m_risk_stats.account_balance, 2));
   Print("Equity: ", DoubleToString(m_risk_stats.account_equity, 2));
   Print("Drawdown actuel: ", DoubleToString(m_risk_stats.current_drawdown, 2), "%");
   Print("Drawdown maximum: ", DoubleToString(m_risk_stats.max_drawdown, 2), "%");
   Print("PnL quotidien: ", DoubleToString(m_risk_stats.daily_pnl, 2), "%");
   Print("Positions ouvertes: ", m_risk_stats.open_positions, "/", m_max_positions);
   Print("Exposition totale: ", DoubleToString(m_risk_stats.total_risk_exposure, 2));
   Print("Niveau de marge: ", DoubleToString(m_risk_stats.margin_level, 2), "%");
   
   if(m_trading_suspended)
      Print("STATUT: TRADING SUSPENDU - ", m_suspension_reason);
   else
      Print("STATUT: TRADING ACTIF");
   
   Print("=====================================");
}
