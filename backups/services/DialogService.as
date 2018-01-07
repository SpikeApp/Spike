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
 
 */
package services
{
	import com.distriqt.extension.dialog.Dialog;
	import com.distriqt.extension.dialog.DialogView;
	import com.distriqt.extension.dialog.builders.AlertBuilder;
	import com.distriqt.extension.dialog.events.DialogViewEvent;
	import com.distriqt.extension.dialog.objects.DialogAction;
	import com.distriqt.extension.notifications.Notifications;
	import com.freshplanet.ane.AirBackgroundFetch.BackgroundFetch;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	
	import spark.formatters.DateTimeFormatter;
	
	import databaseclasses.BlueToothDevice;
	
	import distriqtkey.DistriqtKey;
	
	import events.BlueToothServiceEvent;
	import events.DialogServiceEvent;
	
	import model.ModelLocator;
	
	/**
	 * Will process all dialogs - goal is that any other service that wants to interact with the user will use this service<br> 
	 * Reason for using this service is because some service may be generating requests to open dialogs, while a dialog is already open<br>
	 * This service is going to keep track if there's already a dialog open, in whcih case it's added to a queue.
	 * 
	 */
	public class DialogService extends EventDispatcher
	{
		[ResourceBundle("dialogservice")]
		
		private static var _instance:DialogService = new DialogService();
		
		public static function get instance():DialogService
		{
			return _instance;
		}
		
		private static var initialStart:Boolean = true;
		private static var dialogViews:ArrayCollection;
		private static var dialogViewsMaxDurations:ArrayCollection;
		/**
		 * the dialogview that is currently open, null if none is open 
		 */
		private static var openDialogView:DialogView;
		private static var maxDurationTimer:Timer;
		
		private static var _isInitiated:Boolean = false;
		
		public static function get isInitiated():Boolean
		{
			return _isInitiated;
		}
		
		
		public function DialogService()
		{
			if (_instance != null) {
				throw new Error("DialogService class  constructor can not be used");	
			}
		}
		
		public static function init(stage:Stage):void {
			if (!initialStart)
				return;
			else
				initialStart = false;
			
			Dialog.init(DistriqtKey.distriqtKey);
			Dialog.service.root = stage;
			dialogViews = new ArrayCollection();
			dialogViewsMaxDurations = new ArrayCollection();
			openDialogView = null;
			
			BluetoothService.instance.addEventListener(BlueToothServiceEvent.DEVICE_NOT_PAIRED, deviceNotPaired);
			
			_isInitiated = true;
			_instance.dispatchEvent(new DialogServiceEvent(DialogServiceEvent.DIALOG_SERVICE_INITIATED_EVENT));
		}
		
		private static function deviceNotPaired(event:Event):void {
			if (BackgroundFetch.appIsInForeground())
				return;
			
			if (BlueToothDevice.isBluKon())
				return;//blukon keeps on trying to connect, there's always a request to pair, no need to give additional comments
			
			var titleText:String = ModelLocator.resourceManagerInstance.getString("dialogservice","device_not_paired_dialog_title");
			var bodyText:String = ModelLocator.resourceManagerInstance.getString("dialogservice","device_not_paired_dialog_body");
			
			var dateFormatter:DateTimeFormatter = new DateTimeFormatter();
			dateFormatter.dateTimePattern = "HH:mm:ss";
			dateFormatter.useUTC = false;
			var now:Date = new Date();
			bodyText = bodyText.replace('$time', dateFormatter.format(new Date()));
			
			var alert:DialogView = Dialog.service.create(
				new AlertBuilder()
				.setTitle(titleText)
				.setMessage(bodyText)
				.addOption("Ok", DialogAction.STYLE_POSITIVE, 0)
				.build()
			);
			alert.addEventListener(DialogViewEvent.CLOSED, deviceNotPairedDialogClosed);
			DialogService.addDialog(alert, 240);
		}
		
		private static function deviceNotPairedDialogClosed(event:Event):void {
			Notifications.service.cancel(NotificationService.ID_FOR_DEVICE_NOT_PAIRED);
		}
		
		/**
		 * if maxDurationInSeconds specified then the dialog will be closed after the specified time
		 */
		public static function addDialog(dialogView:DialogView, maxDurationInSeconds:Number = Number.NaN):void {
			if (openDialogView != null) {
				dialogViews.addItem(dialogView);
				dialogViewsMaxDurations.addItem(maxDurationInSeconds);
				//dialog will be processed as soon as the dialog that is currently open is closed again
			} else {
				processNewDialog(dialogView, maxDurationInSeconds);
			}
		}
		
		private static function maxDurationReached(event:Event = null):void {
			openDialogView.dispose();
			openDialogView = null;
			if (dialogViews.length > 0) {
				var dialogViewToShow:DialogView = dialogViews.getItemAt(0) as DialogView;
				dialogViews.removeItemAt(0);
				var maxDuration:Number = dialogViewsMaxDurations.getItemAt(0) as Number;
				dialogViewsMaxDurations.removeItemAt(0);
				processNewDialog(dialogViewToShow, maxDuration);
			}
		}
		
		private static function processNewDialog(dialogView:DialogView, maxDurationInSeconds:Number):void {
			dialogView.addEventListener(DialogViewEvent.CLOSED, dialogViewClosed);
			//dialogView.addEventListener(DialogViewEvent.CANCELLED, dialogViewClosed);
			dialogView.show();
			openDialogView = dialogView;
			if (!isNaN(maxDurationInSeconds)) {
				if (maxDurationInSeconds > 0) {
					disableMaxDurationTimer();
					maxDurationTimer = new Timer(maxDurationInSeconds * 1000, 1);
					maxDurationTimer.addEventListener(TimerEvent.TIMER, maxDurationReached);
					maxDurationTimer.start();
				}
			}
		}
		
		private static function dialogViewClosed(event:DialogViewEvent):void {
			disableMaxDurationTimer();
			
			var alert:DialogView = DialogView(event.currentTarget);
			alert.dispose();
			openDialogView = null;
			if (dialogViews.length > 0) {
				var dialogViewToShow:DialogView = dialogViews.getItemAt(0) as DialogView;
				dialogViews.removeItemAt(0);
				var maxDuration:Number = dialogViewsMaxDurations.getItemAt(0) as Number;
				dialogViewsMaxDurations.removeItemAt(0);
				processNewDialog(dialogViewToShow, maxDuration);
			}
		}
		
		private static function disableMaxDurationTimer():void {
			if (maxDurationTimer != null) {
				maxDurationTimer.stop();
				maxDurationTimer = null;
			}
		}
		
		/**
		 * if maxDurationInSeconds specified then the dialog will be closed after the specified time
		 */
		public static function openSimpleDialog(title:String, message:String, maxDurationInSeconds:Number = Number.NaN):void {
			var alert:DialogView = Dialog.service.create(
				new AlertBuilder()
				.setTitle(title)
				.setMessage(message)
				.addOption("Ok", DialogAction.STYLE_POSITIVE, 0)
				.build()
			);
			DialogService.addDialog(alert, maxDurationInSeconds);
		}
	}
}