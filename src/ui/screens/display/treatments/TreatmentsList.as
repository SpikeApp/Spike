package ui.screens.display.treatments
{
	import database.BlueToothDevice;
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
	
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
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
		private var noteTexture:Texture;
		private var noteImage:Image;
		
		
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
			bolusTexture = MaterialDeepGreyAmberMobileThemeIcons.insulinTexture;
			bolusImage = new Image(bolusTexture);
			noteTexture = MaterialDeepGreyAmberMobileThemeIcons.noteTexture;
			noteImage = new Image(noteTexture);
		}
		
		private function setupContent():void
		{
			/* Content */
			if (true)//(Calibration.allForSensor().length > 1 && !BlueToothDevice.isFollower())
				calibrationButtonEnabled = true;
			
			if (ModelLocator.bgReadings.length > 0)
				var treatmentsEnabled:Boolean = true;
			
			dataProvider = new ListCollection
			(
				[
					{ label: ModelLocator.resourceManagerInstance.getString('chartscreen','calibration_button_title'), icon: calibrationImage, selectable: calibrationButtonEnabled, id: 1 },
					{ label: "Bolus", icon: bolusImage, selectable: treatmentsEnabled, id: 2 },
					{ label: "Note", icon: noteImage, selectable: treatmentsEnabled, id: 3 }
				]
			);
			
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
			
			function treatmentItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";
				item.gap = 5;
				if(!treatmentsEnabled)
					item.alpha = 0.4;
				item.paddingLeft = 8;
				item.paddingRight = 14;
				item.isQuickHitAreaEnabled = true;
				return item;
			}
			setItemRendererFactoryWithID( "treatment-item", treatmentItemFactory );
			
			//Menu Factory
			factoryIDFunction = function( item:Object, index:int ):String
			{
				if(index === 0)
					return "calibration-item";
				else if(index == 1 || index == 2)
					return "treatment-item";
				
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
			else if(treatmentID == 2) //Bolus
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_BOLUS);
			}
			else if(treatmentID == 3) //Note
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_NOTE);
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
			
			if (bolusTexture != null)
			{
				bolusTexture.dispose();
				bolusTexture = null;
			}
			
			if (bolusImage != null)
			{
				bolusImage.dispose();
				bolusImage = null;
			}
			
			if (noteTexture != null)
			{
				noteTexture.dispose();
				noteTexture = null;
			}
			
			if (noteImage != null)
			{
				noteImage.dispose();
				noteImage = null;
			}
			
			super.dispose();
		}
	}
}