package org.gestouch.input;

import Reflect;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.events.EventPhase;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;
import org.gestouch.core.IInputAdapter;
import org.gestouch.core.TouchesManager;

class NativeInputAdapter implements IInputAdapter
{
	public static var MOUSE_TOUCH_POINT_ID(default, never):Int = 0;

	private var _stage:Stage;
	private var _explicitlyHandleTouchEvents:Bool;
	private var _explicitlyHandleMouseEvents:Bool;

	public function new(stage:Stage, explicitlyHandleTouchEvents:Bool = false, explicitlyHandleMouseEvents:Bool = false)
	{
		if (stage == null)
		{
			throw "Stage must be not null.";
		}

		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

		_stage = stage;

		_explicitlyHandleTouchEvents = explicitlyHandleTouchEvents;
		_explicitlyHandleMouseEvents = explicitlyHandleMouseEvents;
	}

	public var touchesManager(default, set):TouchesManager;
	private function set_touchesManager(value:TouchesManager):TouchesManager
	{
		touchesManager = value;

		return touchesManager;
	}

	public function init():Void
	{
		if (Multitouch.supportsTouchEvents || _explicitlyHandleTouchEvents)
		{
			_stage.addEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler, true);
			_stage.addEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler, false);
			_stage.addEventListener(TouchEvent.TOUCH_MOVE, touchMoveHandler, true);
			_stage.addEventListener(TouchEvent.TOUCH_MOVE, touchMoveHandler, false);
			// Maximum priority to prevent event hijacking and loosing the touch
			_stage.addEventListener(TouchEvent.TOUCH_END, touchEndHandler, true, 1024);
			_stage.addEventListener(TouchEvent.TOUCH_END, touchEndHandler, false, 1024);
		}

		if (!Multitouch.supportsTouchEvents || _explicitlyHandleMouseEvents)
		{
			_stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
			_stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false);
		}
	}

	public function onDispose():Void
	{
		touchesManager = null;

		_stage.removeEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler, true);
		_stage.removeEventListener(TouchEvent.TOUCH_BEGIN, touchBeginHandler, false);
		_stage.removeEventListener(TouchEvent.TOUCH_MOVE, touchMoveHandler, true);
		_stage.removeEventListener(TouchEvent.TOUCH_MOVE, touchMoveHandler, false);
		_stage.removeEventListener(TouchEvent.TOUCH_END, touchEndHandler, true);
		_stage.removeEventListener(TouchEvent.TOUCH_END, touchEndHandler, false);

		_stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, true);
		_stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false);
		uninstallMouseListeners();
	}

	private function installMouseListeners():Void
	{
		_stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, true);
		_stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false);
		// Maximum priority to prevent event hijacking
		_stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, true, 1024);
		_stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 1024);
	}

	private function uninstallMouseListeners():Void
	{
		_stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, true);
		_stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler, false);
		// Maximum priority to prevent event hijacking
		_stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, true);
		_stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false);
	}

	private function touchBeginHandler(event:TouchEvent):Void
	{
		// We listen in EventPhase.CAPTURE_PHASE or EventPhase.AT_TARGET
		// (to catch on empty stage) phases only
		if (event.eventPhase == EventPhase.BUBBLING_PHASE)
			return;

		touchesManager.onTouchBegin(event.touchPointID, event.stageX, event.stageY, cast(event.target, DisplayObject));
	}

	private function touchMoveHandler(event:TouchEvent):Void
	{
		// We listen in EventPhase.CAPTURE_PHASE or EventPhase.AT_TARGET
		// (to catch on empty stage) phases only
		if (event.eventPhase == EventPhase.BUBBLING_PHASE)
			return;

		touchesManager.onTouchMove(event.touchPointID, event.stageX, event.stageY);
	}

	private function touchEndHandler(event:TouchEvent):Void
	{
		// We listen in EventPhase.CAPTURE_PHASE or EventPhase.AT_TARGET
		// (to catch on empty stage) phases only
		if (event.eventPhase == EventPhase.BUBBLING_PHASE)
			return;

		if (Reflect.hasField(event, "isTouchPointCanceled") && Reflect.getProperty(event, "isTouchPointCanceled"))
		{
			touchesManager.onTouchCancel(event.touchPointID, event.stageX, event.stageY);
		}
		else
		{
			touchesManager.onTouchEnd(event.touchPointID, event.stageX, event.stageY);
		}
	}

	private function mouseDownHandler(event:MouseEvent):Void
	{
		// We listen in EventPhase.CAPTURE_PHASE or EventPhase.AT_TARGET
		// (to catch on empty stage) phases only
		if (event.eventPhase == EventPhase.BUBBLING_PHASE)
			return;

		var touchAccepted:Bool = touchesManager.onTouchBegin(MOUSE_TOUCH_POINT_ID, event.stageX, event.stageY, cast(event.target, DisplayObject));

		if (touchAccepted)
		{
			installMouseListeners();
		}
	}

	private function mouseMoveHandler(event:MouseEvent):Void
	{
		// We listen in EventPhase.CAPTURE_PHASE or EventPhase.AT_TARGET
		// (to catch on empty stage) phases only
		if (event.eventPhase == EventPhase.BUBBLING_PHASE)
			return;

		touchesManager.onTouchMove(MOUSE_TOUCH_POINT_ID, event.stageX, event.stageY);
	}

	private function mouseUpHandler(event:MouseEvent):Void
	{
		// We listen in EventPhase.CAPTURE_PHASE or EventPhase.AT_TARGET
		// (to catch on empty stage) phases only
		if (event.eventPhase == EventPhase.BUBBLING_PHASE)
			return;

		touchesManager.onTouchEnd(MOUSE_TOUCH_POINT_ID, event.stageX, event.stageY);

		if (touchesManager.activeTouchesCount == 0)
		{
			uninstallMouseListeners();
		}
	}
}
