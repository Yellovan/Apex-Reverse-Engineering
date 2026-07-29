//+------------------------------------------------------------------+
//|                                                  ApexLogger.mq5  |
//|  Passive-only logger for ZennbotApex / grid forensic collection  |
//|  Place on same chart as the live EA — does NOT trade             |
//+------------------------------------------------------------------+
#property copyright   "ZennApex Research"
#property version     "1.03"
#property description "Logs pendings, fills, SL modifies, closes, equity snapshots"
#property description "Output: MQL5/Files/ApexLog_<tag>_YYYYMMDD.csv"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/DealInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//+------------------------------------------------------------------+
input group "=== Logger ==="
input string   InpSymbolFilter   = "";          // Only symbols containing this ("" = all)
input string   InpFilePrefix     = "ApexLog";   // Base name
input string   InpAccountTag     = "";          // e.g. "1k" / "25k" / "36k" (empty = login#)
input int      InpSnapshotSec    = 60;          // Equity/pending snapshot interval (seconds)
input bool     InpLogTicks       = false;       // Very verbose — normally OFF
input bool     InpLogEveryModify = true;        // Log every position SL/TP change
input long     InpMagicMin       = 0;           // 0 = all magics; else only magic in [Min, Max)
input long     InpMagicMax       = 0;

input group "=== Display ==="
input bool     InpShowPanel      = true;
input int      InpPanelX         = 10;
input int      InpPanelY         = 30;

//+------------------------------------------------------------------+
CSymbolInfo   g_sym;
CPositionInfo g_pos;
COrderInfo    g_order;
CDealInfo     g_deal;

string   g_log_path;
int      g_file = INVALID_HANDLE;
datetime g_day_stamp = 0;
datetime g_last_snap = 0;

// Track last known SL per position ticket (detect modifies)
ulong    g_trk_ticket[];
double   g_trk_sl[];
double   g_trk_tp[];
double   g_trk_vol[];

// Chart timeframe (constant for this EA instance)
string   g_timeframe_str;

//+------------------------------------------------------------------+
int OnInit()
{
   // Store timeframe as string
   g_timeframe_str = EnumToString(Period());

   if(InpSymbolFilter != "")
   {
      string u = _Symbol;
      StringToUpper(u);
      string f = InpSymbolFilter;
      StringToUpper(f);
      if(StringFind(u, f) < 0)
         Print("ApexLogger: chart symbol does not match filter [", InpSymbolFilter, "] — still logging filtered symbols only");
   }

   if(!OpenLogFile())
      return INIT_FAILED;

   EventSetTimer(MathMax(1, InpSnapshotSec));
   CaptureSnapshot("INIT");
   ScanExistingPendings("INIT");
   ScanExistingPositions("INIT");

   if(InpShowPanel)
      DrawPanel();

   Print("ApexLogger v1.03 started | file=", g_log_path,
         " filter=", InpSymbolFilter,
         " snap=", InpSnapshotSec, "s",
         " timeframe=", g_timeframe_str);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   CaptureSnapshot("DEINIT");
   EventKillTimer();
   if(g_file != INVALID_HANDLE)
   {
      FileClose(g_file);
      g_file = INVALID_HANDLE;
   }
   ObjectsDeleteAll(0, "AL_");
}

//+------------------------------------------------------------------+
void OnTick()
{
   RotateIfNewDay();
   if(InpLogEveryModify)
      CheckPositionModifies();
}

void OnTimer()
{
   RotateIfNewDay();
   CaptureSnapshot("TIMER");
   if(InpShowPanel)
      DrawPanel();
}

//+------------------------------------------------------------------+
bool SymbolOk(const string sym)
{
   if(InpSymbolFilter == "") return true;
   string u = sym; StringToUpper(u);
   string f = InpSymbolFilter; StringToUpper(f);
   return (StringFind(u, f) >= 0);
}

bool MagicOk(const long magic)
{
   if(InpMagicMin == 0 && InpMagicMax == 0) return true;
   if(InpMagicMax > InpMagicMin)
      return (magic >= InpMagicMin && magic < InpMagicMax);
   return (magic == InpMagicMin);
}

