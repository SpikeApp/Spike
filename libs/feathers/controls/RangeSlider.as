package feathers.controls
{
	import feathers.core.FeathersControl;
	import feathers.core.IFocusDisplayObject;
	import feathers.core.PropertyProxy;
	import feathers.events.FeathersEventType;
	import feathers.utils.math.roundToNearest;
	import flash.geom.Point;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	/**
	 * ...
	 * @author Serg de Adelantado
	 */
	
	/**
	 * Dispatched when the slider's values changes.
	 *
	 * @eventType starling.events.Event.CHANGE
	 */
	[Event(name="change",type="starling.events.Event")]
	
	/**
	 * Dispatched when the user starts dragging one of the slider's thumbs.
	 *
	 * @eventType feathers.events.FeathersEventType.BEGIN_INTERACTION
	 */
	[Event(name="beginInteraction",type="starling.events.Event")]
	
	/**
	 * Dispatched when the user stops dragging one of the slider's thumbs.
	 *
	 * @eventType feathers.events.FeathersEventType.END_INTERACTION
	 */
	[Event(name="endInteraction",type="starling.events.Event")]
	
	public class RangeSlider extends FeathersControl implements IFocusDisplayObject
	{
		public static const SLIDER_MODE_FREE:uint = 0;
		public static const SLIDER_MODE_PUSH:uint = 1;
		public static const SLIDER_MODE_LOCK:uint = 2;
		
		public static const DEFAULT_CHILD_NAME_BACKGROUND:String = "feathers-range-slider-background";
		public static const DEFAULT_CHILD_NAME_MIDDLE_THUMB:String = "feathers-range-slider-middle-thumb";
		public static const DEFAULT_CHILD_NAME_MINIMUM_THUMB:String = "feathers-range-slider-minimum-thumb";
		public static const DEFAULT_CHILD_NAME_MAXIMUM_THUMB:String = "feathers-range-slider-maximum-thumb";
		
		protected static const INVALIDATION_FLAG_BACKGROUND_FACTORY:String = "backgroundFactory";
		protected static const INVALIDATION_FLAG_MIDDLE_THUMB_FACTORY:String = "middleThumbFactory";
		protected static const INVALIDATION_FLAG_MINIMUM_THUMB_FACTORY:String = "mimiumThumbFactory";
		protected static const INVALIDATION_FLAG_MAXIMUM_THUMB_FACTORY:String = "maximumThumbFactory";
		
		protected static const HELPER_POINT:Point = new Point();
		
		protected static function defaultThumbFactory():Button
		{
			return new Button();
		}
		
		protected static function defaultBackgroundFactory():Button
		{
			return new Button();
		}
		
		protected static function defaultMiddleThumbFactory():Button
		{
			return new Button();
		}
		
		protected var _mode:uint;
		protected var _minimum:Number;
		protected var _maximum:Number;
		protected var _rangeMinimum:Number;
		protected var _rangeMaximum:Number;
		protected var _rangeMiddle:Number;
		protected var _rangeMinStored:Number;
		protected var _rangeMaxStored:Number;
		protected var _step:Number;
		protected var _isDragging:Boolean;
		protected var _liveDragging:Boolean;
		protected var _placeLastThumbOnTop:Boolean;
		protected var _thumbsOverlapping:Boolean;
		
		protected var _minimumPadding:Number;
		protected var _maximumPadding:Number;
		
		protected var _minimumTouchPointID:int;
		protected var _maximumTouchPointID:int;
		protected var _middleTouchPointID:int;
		protected var _minimumThumbStart:Point;
		protected var _maximumThumbStart:Point;
		protected var _middleThumbStart:Point;
		protected var _minimumTouchStart:Point;
		protected var _maximumTouchStart:Point;
		protected var _middleTouchStart:Point;		
		
		protected var _backgroundFactory:Function;
		protected var _middleThumbFactory:Function;
		protected var _minimumThumbFactory:Function;
		protected var _maximumThumbFactory:Function;
		
		protected var _background:Button;
		protected var _middleThumb:Button;
		protected var _minimumThumb:Button;
		protected var _maximumThumb:Button;
		
		protected var _backgroundOriginalWidth:Number = NaN;
		protected var _backgroundOriginalHeight:Number = NaN;
		
		protected var _backgroundProperties:PropertyProxy;
		
		protected var _backgroundName:String = DEFAULT_CHILD_NAME_BACKGROUND;
		protected var _middleThumbName:String = DEFAULT_CHILD_NAME_MIDDLE_THUMB;
		protected var _minimumThumbName:String = DEFAULT_CHILD_NAME_MINIMUM_THUMB;
		protected var _maximumThumbName:String = DEFAULT_CHILD_NAME_MAXIMUM_THUMB;
		
		protected var _customBackgroundName:String;
		protected var _customMiddleThumbName:String;
		protected var _customMinimumThumbName:String;
		protected var _customMaximumThumbName:String;
		
		public function RangeSlider()
		{
			super();
			_minimumThumbStart = new Point();
			_maximumThumbStart = new Point();
			_minimumTouchStart = new Point();
			_maximumTouchStart = new Point();
			_middleTouchStart = new Point();
			_middleThumbStart = new Point();
			_minimumPadding = 0;
			_maximumPadding = 0;
			_rangeMinimum = 0;
			_rangeMaximum = 0;
			_rangeMiddle = 0;
			_minimum = 0;
			_maximum = 0;
			_step = 0;
			_minimumTouchPointID = -1;
			_maximumTouchPointID = -1;
			_middleTouchPointID = -1;
			_mode = SLIDER_MODE_FREE;
			_placeLastThumbOnTop = true;
			_liveDragging = true;
			_thumbsOverlapping = false;
		}
		
		override protected function draw():void
		{
			const stylesInvalid:Boolean = isInvalid(INVALIDATION_FLAG_STYLES);
			const backgroundInvalid:Boolean = isInvalid(INVALIDATION_FLAG_BACKGROUND_FACTORY);
			const rangeInvalid:Boolean = isInvalid(INVALIDATION_FLAG_MIDDLE_THUMB_FACTORY);
			const thumbMinimumFactoryInvalid:Boolean = isInvalid(INVALIDATION_FLAG_MINIMUM_THUMB_FACTORY);
			const thumbMaximumFactoryInvalid:Boolean = isInvalid(INVALIDATION_FLAG_MAXIMUM_THUMB_FACTORY);
			
			if (backgroundInvalid)
				_background = createComponent(_background, _backgroundFactory, _backgroundName, _customBackgroundName);
			
			if (rangeInvalid)
			{
				_middleThumb = createComponent(_middleThumb, _middleThumbFactory, _middleThumbName, _customMiddleThumbName);
				_middleThumb.addEventListener(TouchEvent.TOUCH, middle_touchHandler);
			}				
			
			if (thumbMaximumFactoryInvalid)
			{
				_maximumThumb = createComponent(_maximumThumb, _maximumThumbFactory, _maximumThumbName, _customMaximumThumbName);
				_maximumThumb.addEventListener(TouchEvent.TOUCH, thumb_touchHandler);
			}
			
			if (thumbMinimumFactoryInvalid)
			{
				_minimumThumb = createComponent(_minimumThumb, _minimumThumbFactory, _minimumThumbName, _customMinimumThumbName);
				_minimumThumb.addEventListener(TouchEvent.TOUCH, thumb_touchHandler);
			}
			
			if (backgroundInvalid || stylesInvalid)
				refreshBackgroundStyles();
			
			autoSizeIfNeeded();
			
			layoutChildren();
		}

		protected function createComponent(thumb:Button, thumbFactory:Function, defaultName:String, customName:String):Button
		{
			if (thumb)
			{
				thumb.removeFromParent(true);
				thumb = null;
			}
			const factory:Function = thumbFactory != null ? thumbFactory : defaultThumbFactory;
			const thumbName:String = customName != null ? customName : defaultName;
			thumb = Button(factory());
			//thumb.nameList.add(thumbName);
			thumb.keepDownStateOnRollOut = true;			
			addChild(thumb);
			return thumb;
		}
		
		override public function get isEnabled():Boolean
		{
			var result:Boolean = super.isEnabled;
			if (!result)
			{
				_minimumTouchPointID = -1;
				_maximumTouchPointID = -1;
				_middleTouchPointID = -1;
			}
			return result;
		}
		
		private function thumb_touchHandler(e:TouchEvent):void
		{
			if (!isEnabled)
				return;
			
			var touch:Touch;
			var thumb:Button = Button(e.target);
			
			var touchPointID:int;
			if (thumb == _minimumThumb)
				touchPointID = _minimumTouchPointID;
			else
				touchPointID = _maximumTouchPointID;
			
			if (touchPointID >= 0)
			{
				touch = e.getTouch(thumb, null, touchPointID);
				if (!touch)
					return;
				
				if (touch.phase == TouchPhase.MOVED)
				{
					touch.getLocation(this, HELPER_POINT);
					if (thumb == _minimumThumb)
						rangeMinimum = minimumThumbValue(HELPER_POINT);
					else
						rangeMaximum = maximumThumbValue(HELPER_POINT);
				}
				else if (touch.phase == TouchPhase.ENDED)
				{
					if (thumb == _minimumThumb)
						_minimumTouchPointID = -1;
					else
						_maximumTouchPointID = -1;
					_isDragging = false;
					dispatchEventWith(FeathersEventType.END_INTERACTION);
					
					if (!_liveDragging)
						dispatchEventWith(Event.CHANGE);
				}
			}
			else
			{
				touch = e.getTouch(thumb, TouchPhase.BEGAN);
				if (!touch)
					return;
				
				_middleTouchPointID = -1;
				
				if (_placeLastThumbOnTop)
					addChild(thumb);
				
				touch.getLocation(this, HELPER_POINT);
				if (thumb == _minimumThumb)
				{
					_minimumTouchPointID = touch.id;
					_minimumTouchStart.setTo(HELPER_POINT.x, HELPER_POINT.y);
					_minimumThumbStart.setTo(thumb.x, thumb.y);
				}
				else if (thumb == _maximumThumb)
				{
					_maximumTouchPointID = touch.id;
					_maximumTouchStart.setTo(HELPER_POINT.x, HELPER_POINT.y);
					_maximumThumbStart.setTo(thumb.x, thumb.y);
				}
				_isDragging = true;
				
				dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
			}
		}
		
		private function middle_touchHandler(e:TouchEvent):void
		{
			var touch:Touch;
			var thumb:Button = _middleThumb;
			if (_middleTouchPointID >= 0)
			{
				touch = e.getTouch(thumb, null, _middleTouchPointID);
				if (!touch)
					return;
				
				if (touch.phase == TouchPhase.MOVED)
				{
					touch.getLocation(this, HELPER_POINT);
					calcRangeValues(HELPER_POINT);
				}
				else if (touch.phase == TouchPhase.ENDED)
				{
					_middleTouchPointID = -1;
					_isDragging = false;
					dispatchEventWith(FeathersEventType.END_INTERACTION);
					
					if (!_liveDragging)
						dispatchEventWith(Event.CHANGE);
				}
			}
			else
			{
				touch = e.getTouch(thumb, TouchPhase.BEGAN);
				if (!touch)
					return;
				
				_minimumTouchPointID = -1;
				_maximumTouchPointID = -1;
				
				_rangeMaxStored = valueMaximum;
				_rangeMinStored = valueMinimum;
				
				touch.getLocation(this, HELPER_POINT);
				_middleTouchPointID = touch.id;
				_middleTouchStart.setTo(HELPER_POINT.x, HELPER_POINT.y);
				_middleThumbStart.setTo(thumb.x, thumb.y);
				_isDragging = true;
				dispatchEventWith(FeathersEventType.BEGIN_INTERACTION);
			}
		}
		
		private function calcRangeValues(location:Point):void
		{
			const canScroll:Boolean = _rangeMaxStored != _maximum || _rangeMinStored != _minimum;			
			if (canScroll)
			{
				const commonWidth:Number = _minimumThumb.width + _maximumThumb.width + _middleThumb.width;
				const trackScrollableWidth:Number = actualWidth - commonWidth - _minimumPadding - _maximumPadding;			
				var xOffset:Number = location.x - _middleTouchStart.x - _minimumPadding - _minimumThumb.width;
				var xPosition:Number = Math.min(Math.max(0, _middleThumbStart.x + xOffset), trackScrollableWidth);
				var percentage:Number = xPosition / trackScrollableWidth;
				
				var rangeValue:Number = _rangeMaxStored - _rangeMinStored;
				var newMaximum:Number = _maximum - rangeValue;
				
				rangeMinimum = _minimum + percentage * (newMaximum - _minimum);
				rangeMaximum = _minimum + percentage * (newMaximum - _minimum) + rangeValue;
				invalidate(INVALIDATION_FLAG_DATA);
			}			
		}
		
		protected function minimumThumbValue(location:Point):Number
		{
			const trackScrollableWidth:Number = actualWidth - _minimumThumb.width - _minimumPadding - _maximumPadding;
			var overlappingOffset:Number = 0;
			if (!_thumbsOverlapping && _mode != SLIDER_MODE_FREE)
				overlappingOffset = location.x / (trackScrollableWidth - _maximumThumb.width) * _maximumThumb.width;
			const xOffset:Number = location.x - _minimumTouchStart.x - _minimumPadding + overlappingOffset;
			const xPosition:Number = Math.min(Math.max(0, _minimumThumbStart.x + xOffset), trackScrollableWidth);
			const percentage:Number = xPosition / trackScrollableWidth;
			var value:Number = _minimum + percentage * (_maximum - _minimum);
			
			if (_mode == SLIDER_MODE_LOCK)
			{
				if (value > _rangeMaximum)
					value = _rangeMaximum;
			}
			else if (_mode == SLIDER_MODE_PUSH)
			{
				if (value > _rangeMaximum)
					rangeMaximum = value;
			}
			return value;
		}
		
		protected function maximumThumbValue(location:Point):Number
		{
			const trackScrollableWidth:Number = actualWidth - _maximumThumb.width - _minimumPadding - _maximumPadding;
			var overlappingOffset:Number = 0;
			if (!_thumbsOverlapping && _mode != SLIDER_MODE_FREE)
				overlappingOffset = (trackScrollableWidth - location.x + _maximumThumb.width) / trackScrollableWidth * _minimumThumb.width;
			const xOffset:Number = location.x - _maximumTouchStart.x - _minimumPadding - overlappingOffset;
			const xPosition:Number = Math.min(Math.max(0, _maximumThumbStart.x + xOffset), trackScrollableWidth);
			const percentage:Number = xPosition / trackScrollableWidth;
			var value:Number = _minimum + percentage * (_maximum - _minimum);
			
			if (_mode == SLIDER_MODE_LOCK)
			{
				if (value < _rangeMinimum)
					value = _rangeMinimum;
			}
			else if (_mode == SLIDER_MODE_PUSH)
			{
				if (value < _rangeMinimum)
					rangeMinimum = value;
			}
			return value;
		}
		
		//{ Layout
		
		protected function layoutChildren():void
		{
			if (_background)
			{
				_background.width = actualWidth;
				_background.height = actualHeight;
			}
			if (_middleTouchPointID < 0)
			{
				layoutThumbs();
				if (_middleThumb)
				{
					if (_minimumThumb.x < _maximumThumb.x)
					{
						_middleThumb.x = _minimumThumb.x + _minimumThumb.width;
						_middleThumb.width = _maximumThumb.x - _minimumThumb.x - _minimumThumb.width;
					}
					else
					{
						_middleThumb.x = _maximumThumb.x + _maximumThumb.width;
						_middleThumb.width = _minimumThumb.x - _maximumThumb.x - _maximumThumb.width;
					}
				}
			}
			else
			{
				layoutMiddleThumb();
			}			
			_middleThumb.y = (actualHeight - _middleThumb.height) / 2;
			_middleThumb.height = _background.height;		
		}
		
		private function layoutMiddleThumb():void
		{
			var commonWidth:Number = _minimumThumb.width + _maximumThumb.width + _middleThumb.width;
			var scrollableWidth:Number = actualWidth - commonWidth - _minimumPadding - _maximumPadding;
			var padding:Number = _minimumPadding + _minimumThumb.width;
			var diff:Number = _rangeMaxStored - _rangeMinStored;
			var max:Number = _maximum - diff;
			_middleThumb.x = padding + (scrollableWidth * (rangeMinimum - _minimum) / (max - _minimum));
			_maximumThumb.x = _middleThumb.x + _middleThumb.width;
			_minimumThumb.x = _middleThumb.x - _minimumThumb.width;
		}
		
		protected function layoutThumbs():void
		{			
			var scrollableWidth:Number = actualWidth - _minimumThumb.width - _minimumPadding - _maximumPadding;
			if (!_thumbsOverlapping && _mode != SLIDER_MODE_FREE)
				scrollableWidth -= _maximumThumb.width;
			_minimumThumb.x = _minimumPadding + (scrollableWidth * (_rangeMinimum - _minimum) / (_maximum - _minimum));
			_minimumThumb.y = (actualHeight - _minimumThumb.height) / 2;
			
			scrollableWidth = actualWidth - _maximumThumb.width - _minimumPadding - _maximumPadding;
			var maxThumbPostion:Number;
			if (!_thumbsOverlapping && _mode != SLIDER_MODE_FREE)
			{
				scrollableWidth -= _minimumThumb.width;
				maxThumbPostion = _minimumPadding + (scrollableWidth * (_rangeMaximum - _minimum) / (_maximum - _minimum)) + _minimumThumb.width;
			}
			else
				maxThumbPostion = _minimumPadding + (scrollableWidth * (_rangeMaximum - _minimum) / (_maximum - _minimum));
			_maximumThumb.x = maxThumbPostion;
			_maximumThumb.y = (actualHeight - _maximumThumb.height) / 2;
		}
		
		protected function autoSizeIfNeeded():Boolean
		{
			if (isNaN(_backgroundOriginalWidth) || isNaN(_backgroundOriginalHeight))
			{
				_background.validate();
				_backgroundOriginalWidth = _background.width;
				_backgroundOriginalHeight = _background.height;
			}
			
			const needsWidth:Boolean = isNaN(explicitWidth);
			const needsHeight:Boolean = isNaN(explicitHeight);
			if (!needsWidth && !needsHeight)
				return false;
			
			_minimumThumb.validate();
			_maximumThumb.validate();			
			
			var newWidth:Number = explicitWidth;
			var newHeight:Number = explicitHeight;
			
			if (needsWidth)
			{
				newWidth = _backgroundOriginalWidth + Math.max(_maximumThumb.width, _minimumThumb.width) / 2;
			}
			if (needsHeight)
			{
				newHeight = _backgroundOriginalHeight;
				newHeight = Math.max(newHeight, _maximumThumb.height, _minimumThumb.height);
			}
			return setSizeInternal(newWidth, newHeight, false);
		}
		
		//} Layout
		
		//{ Factories		
		
		public function get backgroundFactory():Function
		{
			return _backgroundFactory;
		}
		
		public function set backgroundFactory(value:Function):void
		{
			_backgroundFactory = value;
		}
		
		//} Factories
		
		//{ Names	
			
		public function get customBackgroundName():String 
		{
			return _customBackgroundName;
		}
		
		public function set customBackgroundName(value:String):void 
		{
			_customBackgroundName = value;
			invalidate(INVALIDATION_FLAG_BACKGROUND_FACTORY);
		}
		
		public function get customMinimumThumbName():String
		{
			return _customMinimumThumbName;
		}
		
		public function set customMinimumThumbName(value:String):void
		{
			_customMinimumThumbName = value;
			invalidate(INVALIDATION_FLAG_MINIMUM_THUMB_FACTORY);
		}
		
		public function get customMaximumThumbName():String
		{
			return _customMaximumThumbName;
		}
		
		public function set customMaximumThumbName(value:String):void
		{
			_customMaximumThumbName = value;
			invalidate(INVALIDATION_FLAG_MAXIMUM_THUMB_FACTORY);
		}		
		
		public function get customMiddleThumbName():String 
		{
			return _customMiddleThumbName;
		}
		
		public function set customMiddleThumbName(value:String):void 
		{
			_customMiddleThumbName = value;
			invalidate(INVALIDATION_FLAG_MIDDLE_THUMB_FACTORY);
		}
		
		//} Names
		
		//{ Values	
		
		public function get valueMaximum():Number
		{
			return Math.max(_rangeMaximum, _rangeMinimum);
		}
		
		public function get valueMinimum():Number
		{
			return Math.min(_rangeMaximum, _rangeMinimum);
		}
		
		public function set valueMaximum(value:Number):void
		{
			if (!_maximumThumb || !_minimumThumb)
			{
				rangeMaximum = value;
				return;
			}
			
			if (_maximumThumb.x >= _minimumThumb.x)
				rangeMaximum = value >= rangeMinimum ? value : rangeMinimum;
			else
				rangeMinimum = value >= rangeMaximum ? value : rangeMaximum;
		}
		
		public function set valueMinimum(value:Number):void
		{
			if (!_maximumThumb || !_minimumThumb)
			{
				rangeMinimum = value;
				return;
			}
			
			if (_minimumThumb.x <= _maximumThumb.x)
				rangeMinimum = value <= rangeMaximum ? value : rangeMaximum;
			else
				rangeMaximum = value <= rangeMaximum ? value : rangeMinimum;
		}
		
		public function get mode():uint
		{
			return _mode;
		}
		
		public function set mode(value:uint):void
		{
			if (_mode != value)
			{
				_mode = value;
				setRange(_rangeMinimum, _rangeMaximum);
			}
		}
		
		public function get placeLastThumbOnTop():Boolean
		{
			return _placeLastThumbOnTop;
		}
		
		public function set placeLastThumbOnTop(value:Boolean):void
		{
			_placeLastThumbOnTop = value;
		}
		
		public function get thumbsOverlapping():Boolean
		{
			return _thumbsOverlapping;
		}
		
		public function set thumbsOverlapping(value:Boolean):void
		{
			_thumbsOverlapping = value;
		}
		
		public function get liveDragging():Boolean
		{
			return _liveDragging;
		}
		
		public function set liveDragging(value:Boolean):void
		{
			_liveDragging = value;
		}
		
		protected function setRange(min:Number, max:Number):void
		{
			_rangeMinimum = min;
			_rangeMaximum = max;
			if (_mode != SLIDER_MODE_FREE)
			{
				if (_rangeMaximum < _rangeMinimum)
					_rangeMinimum = _rangeMaximum;
			}
			invalidate(INVALIDATION_FLAG_DATA);
			if (_liveDragging || !_isDragging)
				dispatchEventWith(Event.CHANGE);
		}
		
		protected function get rangeMinimum():Number
		{
			return _rangeMinimum;
		}
		
		protected function set rangeMinimum(value:Number):void
		{
			var newValue:Number = calculateValue(value);
			if (_rangeMinimum != newValue)
			{
				_rangeMinimum = newValue;
				invalidate(INVALIDATION_FLAG_DATA);
				if (_liveDragging || !_isDragging)
					dispatchEventWith(Event.CHANGE);
			}
		}
		
		protected function get rangeMaximum():Number
		{
			return _rangeMaximum;
		}
		
		protected function set rangeMaximum(value:Number):void
		{
			var newValue:Number = calculateValue(value);
			if (_rangeMaximum != newValue)
			{
				_rangeMaximum = newValue;
				invalidate(INVALIDATION_FLAG_DATA);
				if (_liveDragging || !_isDragging)
					dispatchEventWith(Event.CHANGE);
			}
		}
		
		public function get step():Number
		{
			return _step;
		}
		
		public function set step(value:Number):void
		{
			if (value <= Math.round(maximum / 2))
				_step = value;
			else
				_step = 0;
			updateValues();
			invalidate(INVALIDATION_FLAG_DATA);
		}
		
		public function get minimum():Number
		{
			return _minimum;
		}
		
		public function set minimum(value:Number):void
		{
			if (_minimum != value)
			{
				_minimum = value;	
				updateValues();
				invalidate(INVALIDATION_FLAG_DATA);
				if (_liveDragging || !_isDragging)
					dispatchEventWith(Event.CHANGE);
			}
		}
		
		public function get maximum():Number
		{
			return _maximum;
		}
		
		public function set maximum(value:Number):void
		{
			if (_maximum != value)
			{
				_maximum = value;
				updateValues();								
				invalidate(INVALIDATION_FLAG_DATA);				
				if (_liveDragging || !_isDragging)
					dispatchEventWith(Event.CHANGE);
			}
		}
		
		protected function updateValues():void
		{			
			var newValue:Number = calculateValue(_rangeMinimum);
			if (_rangeMinimum != newValue)
				_rangeMinimum = newValue;
			newValue = calculateValue(_rangeMaximum);
			if (_rangeMaximum != newValue)
				_rangeMaximum = newValue;
		}
		
		protected function calculateValue(value:Number):Number
		{
			if (_step != 0)
				var newValue:Number = roundToNearest(value, _step);
			else
				newValue = value;
			return Math.min(Math.max(newValue, _minimum), _maximum);
		}
		
		public function get minimumPadding():Number
		{
			return _minimumPadding;
		}
		
		public function set minimumPadding(value:Number):void
		{
			if (_minimumPadding != value)
			{
				_minimumPadding = value;
				invalidate(INVALIDATION_FLAG_STYLES);
			}
		}
		
		public function get maximumPadding():Number
		{
			return _maximumPadding;
		}
		
		public function set maximumPadding(value:Number):void
		{
			if (_maximumPadding != value)
			{
				_maximumPadding = value;
				invalidate(INVALIDATION_FLAG_STYLES);
			}
		}
		
		//} Values
		
		//{ Properties
		
		public function get backgroundProperties():Object
		{
			if (!_backgroundProperties)
			{
				_backgroundProperties = new PropertyProxy(childProperties_onChange);
			}
			return _backgroundProperties;
		}
		
		public function set backgroundProperties(value:Object):void
		{
			if (this._backgroundProperties == value)
				return;
			
			if (!value)
				value = new PropertyProxy();
			
			if (!(value is PropertyProxy))
			{
				const newValue:PropertyProxy = new PropertyProxy();
				for (var propertyName:String in value)
					newValue[propertyName] = value[propertyName];
				value = newValue;
			}
			
			if (_backgroundProperties)
				_backgroundProperties.removeOnChangeCallback(childProperties_onChange);
			_backgroundProperties = PropertyProxy(value);
			if (_backgroundProperties)
				_backgroundProperties.addOnChangeCallback(childProperties_onChange);
			
			invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		protected function refreshBackgroundStyles():void
		{
			for (var propertyName:String in this._backgroundProperties)
			{
				if (_background.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._backgroundProperties[propertyName];
					_background[propertyName] = propertyValue;
				}
			}
		}
		
		protected function childProperties_onChange(proxy:PropertyProxy, name:Object):void
		{
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		//} Properties
	}
}