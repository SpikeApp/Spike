package ui.chart.markers
{
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import starling.display.Sprite;
	
	import ui.chart.helpers.GlucoseFactory;
	import ui.shapes.SpikeNGon;
	import ui.shapes.SpikeRing;
	
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
		private var isRaw:Boolean;
		private var isPrediction:Boolean;

		// Display Objects
		public var glucoseMarker:*;
		public var hitArea:SpikeNGon;

        public function GlucoseMarker(data:Object, isRaw:Boolean = false, isPrediction:Boolean = false)
        {
            this.data = data;
			this.isRaw = isRaw;
			this.isPrediction = isPrediction;
			
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
			
			if (!isRaw && !isPrediction)
			{
				//Glucose Value (Both internal and external)
				glucoseValue = bgReading.calculatedValue;
				
				var glucoseValueProperties:Object = GlucoseFactory.getGlucoseOutput(glucoseValue);
				glucoseOutput = glucoseValueProperties.glucoseOutput;
				glucoseValueFormatted = glucoseValueProperties.glucoseValueFormatted;
				
				//Slope (Both Arrow And Output)
				//Output
				if(index > 0)
				{
					if (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) != "true" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout") 
						slopeOutput = String(MathHelper.formatNightscoutFollowerSlope(Math.round((glucoseValueFormatted - data.previousGlucoseValueFormatted) * 10) / 10));
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
					slopeOutput = "???";
				
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
			}
			else if (isRaw)
			{
				glucoseValue = Number(data.raw);
				color = data.rawColor;
			}
			else if (isPrediction)
			{
				glucoseValue = Number(data.glucose);
				color = data.color;
			}
			
			//Create graphics
			draw();
		}

        //Function to draw the shape
        public function draw():void
        {
			if (!isPrediction)
			{
            	glucoseMarker = new SpikeNGon(radius, 10, 0, 360, color);
				glucoseMarker.x = glucoseMarker.y = radius;
			}
			else
			{
				glucoseMarker = new SpikeRing(radius / 2, radius, color);
			}
			
            addChild(glucoseMarker);
        }
		
		private function createHitArea():void
		{
			hitArea = new SpikeNGon(radius * 2, 10, 0, 360, 0x00FF00, 0);
			hitArea.x = hitArea.y = radius;
		}
		
		public function addHitArea():void
		{
			if (hitArea == null)
			{
				createHitArea();
			}
			
			addChild(hitArea);
		}
		
		public function removeHitArea():void
		{
			if (hitArea != null)
			{
				hitArea.removeFromParent();
			}
		}
		
		public function updateColor():void
		{
			if (glucoseMarker != null)
				glucoseMarker.removeFromParent(true);
			
			glucoseMarker = new SpikeNGon(radius, 15, 0, 360, color);
			glucoseMarker.x = glucoseMarker.y = radius;
			addChild(glucoseMarker);
		}
		
		public function set newBgReading(bgReading:BgReading):void
		{
			data.bgReading = bgReading;
		}
		
		public function set newRaw(raw:Number):void
		{
			data.raw = raw;
		}
		
		public function setLocationY (newY:Number):void
		{
			data.y = newY;
		}
		
		override public function dispose():void
		{
			if (glucoseMarker != null)
			{
				glucoseMarker.removeFromParent();
				glucoseMarker.dispose();
				glucoseMarker = null;
			}
			
			if (hitArea != null)
			{
				hitArea.removeFromParent();
				hitArea.dispose();
				hitArea = null;
			}
			
			super.dispose();
		}
    }
}
