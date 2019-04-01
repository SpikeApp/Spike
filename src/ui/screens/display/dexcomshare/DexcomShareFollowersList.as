package ui.screens.display.dexcomshare
{
	import com.distriqt.extension.networkinfo.NetworkInfo;
	
	import events.DexcomShareEvent;
	
	import feathers.controls.Button;
	import feathers.controls.Callout;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.List;
	import feathers.controls.ScrollContainer;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.core.PopUpManager;
	import feathers.data.ListCollection;
	import feathers.extensions.MaterialDesignSpinner;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.themes.MaterialDeepGreyAmberMobileThemeIcons;
	
	import model.ModelLocator;
	
	import services.DexcomShareService;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import ui.screens.display.LayoutFactory;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.SpikeJSON;
	import utils.Trace;
	
	[ResourceBundle("sharesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class DexcomShareFollowersList extends List
	{
		/* Constants */
		private static const MAX_RETRIES:uint = 3;
		
		/* Display Objects */
		private var addFollower:Button;
		private var preloader:MaterialDesignSpinner;
		private var actionsContainer:LayoutGroup;
		private var cancel:Button;
		private var positionHelper:Sprite;
		private var newFollowerCreatorCallout:Callout;
		private var errorLabel:Label;
		private var followerCreator:DexcomShareFollowerCreator;
		private var followerCreatorContainer:ScrollContainer;
		private var followerEditor:DexcomShareFollowerEditor;
		private var followerEditorContainer:ScrollContainer;
		private var editFollowerCallout:Callout;
		
		/* Objects */
		private var followersList:Array;
		private var followerManagmentAccessoriesList:Array = [];
		private var followersPropertiesList:Array = [];

		/* Logical variables */
		private var retryCount:int = 0;
		private var errorMessage:String;
		private var displayFollowers:Boolean = false;
		private var deletedContactID:String = "";

		public function DexcomShareFollowersList()
		{
			super();
		}
		
		override protected function initialize():void 
		{
			super.initialize();
			
			Starling.current.stage.addEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			setupProperties();
			setupPreloader();
			Starling.juggler.delayCall(setupInitialContent, 1.5);
		}
		
		/**
		 * Functionality
		 */
		private function setupProperties():void
		{
			/* List Properties */
			clipContent = false;
			isSelectable = false;
			autoHideBackground = true;
			hasElasticEdges = false;
			if (Constants.deviceModel == DeviceInfo.IPHONE_2G_3G_3GS_4_4S_ITOUCH_2_3_4 || Constants.deviceModel == DeviceInfo.IPHONE_5_5S_5C_SE_ITOUCH_5_6)
				width = 250;
			else if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr)
				width = 240;
			else
				width = 300;
				
			height = 300;
		}
		
		private function setupPreloader():void
		{
			preloader = new MaterialDesignSpinner();
			preloader.color = 0x0086FF;
			preloader.validate();
			preloader.x = (width - preloader.width) / 2;
			preloader.y = (height - preloader.height) / 2;
			addChild(preloader);
		}
		
		private function setupInitialContent():void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_no_internet_connection');
				displayFollowers = false;
				setupContent();
				return;
			}
			
			DexcomShareService.instance.addEventListener(DexcomShareEvent.LIST_FOLLOWERS, onFollowersListReceived, false, 0, true);
			DexcomShareService.getFollowers();
		}
		
		private function onFollowersListReceived(e:DexcomShareEvent):void
		{
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.LIST_FOLLOWERS, onFollowersListReceived);
			
			if (e.data == null)
			{
				Trace.myTrace("DexcomShareFollowerList.as", "Error in retrieving follower's list. Server unavailable!");
				displayFollowers = false;
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_dexcom_server_unavailable');
				setupContent();
				return;
			}
			
			var response:String = String(e.data);
			
			followersList = parseDexcomResponse(response) as Array;
			
			if (response == "[]" || response.indexOf("ContactId") != -1)
			{
				Trace.myTrace("DexcomShareFollowerList.as", "Follower's list retrrieved successfully!");
				
				followersList = followersList.sortOn(["ContactName"], Array.CASEINSENSITIVE);
				
				displayFollowers = true;
				errorMessage = null;
				setupContent();
			}
			else
			{
				if (retryCount < MAX_RETRIES)
				{
					Trace.myTrace("DexcomShareFollowerList.as", "Error in retrieving follower's list. Retrying!");
					retryCount ++;
					setupInitialContent();
				}
				else
				{
					Trace.myTrace("DexcomShareFollowerList.as", "Can't retrieve followers list. Aborting!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknow_error_retrieving_followers_list');
					displayFollowers = false;
					setupContent();
				}
			}
		}
		
		private function setupContent():void
		{
			//Remove preloader
			disposePreloader();
			
			//Action Container
			var actionsContainerLayout:HorizontalLayout = new HorizontalLayout();
			actionsContainerLayout.gap = 5;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsContainerLayout;
			
			//Cancel button
			cancel = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.cancelTexture);
			cancel.addEventListener(Event.TRIGGERED, onCancel);
			actionsContainer.addChild(cancel);
			
			//Add follower buttons
			addFollower = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label'), false, MaterialDeepGreyAmberMobileThemeIcons.personAddTexture);
			addFollower.addEventListener(Event.TRIGGERED, onAddFollower);
			if (errorMessage == null)
				actionsContainer.addChild(addFollower);

			/* List Content */
			var listData:ListCollection = new ListCollection();
			if (displayFollowers)
			{
				var numFollowers:int = followersList.length;
				for (var i:int = 0; i < numFollowers; i++) 
				{
					var follower:Object = followersList[i];
					
					var followerManager:DexcomFollowerManagerAccessory = new DexcomFollowerManagerAccessory();
					followerManager.addEventListener(DexcomFollowerManagerAccessory.DELETE, onDeleteFollower);
					followerManager.addEventListener(DexcomFollowerManagerAccessory.EDIT, onEditFollower);
					followerManager.pivotX = -10;
					followerManagmentAccessoriesList.push(followerManager);
					
					var contactName:String = follower.ContactName;
					
					listData.push( { label: contactName, accessory: followerManager, data: follower } );
					
					followersPropertiesList.push( { contactName: contactName, contactID: follower.ContactId } );
				}
			}
			
			if (errorMessage != null)
			{
				errorLabel = LayoutFactory.createLabel(errorMessage, HorizontalAlign.CENTER, VerticalAlign.TOP, 14, false, 0xFF0000);
				errorLabel.width = width - 20;
				errorLabel.wordWrap = true;
				listData.push( { label: "", accessory: errorLabel } );
				errorMessage = null;
			}
			
			listData.push( { label: "", accessory: actionsContainer } );
			
			//Set list content
			dataProvider = listData;
			
			//List Renderer
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				
				return item;
			};
		}
		
		/**
		 * Event Listeners
		 */
		private function onCancel(e:Event):void
		{
			dispatchEventWith(Event.CANCEL);
		}
		
		private function onAddFollower(e:Event):void
		{
			//Position Helper
			setupCalloutPosition();
			
			//Create follower creator
			followerCreator = new DexcomShareFollowerCreator(followersPropertiesList);
			followerCreator.addEventListener(Event.COMPLETE, onCloseFollowerCreator);
			followerCreatorContainer = new ScrollContainer();
			followerCreatorContainer.addChild(followerCreator);
			
			//Create and display callout
			newFollowerCreatorCallout = new Callout();
			newFollowerCreatorCallout.content = followerCreatorContainer;
			newFollowerCreatorCallout.origin = positionHelper;
			PopUpManager.addPopUp(newFollowerCreatorCallout, true, false);
		}
		
		private function onCloseFollowerCreator(e:Event):void
		{
			newFollowerCreatorCallout.close(true);
			
			if (e.data != null && e.data.success == true)
			{
				displayFollowers = true;
				setupInitialContent();
			}
		}
		
		private function onDeleteFollower(e:Event):void
		{
			if (!NetworkInfo.networkInfo.isReachable())
			{
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_no_internet_connection');
				displayFollowers = true;
				setupContent();
				return;
			}
			
			var follower:Object = (((e.currentTarget as DexcomFollowerManagerAccessory).parent as DefaultListItemRenderer).data as Object).data as Object;
			var contactID:String = follower.ContactId;
			deletedContactID = follower.ContactId;
			
			DexcomShareService.instance.addEventListener(DexcomShareEvent.DELETE_FOLLOWER, onDeleteFollowerResponse);
			DexcomShareService.deleteFollower(contactID);
		}
		
		private function onDeleteFollowerResponse (e:DexcomShareEvent):void
		{
			DexcomShareService.instance.removeEventListener(DexcomShareEvent.DELETE_FOLLOWER, onDeleteFollowerResponse);
			
			if (e.data == null)
			{
				Trace.myTrace("DexcomShareFollowerList.as", "Can't delete follower! Server unreachable.");
				errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_server_unreachable_deleting_follower');
				displayFollowers = true;
				setupContent();
				return;
			}
			
			var response:String = String(e.data);
			if (response == "")
			{
				Trace.myTrace("DexcomShareFollowerList.as", "Successfully deleted follower!");
				errorMessage = null;
				displayFollowers = true;
				
				//CleanUp
				for (var i:int = 0; i < followersPropertiesList.length; i++) 
				{
					if (followersPropertiesList[i].contactID == deletedContactID)
					{
						followersPropertiesList.removeAt(i);
						deletedContactID = "";
						break;
					}
				}
				
				setupInitialContent();
			}
			else
			{
				if (response.indexOf("Code") != -1)
				{
					var responseInfo:Object = parseDexcomResponse(response);
					Trace.myTrace("DexcomShareFollowerList.as", "Error deleting follower. Error: " + responseInfo.Message);
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_error_deleting_followers') + " " + responseInfo.Message;
				}
				else
				{
					Trace.myTrace("DexcomShareFollowerList.as", "Unknown error while deleting follower!");
					errorMessage = ModelLocator.resourceManagerInstance.getString('sharesettingsscreen','error_message_unknow_error_deleting_followers');
				}
				displayFollowers = true;
				setupContent();
			}
		}
		
		private function onEditFollower(e:Event):void
		{
			var followerInfo:Object = (((e.currentTarget as DexcomFollowerManagerAccessory).parent as DefaultListItemRenderer).data as Object).data as Object;
			
			//Position Helper
			setupCalloutPosition();
			
			//Create follower creator
			followerEditor = new DexcomShareFollowerEditor(followerInfo);
			followerEditor.addEventListener(Event.COMPLETE, onCloseFollowerEditor);
			followerEditorContainer = new ScrollContainer();
			followerEditorContainer.addChild(followerEditor);
			
			//Create and display callout
			editFollowerCallout = new Callout();
			editFollowerCallout.content = followerEditorContainer;
			editFollowerCallout.origin = positionHelper;
			PopUpManager.addPopUp(editFollowerCallout, true, false);
		}
		
		private function onCloseFollowerEditor(e:Event):void
		{
			editFollowerCallout.close(true);
			
			if (e.data != null && e.data.success == true)
			{
				displayFollowers = true;
				setupInitialContent();
			}
		}
		
		/**
		 * Helpers
		 */
		private function disposePreloader():void
		{
			if (preloader != null)
			{
				removeChild(preloader);
				preloader.dispose();
				preloader = null;
			}
		}
		
		private function setupCalloutPosition():void
		{
			positionHelper = new Sprite();
			positionHelper.x = this.width / 2;
			positionHelper.y = -35;
			addChild(positionHelper);
		}
		
		private static function parseDexcomResponse(response:String):Object
		{
			var responseInfo:Object;
			
			try
			{
				//responseInfo = JSON.parse(response);
				responseInfo = SpikeJSON.parse(response);
			} 
			catch(error:Error) 
			{
				Trace.myTrace("DexcomShareFollowerList.as", "Can't parse server response! Error: " + error.message);
			}
			
			return responseInfo;
		}
		
		private function onStarlingResize(event:ResizeEvent):void 
		{
			if (positionHelper != null)
				positionHelper.x = this.width / 2;
			
			if (errorLabel != null)
				errorLabel.width = width - 20;
		}
		
		/**
		 * Utility
		 */
		override public function dispose():void
		{
			Starling.current.stage.removeEventListener(starling.events.Event.RESIZE, onStarlingResize);
			
			if (followerManagmentAccessoriesList != null && followerManagmentAccessoriesList.length > 0)
			{
				var loopLength:uint = followerManagmentAccessoriesList.length;
				for (var i:int = 0; i < loopLength; i++) 
				{
					var accessory:DexcomFollowerManagerAccessory = followerManagmentAccessoriesList[i] as DexcomFollowerManagerAccessory;
					accessory.dispose();
					accessory = null;
				}	
			}
			
			if (addFollower != null)
			{
				actionsContainer.removeChild(addFollower);
				addFollower.removeEventListener(Event.TRIGGERED, onAddFollower);
				addFollower.dispose();
				addFollower = null;
			}
			
			if (cancel != null)
			{
				actionsContainer.removeChild(cancel);
				cancel.removeEventListener(Event.TRIGGERED, onCancel);
				cancel.dispose();
				cancel = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (preloader != null)
			{
				preloader.dispose();
				preloader = null;
			}
			
			if (positionHelper != null)
			{
				Starling.current.stage.removeChild(positionHelper);
				positionHelper.dispose();
				positionHelper = null;
			}
			
			if (newFollowerCreatorCallout != null)
			{
				newFollowerCreatorCallout.dispose();
				newFollowerCreatorCallout = null;
			}
			
			if (errorLabel != null)
			{
				errorLabel.dispose();
				errorLabel = null;
			}
			
			if (followerCreator != null)
			{
				followerCreatorContainer.removeChild(followerCreator);
				followerCreator.dispose();
				followerCreator = null;
			}
			
			if (followerCreatorContainer != null)
			{
				followerCreatorContainer.dispose();
				followerCreatorContainer = null;
			}
			
			if (followerEditor != null)
			{
				followerEditorContainer.removeChild(followerEditor);
				followerEditor.removeEventListener(Event.COMPLETE, onCloseFollowerEditor);
				followerEditor.dispose();
				followerEditor = null;
			}
			
			if (followerEditorContainer != null)
			{
				followerEditorContainer.dispose();
				followerEditorContainer = null;
			}
			
			if (editFollowerCallout != null)
			{
				editFollowerCallout.dispose();
				editFollowerCallout = null;
			}
			
			super.dispose();
		}
	}
}