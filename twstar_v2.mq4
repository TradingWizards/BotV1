//+------------------------------------------------------------------+
//|                                                   twstar_rsi.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

extern int MA_Period=20;
datetime lasttime = NULL;

extern double Lots = 1.0;
extern int MagicNumber = 12348;
extern int Slippage = 3;
double StopLossLevel = 0;
double TakeProfitLevel = 0;

int P = 1;
double StopLoss = 30;
double TrailingStop = 10;
extern int ShowBars = 500;

int Total, ticket1, ticket2;
double close_array[];
double sma_volume = 0;
double sma_200 = 0;
double rsi_current = 0;
double rsi_previous = 0;
double previous_close = 0;
double sma_5_low = 0;
double sma_5_high = 0;
double macd = 0;

double current_bid_price = 0;
double eis_up = 0.0, eis_down = 0.0, eis_neutral = 0.0, ma_65 = 0.0;

int init() {
   return(INIT_SUCCEEDED);
}
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   return 0;   
}

int start() {
   //double sma_volume = iCustom(NULL, 0, "project\\volumeMA", MA_Period, 0, 0); // returns 1 when it is green
   //double sma_60 = iMA(NULL,0,60,0,MODE_EMA,PRICE_CLOSE,0);
   
   current_bid_price = NormalizeDouble(Bid, Digits);
   Total = OrdersTotal(); // total # of orders
   for (int i = 0; i < Total; i ++) {
      ticket1 = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);

      if(OrderType() == OP_BUY &&  OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
         if(Bid>OrderOpenPrice() && (OrderStopLoss() < (Bid - P * Point * TrailingStop)) ) {
         //if(Bid - OrderOpenPrice() > P * Point * (TrailingStop) ) {
            //Print("Buy->Order stop loss: " + OrderStopLoss()+","+ (Bid - P * Point * TrailingStop));
            ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - P * Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
            continue;
         }
      } else if(OrderType() == OP_SELL &&  OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
         if(OrderOpenPrice()>Ask && (OrderStopLoss() > (Ask + P * Point * TrailingStop)) ) {
         //if((OrderOpenPrice() - Ask) > (P * Point * (TrailingStop))) {
            //Print("Sell->Order stop loss: " + OrderStopLoss()+","+ (Ask + P * Point * TrailingStop));
            ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + P * Point * TrailingStop, OrderTakeProfit(), 0, DarkOrange);
            continue;
         }
      } else {
         continue;
      }
   }

   if(NewBar()) {
      //if(sma_volume>40000 && previous_close>sma_200 && rsi_current<20) {
      //if(previous_close>sma_200 && rsi_current<5 ) {
      CopyClose(Symbol(),0,0,5,close_array);
      //if(previous_close>sma_200 && current_bid_price>sma_5_low && close_array[0]>close_array[1] ) {
      if(macd<-2.5) {
         SendBuyOrder("MACD");
      } else if(previous_close>sma_200 && current_bid_price>sma_5_low && rsi_current<30 ) {
         SendBuyOrder("SMA");
      } else if (eis_up == 1 && previous_close>ma_65) {
         SendBuyOrder("EIS");
      } else if(rsi_previous<6) { //  && rsi_current>rsi_previous
         SendBuyOrder("RSI");
      } else if(macd>2.5) {
         SendSellOrder("MACD");
      } else if(previous_close<sma_200 && current_bid_price<sma_5_high && rsi_current>70 ) {
         SendSellOrder("SMA");
      } else if( (Bid < ma_65 || eis_down == 1 || eis_neutral == 1) && rsi_current>70 ) {
         SendSellOrder("EIS");
      } else if(rsi_previous>92) {
         SendSellOrder("RSI");
      }
   }

   return(0);
}

