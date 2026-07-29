//+------------------------------------------------------------------+
//|                                              ZennApex_XAU.mq5    |
//|                     Reverse-engineered from live journal analysis |
//|                     XAUUSD only · Pending-stop grid · BE trail   |
//+------------------------------------------------------------------+
#property copyright   "ZennApex Research Build"
#property version     "1.21"
#property description "Multi-layer mirrored pending-stop grid for XAUUSD"
#property description "v1.21: wider initial SL (L0/L1/L2) — more room to reach BE before full stop"

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
//| INPUTS — all distances in PRICE units ($ on gold)                |
//+------------------------------------------------------------------+
input group "=== Core ==="
input long              InpMagic            = 157430;
input string            InpTradeComment     = "ZennApex";
input ENUM_LOT_MODE     InpLotMode          = LOT_FIXED;
input double            InpBaseLot          = 0.01;        // Keep small on small accounts
input double            InpRiskPercent      = 0.35;
input double            InpMaxLot           = 0.05;
input double            InpMaxMarginPct     = 35.0;        // Max margin use % of equity

input group "=== Break-Even & Trail ==="
input double            InpBE_Trigger       = 2.5;         // Profit $ to lock BE (keep early)
input double            InpBE_LockBuffer    = 1.0;         // SL = Entry ± this
input double            InpTrailStep        = 2.0;         // Larger steps — let winners breathe
input double            InpTrailStart       = 5.0;         // Trail starts later (was 3.0)

input group "=== Session ==="
input int               InpCancelHour       = 22;
input int               InpCancelMinute     = 0;
input int               InpStartHour        = 0;
input int               InpStartMinute      = 5;
input bool              InpClosePositionsAtCancel = false;

input group "=== Grid ==="
input int               InpMaxLayers        = 3;           // 3 layers = max 6 pending lines
input double            InpMinOffset        = 8.0;         // Min $ from market for a stop
input double            InpUpdateDistance   = 25.0;        // Only move pending if mid shifted by this $
input bool              InpOnlyOnNewBar     = true;        // Place/update only on new bar (cleaner)

input group "=== Filters ==="
input double            InpMaxSpread        = 0.80;
input bool              InpTradeOnMonday    = true;
input bool              InpTradeOnFriday    = true;

input group "=== Debug ==="
input bool              InpLogActions       = true;

//+------------------------------------------------------------------+
//| Layers — offset/sl/tp in PRICE units (from live journal)         |
//+------------------------------------------------------------------+
struct LayerConfig
{
   double lot_mult;
   double offset;      // half-spread from mid
   double sl_dist;
   double tp_dist;
   string tag;
};

// v1.21: wider SL on L0/L1/L2 so price has more room to hit BE
// before the hard stop. BE trigger stays early (2.5).
LayerConfig g_layers[] =
{
   // mult   offset  sl     tp     tag
   { 1.00,   30.0,  100.0,  28.5,  "L0" },  // SL was 83
   { 5.25,   30.0,   50.0,  17.0,  "L1" },  // SL was 34  ← main bleed
   { 4.00,   70.0,  110.0,  13.5,  "L2" },  // SL was 92
   {10.50,   70.0,   31.0,  20.0,  "L3" },
   { 6.50,  100.0,   20.0,  71.0,  "L4" },
   {10.25,  100.0,   32.0,  20.0,  "L5" },
   { 2.00,  125.0,   14.0,  40.5,  "L6" },
   {11.00,  125.0,   20.0,  82.0,  "L7" },
};

//+------------------------------------------------------------------+
CTrade        g_trade;
CPositionInfo g_pos;
COrderInfo    g_order;
CSymbolInfo   g_sym;

