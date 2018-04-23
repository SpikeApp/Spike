package ui.chart
{	
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import starling.display.Shape;
	import starling.display.graphics.NGon;
	
	import treatments.Treatment;
	
	import ui.screens.display.LayoutFactory;
	
	public class MealMarker extends ChartTreatment
	{
		/* Display Objects */
		private var insulinLabel:Label;
		private var carbsLabel:Label;
		private var mainLabel:Label;
		private var insulinMarker:NGon;
		private var carbsMarker:NGon;
		private var stroke:Shape;
		
		/* Properties */
		private var fontSize:int = 11;
		private var backgroundInsulinColor:uint;
		private var backgroundCarbsColor:uint;
		private var strokeColor:uint;
		private var initialRadius:Number = 8;
		private var chartTimeline:Number;

		public function MealMarker(treatment:Treatment, timeline:Number)
		{
			this.treatment = treatment;
			backgroundInsulinColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR));
			backgroundCarbsColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			
			chartTimeline = timeline;
			
			draw();
		}
		
		private function draw():void
		{
			//OpenAPS/Loop support
			if (treatment.insulinAmount <= 1.2)
				initialRadius = 6;
			
			//Radius
			//this.radius = initialRadius + treatment.insulinAmount;
			this.radius = initialRadius + (treatment.carbs / 6);
			if (radius > 15)
				radius = 15;
			
			if (chartTimeline == GlucoseChart.TIMELINE_6H)
			{
				radius *= 0.8;
				fontSize *= 0.8;
			}
			else if (chartTimeline == GlucoseChart.TIMELINE_12H)
			{
				radius *= 0.65;
				fontSize *= 0.7;
			}
			else if (chartTimeline == GlucoseChart.TIMELINE_24H)
			{
				radius *= 0.5;
				fontSize *= 0.6;
			}
			
			//OpenAPS/Loop support
			if (treatment.insulinAmount < 1)
				fontSize -= 1.5;
			
			//Background
			insulinMarker = new NGon(radius, 20, 0, 90, 270);
			insulinMarker.x = radius / 3;
			insulinMarker.y = radius + radius/4;
			insulinMarker.color = backgroundInsulinColor;
			addChild(insulinMarker);
			
			carbsMarker = new NGon(radius, 20, 0, -90, 90);
			carbsMarker.x = radius / 3;
			carbsMarker.y = radius + radius/4;
			carbsMarker.color = backgroundCarbsColor;
			addChild(carbsMarker);
			
			//Stroke
			stroke = new Shape();
			stroke.graphics.lineStyle(0.8, strokeColor, 1);
			stroke.graphics.drawCircle(radius, radius, radius);
			stroke.y = radius/4;
			stroke.x = -radius/1.5;
			addChild(stroke);
			
			//Label
			insulinLabel = LayoutFactory.createLabel(treatment.insulinAmount != 0 ? treatment.insulinAmount + "U" : "", HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, true);
			insulinLabel.validate();
			insulinLabel.x = radius/3 - (insulinLabel.width / 2);
			insulinLabel.y = radius * 2 + 4;
			addChild(insulinLabel);
			
			carbsLabel = LayoutFactory.createLabel(treatment.carbs != 0 ? treatment.carbs + "g" : "", HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, true);
			carbsLabel.validate();
			carbsLabel.x = radius/3 - (carbsLabel.width / 2);
			carbsLabel.y = -carbsLabel.height + 1;
			addChild(carbsLabel);
			
			mainLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, fontSize, true);
			mainLabel.y = carbsLabel.y;
			mainLabel.visible = false;
			addChild(mainLabel);
		}	
		
		override public function labelUp():void
		{
			if (mainLabel != null)
			{
				insulinLabel.visible = false;
				carbsLabel.visible = false;
				mainLabel.text = insulinLabel.text + (insulinLabel.text != "" ? " / " : "") + carbsLabel.text;
				mainLabel.validate();
				mainLabel.y = carbsLabel.y;
				mainLabel.x = radius/3 - (mainLabel.width / 2);
				mainLabel.visible = true;
			}
		}
		
		override public function labelDown():void
		{
			insulinLabel.visible = true;
			carbsLabel.visible = true;
			mainLabel.visible = false;
		}
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, 10, true);
			
			draw();
		}
		
		override public function dispose():void
		{
			if (insulinLabel != null)
			{
				insulinLabel.removeFromParent();
				insulinLabel.dispose();
				insulinLabel = null;
			}
			
			if (carbsLabel != null)
			{
				carbsLabel.removeFromParent();
				carbsLabel.dispose();
				carbsLabel = null;
			}
			
			if (mainLabel != null)
			{
				mainLabel.removeFromParent();
				mainLabel.dispose();
				mainLabel = null;
			}
			
			if (insulinMarker != null)
			{
				insulinMarker.removeFromParent();
				insulinMarker.dispose();
				insulinMarker = null;
			}
			
			if (carbsMarker != null)
			{
				carbsMarker.removeFromParent();
				carbsMarker.dispose();
				carbsMarker = null;
			}
			
			if (stroke != null)
			{
				stroke.removeFromParent();
				stroke.dispose();
				stroke = null;
			}
			
			super.dispose();
		}
	}
}