//+------------------------------------------------------------------+
bool OpenLogFile()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   g_day_stamp = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));

   // Tag: user override, else account login number
   string tag = InpAccountTag;
   StringTrimLeft(tag);
   StringTrimRight(tag);
   if(tag == "")
      tag = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));

   g_log_path = StringFormat("%s_%s_%04d%02d%02d.csv",
                             InpFilePrefix, tag, dt.year, dt.mon, dt.day);

   g_file = FileOpen(g_log_path, FILE_WRITE | FILE_READ | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ';');
   if(g_file == INVALID_HANDLE)
   {
      Print("ApexLogger: cannot open ", g_log_path, " err=", GetLastError());
      return false;
   }

   // If empty → write header (extended)
   if(FileSize(g_file) == 0)
   {
      FileWrite(g_file,
                "time", "event", "symbol", "side", "volume",
                "price", "sl", "tp", "profit", "comment",
                "ticket", "magic", "order", "deal",
                "equity", "balance", "margin", "free_margin",
                "positions", "pendings", "mid",
                "bid", "ask",
                "timeframe",
                "deal_reason",
                "note");
   }
   else
   {
      FileSeek(g_file, 0, SEEK_END);
   }
   return true;
}

void RotateIfNewDay()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime day0 = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
   if(day0 == g_day_stamp) return;

   CaptureSnapshot("DAY_END");
   if(g_file != INVALID_HANDLE)
   {
      FileClose(g_file);
      g_file = INVALID_HANDLE;
   }
   OpenLogFile();
   CaptureSnapshot("DAY_START");
   ScanExistingPendings("DAY_START");
   ScanExistingPositions("DAY_START");
}

//+------------------------------------------------------------------+
void LogRow(const string event,
            const string sym,
            const string side,
            const double volume,
            const double price,
            const double sl,
            const double tp,
            const double profit,
            const string comment,
            const ulong  ticket,
            const long   magic,
            const ulong  order,
            const ulong  deal,
            const string deal_reason = "",
            const string note = "")
{
   if(g_file == INVALID_HANDLE) return;

   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double margin  = AccountInfoDouble(ACCOUNT_MARGIN);
   double free_m  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   int    npos    = CountPositions();
   int    npend   = CountPendings();

   // Get bid/ask/mid for the symbol (use _Symbol if sym empty)
   string use_sym = (sym == "" ? _Symbol : sym);
   double bid = 0, ask = 0, mid = 0;
   if(SymbolInfoDouble(use_sym, SYMBOL_BID) > 0)
   {
      bid = SymbolInfoDouble(use_sym, SYMBOL_BID);
      ask = SymbolInfoDouble(use_sym, SYMBOL_ASK);
      mid = (bid + ask) * 0.5;
   }

   // Excel-safe: IDs as ="123" so no scientific notation; prices 2dp for XAU
   FileWrite(g_file,
             TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
             event,
             sym,
             side,
             DoubleToString(volume, 2),
             (price  > 0 ? DoubleToString(price, 2)  : ""),
             (sl     > 0 ? DoubleToString(sl, 2)     : ""),
             (tp     > 0 ? DoubleToString(tp, 2)     : ""),
             DoubleToString(profit, 2),
             comment,
             (ticket > 0 ? StringFormat("=\"%s\"", IntegerToString(ticket)) : ""),
             (magic  != 0 ? StringFormat("=\"%s\"", IntegerToString(magic))  : "0"),
             (order  > 0 ? StringFormat("=\"%s\"", IntegerToString(order))  : ""),
             (deal   > 0 ? StringFormat("=\"%s\"", IntegerToString(deal))   : ""),
             DoubleToString(equity, 2),
             DoubleToString(balance, 2),
             DoubleToString(margin, 2),
             DoubleToString(free_m, 2),
             IntegerToString(npos),
             IntegerToString(npend),
             (mid > 0 ? DoubleToString(mid, 2) : ""),
             (bid > 0 ? DoubleToString(bid, 2) : ""),
             (ask > 0 ? DoubleToString(ask, 2) : ""),
             g_timeframe_str,
             deal_reason,
             note);
   FileFlush(g_file);
}

//+------------------------------------------------------------------+
int CountPositions()
{
   int c = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_pos.SelectByIndex(i)) continue;
      if(!SymbolOk(g_pos.Symbol())) continue;
      if(!MagicOk(g_pos.Magic())) continue;
      c++;
   }
   return c;
}

int CountPendings()
{
   int c = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!g_order.SelectByIndex(i)) continue;
      if(!SymbolOk(g_order.Symbol())) continue;
      if(!MagicOk(g_order.Magic())) continue;
      ENUM_ORDER_TYPE t = g_order.OrderType();
      if(t == ORDER_TYPE_BUY_STOP || t == ORDER_TYPE_SELL_STOP ||
         t == ORDER_TYPE_BUY_LIMIT || t == ORDER_TYPE_SELL_LIMIT)
         c++;
   }
   return c;
}

