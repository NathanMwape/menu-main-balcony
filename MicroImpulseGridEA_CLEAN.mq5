//+------------------------------------------------------------------+
//| MicroImpulseGridEA_CLEAN.mq5                                      |
//| Logique CORRECTE: 1 position SEULE + Trailing SL + Reverse OK    |
//+------------------------------------------------------------------+

#property copyright "Grid Trading System"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;
CPositionInfo positionInfo;

//--- Inputs
input double LotSize = 0.01;
input double TrailingStopPoints = 50;
input double TakeProfitPoints = 1500;
input int MicroImpulseThreshold = 5;
input ulong MagicNumber = 20260601;
input int MaxSpread = 20;

//--- Global State
bool initialLocked = false;          // Première position ouverte + verrouillage
bool isLong = false;                 // Direction actuelle
double lastHighPrice = 0;            // Plus haut (LONG)
double lastLowPrice = 0;             // Plus bas (SHORT)
int tradeCounter = 0;
bool waitingToReopen = false;        // En attente avant réouverture
datetime positionClosedTime = 0;     // Heure de fermeture

//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    EventSetTimer(100);
    Print("✅ EA INITIALISÉ - En attente de micro impulsion...");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("EA arrêté. Total cycles: ", tradeCounter);
}

//+------------------------------------------------------------------+
void OnTick()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if((ask - bid) / Point() > MaxSpread) return;
    
    // PHASE 1: En attente de micro impulsion INITIALE
    if(!initialLocked && !waitingToReopen)
    {
        if(DetectMicroImpulse())
        {
            OpenPosition();
            initialLocked = true;
            waitingToReopen = false;
        }
    }
    
    // PHASE 2: Position ouverte - vérifier si fermée (SL ou TP)
    if(initialLocked && !waitingToReopen)
    {
        if(!PositionExists())
        {
            Print("💥 POSITION FERMÉE");
            waitingToReopen = true;
            positionClosedTime = TimeCurrent();
            // INVERSION: si c'était LONG, devenir SHORT et vice-versa
            isLong = !isLong;
        }
    }
    
    // PHASE 3: En attente avant réouverture (délai 2 secondes)
    if(waitingToReopen)
    {
        if(TimeCurrent() - positionClosedTime > 2)
        {
            OpenPosition();  // Ouvre la position INVERSÉE
            waitingToReopen = false;
        }
    }
}

//+------------------------------------------------------------------+
// DÉTECTE MICRO IMPULSION M1
//+------------------------------------------------------------------+
bool DetectMicroImpulse()
{
    static int lastBar = -1;
    int currentBar = Bars(_Symbol, PERIOD_M1);
    
    if(currentBar <= lastBar) return false;
    lastBar = currentBar;
    
    double close1 = iClose(_Symbol, PERIOD_M1, 1);
    double open1 = iOpen(_Symbol, PERIOD_M1, 1);
    double close2 = iClose(_Symbol, PERIOD_M1, 2);
    
    // Impulsion UP
    if(close1 > open1 && (close1 - open1) >= MicroImpulseThreshold * Point() && close1 > close2)
    {
        isLong = true;
        Print("📈 MICRO IMPULSION HAUSSIÈRE détectée");
        return true;
    }
    
    // Impulsion DOWN
    if(close1 < open1 && (open1 - close1) >= MicroImpulseThreshold * Point() && close1 < close2)
    {
        isLong = false;
        Print("📉 MICRO IMPULSION BAISSIÈRE détectée");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
// OUVRE UNE POSITION (UNE SEULE À LA FOIS)
//+------------------------------------------------------------------+
void OpenPosition()
{
    // Vérification: PAS de position ouverte
    if(PositionExists())
    {
        Print("⚠️  Une position existe déjà, abandon");
        return;
    }
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(isLong)
    {
        double sl = ask - TrailingStopPoints * Point();
        double tp = ask + TakeProfitPoints * Point();
        
        if(trade.Buy(LotSize, _Symbol, ask, sl, tp, "LONG"))
        {
            lastHighPrice = ask;
            lastLowPrice = ask;
            tradeCounter++;
            Print("");
            Print("✅ POSITION LONG OUVERTE (Cycle ", tradeCounter, ")");
            Print("   Prix: ", DoubleToString(ask, _Digits));
            Print("   SL: ", DoubleToString(sl, _Digits));
            Print("   TP: ", DoubleToString(tp, _Digits));
            Print("");
        }
    }
    else
    {
        double sl = bid + TrailingStopPoints * Point();
        double tp = bid - TakeProfitPoints * Point();
        
        if(trade.Sell(LotSize, _Symbol, bid, sl, tp, "SHORT"))
        {
            lastHighPrice = bid;
            lastLowPrice = bid;
            tradeCounter++;
            Print("");
            Print("✅ POSITION SHORT OUVERTE (Cycle ", tradeCounter, ")");
            Print("   Prix: ", DoubleToString(bid, _Digits));
            Print("   SL: ", DoubleToString(sl, _Digits));
            Print("   TP: ", DoubleToString(tp, _Digits));
            Print("");
        }
    }
}

//+------------------------------------------------------------------+
// VÉRIFIE SI POSITION EXISTE
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
// UPDATE TRAILING STOP (Timer)
//+------------------------------------------------------------------+
void OnTimer()
{
    if(!initialLocked || waitingToReopen) return;
    
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
                    // LONG: Trailing SL vers le HAUT
                    lastHighPrice = MathMax(lastHighPrice, bid);
                    double newSL = lastHighPrice - TrailingStopPoints * Point();
                    
                    if(newSL > positionInfo.StopLoss())
                    {
                        trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit());
                        Print("📊 Trailing SL LONG: ", DoubleToString(newSL, _Digits));
                    }
                }
                else
                {
                    // SHORT: Trailing SL vers le BAS
                    lastLowPrice = MathMin(lastLowPrice, ask);
                    double newSL = lastLowPrice + TrailingStopPoints * Point();
                    
                    if(newSL < positionInfo.StopLoss())
                    {
                        trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit());
                        Print("📊 Trailing SL SHORT: ", DoubleToString(newSL, _Digits));
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
