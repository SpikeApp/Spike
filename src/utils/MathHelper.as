package utils
{
	public class MathHelper
	{
		public function MathHelper() {}
		
		public static function formatNumberToString (value:Number):String
		{
			var output:String;
			
			if (value < 10)
				output = "0" + value;
			else
				output = String(value);
			
			return output;
		}
		
		public static function formatNightscoutFollowerSlope(value:Number):String
		{
			var output:String;
			
			if (value >= 0)
				output = "+ " + String(value);
			else
				output = "- " + String(Math.abs(value));
			
			return output;
		}
		
		public static function formatNumberToStringWithPrefix(value:Number):String
		{
			var output:String = "";
			
			if (value >= 0)
				output = "+" + value;
			else
				output = String(value);
			
			return output;
		}
		
		/**
		 * The [standard deviation](http://en.wikipedia.org/wiki/Standard_deviation)
		 * is the square root of the variance. This is also known as the population
		 * standard deviation. It's useful for measuring the amount
		 * of variation or dispersion in a set of values.
		 *
		 * Standard deviation is only appropriate for full-population knowledge: for
		 * samples of a population, {@link sampleStandardDeviation} is
		 * more appropriate.
		 *
		 * @param {Array<number>} x input
		 * @returns {number} standard deviation
		 * @example
		 * variance([2, 4, 4, 4, 5, 5, 7, 9]); // => 4
		 * standardDeviation([2, 4, 4, 4, 5, 5, 7, 9]); // => 2
		 */
		public static function standardDeviation(x:Array):Number
		{
			if (x.length == 1) 
			{
				return 0;
			}
			
			const v:Number = variance(x);
			
			return Math.sqrt(v);
		}
		
		/**
		 * The [median](http://en.wikipedia.org/wiki/Median) is
		 * the middle number of a list. This is often a good indicator of 'the middle'
		 * when there are outliers that skew the `mean()` value.
		 * This is a [measure of central tendency](https://en.wikipedia.org/wiki/Central_tendency):
		 * a method of finding a typical or central value of a set of numbers.
		 *
		 * The median isn't necessarily one of the elements in the list: the value
		 * can be the average of two elements if the list has an even length
		 * and the two central values are different.
		 *
		 * @param {Array<number>} x input
		 * @returns {number} median value
		 * @example
		 * median([10, 2, 5, 100, 2, 1]); // => 3.5
		 */
		public static function median(x:Array):Number
		{
			return +quantile(x, 0.5);
		}
		
		public static function lowerQuartile(x:Array):Number
		{
			return +quantile(x, 0.25);
		}
		
		public static function upperQuartile(x:Array):Number
		{
			return +quantile(x, 0.75);
		}
		
		/**
		 * The [quantile](https://en.wikipedia.org/wiki/Quantile):
		 * this is a population quantile, since we assume to know the entire
		 * dataset in this library. This is an implementation of the
		 * [Quantiles of a Population](http://en.wikipedia.org/wiki/Quantile#Quantiles_of_a_population)
		 * algorithm from wikipedia.
		 *
		 * Sample is a one-dimensional array of numbers,
		 * and p is either a decimal number from 0 to 1 or an array of decimal
		 * numbers from 0 to 1.
		 * In terms of a k/q quantile, p = k/q - it's just dealing with fractions or dealing
		 * with decimal values.
		 * When p is an array, the result of the function is also an array containing the appropriate
		 * quantiles in input order
		 *
		 * @param {Array<number>} x sample of one or more numbers
		 * @param {Array<number> | number} p the desired quantile, as a number between 0 and 1
		 * @returns {number} quantile
		 * @example
		 * quantile([3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20], 0.5); // => 9
		 */
		public static function quantile(x:Array, p:Number):Number
		{
			const copy:Array = x.concat();
			
			const idx:Number = quantileIndex(copy.length, p);
			quantileSelect(copy, idx, 0, copy.length - 1);
			return quantileSorted(copy, p);
			
			
			function quantileSelect(arr:Array, k:Number, left:Number, right:Number):void
			{
				if (k % 1 == 0) 
				{
					quickselect(arr, k, left, right);
				} 
				else 
				{
					k = Math.floor(k);
					quickselect(arr, k, left, right);
					quickselect(arr, k + 1, k + 1, right);
				}
			}
			
			function multiQuantileSelect(arr:Array, p:Array):void 
			{
				const pLength:uint = p.length;
				const indices:Array = [0];
				
				
				for (var i:int = 0; i < pLength; i++) 
				{
					indices.push(quantileIndex(arr.length, p[i]));
				}
				indices.push(arr.length - 1);
				indices.sort(compare);
				
				const stack:Array = [0, indices.length - 1];
				
				while (stack.length) 
				{
					const r:Number = Math.ceil(stack.pop());
					const l:Number = Math.floor(stack.pop());
					if (r - l <= 1) continue;
					
					const m:Number = Math.floor((l + r) / 2);
					quantileSelect(
						arr,
						indices[m],
						Math.floor(indices[l]),
						Math.ceil(indices[r])
					);
					
					stack.push(l, m, m, r);
				}
			}
			
			function compare(a:Number, b:Number):Number
			{
				return a - b;
			}
			
			function quantileIndex(len:Number, p:Number):Number
			{
				const idx:Number = len * p;
				
				if (p == 1) 
				{
					// If p is 1, directly return the last index
					return len - 1;
				} 
				else if (p == 0) 
				{
					// If p is 0, directly return the first index
					return 0;
				} 
				else if (idx % 1 != 0) 
				{
					// If index is not integer, return the next index in array
					return Math.ceil(idx) - 1;
				} 
				else if (len % 2 == 0) 
				{
					// If the list has even-length, we'll return the middle of two indices
					// around quantile to indicate that we need an average value of the two
					return idx - 0.5;
				} 
				else 
				{
					// Finally, in the simple case of an integer index
					// with an odd-length list, return the index
					return idx;
				}
			}
		}
		
		/**
		 * The [variance](http://en.wikipedia.org/wiki/Variance)
		 * is the sum of squared deviations from the mean.
		 *
		 * This is an implementation of variance, not sample variance:
		 * see the `sampleVariance` method if you want a sample measure.
		 *
		 * @param {Array<number>} x a population of one or more data points
		 * @returns {number} variance: a value greater than or equal to zero.
		 * zero indicates that all values are identical.
		 * @throws {Error} if x's length is 0
		 * @example
		 * variance([1, 2, 3, 4, 5, 6]); // => 2.9166666666666665
		 */
		private static function variance(x:Array):Number
		{
			var xLength:uint = x.length;
			
			// The variance of no numbers is null
			if (xLength == 0) 
			{
				//Variance requires at least one data point
				return Number.NaN;
			}
			
			// Find the mean of squared deviations between the
			// mean value and each value.
			return sumNthPowerDeviations(x, 2) / xLength;
		}
		
		/**
		 * The sum of deviations to the Nth power.
		 * When n=2 it's the sum of squared deviations.
		 * When n=3 it's the sum of cubed deviations.
		 *
		 * @param {Array<number>} x
		 * @param {number} n power
		 * @returns {number} sum of nth power deviations
		 *
		 * @example
		 * var input = [1, 2, 3];
		 * // since the variance of a set is the mean squared
		 * // deviations, we can calculate that with sumNthPowerDeviations:
		 * sumNthPowerDeviations(input, 2) / input.length;
		 */
		private static function sumNthPowerDeviations(x:Array, n:Number):Number
		{
			const meanValue:Number = mean(x);
			var xLength:uint = x.length;
			var sum:Number = 0;
			var tempValue:Number;
			var i:Number;
			
			// This is an optimization: when n is 2 (we're computing a number squared),
			// multiplying the number by itself is significantly faster than using
			// the Math.pow method.
			if (n == 2) 
			{
				for (i = 0; i < xLength; i++) 
				{
					tempValue = x[i].calculatedValue - meanValue;
					sum += tempValue * tempValue;
				}
			} 
			else 
			{
				for (i = 0; i < xLength; i++) 
				{
					sum += Math.pow(x[i].calculatedValue - meanValue, n);
				}
			}
			
			return sum;
		}
		
		/**
		 * The mean, _also known as average_,
		 * is the sum of all values over the number of values.
		 * This is a [measure of central tendency](https://en.wikipedia.org/wiki/Central_tendency):
		 * a method of finding a typical or central value of a set of numbers.
		 *
		 * This runs on `O(n)`, linear time in respect to the array
		 *
		 * @param {Array<number>} x sample of one or more data points
		 * @throws {Error} if the the length of x is less than one
		 * @returns {number} mean
		 * @example
		 * mean([0, 10]); // => 5
		 */
		private static function mean(x:Array):Number 
		{
			var xLength:uint = x.length;
			
			// The mean of no numbers is null
			if (xLength == 0) 
			{
				//Mean requires at least one data point
				return Number.NaN;
			}
			
			return sum(x) / xLength;
		}
		
		/**
		 * Our default sum is the [Kahan-Babuska algorithm](https://pdfs.semanticscholar.org/1760/7d467cda1d0277ad272deb2113533131dc09.pdf).
		 * This method is an improvement over the classical
		 * [Kahan summation algorithm](https://en.wikipedia.org/wiki/Kahan_summation_algorithm).
		 * It aims at computing the sum of a list of numbers while correcting for
		 * floating-point errors. Traditionally, sums are calculated as many
		 * successive additions, each one with its own floating-point roundoff. These
		 * losses in precision add up as the number of numbers increases. This alternative
		 * algorithm is more accurate than the simple way of calculating sums by simple
		 * addition.
		 *
		 * This runs on `O(n)`, linear time in respect to the array.
		 *
		 * @param {Array<number>} x input
		 * @return {number} sum of all input numbers
		 * @example
		 * sum([1, 2, 3]); // => 6
		 */
		private static function sum(x:Array):Number
		{
			var xLength:uint = x.length;
			
			// If the array is empty, we needn't bother computing its sum
			if (xLength == 0) 
			{
				return 0;
			}
			
			// Initializing the sum as the first number in the array
			var sum:Number = x[0].calculatedValue;
			
			// Keeping track of the floating-point error correction
			var correction:Number = 0;
			
			var transition:Number;
			
			for (var i:int = 1; i < xLength; i++) 
			{
				transition = sum + x[i].calculatedValue;
				
				// Here we need to update the correction in a different fashion
				// if the new absolute value is greater than the absolute sum
				if (Math.abs(sum) >= Math.abs(x[i].calculatedValue)) 
				{
					correction += sum - transition + x[i].calculatedValue;
				} 
				else 
				{
					correction += x[i].calculatedValue - transition + sum;
				}
				
				sum = transition;
			}
			
			// Returning the corrected sum
			return sum + correction;
		}
		
		/**
		 * Rearrange items in `arr` so that all items in `[left, k]` range are the smallest.
		 * The `k`-th element will have the `(k - left + 1)`-th smallest value in `[left, right]`.
		 *
		 * Implements Floyd-Rivest selection algorithm https://en.wikipedia.org/wiki/Floyd-Rivest_algorithm
		 *
		 * @param {Array<number>} arr input array
		 * @param {number} k pivot index
		 * @param {number} [left] left index
		 * @param {number} [right] right index
		 * @returns {void} mutates input array
		 * @example
		 * var arr = [65, 28, 59, 33, 21, 56, 22, 95, 50, 12, 90, 53, 28, 77, 39];
		 * quickselect(arr, 8);
		 * // = [39, 28, 28, 33, 21, 12, 22, 50, 53, 56, 59, 65, 90, 77, 95]
		 */
		private static function quickselect(arr:Array, k:Number, left:Number, right:Number):void
		{
			left = left || 0;
			right = right || arr.length - 1;
			
			while (right > left) 
			{
				// 600 and 0.5 are arbitrary constants chosen in the original paper to minimize execution time
				if (right - left > 600) 
				{
					const n:Number = right - left + 1;
					const m:Number = k - left + 1;
					const z:Number = Math.log(n);
					const s:Number = 0.5 * Math.exp((2 * z) / 3);
					var sd:Number = 0.5 * Math.sqrt((z * s * (n - s)) / n);
					if (m - n / 2 < 0) sd *= -1;
					const newLeft:Number = Math.max(left, Math.floor(k - (m * s) / n + sd));
					const newRight:Number = Math.min(
						right,
						Math.floor(k + ((n - m) * s) / n + sd)
					);
					quickselect(arr, k, newLeft, newRight);
				}
				
				const t:Number = arr[k];
				var i:Number = left;
				var j:Number = right;
				
				swap(arr, left, k);
				if (arr[right] > t) swap(arr, left, right);
				
				while (i < j) {
					swap(arr, i, j);
					i++;
					j--;
					while (arr[i] < t) i++;
					while (arr[j] > t) j--;
				}
				
				if (arr[left] === t) swap(arr, left, j);
				else 
				{
					j++;
					swap(arr, j, right);
				}
				
				if (j <= k) left = j + 1;
				if (k <= j) right = j - 1;
			}
			
			function swap(arr:Array, i:Number, j:Number):void 
			{
				const tmp:Number = arr[i];
				arr[i] = arr[j];
				arr[j] = tmp;
			}
		}
		
		/**
		 * This is the internal implementation of quantiles: when you know
		 * that the order is sorted, you don't need to re-sort it, and the computations
		 * are faster.
		 *
		 * @param {Array<number>} x sample of one or more data points
		 * @param {number} p desired quantile: a number between 0 to 1, inclusive
		 * @returns {number} quantile value
		 * @throws {Error} if p ix outside of the range from 0 to 1
		 * @throws {Error} if x is empty
		 * @example
		 * quantileSorted([3, 6, 7, 8, 8, 9, 10, 13, 15, 16, 20], 0.5); // => 9
		 */
		private static function quantileSorted(x:Array, p:Number):Number
		{
			const xLenght:uint = x.length;
			const idx:Number = xLenght * p;
			
			if (xLenght == 0) 
			{
				//Quantile requires at least one data point.
				return Number.NaN;
			} 
			else if (p < 0 || p > 1) 
			{
				//Quantiles must be between 0 and 1
				return Number.NaN;
			} 
			else if (p == 1) 
			{
				// If p is 1, directly return the last element
				return x[xLenght - 1];
			} 
			else if (p == 0) 
			{
				// If p is 0, directly return the first element
				return x[0];
			}
			else if (idx % 1 != 0) 
			{
				// If p is not integer, return the next element in array
				return x[Math.ceil(idx) - 1];
			} 
			else if (xLenght % 2 == 0) 
			{
				// If the list has even-length, we'll take the average of this number
				// and the next value, if there is one
				return (x[idx - 1] + x[idx]) / 2;
			} 
			else 
			{
				// Finally, in the simple case of an integer value
				// with an odd-length list, return the x value at the index.
				return x[idx];
			}
		}
	}
}