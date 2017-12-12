package screens
{
	import data.AlarmNavigatorData;
	
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class AlarmsCustomizerSettingsScreen extends BaseSubScreen
	{
		protected var _options:AlarmNavigatorData;
		
		public function AlarmsCustomizerSettingsScreen() 
		{
			super();;
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.alarmTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		override protected function initialize():void 
		{
			super.initialize();
		}
		
		private function setupContent():void
		{
			/* Set Header Title */
			title = options.selectedAlarmTitle;
			
			//Settings Label
			//var alarmSettingsLabel:Label = LayoutFactory.createSectionLabel("Options");
			//screenRenderer.addChild(alarmSettingsLabel);
			
			//Settings List
			//var alarmSettings:AlarmCustomizerList = new AlarmCustomizerList();
			//screenRenderer.addChild(alarmSettings);
			
			//Schedule Label
			//var alarmScheduleLabel:Label = LayoutFactory.createSectionLabel("Schedule");
			//screenRenderer.addChild(alarmScheduleLabel);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 3;
		}
		
		override protected function onBackButtonTriggered(event:Event):void
		{
			dispatchEventWith(Event.COMPLETE);
		}
		
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
			if(_options == value)
				return;
			
			_options = value;
			
			setupContent();
			adjustMainMenu();
			this.invalidate( INVALIDATION_FLAG_DATA );
		}
	}
}