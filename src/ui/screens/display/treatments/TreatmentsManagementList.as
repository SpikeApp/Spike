package ui.screens.display.treatments
{
	import flash.utils.Dictionary;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.ImageLoader;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Canvas;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.display.graphics.NGon;
	import starling.events.Event;
	import starling.textures.RenderTexture;
	
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.chart.GlucoseFactory;
	import ui.popups.AlertManager;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("globaltranslations")]

	public class TreatmentsManagementList extends List 
	{
		/* Display Objects */
		private var bolusCanvas:Canvas;
		private var bolusTexture:RenderTexture;
		private var carbsCanvas:Canvas;
		private var carbsTexture:RenderTexture;
		private var glucoseCanvas:Canvas;
		private var glucoseTexture:RenderTexture;
		private var noteCanvas:Canvas;
		private var noteTexture:RenderTexture;
		private var mealCanvas:Canvas;
		private var mealTexture:RenderTexture;
		
		/* Objects */
		private var allTreatments:Array;
		private var accessoryDictionary:Dictionary = new Dictionary( true );
		
		/* Properties */
		private var dateFormat:String;
		private var glucoseUnit:String;

		private var treatmentEditorCallout:Callout;

		private var positionHelper:Sprite;

		private var treatmentEditor:TreatmentEditorList;
		
		
		public function TreatmentsManagementList()
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
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			//Get treatments
			allTreatments = TreatmentsManager.treatmentsList.concat();
			
			//Get user's date format (24H/12H)
			dateFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//Get glucose unit
			glucoseUnit = GlucoseHelper.getGlucoseUnit();
		}
		
		private function setupContent():void
		{
			//Sort treatments by date/time
			allTreatments.sortOn(["timestamp"], Array.NUMERIC);
			
			//Treatments icons
			bolusCanvas = createTreatmentIcon(Treatment.TYPE_BOLUS);
			bolusTexture = new RenderTexture(bolusCanvas.width, bolusCanvas.height);
			bolusTexture.draw(bolusCanvas);
			
			carbsCanvas = createTreatmentIcon(Treatment.TYPE_CARBS_CORRECTION);
			carbsTexture = new RenderTexture(carbsCanvas.width, carbsCanvas.height);
			carbsTexture.draw(carbsCanvas);
			
			glucoseCanvas = createTreatmentIcon(Treatment.TYPE_GLUCOSE_CHECK);
			glucoseTexture = new RenderTexture(glucoseCanvas.width, glucoseCanvas.height);
			glucoseTexture.draw(glucoseCanvas);
			
			noteCanvas = createTreatmentIcon(Treatment.TYPE_NOTE);
			noteTexture = new RenderTexture(noteCanvas.width, noteCanvas.height);
			noteTexture.draw(noteCanvas);
			
			mealCanvas = createTreatmentIcon(Treatment.TYPE_MEAL_BOLUS);
			mealTexture = new RenderTexture(mealCanvas.width, mealCanvas.height);
			mealTexture.draw(mealCanvas);
			
			var dataList:Array = [];
			
			for(var i:int = allTreatments.length - 1 ; i >= 0; i--)
			{
				//Treatment properties
				var treatment:Treatment = allTreatments[i] as Treatment;
				var treatmentValue:String;
				var icon:RenderTexture;
				if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
				{
					treatmentValue = GlucoseFactory.formatIOB(treatment.insulinAmount);
					icon = bolusTexture;
				}
				else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
				{
					treatmentValue = GlucoseFactory.formatCOB(treatment.carbs);
					icon = carbsTexture;
				}
				else if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
				{
					treatmentValue = (glucoseUnit == "mg/dL" ? treatment.glucose : Math.round(((BgReading.mgdlToMmol((treatment.glucose))) * 10)) / 10) + " " + glucoseUnit;
					icon = glucoseTexture;
				}
				else if (treatment.type == Treatment.TYPE_NOTE)
				{
					treatmentValue = treatment.note;
					icon = noteTexture;
				}
				else if (treatment.type == Treatment.TYPE_MEAL_BOLUS)
				{
					treatmentValue = GlucoseFactory.formatIOB(treatment.insulinAmount) + "/" + GlucoseFactory.formatCOB(treatment.carbs);
					icon = mealTexture;
				}
				
				var treatmentTime:Date = new Date(treatment.timestamp);
				
				//Row label
				var timeFormatted:String;
				if (dateFormat.slice(0,2) == "24")
					timeFormatted = TimeSpan.formatHoursMinutes(treatmentTime.getHours(), treatmentTime.getMinutes(), TimeSpan.TIME_FORMAT_24H);
				else
					timeFormatted = TimeSpan.formatHoursMinutes(treatmentTime.getHours(), treatmentTime.getMinutes(), TimeSpan.TIME_FORMAT_12H);
				var label:String = timeFormatted + "  -  " + treatmentValue;
				
				//Push row into list
				dataList.push({ icon: icon, label: label, treatment: treatment });
			}
			
			dataProvider = new ArrayCollection(dataList);
			
			itemRendererFactory = function itemRendererFactory():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.iconSourceField = "icon";
				itemRenderer.iconLoaderFactory = function():ImageLoader
				{
					var loader:ImageLoader = new ImageLoader();
					return loader;
				}
				itemRenderer.iconOffsetX = 0;
				itemRenderer.paddingRight = -25;
				itemRenderer.accessoryOffsetX = -30;
				itemRenderer.labelField = "label";
				itemRenderer.accessoryFunction = function(item:Object):LayoutGroup
				{
					var actionsContainer:LayoutGroup = accessoryDictionary[ item ];
					if(!actionsContainer)
					{
						var containerLayout:HorizontalLayout = new HorizontalLayout();
						containerLayout.gap = -10;
						
						actionsContainer = new LayoutGroup();
						actionsContainer.pivotX = -10;
						actionsContainer.layout = containerLayout;
						
						var editButton:Button = new Button();
						editButton.name = "editButton";
						editButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.editTexture);
						editButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
						editButton.addEventListener(Event.TRIGGERED, onEditTreatment);
						actionsContainer.addChild(editButton);
						
						var deleteButton:Button = new Button();
						deleteButton.name = "deleteButton";
						deleteButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.deleteForeverTexture);
						deleteButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
						deleteButton.addEventListener(Event.TRIGGERED, onDeleteTreatment);
						actionsContainer.addChild(deleteButton);
						
						accessoryDictionary[ item ] = actionsContainer;
					}
					
					return actionsContainer;
				}
				
				return itemRenderer;
			}
		}
		
		private function onEditTreatment(e:Event):void
		{
			var item:Object = (((e.currentTarget as Button).parent as LayoutGroup).parent as DefaultListItemRenderer).data as Object;
			var treatment:Treatment = item.treatment as Treatment;
			
			setupCalloutPosition();
			
			if (DeviceInfo.getDeviceType() == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 && treatment.type == Treatment.TYPE_MEAL_BOLUS)
			{
				positionHelper.y -= 10;	
			}
			
			treatmentEditor = new TreatmentEditorList(treatment);
			treatmentEditor.addEventListener(Event.CANCEL, onCancelTreatmentEditor);
			treatmentEditor.addEventListener(Event.CHANGE, onRefreshContent);
			
			treatmentEditorCallout = new Callout();
			treatmentEditorCallout.content = treatmentEditor;
			treatmentEditorCallout.origin = positionHelper;
			
			PopUpManager.addPopUp(treatmentEditorCallout, false, false);
		}
		
		private function onCancelTreatmentEditor(e:Event):void
		{
			treatmentEditorCallout.close(true);
		}
		
		private function onRefreshContent(e:Event):void
		{
			treatmentEditorCallout.close(true);
			
			setupContent();
		}
		
		private function setupCalloutPosition():void
		{
			//Position helper for the callout
			positionHelper = new Sprite();
			positionHelper.x = (Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2)) / 2;
			positionHelper.y = 0;
			addChild(positionHelper);
		}
		
		private function createTreatmentIcon(treatmentType:String):Canvas
		{
			var icon:Canvas = new Canvas();
			var radius:int = 8;
			
			if (treatmentType == Treatment.TYPE_BOLUS || treatmentType == Treatment.TYPE_CORRECTION_BOLUS || treatmentType == Treatment.TYPE_CARBS_CORRECTION || treatmentType == Treatment.TYPE_GLUCOSE_CHECK)
			{
				var marker:NGon = new NGon(radius, 20, 0, 0, 360);
				if (treatmentType == Treatment.TYPE_BOLUS || treatmentType == Treatment.TYPE_CORRECTION_BOLUS)
					marker.color = 0x0086ff;
				else if (treatmentType == Treatment.TYPE_CARBS_CORRECTION)
					marker.color = 0xf8a246;
				else if (treatmentType == Treatment.TYPE_GLUCOSE_CHECK)
					marker.color = 0xFF0000;
				marker.x = marker.width / 2;
				marker.y = marker.height / 2;
				icon.addChild(marker);
			}
			else if (treatmentType == Treatment.TYPE_MEAL_BOLUS)
			{
				var insulinMarker:NGon = new NGon(radius, 20, 0, 90, 270);
				insulinMarker.x = insulinMarker.width / 2;
				insulinMarker.y = insulinMarker.height / 2;
				insulinMarker.color = 0x0086ff;
				icon.addChild(insulinMarker);
				
				var carbsMarker:NGon = new NGon(radius, 20, 0, -90, 90);
				carbsMarker.x = carbsMarker.width / 2;
				carbsMarker.y = carbsMarker.height / 2;
				carbsMarker.color = 0xf8a246;
				icon.addChild(carbsMarker);
			}
			else if (treatmentType == Treatment.TYPE_NOTE)
			{
				var noteImage:Image = new Image(MaterialDeepGreyAmberMobileThemeIcons.noteChartTexture);
				noteImage.scale = 0.75;
				icon.addChild(noteImage);
			}
			
			return icon;
		}
		
		/**
		 * Event Handlers
		 */
		private function onDeleteTreatment(e:Event):void
		{
			//Get list row properties
			var item:Object = (((e.currentTarget as Button).parent as LayoutGroup).parent as DefaultListItemRenderer).data as Object;
			var treatment:Treatment = item.treatment as Treatment;
			
			var alert:Alert = AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('globaltranslations','cant_be_undone'),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","no_uppercase")  },	
					{ label: ModelLocator.resourceManagerInstance.getString("globaltranslations","yes_uppercase"), triggered: deleteTreatment }	
				],
				HorizontalAlign.CENTER
			);
			alert.buttonGroupProperties.gap = 10;
			alert.buttonGroupProperties.horizontalAlign = HorizontalAlign.CENTER;
			
			function deleteTreatment(e:Event):void
			{
				//Delete reading from Spike, database and list
				TreatmentsManager.deleteTreatment(treatment);
				dataProvider.removeItem(item);
			}
		}
		
		/**
		 * Utility
		 */
		
		override public function dispose():void
		{
			//Clear accessories
			if (accessoryDictionary != null)
			{
				for each (var accessoryContainer:LayoutGroup in accessoryDictionary) 
				{
					var deleteButton:Button = accessoryContainer.getChildByName("deleteButton") as Button;
					if (deleteButton != null)
					{
						accessoryContainer.removeChild(deleteButton);
						deleteButton.addEventListener(Event.TRIGGERED, onDeleteTreatment);
						deleteButton.dispose();
						deleteButton = null;
					}
					
					var editButton:Button = accessoryContainer.getChildByName("editButton") as Button;
					if (editButton != null)
					{
						accessoryContainer.removeChild(editButton);
						editButton.addEventListener(Event.TRIGGERED, onEditTreatment);
						editButton.dispose();
						editButton = null;
					}
					
					accessoryContainer.dispose();
					accessoryContainer = null;
				}
			}

			//Clear icons
			if (bolusCanvas != null)
			{
				bolusCanvas.dispose();
				bolusCanvas = null;
			}
			
			if (bolusTexture != null)
			{
				bolusTexture.dispose();
				bolusTexture = null;
			}
			
			if (carbsCanvas != null)
			{
				carbsCanvas.dispose();
				carbsCanvas = null;
			}
			
			if (carbsTexture != null)
			{
				carbsTexture.dispose();
				carbsTexture = null;
			}
			
			if (glucoseCanvas != null)
			{
				glucoseCanvas.dispose();
				glucoseCanvas = null;
			}
			
			if (glucoseTexture != null)
			{
				glucoseTexture.dispose();
				glucoseTexture = null;
			}
			
			if (noteCanvas != null)
			{
				noteCanvas.dispose();
				noteCanvas = null;
			}
			
			if (noteTexture != null)
			{
				noteTexture.dispose();
				noteTexture = null;
			}
			
			if (mealCanvas != null)
			{
				mealCanvas.dispose();
				mealCanvas = null;
			}
			
			if (mealTexture != null)
			{
				mealTexture.dispose();
				mealTexture = null;
			}
			
			super.dispose();
		}
	}
}