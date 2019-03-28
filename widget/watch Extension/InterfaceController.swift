//  Created by Kenneth Stack on 7/9/15.
//  Modified and adapted for Spike by Miguel Kennedy on 23/4/2018
//  Copyright (c) 2015 Perceptus.org, Spike app. All rights reserved.

import WatchKit
import Foundation

//Global variables
var urlUser : String = "http://127.0.0.1:1979"
var mmol : Bool = false
var fullScreenMode : Bool = false
var urgentHighThreshold : Int = 180
var highThreshold : Int = 140
var lowThreshold : Int = 80
var urgentLowThreshold : Int = 60
var urgenLowColor:String = ""
var lowColor:String = ""
var inRangeColor:String = ""
var highColor:String = ""
var urgentHighColor:String = ""
var predictionsDuration:String = ""
var predictionsOutcome:String = ""
var glucoseVelocity:String = ""
var offlineTask:DispatchWorkItem?
let chartEmpty42 = #imageLiteral(resourceName: "chart-empty-42")
let chartEmpty38 = #imageLiteral(resourceName: "chart-empty-38")

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

public extension WKInterfaceImage {
    
    public func setImageWithUrl(_ url:String) -> WKInterfaceImage?
    {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            if let url = URL(string: url)
            {
                if let data = try? Data(contentsOf: url) // may return nil, too
                {
                    let placeholder = UIImage(data: data)!
                    DispatchQueue.main.async {
                        self.setImage(placeholder)
                    }
                }
            }
        }
        
        return self
    }
}

public struct watch {
    
    public static var screenWidth: CGFloat
    {
        return WKInterfaceDevice.current().screenBounds.width
    }
    
    public static var is38: Bool
    {
        return screenWidth == 136
    }
    
    public static var is42: Bool
    {
        return screenWidth == 156
    }
}

class InterfaceController: WKInterfaceController
{
    //IBOutlets
    @IBOutlet weak var bgimage: WKInterfaceImage!
    @IBOutlet weak var primarybg: WKInterfaceLabel!
    @IBOutlet weak var bgdirection: WKInterfaceLabel!
    @IBOutlet weak var deltabg: WKInterfaceLabel!
    @IBOutlet weak var battery: WKInterfaceLabel!
    @IBOutlet weak var minago: WKInterfaceLabel!
    @IBOutlet weak var graphhours: WKInterfaceLabel!
    @IBOutlet weak var hourslider: WKInterfaceSlider!
    @IBOutlet weak var plabel: WKInterfaceLabel!
    @IBOutlet weak var vlabel: WKInterfaceLabel!
    @IBOutlet weak var secondarybgname: WKInterfaceLabel!
    @IBOutlet var loadingicon: WKInterfaceImage!
    @IBOutlet var pumpstatus3: WKInterfaceLabel!
    @IBOutlet var pumpstatus2: WKInterfaceLabel!
    @IBOutlet var pumpstatus: WKInterfaceLabel!
    @IBOutlet var pLabelHolder: WKInterfaceLabel!
    @IBOutlet var vLabelHolder: WKInterfaceLabel!
    
    //Internal Variables
    var graphlength:Int=3
    var bghistread=true as Bool
    var bghist=[] as?  [[String:AnyObject]]
    var responseDict=[:] as [String:AnyObject]
    var cals=[] as? [[String:AnyObject]]
    var craw=true as Bool
    
    @IBAction func onFullScreenTap()
    {
        self.pushController(withName: "FSInterfaceController", context: nil)
    }
    @IBAction func hourslidervalue(_ value: Float)
    {
        let slidermap:[Int:Int]=[1:24,2:12,3:6,4:3,5:1]
        let slidervalue=Int(round(value*1000)/1000)
        graphlength=slidermap[slidervalue]!
        willActivate()
    }
    
    override func willActivate()
    {
        // This method is called when watch view controller is about to be visible to user
        self.vlabel.setTextColor(UIColor.gray)
        self.vlabel.setText("")
        super.willActivate()
        updateData()
    }
    
    override func didDeactivate()
    {
        // This method is called when watch view controller is no longer visible
        // Set all labels to gray. This will indicate that the data shown when the app is activated again is outdated
        let gray=UIColor.gray as UIColor
        self.primarybg.setTextColor(gray)
        self.bgdirection.setTextColor(gray)
        self.plabel.setTextColor(gray)
        self.pLabelHolder.setTextColor(gray)
        self.vlabel.setTextColor(gray)
        self.vLabelHolder.setTextColor(gray)
        self.minago.setTextColor(gray)
        self.deltabg.setTextColor(gray)
        self.pumpstatus.setTextColor(gray)
        self.pumpstatus2.setTextColor(gray)
        self.pumpstatus3.setTextColor(gray)
        self.graphhours.setTextColor(gray)
        super.didDeactivate()
    }
    
