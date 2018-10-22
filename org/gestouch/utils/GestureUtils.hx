package org.gestouch.utils;

import openfl.geom.Point;
import openfl.system.Capabilities;

class GestureUtils
{
	/**
	 * Precalculated coefficient used to convert 'inches per second' value to 'pixels per millisecond' value.
	 */
	public static var IPS_TO_PPMS(default, never):Float = Capabilities.screenDPI * 0.001;
	/**
	 * Precalculated coefficient used to convert radians to degress.
	 */
	public static var RADIANS_TO_DEGREES(default, never):Float = 57.295779513082325; // 180 / Math.PI;
	/**
	 * Precalculated coefficient used to convert degress to radians.
	 */
	public static var DEGREES_TO_RADIANS(default, never):Float = 0.017453292519943; // Math.PI / 180;
	/**
	 * Precalculated coefficient Math.PI * 2
	 */
	public static var PI_DOUBLE(default, never):Float = Math.PI * 2;
	public static var GLOBAL_ZERO(default, never):Point = new Point();
}
