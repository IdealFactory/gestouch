package org.gestouch.gestures;

import org.gestouch.core.GestureState;
import org.gestouch.core.Touch;
import openfl.geom.Point;

@:keepSub
class ZoomGesture extends AbstractContinuousGesture
{
	public var slop:Float = Gesture.DEFAULT_SLOP;
	public var lockAspectRatio:Bool = true;

	private var _touch1:Touch;
	private var _touch2:Touch;
	private var _transformVector:Point;
	private var _initialDistance:Float;

	public function new(target:Dynamic = null)
	{
		super(target);
	}

	public var scaleX:Float = 1;
	public var scaleY:Float = 1;

	override public function reflect():Class<Dynamic>
	{
		return ZoomGesture;
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
		else// == 2
		{
			_touch2 = touch;

			_transformVector = _touch2.location.subtract(_touch1.location);
			_initialDistance = _transformVector.length;
		}
	}

	override public function onTouchMove(touch:Touch):Void
	{
		if (touchesCount < 2)
			return;

		var currTransformVector:Point = _touch2.location.subtract(_touch1.location);

		if (state == GestureState.POSSIBLE)
		{
			var d:Float = currTransformVector.length - _initialDistance;
			var absD:Float = d >= 0 ? d : -d;
			if (absD < slop)
			{
				// Not recognized yet
				return;
			}

			if (slop > 0)
			{
				// adjust _transformVector to avoid initial "jump"
				var slopVector:Point = currTransformVector.clone();
				slopVector.normalize(_initialDistance + (d >= 0 ? slop : -slop));
				_transformVector = slopVector;
			}
		}

		if (lockAspectRatio)
		{
			scaleX *= currTransformVector.length / _transformVector.length;
			scaleY = scaleX;
		}
		else
		{
			scaleX *= currTransformVector.x / _transformVector.x;
			scaleY *= currTransformVector.y / _transformVector.y;
		}

		_transformVector.x = currTransformVector.x;
		_transformVector.y = currTransformVector.y;

		updateLocation();

		if (state == GestureState.POSSIBLE)
		{
			setState(GestureState.BEGAN);
		}
		else
		{
			setState(GestureState.CHANGED);
		}
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
		else//== 1
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

		scaleX = scaleY = 1;
	}
}
