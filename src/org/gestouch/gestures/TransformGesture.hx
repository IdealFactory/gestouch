package org.gestouch.gestures;

import org.gestouch.core.GestureState;
import org.gestouch.core.Touch;
import openfl.geom.Point;

@:keepSub
class TransformGesture extends AbstractContinuousGesture
{
	public var slop:Float = Gesture.DEFAULT_SLOP;

	private var _touch1:Touch;
	private var _touch2:Touch;
	private var _transformVector:Point;

	public function new(target:Dynamic = null)
	{
		super(target);
	}

	public var scale:Float = 1;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var rotation:Float = 0;

	override public function reflect():Class<Dynamic>
	{
		return TransformGesture;
	}

	override public function reset():Void
	{
		_touch1 = null;
		_touch2 = null;

		super.reset();
	}

	override public function onTouchBegin(touch:Touch):Void
	{
		if (touchesCount > 2)
		{
			failOrIgnoreTouch(touch);
			return;
		}

		if (touchesCount == 1)
		{
			_touch1 = touch;
		}
		else
		{
			_touch2 = touch;

			_transformVector = _touch2.location.subtract(_touch1.location);
		}

		updateLocation();

		if (state == GestureState.BEGAN || state == GestureState.CHANGED)
		{
			// notify that location (and amount of touches) has changed
			setState(GestureState.CHANGED);
		}
	}

	override public function onTouchMove(touch:Touch):Void
	{
		var prevLocation:Point = location.clone();
		updateLocation();

		var currTransformVector:Point;

		if (state == GestureState.POSSIBLE)
		{
			if (slop > 0 && touch.locationOffset.length < slop)
			{
				// Not recognized yet
				if (_touch2 != null)
				{
					// Recalculate _transformVector to avoid initial "jump" on recognize
					_transformVector = _touch2.location.subtract(_touch1.location);
				}
				return;
			}
		}

		if (_touch2 != null)
		{
			currTransformVector = _touch2.location.subtract(_touch1.location);

			rotation = Math.atan2(currTransformVector.y, currTransformVector.x) - Math.atan2(_transformVector.y, _transformVector.x);
			scale = currTransformVector.length / _transformVector.length;
			_transformVector = _touch2.location.subtract(_touch1.location);
		}

		offsetX = location.x - prevLocation.x;
		offsetY = location.y - prevLocation.y;

		setState(state == GestureState.POSSIBLE ? GestureState.BEGAN : GestureState.CHANGED);
	}

	override public function onTouchEnd(touch:Touch):Void
	{
		if (touchesCount == 0)
		{
			if (state == GestureState.BEGAN || state == GestureState.CHANGED)
			{
				setState(GestureState.ENDED);
			}
			else if (state == GestureState.POSSIBLE)
			{
				setState(GestureState.FAILED);
			}
		}
		else// == 1
		{
			if (touch == _touch1)
			{
				_touch1 = _touch2;
			}
			_touch2 = null;

			if (state == GestureState.BEGAN || state == GestureState.CHANGED)
			{
				updateLocation();
				setState(GestureState.CHANGED);
			}
		}
	}

	override public function resetNotificationProperties():Void
	{
		super.resetNotificationProperties();

		offsetX = offsetY = 0;
		rotation = 0;
		scale = 1;
	}
}
