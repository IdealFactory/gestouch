package org.gestouch.gestures;

import openfl.Vector;
import org.gestouch.core.GestureState;
import org.gestouch.core.Touch;
import openfl.events.TimerEvent;
import openfl.geom.Point;
import openfl.utils.Timer;

@:keepSub
class TapGesture extends AbstractDiscreteGesture
{
	public var numTouchesRequired:Int = 1;
	public var numTapsRequired:Int = 1;
	public var slop:Float = Gesture.DEFAULT_SLOP << 2;//iOS has 45px for 132 dpi screen
	public var maxTapDelay:Int = 400;
	public var maxTapDuration:Int = 1500;
	public var maxTapDistance:Float = Gesture.DEFAULT_SLOP << 2;

	private var _timer:Timer;
	private var _numTouchesRequiredReached:Bool;
	private var _tapCounter:Int = 0;
	private var _touchBeginLocations:Vector<Point> = new Vector<Point>();


	public function new(target:Dynamic = null)
	{
		super(target);
	}

	override public function reflect():Class<Dynamic>
	{
		return TapGesture;
	}

	override public function reset():Void
	{
		_numTouchesRequiredReached = false;
		_tapCounter = 0;
		_timer.reset();
		_touchBeginLocations.length = 0;

		super.reset();
	}

	override public function canPreventGesture(preventedGesture:Gesture):Bool
	{
		if (Std.is(preventedGesture, TapGesture) &&
			(cast(preventedGesture, TapGesture).numTapsRequired > this.numTapsRequired))
		{
			return false;
		}
		return true;
	}

	override public function preinit():Void
	{
		super.preinit();

		_timer = new Timer(maxTapDelay, 1);
		_timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
	}

	override public function onTouchBegin(touch:Touch):Void
	{
		if (touchesCount > numTouchesRequired)
		{
			failOrIgnoreTouch(touch);
			return;
		}

		if (touchesCount == 1)
		{
			_timer.reset();
			_timer.delay = maxTapDuration;
			_timer.start();
		}

		if (numTapsRequired > 1)
		{
			if (_tapCounter == 0)
			{
				// Save touch begin locations to check
				_touchBeginLocations.push(touch.location);
			}
			else
			{
				// Quite a dirty check, but should work in most cases
				var found:Bool = false;
				for (loc in _touchBeginLocations)
				{
					// current touch should be near any previous one
					if (Point.distance(touch.location, loc) <= maxTapDistance)
					{
						found = true;
						break;
					}
				}

				if (!found)
				{
					setState(GestureState.FAILED);
					return;
				}
			}
		}

		if (touchesCount == numTouchesRequired)
		{
			_numTouchesRequiredReached = true;
			updateLocation();
		}
	}

	override public function onTouchMove(touch:Touch):Void
	{
		if (slop >= 0 && touch.locationOffset.length > slop)
		{
			setState(GestureState.FAILED);
		}
	}

	override public function onTouchEnd(touch:Touch):Void
	{
		if (!_numTouchesRequiredReached)
		{
			setState(GestureState.FAILED);
		}
		else if (touchesCount == 0)
		{
			// reset flag for the next "full press" cycle
			_numTouchesRequiredReached = false;

			_tapCounter++;
			_timer.reset();

			if (_tapCounter == numTapsRequired)
			{
				setState(GestureState.RECOGNIZED);
			}
			else
			{
				_timer.delay = maxTapDelay;
				_timer.start();
			}
		}
	}

	private function timerCompleteHandler(event:TimerEvent):Void
	{
		if (state == GestureState.POSSIBLE)
		{
			setState(GestureState.FAILED);
		}
	}
}
