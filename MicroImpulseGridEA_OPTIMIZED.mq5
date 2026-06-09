//+------------------------------------------------------------------+
//| MicroImpulseGridEA_OPTIMIZED.mq5                                 |
//| Micro Impulse Trading with Infinite Trailing Stop Loop           |
//| Single Initial Position + Trailing SL + Auto Reversal            |
//+------------------------------------------------------------------+

#property copyright "Grid Trading System"
#property link      "https://example.com"
#property version   "2.00"
#property strict
#property description "Optimized Micro Impulse Grid EA - Single Position + Infinite Loop"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- Input parameters
input double LotSize = 0.01;                    // Taille de la position
input double TrailingStopPoints = 50;           // Trailling Stop en points
input double PendingOrderDistance = 30;         // Distance de l'ordre en attente
input int MicroImpulseThreshold = 5;            // Sensibilité de détection (points)
input ulong MagicNumber = 20260601;             // Numéro magique
input int MaxSpread = 20;                       // Spread max autorisé (points)
input bool EnablePendingOrders = true;          // Activer ordres en attente
input int UpdateTrailingInterval = 100;         // Intervalle de mise à jour du trailing (ms)

//--- Global variables
CTrade trade;
CPositionInfo positionInfo;
COrderInfo orderInfo;

//--- Trading State
bool initialPositionOpened = false;              // Position initiale ouverte
bool lockNewPositions = false;                   // Verrouillage pour empêcher autres positions
bool gridLoopActive = false;                     // Boucle de trading active
ulong activePositionTicket = 0;                  // Ticket de la position active
double lastEntryPrice = 0;                       // Dernier prix d'entrée
double lastHighPrice = 0;                        // Plus haut prix atteint (pour trailing)
double lastLowPrice = 0;                         // Plus bas prix atteint (pour trailing)
bool isLongPosition = false;                     // True = Long, False = Short
datetime lastTradeTime = 0;                      // Dernière ouverture de position
datetime lastTrailingUpdateTime = 0;             // Dernière mise à jour du trailing
int tradeCounter = 0;                            // Compteur de trades dans la boucle

//+------------------------------------------------------------------+
//| Initialisation                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    
    // Vérification des prix
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(ask <= 0 || bid <= 0)
    {
        Print("❌ ERREUR: Impossible de récupérer les prix");
        return INIT_FAILED;
    }
    
    // Configuration du timer
    EventSetTimer(100);
    
    Print("=== EA Micro Impulsion Optimisé - INITIALISÉ ===");
    Print("Symbole: ", _Symbol);
    Print("Lot: ", LotSize);
    Print("Trailing Stop: ", TrailingStopPoints, " points");
    Print("Distance ordre limite: ", PendingOrderDistance, " points");
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
    Print("Raison: ", reason);
    Print("Total trades effectués dans cette session: ", tradeCounter);
}

