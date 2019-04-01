package ui.screens.display.settings.about
{
	
	import flash.display.StageOrientation;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import database.LocalSettings;
	
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListHeaderRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.AppInterface;
	import ui.screens.Screens;
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("aboutsettingsscreen")]

	public class AboutList extends GroupedList 
	{
		/*Display Objects */
		private var appNameLabel:Label;
		private var appVersionLabel:Label;
		private var deviceRequirementsLabel:Label;
		private var osRequirementsLabel:Label
		private var hardwareRequerimentsLabel:Label;
		private var facebookGroupButton:Button;
		private var websiteButton:Button;
		
		public function AboutList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
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
			layoutData = new VerticalLayoutData( 100 );
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupContent():void
		{
			/* Set Info Labels */
			appNameLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','app_name_description'), HorizontalAlign.RIGHT);
			appVersionLabel = LayoutFactory.createLabel(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_APPLICATION_VERSION), HorizontalAlign.RIGHT);
			deviceRequirementsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','device_description_label') + (DeviceInfo.isIpad() ? "\n\n" + ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','ipad_device_description_label') : ""));
			deviceRequirementsLabel.width = 170;
			deviceRequirementsLabel.wordWrap = true;
			deviceRequirementsLabel.fontStyles.horizontalAlign = HorizontalAlign.RIGHT;
			deviceRequirementsLabel.validate();
			osRequirementsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','os_description'), HorizontalAlign.RIGHT);
			hardwareRequerimentsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','hardware_description'), HorizontalAlign.RIGHT);
			facebookGroupButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','go_button'), false, MaterialDeepGreyAmberMobileThemeIcons.facebookButtonTexture);
			facebookGroupButton.gap = 2;
			facebookGroupButton.pivotX = -4;
			facebookGroupButton.addEventListener(Event.TRIGGERED, onNavigateToFacebook);
			websiteButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','go_button'), false, MaterialDeepGreyAmberMobileThemeIcons.spikeButtonTexture);
			websiteButton.gap = 2;
			websiteButton.pivotX = -4;
			websiteButton.addEventListener(Event.TRIGGERED, onNavigateToWebsite);
			
			/* Set Screen Content */
			dataProvider = new HierarchicalCollection(
				[
					{
						header  : { label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','info_section_title') },
						children: [
							{ label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','app_name_label'), accessory: appNameLabel },
							{ label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','app_version_label'), accessory: appVersionLabel }
						]
					},
					{
						header  : { label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','requirements_section_title') },
						children: [
							{ label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','device_label'), accessory: deviceRequirementsLabel },
							{ label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','hardware_label'), accessory: hardwareRequerimentsLabel },
							{ label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','os_label'), accessory: osRequirementsLabel }
						]
					},
					{
						header  : { label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','support_section_title') },
						children: [
							{ label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','facebook_group_label'), accessory: facebookGroupButton },
							{ label: ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','website_label'), accessory: websiteButton }
						]
					}
				]
			);	
			
			/* Set Content Renderer */
			itemRendererFactory = function ():IGroupedListItemRenderer {
				const itemRenderer:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.iconField = "icon";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.gap = 8;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					itemRenderer.paddingLeft = 30;
				else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					itemRenderer.paddingRight = 30;
				itemRenderer.labelFunction = function( item:Object ):String
				{
					if (item.label == ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','device_label'))
					{
						itemRenderer.verticalAlign = VerticalAlign.TOP;
						itemRenderer.paddingBottom = itemRenderer.paddingTop = 15;
					}
					
					return item.label;
				};
				
				return itemRenderer;
			};
			
			headerRendererFactory = function():IGroupedListHeaderRenderer
			{
				var headerRenderer:DefaultGroupedListHeaderOrFooterRenderer = new DefaultGroupedListHeaderOrFooterRenderer();
				headerRenderer.contentLabelField = "label";
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						headerRenderer.paddingLeft = 30;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						headerRenderer.paddingRight = 30;
					}
				}
				
				return headerRenderer;
			};
		}
		
		/**
		 * Event Handlers
		 */
		private function onNavigateToFacebook(e:Event):void
		{
			navigateToURL(new URLRequest("https://www.facebook.com/groups/spikeapp/"));
		}
		
		private function onNavigateToWebsite(e:Event):void
		{
			navigateToURL(new URLRequest("https://spike-app.com"));
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			SystemUtil.executeWhenApplicationIsActive( AppInterface.instance.navigator.replaceScreen, Screens.SETTINGS_ABOUT, noTransition);
			
			function noTransition( oldScreen:DisplayObject, newScreen:DisplayObject, completeCallback:Function ):void
			{
				completeCallback();
			};
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if(appNameLabel != null)
			{
				appNameLabel.dispose();
				appNameLabel = null;
			}
			
			if(appVersionLabel != null)
			{
				appVersionLabel.dispose();
				appVersionLabel = null;
			}
			
			if(deviceRequirementsLabel != null)
			{
				deviceRequirementsLabel.dispose();
				deviceRequirementsLabel = null;
			}
			
			if(osRequirementsLabel != null)
			{
				osRequirementsLabel.dispose();
				osRequirementsLabel = null;
			}
			
			if(hardwareRequerimentsLabel != null)
			{
				hardwareRequerimentsLabel.dispose();
				hardwareRequerimentsLabel = null;
			}
			
			if (facebookGroupButton != null)
			{
				facebookGroupButton.addEventListener(Event.TRIGGERED, onNavigateToFacebook);
				facebookGroupButton.dispose();
				facebookGroupButton = null;
			}
			
			if (websiteButton != null)
			{
				websiteButton.addEventListener(Event.TRIGGERED, onNavigateToWebsite);
				websiteButton.dispose();
				websiteButton = null;
			}

			super.dispose();
		}
	}
}