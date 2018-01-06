package screens
{
	import data.AlarmNavigatorData;
	
	import display.settings.alarms.AlarmCustomizerList;
	
	import feathers.controls.Alert;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.AlertManager;
	import utils.Constants;
	
	[ResourceBundle("globaltranslations")]

	public class AlarmsCustomizerSettingsScreen extends BaseSubScreen
	{
		/* Display Objects */
		private var alarmCustomizer:AlarmCustomizerList;
		
		/* Properties */
		protected var _options:AlarmNavigatorData;

		public function AlarmsCustomizerSettingsScreen() 
		{
			super();;
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.alarmTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			/* Set Header Title */
			title = _options.alarmTitle;
			
			alarmCustomizer = new AlarmCustomizerList(_options.alarmID, _options.alarmType);
			alarmCustomizer.addEventListener(Event.COMPLETE, onSkipSaveSettings);
			screenRenderer.addChild(alarmCustomizer);
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
			alarmCustomizer.closeCallout();
			
			if(alarmCustomizer.needsSave)
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
			alarmCustomizer.save()
			dispatchEventWith(Event.COMPLETE);
		}
		
		private function onSkipSaveSettings(e:Event):void
		{
			dispatchEventWith(Event.COMPLETE);
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

		/**
		 * Getters & Setters
		 */
		public function get options():AlarmNavigatorData
		{
			return _options;
		}

		public function set options(value:AlarmNavigatorData):void
		{	
			_options = value;
			
			setupContent();
			adjustMainMenu();
			this.invalidate( INVALIDATION_FLAG_DATA );
		}
	}
}