    func spikeOffline()
    {
        self.primarybg.setText("")
        self.vlabel.setTextColor(UIColor.red)
        self.vlabel.setText("Spike is offline!")
    }
    
    func updateData()
    {
        print("In updateData")
        
        //set bg color to show the user that the data being displayed is outdated and about to be updated
        let gray=UIColor.gray as UIColor
        let white=UIColor.white as UIColor
        self.primarybg.setTextColor(gray)
        self.bgdirection.setTextColor(gray)
        self.plabel.setTextColor(gray)
        self.pLabelHolder.setTextColor(gray)
        self.vlabel.setTextColor(gray)
        self.vlabel.setText("0")
        self.vLabelHolder.setTextColor(gray)
        self.minago.setTextColor(gray)
        self.deltabg.setTextColor(gray)
        self.pumpstatus.setTextColor(gray)
        self.pumpstatus2.setTextColor(gray)
        self.pumpstatus3.setTextColor(gray)
        self.graphhours.setTextColor(gray)
        
        //Define URL and perform connection. startoffset is changed based on how many hours are to be displayed on the graph
        let urlPath: String = urlUser + "/spikewatch?count=350&startoffset=" + String(graphlength * 60 * 60 * 1000)

        guard let url = URL(string: urlPath) else
        {
            print ("URL Parsing Error")
            self.displayError(error: "URL ERROR!")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                print(error!)
                
                offlineTask = DispatchWorkItem { self.spikeOffline() }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 8, execute: offlineTask!)
                
                return
            }
            guard let data = data else {
                print("Data is empty")
                self.displayError(error: "No Data!")
                return
            }
            
