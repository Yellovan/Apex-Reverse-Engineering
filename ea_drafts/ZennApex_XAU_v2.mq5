//+------------------------------------------------------------------+
//| Reconstruction, not a verified clone -- see docs/Pending_Orders.md |
//| and docs/Trailing_Stop.md in the Apex-Reverse-Engineering repo for |
//| the underlying evidence. Grid ladder + trail model are measured    |
//| from real Apex data; the spike-guard is a deliberate, NON-Apex     |
//| addition, currently OFF by default (2026-07-30 walk-forward test   |
//| showed the in-sample-"best" setting was the out-of-sample worst --|
//| see the Spike Guard input group below for the numbers).            |
//+------------------------------------------------------------------+
#property copyright   "ZennApex Research"
#property version     "2.00"
#property description "Multi-layer mirrored pending-stop grid for XAUUSD, calibrated against real Apex evidence"
#property description "v2: measured tier ladder, continuous-trail model, optional spike guard (non-Apex addition)"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//+------------------------------------------------------------------+
enum ENUM_LOT_MODE
{
   LOT_FIXED = 0,
   LOT_RISK_PERCENT
};

//+------------------------------------------------------------------+
//| INPUTS -- all distances in PRICE units ($ on gold)                |
//+------------------------------------------------------------------+
input group "=== Core ==="
input long              InpMagic            = 157430;
input string            InpTradeComment     = "ZennApexV2";
input ENUM_LOT_MODE     InpLotMode          = LOT_FIXED;
input double            InpBaseLot          = 0.01;
input double            InpRiskPercent      = 0.35;
input double            InpMaxLot           = 0.20;
input double            InpMaxMarginPct     = 35.0;

input group "=== Break-Even & Trail (calibrated from 1554 real tickets, 2026-07-30) ==="
input double            InpBE_Trigger       = 1.1;    // profit ($) before SL first moves to profit side -- median observed 1.07
input double            InpBE_LockBuffer    = 0.8;    // initial lock distance once BE triggers
input double            InpTrailDistance    = 1.3;    // continuous trailing distance behind price once in profit -- median step observed 1.24
input double            InpTrailMinStepSize = 0.15;   // don't re-modify for moves smaller than this (avoid order-spam; observed p10 step was 0.16)

input group "=== Session ==="
input int               InpCancelHour       = 22;     // live evidence shows pending cleanup ~22:45 server time
input int               InpCancelMinute     = 45;
input int               InpStartHour        = 0;
input int               InpStartMinute      = 5;
input bool              InpClosePositionsAtCancel = false;

input group "=== Grid (11-tier ladder measured from E-018, docs/Pending_Orders.md) ==="
input int               InpMaxLayers        = 11;     // live evidence shows ~11 tiers active simultaneously -- raise, don't leave at 3
input double            InpMinOffset        = 8.0;
input double            InpUpdateDistance   = 25.0;
input bool              InpOnlyOnNewBar     = true;

input group "=== Filters ==="
input double            InpMaxSpread        = 0.80;
input bool              InpTradeOnMonday    = true;
input bool              InpTradeOnFriday    = true;

input group "=== Spike Guard (NOT observed Apex behaviour -- deliberate safety addition) ==="
// Default OFF as of 2026-07-30: an in-sample sweep on 2026-04-20..07-30
// found ATR=3.0 as the "best" setting (+4.49 vs -0.55 pts/spike), but an
// out-of-sample test on 2026-01-01..04-19 (not used for tuning) reversed
// this completely -- guard-off ($23,146) beat baseline ($22,906), which
// beat the "tuned" ATR=3.0 ($22,055, the WORST of the three). This is a
// textbook overfitting signature, not a validated edge. Leave off until
// a regime-conditional version (only active in genuinely choppy periods,
// not blanket-on) is designed and walk-forward tested.
input bool              InpUseSpikeGuard    = false;
input double            InpSpikeRangeAtr    = 6.0;    // flag a bar as a "spike" if its M1 range >= this x recent avg 1-min range
input double            InpSpikeInitialFrac = 0.35;   // fraction of normal lot taken immediately on a spike-triggered breakout
input double            InpSpikeRetestPts   = 15.0;   // pullback (points) required before adding the remaining size
input int               InpSpikeLookoutMin  = 60;     // give up waiting for the retest after this many minutes

input group "=== Debug ==="
input bool              InpLogActions       = true;

