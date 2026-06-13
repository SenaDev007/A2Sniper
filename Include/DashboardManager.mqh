//+------------------------------------------------------------------+
//| DashboardManager.mqh - Dashboard Professionnel MODERNE           |
//| A2Sniper Ultimate v3.0                                           |
//| Design: Dark theme pro, panneaux élégants                        |
//| Compatible: PC + Mobile MT5                                      |
//| Affichage: Balance, Equity, DD, Win Rate, PF, Score, Session     |
//| Visualisations: OB zones, FVG zones, SL/TP lines, signaux       |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_DASHBOARD_MQH
#define A2SNIPER_DASHBOARD_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Constantes de design (compatibles PC + Mobile)                    |
//+------------------------------------------------------------------+
#define DASH_PREFIX          "A2S_"
#define DASH_CHART_PREFIX    "A2C_"    // Prefix pour objets chart
#define DASH_PANEL_W         310
#define DASH_PANEL_H         580
#define DASH_LEFT_MARGIN     15
#define DASH_TOP_MARGIN      25
#define DASH_LINE_H          17
#define DASH_SECTION_GAP     6

//--- Polices compatibles PC + Mobile MT5
//--- "Arial" est universellement disponible sur MT5 Desktop ET Mobile
//--- "Courier New" pour monospace sur PC et Mobile
#define DASH_FONT_MAIN       "Arial"
#define DASH_FONT_MONO       "Courier New"
#define DASH_FONT_SIZE_H1    11
#define DASH_FONT_SIZE_H2    9
#define DASH_FONT_SIZE_BODY  8
#define DASH_FONT_SIZE_SMALL 7
#define DASH_FONT_SIZE_BIG   13

//+------------------------------------------------------------------+
//| Palette de couleurs moderne                                      |
//+------------------------------------------------------------------+
#define CLR_BG_DARK          C'12,14,20'       // Fond principal tres sombre
#define CLR_BG_PANEL         C'18,22,32'       // Fond panneau
#define CLR_BG_SECTION       C'22,28,40'       // Fond section
#define CLR_BORDER_SUBTLE    C'35,42,58'       // Bordure discrete
#define CLR_TEXT_PRIMARY     C'230,235,245'    // Texte principal
#define CLR_TEXT_SECONDARY   C'130,145,170'    // Texte secondaire
#define CLR_TEXT_DIM         C'80,90,110'      // Texte discret
#define CLR_ACCENT_BLUE      C'0,160,255'      // Accent bleu
#define CLR_ACCENT_CYAN      C'0,210,210'      // Accent cyan
#define CLR_ACCENT_PURPLE    C'130,80,255'     // Accent violet
#define CLR_GREEN_BRIGHT     C'0,220,120'      // Vert vif
#define CLR_GREEN_SOFT       C'60,180,120'     // Vert doux
#define CLR_RED_BRIGHT       C'240,55,80'      // Rouge vif
#define CLR_RED_SOFT         C'200,80,80'      // Rouge doux
#define CLR_YELLOW_BRIGHT    C'255,200,0'      // Jaune vif
#define CLR_ORANGE           C'255,140,0'      // Orange

//--- Couleurs pour les visualisations chart
#define CLR_OB_BULLISH       C'0,180,100'      // OB haussier (vert)
#define CLR_OB_BEARISH       C'220,50,70'      // OB baissier (rouge)
#define CLR_FVG_BULLISH      C'0,140,220'      // FVG haussier (bleu)
#define CLR_FVG_BEARISH      C'180,60,180'     // FVG baissier (violet)
#define CLR_LIQ_BSL          C'255,180,0'      // BSL (jaune)
#define CLR_LIQ_SSL          C'0,200,200'      // SSL (cyan)
#define CLR_SL_LINE          C'240,55,80'      // Stop Loss (rouge)
#define CLR_TP_LINE          C'0,220,120'      // Take Profit (vert)
#define CLR_ENTRY_LINE       C'0,160,255'      // Entry (bleu)

