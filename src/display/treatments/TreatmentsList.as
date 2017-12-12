package display.treatments
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.Alert;
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalAlign;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;

	public class TreatmentsList extends List 
	{

		/* Display Objects */
		private var iconTexture:Texture;
		private var iconImage:Image;
		
		/* Properties */
		private var calibrationValue:TextInput;
		
		public function TreatmentsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			
			iconTexture = MaterialDeepGreyAmberMobileThemeIcons.calibrationTexture;
			iconImage = new Image(iconTexture);
			
			
			dataProvider = new ListCollection(
				[
					{ label: "Calibration", icon: iconImage, id: 1 }
				]);
			
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.gap = 5;
				item.paddingLeft = 8;
				item.paddingRight = 14;
				item.isQuickHitAreaEnabled = true;
				return item;
			};
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		private function onMenuChanged(e:Event):void 
		{
			const treatmentID:Number = selectedItem.id as Number;
			
			if(treatmentID == 1) //Calibration
			{
				/* Create and Style Calibration Text Input */
				calibrationValue = LayoutFactory.createTextInput(false, true, 135, HorizontalAlign.RIGHT);
				calibrationValue.maxChars = 3;
				calibrationValue.paddingRight = 10;
				
				/* Create and Style Popup Window */
				var calibrationPopup:Alert = Alert.show(
					"",
					"Enter BG Value",
					new ListCollection(
						[
							{ label: "CANCEL" },
							{ label: "ADD", triggered: onEnterCalibration }
						]
					),
					calibrationValue
				);
				calibrationPopup.gap = 0;
				calibrationPopup.headerProperties.maxHeight = 30;
				calibrationPopup.buttonGroupProperties.paddingTop = -10;
				calibrationPopup.buttonGroupProperties.paddingRight = 24;
			}
		}
		
		private function onEnterCalibration(event:Event):void
		{
			//TODO: Apply calibration
			//trace("Calibration Value:", calibrationValue.text);
		}
		
		override public function dispose():void
		{
			if (iconTexture != null)
			{
				iconTexture.dispose();
				iconTexture = null;
			}
			
			if (iconImage != null)
			{
				iconImage.dispose();
				iconImage = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}