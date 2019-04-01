package ui.screens.display.treatments
{
	import flash.system.System;
	
	import database.CGMBlueToothDevice;
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
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import treatments.BolusWizard;
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
		private var bolusWizardTexture:Texture;
		private var bolusWizardImage:Image;
		private var exerciseTexture:Texture;
		private var exerciseImage:Image;
		private var insulinCartridgeTexture:Texture;
		private var insulinCartridgeImage:Image;
		private var pumpSiteTexture:Texture;
		private var pumpSiteImage:Image;
		private var pumpBatteryTexture:Texture;
		private var pumpBatteryImage:Image;
		private var basalStartTexture:Texture;
		private var basalStartImage:Image;
		private var basalEndTexture:Texture;
		private var basalEndImage:Image;
		
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
			if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				calibrationTexture = MaterialDeepGreyAmberMobileThemeIcons.calibrationTexture;
				calibrationImage = new Image(calibrationTexture);
			}

			if (treatmentsEnabled && (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout")))
			{
				bolusTexture = MaterialDeepGreyAmberMobileThemeIcons.insulinTexture;
				bolusImage = new Image(bolusTexture);
				basalStartTexture = MaterialDeepGreyAmberMobileThemeIcons.basalStartTexture;
				basalStartImage = new Image(basalStartTexture);
				basalEndTexture = MaterialDeepGreyAmberMobileThemeIcons.basalEndTexture;
				basalEndImage = new Image(basalEndTexture);
				carbsTexture = MaterialDeepGreyAmberMobileThemeIcons.carbsTexture;
				carbsImage = new Image(carbsTexture);
				mealTexture = MaterialDeepGreyAmberMobileThemeIcons.mealTexture;
				mealImage = new Image(mealTexture);
				bgCheckTexture = MaterialDeepGreyAmberMobileThemeIcons.bgCheckTexture;
				bgCheckImage = new Image(bgCheckTexture);
				noteTexture = MaterialDeepGreyAmberMobileThemeIcons.noteTexture;
				noteImage = new Image(noteTexture);
				bolusWizardTexture = MaterialDeepGreyAmberMobileThemeIcons.bolusWizardTexture;
				bolusWizardImage = new Image(bolusWizardTexture);
				exerciseTexture = MaterialDeepGreyAmberMobileThemeIcons.exerciseTexture;
				exerciseImage = new Image(exerciseTexture);
				insulinCartridgeTexture = MaterialDeepGreyAmberMobileThemeIcons.insulinCartridgeTexture;
				insulinCartridgeImage = new Image(insulinCartridgeTexture);
				pumpSiteTexture = MaterialDeepGreyAmberMobileThemeIcons.pumpSiteTexture;
				pumpSiteImage = new Image(pumpSiteTexture);
				pumpBatteryTexture = MaterialDeepGreyAmberMobileThemeIcons.pumpBatteryTexture;
				pumpBatteryImage = new Image(pumpBatteryTexture);
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
			if ((Calibration.allForSensor().length > 1 && (!CGMBlueToothDevice.isFollower()) || ModelLocator.INTERNAL_TESTING))
				calibrationButtonEnabled = true;
			
			if ((numBgReadings > 2 && Calibration.allForSensor().length > 1 && Sensor.getActiveSensor() != null) || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout"))
				canAddTreatments = true;
			
			if (numBgReadings > 2 || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout"))
				canSeeTreatments = true;
			
			var menuData:Array = [];
			if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('chartscreen','calibration_button_title'), icon: calibrationImage, selectable: calibrationButtonEnabled, id: 1 } );
			
			if (treatmentsEnabled && (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout")))
			{
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_bolus'), icon: bolusImage, selectable: canAddTreatments, id: 2 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_carbs'), icon: carbsImage, selectable: canAddTreatments, id: 3 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_meal'), icon: mealImage, selectable: canAddTreatments, id: 4 } );
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump")
				{
					menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_temp_basal_start'), icon: basalStartImage, selectable: canAddTreatments, id: 5 } );
					menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_temp_basal_end'), icon: basalEndImage, selectable: canAddTreatments, id: 6 } );
				}
				else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "mdi")
				{
					menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_basal'), icon: basalStartImage, selectable: canAddTreatments, id: 7 } );
				}
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','bolus_wizard_settings_label'), icon: bolusWizardImage, selectable: canAddTreatments, id: 8 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_bg_check'), icon: bgCheckImage, selectable: canAddTreatments, id: 9 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_note'), icon: noteImage, selectable: canAddTreatments, id: 10 } );
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_exercise'), icon: exerciseImage, selectable: canAddTreatments, id: 11 } );
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump")
				{
					menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_insulin_cartridge_change'), icon: insulinCartridgeImage, selectable: canAddTreatments, id: 12 } );
					menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_site_change'), icon: pumpSiteImage, selectable: canAddTreatments, id: 13 } );
					menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_battery_change'), icon: pumpBatteryImage, selectable: canAddTreatments, id: 14 } );
				}
			}
			if (treatmentsEnabled)
			{
				menuData.push( { label: ModelLocator.resourceManagerInstance.getString('treatments','treatments_screen_title'), icon: treatmentsImage, selectable: canSeeTreatments, id: 15 } );
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
			if (!CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
			{
				factoryIDFunction = function( item:Object, index:int ):String
				{
					if(index === 0 && !CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING)
						return "calibration-item";
					else if(index == 0 || index == 1 || index == 2 || index == 3 || index == 4 || index == 5 || index == 6 || index == 7 || index == 8 || index == 9 || index == 10 || index == 11 || index == 12 || index == 13 || index == 14 || index == 15)
						return "treatment-item";
					else if(index == 16)
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
			else if(treatmentID == 5) //Temp Basal Start
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_TEMP_BASAL);
			}
			else if(treatmentID == 6) //Temp Basal Start
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_TEMP_BASAL_END);
			}
			else if(treatmentID == 7) //Pen Basal
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_MDI_BASAL);
			}
			else if(treatmentID == 8) //Bolus Wizard
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				BolusWizard.display();
			}
			else if(treatmentID == 9) //BG Check
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_GLUCOSE_CHECK);
			}
			else if(treatmentID == 10) //Note
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_NOTE);
			}
			else if(treatmentID == 11) //Exercise
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_EXERCISE);
			}
			else if(treatmentID == 12) //Insulin Cartridge
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE);
			}
			else if(treatmentID == 13) //Pump Site
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_PUMP_SITE_CHANGE);
			}
			else if(treatmentID == 14) //Pump Battery
			{	
				dispatchEventWith(CLOSE); //Close Menu
				
				TreatmentsManager.addTreatment(Treatment.TYPE_PUMP_BATTERY_CHANGE);
			}
			else if(treatmentID == 15) //Treatments Manager
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
			
			if (dataProvider != null)
			{
				dataProvider.dispose( function( item:Object ):void
				{
					var icon:DisplayObject = DisplayObject(item.icon);
					if (icon != null)
						icon.dispose();
				});
			}
			
			if (calibrationTexture != null)
			{
				calibrationTexture.dispose();
				calibrationTexture = null;
			}
			
			if (calibrationImage != null)
			{
				if (calibrationImage.texture != null)
					calibrationImage.texture.dispose();
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
				if (bolusImage.texture != null)
					bolusImage.texture.dispose();
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
				if (noteImage.texture != null)
					noteImage.texture.dispose();
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
				if (bgCheckImage.texture != null)
					bgCheckImage.texture.dispose();
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
				if (carbsImage.texture != null)
					carbsImage.texture.dispose();
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
				if (mealImage.texture != null)
					mealImage.texture.dispose();
				mealImage.dispose();
				mealImage = null;
			}
			
			if (basalStartTexture != null)
			{
				basalStartTexture.dispose();
				basalStartTexture = null;
			}
			
			if (basalStartImage != null)
			{
				if (basalStartImage.texture != null)
					basalStartImage.texture.dispose();
				basalStartImage.dispose();
				basalStartImage = null;
			}
			
			if (basalEndTexture != null)
			{
				basalEndTexture.dispose();
				basalEndTexture = null;
			}
			
			if (basalEndImage != null)
			{
				if (basalEndImage.texture != null)
					basalEndImage.texture.dispose();
				basalEndImage.dispose();
				basalEndImage = null;
			}
			
			if (treatmentsTexture != null)
			{
				treatmentsTexture.dispose();
				treatmentsTexture = null;
			}
			
			if (treatmentsImage != null)
			{
				if (treatmentsImage.texture != null)
					treatmentsImage.texture.dispose();
				treatmentsImage.dispose();
				treatmentsImage = null;
			}
			
			if (bolusWizardTexture != null)
			{
				bolusWizardTexture.dispose();
				bolusWizardTexture = null;
			}
			
			if (bolusWizardImage != null)
			{
				if (bolusWizardImage.texture != null)
					bolusWizardImage.texture.dispose();
				bolusWizardImage.dispose();
				bolusWizardImage = null;
			}
			
			if (exerciseTexture != null)
			{
				exerciseTexture.dispose();
				exerciseTexture = null;
			}
			
			if (exerciseImage != null)
			{
				if (exerciseImage.texture != null)
					exerciseImage.texture.dispose();
				exerciseImage.dispose();
				exerciseImage = null;
			}
			
			if (insulinCartridgeTexture != null)
			{
				insulinCartridgeTexture.dispose();
				insulinCartridgeTexture = null;
			}
			
			if (insulinCartridgeImage != null)
			{
				if (insulinCartridgeImage.texture != null)
					insulinCartridgeImage.texture.dispose();
				insulinCartridgeImage.dispose();
				insulinCartridgeImage = null;
			}
			
			if (pumpSiteTexture != null)
			{
				pumpSiteTexture.dispose();
				pumpSiteTexture = null;
			}
			
			if (pumpSiteImage != null)
			{
				if (pumpSiteImage.texture != null)
					pumpSiteImage.texture.dispose();
				pumpSiteImage.dispose();
				pumpSiteImage = null;
			}
			
			if (pumpBatteryTexture != null)
			{
				pumpBatteryTexture.dispose();
				pumpBatteryTexture = null;
			}
			
			if (pumpBatteryImage != null)
			{
				if (pumpBatteryImage.texture != null)
					pumpBatteryImage.texture.dispose();
				pumpBatteryImage.dispose();
				pumpBatteryImage = null;
			}
			
			super.dispose();
			
			System.pauseForGCIfCollectionImminent(0);
			System.gc();
		}
	}
}