            DispatchQueue.main.async()
            {
                let entries = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String:AnyObject]]

                //Successfully received endpoint data from Spike
                if entries.count > 0
                {
                    //Apply settings... They with the first reading to avoid multiple connections to the server
                    print("Applying settings")
                    var units : String = ""
                    if entries[0]["unit"] != nil { units = entries[0]["unit"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["urgent_high_threshold"] != nil { urgentHighThreshold = entries[0]["urgent_high_threshold"] as! Int }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["high_threshold"] != nil { highThreshold = entries[0]["high_threshold"] as! Int }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["low_threshold"] != nil { lowThreshold = entries[0]["low_threshold"] as! Int }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["urgent_low_threshold"] != nil { urgentLowThreshold = entries[0]["urgent_low_threshold"] as! Int }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["urgent_high_color"] != nil { urgentHighColor = entries[0]["urgent_high_color"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["high_color"] != nil { highColor = entries[0]["high_color"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["in_range_color"] != nil { inRangeColor = entries[0]["in_range_color"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["low_color"] != nil { lowColor = entries[0]["low_color"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if entries[0]["urgent_low_color"] != nil { urgenLowColor = entries[0]["urgent_low_color"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    if (units  == "mmol") { mmol = true } else { mmol = false }
                    
                    //Apply IOB, COB, etc...
                    print("Applying stats")
                    var statusOne:String = ""
                    if entries[0]["status_one"] != nil { statusOne = entries[0]["status_one"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    self.pumpstatus.setText(statusOne)
                    self.pumpstatus.setTextColor(UIColor.white)
                    var statusTwo:String = ""
                    if entries[0]["status_two"] != nil { statusTwo = entries[0]["status_two"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    self.pumpstatus2.setText(statusTwo)
                    self.pumpstatus2.setTextColor(UIColor.white)
                    var statusThree:String = ""
                    if entries[0]["status_three"] != nil { statusThree = entries[0]["status_three"] as! String }
                    else
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    
                    //Cancel any previous offline delayed actions
                    offlineTask?.cancel()
                    
                    self.pumpstatus3.setText(statusThree)
                    self.pumpstatus3.setTextColor(UIColor.white)
                    
                    //Process glucose...
                    print("Processing glucose")
                    self.bghistread=true
                    let slope=0.0 as Double
                    let intercept=0.0 as Double
                    let scale=0.0 as Double
                    if entries[0]["sgv"] == nil
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    let cbg=entries[0]["sgv"] as! Int
                    let priorbg = entries[1]["sgv"] as! Int
                    if entries[0]["direction"] == nil
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    let direction=entries[0]["direction"] as! String
                    let dbg = cbg - priorbg as Int
                    if entries[0]["date"] == nil
                    {
                        self.displayError(error: "Data Missing!")
                        return
                    }
                    
                    if entries[0]["predictions_duration"] != nil
                    {
                        predictionsDuration = entries[0]["predictions_duration"] as! String
                    }
                    else
                    {
                        predictionsDuration = ""
                    }
                    
                    if entries[0]["predictions_outcome"] != nil
                    {
                        predictionsOutcome = entries[0]["predictions_outcome"] as! String
                    }
                    else
                    {
                        predictionsOutcome = ""
                    }
                    
                    if entries[0]["glucose_velocity"] != nil
                    {
                        glucoseVelocity = entries[0]["glucose_velocity"] as! String
                    }
                    else
                    {
                        glucoseVelocity = ""
                    }
                    
                    self.vlabel.setText("")
                    let bgtime=entries[0]["date"] as! TimeInterval
                    let red=UIColor.red as UIColor
                    self.bghist=entries
                    let bgs = entries
                    
                    //Set labels to white before updating data
                    self.plabel.setTextColor(white)
                    self.pLabelHolder.setTextColor(white)
                    self.vlabel.setTextColor(white)
                    self.vLabelHolder.setTextColor(white)
                    self.deltabg.setTextColor(white)
                    self.minago.setTextColor(UIColor.white)
                    
                    let ct=TimeInterval(Date().timeIntervalSince1970)
                    let deltat=(ct-bgtime/1000)/60
                    if deltat >= 15 { self.minago.setTextColor(UIColor.red) }
                    self.minago.setText(String(Int(deltat))+" min ago")
                    
                    if (cbg<40)
                    {
                        //Case where glucose is lower than 40mg/dL
                        self.primarybg.setTextColor(red)
                        self.primarybg.setText("LOW")
                        self.bgdirection.setText("")
                        self.deltabg.setText("")
                    }
                    else if (cbg>400)
                    {
                        //Case where glucose is higher than 400mg/dL
                        self.primarybg.setTextColor(red)
                        self.primarybg.setText("HIGH")
                        self.bgdirection.setText("")
                        self.deltabg.setText("")
                    }
                    else
                    {
                        self.primarybg.setTextColor(self.bgcolor(cbg))
                        self.bgdirection.setText(self.dirgraphics(direction))
                        self.bgdirection.setTextColor(self.bgcolor(cbg))
                        self.deltabg.setTextColor(UIColor.white)
                        
                        if (glucoseVelocity == "" || predictionsOutcome == "" || predictionsDuration == "")
                        {
                            let velocity=self.velocity_cf(bgs, slope: slope,intercept: intercept,scale: scale) as Double
                            let prediction=velocity*30.0+Double(cbg)
                            
                            if (mmol == false)
                            {
                                self.vlabel.setText(String(format:"%.1f", velocity))
                                self.plabel.setText(String(format:"%.0f", prediction))
                                self.pLabelHolder.setText("30 Min Predict")
                            }
                            else
                            {
                                let conv = 18.0182 as Double
                                self.vlabel.setText(String(format:"%.1f", velocity/conv))
                                self.plabel.setText(String(format:"%.1f", prediction/conv))
                                self.pLabelHolder.setText("30 Min Predict")
                            }
                        }
                        else
                        {
                            self.vlabel.setText(glucoseVelocity)
                            self.plabel.setText(predictionsOutcome)
                            self.pLabelHolder.setText(predictionsDuration + " Min Predict")
                        }
                        
                        if (mmol == false)
                        {
                            self.primarybg.setText(String(cbg))
                            if (dbg<0) {self.deltabg.setText(String(dbg)+" mg/dL")} else {self.deltabg.setText("+"+String(dbg)+" mg/dL")}
                        }
                        else
                        {
                            let conv = 18.0182 as Double
                            let mmolbg = Double(cbg) / conv
                            let mmoltext = String(format:"%.1f", mmolbg)
                            self.primarybg.setText(mmoltext)
                            let deltammol = Double(dbg) / conv
                            let delmmoltext = String(format:"%.1f", deltammol)
                            if (dbg<0) {self.deltabg.setText(delmmoltext + " mmol/L")} else {self.deltabg.setText("+" + delmmoltext + " mmol/L")}
                        }
                    }
                }
                else
                {
                    self.displayError(error: "Error loading data!")
                    self.bghistread=false
                    return
                }
                
                //add graph
                let google=self.bggraph(self.graphlength,bghist: self.bghist!)!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                if (self.bghistread==true)&&(google != "NoData")
                {
                    self.graphhours.setTextColor(UIColor.white)
                    var suffix:String = ""
                    if (self.graphlength > 1) { suffix = " Hours" } else { suffix = " Hour" }
                    self.graphhours.setText("Last " + String(self.graphlength) + suffix)
                    self.bgimage.setHidden(false)
                    let imgURL: URL = URL(string: google)! as URL
                    let task2 = URLSession.shared.dataTask(with: imgURL) { data, response, error in
                        guard error == nil else
                        {
                            if watch.is38 { self.bgimage.setImage(chartEmpty38) }
                            else { self.bgimage.setImage(chartEmpty42) }
                            self.graphhours.setTextColor(UIColor.red)
                            self.graphhours.setText("No Chart Data")
                            return
                        }
                        
                        guard let data = data else
                        {
                            if watch.is38 { self.bgimage.setImage(chartEmpty38) }
                            else { self.bgimage.setImage(chartEmpty42) }
                            self.graphhours.setTextColor(UIColor.red)
                            self.graphhours.setText("Google API Error")
                            return
                        }
                        
                        print("Setting graph image")
                        self.bgimage.setImageData(data)
                    }
                    task2.resume()
                }
            } //end dispatch
        } //end urlsession
        
        task.resume()
    }
    
    func velocity_cf(_ bgs:[[String:AnyObject]],slope:Double,intercept:Double,scale:Double)->Double
    {
        //linear fit to 3 data points get slope (ie velocity)
        var v=0 as Double
        var n=0 as Int
        var i=0 as Int
        let ONE_MINUTE=60000.0 as Double
        var bgsgv = [Double](repeating: 0.0, count: 4)
        var date = [Double](repeating: 0.0, count: 4)
        
        i=0
        while i<4
        {
            date[i]=(bgs[i]["date"] as? Double)!
            bgsgv[i]=(bgs[i]["sgv"])!.doubleValue
            i=i+1
            
        }
        if ((date[0]-date[3])/ONE_MINUTE < 15.1) {n=4}
        else
            if ((date[0]-date[2])/ONE_MINUTE < 10.1) {n=3}
            else
                if ((date[0]-date[1])/ONE_MINUTE<10.1) {n=2}
                else {n=0}
        
        var xm=0.0 as Double
        var ym=0.0 as Double
        if (n>0)
        {
            var j=0;
            while j<n
            {
                xm = xm + date[j] / ONE_MINUTE
                ym = ym + bgsgv[j]
                j=j+1
            }
            
            xm=xm/Double(n)
            ym=ym/Double(n)
            var c1=0.0 as Double
            var c2=0.0 as Double
            var t=0.0 as Double
            j=0
            
            while (j<n)
            {
                
                t=date[j]/ONE_MINUTE
                c1=c1+(t-xm)*(bgsgv[j]-ym)
                c2=c2+(t-xm)*(t-xm)
                j=j+1
            }
            
            v=c1/c2
        }
        else
        {
            //Need to decide what to return if there isnt enough data
            v=0
        }
        
        return v
    }
    
    func bgcolor(_ value:Int)->UIColor
    {
        var sgvcolor=UIColor.colorFromHex(hexString: inRangeColor)
        
        if (value < urgentLowThreshold)
        {
            sgvcolor=UIColor.colorFromHex(hexString: urgenLowColor)
        }
        else
            if(value < lowThreshold)
            {
                sgvcolor=UIColor.colorFromHex(hexString: lowColor)
            }
            else
                if (value < highThreshold)
                {
                    sgvcolor=UIColor.colorFromHex(hexString: inRangeColor)
                }
                else
                    if (value < urgentHighThreshold)
                    {
                        sgvcolor=UIColor.colorFromHex(hexString: highColor)
                    }
                    else
                    {
                        sgvcolor=UIColor.colorFromHex(hexString: urgentHighColor)
                    }
        
        return sgvcolor
    }
    
    func dirgraphics(_ value:String)->String
    {
        let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
        
        return graphics[value]!
    }
    
    func bggraph(_ hours:Int,bghist:[[String:AnyObject]])-> String?
    {
        //get bghistory
        var google="" as String
        let ct2=NSInteger(Date().timeIntervalSince1970)
        var xg="" as String
        var yg="" as String
        var pc="&chco=" as String
        var maxy=0
        var maxx=0
        var miny=1000
        let bgth=highThreshold
        let bgtl=lowThreshold
        let numbg=577 as Int
        var gpoints=0 as Int
        var bgtimes = [Int](repeating: 0, count: numbg+1)
        let minutes=hours*60
        var inc:Int=1
        if (hours==3||hours==1) {inc=1} else
            if hours==6 {inc=2} else
                if hours==12 {inc=3} else
                {inc=5}

        //find max time, min and max bg
        var i=0 as Int;
        while (i<bghist.count) {
            let curdate: Double = (bghist[i]["date"] as! Double)/1000
            bgtimes[i]=Int((Double(minutes)-(Double(ct2)-curdate)/(60.0)))
            if (bgtimes[i]>=0) {
                gpoints += 1
                if (bgtimes[i]>maxx) { maxx=bgtimes[i]}
                let bgi = bghist[i]["sgv"] as! Int
                if (bghist[i]["sgv"] as! Int > maxy) {maxy = bghist[i]["sgv"] as! Int}
                if (bgi < miny) {miny = bgi}
            }
            
            i=i+1;}
        
        if gpoints < 2 {return "NoData"}
        
        //insert prediction points into
        if maxy<bgth {maxy=bgth}
        if miny>bgtl {miny=bgtl}
        
        //create strings of data points xg (time) and yg (bg) and string of colors pc
        i=0;
        while i<bghist.count
        {
            if (bgtimes[i]>=0)
            {
                //scale time values
                xg=xg+String(bgtimes[i]*100/minutes)+","
                var sgv:Int = bghist[i]["sgv"] as! Int
                if sgv<urgentLowThreshold {pc=pc+UIColor.colorFromHex(hexString: urgenLowColor).toRGBAString()+"|"} else
                    if sgv<lowThreshold {pc=pc+UIColor.colorFromHex(hexString: lowColor).toRGBAString()+"|"} else
                        if sgv<highThreshold {pc=pc+UIColor.colorFromHex(hexString: inRangeColor).toRGBAString()+"|"} else
                            if sgv<urgentHighThreshold {pc=pc+UIColor.colorFromHex(hexString: highColor).toRGBAString()+"|"} else
                                {pc=pc+UIColor.colorFromHex(hexString: urgentHighColor).toRGBAString()+"|"}
                
                sgv=(sgv-miny)*100/(maxy-miny)
                yg=yg+String(sgv)+","
                
            }
            
            i=i+inc}

        xg=String(xg.dropLast())
        yg=String(yg.dropLast())
        pc=String(pc.dropLast())
        
        let low:Double=Double(bgtl-miny)/Double(maxy-miny)
        let high:Double=Double(bgth-miny)/Double(maxy-miny)
        
        //create string for google chart api
        let band1="&chm=r,FFFFFF,0,"+String(format:"%.2f",high-0.003)+","+String(format:"%.3f",high)
        let band2="|r,FFFFFF,0,"+String(format:"%.2f",(low))+","+String(format:"%.3f",low+0.003)
        //let h:String=String(stringInterpolationSegment: 100.0/Double(hours))
        let h:String=String(100.0/Double(hours))
        let hourlyverticals="&chg="+h+",0,4,0"
        
        if (mmol == false)
        {
            google="https://chart.googleapis.com/chart?cht=s:nda&chxt=y&chxr=0,"+String(miny)+","+String(maxy)+"&chs=180x100"+"&chf=bg,s,000000&chls=3&chd=t:"+xg+"|"+yg+"|20"+pc+"&chof=png&chxs=0,FFFFFF"+band1+band2+hourlyverticals
        }
        else
        {
            let mmolminy = Double(miny) / 18.0182
            let mmolmaxy = Double(maxy) / 18.0182
            google="https://chart.googleapis.com/chart?cht=s:nda&chxt=y&chxr=0,"+String(format:"%.1f",mmolminy)+","+String(format:"%.1f",mmolmaxy)+"&chs=180x100"+"&chf=bg,s,000000&chls=3&chd=t:"+xg+"|"+yg+"|20"+pc+"&chof=png&chxs=0,FFFFFF"+band1+band2+hourlyverticals
        }

        return google
    }
    
    func displayError(error:String)
    {
        self.primarybg.setText("")
        self.vlabel.setTextColor(UIColor.red)
        self.vlabel.setText(error)
    }
}

//Extensions
extension UIColor
{
    func toRGBAString(uppercased: Bool = true) -> String
    {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgba = [r, g, b, a].map { $0 * 255 }.reduce("", { $0 + String(format: "%02x", Int($1)) })
        return uppercased ? rgba.uppercased() : rgba
    }
}
