import ClockKit

class Cowmplication: NSObject, CLKComplicationDataSource {
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
    }
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(CLKComplicationPrivacyBehavior.showOnLockScreen)
    }
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimelineEntry?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: ([CLKComplicationTimelineEntry]?) -> Void) {
        handler([])
    }
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(NSDate())
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        if complication.family == .utilitarianSmall {
            let smallFlat = CLKComplicationTemplateUtilitarianSmallFlat()
            smallFlat.textProvider = CLKSimpleTextProvider(text: "")
            smallFlat.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Utilitarian")!)
            handler(smallFlat)
        } else if complication.family == .utilitarianSmallFlat {
            let smallFlat = CLKComplicationTemplateUtilitarianSmallFlat()
            smallFlat.textProvider = CLKSimpleTextProvider(text: "")
            smallFlat.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Utilitarian")!)
            handler(smallFlat)
        } else if complication.family == .utilitarianLarge {
            let largeFlat = CLKComplicationTemplateUtilitarianLargeFlat()
            largeFlat.textProvider = CLKSimpleTextProvider(text: "", shortText:"")
            largeFlat.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Utilitarian")!)
            handler(largeFlat)
        } else if complication.family == .circularSmall {
            let circularSmall = CLKComplicationTemplateCircularSmallRingImage()
            circularSmall.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Circular")!)
            handler(circularSmall)
        } else if complication.family == .modularSmall {
            let modularSmall = CLKComplicationTemplateModularSmallRingImage()
            modularSmall.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Modular")!)
            handler(modularSmall)
        }
        
        if #available(watchOSApplicationExtension 5.0, *)
        {
            if complication.family == .graphicCircular
            {
                let graphicCircular = CLKComplicationTemplateGraphicCircularImage()
                graphicCircular.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Circular")!)
                handler(graphicCircular)
            }
            else if complication.family == .graphicCorner
            {
                let graphicCorner = CLKComplicationTemplateGraphicCornerTextImage()
                graphicCorner.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Corner")!)
                graphicCorner.textProvider = CLKSimpleTextProvider(text: "SPIKE")
                graphicCorner.textProvider.tintColor = .white
                handler(graphicCorner)
            }
            else if complication.family == .graphicRectangular
            {
                let graphicRectangular = CLKComplicationTemplateGraphicRectangularLargeImage()
                graphicRectangular.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Large Rectangular")!)
                graphicRectangular.textProvider = CLKSimpleTextProvider(text: "")
                handler(graphicRectangular)
            }
            else if complication.family == .graphicBezel
            {
                let graphicBezel = CLKComplicationTemplateGraphicCircularImage()
                graphicBezel.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Bezel")!)
                handler(graphicBezel)
            }
        }
    }
    
    func getPlaceholderTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        if complication.family == .utilitarianSmall {
            let smallFlat = CLKComplicationTemplateUtilitarianSmallFlat()
            smallFlat.textProvider = CLKSimpleTextProvider(text: "")
            smallFlat.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Utilitarian")!)
            handler(smallFlat)
        } else if complication.family == .utilitarianSmallFlat {
            let smallFlat = CLKComplicationTemplateUtilitarianSmallFlat()
            smallFlat.textProvider = CLKSimpleTextProvider(text: "")
            smallFlat.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Utilitarian")!)
            handler(smallFlat)
        } else if complication.family == .utilitarianLarge {
            let largeFlat = CLKComplicationTemplateUtilitarianLargeFlat()
            largeFlat.textProvider = CLKSimpleTextProvider(text: "", shortText:"")
            largeFlat.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Utilitarian")!)
            handler(largeFlat)
        } else if complication.family == .circularSmall {
            let circularSmall = CLKComplicationTemplateCircularSmallRingImage()
            circularSmall.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Circular")!)
            handler(circularSmall)
        } else if complication.family == .modularSmall {
            let modularSmall = CLKComplicationTemplateModularSmallRingImage()
            modularSmall.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Modular")!)
            handler(modularSmall)
        }
        else if complication.family == .extraLarge {
            let extraLarge = CLKComplicationTemplateExtraLargeSimpleImage()
            extraLarge.imageProvider = CLKImageProvider(onePieceImage: UIImage (named: "Complication/Extra Large")!)
            handler(extraLarge)
        }
        
        if #available(watchOSApplicationExtension 5.0, *)
        {
            if complication.family == .graphicCircular
            {
                let graphicCircular = CLKComplicationTemplateGraphicCircularImage()
                graphicCircular.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Circular")!)
                handler(graphicCircular)
            }
            else if complication.family == .graphicCorner
            {
                let graphicCorner = CLKComplicationTemplateGraphicCornerTextImage()
                graphicCorner.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Corner")!)
                graphicCorner.textProvider = CLKSimpleTextProvider(text: "SPIKE")
                 graphicCorner.textProvider.tintColor = .white
                handler(graphicCorner)
            }
            else if complication.family == .graphicRectangular
            {
                let graphicRectangular = CLKComplicationTemplateGraphicRectangularLargeImage()
                graphicRectangular.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Large Rectangular")!)
                graphicRectangular.textProvider = CLKSimpleTextProvider(text: "")
                handler(graphicRectangular)
            }
            else if complication.family == .graphicBezel
            {
                let graphicBezel = CLKComplicationTemplateGraphicCircularImage()
                graphicBezel.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Bezel")!)
                handler(graphicBezel)
            }
        }
    }
}
