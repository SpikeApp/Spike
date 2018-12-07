package ui.screens.display.settings.maintenance
{
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.Forecast;
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.TreatmentsManager;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	
	[ResourceBundle("maintenancesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class CacheMaintenanceSettingsList extends SpikeList
	{
		/* Display Objects */
		private var clearCachesButton:Button;
		
		public function CacheMaintenanceSettingsList()
		{
			super(true);
			
			setupProperties();
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
		
		private function setupContent():void
		{
			//Clear Caches Button
			clearCachesButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','clear_cache_button_label'));
			clearCachesButton.addEventListener(starling.events.Event.TRIGGERED, onClearCaches);
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Set Data
			var data:Array = [];
			data.push( { label: ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','actions_label'), accessory: clearCachesButton } );
			
			dataProvider = new ArrayCollection( data );
		}
		
		/**
		 * Event Listeners
		 */
		private function onClearCaches(e:starling.events.Event):void
		{
			var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('globaltranslations','cant_be_undone'),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase") },
						{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: clearCaches }
					],
					HorizontalAlign.CENTER
				);
			alert.buttonGroupProperties.gap = 10;
			alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			function clearCaches(e:Event):void
			{
				TreatmentsManager.clearAllCaches();
				Forecast.clearAllCaches();
				
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','info_alert_title'),
					ModelLocator.resourceManagerInstance.getString('maintenancesettingsscreen','caches_deleted_successfully_message')
				);
			}	
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			if (this.layout != null)
				(this.layout as VerticalLayout).hasVariableItemDimensions = true;
			
			super.draw();
		}
		
		override public function dispose():void
		{
			if (clearCachesButton != null)
			{
				clearCachesButton.removeEventListener(starling.events.Event.TRIGGERED, onClearCaches);
				clearCachesButton.removeFromParent();
				clearCachesButton.dispose();
				clearCachesButton = null;
			}
			
			super.dispose();
		}
	}
}