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
	
	public class PumpSiteMarker extends ChartTreatment
	{
		private var chartTimeline:Number;
		private var pumpSiteScale:Number = 1;

		//Display Objects
		private var pumpSiteTexture:Texture;
		private var pumpSiteMarker:Image;
		private var hitArea:Quad;
		private var markerContainer:Sprite;
		
		public function PumpSiteMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//Define scale base on main chart timeline range
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
				pumpSiteScale *= 0.8;
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
				pumpSiteScale *= 0.65;
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
				pumpSiteScale *= 0.5;
			
			//Note icon
			pumpSiteTexture = MaterialDeepGreyAmberMobileThemeIcons.pumpSiteChartTexture;
			pumpSiteMarker = new Image(pumpSiteTexture);
			pumpSiteMarker.y = pumpSiteMarker.x = 5;
			
			//Note Mask
			hitArea = new Quad(30, 30, 0xFF0000);
			hitArea.alpha = 0;
			
			//Note container
			markerContainer = new Sprite();
			markerContainer.addChild(pumpSiteMarker);
			markerContainer.addChild(hitArea);
			
			//Scale
			markerContainer.scale = pumpSiteScale;
			
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
			if (pumpSiteTexture != null)
			{
				pumpSiteTexture.dispose();
				pumpSiteTexture = null;
			}
			
			if (pumpSiteMarker != null)
			{
				pumpSiteMarker.removeFromParent();
				if (pumpSiteMarker.texture != null)
					pumpSiteMarker.texture.dispose();
				pumpSiteMarker.dispose();
				pumpSiteMarker = null;
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