//+------------------------------------------------------------------+
//| MicroImpulseGridEA.mq5                                           |
//| Expert Advisor with Micro Impulse Trading & Infinite Grid Loop   |
//| Trading on M1 with Trailing Stop and Pending Opposite Orders    |
//+------------------------------------------------------------------+

#property copyright "Grid Trading System"
#property link      "https://example.com"
#property version   "1.00"
#property strict
#property description "Micro Impulse Grid EA - Infinite Loop Trading"

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

bool isLocked = false;                          // Lock to prevent multiple initial positions
bool isGridActive = false;                      // Grid loop is active
ulong currentPositionTicket = 0;                // Current position ticket
double currentPositionPrice = 0;                // Entry price of current position
double currentTrailingStop = 0;                 // Current trailing stop level
bool isLongPosition = false;                    // Direction flag
datetime lastTradeTime = 0;
datetime lastPositionOpenTime = 0;              // Time of last position opened
int lastDetectionBar = -1;                      // Last bar where impulse was detected
bool pendingOrderExists = false;                // Flag for pending order existence
int cooldownBars = 3;                           // Minimum bars between trades

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
    
    Print("=== Micro Impulse Grid EA Initialized ===");
    Print("Symbol: ", _Symbol);
    Print("Lot Size: ", LotSize);
    Print("Trailing Stop: ", TrailingStopPoints, " points");
    
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
        return; // High spread, skip this tick
    }
    
    // Try to open initial position if not locked
    if(!isLocked)
    {
        if(DetectMicroImpulse())
        {
            OpenInitialPosition();
        }
    }
    else
    {
        // Grid is active - manage trailing stops and open opposite pending order
        if(isGridActive)
        {
            ManageGridLoop();
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
        Print("Micro Impulse Detected: UP");
        return true;
    }
    
    // Micro impulse detection: Strong downward move
    if(close1 < open1 && (open1 - close1) > MicroImpulseThreshold * Point() &&
       close1 < close2 && close2 < close3)
    {
        Print("Micro Impulse Detected: DOWN");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Open initial position based on impulse direction               |
//+------------------------------------------------------------------+
void OpenInitialPosition()
{
    // Strict verification: no position should exist
    if(PositionsTotal() > 0)
    {
        Print("ERROR: Position already exists, cannot open another");
        return;
    }
    
    if(OrdersTotal() > 0)
    {
        Print("ERROR: Pending orders exist, cannot open new position");
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
        if(trade.Buy(LotSize, _Symbol, ask, ask - TrailingStopPoints * Point(), 0, "Grid EA - Initial Long"))
        {
            currentPositionTicket = trade.ResultOrder();
            currentPositionPrice = ask;
            currentTrailingStop = ask - TrailingStopPoints * Point();
            isLocked = true;
            isGridActive = true;
            lastTradeTime = TimeCurrent();
            lastPositionOpenTime = TimeCurrent();
            pendingOrderExists = false;
            
            Print("✓ Initial LONG position opened at ", ask);
            Print("  SL: ", currentTrailingStop);
            Print("  Magic: ", MagicNumber);
            
            Sleep(200);
            
            // Place pending SELL order
            PlacePendingOppositeOrder(false);
        }
    }
    else
    {
        // Open SELL position
        if(trade.Sell(LotSize, _Symbol, bid, bid + TrailingStopPoints * Point(), 0, "Grid EA - Initial Short"))
        {
            currentPositionTicket = trade.ResultOrder();
            currentPositionPrice = bid;
            currentTrailingStop = bid + TrailingStopPoints * Point();
            isLocked = true;
            isGridActive = true;
            lastTradeTime = TimeCurrent();
            lastPositionOpenTime = TimeCurrent();
            pendingOrderExists = false;
            
            Print("✓ Initial SHORT position opened at ", bid);
            Print("  SL: ", currentTrailingStop);
            Print("  Magic: ", MagicNumber);
            
            Sleep(200);
            
            // Place pending BUY order
            PlacePendingOppositeOrder(true);
        }
    }
}

//+------------------------------------------------------------------+
//| Place pending opposite order at distance                        |
//+------------------------------------------------------------------+
void PlacePendingOppositeOrder(bool isBuy)
{
    // Check if pending order already exists
    if(OrdersTotal() > 0)
    {
        Print("Pending order already exists, not creating duplicate");
        pendingOrderExists = true;
        return;
    }
    
    double ask = GetAsk();
    double bid = GetBid();
    
    if(isBuy)
    {
        double limitPrice = ask + PendingOrderDistance * Point();
        double stopLoss = limitPrice - TrailingStopPoints * Point();
        
        if(trade.BuyLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "Grid EA - Pending Buy"))
        {
            Print("✓ Pending BUY order placed at ", limitPrice, " with SL: ", stopLoss);
            pendingOrderExists = true;
        }
    }
    else
    {
        double limitPrice = bid - PendingOrderDistance * Point();
        double stopLoss = limitPrice + TrailingStopPoints * Point();
        
        if(trade.SellLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "Grid EA - Pending Sell"))
        {
            Print("✓ Pending SELL order placed at ", limitPrice, " with SL: ", stopLoss);
            pendingOrderExists = true;
        }
    }
}