string   g_symbol;
double   g_point;
double   g_tick_size;
int      g_digits;
datetime g_last_cancel_day = 0;
datetime g_last_bar_time   = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   g_symbol = _Symbol;
   string u = g_symbol;
   StringToUpper(u);
   if(StringFind(u, "XAU") < 0 && StringFind(u, "GOLD") < 0)
   {
      Print("ZennApex: XAUUSD/GOLD only");
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

   Print("ZennApex v1.21 | ", g_symbol,
         " Layers=", MathMin(InpMaxLayers, ArraySize(g_layers)),
         " BaseLot=", InpBaseLot,
         " SL widened L0/L1/L2 | trail step=", InpTrailStep);

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) { }

//+------------------------------------------------------------------+
void OnTick()
{
   g_sym.RefreshRates();
   ManagePositions();
   CheckScheduledCancel();

   if(!IsTradingAllowed())
      return;

   if(InpOnlyOnNewBar)
   {
      datetime t = iTime(g_symbol, PERIOD_CURRENT, 0);
      if(t == g_last_bar_time)
         return;
      g_last_bar_time = t;
   }

   ManageGrid();
}

//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;
   if(dt.day_of_week == 1 && !InpTradeOnMonday)    return false;
   if(dt.day_of_week == 5 && !InpTradeOnFriday)    return false;

   int now_m    = dt.hour * 60 + dt.min;
   int cancel_m = InpCancelHour * 60 + InpCancelMinute;
   int start_m  = InpStartHour  * 60 + InpStartMinute;
   if(start_m < cancel_m && (now_m < start_m || now_m >= cancel_m))
      return false;

   if((g_sym.Ask() - g_sym.Bid()) > InpMaxSpread)
      return false;

   return true;
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
      if(!g_order.SelectByIndex(i)) continue;
      if(g_order.Symbol() != g_symbol) continue;
      long m = g_order.Magic();
      if(m < InpMagic || m >= InpMagic + ArraySize(g_layers)) continue;
      if(g_trade.OrderDelete(g_order.Ticket())) n++;
   }

   if(InpClosePositionsAtCancel)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(!g_pos.SelectByIndex(i)) continue;
         if(g_pos.Symbol() != g_symbol) continue;
         long m = g_pos.Magic();
         if(m < InpMagic || m >= InpMagic + ArraySize(g_layers)) continue;
         g_trade.PositionClose(g_pos.Ticket());
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
      if(!g_order.SelectByIndex(i)) continue;
      if(g_order.Symbol() != g_symbol) continue;
      if(g_order.Magic() != magic) continue;
      if(g_order.OrderType() != type) continue;
      out_price = g_order.PriceOpen();
      return g_order.Ticket();
   }
   return 0;
}

