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
    @IBOutlet var noData: UILabel!
    @IBOutlet var treatmentsLabel: UILabel!
    
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
    var chart:PNLineChart! = nil
    var chartGlucoseValues = [Double]()
    var chartGlucoseTimes = [String]()
    var fileUrl:URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.miguelkennedy.spike")!
    var externalData:[String : AnyObject] = [:]
    var latestWidgetUpdate:String = ""
    var latestGlucoseValue:String = ""
    var latestGlucoseSlopeArrow:String = ""
    var latestGlucoseDelta:String = ""
    var latestGlucoseTime:String = ""
    var highString:String = ""
    var lowString:String = ""
    var glucoseUnit:String = ""
    var glucoseUnitInternal:String = ""
    var chartData:String = ""
    var externalDataEncoded:Data = Data()
    var urgenLowThreshold:String = ""
    var lowThreshold:String = ""
    var highThreshold:String = ""
    var urgentHighThreshold:String = ""
    var urgenLowColor:String = ""
    var lowColor:String = ""
    var inRangeColor:String = ""
    var highColor:String = ""
    var urgentHighColor:String = ""
    var oldDataColor:String = ""
    var markerColor:String = ""
    var axisColor:String = ""
    var axisFontColor:String = ""
    var gridLinesColor:String = ""
    var mainLineColor:String = ""
    var backgroundColor:String = ""
    var backgroundOpacity:NSString = ""
    var displayLabelsColor:String = ""
    var hourAgo:String = ""
    var minAgo:String = ""
    var ago:String = ""
    var now:String = ""
    var openSpike:String = ""
    var smoothLine:String = ""
    var showMarkers:String = ""
    var showMarkerLabel:String = ""
    var showGridLines:String = ""
    var lineThickness:NSString = ""
    var markerRadius:NSString = ""
    var IOB:String = "0.00U"
    var COB:String = "0.00g"
    var IOBString:String = ""
    var COBString:String = ""
    var predictionsDuration:String = ""
    var predictionsOutcome:String = ""
    
    //Constants
    let millisecondsInHour = 3600000
    let millisecondsInMinute = 60000
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    private var tableViewHeightConstraint : NSLayoutConstraint?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Dummy data
        /*latestWidgetUpdate = "Lat Update: 05, Jun, 22:35"
         latestGlucoseValue = "600"
         latestGlucoseSlopeArrow = "-"
         latestGlucoseDelta = "+0.5"
         latestGlucoseTime = String(Date().toTimestamp())
         glucoseUnit = "mg/dL"
         //chartData = (externalData["chartData"] as? String)!
         //externalDataEncoded = chartData.data(using: String.Encoding.utf8, allowLossyConversion: false)!
         urgenLowThreshold = "50"
         lowThreshold = "60"
         highThreshold = "110"
         urgentHighThreshold = "130"
         urgenLowColor = "#FF0000"
         lowColor = "#FFFF00"
         inRangeColor = "#00FF00"
         highColor = "#0000FF"
         urgentHighColor = "#FF0000"
         oldDataColor = "#CCCCCC"
         markerColor = "#FFFFFF"
         axisColor = "#FFFFFF"
         axisFontColor = "#FFFFFF"
         gridLinesColor = "#FFFFFF"
         backgroundColor = "#FF0000"
         backgroundOpacity = "0.2"
         displayLabelsColor = "#FFFFFF"
         hourAgo = "h"
         minAgo = "m"
         ago = "ago"
         now = "now"
         openSpike = "open spike"
         smoothLine = "true"
         showMarkers = "true"
         showMarkerLabel = "true"
         showGridLines = "false"
         lineThickness = "2"
         markerRadius = "6"
         IOB = "6.05"
         COB = "25.4"
         predictionsDuration = "1h30m"
         predictionsOutcome = "101"
         */
        
        
        //Widget Properties
        chartView.backgroundColor = UIColor.clear
        if #available(iOSApplicationExtension 10.0, *)
        {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        else
        {
            self.preferredContentSize = CGSize(width: mainView.frame.size.width, height: 300)
        }
        
        if getExternalData()
        {
            if populateProperties()
            {
                setBackground()
                setLabels()
                /*if #available(iOSApplicationExtension 10.0, *)
                {
                    if parseChartData()
                    {
                        setChart()
                    }
                }*/
            }
        }
        
        //DEBUG
        //setBackground()
        //setLabels()
        //setChart()
    }
    
    /**
     *  Loads UsersDefaults External Data
     */
    func getExternalData()->Bool
    {
        //External Data
        //Define database file path
        fileUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.miguelkennedy.spike")!.appendingPathComponent("Library/Preferences/group.com.miguelkennedy.spike.plist")
        
        //Check if file exists
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: fileUrl.path)
        {
            print("Database file doesn't exist!")
            noData.text = "No Data!"
            return false
        }
        
        //Parse database file into a dictionary
        externalData = (NSDictionary(contentsOfFile: fileUrl.path) as? [String: AnyObject])!;
        
        return true
    }
    
    func populateProperties()->Bool
    {
        //Validate Data
        if  externalData["latestWidgetUpdate"] == nil ||
            externalData["latestGlucoseValue"] == nil ||
            externalData["latestGlucoseSlopeArrow"] == nil ||
            externalData["latestGlucoseDelta"] == nil ||
            externalData["latestGlucoseTime"] == nil ||
            externalData["glucoseUnit"] == nil ||
            externalData["glucoseUnitInternal"] == nil ||
            externalData["chartData"] == nil ||
            externalData["urgenLowThreshold"] == nil ||
            externalData["lowThreshold"] == nil ||
            externalData["highThreshold"] == nil ||
            externalData["urgentHighThreshold"] == nil ||
            externalData["urgenLowColor"] == nil ||
            externalData["lowColor"] == nil ||
            externalData["inRangeColor"] == nil ||
            externalData["highColor"] == nil ||
            externalData["urgentHighColor"] == nil ||
            externalData["oldDataColor"] == nil ||
            externalData["markerColor"] == nil ||
            externalData["axisColor"] == nil ||
            externalData["axisFontColor"] == nil ||
            externalData["gridLinesColor"] == nil ||
            externalData["mainLineColor"] == nil ||
            externalData["backgroundColor"] == nil ||
            externalData["backgroundOpacity"] == nil ||
            externalData["displayLabelsColor"] == nil ||
            externalData["hourAgo"] == nil ||
            externalData["minAgo"] == nil ||
            externalData["ago"] == nil ||
            externalData["now"] == nil ||
            externalData["openSpike"] == nil ||
            externalData["smoothLine"] == nil ||
            externalData["showMarkers"] == nil ||
            externalData["showMarkerLabel"] == nil ||
            externalData["showGridLines"] == nil ||
            externalData["lineThickness"] == nil ||
            externalData["markerRadius"] == nil ||
            externalData["high"] == nil ||
            externalData["low"] == nil ||
            externalData["IOBString"] == nil ||
            externalData["COBString"] == nil ||
            externalData["predictionDuration"] == nil ||
            externalData["predictionOutcome"] == nil
        {
            print("Missing data in database!")
            noData.text = "Missing data in database!"
            return false
        }
        
        //Get properties
        latestWidgetUpdate = (externalData["latestWidgetUpdate"] as? String)!
        latestGlucoseValue = (externalData["latestGlucoseValue"] as? String)!
        latestGlucoseSlopeArrow = (externalData["latestGlucoseSlopeArrow"] as? String)!
        latestGlucoseDelta = (externalData["latestGlucoseDelta"] as? String)!
        latestGlucoseTime = (externalData["latestGlucoseTime"] as? String)!
        glucoseUnit = (externalData["glucoseUnit"] as? String)!
        glucoseUnitInternal = (externalData["glucoseUnitInternal"] as? String)!
        chartData = (externalData["chartData"] as? String)!
        externalDataEncoded = chartData.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        urgenLowThreshold = (externalData["urgenLowThreshold"] as? String)!
        lowThreshold = (externalData["lowThreshold"] as? String)!
        highThreshold = (externalData["highThreshold"] as? String)!
        urgentHighThreshold = (externalData["urgentHighThreshold"] as? String)!
        urgenLowColor = (externalData["urgenLowColor"] as? String)!
        lowColor = (externalData["lowColor"] as? String)!
        inRangeColor = (externalData["inRangeColor"] as? String)!
        highColor = (externalData["highColor"] as? String)!
        urgentHighColor = (externalData["urgentHighColor"] as? String)!
        oldDataColor = (externalData["oldDataColor"] as? String)!
        markerColor = (externalData["markerColor"] as? String)!
        axisColor = (externalData["axisColor"] as? String)!
        axisFontColor = (externalData["axisFontColor"] as? String)!
        gridLinesColor = (externalData["gridLinesColor"] as? String)!
        mainLineColor = (externalData["mainLineColor"] as? String)!
        backgroundColor = (externalData["backgroundColor"] as? String)!
        backgroundOpacity = (externalData["backgroundOpacity"] as? NSString)!
        displayLabelsColor = (externalData["displayLabelsColor"] as? String)!
        hourAgo = (externalData["hourAgo"] as? String)!
        minAgo = (externalData["minAgo"] as? String)!
        highString = (externalData["high"] as? String)!
        lowString = (externalData["low"] as? String)!
        ago = (externalData["ago"] as? String)!
        now = (externalData["now"] as? String)!
        openSpike = (externalData["openSpike"] as? String)!
        smoothLine = (externalData["smoothLine"] as? String)!
        showMarkers = (externalData["showMarkers"] as? String)!
        showMarkerLabel = (externalData["showMarkerLabel"] as? String)!
        showGridLines = (externalData["showGridLines"] as? String)!
        lineThickness = (externalData["lineThickness"] as? NSString)!
        markerRadius = (externalData["markerRadius"] as? NSString)!
        IOBString = (externalData["IOBString"] as? String)!
        COBString = (externalData["COBString"] as? String)!
        predictionsDuration = (externalData["predictionDuration"] as? String)!
        predictionsOutcome = (externalData["predictionOutcome"] as? String)!
        
        if (externalData["IOB"] != nil)
        {
            IOB = (externalData["IOB"] as? String)!
        }
        if (externalData["COB"] != nil)
        {
            COB = (externalData["COB"] as? String)!
        }
        
        return true
    }
    
    /**
     *  Set view background color and opacity
     */
    func setBackground()
    {
        //View Background
        let viewBackgroundColor:UIColor = UIColor.colorFromHex(hexString: backgroundColor)
        mainView.backgroundColor = viewBackgroundColor.withAlphaComponent(CGFloat((backgroundOpacity.floatValue)))
    }
    
    /**
     *  Populates display labels
     */
    func setLabels()
    {
        glucoseDisplay.text = latestGlucoseValue + " " + latestGlucoseSlopeArrow
        if screenWidth <= 320
        {
            glucoseDisplay.font = glucoseDisplay.font.withSize(40)
        }
        
        if glucoseUnitInternal == "mgdl"
        {
            if getTotalMinutes(latestTimestamp: Int64(latestGlucoseTime)!) >= 6
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: oldDataColor)
            }
            else if latestGlucoseValue == "LOW" || latestGlucoseValue == "??0" || latestGlucoseValue == "?SN" || latestGlucoseValue == "??2" || latestGlucoseValue == "?NA" || latestGlucoseValue == "?NC" || latestGlucoseValue == "?CD" || latestGlucoseValue == "?AD" || latestGlucoseValue == "?RF" || latestGlucoseValue == "???"
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgenLowColor)
                glucoseDisplay.text = lowString + " " + latestGlucoseSlopeArrow
            }
            else if latestGlucoseValue == "HIGH"
            {
                glucoseDisplay.text = highString + " " + latestGlucoseSlopeArrow
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgentHighColor)
            }
            else if let latestGlucoseValueInteger = Int(latestGlucoseValue), let urgentLowThresholdInteger = Int(urgenLowThreshold), latestGlucoseValueInteger <= urgentLowThresholdInteger
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgenLowColor)
            }
            else if let latestGlucoseValueInteger = Int(latestGlucoseValue), let urgentLowThresholdInteger = Int(urgenLowThreshold), let lowThresholdInteger = Int(lowThreshold), latestGlucoseValueInteger > urgentLowThresholdInteger && latestGlucoseValueInteger <= lowThresholdInteger
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: lowColor)
            }
            else if let latestGlucoseValueInteger = Int(latestGlucoseValue), let lowThresholdInteger = Int(lowThreshold), let highThresholdInteger = Int(highThreshold), latestGlucoseValueInteger > lowThresholdInteger && latestGlucoseValueInteger < highThresholdInteger
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: inRangeColor)
            }
            else if let latestGlucoseValueInteger = Int(latestGlucoseValue), let highThresholdInteger = Int(highThreshold), let urgentHighThresholdInteger = Int(urgentHighThreshold), latestGlucoseValueInteger >= highThresholdInteger && latestGlucoseValueInteger < urgentHighThresholdInteger
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: highColor)
            }
            else if let latestGlucoseValueInteger = Int(latestGlucoseValue), let urgentHighThresholdInteger = Int(urgentHighThreshold), latestGlucoseValueInteger >= urgentHighThresholdInteger
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgentHighColor)
            }
        }
        else
        {
            if getTotalMinutes(latestTimestamp: Int64(latestGlucoseTime)!) >= 6
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: oldDataColor)
            }
            else if latestGlucoseValue == "LOW" || latestGlucoseValue == "??0" || latestGlucoseValue == "?SN" || latestGlucoseValue == "??2" || latestGlucoseValue == "?NA" || latestGlucoseValue == "?NC" || latestGlucoseValue == "?CD" || latestGlucoseValue == "?AD" || latestGlucoseValue == "?RF" || latestGlucoseValue == "???"
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgenLowColor)
                glucoseDisplay.text = lowString + " " + latestGlucoseSlopeArrow
            }
            else if latestGlucoseValue == "HIGH"
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgentHighColor)
                glucoseDisplay.text = highString + " " + latestGlucoseSlopeArrow
            }
            else if let latestGlucoseValueFloat = Float(latestGlucoseValue), let urgentLowThresholdFloat = Float(urgenLowThreshold), latestGlucoseValueFloat <= urgentLowThresholdFloat
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgenLowColor)
            }
            else if let latestGlucoseValueFloat = Float(latestGlucoseValue), let urgentLowThresholdFloat = Float(urgenLowThreshold), let lowThresholdFloat = Float(lowThreshold), latestGlucoseValueFloat > urgentLowThresholdFloat && latestGlucoseValueFloat <= lowThresholdFloat
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: lowColor)
            }
            else if let latestGlucoseValueFloat = Float(latestGlucoseValue), let lowThresholdFloat = Float(lowThreshold), let highThresholdFloat = Float(highThreshold), latestGlucoseValueFloat > lowThresholdFloat && latestGlucoseValueFloat < highThresholdFloat
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: inRangeColor)
            }
            else if let latestGlucoseValueFloat = Float(latestGlucoseValue), let highThresholdFloat = Float(highThreshold), let urgentHighThresholdFloat = Float(urgentHighThreshold), latestGlucoseValueFloat >= highThresholdFloat && latestGlucoseValueFloat < urgentHighThresholdFloat
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: highColor)
            }
            else if let latestGlucoseValueFloat = Float(latestGlucoseValue), let urgentHighThresholdFloat = Float(urgentHighThreshold), latestGlucoseValueFloat >= urgentHighThresholdFloat
            {
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgentHighColor)
            }
        }
        
        timeDisplay.text = getTimeAgo(latestTimestamp: Int64(latestGlucoseTime)!, hourAgo: hourAgo, minAgo: minAgo, ago: ago, now: now)
        if getTotalMinutes(latestTimestamp: Int64(latestGlucoseTime)!) >= 6
        {
            timeDisplay.textColor = UIColor.colorFromHex(hexString: oldDataColor)
        }
        else
        {
            timeDisplay.textColor = UIColor.colorFromHex(hexString: displayLabelsColor)
        }
        deltaDisplay.text = latestGlucoseDelta + " " + glucoseUnit
        if getTotalMinutes(latestTimestamp: Int64(latestGlucoseTime)!) >= 6
        {
            deltaDisplay.textColor = UIColor.colorFromHex(hexString: oldDataColor)
        }
        else
        {
            deltaDisplay.textColor = UIColor.colorFromHex(hexString: displayLabelsColor)
        }
        lastUpdateDisplay.text = latestWidgetUpdate
        lastUpdateDisplay.textColor = UIColor.colorFromHex(hexString: displayLabelsColor)
        openApp.setTitle(openSpike, for: .normal)
        openApp.setTitleColor(UIColor.colorFromHex(hexString: displayLabelsColor), for: .normal)
        
        var predictValue:String = "";
        if (predictionsOutcome != "-1")
        {
            predictValue = "   " + predictionsDuration + ":" + predictionsOutcome
        }
        
        treatmentsLabel.text = COBString + ":" + COB + "   " + IOBString + ":" + IOB + predictValue
        treatmentsLabel.textColor = UIColor.colorFromHex(hexString: displayLabelsColor)
    }
    
    func parseChartData()->Bool
    {
        //Process Chart Data
        struct ChartData: Codable
        {
            var value: Double
            var time: String
        }
        
        do
        {
            chartGlucoseValues.removeAll()
            chartGlucoseTimes.removeAll()
            
            let decoder = JSONDecoder()
            let externalDataJSON = try decoder.decode([ChartData].self, from: externalDataEncoded)
            for (chartData) in externalDataJSON
            {
                chartGlucoseValues.append(chartData.value)
                chartGlucoseTimes.append(chartData.time)
            }
        }
        catch
        {
            print("Error parsing chart data! Error: \(error)")
            noData.text = "Error parsing chart data"
            return false
        }
        
        return true
    }
    
    /**
     *  Populates the chart
     */
    func setChart(chartSize:CGFloat)
    {
        if (chart != nil)
        {
            chart.removeFromSuperview()
        }
        
        if #available(iOSApplicationExtension 10.0, *)
        {
            chart = PNLineChart(frame: CGRect(x: 0, y: 0, width:chartSize, height: 178))
        }
        else
        {
            chart = PNLineChart(frame: CGRect(x: 0, y: 0, width:chartSize - 29, height: 178))
        }
        
        if glucoseUnit == "mmol/L"
        {
            chart.yLabelFormat = "%1.1f"
        }
        
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
        chart.axisColor = UIColor.colorFromHex(hexString: axisColor) //Both axis color
        chart.yGridLinesColor = UIColor.colorFromHex(hexString: gridLinesColor) //Horizontal Grid Lines Color
        chart.xLabelColor = UIColor.colorFromHex(hexString: axisFontColor) //X Axis Lower Labels Color
        chart.yLabelColor = UIColor.colorFromHex(hexString: axisFontColor) //X Axis Left Labels Color
        
        //Size
        chart.axisWidth = 0.5
        
        //Chart Data
        let data = PNLineChartData()
        //chart.xLabels = ["Sep 1", "Sep 2", "Sep 3", "Sep 4", "Sep 5", "Sep 6", "Sep 7", "Sep 7", "Sep 7", "Sep 7", "Sep 7", "Sep 7", "Sep 7"]
        //let dataArr = [40, 47, 55, 70, 80, 95, 110, 115, 130, 150, 170, 600, 40]
        //data.itemCount = UInt(dataArr.count)
        chart.xLabels = chartGlucoseTimes
        data.itemCount = UInt(chartGlucoseValues.count)
        
        //Data Color Ranges
        if glucoseUnitInternal == "mgdl"
        {
            let urgentLowThresholdStart = 1
            let urgentLowThresholdEnd = Int(urgenLowThreshold)! - 1
            let lowThresholdStart = Int(urgenLowThreshold)!
            let lowThresholdEnd = Int(lowThreshold)! - lowThresholdStart
            let inRangeThresholdStart = Int(lowThreshold)!
            let inRangeThresholdEnd = Int(highThreshold)! - inRangeThresholdStart
            let highThresholdStart = Int(highThreshold)!
            let highThresholdEnd = Int(urgentHighThreshold)! - highThresholdStart
            let urgentHighThresholdStart = Int(urgentHighThreshold)!
            let urgentHighThresholdEnd = 401 - urgentHighThresholdStart
            
            let urgentLowRange = NSMakeRange(urgentLowThresholdStart, urgentLowThresholdEnd)
            //print("urgentLowRange.lowerBound +\(urgentLowRange.lowerBound)")
            //print("urgentLowThresholdEnd +\(urgentLowThresholdEnd)")
            //print("urgentLowRange.upperBound +\(urgentLowRange.upperBound)")
            
            let lowRange = NSMakeRange(lowThresholdStart, lowThresholdEnd)
            //print("lowRange.lowerBound +\(lowRange.lowerBound)")
            //print("lowThresholdEnd +\(lowThresholdEnd)")
            //print("lowRange.upperBound +\(lowRange.upperBound)")
            
            let inRangeRange = NSMakeRange(inRangeThresholdStart, inRangeThresholdEnd)
            //print("inRangeRange.lowerBound +\(inRangeRange.lowerBound)")
            //print("inRangeThresholdEnd +\(inRangeThresholdEnd)")
            //print("inRangeRange.upperBound +\(inRangeRange.upperBound)")
            
            let highRange = NSMakeRange(highThresholdStart, highThresholdEnd)
            //print("highRange.lowerBound +\(highRange.lowerBound)")
            //print("highThresholdEnd +\(highThresholdEnd)")
            //print("highRange.upperBound +\(highRange.upperBound)")
            
            let urgentHighRange = NSMakeRange(urgentHighThresholdStart, urgentHighThresholdEnd)
            //print("urgentHighRange.lowerBound +\(urgentHighRange.lowerBound)")
            //print("urgentHighThresholdEnd +\(urgentHighThresholdEnd)")
            //print("urgentHighRange.upperBound +\(urgentHighRange.upperBound)")
            
            data.rangeColors = [
                PNLineChartColorRange(range: urgentLowRange, color: UIColor.colorFromHex(hexString: urgenLowColor), inclusive: true),
                PNLineChartColorRange(range: lowRange, color: UIColor.colorFromHex(hexString: lowColor), inclusive: true),
                PNLineChartColorRange(range: inRangeRange, color: UIColor.colorFromHex(hexString: inRangeColor), inclusive: true),
                PNLineChartColorRange(range: highRange, color: UIColor.colorFromHex(hexString: highColor), inclusive: true),
                PNLineChartColorRange(range: urgentHighRange, color: UIColor.colorFromHex(hexString: urgentHighColor), inclusive: true)
            ]
        }
        
        if glucoseUnitInternal == "mgdl"
        {
            data.color = UIColor.colorFromHex(hexString: inRangeColor)
        }
        else
        {
            data.color = UIColor.colorFromHex(hexString: mainLineColor)
        }
        
        //Data Settings
        if showMarkers == "true"
        {
            data.inflexionPointStyle = .circle
        }
        else
        {
            data.inflexionPointStyle = .none
        }
        data.inflexionPointWidth = CGFloat((markerRadius.floatValue))
        data.inflexionPointColor = UIColor.colorFromHex(hexString: markerColor)
        data.lineWidth = CGFloat((lineThickness.floatValue))
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
        
        
        chart.removeFromSuperview()
        
        chartView?.addSubview(chart)
    }
    
    /**
     *  Gets the amount of minutes since last glucose reading
     */
    func getTotalMinutes (latestTimestamp:Int64) -> Int
    {
        let nowTimestamp = Date().toTimestamp()
        let differenceInMills = nowTimestamp! - latestTimestamp
        
        return Int(Int(differenceInMills) / millisecondsInMinute)
    }
    
    /**
     *  Gets the the formatted time for display label since the last glucose reading
     */
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
    
    /**
     *  Controls the Show More / Show Less Functionality
     */
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = maxSize
        } else if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 300)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if let superview = view.superview
        {
            if (parseChartData())
            {
                setChart(chartSize: superview.frame.size.width + 10)
                setChart(chartSize: superview.frame.size.width + 10)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        
        if (parseChartData())
        {
            setChart(chartSize: size.width + 10)
            setChart(chartSize: size.width + 10)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     *  Called periodicaly by iOS to update the widget
     */
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void))
    {
        /*let currentData = externalData
        if getExternalData()
        {
            if NSDictionary(dictionary: currentData).isEqual(to: externalData)
            {
                completionHandler(NCUpdateResult.noData)
            }
            else
            {
                if populateProperties()
                {
                    setBackground()
                    setLabels()
                    if #available(iOSApplicationExtension 10.0, *)
                    {
                        if parseChartData()
                        {
                            setChart()
                        }
                    }
                }
                completionHandler(NCUpdateResult.newData)
            }
        }*/
    }
}

/**
 *  Extension to get timestamp from date
 */
extension Date
{
    func toTimestamp() -> Int64!
    {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
