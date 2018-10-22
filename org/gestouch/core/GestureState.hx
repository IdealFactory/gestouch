package org.gestouch.core;

import org.gestouch.gestures.Gesture;

class GestureState
{
    private static inline var POSSIBLE_NAME:String      = "GestureState.POSSIBLE";
    private static inline var RECOGNIZED_NAME:String    = "GestureState.RECOGNIZED";
    private static inline var BEGAN_NAME:String         = "GestureState.BEGAN";
    private static inline var CHANGED_NAME:String       = "GestureState.CHANGED";
    private static inline var ENDED_NAME:String         = "GestureState.ENDED";
    private static inline var CANCELLED_NAME:String     = "GestureState.CANCELLED";
    private static inline var FAILED_NAME:String        = "GestureState.FAILED";

	public static var POSSIBLE(default, null):GestureState = new GestureState(POSSIBLE_NAME, [RECOGNIZED_NAME, BEGAN_NAME, FAILED_NAME]);
	public static var RECOGNIZED(default, null):GestureState = new GestureState(RECOGNIZED_NAME, [POSSIBLE_NAME], true);
	public static var BEGAN(default, null):GestureState = new GestureState(BEGAN_NAME, [CHANGED_NAME, ENDED_NAME, CANCELLED_NAME]);
	public static var CHANGED(default, null):GestureState = new GestureState(CHANGED_NAME, [CHANGED_NAME, ENDED_NAME, CANCELLED_NAME]);
	public static var ENDED(default, null):GestureState = new GestureState(ENDED_NAME, [POSSIBLE_NAME],true);
	public static var CANCELLED(default, null):GestureState = new GestureState(CANCELLED_NAME, [POSSIBLE_NAME], true);
	public static var FAILED(default, null):GestureState = new GestureState(FAILED_NAME, [POSSIBLE_NAME], true);

	private var name:String;
	private var eventType:String;
	private var validTransitionStateMap:Map<String, Bool> = new Map<String, Bool>();

	public function new(name:String, validTransitions:Array<String>, isEndState:Bool = false)
	{
		this.name = name;
		this.eventType = "gesture" + name.charAt(13).toUpperCase() + name.substr(14).toLowerCase();
		this.isEndState = isEndState;

		setValidNextStates(validTransitions);
	}

	public function toString():String
	{
		return name;
	}

	private function setValidNextStates(states:Array<String>):Void
	{
		for (i in 0...states.length)
		{
			validTransitionStateMap.set(states[i], true);
		}
	}

	@:allow(org.gestouch.gestures.Gesture)
	private function toEventType():String
	{
		return eventType;
	}

	@:allow(org.gestouch.gestures.Gesture)
	private function canTransitionTo(state:GestureState):Bool
	{
		return validTransitionStateMap.exists(state.toString());
	}

	@:allow(org.gestouch.gestures.Gesture)
	private var isEndState(get, null):Bool;
	private function get_isEndState():Bool
	{
		return isEndState;
	}
}
