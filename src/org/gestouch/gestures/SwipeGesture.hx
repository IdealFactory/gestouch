package org.gestouch.gestures;

/**
 * Recognition logic:<br/>
 * 1. should be recognized during <code>maxDuration</code> period<br/>
 * 2. velocity >= minVelocity <b>OR</b> offset >= minOffset
 */
import org.gestouch.core.GestureState;
import org.gestouch.core.Touch;
import openfl.events.TimerEvent;
import openfl.utils.Timer;
import flash.geom.Point;
import openfl.system.Capabilities;
import org.gestouch.utils.GestureUtils;

@:keepSub
class SwipeGesture extends AbstractDiscreteGesture
{
	private static var ANGLE:Float = 40 * GestureUtils.DEGREES_TO_RADIANS;
	private static var MAX_DURATION:Int = 500;
	private static var MIN_OFFSET:Float = Capabilities.screenDPI / 6;
	private static var MIN_VELOCITY:Float = 2 * MIN_OFFSET / MAX_DURATION;

	/**
	 * "Dirty" region around touch begin location which is not taken into account for
	 * recognition/failing algorithms.
	 *
	 * @default Gesture.DEFAULT_SLOP
	 */
	public var slop:Float = Gesture.DEFAULT_SLOP;
	public var numTouchesRequired:Int = 1;
	public var direction:Int = SwipeGestureDirection.ORTHOGONAL;

	/**
	 * The duration of period (in milliseconds) in which SwipeGesture must be recognized.
	 * If gesture is not recognized during this period it fails. Default value is 500 (half a
	 * second) and generally should not be changed. You can change it though for some special
	 * cases, most likely together with <code>minVelocity</code> and <code>minOffset</code>
	 * to achieve really custom behavior.
	 *
	 * @default 500
	 *
	 * @see #minVelocity
	 * @see #minOffset
	 */
	public var maxDuration:Int = MAX_DURATION;

	/**
	 * Minimum offset (in pixels) for gesture to be recognized.
	 * Default value is <code>Capabilities.screenDPI / 6</code> and generally should not
	 * be changed.
	 */
	public var minOffset:Float = MIN_OFFSET;

	/**
	 * Minimum velocity (in pixels per millisecond) for gesture to be recognized.
	 * Default value is <code>2 * minOffset / maxDuration</code> and generally should not
	 * be changed.
	 *
	 * @see #minOffset
	 * @see #minDuration
	 */
	public var minVelocity:Float = MIN_VELOCITY;

	private var _offset:Point = new Point();
	private var _startTime:Int;
	private var _noDirection:Bool;
	private var _avrgVel:Point = new Point();
	private var _timer:Timer;

	public function new(target:Dynamic = null)
	{
		super(target);
	}

	public var offsetX(get, never):Float;
	private function get_offsetX():Float
	{
		return _offset.x;
	}

	public var offsetY(get, never):Float;
	private function get_offsetY():Float
	{
		return _offset.y;
	}

	override public function reflect():Class<Dynamic>
	{
		return SwipeGesture;
	}

	override public function reset():Void
	{
		_startTime = 0;
		_offset.x = 0;
		_offset.y = 0;
		_timer.reset();

		super.reset();
	}

	override public function preinit():Void
	{
		super.preinit();

		_timer = new Timer(maxDuration, 1);
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
			// Because we want to fail as quick as possible
			_startTime = touch.time;

			_timer.reset();
			_timer.delay = maxDuration;
			_timer.start();
		}

		if (touchesCount == numTouchesRequired)
		{
			updateLocation();
			_avrgVel.x = _avrgVel.y = 0;

			// cache direction condition for performance
			_noDirection = (SwipeGestureDirection.ORTHOGONAL & direction) == 0;
		}
	}

	override public function onTouchMove(touch:Touch):Void
	{
		if (touchesCount < numTouchesRequired)
			return;

		var totalTime:Int = touch.time - _startTime;
		if (totalTime == 0)
			return;//It was somehow THAT MUCH performant on one Android tablet

		var prevCentralPointX:Float = centralPoint.x;
		var prevCentralPointY:Float = centralPoint.y;
		updateCentralPoint();

		_offset.x = centralPoint.x - location.x;
		_offset.y = centralPoint.y - location.y;
		var offsetLength:Float = _offset.length;

		// average velocity (total offset to total duration)
		_avrgVel.x = _offset.x / totalTime;
		_avrgVel.y = _offset.y / totalTime;
		var avrgVel:Float = _avrgVel.length;

		if (_noDirection)
		{
			if ((offsetLength > slop || slop != slop) &&
				(avrgVel >= minVelocity || offsetLength >= minOffset))
			{
				setState(GestureState.RECOGNIZED);
			}
		}
		else
		{
			var recentOffsetX:Float = centralPoint.x - prevCentralPointX;
			var recentOffsetY:Float = centralPoint.y - prevCentralPointY;
			//faster Math.abs()
			var absVelX:Float = _avrgVel.x > 0 ? _avrgVel.x : -_avrgVel.x;
			var absVelY:Float = _avrgVel.y > 0 ? _avrgVel.y : -_avrgVel.y;

			if (absVelX > absVelY)
			{
				var absOffsetX:Float = _offset.x > 0 ? _offset.x : -_offset.x;

				if (absOffsetX > slop || slop != slop)//faster isNaN()
				{
					if ((recentOffsetX < 0 && (direction & SwipeGestureDirection.LEFT) == 0) ||
						(recentOffsetX > 0 && (direction & SwipeGestureDirection.RIGHT) == 0) ||
						Math.abs(Math.atan(_offset.y/_offset.x)) > ANGLE)
					{
						// movement in opposite direction
						// or too much diagonally

						setState(GestureState.FAILED);
					}
					else if (absVelX >= minVelocity || absOffsetX >= minOffset)
					{
						_offset.y = 0;
						setState(GestureState.RECOGNIZED);
					}
				}
			}
			else if (absVelY > absVelX)
			{
				var absOffsetY:Float = _offset.y > 0 ? _offset.y : -_offset.y;
				if (absOffsetY > slop || slop != slop)//faster isNaN()
				{
					if ((recentOffsetY < 0 && (direction & SwipeGestureDirection.UP) == 0) ||
						(recentOffsetY > 0 && (direction & SwipeGestureDirection.DOWN) == 0) ||
						Math.abs(Math.atan(_offset.x/_offset.y)) > ANGLE)
					{
						// movement in opposite direction
						// or too much diagonally

						setState(GestureState.FAILED);
					}
					else if (absVelY >= minVelocity || absOffsetY >= minOffset)
					{
						_offset.x = 0;
						setState(GestureState.RECOGNIZED);
					}
				}
			}
			// Give some tolerance for accidental offset on finger press (slop)
			else if (offsetLength > slop || slop != slop)//faster isNaN()
			{
				setState(GestureState.FAILED);
			}
		}
	}

	override public function onTouchEnd(touch:Touch):Void
	{
		if (touchesCount < numTouchesRequired)
		{
			setState(GestureState.FAILED);
		}
	}

	override public function resetNotificationProperties():Void
	{
		super.resetNotificationProperties();

		_offset.x = _offset.y = 0;
	}

	public function timerCompleteHandler(event:TimerEvent):Void
	{
		if (state == GestureState.POSSIBLE)
		{
			setState(GestureState.FAILED);
		}
	}
}
