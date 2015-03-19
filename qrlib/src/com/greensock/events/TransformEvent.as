//Created by Action Script Viewer - http://www.buraks.com/asv
package com.greensock.events{
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class TransformEvent extends Event {

        public static const MOVE:String = "tmMove";
        public static const SCALE:String = "tmScale";
        public static const ROTATE:String = "tmRotate";
        public static const SELECT:String = "tmSelect";
        public static const MOUSE_DOWN:String = "tmMouseDown";
        public static const SELECT_MOUSE_DOWN:String = "tmSelectMouseDown";
        public static const SELECT_MOUSE_UP:String = "tmSelectMouseUp";
        public static const ROLL_OVER_SELECTED:String = "tmRollOverSelected";
        public static const ROLL_OUT_SELECTED:String = "tmRollOutSelected";
        public static const DELETE:String = "tmDelete";
        public static const SELECTION_CHANGE:String = "tmSelectionChange";
        public static const DESELECT:String = "tmDeselect";
        public static const CLICK_OFF:String = "tmClickOff";
        public static const UPDATE:String = "tmUpdate";
        public static const DEPTH_CHANGE:String = "tmDepthChange";
        public static const DESTROY:String = "tmDestroy";
        public static const FINISH_INTERACTIVE_MOVE:String = "tmFinishInteractiveMove";
        public static const FINISH_INTERACTIVE_SCALE:String = "tmFinishInteractiveScale";
        public static const FINISH_INTERACTIVE_ROTATE:String = "tmFinishInteractiveRotate";
        public static const DOUBLE_CLICK:String = "tmDoubleClick";

        public var items:Array;
        public var mouseEvent:MouseEvent;

        public function TransformEvent($type:String, $items:Array, $mouseEvent:MouseEvent=null, $bubbles:Boolean=false, $cancelable:Boolean=false){
            super($type, $bubbles, $cancelable);
            this.items = $items;
            this.mouseEvent = $mouseEvent;
        }

        override public function clone():Event{
            return (new TransformEvent(this.type, this.items, this.mouseEvent, this.bubbles, this.cancelable));
        }


    }
}//package com.greensock.events
