package ui.screens.display.settings.widget
{
	import database.CommonSettings;
	
	import feathers.controls.Check;
	import feathers.controls.List;
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
	
	public class ChartSettingsList extends List
	{
		/* Display Objects */
		private var smoothLineCheck:Check;
		private var showMarkersCheck:Check;
		private var showMarkerLabelCheck:Check;
		private var showGridLinesCheck:Check;
		
		/* Variables */
		public var needsSave:Boolean = false;
		private var smoothLineValue:Boolean;
		private var showMarkersValue:Boolean;
		private var showMarkerLabelValue:Boolean;
		private var showGridLinesValue:Boolean;
		
		public function ChartSettingsList()
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
			smoothLineValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SMOOTH_LINE) == "true";
			showMarkersValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKERS) == "true";
			showMarkerLabelValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL) == "true";
			showGridLinesValue = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_GRID_LINES) == "true";
		}
		
		private function setupContent():void
		{
			//Smooth Line
			smoothLineCheck = LayoutFactory.createCheckMark(smoothLineValue);
			smoothLineCheck.pivotX = 3;
			smoothLineCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Show Markers
			showMarkersCheck = LayoutFactory.createCheckMark(showMarkersValue);
			showMarkersCheck.pivotX = 3;
			showMarkersCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Show Marker Label
			showMarkerLabelCheck = LayoutFactory.createCheckMark(showMarkerLabelValue);
			showMarkerLabelCheck.pivotX = 3;
			showMarkerLabelCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Show Grid Lines
			showGridLinesCheck = LayoutFactory.createCheckMark(showGridLinesValue);
			showGridLinesCheck.pivotX = 3;
			showGridLinesCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
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
					{ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','smooth_line_label'), accessory: smoothLineCheck },
					{ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','show_markers_label'), accessory: showMarkersCheck },
					{ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','show_marker_label_label'), accessory: showMarkerLabelCheck },
					{ label: ModelLocator.resourceManagerInstance.getString('widgetsettingsscreen','show_grid_lines_label'), accessory: showGridLinesCheck }
				]
			);
		}
		
		public function save():void
		{
			if (!needsSave)
				return;
			
			//Smooth Line
			var smoothLineValueToSave:String;
			if (smoothLineValue) smoothLineValueToSave = "true";
			else smoothLineValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SMOOTH_LINE) != smoothLineValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SMOOTH_LINE, smoothLineValueToSave);
			
			//Show Markers
			var showMarkersValueToSave:String;
			if (showMarkersValue) showMarkersValueToSave = "true";
			else showMarkersValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKERS) != showMarkersValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKERS, showMarkersValueToSave);
			
			//Show Marker Label
			var showMarkerLabelValueToSave:String;
			if (showMarkerLabelValue) showMarkerLabelValueToSave = "true";
			else showMarkerLabelValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL) != showMarkerLabelValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_MARKER_LABEL, showMarkerLabelValueToSave);
			
			//Show Grid Lines
			var showGridLinesValueToSave:String;
			if (showGridLinesValue) showGridLinesValueToSave = "true";
			else showGridLinesValueToSave = "false";
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_GRID_LINES) != showGridLinesValueToSave)
				CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_WIDGET_SHOW_GRID_LINES, showGridLinesValueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			smoothLineValue = smoothLineCheck.isSelected;
			showMarkersValue = showMarkersCheck.isSelected;
			showMarkerLabelValue = showMarkerLabelCheck.isSelected;
			showGridLinesValue = showGridLinesCheck.isSelected;
			
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
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (smoothLineCheck != null)
			{
				smoothLineCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				smoothLineCheck.dispose();
				smoothLineCheck = null;
			}
			
			if (showMarkersCheck != null)
			{
				showMarkersCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				showMarkersCheck.dispose();
				showMarkersCheck = null;
			}
			
			if (showMarkerLabelCheck != null)
			{
				showMarkerLabelCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				showMarkerLabelCheck.dispose();
				showMarkerLabelCheck = null;
			}
			
			if (showGridLinesCheck != null)
			{
				showGridLinesCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				showGridLinesCheck.dispose();
				showGridLinesCheck = null;
			}
			
			super.dispose();
		}
	}
}