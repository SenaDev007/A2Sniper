//+------------------------------------------------------------------+
//| PositionStateMachine.mqh - State Machine Professionnelle          |
//| A2Sniper Ultimate v4.0 - Wall Street Level                       |
//| Position lifecycle: SCANNING -> SNIPING -> ENTERED -> MANAGING   |
//| -> SCALING -> EXITING -> CLOSED                                   |
//| Manages each position like a senior trader with precise states    |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_POSITION_STATE_MACHINE_MQH
#define A2SNIPER_POSITION_STATE_MACHINE_MQH

#include "CommonTypes.mqh"
#include "TradeExecutor.mqh"
#include "VolatilityEngine.mqh"
#include "MarketStructureEngine.mqh"

//+------------------------------------------------------------------+
//| Enumerations State Machine                                       |
//+------------------------------------------------------------------+
enum ENUM_POSITION_STATE
  {
   STATE_SCANNING = 0,     // Recherche de setup
   STATE_SNIPING = 1,      // Zone identifiee, en attente d'entree
   STATE_ENTERED = 2,      // Position ouverte, gestion initiale
   STATE_MANAGING = 3,     // Position en cours, BE/Trailing actifs
   STATE_SCALING = 4,      // Partial closes en cours
   STATE_EXITING = 5,      // Preparation de sortie
   STATE_CLOSED = 6        // Position fermee
  };

enum ENUM_EXIT_REASON
  {
   EXIT_NONE = 0,
   EXIT_SL_HIT = 1,            // Stop Loss touche
   EXIT_TP1_HIT = 2,           // TP1 atteint
   EXIT_TP2_HIT = 3,           // TP2 atteint
   EXIT_TP3_HIT = 4,           // TP3 atteint
   EXIT_TRAILING_STOP = 5,     // Trailing stop
   EXIT_STRUCTURE_BREAK = 6,   // Structure cassee (choch contre)
   EXIT_TIMEOUT = 7,           // Timeout
   EXIT_NEWS_PROTECTION = 8,   // Protection news
   EXIT_MANUAL = 9,            // Fermeture manuelle
   EXIT_RISK_MANAGEMENT = 10   // Gestion du risque
  };

enum ENUM_MANAGEMENT_ACTION
  {
   ACTION_NONE = 0,
   ACTION_MOVE_SL_TO_BE = 1,          // Deplacer SL au Break Even
   ACTION_TIGHTEN_TRAILING = 2,       // Resserrer le trailing
   ACTION_PARTIAL_CLOSE_TP1 = 3,      // Fermeture partielle TP1
   ACTION_PARTIAL_CLOSE_TP2 = 4,      // Fermeture partielle TP2
   ACTION_PARTIAL_CLOSE_TP3 = 5,      // Fermeture partielle TP3
   ACTION_ADJUST_SL_STRUCTURE = 6,    // Ajuster SL sur structure
   ACTION_FORCE_CLOSE = 7,            // Fermeture forcee
   ACTION_SUSPEND_MANAGEMENT = 8      // Suspendre gestion (news)
  };

//+------------------------------------------------------------------+
//| Structure de position complete avec etat                          |
//+------------------------------------------------------------------+
struct SManagedPosition
  {
   //--- Identification
   ulong                ticket;                    // Ticket de la position
   ENUM_SIGNAL_TYPE     direction;                 // Direction
   ENUM_POSITION_STATE  state;                     // Etat actuel
   ENUM_EXIT_REASON     exit_reason;               // Raison de sortie

   //--- Prix
   double               entry_price;               // Prix d'entree
   double               original_sl;               // SL original
   double               current_sl;                // SL actuel (dynamique)
   double               original_tp1;              // TP1 original
   double               original_tp2;              // TP2 original
   double               original_tp3;              // TP3 original

   //--- Volume
   double               original_lot;              // Lot original
   double               current_lot;               // Lot actuel

   //--- Risk
   double               risk_distance;             // Distance SL en prix
   double               risk_amount;               // Risque en devise

   //--- Scores
   double               score_at_entry;            // Score a l'entree
   int                  sniper_score;              // Score sniper

   //--- Gestion dynamique
   bool                 be_activated;              // Break Even active
   bool                 trailing_active;           // Trailing actif
   bool                 tp1_hit;                   // TP1 atteint
   bool                 tp2_hit;                   // TP2 atteint
   bool                 tp3_hit;                   // TP3 atteint

   //--- Suivi du profit
   double               highest_profit_r;          // Plus haut R atteint
   double               max_adverse_excursion;     // Max drawdown de la position
   double               last_trail_sl;             // Dernier SL de trailing

   //--- Timing
   datetime             open_time;                 // Heure d'ouverture
   datetime             last_action_time;          // Derniere action
   int                  bars_open;                 // Barres depuis l'ouverture
   int                  max_bars_open;             // Maximum de barres

   //--- Etat
   bool                 is_valid;                  // Position active
   bool                 news_protection_active;    // Protection news active

   //--- Historique des actions
   int                  action_count;              // Nombre d'actions
   ENUM_MANAGEMENT_ACTION last_action;             // Derniere action
  };

