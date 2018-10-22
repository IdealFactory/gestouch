package org.gestouch.gestures;

class SwipeGestureDirection
{
	public static inline var RIGHT:Int = 1 << 0;
	public static inline var LEFT:Int = 1 << 1;
	public static inline var UP:Int = 1 << 2;
	public static inline var DOWN:Int = 1 << 3;

	public static inline var NO_DIRECTION:Int = 0;
	public static inline var HORIZONTAL:Int = RIGHT | LEFT;
	public static inline var VERTICAL:Int = UP | DOWN;
	public static inline var ORTHOGONAL:Int = RIGHT | LEFT | UP | DOWN;
}
