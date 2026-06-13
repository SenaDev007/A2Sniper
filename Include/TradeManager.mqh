//+------------------------------------------------------------------+
//| TradeManager.mqh - Gestion des Positions Ouvertes                |
//| A2Sniper Ultimate v3.1                                           |
//| FIX: Partial close on REMAINING volume, TP3 management,          |
//|      Dynamic BE based on ATR, progressive trailing,              |
//|      intelligent timeout, trailing independent of BE              |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_TRADE_MANAGER_MQH
#define A2SNIPER_TRADE_MANAGER_MQH

#include <Trade\Trade.mqh>
#include <A2Sniper\CommonTypes.mqh>
#include <A2Sniper\TradeExecutor.mqh>
#include <A2Sniper\VolatilityEngine.mqh>

//+------------------------------------------------------------------+
//| Structure de suivi de position                                   |
//+------------------------------------------------------------------+
struct SPositionTracker
  {
   ulong             ticket;                  // Ticket de la position
   ENUM_SIGNAL_TYPE  direction;               // Direction
   double            entry_price;             // Prix d'entree
   double            original_sl;             // SL original
   double            original_tp1;            // TP1 original
   double            original_tp2;            // TP2 original
   double            original_tp3;            // TP3 original
   double            original_lot;            // Lot original
   double            current_lot;             // FIX: Lot actuel (apres partial closes)
   double            risk_distance;           // Distance SL en prix
   bool              be_activated;            // Break Even active
   bool              trailing_active;         // FIX: Trailing actif (independant de BE)
   bool              tp1_hit;                 // TP1 atteint
   bool              tp2_hit;                 // TP2 atteint
   bool              tp3_hit;                 // FIX: TP3 atteint
   double            score_at_entry;          // Score a l'entree
   datetime          open_time;               // Heure d'ouverture
   bool              is_valid;                // Position toujours active
   int               max_bars_open;           // Max barres avant timeout
   double            highest_profit_r;        // FIX: Plus haut R atteint (pour trailing progressif)
   double            last_trail_sl;           // FIX: Dernier SL de trailing (eviter micro-modifications)
  };

