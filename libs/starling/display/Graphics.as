package starling.display
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	import starling.display.graphics.Fill;
	import starling.display.graphics.Graphic;
	import starling.display.graphics.NGon;
	import starling.display.graphics.Plane;
	import starling.display.graphics.RoundedRectangle;
	import starling.display.graphics.Stroke;
	import starling.display.graphics.StrokeVertex;

	import starling.display.materials.IMaterial;
	import starling.display.shaders.fragment.TextureFragmentShader;
	import starling.display.util.CurveUtil;
	import starling.textures.Texture;

	public class Graphics
	{
		protected static const BEZIER_ERROR:Number = 0.75;
		
		// Shared texture fragment shader used across all child Graphic's drawn
		// with a textured fill or stroke.
		protected static var s_textureFragmentShader:TextureFragmentShader = new TextureFragmentShader();
		
		
		protected var _container				:DisplayObjectContainer; // The owner of this Graphics instance.
		protected var _penPosX					:Number;
		protected var _penPosY					:Number;
		
		// Fill state vars
		protected var _currentFill				:Fill;
		protected var _fillStyleSet				:Boolean;
		protected var _fillColor				:uint;
		protected var _fillAlpha				:Number;
		protected var _fillTexture				:Texture;
		protected var _fillMaterial				:IMaterial;
		protected var _fillMatrix				:Matrix;
		
		// Stroke state vars
		protected var _currentStroke			:Stroke;
		protected var _strokeStyleSet			:Boolean;
		protected var _strokeThickness			:Number;
      	protected var _strokeColor				:uint;
		protected var _strokeAlpha				:Number;
		protected var _strokeTexture			:Texture;
		protected var _strokeMaterial			:IMaterial;
		protected var _strokeInterrupted		:Boolean;
		
     	protected var _precisionHitTest			:Boolean = false;
		protected var _precisionHitTestDistance	:Number = 0; 
		
		
        public function Graphics( displayObjectContainer:DisplayObjectContainer )
		{
			_container = displayObjectContainer;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////
		// PUBLIC
		/////////////////////////////////////////////////////////////////////////////////////////
		
		public function clear():void
		{
			while ( _container.numChildren > 0 )
			{
				var child:DisplayObject = _container.getChildAt( 0 );
				child.dispose();
				_container.removeChildAt( 0 );
			}
			
			_penPosX = NaN;
			_penPosY = NaN;
			
			endStroke();
			endFill();
        }
		
		////////////////////////////////////////
		// Fill-style
		////////////////////////////////////////
		
		public function beginFill( color:uint, alpha:Number = 1.0 ):void
		{
			endFill();
			
			_fillStyleSet 	= true;
			_fillColor 		= color;
			_fillAlpha 		= alpha;
			_fillTexture 	= null;
			_fillMaterial 	= null;
			_fillMatrix 	= null;
		}
				
		public function beginTextureFill( texture:Texture, uvMatrix:Matrix = null, color:uint = 0xFFFFFF, alpha:Number = 1.0 ):void
		{
			endFill();
			
			_fillStyleSet 	= true;
			_fillColor 		= color;
			_fillAlpha 		= alpha;
			_fillTexture 	= texture;
			_fillMaterial 	= null;
			_fillMatrix 	= new Matrix();
			
			if ( uvMatrix )
			{
				_fillMatrix = uvMatrix.clone();
				_fillMatrix.invert();
			}
			else
			{
				_fillMatrix = new Matrix();
			}
			
			_fillMatrix.scale( 1 / texture.width, 1 / texture.height );
		}
		
		public function beginMaterialFill( material:IMaterial, uvMatrix:Matrix = null ):void
		{
			endFill();
			
			_fillStyleSet 	= true;
			_fillColor 		= 0xFFFFFF;
			_fillAlpha 		= 1;
			_fillTexture 	= null;
			_fillMaterial 	= material;
			if ( uvMatrix )
			{
				_fillMatrix = uvMatrix.clone();
				_fillMatrix.invert();
			}
			else
			{
				_fillMatrix = new Matrix();
			}
			if ( material.textures.length > 0 )
			{
				_fillMatrix.scale( 1 / material.textures[0].width, 1 / material.textures[0].height );
			}
		}
		
		public function endFill():void
		{
			_fillStyleSet 	= false;
			_fillColor 		= NaN;
			_fillAlpha 		= NaN;
			_fillTexture 	= null;
			_fillMaterial 	= null;
			_fillMatrix 	= null;
			
			// If we started drawing with a fill, but ended drawing
			// before we did anything visible with it, dispose it here.
			if ( _currentFill && _currentFill.numVertices < 3 ) 
			{
				_currentFill.dispose();
				_container.removeChild( _currentFill );
			}
			_currentFill = null;
		}
		
		////////////////////////////////////////
		// Stroke-style
		////////////////////////////////////////
		
		public function lineStyle( thickness:Number = NaN, color:uint = 0, alpha:Number = 1.0 ):void
		{
			endStroke();
			
			_strokeStyleSet			= !isNaN(thickness) && thickness > 0;
			_strokeThickness		= thickness;
			_strokeColor			= color;
			_strokeAlpha			= alpha;
			_strokeTexture 			= null;
			_strokeMaterial			= null;
		}
		
		public function lineTexture( thickness:Number = NaN, texture:Texture = null ):void
		{
			endStroke();
			
			_strokeStyleSet			= !isNaN(thickness) && thickness > 0 && texture;
         	_strokeThickness		= thickness;
			_strokeColor			= 0xFFFFFF;
			_strokeAlpha			= 1;
			_strokeTexture 			= texture;
			_strokeMaterial			= null;
		}
		
		public function lineMaterial( thickness:Number = NaN, material:IMaterial = null ):void
		{
			endStroke();
			
			_strokeStyleSet			= !isNaN(thickness) && thickness > 0 && material;
			_strokeThickness		= thickness;
			_strokeColor			= 0xFFFFFF;
			_strokeAlpha			= 1;
			_strokeTexture			= null;
			_strokeMaterial			= material;
		}
		
		protected function endStroke():void
		{
			_strokeStyleSet			= false;
			_strokeThickness		= NaN;
			_strokeColor			= NaN;
			_strokeAlpha			= NaN;
			_strokeTexture			= null;
			_strokeMaterial			= null;
			
			// If we started drawing with a stroke, but ended drawing
			// before we did anything visible with it, dispose it here.
			if ( _currentStroke && _currentStroke.numVertices < 2 )
			{
				_currentStroke.dispose();
			}
			
			_currentStroke = null;
		}
		
		
		////////////////////////////////////////
		// Draw commands
		////////////////////////////////////////
		
		public function moveTo( x:Number, y:Number ):void
		{
			// Use degenerate methods for moveTo calls.
			// Degenerates allow for better performance as they do not terminate
			// the vertex buffer but instead use zero size polygons to translate
			// from the end point of the last section of the stroke to the
			// start of the new point.
			if ( _strokeStyleSet && _currentStroke )
			{
				_currentStroke.addDegenerates( x, y );
			}
			
			if ( _fillStyleSet ) 
			{
				if ( _currentFill == null )
				{ // Added to make sure that the first vertex in a shape gets added to the fill as well.
					createFill();
					_currentFill.addVertex(x, y);
				}
				else
					_currentFill.addDegenerates( x, y );
			}
			
			_penPosX = x;
			_penPosY = y;
			_strokeInterrupted = true;
		}
		
		public function lineTo( x:Number, y:Number ):void
		{
			if ( isNaN( _penPosX ) )
			{
				moveTo( 0, 0 );
			}
			
			if ( _strokeStyleSet  ) 
			{
				// Create a new stroke Graphic if this is the first
				// time we've start drawing something with it.
				if ( _currentStroke == null )
				{
					createStroke();
				}
				
				if ( _strokeInterrupted || _currentStroke.numVertices == 0  )
				{
					_currentStroke.lineTo( _penPosX, _penPosY, _strokeThickness );
					_strokeInterrupted  = false;
				}
				
				_currentStroke.lineTo( x, y, _strokeThickness );
			}
						
			if ( _fillStyleSet ) 
			{
				if ( _currentFill == null )
				{
					createFill();
				}
				_currentFill.addVertex( x, y );
			}
			
			_penPosX = x;
			_penPosY = y;
		}
		
		public function curveTo( cx:Number, cy:Number, a2x:Number, a2y:Number, error:Number = BEZIER_ERROR ):void
		{
			var startX:Number = _penPosX;
			var startY:Number = _penPosY;
			
			if ( isNaN(startX) )
			{
				startX = 0;
				startY = 0;
			}
			
			var points:Vector.<Number> = CurveUtil.quadraticCurve( startX, startY, cx, cy, a2x, a2y, error );

            var L:int = points.length;
            for ( var i:int = 0; i < L; i+=2 )
            {
                var x:Number = points[i];
                var y:Number = points[i+1];

                if ( i == 0 && isNaN(_penPosX) )
                {
                    moveTo( x, y );
                }
                else
                {
                    lineTo( x, y );
                }
            }

            _penPosX = a2x;
			_penPosY = a2y;
		}
		
		public function cubicCurveTo( c1x:Number, c1y:Number, c2x:Number, c2y:Number, a2x:Number, a2y:Number, error:Number = BEZIER_ERROR ):void
		{
			var startX:Number = _penPosX;
			var startY:Number = _penPosY;
			
			if ( isNaN(startX) )
			{
				startX = 0;
				startY = 0;
			}
			
			var points:Vector.<Number> = CurveUtil.cubicCurve( startX, startY, c1x, c1y, c2x, c2y, a2x, a2y, error );
			
			var L:int = points.length;
            for ( var i:int = 0; i < L; i+=2 )
    		{
	    		var x:Number = points[i];
		    	var y:Number = points[i+1];
				
			   	if ( i == 0 && isNaN(_penPosX) )
			    {
				    moveTo( x, y );
			    }
			    else
			    {
                    lineTo( x, y );
                }
			}

			_penPosX = a2x;
			_penPosY = a2y;
		}
		
		public function drawCircle( x:Number, y:Number, radius:Number ):void
		{
			drawEllipse( x, y, radius*2, radius*2 );
		}
		
		public function drawEllipse( x:Number, y:Number, width:Number, height:Number ):void
		{
			// Calculate num-sides based on a blend between circumference of width and circumference of height.
			// Should provide good results for ellipses with similar widths/heights.
			// Will look bad on very thin ellipses.
			var numSides:int = Math.PI * ( width * 0.5  + height * 0.5 ) * 0.25;
			numSides = numSides < 6 ? 6 : numSides;
			
			// Use an NGon primitive instead of fill to bypass triangulation.
			if ( _fillStyleSet )
			{
				var nGon:NGon = new NGon( width * 0.5, numSides );
				nGon.x = x;
				nGon.y = y;
				nGon.scaleY = height / width;
				
				applyFillStyleToGraphic(nGon);
				
				var m:Matrix = new Matrix();
				m.scale( width, height );
				if ( _fillMatrix )
				{
					m.concat( _fillMatrix );
				}
				nGon.uvMatrix = m;
				nGon.precisionHitTest = _precisionHitTest;
				nGon.precisionHitTestDistance = _precisionHitTestDistance;
				
				_container.addChild(nGon);
			}
			
			// Draw the stroke
			if ( _strokeStyleSet )
			{
				// Null the currentFill after storing it in a local var.
				// This ensures the moveTo/lineTo calls for the stroke below don't
				// end up adding any points to a current fill (as we've already done
				// this in a more efficient manner above).
				var storedFill:Fill = _currentFill;
				_currentFill = null;
				
				var halfWidth:Number = width*0.5;
				var halfHeight:Number = height*0.5;
				var anglePerSide:Number = ( Math.PI * 2 ) / numSides;
				var a:Number = Math.cos( anglePerSide );
				var b:Number = Math.sin( anglePerSide );
				var s:Number = 0.0;
				var c:Number = 1.0;
				
				for ( var i:int = 0; i <= numSides; i++ )
				{
					var sx:Number = s * halfWidth + x;
					var sy:Number = -c * halfHeight + y;
					if ( i == 0 )
					{
						moveTo( sx,sy );
					}
					else
					{
						lineTo( sx,sy );
					}
					
					const ns:Number = b*c + a*s;
					const nc:Number = a*c - b*s;
					c = nc;
					s = ns;
				}
				
				// Reinstate the fill
				_currentFill = storedFill;
			}
		}
		
		
		public function drawRect( x:Number, y:Number, width:Number, height:Number ):void
		{
			// Use a Plane primitive instead of fill to side-step triangulation.
			if ( _fillStyleSet )
			{
				var plane:Plane = new Plane( width, height );
				
				applyFillStyleToGraphic(plane);
				
				var m:Matrix = new Matrix();
				m.scale( width, height );
				if ( _fillMatrix )
				{
					m.concat( _fillMatrix );
				}
				plane.uvMatrix = m;
				plane.x = x;
				plane.y = y;
				_container.addChild( plane );
			}
			
			// Draw the stroke
			if ( _strokeStyleSet )
			{
				// Null the currentFill after storing it in a local var.
				// This ensures the moveTo/lineTo calls for the stroke below don't
				// end up adding any points to a current fill (as we've already done
				// this in a more efficient manner above).
				var storedFill:Fill = _currentFill;
				_currentFill = null;
				
				moveTo( x, y );
				lineTo( x + width, y );
				lineTo( x + width, y + height );
				lineTo( x, y + height );
				lineTo( x, y );
				
				_currentFill = storedFill;
			}
		}
		
		public function drawRoundRect( x:Number, y:Number, width:Number, height:Number, radius:Number ):void
		{
			drawRoundRectComplex( x, y, width, height, radius, radius, radius, radius );
		}
		
		public function drawRoundRectComplex( x:Number, y:Number, width:Number, height:Number, 
											  topLeftRadius:Number, topRightRadius:Number, 
											  bottomLeftRadius:Number, bottomRightRadius:Number ):void
		{
			// Early-out if not fill or stroke style set.
			if ( !_fillStyleSet && !_strokeStyleSet )
			{
				return;
			}
			
			var roundedRect:RoundedRectangle = new RoundedRectangle( width, height, topLeftRadius, 
																	 topRightRadius, bottomLeftRadius,
																	 bottomRightRadius );
			
			// Draw fill
			if ( _fillStyleSet )
			{
				applyFillStyleToGraphic( roundedRect );
				
				var m:Matrix = new Matrix();
				m.scale(width, height);
				if ( _fillMatrix )
				{
					m.concat( _fillMatrix );
				}
				roundedRect.uvMatrix = m;
				roundedRect.x = x;
				roundedRect.y = y;
				_container.addChild(roundedRect);
			}
			_currentFill = storedFill;
			
			if ( _strokeStyleSet )
			{
				// Null the currentFill after storing it in a local var.
				// This ensures the moveTo/lineTo calls for the stroke below don't
				// end up adding any points to a current fill (as we've already done
				// this in a more efficient manner above).
				var storedFill:Fill = _currentFill;
				_currentFill = null;
				
				var strokePoints:Vector.<Number> = roundedRect.getStrokePoints();
				for ( var i:int = 0; i < strokePoints.length; i+=2 )
				{
					if ( i == 0 )
					{
						moveTo(x + strokePoints[i], y + strokePoints[i + 1]);
					}
					else
					{
						lineTo(x + strokePoints[i], y + strokePoints[i + 1]);
					}
				}
				
				_currentFill = storedFill;
			}
		}
		
		
		/**
		 * Used for geometry level hit tests. 
		 * False gives boundingbox results, True gives geometry level results.
		 * True is a lot more exact, but also slower. 
		 */
		public function set precisionHitTest(value:Boolean):void
		{
			_precisionHitTest = value;
			if ( _currentFill )
			{
				_currentFill.precisionHitTest = value;
			}
			if ( _currentStroke )
			{
				_currentStroke.precisionHitTest = value;
			}
		}
		
		public function get precisionHitTest():Boolean 
		{
			return _precisionHitTest;
		}
		
		public function set precisionHitTestDistance(value:Number):void
		{
			_precisionHitTestDistance = value;
			if ( _currentFill )
			{
				_currentFill.precisionHitTestDistance = value;
			}
			if ( _currentStroke )
			{
				_currentStroke.precisionHitTestDistance = value;
			}
		
		}
		
		public function get precisionHitTestDistance() : Number
		{
			return _precisionHitTestDistance;
		}
		
		
		/////////////////////////////////////////////////////////////////////////////////////////
		// PROTECTED
		/////////////////////////////////////////////////////////////////////////////////////////
		
		////////////////////////////////////////
		// Overridable functions for custom
		// Fill/Stroke types
		////////////////////////////////////////
		
		protected function getStrokeInstance():Stroke
		{
			return new Stroke();
		}
		
		protected function getFillInstance():Fill
		{
			return new Fill();
		}
		
		/**
		 * Creates a Stroke instance and inits its material based on the
		 * currently set stroke style.
		 * Result is stored in _currentStroke.
		 */
		protected function createStroke():void
		{
			if ( _currentStroke != null )
			{
				throw( new Error( "Current stroke should be disposed via endStroke() first." ) );
			}
			
			_currentStroke = getStrokeInstance();
			_currentStroke.precisionHitTest = _precisionHitTest;
			_currentStroke.precisionHitTestDistance = _precisionHitTestDistance;
			
			applyStrokeStyleToGraphic(_currentStroke);
						
			_container.addChild(_currentStroke);
		}
		
		/**
		 * Creates a Fill instance and inits its material based on the
		 * currently set fill style.
		 * Result is stored in _currentFill.
		 */
		protected function createFill():void
		{
			if ( _currentFill != null )
			{
				throw( new Error( "Current stroke should be disposed via endFill() first." ) );
			}
			
			_currentFill = getFillInstance();
			if ( _fillMatrix )
			{
				_currentFill.uvMatrix = _fillMatrix;
			}
			_currentFill.precisionHitTest = _precisionHitTest;
			_currentFill.precisionHitTestDistance = _precisionHitTestDistance;
			applyFillStyleToGraphic( _currentFill );
			
			_container.addChild(_currentFill);
		}
		
		protected function applyStrokeStyleToGraphic( graphic:Graphic ):void
		{
			if ( _strokeMaterial )
			{
				graphic.material = _strokeMaterial;
			}
			else if ( _strokeTexture )
			{
				graphic.material.fragmentShader = s_textureFragmentShader;
				graphic.material.textures[0] = _strokeTexture;
			}
			graphic.material.color = _strokeColor;
			graphic.material.alpha = _strokeAlpha;
		}
		
		protected function applyFillStyleToGraphic( graphic:Graphic ):void
		{
			if ( _fillMaterial )
			{
				graphic.material = _fillMaterial;
			}
			else if ( _fillTexture )
			{
				graphic.material.fragmentShader = s_textureFragmentShader;
				graphic.material.textures[0] = _fillTexture;
			}
			if ( _fillMatrix )
			{
				graphic.uvMatrix = _fillMatrix;
			}
			graphic.material.color = _fillColor;
			graphic.material.alpha = _fillAlpha;
		}
		
		////////////////////////////////////////
		// Graphics command functions
		////////////////////////////////////////
		
		
    }
}
