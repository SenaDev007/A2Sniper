//+------------------------------------------------------------------+
//| OrderBookEngine.mqh - Moteur d'Analyse du Carnet d'Ordres        |
//| A2Sniper Trading v4.0 - Wall Street Level                       |
//| Order book analysis: walls, imbalance, liquidity validation,     |
//| institutional footprint, dynamic SL adjustment                   |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_ORDER_BOOK_ENGINE_MQH
#define A2SNIPER_ORDER_BOOK_ENGINE_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Enumerations Order Book                                          |
//+------------------------------------------------------------------+
enum ENUM_ORDERBOOK_STATE
  {
   ORDERBOOK_INACTIVE = 0,     // Carnet non disponible
   ORDERBOOK_ACTIVE   = 1,     // Carnet actif
   ORDERBOOK_PARTIAL  = 2      // Profondeur limitee
  };

enum ENUM_IMBALANCE_DIRECTION
  {
   IMBALANCE_NEUTRAL   = 0,    // Equilibre bid/ask
   IMBALANCE_BULLISH   = 1,    // Pression acheteuse dominante
   IMBALANCE_BEARISH   = -1,   // Pression vendeuse dominante
   IMBALANCE_EXTREME_B = 2,    // Pression acheteuse extreme
   IMBALANCE_EXTREME_S = -2    // Pression vendeuse extreme
  };

enum ENUM_WALL_TYPE
  {
   WALL_NONE       = 0,        // Pas de mur detecte
   WALL_BID        = 1,        // Mur d'achats (support)
   WALL_ASK        = -1,       // Mur de ventes (resistance)
   WALL_ABSORPTION = 2         // Mur d'absorption (institutionnel)
  };

enum ENUM_BOOK_QUALITY
  {
   BOOK_QUALITY_NONE   = 0,    // Pas de donnees
   BOOK_QUALITY_LOW    = 1,    // Profondeur < 5 niveaux
   BOOK_QUALITY_MEDIUM = 2,    // Profondeur 5-15 niveaux
   BOOK_QUALITY_HIGH   = 3     // Profondeur > 15 niveaux
  };

//+------------------------------------------------------------------+
//| Structures Order Book                                            |
//+------------------------------------------------------------------+

//--- Niveau du carnet d'ordres
struct SBookLevel
  {
   double            price;            // Prix du niveau
   double            volume;           // Volume a ce niveau
   double            cumulative_vol;   // Volume cumule
   bool              is_wall;          // Mur detecte a ce niveau
   double            wall_score;       // Score du mur (0-100)
  };

//--- Mur d'ordres detecte
struct SOrderWall
  {
   double            price;            // Prix du mur
   double            volume;           // Volume du mur
   ENUM_WALL_TYPE    type;             // Type de mur
   double            strength;         // Force du mur (0-100)
   double            distance_pips;    // Distance en pips du prix actuel
   bool              is_valid;         // Mur toujours actif
   datetime          detected_time;    // Heure de detection
  };

//--- Resultat de l'analyse d'imbalance
struct SImbalanceResult
  {
   double            bid_volume;           // Volume total cote bid
   double            ask_volume;           // Volume total cote ask
   double            ratio;                // Ratio bid/ask (>1 = bullish)
   ENUM_IMBALANCE_DIRECTION direction;     // Direction de l'imbalance
   double            strength;             // Force de l'imbalance (0-100)
   double            bid_avg_volume;       // Volume moyen par niveau bid
   double            ask_avg_volume;       // Volume moyen par niveau ask
   bool              is_significant;       // Imbalance significatif
  };

//--- Validation Order Book pour signal sniper
struct SOrderBookValidation
  {
   bool              is_available;         // Carnet disponible
   ENUM_BOOK_QUALITY quality;              // Qualite des donnees
   bool              liquidity_ok;         // Liquidite suffisante a l'entree
   bool              imbalance_confirms;   // Imbalance confirme le signal
   bool              wall_supports;        // Mur d'ordres supporte le trade
   double            wall_sl_adjust;       // Ajustement SL base sur le mur
   double            confidence_score;     // Score de confiance (0-100)
   string            rejection_reason;     // Raison du rejet si applicable
  };

