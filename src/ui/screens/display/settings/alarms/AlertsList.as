package ui.screens.display.settings.alarms
{
	import flash.display.StageOrientation;
	
	import database.AlertType;
	import database.Database;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	[ResourceBundle("alertsettingsscreen")]
	[ResourceBundle("globaltranslations")]

	public class AlertsList extends SpikeList 
	{
		/* Display Objects */
		private var addAlertButton:Button;
		private var positionHelper:Sprite;
		private var alertCreatorCallout:Callout;
		private var alertCreatorList:AlertCustomizerList;
		
		/* Internal Variables/Objects */
		private var alertTypesList:Array;
		private var alertTypesButtonsList:Array;
		
		public function AlertsList()
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
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
		}
		
		private function setupInitialContent():void
		{
			/* Get All Current Alert Types */
			alertTypesList = Database.getAlertTypesList();
			
			/* Instantiate Objects */
			alertTypesButtonsList = [];
		}
		
		private function setupContent():void
		{
			/* Controls */
			addAlertButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"add_alert_button_label"), false, MaterialDeepGreyAmberMobileThemeIcons.addAlertTexture);
			addAlertButton.gap = 5;
			addAlertButton.pivotX = -12;
			addAlertButton.addEventListener(Event.TRIGGERED, onAddAlert);
			
			/* Data */
			var listContent:ListCollection = new ListCollection();
			
			var dataLength:int = alertTypesList.length
			for (var i:int = 0; i < dataLength; i++) 
			{
				var alertType:AlertType = alertTypesList[i];
				
				if (alertType.alarmName != "null" && alertType.alarmName != "No Alert")
				{
					var alertControls:AlertManagerAccessory = new AlertManagerAccessory();
					alertControls.pivotX = 2;
					alertControls.addEventListener(AlertManagerAccessory.DELETE, onDeleteAlert);
					alertControls.addEventListener(AlertManagerAccessory.EDIT, onEditAlert);
					alertTypesButtonsList.push(alertControls);
					
					listContent.push( { label: alertType.alarmName, accessory: alertControls, data: alertType, index: i } )
				}
			}
			
			listContent.push( { label: "", accessory: addAlertButton } );
			
			dataProvider = listContent;
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
		}
		
		private function setupCalloutPosition():void
		{
			positionHelper = new Sprite();
			positionHelper.x = (Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2)) / 2;
			positionHelper.y = -45;
			addChild(positionHelper);
		}
		
		private function showAlertCreator():void
		{
			alertCreatorList.addEventListener(Event.COMPLETE, onAlertCreatorClosed);
			
			alertCreatorCallout = new Callout();
			alertCreatorCallout.content = alertCreatorList;
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4)
				alertCreatorCallout.padding = 18;
			else
			{
				if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
					alertCreatorCallout.padding = 18;
				
				setupCalloutPosition();
				alertCreatorCallout.origin = positionHelper;
			}
			
			PopUpManager.addPopUp(alertCreatorCallout, false, false);
		}
		
		public function closeAlertCallout():void
		{
			if (alertCreatorCallout != null)
				alertCreatorCallout.close(true);
		}
		
		/**
		 * Event Handlers
		 */
		private function onDeleteAlert(e:Event):void
		{
			//Get alert data
			var alertData:AlertType = (((e.currentTarget as AlertManagerAccessory).parent as DefaultListItemRenderer).data as Object).data as AlertType;
			var alertName:String = alertData.alarmName;
			
			//Check if alert is in use
			if (AlertType.alertTypeUsed(alertName)) 
			{
				//Alert is in use. Display messag to user notifying that the alert can't be deleted
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alerttype_in_use_alert_title"),
					ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"alerttype_in_use_alert_message")
				);
			}
			else
			{
				//Get current alert index
				var alertIndex:int = (((e.currentTarget as AlertManagerAccessory).parent as DefaultListItemRenderer).data as Object).index;
				
				//Show delete confirmation alert
				AlertManager.showActionAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations',"warning_alert_title"),
					ModelLocator.resourceManagerInstance.getString('alertsettingsscreen',"delete_alert_type_confirmation_message"),
					Number.NaN,
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"no_uppercase") },	
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations',"yes_uppercase"), triggered: onDeleteAlert }	
					]
				);
				
				function onDeleteAlert(e:Event):void
				{
					//Alert not in use. Delete it from databalse
					Database.deleteAlertTypeSynchronous(alertData);
					
					//Update screen
					alertTypesList.removeAt(alertIndex);
					setupContent();
				}
			}
		}
		
		private function onEditAlert(e:Event):void
		{
			//Get alert type data
			var alertData:AlertType = (((e.currentTarget as AlertManagerAccessory).parent as DefaultListItemRenderer).data as Object).data as AlertType;
			
			//Create Alert Creator and Show it
			alertCreatorList = new AlertCustomizerList(alertData);
			showAlertCreator();
		}
		
		private function onAddAlert(e:Event):void 
		{
			//Create Alert Creator and Show it
			alertCreatorList = new AlertCustomizerList(null);
			showAlertCreator();
		}
		
		private function onAlertCreatorClosed():void
		{
			//Refresh Screen
			alertTypesList = Database.getAlertTypesList();
			setupContent();
			
			//Close callout
			alertCreatorCallout.close(true);
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (positionHelper != null)
				positionHelper.x = (Constants.stageWidth - (BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding * 2)) / 2;
			
			if (addAlertButton != null && Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait && Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
				addAlertButton.pivotX = -6;
			else
				addAlertButton.pivotX = -12;
			
			setupRenderFactory();
		}
		
		/**
		 * Utility 
		 */
		override public function dispose():void
		{	
			if(addAlertButton != null)
			{
				addAlertButton.addEventListener(Event.TRIGGERED, onAddAlert);
				addAlertButton.dispose();
				addAlertButton = null;
			}
			
			if (alertTypesButtonsList != null && alertTypesButtonsList.length > 0)
			{
				var buttonsListLength:int = alertTypesButtonsList.length;
				for (var i:int = 0; i < buttonsListLength; i++) 
				{
					var alertManagerButton:AlertManagerAccessory = alertTypesButtonsList[i];
					alertManagerButton.dispose();
					alertManagerButton = null;
				}
			}
			
			if (positionHelper != null)
			{
				removeChild(positionHelper);
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (alertCreatorCallout != null)
			{
				alertCreatorCallout.dispose();
				alertCreatorCallout = null;
			}
			
			if (alertCreatorList != null)
			{
				alertCreatorList.dispose();
				alertCreatorList = null;
			}
			
			super.dispose();
		}
	}
}