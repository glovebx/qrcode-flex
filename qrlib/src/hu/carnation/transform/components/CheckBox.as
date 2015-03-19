//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform.components{
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class CheckBox extends MovieClip {

        public function CheckBox():void{
            addFrameScript(0, this.frame1, 1, this.frame2);
            if (stage){
                this.init();
            } else {
                this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
            };
        }

        private function init(_arg1:Event=null):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.addEventListener(Event.REMOVED_FROM_STAGE, this.dispose, false, 0, true);
            this.addEventListener(MouseEvent.CLICK, this.onClick, false, 0, true);
            this.buttonMode = true;
            this.mouseChildren = false;
        }

        private function dispose(_arg1:Event=null):void{
            removeEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
            this.removeEventListener(MouseEvent.CLICK, this.onClick);
        }

        public function toggleSelected():void{
            if (this.currentFrame == 1){
                gotoAndStop(2);
            } else {
                gotoAndStop(1);
            };
            dispatchEvent(new Event(Event.CHANGE));
        }

        private function onClick(_arg1:MouseEvent=null):void{
            this.toggleSelected();
        }

        public function setSelect():void{
            gotoAndStop(2);
        }

        public function get selected():Boolean{
            return ((this.currentFrame == 2));
        }

        function frame1(){
            stop();
        }

        function frame2(){
            stop();
        }


    }
}//package hu.carnation.transform.components
