package screens
{
	import display.sensor.SensorStartStopList;
	
	import feathers.controls.GroupedList;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.DisplayObject;
	
	import ui.AppInterface;
	
	import utils.Constants;

	public class SensorScreen extends BaseSubScreen
	{	
		public function SensorScreen() 
		{
			super();
			
			/* Set Header Title */
			title = "Sensor";
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.sensorTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupScreen();
			adjustMainMenu();
		}
		
		private function setupScreen():void
		{
			var statusList:GroupedList = new SensorStartStopList();
			screenRenderer.addChild(statusList);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = 1;
		}
		
		override protected function draw():void 
		{
			super.draw();
			
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}