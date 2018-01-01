package services
{
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.errors.IllegalOperationError;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	
	import feathers.controls.Alert;
	import feathers.controls.Callout;
	import feathers.controls.TextCallout;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.layout.RelativePosition;
	
	import model.ModelLocator;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	
	import ui.AppInterface;
	
	import utils.AlertManager;
	import utils.Constants;
	
	[ResourceBundle("tutorialservice")]
	[ResourceBundle("globaltranslations")]

	public class TutorialService extends EventDispatcher
	{
		/* Constants */
		public static const TUTORIAL_FINISHED:String = "tutorialFinished";
		
		/* Objects */
		public static var instance:TutorialService = new TutorialService();
		
		/* Display Objects */
		private static var firstStepCallout:TextCallout;
		private static var secondStepCallout:TextCallout;
		private static var thirdStepCallout:TextCallout;
		private static var fourthStepCallout:TextCallout;
		private static var fifthStepCallout:TextCallout;
		private static var sixthStepCallout:TextCallout;
		private static var seventhStepCallout:TextCallout;
		private static var eighthStepCallout:TextCallout;
		private static var ninethStepCallout:TextCallout;
		private static var tenthStepCallout:TextCallout;
		private static var calloutLocationHelper:Sprite;
		
		/* Internal Variables */
		public static var isActive:Boolean = false;
		public static var firstStepActive:Boolean = false;
		public static var secondStepActive:Boolean = false;
		public static var thirdStepActive:Boolean = false;
		public static var fourthStepActive:Boolean = false;
		public static var fifthStepActive:Boolean = false;
		public static var sixthStepActive:Boolean = false;
		public static var seventhStepActive:Boolean = false;
		public static var eighthStepActive:Boolean = false;
		public static var ninethStepActive:Boolean = false;
		public static var tenthStepActive:Boolean = false;
		
		public function TutorialService()
		{
			//Don't allow class to be instantiated
			if (instance != null)
				throw new IllegalOperationError("TutorialService class is not meant to be instantiated!");	
		}
		
		public static function init():void
		{
			/* Ask user if he/she wants to use the tutorial */
			var tutorialAlert:Alert = AlertManager.showActionAlert
			(
				ModelLocator.resourceManagerInstance.getString('tutorialservice','alert_title'),
				ModelLocator.resourceManagerInstance.getString('tutorialservice','alert_message'),
				Number.NaN,
				[
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','no_uppercase') },
					{ label: ModelLocator.resourceManagerInstance.getString('globaltranslations','yes_uppercase'), triggered:startTutorial }
				]
			)
		}
		
		private static function startTutorial(e:Event):void
		{
			/* Notify that the tutorial has started */
			isActive = true;
			
			/* Init Objects */
			calloutLocationHelper = new Sprite();
			Starling.current.stage.addChild(calloutLocationHelper);
			
			/* Start Tutorial */
			Starling.juggler.delayCall( firstStep, .2);
		}
		
		private static function firstStep():void
		{
			firstStepActive = true;
			
			firstStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','first_step_message'), Constants.mainMenuButton, null, false);
			firstStepCallout.textRendererFactory = calloutTextRenderer;
			firstStepCallout.pivotX += 5;
			firstStepCallout.pivotY -= 12;
			
			AppInterface.instance.drawers.addEventListener(Event.OPEN, onMainMenuOpenedFirstStep);
			
			Starling.juggler.delayCall( closeCallout, 10, firstStepCallout );
		}
		
		private static function onMainMenuOpenedFirstStep(e:Event):void
		{
			AppInterface.instance.drawers.removeEventListener(Event.OPEN, onMainMenuOpenedFirstStep);
			
			closeCallout(firstStepCallout);
			
			Starling.juggler.delayCall( secondStep, .3 );
		}
		
		private static function secondStep():void
		{
			firstStepActive = false;
			secondStepActive = true;
			
			calloutLocationHelper.x = 85;
			calloutLocationHelper.y = 205;
			
			secondStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','second_step_message'), calloutLocationHelper, null, false);
			secondStepCallout.pivotX += 5;
			
			Starling.juggler.delayCall( closeCallout, 4, secondStepCallout );
		}
		
		public static function thirdStep():void
		{
			secondStepActive = false;
			thirdStepActive = true;
			
			calloutLocationHelper.x = 25;
			calloutLocationHelper.y = 105;
			
			thirdStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','third_step_message'), calloutLocationHelper, null, false);
			
			Starling.juggler.delayCall( closeCallout, 4, thirdStepCallout );
		}		
		
		public static function fourthStep():void
		{
			thirdStepActive = false;
			fourthStepActive = true;
			
			calloutLocationHelper.x = Constants.stageWidth / 2;
			calloutLocationHelper.y = 305;
			
			fourthStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','fourth_step_message'), calloutLocationHelper, null, false);
			fourthStepCallout.textRendererFactory = calloutTextRenderer;
			
			Starling.juggler.delayCall( closeCallout, 12, fourthStepCallout );
		}
		
		public static function fifthStep():void
		{
			fourthStepActive = false;
			fifthStepActive = true;
			
			calloutLocationHelper.x = 25;
			calloutLocationHelper.y = 155;
			
			fifthStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','fifth_step_message'), calloutLocationHelper, null, false);
			
			Starling.juggler.delayCall( closeCallout, 7, fifthStepCallout );
		}
		
		public static function sixthStep():void
		{
			fifthStepActive = false;
			sixthStepActive = true;
			
			calloutLocationHelper.x = Constants.stageWidth / 2;
			calloutLocationHelper.y = 205;
			
			sixthStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','sixth_step_message'), calloutLocationHelper, null, false);
			sixthStepCallout.textRendererFactory = calloutTextRenderer;
			
			Starling.juggler.delayCall( closeCallout, 16, sixthStepCallout );
		}
		
		public static function seventhStep():void
		{
			sixthStepActive = false;
			seventhStepActive = true;
			
			calloutLocationHelper.x = 0;
			calloutLocationHelper.y = Constants.stageHeight / 2;
			
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			
			seventhStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','seventh_step_message'), calloutLocationHelper, new <String>[RelativePosition.RIGHT], false);
			seventhStepCallout.textRendererFactory = calloutTextRenderer;
			
			Starling.juggler.delayCall( closeCallout, 50, seventhStepCallout );
			
			AppInterface.instance.drawers.addEventListener(Event.OPEN, onMainMenuOpenedEightStep);
		}
		
		private static function onMainMenuOpenedEightStep(e:Event):void
		{
			AppInterface.instance.drawers.removeEventListener(Event.OPEN, onMainMenuOpenedEightStep);
			
			seventhStepActive = false;
			eighthStepActive = true;
			
			calloutLocationHelper.x = 85;
			calloutLocationHelper.y = 105;
			
			eighthStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','eighth_step_message'), calloutLocationHelper, null, false);
			eighthStepCallout.pivotX += 5;
			
			Starling.juggler.delayCall( closeCallout, 4, eighthStepCallout );
		}
		
		public static function ninethStep():void
		{
			eighthStepActive = false;
			ninethStepActive = true;
			
			calloutLocationHelper.x = Constants.stageWidth - 55;
			calloutLocationHelper.y = 265;
			
			ninethStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','nineth_step_message'), calloutLocationHelper, null, false);
			
			Starling.juggler.delayCall( closeCallout, 4, ninethStepCallout );
		}
		
		public static function tenthStep(target:DisplayObject):void
		{
			ninethStepActive = false;
			tenthStepActive = true;
			
			tenthStepCallout = TextCallout.show(ModelLocator.resourceManagerInstance.getString('tutorialservice','tenth_step_message'), target, new <String>[RelativePosition.TOP], false);
			tenthStepCallout.textRendererFactory = calloutTextRenderer;
			tenthStepCallout.addEventListener(Event.CLOSE, onTutorialFinished);
			
			Starling.juggler.delayCall( closeCallout, 35, tenthStepCallout );
		}
		
		private static function onTutorialFinished():void
		{
			instance.dispatchEventWith(TUTORIAL_FINISHED);
			
			/* Clean Up */
			tenthStepActive = false;
			isActive = false;
			
			Starling.current.stage.removeChild(calloutLocationHelper);
			calloutLocationHelper.dispose();
			calloutLocationHelper = null;
			
			instance = null;
		}
		
		/**
		 * Utility
		 */
		/* Text renderer for the callout message */
		private static function calloutTextRenderer():ITextRenderer
		{
			var messageRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
			messageRenderer.textJustifier = new SpaceJustifier( "en", LineJustification.ALL_BUT_MANDATORY_BREAK);
			
			return messageRenderer;
		};
		
		/* Utility function to close and dispose used callouts */
		private static function closeCallout(callout:Callout):void
		{
			if(callout != null)
			{
				callout.close();
				callout.dispose();
				callout = null;
			}
		}
	}
}