string SideFromOrderType(ENUM_ORDER_TYPE t)
{
   switch(t)
   {
      case ORDER_TYPE_BUY:        return "BUY";
      case ORDER_TYPE_SELL:       return "SELL";
      case ORDER_TYPE_BUY_STOP:   return "BUY_STOP";
      case ORDER_TYPE_SELL_STOP:  return "SELL_STOP";
      case ORDER_TYPE_BUY_LIMIT:  return "BUY_LIMIT";
      case ORDER_TYPE_SELL_LIMIT: return "SELL_LIMIT";
      default: return EnumToString(t);
   }
}

string SideFromDealType(ENUM_DEAL_TYPE t)
{
   if(t == DEAL_TYPE_BUY)  return "BUY";
   if(t == DEAL_TYPE_SELL) return "SELL";
   return EnumToString(t);
}

//+------------------------------------------------------------------+
// Corrected function without DEAL_REASON_UNKNOWN
string DealReasonToString(long reason)
{
   switch((ENUM_DEAL_REASON)reason)
   {
      case DEAL_REASON_SL:        return "SL";
      case DEAL_REASON_TP:        return "TP";
      case DEAL_REASON_SO:        return "STOP_OUT";
      case DEAL_REASON_CLIENT:    return "CLIENT";
      case DEAL_REASON_EXPERT:    return "EXPERT";
      default:                    return "UNKNOWN_" + IntegerToString(reason);
   }
}

//+------------------------------------------------------------------+
void CaptureSnapshot(const string note)
{
   LogRow("SNAPSHOT", _Symbol, "", 0, 0, 0, 0, 0, "",
          0, 0, 0, 0, "", note);
   g_last_snap = TimeCurrent();
}

void ScanExistingPendings(const string note)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!g_order.SelectByIndex(i)) continue;
      if(!SymbolOk(g_order.Symbol())) continue;
      if(!MagicOk(g_order.Magic())) continue;
      ENUM_ORDER_TYPE t = g_order.OrderType();
      if(t != ORDER_TYPE_BUY_STOP && t != ORDER_TYPE_SELL_STOP &&
         t != ORDER_TYPE_BUY_LIMIT && t != ORDER_TYPE_SELL_LIMIT)
         continue;

      LogRow("PENDING_EXIST",
             g_order.Symbol(),
             SideFromOrderType(t),
             g_order.VolumeCurrent(),
             g_order.PriceOpen(),
             g_order.StopLoss(),
             g_order.TakeProfit(),
             0,
             g_order.Comment(),
             g_order.Ticket(),
             g_order.Magic(),
             g_order.Ticket(),
             0,
             "",
             note);
   }
}

void ScanExistingPositions(const string note)
{
   ArrayResize(g_trk_ticket, 0);
   ArrayResize(g_trk_sl, 0);
   ArrayResize(g_trk_tp, 0);
   ArrayResize(g_trk_vol, 0);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_pos.SelectByIndex(i)) continue;
      if(!SymbolOk(g_pos.Symbol())) continue;
      if(!MagicOk(g_pos.Magic())) continue;

      string side = (g_pos.PositionType() == POSITION_TYPE_BUY) ? "BUY" : "SELL";
      LogRow("POS_EXIST",
             g_pos.Symbol(),
             side,
             g_pos.Volume(),
             g_pos.PriceOpen(),
             g_pos.StopLoss(),
             g_pos.TakeProfit(),
             g_pos.Profit(),
             g_pos.Comment(),
             g_pos.Ticket(),
             g_pos.Magic(),
             0, 0,
             "",
             note);

      TrackPosition(g_pos.Ticket(), g_pos.StopLoss(), g_pos.TakeProfit(), g_pos.Volume());
   }
}

//+------------------------------------------------------------------+
void TrackPosition(ulong ticket, double sl, double tp, double vol)
{
   int n = ArraySize(g_trk_ticket);
   for(int i = 0; i < n; i++)
   {
      if(g_trk_ticket[i] == ticket)
      {
         g_trk_sl[i]  = sl;
         g_trk_tp[i]  = tp;
         g_trk_vol[i] = vol;
         return;
      }
   }
   ArrayResize(g_trk_ticket, n + 1);
   ArrayResize(g_trk_sl, n + 1);
   ArrayResize(g_trk_tp, n + 1);
   ArrayResize(g_trk_vol, n + 1);
   g_trk_ticket[n] = ticket;
   g_trk_sl[n]     = sl;
   g_trk_tp[n]     = tp;
   g_trk_vol[n]    = vol;
}

