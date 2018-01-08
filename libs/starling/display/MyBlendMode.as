package starling.display 
{
	import flash.display3D.Context3DBlendFactor;
	/**
	 * ...
	 * @author Sebastien Pautet
	 */
	public class MyBlendMode 
	{		
		private static var BlendFactors:Array = [
            // no premultiplied alpha
            {
                "none"     : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO ],
                "normal"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "add"      : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA ],
                "multiply" : [ Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "screen"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE ],
                "erase"    : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "mask"     : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_ALPHA ],
                "below"    : [ Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA ]
            },
            // premultiplied alpha
            { 
                "none"     : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO ],
                "normal"   : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "add"      : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE ],
                "multiply" : [ Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "screen"   : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR ],
                "erase"    : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
                "mask"     : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_ALPHA ],
                "below"    : [ Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA ]
            }
        ];
      
		public static function getBlendFactors(mode:String, premultipliedAlpha:Boolean=true):Array
		{
			var modes:Object = BlendFactors[int(premultipliedAlpha)];
			if (mode in modes) return modes[mode];
			else throw new ArgumentError("Invalid blend mode");
		}
	}

}