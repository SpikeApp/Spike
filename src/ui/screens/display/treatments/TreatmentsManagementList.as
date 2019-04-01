package ui.screens.display.treatments
{
	import flash.display.StageOrientation;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import database.BgReading;
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.ImageLoader;
	import feathers.controls.LayoutGroup;
	import feathers.controls.ScrollContainer;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.textures.RenderTexture;
	import starling.utils.SystemUtil;
	
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.chart.helpers.GlucoseFactory;
	import ui.popups.AlertManager;
	import ui.screens.display.SpikeList;
	import ui.shapes.SpikeNGon;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.GlucoseHelper;
	import utils.TimeSpan;
	
	[ResourceBundle("globaltranslations")]
	[ResourceBundle("treatments")]

	public class TreatmentsManagementList extends SpikeList 
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
		private var treatmentEditorCallout:Callout;
		private var positionHelper:Sprite;
		private var treatmentEditor:TreatmentEditorList;
		private var sensorStartCanvas:Canvas;
		private var sensorStartTexture:RenderTexture;
		private var treatmentEditorContainer:ScrollContainer;
		private var exerciseCanvas:Canvas;
		private var exerciseTexture:RenderTexture;
		private var insulinCartridgeCanvas:Canvas;
		private var insulinCartridgeTexture:RenderTexture;
		private var pumpSiteCanvas:Canvas;
		private var pumpSiteTexture:RenderTexture;
		private var pumpBatteryCanvas:Canvas;
		private var pumpBatteryTexture:RenderTexture;
		private var tempBasalCanvas:Canvas;
		private var basalTexture:RenderTexture;
		
		/* Objects */
		private var allTreatments:Array;
		private var accessoryDictionary:Dictionary = new Dictionary( true );
		
		/* Properties */
		private var dateFormat:String;
		private var glucoseUnit:String;
		private var bolusColor:uint;
		private var carbsColor:uint;
		private var bgCheckColor:uint;
		private var sensorStartColor:uint;

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
			
			var numberOfTempBasals:uint = TreatmentsManager.basalsList.length;
			var userType:String = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump" ? Treatment.TYPE_TEMP_BASAL : Treatment.TYPE_MDI_BASAL;
			for (var i:int = 0; i < numberOfTempBasals; i++) 
			{
				var tempBasal:Treatment = TreatmentsManager.basalsList[i];
				if (tempBasal != null && tempBasal.type == userType)
				{
					allTreatments.push(tempBasal);
				}
			}
			
			//Get user's date format (24H/12H)
			dateFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
			
			//Get glucose unit
			glucoseUnit = GlucoseHelper.getGlucoseUnit();
			
			//Get treatment's colors
			bolusColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_INSULIN_MARKER_COLOR));
			carbsColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_CARBS_MARKER_COLOR));
			bgCheckColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_BGCHECK_MARKER_COLOR));
			sensorStartColor = uint(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_NEW_SENSOR_MARKER_COLOR));
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
			
			sensorStartCanvas = createTreatmentIcon(Treatment.TYPE_SENSOR_START);
			sensorStartTexture = new RenderTexture(sensorStartCanvas.width, sensorStartCanvas.height);
			sensorStartTexture.draw(sensorStartCanvas);
			
			noteCanvas = createTreatmentIcon(Treatment.TYPE_NOTE);
			noteTexture = new RenderTexture(noteCanvas.width, noteCanvas.height);
			noteTexture.draw(noteCanvas);
			
			mealCanvas = createTreatmentIcon(Treatment.TYPE_MEAL_BOLUS);
			mealTexture = new RenderTexture(mealCanvas.width, mealCanvas.height);
			mealTexture.draw(mealCanvas);
			
			exerciseCanvas = createTreatmentIcon(Treatment.TYPE_EXERCISE);
			exerciseTexture = new RenderTexture(exerciseCanvas.width, exerciseCanvas.height);
			exerciseTexture.draw(exerciseCanvas);
			
			insulinCartridgeCanvas = createTreatmentIcon(Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE);
			insulinCartridgeTexture = new RenderTexture(insulinCartridgeCanvas.width, insulinCartridgeCanvas.height);
			insulinCartridgeTexture.draw(insulinCartridgeCanvas);
			
			pumpSiteCanvas = createTreatmentIcon(Treatment.TYPE_PUMP_SITE_CHANGE);
			pumpSiteTexture = new RenderTexture(pumpSiteCanvas.width, pumpSiteCanvas.height);
			pumpSiteTexture.draw(pumpSiteCanvas);
			
			pumpBatteryCanvas = createTreatmentIcon(Treatment.TYPE_PUMP_BATTERY_CHANGE);
			pumpBatteryTexture = new RenderTexture(pumpBatteryCanvas.width, pumpBatteryCanvas.height);
			pumpBatteryTexture.draw(pumpBatteryCanvas);
			
			//Temp Basals Icons
			tempBasalCanvas = createTreatmentIcon(Treatment.TYPE_TEMP_BASAL);
			basalTexture = new RenderTexture(tempBasalCanvas.width, tempBasalCanvas.height);
			basalTexture.draw(tempBasalCanvas);
			
			var dataList:Array = [];
			var i:int;
			
			for(i = allTreatments.length - 1 ; i >= 0; i--)
			{
				//Treatment properties
				var treatment:Treatment = allTreatments[i] as Treatment;
				var treatmentValue:String;
				var icon:RenderTexture;
				
				if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_CHILD)
				{
					//Skip children
					continue;
				}
				else if (treatment.type == Treatment.TYPE_BOLUS || treatment.type == Treatment.TYPE_CORRECTION_BOLUS)
				{
					treatmentValue = GlucoseFactory.formatIOB(treatment.insulinAmount);
					icon = bolusTexture;
				}
				else if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_BOLUS_PARENT)
				{
					treatmentValue = GlucoseFactory.formatIOB(treatment.getTotalInsulin()) + " " + "(" + ModelLocator.resourceManagerInstance.getString('treatments','extended_bolus_small') + ")";
					icon = bolusTexture;
				}
				else if (treatment.type == Treatment.TYPE_EXTENDED_COMBO_MEAL_PARENT)
				{
					treatmentValue = GlucoseFactory.formatIOB(treatment.getTotalInsulin()) + "/" + GlucoseFactory.formatCOB(treatment.carbs) + " " + "(" + ModelLocator.resourceManagerInstance.getString('treatments','extended_bolus_small') + ")";
					icon = mealTexture;
				}
				else if (treatment.type == Treatment.TYPE_CARBS_CORRECTION)
				{
					treatmentValue = GlucoseFactory.formatCOB(treatment.carbs);
					icon = carbsTexture;
				}
				else if (treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
				{
					treatmentValue = "";
					if (treatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note'))
						treatmentValue += ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_calibration') + " ";
					treatmentValue += (glucoseUnit == "mg/dL" ? treatment.glucose : Math.round(((BgReading.mgdlToMmol((treatment.glucose))) * 10)) / 10) + " " + glucoseUnit;
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
				else if (treatment.type == Treatment.TYPE_SENSOR_START)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_sensor_start');
					icon = sensorStartTexture;
				}
				else if (treatment.type == Treatment.TYPE_EXERCISE)
				{
					treatmentValue = treatment.duration + ModelLocator.resourceManagerInstance.getString('treatments','minutes_small_label') + " / " + TreatmentsManager.getExerciseTreatmentIntensity(treatment);
					icon = exerciseTexture;
				}
				else if (treatment.type == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_insulin_cartridge_change');
					icon = insulinCartridgeTexture;
				}
				else if (treatment.type == Treatment.TYPE_PUMP_BATTERY_CHANGE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_battery_change');
					icon = pumpBatteryTexture;
				}
				else if (treatment.type == Treatment.TYPE_PUMP_SITE_CHANGE)
				{
					treatmentValue = ModelLocator.resourceManagerInstance.getString('treatments','treatment_name_pump_site_change');
					icon = pumpSiteTexture;
				}
				else if (treatment.type == Treatment.TYPE_TEMP_BASAL)
				{
					var tempBasalValue:String = "0U";
					
					if (treatment.isBasalAbsolute)
					{
						tempBasalValue = GlucoseFactory.formatIOB(treatment.basalAbsoluteAmount);
					}
					else if (treatment.isBasalRelative)
					{
						tempBasalValue = treatment.basalPercentAmount + "%";
					}
					else if (treatment.isTempBasalEnd)
					{
						tempBasalValue = ModelLocator.resourceManagerInstance.getString('globaltranslations','not_available');
					}
					
					treatmentValue = tempBasalValue;
					icon = basalTexture;
				}
				else if (treatment.type == Treatment.TYPE_MDI_BASAL)
				{
					treatmentValue = GlucoseFactory.formatIOB(treatment.basalAbsoluteAmount);
					icon = basalTexture;
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
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
		}
		
		override protected function setupRenderFactory():void
		{
			itemRendererFactory = function itemRendererFactory():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.iconSourceField = "icon";
				itemRenderer.accessoryLabelProperties.wordWrap = true;
				itemRenderer.defaultLabelProperties.wordWrap = true;
				itemRenderer.iconLoaderFactory = function():ImageLoader
				{
					var loader:ImageLoader = new ImageLoader();
					return loader;
				}
				itemRenderer.iconOffsetX = 0;
				itemRenderer.paddingRight = -25;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
						itemRenderer.paddingLeft = 30;
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						itemRenderer.paddingRight = 5;
				}
				itemRenderer.accessoryOffsetX = -30;
				itemRenderer.labelField = "label";
				itemRenderer.paddingTop = 10;
				itemRenderer.paddingBottom = 10;
				
				if (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout"))
				{
					itemRenderer.accessoryFunction = function(item:Object):LayoutGroup
					{
						if (item.treatment != null && item.treatment.note == ModelLocator.resourceManagerInstance.getString('treatments','sensor_calibration_note') && item.treatment.type == Treatment.TYPE_GLUCOSE_CHECK)
							return null;
						
						var actionsContainer:LayoutGroup = accessoryDictionary[ item ];
						if(!actionsContainer)
						{
							var containerLayout:HorizontalLayout = new HorizontalLayout();
							containerLayout.gap = -10;
							
							actionsContainer = new LayoutGroup();
							actionsContainer.pivotX = -10;
							actionsContainer.layout = containerLayout;
							
							if (item.treatment.type != Treatment.TYPE_SENSOR_START)
							{
								var editButton:Button = new Button();
								editButton.name = "editButton";
								editButton.defaultIcon = new Image(MaterialDeepGreyAmberMobileThemeIcons.editTexture);
								editButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
								editButton.addEventListener(Event.TRIGGERED, onEditTreatment);
								actionsContainer.addChild(editButton);
							}
							
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
				}
				
				return itemRenderer;
			}
		}
		
		private function setupCalloutPosition():void
		{
			//Position helper for the callout
			if (positionHelper == null)
			{
				positionHelper = new Sprite();
				addChild(positionHelper);
			}
			positionHelper.x = (Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2)) / 2;
			positionHelper.y = 0;
		}
		
		private function createTreatmentIcon(treatmentType:String):Canvas
		{
			var icon:Canvas = new Canvas();
			var radius:int = 8;
			
			if (treatmentType == Treatment.TYPE_BOLUS || treatmentType == Treatment.TYPE_CORRECTION_BOLUS || treatmentType == Treatment.TYPE_CARBS_CORRECTION || treatmentType == Treatment.TYPE_GLUCOSE_CHECK || treatmentType == Treatment.TYPE_SENSOR_START)
			{
				var marker:SpikeNGon = new SpikeNGon(radius, 20, 0, 360);
				if (treatmentType == Treatment.TYPE_BOLUS || treatmentType == Treatment.TYPE_CORRECTION_BOLUS)
					marker.colour = bolusColor;
				else if (treatmentType == Treatment.TYPE_CARBS_CORRECTION)
					marker.colour = carbsColor;
				else if (treatmentType == Treatment.TYPE_GLUCOSE_CHECK)
					marker.colour = bgCheckColor;
				else if (treatmentType == Treatment.TYPE_SENSOR_START)
					marker.colour = sensorStartColor;
				marker.x = marker.width / 2;
				marker.y = marker.height / 2;
				icon.addChild(marker);
			}
			else if (treatmentType == Treatment.TYPE_MEAL_BOLUS)
			{
				var insulinMarker:SpikeNGon = new SpikeNGon(radius, 20, 90, 270);
				insulinMarker.x = insulinMarker.width / 2;
				insulinMarker.y = insulinMarker.height / 2;
				insulinMarker.colour = bolusColor;
				icon.addChild(insulinMarker);
				
				var carbsMarker:SpikeNGon = new SpikeNGon(radius, 20, -90, 90);
				carbsMarker.x = carbsMarker.width / 2;
				carbsMarker.y = carbsMarker.height / 2;
				carbsMarker.colour = carbsColor;
				icon.addChild(carbsMarker);
			}
			else if (treatmentType == Treatment.TYPE_NOTE)
			{
				var noteImage:Image = new Image(MaterialDeepGreyAmberMobileThemeIcons.noteChartTexture);
				noteImage.scale = 0.75;
				icon.addChild(noteImage);
			}
			else if (treatmentType == Treatment.TYPE_EXERCISE)
			{
				var exerciseImage:Image = new Image(MaterialDeepGreyAmberMobileThemeIcons.exerciseChartTexture);
				exerciseImage.scale = 0.75;
				icon.addChild(exerciseImage);
			}
			else if (treatmentType == Treatment.TYPE_INSULIN_CARTRIDGE_CHANGE)
			{
				var insulinCartridgeImage:Image = new Image(MaterialDeepGreyAmberMobileThemeIcons.insulinCartridgeChartTexture);
				insulinCartridgeImage.scale = 0.75;
				icon.addChild(insulinCartridgeImage);
			}
			else if (treatmentType == Treatment.TYPE_PUMP_BATTERY_CHANGE)
			{
				var pumpBatteryImage:Image = new Image(MaterialDeepGreyAmberMobileThemeIcons.pumpBatteryChartTexture);
				pumpBatteryImage.scale = 0.75;
				icon.addChild(pumpBatteryImage);
			}
			else if (treatmentType == Treatment.TYPE_PUMP_SITE_CHANGE)
			{
				var pumpSiteImage:Image = new Image(MaterialDeepGreyAmberMobileThemeIcons.pumpSiteChartTexture);
				pumpSiteImage.scale = 0.75;
				icon.addChild(pumpSiteImage);
			}
			else if (treatmentType == Treatment.TYPE_TEMP_BASAL || treatmentType == Treatment.TYPE_MDI_BASAL)
			{
				var tbQuad:Quad = new Quad(radius * 1.85, radius * 1.85, bolusColor);
				icon.addChild(tbQuad);
			}
			
			return icon;
		}
		
		/**
		 * Event Handlers
		 */
		private function onEditTreatment(e:Event):void
		{
			var item:Object = (((e.currentTarget as Button).parent as LayoutGroup).parent as DefaultListItemRenderer).data as Object;
			var treatment:Treatment = item.treatment as Treatment;
			
			setupCalloutPosition();
			
			if (treatmentEditorContainer != null) treatmentEditorContainer.removeFromParent(true);
			treatmentEditorContainer = new ScrollContainer();
			treatmentEditorContainer.layout = new VerticalLayout();
			
			if (treatmentEditor != null) treatmentEditor.removeFromParent(true);
			treatmentEditor = new TreatmentEditorList(treatment);
			treatmentEditor.addEventListener(Event.CANCEL, onCancelTreatmentEditor);
			treatmentEditor.addEventListener(Event.CHANGE, onRefreshContent);
			treatmentEditorContainer.addChild(treatmentEditor);
			treatmentEditorContainer.validate();
			
			var predictionsCalloutPointOfOrigin:Number = positionHelper.localToGlobal(new Point(0, 0)).y;
			var predictionsContentOriginalHeight:Number = treatmentEditor.height + 60;
			var suggestedPredictionsCalloutHeight:Number = Constants.stageHeight - predictionsCalloutPointOfOrigin - 5;
			var finalCalloutHeight:Number = predictionsContentOriginalHeight > suggestedPredictionsCalloutHeight ?  suggestedPredictionsCalloutHeight : predictionsContentOriginalHeight;
			
			if (treatmentEditorCallout != null) treatmentEditorCallout.removeFromParent(true);
			treatmentEditorCallout = new Callout();
			treatmentEditorCallout.content = treatmentEditorContainer;
			treatmentEditorCallout.origin = positionHelper;
			
			treatmentEditorCallout.height = finalCalloutHeight;
			treatmentEditorContainer.height = finalCalloutHeight - 50;
			treatmentEditorContainer.maxHeight = finalCalloutHeight - 50;
			
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
				TreatmentsManager.deleteTreatment(treatment, true, true, !CGMBlueToothDevice.isFollower() || ModelLocator.INTERNAL_TESTING, true, false);
				dataProvider.removeItem(item);
			}
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			SystemUtil.executeWhenApplicationIsActive( setupCalloutPosition );
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			//Common variable holders
			var childImage:Image;
			
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
			var i:int;
			var childCanvas:DisplayObject;
			if (bolusCanvas != null)
			{
				for(i = bolusCanvas.numChildren - 1 ; i >= 0; i--)
				{
					childCanvas = bolusCanvas.getChildAt(i);
					if (childCanvas != null)
					{
						childCanvas.removeFromParent();
						childCanvas.dispose();
						childCanvas = null;
					}
				}
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
				for(i = carbsCanvas.numChildren - 1 ; i >= 0; i--)
				{
					childCanvas = carbsCanvas.getChildAt(i);
					if (childCanvas != null)
					{
						childCanvas.removeFromParent();
						childCanvas.dispose();
						childCanvas = null;
					}
				}
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
				for(i = glucoseCanvas.numChildren - 1 ; i >= 0; i--)
				{
					childCanvas = glucoseCanvas.getChildAt(i);
					if (childCanvas != null)
					{
						childCanvas.removeFromParent();
						childCanvas.dispose();
						childCanvas = null;
					}
				}
				glucoseCanvas.dispose();
				glucoseCanvas = null;
			}
			
			if (glucoseTexture != null)
			{
				glucoseTexture.dispose();
				glucoseTexture = null;
			}
			
			if (sensorStartCanvas != null)
			{
				for(i = sensorStartCanvas.numChildren - 1 ; i >= 0; i--)
				{
					childCanvas = sensorStartCanvas.getChildAt(i);
					if (childCanvas != null)
					{
						childCanvas.removeFromParent();
						childCanvas.dispose();
						childCanvas = null;
					}
				}
				sensorStartCanvas.dispose();
				sensorStartCanvas = null;
			}
			
			if (sensorStartTexture != null)
			{
				sensorStartTexture.dispose();
				sensorStartTexture = null;
			}
			
			if (noteCanvas != null)
			{
				for(i = noteCanvas.numChildren - 1 ; i >= 0; i--)
				{
					if (noteCanvas.getChildAt(i) is Image)
					{
						childImage = noteCanvas.getChildAt(i) as Image;
						if (childImage != null)
						{
							childImage.removeFromParent();
							if (childImage.texture != null)
								childImage.texture.dispose();
							childImage.dispose();
							childImage = null;
						}
					}
				}
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
				for(i = mealCanvas.numChildren - 1 ; i >= 0; i--)
				{
					childCanvas = mealCanvas.getChildAt(i);
					if (childCanvas != null)
					{
						childCanvas.removeFromParent();
						childCanvas.dispose();
						childCanvas = null;
					}
				}
				mealCanvas.dispose();
				mealCanvas = null;
			}
			
			if (mealTexture != null)
			{
				mealTexture.dispose();
				mealTexture = null;
			}
			
			if (exerciseCanvas != null)
			{
				for(i = exerciseCanvas.numChildren - 1 ; i >= 0; i--)
				{
					if (exerciseCanvas.getChildAt(i) is Image)
					{
						childImage = exerciseCanvas.getChildAt(i) as Image;
						if (childImage != null)
						{
							childImage.removeFromParent();
							if (childImage.texture != null)
								childImage.texture.dispose();
							childImage.dispose();
							childImage = null;
						}
					}
				}
				exerciseCanvas.dispose();
				exerciseCanvas = null;
			}
			
			if (exerciseTexture != null)
			{
				exerciseTexture.dispose();
				exerciseTexture = null;
			}
			
			if (insulinCartridgeCanvas != null)
			{
				for(i = insulinCartridgeCanvas.numChildren - 1 ; i >= 0; i--)
				{
					if (insulinCartridgeCanvas.getChildAt(i) is Image)
					{
						childImage = insulinCartridgeCanvas.getChildAt(i) as Image;
						if (childImage != null)
						{
							childImage.removeFromParent();
							if (childImage.texture != null)
								childImage.texture.dispose();
							childImage.dispose();
							childImage = null;
						}
					}
				}
				insulinCartridgeCanvas.dispose();
				insulinCartridgeCanvas = null;
			}
			
			if (insulinCartridgeTexture != null)
			{
				insulinCartridgeTexture.dispose();
				insulinCartridgeTexture = null;
			}
			
			if (pumpBatteryCanvas != null)
			{
				for(i = pumpBatteryCanvas.numChildren - 1 ; i >= 0; i--)
				{
					if (pumpBatteryCanvas.getChildAt(i) is Image)
					{
						childImage = pumpBatteryCanvas.getChildAt(i) as Image;
						if (childImage != null)
						{
							childImage.removeFromParent();
							if (childImage.texture != null)
								childImage.texture.dispose();
							childImage.dispose();
							childImage = null;
						}
					}
				}
				pumpBatteryCanvas.dispose();
				pumpBatteryCanvas = null;
			}
			
			if (pumpBatteryTexture != null)
			{
				pumpBatteryTexture.dispose();
				pumpBatteryTexture = null;
			}
			
			if (pumpSiteCanvas != null)
			{
				for(i = pumpSiteCanvas.numChildren - 1 ; i >= 0; i--)
				{
					if (pumpSiteCanvas.getChildAt(i) is Image)
					{
						childImage = pumpSiteCanvas.getChildAt(i) as Image;
						if (childImage != null)
						{
							childImage.removeFromParent();
							if (childImage.texture != null)
								childImage.texture.dispose();
							childImage.dispose();
							childImage = null;
						}
					}
				}
				pumpSiteCanvas.dispose();
				pumpSiteCanvas = null;
			}
			
			if (basalTexture != null)
			{
				basalTexture.dispose();
				basalTexture = null;
			}
			
			if (tempBasalCanvas != null)
			{
				for(i = tempBasalCanvas.numChildren - 1 ; i >= 0; i--)
				{
					if (tempBasalCanvas.getChildAt(i) is Image)
					{
						childImage = tempBasalCanvas.getChildAt(i) as Image;
						if (childImage != null)
						{
							childImage.removeFromParent();
							if (childImage.texture != null)
								childImage.texture.dispose();
							childImage.dispose();
							childImage = null;
						}
					}
				}
				tempBasalCanvas.dispose();
				tempBasalCanvas = null;
			}
			
			if (pumpSiteTexture != null)
			{
				pumpSiteTexture.dispose();
				pumpSiteTexture = null;
			}
			
			if (treatmentEditor != null)
			{
				treatmentEditor.removeFromParent();
				treatmentEditor.dispose();
				treatmentEditor = null;
			}
			
			if (treatmentEditorContainer != null)
			{
				treatmentEditorContainer.removeFromParent();
				treatmentEditorContainer.dispose();
				treatmentEditorContainer = null;
			}
			
			if (treatmentEditorCallout != null)
			{
				treatmentEditorCallout.removeFromParent();
				treatmentEditorCallout.dispose();
				treatmentEditorCallout = null;
			}
			
			super.dispose();
		}
	}
}