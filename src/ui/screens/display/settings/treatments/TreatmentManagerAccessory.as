package ui.screens.display.settings.treatments
{
	import feathers.controls.Button;
	import feathers.controls.LayoutGroup;
	import feathers.layout.HorizontalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import utils.Constants;
	import utils.DeviceInfo;
	
	public class TreatmentManagerAccessory extends Sprite
	{	
		/* Constants */
		public static const DELETE:String = "delete";
		public static const EDIT:String = "edit";
		
		/* Display Objects */
		private var renderer:LayoutGroup;
		private var deleteButton:Button;
		private var deleteButtonTexture:Texture;
		private var deleteButtonIcon:Image;
		private var editButton:Button;
		private var editButtonTexture:Texture;
		private var editButtonIcon:Image;
		
		public function TreatmentManagerAccessory()
		{
			super();
			
			setupContent();
		}
		
		private function setupContent():void
		{
			/* Layout Container */
			var rendererLayout:HorizontalLayout = new HorizontalLayout();
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				rendererLayout.gap = -15;
			else
				rendererLayout.gap = -8;
			
			renderer = new LayoutGroup();
			renderer.layout = rendererLayout;
			addChild(renderer);
			
			/* Buttons */
			deleteButton = new Button();
			deleteButtonTexture = MaterialDeepGreyAmberMobileThemeIcons.deleteForeverTexture;
			deleteButtonIcon = new Image(deleteButtonTexture);
			deleteButton.defaultIcon = deleteButtonIcon;
			deleteButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			deleteButton.addEventListener(Event.TRIGGERED, onDelete);
			deleteButton.validate();
			renderer.addChild(deleteButton);
			
			editButton = new Button();
			editButtonTexture = MaterialDeepGreyAmberMobileThemeIcons.editTexture;
			editButtonIcon = new Image(editButtonTexture);
			editButton.defaultIcon = editButtonIcon;
			editButton.styleNameList.add( BaseMaterialDeepGreyAmberMobileTheme.THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY );
			editButton.addEventListener(Event.TRIGGERED, onEdit);
			editButton.validate();
			renderer.addChild(editButton);
			
			/* Validate Layout */
			renderer.validate();
		}
		
		/**
		 * Event Listeners
		 */
		private function onDelete(e:Event):void
		{
			dispatchEventWith(DELETE);
		}
		
		private function onEdit(e:Event):void
		{
			dispatchEventWith(EDIT);
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			if (editButton != null)
			{
				editButtonTexture.dispose();
				editButtonTexture = null;
				if (editButtonIcon.texture != null)
					editButtonIcon.texture.dispose();
				editButtonIcon.dispose();
				editButtonIcon = null;
				editButton.removeEventListener(Event.TRIGGERED, onEdit);
				editButton.dispose();
				editButton = null;
			}
			
			if (deleteButton != null)
			{
				deleteButtonTexture.dispose();
				deleteButtonTexture = null;
				if (deleteButtonIcon.texture != null)
					deleteButtonIcon.texture.dispose();
				deleteButtonIcon.dispose();
				deleteButtonIcon = null;
				deleteButton.removeEventListener(Event.TRIGGERED, onDelete);
				deleteButton.dispose();
				deleteButton = null;
			}
			
			if (renderer != null)
			{
				renderer.dispose();
				renderer = null;
			}
			
			super.dispose();
		}
	}
}