void UntrackPosition(ulong ticket)
{
   int n = ArraySize(g_trk_ticket);
   for(int i = 0; i < n; i++)
   {
      if(g_trk_ticket[i] != ticket) continue;
      // swap-remove
      g_trk_ticket[i] = g_trk_ticket[n - 1];
      g_trk_sl[i]     = g_trk_sl[n - 1];
      g_trk_tp[i]     = g_trk_tp[n - 1];
      g_trk_vol[i]    = g_trk_vol[n - 1];
      ArrayResize(g_trk_ticket, n - 1);
      ArrayResize(g_trk_sl, n - 1);
      ArrayResize(g_trk_tp, n - 1);
      ArrayResize(g_trk_vol, n - 1);
      return;
   }
}

bool GetTracked(ulong ticket, double &sl, double &tp, double &vol)
{
   int n = ArraySize(g_trk_ticket);
   for(int i = 0; i < n; i++)
   {
      if(g_trk_ticket[i] == ticket)
      {
         sl = g_trk_sl[i]; tp = g_trk_tp[i]; vol = g_trk_vol[i];
         return true;
      }
   }
   return false;
}

void CheckPositionModifies()
{
   // Detect SL/TP changes on open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_pos.SelectByIndex(i)) continue;
      if(!SymbolOk(g_pos.Symbol())) continue;
      if(!MagicOk(g_pos.Magic())) continue;

      ulong  ticket = g_pos.Ticket();
      double sl = g_pos.StopLoss();
      double tp = g_pos.TakeProfit();
      double vol = g_pos.Volume();
      double old_sl, old_tp, old_vol;

      if(!GetTracked(ticket, old_sl, old_tp, old_vol))
      {
         TrackPosition(ticket, sl, tp, vol);
         continue;
      }

      bool sl_chg = (MathAbs(sl - old_sl) > 1e-8);
      bool tp_chg = (MathAbs(tp - old_tp) > 1e-8);
      bool vol_chg = (MathAbs(vol - old_vol) > 1e-8);

      if(sl_chg || tp_chg || vol_chg)
      {
         string side = (g_pos.PositionType() == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         string note = "";
         if(sl_chg) note += StringFormat("SLwas=%.5f ", old_sl);
         if(tp_chg) note += StringFormat("TPwas=%.5f ", old_tp);
         if(vol_chg) note += StringFormat("VOLwas=%.2f ", old_vol);

         // Price units locked (profit distance of SL from entry)
         double entry = g_pos.PriceOpen();
         int dir = (g_pos.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;
         double lock = (sl > 0) ? dir * (sl - entry) : 0;
         double float_p = dir * ((g_pos.PositionType() == POSITION_TYPE_BUY
                                  ? SymbolInfoDouble(g_pos.Symbol(), SYMBOL_BID)
                                  : SymbolInfoDouble(g_pos.Symbol(), SYMBOL_ASK)) - entry);

         LogRow("MODIFY",
                g_pos.Symbol(),
                side,
                vol,
                entry,
                sl,
                tp,
                g_pos.Profit(),
                g_pos.Comment(),
                ticket,
                g_pos.Magic(),
                0, 0,
                "",
                StringFormat("%s|lock=%.2f|float=%.2f", note, lock, float_p));

         TrackPosition(ticket, sl, tp, vol);
      }
   }
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   // --- Deal added ---
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(!HistoryDealSelect(trans.deal)) return;
      string sym = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
      if(!SymbolOk(sym)) return;
      long magic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
      if(!MagicOk(magic)) return;

      long   dtype  = HistoryDealGetInteger(trans.deal, DEAL_TYPE);
      long   entry  = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
      double vol    = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
      double price  = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
      double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
      double sl     = HistoryDealGetDouble(trans.deal, DEAL_SL);
      double tp     = HistoryDealGetDouble(trans.deal, DEAL_TP);
      string cmt    = HistoryDealGetString(trans.deal, DEAL_COMMENT);
      ulong  pos_id = (ulong)HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
      ulong  order  = (ulong)HistoryDealGetInteger(trans.deal, DEAL_ORDER);
      long   reason = HistoryDealGetInteger(trans.deal, DEAL_REASON);
      string reason_str = DealReasonToString(reason);

      string side = SideFromDealType((ENUM_DEAL_TYPE)dtype);
      string event = "DEAL";
      string note  = "";

      if(entry == DEAL_ENTRY_IN)
      {
         event = "FILL";
         note = "IN";
         // Start tracking if position now exists
         if(g_pos.SelectByTicket(pos_id))
            TrackPosition(pos_id, g_pos.StopLoss(), g_pos.TakeProfit(), g_pos.Volume());
      }
      else if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
      {
         event = "CLOSE";
         note = (entry == DEAL_ENTRY_OUT_BY) ? "OUT_BY" : "OUT";
         // Approximate price move from comment/profit if possible
         if(vol > 0)
         {
            double move = profit / (vol * 100.0); // XAU $ move approx
            note += StringFormat("|move≈%.2f", move);
         }
         UntrackPosition(pos_id);
      }
      else if(entry == DEAL_ENTRY_INOUT)
      {
         event = "INOUT";
      }

      LogRow(event, sym, side, vol, price, sl, tp, profit, cmt,
             pos_id, magic, order, trans.deal, reason_str, note);
      return;
   }

   // --- Order added (pending placed) ---
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD)
   {
      if(!g_order.Select(trans.order)) return;   // COrderInfo::Select(ticket)
      if(!SymbolOk(g_order.Symbol())) return;
      if(!MagicOk(g_order.Magic())) return;

      ENUM_ORDER_TYPE t = g_order.OrderType();
      if(t != ORDER_TYPE_BUY_STOP && t != ORDER_TYPE_SELL_STOP &&
         t != ORDER_TYPE_BUY_LIMIT && t != ORDER_TYPE_SELL_LIMIT)
         return;

      LogRow("PENDING_ADD",
             g_order.Symbol(),
             SideFromOrderType(t),
             g_order.VolumeCurrent(),
             g_order.PriceOpen(),
             g_order.StopLoss(),
             g_order.TakeProfit(),
             0,
             g_order.Comment(),
             g_order.Ticket(),
             g_order.Magic(),
             g_order.Ticket(),
             0,
             "",
             "");
      return;
   }

   // --- Order deleted (cancel / filled remove) ---
   if(trans.type == TRADE_TRANSACTION_ORDER_DELETE)
   {
      // Order may already be gone from pool — use trans fields
      string sym = trans.symbol;
      if(!SymbolOk(sym)) return;

      string side = SideFromOrderType(trans.order_type);
      LogRow("PENDING_DEL",
             sym,
             side,
             trans.volume,
             trans.price,
             trans.price_sl,
             trans.price_tp,
             0,
             "",
             trans.order,
             0,
             trans.order,
             0,
             "",
             EnumToString(trans.order_state));
      return;
   }

   // --- Order update (pending price/SL change) ---
   if(trans.type == TRADE_TRANSACTION_ORDER_UPDATE)
   {
      if(!g_order.Select(trans.order)) return;   // COrderInfo::Select(ticket)
      if(!SymbolOk(g_order.Symbol())) return;
      if(!MagicOk(g_order.Magic())) return;

      ENUM_ORDER_TYPE t = g_order.OrderType();
      if(t != ORDER_TYPE_BUY_STOP && t != ORDER_TYPE_SELL_STOP &&
         t != ORDER_TYPE_BUY_LIMIT && t != ORDER_TYPE_SELL_LIMIT)
         return;

      LogRow("PENDING_UPD",
             g_order.Symbol(),
             SideFromOrderType(t),
             g_order.VolumeCurrent(),
             g_order.PriceOpen(),
             g_order.StopLoss(),
             g_order.TakeProfit(),
             0,
             g_order.Comment(),
             g_order.Ticket(),
             g_order.Magic(),
             g_order.Ticket(),
             0,
             "",
             "");
   }
}

//+------------------------------------------------------------------+
void DrawPanel()
{
   string name = "AL_BG";
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, 280);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, 100);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpPanelX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpPanelY);

   string txt = StringFormat(
      "ApexLogger v1.03\n%s\nTF: %s\nPos:%d  Pend:%d\nEq:%.2f\nSnap:%ds",
      g_log_path,
      g_timeframe_str,
      CountPositions(),
      CountPendings(),
      AccountInfoDouble(ACCOUNT_EQUITY),
      InpSnapshotSec);

   string tn = "AL_TXT";
   if(ObjectFind(0, tn) < 0)
   {
      ObjectCreate(0, tn, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, tn, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, tn, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, tn, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, tn, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, tn, OBJPROP_SELECTABLE, false);
   }
   ObjectSetInteger(0, tn, OBJPROP_XDISTANCE, InpPanelX + 8);
   ObjectSetInteger(0, tn, OBJPROP_YDISTANCE, InpPanelY + 6);
   ObjectSetString(0, tn, OBJPROP_TEXT, txt);
}
//+------------------------------------------------------------------+
