package renderers
{
	import flash.display.Graphics;
	
	import mx.charts.series.items.PlotSeriesItem;
	
	import spark.components.IconItemRenderer;
	
	import databaseclasses.BgReading;
	import databaseclasses.CommonSettings;
	
	public class BGGraphItemRenderer extends IconItemRenderer
	{
		private var _chartItem:PlotSeriesItem;
		
		public function BGGraphItemRenderer()
		{
			super();
		}
		
		override public function get data():Object {
			return _chartItem;
		}
		
		override public function set data(value:Object):void {
			_chartItem = value as PlotSeriesItem; 
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void {
			if(!_chartItem.item)
				return;
			
			if (!_chartItem.item.calculatedValue)
				return;
			
			if (isNaN(_chartItem.item.calculatedValue))
				return;
			
			var g:Graphics = graphics;
			g.clear();  
			var value:Number = CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_DO_MGDL) == "true" ? _chartItem.item.calculatedValue as Number:BgReading.mmolToMgdl(_chartItem.item.calculatedValue as Number);
			var color:uint = value > new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_HIGH_MARK)) ? 0xFFBB33 :
				value < new Number(CommonSettings.getCommonSetting(CommonSettings.COMMON_SETTING_LOW_MARK)) ? 0xC30909:0x33B5E6;
			g.beginFill(color);
			g.drawCircle(0, 0, 2);
			g.endFill();
		}
		
	}
}