#include <Trade\Trade.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>


input group "Risk Managment"
input int StopLoss = 0;
input int TakeProfit = 0;
input double percent_risk = 0.1;


input group "Time Control"
input ENUM_TIMEFRAMES Timeframe = 1;
input int StartHour = 1;
input int EndHour = 23;
input int StartMinute = 0;
input int EndMinute = 0;
input int NumTradeAllowed = 1;

input group "Trailing Stop"
input bool RunTrailing = true;
input double TrailingStart = 100;
input double TrailingStop = 50;

input group "SMA Control"
input int SMA_Period_short = 50;
input int SMA_Period_long = 200;
input double SMA_Buffer = 0.2;
input ENUM_TIMEFRAMES SMA_Timeframe = 1;


input group "Key Levels"
input double Key_Level_1 = 0.000;
input double Key_Level_2 = 0.200;
input double Key_Level_3 = 0.500;
input double Key_Level_4 = 0.800;
input double Price_Range = 0.00;

input group "ADX control"
input int adx_period = 9;
input int adx_middle_value = 25;
input ENUM_TIMEFRAMES ADX_Timeframe = 1;

int sma_short_handle = 0;
int sma_long_handle = 0;
int adx_handle = 0;

CTrade trade;
MqlDateTime currentTime;

int OnInit()
  {
   sma_short_handle = iMA(NULL, SMA_Timeframe, SMA_Period_short, 0, MODE_SMA, PRICE_CLOSE);
   sma_long_handle = iMA(NULL, SMA_Timeframe, SMA_Period_long, 0, MODE_SMA, PRICE_CLOSE);
   adx_handle = iADX(NULL, ADX_Timeframe, adx_period);
   
   
   return(INIT_SUCCEEDED);
  }


void OnDeinit(const int reason)
  {

   
  }
  

int look_for_trade = 0;
int look_for_buy = 0;
int look_for_sell = 0;


void OnTick()
  {

   TimeToStruct(TimeCurrent(), currentTime);
   int currentHour = currentTime.hour;
   int currentMinute = currentTime.min;
   
   trailingstop();
   
   if (PositionsTotal() == 0) {
      if (look_for_sell == 1) {
         placesell();
      }
      if (look_for_buy == 1) {
         placebuy();
   }
      }
      
   DisplayKeyLevels();
   //pricepassinglevel = tradelevel())
   
   checkfortrade();

   placepos();
   
   if (EndHour == currentHour && EndMinute == currentMinute) {
      done_tag = 0;
      
      }
   /*if (pricepassinglevel) {
       placepos()
       }*/
      
   
   

   
  }
double accountbalance = 0;

/*double calclotsize(double rp, double Sl) {
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * rp / 100;
   double moneyLotStep = (Sl / ticksize) * tickvalue * lotstep;
   
   double lots = MathFloor(riskMoney / moneyLotStep) * lotstep;
   
   

    

    return lots;  // Normalize lot size to 2 decimal places
}*/



double previous_price_array[2] = {0, 0};

void placesell() {
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double point_value = SymbolInfoDouble(NULL, SYMBOL_POINT);
   double stopLossLevel = StopLoss * point_value;
   double takeProfitLevel = TakeProfit * point_value;
   
   //printf("Searching for sell");
   previous_price_array[1] = previous_price_array[0];
   previous_price_array[0] = currentAsk;
   
   
      if (previous_price_array[1] > 0) {
        for (int i = 0; i < ArraySize(adjustedKeyLevels); i++) {
            double level = adjustedKeyLevels[i];

            // Check if the price has moved from above a key level to below it.
            if (previous_price_array[1] >= level && previous_price_array[0] < level) {
                Print("SELL at: ", level);
                // Execute a sell trade.
                //double lotsize = calclotsize(percent_risk, StopLoss);
                
                trade.Sell(percent_risk, _Symbol, 0, currentAsk + stopLossLevel, currentAsk - takeProfitLevel, "Sell");
                look_for_sell = 0;
                // Assuming you want to break after finding the first matching level and executing a trade
                break;
            }
        }
    }
   


}

double last_buy_price = 0.00;
double last_sell_price = 0.00;

void trailingstop(){
   if (PositionsTotal() == 0 || !RunTrailing)  {
      return;
      }
      
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentStopLoss = PositionGetDouble(POSITION_SL);
   double currentPositionProfit = PositionGetDouble(POSITION_PROFIT);
   double distanceToCurrentPrice = 0.0;
   double newStopLoss = 0.0;
   long positiontype = PositionGetInteger(POSITION_TYPE);
   double entryprice = PositionGetDouble(POSITION_PRICE_OPEN);
   double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
   
   if(positiontype == POSITION_TYPE_BUY) {
      if ((bid - entryprice) > TrailingStart * point && last_buy_price < bid) {
         double newSL = bid - TrailingStop * point;
         double currentTP = PositionGetDouble(POSITION_TP);
         last_buy_price = bid;
         trade.PositionModify(_Symbol, newSL, currentTP);
         }
         }
   if(positiontype == POSITION_TYPE_SELL) {
      if ((entryprice - ask) > TrailingStart * point && last_sell_price > ask) {
         double newSL = ask + TrailingStop * point;
         double currentTP = PositionGetDouble(POSITION_TP);
         last_sell_price = ask;
         trade.PositionModify(_Symbol, newSL, currentTP);
            
        
    
    
   
   }
   
}
}


