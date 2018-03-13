package ui.chart
{
	import database.BgReading;
	import database.BlueToothDevice;
	import database.CommonSettings;
	
	import model.ModelLocator;
	
	import starling.display.Canvas;
	import starling.display.Sprite;
	
	import utils.MathHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("chartscreen")]

	public class GlucoseMarker extends Sprite
    {
		// Public Properties
		public var index:int;
        public var glucoseValue:Number;
		public var glucoseValueFormatted:Number;
		public var glucoseOutput:String;
		public var slopeOutput:String;
		public var slopeArrow:String;
        public var timestamp:Number;
		public var timeFormatted:String;
		public var radius:Number;
		public var color:uint;
		public var bgReading:BgReading;
		
		// Internal Variables
		private var data:Object;
		private var dateFormat:String;

		private var glucoseMarker:Canvas;

        public function GlucoseMarker(data:Object)
        {
            this.data = data;
			
			dateFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			process();
        }
		
		public function process():void
		{
			//Set properties
			radius = data.radius;
			
			//bgReading
			bgReading = data.bgReading;
			
			//Coordinates
			x = data.x;
			y = data.y;
			
			//Index (for later reference)
			index = data.index;
			
			//Timestamp
			timestamp = bgReading.timestamp;
			
			//Glucose Value (Both internal and external)
			glucoseValue = bgReading.calculatedValue;
			
			var glucoseValueProperties:Object = GlucoseFactory.getGlucoseOutput(glucoseValue);
			glucoseOutput = glucoseValueProperties.glucoseOutput;
			glucoseValueFormatted = glucoseValueProperties.glucoseValueFormatted;
			
			//Slope (Both Arrow And Output)
			//Output
			if(index > 0)
			{
				if (BlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout") 
					slopeOutput = String(MathHelper.formatNightscoutFollowerSlope(Math.round((glucoseValueFormatted - data.previousGlucoseValueFormatted) * 10) / 10)) + " mmol/L";
				else
				{
					slopeOutput = GlucoseFactory.getGlucoseSlope
					(
						data.previousGlucoseValue,
						data.previousGlucoseValueFormatted,
						glucoseValue,
						glucoseValueFormatted
					);
				}
			}
			else
				slopeOutput = ModelLocator.resourceManagerInstance.getString('chartscreen','slope_unknown');
			
			//Arrow
			if (bgReading.hideSlope)
				slopeArrow = "\u21C4";
			else
				slopeArrow = bgReading.slopeArrow();
			
			//Time
			var markerDate:Date = new Date(timestamp);
			if (dateFormat.slice(0,2) == "24")
				timeFormatted = TimeSpan.formatHoursMinutes(markerDate.getHours(), markerDate.getMinutes(), TimeSpan.TIME_FORMAT_24H);
			else
				timeFormatted = TimeSpan.formatHoursMinutes(markerDate.getHours(), markerDate.getMinutes(), TimeSpan.TIME_FORMAT_12H);
			
			//Define glucose marker color
			color = GlucoseFactory.getGlucoseColor(glucoseValue);
			
			//Create graphics
			draw();
		}

        //Function to draw the shape
        public function draw():void
        {
            glucoseMarker = new Canvas();
            glucoseMarker.beginFill(color);
            glucoseMarker.drawCircle(radius,radius,radius);
            glucoseMarker.endFill();
			
            
            addChild(glucoseMarker);
        }
		
		public function updateColor():void
		{
			removeChild(glucoseMarker);
			
			glucoseMarker = new Canvas();
			glucoseMarker.beginFill(color);
			glucoseMarker.drawCircle(radius,radius,radius);
			glucoseMarker.endFill();
			
			addChild(glucoseMarker)
		}
		
		public function set newBgReading(bgReading:BgReading):void
		{
			data.bgReading = bgReading;
		}
		
		public function setLocationY (newY:Number):void
		{
			data.y = newY;
		}
    }
}
