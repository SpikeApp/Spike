package ui.chart.markers
{	
	import database.CommonSettings;
	
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	
	import treatments.Treatment;
	
	import ui.chart.GlucoseChart;
	import ui.chart.visualcomponents.ChartTreatment;
	import ui.screens.display.LayoutFactory;
	import ui.shapes.SpikeNGon;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class MealMarker extends ChartTreatment
	{
		/* Display Objects */
		private var insulinLabel:Label;
		private var carbsLabel:Label;
		private var mainLabel:Label;
		private var insulinMarker:SpikeNGon;
		private var carbsMarker:SpikeNGon;
		private var stroke:SpikeNGon;
		
		/* Properties */
		private var fontSize:int = 11;
		private var backgroundInsulinColor:uint;
		private var backgroundCarbsColor:uint;
		private var strokeColor:uint;
		private var initialRadius:Number = 8;
		private var chartTimeline:Number;
		private var numSides:int = 30;
		private var strokeThickness:Number = 0.8;

		public function MealMarker(treatment:Treatment, timeline:Number, isExtended:Boolean = false)
		{
			this.treatment = treatment;
			backgroundInsulinColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR));
			backgroundCarbsColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR));
			strokeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_STROKE_COLOR));
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				numSides = 20;
			
			chartTimeline = timeline;
			
			if (isExtended)
				strokeThickness *= 1.5;
			
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
			if (treatment.insulinAmount < 1 && treatment.insulinAmount > 0)
				fontSize -= 1.5;
			
			//Stroke
			stroke = new SpikeNGon(radius + strokeThickness, numSides, 0, 360, strokeColor);
			stroke.x = radius / 3;
			stroke.y = radius + radius/4;
			addChild(stroke);
			
			//Background
			insulinMarker = new SpikeNGon(radius, numSides, 90, 270, backgroundInsulinColor);
			insulinMarker.x = radius / 3;
			insulinMarker.y = radius + radius/4;
			addChild(insulinMarker);
			
			carbsMarker = new SpikeNGon(radius, numSides, -90, 90, backgroundCarbsColor);
			carbsMarker.x = radius / 3;
			carbsMarker.y = radius + radius/4;
			addChild(carbsMarker);
			
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
			if (mainLabel != null && insulinLabel != null && carbsLabel != null)
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
			if (mainLabel != null && insulinLabel != null && carbsLabel != null)
			{
				insulinLabel.visible = true;
				carbsLabel.visible = true;
				mainLabel.visible = false;
			}
		}
		
		override public function updateMarker(treatment:Treatment):void
		{
			this.treatment = treatment;
			
			removeChildren(0, -1, true);
			
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