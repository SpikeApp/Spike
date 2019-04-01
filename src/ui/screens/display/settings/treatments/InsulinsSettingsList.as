package ui.screens.display.settings.treatments
{
	import com.adobe.utils.StringUtil;
	
	import flash.display.StageOrientation;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.controls.PickerList;
	import feathers.controls.TextInput;
	import feathers.controls.popups.DropDownPopUpContentManager;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	import treatments.Treatment;
	import treatments.TreatmentsManager;
	
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	import ui.shapes.SpikeInsulinActivityCurve;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class InsulinsSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var addInsulinButton:Button;
		private var insulinDIA:NumericStepper;
		private var saveInsulinButton:Button;
		private var insulinTypesPicker:PickerList;
		private var insulinName:TextInput;
		private var insulinSettingsExplanation:Label;
		private var defaultInsulinCheck:Check;
		private var cancelInsulinButton:Button;
		private var actionsContainer:LayoutGroup;
		private var modeLabel:Label;
		private var guideContainer:LayoutGroup;
		private var diaGuideButton:Button;
		private var insulinCurvePicker:PickerList;
		private var insulinPeak:NumericStepper;
		private var insulinCurveGraph:SpikeInsulinActivityCurve;
		private var insulinCurveContainer:LayoutGroup;
		private var insulinCurvePresetsPicker:PickerList;
		private var xAxisLegend:Label;
		private var yAxisLegend:Label;
		
		/* Properties */
		private var userInsulins:Array;
		private var newInsulinMode:Boolean = false;
		private var editInsulinMode:Boolean = false;
		private var isSaveEnabled:Boolean = false;
		private var accessoryList:Array = [];
		private var insulinToEdit:Insulin;
		private var selectedInsulinCurve:String = "bilinear";
		private var isBasalEnabled:Boolean = false;
		
		public function InsulinsSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();	
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
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get Values From Database */
			userInsulins = ProfileManager.insulinsList;
		}
		
		private function setupContent():void
		{	
			//Add Insulin Button
			addInsulinButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','add_insulin_button_label'));
			addInsulinButton.addEventListener(Event.TRIGGERED, onNewInsulin);
			
			//Mode Label
			modeLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			modeLabel.wordWrap = true;
			modeLabel.width = width;
			
			//New Insulin Name
			insulinName = LayoutFactory.createTextInput(false, false, Constants.isPortrait ? 140: 240, HorizontalAlign.RIGHT);
			if (DeviceInfo.isTablet()) insulinName.width += 100;
			insulinName.addEventListener(Event.CHANGE, onInsulinNameChanged);
			
			//New Insulin Type
			var insulinTypesLabelList:Array = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_types_list').split(",");
			var insulinTypesList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < insulinTypesLabelList.length; i++) 
			{
				insulinTypesList.push( {label: StringUtil.trim(insulinTypesLabelList[i]) } );
			}
			insulinTypesPicker = LayoutFactory.createPickerList();
			insulinTypesPicker.labelField = "label";
			insulinTypesPicker.itemRendererFactory = function():IListItemRenderer
			{
				var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				renderer.paddingRight = renderer.paddingLeft = 20;
				return renderer;
			};
			insulinTypesPicker.popUpContentManager = new DropDownPopUpContentManager();
			insulinTypesPicker.dataProvider = insulinTypesList;
			insulinTypesPicker.addEventListener(Event.CHANGE, onSettingsChanged);
			insulinTypesPicker.addEventListener(Event.CHANGE, onInsulinTypeChanged);
			
			//New Insulin DIA
			insulinDIA = LayoutFactory.createNumericStepper(1.1, 8, 3, 0.1);
			insulinDIA.pivotX = -8;
			insulinDIA.addEventListener(Event.CHANGE, onSettingsChanged);
			insulinDIA.addEventListener(Event.CHANGE, onDiaPeakChanged);
			
			//Curve
			var insulinCurvesList:ArrayCollection = new ArrayCollection();
			insulinCurvesList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_bilinear_curve_label'), id: "bilinear" } );
			insulinCurvesList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_exponential_curve_label'), id: "exponential" } );
			
			insulinCurvePicker = LayoutFactory.createPickerList();
			insulinCurvePicker.labelField = "label";
			insulinCurvePicker.itemRendererFactory = function():IListItemRenderer
			{
				var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				renderer.paddingRight = renderer.paddingLeft = 20;
				return renderer;
			};
			insulinCurvePicker.popUpContentManager = new DropDownPopUpContentManager();
			insulinCurvePicker.dataProvider = insulinCurvesList;
			insulinCurvePicker.addEventListener(Event.CHANGE, onInsulinCurveChanged);
			
			//Curve Presets
			var insulinCurvesPresetsList:ArrayCollection = new ArrayCollection();
			insulinCurvesPresetsList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_model_rapid_acting_adults_preset'), id: "rapid-acting-adults" } );
			insulinCurvesPresetsList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_model_rapid_acting_children_preset'), id: "rapid-acting-children" } );
			insulinCurvesPresetsList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_model_ultra_rapid_adults_preset'), id: "ultra-rapid-adults" } );
			insulinCurvesPresetsList.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_model_ultra_rapid_children_preset'), id: "ultra-rapid-children" } );
			
			insulinCurvePresetsPicker = LayoutFactory.createPickerList();
			insulinCurvePresetsPicker.labelField = "label";
			insulinCurvePresetsPicker.itemRendererFactory = function():IListItemRenderer
			{
				var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				renderer.paddingRight = renderer.paddingLeft = 20;
				return renderer;
			};
			insulinCurvePresetsPicker.popUpContentManager = new DropDownPopUpContentManager();
			insulinCurvePresetsPicker.dataProvider = insulinCurvesPresetsList;
			insulinCurvePresetsPicker.prompt = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_model_custom_preset');
			insulinCurvePresetsPicker.addEventListener(Event.CHANGE, onInsulinCurvePresetChanged);
			
			//Peak
			insulinPeak = LayoutFactory.createNumericStepper(30, 210, 75, 1);
			insulinPeak.pivotX = -8;
			insulinPeak.addEventListener(Event.CHANGE, onSettingsChanged);
			insulinPeak.addEventListener(Event.CHANGE, onDiaPeakChanged);
			
			//Default Insulin
			defaultInsulinCheck = LayoutFactory.createCheckMark(false);
			defaultInsulinCheck.pivotX = 3;
			defaultInsulinCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Insulin Curve Container
			insulinCurveContainer = LayoutFactory.createLayoutGroup("vertical", HorizontalAlign.CENTER, VerticalAlign.TOP, 5);
			insulinCurveContainer.width = width;
			(insulinCurveContainer.layout as VerticalLayout).paddingTop = 15;
			(insulinCurveContainer.layout as VerticalLayout).paddingBottom = 15;
			
			//Insulin Curve Legends
			xAxisLegend = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_curve_chart_x_label'), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			insulinCurveContainer.addChild(xAxisLegend);
			
			yAxisLegend = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_curve_chart_y_label'), HorizontalAlign.RIGHT, VerticalAlign.TOP, 8, true);
			insulinCurveContainer.addChild(yAxisLegend);
	
			//Settings explanation
			insulinSettingsExplanation = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_settings_explanation'), HorizontalAlign.JUSTIFY);
			insulinSettingsExplanation.wordWrap = true;
			insulinSettingsExplanation.width = width;
			insulinSettingsExplanation.paddingTop = insulinSettingsExplanation.paddingBottom = 10;
			
			//DIA Guide Button
			var guideLayout:HorizontalLayout = new HorizontalLayout();
			guideLayout.horizontalAlign = HorizontalAlign.CENTER;
			guideContainer = new LayoutGroup();
			guideContainer.layout = guideLayout;
			guideContainer.width = width;
			diaGuideButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','guide_button_label'));
			diaGuideButton.addEventListener(Event.TRIGGERED, onGuide);
			guideContainer.addChild(diaGuideButton);
			
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.gap = 10;
			
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			
			//Cancel New Insulin
			cancelInsulinButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label'));
			cancelInsulinButton.addEventListener(Event.TRIGGERED, onCancelInsulin);
			actionsContainer.addChild(cancelInsulinButton);
			
			//Save New Insulin
			saveInsulinButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','save_button_label'));
			saveInsulinButton.isEnabled = false;
			saveInsulinButton.addEventListener(Event.TRIGGERED, onSaveInsulin);
			actionsContainer.addChild(saveInsulinButton);
			
			/* Set Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "text";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingRight = 0;
				return itemRenderer;
			};
			
			refreshContent();
		}
		
		private function onInsulinTypeChanged(e:Event):void
		{
			if (insulinTypesPicker != null && insulinTypesPicker.selectedIndex == 4)
			{
				insulinDIA.maximum = 72;
				insulinDIA.value = 24;
				isBasalEnabled = true;
			}
			else
			{
				insulinDIA.maximum = 8;
				if (insulinDIA.value > 8) insulinDIA.value = 8;
				isBasalEnabled = false;
			}
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Set screen content
			var data:Array = [];
			
			for (var i:int = 0; i < userInsulins.length; i++) 
			{
				var insulin:Insulin = userInsulins[i];
				if (insulin.name.indexOf("Nightscout") == -1 && !insulin.isHidden)
				{
					var insulinAccessory:TreatmentManagerAccessory = new TreatmentManagerAccessory();
					insulinAccessory.addEventListener(TreatmentManagerAccessory.EDIT, onEditInsulin);
					insulinAccessory.addEventListener(TreatmentManagerAccessory.DELETE, onDeleteInsulin);
					accessoryList.push(insulinAccessory);
					data.push( { label: insulin.name, accessory: insulinAccessory, insulin: insulin } );
				}
			}
			
			data.push( { label: "", accessory: addInsulinButton } );
			
			if (newInsulinMode || editInsulinMode)
			{
				modeLabel.text = newInsulinMode ? ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','new_insulin_label') : ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','edit_insulin_label');
				data.push( { label: "", accessory: modeLabel } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','name_label'), accessory: insulinName } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','type_label'), accessory: insulinTypesPicker } );
				if (!isBasalEnabled)
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps")
					{
						data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_model_label'), accessory: insulinCurvePicker } );
						
						if (selectedInsulinCurve == "exponential")
						{
							data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_model_presets_label'), accessory: insulinCurvePresetsPicker } );
						}
					}
				}
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','dia_label'), accessory: insulinDIA } );
				if (!isBasalEnabled)
				{
					if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps" && selectedInsulinCurve == "exponential")
					{
						data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_peak_label'), accessory: insulinPeak } );
					}
					data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','default_insulin_label'), accessory: defaultInsulinCheck } );
				
					plotInsulinCurve();
					data.push( { label: "", accessory: insulinCurveContainer } );
				}
				
				data.push( { label: "", accessory: actionsContainer } );
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps" && !isBasalEnabled)
				{
					insulinSettingsExplanation.text = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_curve_peak_description') + "\n\n" + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_settings_explanation');
				}
				else
				{
					if (!isBasalEnabled)
					{
						insulinSettingsExplanation.text = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_settings_explanation');
					}
					else
					{
						var startIndex:int = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_settings_explanation').indexOf("\n");
						insulinSettingsExplanation.text = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_settings_explanation').slice(0, startIndex);
					}
				}
				data.push( { label: "", accessory: insulinSettingsExplanation } );
				data.push( { label: "", accessory: guideContainer } );
			}
			
			dataProvider = new ArrayCollection(data);
		}
		
		private function plotInsulinCurve():void
		{
			if (insulinCurveGraph != null)
			{
				insulinCurveGraph.removeFromParent();
				insulinCurveGraph.dispose();
				insulinCurveGraph = null;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps")
			{
				if (selectedInsulinCurve == "exponential")
				{
					insulinCurveGraph = new SpikeInsulinActivityCurve(SpikeInsulinActivityCurve.EXPONENTIAL_OPENAPS_MODEL, insulinDIA.value, insulinPeak.value);
					insulinCurveContainer.addChildAt(insulinCurveGraph, 0);
					insulinCurveContainer.readjustLayout();
					insulinCurveContainer.validate();
					insulinCurveGraph.x = 30;
					
					if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					{
						if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
						{
							insulinCurveGraph.x += 25;
						}
						else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						{
							insulinCurveGraph.x += 35;
						}
					}
				}
				else if (selectedInsulinCurve == "bilinear")
				{
					insulinCurveGraph = new SpikeInsulinActivityCurve(SpikeInsulinActivityCurve.BILINEAR_OPENAPS_MODEL, insulinDIA.value);
					insulinCurveContainer.addChildAt(insulinCurveGraph, 0);
					insulinCurveContainer.readjustLayout();
					insulinCurveContainer.validate();
					insulinCurveGraph.x = 30;
					
					if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
					{
						if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
						{
							insulinCurveGraph.x += 25;
						}
						else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						{
							insulinCurveGraph.x += 35;
						}
					}
				}
			}
			else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "nightscout")
			{
				insulinCurveGraph = new SpikeInsulinActivityCurve(SpikeInsulinActivityCurve.NIGHTSCOUT_MODEL, insulinDIA.value);
				insulinCurveContainer.addChildAt(insulinCurveGraph, 0);
				insulinCurveContainer.readjustLayout();
				insulinCurveContainer.validate();
				insulinCurveGraph.x = 30;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						insulinCurveGraph.x += 25;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						insulinCurveGraph.x += 35;
					}
				}
			}
		}
		
		private function onDiaPeakChanged(e:Event):void
		{
			//Check if it's basal
			if (insulinTypesPicker != null && insulinTypesPicker.selectedIndex == 4)
			{
				return;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps" && selectedInsulinCurve == "exponential")
			{
				//Perform validations to avoid breaking the exponential algorithm
				var doublePeak:Number = 2 * insulinPeak.value;
				var diaInMinutes:Number = insulinDIA.value * 60;
				
				if (diaInMinutes <= doublePeak)
				{
					//DIA in minutes needs to be greater than 2 * Peak. Let's adjust it.
					if (e.currentTarget === insulinPeak)
					{
						insulinDIA.value += 0.1;
					}
					else
					{
						insulinPeak.value -= 12;
					}
				}
				
				//Set curve preset as custom
				insulinCurvePresetsPicker.selectedIndex = -1;
				
				//Plot the curve
				plotInsulinCurve();
			}
			else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps" && selectedInsulinCurve == "bilinear")
			{
				//Plot the curve
				plotInsulinCurve();
			}
			else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "nightscout")
			{
				//Plot the curve
				plotInsulinCurve();
			}
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			if (insulinName.text != "")
				isSaveEnabled = true;
			
			draw();
		}
		
		private function onInsulinCurveChanged(e:Event):void
		{
			selectedInsulinCurve = insulinCurvePicker.selectedItem.id;
			
			if (selectedInsulinCurve == "exponential" && !editInsulinMode)
			{
				adjustSettingsForPreset();
			}
			else if (selectedInsulinCurve == "bilinear" && !editInsulinMode)
			{
				insulinDIA.value = 3;
			}
			
			if (insulinName.text != "")
				isSaveEnabled = true;
			
			refreshContent();
		}
		
		private function onInsulinCurvePresetChanged(e:Event):void
		{
			adjustSettingsForPreset();
			plotInsulinCurve();
		}
		
		private function removeDiaPeakEventListeners():void
		{
			insulinDIA.removeEventListener(Event.CHANGE, onDiaPeakChanged);
			insulinPeak.removeEventListener(Event.CHANGE, onDiaPeakChanged);
		}
		
		private function addDiaPeakEventListeners():void
		{
			insulinDIA.addEventListener(Event.CHANGE, onDiaPeakChanged);
			insulinPeak.addEventListener(Event.CHANGE, onDiaPeakChanged);
		}
		
		private function adjustSettingsForPreset():void
		{
			//Validation
			if (insulinCurvePresetsPicker.selectedIndex == -1)
				return;
			
			removeDiaPeakEventListeners();
			
			var selectedPreset:String = insulinCurvePresetsPicker.selectedItem.id;
			
			if (selectedPreset == "rapid-acting-adults")
			{
				insulinPeak.value = 75;
				insulinDIA.value = 5;
			}
			else if (selectedPreset == "rapid-acting-children")
			{
				insulinPeak.value = 50;
				insulinDIA.value = 5;
			}
			else if (selectedPreset == "ultra-rapid-adults")
			{
				insulinPeak.value = 55;
				insulinDIA.value = 5;
			}
			else if (selectedPreset == "ultra-rapid-children")
			{
				insulinPeak.value = 45;
				insulinDIA.value = 5;
			}
			
			addDiaPeakEventListeners();
		}
		
		private function onInsulinNameChanged(e:Event):void
		{
			if (insulinName.text != "")
				isSaveEnabled = true;
			else
				isSaveEnabled = false;
			
			draw();
		}
		
		private function onNewInsulin(e:Event):void
		{
			insulinDIA.value = 3;
			insulinDIA.maximum = 8;
			
			newInsulinMode = true;
			editInsulinMode = false;
			isSaveEnabled = false;
			isBasalEnabled = false;
			
			refreshContent();
		}
		
		private function onCancelInsulin(e:Event):void
		{
			//Reset variables
			newInsulinMode = false;
			editInsulinMode = false;
			isSaveEnabled = false;
			isBasalEnabled = false;
			
			//Reset controls
			defaultInsulinCheck.isSelected = false;
			insulinName.text = "";
			insulinTypesPicker.selectedIndex = 0;
			insulinCurvePicker.selectedIndex = 0;
			insulinPeak.value = 75;
			selectedInsulinCurve = "bilinear";
			insulinDIA.value = 5;
			insulinCurvePresetsPicker.selectedIndex = 0;
			
			//Refresh screen content
			refreshContent();
			
			//Reset vertical scroll position
			dispatchEventWith(Event.CLOSE);
		}
		
		private function onEditInsulin(e:Event):void
		{
			//Set display controls to insulin properties
			isBasalEnabled = false;
			
			var insulin:Insulin = (((e.currentTarget as TreatmentManagerAccessory).parent as Object).data as Object).insulin as Insulin;
			insulinName.text = insulin.name;
			defaultInsulinCheck.isSelected = insulin.isDefault;
			var selectedInsulinTypeIndex:int = 0;
			for (var i:int = 0; i < insulinTypesPicker.dataProvider.length; i++) 
			{
				var typeLabel:String = (insulinTypesPicker.dataProvider as ArrayCollection).arrayData[i].label;
				if (typeLabel == insulin.type)
				{
					selectedInsulinTypeIndex = i;
					break;
				}
			}
			insulinTypesPicker.selectedIndex = selectedInsulinTypeIndex;
			insulinPeak.value = insulin.peak;
			insulinDIA.value = insulin.dia;
			
			if (insulin.dia == 5 && insulin.peak == 75)
			{
				insulinCurvePresetsPicker.selectedIndex = 0;
			}
			else if (insulin.dia == 5 && insulin.peak == 50)
			{
				insulinCurvePresetsPicker.selectedIndex = 1;
			}
			else if (insulin.dia == 5 && insulin.peak == 55)
			{
				insulinCurvePresetsPicker.selectedIndex = 2;
			}
			else if (insulin.dia == 5 && insulin.peak == 45)
			{
				insulinCurvePresetsPicker.selectedIndex = 3;
			}
			else
			{
				insulinCurvePresetsPicker.selectedIndex = -1;
			}
			
			if (insulin.curve == "bilinear")
				insulinCurvePicker.selectedIndex = 0;
			else if (insulin.curve == "exponential")
				insulinCurvePicker.selectedIndex = 1;
			else
				insulinCurvePicker.selectedIndex = 0;
			
			//Mark insulin to edit
			insulinToEdit = insulin;
			
			//Set modes
			editInsulinMode = true;
			newInsulinMode = false;
			isSaveEnabled = false;
			
			refreshContent();
		}
		
		private function onDeleteInsulin(e:Event):void
		{
			var insulin:Insulin = (((e.currentTarget as TreatmentManagerAccessory).parent as Object).data as Object).insulin as Insulin;
			if (insulin != null)
			{
				ProfileManager.deleteInsulin(insulin);
				
				refreshContent();
			}
		}
		
		private function onSaveInsulin(e:Event):void
		{
			//Common variables
			var i:int;
			var insulin:Insulin;
			
			if (newInsulinMode)
			{
				//Remove default from all other insulins
				if (defaultInsulinCheck.isSelected)
				{
					for (i = 0; i < userInsulins.length; i++) 
					{
						insulin = userInsulins[i];
						if (insulin.isDefault)
						{
							insulin.isDefault = false;
							ProfileManager.updateInsulin(insulin);
						}
					}
				}
				
				//Add insulin to Spike
				ProfileManager.addInsulin
				(
					insulinName.text, 
					insulinDIA.value, 
					insulinTypesPicker.selectedItem.label, 
					defaultInsulinCheck.isSelected, 
					null, 
					true, 
					false, 
					insulinCurvePicker.selectedItem.id, 
					insulinPeak.value
				);
			}
			else if (editInsulinMode && insulinToEdit != null)
			{
				insulinToEdit.dia = insulinDIA.value;
				insulinToEdit.isDefault = defaultInsulinCheck.isSelected;
				insulinToEdit.name = insulinName.text;
				insulinToEdit.type = insulinTypesPicker.selectedItem.label;
				insulinToEdit.curve = insulinCurvePicker.selectedItem.id;
				insulinToEdit.peak = insulinPeak.value;
				
				//Remove default from all other insulins
				if (defaultInsulinCheck.isSelected)
				{
					for (i = 0; i < userInsulins.length; i++) 
					{
						insulin = userInsulins[i];
						if (insulin.isDefault && insulin.ID != insulinToEdit.ID)
						{
							insulin.isDefault = false;
							ProfileManager.updateInsulin(insulin);
						}
					}
				}
				
				//Update Database
				ProfileManager.updateInsulin(insulinToEdit);
				
				//Update all previous treatments
				var numberOfTreatments:uint = TreatmentsManager.treatmentsList.length;
				for (var j:int = 0; j < numberOfTreatments; j++) 
				{
					var treatment:Treatment = TreatmentsManager.treatmentsList[j];
					if (treatment != null && treatment.insulinAmount > 0 && treatment.insulinID == insulinToEdit.ID)
					{
						treatment.dia = insulinDIA.value;
						TreatmentsManager.updateTreatment(treatment);
					}
				}
				
			}
			
			//Reset Modes
			newInsulinMode = false;
			editInsulinMode = false;
			
			//Reset Controls
			defaultInsulinCheck.isSelected = false;
			isSaveEnabled = false;
			insulinName.text = "";
			insulinTypesPicker.selectedIndex = 0;
			insulinDIA.value = 5;
			insulinCurvePicker.selectedIndex = 0;
			selectedInsulinCurve = "bilinear";
			insulinPeak.value = 75;
			insulinCurvePresetsPicker.selectedIndex = 0;
			
			//Reset Objects 
			insulinToEdit = null;
			
			refreshContent();
			
			//Reset vertical scroll position
			dispatchEventWith(Event.CLOSE);
		}
		
		private function onGuide(e:Event):void
		{
			navigateToURL(new URLRequest("https://www.waltzingthedragon.ca/diabetes/managing-bg/adjusting-insulin-pump-duration-of-insulin-action-dia/"));
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (modeLabel != null)
				modeLabel.width = width;
			
			if (insulinSettingsExplanation != null)
				insulinSettingsExplanation.width = width;
			
			if (insulinSettingsExplanation != null)
				guideContainer.width = width;
			
			if (insulinName != null)
			{
				insulinName.width = Constants.isPortrait ? 140: 240;
				if (DeviceInfo.isTablet()) insulinName.width += 100;
			}
			
			if (insulinCurveContainer != null)
			{
				insulinCurveContainer.width = width;
			}
			
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DEFAULT_IOB_COB_ALGORITHM) == "openaps" && selectedInsulinCurve == "exponential")
			{
				SystemUtil.executeWhenApplicationIsActive(plotInsulinCurve);
			}
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override protected function draw():void
		{
			try
			{
				(layout as VerticalLayout).hasVariableItemDimensions = true;
			} 
			catch(error:Error) {}
			
			if (saveInsulinButton != null)
				saveInsulinButton.isEnabled = isSaveEnabled;
			
			super.draw();
		}
		
		override public function dispose():void
		{
			if (accessoryList != null)
			{
				for (var i:int = 0; i < accessoryList.length; i++) 
				{
					var accessory:TreatmentManagerAccessory = accessoryList[i];
					accessory.removeEventListener(TreatmentManagerAccessory.EDIT, onEditInsulin);
					accessory.removeEventListener(TreatmentManagerAccessory.DELETE, onDeleteInsulin);
					accessory.dispose();
					accessory = null;
				}
				
			}
			
			if (addInsulinButton != null)
			{
				addInsulinButton.removeEventListener(Event.TRIGGERED, onNewInsulin);
				addInsulinButton.dispose();
				addInsulinButton = null;
			}
			
			if (saveInsulinButton != null)
			{
				saveInsulinButton.removeFromParent();
				saveInsulinButton.removeEventListener(Event.TRIGGERED, onSaveInsulin);
				saveInsulinButton.dispose();
				saveInsulinButton = null;
			}
			
			if (cancelInsulinButton != null)
			{
				cancelInsulinButton.removeFromParent();
				cancelInsulinButton.removeEventListener(Event.TRIGGERED, onCancelInsulin);
				cancelInsulinButton.dispose();
				cancelInsulinButton = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (insulinDIA != null)
			{
				insulinDIA.removeEventListener(Event.CHANGE, onSettingsChanged);
				insulinDIA.dispose();
				insulinDIA = null;
			}
			
			if (insulinTypesPicker != null)
			{
				insulinTypesPicker.removeEventListener(Event.CHANGE, onSettingsChanged);
				insulinTypesPicker.dispose();
				insulinTypesPicker = null;
			}
			
			if (insulinCurvePicker != null)
			{
				insulinCurvePicker.removeEventListener(Event.CHANGE, onInsulinCurveChanged);
				insulinCurvePicker.dispose();
				insulinCurvePicker = null;
			}
			
			if (insulinPeak != null)
			{
				insulinPeak.removeEventListener(Event.CHANGE, onSettingsChanged);
				insulinPeak.dispose();
				insulinPeak = null;
			}
			
			if (insulinName != null)
			{
				insulinName.removeEventListener(Event.CHANGE, onInsulinNameChanged);
				insulinName.dispose();
				insulinName = null;
			}
			
			if (insulinSettingsExplanation != null)
			{
				insulinSettingsExplanation.dispose();
				insulinSettingsExplanation = null;
			}
			
			if (modeLabel != null)
			{
				modeLabel.dispose();
				modeLabel = null;
			}
			
			if (defaultInsulinCheck != null)
			{
				defaultInsulinCheck.removeEventListener(Event.CHANGE, onSettingsChanged);
				defaultInsulinCheck.dispose();
				defaultInsulinCheck = null;
			}
			
			if (diaGuideButton != null)
			{
				diaGuideButton.removeFromParent();
				diaGuideButton.removeEventListener(Event.TRIGGERED, onGuide);
				diaGuideButton.dispose();
				diaGuideButton = null;
			}
			
			if (guideContainer != null)
			{
				guideContainer.dispose();
				guideContainer = null;
			}
			
			if (insulinCurvePresetsPicker != null)
			{
				insulinCurvePresetsPicker.removeFromParent();
				insulinCurvePresetsPicker.removeEventListener(Event.CHANGE, onInsulinCurvePresetChanged);
				insulinCurvePresetsPicker.dispose();
				insulinCurvePresetsPicker = null;
			}
			
			if (insulinCurveGraph != null)
			{
				insulinCurveGraph.removeFromParent();
				insulinCurveGraph.dispose();
				insulinCurveGraph = null;
			}
			
			if (insulinCurveContainer != null)
			{
				insulinCurveContainer.removeFromParent();
				insulinCurveContainer.dispose();
				insulinCurveContainer = null;
			}
			
			if (xAxisLegend != null)
			{
				xAxisLegend.removeFromParent();
				xAxisLegend.dispose();
				xAxisLegend = null;
			}
			
			if (yAxisLegend != null)
			{
				yAxisLegend.removeFromParent();
				yAxisLegend.dispose();
				yAxisLegend = null;
			}
			
			super.dispose();
		}
	}
}