//+------------------------------------------------------------------+
//| Layers -- offset/sl/tp in PRICE units, SL/TP measured from 634    |
//| real order placements in E-018 (docs/Pending_Orders.md, tiers     |
//| A-K). Offset column is NOT independently confirmed (no evidence   |
//| source records bid/ask at placement time) -- kept as the v1.21    |
//| draft's approximate values pending better data.                   |
//+------------------------------------------------------------------+
struct LayerConfig
{
   double lot_mult;   // vs. tier A ratio, measured from lot-ladder (0.04/0.08/.../0.53)
   double offset;     // UNCONFIRMED -- approximate, see docs/Pending_Orders.md open question
   double sl_dist;    // measured, docs/Pending_Orders.md
   double tp_dist;    // measured, docs/Pending_Orders.md
   string tag;
};

LayerConfig g_layers[] =
{
   // mult    offset   sl      tp     tag
   {  1.00,    30.0,   82.9,   28.7,  "A" },
   {  2.00,    30.0,   14.2,   40.5,  "B" },
   {  3.00,    55.0,   82.5,   14.0,  "C" },
   {  3.75,    55.0,   92.6,   13.5,  "D" },
   {  5.00,    70.0,   34.2,   17.1,  "E" },
   {  6.25,    70.0,   20.2,   70.8,  "F" },
   {  7.75,    90.0,   70.7,   29.3,  "G" },
   {  9.25,    90.0,   54.5,   17.1,  "H" },
   { 10.25,   110.0,   31.2,   20.0,  "I" },
   { 10.75,   110.0,   20.2,   82.9,  "J" },
   { 12.75,   130.0,   50.5,   36.4,  "K" },
};

//+------------------------------------------------------------------+
CTrade        g_trade;
CSymbolInfo   g_sym;

string   g_symbol;
double   g_point;
double   g_tick_size;
int      g_digits;
datetime g_last_cancel_day = 0;
datetime g_last_bar_time   = 0;

// Spike-guard state: tickets waiting for a retest add-on
struct PendingAddOn
{
   ulong  ticket;
   long   magic;
   string symbol;
   int    dir;           // 1 = buy, -1 = sell
   double spike_extreme;
   double remaining_lot;
   double sl_dist;        // same tier's SL/TP distance -- the add-on gets its own
   double tp_dist;        // protective stop too, it does NOT inherit one automatically
   datetime deadline;
   bool   awaiting_fill;  // true = a reduced order was placed, wait for it to fill first;
                           // false = no immediate entry at all (lot too small to reduce,
                           // see TryPlaceOrPromoteLayer), go straight to watching the retest
};
PendingAddOn g_pending_addons[];

// Rolling 1-min range tracker for spike detection
double   g_recent_ranges[60];
int      g_recent_ranges_idx = 0;
bool     g_recent_ranges_full = false;

