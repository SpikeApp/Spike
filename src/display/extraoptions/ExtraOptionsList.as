package display.extraoptions
{
	import flash.system.System;
	
	import events.ScreenEvent;
	
	import feathers.controls.List;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.AnchorLayoutData;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import screens.Screens;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import ui.AppInterface;

	public class ExtraOptionsList extends List 
	{
		public static const CLOSE:String = "close";
		
		/* Display Objects */
		private var fullScreenIconTexture:Texture;
		private var fullScreenIconImage:Image;
		private var speechDisabledIconTexture:Texture;
		private var speechEnabledIconTexture:Texture;
		private var speechIconImage:Image;
		
		/* Properties */
		private var speechEnabled:Boolean;
		
		public function ExtraOptionsList()
		{
			super();
		}
		override protected function initialize():void 
		{
			super.initialize();
			
			speechEnabled = false;
			
			clipContent = false;
			isSelectable = true;
			autoHideBackground = true;
			hasElasticEdges = false;
			
			fullScreenIconTexture = MaterialDeepGreyAmberMobileThemeIcons.fullscreenTexture;
			fullScreenIconImage = new Image(fullScreenIconTexture);
			
			if(!speechEnabled)
			{
				speechDisabledIconTexture = MaterialDeepGreyAmberMobileThemeIcons.phoneSpeakerTexture;
				speechIconImage = new Image(speechDisabledIconTexture);
			}
			else
			{
				speechEnabledIconTexture = MaterialDeepGreyAmberMobileThemeIcons.phoneSpeakerEnabledTexture;
				speechIconImage = new Image(speechEnabledIconTexture);
			}
			
			buildListLayout();
			
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.iconField = "icon";
				item.gap = 5;
				item.paddingLeft = 8;
				item.paddingRight = 14;
				item.isQuickHitAreaEnabled = true;
				return item;
			};
			layoutData = new AnchorLayoutData( 0, 0, 0, 0 );
			addEventListener( Event.CHANGE, onMenuChanged );
		}
		
		private function buildListLayout():void
		{
			dataProvider = new ListCollection(
				[
					{ label: "Fullscreen", icon: fullScreenIconImage, id: 1 },
					{ label: "Speech", icon: speechIconImage, id: 2 }
				]);
		}
		
		private function onMenuChanged(e:Event):void 
		{
			if(selectedItem != null)
			{
				const treatmentID:Number = selectedItem.id as Number;
				
				if ( treatmentID == 1 ) //FullScreen
				{
					dispatchEventWith(CLOSE); //Close Menu
					
					AppInterface.instance.navigator.pushScreen( Screens.FULLSCREEN_GLUCOSE ); //Push Fullscreen Glucose Screen
				}
				else if ( treatmentID == 2 ) //Speech
				{
					if (!speechEnabled)
					{
						speechEnabled = true;
						if(speechDisabledIconTexture != null)
						{
							speechDisabledIconTexture.dispose();
							speechDisabledIconTexture = null;
						}
						speechEnabledIconTexture = MaterialDeepGreyAmberMobileThemeIcons.phoneSpeakerEnabledTexture;
						speechIconImage = new Image(speechEnabledIconTexture);
					}
					else if (speechEnabled)
					{
						speechEnabled = false;
						if(speechEnabledIconTexture != null)
						{
							speechEnabledIconTexture.dispose();
							speechEnabledIconTexture = null;
						}
						speechDisabledIconTexture = MaterialDeepGreyAmberMobileThemeIcons.phoneSpeakerTexture;
						speechIconImage = new Image(speechDisabledIconTexture);
					}
					buildListLayout();
				}
			}
		}
		
		private function onEnterCalibration(event:Event):void
		{
			//TODO: Apply calibration
			//trace("Calibration Value:", calibrationValue.text);
		}
		
		override public function dispose():void
		{
			if (fullScreenIconTexture != null)
			{
				fullScreenIconTexture.dispose();
				fullScreenIconTexture = null;
			}
			
			if (fullScreenIconImage != null)
			{
				fullScreenIconImage.dispose();
				fullScreenIconImage = null;
			}
			
			if (speechDisabledIconTexture != null)
			{
				speechDisabledIconTexture.dispose();
				speechDisabledIconTexture = null;
			}
			
			if (speechEnabledIconTexture != null)
			{
				speechEnabledIconTexture.dispose();
				speechEnabledIconTexture = null;
			}
			
			if (speechIconImage != null)
			{
				speechIconImage.dispose();
				speechIconImage = null;
			}
			
			System.pauseForGCIfCollectionImminent(0);
			
			super.dispose();
		}
	}
}