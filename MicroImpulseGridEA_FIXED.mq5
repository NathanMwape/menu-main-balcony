//+------------------------------------------------------------------+
//| MicroImpulseGridEA.mq5                                           |
//| Expert Advisor with Micro Impulse Trading & Infinite Grid Loop   |
//| Trading on M1 with Trailing Stop and Pending Opposite Orders    |
//+------------------------------------------------------------------+

#property copyright "Grid Trading System"
#property link      "https://example.com"
#property version   "2.00"
#property strict
#property description "Micro Impulse Grid EA - ONE position + ONE pending order ONLY"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input parameters
input double LotSize = 0.01;                    // Position size
input double TrailingStopPoints = 50;           // Trailing stop in points
input double PendingOrderDistance = 30;         // Distance for pending order from entry
input int MicroImpulseThreshold = 5;            // Sensitivity for micro impulse detection
input ulong MagicNumber = 20260531;             // Magic number for identification
input int MaxSpread = 20;                       // Max spread in points

//--- Global variables
CTrade trade;
CPositionInfo positionInfo;
COrderInfo orderInfo;

//--- State machine enum
enum TRADING_STATE
{
    STATE_WAITING,              // Waiting for impulse
    STATE_POSITION_OPEN,        // Position open + pending order placed
    STATE_POSITION_CLOSED       // Position closed, waiting for next impulse
};

TRADING_STATE currentState = STATE_WAITING;
bool isLongPosition = false;                    // Direction of current position
datetime lastTradeTime = 0;
int lastImpulseBar = -1;

//--- Helper function for Ask price
double GetAsk()
{
    return SymbolInfoDouble(_Symbol, SYMBOL_ASK);
}

//--- Helper function for Bid price
double GetBid()
{
    return SymbolInfoDouble(_Symbol, SYMBOL_BID);
}

//--- Count positions for this EA
int CountPositions()
{
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == _Symbol)
            {
                count++;
            }
        }
    }
    return count;
}

//--- Count pending orders for this EA
int CountPendingOrders()
{
    int count = 0;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(orderInfo.SelectByIndex(i))
        {
            if(orderInfo.Magic() == MagicNumber && orderInfo.Symbol() == _Symbol)
            {
                if(orderInfo.OrderType() == ORDER_TYPE_BUY_LIMIT || 
                   orderInfo.OrderType() == ORDER_TYPE_SELL_LIMIT)
                {
                    count++;
                }
            }
        }
    }
    return count;
}

