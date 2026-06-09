//+------------------------------------------------------------------+
//| MicroImpulseGridEA_FINAL.mq5                                     |
//| Micro Impulse Trading with Infinite Trailing Stop Loop           |
//| Single Initial Position + Trailing SL + Auto Reversal + TP 1500  |
//+------------------------------------------------------------------+

#property copyright "Grid Trading System"
#property link      "https://example.com"
#property version   "4.00"
#property strict
#property description "Micro Impulse Grid EA - TP 1500 points"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input parameters
input double LotSize = 0.01;                    // Taille de la position
input double TrailingStopPoints = 50;           // Trailling Stop en points
input double TakeProfitPoints = 1500;           // Take Profit en points
input double PendingOrderDistance = 30;         // Distance de l'ordre en attente
input int MicroImpulseThreshold = 5;            // Sensibilité de détection (points)
input ulong MagicNumber = 20260601;             // Numéro magique
input int MaxSpread = 20;                       // Spread max autorisé (points)
input bool EnablePendingOrders = true;          // Activer ordres en attente

//--- Global variables
CTrade trade;
CPositionInfo positionInfo;
COrderInfo orderInfo;

//--- Trading State
bool lockNewPositions = false;                  // Verrouillage
bool gridLoopActive = false;                    // Boucle de trading active
ulong activePositionTicket = 0;                 // Ticket de la position active
double lastHighPrice = 0;                       // Plus haut prix atteint
double lastLowPrice = 0;                        // Plus bas prix atteint
bool isLongPosition = false;                    // True = Long, False = Short
int tradeCounter = 0;                           // Compteur de trades
bool waitingForNewPosition = false;             // Flag: en attente d'ouverture inverse
datetime lastPositionClosedTime = 0;            // Heure de fermeture

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(ask <= 0 || bid <= 0)
    {
        Print("❌ ERREUR: Impossible de récupérer les prix");
        return INIT_FAILED;
    }
    
    EventSetTimer(100);
    
    Print("=== EA Micro Impulsion v4.00 - INITIALISÉ ===");
    Print("Symbole: ", _Symbol);
    Print("Lot: ", LotSize);
    Print("Trailing Stop: ", TrailingStopPoints, " points");
    Print("Take Profit: ", TakeProfitPoints, " points");
    Print("");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Désinitialisation                                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    Print("=== EA arrêté ===");
    Print("Total cycles effectués: ", tradeCounter);
}

//+------------------------------------------------------------------+
//| Tick function - Boucle principale                               |
//+------------------------------------------------------------------+
void OnTick()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spread = (ask - bid) / Point();
    
    if(spread > MaxSpread)
        return;
    
    // PHASE 1: Attendre la première micro impulsion
    if(!lockNewPositions)
    {
        if(DetectMicroImpulse())
        {
            OpenInitialPosition();
        }
    }
    // PHASE 2: Gérer la boucle infinie
    else if(gridLoopActive)
    {
        UpdateTrailingStop();
        ManagePositionClosure();
    }
}

//+------------------------------------------------------------------+
//| Détecte les micro impulsions sur M1                              |
//+------------------------------------------------------------------+
bool DetectMicroImpulse()
{
    static int lastBar = -1;
    int currentBar = Bars(_Symbol, PERIOD_M1);
    
    if(currentBar <= lastBar)
        return false;
    
    lastBar = currentBar;
    
    double close1 = iClose(_Symbol, PERIOD_M1, 1);
    double close2 = iClose(_Symbol, PERIOD_M1, 2);
    double open1 = iOpen(_Symbol, PERIOD_M1, 1);
    
    // Micro impulsion HAUSSIÈRE
    if(close1 > open1 && 
       (close1 - open1) >= MicroImpulseThreshold * Point() &&
       close1 > close2)
    {
        Print("📈 MICRO IMPULSION HAUSSIÈRE détectée");
        return true;
    }
    
    // Micro impulsion BAISSIÈRE
    if(close1 < open1 && 
       (open1 - close1) >= MicroImpulseThreshold * Point() &&
       close1 < close2)
    {
        Print("📉 MICRO IMPULSION BAISSIÈRE détectée");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Ouvre la position initiale                                       |
//+------------------------------------------------------------------+
void OpenInitialPosition()
{
    if(PositionsTotal() > 0 || OrdersTotal() > 0)
        return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double close1 = iClose(_Symbol, PERIOD_M1, 1);
    double open1 = iOpen(_Symbol, PERIOD_M1, 1);
    
    isLongPosition = (close1 > open1);
    
    if(isLongPosition)
    {
        double stopLoss = ask - TrailingStopPoints * Point();
        double takeProfit = ask + TakeProfitPoints * Point();
        
        if(trade.Buy(LotSize, _Symbol, ask, stopLoss, takeProfit, "INITIAL LONG"))
        {
            activePositionTicket = trade.ResultOrder();
            lastHighPrice = ask;
            lastLowPrice = ask;
            lockNewPositions = true;
            gridLoopActive = true;
            tradeCounter++;
            waitingForNewPosition = false;
            
            Print("");
            Print("✅ POSITION INITIALE LONG OUVERTE");
            Print("   Prix: ", DoubleToString(ask, _Digits));
            Print("   SL: ", DoubleToString(stopLoss, _Digits));
            Print("   TP: ", DoubleToString(takeProfit, _Digits));
            Print("   🔒 VERROUILLAGE ACTIVÉ");
            Print("");
            
            if(EnablePendingOrders)
                PlacePendingOrder();
        }
    }
    else
    {
        double stopLoss = bid + TrailingStopPoints * Point();
        double takeProfit = bid - TakeProfitPoints * Point();
        
        if(trade.Sell(LotSize, _Symbol, bid, stopLoss, takeProfit, "INITIAL SHORT"))
        {
            activePositionTicket = trade.ResultOrder();
            lastHighPrice = bid;
            lastLowPrice = bid;
            lockNewPositions = true;
            gridLoopActive = true;
            tradeCounter++;
            waitingForNewPosition = false;
            
            Print("");
            Print("✅ POSITION INITIALE SHORT OUVERTE");
            Print("   Prix: ", DoubleToString(bid, _Digits));
            Print("   SL: ", DoubleToString(stopLoss, _Digits));
            Print("   TP: ", DoubleToString(takeProfit, _Digits));
            Print("   🔒 VERROUILLAGE ACTIVÉ");
            Print("");
            
            if(EnablePendingOrders)
                PlacePendingOrder();
        }
    }
}

//+------------------------------------------------------------------+
//| Place un ordre limite d'attente                                  |
//+------------------------------------------------------------------+
void PlacePendingOrder()
{
    if(OrdersTotal() > 0)
        return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(isLongPosition)
    {
        double limitPrice = bid - PendingOrderDistance * Point();
        double stopLoss = limitPrice + TrailingStopPoints * Point();
        trade.SellLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "PENDING SELL");
    }
    else
    {
        double limitPrice = ask + PendingOrderDistance * Point();
        double stopLoss = limitPrice - TrailingStopPoints * Point();
        trade.BuyLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "PENDING BUY");
    }
}

