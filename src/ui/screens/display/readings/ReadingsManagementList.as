package ui.screens.display.readings
{
	import mx.utils.ObjectUtil;
	
	import database.AlertType;
	import database.BgReading;
	import database.CommonSettings;
	import database.Database;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.text.TextFormat;
	
	import ui.screens.display.settings.alarms.AlertManagerAccessory;
	
	import utils.BgGraphBuilder;
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]

	public class ReadingsManagementList extends List 
	{
		/* Display Objects */
		
		/* Objects */
		private var accessoriesList:Array = [];
		
		/* Properties */
		private var urgentLowThreshold:Number;
		private var lowThreshold:Number;
		private var highThreshold:Number;
		private var urgentHighThreshold:Number;
		private var lowColor:uint;
		private var inRangeColor:uint;
		private var highColor:uint;
		private var urgentHighColor:uint;
		private var urgentLowColor:uint;
		
		public function ReadingsManagementList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
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
		
		private function setupInitialContent():void
		{
			urgentLowThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_LOW_MARK));
			lowThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK));
			highThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK));
			urgentHighThreshold = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_URGENT_HIGH_MARK));
			
			urgentLowColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_LOW_COLOR));
			lowColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_LOW_COLOR));
			inRangeColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_IN_RANGE_COLOR));
			highColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_HIGH_COLOR));
			urgentHighColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_URGENT_HIGH_COLOR));
		}
		
		private function setupContent():void
		{
			///Notifications On/Off Toggle
			
			
			//Define Notifications Settings Data
			var dataList:Array = [];
			var readingsList:Array = ModelLocator.bgReadings;
			
			for(var i:int = readingsList.length - 1 ; i >= 0; i--)
			{
				var reading:BgReading = readingsList[i];
				var glucoseValue:String = BgGraphBuilder.unitizedString(reading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
				var deleteButton:Button = new Button();
				deleteButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.deleteForeverTexture);
				deleteButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
				deleteButton.addEventListener(Event.TRIGGERED, onDeleteReading);
				accessoriesList.push(deleteButton);
				dataList.push({ label: glucoseValue, accessory: deleteButton, bgReading: reading, id: i });
			}
			
			dataProvider = new ArrayCollection(dataList);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				
				return item;
			};
			
			var urgentHighTextFormat:TextFormat = new TextFormat("Roboto", 14, urgentHighColor);
			function urgentHighItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.fontStyles = urgentHighTextFormat;
				
				return item;
			}
			
			var highTextFormat:TextFormat = new TextFormat("Roboto", 14, highColor);
			function highItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.fontStyles = highTextFormat;
				
				return item;
			}
			
			var inRangeTextFormat:TextFormat = new TextFormat("Roboto", 14, inRangeColor);
			inRangeTextFormat.bold = true;
			function inRangeItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.fontStyles = inRangeTextFormat;
				
				return item;
			}
			
			var lowTextFormat:TextFormat = new TextFormat("Roboto", 14, lowColor);
			function lowItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.fontStyles = lowTextFormat;
				
				return item;
			}
			
			var urgentLowTextFormat:TextFormat = new TextFormat("Roboto", 14, urgentLowColor);
			function urgentLowItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.fontStyles = urgentLowTextFormat;
				
				return item;
			}
			
			setItemRendererFactoryWithID( "urgent-high-item", urgentHighItemFactory );
			setItemRendererFactoryWithID( "high-item", highItemFactory );
			setItemRendererFactoryWithID( "in-range-item", inRangeItemFactory );
			setItemRendererFactoryWithID( "low-item", lowItemFactory );
			setItemRendererFactoryWithID( "urgent-low-item", urgentLowItemFactory );
			
			factoryIDFunction = function( item:Object, index:int ):String
			{
				var glucoseValue:Number = Number(item.label);
				
				if (glucoseValue >= urgentHighThreshold)
					return "urgent-high-item";
				else if (glucoseValue >= highThreshold)
					return "high-item";
				else if (glucoseValue > lowThreshold && glucoseValue < highThreshold)
					return "in-range-item";
				else if (glucoseValue <= lowThreshold && glucoseValue > urgentLowThreshold)
					return "low-item";
				else
					return "urgent-low-item";
				
				return "default-item";
			};
		}
		
		/**
		 * Event Handlers
		 */
		private function onDeleteReading(e:Event):void
		{
			var bgReading:BgReading = (((e.currentTarget as Button).parent as DefaultListItemRenderer).data as Object).bgReading as BgReading;
			var id:int = (((e.currentTarget as Button).parent as DefaultListItemRenderer).data as Object).id;
			
			ModelLocator.bgReadings.removeAt(id);
			Database.deleteBgReadingSynchronous(bgReading);
			setupContent();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			
			
			super.dispose();
		}
	}
}