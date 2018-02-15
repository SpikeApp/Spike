package ui.screens.display.treatments
{
	import database.Calibration;
	
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
		/* Constants */
		public static const CLOSE:String = "close";
		
		/* Display Objects */
		private var calibrationTexture:Texture;
		private var calibrationImage:Image;
		private var bolusTexture:Texture;
		private var bolusImage:Image;
		
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
			
			calibrationTexture = MaterialDeepGreyAmberMobileThemeIcons.calibrationTexture;
			calibrationImage = new Image(calibrationTexture);
			bolusTexture = MaterialDeepGreyAmberMobileThemeIcons.accountChildTexture;
			bolusImage = new Image(bolusTexture);
		}
		
		private function setupContent():void
		{
			/* Content */
			if (Calibration.allForSensor().length > 1)
				calibrationButtonEnabled = true;
			
			//if (ModelLocator.INTERNAL_TESTING == false)
			//{
			dataProvider = new ListCollection(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('chartscreen','calibration_button_title'), icon: calibrationImage, selectable:calibrationButtonEnabled, id: 1 }
				]);
			/*}
			else
			{
				dataProvider = new ListCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('chartscreen','calibration_button_title'), icon: calibrationImage, selectable:calibrationButtonEnabled, id: 1 },
						{ label: "Bolus", icon: bolusImage, selectable:calibrationButtonEnabled, id: 2 }
					]);
			}*/
			
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
				
				dispatchEventWith(CLOSE); //Close Menu
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			removeEventListener( Event.CHANGE, onMenuChanged );
			
			if (calibrationTexture != null)
			{
				calibrationTexture.dispose();
				calibrationTexture = null;
			}
			
			if (calibrationImage != null)
			{
				calibrationImage.dispose();
				calibrationImage = null;
			}
			
			super.dispose();
		}
	}
}