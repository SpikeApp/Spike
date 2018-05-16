package ui.chart
{
	import database.CommonSettings;
	
	import starling.display.Canvas;
	import starling.display.Shape;
	
	import treatments.Treatment;
	
	import ui.shapes.SpikeDisplayObject;
	
	public class SensorMarker extends ChartTreatment
	{
		/* Properties */
		private var backgroundColor:uint;
		private var strokeColor:uint;

		// Display Objects
		private var sensorMarker:Canvas;
		private var stroke:SpikeDisplayObject;
		private var hitArea:Shape;
		
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
			
			//Hit Area
			hitArea = new Shape();
			hitArea.graphics.beginFill(0xFF0000, 0);
			hitArea.graphics.drawCircle(0, 0, radius * 2.5);
			hitArea.graphics.endFill();
			hitArea.x = radius / 2.5;
			hitArea.y = radius * 1.25;
			hitArea.alpha = 0;
			addChild(hitArea);
			
			//Background
			sensorMarker = new Canvas();
			sensorMarker.beginFill(backgroundColor);
			sensorMarker.drawCircle(radius / 3, radius + radius/4, radius);
			addChild(sensorMarker);
			
			//Stroke
			var strokeShape:Shape = new Shape();
			strokeShape.graphics.lineStyle(0.8, strokeColor, 1);
			strokeShape.graphics.drawCircle(radius, radius, radius);
			
			stroke = GraphLayoutFactory.createImageFromShape(strokeShape);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
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