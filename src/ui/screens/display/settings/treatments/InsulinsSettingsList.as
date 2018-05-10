package ui.screens.display.settings.treatments
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
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
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class InsulinsSettingsList extends List 
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
		
		/* Properties */
		private var userInsulins:Array;
		private var newInsulinMode:Boolean = false;
		private var editInsulinMode:Boolean = false;
		private var isSaveEnabled:Boolean = false;
		private var accessoryList:Array = [];
		private var insulinToEdit:Insulin;
		
		public function InsulinsSettingsList()
		{
			super();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
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
			insulinName.addEventListener(Event.CHANGE, onInsulinNameChanged);
			
			//New Insulin Type
			var insulinTypesLabelList:Array = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_types_list').split(",");
			var insulinTypesList:ArrayCollection = new ArrayCollection();
			for (var i:int = 0; i < insulinTypesLabelList.length; i++) 
			{
				insulinTypesList.push( {label: insulinTypesLabelList[i] } );
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
			
			//New Insulin DIA
			insulinDIA = LayoutFactory.createNumericStepper(0.5, 150, 3, 0.1);
			insulinDIA.pivotX = -8;
			insulinDIA.addEventListener(Event.CHANGE, onSettingsChanged);
			
			//Default Insulin
			defaultInsulinCheck = LayoutFactory.createCheckMark(false);
			defaultInsulinCheck.pivotX = 3;
			defaultInsulinCheck.addEventListener(Event.CHANGE, onSettingsChanged);
			
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
		
		private function refreshContent():void
		{
			//Set screen content
			var data:Array = [];
			
			for (var i:int = 0; i < userInsulins.length; i++) 
			{
				var insulin:Insulin = userInsulins[i];
				if (insulin.name.indexOf("Nightscout") == -1)
				{
					var insulinAccessory:InsulinManagerAccessory = new InsulinManagerAccessory();
					insulinAccessory.addEventListener(InsulinManagerAccessory.EDIT, onEditInsulin);
					insulinAccessory.addEventListener(InsulinManagerAccessory.DELETE, onDeleteInsulin);
					accessoryList.push(insulinAccessory);
					data.push( { text: insulin.name, accessory: insulinAccessory, insulin: insulin } );
				}
			}
			
			data.push( { text: "", accessory: addInsulinButton } );
			
			if (newInsulinMode || editInsulinMode)
			{
				modeLabel.text = newInsulinMode ? ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','new_insulin_label') : ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','edit_insulin_label');
				data.push( { text: "", accessory: modeLabel } );
				data.push( { text: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','name_label'), accessory: insulinName } );
				data.push( { text: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','type_label'), accessory: insulinTypesPicker } );
				data.push( { text: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','dia_label'), accessory: insulinDIA } );
				data.push( { text: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','default_insulin_label'), accessory: defaultInsulinCheck } );
				data.push( { text: "", accessory: actionsContainer } );
				data.push( { text: "", accessory: insulinSettingsExplanation } );
				data.push( { text: "", accessory: guideContainer } );
			}
			
			dataProvider = new ArrayCollection(data);
		}
		
		/**
		 * Event Listeners
		 */
		private function onSettingsChanged(e:Event):void
		{
			isSaveEnabled = true;
			
			draw();
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
			newInsulinMode = true;
			editInsulinMode = false;
			isSaveEnabled = false;
			
			refreshContent();
		}
		
		private function onCancelInsulin(e:Event):void
		{
			//Reset variables
			newInsulinMode = false;
			editInsulinMode = false;
			isSaveEnabled = false;
			
			//Reset controls
			defaultInsulinCheck.isSelected = false;
			insulinName.text = "";
			insulinTypesPicker.selectedIndex = 0;
			
			//Refresh screen content
			refreshContent();
		}
		
		private function onEditInsulin(e:Event):void
		{
			//Set display controls to insulin properties
			var insulin:Insulin = (((e.currentTarget as InsulinManagerAccessory).parent as Object).data as Object).insulin as Insulin;
			insulinName.text = insulin.name;
			defaultInsulinCheck.isSelected = insulin.isDefault;
			insulinDIA.value = insulin.dia;
			var selectedInsulinTypeIndex:int = 0;
			for (var i:int = 0; i < insulinTypesPicker.dataProvider.length; i++) 
			{
				//trace(ObjectUtil.toString(insulinTypesPicker.dataProvider.arrayData));
				var typeLabel:String = (insulinTypesPicker.dataProvider as ArrayCollection).arrayData[i].label;
				if (typeLabel == insulin.type)
				{
					selectedInsulinTypeIndex = i;
					break;
				}
			}
			insulinTypesPicker.selectedIndex = selectedInsulinTypeIndex
			
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
			var insulin:Insulin = (((e.currentTarget as InsulinManagerAccessory).parent as Object).data as Object).insulin as Insulin;
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
				ProfileManager.addInsulin(insulinName.text, insulinDIA.value, insulinTypesPicker.selectedItem.label, defaultInsulinCheck.isSelected);
			}
			else if (editInsulinMode && insulinToEdit != null)
			{
				insulinToEdit.dia = insulinDIA.value;
				insulinToEdit.isDefault = defaultInsulinCheck.isSelected;
				insulinToEdit.name = insulinName.text;
				insulinToEdit.type = insulinTypesPicker.selectedItem.label;
				
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
				
				ProfileManager.updateInsulin(insulinToEdit);
			}
			
			//Reset Modes
			newInsulinMode = false;
			editInsulinMode = false;
			
			//Reset Controls
			defaultInsulinCheck.isSelected = false;
			isSaveEnabled = false;
			insulinName.text = "";
			insulinTypesPicker.selectedIndex = 0;
			
			//Reset Objects 
			insulinToEdit = null;
			
			refreshContent();
		}
		
		private function onGuide(e:Event):void
		{
			navigateToURL(new URLRequest("https://www.waltzingthedragon.ca/diabetes/managing-bg/adjusting-insulin-pump-duration-of-insulin-action-dia/"));
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
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (modeLabel != null)
				modeLabel.width = width;
			
			if (insulinSettingsExplanation != null)
				insulinSettingsExplanation.width = width;
			
			if (insulinSettingsExplanation != null)
				guideContainer.width = width;
			
			if (insulinName != null)
				insulinName.width = Constants.isPortrait ? 140: 240;
		}
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (accessoryList != null)
			{
				for (var i:int = 0; i < accessoryList.length; i++) 
				{
					var accessory:InsulinManagerAccessory = accessoryList[i];
					accessory.removeEventListener(InsulinManagerAccessory.EDIT, onEditInsulin);
					accessory.removeEventListener(InsulinManagerAccessory.DELETE, onDeleteInsulin);
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
			
			super.dispose();
		}
	}
}