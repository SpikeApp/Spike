package ui.screens.display.settings.treatments
{
	import flash.display.StageOrientation;
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
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ArrayCollection;
	import feathers.layout.HorizontalAlign;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalAlign;
	import feathers.layout.VerticalLayout;
	import feathers.themes.BaseMaterialDeepGreyAmberMobileTheme;
	
	import model.ModelLocator;
	
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	import treatments.Profile;
	import treatments.ProfileManager;
	import treatments.TreatmentsManager;
	
	import ui.popups.AlertManager;
	import ui.screens.display.LayoutFactory;
	import ui.screens.display.SpikeList;
	
	import utils.Constants;
	import utils.DeviceInfo;
	import utils.MathHelper;
	import utils.TimeSpan;
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
		private var trend45UpStepper:NumericStepper;
		private var trend90UpStepper:NumericStepper;
		private var trendDoubleUpStepper:NumericStepper;
		private var trend45DownStepper:NumericStepper;
		private var trend90DownStepper:NumericStepper;
		private var trendDoubleDownStepper:NumericStepper;
		
		/* Properties */
		private var userProfiles:Array;
		private var accessoryList:Array = [];
		private var addMode:Boolean = false;
		private var editMode:Boolean = false;
		private var unit:String;		
		private var isDefaultEmpty:Boolean;
		private var selectedProfile:Profile;
		private var timeFormat:String;
		
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
			/* Get Settings */
			userProfiles = ProfileManager.profilesList;
			unit = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? "mgdl" : "mmol";
			timeFormat = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_CHART_DATE_FORMAT);
		}
		
		private function setupContent():void
		{	
			//MODE Label
			modeLabel = LayoutFactory.createLabel("", HorizontalAlign.CENTER, VerticalAlign.TOP, 14, true);
			modeLabel.wordWrap = true;
			modeLabel.width = width;
			
			//ADD Button
			addProfileButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','add_button_label'));
			addProfileButton.addEventListener(Event.TRIGGERED, onAddProfile);
			
			//Actions Container
			var actionsLayout:HorizontalLayout = new HorizontalLayout();
			actionsLayout.gap = 5;
			actionsContainer = new LayoutGroup();
			actionsContainer.layout = actionsLayout;
			
			//CANCEL Button
			cancelProfileButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label'));
			cancelProfileButton.addEventListener(Event.TRIGGERED, onCancelProfile);
			actionsContainer.addChild(cancelProfileButton);
			
			//SAVE Button
			saveProfileButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('globaltranslations','save_button_label'));
			saveProfileButton.addEventListener(Event.TRIGGERED, onSaveProfile);
			actionsContainer.addChild(saveProfileButton);
			
			//ISF / IC / Target BG / Trend Corrections
			ISFStepper = LayoutFactory.createNumericStepper(unit == "mgdl" ? 1 : Math.round(BgReading.mgdlToMmol(1) * 10) / 10, unit == "mgdl" ? 400 : Math.round(BgReading.mgdlToMmol(400) * 10) / 10, unit == "mgdl" ? 25 : Math.round(BgReading.mgdlToMmol(25) * 10) / 10, unit == "mgdl" ? 0.2 : 0.1);
			ICStepper = LayoutFactory.createNumericStepper(0.5, 200, 10, 0.1);
			targetBGStepper = LayoutFactory.createNumericStepper(unit == "mgdl" ? 40 : Math.round(BgReading.mgdlToMmol(40) * 10) / 10, unit == "mgdl" ? 400 : Math.round(BgReading.mgdlToMmol(400) * 10) / 10, unit == "mgdl" ? 100 : Math.round(BgReading.mgdlToMmol(100) * 10) / 10,  unit == "mgdl" ? 1 : 0.1);
			trend45UpStepper = LayoutFactory.createNumericStepper(0, 10, 1, 0.1);
			trend90UpStepper = LayoutFactory.createNumericStepper(0, 10, 1.5, 0.1);
			trendDoubleUpStepper = LayoutFactory.createNumericStepper(0, 10, 2, 0.1);
			trend45DownStepper = LayoutFactory.createNumericStepper(0, 100, 10, 0.5);
			trend90DownStepper = LayoutFactory.createNumericStepper(0, 100, 15, 0.5);
			trendDoubleDownStepper = LayoutFactory.createNumericStepper(0, 100, 20, 0.5);
			
			//START Time
			profileStartTime = new DateTimeSpinner();
			profileStartTime.editingMode = DateTimeMode.TIME;
			profileStartTime.locale = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_LANGUAGE);
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
			ICGuideButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_carb_ratio_guide_label'));
			ICGuideButton.addEventListener(Event.TRIGGERED, onICGuide);
			guidesContainer.addChild(ICGuideButton);
			
			//ISF Guide Button
			ISFGuideButton = LayoutFactory.createButton(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_sensitivity_factor_guide_label'));
			ISFGuideButton.addEventListener(Event.TRIGGERED, onISFGuide);
			guidesContainer.addChild(ISFGuideButton);
			
			//Glossary
			glossaryLabel = LayoutFactory.createLabel(ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','isf_ic_trend_bgtarget_description_label'), HorizontalAlign.JUSTIFY);
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
					//Accessory
					var profileAccessory:TreatmentManagerAccessory = new TreatmentManagerAccessory();
					profileAccessory.addEventListener(TreatmentManagerAccessory.EDIT, onEditProfile);
					profileAccessory.addEventListener(TreatmentManagerAccessory.DELETE, onDeleteProfile);
					accessoryList.push(profileAccessory);
					
					//Date
					var profileDate:Date = ProfileManager.getProfileDate(profile);
					
					//Data
					data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','start_time_label') + ": " + TimeSpan.formatHoursMinutes(profileDate.hours, profileDate.minutes, timeFormat.slice(0,2) == "24" ? TimeSpan.TIME_FORMAT_24H : TimeSpan.TIME_FORMAT_12H) + ", " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_sensitivity_factor_short_label') + " : " + (unit == "mgdl" ? profile.insulinSensitivityFactors : Math.round(BgReading.mgdlToMmol(Number(profile.insulinSensitivityFactors)) * 10) / 10) + "," + "\n" + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_to_carb_ratio_short_label') + ": " + profile.insulinToCarbRatios + ", " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','target_glucose_label') + ": " + (unit == "mgdl" ? profile.targetGlucoseRates : Math.round(BgReading.mgdlToMmol(Number(profile.targetGlucoseRates)) * 10) / 10) + "\n" + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trends_label') + ": " + "\u2197 " + profile.trend45Up + "U" + " | " + "\u2191 " + profile.trend90Up + "U" + " | " + "\u2191\u2191 " + profile.trendDoubleUp + "U" + " | " + "\u2198 " + profile.trend45Down + "g" + " | " + "\u2193 " + profile.trend90Down + "g" + " | " + "\u2193\u2193 " + profile.trendDoubleDown + "g", accessory: profileAccessory, profile: profile  } );
					validProfile = true;
				}
			}
			
			if (!validProfile && !editMode && !addMode)
			{
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','add_configuration_label') } );
			}
			
			//Add Components
			if (addMode || editMode)
			{
				if (addMode) modeLabel.text = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','add_profile_label');	
				else if (editMode)modeLabel.text = ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','edit_profile_label');
				
				data.push( { label: "", accessory:  modeLabel} );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','start_time_label'), accessory: profileStartTime } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_sensitivity_factor_short_label'), accessory: ISFStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','insulin_to_carb_ratio_short_label'), accessory: ICStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','target_glucose_label'), accessory: targetBGStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trend') + " \u2197" + " - " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','units_of_insulin_label'), accessory: trend45UpStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trend') + " \u2191" + " - " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','units_of_insulin_label'), accessory: trend90UpStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trend') + " \u2191\u2191" + " - " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','units_of_insulin_label'), accessory: trendDoubleUpStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trend') + " \u2198" + " - " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','grams_of_carbs_label'), accessory: trend45DownStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trend') + " \u2193" + " - " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','grams_of_carbs_label'), accessory: trend90DownStepper } );
				data.push( { label: ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','glucose_trend') + " \u2193\u2193" + " - " + ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','grams_of_carbs_label'), accessory: trendDoubleDownStepper } );
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
			profileSugestedTime.seconds = 0;
			profileSugestedTime.milliseconds = 0;
			
			isDefaultEmpty = false;
			
			if (userProfiles.length == 1 && (userProfiles[0] as Profile).time == "00:00" && (userProfiles[0] as Profile).insulinSensitivityFactors == "" && (userProfiles[0] as Profile).insulinToCarbRatios == "" && (userProfiles[0] as Profile).targetGlucoseRates == "")
			{
				//It's the default empty profile. No need to change suggested date.
				isDefaultEmpty = true;
			}
			else if (editMode && selectedProfile != null && selectedProfile.time == "00:00")
			{
				//Use default date
			}
			else if (!editMode)
			{
				//Not default profile. Get last profile
				var lastProfile:Profile = userProfiles[userProfiles.length - 1] as Profile;
				var lastProfileDate:Date = ProfileManager.getProfileDate(lastProfile);
				
				if (lastProfileDate.minutes == 59 && lastProfileDate.hours < 23)
				{
					profileSugestedTime.hours = lastProfileDate.hours + 1;
					profileSugestedTime.minutes = 0;
				}
				else if (lastProfileDate.minutes == 59 && lastProfileDate.hours == 23)
				{
					profileSugestedTime.hours = 12;
					profileSugestedTime.minutes = 0;
				}
				else
				{
					profileSugestedTime.hours = lastProfileDate.hours;
					profileSugestedTime.minutes = lastProfileDate.minutes + 1;
				}
			}
			else if (editMode && selectedProfile != null)
			{
				//Suggested date should be equal to selected profile date
				profileSugestedTime = ProfileManager.getProfileDate(selectedProfile);
			}
			
			profileStartTime.value = profileSugestedTime;
			
			if (isDefaultEmpty || (editMode && selectedProfile != null && selectedProfile.time == "00:00"))
			{
				profileStartTime.touchable = false;
				profileStartTime.alpha = 0.6;
			}
			else
			{
				profileStartTime.touchable = true;
				profileStartTime.alpha = 1;
			}
			
			if (addMode)
			{
				if (unit == "mgdl")
				{
					ISFStepper.minimum = 1;
					ISFStepper.maximum = 400;
					ISFStepper.value = 25;
					ISFStepper.step = 0.2;
					
					targetBGStepper.minimum = 40;
					targetBGStepper.maximum = 400;
					targetBGStepper.value = 100;
					targetBGStepper.step = 1;
				}
				else
				{
					ISFStepper.minimum = Math.round(BgReading.mgdlToMmol(1) * 10) / 10;
					ISFStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					ISFStepper.value = Math.round(BgReading.mgdlToMmol(25) * 10) / 10;
					ISFStepper.step = 0.1;
					
					targetBGStepper.minimum = Math.round(BgReading.mgdlToMmol(40) * 10) / 10;
					targetBGStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					targetBGStepper.value = Math.round(BgReading.mgdlToMmol(100) * 10) / 10;
					targetBGStepper.step = 0.1;
				}
				
				ICStepper.minimum = 0.5;
				ICStepper.maximum = 200;
				ICStepper.value = 10;
				ICStepper.step = 0.1;
				
				trend45UpStepper.value = 1;
				trend90UpStepper.value = 1.5;
				trendDoubleUpStepper.value = 2;
				trend45DownStepper.value = 10;
				trend90DownStepper.value = 15;
				trendDoubleDownStepper.value = 20;
			}
			else if (editMode && selectedProfile != null)
			{
				if (unit == "mgdl")
				{
					ISFStepper.minimum = 1;
					ISFStepper.maximum = 400;
					ISFStepper.value = Number(selectedProfile.insulinSensitivityFactors);
					ISFStepper.step = 0.2;
					
					targetBGStepper.minimum = 40;
					targetBGStepper.maximum = 400;
					targetBGStepper.value = Number(selectedProfile.targetGlucoseRates);
					targetBGStepper.step = 1;
				}
				else
				{
					ISFStepper.minimum = Math.round(BgReading.mgdlToMmol(1) * 10) / 10;
					ISFStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					ISFStepper.value = Math.round(BgReading.mgdlToMmol(Number(selectedProfile.insulinSensitivityFactors)) * 10) / 10;
					ISFStepper.step = 0.1;
					
					targetBGStepper.minimum = Math.round(BgReading.mgdlToMmol(40) * 10) / 10;
					targetBGStepper.maximum = Math.round(BgReading.mgdlToMmol(400) * 10) / 10;
					targetBGStepper.value = Math.round(BgReading.mgdlToMmol(Number(selectedProfile.targetGlucoseRates)) * 10) / 10;
					targetBGStepper.step = 0.1;
				}
				
				ICStepper.minimum = 0.5;
				ICStepper.maximum = 200;
				ICStepper.value = Number(selectedProfile.insulinToCarbRatios);
				ICStepper.step = 0.1;
				
				trend45UpStepper.value = selectedProfile.trend45Up;
				trend90UpStepper.value = selectedProfile.trend90Up;
				trendDoubleUpStepper.value = selectedProfile.trendDoubleUp;
				trend45DownStepper.value = selectedProfile.trend45Down;
				trend90DownStepper.value = selectedProfile.trend90Down;
				trendDoubleDownStepper.value = selectedProfile.trendDoubleDown;
			}
			
			if (saveProfileButton != null) saveProfileButton.isEnabled = true;
		}
		
		private function doesProfileTimeOverlap():Boolean
		{
			var overlapFound:Boolean = false;
			var suggestedHour:Number = profileStartTime.value.hours;
			var suggestedMinutes:Number = profileStartTime.value.minutes;
			
			for (var i:int = 0; i < userProfiles.length; i++) 
			{
				var existingProfile:Profile = userProfiles[i] as Profile;
				
				if (editMode && selectedProfile.ID == existingProfile.ID)
					continue;
				
				var existingProfileDate:Date = ProfileManager.getProfileDate(existingProfile);
				
				if (suggestedHour == existingProfileDate.hours && suggestedMinutes == existingProfileDate.minutes)
				{
					overlapFound = true;
					break;
				}
			}
			
			return overlapFound;
		}
		
		override protected function setupRenderFactory():void
		{
			/* List Item Renderer */
			itemRendererFactory = function():IListItemRenderer 
			{
				const item:DefaultListItemRenderer = new DefaultListItemRenderer();
				item.labelField = "label";
				item.accessoryField = "accessory";
				item.iconSourceField = "icon";
				item.paddingTop = 5;
				item.paddingBottom = 5;
				item.accessoryLabelProperties.wordWrap = true;
				item.defaultLabelProperties.wordWrap = true;
				
				if (Constants.deviceModel == DeviceInfo.IPHONE_X_Xs_XsMax_Xr && !Constants.isPortrait)
				{
					if (Constants.currentOrientation == StageOrientation.ROTATED_RIGHT)
					{
						item.paddingLeft = 30;
						if (noRightPadding) item.paddingRight = 0;
					}
					else if (Constants.currentOrientation == StageOrientation.ROTATED_LEFT)
						item.paddingRight = 30;
				}
				else
					if (noRightPadding) item.paddingRight = 0;
				
				return item;
			};
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
						ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
						ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','cant_delete_profile_label') + " " + TimeSpan.formatHoursMinutes(0, 0, timeFormat.slice(0,2) == "24" ? TimeSpan.TIME_FORMAT_24H : TimeSpan.TIME_FORMAT_12H)
					);
				
				return;
			}
			
			AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
				ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','delete_profile_confirmation_label'),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','cancel_button_label').toUpperCase() },
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','yes_uppercase').toUpperCase(), triggered: deleteProfile }
				]
			);
			
			function deleteProfile():void
			{
				if (profile != null)
				{
					ProfileManager.deleteProfile(profile);
					
					configureComponents();
					refreshContent();
				}
			}
		}
		
		private function onSaveProfile(e:Event):void
		{
			if (!isDefaultEmpty && !editMode && doesProfileTimeOverlap())
			{
				AlertManager.showSimpleAlert
				(
					ModelLocator.resourceManagerInstance.getString('globaltranslations','warning_alert_title'),
					ModelLocator.resourceManagerInstance.getString('profilesettingsscreen','conflicting_profile_label')
				);
				
				return;
			}
			
			if (addMode)
			{
				if (isDefaultEmpty)
				{
					var defaultProfile:Profile = userProfiles[0] as Profile;
					defaultProfile.insulinSensitivityFactors = unit == "mgdl" ? String(ISFStepper.value) : String(Math.round(BgReading.mmolToMgdl(ISFStepper.value)));
					defaultProfile.insulinToCarbRatios = String(ICStepper.value);
					defaultProfile.targetGlucoseRates = unit == "mgdl" ? String(targetBGStepper.value) : String(Math.round(BgReading.mmolToMgdl(targetBGStepper.value)));
					defaultProfile.trendCorrections = "up45:" + trend45UpStepper.value + "|" + "up90:" + trend90UpStepper.value + "|" + "upDouble:" + trendDoubleUpStepper.value + "|" + "down45:" + trend45DownStepper.value + "|" + "down90:" + trend90DownStepper.value + "|" + "downDouble:" + trendDoubleDownStepper.value;
					defaultProfile.parseTrends();
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
							unit == "mgdl" ? String(ISFStepper.value) : String(Math.round(BgReading.mmolToMgdl(ISFStepper.value))),
							ProfileManager.getCarbAbsorptionRate(),
							"",
							unit == "mgdl" ? String(targetBGStepper.value) : String(Math.round(BgReading.mmolToMgdl(targetBGStepper.value))),
							"up45:" + trend45UpStepper.value + "|" + "up90:" + trend90UpStepper.value + "|" + "upDouble:" + trendDoubleUpStepper.value + "|" + "down45:" + trend45DownStepper.value + "|" + "down90:" + trend90DownStepper.value + "|" + "downDouble:" + trendDoubleDownStepper.value,
							new Date().valueOf()
						);
					
					ProfileManager.insertProfile(newProfile);
				}
				
				//Clear Previous IOB/COB Caches
				TreatmentsManager.clearAllCaches();
			}
			else if (editMode && selectedProfile != null)
			{
				if (Number(selectedProfile.insulinSensitivityFactors) != ISFStepper.value || Number(selectedProfile.insulinToCarbRatios) != ICStepper.value)
				{
					//Clear Previous IOB/COB Caches
					TreatmentsManager.clearAllCaches();
				}
				
				selectedProfile.time = MathHelper.formatNumberToString(profileStartTime.value.hours) + ":" + MathHelper.formatNumberToString(profileStartTime.value.minutes);
				selectedProfile.insulinSensitivityFactors = unit == "mgdl" ? String(ISFStepper.value) : String(Math.round(BgReading.mmolToMgdl(ISFStepper.value)));
				selectedProfile.insulinToCarbRatios = String(ICStepper.value);
				selectedProfile.targetGlucoseRates = unit == "mgdl" ? String(targetBGStepper.value) : String(Math.round(BgReading.mmolToMgdl(targetBGStepper.value)));
				selectedProfile.trendCorrections = "up45:" + trend45UpStepper.value + "|" + "up90:" + trend90UpStepper.value + "|" + "upDouble:" + trendDoubleUpStepper.value + "|" + "down45:" + trend45DownStepper.value + "|" + "down90:" + trend90DownStepper.value + "|" + "downDouble:" + trendDoubleDownStepper.value;
				selectedProfile.parseTrends();
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
			saveProfileButton.isEnabled = doesProfileTimeOverlap() ? false : true;
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
			
			if (trend45UpStepper != null)
			{
				trend45UpStepper.dispose();
				trend45UpStepper = null;
			}
			
			if (trend90UpStepper != null)
			{
				trend90UpStepper.dispose();
				trend90UpStepper = null;
			}
			
			if (trendDoubleUpStepper != null)
			{
				trendDoubleUpStepper.dispose();
				trendDoubleUpStepper = null;
			}
			
			if (trend45DownStepper != null)
			{
				trend45DownStepper.dispose();
				trend45DownStepper = null;
			}
			
			if (trend90DownStepper != null)
			{
				trend90DownStepper.dispose();
				trend90DownStepper = null;
			}
			
			if (trendDoubleDownStepper != null)
			{
				trendDoubleDownStepper.dispose();
				trendDoubleDownStepper = null;
			}
			
			super.dispose();
		}
	}
}