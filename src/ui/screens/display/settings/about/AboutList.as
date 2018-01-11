package ui.screens.display.settings.about
{
	
	import databaseclasses.LocalSettings;
	
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import ui.screens.display.LayoutFactory;
	
	import utilities.Constants;
	
	[ResourceBundle("aboutsettingsscreen")]

	public class AboutList extends GroupedList 
	{
		/*Display Objects */
		private var appNameLabel:Label;
		private var appVersionLabel:Label;
		private var deviceRequirementsLabel:Label;
		private var osRequirementsLabel:Label
		private var hardwareRequerimentsLabel:Label;
		
		public function AboutList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
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
			deviceRequirementsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','device_description_label'));
			deviceRequirementsLabel.width = 170;
			deviceRequirementsLabel.wordWrap = true;
			deviceRequirementsLabel.fontStyles.horizontalAlign = HorizontalAlign.RIGHT;
			deviceRequirementsLabel.paddingTop = deviceRequirementsLabel.paddingBottom = 10;
			deviceRequirementsLabel.validate();
			osRequirementsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','os_description'), HorizontalAlign.RIGHT);
			hardwareRequerimentsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('aboutsettingsscreen','hardware_description'), HorizontalAlign.RIGHT);
			
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
					}
				]
			);	
			
			/* Set Content Renderer */
			this.itemRendererFactory = function ():IGroupedListItemRenderer {
				const item:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.accessoryField = "accessory";
				item.gap = 8;
				return item;
			};
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
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

			super.dispose();
		}
	}
}