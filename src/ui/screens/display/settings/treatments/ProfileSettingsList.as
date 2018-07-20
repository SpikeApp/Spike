package ui.screens.display.settings.treatments
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import database.BgReading;
	import database.CommonSettings;
	
	import feathers.controls.Button;
	import feathers.controls.DateTimeMode;
	import feathers.controls.DateTimeSpinner;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.NumericStepper;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.MathHelper;
	import utils.UniqueId;
	
	[ResourceBundle("profilesettingsscreen")]
	[ResourceBundle("globaltranslations")]
	
	public class ProfileSettingsList extends SpikeList 
	{
		/* Display Objects */
		private var addProfileButton:Button;
		private var ISFStepper:NumericStepper;
		private var ICStepper:NumericStepper;
		private var targetBGStepper:NumericStepper;
		private var profileStartTime:DateTimeSpinner;
		private var saveProfileButton:Button;
		private var cancelProfileButton:Button;
		private var actionsContainer:LayoutGroup;
		private var modeLabel:Label;
		private var ISFGuideButton:Button;
		private var ICGuideButton:Button;
		private var guidesContainer:LayoutGroup;
		private var glossaryLabel:Label;
		
		/* Properties */
		private var userProfiles:Array;
		private var accessoryList:Array = [];
		private var addMode:Boolean = false;
		private var editMode:Boolean = false;
		private var unit:String;		
		private var isDefaultEmpty:Boolean;
		private var selectedProfile:Profile;
		
		public function ProfileSettingsList()
		{
			super(true);
			
			setupProperties();
			setupInitialContent();	
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
		
		private function setupInitialContent():void
		{
			/* Get Values From Database */
			userProfiles = ProfileManager.profilesList;
			
			/* Get Settings */
			unit = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mgdl" : "mmol";
		}
		
		private function setupContent():void
		{	
			//MODE Label
			modeLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			modeLabel.wordWrap = true;
			modeLabel.width = width;
			
			//ADD Button
			addProfileButton = LayoutFactory.createButton("Add");
			addProfileButton.addEventListener(Event.TRIGGERED, onAddProfile);
			
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.gap = 5;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			
			//CANCEL Button
			cancelProfileButton = LayoutFactory.createButton("Cancel");
			cancelProfileButton.addEventListener(Event.TRIGGERED, onCancelProfile);
			actionsContainer.addChild(cancelProfileButton);
			
			//SAVE Button
			saveProfileButton = LayoutFactory.createButton("Save");
			saveProfileButton.addEventListener(Event.TRIGGERED, onSaveProfile);
			actionsContainer.addChild(saveProfileButton);
			
			//ISF / IC / Target BG
			ISFStepper = LayoutFactory.createNumericStepper(unit == "mgdl" ? 1 : Math.round(BgReading.mgdlToMmol(1) * 10) / 10, unit == "mgdl" ? 400 : Math.round(BgReading.mgdlToMmol(400) * 10) / 10, unit == "mgdl" ? 10 : Math.round(BgReading.mgdlToMmol(10) * 10) / 10, unit == "mgdl" ? 1 : 0.1);
			ICStepper = LayoutFactory.createNumericStepper(0.5, 200, 10, 0.5);
			targetBGStepper = LayoutFactory.createNumericStepper(unit == "mgdl" ? 40 : Math.round(BgReading.mgdlToMmol(40) * 10) / 10, unit == "mgdl" ? 400 : Math.round(BgReading.mgdlToMmol(400) * 10) / 10, unit == "mgdl" ? 100 : Math.round(BgReading.mgdlToMmol(100) * 10) / 10,  unit == "mgdl" ? 1 : 0.1);
			
			//START Time
			profileStartTime = new DateTimeSpinner();
			profileStartTime.editingMode = DateTimeMode.TIME;
			profileStartTime.height = 60;
			profileStartTime.paddingTop = 5;
			profileStartTime.paddingBottom = 5;
			profileStartTime.paddingRight = 12;
			profileStartTime.minuteStep = 1;
			profileStartTime.addEventListener(Event.CHANGE, onTimeChanged);
			
			//Guides Container
			var guidesConstainerLayout:HorizontalLayout = new HorizontalLayout();
			guidesConstainerLayout.horizontalAlign = HorizontalAlign.CENTER;
			guidesConstainerLayout.gap = 5;
			guidesContainer = new LayoutGroup();
			guidesContainer.layout = guidesConstainerLayout;
			guidesContainer.width = width;
			
			//I:C Guide Button
			ICGuideButton = LayoutFactory.createButton("I:C Guide");
			ICGuideButton.addEventListener(Event.TRIGGERED, onICGuide);
			guidesContainer.addChild(ICGuideButton);
			
			//ISF Guide Button
			ISFGuideButton = LayoutFactory.createButton("ISF Guide");
			ISFGuideButton.addEventListener(Event.TRIGGERED, onISFGuide);
			guidesContainer.addChild(ISFGuideButton);
			
			//Glossary
			glossaryLabel = LayoutFactory.createLabel("ISF (Insulin Sensitivity Factor): The amount of glucose (mg/dl or mmol/L) lowered by 1U of insulin.\n\nI:C (Insulin to Carb Ratio): The amount of carbs (g) covered by 1U of insulin.\n\nTarget BG: The glucose value you're aiming at, the one you want to stay at most of the time.\n\nTo determine your I:C and ISF please read the guides below.", HorizontalAlign.JUSTIFY);
			glossaryLabel.wordWrap = true;
			glossaryLabel.width = width;
			glossaryLabel.paddingTop = glossaryLabel.paddingBottom = 10;
			
			configureComponents();
			refreshContent();
		}
		
		private function refreshContent():void
		{
			//Set screen content
			var data:Array = [];
			
			//Loop Profiles
			var validProfile:Boolean = false;
			for (var i:int = 0; i < userProfiles.length; i++) 
			{
				var profile:Profile = userProfiles[i];
				if (profile.time != "" && profile.insulinSensitivityFactors != "" && profile.insulinToCarbRatios != "" && profile.targetGlucoseRates != "")
				{
					var profileAccessory:TreatmentManagerAccessory = new TreatmentManagerAccessory();
					profileAccessory.addEventListener(TreatmentManagerAccessory.EDIT, onEditProfile);
					profileAccessory.addEventListener(TreatmentManagerAccessory.DELETE, onDeleteProfile);
					accessoryList.push(profileAccessory);
					
					data.push( { label: "Time: " + profile.time + ", ISF: " + profile.insulinSensitivityFactors + "," + "\n" + "I:C: " + profile.insulinToCarbRatios + ", Target BG: " + profile.targetGlucoseRates, accessory: profileAccessory, profile: profile  } );
					validProfile = true;
				}
			}
			
			if (!validProfile && !editMode && !addMode)
			{
				data.push( { label: "Please add settings..." } );
			}
			
			//Add Components
			if (addMode || editMode)
			{
				if (addMode) modeLabel.text = "Add Profile";	
				else if (editMode)modeLabel.text = "Edit Profile";
				
				data.push( { label: "", accessory:  modeLabel} );
				data.push( { label: "Start Time", accessory: profileStartTime } );
				data.push( { label: "ISF", accessory: ISFStepper } );
				data.push( { label: "I:C", accessory: ICStepper } );
				data.push( { label: "Target BG", accessory: targetBGStepper } );
			}
			
			if (!addMode && !editMode)
			{
				var lastProfile:Profile = userProfiles[userProfiles.length - 1] as Profile;
				if (lastProfile != null && lastProfile.time != "23:59")
				{
					data.push( { label: "", accessory: addProfileButton } );
				}
			}
			else
			{
				data.push( { label: "", accessory: actionsContainer } );
			}
			
			//Glossary & Guide
			data.push( { label: "", accessory: glossaryLabel } );
			data.push( { label: "", accessory: guidesContainer } );
			
			dataProvider = new ArrayCollection(data);
		}
		
		private function configureComponents():void
		{
			var profileSugestedTime:Date = new Date();
			profileSugestedTime.hours = 0;
			profileSugestedTime.minutes = 0;
			
			isDefaultEmpty = false;
			
			if (userProfiles.length == 1 && (userProfiles[0] as Profile).time == "00:00" && (userProfiles[0] as Profile).insulinSensitivityFactors == "" && (userProfiles[0] as Profile).insulinToCarbRatios == "" && (userProfiles[0] as Profile).targetGlucoseRates == "")
			{
				//It's the default empty profile. No need to change suggested date.
				isDefaultEmpty = true;
			}
			else if (editMode && selectedProfile != null && selectedProfile.time == "00:00")
			{
				//Do nothing.
			}
			else
			{
				//Not default profile. Get last profile
				var lastProfile:Profile = userProfiles[userProfiles.length - 1] as Profile;
				
				var lastProfileTotalTime:String = lastProfile.time;
				var lastProfileDividedTime:Array = lastProfileTotalTime.split(":");
				var lastProfileHour:Number = Number(lastProfileDividedTime[0]);
				var lastProfileMinutes:Number = Number(lastProfileDividedTime[1]);
				
				if (lastProfileMinutes == 59 && lastProfileHour < 23)
				{
					profileSugestedTime.hours = lastProfileHour + 1;
					profileSugestedTime.minutes = 0;
				}
				else
				{
					profileSugestedTime.hours = lastProfileHour;
					profileSugestedTime.minutes = lastProfileMinutes + 1;
				}
			}
			
			profileStartTime.value = new Date(profileSugestedTime.valueOf());
			
			if (isDefaultEmpty || (editMode && selectedProfile != null && selectedProfile.time == "00:00"))
			{
				profileStartTime.touchable = false;
				profileStartTime.alpha = 0.6;
			}
			
			if (addMode)
			{
				if (unit == "mgdl")
				{
					ISFStepper.minimum = 1;
					ISFStepper.maximum = 400;
					ISFStepper.value = 10;
					ISFStepper.step = 1;
					
					targetBGStepper.minimum = 40;
					targetBGStepper.maximum = 400;
					targetBGStepper.value = 100;
					targetBGStepper.step = 1;
				}
				else
				{
					ISFStepper.minimum = Math.round(BgReading.mgdlToMmol(1) * 10) / 10;
					ISFStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					ISFStepper.value = Math.round(BgReading.mgdlToMmol(10) * 10) / 10
					ISFStepper.step = 0.1;
					
					targetBGStepper.minimum = Math.round(BgReading.mgdlToMmol(40) * 10) / 10;
					targetBGStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					targetBGStepper.value = Math.round(BgReading.mgdlToMmol(100) * 10) / 10;
					targetBGStepper.step = 0.1;
				}
				
				ICStepper.minimum = 0.5;
				ICStepper.maximum = 200;
				ICStepper.value = 10;
				ICStepper.step = 0.5;
			}
			else if (editMode && selectedProfile != null)
			{
				if (unit == "mgdl")
				{
					ISFStepper.minimum = 1;
					ISFStepper.maximum = 400;
					ISFStepper.value = Number(selectedProfile.insulinSensitivityFactors);
					ISFStepper.step = 1;
					
					targetBGStepper.minimum = 40;
					targetBGStepper.maximum = 400;
					targetBGStepper.value = Number(selectedProfile.targetGlucoseRates);
					targetBGStepper.step = 1;
				}
				else
				{
					ISFStepper.minimum = Math.round(BgReading.mgdlToMmol(1) * 10) / 10;
					ISFStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					ISFStepper.value = Math.round(BgReading.mgdlToMmol(Number(selectedProfile.insulinSensitivityFactors)) * 10) / 10
					ISFStepper.step = 0.1;
					
					targetBGStepper.minimum = Math.round(BgReading.mgdlToMmol(40) * 10) / 10;
					targetBGStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					targetBGStepper.value = Math.round(BgReading.mgdlToMmol(Number(selectedProfile.targetGlucoseRates)) * 10) / 10;
					targetBGStepper.step = 0.1;
				}
				
				ICStepper.minimum = 0.5;
				ICStepper.maximum = 200;
				ICStepper.value = Number(selectedProfile.insulinToCarbRatios);
				ICStepper.step = 0.5;
			}
			
			saveProfileButton.isEnabled = true;
		}
		
		private function doesProfileTimeOverlap():Boolean
		{
			var overlapFound:Boolean = false;
			var suggestedHour:Number = profileStartTime.value.hours;
			var suggestedMinutes:Number = profileStartTime.value.minutes;
			
			for (var i:int = 0; i < userProfiles.length; i++) 
			{
				var existingProfile:Profile = userProfiles[i] as Profile;
				var existingProfileTime:Array = existingProfile.time.split(":");
				var existingProfileHour:Number = Number(existingProfileTime[0]);
				var existingProfileMinutes:Number = Number(existingProfileTime[1]);
				
				if (suggestedHour == existingProfileHour && suggestedMinutes == existingProfileMinutes)
				{
					overlapFound = true;
					break;
				}
			}
			
			return overlapFound;
		}
		
		/**
		 * Event Listeners
		 */
		private function onAddProfile(e:Event):void
		{
			addMode = true;
			editMode = false;
			
			configureComponents();
			refreshContent();
		}
		
		private function onEditProfile(e:Event):void
		{
			var profile:Profile = (((e.currentTarget as TreatmentManagerAccessory).parent as Object).data as Object).profile as Profile;
			
			addMode = false;
			editMode = false;
			
			if (profile != null)
			{
				editMode = true;
				selectedProfile = profile;
			}
			
			configureComponents();
			refreshContent();
		}
		
		private function onDeleteProfile(e:Event):void
		{
			var profile:Profile = (((e.currentTarget as TreatmentManagerAccessory).parent as Object).data as Object).profile as Profile;
			
			if (profile != null && profile.time == "00:00")
			{
				AlertManager.showSimpleAlert
					(
						"Warning",
						"Can't delete profile! There needs to be at least one profile that starts at 00:00"
					);
				
				return;
			}
			
			if (profile != null)
			{
				ProfileManager.deleteProfile(profile);
				
				configureComponents();
				refreshContent();
			}
		}
		
		private function onSaveProfile(e:Event):void
		{
			if (doesProfileTimeOverlap())
			{
				AlertManager.showSimpleAlert
					(
						"Warning",
						"Profile start time already in use. Please select a different time"
					);
				
				return;
			}
			
			if (addMode)
			{
				if (isDefaultEmpty)
				{
					var defaultProfile:Profile = userProfiles[0] as Profile;
					defaultProfile.insulinSensitivityFactors = unit = "mgdl" ? String(ISFStepper.value) : String(Math.round(BgReading.mmolToMgdl(ISFStepper.value)));
					defaultProfile.insulinToCarbRatios = String(ICStepper.value);
					defaultProfile.targetGlucoseRates = unit = "mgdl" ? String(targetBGStepper.value) : String(Math.round(BgReading.mmolToMgdl(targetBGStepper.value)));
					ProfileManager.updateProfile(defaultProfile);
					
					isDefaultEmpty = false;
				}
				else
				{
					var newProfile:Profile = new Profile
						(
							UniqueId.createEventId(),
							MathHelper.formatNumberToString(profileStartTime.value.hours) + ":" + MathHelper.formatNumberToString(profileStartTime.value.minutes),
							"Default",
							String(ICStepper.value),
							unit = "mgdl" ? String(ISFStepper.value) : String(Math.round(BgReading.mmolToMgdl(ISFStepper.value))),
							ProfileManager.getCarbAbsorptionRate(),
							"",
							unit = "mgdl" ? String(targetBGStepper.value) : String(Math.round(BgReading.mmolToMgdl(targetBGStepper.value))),
							new Date().valueOf()
						);
					
					ProfileManager.insertProfile(newProfile);
				}
			}
			else if (editMode)
			{
				selectedProfile.insulinSensitivityFactors = unit = "mgdl" ? String(ISFStepper.value) : String(Math.round(BgReading.mmolToMgdl(ISFStepper.value)));
				selectedProfile.insulinToCarbRatios = String(ICStepper.value);
				selectedProfile.targetGlucoseRates = unit = "mgdl" ? String(targetBGStepper.value) : String(Math.round(BgReading.mmolToMgdl(targetBGStepper.value)));
				ProfileManager.updateProfile(selectedProfile);
				
				selectedProfile = null;
			}
			
			addMode = false;
			editMode = false;
			
			refreshContent();
		}
		
		private function onCancelProfile(e:Event):void
		{
			addMode = false;
			editMode = false;
			selectedProfile = null;
			
			refreshContent();
		}
		
		private function onTimeChanged(e:Event):void
		{
			if (doesProfileTimeOverlap())
				saveProfileButton.isEnabled = false;
			else
				saveProfileButton.isEnabled = true;
		}
		
		private function onISFGuide(e:Event):void
		{
			navigateToURL(new URLRequest("https://spike-app.com/app/docs/InsulinSensitivityFactor.pdf"));
		}
		
		private function onICGuide(e:Event):void
		{
			navigateToURL(new URLRequest("https://spike-app.com/app/docs/InsulinToCarbRatio.pdf"));
		}
		
		override protected function onStarlingResize(event:ResizeEvent):void 
		{
			width = Constants.stageWidth - (2 * BaseMaterialDeepGreyAmberMobileTheme.defaultPanelPadding);
			
			if (modeLabel != null)
				modeLabel.width = width;
			
			if (glossaryLabel != null)
				glossaryLabel.width = width;
			
			if (guidesContainer != null)
				guidesContainer.width = width;
			
			setupRenderFactory();
		}
		
		/**
		 * Utility
		 */	
		override protected function draw():void
		{
			if ((layout as VerticalLayout) != null)
			{
				(layout as VerticalLayout).hasVariableItemDimensions = true;
				(layout as VerticalLayout).useVirtualLayout = false;
			}
			
			super.draw();
		}
		
		override public function dispose():void
		{
			if (ISFStepper != null)
			{
				ISFStepper.dispose();
				ISFStepper = null;
			}
			
			if (ICStepper != null)
			{
				ICStepper.dispose();
				ICStepper = null;
			}
			
			if (targetBGStepper != null)
			{
				targetBGStepper.dispose();
				targetBGStepper = null;
			}
			
			if (profileStartTime != null)
			{
				profileStartTime.removeEventListener(Event.CHANGE, onTimeChanged);
				profileStartTime.dispose();
				profileStartTime = null;
			}
			
			if (addProfileButton != null)
			{
				addProfileButton.removeEventListener(Event.TRIGGERED, onAddProfile);
				addProfileButton.removeFromParent();
				addProfileButton.dispose();
				addProfileButton = null;
			}
			
			if (saveProfileButton != null)
			{
				saveProfileButton.removeEventListener(Event.TRIGGERED, onSaveProfile);
				saveProfileButton.removeFromParent();
				saveProfileButton.dispose();
				saveProfileButton = null;
			}
			
			if (cancelProfileButton != null)
			{
				cancelProfileButton.removeEventListener(Event.TRIGGERED, onCancelProfile);
				cancelProfileButton.removeFromParent();
				cancelProfileButton.dispose();
				cancelProfileButton = null;
			}
			
			if (actionsContainer != null)
			{
				actionsContainer.dispose();
				actionsContainer = null;
			}
			
			if (modeLabel != null)
			{
				modeLabel.dispose();
				modeLabel = null;
			}
			
			if (ISFGuideButton != null)
			{
				ISFGuideButton.removeEventListener(Event.TRIGGERED, onISFGuide);
				ISFGuideButton.removeFromParent();
				ISFGuideButton.dispose();
				ISFGuideButton = null;
			}
			
			if (ICGuideButton != null)
			{
				ICGuideButton.removeEventListener(Event.TRIGGERED, onICGuide);
				ICGuideButton.removeFromParent();
				ICGuideButton.dispose();
				ICGuideButton = null;
			}
			
			if (guidesContainer != null)
			{
				guidesContainer.removeFromParent();
				guidesContainer.dispose();
				guidesContainer = null;
			}
			
			if (glossaryLabel != null)
			{
				glossaryLabel.dispose();
				glossaryLabel = null;
			}
			
			super.dispose();
		}
	}
}