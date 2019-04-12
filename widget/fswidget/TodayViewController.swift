//
//  TodayViewController.swift
//  Widget
//
//  Created by Miguel Kennedy on 05/02/2018.
//  Copyright © 2018 Spike. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding
{
    //IBOutlet
    @IBOutlet var mainView: UIView!
    @IBOutlet var glucoseDisplay: UILabel!
    @IBOutlet var timeDisplay: UILabel!
    @IBOutlet var deltaDisplay: UILabel!
    @IBOutlet var lastUpdateDisplay: UILabel!
    @IBOutlet var openApp: UIButton!
    @IBOutlet var noData: UILabel!
    @IBOutlet var treatmentsLabel: UILabel!
    @IBOutlet var treatmentsConstrain: NSLayoutConstraint!
    @IBOutlet var predictionsLabel: UILabel!
    
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
    var dynamicAppGroup:String = ""
    var chartGlucoseValues = [Double]()
    var chartGlucoseTimes = [String]()
    var fileUrl:URL?
    var externalData:[String : AnyObject] = [:]
    var latestWidgetUpdate:String = ""
    var latestGlucoseValue:String = ""
    var latestGlucoseSlopeArrow:String = ""
    var latestGlucoseDelta:String = ""
    var latestGlucoseTime:String = ""
    var glucoseUnit:String = ""
    var glucoseUnitInternal:String = ""
    var externalDataEncoded:Data = Data()
    var urgenLowThreshold:String = ""
    var lowThreshold:String = ""
    var highThreshold:String = ""
    var urgentHighThreshold:String = ""
    var highString:String = ""
    var lowString:String = ""
    var urgenLowColor:String = ""
    var lowColor:String = ""
    var inRangeColor:String = ""
    var highColor:String = ""
    var urgentHighColor:String = ""
    var oldDataColor:String = ""
    var backgroundColor:String = ""
    var backgroundOpacity:NSString = ""
    var displayLabelsColor:String = ""
    var hourAgo:String = ""
    var minAgo:String = ""
    var ago:String = ""
    var now:String = ""
    var openSpike:String = ""
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
        if #available(iOSApplicationExtension 10.0, *)
        {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
        else
        {
            self.preferredContentSize = CGSize(width: mainView.frame.size.width, height: 300)
        }
        
        glucoseDisplay.adjustsFontSizeToFitWidth = true
        glucoseDisplay.numberOfLines = 0
        glucoseDisplay.minimumScaleFactor = 0.1
        glucoseDisplay.baselineAdjustment = .alignCenters
        glucoseDisplay.textAlignment = .center
        
        
        //Get App Groups address directly from the mobile provisioning file.
        if let provision = MobileProvision.read()
        {
            dynamicAppGroup = provision.entitlements.appGroups[0]
            
            if (!dynamicAppGroup.isEmpty)
            {
                //Populate Widget
                if getExternalData()
                {
                    if populateProperties()
                    {
                        setBackground()
                        setLabels()
                    }
                }
            }
            else
            {
                noData.text = "Can't connect to Spike. Not enough permissions!"
            }
        }
        else
        {
            noData.text = "Can't connect to Spike. Not enough permissions!"
        }
    }
    
    /**
     *  Loads UsersDefaults External Data
     */
    func getExternalData()->Bool
    {
        if (dynamicAppGroup.isEmpty)
        {
            print("Can't connect to Spike. Not enough permissions!")
            
            noData.text = "Can't connect to Spike. Not enough permissions!"
            return false
        }
        
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
            externalData["backgroundColor"] == nil ||
            externalData["backgroundOpacity"] == nil ||
            externalData["displayLabelsColor"] == nil ||
            externalData["hourAgo"] == nil ||
            externalData["minAgo"] == nil ||
            externalData["ago"] == nil ||
            externalData["now"] == nil ||
            externalData["openSpike"] == nil ||
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
        backgroundColor = (externalData["backgroundColor"] as? String)!
        backgroundOpacity = (externalData["backgroundOpacity"] as? NSString)!
        displayLabelsColor = (externalData["displayLabelsColor"] as? String)!
        hourAgo = (externalData["hourAgo"] as? String)!
        minAgo = (externalData["minAgo"] as? String)!
        ago = (externalData["ago"] as? String)!
        now = (externalData["now"] as? String)!
        openSpike = (externalData["openSpike"] as? String)!
        highString = (externalData["high"] as? String)!
        lowString = (externalData["low"] as? String)!
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
                glucoseDisplay.textColor = UIColor.colorFromHex(hexString: urgentHighColor)
                glucoseDisplay.text = highString + " " + latestGlucoseSlopeArrow
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
        
        treatmentsLabel.text = COBString + ":" + COB + "   " + IOBString + ":" + IOB
        treatmentsLabel.textColor = UIColor.colorFromHex(hexString: displayLabelsColor)
        
        if phone.isSmallScreen
        {
            treatmentsConstrain.constant = 39
            mainView.layoutIfNeeded()
            treatmentsLabel.font = treatmentsLabel.font.withSize(14)
        }
        
        var predictValue:String = "";
        if (predictionsOutcome != "-1")
        {
            predictValue = predictionsDuration + ": " + predictionsOutcome
        }
        
        predictionsLabel.text = predictValue
        predictionsLabel.textColor = UIColor.colorFromHex(hexString: displayLabelsColor)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     *  Called periodicaly by iOS to update the widget
     */
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void))
    {
        let currentData = externalData
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
                }
                completionHandler(NCUpdateResult.newData)
            }
        }
    }
}

public struct phone {
    
    public static var screenWidth: CGFloat
    {
        return UIScreen.main.bounds.width
    }
    
    public static var isSmallScreen: Bool
    {
        return screenWidth == 320
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
