package ui.screens.display.settings.chart
{
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("chartsettingsscreen")]

	public class VisualizationSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var targetBGLineCheck:Check;
		private var urgentHighLineCheck:Check;
		private var highLineCheck:Check;
		private var lowLineCheck:Check;
		private var urgentLowLineCheck:Check;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var displayTargetBGLine:Boolean;
		private var displayUrgentHighLine:Boolean;
		private var displayHighLine:Boolean;
		private var displayLowLine:Boolean;
		private var displayUrgentLowLine:Boolean;
		
		public function VisualizationSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialState();	
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialState():void
		{
			//Retrieve data from database
			displayTargetBGLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_TARGET_LINE) == "true";
			displayUrgentHighLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_HIGH_LINE) == "true";
			displayHighLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_HIGH_LINE) == "true";
			displayLowLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LOW_LINE) == "true";
			displayUrgentLowLine = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_LOW_LINE) == "true";
		}
		
		private function setupContent():void
		{
			//Target Line
			targetBGLineCheck = LayoutFactory.createCheckMark(displayTargetBGLine);
			targetBGLineCheck.pivotX = 5;
			targetBGLineCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			urgentHighLineCheck = LayoutFactory.createCheckMark(displayUrgentHighLine);
			urgentHighLineCheck.pivotX = 5;
			urgentHighLineCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			highLineCheck = LayoutFactory.createCheckMark(displayHighLine);
			highLineCheck.pivotX = 5;
			highLineCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			lowLineCheck = LayoutFactory.createCheckMark(displayLowLine);
			lowLineCheck.pivotX = 5;
			lowLineCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			urgentLowLineCheck = LayoutFactory.createCheckMark(displayUrgentLowLine);
			urgentLowLineCheck.pivotX = 5;
			urgentLowLineCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','display_urgent_high_glucose_line'), accessory: urgentHighLineCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','display_high_glucose_line'), accessory: highLineCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','display_target_glucose_line'), accessory: targetBGLineCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','display_low_glucose_line'), accessory: lowLineCheck } );
			data.push( { label: ModelLocator.resourceManagerInstance.getString('chartsettingsscreen','display_urgent_low_glucose_line'), accessory: urgentLowLineCheck } );
			
			dataProvider = new ArrayCollection( data );
		}
		
		public function save():void
		{
			//Update Database
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_TARGET_LINE) != String(displayTargetBGLine))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_TARGET_LINE, String(displayTargetBGLine));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_HIGH_LINE) != String(displayUrgentHighLine))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_HIGH_LINE, String(displayUrgentHighLine));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_HIGH_LINE) != String(displayHighLine))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_HIGH_LINE, String(displayHighLine));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LOW_LINE) != String(displayLowLine))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_LOW_LINE, String(displayLowLine));
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_LOW_LINE) != String(displayUrgentLowLine))
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_CHART_DISPLAY_URGENT_LOW_LINE, String(displayUrgentLowLine));
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			displayTargetBGLine = targetBGLineCheck.isSelected;
			displayUrgentHighLine = urgentHighLineCheck.isSelected;
			displayHighLine = highLineCheck.isSelected;
			displayLowLine = lowLineCheck.isSelected;
			displayUrgentLowLine = urgentLowLineCheck.isSelected;
			
			needsSave = true;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (targetBGLineCheck != null)
			{
				targetBGLineCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				targetBGLineCheck.dispose();
				targetBGLineCheck = null;
			}
			
			if (urgentHighLineCheck != null)
			{
				urgentHighLineCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				urgentHighLineCheck.dispose();
				urgentHighLineCheck = null;
			}
			
			if (highLineCheck != null)
			{
				highLineCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				highLineCheck.dispose();
				highLineCheck = null;
			}
			
			if (lowLineCheck != null)
			{
				lowLineCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				lowLineCheck.dispose();
				lowLineCheck = null;
			}
			
			if (urgentLowLineCheck != null)
			{
				urgentLowLineCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				urgentLowLineCheck.dispose();
				urgentLowLineCheck = null;
			}
			
			super.dispose();
		}
	}
}