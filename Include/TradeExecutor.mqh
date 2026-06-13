//+------------------------------------------------------------------+
//| TradeExecutor.mqh - Execution des Trades                         |
//| A2Sniper Ultimate v3.1                                           |
//| FIX: TP2/TP3 via position management, retry mechanism,           |
//|      stops level validation, slippage protection                  |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_TRADE_EXECUTOR_MQH
#define A2SNIPER_TRADE_EXECUTOR_MQH

#include <Trade\Trade.mqh>
#include <A2Sniper\CommonTypes.mqh>
#include <A2Sniper\RiskManager.mqh>

//+------------------------------------------------------------------+
//| Classe CTradeExecutor                                            |
//+------------------------------------------------------------------+
class CTradeExecutor
  {
private:
   bool              m_initialized;
   CTrade            m_trade;                 // Objet trade MQL5
   CRiskManager     *m_risk_manager;
   ulong             m_magic_number;

   //--- Statistiques d'execution
   int               m_total_executed;
   int               m_total_errors;
   int               m_slippage_total;

   //--- Methodes privees
   bool              ValidateOrder(const ENUM_SIGNAL_TYPE direction, double &price, double &sl, double &tp);
   bool              SetTradeParams();
   string            GetErrorDescription(uint retcode) const;
   bool              ValidateStopsLevel(double &sl, double &tp, const ENUM_SIGNAL_TYPE direction, double entry_price);
   int               ExecuteWithRetry(bool is_buy, double lot, double price, double sl, double tp, string comment);

public:
   //--- Constructeur / Destructeur
                     CTradeExecutor();
                    ~CTradeExecutor();

   //--- Initialisation
   bool              Initialize(CRiskManager *rm, ulong magic = A2SNIPER_MAGIC);
   void              Deinitialize();

   //--- Execution
   int               ExecuteBuy(double entry_price, double sl, double tp1, double tp2, double tp3, double lot);
   int               ExecuteSell(double entry_price, double sl, double tp1, double tp2, double tp3, double lot);
   bool              ClosePosition(const ulong ticket);
   bool              ClosePartial(const ulong ticket, const double volume_to_close);
   bool              ModifyPosition(const ulong ticket, double sl, double tp);

   //--- Accesseurs
   int               GetTotalExecuted() const { return m_total_executed; }
   int               GetTotalErrors() const { return m_total_errors; }

   //--- Info
   string            GetExecutorInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CTradeExecutor::CTradeExecutor() :
   m_initialized(false),
   m_risk_manager(NULL),
   m_magic_number(A2SNIPER_MAGIC),
   m_total_executed(0),
   m_total_errors(0),
   m_slippage_total(0)
  {
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CTradeExecutor::~CTradeExecutor()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CTradeExecutor::Initialize(CRiskManager *rm, ulong magic)
  {
   if(rm == NULL)
     {
      Print("A2Sniper TE: Risk Manager NULL");
      return false;
     }

   m_risk_manager = rm;
   m_magic_number = magic;

   SetTradeParams();

   m_initialized = true;
   Print("A2Sniper TE: Trade Executor initialise (Magic: ", m_magic_number, ")");
   return true;
  }

//+------------------------------------------------------------------+
//| Configurer les parametres de trade                               |
//+------------------------------------------------------------------+
bool CTradeExecutor::SetTradeParams()
  {
   m_trade.SetExpertMagicNumber(m_magic_number);
   m_trade.SetDeviationInPoints(MAX_SLIPPAGE_POINTS);
   //--- Auto-detect filling mode
   long fill_mode = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fill_mode & SYMBOL_FILLING_FOK) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((fill_mode & SYMBOL_FILLING_IOC) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
   m_trade.SetMarginMode();

   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CTradeExecutor::Deinitialize()
  {
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Valider les niveaux de stops (distance minimum broker)           |
//| FIX: Verifier SYMBOL_TRADE_STOPS_LEVEL avant envoi              |
//+------------------------------------------------------------------+
bool CTradeExecutor::ValidateStopsLevel(double &sl, double &tp, const ENUM_SIGNAL_TYPE direction, double entry_price)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   long stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freeze_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

   //--- Utiliser le plus restrictif entre stops_level et freeze_level
   long min_distance = MathMax(stops_level, freeze_level);
   if(min_distance <= 0)
      min_distance = MathMax(MIN_SL_DISTANCE_PIPS, MIN_TP_DISTANCE_PIPS);

   double min_dist_price = (double)min_distance * _Point;

   //--- Verifier et ajuster SL
   if(direction == SIGNAL_BUY || direction == SIGNAL_SELL)
     {
      double sl_distance = MathAbs(entry_price - sl);
      double tp_distance = MathAbs(tp - entry_price);

      //--- SL trop proche
      if(sl_distance < min_dist_price)
        {
         Print("A2Sniper TE: SL trop proche (", DoubleToString(sl_distance / _Point, 0),
               " pts < ", min_distance, " pts min) - Ajustement");
         if(direction == SIGNAL_BUY)
            sl = NormalizeDouble(entry_price - min_dist_price, digits);
         else
            sl = NormalizeDouble(entry_price + min_dist_price, digits);
        }

      //--- TP trop proche
      if(tp_distance < min_dist_price)
        {
         Print("A2Sniper TE: TP trop proche (", DoubleToString(tp_distance / _Point, 0),
               " pts < ", min_distance, " pts min) - Ajustement");
         if(direction == SIGNAL_BUY)
            tp = NormalizeDouble(entry_price + min_dist_price, digits);
         else
            tp = NormalizeDouble(entry_price - min_dist_price, digits);
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Valider un ordre avant envoi                                     |
//+------------------------------------------------------------------+
bool CTradeExecutor::ValidateOrder(const ENUM_SIGNAL_TYPE direction, double &price, double &sl, double &tp)
  {
   //--- Check spread
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   if(spread > MAX_SPREAD_POINTS * _Point)
     {
      Print("A2Sniper TE: Spread trop eleve (", spread / _Point, " points)");
      return false;
     }

   //--- Ajuster les prix
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(direction == SIGNAL_BUY)
     {
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sl = NormalizeDouble(sl, digits);
      tp = NormalizeDouble(tp, digits);

      if(sl >= price || tp <= price)
        {
         Print("A2Sniper TE: Niveaux SL/TP invalides pour BUY (SL=", sl, " Price=", price, " TP=", tp, ")");
         return false;
        }
     }
   else
     {
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sl = NormalizeDouble(sl, digits);
      tp = NormalizeDouble(tp, digits);

      if(sl <= price || tp >= price)
        {
         Print("A2Sniper TE: Niveaux SL/TP invalides pour SELL (SL=", sl, " Price=", price, " TP=", tp, ")");
         return false;
        }
     }

   //--- FIX: Valider la distance minimum des stops (broker requirement)
   ValidateStopsLevel(sl, tp, direction, price);

   price = NormalizeDouble(price, digits);
   return true;
  }

//+------------------------------------------------------------------+
//| Execution avec retry (FIX: mecanisme de retry institutionnel)    |
//+------------------------------------------------------------------+
int CTradeExecutor::ExecuteWithRetry(bool is_buy, double lot, double price, double sl, double tp, string comment)
  {
   for(int attempt = 1; attempt <= ORDER_RETRY_COUNT; attempt++)
     {
      bool result;
      if(is_buy)
         result = m_trade.Buy(lot, _Symbol, price, sl, tp, comment);
      else
         result = m_trade.Sell(lot, _Symbol, price, sl, tp, comment);

      if(result)
        {
         m_total_executed++;
         int ticket = (int)m_trade.ResultOrder();
         return ticket;
        }

      uint retcode = m_trade.ResultRetcode();

      //--- Requote: re-essayer avec le nouveau prix
      if(retcode == 10004) // Requote
        {
         Print("A2Sniper TE: Requote (tentative ", attempt, "/", ORDER_RETRY_COUNT, ")");
         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         if(is_buy)
            price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         else
            price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         price = NormalizeDouble(price, digits);
         continue;
        }

      //--- Timeout: re-essayer
      if(retcode == 10012) // Request canceled by timeout
        {
         Print("A2Sniper TE: Timeout (tentative ", attempt, "/", ORDER_RETRY_COUNT, ")");
         Sleep(ORDER_RETRY_DELAY_MS);
         continue;
        }

      //--- Erreurs fatales: ne pas re-essayer
      if(retcode == 10014 || // Invalid volume
         retcode == 10015 || // Invalid price
         retcode == 10016 || // Invalid stops
         retcode == 10019)   // Not enough money
        {
         Print("A2Sniper TE: Erreur fatale - ", GetErrorDescription(retcode));
         m_total_errors++;
         return -1;
        }

      //--- Autres erreurs: re-essayer
      Print("A2Sniper TE: Erreur (tentative ", attempt, "/", ORDER_RETRY_COUNT, ") - ", GetErrorDescription(retcode));
      if(attempt < ORDER_RETRY_COUNT)
         Sleep(ORDER_RETRY_DELAY_MS);
     }

   //--- Echec apres tous les essais
   m_total_errors++;
   Print("A2Sniper TE: Echec apres ", ORDER_RETRY_COUNT, " tentatives");
   return -1;
  }

//+------------------------------------------------------------------+
//| Executer un achat                                                |
//| FIX: TP1 utilise pour l'ordre initial. TP2/TP3 seront geres     |
//| par PositionStateMachine via ModifyPosition quand les niveaux seront  |
//| atteints. Le MT5 ne supporte qu'un seul TP par position.         |
//+------------------------------------------------------------------+
int CTradeExecutor::ExecuteBuy(double entry_price, double sl, double tp1, double tp2, double tp3, double lot)
  {
   if(!m_initialized)
      return -1;

   double price = entry_price;
   double sl_copy = sl;
   double tp_copy = tp1;
   if(!ValidateOrder(SIGNAL_BUY, price, sl_copy, tp_copy))
     {
      m_total_errors++;
      return -1;
     }

   //--- Verifier le risque
   if(m_risk_manager != NULL && !m_risk_manager.CanOpenTrade(SIGNAL_BUY))
     {
      Print("A2Sniper TE: Trade refuse par Risk Manager");
      return -1;
     }

   //--- Verifier la marge disponible (FIX)
   if(m_risk_manager != NULL && !m_risk_manager.HasEnoughMargin(lot))
     {
      Print("A2Sniper TE: Marge insuffisante pour lot=", lot);
      m_total_errors++;
      return -1;
     }

   //--- Calculer le lot si necessaire
   if(lot <= 0 && m_risk_manager != NULL)
     {
      double sl_pips = MathAbs(price - sl_copy) / _Point;
      lot = m_risk_manager.CalculateLotSize(sl_pips);
     }

   if(lot <= 0)
     {
      Print("A2Sniper TE: Taille de lot invalide");
      m_total_errors++;
      return -1;
     }

   //--- Executer avec retry
   int ticket = ExecuteWithRetry(true, lot, price, sl_copy, tp_copy, "A2Sniper BUY");

   if(ticket > 0)
     {
      Print("A2Sniper TE: BUY execute - Ticket=", ticket, " Lot=", lot,
            " Price=", price, " SL=", sl_copy, " TP=", tp_copy,
            " TP2=", tp2, " TP3=", tp3);
     }

   return ticket;
  }

//+------------------------------------------------------------------+
//| Executer une vente                                               |
//| FIX: Meme logique que BUY - TP2/TP3 geres par PositionStateMachine      |
//+------------------------------------------------------------------+
int CTradeExecutor::ExecuteSell(double entry_price, double sl, double tp1, double tp2, double tp3, double lot)
  {
   if(!m_initialized)
      return -1;

   double price = entry_price;
   double sl_copy = sl;
   double tp_copy = tp1;
   if(!ValidateOrder(SIGNAL_SELL, price, sl_copy, tp_copy))
     {
      m_total_errors++;
      return -1;
     }

   if(m_risk_manager != NULL && !m_risk_manager.CanOpenTrade(SIGNAL_SELL))
     {
      Print("A2Sniper TE: Trade refuse par Risk Manager");
      return -1;
     }

   //--- Verifier la marge disponible (FIX)
   if(m_risk_manager != NULL && !m_risk_manager.HasEnoughMargin(lot))
     {
      Print("A2Sniper TE: Marge insuffisante pour lot=", lot);
      m_total_errors++;
      return -1;
     }

   if(lot <= 0 && m_risk_manager != NULL)
     {
      double sl_pips = MathAbs(price - sl_copy) / _Point;
      lot = m_risk_manager.CalculateLotSize(sl_pips);
     }

   if(lot <= 0)
     {
      Print("A2Sniper TE: Taille de lot invalide");
      m_total_errors++;
      return -1;
     }

   int ticket = ExecuteWithRetry(false, lot, price, sl_copy, tp_copy, "A2Sniper SELL");

   if(ticket > 0)
     {
      Print("A2Sniper TE: SELL execute - Ticket=", ticket, " Lot=", lot,
            " Price=", price, " SL=", sl_copy, " TP=", tp_copy,
            " TP2=", tp2, " TP3=", tp3);
     }

   return ticket;
  }

//+------------------------------------------------------------------+
//| Fermer une position                                              |
//+------------------------------------------------------------------+
bool CTradeExecutor::ClosePosition(const ulong ticket)
  {
   if(!m_trade.PositionClose(ticket))
     {
      Print("A2Sniper TE: Erreur fermeture position ", ticket, " - ", m_trade.ResultRetcodeDescription());
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Fermeture partielle                                              |
//+------------------------------------------------------------------+
bool CTradeExecutor::ClosePartial(const ulong ticket, const double volume_to_close)
  {
   if(volume_to_close <= 0)
      return false;

   //--- Arrondir le volume au step du symbole
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double normalized_volume = MathFloor(volume_to_close / lot_step) * lot_step;

   if(normalized_volume < min_lot)
     {
      Print("A2Sniper TE: Volume partiel trop petit (", normalized_volume, " < min=", min_lot, ")");
      return false;
     }

   if(!m_trade.PositionClosePartial(ticket, normalized_volume))
     {
      Print("A2Sniper TE: Erreur fermeture partielle ", ticket, " vol=", normalized_volume,
            " - ", m_trade.ResultRetcodeDescription());
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Modifier SL/TP d'une position                                    |
//+------------------------------------------------------------------+
bool CTradeExecutor::ModifyPosition(const ulong ticket, double sl, double tp)
  {
   if(!m_trade.PositionModify(ticket, sl, tp))
     {
      uint retcode = m_trade.ResultRetcode();
      //--- Ne pas logger si "no changes" (10025) - c'est normal
      if(retcode != 10025)
         Print("A2Sniper TE: Erreur modification position ", ticket, " - ", m_trade.ResultRetcodeDescription());
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Description des erreurs                                          |
//+------------------------------------------------------------------+
string CTradeExecutor::GetErrorDescription(uint retcode) const
  {
   switch(retcode)
     {
      case 10004: return "Requote";
      case 10006: return "Request rejected";
      case 10007: return "Request canceled by trader";
      case 10010: return "Only partial of the request was executed";
      case 10011: return "Request processing error";
      case 10012: return "Request canceled by timeout";
      case 10013: return "Invalid request";
      case 10014: return "Invalid volume";
      case 10015: return "Invalid price";
      case 10016: return "Invalid stops";
      case 10017: return "Trade disabled";
      case 10018: return "Market closed";
      case 10019: return "Not enough money";
      case 10020: return "Price changed";
      case 10021: return "No quotes";
      case 10022: return "Invalid expiration date";
      case 10023: return "Order state changed";
      case 10024: return "Too frequent requests";
      case 10025: return "No changes in request";
      case 10026: return "Autotrading disabled by server";
      case 10027: return "Autotrading disabled by client";
      case 10028: return "Request locked for processing";
      case 10029: return "Order or position frozen";
      case 10030: return "Invalid order filling type";
      case 10031: return "No connection with trade server";
      case 10032: return "Operation allowed only for live accounts";
      case 10033: return "Pending orders limit reached";
      case 10034: return "Volume limit reached";
      case 10035: return "Invalid order";
      case 10036: return "Position already closed";
      case 10038: return "Long only";
      case 10039: return "Short only";
      case 10040: return "Close only";
      case 10041: return "FIFO close only";
      default:    return StringFormat("Unknown error (%d)", retcode);
     }
  }

//+------------------------------------------------------------------+
//| Info executeur                                                   |
//+------------------------------------------------------------------+
string CTradeExecutor::GetExecutorInfo() const
  {
   return StringFormat("Executor: Executed=%d Errors=%d ErrorRate=%.1f%% Magic=%d",
                       m_total_executed, m_total_errors,
                       (m_total_executed > 0) ? (double)m_total_errors / m_total_executed * 100 : 0,
                       m_magic_number);
  }

#endif // A2SNIPER_TRADE_EXECUTOR_MQH
//+------------------------------------------------------------------+