//+------------------------------------------------------------------+
int OnInit()
{
   g_symbol = _Symbol;
   string u = g_symbol;
   StringToUpper(u);
   if(StringFind(u, "XAU") < 0 && StringFind(u, "GOLD") < 0)
   {
      Print("ZennApexV2: XAUUSD/GOLD only");
      return INIT_FAILED;
   }

   if(!g_sym.Name(g_symbol))
      return INIT_FAILED;

   g_sym.Refresh();
   g_point     = g_sym.Point();
   g_tick_size = g_sym.TickSize();
   g_digits    = (int)g_sym.Digits();

   g_trade.SetDeviationInPoints(50);
   g_trade.SetTypeFillingBySymbol(g_symbol);
   g_trade.LogLevel(LOG_LEVEL_ERRORS);

   ArrayInitialize(g_recent_ranges, 0.0);

   // Same real-world gotcha bit ApexLogger last week: OnInit() always runs
   // once on attach, but if Algo Trading is off (globally, or "Allow Algo
   // Trading" unticked for this EA specifically), OnTick() never fires
   // again afterward -- the EA looks loaded but silently does nothing.
   bool termAllowed = (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
   bool mqlAllowed  = (bool)MQLInfoInteger(MQL_TRADE_ALLOWED);
   if(!termAllowed || !mqlAllowed)
      Print("!!! ZennApexV2 WARNING: Algo Trading looks DISABLED (terminal=", termAllowed,
            " this-EA=", mqlAllowed, "). OnTick will likely never fire. Check the 'Algo Trading' ",
            "toolbar button AND this EA's Properties -> Common -> 'Allow Algo Trading', then re-attach.");
   else
      Print("ZennApexV2: Algo Trading permissions OK.");

   Print("ZennApexV2 v2.00 | ", g_symbol,
         " Layers=", MathMin(InpMaxLayers, ArraySize(g_layers)),
         " BaseLot=", InpBaseLot,
         " SpikeGuard=", InpUseSpikeGuard ? "ON" : "OFF",
         " TrailDist=", InpTrailDistance);

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) { }

//+------------------------------------------------------------------+
void OnTick()
{
   g_sym.RefreshRates();
   UpdateRecentRange();
   ManagePositions();
   ManagePendingAddOns();
   CheckScheduledCancel();

   string block_reason = "";
   if(!IsTradingAllowed(block_reason))
   {
      LogBlockedOnce(block_reason);
      return;
   }

   // Spike detection must run every tick/minute -- NOT gated behind
   // InpOnlyOnNewBar's chart-period throttle. On an H1 chart, gating it
   // there meant the spike check only ever fired once per hour (missing
   // 59 of every 60 minutes) -- found via the 2026-07 backtest showing
   // zero spike-guard triggers despite a known FOMC spike in that window.
   int spike_dir = 0;
   bool spike_now = InpUseSpikeGuard && IsSpikeBarNow(spike_dir);

   bool run_grid = spike_now;   // a fresh spike always gets an immediate reaction
   if(InpOnlyOnNewBar)
   {
      datetime t = iTime(g_symbol, PERIOD_CURRENT, 0);
      if(t != g_last_bar_time)
      {
         g_last_bar_time = t;
         run_grid = true;
      }
   }
   else
      run_grid = true;

   if(run_grid)
      ManageGrid(spike_now, spike_dir);
}

//+------------------------------------------------------------------+
//| Track a rolling window of 1-min bar ranges to judge whether the   |
//| CURRENT bar (shift 0, still forming) is an abnormal spike --      |
//| mirrors the offline backtest's percentile-based threshold, but    |
//| computed live from a trailing window instead of a fixed constant. |
//+------------------------------------------------------------------+
double AvgRecentRange()
{
   int n = g_recent_ranges_full ? 60 : g_recent_ranges_idx;
   if(n == 0) return 0.0;
   double sum = 0;
   for(int i = 0; i < n; i++) sum += g_recent_ranges[i];
   return sum / n;
}

void UpdateRecentRange()
{
   static datetime last_min = 0;
   datetime cur_min = iTime(g_symbol, PERIOD_M1, 0);
   if(cur_min == last_min) return;
   last_min = cur_min;

   double range = iHigh(g_symbol, PERIOD_M1, 1) - iLow(g_symbol, PERIOD_M1, 1);
   g_recent_ranges[g_recent_ranges_idx] = range;
   g_recent_ranges_idx = (g_recent_ranges_idx + 1) % 60;
   if(g_recent_ranges_idx == 0) g_recent_ranges_full = true;
}

bool IsSpikeBarNow(int &out_dir)
{
   double avg = AvgRecentRange();
   if(avg <= 0) return false;
   double open1  = iOpen(g_symbol, PERIOD_M1, 1);
   double close1 = iClose(g_symbol, PERIOD_M1, 1);
   double high1  = iHigh(g_symbol, PERIOD_M1, 1);
   double low1   = iLow(g_symbol, PERIOD_M1, 1);
   double range  = high1 - low1;
   if(range < InpSpikeRangeAtr * avg) return false;
   out_dir = (close1 >= open1) ? 1 : -1;
   return true;
}

//+------------------------------------------------------------------+
bool IsTradingAllowed(string &reason)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.day_of_week == 0 || dt.day_of_week == 6) { reason = "weekend"; return false; }
   if(dt.day_of_week == 1 && !InpTradeOnMonday)   { reason = "Monday disabled (InpTradeOnMonday)"; return false; }
   if(dt.day_of_week == 5 && !InpTradeOnFriday)   { reason = "Friday disabled (InpTradeOnFriday)"; return false; }

   int now_m    = dt.hour * 60 + dt.min;
   int cancel_m = InpCancelHour * 60 + InpCancelMinute;
   int start_m  = InpStartHour  * 60 + InpStartMinute;
   if(start_m < cancel_m && (now_m < start_m || now_m >= cancel_m))
   {
      reason = StringFormat("outside session window (now=%02d:%02d, start=%02d:%02d, cancel=%02d:%02d)",
                             dt.hour, dt.min, InpStartHour, InpStartMinute, InpCancelHour, InpCancelMinute);
      return false;
   }

   double spread = g_sym.Ask() - g_sym.Bid();
   if(spread > InpMaxSpread)
   {
      reason = StringFormat("spread too wide (%.2f > InpMaxSpread=%.2f)", spread, InpMaxSpread);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
void LogBlockedOnce(const string reason)
{
   if(!InpLogActions || reason == "") return;
   static string last_reason = "";
   static datetime last_print = 0;
   datetime now = TimeCurrent();
   if(reason == last_reason && (now - last_print) < 300) return;   // throttle: max once/5min per reason
   Print("ZennApexV2: grid paused -- ", reason);
   last_reason = reason;
   last_print = now;
}

//+------------------------------------------------------------------+
void CheckScheduledCancel()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime day0 = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
   if(g_last_cancel_day == day0) return;

   if(dt.hour * 60 + dt.min < InpCancelHour * 60 + InpCancelMinute)
      return;

   int n = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket)) continue;
      if(OrderGetString(ORDER_SYMBOL) != g_symbol) continue;
      long m = OrderGetInteger(ORDER_MAGIC);
      if(m < InpMagic || m >= InpMagic + ArraySize(g_layers)) continue;
      if(g_trade.OrderDelete(ticket)) n++;
   }

   if(InpClosePositionsAtCancel)
   {
      int total = PositionsTotal();
      for(int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
         long m = PositionGetInteger(POSITION_MAGIC);
         if(m < InpMagic || m >= InpMagic + ArraySize(g_layers)) continue;
         g_trade.PositionClose(ticket);
      }
   }

   g_last_cancel_day = day0;
   if(InpLogActions) Print("Scheduled cancel: ", n, " pendings removed");
}

