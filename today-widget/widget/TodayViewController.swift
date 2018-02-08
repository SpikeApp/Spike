//
//  TodayViewController.swift
//  Widget
//
//  Created by Miguel Kennedy on 05/02/2018.
//  Copyright © 2018 Spike. All rights reserved.
//

import UIKit
import NotificationCenter
import PNChart

class TodayViewController: UIViewController, NCWidgetProviding, PNChartDelegate
{
    //IBOutlet
    @IBOutlet var chartView: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet var glucoseDisplay: UILabel!
    @IBOutlet var timeDisplay: UILabel!
    @IBOutlet var deltaDisplay: UILabel!
    @IBOutlet var lastUpdateDisplay: UILabel!
    @IBOutlet var openApp: UIButton!
    
    //IBActions
    @IBAction func openApp(_ sender: Any)
    {
        let url: URL? = URL(string: "spikeapp://")!
        if let appurl = url
        {
            self.extensionContext!.open(appurl, completionHandler: nil)
        }
    }
    
    //Variables
    var chartGlucoseValues = [Double]()
    var chartGlucoseTimes = [String]()
    
    //Constants
    let millisecondsInHour = 3600000
    let millisecondsInMinute = 60000
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Dummy data
        /*glucoseDisplay.text = "89"
        timeDisplay.text = "02min ago"
        deltaDisplay.text = "+0.5 mg/dL"
        lastUpdateDisplay.text = "Last update: 06, Jun, 15:35"*/
        
        
        //Widget Properties
        chartView.backgroundColor = UIColor.clear
        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        } else {
            // Fallback on earlier versions
        }
        
        //External Data
        //Define database file path
        let fileUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.spike-app.spike")!.appendingPathComponent("Library/Preferences/group.com.spike-app.spike.plist")
        
        //Check if file exists
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: fileUrl.path)
        {
            print("Database file doesn't exist!")
            return
        }
        
        //Parse database file into a dictionary
        let externalData = NSDictionary(contentsOfFile: fileUrl.path) as? [String: AnyObject];
        if (externalData!["glucoseValues"] == nil)
        {
            return
        }
        
        //Get properties
        let latestWidgetUpdate = externalData!["latestWidgetUpdate"] as? String
        let latestGlucoseValue = externalData!["latestGlucoseValue"] as? String
        let latestGlucoseSlopeArrow = externalData!["latestGlucoseSlopeArrow"] as? String
        let latestGlucoseDelta = externalData!["latestGlucoseDelta"] as? String
        let latestGlucoseTime = externalData!["latestGlucoseTime"] as? String
        let glucoseUnit = externalData!["glucoseUnit"] as? String
        let chartData = externalData!["chartData"] as? String
        let externalDataEncoded = chartData?.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let urgenLowThreshold = externalData!["urgenLowThreshold"] as? String
        let lowThreshold = externalData!["lowThreshold"] as? String
        let highThreshold = externalData!["highThreshold"] as? String
        let urgentHighThreshold = externalData!["urgentHighThreshold"] as? String
        let urgenLowColor = externalData!["urgenLowColor"] as? String
        let lowColor = externalData!["lowColor"] as? String
        let inRangeColor = externalData!["inRangeColor"] as? String
        let highColor = externalData!["highColor"] as? String
        let urgentHighColor = externalData!["urgentHighColor"] as? String
        let oldDataColor = externalData!["oldDataColor"] as? String
        let markerColor = externalData!["markerColor"] as? String
        let axisColor = externalData!["axisColor"] as? String
        let axisFontColor = externalData!["axisFontColor"] as? String
        let gridLinesColor = externalData!["gridLinesColor"] as? String
        let backgroundColor = externalData!["backgroundColor"] as? String
        let backgroundOpacity = externalData!["backgroundOpacity"] as? NSString
        let displayLabelsColor = externalData!["displayLabelsColor"] as? String
        let hourAgo = externalData!["hourAgo"] as? String
        let minAgo = externalData!["minAgo"] as? String
        let ago = externalData!["ago"] as? String
        let now = externalData!["now"] as? String
        let openSpike = externalData!["openSpike"] as? String
        let smoothLine = externalData!["smoothLine"] as? String
        let showMarkers = externalData!["showMarkers"] as? String
        let showMarkerLabel = externalData!["showMarkerLabel"] as? String
        let showGridLines = externalData!["showGridLines"] as? String
        let lineThickness = externalData!["lineThickness"] as? NSString
        let markerRadius = externalData!["markerRadius"] as? NSString
        
        //View Background
        let viewBackgroundColor:UIColor = UIColor.colorFromHex(hexString: backgroundColor!)
        mainView.backgroundColor = viewBackgroundColor.withAlphaComponent(CGFloat((backgroundOpacity?.floatValue)!))
        
        //Process Chart Data
        struct ChartData: Codable
        {
            var value: Double
            var time: String
        }
        
        do
        {
            let decoder = JSONDecoder()
            let externalDataJSON = try decoder.decode([ChartData].self, from: externalDataEncoded!)
            for (chartData) in externalDataJSON
            {
                chartGlucoseValues.append(chartData.value)
                chartGlucoseTimes.append(chartData.time)
            }
        }
        catch
        {
            print(error)
            return
        }
        
        //Display Labels
        glucoseDisplay.text = latestGlucoseValue! + " " + latestGlucoseSlopeArrow!
        if getTotalMinutes(latestTimestamp: Int64(latestGlucoseTime!)!) >= 6
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: oldDataColor!)
        }
        else if latestGlucoseValue == "LOW" || latestGlucoseValue == "??0" || latestGlucoseValue == "?SN" || latestGlucoseValue == "??2" || latestGlucoseValue == "?NA" || latestGlucoseValue == "?NC" || latestGlucoseValue == "?CD" || latestGlucoseValue == "?AD" || latestGlucoseValue == "?RF" || latestGlucoseValue == "???"
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgenLowColor!)
        }
        else if latestGlucoseValue == "HIGH"
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgentHighColor!)
        }
        else if let latestGlucoseValueInteger = Int(latestGlucoseValue!), let urgentLowThresholdInteger = Int(urgenLowThreshold!), latestGlucoseValueInteger <= urgentLowThresholdInteger
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgenLowColor!)
        }
        else if let latestGlucoseValueInteger = Int(latestGlucoseValue!), let urgentLowThresholdInteger = Int(urgenLowThreshold!), let lowThresholdInteger = Int(lowThreshold!), latestGlucoseValueInteger > urgentLowThresholdInteger && latestGlucoseValueInteger <= lowThresholdInteger
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: lowColor!)
        }
        else if let latestGlucoseValueInteger = Int(latestGlucoseValue!), let lowThresholdInteger = Int(lowThreshold!), let highThresholdInteger = Int(highThreshold!), latestGlucoseValueInteger > lowThresholdInteger && latestGlucoseValueInteger < highThresholdInteger
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: inRangeColor!)
        }
        else if let latestGlucoseValueInteger = Int(latestGlucoseValue!), let highThresholdInteger = Int(highThreshold!), let urgentHighThresholdInteger = Int(urgentHighThreshold!), latestGlucoseValueInteger >= highThresholdInteger && latestGlucoseValueInteger < urgentHighThresholdInteger
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: highColor!)
        }
        else if let latestGlucoseValueInteger = Int(latestGlucoseValue!), let urgentHighThresholdInteger = Int(urgentHighThreshold!), latestGlucoseValueInteger >= urgentHighThresholdInteger
        {
            glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgentHighColor!)
        }
        
        timeDisplay.text = getTimeAgo(latestTimestamp: Int64(latestGlucoseTime!)!, hourAgo: hourAgo!, minAgo: minAgo!, ago: ago!, now: now!)
        if getTotalMinutes(latestTimestamp: Int64(latestGlucoseTime!)!) >= 6
        {
            timeDisplay.textColor = UIColor.colorFromHex(hexString: oldDataColor!)
        }
        else
        {
            timeDisplay.textColor = UIColor.colorFromHex(hexString: displayLabelsColor!)
        }
        deltaDisplay.text = latestGlucoseDelta! + " " + glucoseUnit!
        if getTotalMinutes(latestTimestamp: Int64(latestGlucoseTime!)!) >= 6
        {
            deltaDisplay.textColor = UIColor.colorFromHex(hexString: oldDataColor!)
        }
        else
        {
            deltaDisplay.textColor = UIColor.colorFromHex(hexString: displayLabelsColor!)
        }
        lastUpdateDisplay.text = latestWidgetUpdate!
        lastUpdateDisplay.textColor = UIColor.colorFromHex(hexString: displayLabelsColor!)
        openApp.setTitle(openSpike, for: .normal)
        openApp.setTitleColor(UIColor.colorFromHex(hexString: displayLabelsColor!), for: .normal)
        
        if #available(iOSApplicationExtension 10.0, *)
        {
            //Chart
            let chart:PNLineChart = PNLineChart(frame: CGRect(x: 0, y: 0, width:chartView!.frame.size.width, height: 178))
            if glucoseUnit == "mmol/L"
            {
                chart.yLabelFormat = "%1.1f"
            }
            //Doesn't do anything on the display
            chart.showLabel = false
            
            //Settings
            chart.isShowCoordinateAxis = true
            chart.showGenYLabels = true //Y Axis Labels
            chart.showLabel = true; //X Axis Labels
            chart.xLabelFont = UIFont.systemFont(ofSize: 8) //X Axis Lower Labels Font
            chart.yLabelFont = UIFont.systemFont(ofSize: 8) //Y Axis Left Labels Font
            if smoothLine == "true"
            {
                chart.showSmoothLines = true;
            }
            else
            {
                chart.showSmoothLines = false;
            }
            if showGridLines == "true"
            {
                chart.showYGridLines = true; //Horizontal Grid Lines
            }
            else
            {
                chart.showYGridLines = false; //Horizontal Grid Lines
            }
            
            //Colors
            chart.backgroundColor = UIColor.clear
            chart.axisColor = UIColor.colorFromHex(hexString: axisColor!) //Both axis color
            chart.yGridLinesColor = UIColor.colorFromHex(hexString: gridLinesColor!) //Horizontal Grid Lines Color
            chart.xLabelColor = UIColor.colorFromHex(hexString: axisFontColor!) //X Axis Lower Labels Color
            chart.yLabelColor = UIColor.colorFromHex(hexString: axisFontColor!) //X Axis Left Labels Color
            
            //Size
            chart.axisWidth = 0.5
            
            //Chart Data
            //chart.xLabels = ["Sep 1", "Sep 2", "Sep 3", "Sep 4", "Sep 5", "Sep 6", "Sep 7", "Sep 7", "Sep 7", "Sep 7", "Sep 7", "Sep 7", "Sep 7"]
            //let dataArr = [40, 47, 55, 70, 80, 95, 110, 115, 130, 150, 170, 600, 40]
            chart.xLabels = chartGlucoseTimes
            let data = PNLineChartData()
            let lowRange = NSRange(location: 1, length: 54)
            let inRange = NSRange(location: 55, length: 55)
            let highRange = NSRange(location: 110, length: 20)
            let urgentRange = NSRange(location: 130, length: 600)
            data.rangeColors = [
                PNLineChartColorRange(range: lowRange, color: UIColor.red), //0 to 55
                PNLineChartColorRange(range: inRange, color: UIColor.green), //0 to 55
                PNLineChartColorRange(range: highRange, color: UIColor.yellow), //110 to 130
                PNLineChartColorRange(range: urgentRange, color: UIColor.red) //130 to 600
            ]
            /*data.rangeColors = [
                PNLineChartColorRange(range: NSMakeRange(1, 55), color: UIColor.red), //0 to 55
                PNLineChartColorRange(range: NSMakeRange(110, 20), color: UIColor.yellow), //110 to 130
                PNLineChartColorRange(range: NSMakeRange(130, 600), color: UIColor.red) //130 to 600
            ]*/
            //data.color = UIColor.green
            //data.itemCount = UInt(dataArr.count)
            data.itemCount = UInt(chartGlucoseValues.count)
            if showMarkers == "true"
            {
                data.inflexionPointStyle = .circle
            }
            else
            {
                data.inflexionPointStyle = .none
            }
            data.inflexionPointWidth = CGFloat((markerRadius?.floatValue)!)
            data.inflexionPointColor = UIColor.colorFromHex(hexString: markerColor!)
            data.lineWidth = CGFloat((lineThickness?.floatValue)!)
            data.pointLabelColor = UIColor.colorFromHex(hexString: "#FFFFFF")
            if showMarkerLabel == "true"
            {
                data.showPointLabel = true;
            }
            else
            {
                data.showPointLabel = false;
            }
            data.pointLabelFont = UIFont.systemFont(ofSize: 8)
            if glucoseUnit == "mmol/L"
            {
                data.pointLabelFormat = "%1.1f";
            }
            data.getData = ({
                (index: UInt) -> PNLineChartDataItem in
                //let yValue:CGFloat = CGFloat(dataArr[Int(index)])
                let yValue:CGFloat = CGFloat(self.chartGlucoseValues[Int(index)])
                let item = PNLineChartDataItem(y: yValue)
                return item!
            })
            
            chart.chartData = [data]
            chart.stroke()
            
            chartView?.addSubview(chart)
        }
    }
    
    func getTotalMinutes (latestTimestamp:Int64) -> Int
    {
        let nowTimestamp = Date().toTimestamp()
        let differenceInMills = nowTimestamp! - latestTimestamp
        
        return Int(Int(differenceInMills) / millisecondsInMinute)
    }
    
    func getTimeAgo(latestTimestamp:Int64, hourAgo:String, minAgo:String, ago:String, now:String)->String
    {
        let nowTimestamp = Date().toTimestamp()
        let differenceInMills = nowTimestamp! - latestTimestamp
        let hours = Int(Int(differenceInMills) / millisecondsInHour) % 24;
        let minutes = Int(Int(differenceInMills) / millisecondsInMinute) % 60

        var output : String = ""
        var hoursFormatted : String
        var minutesFormatted : String = ""
        
        if hours > 0
        {
            if hours < 10
            {
                hoursFormatted = "0" + String(hours)
            }
            else
            {
                hoursFormatted = String(hours)
            }
            
            output += hoursFormatted + hourAgo
            if minutes > 0
            {
                hoursFormatted += ":"
            }
            else
            {
                hoursFormatted += " " + ago
            }
        }
        
        if minutes > 0
        {
            if minutes < 10
            {
                minutesFormatted = "0" + String(minutes)
            }
            else
            {
                minutesFormatted = String(minutes)
            }
            
            output += minutesFormatted + minAgo + " " + ago
        }
        
        if minutes == 0 && hours == 0
        {
            output = now
        }
        
        return output
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = maxSize
        } else if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 300)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}

/* Extensions */
extension Date
{
    func toTimestamp() -> Int64!
    {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
