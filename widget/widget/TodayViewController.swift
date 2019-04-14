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
import SwiftyJSON

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
    var globalChartSize:CGFloat?
    var offlineTask:DispatchWorkItem?
    var dynamicAppGroup:String = ""
    var chart:PNLineChart! = nil
    var chartGlucoseValues = [Double]()
    var chartGlucoseTimes = [String]()
    var fileUrl:URL?
    var externalData:[String : AnyObject] = [:]
    var externalDataJSON:JSON?
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
        
        noData.text = ""
        
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
        
        //Get App Groups address directly from the mobile provisioning file.
        if let provision = MobileProvision.read()
        {
            dynamicAppGroup = provision.entitlements.appGroups[0]
            
            if (dynamicAppGroup.isEmpty)
            {
                mainView.backgroundColor = UIColor.colorFromHex(hexString: "#000000").withAlphaComponent(0.7)
            }
        }
        else
        {
           mainView.backgroundColor = UIColor.colorFromHex(hexString: "#000000").withAlphaComponent(0.7)
        }
        
        if getExternalData()
        {
            if populateProperties()
            {
                setBackground()
                setLabels()
            }
        }
    }
    
    /**
     *  Loads UsersDefaults External Data
     */
    func getExternalData()->Bool
    {
        var success: Bool = false
        
        if (!dynamicAppGroup.isEmpty)
        {
            //Define database file path
            fileUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: dynamicAppGroup)!.appendingPathComponent("Library/Preferences/" + dynamicAppGroup + ".plist")
            
            //Check if file exists
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: fileUrl!.path)
            {
                print("Database file doesn't exist!")
                
                noData.text = "Can't connect to Spike!"
                return false
            }
            
            //Parse database file into a dictionary
            externalData = (NSDictionary(contentsOfFile: fileUrl!.path) as? [String: AnyObject])!;
            
            success = true
        }
        else
        {
            let urlPath: String = "http://127.0.0.1:1979/spikewidget"
            
            guard let url = URL(string: urlPath) else
            {
                print ("URL Parsing Error")
                noData.text = "No Data!"
                return false
            }
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil else {
                    print(error!)
                    self.noData.text = "No Data!"
                    success = false;
                    
                    return
                }
                guard let data = data else {
                    print("Data is empty")
                    self.noData.text = "No Data!"
                    success = false;
                    
                    return
                }
                
                DispatchQueue.main.sync()
                {
                    print("Got response from server!")
                        
                    self.externalDataJSON = try! JSON(data: data)
                    success = true;
                        
                    if self.populateProperties()
                    {
                        self.setBackground()
                        self.setLabels()
                        
                        if #available(iOSApplicationExtension 10.0, *)
                        {
                            if self.parseChartData()
                            {
                                if (self.globalChartSize == nil)
                                {
                                    self.globalChartSize = self.view.frame.size.width + 10
                                }
                                
                                self.setChart(chartSize: self.globalChartSize!)
                            }
                        }
                    }
                } //end dispatch
            } //end urlsession
            
            task.resume()
        }
        
        return success
    }
    
    func populateProperties()->Bool
    {
        if (!dynamicAppGroup.isEmpty)
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
        }
        else
        {
            if  externalDataJSON?["latestWidgetUpdate"].string == nil ||
                externalDataJSON?["latestGlucoseValue"].string == nil ||
                externalDataJSON?["latestGlucoseSlopeArrow"].string == nil ||
                externalDataJSON?["latestGlucoseDelta"].string == nil ||
                externalDataJSON?["latestGlucoseTime"].string == nil ||
                externalDataJSON?["glucoseUnit"].string == nil ||
                externalDataJSON?["glucoseUnitInternal"].string == nil ||
                externalDataJSON?["chartData"].string == nil ||
                externalDataJSON?["urgenLowThreshold"].string == nil ||
                externalDataJSON?["lowThreshold"].string == nil ||
                externalDataJSON?["highThreshold"].string == nil ||
                externalDataJSON?["urgentHighThreshold"].string == nil ||
                externalDataJSON?["urgenLowColor"].string == nil ||
                externalDataJSON?["lowColor"].string == nil ||
                externalDataJSON?["inRangeColor"].string == nil ||
                externalDataJSON?["highColor"].string == nil ||
                externalDataJSON?["urgentHighColor"].string == nil ||
                externalDataJSON?["oldDataColor"].string == nil ||
                externalDataJSON?["markerColor"].string == nil ||
                externalDataJSON?["axisColor"].string == nil ||
                externalDataJSON?["axisFontColor"].string == nil ||
                externalDataJSON?["gridLinesColor"].string == nil ||
                externalDataJSON?["mainLineColor"].string == nil ||
                externalDataJSON?["backgroundColor"].string == nil ||
                externalDataJSON?["backgroundOpacity"].string == nil ||
                externalDataJSON?["displayLabelsColor"].string == nil ||
                externalDataJSON?["hourAgo"].string == nil ||
                externalDataJSON?["minAgo"].string == nil ||
                externalDataJSON?["ago"].string == nil ||
                externalDataJSON?["now"].string == nil ||
                externalDataJSON?["openSpike"].string == nil ||
                externalDataJSON?["smoothLine"].string == nil ||
                externalDataJSON?["showMarkers"].string == nil ||
                externalDataJSON?["showMarkerLabel"].string == nil ||
                externalDataJSON?["showGridLines"].string == nil ||
                externalDataJSON?["lineThickness"].string == nil ||
                externalDataJSON?["markerRadius"].string == nil ||
                externalDataJSON?["high"].string == nil ||
                externalDataJSON?["low"].string == nil ||
                externalDataJSON?["IOBString"].string == nil ||
                externalDataJSON?["COBString"].string == nil ||
                externalDataJSON?["predictionDuration"].string == nil ||
                externalDataJSON?["predictionOutcome"].string == nil
            {
                print("Missing data in database!")
                noData.text = "Missing data in database!"
                return false
            }
            
            //Get properties
            latestWidgetUpdate = (externalDataJSON?["latestWidgetUpdate"].string)!
            latestGlucoseValue = (externalDataJSON?["latestGlucoseValue"].string)!
            latestGlucoseSlopeArrow = (externalDataJSON?["latestGlucoseSlopeArrow"].string)!
            latestGlucoseDelta = (externalDataJSON?["latestGlucoseDelta"].string)!
            latestGlucoseTime = (externalDataJSON?["latestGlucoseTime"].string)!
            glucoseUnit = (externalDataJSON?["glucoseUnit"].string)!
            glucoseUnitInternal = (externalDataJSON?["glucoseUnitInternal"].string)!
            chartData = (externalDataJSON?["chartData"].string)!
            externalDataEncoded = chartData.data(using: String.Encoding.utf8, allowLossyConversion: false)!
            urgenLowThreshold = (externalDataJSON?["urgenLowThreshold"].string)!
            lowThreshold = (externalDataJSON?["lowThreshold"].string)!
            highThreshold = (externalDataJSON?["highThreshold"].string)!
            urgentHighThreshold = (externalDataJSON?["urgentHighThreshold"].string)!
            urgenLowColor = (externalDataJSON?["urgenLowColor"].string)!
            lowColor = (externalDataJSON?["lowColor"].string)!
            inRangeColor = (externalDataJSON?["inRangeColor"].string)!
            highColor = (externalDataJSON?["highColor"].string)!
            urgentHighColor = (externalDataJSON?["urgentHighColor"].string)!
            oldDataColor = (externalDataJSON?["oldDataColor"].string)!
            markerColor = (externalDataJSON?["markerColor"].string)!
            axisColor = (externalDataJSON?["axisColor"].string)!
            axisFontColor = (externalDataJSON?["axisFontColor"].string)!
            gridLinesColor = (externalDataJSON?["gridLinesColor"].string)!
            mainLineColor = (externalDataJSON?["mainLineColor"].string)!
            backgroundColor = (externalDataJSON?["backgroundColor"].string)!
            backgroundOpacity = (externalDataJSON?["backgroundOpacity"].string)! as NSString
            displayLabelsColor = (externalDataJSON?["displayLabelsColor"].string)!
            hourAgo = (externalDataJSON?["hourAgo"].string)!
            minAgo = (externalDataJSON?["minAgo"].string)!
            highString = (externalDataJSON?["high"].string)!
            lowString = (externalDataJSON?["low"].string)!
            ago = (externalDataJSON?["ago"].string)!
            now = (externalDataJSON?["now"].string)!
            openSpike = (externalDataJSON?["openSpike"].string)!
            smoothLine = (externalDataJSON?["smoothLine"].string)!
            showMarkers = (externalDataJSON?["showMarkers"].string)!
            showMarkerLabel = (externalDataJSON?["showMarkerLabel"].string)!
            showGridLines = (externalDataJSON?["showGridLines"].string)!
            lineThickness = (externalDataJSON?["lineThickness"].string)! as NSString
            markerRadius = (externalDataJSON?["markerRadius"].string)! as NSString
            IOBString = (externalDataJSON?["IOBString"].string)!
            COBString = (externalDataJSON?["COBString"].string)!
            predictionsDuration = (externalDataJSON?["predictionDuration"].string)!
            predictionsOutcome = (externalDataJSON?["predictionOutcome"].string)!
            
            if (externalDataJSON?["IOB"].string != nil)
            {
                IOB = (externalDataJSON?["IOB"].string)!
            }
            if (externalDataJSON?["COB"].string != nil)
            {
                COB = (externalDataJSON?["COB"].string)!
            }

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
            
            if (chartGlucoseValues.count > 0)
            {
                noData.text = ""
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
            globalChartSize = superview.frame.size.width + 10
            
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
        
        globalChartSize = size.width + 10
        
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
        //Do nothing
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

struct MobileProvision: Decodable {
    var entitlements: Entitlements
    
    private enum CodingKeys : String, CodingKey {
        case entitlements = "Entitlements"
    }
    
    // Sublevel: decode entitlements informations
    struct Entitlements: Decodable {
        let appGroups: [String]
        
        private enum CodingKeys: String, CodingKey {
            case appGroups = "com.apple.security.application-groups"
        }
        
        init(appGroups: Array<String>) {
            self.appGroups = appGroups
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let appGroups: [String] = (try? container.decode([String].self, forKey: .appGroups)) ?? []
            
            self.init(appGroups: appGroups)
        }
    }
}

extension MobileProvision {
    // Read mobileprovision file embedded in app.
    static func read() -> MobileProvision? {
        let profilePath: String? = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision")
        guard let path = profilePath else { return nil }
        return read(from: path)
    }
    
    // Read a .mobileprovision file on disk
    static func read(from profilePath: String) -> MobileProvision? {
        guard let plistDataString = try? NSString.init(contentsOfFile: profilePath,
                                                       encoding: String.Encoding.isoLatin1.rawValue) else { return nil }
        
        // Skip binary part at the start of the mobile provisionning profile
        let scanner = Scanner(string: plistDataString as String)
        guard scanner.scanUpTo("<plist", into: nil) != false else { return nil }
        
        // ... and extract plist until end of plist payload (skip the end binary part.
        var extractedPlist: NSString?
        guard scanner.scanUpTo("</plist>", into: &extractedPlist) != false else { return nil }
        
        guard let plist = extractedPlist?.appending("</plist>").data(using: .isoLatin1) else { return nil }
        let decoder = PropertyListDecoder()
        do {
            let provision = try decoder.decode(MobileProvision.self, from: plist)
            return provision
        } catch {
            // TODO: log / handle error
            return nil
        }
    }
}

class chartDataValue
{
    var value: Double
    var time: String
    var timestamp: Int
    
    init(value: Double, time: String, timestamp: Int)
    {
        self.value = value
        self.time = time
        self.timestamp = timestamp
    }
}
