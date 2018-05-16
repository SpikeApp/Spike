package ui.screens.display.settings.widget
{
	import database.CommonSettings;
	
	import feathers.controls.List;
	import feathers.controls.NumericStepper;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("widgetsettingsscreen")]
	
	public class SizeSettingsList extends List
	{
		/* Display Objects */
		private var lineThicknessStepper:NumericStepper;
		private var markerRadiusStepper:NumericStepper;
		
		/* Variables */
		public var needsSave:Boolean = false;
		private var lineThicknessValue:int;
		private var markerRadiusValue:int;
		
		public function SizeSettingsList()
		{
			super();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			stupInitialContent();
			setupContent();
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function stupInitialContent():void
		{
			lineThicknessValue = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LINE_THICKNESS));
			markerRadiusValue = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MARKER_RADIUS));
		}
		
		private function setupContent():void
		{
			//Line Thickness Stepper
			lineThicknessStepper = LayoutFactory.createNumericStepper(1, 3, lineThicknessValue);
			lineThicknessStepper.pivotX = -8;
			lineThicknessStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Marker Radius Stepper
			markerRadiusStepper = LayoutFactory.createNumericStepper(3, 7, markerRadiusValue);
			markerRadiusStepper.pivotX = -8;
			markerRadiusStepper.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
			//Set Data
			dataProvider = new ArrayCollection
			(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','line_thickness_label'), accessory: lineThicknessStepper },
					{ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','marker_radius_label'), accessory: markerRadiusStepper }
				]
			);
		}
		
		public function save():void
		{
			if (!needsSave)
				return;
			
			//Line Thickness
			var lineThicknessValueToSave:String = String(lineThicknessValue);
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LINE_THICKNESS) != lineThicknessValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_LINE_THICKNESS, lineThicknessValueToSave);
			
			//Marker Radius
			var markerRadiusValueToSave:String = String(markerRadiusValue);
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MARKER_RADIUS) != markerRadiusValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_MARKER_RADIUS, markerRadiusValueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			lineThicknessValue = lineThicknessStepper.value;
			markerRadiusValue = markerRadiusStepper.value;
			
			needsSave = true;
			
			save();
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (lineThicknessStepper != null)
			{
				lineThicknessStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				lineThicknessStepper.dispose();
				lineThicknessStepper = null;
			}
			
			if (markerRadiusStepper != null)
			{
				markerRadiusStepper.removeEventListener(Event.CHANGE, onSettingsChanged);
				markerRadiusStepper.dispose();
				markerRadiusStepper = null;
			}
			
			super.dispose();
		}
	}
}