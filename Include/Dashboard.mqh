//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                        Copyright 2025, YEHI OR Tech     |
//|                                       https://www.yehiortech.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, YEHI OR Tech"
#property link      "https://www.yehiortech.com"

// Classe pour gérer l'affichage du dashboard
class CDashboard
{
private:
   string            m_prefix;           // Préfixe pour les objets
   int               m_x_pos;            // Position X du dashboard
   int               m_y_pos;            // Position Y du dashboard
   int               m_width;            // Largeur du dashboard
   int               m_height;           // Hauteur du dashboard
   color             m_bg_color;         // Couleur de fond
   color             m_border_color;     // Couleur de bordure
   color             m_text_color;       // Couleur du texte
   color             m_title_color;      // Couleur du titre
   color             m_profit_color;     // Couleur des profits
   color             m_loss_color;       // Couleur des pertes
   int               m_font_size;        // Taille de la police
   string            m_font_name;        // Nom de la police
   bool              m_is_visible;       // Visibilité du dashboard
   
   // Données à afficher
   string            m_symbol;           // Symbole actuel
   ENUM_TIMEFRAMES   m_timeframe;        // Timeframe actuel
   double            m_account_balance;  // Solde du compte
   double            m_account_equity;   // Équité du compte
   double            m_daily_profit;     // Profit journalier
   int               m_total_trades;     // Nombre total de trades
   int               m_winning_trades;   // Nombre de trades gagnants
   int               m_losing_trades;    // Nombre de trades perdants
   double            m_win_rate;         // Taux de réussite
   string            m_last_signal;      // Dernier signal
   datetime          m_last_signal_time; // Heure du dernier signal
   bool              m_trading_enabled;  // Trading activé/désactivé
   
   // Méthodes privées
   void              CreateBackground();
   void              CreateTitle();
   void              CreateLabels();
   void              UpdateLabels();

public:
                     CDashboard();
                    ~CDashboard();
   
   // Méthodes d'initialisation
   bool              Initialize(string prefix="ShalomEA_", int x=20, int y=20, int width=300, int height=400);
   void              Deinitialize();
   
   // Méthodes de mise à jour
   void              Update(double balance, double equity, double daily_profit, 
                           int total_trades, int winning_trades, int losing_trades,
                           string last_signal, datetime last_signal_time, bool trading_enabled);
   
   // Méthodes de contrôle
   void              Show();
   void              Hide();
   bool              IsVisible() { return m_is_visible; }
   
   // Méthodes d'accès
   void              SetPosition(int x, int y);
   void              SetColors(color bg, color border, color text, color title, color profit, color loss);
   void              SetFont(string font_name, int font_size);
};

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CDashboard::CDashboard()
{
   m_prefix = "ShalomEA_";
   m_x_pos = 20;
   m_y_pos = 20;
   m_width = 300;
   m_height = 400;
   m_bg_color = C'25,25,25';
   m_border_color = C'50,50,50';
   m_text_color = clrWhite;
   m_title_color = C'0,162,232';
   m_profit_color = clrLime;
   m_loss_color = clrRed;
   m_font_size = 10;
   m_font_name = "Arial";
   m_is_visible = false;
   
   m_symbol = Symbol();
   m_timeframe = Period();
   m_account_balance = 0.0;
   m_account_equity = 0.0;
   m_daily_profit = 0.0;
   m_total_trades = 0;
   m_winning_trades = 0;
   m_losing_trades = 0;
   m_win_rate = 0.0;
   m_last_signal = "Aucun";
   m_last_signal_time = 0;
   m_trading_enabled = false;
}

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CDashboard::~CDashboard()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialisation du dashboard                                      |
//+------------------------------------------------------------------+
bool CDashboard::Initialize(string prefix="ShalomEA_", int x=20, int y=20, int width=300, int height=400)
{
   m_prefix = prefix;
   m_x_pos = x;
   m_y_pos = y;
   m_width = width;
   m_height = height;
   
   // Création des éléments graphiques
   CreateBackground();
   CreateTitle();
   CreateLabels();
   
   m_is_visible = true;
   
   return true;
}

//+------------------------------------------------------------------+
//| Désinitialisation du dashboard                                   |
//+------------------------------------------------------------------+
void CDashboard::Deinitialize()
{
   // Suppression de tous les objets
   ObjectsDeleteAll(0, m_prefix);
   m_is_visible = false;
}

