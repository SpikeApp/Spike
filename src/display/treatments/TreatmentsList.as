package display.treatments
{
	import flash.system.System;
	
	import databaseclasses.Calibration;
	
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.CalibrationService;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	[ResourceBundle("chartscreen")]

	public class TreatmentsList extends List 
	{

		/* Display Objects */
		private var iconTexture:Texture;
		private var iconImage:Image;
		
		/* Properties */
		private var calibrationButtonEnabled:Boolean = false;
		
		public function TreatmentsList()
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
			/* Properties */
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			
			iconTexture = MaterialDeepGreyAmberMobileThemeIcons.calibrationTexture;
			iconImage = new Image(iconTexture);
		}
		
		private function setupContent():void
		{
			/* Content */
			if (Calibration.allForSensor().length > 1)
				calibrationButtonEnabled = true;
			
			dataProvider = new ListCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('chartscreen','calibration_button_title'), icon: iconImage, selectable:calibrationButtonEnabled, id: 1 }
				]);
			
			//Calibration Item Renderer Factory
			function calibrationItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";
				item.gap = 5;
				if(!calibrationButtonEnabled)
					item.alpha = 0.4;
				item.paddingLeft = 8;
				item.paddingRight = 14;
				item.isQuickHitAreaEnabled = true;
				return item;
			}
			setItemRendererFactoryWithID( "calibration-item", calibrationItemFactory );
			
			//Menu Factory
			factoryIDFunction = function( item:Object, index:int ):String
			{
				if(index === 0)
					return "calibration-item";
				
				return "default-item";
			};
			
			//Menu Layout
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			
			/* Event Handlers */
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		/**
		 * Event Handlers
		 */
		private function onMenuChanged(e:Event):void 
		{
			const treatmentID:Number = selectedItem.id as Number;
			
			if(treatmentID == 1) //Calibration
			{
				CalibrationService.calibrationOnRequest();
			}
		}
		
		/**
		 * Utility
		 */
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