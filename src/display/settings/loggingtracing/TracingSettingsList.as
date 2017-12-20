package display.settings.loggingtracing
{
	import flash.system.System;
	
	import Utilities.Trace;
	
	import databaseclasses.LocalSettings;
	
	import display.LayoutFactory;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	
	import utils.Constants;

	[ResourceBundle("logtracesettingsscreen")]
	
	public class TracingSettingsList extends List 
	{
		/* Display Objects */
		private var traceToggle:ToggleSwitch;
		private var sendEmail:Button;
		
		/* Properties */
		public var needsSave:Boolean = false;
		private var isTraceEnabled:Boolean;
		
		public function TracingSettingsList()
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
			/* Get data from database */
			isTraceEnabled = LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED) == "true";
		}
		
		private function setupContent():void
		{
			//On/Off Toggle
			traceToggle = LayoutFactory.createToggleSwitch(isTraceEnabled);
			traceToggle.addEventListener( Event.CHANGE, onTraceOnOff );
			
			//Send Email
			sendEmail = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','email_button_title'), false, MaterialDeepGreyAmberMobileThemeIcons.sendTexture);
			sendEmail.addEventListener(Event.TRIGGERED, onSendEmail);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Define Trace Settings Data
			reloadTraceSettings(isTraceEnabled);
		}
		
		private function reloadTraceSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','enabled_label'), accessory: traceToggle },
						{ label: "", accessory: sendEmail },
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: ModelLocator.resourceManagerInstance.getString('logtracesettingsscreen','enabled_label'), accessory: traceToggle },
					]);
			}
		}
		
		public function save():void
		{
			var valueToSave:String;
			if(isTraceEnabled) valueToSave = "true";
			else valueToSave = "false";
			
			if (LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED) != valueToSave)
				LocalSettings.setLocalSetting(LocalSettings.LOCAL_SETTING_DETAILED_TRACING_ENABLED, valueToSave);
			
			needsSave = false;
		}
		
		/**
		 * Event Handlers
		 */
		private function onTraceOnOff(event:Event):void
		{
			isTraceEnabled = traceToggle.isSelected;
			
			needsSave = true;
			
			reloadTraceSettings(isTraceEnabled);
		}
		
		private function onSendEmail():void
		{
			//Update internal variables and controls
			isTraceEnabled = false;
			traceToggle.isSelected = false;
			
			//Disable Tracing
			save();
			
			//Send trace file
			Trace.sendTraceFile();
		}
		
		/**
		 * Utilty
		 */
		override public function dispose():void
		{
			if(traceToggle != null)
			{
				traceToggle.dispose();
				traceToggle = null;
			}
			if(sendEmail != null)
			{
				sendEmail.dispose();
				sendEmail = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}