//+------------------------------------------------------------------+
//| Création du fond du dashboard                                    |
//+------------------------------------------------------------------+
void CDashboard::CreateBackground()
{
   string name = m_prefix + "Background";
   
   // Création du rectangle de fond
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   }
   
   // Propriétés du rectangle
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_x_pos);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_y_pos);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, m_width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, m_height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, m_bg_color);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, m_border_color);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Création du titre du dashboard                                   |
//+------------------------------------------------------------------+
void CDashboard::CreateTitle()
{
   string name = m_prefix + "Title";
   
   // Création du titre
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   }
   
   // Propriétés du titre
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_x_pos + 10);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_y_pos + 15);
   ObjectSetInteger(0, name, OBJPROP_COLOR, m_title_color);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, m_font_size + 2);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetString(0, name, OBJPROP_FONT, m_font_name);
   ObjectSetString(0, name, OBJPROP_TEXT, "SHALOM EA - DASHBOARD");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Création des étiquettes du dashboard                             |
//+------------------------------------------------------------------+
void CDashboard::CreateLabels()
{
   string labels[] = {
      "Symbol", "TimeFrame", "Balance", "Equity", "DailyProfit",
      "TotalTrades", "WinningTrades", "LosingTrades", "WinRate",
      "LastSignal", "SignalTime", "TradingStatus"
   };
   
   int y_offset = 50;
   int spacing = 25;
   
   // Création des étiquettes
   for(int i=0; i<ArraySize(labels); i++)
   {
      // Étiquette
      string label_name = m_prefix + "Label_" + labels[i];
      if(ObjectFind(0, label_name) < 0)
      {
         ObjectCreate(0, label_name, OBJ_LABEL, 0, 0, 0);
      }
      
      ObjectSetInteger(0, label_name, OBJPROP_XDISTANCE, m_x_pos + 10);
      ObjectSetInteger(0, label_name, OBJPROP_YDISTANCE, m_y_pos + y_offset + i*spacing);
      ObjectSetInteger(0, label_name, OBJPROP_COLOR, m_text_color);
      ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, m_font_size);
      ObjectSetInteger(0, label_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, label_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetString(0, label_name, OBJPROP_FONT, m_font_name);
      ObjectSetString(0, label_name, OBJPROP_TEXT, labels[i] + ":");
      ObjectSetInteger(0, label_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, label_name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, label_name, OBJPROP_HIDDEN, true);
      
      // Valeur
      string value_name = m_prefix + "Value_" + labels[i];
      if(ObjectFind(0, value_name) < 0)
      {
         ObjectCreate(0, value_name, OBJ_LABEL, 0, 0, 0);
      }
      
      ObjectSetInteger(0, value_name, OBJPROP_XDISTANCE, m_x_pos + 150);
      ObjectSetInteger(0, value_name, OBJPROP_YDISTANCE, m_y_pos + y_offset + i*spacing);
      ObjectSetInteger(0, value_name, OBJPROP_COLOR, m_text_color);
      ObjectSetInteger(0, value_name, OBJPROP_FONTSIZE, m_font_size);
      ObjectSetInteger(0, value_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, value_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetString(0, value_name, OBJPROP_FONT, m_font_name);
      ObjectSetString(0, value_name, OBJPROP_TEXT, "-");
      ObjectSetInteger(0, value_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, value_name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, value_name, OBJPROP_HIDDEN, true);
   }
}

//+------------------------------------------------------------------+
//| Mise à jour des étiquettes du dashboard                          |
//+------------------------------------------------------------------+
void CDashboard::UpdateLabels()
{
   if(!m_is_visible) return;
   
   // Mise à jour des valeurs
   ObjectSetString(0, m_prefix + "Value_Symbol", OBJPROP_TEXT, m_symbol);
   ObjectSetString(0, m_prefix + "Value_TimeFrame", OBJPROP_TEXT, EnumToString(m_timeframe));
   ObjectSetString(0, m_prefix + "Value_Balance", OBJPROP_TEXT, DoubleToString(m_account_balance, 2));
   ObjectSetString(0, m_prefix + "Value_Equity", OBJPROP_TEXT, DoubleToString(m_account_equity, 2));
   
   // Profit journalier avec couleur
   string daily_profit_str = DoubleToString(m_daily_profit, 2);
   ObjectSetString(0, m_prefix + "Value_DailyProfit", OBJPROP_TEXT, daily_profit_str);
   ObjectSetInteger(0, m_prefix + "Value_DailyProfit", OBJPROP_COLOR, m_daily_profit >= 0 ? m_profit_color : m_loss_color);
   
   ObjectSetString(0, m_prefix + "Value_TotalTrades", OBJPROP_TEXT, IntegerToString(m_total_trades));
   ObjectSetString(0, m_prefix + "Value_WinningTrades", OBJPROP_TEXT, IntegerToString(m_winning_trades));
   ObjectSetString(0, m_prefix + "Value_LosingTrades", OBJPROP_TEXT, IntegerToString(m_losing_trades));
   ObjectSetString(0, m_prefix + "Value_WinRate", OBJPROP_TEXT, DoubleToString(m_win_rate, 1) + "%");
   ObjectSetString(0, m_prefix + "Value_LastSignal", OBJPROP_TEXT, m_last_signal);
   
   // Format de l'heure du signal
   string time_str = "Aucun";
   if(m_last_signal_time > 0)
   {
      MqlDateTime dt;
      TimeToStruct(m_last_signal_time, dt);
      time_str = StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);
   }
   ObjectSetString(0, m_prefix + "Value_SignalTime", OBJPROP_TEXT, time_str);
   
   // Status du trading avec couleur
   string status = m_trading_enabled ? "ACTIF" : "INACTIF";
   ObjectSetString(0, m_prefix + "Value_TradingStatus", OBJPROP_TEXT, status);
   ObjectSetInteger(0, m_prefix + "Value_TradingStatus", OBJPROP_COLOR, m_trading_enabled ? m_profit_color : m_loss_color);
}