//--- Snapshot complet du carnet
struct SOrderBookSnapshot
  {
   SBookLevel        bid_levels[];         // Niveaux bid
   SBookLevel        ask_levels[];         // Niveaux ask
   int               bid_depth;            // Profondeur bid
   int               ask_depth;            // Profondeur ask
   double            spread;               // Spread actuel
   double            mid_price;            // Prix milieu
   datetime          timestamp;            // Heure du snapshot
   ENUM_ORDERBOOK_STATE state;             // Etat du carnet
   ENUM_BOOK_QUALITY quality;              // Qualite des donnees
  };

//+------------------------------------------------------------------+
//| Classe COrderBookEngine                                          |
//+------------------------------------------------------------------+
class COrderBookEngine
  {
private:
   //--- Configuration
   bool              m_enabled;               // Moteur active
   bool              m_subscribed;            // Souscrit au MarketBook
   string            m_symbol;                // Symbole analyse
   ENUM_ORDERBOOK_STATE m_state;              // Etat actuel
   ENUM_BOOK_QUALITY m_quality;               // Qualite actuelle

   //--- Parametres de detection
   double            m_wall_multiplier;       // Multiplicateur pour detecter un mur (x fois la moyenne)
   int               m_min_wall_levels;       // Niveaux minimums pour un mur valide
   double            m_imbalance_threshold;   // Seuil d'imbalance significatif (ratio)
   double            m_extreme_imbalance;     // Seuil d'imbalance extreme
   int               m_max_wall_count;        // Nombre max de murs a tracker
   double            m_min_liquidity_ratio;   // Ratio liquidite minimum pour valider
   int               m_max_levels;            // Niveaux maximum a analyser

   //--- Donnees courantes
   SOrderBookSnapshot m_snapshot;             // Snapshot actuel
   SOrderWall        m_walls[];               // Murs detectes
   int               m_wall_count;            // Nombre de murs
   SImbalanceResult  m_imbalance;             // Imbalance actuel

   //--- Historique et statistiques
   double            m_imbalance_history[];   // Historique des ratios
   int               m_imbalance_hist_size;   // Taille historique
   int               m_total_snapshots;       // Nombre total de snapshots
   int               m_successful_reads;      // Lectures reussies
   int               m_failed_reads;          // Lectures echouees
   datetime          m_last_update;           // Derniere mise a jour

   //--- Methodes privees
   bool              SubscribeToBook();
   void              UnsubscribeFromBook();
   bool              ReadMarketBook();
   void              AnalyzeWalls();
   void              AnalyzeImbalance();
   double            CalculateAverageVolume(const SBookLevel &levels[], int count);
   double            CalculateLiquidityAtPrice(double target_price, double tolerance, ENUM_SIGNAL_TYPE direction);
   double            FindNearestWall(double reference_price, ENUM_SIGNAL_TYPE direction);
   double            AdjustSLForWall(double current_sl, double wall_price, ENUM_SIGNAL_TYPE direction);
   void              SortWallsByStrength();
   void              AddWall(SOrderWall &wall);

public:
                     COrderBookEngine();
                    ~COrderBookEngine();

   //--- Initialisation
   bool              Initialize(string symbol, double wall_multiplier = 3.0,
                                double imbalance_threshold = 1.5, double extreme_imbalance = 2.5,
                                int max_wall_count = 10, double min_liquidity_ratio = 0.3,
                                int max_levels = 50);
   void              Deinitialize();
   void              SetEnabled(bool enabled);

   //--- Mise a jour
   bool              Update();

   //--- Validation sniper
   SOrderBookValidation ValidateSignal(ENUM_SIGNAL_TYPE direction, double entry_price,
                                        double stop_loss, double atr);
   bool              HasLiquidityAtEntry(double entry_price, double tolerance);
   bool              HasWallSupport(ENUM_SIGNAL_TYPE direction, double reference_price);
   double            GetAdjustedStopLoss(double current_sl, ENUM_SIGNAL_TYPE direction);

   //--- Acces aux donnees
   SImbalanceResult  GetImbalance();
   SOrderBookSnapshot GetSnapshot();
   int               GetWallCount();
   SOrderWall        GetWall(int index);
   SOrderWall        GetNearestWall(ENUM_SIGNAL_TYPE direction);
   double            GetBidAskRatio();
   ENUM_BOOK_QUALITY GetBookQuality();
   bool              IsAvailable();

   //--- Statistiques
   double            GetReadSuccessRate();
   int               GetTotalSnapshots();
   string            GetStateName();
   string            GetImbalanceName();
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
COrderBookEngine::COrderBookEngine() :
   m_enabled(false),
   m_subscribed(false),
   m_symbol(""),
   m_state(ORDERBOOK_INACTIVE),
   m_quality(BOOK_QUALITY_NONE),
   m_wall_multiplier(3.0),
   m_min_wall_levels(3),
   m_imbalance_threshold(1.5),
   m_extreme_imbalance(2.5),
   m_max_wall_count(10),
   m_min_liquidity_ratio(0.3),
   m_max_levels(50),
   m_wall_count(0),
   m_imbalance_hist_size(20),
   m_total_snapshots(0),
   m_successful_reads(0),
   m_failed_reads(0),
   m_last_update(0)
  {
   ArrayResize(m_walls, 0);
   ArrayResize(m_imbalance_history, m_imbalance_hist_size);
   ArrayInitialize(m_imbalance_history, 1.0);
   ZeroMemory(m_snapshot);
   ZeroMemory(m_imbalance);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
COrderBookEngine::~COrderBookEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool COrderBookEngine::Initialize(string symbol, double wall_multiplier,
                                   double imbalance_threshold, double extreme_imbalance,
                                   int max_wall_count, double min_liquidity_ratio,
                                   int max_levels)
  {
   m_symbol = symbol;
   m_wall_multiplier = wall_multiplier;
   m_imbalance_threshold = imbalance_threshold;
   m_extreme_imbalance = extreme_imbalance;
   m_max_wall_count = max_wall_count;
   m_min_liquidity_ratio = min_liquidity_ratio;
   m_max_levels = max_levels;

   //--- Verifier si le MarketBook est supporte
   if(!SymbolInfoInteger(m_symbol, SYMBOL_BOOK_DEPTH))
     {
      Print("A2Sniper Trading: OrderBook - Profondeur non disponible pour ", m_symbol);
      m_state = ORDERBOOK_INACTIVE;
      m_enabled = false;
      // Ne pas echouer - graceful degradation
      return true;
     }

   //--- Souscrire au carnet d'ordres
   if(SubscribeToBook())
     {
      m_enabled = true;
      m_state = ORDERBOOK_ACTIVE;
      Print("A2Sniper Trading: OrderBook Engine initialise - ", m_symbol,
            " | WallX=", m_wall_multiplier, " | ImbalanceThresh=", m_imbalance_threshold);
     }
   else
     {
      m_enabled = false;
      m_state = ORDERBOOK_INACTIVE;
      Print("A2Sniper Trading: OrderBook - Souscription echouee, mode degrade actif");
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void COrderBookEngine::Deinitialize()
  {
   if(m_subscribed)
      UnsubscribeFromBook();

   m_enabled = false;
   m_state = ORDERBOOK_INACTIVE;
   m_quality = BOOK_QUALITY_NONE;
   m_wall_count = 0;
   ArrayResize(m_walls, 0);
  }

//+------------------------------------------------------------------+
//| Activer/desactiver le moteur                                     |
//+------------------------------------------------------------------+
void COrderBookEngine::SetEnabled(bool enabled)
  {
   m_enabled = enabled;
   if(!enabled)
     {
      m_state = ORDERBOOK_INACTIVE;
      ZeroMemory(m_snapshot);
     }
   else if(m_subscribed)
      m_state = ORDERBOOK_ACTIVE;
  }

//+------------------------------------------------------------------+
//| Souscrire au MarketBook                                          |
//+------------------------------------------------------------------+
bool COrderBookEngine::SubscribeToBook()
  {
   if(!SymbolInfoInteger(m_symbol, SYMBOL_BOOK_DEPTH))
      return false;

   if(!MarketBookAdd(m_symbol))
     {
      Print("A2Sniper Trading: OrderBook - Erreur souscription MarketBookAdd");
      return false;
     }

   m_subscribed = true;
   return true;
  }

//+------------------------------------------------------------------+
//| Se desinscrire du MarketBook                                     |
//+------------------------------------------------------------------+
void COrderBookEngine::UnsubscribeFromBook()
  {
   if(m_subscribed)
     {
      MarketBookRelease(m_symbol);
      m_subscribed = false;
     }
  }

//+------------------------------------------------------------------+
//| Mise a jour - lire le carnet d'ordres                            |
//+------------------------------------------------------------------+
bool COrderBookEngine::Update()
  {
   if(!m_enabled)
      return false;

   m_total_snapshots++;

   if(!ReadMarketBook())
     {
      m_failed_reads++;
      return false;
     }

   m_successful_reads++;
   m_last_update = TimeCurrent();

   //--- Analyser les murs d'ordres
   AnalyzeWalls();

   //--- Analyser l'imbalance bid/ask
   AnalyzeImbalance();

   return true;
  }

//+------------------------------------------------------------------+
//| Lire les donnees du MarketBook                                   |
//+------------------------------------------------------------------+
bool COrderBookEngine::ReadMarketBook()
  {
   MqlBookInfo book[];
   int count = MarketBookGet(m_symbol, book);

   if(count <= 0)
     {
      //--- Si la lecture echoue plusieurs fois, passer en mode degrade
      if(m_failed_reads > 5 && m_state == ORDERBOOK_ACTIVE)
        {
         m_state = ORDERBOOK_PARTIAL;
         Print("A2Sniper Trading: OrderBook - Passage en mode partiel (lectures echouees)");
        }
      return false;
     }

   //--- Separer bid et ask
   int bid_count = 0, ask_count = 0;
   for(int i = 0; i < count; i++)
     {
      if(book[i].type == BOOK_TYPE_SELL) ask_count++;   // Ask = sell side
      else if(book[i].type == BOOK_TYPE_BUY) bid_count++; // Bid = buy side
     }

   if(bid_count == 0 || ask_count == 0)
      return false;

   //--- Allocation des tableaux
   ArrayResize(m_snapshot.bid_levels, bid_count);
   ArrayResize(m_snapshot.ask_levels, ask_count);
   m_snapshot.bid_depth = bid_count;
   m_snapshot.ask_depth = ask_count;

   //--- Remplir les niveaux
   int bid_idx = 0, ask_idx = 0;
   double cum_bid = 0, cum_ask = 0;

   for(int i = 0; i < count; i++)
     {
      SBookLevel level;
      level.price = book[i].price;
      level.volume = (double)book[i].volume;
      level.is_wall = false;
      level.wall_score = 0;

      if(book[i].type == BOOK_TYPE_BUY)
        {
         cum_bid += level.volume;
         level.cumulative_vol = cum_bid;
         m_snapshot.bid_levels[bid_idx] = level;
         bid_idx++;
        }
      else if(book[i].type == BOOK_TYPE_SELL)
        {
         cum_ask += level.volume;
         level.cumulative_vol = cum_ask;
         m_snapshot.ask_levels[ask_idx] = level;
         ask_idx++;
        }
     }

   //--- Calculer le spread et le mid-price
   if(bid_count > 0 && ask_count > 0)
     {
      double best_bid = m_snapshot.bid_levels[0].price;
      double best_ask = m_snapshot.ask_levels[0].price;
      m_snapshot.spread = best_ask - best_bid;
      m_snapshot.mid_price = (best_bid + best_ask) / 2.0;
     }

   m_snapshot.timestamp = TimeCurrent();
   m_snapshot.state = ORDERBOOK_ACTIVE;

   //--- Evaluer la qualite des donnees
   int min_depth = MathMin(bid_count, ask_count);
   if(min_depth >= 15)
      m_snapshot.quality = BOOK_QUALITY_HIGH;
   else if(min_depth >= 5)
      m_snapshot.quality = BOOK_QUALITY_MEDIUM;
   else
      m_snapshot.quality = BOOK_QUALITY_LOW;

   m_quality = m_snapshot.quality;

   return true;
  }

//+------------------------------------------------------------------+
//| Analyser et detecter les murs d'ordres                           |
//+------------------------------------------------------------------+
void COrderBookEngine::AnalyzeWalls()
  {
   m_wall_count = 0;
   ArrayResize(m_walls, 0);

   //--- Volume moyen pour le cote bid
   double avg_bid_vol = CalculateAverageVolume(m_snapshot.bid_levels, m_snapshot.bid_depth);
   double avg_ask_vol = CalculateAverageVolume(m_snapshot.ask_levels, m_snapshot.ask_depth);

   if(avg_bid_vol <= 0 || avg_ask_vol <= 0)
      return;

   //--- Detecter les murs bid (support)
   for(int i = 0; i < m_snapshot.bid_depth && m_wall_count < m_max_wall_count; i++)
     {
      if(m_snapshot.bid_levels[i].volume >= avg_bid_vol * m_wall_multiplier)
        {
         SOrderWall wall;
         wall.price = m_snapshot.bid_levels[i].price;
         wall.volume = m_snapshot.bid_levels[i].volume;
         wall.type = WALL_BID;
         wall.strength = MathMin(100.0, (m_snapshot.bid_levels[i].volume / avg_bid_vol) * 25.0);
         wall.distance_pips = MathAbs(m_snapshot.mid_price - wall.price) / _Point;
         wall.is_valid = true;
         wall.detected_time = TimeCurrent();

         //--- Verifier si c'est un mur d'absorption (volume massif)
         if(m_snapshot.bid_levels[i].volume >= avg_bid_vol * (m_wall_multiplier * 2.0))
            wall.type = WALL_ABSORPTION;

         AddWall(wall);
         m_snapshot.bid_levels[i].is_wall = true;
         m_snapshot.bid_levels[i].wall_score = wall.strength;
        }
     }

   //--- Detecter les murs ask (resistance)
   for(int i = 0; i < m_snapshot.ask_depth && m_wall_count < m_max_wall_count; i++)
     {
      if(m_snapshot.ask_levels[i].volume >= avg_ask_vol * m_wall_multiplier)
        {
         SOrderWall wall;
         wall.price = m_snapshot.ask_levels[i].price;
         wall.volume = m_snapshot.ask_levels[i].volume;
         wall.type = WALL_ASK;
         wall.strength = MathMin(100.0, (m_snapshot.ask_levels[i].volume / avg_ask_vol) * 25.0);
         wall.distance_pips = MathAbs(m_snapshot.mid_price - wall.price) / _Point;
         wall.is_valid = true;
         wall.detected_time = TimeCurrent();

         //--- Verifier si c'est un mur d'absorption (volume massif)
         if(m_snapshot.ask_levels[i].volume >= avg_ask_vol * (m_wall_multiplier * 2.0))
            wall.type = WALL_ABSORPTION;

         AddWall(wall);
         m_snapshot.ask_levels[i].is_wall = true;
         m_snapshot.ask_levels[i].wall_score = wall.strength;
        }
     }

   //--- Trier par force
   SortWallsByStrength();
  }

//+------------------------------------------------------------------+
//| Analyser l'imbalance bid/ask                                     |
//+------------------------------------------------------------------+
void COrderBookEngine::AnalyzeImbalance()
  {
   double total_bid = 0, total_ask = 0;
   int bid_levels = MathMin(m_snapshot.bid_depth, m_max_levels);
   int ask_levels = MathMin(m_snapshot.ask_depth, m_max_levels);

   //--- Somme des volumes sur les N premiers niveaux
   for(int i = 0; i < bid_levels; i++)
      total_bid += m_snapshot.bid_levels[i].volume;
   for(int i = 0; i < ask_levels; i++)
      total_ask += m_snapshot.ask_levels[i].volume;

   m_imbalance.bid_volume = total_bid;
   m_imbalance.ask_volume = total_ask;

   //--- Ratio bid/ask
   if(total_ask > 0)
      m_imbalance.ratio = total_bid / total_ask;
   else if(total_bid > 0)
      m_imbalance.ratio = 10.0;
   else
      m_imbalance.ratio = 1.0;

   //--- Volumes moyens
   m_imbalance.bid_avg_volume = (bid_levels > 0) ? total_bid / bid_levels : 0;
   m_imbalance.ask_avg_volume = (ask_levels > 0) ? total_ask / ask_levels : 0;

   //--- Determiner la direction de l'imbalance
   if(m_imbalance.ratio >= m_extreme_imbalance)
      m_imbalance.direction = IMBALANCE_EXTREME_B;
   else if(m_imbalance.ratio >= m_imbalance_threshold)
      m_imbalance.direction = IMBALANCE_BULLISH;
   else if(m_imbalance.ratio <= (1.0 / m_extreme_imbalance))
      m_imbalance.direction = IMBALANCE_EXTREME_S;
   else if(m_imbalance.ratio <= (1.0 / m_imbalance_threshold))
      m_imbalance.direction = IMBALANCE_BEARISH;
   else
      m_imbalance.direction = IMBALANCE_NEUTRAL;

   //--- Force de l'imbalance (0-100)
   double deviation = MathAbs(m_imbalance.ratio - 1.0);
   m_imbalance.strength = MathMin(100.0, deviation * 50.0);

   //--- Significativite
   m_imbalance.is_significant = (m_imbalance.strength >= 20.0);

   //--- Mettre a jour l'historique
   for(int i = m_imbalance_hist_size - 1; i > 0; i--)
      m_imbalance_history[i] = m_imbalance_history[i - 1];
   m_imbalance_history[0] = m_imbalance.ratio;
  }

//+------------------------------------------------------------------+
//| Calculer le volume moyen d'un cote                               |
//+------------------------------------------------------------------+
double COrderBookEngine::CalculateAverageVolume(const SBookLevel &levels[], int count)
  {
   if(count <= 0) return 0;

   double total = 0;
   int valid = 0;
   int limit = MathMin(count, m_max_levels);

   for(int i = 0; i < limit; i++)
     {
      if(levels[i].volume > 0)
        {
         total += levels[i].volume;
         valid++;
        }
     }

   return (valid > 0) ? total / valid : 0;
  }

//+------------------------------------------------------------------+
//| Calculer la liquidite a un niveau de prix                        |
//+------------------------------------------------------------------+
double COrderBookEngine::CalculateLiquidityAtPrice(double target_price, double tolerance,
                                                     ENUM_SIGNAL_TYPE direction)
  {
   double total_liquidity = 0;

   if(direction == SIGNAL_BUY)
     {
      //--- Pour un achat, verifier la liquidite ask (fournisseurs)
      for(int i = 0; i < m_snapshot.ask_depth; i++)
        {
         if(MathAbs(m_snapshot.ask_levels[i].price - target_price) <= tolerance)
            total_liquidity += m_snapshot.ask_levels[i].volume;
        }
     }
   else
     {
      //--- Pour une vente, verifier la liquidite bid (demandeurs)
      for(int i = 0; i < m_snapshot.bid_depth; i++)
        {
         if(MathAbs(m_snapshot.bid_levels[i].price - target_price) <= tolerance)
            total_liquidity += m_snapshot.bid_levels[i].volume;
        }
     }

   return total_liquidity;
  }

//+------------------------------------------------------------------+
//| Trouver le mur le plus proche dans une direction                 |
//+------------------------------------------------------------------+
double COrderBookEngine::FindNearestWall(double reference_price, ENUM_SIGNAL_TYPE direction)
  {
   double nearest = 0;
   double min_distance = DBL_MAX;

   for(int i = 0; i < m_wall_count; i++)
     {
      if(!m_walls[i].is_valid) continue;

      //--- Pour un BUY: chercher un mur BID en dessous (support)
      if(direction == SIGNAL_BUY && m_walls[i].type == WALL_BID)
        {
         if(m_walls[i].price < reference_price)
           {
            double dist = reference_price - m_walls[i].price;
            if(dist < min_distance)
              {
               min_distance = dist;
               nearest = m_walls[i].price;
              }
           }
        }
      //--- Pour un SELL: chercher un mur ASK au-dessus (resistance)
      else if(direction == SIGNAL_SELL && m_walls[i].type == WALL_ASK)
        {
         if(m_walls[i].price > reference_price)
           {
            double dist = m_walls[i].price - reference_price;
            if(dist < min_distance)
              {
               min_distance = dist;
               nearest = m_walls[i].price;
              }
           }
        }
     }

   return nearest;
  }

//+------------------------------------------------------------------+
//| Ajuster le SL base sur les murs d'ordres                        |
//+------------------------------------------------------------------+
double COrderBookEngine::AdjustSLForWall(double current_sl, double wall_price,
                                           ENUM_SIGNAL_TYPE direction)
  {
   if(wall_price <= 0) return current_sl;

   double adjusted_sl = current_sl;
   double buffer_pips = 3.0; // Buffer de 3 pips au-dela du mur
   double buffer = buffer_pips * _Point;

   if(direction == SIGNAL_BUY)
     {
      //--- Pour un BUY: placer le SL en dessous du mur bid (support)
      double wall_sl = wall_price - buffer;
      //--- Ne prendre le SL ajuste que s'il est plus proche (plus serre)
      if(wall_sl > current_sl)
         adjusted_sl = wall_sl;
     }
   else
     {
      //--- Pour un SELL: placer le SL au-dessus du mur ask (resistance)
      double wall_sl = wall_price + buffer;
      //--- Ne prendre le SL ajuste que s'il est plus proche (plus serre)
      if(wall_sl < current_sl || current_sl <= 0)
         adjusted_sl = wall_sl;
     }

   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   return NormalizeDouble(adjusted_sl, digits);
  }

//+------------------------------------------------------------------+
//| Ajouter un mur a la liste                                        |
//+------------------------------------------------------------------+
void COrderBookEngine::AddWall(SOrderWall &wall)
  {
   m_wall_count++;
   ArrayResize(m_walls, m_wall_count);
   m_walls[m_wall_count - 1] = wall;
  }

//+------------------------------------------------------------------+
//| Trier les murs par force (decroissant)                           |
//+------------------------------------------------------------------+
void COrderBookEngine::SortWallsByStrength()
  {
   if(m_wall_count <= 1) return;

   //--- Tri a bulles (suffisant pour < 20 murs)
   for(int i = 0; i < m_wall_count - 1; i++)
     {
      for(int j = i + 1; j < m_wall_count; j++)
        {
         if(m_walls[j].strength > m_walls[i].strength)
           {
            SOrderWall temp = m_walls[i];
            m_walls[i] = m_walls[j];
            m_walls[j] = temp;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Valider un signal sniper avec le carnet d'ordres                 |
//+------------------------------------------------------------------+
SOrderBookValidation COrderBookEngine::ValidateSignal(ENUM_SIGNAL_TYPE direction,
                                                        double entry_price,
                                                        double stop_loss,
                                                        double atr)
  {
   SOrderBookValidation result;
   ZeroMemory(result);

   //--- Verifier la disponibilite
   result.is_available = m_enabled && (m_state != ORDERBOOK_INACTIVE);
   result.quality = m_quality;

   if(!result.is_available)
     {
      result.confidence_score = 50.0; // Neutre si non disponible
      result.rejection_reason = "OrderBook non disponible";
      return result;
     }

   //--- 1. Verifier la liquidite a l'entree
   double tolerance = atr * 0.5; // Tolerance = moitie de l'ATR
   double liquidity = CalculateLiquidityAtPrice(entry_price, tolerance, direction);
   double avg_vol = (m_imbalance.bid_avg_volume + m_imbalance.ask_avg_volume) / 2.0;

   result.liquidity_ok = (avg_vol > 0) ? (liquidity / avg_vol >= m_min_liquidity_ratio) : true;

   if(!result.liquidity_ok)
      result.rejection_reason = "Liquidite insuffisante a l'entree";

   //--- 2. Verifier que l'imbalance confirme le signal
   if(direction == SIGNAL_BUY)
      result.imbalance_confirms = (m_imbalance.direction == IMBALANCE_BULLISH ||
                                    m_imbalance.direction == IMBALANCE_EXTREME_B);
   else
      result.imbalance_confirms = (m_imbalance.direction == IMBALANCE_BEARISH ||
                                    m_imbalance.direction == IMBALANCE_EXTREME_S);

   //--- 3. Verifier le support/resistance des murs
   double nearest_wall = FindNearestWall(entry_price, direction);
   result.wall_supports = (nearest_wall > 0);

   //--- 4. Calculer l'ajustement SL base sur les murs
   if(result.wall_supports)
      result.wall_sl_adjust = AdjustSLForWall(stop_loss, nearest_wall, direction);
   else
      result.wall_sl_adjust = stop_loss;

   //--- 5. Calculer le score de confiance global
   double score = 50.0; // Base neutre

   //--- Bonus liquidite
   if(result.liquidity_ok) score += 15.0;
   else score -= 20.0;

   //--- Bonus imbalance
   if(result.imbalance_confirms) score += 20.0;
   else score -= 10.0;

   //--- Bonus mur
   if(result.wall_supports) score += 15.0;

   //--- Bonus qualite des donnees
   if(m_quality == BOOK_QUALITY_HIGH) score += 5.0;
   else if(m_quality == BOOK_QUALITY_LOW) score -= 5.0;

   //--- Imbalance extreme = attention (potentiel retournement)
   if(m_imbalance.direction == IMBALANCE_EXTREME_B && direction == SIGNAL_SELL)
      score -= 15.0; // Vendre contre un imbalance extreme acheteur = risque
   if(m_imbalance.direction == IMBALANCE_EXTREME_S && direction == SIGNAL_BUY)
      score -= 15.0; // Acheter contre un imbalance extreme vendeur = risque

   result.confidence_score = MathMax(0.0, MathMin(100.0, score));

   return result;
  }

//+------------------------------------------------------------------+
//| Verifier s'il y a assez de liquidite a l'entree                  |
//+------------------------------------------------------------------+
bool COrderBookEngine::HasLiquidityAtEntry(double entry_price, double tolerance)
  {
   if(!m_enabled || m_state == ORDERBOOK_INACTIVE)
      return true; // Graceful: accepter si non disponible

   double atr = 0;
   // Utiliser la tolerance fournie ou calculer depuis le spread
   if(tolerance <= 0)
      tolerance = m_snapshot.spread * 5.0;

   double buy_liq = CalculateLiquidityAtPrice(entry_price, tolerance, SIGNAL_BUY);
   double sell_liq = CalculateLiquidityAtPrice(entry_price, tolerance, SIGNAL_SELL);
   double avg_vol = (m_imbalance.bid_avg_volume + m_imbalance.ask_avg_volume) / 2.0;

   if(avg_vol <= 0) return true;

   return (MathMax(buy_liq, sell_liq) / avg_vol >= m_min_liquidity_ratio);
  }

//+------------------------------------------------------------------+
//| Verifier si un mur supporte la direction                         |
//+------------------------------------------------------------------+
bool COrderBookEngine::HasWallSupport(ENUM_SIGNAL_TYPE direction, double reference_price)
  {
   if(!m_enabled || m_state == ORDERBOOK_INACTIVE)
      return false;

   double wall = FindNearestWall(reference_price, direction);
   return (wall > 0);
  }

//+------------------------------------------------------------------+
//| Obtenir le SL ajuste base sur les murs                           |
//+------------------------------------------------------------------+
double COrderBookEngine::GetAdjustedStopLoss(double current_sl, ENUM_SIGNAL_TYPE direction)
  {
   if(!m_enabled || m_state == ORDERBOOK_INACTIVE)
      return current_sl;

   double mid = m_snapshot.mid_price;
   if(mid <= 0) return current_sl;

   double wall = FindNearestWall(mid, direction);
   if(wall <= 0) return current_sl;

   return AdjustSLForWall(current_sl, wall, direction);
  }

//+------------------------------------------------------------------+
//| Accesseurs                                                       |
//+------------------------------------------------------------------+
SImbalanceResult COrderBookEngine::GetImbalance()
  { return m_imbalance; }

SOrderBookSnapshot COrderBookEngine::GetSnapshot()
  { return m_snapshot; }

int COrderBookEngine::GetWallCount()
  { return m_wall_count; }

SOrderWall COrderBookEngine::GetWall(int index)
  {
   if(index < 0 || index >= m_wall_count)
     {
      SOrderWall empty;
      ZeroMemory(empty);
      return empty;
     }
   return m_walls[index];
  }

SOrderWall COrderBookEngine::GetNearestWall(ENUM_SIGNAL_TYPE direction)
  {
   double mid = (m_snapshot.mid_price > 0) ? m_snapshot.mid_price : SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double wall_price = FindNearestWall(mid, direction);

   for(int i = 0; i < m_wall_count; i++)
     {
      if(m_walls[i].price == wall_price && m_walls[i].is_valid)
         return m_walls[i];
     }

   SOrderWall empty;
   ZeroMemory(empty);
   return empty;
  }

double COrderBookEngine::GetBidAskRatio()
  { return m_imbalance.ratio; }

ENUM_BOOK_QUALITY COrderBookEngine::GetBookQuality()
  { return m_quality; }

bool COrderBookEngine::IsAvailable()
  { return m_enabled && (m_state != ORDERBOOK_INACTIVE); }

//+------------------------------------------------------------------+
//| Statistiques                                                     |
//+------------------------------------------------------------------+
double COrderBookEngine::GetReadSuccessRate()
  {
   if(m_total_snapshots <= 0) return 0;
   return ((double)m_successful_reads / m_total_snapshots) * 100.0;
  }

int COrderBookEngine::GetTotalSnapshots()
  { return m_total_snapshots; }

string COrderBookEngine::GetStateName()
  {
   switch(m_state)
     {
      case ORDERBOOK_ACTIVE:  return "ACTIF";
      case ORDERBOOK_PARTIAL: return "PARTIEL";
      default:                return "INACTIF";
     }
  }

string COrderBookEngine::GetImbalanceName()
  {
   switch(m_imbalance.direction)
     {
      case IMBALANCE_EXTREME_B: return "EXTREME ACHETEUR";
      case IMBALANCE_BULLISH:   return "ACHETEUR";
      case IMBALANCE_BEARISH:   return "VENDEUR";
      case IMBALANCE_EXTREME_S: return "EXTREME VENDEUR";
      default:                  return "NEUTRE";
     }
  }

#endif // A2SNIPER_ORDER_BOOK_ENGINE_MQH
//+------------------------------------------------------------------+
