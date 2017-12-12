package display.transmitter
{
	
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
	import starling.textures.Texture;
	
	import utils.Constants;

	public class TransmitterStatusList extends GroupedList 
	{
		/* Display Objects */
		private var voltageAIcon:Texture;
		private var voltageAIconImage:Image;
		private var voltageALabel:Label;
		private var voltageBIcon:Texture;
		private var voltageBIconImage:Image;
		private var voltageBLabel:Label;
		private var resistanceIcon:Texture;
		private var resistanceIconImage:Image;
		private var resistanceLabel:Label;
		private var transmitterTypeLabel:Label;
		private var transmitterNameLabel:Label;

		public function TransmitterStatusList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			/* Set Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			layoutData = new VerticalLayoutData( 100 );
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			/* Define Battery Status Icons*/
			voltageAIcon = MaterialDeepGreyAmberMobileThemeIcons.batteryOkTexture;
			voltageAIconImage = new Image(voltageAIcon);
			voltageBIcon = MaterialDeepGreyAmberMobileThemeIcons.batteryAlertTexture;
			voltageBIconImage = new Image(voltageBIcon);
			resistanceIcon = MaterialDeepGreyAmberMobileThemeIcons.batteryBadTexture;
			resistanceIconImage = new Image(resistanceIcon);
			
			/* Define Battery Status Labels */
			transmitterTypeLabel = LayoutFactory.createLabel("Dexcom G5", HorizontalAlign.RIGHT);
			transmitterNameLabel = LayoutFactory.createLabel("DexcomWK", HorizontalAlign.RIGHT);
			voltageALabel = LayoutFactory.createLabel("312", HorizontalAlign.RIGHT);
			voltageBLabel = LayoutFactory.createLabel("265", HorizontalAlign.RIGHT);
			resistanceLabel = LayoutFactory.createLabel("1800", HorizontalAlign.RIGHT);
			
			/* Set Data */
			dataProvider = new HierarchicalCollection(
				[
					{
						header  : { label: "Info" },
						children: [
							{ label: "Data Source", accessory: transmitterTypeLabel },
							{ label: "Device Name", accessory: transmitterNameLabel },
						]
					},
					{
						header  : { label: "Battery" },
						children: [
							{ label: "Voltage A", accessory: voltageALabel, icon: voltageAIconImage },
							{ label: "Voltage B", accessory: voltageBLabel, icon: voltageBIconImage },
							{ label: "Resistance", accessory: resistanceLabel, icon: resistanceIconImage },
						]
					},
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
		
		override public function dispose():void
		{
			if(voltageAIcon != null)
			{
				voltageAIcon.dispose();
				voltageAIcon = null;
				voltageAIconImage.dispose();
				voltageAIconImage = null;
				voltageALabel.dispose();
				voltageALabel = null;
			}
			
			if(voltageBIcon != null)
			{
				voltageBIcon.dispose();
				voltageBIcon = null;
				voltageBIconImage.dispose();
				voltageAIconImage = null;
				voltageBLabel.dispose();
				voltageBLabel = null;
			}
			
			if(resistanceIcon != null)
			{
				resistanceIcon.dispose();
				resistanceIcon = null;
				resistanceIconImage.dispose();
				resistanceIconImage = null;
				resistanceLabel.dispose();
				resistanceLabel = null;
			}
			
			if(transmitterTypeLabel != null)
			{
				transmitterTypeLabel.dispose();
				transmitterTypeLabel = null;
			}
			
			if(transmitterNameLabel != null)
			{
				transmitterNameLabel.dispose();
				transmitterNameLabel = null;
			}

			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}