//+------------------------------------------------------------------+
//| Mise à jour des données du dashboard                             |
//+------------------------------------------------------------------+
void CDashboard::Update(double balance, double equity, double daily_profit, 
                       int total_trades, int winning_trades, int losing_trades,
                       string last_signal, datetime last_signal_time, bool trading_enabled)
{
   m_symbol = Symbol();
   m_timeframe = Period();
   m_account_balance = balance;
   m_account_equity = equity;
   m_daily_profit = daily_profit;
   m_total_trades = total_trades;
   m_winning_trades = winning_trades;
   m_losing_trades = losing_trades;
   
   // Calcul du taux de réussite
   if(m_total_trades > 0)
      m_win_rate = (double)m_winning_trades / m_total_trades * 100.0;
   else
      m_win_rate = 0.0;
   
   m_last_signal = last_signal;
   m_last_signal_time = last_signal_time;
   m_trading_enabled = trading_enabled;
   
   UpdateLabels();
}



//+------------------------------------------------------------------+
//| Afficher le dashboard                                            |
//+------------------------------------------------------------------+
void CDashboard::Show()
{
   if(!m_is_visible)
   {
      m_is_visible = true;
      
      // Rendre tous les objets visibles
      string prefix = m_prefix;
      int total = ObjectsTotal(0);
      
      for(int i=0; i<total; i++)
      {
         string name = ObjectName(0, i);
         if(StringFind(name, prefix) == 0)
         {
            ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
         }
      }
      
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| Cacher le dashboard                                              |
//+------------------------------------------------------------------+
void CDashboard::Hide()
{
   if(m_is_visible)
   {
      m_is_visible = false;
      
      // Rendre tous les objets invisibles
      string prefix = m_prefix;
      int total = ObjectsTotal(0);
      
      for(int i=0; i<total; i++)
      {
         string name = ObjectName(0, i);
         if(StringFind(name, prefix) == 0)
         {
            ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
         }
      }
      
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| Définir la position du dashboard                                 |
//+------------------------------------------------------------------+
void CDashboard::SetPosition(int x, int y)
{
   m_x_pos = x;
   m_y_pos = y;
   
   if(m_is_visible)
   {
      CreateBackground();
      CreateTitle();
      CreateLabels();
      UpdateLabels();
   }
}

//+------------------------------------------------------------------+
//| Définir les couleurs du dashboard                                |
//+------------------------------------------------------------------+
void CDashboard::SetColors(color bg, color border, color text, color title, color profit, color loss)
{
   m_bg_color = bg;
   m_border_color = border;
   m_text_color = text;
   m_title_color = title;
   m_profit_color = profit;
   m_loss_color = loss;
   
   if(m_is_visible)
   {
      CreateBackground();
      CreateTitle();
      CreateLabels();
      UpdateLabels();
   }
}

//+------------------------------------------------------------------+
//| Définir la police du dashboard                                   |
//+------------------------------------------------------------------+
void CDashboard::SetFont(string font_name, int font_size)
{
   m_font_name = font_name;
   m_font_size = font_size;
   
   if(m_is_visible)
   {
      CreateTitle();
      CreateLabels();
      UpdateLabels();
   }
}
