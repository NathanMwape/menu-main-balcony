//+------------------------------------------------------------------+
//| MicroImpulseGridEA_FINAL.mq5                                      |
//| Expert Advisor - Suivi Prix par Accélération des Ticks            |
//| Reverse Automatique + Trailing Stop + Boucle Infinie             |
//| Hedging Account - Strictement une seule position à la fois       |
//+------------------------------------------------------------------+

#property copyright "Grid Trading System"
#property version   "1.00"
#property strict
#property description "EA with tick acceleration detection and automatic reverse"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+

input double LotSize = 0.01;
input double TakeProfitPoints = 2000;
input double TrailingStopPoints = 90;
input ulong MagicNumber = 20260699;

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

CTrade trade;
CPositionInfo positionInfo;

// State machine
enum EA_STATE { 
    STATE_WAITING_SIGNAL,      // Waiting for first impulse
    STATE_POSITION_OPEN,       // Position is open
    STATE_DETECTING_CLOSURE    // Position just closed
};

EA_STATE currentState = STATE_WAITING_SIGNAL;

// Detection variables
double previousBid = 0;
double previousSpeed = 0;
datetime previousTickTime = 0;

double accelerationArray[50];  // Store last 50 acceleration values
int accelerationIndex = 0;
bool detectionActive = true;

// Position variables
bool isLong = false;
double lastTPPrice = 0;
double lastSLPrice = 0;
double lastHighPrice = 0;
double lastLowPrice = 0;
int cycleCounter = 0;
ulong lastClosedTicket = 0;

//+------------------------------------------------------------------+
//| INITIALIZATION                                                     |
//+------------------------------------------------------------------+

int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    
    previousBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    previousTickTime = TimeCurrent();
    
    Print("=== MICRO IMPULSE GRID EA - FINAL ===");
    Print("TP: ", TakeProfitPoints, " points | SL: ", TrailingStopPoints, " points");
    Print("Account Type: Hedging");
    Print("Waiting for initial impulse detection...");
    
    EventSetTimer(100);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DEINITIALIZATION                                                  |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("EA Stopped. Total cycles completed: ", cycleCounter);
}

//+------------------------------------------------------------------+
//| TICK FUNCTION - MAIN LOGIC                                       |
//+------------------------------------------------------------------+

void OnTick()
{
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    datetime currentTime = TimeCurrent();
    
    switch(currentState)
    {
        case STATE_WAITING_SIGNAL:
            DetectInitialImpulse(currentBid, currentAsk, currentTime);
            break;
            
        case STATE_POSITION_OPEN:
            if(!HasPosition())
            {
                currentState = STATE_DETECTING_CLOSURE;
            }
            break;
            
        case STATE_DETECTING_CLOSURE:
            HandlePositionClosure(currentBid, currentAsk);
            currentState = STATE_WAITING_SIGNAL;
            break;
    }
    
    previousBid = currentBid;
}

//+------------------------------------------------------------------+
//| DETECT INITIAL IMPULSE BASED ON TICK ACCELERATION                |
//+------------------------------------------------------------------+

void DetectInitialImpulse(double currentBid, double currentAsk, datetime currentTime)
{
    if(!detectionActive)
        return;
        
    if(HasPosition())
    {
        detectionActive = false;
        currentState = STATE_POSITION_OPEN;
        return;
    }
    
    // Calculate elapsed time
    double elapsedSeconds = (double)(currentTime - previousTickTime);
    if(elapsedSeconds <= 0)
        elapsedSeconds = 0.001;
    
    // Calculate current speed
    double priceDifference = MathAbs(currentBid - previousBid);
    double currentSpeed = priceDifference / elapsedSeconds;
    
    // Calculate acceleration
    double acceleration = currentSpeed - previousSpeed;
    
    // Calculate direction
    double direction = currentBid - previousBid;
    
    // Store acceleration value
    accelerationArray[accelerationIndex] = MathAbs(acceleration);
    accelerationIndex++;
    if(accelerationIndex >= 50)
        accelerationIndex = 0;
    
    // Calculate average acceleration
    double averageAcceleration = CalculateAverageAcceleration();
    
    // Check for BUY signal
    if(direction > 0 && acceleration > (averageAcceleration * 2) && averageAcceleration > 0)
    {
        if(!HasPosition())
        {
            isLong = true;
            if(OpenPosition(currentBid, currentAsk))
            {
                detectionActive = false;
                currentState = STATE_POSITION_OPEN;
            }
        }
    }
    // Check for SELL signal
    else if(direction < 0 && MathAbs(acceleration) > (averageAcceleration * 2) && averageAcceleration > 0)
    {
        if(!HasPosition())
        {
            isLong = false;
            if(OpenPosition(currentBid, currentAsk))
            {
                detectionActive = false;
                currentState = STATE_POSITION_OPEN;
            }
        }
    }
    
    previousSpeed = currentSpeed;
    previousTickTime = currentTime;
}

//+------------------------------------------------------------------+
//| CALCULATE AVERAGE ACCELERATION                                    |
//+------------------------------------------------------------------+

