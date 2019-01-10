package ui.chart.markers
{
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.textures.Texture;
	
	import treatments.Treatment;
	import ui.chart.visualcomponents.ChartTreatment;
	import ui.chart.GlucoseChart;
	
	public class PumpBatteryMarker extends ChartTreatment
	{
		private var chartTimeline:Number;
		private var pumpBatteryScale:Number = 1;

		//Display Objects
		private var pumpBatteryTexture:Texture;
		private var pumpBatteryMarker:Image;
		private var hitArea:Quad;
		private var markerContainer:Sprite;
		
		public function PumpBatteryMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//Define scale base on main chart timeline range
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
				pumpBatteryScale *= 0.8;
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
				pumpBatteryScale *= 0.65;
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
				pumpBatteryScale *= 0.5;
			
			//Note icon
			pumpBatteryTexture = MaterialDeepGreyAmberMobileThemeIcons.pumpBatteryChartTexture;
			pumpBatteryMarker = new Image(pumpBatteryTexture);
			pumpBatteryMarker.y = pumpBatteryMarker.x = 5;
			
			//Note Mask
			hitArea = new Quad(30, 30, 0xFF0000);
			hitArea.alpha = 0;
			
			//Note container
			markerContainer = new Sprite();
			markerContainer.addChild(pumpBatteryMarker);
			markerContainer.addChild(hitArea);
			
			//Scale
			markerContainer.scale = pumpBatteryScale;
			
			addChild(markerContainer);
		}
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, -1, true);
			
			draw();
		}
		
		override public function dispose():void
		{
			if (pumpBatteryTexture != null)
			{
				pumpBatteryTexture.dispose();
				pumpBatteryTexture = null;
			}
			
			if (pumpBatteryMarker != null)
			{
				pumpBatteryMarker.removeFromParent();
				if (pumpBatteryMarker.texture != null)
					pumpBatteryMarker.texture.dispose();
				pumpBatteryMarker.dispose();
				pumpBatteryMarker = null;
			}
			
			if (hitArea != null)
			{
				hitArea.removeFromParent();
				hitArea.dispose();
				hitArea = null;
			}
			
			if (markerContainer != null)
			{
				markerContainer.removeFromParent();
				markerContainer.dispose();
				markerContainer = null;
			}
			
			super.dispose();
		}
	}
}