//+------------------------------------------------------------------+
bool HasMarginRoom(double lot)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);
   if(equity <= 0) return false;

   double need = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, g_symbol, lot, g_sym.Ask(), need))
      return false;

   if(margin + need > equity * (InpMaxMarginPct / 100.0))
      return false;
   if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) < need * 1.2)
      return false;
   return true;
}

//+------------------------------------------------------------------+
ulong FindPending(long magic, ENUM_ORDER_TYPE type, double &out_price)
{
   out_price = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0 || !OrderSelect(ticket)) continue;
      if(OrderGetString(ORDER_SYMBOL) != g_symbol) continue;
      if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != type) continue;
      out_price = OrderGetDouble(ORDER_PRICE_OPEN);
      return ticket;
   }
   return 0;
}

bool HasPosition(long magic, ENUM_POSITION_TYPE type)
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == type) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void ManageGrid(bool spike_now, int spike_dir)
{
   int n = MathMin(InpMaxLayers, ArraySize(g_layers));
   double mid = (g_sym.Ask() + g_sym.Bid()) * 0.5;

   for(int i = 0; i < n; i++)
   {
      long magic = InpMagic + i;
      LayerConfig layer = g_layers[i];
      double lot = CalcLot(layer);
      if(lot <= 0) continue;

      double want_buy  = NormalizeDouble(mid + layer.offset, g_digits);
      double want_sell = NormalizeDouble(mid - layer.offset, g_digits);

      if(want_buy - g_sym.Ask() < InpMinOffset)
         want_buy = NormalizeDouble(g_sym.Ask() + InpMinOffset, g_digits);
      if(g_sym.Bid() - want_sell < InpMinOffset)
         want_sell = NormalizeDouble(g_sym.Bid() - InpMinOffset, g_digits);

      TryPlaceOrPromoteLayer(magic, layer, ORDER_TYPE_BUY_STOP, want_buy, lot,
                              spike_now && spike_dir > 0);
      TryPlaceOrPromoteLayer(magic, layer, ORDER_TYPE_SELL_STOP, want_sell, lot,
                              spike_now && spike_dir < 0);
   }
}

