package ui.screens.display.settings.profile
{
	import feathers.controls.Button;
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
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import treatments.Insulin;
	import treatments.ProfileManager;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("profilesettingsscreen")]

	public class InsulinsSettingsList extends List 
	{
		/* Display Objects */
		private var insulinsPicker:PickerList;
		
		/* Properties */
		public var needsSave:Boolean = false;

		private var userInsulins:Array;

		private var addInsulinContainer:LayoutGroup;

		private var addInsulinButton:Button;

		private var insulinDIA:NumericStepper;

		private var saveInsulinButton:Button;

		private var insulinTypesPicker:PickerList;

		private var insulinName:TextInput;
		
		private var newInsulinMode:Boolean = false;

		private var diaExplanation:Label;
		
		public function InsulinsSettingsList()
		{
			super();
			
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
			//Insulins Picker List
			insulinsPicker = LayoutFactory.createPickerList();
			
			//Add Insulin Button
			var addInsulinLayout:HorizontalLayout = new HorizontalLayout();
			addInsulinLayout.horizontalAlign = HorizontalAlign.CENTER;
			addInsulinContainer = new LayoutGroup();
			addInsulinContainer.layout = addInsulinLayout;
			addInsulinContainer.width = width;
			
			addInsulinButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','add_insulin_button_label'));
			addInsulinButton.addEventListener(Event.TRIGGERED, onNewInsulin);
			addInsulinContainer.addChild(addInsulinButton);
			
			//New Insulin Name
			insulinName = LayoutFactory.createTextInput(false, false, 140, HorizontalAlign.RIGHT);
			
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
			
			//New Insulin DIA
			insulinDIA = LayoutFactory.createNumericStepper(0.5, 150, 3, 0.1);
			
			//DIA explanation
			diaExplanation = LayoutFactory.createLabel("DIA means Duration of Insulin Action - The ammount of hours the insulin stays active in your body. This setting is used to calculate IOB (Insulin On Board) in Spike's main chart.", HorizontalAlign.JUSTIFY);
			diaExplanation.wordWrap = true;
			diaExplanation.width = width;
			diaExplanation.paddingTop = diaExplanation.paddingBottom = 10;
			
			//Save New Insulin
			saveInsulinButton = LayoutFactory.createButton("Save");
			saveInsulinButton.addEventListener(Event.TRIGGERED, onSaveInsulin);
			
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
			/* Set Insulins Data */
			insulinsPicker.removeEventListener(Event.CHANGE, onInsulinChanged);
			var insulinsList:ArrayCollection = new ArrayCollection();
			if (userInsulins != null)
			{
				for (var i:int = 0; i < userInsulins.length; i++) 
				{
					var insulin:Insulin = userInsulins[i];
					insulinsList.push( {label: insulin.name, id: insulin.ID} );
				}
			}
			insulinsPicker.labelField = "label";
			insulinsPicker.itemRendererFactory = function():IListItemRenderer
			{
				var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				renderer.paddingRight = renderer.paddingLeft = 20;
				return renderer;
			};
			insulinsPicker.popUpContentManager = new DropDownPopUpContentManager();
			insulinsPicker.dataProvider = insulinsList;
			insulinsPicker.addEventListener(Event.CHANGE, onInsulinChanged);
			
			
			//Set screen content
			var data:Array = [];
			if (userInsulins != null && userInsulins.length > 0)
				data.push( { text: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_name_label'), accessory: insulinsPicker } );
			data.push( { text: "", accessory: addInsulinButton } );
			if (newInsulinMode)
			{
				data.push( { text: "Name", accessory: insulinName } );
				data.push( { text: "Type", accessory: insulinTypesPicker } );
				data.push( { text: "DIA (Hours)", accessory: insulinDIA } );
				data.push( { text: "", accessory: diaExplanation } );
				data.push( { text: "", accessory: saveInsulinButton } );
			}
			
			
			
			dataProvider = new ArrayCollection(data);
		}
		
		public function save():void
		{
			
			
			
			
			needsSave = false;
		}
		
		/**
		 * Event Listeners
		 */
		private function onInsulinChanged(e:Event):void
		{
			
			
			needsSave = true;
		}
		
		private function onNewInsulin(e:Event):void
		{
			newInsulinMode = true;
			refreshContent();
		}
		
		private function onSaveInsulin(e:Event):void
		{
			newInsulinMode = false;
			
			//Add insulin to Spike
			ProfileManager.addInsulin(insulinName.text, insulinDIA.value, insulinTypesPicker.selectedItem.label);
			
			refreshContent();
		}
		
		private function onSettingsChanged(e:Event):void
		{
			needsSave = true;
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
			
			super.draw();
		}
		
		override public function dispose():void
		{
			if (insulinsPicker != null)
			{
				insulinsPicker.removeEventListener(Event.CHANGE, onInsulinChanged);
				insulinsPicker.dispose();
				insulinsPicker = null;
			}
			
			super.dispose();
		}
	}
}