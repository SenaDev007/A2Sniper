//+------------------------------------------------------------------+
//| BacktestIntelligenceEngine.mqh - Intelligence de Backtest        |
//| A2Sniper Ultimate v3.0                                           |
//| Backtests automatiques, Comparaison de stratégies,               |
//| Classement des setups, Notation automatique A+ à D               |
//+------------------------------------------------------------------+
#ifndef A2SNIPER_BACKTEST_INTEL_MQH
#define A2SNIPER_BACKTEST_INTEL_MQH

#include "CommonTypes.mqh"

//+------------------------------------------------------------------+
//| Résultat d'un setup de trading                                    |
//+------------------------------------------------------------------+
struct SSetupResult
  {
   string               setup_type;        // Type de setup (ex: "SRE_Bullish_OB")
   int                  total_trades;      // Nombre total de trades
   int                  wins;              // Trades gagnants
   double               win_rate;          // Taux de réussite (%)
   double               profit_factor;     // Profit Factor
   double               avg_rr;            // R:R moyen
   double               total_profit;      // Profit total
   double               max_drawdown;      // Drawdown max (%)
   double               avg_hold_time;     // Temps de maintien moyen (heures)
   ENUM_BACKTEST_GRADE  grade;             // Note A+ à D
   bool                 is_profitable;     // Rentable ?
   datetime             last_updated;      // Dernière mise à jour
  };

//+------------------------------------------------------------------+
//| Classe CBacktestIntelligenceEngine                                |
//+------------------------------------------------------------------+
class CBacktestIntelligenceEngine
  {
private:
   bool                 m_initialized;
   int                  m_max_setups;

   //--- Résultats par setup
   SSetupResult         m_setups[];
   int                  m_setup_count;

   //--- Résumé global
   ENUM_BACKTEST_GRADE  m_overall_grade;
   double               m_overall_stability; // 0-100, stabilité globale

   //--- Méthodes privées
   ENUM_BACKTEST_GRADE  CalculateGrade(double win_rate, double pf, double dd, double stability) const;
   double               CalculateStability() const;
   int                  FindSetup(const string setup_type) const;
   void                 SortSetupsByGrade();

public:
   //--- Constructeur / Destructeur
                        CBacktestIntelligenceEngine();
                       ~CBacktestIntelligenceEngine();

   //--- Initialisation
   bool                 Initialize(int max_setups = 50);
   void                 Deinitialize();

   //--- Enregistrement d'un résultat
   bool                 RecordSetupResult(const SSetupResult &result);
   bool                 UpdateSetupFromTrade(const string setup_type, bool is_win,
                                              double profit, double rr, double dd_pct);

   //--- Analyse
   ENUM_BACKTEST_GRADE  GetOverallGrade() const { return m_overall_grade; }
   double               GetOverallStability() const { return m_overall_stability; }
   SSetupResult         GetBestSetup() const;
   SSetupResult         GetWorstSetup() const;
   SSetupResult         GetSetupByType(const string setup_type) const;

   //--- Comparaison
   bool                 IsSetupViable(const string setup_type) const;
   double               GetSetupWinRate(const string setup_type) const;
   double               GetSetupProfitFactor(const string setup_type) const;

   //--- Statistiques
   int                  GetSetupCount() const { return m_setup_count; }
   SSetupResult         GetSetup(const int index) const;

   //--- Info
   string               GetGradeString(ENUM_BACKTEST_GRADE grade) const;
   string               GetBacktestInfo() const;
  };

//+------------------------------------------------------------------+
//| Constructeur                                                     |
//+------------------------------------------------------------------+
CBacktestIntelligenceEngine::CBacktestIntelligenceEngine() :
   m_initialized(false),
   m_max_setups(50),
   m_setup_count(0),
   m_overall_grade(GRADE_D),
   m_overall_stability(0)
  {
   ArrayResize(m_setups, 0);
  }

