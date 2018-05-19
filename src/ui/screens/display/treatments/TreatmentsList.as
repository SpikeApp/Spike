package ui.screens.display.treatments
{
	import database.BlueToothDevice;
	import database.Calibration;
	import database.CommonSettings;
	import database.Sensor;
	
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
	
	import ui.AppInterface;
	import ui.screens.Screens;
	
	[ResourceBundle("chartscreen")]
	[ResourceBundle("treatments")]

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
		private var bgCheckTexture:Texture;
		private var bgCheckImage:Image;
		private var carbsTexture:Texture;
		private var carbsImage:Image;
		private var mealTexture:Texture;
		private var mealImage:Image;
		private var treatmentsTexture:Texture;
		private var treatmentsImage:Image;
		
		/* Properties */
		private var calibrationButtonEnabled:Boolean = false;
		private var treatmentsEnabled:Boolean = false;
		private var numBgReadings:int = 0;
		private var canAddTreatments:Boolean = false;
		private var canSeeTreatments:Boolean = false;
		
		public function TreatmentsList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
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
		}
		
		private function setupInitialContent():void
		{
			//Properties
			treatmentsEnabled = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true";
			numBgReadings = ModelLocator.bgReadings.length;
			
			//Images & Textures
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				calibrationTexture = MaterialDeepGreyAmberMobileThemeIcons.calibrationTexture;
				calibrationImage = new Image(calibrationTexture);
			}
			if (treatmentsEnabled && (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING))
			{
				bolusTexture = MaterialDeepGreyAmberMobileThemeIcons.insulinTexture;
				bolusImage = new Image(bolusTexture);
				carbsTexture = MaterialDeepGreyAmberMobileThemeIcons.carbsTexture;
				carbsImage = new Image(carbsTexture);
				mealTexture = MaterialDeepGreyAmberMobileThemeIcons.mealTexture;
				mealImage = new Image(mealTexture);
				bgCheckTexture = MaterialDeepGreyAmberMobileThemeIcons.bgCheckTexture;
				bgCheckImage = new Image(bgCheckTexture);
				noteTexture = MaterialDeepGreyAmberMobileThemeIcons.noteTexture;
				noteImage = new Image(noteTexture);
			}
			if (treatmentsEnabled)
			{
				treatmentsTexture = MaterialDeepGreyAmberMobileThemeIcons.treatmentsTexture;
				treatmentsImage = new Image(treatmentsTexture);
			}
		}
		
		private function setupContent():void
		{
			/* Content */
			if (Calibration.allForSensor().length > 1 && (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING))
				calibrationButtonEnabled = true;
			
			if ((numBgReadings > 2 && Calibration.allForSensor().length > 1 && Sensor.getActiveSensor() != null) || ModelLocator.INTERNAL_TESTING == true)
				canAddTreatments = true;
			
			if (numBgReadings > 2 || ModelLocator.INTERNAL_TESTING == true)
				canSeeTreatments = true;
			
			var menuData:Array = [];
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','calibration_button_title'), icon: calibrationImage, selectable: calibrationButtonEnabled, id: 1 } );
			if (treatmentsEnabled && (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING))
			{
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_bolus'), icon: bolusImage, selectable: canAddTreatments, id: 2 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs'), icon: carbsImage, selectable: canAddTreatments, id: 3 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_meal'), icon: mealImage, selectable: canAddTreatments, id: 4 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_bg_check'), icon: bgCheckImage, selectable: canAddTreatments, id: 5 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note'), icon: noteImage, selectable: canAddTreatments, id: 6 } );
			}
			if (treatmentsEnabled)
			{
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatments_screen_title'), icon: treatmentsImage, selectable: canSeeTreatments, id: 7 } );
			}
			
			dataProvider = new ListCollection(menuData);
			
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
				if(!canAddTreatments)
					item.alpha = 0.4;
				item.paddingLeft = 8;
				item.paddingRight = 14;
				item.isQuickHitAreaEnabled = true;
				return item;
			}
			setItemRendererFactoryWithID( "treatment-item", treatmentItemFactory );
			
			function treatmentListItemFactory():IListItemRenderer
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.itemHasSelectable = true;
				item.selectableField = "selectable";
				item.gap = 5;
				if(!canSeeTreatments)
					item.alpha = 0.4;
				item.paddingLeft = 8;
				item.paddingRight = 14;
				item.isQuickHitAreaEnabled = true;
				return item;
			}
			setItemRendererFactoryWithID( "treatment-list-item", treatmentListItemFactory );
			
			//Menu Factory
			if (!BlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				factoryIDFunction = function( item:Object, index:int ):String
				{
					if(index === 0)
						return "calibration-item";
					else if(index == 1 || index == 2 || index == 3 || index == 4 || index == 5 || index == 6)
						return "treatment-item";
					else if(index == 6)
						return "treatment-list-item";
					
					return "default-item";
				};
			}
			else
			{
				factoryIDFunction = function( item:Object, index:int ):String
				{
					return "treatment-list-item";
				};
			}
			
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
			else if(treatmentID == 3) //Carbs
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_CARBS_CORRECTION);
			}
			else if(treatmentID == 4) //Meal
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_MEAL_BOLUS);
			}
			else if(treatmentID == 5) //BG Check
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_GLUCOSE_CHECK);
			}
			else if(treatmentID == 6) //Note
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_NOTE);
			}
			else if(treatmentID == 7) //All Treatments
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				AppInterface.instance.navigator.pushScreen( Screens.ALL_TREATMENTS ); //Push Treatments Management Screen
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
			
			if (bgCheckTexture != null)
			{
				bgCheckTexture.dispose();
				bgCheckTexture = null;
			}
			
			if (bgCheckImage != null)
			{
				bgCheckImage.dispose();
				bgCheckImage = null;
			}
			
			if (carbsTexture != null)
			{
				carbsTexture.dispose();
				carbsTexture = null;
			}
			
			if (carbsImage != null)
			{
				carbsImage.dispose();
				carbsImage = null;
			}
			
			if (mealTexture != null)
			{
				mealTexture.dispose();
				mealTexture = null;
			}
			
			if (mealImage != null)
			{
				mealImage.dispose();
				mealImage = null;
			}
			
			if (treatmentsTexture != null)
			{
				treatmentsTexture.dispose();
				treatmentsTexture = null;
			}
			
			if (treatmentsImage != null)
			{
				treatmentsImage.dispose();
				treatmentsImage = null;
			}
			
			super.dispose();
		}
	}
}