//+------------------------------------------------------------------+
//| Mise à jour du Trailing Stop                                    |
//+------------------------------------------------------------------+
void UpdateTrailingStop()
{
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
                    
                    if(newSL > positionInfo.StopLoss() + Point())
                    {
                        trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit());
                    }
                }
                else if(positionInfo.PositionType() == POSITION_TYPE_SELL)
                {
                    lastLowPrice = MathMin(lastLowPrice, ask);
                    double newSL = lastLowPrice + TrailingStopPoints * Point();
                    
                    if(newSL < positionInfo.StopLoss() - Point())
                    {
                        trade.PositionModify(_Symbol, newSL, positionInfo.TakeProfit());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Gère la fermeture de position et ouverture inverse               |
//+------------------------------------------------------------------+
void ManagePositionClosure()
{
    bool positionExists = false;
    
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == _Symbol)
            {
                positionExists = true;
                break;
            }
        }
    }
    
    // Si on attend une nouvelle position
    if(waitingForNewPosition && !positionExists)
    {
        if(TimeCurrent() - lastPositionClosedTime > 2)
        {
            OpenReversePosition();
        }
        return;
    }
    
    // Si la position actuelle a disparu
    if(!positionExists && !waitingForNewPosition)
    {
        Print("");
        Print("💥 POSITION FERMÉE PAR SL OU TP");
        Print("➡️  Préparation de la position inverse...");
        Print("");
        
        CancelAllOrders();
        
        waitingForNewPosition = true;
        lastPositionClosedTime = TimeCurrent();
        
        isLongPosition = !isLongPosition;
    }
}

//+------------------------------------------------------------------+
//| Ouvre la position inverse                                        |
//+------------------------------------------------------------------+
void OpenReversePosition()
{
    if(PositionsTotal() > 0)
        return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(isLongPosition)
    {
        double stopLoss = ask - TrailingStopPoints * Point();
        double takeProfit = ask + TakeProfitPoints * Point();
        
        if(trade.Buy(LotSize, _Symbol, ask, stopLoss, takeProfit, "LOOP LONG"))
        {
            activePositionTicket = trade.ResultOrder();
            lastHighPrice = ask;
            lastLowPrice = ask;
            tradeCounter++;
            waitingForNewPosition = false;
            
            Print("✅ POSITION LONG OUVERTE (Cycle ", tradeCounter, ")");
            Print("   Prix: ", DoubleToString(ask, _Digits));
            Print("   SL: ", DoubleToString(stopLoss, _Digits));
            Print("   TP: ", DoubleToString(takeProfit, _Digits));
            Print("");
            
            if(EnablePendingOrders)
                PlacePendingOrder();
        }
    }
    else
    {
        double stopLoss = bid + TrailingStopPoints * Point();
        double takeProfit = bid - TakeProfitPoints * Point();
        
        if(trade.Sell(LotSize, _Symbol, bid, stopLoss, takeProfit, "LOOP SHORT"))
        {
            activePositionTicket = trade.ResultOrder();
            lastHighPrice = bid;
            lastLowPrice = bid;
            tradeCounter++;
            waitingForNewPosition = false;
            
            Print("✅ POSITION SHORT OUVERTE (Cycle ", tradeCounter, ")");
            Print("   Prix: ", DoubleToString(bid, _Digits));
            Print("   SL: ", DoubleToString(stopLoss, _Digits));
            Print("   TP: ", DoubleToString(takeProfit, _Digits));
            Print("");
            
            if(EnablePendingOrders)
                PlacePendingOrder();
        }
    }
}

//+------------------------------------------------------------------+
//| Annule tous les ordres en attente                                |
//+------------------------------------------------------------------+
void CancelAllOrders()
{
    for(int i = (int)OrdersTotal() - 1; i >= 0; i--)
    {
        if(orderInfo.SelectByIndex(i))
        {
            if(orderInfo.Magic() == MagicNumber && orderInfo.Symbol() == _Symbol)
            {
                trade.OrderDelete(orderInfo.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Timer event                                                     |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(gridLoopActive)
    {
        UpdateTrailingStop();
        ManagePositionClosure();
    }
}

//+------------------------------------------------------------------+
//| Fin de l'Expert Advisor                                          |
//+------------------------------------------------------------------+