void SendBuyOrder(string filter_name) {
   //Check free margin   
   if(AccountFreeMarginCheck(Symbol(),OP_BUY,Lots)<=0 || GetLastError()==134) {   
      Print("We have no money to buy. Free Margin = ", AccountFreeMargin() );   
      return;   
   }
   
   current_bid_price = NormalizeDouble(Bid, Digits);
   //StopLossLevel = NormalizeDouble(current_bid_price - Point * 100, Digits);
   //StopLossLevel = Bid - StopLoss * Point * P;
   StopLossLevel = Ask - StopLoss * Point * P;
   TakeProfitLevel = 0;
   
   ticket1 = OrderSend(Symbol(), OP_BUY, Lots, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Buy(#" + filter_name + DoubleToString(MagicNumber) + ")", MagicNumber, 0, DodgerBlue);
   if(ticket1 > 0) {
      if (OrderSelect(ticket1, SELECT_BY_TICKET, MODE_TRADES)) {
         Print("New Buy order opened at : ", DoubleToString(OrderOpenPrice())+ ", Total Orders: " + DoubleToString(OrdersTotal()));
      } else {
         Print("Error opening BUY order : ", GetLastError());
      }
   }
}

void SendSellOrder(string filter_name) {
   //Check free margin   
   if(AccountFreeMarginCheck(Symbol(),OP_BUY,Lots)<=0 || GetLastError()==134) {   
      Print("We have no money to buy. Free Margin = ", AccountFreeMargin() );   
      return;   
   }
   
   current_bid_price = NormalizeDouble(Bid, Digits);
   //StopLossLevel = NormalizeDouble(current_bid_price - Point * 100, Digits);
   //StopLossLevel = Ask + StopLoss * Point * P;
   StopLossLevel = Bid + StopLoss * Point * P;
   TakeProfitLevel = 0;
   
   ticket1 = OrderSend(Symbol(), OP_SELL, Lots, Ask, Slippage, StopLossLevel, TakeProfitLevel, "Sell(#" + filter_name + DoubleToString(MagicNumber) + ")", MagicNumber, 0, DodgerBlue);
   if(ticket1 > 0) {
      if (OrderSelect(ticket1, SELECT_BY_TICKET, MODE_TRADES)) {
         Print("New Sell order opened at : ", DoubleToString(OrderOpenPrice())+ ", Total Orders: " + DoubleToString(OrdersTotal()));
      } else {
         Print("Error opening BUY order : ", GetLastError());
      }
   }
}

bool NewBar() {   
   if (Time[0] == lasttime ) {
      return false;
   }
   
   Print("New Bar is generated at : "+ TimeCurrent());
   
   sma_volume = NormalizeDouble(iCustom(NULL, 0, "project\\volumeMA", MA_Period, 0, 1), Digits);
   sma_200 = NormalizeDouble(iMA(NULL,0,200,0,MODE_EMA,PRICE_CLOSE,1), Digits);
   rsi_current = iRSI(Symbol(),0,2,PRICE_CLOSE,0);
   rsi_previous = iRSI(Symbol(),0,2,PRICE_CLOSE,1);
   previous_close = NormalizeDouble(iClose(NULL,0,1), Digits);
   sma_5_low = NormalizeDouble(iMA(NULL,0,5,0,MODE_EMA,PRICE_LOW,1), Digits);
   sma_5_high    = NormalizeDouble(iMA(NULL,0,5,0,MODE_EMA,PRICE_HIGH,1), Digits);
   //New bar is created, and setting/re-setting the supporting points, eis variables
 
   eis_up = iCustom(NULL, 0, "Elder_Impulse_System", ShowBars, 0, 1);
   eis_down = iCustom(NULL, 0, "Elder_Impulse_System", ShowBars, 2, 1);
   eis_neutral = iCustom(NULL, 0, "Elder_Impulse_System", ShowBars, 1, 1);
   ma_65 = iMA(NULL, 0, 65, 0, MODE_EMA, PRICE_CLOSE, 1);
   macd = iMACD(NULL,0,1,65,1,PRICE_CLOSE,MODE_MAIN,1);
  
   lasttime = Time[0];
   return(true);
}

/**
Buy Signal:
[type = stock]
and [today's sma(20,volume) > 40000]
and [today's sma(60,close) > 20]
and [today's close > today's sma(200,close)]
and [5 x today's rsi(2)]
**/