//--- Delete all pending orders
void DeleteAllPendingOrders()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(orderInfo.SelectByIndex(i))
        {
            if(orderInfo.Magic() == MagicNumber && orderInfo.Symbol() == _Symbol)
            {
                if(orderInfo.OrderType() == ORDER_TYPE_BUY_LIMIT || 
                   orderInfo.OrderType() == ORDER_TYPE_SELL_LIMIT)
                {
                    trade.OrderDelete(orderInfo.Ticket());
                    Print("Deleted pending order: ", orderInfo.Ticket());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    
    double ask = GetAsk();
    double bid = GetBid();
    
    if(ask == 0 || bid == 0)
    {
        Print("Error: Unable to initialize symbol data");
        return INIT_FAILED;
    }
    
    Print("=== Micro Impulse Grid EA v2 Initialized ===");
    Print("Symbol: ", _Symbol);
    Print("Lot Size: ", LotSize);
    Print("Trailing Stop: ", TrailingStopPoints, " points");
    Print("Initial State: WAITING");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Expert Advisor stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    double ask = GetAsk();
    double bid = GetBid();
    
    // Check spread
    if((ask - bid) > MaxSpread * Point())
    {
        return;
    }
    
    // Verify position count
    int posCount = CountPositions();
    int ordCount = CountPendingOrders();
    
    switch(currentState)
    {
        case STATE_WAITING:
        {
            // Must have NO positions and NO pending orders
            if(posCount > 0 || ordCount > 0)
            {
                Print("ERROR: State is WAITING but positions=", posCount, " orders=", ordCount);
                if(posCount > 0)
                    break; // Let existing position close
                if(ordCount > 0)
                    DeleteAllPendingOrders(); // Clean up
            }
            
            // Look for impulse
            if(DetectMicroImpulse())
            {
                OpenInitialPosition();
                currentState = STATE_POSITION_OPEN;
            }
            break;
        }
        
        case STATE_POSITION_OPEN:
        {
            // Must have EXACTLY 1 position and 1 pending order
            if(posCount != 1)
            {
                Print("ERROR: State is POSITION_OPEN but position count=", posCount);
                if(posCount == 0)
                {
                    currentState = STATE_POSITION_CLOSED;
                    DeleteAllPendingOrders();
                }
                else if(posCount > 1)
                {
                    Print("CRITICAL: Multiple positions detected!");
                    DeleteAllPendingOrders();
                }
                break;
            }
            
            if(ordCount != 1)
            {
                Print("WARNING: Expected 1 pending order, found ", ordCount);
                if(ordCount == 0)
                {
                    PlacePendingOppositeOrder(!isLongPosition);
                }
                else if(ordCount > 1)
                {
                    DeleteAllPendingOrders();
                    Sleep(100);
                    PlacePendingOppositeOrder(!isLongPosition);
                }
                break;
            }
            
            // Update trailing stop
            UpdateTrailingStop();
            break;
        }
        
        case STATE_POSITION_CLOSED:
        {
            // Position should be closed, clean up pending orders
            if(posCount > 0)
            {
                Print("ERROR: Position should be closed!");
                break; // Wait for position to close
            }
            
            if(ordCount > 0)
            {
                Print("Cleaning up pending orders after position close");
                DeleteAllPendingOrders();
            }
            
            // Ready to accept new impulse
            currentState = STATE_WAITING;
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Detect micro impulse signal on M1                               |
//+------------------------------------------------------------------+
bool DetectMicroImpulse()
{
    static int lastBar = -1;
    int currentBar = Bars(_Symbol, PERIOD_M1);
    
    if(currentBar <= lastBar)
        return false;
    
    lastBar = currentBar;
    
    // Get recent candles (last 3 candles)
    double close1 = iClose(_Symbol, PERIOD_M1, 1);
    double close2 = iClose(_Symbol, PERIOD_M1, 2);
    double close3 = iClose(_Symbol, PERIOD_M1, 3);
    double open1 = iOpen(_Symbol, PERIOD_M1, 1);
    
    // Micro impulse detection: Strong upward move
    if(close1 > open1 && (close1 - open1) > MicroImpulseThreshold * Point() &&
       close1 > close2 && close2 > close3)
    {
        Print(">>> Micro Impulse Detected: UP");
        return true;
    }
    
    // Micro impulse detection: Strong downward move
    if(close1 < open1 && (open1 - close1) > MicroImpulseThreshold * Point() &&
       close1 < close2 && close2 < close3)
    {
        Print(">>> Micro Impulse Detected: DOWN");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Open initial position based on impulse direction               |
//+------------------------------------------------------------------+
void OpenInitialPosition()
{
    // Final safety check
    if(CountPositions() > 0 || CountPendingOrders() > 0)
    {
        Print("SAFETY BLOCK: Cannot open position, existing positions/orders detected");
        return;
    }
    
    double close1 = iClose(_Symbol, PERIOD_M1, 1);
    double open1 = iOpen(_Symbol, PERIOD_M1, 1);
    double ask = GetAsk();
    double bid = GetBid();
    
    isLongPosition = (close1 > open1); // UP = Long, DOWN = Short
    
    if(isLongPosition)
    {
        // Open BUY position
        if(trade.Buy(LotSize, _Symbol, ask, ask - TrailingStopPoints * Point(), 0, "GRID-LONG"))
        {
            Print("✓ LONG position OPENED at ", ask, " SL=", ask - TrailingStopPoints * Point());
            Sleep(200);
            PlacePendingOppositeOrder(false);
        }
        else
        {
            Print("FAILED to open LONG position. Error: ", GetLastError());
        }
    }
    else
    {
        // Open SELL position
        if(trade.Sell(LotSize, _Symbol, bid, bid + TrailingStopPoints * Point(), 0, "GRID-SHORT"))
        {
            Print("✓ SHORT position OPENED at ", bid, " SL=", bid + TrailingStopPoints * Point());
            Sleep(200);
            PlacePendingOppositeOrder(true);
        }
        else
        {
            Print("FAILED to open SHORT position. Error: ", GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| Place pending opposite order at distance                        |
//+------------------------------------------------------------------+
void PlacePendingOppositeOrder(bool isBuy)
{
    // Safety check
    if(CountPendingOrders() > 0)
    {
        Print("Pending order already exists, not creating duplicate");
        return;
    }
    
    double ask = GetAsk();
    double bid = GetBid();
    
    if(isBuy)
    {
        double limitPrice = ask + PendingOrderDistance * Point();
        double stopLoss = limitPrice - TrailingStopPoints * Point();
        
        if(trade.BuyLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "GRID-PENDING-BUY"))
        {
            Print("✓ Pending BUY placed at ", limitPrice, " SL=", stopLoss);
        }
    }
    else
    {
        double limitPrice = bid - PendingOrderDistance * Point();
        double stopLoss = limitPrice + TrailingStopPoints * Point();
        
        if(trade.SellLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "GRID-PENDING-SELL"))
        {
            Print("✓ Pending SELL placed at ", limitPrice, " SL=", stopLoss);
        }
    }
}

//+------------------------------------------------------------------+
//| Update trailing stop for open position                          |
//+------------------------------------------------------------------+
void UpdateTrailingStop()
{
    double ask = GetAsk();
    double bid = GetBid();
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == _Symbol)
            {
                if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                {
                    // For BUY: move SL up if price moves up
                    double newSL = bid - TrailingStopPoints * Point();
                    
                    if(newSL > positionInfo.StopLoss() && newSL > 0)
                    {
                        if(trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit()))
                        {
                            Print("✓ BUY SL updated to ", newSL);
                        }
                    }
                }
                else if(positionInfo.PositionType() == POSITION_TYPE_SELL)
                {
                    // For SELL: move SL down if price moves down
                    double newSL = ask + TrailingStopPoints * Point();
                    
                    if(newSL < positionInfo.StopLoss() && newSL > 0)
                    {
                        if(trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit()))
                        {
                            Print("✓ SELL SL updated to ", newSL);
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| OnTimer for periodic state checks                               |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Periodic validation
    int posCount = CountPositions();
    int ordCount = CountPendingOrders();
    
    // Log current state
    if(posCount != 0 || ordCount != 0)
    {
        Print("[STATE:", currentState, "] Positions:", posCount, " Orders:", ordCount);
    }
}

//+------------------------------------------------------------------+
//| End of Expert Advisor                                           |
//+------------------------------------------------------------------+
