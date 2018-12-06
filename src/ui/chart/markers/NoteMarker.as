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
	
	public class NoteMarker extends ChartTreatment
	{
		private var chartTimeline:Number;
		private var noteScale:Number = 1;

		//Display Objects
		private var noteTexture:Texture;
		private var noteMarker:Image;
		private var hitArea:Quad;
		private var markerContainer:Sprite;
		
		public function NoteMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//Define scale base on main chart timeline range
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
				noteScale *= 0.8;
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
				noteScale *= 0.65;
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
				noteScale *= 0.5;
			
			//Note icon
			noteTexture = MaterialDeepGreyAmberMobileThemeIcons.noteChartTexture;
			noteMarker = new Image(noteTexture);
			noteMarker.y = noteMarker.x = 5;
			
			//Note Mask
			hitArea = new Quad(30, 30, 0xFF0000);
			hitArea.alpha = 0;
			
			//Note container
			markerContainer = new Sprite();
			markerContainer.addChild(noteMarker);
			markerContainer.addChild(hitArea);
			
			//Scale
			markerContainer.scale = noteScale;
			
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
			if (noteTexture != null)
			{
				noteTexture.dispose();
				noteTexture = null;
			}
			
			if (noteMarker != null)
			{
				noteMarker.removeFromParent();
				if (noteMarker.texture != null)
					noteMarker.texture.dispose();
				noteMarker.dispose();
				noteMarker = null;
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