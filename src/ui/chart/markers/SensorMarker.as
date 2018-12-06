package ui.chart.markers
{
	import database.CommonSettings;
	
	import treatments.Treatment;
	
	import ui.shapes.SpikeNGon;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import ui.chart.visualcomponents.ChartTreatment;
	
	public class SensorMarker extends ChartTreatment
	{
		/* Properties */
		private var backgroundColor:uint;
		private var strokeColor:uint;
		private var numSides:int = 30;
		private const strokeThickness:Number = 0.8;

		// Display Objects
		private var sensorMarker:SpikeNGon;
		private var stroke:SpikeNGon;
		
		public function SensorMarker(treatment:Treatment)
		{
			this.treatment = treatment;
			backgroundColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				numSides = 20;
			
			draw();
		}
		
		private function draw():void
		{
			//Radius
			this.radius = 6;
			
			//Stroke
			stroke = new SpikeNGon(radius + strokeThickness, numSides, 0, 360, strokeColor);
			stroke.x = radius / 3;
			stroke.y = radius + radius/4;
			addChild(stroke);
			
			//Background
			sensorMarker = new SpikeNGon(radius, numSides, 0, 360, backgroundColor);
			sensorMarker.x = radius / 3;
			sensorMarker.y = radius + radius/4;
			addChild(sensorMarker);
		}	
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, -1, true);
			
			draw();
		}
		
		override public function dispose():void
		{
			if (sensorMarker != null)
			{
				sensorMarker.removeFromParent();
				sensorMarker.dispose();
				sensorMarker = null;
			}
			
			if (stroke != null)
			{
				stroke.removeFromParent();
				stroke.dispose();
				stroke = null;
			}
			
			super.dispose();
		}
	}
}