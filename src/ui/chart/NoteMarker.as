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
		public function NoteMarker(treatment:Treatment)
		{
			this.treatment = treatment;
			
			draw();
		}
		
		private function draw():void
		{
			var noteTexture:Texture = MaterialDeepGreyAmberMobileThemeIcons.noteChartTexture;
			var noteMarker:Image = new Image(noteTexture);
			noteMarker.y = noteMarker.x = 5;
			var hitArea:Quad = new Quad(30, 30, 0xFF0000);
			hitArea.alpha = 0;
			var markerContainer:Sprite = new Sprite();
			markerContainer.addChild(noteMarker);
			markerContainer.addChild(hitArea);
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