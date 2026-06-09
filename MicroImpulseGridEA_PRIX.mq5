//+------------------------------------------------------------------+
//| MicroImpulseGridEA_PRIX.mq5                                       |
//| Suivi de Prix par Accélération des Ticks + Reverse Automatique   |
//| TP 2000 points | Trailing Stop 150 points | UNE SEULE POSITION  |
//+------------------------------------------------------------------+

#property copyright "Grid Trading System"
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;
CPositionInfo positionInfo;

//--- Inputs
input double LotSize = 0.01;
input double TakeProfitPoints = 2000;
input double TrailingStopPoints = 150;
input int AccelerationThreshold = 3;
input ulong MagicNumber = 20260699;

//--- Global State
enum EA_STATE { WAITING_SIGNAL, POSITION_OPEN, CLOSING_POSITION };
EA_STATE eaState = WAITING_SIGNAL;

bool isLong = false;
double lastPrice = 0;
double lastHighPrice = 0;
double lastLowPrice = 0;
int tradeCounter = 0;
double lastTPPrice = 0;
double lastSLPrice = 0;
datetime lastTickTime = 0;

//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    
    Print("=== EA PRIX v3.00 - SUIVI STRICTEMENT UNE POSITION ===");
    Print("TP: ", TakeProfitPoints, " points | SL: ", TrailingStopPoints, " points");
    Print("Attente du premier signal...");
    
    lastPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    EventSetTimer(50);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("EA arrêté - Total cycles: ", tradeCounter);
}

//+------------------------------------------------------------------+
void OnTick()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // MACHINE À ÉTATS STRICTE
    switch(eaState)
    {
        case WAITING_SIGNAL:
        {
            // Vérifier qu'aucune position n'existe (sécurité)
            if(PositionExists())
            {
                eaState = POSITION_OPEN;
                break;
            }
            
            // Détection d'impulsion
            double acceleration = ask - lastPrice;
            lastPrice = ask;
            
            // BUY: accélération positive
            if(acceleration >= AccelerationThreshold * Point())
            {
                if(!PositionExists())
                {
                    isLong = true;
                    if(OpenNewPosition())
                    {
                        eaState = POSITION_OPEN;
                    }
                }
            }
            // SELL: accélération négative
            else if(acceleration <= -AccelerationThreshold * Point())
            {
                if(!PositionExists())
                {
                    isLong = false;
                    if(OpenNewPosition())
                    {
                        eaState = POSITION_OPEN;
                    }
                }
            }
            break;
        }
        
        case POSITION_OPEN:
        {
            // Si position fermée → déterminer cause et rouvrir
            if(!PositionExists())
            {
                eaState = CLOSING_POSITION;
            }
            break;
        }
        
        case CLOSING_POSITION:
        {
            HandleClosureAndReopen();
            eaState = WAITING_SIGNAL;
            break;
        }
    }
}

//+------------------------------------------------------------------+
bool OpenNewPosition()
{
    // TRIPLE VÉRIFICATION
    if(PositionExists())
    {
        Print("❌ SÉCURITÉ: Position existe déjà!");
        return false;
    }
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(isLong)
    {
        double sl = ask - TrailingStopPoints * Point();
        double tp = ask + TakeProfitPoints * Point();
        
        if(trade.Buy(LotSize, _Symbol, ask, sl, tp, "BUY"))
        {
            lastHighPrice = ask;
            lastLowPrice = ask;
            lastTPPrice = tp;
            lastSLPrice = sl;
            tradeCounter++;
            
            Print("");
            Print("✅ BUY CYCLE ", tradeCounter);
            Print("   Prix: ", DoubleToString(ask, _Digits));
            Print("   SL: ", DoubleToString(sl, _Digits));
            Print("   TP: ", DoubleToString(tp, _Digits), " (distance: ", DoubleToString(tp - ask, _Digits), ")");
            Print("");
            return true;
        }
    }
    else
    {
        double sl = bid + TrailingStopPoints * Point();
        double tp = bid - TakeProfitPoints * Point();
        
        if(trade.Sell(LotSize, _Symbol, bid, sl, tp, "SELL"))
        {
            lastHighPrice = bid;
            lastLowPrice = bid;
            lastTPPrice = tp;
            lastSLPrice = sl;
            tradeCounter++;
            
            Print("");
            Print("✅ SELL CYCLE ", tradeCounter);
            Print("   Prix: ", DoubleToString(bid, _Digits));
            Print("   SL: ", DoubleToString(sl, _Digits));
            Print("   TP: ", DoubleToString(tp, _Digits), " (distance: ", DoubleToString(bid - tp, _Digits), ")");
            Print("");
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
void HandleClosureAndReopen()
{
    Print("💥 POSITION FERMÉE - CYCLE ", tradeCounter);
    Sleep(300);
    
    // Analyser le prix de fermeture pour déterminer cause
    double closurePrice = 0;
    bool wasTpHit = false;
    
    if(HistorySelect(TimeCurrent() - 3600, TimeCurrent()))
    {
        for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
        {
            ulong deal_ticket = HistoryDealGetTicket(i);
            if(deal_ticket > 0)
            {
                if(HistoryDealGetInteger(deal_ticket, DEAL_MAGIC) == MagicNumber &&
                   HistoryDealGetString(deal_ticket, DEAL_SYMBOL) == _Symbol)
                {
                    closurePrice = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
                    
                    // Déterminer: TP ou SL?
                    if(MathAbs(closurePrice - lastTPPrice) < 5 * Point())
                    {
                        wasTpHit = true;
                        Print("   ➡️  TP ATTEINT → MÊME SENS");
                    }
                    else
                    {
                        wasTpHit = false;
                        isLong = !isLong;
                        Print("   ➡️  TRAILING STOP → INVERSE");
                    }
                    break;
                }
            }
        }
    }
    
    Sleep(500);
    
    // Réouvrir immédiatement
    if(!PositionExists())
    {
        OpenNewPosition();
    }
}

//+------------------------------------------------------------------+
bool PositionExists()
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
void OnTimer()
{
    if(eaState != POSITION_OPEN) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == _Symbol)
            {
                if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                {
                    lastHighPrice = MathMax(lastHighPrice, bid);
                    double newSL = lastHighPrice - TrailingStopPoints * Point();
                    
                    if(newSL > positionInfo.StopLoss() + 0.1 * Point())
                    {
                        trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit());
                    }
                }
                else
                {
                    lastLowPrice = MathMin(lastLowPrice, ask);
                    double newSL = lastLowPrice + TrailingStopPoints * Point();
                    
                    if(newSL < positionInfo.StopLoss() - 0.1 * Point())
                    {
                        trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+

