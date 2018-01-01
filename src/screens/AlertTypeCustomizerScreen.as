package screens
{
	import data.AlertNavigatorData;
	
	import databaseclasses.AlertType;
	
	import display.settings.alarms.AlertCustomizerList;
	
	import feathers.controls.Alert;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.AlertManager;
	import utils.Constants;
	
	[ResourceBundle("alertsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class AlertTypeCustomizerScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var alertSettings:AlertCustomizerList;
		
		/* Internal Variables / Objects */
		private var settingsSaved:Boolean = true;
		protected var _options:AlertNavigatorData;
		private var selectedAlertType:AlertType;
		
		public function AlertTypeCustomizerScreen() 
		{
			super();
		}
		
		/**
		 * Functionality
		 */
		private function setupInitialContent():void
		{
			selectedAlertType = _options.alertData as AlertType;
			
			/* Set Header Title */
			if (selectedAlertType == null)
				title = ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alert_type_customizer_new_screen_title");
			else
				title = selectedAlertType.alarmName;
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.alertTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
			
		}
		
		private function setupContent():void
		{
			alertSettings = new AlertCustomizerList(selectedAlertType);
			alertSettings.addEventListener(Event.COMPLETE, onSkipSaveSettings);
			screenRenderer.addChild(alertSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		/**
		 * Event Listeners
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			if(alertSettings.needsSave)
			{
				var alert:Alert = AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations',"save_changes"),
					ModelLocator.resourceManagerInstance.getString('globaltranslations',"want_to_save_changes"),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"no_uppercase"), triggered: onSkipSaveSettings },
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"yes_uppercase"), triggered: onSaveSettings }
					]
				);
			}
			else
				dispatchEventWith(Event.COMPLETE);
		}
		
		private function onSaveSettings(e:Event):void
		{
			if(alertSettings.save())
				dispatchEventWith(Event.COMPLETE);
		}
		
		private function onSkipSaveSettings(e:Event):void
		{
			dispatchEventWith(Event.COMPLETE);
		}
		
		/**
		 * Getters & Setters
		 */
		public function get options():AlertNavigatorData
		{
			return _options;
		}
		
		public function set options(value:AlertNavigatorData):void
		{	
			if(_options == value)
				return;
			
			_options = value;
			
			setupInitialContent();
			setupContent();
			adjustMainMenu();
			
			this.invalidate( INVALIDATION_FLAG_DATA );
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}