void TryPlaceOrPromoteLayer(long magic, const LayerConfig &layer, ENUM_ORDER_TYPE type,
                             double want_price, double lot, bool is_spike_side)
{
   bool is_buy = (type == ORDER_TYPE_BUY_STOP);
   ENUM_POSITION_TYPE ptype = is_buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   if(HasPosition(magic, ptype)) return;

   double existing_price = 0;
   ulong ticket = FindPending(magic, type, existing_price);
   if(ticket > 0)
   {
      if(MathAbs(existing_price - want_price) >= InpUpdateDistance)
      {
         g_trade.OrderDelete(ticket);
         ticket = 0;
      }
   }
   if(ticket != 0) return;

   // On the smallest tiers, lot*InpSpikeInitialFrac rounds back up to the
   // broker's minimum lot -- i.e. the SAME as the full size, so "reducing"
   // does nothing and the spike-guard's whole point (don't take full size
   // right at the spike extreme) would be silently defeated. When that
   // happens, defer the ENTIRE lot to the retest instead of placing
   // anything immediately, rather than falling back to a full-size entry.
   double full_lot = NormalizeLot(lot);
   double place_lot = full_lot;
   bool fully_deferred = false;
   if(is_spike_side)
   {
      double reduced_lot = NormalizeLot(lot * InpSpikeInitialFrac);
      if(reduced_lot >= full_lot - 1e-9)
      {
         fully_deferred = true;
         if(InpLogActions)
            Print(layer.tag, ": spike lot too small to reduce (full=", full_lot,
                  ") -- deferring entire size to retest, no immediate entry");
         RegisterPendingAddOn(magic, type, want_price, full_lot, layer.sl_dist, layer.tp_dist, false);
         return;
      }
      place_lot = reduced_lot;
   }
   if(place_lot <= 0)
   {
      if(InpLogActions) Print(layer.tag, ": skipped, place_lot<=0 (lot=", lot, " frac-applied=", is_spike_side, ")");
      return;
   }
   if(!HasMarginRoom(place_lot))
   {
      if(InpLogActions) Print(layer.tag, ": skipped, no margin room for lot=", place_lot,
                               " equity=", AccountInfoDouble(ACCOUNT_EQUITY),
                               " margin=", AccountInfoDouble(ACCOUNT_MARGIN));
      return;
   }

   double sl = is_buy ? NormalizeDouble(want_price - layer.sl_dist, g_digits)
                       : NormalizeDouble(want_price + layer.sl_dist, g_digits);
   double tp = is_buy ? NormalizeDouble(want_price + layer.tp_dist, g_digits)
                       : NormalizeDouble(want_price - layer.tp_dist, g_digits);
   if(!IsPendingValid(type, want_price, sl, tp))
   {
      if(InpLogActions)
      {
         long stops = SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL);
         Print(layer.tag, ": IsPendingValid rejected ", is_buy ? "BUY_STOP" : "SELL_STOP",
               " price=", want_price, " sl=", sl, " tp=", tp,
               " bid=", g_sym.Bid(), " ask=", g_sym.Ask(), " stops_level_pts=", stops);
      }
      return;
   }

   g_trade.SetExpertMagicNumber(magic);
   string cmt = StringFormat("%s|%s|%s", InpTradeComment, layer.tag, is_buy ? "B" : "S");
   bool sent = is_buy
      ? g_trade.BuyStop(place_lot, want_price, g_symbol, sl, tp, ORDER_TIME_GTC, 0, cmt)
      : g_trade.SellStop(place_lot, want_price, g_symbol, sl, tp, ORDER_TIME_GTC, 0, cmt);
   g_trade.SetExpertMagicNumber(InpMagic);

   if(sent && InpLogActions)
      Print(layer.tag, is_spike_side ? " SPIKE-REDUCED " : " ", is_buy ? "BUY STOP" : "SELL STOP",
            " ", place_lot, " @ ", want_price, " SL=", sl, " TP=", tp);
   else if(!sent)
      Print(layer.tag, ": ORDER FAILED ", is_buy ? "BUY_STOP" : "SELL_STOP",
            " lot=", place_lot, " price=", want_price, " sl=", sl, " tp=", tp,
            " retcode=", g_trade.ResultRetcode(),
            " (", g_trade.ResultRetcodeDescription(), ")");

   // If this was a reduced spike-side entry, register the remaining size to
   // add on a confirmed retest. Not observed Apex behaviour -- see header.
   if(sent && is_spike_side && place_lot < lot - 1e-9)
   {
      RegisterPendingAddOn(magic, type, want_price, lot - place_lot, layer.sl_dist, layer.tp_dist, true);
   }
}

