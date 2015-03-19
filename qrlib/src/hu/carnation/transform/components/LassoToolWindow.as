//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform.components{
    import flash.display.Sprite;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    public class LassoToolWindow extends Sprite {

        public static const OK_CLICK:String = "okClick";
        public static const CANCEL_CLICK:String = "cancelClick";
        public static const TOGGLEMASK_CLICK:String = "togglemaskClick";

        public var okButton:MovieClip;//instance name
        public var cancelButton:MovieClip;//instance name
        public var toggleMaskButton:MovieClip;//instance name

        public function LassoToolWindow():void{
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        private function init(_arg1:Event):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.addEventListener(Event.REMOVED_FROM_STAGE, this.dispose, false, 0, true);
            this.addEventListener(MouseEvent.MOUSE_DOWN, this.onPanelMouseDown, false, 0, true);
            this.okButton.labelTf.text = "DONE";
            this.cancelButton.labelTf.text = "CANCEL";
            this.toggleMaskButton.labelTf.text = "PREVIEW";
            this.okButton.buttonMode = (this.cancelButton.buttonMode = (this.toggleMaskButton.buttonMode = true));
            this.okButton.mouseChildren = (this.cancelButton.mouseChildren = (this.toggleMaskButton.mouseChildren = false));
            this.okButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.cancelButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.toggleMaskButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.okButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.cancelButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.toggleMaskButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.okButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.cancelButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.toggleMaskButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
        }

        private function onButtonClick(_arg1:MouseEvent):void{
            _arg1.stopImmediatePropagation();
            switch (_arg1.currentTarget){
                case this.okButton:
                    dispatchEvent(new Event(OK_CLICK));
                    return;
                case this.cancelButton:
                    dispatchEvent(new Event(CANCEL_CLICK));
                    return;
                case this.toggleMaskButton:
                    dispatchEvent(new Event(TOGGLEMASK_CLICK));
                    return;
            };
        }

        private function onButtonOver(_arg1:MouseEvent):void{
            var _local2:MovieClip = MovieClip(_arg1.currentTarget);
            _local2.gotoAndStop(2);
        }

        private function onButtonOut(_arg1:MouseEvent):void{
            var _local2:MovieClip = MovieClip(_arg1.currentTarget);
            _local2.gotoAndStop(1);
        }

        private function onPanelMouseDown(_arg1:MouseEvent):void{
            this.addEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp, false, 0, true);
            this.startDrag(false, new Rectangle(0, 0, (stage.stageWidth - this.width), (stage.stageHeight - this.height)));
        }

        private function onPanelMouseUp(_arg1:MouseEvent):void{
            this.stopDrag();
            this.removeEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp);
        }

        private function dispose(_arg1:Event):void{
            removeEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
        }


    }
}//package hu.carnation.transform.components