//+------------------------------------------------------------------+
//| Classe CPositionStateMachine                                     |
//+------------------------------------------------------------------+
class CPositionStateMachine
  {
private:
   bool                   m_initialized;
   CTradeExecutor        *m_executor;
   CVolatilityEngine     *m_volatility;
   CMarketStructureEngine *m_market_structure;

   //--- Parametres
   bool                   m_enable_be;
   bool                   m_enable_trailing;
   bool                   m_enable_partial_close;
   bool                   m_enable_structural_sl;
   ENUM_TRAILING_MODE     m_trailing_mode;

   //--- Seuils dynamiques
   double                 m_be_activation_r;        // R pour activer BE
   double                 m_trailing_activation_r;  // R pour activer trailing
   double                 m_structure_sl_buffer;    // Buffer pour SL structurel

   //--- Positions gerees
   SManagedPosition       m_positions[];
   int                    m_position_count;

   //--- Statistiques
   int                    m_total_managed;
   int                    m_be_count;
   int                    m_trailing_count;
   int                    m_partial_close_count;
   int                    m_structural_sl_count;
   int                    m_force_close_count;

   //--- Methodes de transition d'etat
   void                   TransitionToState(SManagedPosition &pos, ENUM_POSITION_STATE new_state);
   ENUM_MANAGEMENT_ACTION DetermineAction(SManagedPosition &pos);
   bool                   ExecuteAction(SManagedPosition &pos, ENUM_MANAGEMENT_ACTION action);

   //--- Methodes de gestion par etat
   void                   ManageScanningState(SManagedPosition &pos);
   void                   ManageSnipingState(SManagedPosition &pos);
   void                   ManageEnteredState(SManagedPosition &pos);
   void                   ManageManagingState(SManagedPosition &pos);
   void                   ManageScalingState(SManagedPosition &pos);
   void                   ManageExitingState(SManagedPosition &pos);

   //--- Methodes de calcul
   double                 CalculateCurrentR(const SManagedPosition &pos) const;
   double                 CalculateProgressiveTrailMult(double current_r) const;
   double                 CalculateStructuralSL(ENUM_SIGNAL_TYPE direction) const;
   double                 GetATRValue() const;
   int                    FindPositionByTicket(ulong ticket) const;

public:
   //--- Constructeur / Destructeur
                          CPositionStateMachine();
                         ~CPositionStateMachine();

   //--- Initialisation
   bool                   Initialize(CTradeExecutor *executor, CVolatilityEngine *vol,
                                      CMarketStructureEngine *ms,
                                      bool enable_be = true, bool enable_trailing = true,
                                      bool enable_partial = true, bool enable_structural_sl = true,
                                      ENUM_TRAILING_MODE trailing_mode = TRAILING_ATR);
   void                   Deinitialize();

   //--- Gestion des positions
   bool                   RegisterPosition(ulong ticket, ENUM_SIGNAL_TYPE direction,
                                            double entry, double sl, double tp1, double tp2, double tp3,
                                            double lot, double score, int sniper_score);
   bool                   RemovePosition(ulong ticket);

   //--- Mise a jour (a chaque tick)
   bool                   Update();

   //--- Accesseurs
   int                    GetPositionCount() const { return m_position_count; }
   SManagedPosition       GetPosition(int index) const;
   ENUM_POSITION_STATE    GetPositionState(ulong ticket) const;
   int                    GetStateCount(ENUM_POSITION_STATE state) const;

   //--- Info
   string                 GetStateMachineInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CPositionStateMachine::CPositionStateMachine() :
   m_initialized(false),
   m_executor(NULL),
   m_volatility(NULL),
   m_market_structure(NULL),
   m_enable_be(true),
   m_enable_trailing(true),
   m_enable_partial_close(true),
   m_enable_structural_sl(true),
   m_trailing_mode(TRAILING_ATR),
   m_be_activation_r(BE_ACTIVATION_R),
   m_trailing_activation_r(TRAILING_ACTIVATION_R),
   m_structure_sl_buffer(0.2),
   m_position_count(0),
   m_total_managed(0),
   m_be_count(0),
   m_trailing_count(0),
   m_partial_close_count(0),
   m_structural_sl_count(0),
   m_force_close_count(0)
  {
   ArrayResize(m_positions, 0);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CPositionStateMachine::~CPositionStateMachine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CPositionStateMachine::Initialize(CTradeExecutor *executor, CVolatilityEngine *vol,
                                         CMarketStructureEngine *ms,
                                         bool enable_be, bool enable_trailing,
                                         bool enable_partial, bool enable_structural_sl,
                                         ENUM_TRAILING_MODE trailing_mode)
  {
   if(executor == NULL) return false;

   m_executor = executor;
   m_volatility = vol;
   m_market_structure = ms;
   m_enable_be = enable_be;
   m_enable_trailing = enable_trailing;
   m_enable_partial_close = enable_partial;
   m_enable_structural_sl = enable_structural_sl;
   m_trailing_mode = trailing_mode;

   m_initialized = true;
   Print("A2Sniper PSM: Position State Machine initialisee (BE=", m_enable_be,
         " Trail=", m_enable_trailing, " Partial=", m_enable_partial_close,
         " StructSL=", m_enable_structural_sl, ")");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CPositionStateMachine::Deinitialize()
  {
   m_position_count = 0;
   ArrayResize(m_positions, 0);
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Transition d'etat                                                |
//+------------------------------------------------------------------+
void CPositionStateMachine::TransitionToState(SManagedPosition &pos, ENUM_POSITION_STATE new_state)
  {
   if(pos.state == new_state) return;

   ENUM_POSITION_STATE old_state = pos.state;
   pos.state = new_state;
   pos.last_action_time = TimeCurrent();

   Print("A2Sniper PSM: Ticket=", pos.ticket, " Transition: ",
         (old_state == STATE_SCANNING) ? "SCANNING" :
         (old_state == STATE_SNIPING) ? "SNIPING" :
         (old_state == STATE_ENTERED) ? "ENTERED" :
         (old_state == STATE_MANAGING) ? "MANAGING" :
         (old_state == STATE_SCALING) ? "SCALING" :
         (old_state == STATE_EXITING) ? "EXITING" : "CLOSED",
         " -> ",
         (new_state == STATE_SCANNING) ? "SCANNING" :
         (new_state == STATE_SNIPING) ? "SNIPING" :
         (new_state == STATE_ENTERED) ? "ENTERED" :
         (new_state == STATE_MANAGING) ? "MANAGING" :
         (new_state == STATE_SCALING) ? "SCALING" :
         (new_state == STATE_EXITING) ? "EXITING" : "CLOSED");
  }

//+------------------------------------------------------------------+
//| Calculer le R actuel                                             |
//+------------------------------------------------------------------+
double CPositionStateMachine::CalculateCurrentR(const SManagedPosition &pos) const
  {
   if(pos.risk_distance <= 0) return 0;

   double current_price = (pos.direction == SIGNAL_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double profit_distance;
   if(pos.direction == SIGNAL_BUY)
      profit_distance = current_price - pos.entry_price;
   else
      profit_distance = pos.entry_price - current_price;

   return profit_distance / pos.risk_distance;
  }

//+------------------------------------------------------------------+
//| Multiplicateur de trailing progressif                            |
//| 0.5R = 2.0x ATR, 1R = 1.5x, 2R = 1.0x, 3R+ = 0.7x             |
//+------------------------------------------------------------------+
double CPositionStateMachine::CalculateProgressiveTrailMult(double current_r) const
  {
   if(current_r >= 3.0)  return 0.7;
   if(current_r >= 2.5)  return 0.85;
   if(current_r >= 2.0)  return 1.0;
   if(current_r >= 1.5)  return 1.2;
   if(current_r >= 1.0)  return 1.5;
   return 2.0;  // Large au debut
  }

//+------------------------------------------------------------------+
//| Calculer le SL structurel (sous le swing)                        |
//+------------------------------------------------------------------+
double CPositionStateMachine::CalculateStructuralSL(ENUM_SIGNAL_TYPE direction) const
  {
   if(m_market_structure == NULL) return 0;

   double atr = GetATRValue();
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   SMarketStructure m15 = m_market_structure->GetStructure(PERIOD_M15);

   if(direction == SIGNAL_BUY && m15.last_swing_low > 0)
     {
      double buffer = (atr > 0) ? atr * m_structure_sl_buffer : BE_MIN_OFFSET_PIPS * _Point;
      return NormalizeDouble(m15.last_swing_low - buffer, digits);
     }
   if(direction == SIGNAL_SELL && m15.last_swing_high > 0)
     {
      double buffer = (atr > 0) ? atr * m_structure_sl_buffer : BE_MIN_OFFSET_PIPS * _Point;
      return NormalizeDouble(m15.last_swing_high + buffer, digits);
     }

   return 0;
  }

//+------------------------------------------------------------------+
//| Obtenir ATR                                                      |
//+------------------------------------------------------------------+
double CPositionStateMachine::GetATRValue() const
  {
   if(m_volatility != NULL)
      return m_volatility->GetCurrentATR();

   static int atr_handle = INVALID_HANDLE;
   if(atr_handle == INVALID_HANDLE)
      atr_handle = iATR(_Symbol, PERIOD_CURRENT, DEFAULT_ATR_PERIOD);
   if(atr_handle == INVALID_HANDLE) return 0;

   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(atr_handle, 0, 0, 1, buffer) > 0)
      return buffer[0];
   return 0;
  }

//+------------------------------------------------------------------+
//| Trouver position par ticket                                      |
//+------------------------------------------------------------------+
int CPositionStateMachine::FindPositionByTicket(ulong ticket) const
  {
   for(int i = 0; i < m_position_count; i++)
      if(m_positions[i].ticket == ticket && m_positions[i].is_valid)
         return i;
   return -1;
  }

//+------------------------------------------------------------------+
//| Determiner l'action necessaire                                   |
//+------------------------------------------------------------------+
ENUM_MANAGEMENT_ACTION CPositionStateMachine::DetermineAction(SManagedPosition &pos)
  {
   double current_r = CalculateCurrentR(pos);

   //--- Suivre le plus haut R
   if(current_r > pos.highest_profit_r)
      pos.highest_profit_r = current_r;

   //--- Suivre le max adverse excursion
   if(current_r < 0 && MathAbs(current_r) > pos.max_adverse_excursion)
      pos.max_adverse_excursion = MathAbs(current_r);

   //--- 1. Protection news: resserrer le SL
   if(pos.news_protection_active && current_r > 0)
      return ACTION_TIGHTEN_TRAILING;

   //--- 2. Break Even (1R)
   if(m_enable_be && !pos.be_activated && current_r >= m_be_activation_r)
      return ACTION_MOVE_SL_TO_BE;

   //--- 3. Ajustement SL structurel
   if(m_enable_structural_sl && pos.be_activated && !pos.tp1_hit)
     {
      double structural_sl = CalculateStructuralSL(pos.direction);
      if(structural_sl > 0)
        {
         bool should_adjust = false;
         if(pos.direction == SIGNAL_BUY && structural_sl > pos.current_sl)
            should_adjust = true;
         if(pos.direction == SIGNAL_SELL && structural_sl < pos.current_sl && structural_sl > 0)
            should_adjust = true;
         if(should_adjust)
            return ACTION_ADJUST_SL_STRUCTURE;
        }
     }

   //--- 4. Partial Close TP1
   if(m_enable_partial_close && !pos.tp1_hit && current_r >= TP1_R_MULT)
      return ACTION_PARTIAL_CLOSE_TP1;

   //--- 5. Partial Close TP2
   if(m_enable_partial_close && pos.tp1_hit && !pos.tp2_hit && current_r >= TP2_R_MULT)
      return ACTION_PARTIAL_CLOSE_TP2;

   //--- 6. Partial Close TP3 ou trailing agressif
   if(pos.tp1_hit && pos.tp2_hit && !pos.tp3_hit && current_r >= TP3_R_MULT)
     {
      if(!m_enable_trailing)
         return ACTION_PARTIAL_CLOSE_TP3;
      //--- Sinon, laisser le trailing gerer (plus profitable)
     }

   //--- 7. Trailing stop (si actif et seuil atteint)
   if(m_enable_trailing && current_r >= m_trailing_activation_r)
      return ACTION_TIGHTEN_TRAILING;

   //--- 8. Force close si structure cassee contre nous
   if(m_market_structure != NULL)
     {
      SMarketStructure m15 = m_market_structure->GetStructure(PERIOD_M15);
      if(pos.direction == SIGNAL_BUY && m15.last_event == STRUCTURE_CHOCH_BEARISH && current_r < 0.5)
         return ACTION_FORCE_CLOSE;
      if(pos.direction == SIGNAL_SELL && m15.last_event == STRUCTURE_CHOCH_BULLISH && current_r < 0.5)
         return ACTION_FORCE_CLOSE;
     }

   //--- 9. Timeout
   if(pos.bars_open >= pos.max_bars_open && current_r < 0.3)
      return ACTION_FORCE_CLOSE;

   return ACTION_NONE;
  }

//+------------------------------------------------------------------+
//| Executer une action de gestion                                   |
//+------------------------------------------------------------------+
bool CPositionStateMachine::ExecuteAction(SManagedPosition &pos, ENUM_MANAGEMENT_ACTION action)
  {
   if(m_executor == NULL) return false;

   if(!PositionSelectByTicket(pos.ticket))
     {
      pos.is_valid = false;
      return false;
     }

   double current_sl = PositionGetDouble(POSITION_SL);
   double current_tp = PositionGetDouble(POSITION_TP);
   double current_volume = PositionGetDouble(POSITION_VOLUME);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double atr = GetATRValue();
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   switch(action)
     {
      case ACTION_MOVE_SL_TO_BE:
        {
         double offset = (atr > 0) ? atr * BE_ATR_OFFSET_MULT : BE_MIN_OFFSET_PIPS * _Point;
         offset = MathMax(offset, BE_MIN_OFFSET_PIPS * _Point);
         double be_price;

         if(pos.direction == SIGNAL_BUY)
            be_price = NormalizeDouble(pos.entry_price + offset, digits);
         else
            be_price = NormalizeDouble(pos.entry_price - offset, digits);

         bool should_modify = false;
         if(pos.direction == SIGNAL_BUY && be_price > current_sl) should_modify = true;
         if(pos.direction == SIGNAL_SELL && (be_price < current_sl || current_sl == 0)) should_modify = true;

         if(should_modify)
           {
            if(m_executor->ModifyPosition(pos.ticket, be_price, current_tp))
              {
               pos.be_activated = true;
               pos.current_sl = be_price;
               pos.last_trail_sl = be_price;
               m_be_count++;
               TransitionToState(pos, STATE_MANAGING);
               Print("A2Sniper PSM: BE active - Ticket=", pos.ticket, " SL=", be_price);
              }
           }
         break;
        }

      case ACTION_TIGHTEN_TRAILING:
        {
         double current_r = CalculateCurrentR(pos);
         double trail_mult = CalculateProgressiveTrailMult(current_r);
         if(atr <= 0) break;

         double trail_distance = atr * trail_mult;
         double current_price = (pos.direction == SIGNAL_BUY) ?
                                 SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                 SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double new_sl;

         if(pos.direction == SIGNAL_BUY)
            new_sl = NormalizeDouble(current_price - trail_distance, digits);
         else
            new_sl = NormalizeDouble(current_price + trail_distance, digits);

         //--- Le trailing ne doit JAMAIS reculer
         double step = TRAILING_STEP_PIPS * _Point;
         bool should_modify = false;

         if(pos.direction == SIGNAL_BUY && new_sl > current_sl + step) should_modify = true;
         if(pos.direction == SIGNAL_SELL && (current_sl == 0 || new_sl < current_sl - step)) should_modify = true;

         //--- Protection: ne jamais reculer
         if(pos.direction == SIGNAL_BUY && new_sl < pos.last_trail_sl) should_modify = false;
         if(pos.direction == SIGNAL_SELL && new_sl > pos.last_trail_sl && pos.last_trail_sl > 0) should_modify = false;

         if(should_modify)
           {
            if(m_executor->ModifyPosition(pos.ticket, new_sl, current_tp))
              {
               pos.trailing_active = true;
               pos.current_sl = new_sl;
               pos.last_trail_sl = new_sl;
               m_trailing_count++;
               if(pos.state < STATE_MANAGING)
                  TransitionToState(pos, STATE_MANAGING);
              }
           }
         break;
        }

      case ACTION_PARTIAL_CLOSE_TP1:
        {
         double close_volume = MathFloor(current_volume * PARTIAL_TP1_PCT / 100.0 / lot_step) * lot_step;
         if(close_volume >= min_lot)
           {
            if(m_executor->ClosePartial(pos.ticket, close_volume))
              {
               pos.tp1_hit = true;
               pos.current_lot = current_volume - close_volume;
               m_partial_close_count++;
               TransitionToState(pos, STATE_SCALING);
               Print("A2Sniper PSM: TP1 atteint - Partial close ", DoubleToString(close_volume, 2),
                     " lots - Ticket=", pos.ticket);
              }
           }
         break;
        }

      case ACTION_PARTIAL_CLOSE_TP2:
        {
         double remaining = PositionGetDouble(POSITION_VOLUME);
         double close_volume = MathFloor(remaining * PARTIAL_TP2_PCT / 100.0 / lot_step) * lot_step;
         if(close_volume >= min_lot)
           {
            if(m_executor->ClosePartial(pos.ticket, close_volume))
              {
               pos.tp2_hit = true;
               pos.current_lot = remaining - close_volume;
               m_partial_close_count++;
               Print("A2Sniper PSM: TP2 atteint - Partial close ", DoubleToString(close_volume, 2),
                     " lots - Ticket=", pos.ticket);
              }
           }
         break;
        }

      case ACTION_PARTIAL_CLOSE_TP3:
        {
         double remaining = PositionGetDouble(POSITION_VOLUME);
         if(remaining >= min_lot)
           {
            if(m_executor->ClosePartial(pos.ticket, remaining))
              {
               pos.tp3_hit = true;
               m_partial_close_count++;
               TransitionToState(pos, STATE_EXITING);
               Print("A2Sniper PSM: TP3 atteint - Fermeture totale - Ticket=", pos.ticket);
              }
           }
         break;
        }

      case ACTION_ADJUST_SL_STRUCTURE:
        {
         double structural_sl = CalculateStructuralSL(pos.direction);
         if(structural_sl > 0)
           {
            bool should_modify = false;
            if(pos.direction == SIGNAL_BUY && structural_sl > current_sl + _Point) should_modify = true;
            if(pos.direction == SIGNAL_SELL && structural_sl < current_sl - _Point && structural_sl > 0) should_modify = true;

            if(should_modify)
              {
               if(m_executor->ModifyPosition(pos.ticket, structural_sl, current_tp))
                 {
                  pos.current_sl = structural_sl;
                  pos.last_trail_sl = structural_sl;
                  m_structural_sl_count++;
                  Print("A2Sniper PSM: SL ajuste sur structure - Ticket=", pos.ticket,
                        " SL=", structural_sl);
                 }
              }
           }
         break;
        }

      case ACTION_FORCE_CLOSE:
        {
         if(m_executor->ClosePosition(pos.ticket))
           {
            pos.is_valid = false;
            pos.exit_reason = EXIT_STRUCTURE_BREAK;
            m_force_close_count++;
            TransitionToState(pos, STATE_CLOSED);
            Print("A2Sniper PSM: Fermeture forcee - Ticket=", pos.ticket);
           }
         break;
        }

      default:
         break;
     }

   pos.last_action = action;
   pos.action_count++;
   return true;
  }

//+------------------------------------------------------------------+
//| Gerer l'etat ENTERED                                             |
//+------------------------------------------------------------------+
void CPositionStateMachine::ManageEnteredState(SManagedPosition &pos)
  {
   double current_r = CalculateCurrentR(pos);

   //--- Transition vers MANAGING si le trade commence a performer
   if(current_r >= 0.3)  // 0.3R = le trade commence a aller dans notre sens
     {
      TransitionToState(pos, STATE_MANAGING);
     }

   //--- Verifier le timeout rapide (si le trade ne bouge pas)
   if(pos.bars_open >= 12 && MathAbs(current_r) < 0.2)  // 3h sur M15, stagnant
     {
      //--- Forcer le BE meme si le seuil n'est pas atteint
      if(m_enable_be && !pos.be_activated && m_executor != NULL)
        {
         double offset = BE_MIN_OFFSET_PIPS * _Point;
         double be_price;
         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         double current_tp = PositionGetDouble(POSITION_TP);

         if(pos.direction == SIGNAL_BUY)
            be_price = NormalizeDouble(pos.entry_price + offset, digits);
         else
            be_price = NormalizeDouble(pos.entry_price - offset, digits);

         if(m_executor->ModifyPosition(pos.ticket, be_price, current_tp))
           {
            pos.be_activated = true;
            pos.current_sl = be_price;
            pos.last_trail_sl = be_price;
            m_be_count++;
            TransitionToState(pos, STATE_MANAGING);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Gerer l'etat MANAGING                                            |
//+------------------------------------------------------------------+
void CPositionStateMachine::ManageManagingState(SManagedPosition &pos)
  {
   //--- Determiner et executer l'action
   ENUM_MANAGEMENT_ACTION action = DetermineAction(pos);
   if(action != ACTION_NONE)
      ExecuteAction(pos, action);

   //--- Transition vers SCALING si TP1 atteint
   if(pos.tp1_hit)
      TransitionToState(pos, STATE_SCALING);
  }

//+------------------------------------------------------------------+
//| Gerer l'etat SCALING                                             |
//+------------------------------------------------------------------+
void CPositionStateMachine::ManageScalingState(SManagedPosition &pos)
  {
   //--- Continuer la gestion (trailing, partials, etc.)
   ENUM_MANAGEMENT_ACTION action = DetermineAction(pos);
   if(action != ACTION_NONE)
      ExecuteAction(pos, action);

   //--- Transition vers EXITING si tous les TPs sont atteints
   if(pos.tp1_hit && pos.tp2_hit)
      TransitionToState(pos, STATE_EXITING);
  }

//+------------------------------------------------------------------+
//| Gerer l'etat EXITING                                             |
//+------------------------------------------------------------------+
void CPositionStateMachine::ManageExitingState(SManagedPosition &pos)
  {
   //--- Le trailing agressif protege les gains restants
   //--- Multiplicateur tres serre (0.7x ATR a 3R+)
   double current_r = CalculateCurrentR(pos);

   if(current_r > 0 && m_enable_trailing)
     {
      double trail_mult = CalculateProgressiveTrailMult(current_r);
      double atr = GetATRValue();
      if(atr > 0)
        {
         double current_price = (pos.direction == SIGNAL_BUY) ?
                                 SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                 SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         double trail_distance = atr * trail_mult;
         double new_sl;

         if(pos.direction == SIGNAL_BUY)
            new_sl = NormalizeDouble(current_price - trail_distance, digits);
         else
            new_sl = NormalizeDouble(current_price + trail_distance, digits);

         double current_sl = PositionGetDouble(POSITION_SL);
         double current_tp = PositionGetDouble(POSITION_TP);
         double step = TRAILING_STEP_PIPS * _Point;
         bool should_modify = false;

         if(pos.direction == SIGNAL_BUY && new_sl > current_sl + step) should_modify = true;
         if(pos.direction == SIGNAL_SELL && (current_sl == 0 || new_sl < current_sl - step)) should_modify = true;

         if(pos.direction == SIGNAL_BUY && new_sl < pos.last_trail_sl) should_modify = false;
         if(pos.direction == SIGNAL_SELL && new_sl > pos.last_trail_sl && pos.last_trail_sl > 0) should_modify = false;

         if(should_modify && m_executor != NULL)
           {
            if(m_executor->ModifyPosition(pos.ticket, new_sl, current_tp))
              {
               pos.current_sl = new_sl;
               pos.last_trail_sl = new_sl;
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Enregistrer une nouvelle position                                |
//+------------------------------------------------------------------+
bool CPositionStateMachine::RegisterPosition(ulong ticket, ENUM_SIGNAL_TYPE direction,
                                               double entry, double sl, double tp1, double tp2, double tp3,
                                               double lot, double score, int sniper_score)
  {
   if(FindPositionByTicket(ticket) >= 0) return false;

   SManagedPosition pos;
   ZeroMemory(pos);

   pos.ticket = ticket;
   pos.direction = direction;
   pos.state = STATE_ENTERED;
   pos.exit_reason = EXIT_NONE;

   pos.entry_price = entry;
   pos.original_sl = sl;
   pos.current_sl = sl;
   pos.original_tp1 = tp1;
   pos.original_tp2 = tp2;
   pos.original_tp3 = tp3;

   pos.original_lot = lot;
   pos.current_lot = lot;

   pos.risk_distance = MathAbs(entry - sl);
   pos.risk_amount = 0;  // Serait calcule avec le tick value

   pos.score_at_entry = score;
   pos.sniper_score = sniper_score;

   pos.be_activated = false;
   pos.trailing_active = false;
   pos.tp1_hit = false;
   pos.tp2_hit = false;
   pos.tp3_hit = false;

   pos.highest_profit_r = 0;
   pos.max_adverse_excursion = 0;
   pos.last_trail_sl = sl;

   pos.open_time = TimeCurrent();
   pos.last_action_time = TimeCurrent();
   pos.bars_open = 0;
   pos.max_bars_open = POSITION_TIMEOUT_BARS;

   pos.is_valid = true;
   pos.news_protection_active = false;
   pos.action_count = 0;
   pos.last_action = ACTION_NONE;

   m_position_count++;
   ArrayResize(m_positions, m_position_count);
   m_positions[m_position_count - 1] = pos;
   m_total_managed++;

   Print("A2Sniper PSM: Position enregistree - Ticket=", ticket,
         " State=ENTERED SniperScore=", sniper_score);

   return true;
  }

//+------------------------------------------------------------------+
//| Supprimer une position                                           |
//+------------------------------------------------------------------+
bool CPositionStateMachine::RemovePosition(ulong ticket)
  {
   int idx = FindPositionByTicket(ticket);
   if(idx < 0) return false;
   m_positions[idx].is_valid = false;
   TransitionToState(m_positions[idx], STATE_CLOSED);
   return true;
  }

//+------------------------------------------------------------------+
//| Mise a jour (a chaque tick)                                      |
//+------------------------------------------------------------------+
bool CPositionStateMachine::Update()
  {
   if(!m_initialized) return false;

   for(int i = m_position_count - 1; i >= 0; i--)
     {
      if(!m_positions[i].is_valid) continue;

      //--- Verifier si la position existe encore
      if(!PositionSelectByTicket(m_positions[i].ticket))
        {
         m_positions[i].is_valid = false;
         continue;
        }

      //--- Mettre a jour les barres ouvertes
      m_positions[i].bars_open = iBarShift(_Symbol, PERIOD_CURRENT, m_positions[i].open_time);

      //--- Gerer selon l'etat
      switch(m_positions[i].state)
        {
         case STATE_ENTERED:
            ManageEnteredState(m_positions[i]);
            break;
         case STATE_MANAGING:
            ManageManagingState(m_positions[i]);
            break;
         case STATE_SCALING:
            ManageScalingState(m_positions[i]);
            break;
         case STATE_EXITING:
            ManageExitingState(m_positions[i]);
            break;
         default:
            break;
        }
     }

   //--- Nettoyer les positions fermee
   SManagedPosition temp[];
   int new_count = 0;
   for(int i = 0; i < m_position_count; i++)
     {
      if(m_positions[i].is_valid)
        {
         new_count++;
         ArrayResize(temp, new_count);
         temp[new_count - 1] = m_positions[i];
        }
     }

   m_position_count = new_count;
   ArrayResize(m_positions, m_position_count);
   for(int i = 0; i < m_position_count; i++)
      m_positions[i] = temp[i];

   return true;
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
SManagedPosition CPositionStateMachine::GetPosition(int index) const
  {
   if(index >= 0 && index < m_position_count)
      return m_positions[index];
   SManagedPosition empty;
   ZeroMemory(empty);
   return empty;
  }

ENUM_POSITION_STATE CPositionStateMachine::GetPositionState(ulong ticket) const
  {
   int idx = FindPositionByTicket(ticket);
   if(idx >= 0) return m_positions[idx].state;
   return STATE_CLOSED;
  }

int CPositionStateMachine::GetStateCount(ENUM_POSITION_STATE state) const
  {
   int count = 0;
   for(int i = 0; i < m_position_count; i++)
      if(m_positions[i].is_valid && m_positions[i].state == state)
         count++;
   return count;
  }

string CPositionStateMachine::GetStateMachineInfo() const
  {
   return StringFormat("PSM: Managed=%d | BE=%d Trail=%d Partial=%d StructSL=%d Force=%d | Positions=%d",
                       m_total_managed, m_be_count, m_trailing_count,
                       m_partial_close_count, m_structural_sl_count,
                       m_force_close_count, m_position_count);
  }

#endif // A2SNIPER_POSITION_STATE_MACHINE_MQH
//+------------------------------------------------------------------+
