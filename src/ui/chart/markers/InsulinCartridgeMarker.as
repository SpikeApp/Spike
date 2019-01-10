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
	
	public class InsulinCartridgeMarker extends ChartTreatment
	{
		private var chartTimeline:Number;
		private var insulinCartridgeScale:Number = 1;

		//Display Objects
		private var insulinCartridgeTexture:Texture;
		private var insulinCartridgeMarker:Image;
		private var hitArea:Quad;
		private var markerContainer:Sprite;
		
		public function InsulinCartridgeMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//Define scale base on main chart timeline range
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
				insulinCartridgeScale *= 0.8;
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
				insulinCartridgeScale *= 0.65;
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
				insulinCartridgeScale *= 0.5;
			
			//Note icon
			insulinCartridgeTexture = MaterialDeepGreyAmberMobileThemeIcons.insulinCartridgeChartTexture;
			insulinCartridgeMarker = new Image(insulinCartridgeTexture);
			insulinCartridgeMarker.y = insulinCartridgeMarker.x = 5;
			
			//Note Mask
			hitArea = new Quad(30, 30, 0xFF0000);
			hitArea.alpha = 0;
			
			//Note container
			markerContainer = new Sprite();
			markerContainer.addChild(insulinCartridgeMarker);
			markerContainer.addChild(hitArea);
			
			//Scale
			markerContainer.scale = insulinCartridgeScale;
			
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
			if (insulinCartridgeTexture != null)
			{
				insulinCartridgeTexture.dispose();
				insulinCartridgeTexture = null;
			}
			
			if (insulinCartridgeMarker != null)
			{
				insulinCartridgeMarker.removeFromParent();
				if (insulinCartridgeMarker.texture != null)
					insulinCartridgeMarker.texture.dispose();
				insulinCartridgeMarker.dispose();
				insulinCartridgeMarker = null;
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