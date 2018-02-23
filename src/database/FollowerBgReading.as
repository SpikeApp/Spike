package database
{
	public class FollowerBgReading extends BgReading
	{
		/**
		 * used by NightScoutService<br>
		 * NightScoutService will download readings from NS, and store them as NSBgReading<br>
		 * When user switches from follower to non-follower, NightScout service must go through readings in modellocator, if it's a NSBgReading then it will be cleaned<br>
		 */
		public function FollowerBgReading(timestamp:Number, sensor:Sensor, calibration:Calibration, rawData:Number, filteredData:Number, ageAdjustedRawValue:Number, calibrationFlag:Boolean, calculatedValue:Number, filteredCalculatedValue:Number, calculatedValueSlope:Number, a:Number, b:Number, c:Number, ra:Number, rb:Number, rc:Number, rawCalculated:Number, hideSlope:Boolean, noise:String, lastmodifiedtimestamp:Number, bgreadingid:String)
		{
			super(timestamp, sensor, calibration, rawData, filteredData, ageAdjustedRawValue, calibrationFlag, calculatedValue, filteredCalculatedValue, calculatedValueSlope, a, b, c, ra, rb, rc, rawCalculated, hideSlope, noise, lastmodifiedtimestamp, bgreadingid);
		}
	}
}