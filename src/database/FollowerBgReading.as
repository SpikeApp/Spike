package database
{
	public class FollowerBgReading extends BgReading
	{
		public function FollowerBgReading(timestamp:Number, sensor:Sensor, calibration:Calibration, rawData:Number, filteredData:Number, ageAdjustedRawValue:Number, calibrationFlag:Boolean, calculatedValue:Number, filteredCalculatedValue:Number, calculatedValueSlope:Number, a:Number, b:Number, c:Number, ra:Number, rb:Number, rc:Number, rawCalculated:Number, hideSlope:Boolean, noise:String, lastmodifiedtimestamp:Number, bgreadingid:String)
		{
			super(timestamp, sensor, calibration, rawData, filteredData, ageAdjustedRawValue, calibrationFlag, calculatedValue, filteredCalculatedValue, calculatedValueSlope, a, b, c, ra, rb, rc, rawCalculated, hideSlope, noise, lastmodifiedtimestamp, bgreadingid);
		}
	}
}