//+------------------------------------------------------------------+
//| Classe CTradeManager                                             |
//+------------------------------------------------------------------+
class CTradeManager
  {
private:
   bool              m_initialized;
   CTradeExecutor   *m_executor;
   CVolatilityEngine *m_volatility;

   //--- Parametres
   bool              m_enable_break_even;     // Activer Break Even
   bool              m_enable_trailing;       // Activer Trailing Stop
   bool              m_enable_partial_close;  // Activer fermeture partielle
   ENUM_TRAILING_MODE m_trailing_mode;        // Mode de trailing
   double            m_be_activation_r;       // Activation BE a X R
   double            m_be_atr_offset_mult;    // FIX: Offset BE en multiplicateur ATR
   double            m_trailing_atr_mult;     // Trailing ATR multiplicateur
   int               m_trailing_step_pips;    // Step trailing en pips
   double            m_trailing_activation_r; // FIX: Activation trailing a X R (independant de BE)

   //--- Positions trackees
   SPositionTracker  m_positions[];           // Positions suivies
   int               m_position_count;

   //--- Methodes privees
   int               FindPositionByTicket(const ulong ticket) const;
   void              CheckBreakEven(SPositionTracker &pos);
   void              CheckTrailingStop(SPositionTracker &pos);
   void              CheckPartialClose(SPositionTracker &pos);
   double            CalculateTrailingSL(const SPositionTracker &pos) const;
   double            GetATRValue() const;
   double            CalculateProgressiveTrailMult(double current_r) const;

public:
   //--- Constructeur / Destructeur
                     CTradeManager();
                    ~CTradeManager();

   //--- Initialisation
   bool              Initialize(CTradeExecutor *executor, CVolatilityEngine *volatility,
                                 bool enable_be = true, bool enable_trailing = true,
                                 bool enable_partial = true,
                                 ENUM_TRAILING_MODE trailing_mode = TRAILING_ATR);
   void              Deinitialize();

   //--- Gestion des positions
   bool              RegisterPosition(const ulong ticket, const ENUM_SIGNAL_TYPE direction,
                                       double entry_price, double sl, double tp1, double tp2, double tp3,
                                       double lot, double score);
   bool              RemovePosition(const ulong ticket);

   //--- Mise a jour (appeler a chaque tick)
   bool              Update();

   //--- Accesseurs
   int               GetPositionCount() const { return m_position_count; }
   SPositionTracker  GetPosition(const int index) const;

   //--- Info
   string            GetTradeManagerInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager() :
   m_initialized(false),
   m_executor(NULL),
   m_volatility(NULL),
   m_enable_break_even(true),
   m_enable_trailing(true),
   m_enable_partial_close(true),
   m_trailing_mode(TRAILING_ATR),
   m_be_activation_r(BE_ACTIVATION_R),
   m_be_atr_offset_mult(BE_ATR_OFFSET_MULT),
   m_trailing_atr_mult(TRAILING_ATR_MULT),
   m_trailing_step_pips(TRAILING_STEP_PIPS),
   m_trailing_activation_r(TRAILING_ACTIVATION_R),
   m_position_count(0)
  {
   ArrayResize(m_positions, 0);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(CTradeExecutor *executor, CVolatilityEngine *volatility,
                                 bool enable_be, bool enable_trailing, bool enable_partial,
                                 ENUM_TRAILING_MODE trailing_mode)
  {
   if(executor == NULL)
     {
      Print("A2Sniper TM: Trade Executor NULL");
      return false;
     }

   m_executor = executor;
   m_volatility = volatility;
   m_enable_break_even = enable_be;
   m_enable_trailing = enable_trailing;
   m_enable_partial_close = enable_partial;
   m_trailing_mode = trailing_mode;

   m_initialized = true;
   Print("A2Sniper TM: Trade Manager initialise (BE=", m_enable_break_even,
         " Trail=", m_enable_trailing, " Partial=", m_enable_partial_close, ")");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CTradeManager::Deinitialize()
  {
   m_position_count = 0;
   ArrayResize(m_positions, 0);
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Trouver une position par ticket                                  |
//+------------------------------------------------------------------+
int CTradeManager::FindPositionByTicket(const ulong ticket) const
  {
   for(int i = 0; i < m_position_count; i++)
     {
      if(m_positions[i].ticket == ticket && m_positions[i].is_valid)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Enregistrer une nouvelle position                                |
//+------------------------------------------------------------------+
bool CTradeManager::RegisterPosition(const ulong ticket, const ENUM_SIGNAL_TYPE direction,
                                       double entry_price, double sl, double tp1, double tp2, double tp3,
                                       double lot, double score)
  {
   //--- Verifier si deja enregistre
   if(FindPositionByTicket(ticket) >= 0)
      return false;

   SPositionTracker pos;
   pos.ticket = ticket;
   pos.direction = direction;
   pos.entry_price = entry_price;
   pos.original_sl = sl;
   pos.original_tp1 = tp1;
   pos.original_tp2 = tp2;
   pos.original_tp3 = tp3;
   pos.original_lot = lot;
   pos.current_lot = lot;           // FIX: Initialiser le lot actuel
   pos.risk_distance = MathAbs(entry_price - sl);
   pos.be_activated = false;
   pos.trailing_active = false;     // FIX: Trailing independant
   pos.tp1_hit = false;
   pos.tp2_hit = false;
   pos.tp3_hit = false;             // FIX: Suivi TP3
   pos.score_at_entry = score;
   pos.open_time = TimeCurrent();
   pos.is_valid = true;
   pos.max_bars_open = POSITION_TIMEOUT_BARS;
   pos.highest_profit_r = 0;        // FIX: Suivi du plus haut R
   pos.last_trail_sl = sl;          // FIX: Dernier SL

   m_position_count++;
   ArrayResize(m_positions, m_position_count);
   m_positions[m_position_count - 1] = pos;

   Print("A2Sniper TM: Position enregistree - Ticket=", ticket, " Dir=",
         (direction == SIGNAL_BUY) ? "BUY" : "SELL",
         " Lot=", lot, " Score=", score,
         " SL=", sl, " TP1=", tp1, " TP2=", tp2, " TP3=", tp3);

   return true;
  }

//+------------------------------------------------------------------+
//| Supprimer une position                                           |
//+------------------------------------------------------------------+
bool CTradeManager::RemovePosition(const ulong ticket)
  {
   int idx = FindPositionByTicket(ticket);
   if(idx < 0)
      return false;

   m_positions[idx].is_valid = false;
   return true;
  }

//+------------------------------------------------------------------+
//| Verifier Break Even                                              |
//| FIX: BE dynamique base sur ATR au lieu de pips fixes             |
//+------------------------------------------------------------------+
void CTradeManager::CheckBreakEven(SPositionTracker &pos)
  {
   if(!m_enable_break_even || pos.be_activated)
      return;

   //--- Selectionner la position
   if(!PositionSelectByTicket(pos.ticket))
     {
      pos.is_valid = false;
      return;
     }

   double current_sl = PositionGetDouble(POSITION_SL);
   double current_tp = PositionGetDouble(POSITION_TP);
   double current_price = (pos.direction == SIGNAL_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   //--- Calculer le profit actuel en R
   double profit_distance;
   if(pos.direction == SIGNAL_BUY)
      profit_distance = current_price - pos.entry_price;
   else
      profit_distance = pos.entry_price - current_price;

   double current_r = (pos.risk_distance > 0) ? profit_distance / pos.risk_distance : 0;

   //--- Suivre le plus haut R atteint
   if(current_r > pos.highest_profit_r)
      pos.highest_profit_r = current_r;

   //--- Activer BE si on a atteint le seuil
   if(current_r >= m_be_activation_r)
     {
      double be_price;
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

      //--- FIX: Offset dynamique base sur ATR (plus precis que pips fixes)
      double atr = GetATRValue();
      double offset;
      if(atr > 0)
         offset = atr * m_be_atr_offset_mult;     // Offset = 0.2 * ATR
      else
         offset = BE_MIN_OFFSET_PIPS * _Point;    // Fallback: 1 pip

      //--- Verifier que l'offset est au minimum
      offset = MathMax(offset, BE_MIN_OFFSET_PIPS * _Point);

      if(pos.direction == SIGNAL_BUY)
         be_price = NormalizeDouble(pos.entry_price + offset, digits);
      else
         be_price = NormalizeDouble(pos.entry_price - offset, digits);

      //--- Ne modifier que si le nouveau SL est meilleur
      bool should_modify = false;
      if(pos.direction == SIGNAL_BUY && be_price > current_sl)
         should_modify = true;
      if(pos.direction == SIGNAL_SELL && (be_price < current_sl || current_sl == 0))
         should_modify = true;

      if(should_modify)
        {
         if(m_executor != NULL && m_executor->ModifyPosition(pos.ticket, be_price, current_tp))
           {
            pos.be_activated = true;
            pos.last_trail_sl = be_price;
            Print("A2Sniper TM: Break Even active - Ticket=", pos.ticket,
                  " SL=", be_price, " (offset=", DoubleToString(offset / _Point, 1), " pts ATR-based)");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| FIX: Calcul du multiplicateur de trailing progressif             |
//| Plus le profit est eleve, plus le trailing se resserre           |
//| 0.5R = 2.0x ATR, 1R = 1.5x ATR, 2R = 1.0x ATR, 3R+ = 0.7x    |
//+------------------------------------------------------------------+
double CTradeManager::CalculateProgressiveTrailMult(double current_r) const
  {
   //--- v4: Adaptive trailing - serer plus vite en haute volatilite
   double atr = GetATRValue();
   double avg_atr = 0;
   //--- Obtenir ATR moyen depuis le volatility engine si disponible
   //--- (fallback: utiliser l'ATR actuel comme approximation)
   double atr_ratio = 1.0;

   //--- En haute volatilité, on resserre PLUS VITE (risque de reversal)
   //--- En basse volatilité, on reste PLUS LARGE (mouvement lent)
   if(atr_ratio >= 2.0)
     {
      //--- Marché très volatil: trailing très serré dès 1R
      if(current_r >= 2.0)  return 0.5;   // Ultra serré
      if(current_r >= 1.5)  return 0.8;   // Très serré
      if(current_r >= 1.0)  return 1.0;   // Serré
      return 1.2;                          // Modéré
     }
   else if(atr_ratio >= 1.5)
     {
      //--- Marché modérément volatil
      if(current_r >= 3.0)  return 0.6;   // Très serré
      if(current_r >= 2.0)  return 0.8;   // Serré
      if(current_r >= 1.5)  return 1.0;   // Modéré
      if(current_r >= 1.0)  return 1.2;   // Standard
      return m_trailing_atr_mult;          // Large
     }
   else
     {
      //--- Marché normal ou calme: trailing standard
      if(current_r >= 3.0)  return 0.7;   // Très serré
      if(current_r >= 2.0)  return 1.0;   // Serré
      if(current_r >= 1.5)  return 1.2;   // Modéré
      if(current_r >= 1.0)  return 1.5;   // Standard
      return m_trailing_atr_mult;          // Large
     }
  }

//+------------------------------------------------------------------+
//| Verifier Trailing Stop                                           |
//| FIX: Trailing independant de BE, progressif, ne recule jamais    |
//+------------------------------------------------------------------+
void CTradeManager::CheckTrailingStop(SPositionTracker &pos)
  {
   if(!m_enable_trailing)
      return;

   if(!PositionSelectByTicket(pos.ticket))
     {
      pos.is_valid = false;
      return;
     }

   double current_sl = PositionGetDouble(POSITION_SL);
   double current_tp = PositionGetDouble(POSITION_TP);
   double current_price = (pos.direction == SIGNAL_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   //--- FIX: Calculer le R actuel pour le trailing progressif
   double profit_distance;
   if(pos.direction == SIGNAL_BUY)
      profit_distance = current_price - pos.entry_price;
   else
      profit_distance = pos.entry_price - current_price;

   double current_r = (pos.risk_distance > 0) ? profit_distance / pos.risk_distance : 0;

   //--- FIX: Activer le trailing a partir de TRAILING_ACTIVATION_R (0.5R)
   //--- Pas besoin d'attendre le BE
   if(current_r < m_trailing_activation_r)
      return;

   pos.trailing_active = true;

   //--- Calculer le nouveau SL avec multiplicateur progressif
   double atr = GetATRValue();
   if(atr <= 0)
      return;

   double trail_mult = CalculateProgressiveTrailMult(current_r);
   double trail_distance = atr * trail_mult;
   double new_sl;

   if(pos.direction == SIGNAL_BUY)
      new_sl = current_price - trail_distance;
   else
      new_sl = current_price + trail_distance;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   new_sl = NormalizeDouble(new_sl, digits);

   //--- FIX: Ne modifier que si le nouveau SL est meilleur ET assez eloigne
   //--- Le trailing ne doit JAMAIS reculer
   bool should_modify = false;
   double step = m_trailing_step_pips * _Point;

   if(pos.direction == SIGNAL_BUY)
     {
      //--- Le nouveau SL doit etre plus haut que l'actuel + step
      if(new_sl > current_sl + step)
         should_modify = true;
     }
   else
     {
      //--- Le nouveau SL doit etre plus bas que l'actuel - step
      if(current_sl == 0 || new_sl < current_sl - step)
         should_modify = true;
     }

   //--- FIX: Ne jamais reculer le SL (protection institutionnelle)
   if(pos.direction == SIGNAL_BUY && new_sl < pos.last_trail_sl)
      should_modify = false;
   if(pos.direction == SIGNAL_SELL && new_sl > pos.last_trail_sl && pos.last_trail_sl > 0)
      should_modify = false;

   if(should_modify && m_executor != NULL)
     {
      if(m_executor->ModifyPosition(pos.ticket, new_sl, current_tp))
        {
         pos.last_trail_sl = new_sl;
         Print("A2Sniper TM: Trailing mis a jour - Ticket=", pos.ticket,
               " SL=", new_sl, " R=", DoubleToString(current_r, 2),
               " TrailMult=", DoubleToString(trail_mult, 1));
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculer le SL de trailing                                       |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingSL(const SPositionTracker &pos) const
  {
   double atr = GetATRValue();
   double current_price = (pos.direction == SIGNAL_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   switch(m_trailing_mode)
     {
      case TRAILING_ATR:
        {
         if(atr <= 0) return 0;
         double trail_distance = atr * m_trailing_atr_mult;
         if(pos.direction == SIGNAL_BUY)
            return current_price - trail_distance;
         else
            return current_price + trail_distance;
        }

      case TRAILING_STRUCTURE:
        {
         //--- Utiliser les swing points recents
         if(pos.direction == SIGNAL_BUY)
           {
            for(int i = 1; i < 20; i++)
              {
               double low = iLow(_Symbol, PERIOD_CURRENT, i);
               bool is_swing = true;
               for(int j = 1; j <= 3; j++)
                 {
                  if(iLow(_Symbol, PERIOD_CURRENT, i - j) < low ||
                     iLow(_Symbol, PERIOD_CURRENT, i + j) < low)
                    { is_swing = false; break; }
                 }
               if(is_swing && low < current_price)
                  return low - atr * 0.2;
              }
           }
         else
           {
            for(int i = 1; i < 20; i++)
              {
               double high = iHigh(_Symbol, PERIOD_CURRENT, i);
               bool is_swing = true;
               for(int j = 1; j <= 3; j++)
                 {
                  if(iHigh(_Symbol, PERIOD_CURRENT, i - j) > high ||
                     iHigh(_Symbol, PERIOD_CURRENT, i + j) > high)
                    { is_swing = false; break; }
                 }
               if(is_swing && high > current_price)
                  return high + atr * 0.2;
              }
           }
         return 0;
        }

      case TRAILING_SWING:
        {
         if(atr <= 0) return 0;
         double trail_distance = atr * 0.8;
         if(pos.direction == SIGNAL_BUY)
            return current_price - trail_distance;
         else
            return current_price + trail_distance;
        }
     }

   return 0;
  }

//+------------------------------------------------------------------+
//| Verifier Partial Close                                           |
//| FIX: Partial close sur le VOLUME RESTANT, pas le lot original    |
//|      TP3 gestion ajoutee                                         |
//+------------------------------------------------------------------+
void CTradeManager::CheckPartialClose(SPositionTracker &pos)
  {
   if(!m_enable_partial_close)
      return;

   if(!PositionSelectByTicket(pos.ticket))
     {
      pos.is_valid = false;
      return;
     }

   double current_price = (pos.direction == SIGNAL_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double current_volume = PositionGetDouble(POSITION_VOLUME);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   //--- Verifier TP1 (fermer PARTIAL_TP1_PCT du volume RESTANT)
   if(!pos.tp1_hit)
     {
      double tp1_price = pos.original_tp1;
      bool tp1_reached = (pos.direction == SIGNAL_BUY) ? (current_price >= tp1_price) : (current_price <= tp1_price);

      if(tp1_reached)
        {
         //--- FIX: Calculer le volume a fermer sur le VOLUME RESTANT
         double close_volume = NormalizeDouble(current_volume * PARTIAL_TP1_PCT / 100.0, 2);
         close_volume = MathFloor(close_volume / lot_step) * lot_step;  // Arrondir au step

         if(close_volume >= min_lot && m_executor != NULL)
           {
            if(m_executor->ClosePartial(pos.ticket, close_volume))
              {
               pos.tp1_hit = true;
               pos.current_lot = current_volume - close_volume;  // FIX: Mettre a jour le lot actuel
               Print("A2Sniper TM: TP1 atteint - Fermeture partielle ", DoubleToString(PARTIAL_TP1_PCT, 0),
                     "% du reste (", DoubleToString(close_volume, 2), " lots) - Ticket=", pos.ticket,
                     " Restant=", DoubleToString(pos.current_lot, 2));
              }
           }
        }
     }

   //--- Verifier TP2 (fermer PARTIAL_TP2_PCT du volume RESTANT)
   if(pos.tp1_hit && !pos.tp2_hit)
     {
      double tp2_price = pos.original_tp2;
      bool tp2_reached = (pos.direction == SIGNAL_BUY) ?
                          (current_price >= tp2_price) : (current_price <= tp2_price);

      if(tp2_reached)
        {
         //--- FIX: Utiliser le volume RESTANT de la position (pas le lot original)
         double remaining = PositionGetDouble(POSITION_VOLUME);
         double close_volume = NormalizeDouble(remaining * PARTIAL_TP2_PCT / 100.0, 2);
         close_volume = MathFloor(close_volume / lot_step) * lot_step;

         if(close_volume >= min_lot && m_executor != NULL)
           {
            if(m_executor->ClosePartial(pos.ticket, close_volume))
              {
               pos.tp2_hit = true;
               pos.current_lot = remaining - close_volume;
               Print("A2Sniper TM: TP2 atteint - Fermeture partielle ", DoubleToString(PARTIAL_TP2_PCT, 0),
                     "% du reste (", DoubleToString(close_volume, 2), " lots) - Ticket=", pos.ticket,
                     " Restant=", DoubleToString(pos.current_lot, 2));
              }
           }
        }
     }

   //--- FIX: Verifier TP3 (fermer le reste ou laisser le trailing gerer)
   if(pos.tp1_hit && pos.tp2_hit && !pos.tp3_hit)
     {
      double tp3_price = pos.original_tp3;
      bool tp3_reached = (pos.direction == SIGNAL_BUY) ?
                          (current_price >= tp3_price) : (current_price <= tp3_price);

      if(tp3_reached)
        {
         //--- Option 1: Fermer toute la position a TP3
         //--- Option 2: Laisser le trailing gerer (recommande pour maximiser les gains)
         //--- On utilise le trailing progressif qui resserre a 0.7x ATR a 3R
         //--- Donc on marque TP3 comme atteint mais on ne ferme pas - le trailing fera le travail
         pos.tp3_hit = true;
         Print("A2Sniper TM: TP3 atteint - Trailing progressif actif (0.7x ATR) - Ticket=", pos.ticket,
               " R atteint=", DoubleToString((current_price - pos.entry_price) / pos.risk_distance, 1));

         //--- Si le trailing est desactive, fermer la position a TP3
         if(!m_enable_trailing && m_executor != NULL)
           {
            double remaining = PositionGetDouble(POSITION_VOLUME);
            if(remaining >= min_lot)
              {
               m_executor->ClosePartial(pos.ticket, remaining);
               Print("A2Sniper TM: TP3 - Fermeture totale (trailing desactive) - Ticket=", pos.ticket);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Obtenir ATR (FIX: pas de creation de handle par tick)            |
//+------------------------------------------------------------------+
double CTradeManager::GetATRValue() const
  {
   //--- Utiliser le moteur de volatilite si disponible
   if(m_volatility != NULL)
      return m_volatility->GetCurrentATR();

   //--- FIX: Fallback statique - ne pas creer un handle par tick
   //--- Utiliser iATR avec un handle global statique
   static int atr_handle = INVALID_HANDLE;
   if(atr_handle == INVALID_HANDLE)
     {
      atr_handle = iATR(_Symbol, PERIOD_CURRENT, DEFAULT_ATR_PERIOD);
      if(atr_handle == INVALID_HANDLE)
         return 0;
     }

   double buffer[];
   ArraySetAsSeries(buffer, true);
   if(CopyBuffer(atr_handle, 0, 0, 1, buffer) > 0)
      return buffer[0];

   return 0;
  }

//+------------------------------------------------------------------+
//| Mise a jour (a chaque tick)                                      |
//| FIX: Timeout intelligent - ne fermer que les positions stagnantes|
//+------------------------------------------------------------------+
bool CTradeManager::Update()
  {
   if(!m_initialized)
      return false;

   //--- Parcourir toutes les positions trackees
   for(int i = m_position_count - 1; i >= 0; i--)
     {
      if(!m_positions[i].is_valid)
         continue;

      //--- Verifier si la position existe encore
      if(!PositionSelectByTicket(m_positions[i].ticket))
        {
         m_positions[i].is_valid = false;
         continue;
        }

      //--- FIX: Timeout intelligent - fermer si stagnation prolongee
      //--- MAIS ne pas fermer si la position est en profit significatif
      if(m_positions[i].max_bars_open > 0 && !m_positions[i].be_activated)
        {
         int bars_open = iBarShift(_Symbol, PERIOD_CURRENT, m_positions[i].open_time);
         if(bars_open >= m_positions[i].max_bars_open)
           {
            //--- FIX: Verifier si la position est en profit
            double current_price = (m_positions[i].direction == SIGNAL_BUY) ?
                                    SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                                    SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double profit_pips;
            if(m_positions[i].direction == SIGNAL_BUY)
               profit_pips = (current_price - m_positions[i].entry_price) / _Point;
            else
               profit_pips = (m_positions[i].entry_price - current_price) / _Point;

            //--- Ne fermer que si vraiment stagnant (profit < POSITION_STAGNANT_PIPS)
            if(profit_pips < POSITION_STAGNANT_PIPS)
              {
               Print("A2Sniper TM: Timeout position stagnante - Ticket=", m_positions[i].ticket,
                     " Bars=", bars_open, " Profit=", DoubleToString(profit_pips, 1), " pips");
               if(m_executor != NULL)
                  m_executor->ClosePosition(m_positions[i].ticket);
               m_positions[i].is_valid = false;
               continue;
              }
            else
              {
               Print("A2Sniper TM: Position en profit malgre timeout - Ticket=", m_positions[i].ticket,
                     " Profit=", DoubleToString(profit_pips, 1), " pips - BE force");
               //--- Forcer le BE au lieu de fermer
               if(!m_positions[i].be_activated)
                 {
                  double current_sl = PositionGetDouble(POSITION_SL);
                  double current_tp = PositionGetDouble(POSITION_TP);
                  int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
                  double be_offset = BE_MIN_OFFSET_PIPS * _Point;
                  double be_price;

                  if(m_positions[i].direction == SIGNAL_BUY)
                     be_price = NormalizeDouble(m_positions[i].entry_price + be_offset, digits);
                  else
                     be_price = NormalizeDouble(m_positions[i].entry_price - be_offset, digits);

                  if(m_executor != NULL)
                    {
                     m_executor->ModifyPosition(m_positions[i].ticket, be_price, current_tp);
                     m_positions[i].be_activated = true;
                    }
                 }
              }
           }
        }

      //--- Gerer la position (ordre important: BE d'abord, puis trailing, puis partial)
      CheckBreakEven(m_positions[i]);
      CheckTrailingStop(m_positions[i]);
      CheckPartialClose(m_positions[i]);
     }

   //--- Nettoyer les positions fermees
   SPositionTracker temp[];
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
SPositionTracker CTradeManager::GetPosition(const int index) const
  {
   if(index >= 0 && index < m_position_count)
      return m_positions[index];
   SPositionTracker empty;
   ZeroMemory(empty);
   return empty;
  }

//+------------------------------------------------------------------+
//| Info Trade Manager                                               |
//+------------------------------------------------------------------+
string CTradeManager::GetTradeManagerInfo() const
  {
   return StringFormat("TM: Positions=%d | BE=%s Trail=%s(%d) Partial=%s",
                       m_position_count,
                       m_enable_break_even ? "ON" : "OFF",
                       m_enable_trailing ? "ON" : "OFF", m_trailing_mode,
                       m_enable_partial_close ? "ON" : "OFF");
  }

#endif // A2SNIPER_TRADE_MANAGER_MQH
//+------------------------------------------------------------------+
