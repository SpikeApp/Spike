package ui.popups
{	
	import com.adobe.utils.StringUtil;
	
	import flash.errors.IllegalOperationError;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	
	import model.ModelLocator;
	
	import services.AlarmService;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.ResizeEvent;
	import starling.utils.SystemUtil;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;

	[ResourceBundle("globaltranslations")]
	[ResourceBundle("alarmpresnoozer")]
	[ResourceBundle("alarmservice")]
	
	public class AlarmPreSnoozer extends EventDispatcher
	{
		/* Constants */
		public static const CANCELLED:String = "onCancelled";
		public static const CLOSED:String = "onClosed";
		
		/* Display Objects */
		private static var snoozePickerList:PickerList;
		private static var snoozeCallout:Callout;
		private static var titleLabel:Label;
		private static var mainContainer:LayoutGroup;
		private static var actionButtonsContainer:LayoutGroup;
		private static var alarmTypesPicker:PickerList;
		private static var preSnoozeButton:Button;
		private static var snoozeStatusLabel:Label;
		private static var cancelButton:Button;
		private static var unSnoozeButton:Button;
		private static var positionHelper:Sprite;
		
		/* Properties */
		private static var firstRun:Boolean = true;
		private static var _instance:AlarmPreSnoozer;
		private static var dataProvider:ArrayCollection;
		private static var selectedSnoozeIndex:int = 0;
		private static var snoozeLabels:Array;
		private static var snoozeTitle:String = "";
		private static var unSnoozeAction:Function = null;
		private static var snoozeAction:Function = null;
		
		public function AlarmPreSnoozer()
		{
			//Don't allow class to be instantiated
			if (_instance != null)
				throw new IllegalOperationError("AlarmSnoozer class is not meant to be instantiated!");
		}
		
		/**
		 * Functionality
		 */
		public static function displaySnoozer(title:String, labels:Array):void
		{
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			//Update internal variables
			if (snoozeLabels == null) snoozeLabels = labels;
			snoozeTitle = title;
			
			if (_instance == null)
				_instance = new AlarmPreSnoozer();
				
			//Create objects
			createDisplayObjects();
			
			/* Display Callout */
			displayCallout();
		}
		
		private static function displayCallout():void
		{
			//Close the callout
			if (PopUpManager.isPopUp(snoozeCallout))
				PopUpManager.removePopUp(snoozeCallout);
			else if (snoozeCallout != null)
				snoozeCallout.close();
			
			//Display callout
			PopUpManager.addPopUp(snoozeCallout, true, false);
		}
		
		private static function createDisplayObjects():void
		{
			/* Main Container */
			if (mainContainer != null)
				mainContainer.removeChildren();
			
			var mainLayout:VerticalLayout = new VerticalLayout();
			mainLayout.horizontalAlign = HorizontalAlign.CENTER;
			mainLayout.gap = 15;
			
			if (mainContainer != null) mainContainer.dispose();
			mainContainer = new LayoutGroup();
			mainContainer.layout = mainLayout;
			
			/* Title */
			if (titleLabel != null) 
			{
				titleLabel.removeFromParent();
				titleLabel.dispose();
			}
			titleLabel = LayoutFactory.createSectionLabel(snoozeTitle, false, HorizontalAlign.CENTER);
			mainContainer.addChild(titleLabel);
			
			/* First Phase */
			createFirstPhase();
			
			/* Action Buttons */
			var actionButtonsLayout:HorizontalLayout = new HorizontalLayout();
			actionButtonsLayout.gap = 5;
			
			if (actionButtonsContainer != null)
			{
				actionButtonsContainer.removeFromParent();
				actionButtonsContainer.dispose();
			}
			actionButtonsContainer = new LayoutGroup();
			actionButtonsContainer.layout = actionButtonsLayout;
			mainContainer.addChild(actionButtonsContainer);
			
			//Cancel Button
			if (cancelButton != null)
			{
				cancelButton.removeFromParent();
				cancelButton.dispose();
			}
			cancelButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations',"cancel_button_label"));
			cancelButton.addEventListener(Event.TRIGGERED, onCancel);
			actionButtonsContainer.addChild(cancelButton);
			
			//Pre(Un)-snooze Buttons
			if (preSnoozeButton != null)
			{
				preSnoozeButton.removeFromParent();
				preSnoozeButton.dispose();
			}
			preSnoozeButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label"));
			preSnoozeButton.addEventListener(Event.TRIGGERED, snoozeAlarm);
			
			if (unSnoozeButton != null)
			{
				unSnoozeButton.removeFromParent();
				unSnoozeButton.dispose();
			}
			unSnoozeButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"unsnooze_button_label"));
			unSnoozeButton.addEventListener(Event.TRIGGERED, unSnoozeAlarm);
			
			if (snoozeStatusLabel != null)
			{
				snoozeStatusLabel.removeFromParent();
				snoozeStatusLabel.dispose();
			}
			snoozeStatusLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER);
			
			if (Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6 || Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
			{
				cancelButton.paddingLeft = cancelButton.paddingRight = 10;
				preSnoozeButton.paddingLeft = preSnoozeButton.paddingRight = 10;
				unSnoozeButton.paddingLeft = unSnoozeButton.paddingRight = 10;
			}
			
			/* Callout Position Helper Creation */
			calculatePositionHelper();
			
			/* Callout Creation */
			if (snoozeCallout != null)
			{
				snoozeCallout.removeFromParent();
				snoozeCallout.dispose();
			}
			snoozeCallout = new Callout();
			snoozeCallout.content = mainContainer;
			snoozeCallout.origin = positionHelper;
			snoozeCallout.minWidth = 240;
			if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				snoozeCallout.paddingLeft = snoozeCallout.paddingRight = 12;
		}
		
		private static function calculatePositionHelper():void
		{
			if (positionHelper == null)
			{
				positionHelper = new Sprite();
				Starling.current.stage.addChild(positionHelper);
			}
			
			positionHelper.x = Constants.stageWidth / 2;
			
			var yPos:Number = 0;
			if (!isNaN(Constants.headerHeight))
				yPos = Constants.headerHeight - 10;
			else
			{
				if (Constants.deviceModel != DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
					yPos = 68;
				else
					yPos = Constants.isPortrait ? 98 : 68;
			}
			
			positionHelper.y = yPos;
		}
		
		private static function createFirstPhase():void
		{
			/* Alarm Selector */
			var alarmTypesLabels:Array = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"pre_snoozer_alarm_list").split(",");
			var alarmTypesDataProvider:ArrayCollection = new ArrayCollection();
			var numAlarmTypesLabels:uint = alarmTypesLabels.length;
			for (var i:int = 0; i < numAlarmTypesLabels; i++) 
			{
				alarmTypesDataProvider.push( { label: StringUtil.trim(alarmTypesLabels[i]) } );
			}
			if (alarmTypesPicker != null)
			{
				alarmTypesPicker.removeFromParent();
				alarmTypesPicker.dispose();
			}
			alarmTypesPicker = LayoutFactory.createPickerList();
			alarmTypesPicker.prompt = ModelLocator.resourceManagerInstance.getString('globaltranslations',"picker_select");
			alarmTypesPicker.dataProvider = alarmTypesDataProvider;
			alarmTypesPicker.selectedIndex = -1;
			alarmTypesPicker.addEventListener(Event.CHANGE, onAlarmChosen);
			
			alarmTypesPicker.itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.paddingRight = 10;
				itemRenderer.paddingLeft = 10;
				return itemRenderer;
			}
			
			mainContainer.addChild(alarmTypesPicker);
		}
		
		private static function createSecondPhase():void
		{
			/* Snoozer Picker List */
			if (snoozePickerList != null)
			{
				snoozePickerList.removeFromParent();
				snoozePickerList.dispose();
			}
			snoozePickerList = LayoutFactory.createPickerList();
			dataProvider = new ArrayCollection();
			
			var numLabels:uint = snoozeLabels.length;
			for (var i:int = 0; i < numLabels; i++) 
			{
				dataProvider.push( { label: (snoozeLabels[i] as String).replace("minutes", ModelLocator.resourceManagerInstance.getString('alarmservice',"minutes")).replace("hours", ModelLocator.resourceManagerInstance.getString('alarmservice',"hours")).replace("hour", ModelLocator.resourceManagerInstance.getString('alarmservice',"hour")).replace("day", ModelLocator.resourceManagerInstance.getString('alarmservice',"day")).replace("week", ModelLocator.resourceManagerInstance.getString('alarmservice',"week")) } );
			}
			
			snoozePickerList.dataProvider = dataProvider;
			snoozePickerList.selectedIndex = selectedSnoozeIndex;
			mainContainer.addChildAt(snoozePickerList, 2);
		}
		
		public static function closeCallout():void
		{
			//Close the callout
			if (PopUpManager.isPopUp(snoozeCallout))
				PopUpManager.removePopUp(snoozeCallout);
			else if(snoozeCallout != null)
				snoozeCallout.close();
		}
		
		/**
		 * Event Listeners
		 */
		private static function onAlarmChosen(e:Event):void
		{
			var selectedAlarmIndex:int = alarmTypesPicker.selectedIndex;
			mainContainer.removeChild(snoozeStatusLabel);
			mainContainer.removeChild(snoozePickerList);
			
			if (selectedAlarmIndex == 0)
			{
				//All Alarm
				if (AlarmService.veryHighAlertSnoozed() ||
					AlarmService.highAlertSnoozed() ||
					AlarmService.lowAlertSnoozed() ||
					AlarmService.veryLowAlertSnoozed() ||
					AlarmService.missedReadingAlertSnoozed() ||
					AlarmService.phoneMutedAlertSnoozed() ||
					AlarmService.fastRiseAlertSnoozed() ||
					AlarmService.fastDropAlertSnoozed()
					)
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					preSnoozeButton.addEventListener(Event.TRIGGERED, snoozeAllAlarms);
					createSecondPhase();
					actionButtonsContainer.addChild(unSnoozeButton);
					unSnoozeButton.addEventListener(Event.TRIGGERED, unSnoozeAllAlarms);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					preSnoozeButton.addEventListener(Event.TRIGGERED, snoozeAllAlarms);
					createSecondPhase();
				}
			}
			else if (selectedAlarmIndex == 1)
			{
				//Fast Rise Alarm
				if (AlarmService.fastRiseAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.fastRiseAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeFastRiseAlert
					unSnoozeAction = AlarmService.resetFastRiseAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeFastRiseAlert
				}
			}
			else if (selectedAlarmIndex == 2)
			{
				//Urgent High Alarm
				if (AlarmService.veryHighAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.veryHighAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeVeryHighAlert
					unSnoozeAction = AlarmService.resetVeryHighAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeVeryHighAlert
				}
			}
			else if (selectedAlarmIndex == 3)
			{
				//High Alarm
				if (AlarmService.highAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.highAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeHighAlert;
					unSnoozeAction = AlarmService.resetHighAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeHighAlert;
				}
			}
			else if (selectedAlarmIndex == 4)
			{
				//Fast Drop
				if (AlarmService.fastDropAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.fastDropAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeFastDropAlert;
					unSnoozeAction = AlarmService.resetFastDropAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeFastDropAlert;
				}
			}
			else if (selectedAlarmIndex == 5)
			{
				//Low Alarm
				if (AlarmService.lowAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.lowAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeLowAlert;
					unSnoozeAction = AlarmService.resetLowAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeLowAlert;
				}
			}
			else if (selectedAlarmIndex == 6)
			{
				//Urgent Low Alarm
				if (AlarmService.veryLowAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.veryLowAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeVeyLowAlert;
					unSnoozeAction = AlarmService.resetVeryLowAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					preSnoozeButton.label = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"presnooze_button_label").toUpperCase();
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeVeyLowAlert;
				}
			}
			else if (selectedAlarmIndex == 7)
			{
				//Missed Readings
				if (AlarmService.missedReadingAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.missedReadingAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeMissedReadingAlert;
					unSnoozeAction = AlarmService.resetMissedReadingAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozeMissedReadingAlert;
				}
			}
			else if (selectedAlarmIndex == 8)
			{
				//Muted
				if (AlarmService.phoneMutedAlertSnoozed())
				{
					snoozeStatusLabel.text = ModelLocator.resourceManagerInstance.getString('alarmpresnoozer',"snoozed_for") + " " + AlarmService.phoneMutedAlertSnoozeAsString();
					mainContainer.addChildAt(snoozeStatusLabel, 2);
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozePhoneMutedAlert;
					unSnoozeAction = AlarmService.resetPhoneMutedAlert;
					actionButtonsContainer.addChild(unSnoozeButton);
				}
				else
				{
					actionButtonsContainer.addChild(preSnoozeButton);
					createSecondPhase();
					snoozeAction = AlarmService.snoozePhoneMutedAlert;
				}
			}
			
			snoozeCallout.invalidate();
			snoozeCallout.validate();
		}
		
		private static function snoozeAlarm(e:Event):void
		{
			if (snoozeAction != null)
			{
				snoozeAction.call(null, snoozePickerList.selectedIndex);
				snoozeAction = null;
				closeCallout();
			}
		}
		
		private static function snoozeAllAlarms(e:Event):void
		{
			AlarmService.snoozeVeryHighAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeHighAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeLowAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeVeyLowAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeMissedReadingAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozePhoneMutedAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeFastRiseAlert(snoozePickerList.selectedIndex);
			AlarmService.snoozeFastDropAlert(snoozePickerList.selectedIndex);
			
			closeCallout();
		}
		
		private static function unSnoozeAlarm(e:Event):void
		{
			if (unSnoozeAction != null)
			{
				unSnoozeAction.call();
				unSnoozeAction = null;
				closeCallout();
			}
		}
		
		private static function unSnoozeAllAlarms(e:Event):void
		{
			if (AlarmService.veryHighAlertSnoozed())
				AlarmService.resetVeryHighAlert();
			
			if (AlarmService.highAlertSnoozed())
				AlarmService.resetHighAlert();
				
			if (AlarmService.lowAlertSnoozed())
				AlarmService.resetLowAlert();
				
			if (AlarmService.veryLowAlertSnoozed())
				AlarmService.resetVeryLowAlert();
				
			if (AlarmService.missedReadingAlertSnoozed())
				AlarmService.resetMissedReadingAlert();
				
			if (AlarmService.phoneMutedAlertSnoozed())
				AlarmService.resetPhoneMutedAlert();
			
			if (AlarmService.fastRiseAlertSnoozed())
				AlarmService.resetFastRiseAlert();
			
			if (AlarmService.fastDropAlertSnoozed())
				AlarmService.resetFastDropAlert();
			
			closeCallout();
		}
		
		private static function onCancel(e:Event):void
		{
			closeCallout();
		}
		
		private static function onStarlingResize(event:ResizeEvent):void 
		{
			SystemUtil.executeWhenApplicationIsActive(calculatePositionHelper);
		}

		/**
		 * Getters & Setters
		 */
		public static function get instance():AlarmPreSnoozer
		{
			if (_instance == null)
				_instance = new AlarmPreSnoozer();
				
			return _instance;
		}
	}
}