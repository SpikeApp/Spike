package services
{
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	
	import database.BgReading;
	import database.CommonSettings;
	import database.LocalSettings;
	
	import events.FollowerEvent;
	import events.SettingsServiceEvent;
	import events.SpikeEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import utils.BgGraphBuilder;
	import utils.GlucoseHelper;
	import utils.Trace;
	
	[ResourceBundle("texttospeech")]
	
	/**
	 * Class responsible for managing text to speak functionallity. 
	 */
	public class TextToSpeechService
	{
		//Define variables
		private static var initiated:Boolean = false;
		private static var lockEnabled:Boolean = false;
		private static var speakInterval:int = 1;
		private static var receivedReadings:int = 0;
		private static var speechLanguageCode:String;
		private static var glucoseThresholdsActivated:Boolean = false;
		private static var glucoseThresholdHigh:Number = 0;
		private static var glucoseThresholdLow:Number = 0;

		public function TextToSpeechService()
		{
			//Don't allow class to be instantiated
			throw new IllegalOperationError("TextToSpeech class is not meant to be instantiated!");
		}
		
		public static function init():void
		{
			if (!initiated) 
			{
				//Instantiate objects and variables
				initiated = true;
				speakInterval = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL));
				glucoseThresholdsActivated = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_ON) == "true";
				glucoseThresholdHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_HIGH));
				glucoseThresholdLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_LOW));
				
				Spike.instance.addEventListener(SpikeEvent.APP_HALTED, onHaltExecution);
				
				//Register event listener for changed settings
				CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
				
				//Register event listener for new blood glucose readings
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
				NightscoutService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
				DexcomShareService.instance.addEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
				
				//Set speech language
				speechLanguageCode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE);
				
				myTrace("TextToSpeech started. Enabled: " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) + " | Interval: " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL) + " | Language: " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE));
			}
		}
		
		/**
		*Functionality functions
		*/
		
		public static function setLocaleChain():void 
		{
			//Define locales and fallbacks
			if(speechLanguageCode == "en-GB" || 
				speechLanguageCode == "en-US" || 
				speechLanguageCode == "en-ZA" || 
				speechLanguageCode == "en-IE" || 
				speechLanguageCode == "en-AU")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["en_US"];
			}
			else if(speechLanguageCode == "es-ES")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["es_ES","es_MX","en_US"];
			}
			else if(speechLanguageCode == "es-MX")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["es_MX","es_ES","en_US"];
			}
			else if(speechLanguageCode == "pt-PT")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["pt_PT","pt_BR","en_US"];
			}
			else if(speechLanguageCode == "pt-BR")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["pt_BR","pt_PT","en_US"];
			}
			else if(speechLanguageCode == "nl-NL" || speechLanguageCode == "nl-BE")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["nl_BE","en_US"];
			}
			else if(speechLanguageCode == "fr-FR" || speechLanguageCode == "fr-CA")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["fr_FR","en_US"];
			}
			else if(speechLanguageCode == "ru-RU")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["ru_RU","en_US"];
			}
			else if(speechLanguageCode == "pl-PL")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["pl_PL","en_US"];
			}
			else if(speechLanguageCode == "it-IT")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["it_IT","en_US"];
			}
			else if(speechLanguageCode == "zh-CN" || speechLanguageCode == "zh-HK" || speechLanguageCode == "zh-TW")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["zh_CN","en_US"];
			}
			else if(speechLanguageCode == "sl-SL")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["sl_SL","en_US"];
			}
			else if(speechLanguageCode == "de-DE")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["de_DE","en_US"];
			}
			else if(speechLanguageCode == "da-DK")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["da_DK","en_US"];
			}
			else if(speechLanguageCode == "fi-FI")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["fi_FI","en_US"];
			}
			else if(speechLanguageCode == "no-NO")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["no_NO","en_US"];
			}
			else if(speechLanguageCode == "sv-SE")
			{
				ModelLocator.resourceManagerInstance.localeChain = ["sv_SE","en_US"];
			}
		}
		
		public static function sayText(text:String, language:String = "en-US"):void 
		{
			myTrace("Text to speak: " + text);
			
			//Start Text To Speech
			SpikeANE.say(text, language, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_ON) == "true" ? Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_USER_DEFINED_SYSTEM_VOLUME_VALUE)) : Number.NaN);	
		}
		
		//Remove all spaces in the string.
		private static function removeSpaces(text:String):String
		{
			var rex:RegExp = /[\s\r\n]+/gim;
			return text.replace(rex,'');
		}
		
		private static function assertFractionalDigits(number:String):String 
		{
			if(!isNaN(Number(removeSpaces(number))))
			{	
				if(number.indexOf(".") == -1)
				{
					//Assert at least one fractional digit.	
					return number.concat(".0");
				}
			}
			return number;
		}
		
		private static function formatLocaleSpecific(number:String):String 
		{
			if(!isNaN(Number(removeSpaces(number))))
			{
				//For some languages it is important that the string is formatted with the locale specific decimal separator.
				if (speechLanguageCode == "de-DE")
				{
					return number.replace(".", ",");
				}
			}
			return number;
		}
		
		private static function speakReading():void
		{
			//Update received readings counter
			receivedReadings += 1;
			
			//Only speak blood glucose reading if app is in the background or phone is locked
			if (((receivedReadings - 1) % speakInterval == 0))
			{	
				//Get current bg reading and format it 
				var currentBgReading:BgReading = BgReading.lastNoSensor();
				if (currentBgReading != null) 
				{
					//Validate thresholds
					if (glucoseThresholdsActivated && glucoseThresholdHigh != 0 && glucoseThresholdLow != 0 && currentBgReading.calculatedValue != 0 && currentBgReading.calculatedValue > glucoseThresholdLow && currentBgReading.calculatedValue < glucoseThresholdHigh)
						return;
					
					if ((new Date()).valueOf() - currentBgReading.timestamp < 4.5 * 60 * 1000) 
					{
						//Set locale chain
						setLocaleChain();
						
						//Speech Output
						var currentBgReadingOutput:String;
						
						//Get current glucose
						var currentBgReadingFormatted:String = BgGraphBuilder.unitizedString(currentBgReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
						
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "false")
						{
							currentBgReadingFormatted = assertFractionalDigits(currentBgReadingFormatted);
						}						
						
						currentBgReadingFormatted = formatLocaleSpecific(currentBgReadingFormatted);
						
						if (currentBgReadingFormatted == "HIGH")
							currentBgReadingFormatted = ". " + ModelLocator.resourceManagerInstance.getString('texttospeech','high');
						else if (currentBgReadingFormatted == "LOW") 
							currentBgReadingFormatted = ". " + ModelLocator.resourceManagerInstance.getString('texttospeech','low');
						
						//Get trend (slope)
						var currentTrend:String = currentBgReading.slopeName() as String;
							
						//Get current delta
						//var currentDelta:String = BgGraphBuilder.unitizedDeltaString(false, true);
						var currentDelta:String = GlucoseHelper.calculateLatestDelta(false, true);
						
						//If user wants trend to be spoken...
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_TREND_ON) == "true")
						{
							//Format trend (slope)
							if (currentTrend == "NONE" || currentTrend == "NON COMPUTABLE")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trendnoncomputable');
							else if (currentTrend == "DoubleDown")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trenddoubledown');
							else if (currentTrend == "SingleDown")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trendsingledown');
							else if (currentTrend == "FortyFiveDown")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trendfortyfivedown');
							else if (currentTrend == "Flat")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trendflat');
							else if (currentTrend == "FortyFiveUp")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trendfortyfiveup');
							else if (currentTrend == "SingleUp")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trendsingleup');
							else if (currentTrend == "DoubleUp")
								currentTrend = ModelLocator.resourceManagerInstance.getString('texttospeech','trenddoubleup');
						}
						
						//If user wants delta to be spoken...
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_DELTA_ON) == "true")
						{	
							//Format current delta in case of anomalies
							if (currentDelta == "ERR" || currentDelta == "???")
								currentDelta = ModelLocator.resourceManagerInstance.getString('texttospeech','deltanoncomputable');
							
							if (currentDelta == "0.0" || currentDelta == "+0" || currentDelta == "+ 0" || currentDelta == "-0" || currentDelta == "- 0")
								currentDelta = "0";
							
							currentDelta = formatLocaleSpecific(currentDelta);
						}
						
						//Create output text
						var currentBgPrefix:String = ModelLocator.resourceManagerInstance.getString('texttospeech','currentglucose');
						var currentTrendPrefix:String = ModelLocator.resourceManagerInstance.getString('texttospeech','currenttrend');
						var currentDeltaPrefix:String = ModelLocator.resourceManagerInstance.getString('texttospeech','currentdelta');
						
						//Reset locale chain
						ModelLocator.resourceManagerInstance.localeChain = [CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_APP_LANGUAGE),"en_US"];
						
						//Glucose
						currentBgReadingOutput = currentBgPrefix + " " + currentBgReadingFormatted + ". ";
						
						//If user wants trend to be spoken...
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_TREND_ON) == "true")
							currentBgReadingOutput += currentTrendPrefix + " " + currentTrend + ". ";
						
						//If user wants delta to be spoken...
						if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_DELTA_ON) == "true")
							currentBgReadingOutput += currentDeltaPrefix + " " + currentDelta + ".";
				
						//Send output to TTS
						sayText(currentBgReadingOutput, speechLanguageCode);
					}
					else 
					{
						//not speaking the reading if it's older than 4,5 minutes
						//this can be the case for follower mode
						myTrace("in speakReading, timestamp of lastbgreading is older than 4.5 minutes");
					}
				}
			}
		}
		
		/**
		*Utility functions
		*/
		private static function myTrace(log:String):void 
		{
			Trace.myTrace("TextToSpeech.as", log);
		}
		
		/**
		*Event Handlers
		*/
		
		//Event fired when a new BG value is received from the transmitter
		private static function onBgReadingReceived(event:Event = null):void 
		{
			//if phone is muted and mute is not overriden by alert, then there's no need to suppress the speak bgreading even if an alarm is ongoing
			if (CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) == "true"
				&&
				!SpikeANE.isPlayingSound() 
				&&
				((!ModelLocator.phoneMuted) || LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE) == "true"))
			{	
				//Speak BG Reading
				speakReading();
			} 
		}
		//Event fired when app settings are changed
		private static function onSettingsChanged(event:SettingsServiceEvent):void 
		{
			//Update internal interval
			if (event.data == CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL) 
			{
				myTrace("Settings changed! Speak readings interval is now " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL));
				
				//Set new chosen interval
				speakInterval = int(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL));
				
				//Reset glucose readings
				receivedReadings = 0;
			}
			else if (event.data == CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) 
			{
				myTrace("Settings changed! Speak readings feature is now " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON));
			}
			else if (event.data == CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE) 
			{
				myTrace("Settings changed! Speak readings language is now " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE));
				
				//Set new language code in database
				speechLanguageCode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE);
			}
			else if (event.data == CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_ON) 
			{
				glucoseThresholdsActivated = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_ON) == "true";
			}
			else if (event.data == CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_HIGH || event.data == CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_LOW) 
			{
				glucoseThresholdHigh = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_HIGH));
				glucoseThresholdLow = Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_THRESHOLD_LOW));
			}
		}
		
		/**
		 * Stops the service entirely. Useful for database restores
		 */
		private static function onHaltExecution(e:SpikeEvent):void
		{
			myTrace("Stopping service...");
			
			stopService();
		}
		
		private static function stopService():void
		{
			CommonSettings.instance.removeEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
			TransmitterService.instance.removeEventListener(TransmitterServiceEvent.LAST_BGREADING_RECEIVED, onBgReadingReceived);
			NightscoutService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
			DexcomShareService.instance.removeEventListener(FollowerEvent.BG_READING_RECEIVED, onBgReadingReceived);
			
			myTrace("Service stopped!");
		}
	}
}