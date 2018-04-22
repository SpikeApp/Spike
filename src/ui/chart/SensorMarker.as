package ui.chart
{
	import database.CommonSettings;
	
	import starling.display.Shape;
	import starling.display.graphics.NGon;
	
	import treatments.Treatment;
	
	public class SensorMarker extends ChartTreatment
	{
		/* Properties */
		private var backgroundColor:uint;
		private var strokeColor:uint;

		// Display Objects
		private var sensorMarker:NGon;
		private var stroke:Shape;
		
		public function SensorMarker(treatment:Treatment)
		{
			this.treatment = treatment;
			backgroundColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			
			draw();
		}
		
		private function draw():void
		{
			//Radius
			this.radius = 6;
			
			//Background
			sensorMarker = new NGon(radius, 20, 0, 0, 360);
			sensorMarker.x = radius / 3;
			sensorMarker.y = radius + radius/4;
			sensorMarker.color = backgroundColor;
			addChild(sensorMarker);
			
			//Stroke
			stroke = new Shape();
			stroke.graphics.lineStyle(0.8, strokeColor, 1);
			stroke.graphics.drawCircle(radius, radius, radius);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
		}	
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, 10, true);
			
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