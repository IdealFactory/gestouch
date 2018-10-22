package org.gestouch.events;

import openfl.events.Event;
import org.gestouch.core.GestureState;

class GestureEvent extends Event
{
	public static inline var GESTURE_POSSIBLE:String = "gesturePossible";
	public static inline var GESTURE_RECOGNIZED:String = "gestureRecognized";
	public static inline var GESTURE_BEGAN:String = "gestureBegan";
	public static inline var GESTURE_CHANGED:String = "gestureChanged";
	public static inline var GESTURE_ENDED:String = "gestureEnded";
	public static inline var GESTURE_CANCELLED:String = "gestureCancelled";
	public static inline var GESTURE_FAILED:String = "gestureFailed";

	public static inline var GESTURE_STATE_CHANGE:String = "gestureStateChange";

	public var newState:GestureState;
	public var oldState:GestureState;

	public function new(type:String, newState:GestureState, oldState:GestureState)
	{
		super(type, false, false);

		this.newState = newState;
		this.oldState = oldState;
	}

	override public function clone():Event
	{
		return new GestureEvent(type, newState, oldState);
	}

	override public function toString():String
	{
		return formatToString("GestureEvent", "type", "oldState", "newState");
	}
}
