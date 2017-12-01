import Foundation

func indicatorMA(yValues: [Candle], period: Int=14) -> [Double]{

    var sum = 0.0
    var SMA: [Double] = []
    
    //Simple Moving Average
    for i in 0..<Int(period) {
        sum  += yValues[i].close
        if i < Int(period)-1 {
            SMA.append(0)//These values are to be ignored
        }
    }
    SMA.append(sum/Double(period))
    for i in Int(period)..<yValues.count {
        sum = (sum - yValues[i - Int(period)].close) + yValues[i].close
        SMA.append(sum/Double(period))
    }
    return SMA
}