void placebuy() {
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double point_value = SymbolInfoDouble(NULL, SYMBOL_POINT);
   double stopLossLevel = StopLoss * point_value;
   double takeProfitLevel = TakeProfit * point_value;
   
   //printf("Searching for buy");
   previous_price_array[1] = previous_price_array[0];
   previous_price_array[0] = currentBid;
   
   
    // Ensure there's a previous price to compare against
    if (previous_price_array[1] > 0) {
        for (int i = 0; i < ArraySize(adjustedKeyLevels); i++) {
            double level = adjustedKeyLevels[i];

            // Check if the price has moved from below a key level to above it
            if (previous_price_array[1] < level && previous_price_array[0] >= level) {
                Print("BUY at: ", level);
                // Execute a buy trade
                //double lotsize = calclotsize(percent_risk, StopLoss);
                trade.Buy(percent_risk, _Symbol, 0, currentBid - stopLossLevel, currentBid + takeProfitLevel, "BUY");
                look_for_buy = 0;
                // Assuming you want to break after finding the first matching level and executing a trade
                break;
            }
        }
    }
   }

int done_tag = 0;
int sma_direction = 0;
int adx_direction = 0;

void checkfortrade(){
   TimeToStruct(TimeCurrent(), currentTime);
   int currentHour = currentTime.hour;
   int currentMinute = currentTime.min;
   
   if (StartHour == currentHour && StartMinute == currentMinute && done_tag == 0) {
      sma_direction = getmadirection();
      adx_direction = getadxdirection();
      printf("sma and adx are now updated");
      look_for_trade = 1;
         
         
      done_tag = 1;
      
   }
         }
      

void placepos() {
   
   if (PositionsTotal() > 0 || look_for_trade == 0){
      return;
      }
   
   if (adx_direction == 1) {
      if (sma_direction == 2) {
         printf("looking for buy...");
         look_for_trade = 0;
         look_for_buy = 1;
         }
      else if (sma_direction == 1) {
         printf("looking for sell...");
         look_for_trade = 0;
         look_for_sell = 1;
         }
         
      else {
         return;
         }
         }
   }


   
   
double adjustedKeyLevels[4];
void DisplayKeyLevels() {
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double currentPrice = (currentAsk + currentBid) / 2;

    int intPartOfCurrentPrice = (int)currentPrice;

    
    adjustedKeyLevels[0] = intPartOfCurrentPrice + Key_Level_1; 
    adjustedKeyLevels[1] = intPartOfCurrentPrice + Key_Level_2;
    adjustedKeyLevels[2] = intPartOfCurrentPrice + Key_Level_3;
    adjustedKeyLevels[3] = intPartOfCurrentPrice + Key_Level_4;

    
    // Delete previous lines to avoid clutter
    for(int i = ObjectsTotal(0, -1, OBJ_HLINE) - 1; i >= 0; i--) {
        string name = ObjectName(0, i, OBJ_HLINE);
        if(StringFind(name, "KeyLevel_") != -1) {
            ObjectDelete(0, name);
        }
    }
    
    // Create lines for adjusted key levels
    for(int i = 0; i < ArraySize(adjustedKeyLevels); i++) {
        double keyLevel = adjustedKeyLevels[i];
        // Check if the key level is within the direct range of the current price
        if(MathAbs(currentPrice - keyLevel) <= Price_Range) {
            string lineName = "KeyLevel_" + IntegerToString(i);
            if(!ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, keyLevel)) {
                Print("Failed to create horizontal line for key level: ", keyLevel);
            } else {
                ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrLightBlue); // Set line color
                ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_SOLID); // Set line style
                ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2); // Set line width
            }
        }
    }
}

double  last_shortMA_price = 0;
double last_longMA_price = 0;
   
   
int getmadirection() {
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   
    double emashort[2];
    double emalong[2];
    
    CopyBuffer(sma_short_handle, 0, 0, 2, emashort);
    last_shortMA_price = emashort[1];
    
    CopyBuffer(sma_long_handle, 0, 0, 2, emalong);
    last_longMA_price = emalong[1];
    
    if (currentBid < last_shortMA_price && currentBid < last_longMA_price) {
         printf("bearish ma");
         return 1;
         }
    else if (currentBid > last_shortMA_price && currentBid > last_longMA_price) {
         printf("bullish ma");
         return 2;
         }
    else {
      return 3;
      }
   
    }
    
double lastadxvalue= 0;

int getadxdirection() {
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   
    double adxvalue[2];
    
    CopyBuffer(adx_handle, 0, 0, 2, adxvalue);
    lastadxvalue = adxvalue[1];
    
    if (lastadxvalue > adx_middle_value) {
         printf("ADX good");
         return 1;
         
         }
    else {
         return 2;
         }
     
    
   }

