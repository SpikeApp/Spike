package treatments
{
	import utils.MathHelper;
	import utils.UniqueId;

	public class BasalRate
	{
		/* Properties */
		public var ID:String;
		public var startTime:String;
		public var startHours:Number;
		public var startMinutes:Number;
		public var basalRate:Number;
		public var timestamp:Number;
		
		public function BasalRate(basalRate:Number, startHours:Number, startMinutes:Number, startTime:String = null, ID:String = null, timestamp:Number = Number.NaN)
		{
			this.basalRate = basalRate;
			this.startHours = startHours;
			this.startMinutes = startMinutes;
			this.startTime = startTime != null ? startTime : MathHelper.formatNumberToString(startHours) + ":" + MathHelper.formatNumberToString(startMinutes);
			this.ID = ID != null ? ID : UniqueId.createEventId();
			this.timestamp = !isNaN(timestamp) ? timestamp : new Date().valueOf();
		}
	}
}