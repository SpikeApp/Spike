//
//  FSInterfaceController.swift
//  watch Extension
//
//  Created by Miguel Kennedy on 30/04/2018.
//  Copyright © 2018 Spike. All rights reserved.
//

import WatchKit
import Foundation

class FSInterfaceController: WKInterfaceController
{
    @IBOutlet var glucoseDisplay: WKInterfaceLabel!
    @IBOutlet var slopeDisplay: WKInterfaceLabel!
    @IBOutlet var timeAgoDisplay: WKInterfaceLabel!
    @IBOutlet var IOBCOBDisplay: WKInterfaceLabel!
    
    //Internal Variables
    var bghistread=true as Bool
    var bghist=[] as?  [[String:AnyObject]]
    
    @IBAction func onChartTap()
    {
        self.pop()
    }
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updateData()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        //Set all labels to gray to indicate outdated data to the user.
        let gray=UIColor.gray as UIColor
        self.glucoseDisplay.setTextColor(gray)
        self.timeAgoDisplay.setTextColor(gray)
        self.slopeDisplay.setTextColor(gray)
        self.IOBCOBDisplay.setTextColor(gray)
    }
    
    func updateData()
    {
        print("In updateData")
        
        //set bg color to show the user that the data being displayed is outdated and about to be updated
        let gray=UIColor.gray as UIColor
        let white=UIColor.white as UIColor
        self.glucoseDisplay.setTextColor(gray)
        self.timeAgoDisplay.setTextColor(gray)
        self.slopeDisplay.setTextColor(gray)
        self.IOBCOBDisplay.setTextColor(gray)
        
        //Define URL and perform connection. Ask for 2 readings but allow an offset of 24H. Lightmode means no stats like A1C, AVG, etc. Just IOB/COB
        let urlPath: String = urlUser + "/spikewatch?count=2&lightMode=true&startoffset=" + String(24 * 60 * 60 * 1000)
        
        guard let url = URL(string: urlPath) else
        {
            print ("URL Parsing Error")
            displayError(error: "URL ERROR!")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                print(error!)
                self.displayError(error: "Spike is offline!")
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
                        self.IOBCOBDisplay.setText(statusOne)
                        
                        //Process glucose...
                        print("Processing glucose")
                        self.bghistread=true
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
                        let bgtime=entries[0]["date"] as! TimeInterval
                        let red=UIColor.red as UIColor
                        self.bghist=entries
                        
                        //Set labels to white before updating data
                        self.glucoseDisplay.setTextColor(white)
                        self.timeAgoDisplay.setTextColor(white)
                        self.slopeDisplay.setTextColor(white)
                        self.IOBCOBDisplay.setTextColor(white)
                        
                        let ct=TimeInterval(Date().timeIntervalSince1970)
                        let deltat=(ct-bgtime/1000)/60
                        if deltat >= 15 { self.timeAgoDisplay.setTextColor(UIColor.red) }
                        self.timeAgoDisplay.setText(String(Int(deltat))+" min ago")
                        
                        if (cbg<40)
                        {
                            //Case where glucose is lower than 40mg/dL
                            self.glucoseDisplay.setTextColor(red)
                            self.glucoseDisplay.setText("LOW")
                        }
                        else if (cbg>400)
                        {
                            //Case where glucose is higher than 400mg/dL
                            self.glucoseDisplay.setTextColor(red)
                            self.glucoseDisplay.setText("HIGH")
                        }
                        else
                        {
                            self.glucoseDisplay.setTextColor(self.bgcolor(cbg))
                            
                            if (mmol == false)
                            {
                                self.glucoseDisplay.setText(String(cbg) + self.dirgraphics(direction))
                                if (dbg<0) {self.slopeDisplay.setText(String(dbg)+" mg/dL")} else {self.slopeDisplay.setText("+"+String(dbg)+" mg/dL")}
                            }
                            else
                            {   let conv = 18.0182 as Double
                                let mmolbg = Double(cbg) / conv
                                let mmoltext = String(format:"%.1f", mmolbg)
                                self.slopeDisplay.setText(mmoltext)
                                let deltammol = Double(dbg) / conv
                                let delmmoltext = String(format:"%.1f", deltammol)
                                if (dbg<0) {self.slopeDisplay.setText(delmmoltext + " mmol/L")} else {self.slopeDisplay.setText("+" + delmmoltext + " mmol/L")}
                                self.glucoseDisplay.setText(String(mmoltext) + self.dirgraphics(direction))
                            }
                        }
                    }
                    else
                    {
                        self.displayError(error: "Error loading data!")
                        self.bghistread=false
                        return
                    }
            } //end dispatch
        } //end urlsession
        
        task.resume()
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
    
    func displayError(error:String)
    {
        self.timeAgoDisplay.setText("")
        self.slopeDisplay.setText("")
        self.IOBCOBDisplay.setText("")
        self.glucoseDisplay.setTextColor(UIColor.red)
        self.glucoseDisplay.setText(error)
    }
    
    func dirgraphics(_ value:String)->String
    {
        let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
        
        return graphics[value]!
    }
}