//+------------------------------------------------------------------+
//| Destructeur                                                      |
//+------------------------------------------------------------------+
CBacktestIntelligenceEngine::~CBacktestIntelligenceEngine()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
bool CBacktestIntelligenceEngine::Initialize(int max_setups)
  {
   m_max_setups = (max_setups > 10) ? max_setups : 50;
   m_initialized = true;
   Print("A2Sniper BIE: Backtest Intelligence Engine initialisé");
   return true;
  }

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void CBacktestIntelligenceEngine::Deinitialize()
  {
   m_setup_count = 0;
   ArrayResize(m_setups, 0);
   m_initialized = false;
  }

//+------------------------------------------------------------------+
//| Calculer la note (Grade)                                         |
//+------------------------------------------------------------------+
ENUM_BACKTEST_GRADE CBacktestIntelligenceEngine::CalculateGrade(double win_rate, double pf,
                                                                  double dd, double stability) const
  {
   //--- Score composite (0-100)
   double score = 0;

   //--- Win Rate (25 pts)
   score += MathMin(win_rate / 80.0, 1.0) * 25;

   //--- Profit Factor (25 pts)
   score += MathMin(pf / 3.0, 1.0) * 25;

   //--- Drawdown (25 pts, inversé - moins de DD = meilleur)
   if(dd <= 3) score += 25;
   else if(dd <= 5) score += 20;
   else if(dd <= 10) score += 15;
   else if(dd <= 15) score += 10;
   else score += 5;

   //--- Stabilité (25 pts)
   score += MathMin(stability / 100.0, 1.0) * 25;

   //--- Attribution de la note
   if(score >= 90) return GRADE_A_PLUS;
   if(score >= 75) return GRADE_A;
   if(score >= 60) return GRADE_B;
   if(score >= 40) return GRADE_C;
   return GRADE_D;
  }

//+------------------------------------------------------------------+
//| Calculer la stabilité globale                                    |
//+------------------------------------------------------------------+
double CBacktestIntelligenceEngine::CalculateStability() const
  {
   if(m_setup_count == 0) return 0;

   //--- Stabilité basée sur la consistance des résultats
   double avg_wr = 0;
   int profitable_count = 0;

   for(int i = 0; i < m_setup_count; i++)
     {
      avg_wr += m_setups[i].win_rate;
      if(m_setups[i].is_profitable) profitable_count++;
     }

   avg_wr /= m_setup_count;
   double profitable_ratio = (double)profitable_count / m_setup_count;

   //--- Stabilité = combinaison de WR moyen et ratio de setups rentables
   return (avg_wr * 0.5 + profitable_ratio * 50.0);
  }

