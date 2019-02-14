package ui.screens.display.settings.integration
{	
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.display.StageOrientation;
	
	import database.CGMBlueToothDevice;
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Label;
	import feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListHeaderRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("workflowsettingsscreen")]
	[ResourceBundle("alarmsettingsscreen")]
	[ResourceBundle("transmittersettingsscreen")]
	[ResourceBundle("treatments")]

	public class WorkflowSettingsList extends GroupedList 
	{
		/* Display Objects */
		private var alarmsSnoozerButton:Button;
		private var alarmsUnsnoozerButton:Button;
		private var readingsOnDemandButton:Button;
		private var bolusButton:Button;
		private var carbsButton:Button;
		private var mealButton:Button;
		private var tempBasalStartButton:Button;
		private var tempBasalEndButton:Button;
		private var basalButton:Button;
		private var bgCheckButton:Button;
		private var noteButton:Button;
		private var exerciseButton:Button;
		private var insulinCartridgeButton:Button;
		private var pumpSiteButton:Button;
		private var pumpBatteryButton:Button;

		private var instructionsLabel:Label;
		
		public function WorkflowSettingsList()
		{
			super();
			
			setupProperties();
			setupEventListeners();
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
		
		private function setupEventListeners():void
		{
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
		}
		
		private function setupContent():void
		{
			//Alarms
			alarmsSnoozerButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			alarmsSnoozerButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			alarmsUnsnoozerButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			alarmsUnsnoozerButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			//Transmitter
			readingsOnDemandButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			readingsOnDemandButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			//Treatments
			bolusButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			bolusButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			carbsButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			carbsButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			mealButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			mealButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			tempBasalStartButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			tempBasalStartButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			tempBasalEndButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			tempBasalEndButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			basalButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			basalButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			bgCheckButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			bgCheckButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			noteButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			noteButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			exerciseButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			exerciseButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			insulinCartridgeButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			insulinCartridgeButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			pumpSiteButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			pumpSiteButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			pumpBatteryButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","import_workflow"));
			pumpBatteryButton.addEventListener(Event.TRIGGERED, onActivateWorkflow);
			
			instructionsLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","workflow_instruction_body") + "\n\n" + ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","workflow_instruction_apple_watch_disclaimer"), HorizontalAlign.JUSTIFY, VerticalAlign.TOP);
			instructionsLabel.wordWrap = true;
			instructionsLabel.width = width - 20;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
			{
				instructionsLabel.width -= 20;
			}
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var screenDataContent:Array = [];
			
			//Alarms
			var alarmsSection:Object = {};
			alarmsSection.header = { label: ModelLocator.resourceManagerInstance.getString("alarmsettingsscreen","screen_title") };
			
			var alarmsSectionChildren:Array = [];
			alarmsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","alarms_snoozer_workflow"), accessory: alarmsSnoozerButton } );
			alarmsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","alarms_unsnoozer_workflow"), accessory: alarmsUnsnoozerButton } );
			
			alarmsSection.children = alarmsSectionChildren;
			screenDataContent.push(alarmsSection);
			
			//Transmitter
			if (CGMBlueToothDevice.isMiaoMiao())
			{
				var transmitterSection:Object = {};
				transmitterSection.header = { label: ModelLocator.resourceManagerInstance.getString("transmittersettingsscreen","transmitter_settings_title") };
				
				var transmitterSectionChildren:Array = [];
				transmitterSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","readings_on_demand_workflow"), accessory: readingsOnDemandButton } );
				
				transmitterSection.children = transmitterSectionChildren;
				screenDataContent.push(transmitterSection);
			}
			
			//Treatments
			if ((CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_TREATMENTS_ENABLED) == "true" && (!CGMBlueToothDevice.isFollower() || (CGMBlueToothDevice.isFollower() && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_URL) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DATA_COLLECTION_NS_API_SECRET) != "" && CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_FOLLOWER_MODE) == "Nightscout")))) 
			{
				var treatmentsSection:Object = {};
				treatmentsSection.header = { label: ModelLocator.resourceManagerInstance.getString("treatments","treatments_screen_title") };
				
				var treatmentsSectionChildren:Array = [];
				treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_bolus"), accessory: bolusButton } );
				treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_carbs"), accessory: carbsButton } );
				treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_meal"), accessory: mealButton } );
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump")
				{
					treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_temp_basal_start"), accessory: tempBasalStartButton } );
					treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_temp_basal_end"), accessory: tempBasalEndButton } );
				}
				else if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "mdi")
				{
					treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_basal"), accessory: basalButton } );
				}
				treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_bg_check"), accessory: bgCheckButton } );
				treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_note"), accessory: noteButton } );
				treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_exercise"), accessory: exerciseButton } );
				if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_USER_TYPE_PUMP_OR_MDI) == "pump")
				{
					treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_insulin_cartridge_change"), accessory: insulinCartridgeButton } );
					treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_pump_site_change"), accessory: pumpSiteButton } );
					treatmentsSectionChildren.push( { label: ModelLocator.resourceManagerInstance.getString("treatments","treatment_name_pump_battery_change"), accessory: pumpBatteryButton } );
				}
				
				treatmentsSection.children = treatmentsSectionChildren;
				screenDataContent.push(treatmentsSection);
			
			}
			
			//Instructions
			var instructionsSection:Object = {};
			instructionsSection.header = { label: ModelLocator.resourceManagerInstance.getString("workflowsettingsscreen","workflow_instructions_title") };
			
			var instructionsSectionChildren:Array = [];
			instructionsSectionChildren.push( { label: "", accessory: instructionsLabel } );
			
			instructionsSection.children = instructionsSectionChildren;
			screenDataContent.push(instructionsSection);
			
			dataProvider = new HierarchicalCollection(screenDataContent);
			setupRenderFactory();
		}
		
		private function setupRenderFactory():void
		{
			itemRendererFactory = function():IGroupedListItemRenderer
			{
				var itemRenderer:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.iconSourceField = "accessory";
				itemRenderer.paddingLeft = -5;
				itemRenderer.paddingTop = itemRenderer.paddingBottom = 10;
				itemRenderer.accessoryLabelProperties.wordWrap = true;
				itemRenderer.defaultLabelProperties.wordWrap = true;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						itemRenderer.paddingLeft = 25;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						itemRenderer.paddingRight = 30;
					}
				}
				
				return itemRenderer;
			};
			
			headerRendererFactory = function():IGroupedListHeaderRenderer
			{
				var headerRenderer:DefaultGroupedListHeaderOrFooterRenderer = new DefaultGroupedListHeaderOrFooterRenderer();
				headerRenderer.contentLabelField = "label";
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						headerRenderer.paddingLeft = 30;
					}
				}
				
				return headerRenderer;
			};
		}
		
		/**
		 * Event Listeners
		 */
		private function onActivateWorkflow(e:Event):void
		{
			if (e.currentTarget == null)
			{
				return;
			}
			
			var selectedWorkflow:String;
			
			switch (e.currentTarget)
			{
				case alarmsSnoozerButton:
				{
					selectedWorkflow = "Snooze Alarms.wflow";
					break;
				}
				case alarmsUnsnoozerButton:
				{
					selectedWorkflow = "Un-Snooze Alarms.wflow";
					break;
				}
				case readingsOnDemandButton:
				{
					selectedWorkflow = "On-Demand.wflow";
					break;
				}
				case bolusButton:
				{
					selectedWorkflow = "Spike Bolus.wflow";
					break;
				}
				case carbsButton:
				{
					selectedWorkflow = "Spike Carbs.wflow";
					break;
				}
				case mealButton:
				{
					selectedWorkflow = "Spike Meal.wflow";
					break;
				}
				case tempBasalStartButton:
				{
					selectedWorkflow = "Spike TBasal Start.wflow";
					break;
				}
				case tempBasalEndButton:
				{
					selectedWorkflow = "Spike TBasal End.wflow";
					break;
				}
				case basalButton:
				{
					selectedWorkflow = "Spike Basal.wflow";
					break;
				}
				case bgCheckButton:
				{
					selectedWorkflow = "Spike BG Check.wflow";
					break;
				}
				case noteButton:
				{
					selectedWorkflow = "Spike Note.wflow";
					break;
				}
				case exerciseButton:
				{
					selectedWorkflow = "Spike Exercise.wflow";
					break;
				}
				case insulinCartridgeButton:
				{
					selectedWorkflow = "Spike ICartridge.wflow";
					break;
				}
				case pumpSiteButton:
				{
					selectedWorkflow = "Spike PSite.wflow";
					break;
				}
				case pumpBatteryButton:
				{
					selectedWorkflow = "Spike PBattery.wflow";
					break;
				}
			}
			
			if (selectedWorkflow != null)
			{
				SpikeANE.openWithDefaultApplication("assets/workflows/" + selectedWorkflow, SpikeANE.APPLICATION_DIR);
			}
		}
		
		protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (instructionsLabel != null)
			{
				instructionsLabel.width = width - 20;
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					instructionsLabel.width -= 20;
				}
			}
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (alarmsSnoozerButton != null)
			{
				alarmsSnoozerButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				alarmsSnoozerButton.removeFromParent();
				alarmsSnoozerButton.dispose();
				alarmsSnoozerButton = null;
			}
			
			if (alarmsUnsnoozerButton != null)
			{
				alarmsUnsnoozerButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				alarmsUnsnoozerButton.removeFromParent();
				alarmsUnsnoozerButton.dispose();
				alarmsUnsnoozerButton = null;
			}
			
			if (readingsOnDemandButton != null)
			{
				readingsOnDemandButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				readingsOnDemandButton.removeFromParent();
				readingsOnDemandButton.dispose();
				readingsOnDemandButton = null;
			}
			
			if (bolusButton != null)
			{
				bolusButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				bolusButton.removeFromParent();
				bolusButton.dispose();
				bolusButton = null;
			}
			
			if (carbsButton != null)
			{
				carbsButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				carbsButton.removeFromParent();
				carbsButton.dispose();
				carbsButton = null;
			}
			
			if (mealButton != null)
			{
				mealButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				mealButton.removeFromParent();
				mealButton.dispose();
				mealButton = null;
			}
			
			if (tempBasalStartButton != null)
			{
				tempBasalStartButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				tempBasalStartButton.removeFromParent();
				tempBasalStartButton.dispose();
				tempBasalStartButton = null;
			}
			
			if (tempBasalEndButton != null)
			{
				tempBasalEndButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				tempBasalEndButton.removeFromParent();
				tempBasalEndButton.dispose();
				tempBasalEndButton = null;
			}
			
			if (basalButton != null)
			{
				basalButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				basalButton.removeFromParent();
				basalButton.dispose();
				basalButton = null;
			}
			
			if (bgCheckButton != null)
			{
				bgCheckButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				bgCheckButton.removeFromParent();
				bgCheckButton.dispose();
				bgCheckButton = null;
			}
			
			if (noteButton != null)
			{
				noteButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				noteButton.removeFromParent();
				noteButton.dispose();
				noteButton = null;
			}
			
			if (exerciseButton != null)
			{
				exerciseButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				exerciseButton.removeFromParent();
				exerciseButton.dispose();
				exerciseButton = null;
			}
			
			if (insulinCartridgeButton != null)
			{
				insulinCartridgeButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				insulinCartridgeButton.removeFromParent();
				insulinCartridgeButton.dispose();
				insulinCartridgeButton = null;
			}
			
			if (pumpSiteButton != null)
			{
				pumpSiteButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				pumpSiteButton.removeFromParent();
				pumpSiteButton.dispose();
				pumpSiteButton = null;
			}
			
			if (pumpBatteryButton != null)
			{
				pumpBatteryButton.removeEventListener(Event.TRIGGERED, onActivateWorkflow);
				pumpBatteryButton.removeFromParent();
				pumpBatteryButton.dispose();
				pumpBatteryButton = null;
			}
			
			super.dispose();
		}
	}
}