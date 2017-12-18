
import Foundation
import Cocoa
import Charts

struct Candle {
    var date: Date
    var open: Double
    var high: Double
    var low: Double
    var close: Double
}

class ViewController: NSViewController, ChartViewDelegate {
    //Chart view outlets
    @IBOutlet weak var combinedChartView: LineChartView!        //NSView!
    @IBOutlet weak var lineChartView: LineChartView!            //NSView!
    
    var xValues : [String] = []
    var mainTimeSerie : [CandleChartDataEntry] = []

    var currentCount = 0.0

    var timer  : Timer?

    var timeSerie: [Candle] = createTimeSerie()         // Fill an array with Date, O, H, L, C
    var yValuesMA14: [Double] = []
    
    var indexInTimeserie = 0    // use to get always the same price. Cycling the Tiemserie object
    var defaultPointNumber = 0.0  // Default number of point before scroling, used for setVisibleXRangeMaximum
    
    // Zoom Buttons
    @IBAction func zoomAll(_ sender: Any) {
        print("zoomAll")

        combinedChartView.fitScreen()
        lineChartView.fitScreen()
        defaultPointNumber = Double(mainTimeSerie.count)    // change the default point number so that scrol start only with next datapoint
    }
    @IBAction func zoomIn(_ sender: Any) {
        print("zoomIn")
        combinedChartView.zoomIn()
        //lineChartView.zoomIn()
        
        lineChartView.zoomToCenter(scaleX: 1.5, scaleY: 1)
    }
    @IBAction func zoomOut(_ sender: Any) {
        print("zoomOut")
        combinedChartView.zoomOut()
        //lineChartView.zoomOut()
        
        lineChartView.zoomToCenter(scaleX: 2/3, scaleY: 1)
    }
    @IBAction func playButton(_ sender: Any) {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.addValuesToChart), userInfo: nil, repeats: true)
    }
    
    @IBAction func pauseButton(_ sender: Any) {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        combinedChartView.xAxis.resetCustomAxisMax()
        combinedChartView.xAxis.resetCustomAxisMin()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
       
        combinedChartView.delegate = self
        lineChartView.delegate = self
        
        initChart()

        yValuesMA14 = indicatorMA(yValues: timeSerie, period:14)

        initData(mainChartValues: timeSerie, secondChartValues: yValuesMA14)
    }
    
    @IBAction func addValuesToChart(_ sender: Any) {
        let open = timeSerie[indexInTimeserie].open
        let high = timeSerie[indexInTimeserie].high
        let low = timeSerie[indexInTimeserie].low
        let close = timeSerie[indexInTimeserie].close
        // Reposition the new data point into the sample timeserie
        if indexInTimeserie > timeSerie.count{
            indexInTimeserie = 0
        } else {
            indexInTimeserie += 1
        }
        
        let pointNumber = timeSerie.count
        let lastday = timeSerie[pointNumber-1].date
        timeSerie.append(Candle(date: Calendar.current.date(byAdding: .day, value: 1, to: lastday)!, open: open, high: high, low: low, close: close))

        // Update the x-axis
        let aDate : String = lastday.toString(dateFormat: "dd-MM")
        xValues.append(aDate)
        combinedChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:xValues)
        lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:xValues)

        // Set the number of point displayed before scrolling
        combinedChartView.setVisibleXRangeMaximum(defaultPointNumber)
        lineChartView.setVisibleXRangeMaximum(defaultPointNumber)
        
        yValuesMA14 = indicatorMA(yValues: timeSerie, period:14)
        //****************
        // Update main chart
        //****************
        // Add the new data point in the main timeserie
        let newDataEntry = CandleChartDataEntry(x:  Double(pointNumber), shadowH: high, shadowL: low, open: open, close: close)
        combinedChartView.data?.addEntry(newDataEntry, dataSetIndex: 0)
        // Add new data point for MA
        var newowvalue = ChartDataEntry()
        
        combinedChartView.data?.notifyDataChanged()
        combinedChartView.notifyDataSetChanged()
        combinedChartView.moveViewToX(Double(CGFloat(pointNumber)))
        //****************
        // Update second chart
        //****************
        newowvalue = ChartDataEntry(x: Double(pointNumber), y: yValuesMA14[pointNumber-1])
        lineChartView.data?.addEntry(newowvalue, dataSetIndex: 0)
        lineChartView.data?.notifyDataChanged()
        lineChartView.notifyDataSetChanged()
        lineChartView.moveViewToX(Double(CGFloat(pointNumber)))

    }
    
    func initChart(){
        combinedChartView.noDataText = "Loading data..."
        lineChartView.noDataText = "Loading data..."
        
        // Main Chart
        combinedChartView.chartDescription?.text = ""
        // remove legend
        combinedChartView.legend.enabled = false
        combinedChartView.doubleTapToZoomEnabled = true
        // Draw a border around the chart
        combinedChartView.drawBordersEnabled = true
        // Background
        combinedChartView.drawGridBackgroundEnabled = true
        combinedChartView.gridBackgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        combinedChartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        // x Axis
        combinedChartView.xAxis.drawGridLinesEnabled = true // draw vertical line
        combinedChartView.xAxis.drawAxisLineEnabled = true  // line in the xaxis
        combinedChartView.xAxis.drawLabelsEnabled = true    // draw level in x axis
        //
        // Sub chart
        //
        lineChartView.chartDescription?.text = ""
        // remove legend
        lineChartView.legend.enabled = false
        lineChartView.doubleTapToZoomEnabled = true
        // Draw a border around the chart
        lineChartView.drawBordersEnabled = true
        // Background
        lineChartView.drawGridBackgroundEnabled = true
        lineChartView.gridBackgroundColor = NSUIColor.lightGray
        lineChartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        // lineChartView.xAxis.granularity = 1.0
        // x Axis
        lineChartView.xAxis.axisMinimum = 0.0
        lineChartView.xAxis.drawGridLinesEnabled = true // draw vertical line
        lineChartView.xAxis.drawAxisLineEnabled = true  // line in the xaxis
        lineChartView.xAxis.drawLabelsEnabled = true    // draw level in x axis
    }
    
    //Function to set chart values
    func initData(mainChartValues: [Candle], secondChartValues: [Double]) {
        
        let timeSerieSize = mainChartValues.count
        defaultPointNumber = Double(timeSerieSize)
        
        for i in 0..<timeSerieSize {
            let aDate : String =  mainChartValues[i].date.toString(dateFormat: "dd-MM")
            xValues.append(aDate)
        }
        //------------------------------
        // Upper Chart
        //------------------------------
        for i in 0..<timeSerieSize {
            let open = mainChartValues[i].open
            let high = mainChartValues[i].high
            let low = mainChartValues[i].low
            let close = mainChartValues[i].close
            
            mainTimeSerie.append(CandleChartDataEntry(x: Double(i), shadowH: high, shadowL: low, open: open, close: close))
        }
        let candleChartDataSet = CandleChartDataSet(values: mainTimeSerie, label: "Price")
        let candleChartData = CandleChartData(dataSets: [candleChartDataSet])


        let linesData = LineChartData()
        
        let data = CombinedChartData()
        data.candleData = candleChartData
        data.lineData = linesData

        combinedChartView.data = data

        combinedChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:xValues)

        candleChartDataSet.decreasingColor = NSColor.red
        candleChartDataSet.increasingColor = NSColor.green
        candleChartDataSet.neutralColor = NSColor.blue
        candleChartDataSet.shadowColorSameAsCandle = true
        candleChartDataSet.shadowWidth = 1
        candleChartDataSet.decreasingFilled = true
        candleChartDataSet.increasingFilled = false
        candleChartDataSet.drawValuesEnabled = false

        //------------------------------
        // Lower Chart
        //------------------------------
        //Ignore values that are "0"
        var indicatorLower_yValues: [ChartDataEntry] = []

        for i in 0..<timeSerieSize {
            if secondChartValues[i] != 0 {   //ADD: If clause to skip "0"
                let indicatorLower_yValue = ChartDataEntry(x:Double(i) , y: secondChartValues[i])
                indicatorLower_yValues.append(indicatorLower_yValue)
            }
        }

        let lineChartDataSet = LineChartDataSet(values: indicatorLower_yValues, label: "indicatorLower")
        let lineChartData = LineChartData(dataSets: [lineChartDataSet])
        lineChartView.data = lineChartData
        
        lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:xValues)
        lineChartDataSet.drawCirclesEnabled = false
        lineChartDataSet.drawValuesEnabled = false
        lineChartDataSet.colors = [NSUIColor.orange]
        lineChartDataSet.lineWidth = 3
    }

    override public func viewDidAppear() {
        super.viewDidAppear()
        view.window!.title = "RealTime Chart"
    }
    
    override func viewWillDisappear()
    {
        super.viewWillDisappear()
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
     
        if  chartView == combinedChartView {
            let currentMatrix = chartView.viewPortHandler.touchMatrix
            lineChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: lineChartView, invalidate: true)
        }else {
            let currentMatrix = chartView.viewPortHandler.touchMatrix
            combinedChartView.viewPortHandler.refresh(newMatrix: currentMatrix, chart: combinedChartView, invalidate: true)
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(" chartValueSelected entry.x = \(entry.x)  entry.y= \(entry.y)  x = \(highlight.x) y = \(highlight.y)")
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        print("chartValueNothingSelected")
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        print("chartScaled")

    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}