//+------------------------------------------------------------------+
//| Manage grid loop: trailing stop and position replacement        |
//+------------------------------------------------------------------+
void ManageGridLoop()
{
    double ask = GetAsk();
    double bid = GetBid();
    
    // Update trailing stop for current position
    UpdateTrailingStop();
    
    // Check if position was closed (by SL hit)
    bool positionStillOpen = false;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && 
               positionInfo.Symbol() == _Symbol &&
               StringFind(positionInfo.Comment(), "Initial") != -1)
            {
                positionStillOpen = true;
                break;
            }
        }
    }
    
    // If position is closed, open inverse position
    if(!positionStillOpen && isGridActive)
    {
        Print("→ Position closed, opening inverse...");
        Sleep(500); // Small delay to avoid rapid reconnects
        
        // Invert direction
        isLongPosition = !isLongPosition;
        
        if(isLongPosition)
        {
            // Open new BUY after previous SELL was closed
            if(trade.Buy(LotSize, _Symbol, ask, ask - TrailingStopPoints * Point(), 0, "Grid EA - Loop Buy"))
            {
                currentPositionTicket = trade.ResultOrder();
                currentPositionPrice = ask;
                currentTrailingStop = ask - TrailingStopPoints * Point();
                lastTradeTime = TimeCurrent();
                
                Print("✓ NEW LONG position opened at ", ask);
                Print("  SL: ", currentTrailingStop);
                
                // Place pending SELL order for the next cycle
                PlacePendingOppositeOrder(false);
            }
        }
        else
        {
            // Open new SELL after previous BUY was closed
            if(trade.Sell(LotSize, _Symbol, bid, bid + TrailingStopPoints * Point(), 0, "Grid EA - Loop Sell"))
            {
                currentPositionTicket = trade.ResultOrder();
                currentPositionPrice = bid;
                currentTrailingStop = bid + TrailingStopPoints * Point();
                lastTradeTime = TimeCurrent();
                
                Print("✓ NEW SHORT position opened at ", bid);
                Print("  SL: ", currentTrailingStop);
                
                // Place pending BUY order for the next cycle
                PlacePendingOppositeOrder(true);
            }
        }
    }
    
    // Cancel old pending orders and recreate them if needed
    CancelOldPendingOrders();
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
                    
                    if(newSL > positionInfo.StopLoss())
                    {
                        if(trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit()))
                        {
                            currentTrailingStop = newSL;
                        }
                    }
                }
                else if(positionInfo.PositionType() == POSITION_TYPE_SELL)
                {
                    // For SELL: move SL down if price moves down
                    double newSL = ask + TrailingStopPoints * Point();
                    
                    if(newSL < positionInfo.StopLoss())
                    {
                        if(trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit()))
                        {
                            currentTrailingStop = newSL;
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Cancel old pending orders and verify new ones exist             |
//+------------------------------------------------------------------+
void CancelOldPendingOrders()
{
    // Keep only the most recent pending order
    ulong newestOrder = 0;
    datetime newestTime = 0;
    
    for(int i = (int)OrdersTotal() - 1; i >= 0; i--)
    {
        if(orderInfo.SelectByIndex(i))
        {
            if(orderInfo.Magic() == MagicNumber && orderInfo.Symbol() == _Symbol)
            {
                if(orderInfo.OrderType() == ORDER_TYPE_BUY_LIMIT || 
                   orderInfo.OrderType() == ORDER_TYPE_SELL_LIMIT)
                {
                    if(orderInfo.TimeSetup() > newestTime)
                    {
                        // Cancel old order
                        if(newestOrder != 0)
                        {
                            trade.OrderDelete(newestOrder);
                        }
                        
                        newestOrder = orderInfo.Ticket();
                        newestTime = orderInfo.TimeSetup();
                    }
                    else
                    {
                        trade.OrderDelete(orderInfo.Ticket());
                    }
                }
            }
        }
    }
    
    // If no pending order exists, create new one
    if(OrdersTotal() == 0 && isGridActive)
    {
        PlacePendingOppositeOrder(!isLongPosition);
    }
}

//+------------------------------------------------------------------+
//| OnTimer for periodic checks (every 100ms)                       |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Additional periodic management can be done here
    ManageGridLoop();
}

//+------------------------------------------------------------------+
//| End of Expert Advisor                                           |
//+------------------------------------------------------------------+
