//+------------------------------------------------------------------+
//| SmartMoneyEngine.mqh - Concepts Smart Money & ICT                |
//| A2Sniper Ultimate v3.0                                           |
//| Premium/Discount, Order Blocks, FVG, Mitigation, Breaker Blocks  |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_SMC_MQH
#define A2SNIPER_SMC_MQH

#include "CommonTypes.mqh"
#include "MarketStructureEngine.mqh"
#include "OrderBlockEngine.mqh"
#include "FVGEngine.mqh"
#include "LiquidityEngine.mqh"

//+------------------------------------------------------------------+
//| Classe CSmartMoneyEngine                                         |
//+------------------------------------------------------------------+
class CSmartMoneyEngine
  {
private:
   bool              m_initialized;

   //--- Références
   CMarketStructureEngine *m_market_structure;
   COrderBlockEngine      *m_order_blocks;
   CFVGEngine             *m_fvg_engine;
   CLiquidityEngine       *m_liquidity_engine;

   //--- Données calculées
   double            m_premium_level;         // Zone Premium (au-dessus)
   double            m_discount_level;        // Zone Discount (en-dessous)
   double            m_equilibrium;           // Équilibre (50%)
   bool              m_is_premium;            // Prix en zone Premium
   bool              m_is_discount;           // Prix en zone Discount

   //--- Méthodes privées
   void              CalculatePremiumDiscount();
   double            GetSwingHighForRange() const;
   double            GetSwingLowForRange() const;

public:
   //--- Constructeur / Destructeur
                     CSmartMoneyEngine();
                    ~CSmartMoneyEngine();

   //--- Initialisation
   bool              Initialize(CMarketStructureEngine *mse, COrderBlockEngine *obe,
                                 CFVGEngine *fvge, CLiquidityEngine *le);
   void              Deinitialize();

   //--- Mise à jour
   bool              Update();

   //--- Accesseurs
   double            GetPremiumLevel() const { return m_premium_level; }
   double            GetDiscountLevel() const { return m_discount_level; }
   double            GetEquilibrium() const { return m_equilibrium; }
   bool              IsPriceInPremium() const { return m_is_premium; }
   bool              IsPriceInDiscount() const { return m_is_discount; }

   //--- Vérifications SMC
   bool              HasSmartMoneyConfirmation(const ENUM_SIGNAL_TYPE direction) const;
   double            GetSMCScore(const ENUM_SIGNAL_TYPE direction) const;

   //--- Premium/Discount pour direction
   bool              IsDirectionAlignedWithPD(const ENUM_SIGNAL_TYPE direction) const;

   //--- Info
   string            GetSMCInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CSmartMoneyEngine::CSmartMoneyEngine() :
   m_initialized(false),
   m_market_structure(NULL),
   m_order_blocks(NULL),
   m_fvg_engine(NULL),
   m_liquidity_engine(NULL),
   m_premium_level(0),
   m_discount_level(0),
   m_equilibrium(0),
   m_is_premium(false),
   m_is_discount(false)
  {
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CSmartMoneyEngine::~CSmartMoneyEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CSmartMoneyEngine::Initialize(CMarketStructureEngine *mse, COrderBlockEngine *obe,
                                     CFVGEngine *fvge, CLiquidityEngine *le)
  {
   if(mse == NULL || obe == NULL || fvge == NULL || le == NULL)
     {
      Print("A2Sniper SME: Erreur - moteurs dépendants NULL");
      return false;
     }

   m_market_structure = mse;
   m_order_blocks = obe;
   m_fvg_engine = fvge;
   m_liquidity_engine = le;

   m_initialized = true;
   Print("A2Sniper SME: Smart Money Engine initialisé");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CSmartMoneyEngine::Deinitialize()
  {
   m_market_structure = NULL;
   m_order_blocks = NULL;
   m_fvg_engine = NULL;
   m_liquidity_engine = NULL;
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Calculer les zones Premium/Discount                              |
//+------------------------------------------------------------------+
void CSmartMoneyEngine::CalculatePremiumDiscount()
  {
   double range_high = GetSwingHighForRange();
   double range_low = GetSwingLowForRange();

   if(range_high <= range_low)
      return;

   double range = range_high - range_low;
   m_equilibrium = range_low + range * 0.5;
   m_premium_level = range_low + range * 0.75;   // Au-dessus de 75% = Premium
   m_discount_level = range_low + range * 0.25;   // En-dessous de 25% = Discount

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
   m_is_premium = (current_price >= m_premium_level);
   m_is_discount = (current_price <= m_discount_level);
  }

//+------------------------------------------------------------------+
//| Obtenir le Swing High pour la plage                              |
//+------------------------------------------------------------------+
double CSmartMoneyEngine::GetSwingHighForRange() const
  {
   if(m_market_structure != NULL)
     {
      double sh = m_market_structure->GetLastSwingHigh(PERIOD_CURRENT);
      if(sh > 0) return sh;
     }

   //--- Fallback: chercher le plus haut sur 50 barres
   double highest = 0;
   for(int i = 1; i < 50; i++)
     {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      if(h > highest) highest = h;
     }
   return highest;
  }

//+------------------------------------------------------------------+
//| Obtenir le Swing Low pour la plage                               |
//+------------------------------------------------------------------+
double CSmartMoneyEngine::GetSwingLowForRange() const
  {
   if(m_market_structure != NULL)
     {
      double sl = m_market_structure->GetLastSwingLow(PERIOD_CURRENT);
      if(sl > 0) return sl;
     }

   double lowest = DBL_MAX;
   for(int i = 1; i < 50; i++)
     {
      double l = iLow(_Symbol, PERIOD_CURRENT, i);
      if(l < lowest && l > 0) lowest = l;
     }
   return lowest;
  }

//+------------------------------------------------------------------+
//| Mise à jour                                                      |
//+------------------------------------------------------------------+
bool CSmartMoneyEngine::Update()
  {
   if(!m_initialized)
      return false;

   CalculatePremiumDiscount();
   return true;
  }

//+------------------------------------------------------------------+
//| Confirmation Smart Money pour une direction                       |
//+------------------------------------------------------------------+
bool CSmartMoneyEngine::HasSmartMoneyConfirmation(const ENUM_SIGNAL_TYPE direction) const
  {
   if(!m_initialized)
      return false;

   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
   int confirmations = 0;

   //--- 1. Prix dans la bonne zone Premium/Discount
   if(IsDirectionAlignedWithPD(direction))
      confirmations++;

   //--- 2. Order Block présent dans la direction
   if(m_order_blocks != NULL)
     {
      ENUM_OB_TYPE ob_type = (direction == SIGNAL_BUY) ? OB_BULLISH : OB_BEARISH;
      if(m_order_blocks->IsPriceAtOB(current_price, ob_type))
         confirmations++;
     }

   //--- 3. FVG dans la direction
   if(m_fvg_engine != NULL)
     {
      ENUM_FVG_TYPE fvg_type = (direction == SIGNAL_BUY) ? FVG_BULLISH : FVG_BEARISH;
      if(m_fvg_engine->IsPriceInFVG(current_price, fvg_type))
         confirmations++;
     }

   //--- 4. Liquidity sweep dans la direction opposée
   if(m_liquidity_engine != NULL)
     {
      if(m_liquidity_engine->HasLiquiditySweepForDirection(direction))
         confirmations++;
     }

   //--- Au moins 2 confirmations sur 4
   return (confirmations >= 2);
  }

//+------------------------------------------------------------------+
//| La direction est-elle alignée avec Premium/Discount ?            |
//+------------------------------------------------------------------+
bool CSmartMoneyEngine::IsDirectionAlignedWithPD(const ENUM_SIGNAL_TYPE direction) const
  {
   //--- Achat en zone Discount (acheter pas cher)
   if(direction == SIGNAL_BUY && m_is_discount)
      return true;
   //--- Vente en zone Premium (vendre cher)
   if(direction == SIGNAL_SELL && m_is_premium)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//| Score SMC global (0-100)                                         |
//+------------------------------------------------------------------+
double CSmartMoneyEngine::GetSMCScore(const ENUM_SIGNAL_TYPE direction) const
  {
   if(!m_initialized)
      return 0;

   double score = 0;
   double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);

   //--- Premium/Discount (25 pts)
   if(IsDirectionAlignedWithPD(direction))
      score += 25;

   //--- Order Block (25 pts)
   if(m_order_blocks != NULL)
     {
      ENUM_OB_TYPE ob_type = (direction == SIGNAL_BUY) ? OB_BULLISH : OB_BEARISH;
      double ob_score = m_order_blocks->GetOBScoreAtPrice(current_price, ob_type);
      score += ob_score * 0.25;
     }

   //--- FVG (25 pts)
   if(m_fvg_engine != NULL)
     {
      ENUM_FVG_TYPE fvg_type = (direction == SIGNAL_BUY) ? FVG_BULLISH : FVG_BEARISH;
      double fvg_score = m_fvg_engine->GetFVGScoreAtPrice(current_price, fvg_type);
      score += fvg_score * 0.25;
     }

   //--- Liquidity (25 pts)
   if(m_liquidity_engine != NULL)
     {
      double liq_score = m_liquidity_engine->GetLiquidityScore(direction);
      score += liq_score * 0.25;
     }

   return MathMin(score, 100.0);
  }

//+------------------------------------------------------------------+
//| Info SMC                                                         |
//+------------------------------------------------------------------+
string CSmartMoneyEngine::GetSMCInfo() const
  {
   return StringFormat("SMC: Premium=%.5f Discount=%.5f Eq=%.5f | InPremium=%s InDiscount=%s",
                       m_premium_level, m_discount_level, m_equilibrium,
                       m_is_premium ? "Y" : "N", m_is_discount ? "Y" : "N");
  }

#endif // A2SNIPER_SMC_MQH
//+------------------------------------------------------------------+