bool HasPosition(long magic, ENUM_POSITION_TYPE type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Symbol() != g_symbol) continue;
      if(g_pos.Magic() != magic) continue;
      if(g_pos.PositionType() == type) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void ManageGrid()
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

      if(!HasPosition(magic, POSITION_TYPE_BUY))
      {
         double existing_price = 0;
         ulong  ticket = FindPending(magic, ORDER_TYPE_BUY_STOP, existing_price);

         if(ticket > 0)
         {
            if(MathAbs(existing_price - want_buy) >= InpUpdateDistance)
            {
               g_trade.OrderDelete(ticket);
               ticket = 0;
            }
         }

         if(ticket == 0 && HasMarginRoom(lot))
         {
            double sl = NormalizeDouble(want_buy - layer.sl_dist, g_digits);
            double tp = NormalizeDouble(want_buy + layer.tp_dist, g_digits);
            if(IsPendingValid(ORDER_TYPE_BUY_STOP, want_buy, sl, tp))
            {
               g_trade.SetExpertMagicNumber(magic);
               string cmt = StringFormat("%s|%s|B", InpTradeComment, layer.tag);
               if(g_trade.BuyStop(lot, want_buy, g_symbol, sl, tp, ORDER_TIME_GTC, 0, cmt))
               {
                  if(InpLogActions)
                     Print("L", i, " BUY STOP ", lot, " @ ", want_buy, " SL=", sl, " TP=", tp);
               }
               g_trade.SetExpertMagicNumber(InpMagic);
            }
         }
      }

      if(!HasPosition(magic, POSITION_TYPE_SELL))
      {
         double existing_price = 0;
         ulong  ticket = FindPending(magic, ORDER_TYPE_SELL_STOP, existing_price);

         if(ticket > 0)
         {
            if(MathAbs(existing_price - want_sell) >= InpUpdateDistance)
            {
               g_trade.OrderDelete(ticket);
               ticket = 0;
            }
         }

         if(ticket == 0 && HasMarginRoom(lot))
         {
            double sl = NormalizeDouble(want_sell + layer.sl_dist, g_digits);
            double tp = NormalizeDouble(want_sell - layer.tp_dist, g_digits);
            if(IsPendingValid(ORDER_TYPE_SELL_STOP, want_sell, sl, tp))
            {
               g_trade.SetExpertMagicNumber(magic);
               string cmt = StringFormat("%s|%s|S", InpTradeComment, layer.tag);
               if(g_trade.SellStop(lot, want_sell, g_symbol, sl, tp, ORDER_TIME_GTC, 0, cmt))
               {
                  if(InpLogActions)
                     Print("L", i, " SELL STOP ", lot, " @ ", want_sell, " SL=", sl, " TP=", tp);
               }
               g_trade.SetExpertMagicNumber(InpMagic);
            }
         }
      }
   }
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

   double step = g_sym.LotsStep();
   if(step <= 0) step = 0.01;
   lot = MathFloor(lot / step + 1e-12) * step;
   lot = MathMax(g_sym.LotsMin(), MathMin(MathMin(g_sym.LotsMax(), InpMaxLot), lot));
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!g_pos.SelectByIndex(i)) continue;
      if(g_pos.Symbol() != g_symbol) continue;
      long magic = g_pos.Magic();
      if(magic < InpMagic || magic >= InpMagic + ArraySize(g_layers)) continue;

      ulong  ticket = g_pos.Ticket();
      double entry  = g_pos.PriceOpen();
      double cur_sl = g_pos.StopLoss();
      double cur_tp = g_pos.TakeProfit();
      long   type   = g_pos.PositionType();
      double price  = (type == POSITION_TYPE_BUY) ? g_sym.Bid() : g_sym.Ask();
      int    dir    = (type == POSITION_TYPE_BUY) ? 1 : -1;

      double profit  = dir * (price - entry);
      double sl_lock = (cur_sl > 0) ? dir * (cur_sl - entry) : -999;

      bool be_locked = (sl_lock >= InpBE_LockBuffer - 0.15);

      if(!be_locked && profit >= InpBE_Trigger)
      {
         double new_sl = NormalizeDouble(entry + dir * InpBE_LockBuffer, g_digits);
         if(IsSLValid(type, price, new_sl))
         {
            if(g_trade.PositionModify(ticket, new_sl, cur_tp) && InpLogActions)
               Print("BE #", ticket, " profit=", DoubleToString(profit, 2), " SL=", new_sl);
         }
         continue;
      }

      if(be_locked && profit >= InpBE_LockBuffer + InpTrailStart)
      {
         double extra  = profit - InpBE_LockBuffer;
         double steps  = MathFloor(extra / InpTrailStep);
         if(steps < 1) continue;
         double want   = InpBE_LockBuffer + (steps - 1) * InpTrailStep;
         if(want <= sl_lock + InpTrailStep * 0.4) continue;

         double new_sl = NormalizeDouble(entry + dir * want, g_digits);
         if(IsSLValid(type, price, new_sl))
         {
            if(g_trade.PositionModify(ticket, new_sl, cur_tp) && InpLogActions)
               Print("TRAIL #", ticket, " lock=", DoubleToString(want, 2));
         }
      }
   }
}

//+------------------------------------------------------------------+
bool IsSLValid(long pos_type, double price, double sl)
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