double NormalizeLot(double lot)
{
   double step = g_sym.LotsStep();
   if(step <= 0) step = 0.01;
   lot = MathFloor(lot / step + 1e-12) * step;
   return MathMax(g_sym.LotsMin(), MathMin(g_sym.LotsMax(), lot));
}

//+------------------------------------------------------------------+
//| Spike-guard add-on bookkeeping. When a reduced entry fills on the |
//| spike side, watch for a pullback of InpSpikeRetestPts before      |
//| adding the remaining size -- or give up after InpSpikeLookoutMin. |
//| NOTE: this account runs in hedging mode (confirmed live evidence, |
//| "trading has been enabled - hedging mode"), so the add-on opens a |
//| SECOND, independent position -- it does NOT merge into the first  |
//| one's ticket. Same magic number is used so ManagePositions()'s    |
//| trailing loop picks it up and manages it on its own thereafter.   |
//+------------------------------------------------------------------+
void RegisterPendingAddOn(long magic, ENUM_ORDER_TYPE type, double entry_ref_price,
                           double remaining_lot, double sl_dist, double tp_dist, bool awaiting_fill)
{
   int n = ArraySize(g_pending_addons);
   ArrayResize(g_pending_addons, n + 1);
   g_pending_addons[n].ticket        = 0;   // sentinel: 0 = reduced entry not yet confirmed filled
   g_pending_addons[n].magic         = magic;
   g_pending_addons[n].symbol        = g_symbol;
   g_pending_addons[n].dir           = (type == ORDER_TYPE_BUY_STOP) ? 1 : -1;
   g_pending_addons[n].spike_extreme = entry_ref_price;
   g_pending_addons[n].remaining_lot = remaining_lot;
   g_pending_addons[n].sl_dist       = sl_dist;
   g_pending_addons[n].tp_dist       = tp_dist;
   g_pending_addons[n].deadline      = TimeCurrent() + InpSpikeLookoutMin * 60;
   g_pending_addons[n].awaiting_fill = awaiting_fill;
}

