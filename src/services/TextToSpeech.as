/**
 Copyright (C) 2016  Johan Degraeve
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/gpl.txt>.
 
 Author: Miguel Kennedy
 
 */

package services
{
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	
	import Utilities.BgGraphBuilder;
	import Utilities.Trace;
	
	import databaseclasses.BgReading;
	import databaseclasses.CommonSettings;
	import databaseclasses.LocalSettings;
	
	import events.SettingsServiceEvent;
	import events.TransmitterServiceEvent;
	
	import model.ModelLocator;
	
	import services.TransmitterService;
	
	[ResourceBundle("texttospeech")]
	
	/**
	 * Class responsible for managing text to speak functionallity. 
	 */
	public class TextToSpeech
	{
		//Define variables
		private static var initiated:Boolean = false;
		private static var lockEnabled:Boolean = false;
		private static var speakInterval:int = 1;
		private static var receivedReadings:int = 0;
		private static var speechLanguageCode:String;

		public function TextToSpeech()
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
				
				//Register event listener for changed settings
				CommonSettings.instance.addEventListener(SettingsServiceEvent.SETTING_CHANGED, onSettingsChanged);
				
				//Register event listener for new blood glucose readings
				TransmitterService.instance.addEventListener(TransmitterServiceEvent.BGREADING_EVENT, onBgReadingReceived);
				
				//Set speech language
				speechLanguageCode = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE);
				
				myTrace("TextToSpeech started. Enabled: " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_ON) + " | Interval: " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEAK_READINGS_INTERVAL) + " | Language: " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_SPEECH_LANGUAGE));
			}
		}
		
		/**
		*Functionality functions
		*/
		
		public static function sayText(text:String, language:String = "en-US"):void 
		{
			myTrace("Text to speak: " + text);
			
			//Start Text To Speech
			BackgroundFetch.say(text, language);		
		}
		
		private static function speakReading():void
		{
			//Update received readings counter
			receivedReadings += 1;
			
			//Only speak blood glucose reading if app is in the background or phone is locked
			if (((receivedReadings - 1) % speakInterval == 0))
			{	
				//Get current bg reading and format it 
				var currentBgReadingList:ArrayCollection = BgReading.latestBySize(1);
				if (currentBgReadingList.length > 0) 
				
				{
					//Speech Output
					var currentBgReadingOutput:String;
					
					//Get current glucose
					var currentBgReading:BgReading = currentBgReadingList.getItemAt(0) as BgReading;
					var currentBgReadingFormatted:String = BgGraphBuilder.unitizedString(currentBgReading.calculatedValue, CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true");
						
					//Get trend (slope)
					var currentTrend:String = currentBgReading.slopeName() as String;
						
					//Get current delta
					var currentDelta:String = BgGraphBuilder.unitizedDeltaString(false, true);
					
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
						
						if (currentDelta == "0.0" || currentDelta == "+0" || currentDelta == "-0")
							currentDelta = "0";
					}
					
					//Create output text
					var currentBgPrefix:String = ModelLocator.resourceManagerInstance.getString('texttospeech','currentglucose');
					var currentTrendPrefix:String = ModelLocator.resourceManagerInstance.getString('texttospeech','currenttrend');
					var currentDeltaPrefix:String = ModelLocator.resourceManagerInstance.getString('texttospeech','currentdelta');
					
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
					(	!BackgroundFetch.isPlayingSound() 
						|| 
						(ModelLocator.phoneMuted && !(LocalSettings.getLocalSetting(LocalSettings.LOCAL_SETTING_OVERRIDE_MUTE) == "true"))
					)
			   ) 
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
		}
	}
}