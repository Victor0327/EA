//+------------------------------------------------------------------+
//|                                                        Bands.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Bollinger Bands"
#property strict

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_color1 LightSeaGreen
#property indicator_color2 LightSeaGreen
#property indicator_color3 LightSeaGreen
#property indicator_color4 LightSeaGreen
#property indicator_color5 LightSeaGreen
#property indicator_color6 LightSeaGreen
#property indicator_color7 LightSeaGreen
#property indicator_color8 LightSeaGreen
#property indicator_color9 LightSeaGreen
//--- indicator parameters
input int    InpBandsPeriod=20;      // Bands Period
input int    InpBandsShift=0;        // Bands Shift
input double InpBandsDeviations=2.0; // Bands Deviations
//--- buffers
double ExtMovingBuffer[];

double ExtNarrowUpperBuffer[];
double ExtNormalUpperBuffer[];
double ExtWidenUpperBuffer[];

double ExtNarrowLowerBuffer[];
double ExtNormalLowerBuffer[];
double ExtWidenLowerBuffer[];

double ExtStdDevBuffer[];

class Welford {
public:
    Welford() : count_(0), mean_(0), M2_(0) {}

    void Add(double x) {
        count_++;
        double delta = x - mean_;
        mean_ += delta / count_;
        M2_ += delta * (x - mean_);
    }

    double Count() const { return count_; }

    double Mean() const { return mean_; }

    double Variance() const { return M2_ / (count_); }

    double StandardDeviation() const { 
        return MathSqrt(Variance()); 
    }

private:
    double count_;
    double mean_;
    double M2_;
};


//--- 存储布林带开口的波动值
Welford welford = new Welford();
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {  
//--- 1 additional buffer used for counting.
   IndicatorBuffers(4);
   IndicatorDigits(Digits);
//--- middle line
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMovingBuffer);
   SetIndexShift(0,InpBandsShift);
   SetIndexLabel(0,"Bands SMA");
//--- upper band
   SetIndexStyle(1,DRAW_LINE,EMPTY,2,Red);
   SetIndexBuffer(1,ExtNarrowUpperBuffer);
   SetIndexShift(1,InpBandsShift);
   SetIndexLabel(1,"Bands Upper");
   
   SetIndexStyle(2,DRAW_LINE,EMPTY,2,LightSeaGreen);
   SetIndexBuffer(2,ExtNormalUpperBuffer);
   SetIndexShift(2,InpBandsShift);
   SetIndexLabel(2,"Bands Upper");
   
   SetIndexStyle(3,DRAW_LINE,EMPTY,2,Blue);
   SetIndexBuffer(3,ExtWidenUpperBuffer);
   SetIndexShift(3,InpBandsShift);
   SetIndexLabel(3,"Bands Upper");
//--- lower band
   SetIndexStyle(4,DRAW_LINE,EMPTY,2,Red);
   SetIndexBuffer(4,ExtNarrowLowerBuffer);
   SetIndexShift(4,InpBandsShift);
   SetIndexLabel(4,"Bands Lower");
   
   SetIndexStyle(5,DRAW_LINE,EMPTY,2,LightSeaGreen);
   SetIndexBuffer(5,ExtNormalLowerBuffer);
   SetIndexShift(5,InpBandsShift);
   SetIndexLabel(5,"Bands Lower");
   
   SetIndexStyle(6,DRAW_LINE,EMPTY,2,Blue);
   SetIndexBuffer(6,ExtWidenLowerBuffer);
   SetIndexShift(6,InpBandsShift);
   SetIndexLabel(6,"Bands Lower");

//--- work buffer
   SetIndexBuffer(7,ExtStdDevBuffer);
//--- check for input parameter
   if(InpBandsPeriod<=0)
     {
      Print("Wrong input parameter Bands Period=",InpBandsPeriod);
      return(INIT_FAILED);
     }
//---
   SetIndexDrawBegin(0,InpBandsPeriod+InpBandsShift);
   SetIndexDrawBegin(1,InpBandsPeriod+InpBandsShift);
   SetIndexDrawBegin(2,InpBandsPeriod+InpBandsShift);
//--- initialization done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Bollinger Bands                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int i,pos;
//---
   if(rates_total<=InpBandsPeriod || InpBandsPeriod<=0)
      return(0);
//--- counting from 0 to rates_total
   ArraySetAsSeries(ExtMovingBuffer,false);
   ArraySetAsSeries(ExtNarrowUpperBuffer,false);
   ArraySetAsSeries(ExtNormalUpperBuffer,false);
   ArraySetAsSeries(ExtWidenUpperBuffer,false);
   ArraySetAsSeries(ExtNarrowLowerBuffer,false);
   ArraySetAsSeries(ExtNormalLowerBuffer,false);
   ArraySetAsSeries(ExtWidenLowerBuffer,false);
   ArraySetAsSeries(ExtStdDevBuffer,false);
   ArraySetAsSeries(close,false);