void ManagePendingAddOns()
{
   for(int i = ArraySize(g_pending_addons) - 1; i >= 0; i--)
   {
      PendingAddOn a = g_pending_addons[i];
      if(TimeCurrent() > a.deadline)
      {
         RemoveAddOn(i);
         continue;
      }

      // "Partial" mode: only act once the reduced position actually exists
      // (fill confirmed). "Fully deferred" mode (awaiting_fill=false, see
      // TryPlaceOrPromoteLayer) has no initial order at all -- skip straight
      // to watching the retest condition below.
      if(a.awaiting_fill && a.ticket == 0)
      {
         if(!HasPosition(a.magic, a.dir > 0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
            continue;
         g_pending_addons[i].ticket = 1; // sentinel: "position exists", exact ticket not needed below
      }

      double bid = g_sym.Bid(), ask = g_sym.Ask();
      bool retested = (a.dir > 0) ? (bid <= a.spike_extreme - InpSpikeRetestPts)
                                   : (ask >= a.spike_extreme + InpSpikeRetestPts);
      if(!retested) continue;

      if(HasMarginRoom(a.remaining_lot))
      {
         double fill_price = (a.dir > 0) ? ask : bid;
         double add_sl = (a.dir > 0) ? NormalizeDouble(fill_price - a.sl_dist, g_digits)
                                       : NormalizeDouble(fill_price + a.sl_dist, g_digits);
         double add_tp = (a.dir > 0) ? NormalizeDouble(fill_price + a.tp_dist, g_digits)
                                       : NormalizeDouble(fill_price - a.tp_dist, g_digits);
         g_trade.SetExpertMagicNumber(a.magic);
         bool ok = (a.dir > 0)
            ? g_trade.Buy(a.remaining_lot, a.symbol, 0, add_sl, add_tp, InpTradeComment + "|addon")
            : g_trade.Sell(a.remaining_lot, a.symbol, 0, add_sl, add_tp, InpTradeComment + "|addon");
         g_trade.SetExpertMagicNumber(InpMagic);
         if(ok && InpLogActions)
            Print("Spike-guard add-on filled: magic=", a.magic, " lot=", a.remaining_lot,
                  " sl=", add_sl, " tp=", add_tp);
      }
      RemoveAddOn(i);
   }
}

void RemoveAddOn(int i)
{
   int n = ArraySize(g_pending_addons);
   g_pending_addons[i] = g_pending_addons[n - 1];
   ArrayResize(g_pending_addons, n - 1);
}

//+------------------------------------------------------------------+
bool IsPendingValid(ENUM_ORDER_TYPE type, double price, double sl, double tp)
{
   long stops = SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double min_d = MathMax(stops * g_point, g_tick_size * 2);

   if(type == ORDER_TYPE_BUY_STOP)
   {
      if(price <= g_sym.Ask() + min_d) return false;
      if(sl > 0 && (price - sl) < min_d) return false;
      if(tp > 0 && (tp - price) < min_d) return false;
   }
   else
   {
      if(price >= g_sym.Bid() - min_d) return false;
      if(sl > 0 && (sl - price) < min_d) return false;
      if(tp > 0 && (price - tp) < min_d) return false;
   }
   return true;
}

//+------------------------------------------------------------------+
double CalcLot(const LayerConfig &layer)
{
   double lot;
   if(InpLotMode == LOT_FIXED)
      lot = InpBaseLot * layer.lot_mult;
   else
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double risk   = equity * (InpRiskPercent / 100.0);
      double tval   = g_sym.TickValue();
      double tsz    = g_sym.TickSize();
      if(tsz > 0 && tval > 0 && layer.sl_dist > 0)
      {
         double per_lot = (layer.sl_dist / tsz) * tval;
         lot = (per_lot > 0) ? (risk / per_lot) * layer.lot_mult : InpBaseLot;
      }
      else lot = InpBaseLot;
   }
   lot = MathMin(lot, InpMaxLot);
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Continuous trailing model (replaces v1.21's discrete-step model). |
//| Calibrated from 40,274 real SL-modify events across 1554 matched  |
//| tickets (2026-07-30 re-analysis): median first-profit-lock ~1.07  |
//| points, median subsequent step ~1.24 points -- i.e. Apex re-      |
//| evaluates and nudges SL almost continuously rather than waiting   |
//| for a fixed profit multiple before jumping SL by a fixed amount.  |
//+------------------------------------------------------------------+
void ManagePositions()
{
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic < InpMagic || magic >= InpMagic + ArraySize(g_layers)) continue;

      double entry  = PositionGetDouble(POSITION_PRICE_OPEN);
      double cur_sl = PositionGetDouble(POSITION_SL);
      double cur_tp = PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double price  = (type == POSITION_TYPE_BUY) ? g_sym.Bid() : g_sym.Ask();
      int    dir    = (type == POSITION_TYPE_BUY) ? 1 : -1;

      double profit  = dir * (price - entry);
      double sl_lock = (cur_sl > 0) ? dir * (cur_sl - entry) : -999;

      // Desired lock = profit minus the trailing distance, floored at the
      // BE buffer once triggered. Never move SL backwards (only forward).
      double desired_lock;
      if(profit < InpBE_Trigger)
         continue;   // not yet in enough profit to touch SL at all
      if(sl_lock < InpBE_LockBuffer - 1e-9)
         desired_lock = InpBE_LockBuffer;                       // first move: lock the BE buffer
      else
         desired_lock = profit - InpTrailDistance;               // continuous trail behind price

      if(desired_lock <= sl_lock + InpTrailMinStepSize)
         continue;   // not enough improvement yet -- avoid order-spam

      double new_sl = NormalizeDouble(entry + dir * desired_lock, g_digits);
      if(IsSLValid(type, price, new_sl))
      {
         if(g_trade.PositionModify(ticket, new_sl, cur_tp) && InpLogActions)
            Print("TRAIL #", ticket, " lock=", DoubleToString(desired_lock, 2));
      }
   }
}

//+------------------------------------------------------------------+
bool IsSLValid(ENUM_POSITION_TYPE pos_type, double price, double sl)
{
   long stops = SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double min_d = MathMax(stops * g_point, g_tick_size);
   if(pos_type == POSITION_TYPE_BUY)
      return (sl < price - min_d);
   return (sl > price + min_d);
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(!InpLogActions) return;
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
      Print("Deal #", trans.deal, " ", EnumToString(trans.deal_type),
            " ", trans.volume, " @ ", trans.price);
}
//+------------------------------------------------------------------+