//+------------------------------------------------------------------+
//| Classe CDashboardManager                                         |
//+------------------------------------------------------------------+
class CDashboardManager
  {
private:
   bool              m_initialized;
   bool              m_visible;
   int               m_x;
   int               m_y;
   bool              m_objects_created;

   //--- Dernieres donnees affichees
   SStatistics       m_stats;
   double            m_active_score;
   string            m_active_session;
   string            m_active_signal;
   string            m_sre_class;
   double            m_daily_dd;
   double            m_weekly_dd;
   double            m_risk_pct;
   int               m_open_trades;
   bool              m_suspended;

   //--- Donnees pour visualisations chart
   int               m_chart_ob_bull_count;
   int               m_chart_ob_bear_count;
   int               m_chart_fvg_bull_count;
   int               m_chart_fvg_bear_count;
   bool              m_has_active_trade;
   double            m_trade_entry;
   double            m_trade_sl;
   double            m_trade_tp1;
   double            m_trade_tp2;
   double            m_trade_tp3;
   ENUM_SIGNAL_TYPE  m_trade_direction;

   //--- Methodes de creation de panneaux
   void              CreateBackground();
   void              CreateHeaderSection(int &y);
   void              CreateAccountSection(int &y);
   void              CreatePerformanceSection(int &y);
   void              CreateSignalSection(int &y);
   void              CreateRiskSection(int &y);
   void              CreateSessionSection(int &y);
   void              CreateEngineSection(int &y);
   void              CreateFooterSection(int &y);

   //--- Methodes de mise a jour
   void              UpdateHeaderSection();
   void              UpdateAccountSection();
   void              UpdatePerformanceSection();
   void              UpdateSignalSection();
   void              UpdateRiskSection();
   void              UpdateSessionSection();
   void              UpdateEngineSection();

   //--- Methodes utilitaires
   void              CreateRectLabel(const string name, int x, int y, int w, int h,
                                       color bg_clr, color border_clr = clrNONE, int corner = CORNER_LEFT_UPPER);
   void              CreateTextLabel(const string name, const string text, int x, int y,
                                       color clr, string font_name = DASH_FONT_MAIN,
                                       int font_size = DASH_FONT_SIZE_BODY, int corner = CORNER_LEFT_UPPER);
   void              UpdateText(const string name, const string text, color clr = clrNONE);
   void              UpdateRectColor(const string name, color bg_clr, color border_clr = clrNONE);
   void              DeleteAll();
   void              DeleteChartObjects();
   string            FmtDbl(double val, int dec = 2) const;
   string            FmtPct(double val, int dec = 1) const;
   string            FmtMoney(double val) const;
   color             GetWRColor(double wr) const;
   color             GetPFColor(double pf) const;
   color             GetDDColor(double dd) const;
   color             GetScoreColor(double score) const;

public:
   //--- Constructeur / Destructeur
                     CDashboardManager();
                    ~CDashboardManager();

   //--- Initialisation
   bool              Initialize(int x = 10, int y = 25, bool visible = true);
   void              Deinitialize();

   //--- Mise a jour principale
   bool              Update(const SStatistics &stats, double active_score = 0,
                             string session = "", string signal = "",
                             string sre_class = "", double daily_dd = 0,
                             double weekly_dd = 0, double risk_pct = 0,
                             int open_trades = 0, bool suspended = false);

   //--- Visualisations chart
   void              DrawOrderBlocks(const SOrderBlock &obs[], int count);
   void              DrawFVGZones(const SFVG &fvgs[], int count);
   void              DrawLiquidityZones(const SLiquidityZone &zones[], int count);
   void              DrawTradeLevels(double entry, double sl, double tp1, double tp2, double tp3,
                                      ENUM_SIGNAL_TYPE direction);
   void              ClearTradeLevels();

   //--- Controle
   void              Show() { m_visible = true; CreateBackground(); }
   void              Hide() { m_visible = false; DeleteAll(); }
   bool              IsVisible() const { return m_visible; }

   //--- Info
   string            GetDashboardInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CDashboardManager::CDashboardManager() :
   m_initialized(false),
   m_visible(true),
   m_x(10),
   m_y(25),
   m_objects_created(false),
   m_active_score(0),
   m_active_session(""),
   m_active_signal("NONE"),
   m_sre_class(""),
   m_daily_dd(0),
   m_weekly_dd(0),
   m_risk_pct(0),
   m_open_trades(0),
   m_suspended(false),
   m_chart_ob_bull_count(0),
   m_chart_ob_bear_count(0),
   m_chart_fvg_bull_count(0),
   m_chart_fvg_bear_count(0),
   m_has_active_trade(false),
   m_trade_entry(0),
   m_trade_sl(0),
   m_trade_tp1(0),
   m_trade_tp2(0),
   m_trade_tp3(0),
   m_trade_direction(SIGNAL_NONE)
  {
   ZeroMemory(m_stats);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CDashboardManager::~CDashboardManager()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CDashboardManager::Initialize(int x, int y, bool visible)
  {
   m_x = x;
   m_y = y;
   m_visible = visible;
   DeleteAll();
   DeleteChartObjects();
   m_initialized = true;
   Print("A2Sniper DM: Dashboard Manager initialise (Modern Design - PC/Mobile)");
   return true;
  }

//+------------------------------------------------------------------+
//| Desinitialisation                                                |
//+------------------------------------------------------------------+
void CDashboardManager::Deinitialize()
  {
   DeleteAll();
   DeleteChartObjects();
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Creer un rectangle (panneau/section)                             |
//+------------------------------------------------------------------+
void CDashboardManager::CreateRectLabel(const string name, int x, int y, int w, int h,
                                           color bg_clr, color border_clr, int corner)
  {
   string full_name = DASH_PREFIX + name;
   if(ObjectFind(0, full_name) < 0)
     {
      ObjectCreate(0, full_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
     }
   ObjectSetInteger(0, full_name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, full_name, OBJPROP_XDISTANCE, m_x + x);
   ObjectSetInteger(0, full_name, OBJPROP_YDISTANCE, m_y + y);
   ObjectSetInteger(0, full_name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, full_name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, full_name, OBJPROP_BGCOLOR, bg_clr);
   ObjectSetInteger(0, full_name, OBJPROP_COLOR, (border_clr != clrNONE) ? border_clr : CLR_BORDER_SUBTLE);
   ObjectSetInteger(0, full_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, full_name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, full_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, full_name, OBJPROP_BACK, false);
  }

//+------------------------------------------------------------------+
//| Creer un label texte                                             |
//+------------------------------------------------------------------+
void CDashboardManager::CreateTextLabel(const string name, const string text, int x, int y,
                                           color clr, string font_name, int font_size, int corner)
  {
   string full_name = DASH_PREFIX + name;
   if(ObjectFind(0, full_name) < 0)
     {
      ObjectCreate(0, full_name, OBJ_LABEL, 0, 0, 0);
     }
   ObjectSetInteger(0, full_name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, full_name, OBJPROP_XDISTANCE, m_x + x);
   ObjectSetInteger(0, full_name, OBJPROP_YDISTANCE, m_y + y);
   ObjectSetString(0, full_name, OBJPROP_FONT, font_name);
   ObjectSetInteger(0, full_name, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger(0, full_name, OBJPROP_COLOR, clr);
   ObjectSetString(0, full_name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, full_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, full_name, OBJPROP_BACK, false);
  }

//+------------------------------------------------------------------+
//| Mettre a jour un texte                                           |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateText(const string name, const string text, color clr)
  {
   string full_name = DASH_PREFIX + name;
   if(ObjectFind(0, full_name) >= 0)
     {
      ObjectSetString(0, full_name, OBJPROP_TEXT, text);
      if(clr != clrNONE)
         ObjectSetInteger(0, full_name, OBJPROP_COLOR, clr);
     }
  }

//+------------------------------------------------------------------+
//| Mettre a jour la couleur d'un rectangle                          |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateRectColor(const string name, color bg_clr, color border_clr)
  {
   string full_name = DASH_PREFIX + name;
   if(ObjectFind(0, full_name) >= 0)
     {
      ObjectSetInteger(0, full_name, OBJPROP_BGCOLOR, bg_clr);
      if(border_clr != clrNONE)
         ObjectSetInteger(0, full_name, OBJPROP_COLOR, border_clr);
     }
  }

//+------------------------------------------------------------------+
//| Supprimer tous les objets dashboard                              |
//+------------------------------------------------------------------+
void CDashboardManager::DeleteAll()
  {
   ObjectsDeleteAll(0, DASH_PREFIX);
   m_objects_created = false;
  }

//+------------------------------------------------------------------+
//| Supprimer tous les objets chart                                  |
//+------------------------------------------------------------------+
void CDashboardManager::DeleteChartObjects()
  {
   ObjectsDeleteAll(0, DASH_CHART_PREFIX);
  }

//+------------------------------------------------------------------+
//| Formatters                                                       |
//+------------------------------------------------------------------+
string CDashboardManager::FmtDbl(double val, int dec) const { return DoubleToString(val, dec); }
string CDashboardManager::FmtPct(double val, int dec) const { return DoubleToString(val, dec) + "%"; }
string CDashboardManager::FmtMoney(double val) const
  {
   string sign = (val >= 0) ? "+" : "";
   return sign + DoubleToString(val, 2);
  }

//+------------------------------------------------------------------+
//| Couleurs contextuelles                                           |
//+------------------------------------------------------------------+
color CDashboardManager::GetWRColor(double wr) const
  {
   if(wr >= 65) return CLR_GREEN_BRIGHT;
   if(wr >= 50) return CLR_YELLOW_BRIGHT;
   if(wr >= 35) return CLR_ORANGE;
   return CLR_RED_BRIGHT;
  }

color CDashboardManager::GetPFColor(double pf) const
  {
   if(pf >= 2.0) return CLR_GREEN_BRIGHT;
   if(pf >= 1.5) return CLR_GREEN_SOFT;
   if(pf >= 1.0) return CLR_YELLOW_BRIGHT;
   return CLR_RED_BRIGHT;
  }

color CDashboardManager::GetDDColor(double dd) const
  {
   if(dd <= 3) return CLR_GREEN_BRIGHT;
   if(dd <= 5) return CLR_GREEN_SOFT;
   if(dd <= 8) return CLR_YELLOW_BRIGHT;
   if(dd <= 12) return CLR_ORANGE;
   return CLR_RED_BRIGHT;
  }

color CDashboardManager::GetScoreColor(double score) const
  {
   if(score >= 90) return CLR_GREEN_BRIGHT;
   if(score >= 75) return CLR_YELLOW_BRIGHT;
   if(score >= 60) return CLR_ORANGE;
   return CLR_RED_BRIGHT;
  }

//+------------------------------------------------------------------+
//| Creer le fond principal                                          |
//+------------------------------------------------------------------+
void CDashboardManager::CreateBackground()
  {
   //--- Fond principal du dashboard
   CreateRectLabel("bg_main", 0, 0, DASH_PANEL_W, DASH_PANEL_H + 10, CLR_BG_PANEL, CLR_BORDER_SUBTLE);

   //--- Barre d'accent en haut (bleu degrade)
   CreateRectLabel("accent_bar", 0, 0, DASH_PANEL_W, 3, CLR_ACCENT_BLUE, CLR_ACCENT_BLUE);
  }

//+------------------------------------------------------------------+
//| Creer la section En-tete                                         |
//+------------------------------------------------------------------+
void CDashboardManager::CreateHeaderSection(int &y)
  {
   y += 8;
   //--- Logo / Titre (sans symboles Unicode speciaux pour compatibilite mobile)
   CreateTextLabel("hdr_icon", ">>", 8, y, CLR_ACCENT_CYAN, DASH_FONT_MONO, DASH_FONT_SIZE_H1);
   CreateTextLabel("hdr_title", "A2SNIPER ULTIMATE", 40, y, CLR_TEXT_PRIMARY, DASH_FONT_MAIN, DASH_FONT_SIZE_H1);
   y += DASH_LINE_H + 2;
   CreateTextLabel("hdr_version", "  v3.0 | SMC - ICT - AI", 8, y, CLR_TEXT_DIM, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   y += DASH_LINE_H + 2;

   //--- Ligne de separation
   CreateRectLabel("hdr_sep", 8, y, DASH_PANEL_W - 16, 1, CLR_BORDER_SUBTLE, CLR_BORDER_SUBTLE);
   y += DASH_SECTION_GAP;
  }

//+------------------------------------------------------------------+
//| Creer la section Compte                                          |
//+------------------------------------------------------------------+
void CDashboardManager::CreateAccountSection(int &y)
  {
   //--- Section header
   CreateTextLabel("acc_title", "  > ACCOUNT", 8, y, CLR_ACCENT_CYAN, DASH_FONT_MAIN, DASH_FONT_SIZE_H2);
   y += DASH_LINE_H + 2;

   //--- Fond de section
   CreateRectLabel("acc_bg", 8, y, DASH_PANEL_W - 16, 50, CLR_BG_SECTION, CLR_BORDER_SUBTLE);
   int inner_y = y + 6;

   CreateTextLabel("acc_bal_lbl", "    Balance", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("acc_bal_val", "$0.00", 165, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   inner_y += DASH_LINE_H;

   CreateTextLabel("acc_eq_lbl", "    Equity", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("acc_eq_val", "$0.00", 165, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   inner_y += DASH_LINE_H;

   CreateTextLabel("acc_pnl_lbl", "    P&L", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("acc_pnl_val", "+$0.00", 165, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);

   y += 56;
   y += DASH_SECTION_GAP;
  }

//+------------------------------------------------------------------+
//| Creer la section Performance                                     |
//+------------------------------------------------------------------+
void CDashboardManager::CreatePerformanceSection(int &y)
  {
   CreateTextLabel("perf_title", "  > PERFORMANCE", 8, y, CLR_ACCENT_PURPLE, DASH_FONT_MAIN, DASH_FONT_SIZE_H2);
   y += DASH_LINE_H + 2;

   CreateRectLabel("perf_bg", 8, y, DASH_PANEL_W - 16, 90, CLR_BG_SECTION, CLR_BORDER_SUBTLE);
   int inner_y = y + 6;

   //--- Ligne 1: Win Rate | Profit Factor
   CreateTextLabel("perf_wr_lbl", "    Win Rate", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_wr_val", "0.0%", 130, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   CreateTextLabel("perf_pf_lbl", "PF", 210, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_pf_val", "0.00", 230, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   inner_y += DASH_LINE_H;

   //--- Ligne 2: Drawdown | Avg R:R
   CreateTextLabel("perf_dd_lbl", "    Max DD", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_dd_val", "0.0%", 130, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   CreateTextLabel("perf_rr_lbl", "Avg R", 210, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_rr_val", "1:0.0", 240, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   inner_y += DASH_LINE_H;

   //--- Ligne 3: Trades | Sharpe
   CreateTextLabel("perf_tr_lbl", "    Trades", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_tr_val", "0", 130, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   CreateTextLabel("perf_sh_lbl", "Sharpe", 210, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_sh_val", "0.00", 255, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   inner_y += DASH_LINE_H;

   //--- Ligne 4: Recovery Factor | Expectancy
   CreateTextLabel("perf_rf_lbl", "    Recovery", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_rf_val", "0.00", 130, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   CreateTextLabel("perf_ex_lbl", "Expect", 210, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("perf_ex_val", "0.00", 255, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);

   y += 96;
   y += DASH_SECTION_GAP;
  }

//+------------------------------------------------------------------+
//| Creer la section Signal                                          |
//+------------------------------------------------------------------+
void CDashboardManager::CreateSignalSection(int &y)
  {
   CreateTextLabel("sig_title", "  > ACTIVE SIGNAL", 8, y, CLR_GREEN_BRIGHT, DASH_FONT_MAIN, DASH_FONT_SIZE_H2);
   y += DASH_LINE_H + 2;

   CreateRectLabel("sig_bg", 8, y, DASH_PANEL_W - 16, 68, CLR_BG_SECTION, CLR_BORDER_SUBTLE);
   int inner_y = y + 6;

   //--- Score principal (grand)
   CreateTextLabel("sig_score_lbl", "    AI Score", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("sig_score_val", "0", 145, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_BIG);
   CreateTextLabel("sig_score_max", "/100", 185, inner_y, CLR_TEXT_DIM, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   inner_y += DASH_LINE_H + 6;

   //--- Direction + SRE Class
   CreateTextLabel("sig_dir_lbl", "    Direction", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("sig_dir_val", "NONE", 145, inner_y, CLR_TEXT_DIM, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   CreateTextLabel("sig_class_lbl", "Class", 225, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("sig_class_val", "--", 265, inner_y, CLR_TEXT_DIM, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);
   inner_y += DASH_LINE_H;

   //--- SRE Score bar indicator
   CreateTextLabel("sig_sre_lbl", "    SRE", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateRectLabel("sig_sre_bar_bg", 145, inner_y + 3, 120, 8, C'30,35,50', C'30,35,50');
   CreateRectLabel("sig_sre_bar", 145, inner_y + 3, 0, 8, CLR_ACCENT_BLUE, CLR_ACCENT_BLUE);
   CreateTextLabel("sig_sre_pct", "0", 270, inner_y, CLR_TEXT_DIM, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);

   y += 74;
   y += DASH_SECTION_GAP;
  }

//+------------------------------------------------------------------+
//| Creer la section Risque                                          |
//+------------------------------------------------------------------+
void CDashboardManager::CreateRiskSection(int &y)
  {
   CreateTextLabel("risk_title", "  > RISK MANAGEMENT", 8, y, CLR_ORANGE, DASH_FONT_MAIN, DASH_FONT_SIZE_H2);
   y += DASH_LINE_H + 2;

   CreateRectLabel("risk_bg", 8, y, DASH_PANEL_W - 16, 50, CLR_BG_SECTION, CLR_BORDER_SUBTLE);
   int inner_y = y + 6;

   CreateTextLabel("risk_dd_lbl", "    Daily DD", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("risk_dd_val", "0.0%", 130, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   CreateTextLabel("risk_wdd_lbl", "Week DD", 210, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("risk_wdd_val", "0.0%", 262, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   inner_y += DASH_LINE_H;

   CreateTextLabel("risk_risk_lbl", "    Risk/Trade", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("risk_risk_val", "1.0%", 130, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   CreateTextLabel("risk_pos_lbl", "Positions", 210, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("risk_pos_val", "0/3", 262, inner_y, CLR_TEXT_PRIMARY, DASH_FONT_MONO, DASH_FONT_SIZE_BODY);
   inner_y += DASH_LINE_H;

   //--- Statut de suspension
   CreateTextLabel("risk_status_lbl", "    Status", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("risk_status_val", "[ACTIVE]", 130, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MAIN, DASH_FONT_SIZE_BODY);

   y += 56;
   y += DASH_SECTION_GAP;
  }

//+------------------------------------------------------------------+
//| Creer la section Session                                         |
//+------------------------------------------------------------------+
void CDashboardManager::CreateSessionSection(int &y)
  {
   CreateTextLabel("ses_title", "  > SESSION", 8, y, CLR_ACCENT_BLUE, DASH_FONT_MAIN, DASH_FONT_SIZE_H2);
   y += DASH_LINE_H + 2;

   CreateRectLabel("ses_bg", 8, y, DASH_PANEL_W - 16, 32, CLR_BG_SECTION, CLR_BORDER_SUBTLE);
   int inner_y = y + 6;

   CreateTextLabel("ses_name_lbl", "    Active", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("ses_name_val", "Off-Session", 100, inner_y, CLR_ACCENT_BLUE, DASH_FONT_MAIN, DASH_FONT_SIZE_BODY);
   CreateTextLabel("ses_kz_lbl", "KZ", 220, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("ses_kz_val", "--", 240, inner_y, CLR_TEXT_DIM, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);

   y += 38;
   y += DASH_SECTION_GAP;
  }

//+------------------------------------------------------------------+
//| Creer la section Moteurs (Engine Status)                         |
//+------------------------------------------------------------------+
void CDashboardManager::CreateEngineSection(int &y)
  {
   CreateTextLabel("eng_title", "  > ENGINES", 8, y, CLR_ACCENT_CYAN, DASH_FONT_MAIN, DASH_FONT_SIZE_H2);
   y += DASH_LINE_H + 2;

   CreateRectLabel("eng_bg", 8, y, DASH_PANEL_W - 16, 32, CLR_BG_SECTION, CLR_BORDER_SUBTLE);
   int inner_y = y + 6;

   CreateTextLabel("eng_ob_lbl", "    OB", 8, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("eng_ob_bull", "B:0", 65, inner_y, CLR_GREEN_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("eng_ob_bear", "S:0", 105, inner_y, CLR_RED_BRIGHT, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("eng_fvg_lbl", "FVG", 145, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("eng_fvg_bull", "B:0", 180, inner_y, CLR_FVG_BULLISH, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("eng_fvg_bear", "S:0", 215, inner_y, CLR_FVG_BEARISH, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("eng_liq_lbl", "LIQ", 248, inner_y, CLR_TEXT_SECONDARY, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
   CreateTextLabel("eng_liq_val", "0", 278, inner_y, CLR_LIQ_BSL, DASH_FONT_MONO, DASH_FONT_SIZE_SMALL);

   y += 38;
  }

//+------------------------------------------------------------------+
//| Creer la section Footer                                          |
//+------------------------------------------------------------------+
void CDashboardManager::CreateFooterSection(int &y)
  {
   y += 4;
   CreateRectLabel("foot_sep", 8, y, DASH_PANEL_W - 16, 1, CLR_BORDER_SUBTLE, CLR_BORDER_SUBTLE);
   y += 6;
   CreateTextLabel("foot_text", "  SMC - ICT - Strategic Reversal - AI Scoring", 8, y, CLR_TEXT_DIM, DASH_FONT_MAIN, DASH_FONT_SIZE_SMALL);
  }

//+------------------------------------------------------------------+
//| Mise a jour section En-tete                                      |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateHeaderSection()
  {
   //--- Pas de mise a jour dynamique necessaire pour le header
  }

//+------------------------------------------------------------------+
//| Mise a jour section Compte                                       |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateAccountSection()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl     = equity - balance;

   UpdateText("acc_bal_val", "$" + FmtDbl(balance, 2), CLR_TEXT_PRIMARY);
   UpdateText("acc_eq_val", "$" + FmtDbl(equity, 2), CLR_TEXT_PRIMARY);

   color pnl_clr = (pnl >= 0) ? CLR_GREEN_BRIGHT : CLR_RED_BRIGHT;
   UpdateText("acc_pnl_val", FmtMoney(pnl), pnl_clr);
  }

//+------------------------------------------------------------------+
//| Mise a jour section Performance                                  |
//+------------------------------------------------------------------+
void CDashboardManager::UpdatePerformanceSection()
  {
   UpdateText("perf_wr_val", FmtPct(m_stats.win_rate), GetWRColor(m_stats.win_rate));
   UpdateText("perf_pf_val", FmtDbl(m_stats.profit_factor, 2), GetPFColor(m_stats.profit_factor));
   UpdateText("perf_dd_val", FmtPct(m_stats.max_drawdown), GetDDColor(m_stats.max_drawdown));
   UpdateText("perf_rr_val", "1:" + FmtDbl(m_stats.avg_rr, 1), CLR_TEXT_PRIMARY);
   UpdateText("perf_tr_val", IntegerToString(m_stats.total_trades), CLR_TEXT_PRIMARY);
   UpdateText("perf_sh_val", FmtDbl(m_stats.sharpe_ratio, 2), CLR_TEXT_PRIMARY);
   UpdateText("perf_rf_val", FmtDbl(m_stats.recovery_factor, 2), CLR_TEXT_PRIMARY);
   UpdateText("perf_ex_val", FmtDbl(m_stats.expectancy, 2), CLR_TEXT_PRIMARY);
  }

//+------------------------------------------------------------------+
//| Mise a jour section Signal                                       |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateSignalSection()
  {
   UpdateText("sig_score_val", IntegerToString((int)m_active_score), GetScoreColor(m_active_score));

   //--- Direction
   color dir_clr = CLR_TEXT_DIM;
   if(m_active_signal == "BUY") dir_clr = CLR_GREEN_BRIGHT;
   else if(m_active_signal == "SELL") dir_clr = CLR_RED_BRIGHT;
   UpdateText("sig_dir_val", m_active_signal, dir_clr);

   //--- SRE Class
   color class_clr = CLR_TEXT_DIM;
   if(m_sre_class == "ELITE") class_clr = CLR_ACCENT_CYAN;
   else if(m_sre_class == "SNIPER") class_clr = CLR_GREEN_BRIGHT;
   else if(m_sre_class == "STANDARD") class_clr = CLR_YELLOW_BRIGHT;
   else if(m_sre_class == "WEAK") class_clr = CLR_ORANGE;
   UpdateText("sig_class_val", (m_sre_class == "") ? "--" : m_sre_class, class_clr);

   //--- SRE bar (proportion du score sur 100)
   int bar_width = (int)(m_active_score / 100.0 * 120);
   bar_width = MathMax(0, MathMin(120, bar_width));
   UpdateRectColor("sig_sre_bar", GetScoreColor(m_active_score), GetScoreColor(m_active_score));

   //--- Redimensionner la barre
   string bar_name = DASH_PREFIX + "sig_sre_bar";
   if(ObjectFind(0, bar_name) >= 0)
      ObjectSetInteger(0, bar_name, OBJPROP_XSIZE, bar_width);

   UpdateText("sig_sre_pct", IntegerToString((int)m_active_score), CLR_TEXT_DIM);
  }

//+------------------------------------------------------------------+
//| Mise a jour section Risque                                       |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateRiskSection()
  {
   UpdateText("risk_dd_val", FmtPct(m_daily_dd), GetDDColor(m_daily_dd));
   UpdateText("risk_wdd_val", FmtPct(m_weekly_dd), GetDDColor(m_weekly_dd));
   UpdateText("risk_risk_val", FmtPct(m_risk_pct, 1), CLR_TEXT_PRIMARY);
   UpdateText("risk_pos_val", IntegerToString(m_open_trades) + "/3", CLR_TEXT_PRIMARY);

   if(m_suspended)
     {
      UpdateText("risk_status_val", "[SUSPENDED]", CLR_RED_BRIGHT);
      UpdateRectColor("risk_bg", C'35,18,18', CLR_RED_SOFT);
     }
   else
     {
      UpdateText("risk_status_val", "[ACTIVE]", CLR_GREEN_BRIGHT);
      UpdateRectColor("risk_bg", CLR_BG_SECTION, CLR_BORDER_SUBTLE);
     }
  }

//+------------------------------------------------------------------+
//| Mise a jour section Session                                      |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateSessionSection()
  {
   color ses_clr = CLR_TEXT_DIM;
   if(m_active_session == "London" || m_active_session == "London-NY Overlap")
      ses_clr = CLR_GREEN_BRIGHT;
   else if(m_active_session == "New York")
      ses_clr = CLR_YELLOW_BRIGHT;
   else if(m_active_session == "Asian")
      ses_clr = CLR_ACCENT_BLUE;

   UpdateText("ses_name_val", m_active_session, ses_clr);

   //--- Kill Zone indicator
   bool is_kz = (m_active_session == "London" || m_active_session == "London-NY Overlap");
   UpdateText("ses_kz_val", is_kz ? "ON" : "OFF", is_kz ? CLR_GREEN_BRIGHT : CLR_TEXT_DIM);
  }

//+------------------------------------------------------------------+
//| Mise a jour section Moteurs                                      |
//+------------------------------------------------------------------+
void CDashboardManager::UpdateEngineSection()
  {
   UpdateText("eng_ob_bull", "B:" + IntegerToString(m_chart_ob_bull_count), CLR_GREEN_BRIGHT);
   UpdateText("eng_ob_bear", "S:" + IntegerToString(m_chart_ob_bear_count), CLR_RED_BRIGHT);
   UpdateText("eng_fvg_bull", "B:" + IntegerToString(m_chart_fvg_bull_count), CLR_FVG_BULLISH);
   UpdateText("eng_fvg_bear", "S:" + IntegerToString(m_chart_fvg_bear_count), CLR_FVG_BEARISH);
   }

//+------------------------------------------------------------------+
//| Dessiner les Order Blocks sur le chart                           |
//+------------------------------------------------------------------+
void CDashboardManager::DrawOrderBlocks(const SOrderBlock &obs[], int count)
  {
   //--- Nettoyer les anciens OB
   for(int i = 0; i < 20; i++)
     {
      string name_bull = DASH_CHART_PREFIX + "OB_B_" + IntegerToString(i);
      string name_bear = DASH_CHART_PREFIX + "OB_S_" + IntegerToString(i);
      if(ObjectFind(0, name_bull) >= 0) ObjectDelete(0, name_bull);
      if(ObjectFind(0, name_bear) >= 0) ObjectDelete(0, name_bear);
     }

   int bull_idx = 0, bear_idx = 0;
   m_chart_ob_bull_count = 0;
   m_chart_ob_bear_count = 0;

   for(int i = 0; i < count && i < 20; i++)
     {
      if(!obs[i].is_valid) continue;

      string name;
      color clr;
      if(obs[i].type == OB_BULLISH)
        {
         name = DASH_CHART_PREFIX + "OB_B_" + IntegerToString(bull_idx);
         clr = CLR_OB_BULLISH;
         bull_idx++;
         m_chart_ob_bull_count++;
        }
      else
        {
         name = DASH_CHART_PREFIX + "OB_S_" + IntegerToString(bear_idx);
         clr = CLR_OB_BEARISH;
         bear_idx++;
         m_chart_ob_bear_count++;
        }

      //--- Creer le rectangle sur le chart
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, obs[i].time, obs[i].high, obs[i].time + PeriodSeconds(PERIOD_CURRENT) * 5, obs[i].low);

      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);

      //--- Opacite selon l'etat: Fresh=plein, Mitigated=plus transparent, Consumed=desactive
      if(obs[i].state == OB_STATE_FRESH)
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
      else if(obs[i].state == OB_STATE_MITIGATED)
         ObjectSetInteger(0, name, OBJPROP_BACK, false);
      else
        {
         ObjectDelete(0, name);
         if(obs[i].type == OB_BULLISH) m_chart_ob_bull_count--;
         else m_chart_ob_bear_count--;
        }
     }
  }

//+------------------------------------------------------------------+
//| Dessiner les zones FVG sur le chart                              |
//+------------------------------------------------------------------+
void CDashboardManager::DrawFVGZones(const SFVG &fvgs[], int count)
  {
   //--- Nettoyer les anciens FVG
   for(int i = 0; i < 20; i++)
     {
      string name_bull = DASH_CHART_PREFIX + "FVG_B_" + IntegerToString(i);
      string name_bear = DASH_CHART_PREFIX + "FVG_S_" + IntegerToString(i);
      if(ObjectFind(0, name_bull) >= 0) ObjectDelete(0, name_bull);
      if(ObjectFind(0, name_bear) >= 0) ObjectDelete(0, name_bear);
     }

   int bull_idx = 0, bear_idx = 0;
   m_chart_fvg_bull_count = 0;
   m_chart_fvg_bear_count = 0;

   for(int i = 0; i < count && i < 20; i++)
     {
      if(!fvgs[i].is_valid || fvgs[i].is_filled) continue;

      string name;
      color clr;
      if(fvgs[i].type == FVG_BULLISH)
        {
         name = DASH_CHART_PREFIX + "FVG_B_" + IntegerToString(bull_idx);
         clr = CLR_FVG_BULLISH;
         bull_idx++;
         m_chart_fvg_bull_count++;
        }
      else
        {
         name = DASH_CHART_PREFIX + "FVG_S_" + IntegerToString(bear_idx);
         clr = CLR_FVG_BEARISH;
         bear_idx++;
         m_chart_fvg_bear_count++;
        }

      //--- Creer le rectangle FVG
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, fvgs[i].time, fvgs[i].high, fvgs[i].time + PeriodSeconds(PERIOD_CURRENT) * 10, fvgs[i].low);

      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
     }
  }

//+------------------------------------------------------------------+
//| Dessiner les zones de liquidite sur le chart                     |
//+------------------------------------------------------------------+
void CDashboardManager::DrawLiquidityZones(const SLiquidityZone &zones[], int count)
  {
   //--- Nettoyer les anciennes zones
   for(int i = 0; i < 20; i++)
     {
      string name = DASH_CHART_PREFIX + "LIQ_" + IntegerToString(i);
      if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
     }

   int drawn = 0;
   for(int i = 0; i < count && drawn < 20; i++)
     {
      if(!zones[i].is_valid) continue;

      string name = DASH_CHART_PREFIX + "LIQ_" + IntegerToString(drawn);
      color clr = CLR_LIQ_BSL;

      //--- Ligne horizontale pour le niveau de liquidite
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, zones[i].price);

      //--- Couleur selon le type
      if(zones[i].type == LIQUIDITY_BSL || zones[i].type == LIQUIDITY_EQUAL_HIGH || zones[i].type == LIQUIDITY_DOUBLE_TOP)
         clr = CLR_LIQ_BSL;
      else
         clr = CLR_LIQ_SSL;

      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, zones[i].is_swept ? STYLE_DOT : STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, zones[i].is_swept ? 1 : 2);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);

      drawn++;
     }
  }

//+------------------------------------------------------------------+
//| Dessiner les niveaux de trade (Entry, SL, TP) sur le chart       |
//+------------------------------------------------------------------+
void CDashboardManager::DrawTradeLevels(double entry, double sl, double tp1, double tp2, double tp3,
                                          ENUM_SIGNAL_TYPE direction)
  {
   //--- Nettoyer les anciens niveaux
   ClearTradeLevels();

   m_has_active_trade = true;
   m_trade_entry = entry;
   m_trade_sl = sl;
   m_trade_tp1 = tp1;
   m_trade_tp2 = tp2;
   m_trade_tp3 = tp3;
   m_trade_direction = direction;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   //--- Entry line (bleu)
   string name_e = DASH_CHART_PREFIX + "TRADE_ENTRY";
   ObjectCreate(0, name_e, OBJ_HLINE, 0, 0, entry);
   ObjectSetInteger(0, name_e, OBJPROP_COLOR, CLR_ENTRY_LINE);
   ObjectSetInteger(0, name_e, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name_e, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name_e, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name_e, OBJPROP_BACK, false);

   //--- SL line (rouge)
   string name_s = DASH_CHART_PREFIX + "TRADE_SL";
   ObjectCreate(0, name_s, OBJ_HLINE, 0, 0, sl);
   ObjectSetInteger(0, name_s, OBJPROP_COLOR, CLR_SL_LINE);
   ObjectSetInteger(0, name_s, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, name_s, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name_s, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name_s, OBJPROP_BACK, false);

   //--- TP1 line (vert)
   if(tp1 > 0)
     {
      string name_t1 = DASH_CHART_PREFIX + "TRADE_TP1";
      ObjectCreate(0, name_t1, OBJ_HLINE, 0, 0, tp1);
      ObjectSetInteger(0, name_t1, OBJPROP_COLOR, CLR_TP_LINE);
      ObjectSetInteger(0, name_t1, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name_t1, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name_t1, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name_t1, OBJPROP_BACK, false);
     }

   //--- TP2 line (vert plus clair)
   if(tp2 > 0)
     {
      string name_t2 = DASH_CHART_PREFIX + "TRADE_TP2";
      ObjectCreate(0, name_t2, OBJ_HLINE, 0, 0, tp2);
      ObjectSetInteger(0, name_t2, OBJPROP_COLOR, CLR_GREEN_SOFT);
      ObjectSetInteger(0, name_t2, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name_t2, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name_t2, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name_t2, OBJPROP_BACK, false);
     }

   //--- TP3 line (vert encore plus clair)
   if(tp3 > 0)
     {
      string name_t3 = DASH_CHART_PREFIX + "TRADE_TP3";
      ObjectCreate(0, name_t3, OBJ_HLINE, 0, 0, tp3);
      ObjectSetInteger(0, name_t3, OBJPROP_COLOR, C'80,200,140');
      ObjectSetInteger(0, name_t3, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name_t3, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name_t3, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name_t3, OBJPROP_BACK, false);
     }
  }

//+------------------------------------------------------------------+
//| Effacer les niveaux de trade                                     |
//+------------------------------------------------------------------+
void CDashboardManager::ClearTradeLevels()
  {
   string names[] = {"TRADE_ENTRY", "TRADE_SL", "TRADE_TP1", "TRADE_TP2", "TRADE_TP3"};
   for(int i = 0; i < ArraySize(names); i++)
     {
      string name = DASH_CHART_PREFIX + names[i];
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
     }
   m_has_active_trade = false;
  }

//+------------------------------------------------------------------+
//| Mise a jour principale (appelee a chaque tick)                   |
//+------------------------------------------------------------------+
bool CDashboardManager::Update(const SStatistics &stats, double active_score,
                                 string session, string signal,
                                 string sre_class, double daily_dd,
                                 double weekly_dd, double risk_pct,
                                 int open_trades, bool suspended)
  {
   if(!m_initialized || !m_visible)
      return false;

   m_stats = stats;
   m_active_score = active_score;
   m_active_session = session;
   m_active_signal = signal;
   m_sre_class = sre_class;
   m_daily_dd = daily_dd;
   m_weekly_dd = weekly_dd;
   m_risk_pct = risk_pct;
   m_open_trades = open_trades;
   m_suspended = suspended;

   //--- Creer les objets la premiere fois
   if(!m_objects_created)
     {
      DeleteAll();
      int y = 0;
      CreateBackground();
      CreateHeaderSection(y);
      CreateAccountSection(y);
      CreatePerformanceSection(y);
      CreateSignalSection(y);
      CreateRiskSection(y);
      CreateSessionSection(y);
      CreateEngineSection(y);
      CreateFooterSection(y);
      m_objects_created = true;
     }

   //--- Mettre a jour toutes les sections
   UpdateHeaderSection();
   UpdateAccountSection();
   UpdatePerformanceSection();
   UpdateSignalSection();
   UpdateRiskSection();
   UpdateSessionSection();
   UpdateEngineSection();

   ChartRedraw();
   return true;
  }

//+------------------------------------------------------------------+
//| Info dashboard                                                   |
//+------------------------------------------------------------------+
string CDashboardManager::GetDashboardInfo() const
  {
   return StringFormat("Dashboard: Visible=%s Score=%.0f Session=%s Signal=%s OB=%d/%d FVG=%d/%d",
                       m_visible ? "Y" : "N", m_active_score, m_active_session, m_active_signal,
                       m_chart_ob_bull_count, m_chart_ob_bear_count,
                       m_chart_fvg_bull_count, m_chart_fvg_bear_count);
  }

#endif // A2SNIPER_DASHBOARD_MQH
//+------------------------------------------------------------------+
