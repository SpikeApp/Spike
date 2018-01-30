package feathers.controls.text
{
	import feathers.controls.text.TextFieldTextRenderer;
	
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.utils.Pool;
	
	public class HyperlinkTextFieldTextRenderer extends TextFieldTextRenderer
	{
		//these tags will translate to the \r character
		private static const BREAK_CONTENT:Vector.<String> = new <String>
			[
				"br",
				"br/",
				"/p",
				"li",
				"/li",
			];
		
		public function HyperlinkTextFieldTextRenderer()
		{
			this.isHTML = true;
		}
		
		override public function set isHTML(value:Boolean):void
		{
			super.isHTML = value;
			if(this._isHTML)
			{
				this.addEventListener(TouchEvent.TOUCH, touchHandler);
			}
			else
			{
				this.removeEventListener(TouchEvent.TOUCH, touchHandler);
			}
		}
		
		/**
		 * @private
		 */
		protected function touchHandler(event:TouchEvent):void
		{
			if(!this._isHTML)
			{
				return;
			}
			var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
			if(!touch)
			{
				return;
			}
			var location:Point = touch.getLocation(this, Pool.getPoint());
			var charIndex:int = this.textField.getCharIndexAtPoint(location.x, location.y);
			Pool.putPoint(location);
			var htmlCharIndex:int = -1;
			var htmlText:String = this._text;
			var regularText:String = this.textField.text;
			var htmlTextLength:int = htmlText.length;
			var lastHTMLContent:String;
			for(var i:int = 0; i <= charIndex; i++)
			{
				htmlCharIndex++;
				if(htmlCharIndex >= htmlTextLength)
				{
					//this shouldn't happen, but there's a chance that the html
					//index and the regular index get out of sync, and this is
					//better than being in an infinite loop!
					break;
				}
				var regularChar:String = regularText.charAt(i);
				var htmlChar:String = htmlText.charAt(htmlCharIndex);
				if(regularChar === "\r")
				{
					if(htmlChar === "\n")
					{
						//if the html text uses \n, it will be replaced with \r
						//in the regular text
						continue;
					}
					else if(htmlChar === "\r")
					{
						//if the html text uses \r\n, it will be replaced with
						//\r in the regular text
						//we should also skip the extra \n
						htmlCharIndex++;
						continue;
					}
				}
				if(htmlChar === "\r")
				{
					//if the html text uses \r (but not \r\n), it will be
					//completely skipped in the regular text
					htmlCharIndex++;
					htmlChar = htmlText.charAt(htmlCharIndex);
				}
				var lastHTMLIndex:int = -1;
				do
				{
					if(lastHTMLIndex === htmlCharIndex)
					{
						//we haven't moved forward at all,
						//so we're stuck in an infinite loop!
						break;
					}
					lastHTMLIndex = htmlCharIndex;
					if(htmlCharIndex >= htmlTextLength)
					{
						//we've gone past the end, we must be stuck
						//in an infinite loop!
						break;
					}
					if(htmlChar == "<")
					{
						var skipTo:int = htmlText.indexOf(">", htmlCharIndex);
						lastHTMLContent = htmlText.substr(htmlCharIndex + 1, skipTo - htmlCharIndex - 1);
						if(regularChar === "\r" && BREAK_CONTENT.indexOf(lastHTMLContent) !== -1)
						{
							htmlCharIndex = skipTo;
						}
						else
						{
							htmlCharIndex = skipTo + 1;
						}
						htmlChar = htmlText.charAt(htmlCharIndex);
					}
					else if(htmlChar == "&")
					{
						skipTo = htmlText.indexOf(";", htmlCharIndex);
						var spaceIndex:int = htmlText.indexOf(" ", htmlCharIndex);
						if(skipTo !== -1 && (spaceIndex === -1 || spaceIndex > skipTo))
						{
							//it's possible that there will be no ; after the &
							//also, if a space appears before ;, then the & is
							//not the start of the entity.
							htmlCharIndex = skipTo;
						}
						htmlChar = regularChar;
					}
				}
				while(htmlChar != regularChar);
			}
			if(!lastHTMLContent || lastHTMLContent.search(/^a\s+/) != 0)
			{
				return;
			}
			var linkStartIndex:int = lastHTMLContent.search(/href=[\"\']/) + 6;
			if(linkStartIndex < 2)
			{
				return;
			}
			var linkEndIndex:int = lastHTMLContent.indexOf("\"", linkStartIndex + 1);
			if(linkEndIndex < 0)
			{
				linkEndIndex = lastHTMLContent.indexOf("'", linkStartIndex + 1);
				if(linkEndIndex < 0)
				{
					return;
				}
			}
			var url:String = lastHTMLContent.substr(linkStartIndex, linkEndIndex - linkStartIndex);
			navigateToURL(new URLRequest(url));
		}
	}
}