//+------------------------------------------------------------------+
//| Trouver un setup par type                                        |
//+------------------------------------------------------------------+
int CBacktestIntelligenceEngine::FindSetup(const string setup_type) const
  {
   for(int i = 0; i < m_setup_count; i++)
     {
      if(m_setups[i].setup_type == setup_type)
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| Trier les setups par note                                        |
//+------------------------------------------------------------------+
void CBacktestIntelligenceEngine::SortSetupsByGrade()
  {
   //--- Tri à bulles simple (petit nombre de setups)
   for(int i = 0; i < m_setup_count - 1; i++)
     {
      for(int j = 0; j < m_setup_count - i - 1; j++)
        {
         if(m_setups[j].grade < m_setups[j + 1].grade)
           {
            SSetupResult temp = m_setups[j];
            m_setups[j] = m_setups[j + 1];
            m_setups[j + 1] = temp;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Enregistrer un résultat de setup                                 |
//+------------------------------------------------------------------+
bool CBacktestIntelligenceEngine::RecordSetupResult(const SSetupResult &result)
  {
   if(!m_initialized) return false;

   int idx = FindSetup(result.setup_type);

   if(idx >= 0)
     {
      //--- Mettre à jour le setup existant
      m_setups[idx] = result;
      m_setups[idx].last_updated = TimeCurrent();
     }
   else
     {
      //--- Ajouter un nouveau setup
      if(m_setup_count >= m_max_setups)
         return false;

      m_setup_count++;
      ArrayResize(m_setups, m_setup_count);
      m_setups[m_setup_count - 1] = result;
      m_setups[m_setup_count - 1].last_updated = TimeCurrent();
     }

   //--- Recalculer
   m_overall_stability = CalculateStability();

   //--- Calculer la note globale
   double avg_wr = 0, avg_pf = 0, avg_dd = 0;
   for(int i = 0; i < m_setup_count; i++)
     {
      avg_wr += m_setups[i].win_rate;
      avg_pf += m_setups[i].profit_factor;
      avg_dd += m_setups[i].max_drawdown;
     }
   avg_wr /= m_setup_count;
   avg_pf /= m_setup_count;
   avg_dd /= m_setup_count;

   m_overall_grade = CalculateGrade(avg_wr, avg_pf, avg_dd, m_overall_stability);
   SortSetupsByGrade();

   return true;
  }

//+------------------------------------------------------------------+
//| Mettre à jour un setup depuis un trade                           |
//+------------------------------------------------------------------+
bool CBacktestIntelligenceEngine::UpdateSetupFromTrade(const string setup_type, bool is_win,
                                                         double profit, double rr, double dd_pct)
  {
   if(!m_initialized) return false;

   int idx = FindSetup(setup_type);

   if(idx >= 0)
     {
      m_setups[idx].total_trades++;
      if(is_win)
        {
         m_setups[idx].wins++;
         m_setups[idx].total_profit += profit;
        }
      else
        {
         m_setups[idx].total_profit -= MathAbs(profit);
        }

      m_setups[idx].win_rate = (m_setups[idx].total_trades > 0) ?
                                ((double)m_setups[idx].wins / m_setups[idx].total_trades) * 100.0 : 0;

      m_setups[idx].avg_rr = (m_setups[idx].total_trades > 0) ?
                              (m_setups[idx].avg_rr * (m_setups[idx].total_trades - 1) + rr) /
                              m_setups[idx].total_trades : rr;

      m_setups[idx].max_drawdown = MathMax(m_setups[idx].max_drawdown, dd_pct);
      m_setups[idx].is_profitable = (m_setups[idx].total_profit > 0);

      //--- Calculer PF
      double total_win = 0, total_loss = 0;
      if(m_setups[idx].wins > 0)
         total_win = m_setups[idx].total_profit * m_setups[idx].wins /
                     MathMax(m_setups[idx].total_trades, 1);
      total_loss = MathAbs(MathMin(m_setups[idx].total_profit -
                                    (m_setups[idx].is_profitable ? m_setups[idx].total_profit * 2 : 0), 0));
      m_setups[idx].profit_factor = (total_loss > 0) ? total_win / total_loss : (total_win > 0 ? 9.9 : 0);

      m_setups[idx].grade = CalculateGrade(m_setups[idx].win_rate, m_setups[idx].profit_factor,
                                            m_setups[idx].max_drawdown, m_overall_stability);
      m_setups[idx].last_updated = TimeCurrent();
     }
   else
     {
      //--- Créer un nouveau setup
      SSetupResult result;
      result.setup_type = setup_type;
      result.total_trades = 1;
      result.wins = is_win ? 1 : 0;
      result.win_rate = is_win ? 100.0 : 0.0;
      result.avg_rr = rr;
      result.total_profit = is_win ? profit : -MathAbs(profit);
      result.max_drawdown = dd_pct;
      result.avg_hold_time = 0;
      result.is_profitable = is_win;
      result.profit_factor = is_win ? 9.9 : 0;
      result.grade = CalculateGrade(result.win_rate, result.profit_factor, result.max_drawdown, 50);
      result.last_updated = TimeCurrent();
      RecordSetupResult(result);
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Meilleur setup                                                   |
//+------------------------------------------------------------------+
SSetupResult CBacktestIntelligenceEngine::GetBestSetup() const
  {
   if(m_setup_count == 0)
     {
      SSetupResult empty;
      ZeroMemory(empty);
      return empty;
     }

   SSetupResult best = m_setups[0];
   for(int i = 1; i < m_setup_count; i++)
     {
      if(m_setups[i].grade > best.grade ||
         (m_setups[i].grade == best.grade && m_setups[i].profit_factor > best.profit_factor))
         best = m_setups[i];
     }
   return best;
  }

//+------------------------------------------------------------------+
//| Pire setup                                                       |
//+------------------------------------------------------------------+
SSetupResult CBacktestIntelligenceEngine::GetWorstSetup() const
  {
   if(m_setup_count == 0)
     {
      SSetupResult empty;
      ZeroMemory(empty);
      return empty;
     }

   SSetupResult worst = m_setups[0];
   for(int i = 1; i < m_setup_count; i++)
     {
      if(m_setups[i].grade < worst.grade)
         worst = m_setups[i];
     }
   return worst;
  }

//+------------------------------------------------------------------+
//| Obtenir un setup par type                                        |
//+------------------------------------------------------------------+
SSetupResult CBacktestIntelligenceEngine::GetSetupByType(const string setup_type) const
  {
   int idx = FindSetup(setup_type);
   if(idx >= 0) return m_setups[idx];
   SSetupResult empty;
   ZeroMemory(empty);
   return empty;
  }

//+------------------------------------------------------------------+
//| Le setup est-il viable ?                                         |
//+------------------------------------------------------------------+
bool CBacktestIntelligenceEngine::IsSetupViable(const string setup_type) const
  {
   int idx = FindSetup(setup_type);
   if(idx < 0) return true; // Inconnu = potentiellement viable
   return m_setups[idx].is_profitable && m_setups[idx].win_rate >= 50.0;
  }

//+------------------------------------------------------------------+
//| Win Rate d'un setup                                              |
//+------------------------------------------------------------------+
double CBacktestIntelligenceEngine::GetSetupWinRate(const string setup_type) const
  {
   int idx = FindSetup(setup_type);
   if(idx < 0) return 0;
   return m_setups[idx].win_rate;
  }

//+------------------------------------------------------------------+
//| Profit Factor d'un setup                                         |
//+------------------------------------------------------------------+
double CBacktestIntelligenceEngine::GetSetupProfitFactor(const string setup_type) const
  {
   int idx = FindSetup(setup_type);
   if(idx < 0) return 0;
   return m_setups[idx].profit_factor;
  }

//+------------------------------------------------------------------+
//| Accesseur                                                        |
//+------------------------------------------------------------------+
SSetupResult CBacktestIntelligenceEngine::GetSetup(const int index) const
  {
   if(index >= 0 && index < m_setup_count)
      return m_setups[index];
   SSetupResult empty;
   ZeroMemory(empty);
   return empty;
  }

//+------------------------------------------------------------------+
//| Grade en chaîne                                                  |
//+------------------------------------------------------------------+
string CBacktestIntelligenceEngine::GetGradeString(ENUM_BACKTEST_GRADE grade) const
  {
   switch(grade)
     {
      case GRADE_A_PLUS: return "A+";
      case GRADE_A:      return "A";
      case GRADE_B:      return "B";
      case GRADE_C:      return "C";
      case GRADE_D:      return "D";
      default:           return "?";
     }
  }

//+------------------------------------------------------------------+
//| Info backtest                                                    |
//+------------------------------------------------------------------+
string CBacktestIntelligenceEngine::GetBacktestInfo() const
  {
   return StringFormat("BIE: Grade=%s Stability=%.0f%% Setups=%d",
                       GetGradeString(m_overall_grade), m_overall_stability, m_setup_count);
  }

#endif // A2SNIPER_BACKTEST_INTEL_MQH
//+------------------------------------------------------------------+
