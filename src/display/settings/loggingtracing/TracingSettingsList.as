package display.settings.loggingtracing
{
	import flash.system.System;
	
	import display.LayoutFactory;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.controls.ToggleSwitch;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.events.Event;
	
	import utils.Constants;

	public class TracingSettingsList extends List 
	{
		/* Display Objects */
		private var traceToggle:ToggleSwitch;
		private var sendEmail:Button;
		
		public function TracingSettingsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			//Set Properties
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			paddingBottom = 5;
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			//On/Off Toggle
			traceToggle = LayoutFactory.createToggleSwitch(false);
			traceToggle.addEventListener( Event.CHANGE, onTraceOnOff );
			
			//Send Email
			sendEmail = LayoutFactory.createButton("E-mail Trace File", false, MaterialDeepGreyAmberMobileThemeIcons.sendTexture);
			
			//Set Item Renderer
			itemRendererFactory = function():IListItemRenderer
			{
				var itemRenderer:DefaultListItemRenderer = new DefaultListItemRenderer();
				itemRenderer.labelField = "label";
				itemRenderer.accessoryField = "accessory";
				return itemRenderer;
			};
			
			//Define Trace Settings Data
			reloadTraceSettings(traceToggle.isSelected);
		}
		
		private function onTraceOnOff(event:Event):void
		{
			var toggle:ToggleSwitch = ToggleSwitch( event.currentTarget );
			
			if(toggle.isSelected)
				reloadTraceSettings(true);
			else
				reloadTraceSettings(false);
		}
		
		private function reloadTraceSettings(fullDisplay:Boolean):void
		{
			if(fullDisplay)
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: traceToggle },
						{ label: "", accessory: sendEmail },
					]);
			}
			else
			{
				dataProvider = new ArrayCollection(
					[
						{ label: "Enabled", accessory: traceToggle },
					]);
			}
		}
		
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