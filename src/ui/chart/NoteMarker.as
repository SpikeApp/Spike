package ui.chart
{
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
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
			addChild(noteMarker);
		}		
	}
}