//+------------------------------------------------------------------+
//| Tick function - Boucle principale                               |
//+------------------------------------------------------------------+
void OnTick()
{
    // Vérification du spread
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double spread = (ask - bid) / Point();
    
    if(spread > MaxSpread)
    {
        return; // Spread trop élevé
    }
    
    // PHASE 1: Attendre la première micro impulsion
    if(!initialPositionOpened && !lockNewPositions)
    {
        if(DetectMicroImpulse())
        {
            OpenInitialPosition();
        }
    }
    
    // PHASE 2: Gérer la boucle infinie après première position
    if(gridLoopActive && lockNewPositions)
    {
        ManageTrailingStop();
        CheckPositionClosed();
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
    
    // Récupère les 3 dernières bougies
    double close0 = iClose(_Symbol, PERIOD_M1, 0); // Bougie actuelle
    double close1 = iClose(_Symbol, PERIOD_M1, 1); // Bougie précédente
    double close2 = iClose(_Symbol, PERIOD_M1, 2); // Avant-dernier
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
//| Ouvre la position initiale et active le verrouillage            |
//+------------------------------------------------------------------+
void OpenInitialPosition()
{
    // Vérification de sécurité
    if(PositionsTotal() > 0 || OrdersTotal() > 0)
    {
        Print("⚠️  Position ou ordre existant, annulation");
        return;
    }
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double close1 = iClose(_Symbol, PERIOD_M1, 1);
    double open1 = iOpen(_Symbol, PERIOD_M1, 1);
    
    // Détermine la direction
    isLongPosition = (close1 > open1);
    
    if(isLongPosition)
    {
        // POSITION D'ACHAT
        double stopLoss = ask - TrailingStopPoints * Point();
        
        if(trade.Buy(LotSize, _Symbol, ask, stopLoss, 0, "🔷 Initial LONG"))
        {
            activePositionTicket = trade.ResultOrder();
            lastEntryPrice = ask;
            lastHighPrice = ask;
            lastLowPrice = ask;
            initialPositionOpened = true;
            lockNewPositions = true;
            gridLoopActive = true;
            lastTradeTime = TimeCurrent();
            tradeCounter++;
            
            Print("");
            Print("✅ POSITION INITIALE OUVERTE - LONG");
            Print("   Prix d'entrée: ", DoubleToString(ask, _Digits));
            Print("   Stop Loss: ", DoubleToString(stopLoss, _Digits));
            Print("   Ticket: ", activePositionTicket);
            Print("   🔒 VERROUILLAGE ACTIVÉ - Pas d'autres positions possibles");
            Print("");
            
            Sleep(200);
            
            // Place l'ordre limite d'attente pour VENTE
            if(EnablePendingOrders)
            {
                PlacePendingReverseOrder();
            }
        }
    }
    else
    {
        // POSITION DE VENTE
        double stopLoss = bid + TrailingStopPoints * Point();
        
        if(trade.Sell(LotSize, _Symbol, bid, stopLoss, 0, "🔶 Initial SHORT"))
        {
            activePositionTicket = trade.ResultOrder();
            lastEntryPrice = bid;
            lastHighPrice = bid;
            lastLowPrice = bid;
            initialPositionOpened = true;
            lockNewPositions = true;
            gridLoopActive = true;
            lastTradeTime = TimeCurrent();
            tradeCounter++;
            
            Print("");
            Print("✅ POSITION INITIALE OUVERTE - SHORT");
            Print("   Prix d'entrée: ", DoubleToString(bid, _Digits));
            Print("   Stop Loss: ", DoubleToString(stopLoss, _Digits));
            Print("   Ticket: ", activePositionTicket);
            Print("   🔒 VERROUILLAGE ACTIVÉ - Pas d'autres positions possibles");
            Print("");
            
            Sleep(200);
            
            // Place l'ordre limite d'attente pour ACHAT
            if(EnablePendingOrders)
            {
                PlacePendingReverseOrder();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Place un ordre limite d'attente inversé                          |
//+------------------------------------------------------------------+
void PlacePendingReverseOrder()
{
    // Ne crée qu'un seul ordre d'attente
    if(OrdersTotal() > 0)
        return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if(isLongPosition)
    {
        // Ordre SELL limit en attente
        double limitPrice = bid - PendingOrderDistance * Point();
        double stopLoss = limitPrice + TrailingStopPoints * Point();
        
        if(trade.SellLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "⏳ Pending SELL"))
        {
            Print("   ⏳ Ordre SELL limite placé à ", DoubleToString(limitPrice, _Digits));
            Print("   Stop Loss: ", DoubleToString(stopLoss, _Digits));
        }
    }
    else
    {
        // Ordre BUY limit en attente
        double limitPrice = ask + PendingOrderDistance * Point();
        double stopLoss = limitPrice - TrailingStopPoints * Point();
        
        if(trade.BuyLimit(LotSize, limitPrice, _Symbol, stopLoss, 0, ORDER_TIME_GTC, 0, "⏳ Pending BUY"))
        {
            Print("   ⏳ Ordre BUY limite placé à ", DoubleToString(limitPrice, _Digits));
            Print("   Stop Loss: ", DoubleToString(stopLoss, _Digits));
        }
    }
}

//+------------------------------------------------------------------+
//| Gère le Trailing Stop pour la position active                   |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    datetime now = TimeCurrent();
    
    // Vérification de l'intervalle de mise à jour
    if((now - lastTrailingUpdateTime) * 1000 < UpdateTrailingInterval)
        return;
    
    lastTrailingUpdateTime = now;
    
    // Cherche TOUTE position avec le magic number (peu importe le commentaire)
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && 
               positionInfo.Symbol() == _Symbol)
            {
                if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                {
                    // Position LONG - Trailling SL vers le haut
                    lastHighPrice = MathMax(lastHighPrice, bid);
                    double newSL = lastHighPrice - TrailingStopPoints * Point();
                    
                    if(newSL > positionInfo.StopLoss() + Point())
                    {
                        if(trade.PositionModify(_Symbol, newSL, 0))
                        {
                            Print("📊 Trailing SL LONG mis à jour: ", DoubleToString(newSL, _Digits));
                        }
                    }
                }
                else if(positionInfo.PositionType() == POSITION_TYPE_SELL)
                {
                    // Position SHORT - Trailling SL vers le bas
                    lastLowPrice = MathMin(lastLowPrice, ask);
                    double newSL = lastLowPrice + TrailingStopPoints * Point();
                    
                    if(newSL < positionInfo.StopLoss() - Point())
                    {
                        if(trade.PositionModify(_Symbol, newSL, 0))
                        {
                            Print("📊 Trailing SL SHORT mis à jour: ", DoubleToString(newSL, _Digits));
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Vérifie si la position a été fermée (SL touché)                  |
//+------------------------------------------------------------------+
void CheckPositionClosed()
{
    bool positionExists = false;
    
    // Cherche TOUTE position avec le magic number (peu importe le commentaire)
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(positionInfo.SelectByIndex(i))
        {
            if(positionInfo.Magic() == MagicNumber && 
               positionInfo.Symbol() == _Symbol)
            {
                positionExists = true;
                break;
            }
        }
    }
    
    // Si la position a été fermée, on ouvre l'inverse
    if(!positionExists)
    {
        Print("");
        Print("💥 STOP LOSS TOUCHÉ - Position fermée!");
        Print("➡️  Ouverture de la position INVERSE...");
        Print("");
        
        Sleep(500); // Pause pour stabiliser le serveur
        
        // Supprime l'ordre limite non exécuté
        CancelAllPendingOrders();
        
        Sleep(200);
        
        // Inverse la direction
        isLongPosition = !isLongPosition;
        
        Sleep(200);
        
        // Ouvre immédiatement la position inverse
        OpenReversePosition();
    }
}

//+------------------------------------------------------------------+
//| Ouvre la position inverse (après fermeture du SL)               |
//+------------------------------------------------------------------+
void OpenReversePosition()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Vérification de sécurité
    if(PositionsTotal() > 0)
    {
        Print("⚠️  Position existante, attente...");
        return;
    }
    
    if(isLongPosition)
    {
        // Ouvre LONG après que SHORT ait été fermé
        double stopLoss = ask - TrailingStopPoints * Point();
        
        if(trade.Buy(LotSize, _Symbol, ask, stopLoss, 0, "🔷 Loop LONG"))
        {
            activePositionTicket = trade.ResultOrder();
            lastEntryPrice = ask;
            lastHighPrice = ask;
            lastLowPrice = ask;
            lastTradeTime = TimeCurrent();
            tradeCounter++;
            
            Print("✅ POSITION LONG OUVERTE (Cycle ", tradeCounter, ")");
            Print("   Prix: ", DoubleToString(ask, _Digits));
            Print("   SL: ", DoubleToString(stopLoss, _Digits));
            Print("");
            
            Sleep(200);
            if(EnablePendingOrders)
                PlacePendingReverseOrder();
        }
    }
    else
    {
        // Ouvre SHORT après que LONG ait été fermé
        double stopLoss = bid + TrailingStopPoints * Point();
        
        if(trade.Sell(LotSize, _Symbol, bid, stopLoss, 0, "🔶 Loop SHORT"))
        {
            activePositionTicket = trade.ResultOrder();
            lastEntryPrice = bid;
            lastHighPrice = bid;
            lastLowPrice = bid;
            lastTradeTime = TimeCurrent();
            tradeCounter++;
            
            Print("✅ POSITION SHORT OUVERTE (Cycle ", tradeCounter, ")");
            Print("   Prix: ", DoubleToString(bid, _Digits));
            Print("   SL: ", DoubleToString(stopLoss, _Digits));
            Print("");
            
            Sleep(200);
            if(EnablePendingOrders)
                PlacePendingReverseOrder();
        }
    }
}

//+------------------------------------------------------------------+
//| Annule tous les ordres en attente                                |
//+------------------------------------------------------------------+
void CancelAllPendingOrders()
{
    for(int i = (int)OrdersTotal() - 1; i >= 0; i--)
    {
        if(orderInfo.SelectByIndex(i))
        {
            if(orderInfo.Magic() == MagicNumber && 
               orderInfo.Symbol() == _Symbol)
            {
                if(trade.OrderDelete(orderInfo.Ticket()))
                {
                    Print("   ❌ Ordre limite annulé: ", orderInfo.Ticket());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Timer event pour mise à jour périodique                          |
//+-j-----------------------------------------------------------------+
void OnTimer()
{
    if(gridLoopActive)
    {
        ManageTrailingStop();
        CheckPositionClosed();
    }
}

//+------------------------------------------------------------------+
//| Fin de l'Expert Advisor                                          |
//+------------------------------------------------------------------+
