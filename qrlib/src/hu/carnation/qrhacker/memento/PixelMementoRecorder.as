//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker.memento{
    import flash.events.EventDispatcher;
    import __AS3__.vec.Vector;
    import flash.events.Event;
    import __AS3__.vec.*;

    public class PixelMementoRecorder extends EventDispatcher {

        private var mementos:Vector.<PixelMemento>;
        private var mementoIndex:int;
        private var historyLength:int = 80;

        public function PixelMementoRecorder(){
            this.mementos = new Vector.<PixelMemento>();
            this.mementoIndex = 0;
        }

        public function get pixelMemento():PixelMemento{
            return (this.mementos[this.mementoIndex]);
        }

        public function undo():void{
            if (this.mementoIndex > 0){
                this.mementoIndex--;
                if (((!((this.pixelMemento.type == PixelMemento.UNDO))) && ((this.mementoIndex > 0)))){
                    this.mementoIndex--;
                };
                trace(("PixelMementoRecorder.undo() index: " + this.mementoIndex));
                dispatchEvent(new Event(Event.CHANGE));
            };
        }

        public function reset():void{
            this.mementos = new Vector.<PixelMemento>();
            this.mementoIndex = 0;
        }

        public function addState(pixelMemento:PixelMemento):void{
            if (this.mementoIndex != this.mementos.length){
                if ((this.mementoIndex % 2) == 0){
                    this.mementos.splice(this.mementoIndex, (this.mementos.length - this.mementoIndex));
                } else {
                    this.mementos.splice((this.mementoIndex + 1), ((this.mementos.length - this.mementoIndex) - 1));
                };
            };
            this.mementos.push(pixelMemento);
            while (this.mementos.length > this.historyLength) {
                this.mementos.shift();
            };
            this.mementoIndex = this.mementos.length;
        }

        public function redo():void{
            if (this.mementoIndex < (this.mementos.length - 1)){
                this.mementoIndex++;
                if (((!((this.pixelMemento.type == PixelMemento.REDO))) && ((this.mementoIndex < (this.mementos.length - 1))))){
                    this.mementoIndex++;
                };
                trace(("PixelMementoRecorder.redo() index: " + this.mementoIndex));
                dispatchEvent(new Event(Event.CHANGE));
            };
        }


    }
}//package hu.carnation.qrhacker.memento
