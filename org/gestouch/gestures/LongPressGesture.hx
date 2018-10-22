package org.gestouch.gestures;

import org.gestouch.core.GestureState;
import org.gestouch.core.Touch;
import openfl.events.TimerEvent;
import openfl.utils.Timer;


/**
 * TODO:
 * - add numTapsRequired
 *
 */
@:keepSub
class LongPressGesture extends AbstractContinuousGesture
{
	public var numTouchesRequired:Int = 1;
	/**
	 * The minimum time interval in millisecond fingers must press on the target for the gesture to be recognized.
	 *
	 * @default 500
	 */
	public var minPressDuration:Int = 500;
	public var slop:Float = Gesture.DEFAULT_SLOP;

	private var _timer:Timer;
	private var _numTouchesRequiredReached:Bool;

	public function new(target:Dynamic = null)
	{
		super(target);
	}

	override public function reflect():Class<Dynamic>
	{
		return LongPressGesture;
	}

	override public function reset():Void
	{
		super.reset();

		_numTouchesRequiredReached = false;
		_timer.reset();
	}

	override public function preinit():Void
	{
		super.preinit();

		_timer = new Timer(minPressDuration, 1);
		_timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
	}

	override public function onTouchBegin(touch:Touch):Void
	{
		if (touchesCount > numTouchesRequired)
		{
			failOrIgnoreTouch(touch);
			return;
		}

		if (touchesCount == numTouchesRequired)
		{
			_numTouchesRequiredReached = true;
			_timer.reset();
			_timer.delay = minPressDuration > 1 ? minPressDuration : 1;
			_timer.start();
		}
	}

	override public function onTouchMove(touch:Touch):Void
	{
		if (state == GestureState.POSSIBLE && slop > 0 && touch.locationOffset.length > slop)
		{
			setState(GestureState.FAILED);
		}
		else if (state == GestureState.BEGAN || state == GestureState.CHANGED)
		{
			updateLocation();
			setState(GestureState.CHANGED);
		}
	}

	override public function onTouchEnd(touch:Touch):Void
	{
		if (_numTouchesRequiredReached)
		{
			if (state == GestureState.BEGAN || state == GestureState.CHANGED)
			{
				updateLocation();
				setState(GestureState.ENDED);
			}
			else
			{
				setState(GestureState.FAILED);
			}
		}
		else
		{
			setState(GestureState.FAILED);
		}
	}

	public function timerCompleteHandler(event:TimerEvent = null):Void
	{
		if (state == GestureState.POSSIBLE)
		{
			updateLocation();
			setState(GestureState.BEGAN);
		}
	}
}