double CalculateAverageAcceleration()
{
    double sum = 0;
    int count = 0;
    
    for(int i = 0; i < 50; i++)
    {
        if(accelerationArray[i] > 0 || i < accelerationIndex)
        {
            sum += accelerationArray[i];
            count++;
        }
    }
    
    if(count > 0)
        return sum / count;
    return 0;
}

//+------------------------------------------------------------------+
//| OPEN NEW POSITION                                                 |
//+------------------------------------------------------------------+

bool OpenPosition(double currentBid, double currentAsk)
{
    // Triple verification - no position should exist
    if(HasPosition())
    {
        Print("SECURITY: Position already exists!");
        return false;
    }
    
    double price, sl, tp;
    
    if(isLong)
    {
        price = currentAsk;
        sl = currentAsk - TrailingStopPoints * Point();
        tp = currentAsk + TakeProfitPoints * Point();
        
        if(!trade.Buy(LotSize, _Symbol, price, sl, tp))
        {
            Print("BUY order failed. Error: ", GetLastError());
            return false;
        }
        
        lastHighPrice = currentAsk;
        lastLowPrice = currentAsk;
        lastTPPrice = tp;
        lastSLPrice = sl;
        cycleCounter++;
        
        Print("");
        Print("✅ BUY OPENED - CYCLE ", cycleCounter);
        Print("   Entry: ", DoubleToString(price, _Digits));
        Print("   TP: ", DoubleToString(tp, _Digits), " (Distance: ", DoubleToString(tp - price, _Digits), ")");
        Print("   SL: ", DoubleToString(sl, _Digits));
        Print("");
    }
    else
    {
        price = currentBid;
        sl = currentBid + TrailingStopPoints * Point();
        tp = currentBid - TakeProfitPoints * Point();
        
        if(!trade.Sell(LotSize, _Symbol, price, sl, tp))
        {
            Print("SELL order failed. Error: ", GetLastError());
            return false;
        }
        
        lastHighPrice = currentBid;
        lastLowPrice = currentBid;
        lastTPPrice = tp;
        lastSLPrice = sl;
        cycleCounter++;
        
        Print("");
        Print("✅ SELL OPENED - CYCLE ", cycleCounter);
        Print("   Entry: ", DoubleToString(price, _Digits));
        Print("   TP: ", DoubleToString(tp, _Digits), " (Distance: ", DoubleToString(price - tp, _Digits), ")");
        Print("   SL: ", DoubleToString(sl, _Digits));
        Print("");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| HANDLE POSITION CLOSURE AND REOPEN                               |
//+------------------------------------------------------------------+

void HandlePositionClosure(double currentBid, double currentAsk)
{
    Sleep(300);
    
    // Determine if closed by TP or SL
    bool wasTpHit = false;
    
    if(HistorySelect(TimeCurrent() - 3600, TimeCurrent()))
    {
        for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
        {
            ulong dealTicket = HistoryDealGetTicket(i);
            
            if(dealTicket > 0 && dealTicket != lastClosedTicket)
            {
                if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == MagicNumber &&
                   HistoryDealGetString(dealTicket, DEAL_SYMBOL) == _Symbol)
                {
                    double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                    
                    // Check if closed by TP
                    if(MathAbs(dealPrice - lastTPPrice) < 5 * Point())
                    {
                        wasTpHit = true;
                        Print("💰 TAKE PROFIT HIT - Same direction");
                    }
                    else
                    {
                        wasTpHit = false;
                        isLong = !isLong;
                        Print("🛑 TRAILING STOP HIT - Reverse direction");
                    }
                    
                    lastClosedTicket = dealTicket;
                    break;
                }
            }
        }
    }
    
    Sleep(500);
    
    // Reopen position
    if(!HasPosition())
    {
        OpenPosition(currentBid, currentAsk);
    }
}

//+------------------------------------------------------------------+
//| VERIFY IF POSITION EXISTS                                         |
//+------------------------------------------------------------------+

bool HasPosition()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == _Symbol)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| TIMER - UPDATE TRAILING STOP                                     |
//+------------------------------------------------------------------+

void OnTimer()
{
    if(currentState != STATE_POSITION_OPEN)
        return;
    
    double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == _Symbol)
            {
                double currentSL = positionInfo.StopLoss();
                double newSL = 0;
                
                if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                {
                    // BUY: Trailing SL moves up, never down
                    lastHighPrice = MathMax(lastHighPrice, currentBid);
                    newSL = lastHighPrice - TrailingStopPoints * Point();
                    
                    if(newSL > currentSL + Point())
                    {
                        if(!trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit()))
                        {
                            Print("BUY Modify SL failed. Error: ", GetLastError());
                        }
                    }
                }
                else if(positionInfo.PositionType() == POSITION_TYPE_SELL)
                {
                    // SELL: Trailing SL moves down, never up
                    lastLowPrice = MathMin(lastLowPrice, currentAsk);
                    newSL = lastLowPrice + TrailingStopPoints * Point();
                    
                    if(newSL < currentSL - Point())
                    {
                        if(!trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit()))
                        {
                            Print("SELL Modify SL failed. Error: ", GetLastError());
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
