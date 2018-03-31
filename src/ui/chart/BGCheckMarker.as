package ui.chart
{
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.graphics.NGon;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	
	public class BGCheckMarker extends ChartTreatment
	{
		/* Constants */
		private const FONT_SIZE:int = 10;
		
		/* Display Objects */
		private var label:Label;
		
		public function BGCheckMarker(treatment:Treatment)
		{
			this.treatment = treatment;
			
			draw();
		}
		
		private function draw():void
		{
			//Radius
			this.radius = 6;
			
			//Background
			var BGMarker:NGon = new NGon(radius, 20, 0, 0, 360);
			BGMarker.x = radius / 3;
			BGMarker.y = radius + radius/4;
			BGMarker.color = 0xFF0000;
			addChild(BGMarker);
			
			//Stroke
			var stroke:Shape = new Shape();
			stroke.graphics.lineStyle(0.8, 0xEEEEEE, 1);
			stroke.graphics.drawCircle(radius, radius, radius);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
			//Label
			var glucoseValue:Number;
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true")
				glucoseValue = treatment.glucose;
			else
				glucoseValue = Math.round(((BgReading.mgdlToMmol((treatment.glucose))) * 10)) / 10;
			
			label = LayoutFactory.createLabel(String(glucoseValue), HorizontalAlign.CENTER, VerticalAlign.TOP, FONT_SIZE, true);
			label.validate();
			label.x = radius/3 - (label.width / 2);
			label.y = radius * 2 + 4;
			addChild(label);
		}	
		
		override public function labelUp():void
		{
			if (label != null)
				label.y = -label.height + 3;
		}
		
		override public function labelDown():void
		{
			if (label != null)
				label.y = radius * 2 + 3;
		}
	}
}