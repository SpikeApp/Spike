package ui.chart
{
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.textures.Texture;
	
	import treatments.Treatment;
	
	public class NoteMarker extends ChartTreatment
	{
		private var chartTimeline:Number;
		private var noteScale:Number = 1;
		
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
			var noteTexture:Texture = MaterialDeepGreyAmberMobileThemeIcons.noteChartTexture;
			var noteMarker:Image = new Image(noteTexture);
			noteMarker.y = noteMarker.x = 5;
			
			//Note Mask
			var hitArea:Quad = new Quad(30, 30, 0xFF0000);
			hitArea.alpha = 0;
			
			//Note container
			var markerContainer:Sprite = new Sprite();
			markerContainer.addChild(noteMarker);
			markerContainer.addChild(hitArea);
			
			//Scale
			markerContainer.scale = noteScale;
			
			addChild(markerContainer);
		}
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, 10, true);
			
			draw();
		}
	}
}