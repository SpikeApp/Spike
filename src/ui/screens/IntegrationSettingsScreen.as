package ui.screens
{
	import flash.display.StageOrientation;
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
	
	import feathers.controls.DragGesture;
	import feathers.controls.Label;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.AppInterface;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.settings.integration.HTTPServerSettingsList;
	import ui.screens.display.settings.integration.IFTTTSettingsChooser;
	import ui.screens.display.settings.integration.PebbleSettingsChooser;
	import ui.screens.display.settings.integration.SiDiarySettingsList;
	import ui.screens.display.settings.integration.WorkflowSettingsChooser;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("integrationsettingsscreen")]

	public class IntegrationSettingsScreen extends BaseSubScreen
	{	
		/* Display Objects */
		private var httpServerSettings:HTTPServerSettingsList;
		private var httpServerSectionLabel:Label;
		private var siDiaryLabel:Label;
		private var siDiarySettings:SiDiarySettingsList;
		private var httpServerSectionSubLabel:Label;
		private var iFTTTLabel:Label;
		private var iFTTTSettingsChooser:IFTTTSettingsChooser;
		private var workflowLabel:Label;
		private var workflowSettingsChooser:WorkflowSettingsChooser;
		private var pebbleLabel:Label;
		private var pebbleSettingsChooser:PebbleSettingsChooser;
		
		public function IntegrationSettingsScreen() 
		{
			super();
			
			setupHeader();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupContent();
			adjustMainMenu();
		}
		
		/**
		 * Functionality
		 */
		private function setupHeader():void
		{
			/* Set Header Title */
			title = ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','screen_title');
			
			/* Set Header Icon */
			icon = getScreenIcon(MaterialDeepGreyAmberMobileThemeIcons.integrationTexture);
			iconContainer = new <DisplayObject>[icon];
			headerProperties.rightItems = iconContainer;
		}
		
		private function setupContent():void
		{
			//Deactivate menu drag gesture 
			AppInterface.instance.drawers.openGesture = DragGesture.NONE;
			
			//IFTTT Section Label
			iFTTTLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','ifttt_label'));
			screenRenderer.addChild(iFTTTLabel);
			
			//IFTTT Settings
			iFTTTSettingsChooser = new IFTTTSettingsChooser();
			screenRenderer.addChild(iFTTTSettingsChooser);
			
			//Workflow Section Label
			workflowLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','workflow_label'));
			screenRenderer.addChild(workflowLabel);
			
			//Workflow Settings
			workflowSettingsChooser = new WorkflowSettingsChooser();
			screenRenderer.addChild(workflowSettingsChooser);
			
			//Pebble Section Label
			pebbleLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','pebble_label'));
			screenRenderer.addChild(pebbleLabel);
			
			//Workflow Settings
			pebbleSettingsChooser = new PebbleSettingsChooser();
			screenRenderer.addChild(pebbleSettingsChooser);
			
			if (!CGMBlueToothDevice.isFollower())
			{
				//SiDiary Section Label
				siDiaryLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','sidiary_section_label'));
				screenRenderer.addChild(siDiaryLabel);
				
				//SiDiary Settings
				siDiarySettings = new SiDiarySettingsList();
				screenRenderer.addChild(siDiarySettings);
			}
			
			//HTTP Server Section Label
			httpServerSectionLabel = LayoutFactory.createSectionLabel(ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','server_section_label'));
			screenRenderer.addChild(httpServerSectionLabel);
			
			//HTTP Server Section Sublabel
			httpServerSectionSubLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('integrationsettingsscreen','server_section_sublabel'), HorizontalAlign.LEFT, VerticalAlign.TOP, 11, true);
			screenRenderer.addChild(httpServerSectionSubLabel);
			
			//HTTP Server Settings
			httpServerSettings = new HTTPServerSettingsList();
			screenRenderer.addChild(httpServerSettings);
		}
		
		private function adjustMainMenu():void
		{
			AppInterface.instance.menu.selectedIndex = Constants.isPortrait ? 4 : 3;
		}
		
		/**
		 * Event Handlers
		 */
		override protected function onBackButtonTriggered(event:Event):void
		{
			//Save Settings
			if (httpServerSettings.needsSave)
				httpServerSettings.save();
			
			//Activate menu drag gesture
			AppInterface.instance.drawers.openGesture = DragGesture.EDGE;
			
			//Pop Screen
			dispatchEventWith(Event.COMPLETE);
		}
		
		override protected function onTransitionInComplete(e:Event):void
		{
			//Swipe to pop functionality
			AppInterface.instance.navigator.isSwipeToPopEnabled = true;
		}
		
		override protected function onStarlingBaseResize(e:ResizeEvent):void 
		{
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
			{
				if (iFTTTLabel != null) iFTTTLabel.paddingLeft = 30;
				if (workflowLabel != null) workflowLabel.paddingLeft = 30;
				if (pebbleLabel != null) pebbleLabel.paddingLeft = 30;
				if (siDiaryLabel != null) siDiaryLabel.paddingLeft = 30;
				if (httpServerSectionLabel != null) httpServerSectionLabel.paddingLeft = 30;
				if (httpServerSectionSubLabel != null) httpServerSectionSubLabel.paddingLeft = 30;
			}
			else
			{
				if (iFTTTLabel != null) iFTTTLabel.paddingLeft = 0;
				if (workflowLabel != null) workflowLabel.paddingLeft = 0;
				if (pebbleLabel != null) pebbleLabel.paddingLeft = 0;
				if (siDiaryLabel != null) siDiaryLabel.paddingLeft = 0;
				if (httpServerSectionLabel != null) httpServerSectionLabel.paddingLeft = 0;
				if (httpServerSectionSubLabel != null) httpServerSectionSubLabel.paddingLeft = 0;
			}
			
			setupHeaderSize();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (httpServerSettings != null)
			{
				httpServerSettings.removeFromParent();
				httpServerSettings.dispose();
				httpServerSettings = null;
			}
			
			if (httpServerSectionLabel != null)
			{
				httpServerSectionLabel.removeFromParent();
				httpServerSectionLabel.dispose();
				httpServerSectionLabel = null;
			}
			
			if (siDiaryLabel != null)
			{
				siDiaryLabel.removeFromParent();
				siDiaryLabel.dispose();
				siDiaryLabel = null;
			}
			
			if (siDiarySettings != null)
			{
				siDiarySettings.removeFromParent();
				siDiarySettings.dispose();
				siDiarySettings = null;
			}
			
			if (iFTTTLabel != null)
			{
				iFTTTLabel.removeFromParent();
				iFTTTLabel.dispose();
				iFTTTLabel = null;
			}
			
			if (iFTTTSettingsChooser != null)
			{
				iFTTTSettingsChooser.removeFromParent();
				iFTTTSettingsChooser.dispose();
				iFTTTSettingsChooser = null;
			}
			
			if (workflowLabel != null)
			{
				workflowLabel.removeFromParent();
				workflowLabel.dispose();
				workflowLabel = null;
			}
			
			if (workflowSettingsChooser != null)
			{
				workflowSettingsChooser.removeFromParent();
				workflowSettingsChooser.dispose();
				workflowSettingsChooser = null;
			}
			
			if (pebbleLabel != null)
			{
				pebbleLabel.removeFromParent();
				pebbleLabel.dispose();
				pebbleLabel = null;
			}
			
			if (pebbleSettingsChooser != null)
			{
				pebbleSettingsChooser.removeFromParent();
				pebbleSettingsChooser.dispose();
				pebbleSettingsChooser = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
		}
		
		override protected function draw():void 
		{
			var layoutInvalid:Boolean = isInvalid( INVALIDATION_FLAG_LAYOUT );
			super.draw();
			icon.x = Constants.stageWidth - icon.width - BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding;
		}
	}
}