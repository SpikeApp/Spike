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
	
	public class ExerciseMarker extends ChartTreatment
	{
		private var chartTimeline:Number;
		private var exerciseScale:Number = 1;

		//Display Objects
		private var exerciseTexture:Texture;
		private var exerciseMarker:Image;
		private var hitArea:Quad;
		private var markerContainer:Sprite;
		
		public function ExerciseMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//Define scale base on main chart timeline range
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
				exerciseScale *= 0.8;
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
				exerciseScale *= 0.65;
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
				exerciseScale *= 0.5;
			
			//Note icon
			exerciseTexture = MaterialDeepGreyAmberMobileThemeIcons.exerciseChartTexture;
			exerciseMarker = new Image(exerciseTexture);
			exerciseMarker.y = exerciseMarker.x = 5;
			
			//Note Mask
			hitArea = new Quad(30, 30, 0xFF0000);
			hitArea.alpha = 0;
			
			//Note container
			markerContainer = new Sprite();
			markerContainer.addChild(exerciseMarker);
			markerContainer.addChild(hitArea);
			
			//Scale
			markerContainer.scale = exerciseScale;
			
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
			if (exerciseTexture != null)
			{
				exerciseTexture.dispose();
				exerciseTexture = null;
			}
			
			if (exerciseMarker != null)
			{
				exerciseMarker.removeFromParent();
				if (exerciseMarker.texture != null)
					exerciseMarker.texture.dispose();
				exerciseMarker.dispose();
				exerciseMarker = null;
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