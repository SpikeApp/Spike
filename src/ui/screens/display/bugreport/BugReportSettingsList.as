package ui.screens.display.bugreport
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import database.LocalSettings;
	
	import feathers.controls.Alert;
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.TextArea;
	import feathers.controls.TextInput;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.controls.text.HyperlinkTextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.ArrayCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import network.EmailSender;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	import starling.text.TextFormat;
	import starling.utils.SystemUtil;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DataValidator;
	import utils.DeviceInfo;
	import utils.TimeSpan;
	import utils.Trace;

	[ResourceBundle("bugreportsettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class BugReportSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var traceToggle:ToggleSwitch;
		private var nameField:TextInput;
		private var emailField:TextInput;
		private var messageField:TextArea;
		private var sendEmail:Button;
		private var warningTitleLabel:Label;
		private var warningDescriptionLabel:Label;
		
		/* Properties */
		private var isTraceEnabled:Boolean
		
		public function BugReportSettingsList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			setupProperties();
			setupInitialContent();
			setupContent();
			setupRenderFactory();
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
			/* Get data from database */
			isTraceEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED) == "true";
		}
		
		private function setupContent():void
		{
			//Calculate fields dimensions
			var fieldWidth:int;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				fieldWidth = 165;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_6_6S_7_8 || Constants.deviceModel == DeviceInfo.IPHONE_6PLUS_6SPLUS_7PLUS_8PLUS)
				fieldWidth = 200;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				fieldWidth = 155;
			else if (Constants.deviceModel == DeviceInfo.IPAD_1_2_3_4_5_AIR1_2_PRO_97)
				fieldWidth = 400;
			else if (Constants.deviceModel == DeviceInfo.IPAD_PRO_105)
				fieldWidth = 450;
			else if (Constants.deviceModel == DeviceInfo.IPAD_PRO_129)
				fieldWidth = 550;
			else if (Constants.deviceModel == DeviceInfo.IPAD_MINI_1_2_3_4)
				fieldWidth = 300;
			else
				fieldWidth = 200;
			
			if (!Constants.isPortrait)
				fieldWidth += 100;
			
			//On/Off Toggle
			traceToggle = LayoutFactory.createToggleSwitch(isTraceEnabled);
			traceToggle.pivotX = 6;
			traceToggle.addEventListener( starling.events.Event.CHANGE, onTraceOnOff );
			
			//Name Field
			nameField = LayoutFactory.createTextInput(false, false, fieldWidth, HorizontalAlign.RIGHT);
			nameField.addEventListener(FeathersEventType.ENTER, onKeyboardEnter);
			nameField.pivotX = 6;
			nameField.text = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_BUG_REPORT_NAME);
			
			//Email Field
			emailField = LayoutFactory.createTextInput(false, false, fieldWidth, HorizontalAlign.RIGHT, false, true);
			emailField.addEventListener(FeathersEventType.ENTER, onKeyboardEnter);
			emailField.pivotX = 6;
			emailField.text = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_BUG_REPORT_EMAIL);
			
			//Text Area
			messageField = new TextArea();
			messageField.addEventListener(FeathersEventType.ENTER, onKeyboardEnter);
			messageField.fontStyles = new TextFormat("Roboto", 14, 0xEEEEEE, HorizontalAlign.RIGHT, VerticalAlign.TOP);
			messageField.paddingTop = 3;
			messageField.pivotX = 6;
			messageField.width = fieldWidth;
			messageField.height = 150;
			
			//Send Email
			sendEmail = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_button_title'), false, MaterialDeepGreyAmberMobileThemeIcons.sendTexture);
			sendEmail.pivotX = 3;
			sendEmail.addEventListener(starling.events.Event.TRIGGERED, onSendEmail);
			
			//Warning Title Label
			warningTitleLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','warning_label'), HorizontalAlign.CENTER, VerticalAlign.TOP, 17, true);
			warningTitleLabel.width = width;
			
			//Instructions Description Label
			warningDescriptionLabel = new Label();
			warningDescriptionLabel.text = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','warning_description');
			warningDescriptionLabel.width = width;
			warningDescriptionLabel.wordWrap = true;
			warningDescriptionLabel.paddingTop = 10;
			warningDescriptionLabel.isQuickHitAreaEnabled = false;
			warningDescriptionLabel.textRendererFactory = function():ITextRenderer 
			{
				var textRenderer:HyperlinkTextFieldTextRenderer = new HyperlinkTextFieldTextRenderer();
				textRenderer.wordWrap = true;
				textRenderer.isHTML = true;
				textRenderer.pixelSnapping = true;
				
				return textRenderer;
			};
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.paddingBottom = itemRenderer.paddingTop = 10;
				itemRenderer.paddingRight = 0;
				itemRenderer.labelFunction = function( item:Object ):String
				{
					if (item.label == ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','message_label'))
						itemRenderer.verticalAlign = VerticalAlign.TOP;
					
					return item.label;
				};
				
				return itemRenderer;
			};
			
			(layout as VerticalLayout).hasVariableItemDimensions = true;
			
			//Define Trace Settings Data
			reloadTraceSettings(isTraceEnabled);
		}
		
		private function reloadTraceSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: traceToggle },
						{ label: ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','name_label'), accessory: nameField },
						{ label: ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_label'), accessory: emailField },
						{ label: ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','message_label'), accessory: messageField },
						{ label: "", accessory: sendEmail },
						{ label: "", accessory: warningTitleLabel },
						{ label: "", accessory: warningDescriptionLabel }
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','enabled_label'), accessory: traceToggle },
						{ label: "", accessory: warningTitleLabel },
						{ label: "", accessory: warningDescriptionLabel }
					]);
			}
		}
		
		private function resetLogFile():void
		{
			var fileName:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_NAME);
			if (fileName != "")
			{
				var file:File = File.applicationStorageDirectory.resolvePath(fileName);
				if (file.exists)
					file.deleteFileAsync();
			}
			SpikeANE.resetTraceFilePath();
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_NAME, "");
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_PATH_NAME, "");
		}
		
		/**
		 * Event Handlers
		 */
		private function onTraceOnOff(event:starling.events.Event):void
		{	
			isTraceEnabled = traceToggle.isSelected;
			
			var valueToSave:String;
			if(isTraceEnabled) valueToSave = "true";
			else valueToSave = "false";
			
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED, valueToSave);
			//LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_NSLOG, valueToSave);
			
			reloadTraceSettings(isTraceEnabled);
			
			if (!isTraceEnabled)
			{
				resetLogFile();
				messageField.text = "";
			}
		}
		
		private function onSendEmail():void
		{
			//Validation
			if (!NetworkInfo.networkInfo.isReachable())
			{
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','no_network_connection')
					);
				
				return;
			}
			else if (nameField.text == "")
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','name_required')
				);
				
				return;
			}
			else if (emailField.text == "")
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_required')
				);
				
				return;
			}
			else if (!DataValidator.validateEmail(emailField.text))
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_invalid')
				);
				
				return;
			}
			else if (messageField.text == "" || messageField.text == " ")
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','message_required')
				);
				
				return;
			}
			
			//Store name and email, they will be used to prefill the fields next time
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_BUG_REPORT_EMAIL, emailField.text);
			LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_BUG_REPORT_NAME, nameField.text);
			
			//Temporarly disable send button
			sendEmail.label = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','stand_by_button_label');
			sendEmail.isEnabled = false;
			
			//Get the trace log
			var fileName:String = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_TRACE_FILE_NAME);
			if (fileName != "")
			{
				var file:File = File.applicationStorageDirectory.resolvePath(fileName);
				if (file.exists && file.size > 0)
				{
					//Check if log is at least 15min old
					var traceLogAgeInMinutes:Number = TimeSpan.fromDates(file.creationDate, new Date()).totalMinutes;
					
					if (traceLogAgeInMinutes >= 15)
					{
						Trace.myTrace("BugReportSettingsList.as", "Sending log!");
						
						//Get the trace log
						var fileStream:FileStream = new FileStream();
						fileStream.open(file, FileMode.READ);
						
						//Read trace log raw bytes into memory
						var fileData:ByteArray = new ByteArray();
						fileStream.readBytes(fileData);
						fileStream.close();
						
						//Create URL Request Address
						var emailBody:String = "";
						emailBody += "<p><b>Name:</b> " + nameField.text + "</br>";
						emailBody += "<b>Email:</b> " + emailField.text + "</br>";
						emailBody += "<b>Message:</b> " + messageField.text + "</p>";
						
						var vars:URLVariables = new URLVariables();
						vars.fileName = fileName;
						vars.mimeType = "text/plain";
						vars.emailSubject = "Bug Report by " + nameField.text;
						vars.emailBody = emailBody;
						vars.userEmail = emailField.text;
						vars.mode = EmailSender.MODE_EMAIL_SUPPORT;
						
						//Send data
						EmailSender.sendData
						(
							EmailSender.TRANSMISSION_URL_WITH_ATTACHMENT,
							onLoadCompleteHandler,
							vars,
							fileData
						);
						
						//Reset trace log state
						resetLogFile();
					}
					else
					{
						var message:String = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','trace_file_too_recent_prefix') + " ";
						if (Math.floor(traceLogAgeInMinutes) == 1)
							message += Math.floor(traceLogAgeInMinutes) + " " + ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','minute');
						else
							message += Math.floor(traceLogAgeInMinutes) + " " + ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','minutes');
						message += "\n\n";
						message += ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','trace_file_too_recent_suffix')
						
						var alert:Alert = AlertManager.showSimpleAlert
						(
							ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
							message
						);
						alert.height = 330;
						
						//Enable send button
						sendEmail.label = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_button_title');
						sendEmail.isEnabled = true;
					}
				}
				else
				{
					AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
						ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','trace_file_non_existent')
					);
					
					//Enable send button
					sendEmail.label = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_button_title');
					sendEmail.isEnabled = true;
				}
			}
			else
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
					ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','trace_file_non_existent')
				);
				
				//Enable send button
				sendEmail.label = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_button_title');
				sendEmail.isEnabled = true;
			}
		}
		
		private function onLoadCompleteHandler(event:flash.events.Event):void 
		{ 
			var loader:URLLoader = URLLoader(event.target);
			if (loader == null || loader.data == null)
				return;
			
			var response:Object = loader.data;
			
			loader.removeEventListener(flash.events.Event.COMPLETE, onLoadCompleteHandler);
			loader = null;
			
			if (sendEmail == null)
				return;
			
			if (response.success != null && response.success == "true")
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','success_alert_title'),
					ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','bug_report_sent_successfully'),
					Number.NaN,
					null,
					HorizontalAlign.CENTER
				);
				
				//Update internal variables and controls
				isTraceEnabled = false;
				traceToggle.isSelected = false;
			}
			else
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','error_alert_title'),
					ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','bug_report_error') + " " + response.statuscode
				);
			}
			
			//Enable send button
			sendEmail.label = ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','email_button_title');
			sendEmail.isEnabled = true;
		} 
		
		private function onKeyboardEnter(e:starling.events.Event):void
		{
			nameField.clearFocus();
			emailField.clearFocus();
			messageField.clearFocus();
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			SystemUtil.executeWhenApplicationIsActive( setupContent );
			SystemUtil.executeWhenApplicationIsActive( setupRenderFactory );
		}
		
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				itemRenderer.accessoryLabelProperties.wordWrap = true;
				itemRenderer.defaultLabelProperties.wordWrap = true;
				itemRenderer.paddingBottom = itemRenderer.paddingTop = 10;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						itemRenderer.paddingLeft = 30;
						if (warningDescriptionLabel != null)warningDescriptionLabel.width = width - 40;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
					{
						itemRenderer.paddingRight = 30;
						if (warningDescriptionLabel != null) warningDescriptionLabel.width = width - 30;
					}
				}
				else
				{
					itemRenderer.paddingRight = 0;
					if (warningDescriptionLabel != null) warningDescriptionLabel.width = width;
				}
				
				itemRenderer.labelFunction = function( item:Object ):String
				{
					if (item.label == ModelLocator.resourceManagerInstance.getString('bugreportsettingsscreen','message_label'))
						itemRenderer.verticalAlign = VerticalAlign.TOP;
					
					return item.label;
				};
				
				return itemRenderer;
			};
		}
		
		/**
		 * Utilty
		 */
		
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if(traceToggle != null)
			{
				traceToggle.removeEventListener( starling.events.Event.CHANGE, onTraceOnOff );
				traceToggle.dispose();
				traceToggle = null;
			}
			
			if (nameField != null)
			{
				nameField.removeEventListener(FeathersEventType.ENTER, onKeyboardEnter);
				nameField.dispose();
				nameField = null;
			}
			
			if (emailField != null)
			{
				emailField.removeEventListener(FeathersEventType.ENTER, onKeyboardEnter);
				emailField.dispose();
				emailField = null;
			}
			
			if (messageField != null)
			{
				messageField.removeEventListener(FeathersEventType.ENTER, onKeyboardEnter);
				messageField.dispose();
				messageField = null;
			}
			
			if(sendEmail != null)
			{
				sendEmail.removeEventListener(starling.events.Event.TRIGGERED, onSendEmail);
				sendEmail.dispose();
				sendEmail = null;
			}
			
			if (warningTitleLabel != null)
			{
				warningTitleLabel.dispose();
				warningTitleLabel = null;
			}
			
			if (warningDescriptionLabel != null)
			{
				warningDescriptionLabel.dispose();
				warningDescriptionLabel = null;
			}
			
			super.dispose();
		}
	}
}