package ui.screens.display.settings.integration
{
	import com.debokeh.anes.utils.DeviceFileUtil;
	
	import flash.filesystem.File;
	
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.renderers.DefaultGroupedListItemRenderer;
	import feathers.controls.renderers.IGroupedListItemRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.events.Event;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	
	[ResourceBundle("chartsettingsscreen")]

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
		
		public function WorkflowSettingsList()
		{
			super();
			
			setupProperties();
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
		
		private function setupContent():void
		{
			//Alarms
			alarmsSnoozerButton = LayoutFactory.createButton("Get");
			alarmsSnoozerButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			alarmsUnsnoozerButton = LayoutFactory.createButton("Get");
			alarmsUnsnoozerButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			//Transmitter
			readingsOnDemandButton = LayoutFactory.createButton("Get");
			readingsOnDemandButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			//Treatments
			bolusButton = LayoutFactory.createButton("Get");
			bolusButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			carbsButton = LayoutFactory.createButton("Get");
			carbsButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			mealButton = LayoutFactory.createButton("Get");
			mealButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			tempBasalStartButton = LayoutFactory.createButton("Get");
			tempBasalStartButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			tempBasalEndButton = LayoutFactory.createButton("Get");
			tempBasalEndButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			basalButton = LayoutFactory.createButton("Get");
			basalButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			bgCheckButton = LayoutFactory.createButton("Get");
			bgCheckButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			noteButton = LayoutFactory.createButton("Get");
			noteButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			exerciseButton = LayoutFactory.createButton("Get");
			exerciseButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			insulinCartridgeButton = LayoutFactory.createButton("Get");
			insulinCartridgeButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			pumpSiteButton = LayoutFactory.createButton("Get");
			pumpSiteButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			pumpBatteryButton = LayoutFactory.createButton("Get");
			pumpBatteryButton.addEventListener(Event.TRIGGERED, onGetWorkflow);
			
			refreshContent();
		}
		
		private function refreshContent():void
		{
			var screenDataContent:Array = [];
			
			//Alarms
			var alarmsSection:Object = {};
			alarmsSection.header = { label: "Alarms" };
			
			var alarmsSectionChildren:Array = [];
			alarmsSectionChildren.push( { label: "Alarms Snoozer", accessory: alarmsSnoozerButton } );
			alarmsSectionChildren.push( { label: "Alarms Un-Snoozer", accessory: alarmsUnsnoozerButton } );
			
			alarmsSection.children = alarmsSectionChildren;
			screenDataContent.push(alarmsSection);
			
			//Transmitter
			var transmitterSection:Object = {};
			transmitterSection.header = { label: "Transmitter" };
			
			var transmitterSectionChildren:Array = [];
			transmitterSectionChildren.push( { label: "Readings On-Demand", accessory: readingsOnDemandButton } );
			
			transmitterSection.children = transmitterSectionChildren;
			screenDataContent.push(transmitterSection);
			
			//Treatments
			var treatmentsSection:Object = {};
			treatmentsSection.header = { label: "Treatments" };
			
			var treatmentsSectionChildren:Array = [];
			treatmentsSectionChildren.push( { label: "Bolus", accessory: bolusButton } );
			treatmentsSectionChildren.push( { label: "Carbs", accessory: carbsButton } );
			treatmentsSectionChildren.push( { label: "Meal", accessory: mealButton } );
			treatmentsSectionChildren.push( { label: "Temp Basal Start", accessory: tempBasalStartButton } );
			treatmentsSectionChildren.push( { label: "Temp Basal End", accessory: tempBasalEndButton } );
			treatmentsSectionChildren.push( { label: "Basal", accessory: basalButton } );
			treatmentsSectionChildren.push( { label: "BG Check", accessory: bgCheckButton } );
			treatmentsSectionChildren.push( { label: "Note", accessory: noteButton } );
			treatmentsSectionChildren.push( { label: "Exercise", accessory: exerciseButton } );
			treatmentsSectionChildren.push( { label: "Insulin Cartridge", accessory: insulinCartridgeButton } );
			treatmentsSectionChildren.push( { label: "Pump Site", accessory: pumpSiteButton } );
			treatmentsSectionChildren.push( { label: "Pump Battery", accessory: pumpBatteryButton } );
			
			treatmentsSection.children = treatmentsSectionChildren;
			screenDataContent.push(treatmentsSection);
			
			dataProvider = new HierarchicalCollection(screenDataContent);
			
			itemRendererFactory = function():IGroupedListItemRenderer
			{
				var itemRenderer:DefaultGroupedListItemRenderer = new DefaultGroupedListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.iconSourceField = "accessory";
				itemRenderer.paddingLeft = -5;
				
				return itemRenderer;
			};
		}
		
		/**
		 * Event Listeners
		 */
		private function onGetWorkflow(e:Event):void
		{
			var selectedWorkflow:String = "";
			
			if (e.currentTarget != null && e.currentTarget == bolusButton)
			{
				trace("É BOLUS");
				selectedWorkflow = "SpikeBolus.wflow";
			}
			
			if (selectedWorkflow != "")
			{
				var workflowFile:File = File.applicationDirectory.resolvePath("assets/workflows/" + selectedWorkflow);
				var tempFile:File = File.documentsDirectory.resolvePath("tempWorkflow.wflow");
				workflowFile.copyTo(tempFile, true);
				
				trace("SIIIIIIGA");
				DeviceFileUtil.openWith("tempWorkflow.wflow");
				
				//tempFile.openWithDefaultApplication();
			}
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (alarmsSnoozerButton != null)
			{
				alarmsSnoozerButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				alarmsSnoozerButton.removeFromParent();
				alarmsSnoozerButton.dispose();
				alarmsSnoozerButton = null;
			}
			
			if (alarmsUnsnoozerButton != null)
			{
				alarmsUnsnoozerButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				alarmsUnsnoozerButton.removeFromParent();
				alarmsUnsnoozerButton.dispose();
				alarmsUnsnoozerButton = null;
			}
			
			if (readingsOnDemandButton != null)
			{
				readingsOnDemandButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				readingsOnDemandButton.removeFromParent();
				readingsOnDemandButton.dispose();
				readingsOnDemandButton = null;
			}
			
			if (bolusButton != null)
			{
				bolusButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				bolusButton.removeFromParent();
				bolusButton.dispose();
				bolusButton = null;
			}
			
			if (carbsButton != null)
			{
				carbsButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				carbsButton.removeFromParent();
				carbsButton.dispose();
				carbsButton = null;
			}
			
			if (mealButton != null)
			{
				mealButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				mealButton.removeFromParent();
				mealButton.dispose();
				mealButton = null;
			}
			
			if (tempBasalStartButton != null)
			{
				tempBasalStartButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				tempBasalStartButton.removeFromParent();
				tempBasalStartButton.dispose();
				tempBasalStartButton = null;
			}
			
			if (tempBasalEndButton != null)
			{
				tempBasalEndButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				tempBasalEndButton.removeFromParent();
				tempBasalEndButton.dispose();
				tempBasalEndButton = null;
			}
			
			if (basalButton != null)
			{
				basalButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				basalButton.removeFromParent();
				basalButton.dispose();
				basalButton = null;
			}
			
			if (bgCheckButton != null)
			{
				bgCheckButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				bgCheckButton.removeFromParent();
				bgCheckButton.dispose();
				bgCheckButton = null;
			}
			
			if (noteButton != null)
			{
				noteButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				noteButton.removeFromParent();
				noteButton.dispose();
				noteButton = null;
			}
			
			if (exerciseButton != null)
			{
				exerciseButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				exerciseButton.removeFromParent();
				exerciseButton.dispose();
				exerciseButton = null;
			}
			
			if (insulinCartridgeButton != null)
			{
				insulinCartridgeButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				insulinCartridgeButton.removeFromParent();
				insulinCartridgeButton.dispose();
				insulinCartridgeButton = null;
			}
			
			if (pumpSiteButton != null)
			{
				pumpSiteButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				pumpSiteButton.removeFromParent();
				pumpSiteButton.dispose();
				pumpSiteButton = null;
			}
			
			if (pumpBatteryButton != null)
			{
				pumpBatteryButton.removeEventListener(Event.TRIGGERED, onGetWorkflow);
				pumpBatteryButton.removeFromParent();
				pumpBatteryButton.dispose();
				pumpBatteryButton = null;
			}
			
			super.dispose();
		}
	}
}