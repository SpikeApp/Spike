package utils
{
	public class DataValidator
	{
		public static function validateEmail(emailAddress:String):Boolean
		{
			var emailExpression:RegExp = /([a-z0-9._-]+?)@([a-z0-9.-]+)\.([a-z]{2,4})/;
			return emailExpression.test(emailAddress);
		}
	}
}