//--- initial zero
   if(prev_calculated<1)
     {
      for(i=0; i<InpBandsPeriod; i++)
        {
         ExtMovingBuffer[i]=EMPTY_VALUE;
         ExtNarrowUpperBuffer[i]=EMPTY_VALUE;
         ExtNormalUpperBuffer[i]=EMPTY_VALUE;
         ExtWidenUpperBuffer[i]=EMPTY_VALUE;
         ExtNarrowLowerBuffer[i]=EMPTY_VALUE;
         ExtNormalLowerBuffer[i]=EMPTY_VALUE;
         ExtWidenLowerBuffer[i]=EMPTY_VALUE;
        }
     }
//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle
   for(i=pos; i<rates_total && !IsStopped(); i++)  
     {
      //Print("pos", pos,"rates_total",rates_total,"welford.Count()",welford.Count());
      //--- middle line
      ExtMovingBuffer[i]=SimpleMA(i,InpBandsPeriod,close);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,close,ExtMovingBuffer,InpBandsPeriod);
      
      if (welford.Count() < rates_total) {
         welford.Add(4*ExtStdDevBuffer[i]);
         //Print("welford count",  welford.Count());
         //Print("welford StandardDeviation",  welford.StandardDeviation());
      }
      
      double upper = ExtMovingBuffer[i]+InpBandsDeviations*ExtStdDevBuffer[i];
      double lower = ExtMovingBuffer[i]-InpBandsDeviations*ExtStdDevBuffer[i];



      //计算上限和下限之间的差值
      double diff = upper - lower;
      
      //如果差值小于阈值，则更改带的颜色
      // narrow
    
      if (diff < welford.Mean()) {         
         ExtNarrowUpperBuffer[i] = upper;
         ExtNarrowLowerBuffer[i] = lower;
      // widen   
      } else if (diff > welford.Mean() + welford.StandardDeviation()) {
         ExtWidenUpperBuffer[i] = upper;
         ExtWidenLowerBuffer[i] = lower;
         // 前105根K到前5根K之间narrow的数量占比超过95%，报警
         if (i - 105 > 0) {
            double difflast = 2 * InpBandsDeviations*ExtStdDevBuffer[i - 1];
            if (difflast <= welford.Mean() + welford.StandardDeviation()) {

               int jCount = 0;
               for(int j = i - 105; j < i - 5; j++) 
                  {
                     // Print(j,"ExtNarrowUpperBuffer",  ExtNarrowUpperBuffer[j]);
                     if (ExtNarrowUpperBuffer[j] < 1000 && ExtNarrowUpperBuffer[j] > 0) {
                        jCount ++;
                     }
                  }
               
               if (jCount >= 95) {
                  Print("jCount",  jCount);
                  Print("welford Mean",welford.Mean(), 
                  "StandardDeviation",welford.StandardDeviation(),
                  "Mean-StandardDeviation",welford.Mean() - welford.StandardDeviation(),
                  "Mean+StandardDeviation",welford.Mean() + welford.StandardDeviation()
                  );
                  double askPrice = Ask;
                  double bidPrice = Bid;
                  double closePrice = Close[0];
                  if (closePrice >= ExtMovingBuffer[i]) {
                     DrawBuyArrow(askPrice);                  
                     Print("DrawBuyArrow",  askPrice);
                  } else {
                     DrawSellArrow(bidPrice);
                     Print("DrawSellArrow",  bidPrice);
                  }               
               }
            }
         }
         
      } else {
         ExtNormalUpperBuffer[i] = upper;
         ExtNormalLowerBuffer[i] = lower;
      }
     }
   // Print(Bars);
     
      //Print("welford count",  welford.Count());
      //Print("welford StandardDeviation",  welford.StandardDeviation());
     
     
//---- OnCalculate done. Return new prev_calculated.
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate Standard Deviation                                     |
//+------------------------------------------------------------------+
double StdDev_Func(int position,const double &price[],const double &MAprice[],int period)
  {
//--- variables
   double StdDev_dTmp=0.0;
//--- check for position
   if(position>=period)
     {
      //--- calcualte StdDev
      for(int i=0; i<period; i++)
         StdDev_dTmp+=MathPow(price[position-i]-MAprice[position],2);
      StdDev_dTmp=MathSqrt(StdDev_dTmp/period);
     }
//--- return calculated value
   return(StdDev_dTmp);
  }
//+------------------------------------------------------------------+

// 绘制一个买入箭头标识
void DrawBuyArrow(double price)
{
    // 设置箭头的颜色和宽度
    ObjectSet("BuyArrow", OBJPROP_COLOR, Blue);
    ObjectSet("BuyArrow", OBJPROP_WIDTH, 2);

    // 绘制箭头
    ObjectCreate("BuyArrow", OBJ_ARROW, 0, Time[0], price, 0);
    ObjectSet("BuyArrow", OBJPROP_ARROWCODE, 233);
}

// 绘制一个卖出箭头标识
void DrawSellArrow(double price)
{
    // 设置箭头的颜色和宽度
    ObjectSet("SellArrow", OBJPROP_COLOR, Red);
    ObjectSet("SellArrow", OBJPROP_WIDTH, 2);

    // 绘制箭头
    ObjectCreate("SellArrow", OBJ_ARROW, 0, Time[0], price, 0);
    ObjectSet("SellArrow", OBJPROP_ARROWCODE, 234);
}

