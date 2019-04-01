package model
{
	import com.distriqt.extension.notifications.Notifications;
	import com.distriqt.extension.notifications.builders.NotificationBuilder;
	import com.spikeapp.spike.airlibrary.SpikeANE;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	import database.CommonSettings;
	import database.Sensor;
	
	import services.MultipleMiaoMiaoService;
	import services.NotificationService;
	import services.TransmitterService;
	
	import ui.popups.AlertManager;
	
	import utils.Crc;
	import utils.Trace;
	import utils.libre.LibreAlarmReceiver;
	
	public class Tomato
	{
		[ResourceBundle("tomato")]
		
		private static var TOMATO_HEADER_LENGTH:int = 18;		
		private static var resendPakcetTimer:Timer;
		private static var resendPacketCounter:int = 0;
		private static const MAX_PACKET_RESEND_REQUESTS:int = 3;
		
		public function Tomato()
		{
		}
		
		private static function sendStartReadingCommandToMiaoMiao(event:Event):void {
			myTrace("in sendStartReadingCommandToMiaoMiao");
			SpikeANE.sendStartReadingCommmandToMiaoMia();
		}
		
		public static function decodeTomatoPacket(s_full_data:ByteArray):void {
			if (resendPakcetTimer != null) {
				if (resendPakcetTimer.running) {
					resendPakcetTimer.stop();
				}
				resendPakcetTimer = null;
			}
			
			s_full_data.position = 0;
			myTrace("in decodeTomatoPacket, received packet ");
			
			////
			var data:ByteArray = new ByteArray();
			data.endian = Endian.LITTLE_ENDIAN;
			s_full_data.position = TOMATO_HEADER_LENGTH;
			s_full_data.readBytes(data, 0, 344);
			var checksum_ok:Boolean = Crc.LibreCrc(data);
			myTrace("in decodeTomatoPacket,  checksum_ok = " + checksum_ok);
			
			if (!checksum_ok) {
				resendPacketCounter++;
				if (resendPacketCounter <= MAX_PACKET_RESEND_REQUESTS) {
					myTrace("in decodeTomatoPacket, checksum not ok. Start timer of 60 seconds to send start reading command");
					resendPakcetTimer = new Timer(60 * 1000, 1);
					resendPakcetTimer.addEventListener(TimerEvent.TIMER, sendStartReadingCommandToMiaoMiao);
					resendPakcetTimer.start();
				} else {
					myTrace("in decodeTomatoPacket, checksum not ok. Reached maximum number of retries, which is " + MAX_PACKET_RESEND_REQUESTS);
					resendPacketCounter = 0;
				}
				return;
			} else {
				resendPacketCounter = 0;
			}
			
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL, (new Number(getByteAt(s_full_data,13))).toString());
			
			s_full_data.position = 16;
			var temp:ByteArray = new ByteArray();s_full_data.readBytes(temp, 0,2);
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_HARDWARE, utils.UniqueId.bytesToHex(temp));
			
			s_full_data.position = 14;
			temp = new ByteArray();s_full_data.readBytes(temp, 0, 2);
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_FW,utils.UniqueId.bytesToHex(temp));
			myTrace("in decodeTomatoPacket, COMMON_SETTING_MIAOMIAO_HARDWARE = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_HARDWARE) + ", COMMON_SETTING_MIAOMIAO_FW = " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_FW) + ", battery level  " + CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_MIAOMIAO_BATTERY_LEVEL)); 
			
			data.position = 4;
			temp = new ByteArray();data.readBytes(temp, 0, 1);
			
			//read sensor status 
			//1 = sensor not yet started
			//2 = sensor in warmup phase
			//3 = sensor ready and working (up to 14 days and twelve hours)
			//4 = sensor expired (for the following twelve hours, FRAM data section content does not change any more)
			//5 = sensor shutdown
			//6 = sensor failure
			var sensorState:int = temp[0];
			if (sensorState == 1) {
				giveSensorWarning(ModelLocator.resourceManagerInstance.getString("tomato","libre_sensor_not_yet_started_title"), ModelLocator.resourceManagerInstance.getString("tomato","libre_sensor_not_yet_started_body"));
				myTrace("in decodeTomatoPacket, sensor not yet started status received (status = 1), generating notification, no further processing");
				return;
			} else if (sensorState == 6) {
				giveSensorWarning(ModelLocator.resourceManagerInstance.getString("tomato","libre_sensor_sensor_failure_title"), ModelLocator.resourceManagerInstance.getString("tomato","libre_sensor_sensor_failure_body"));
				myTrace("in decodeTomatoPacket, sensor failure received (status = 6), generating notification, no further processing");
				return;
			} 
			
			var mResult:Array = LibreAlarmReceiver.parseData("tomato", data);
			mResult = mResult.concat(MultipleMiaoMiaoService.intermediateCalibrationsList);
			MultipleMiaoMiaoService.resetIntermediateCalibrationsList();
			mResult.sortOn(["realDate"], Array.NUMERIC);

			//LibreAlarmReceiver.CalculateFromDataTransferObject(mResult)
			if (LibreAlarmReceiver.CalculateFromDataTransferObject(mResult)) {
				TransmitterService.dispatchLastBgReadingReceivedEvent();
			}
		}
		
		public static function receivedSensorChangedFromMiaoMiao():void {
			myTrace("in decodeTomatoPacket, received sensor change from miaomioa. Confirming sensor change and Stopping the sensor"); 
			SpikeANE.confirmSensorChangeMiaoMiao();
			Sensor.stopSensor();
			CommonSettings.setCommonSetting(CommonSettings.COMMON_SETTING_FSL_SENSOR_AGE, "0");
		}
		
		
		private static function giveSensorWarning(title:String, body:String):void {
			if (SpikeANE.appIsInForeground()) {
				AlertManager.showSimpleAlert
					(
						ModelLocator.resourceManagerInstance.getString("transmitterservice","warning"),
						title + " " + body
					);
			} else {
				var notificationBuilder:NotificationBuilder = new NotificationBuilder()
					.setId(NotificationService.ID_FOR_LIBRE_SENSOR_14DAYS)
					.setAlert(ModelLocator.resourceManagerInstance.getString("transmitterservice","warning"))
					.setTitle(title)
					.setBody(body)
					.enableVibration(false)
					.setSound("");
				Notifications.service.notify(notificationBuilder.build());
			}
		}
		
		private static function myTrace(log:String):void {
			Trace.myTrace("Tomato.as", log);
		}
		
		private static function getByteAt(buffer:ByteArray, position:int):int {
			buffer.position = position;
			return buffer.readByte();
		}
	}
}