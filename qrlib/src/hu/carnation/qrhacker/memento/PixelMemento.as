//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker.memento{
    import hu.carnation.qrhacker.display.Pixel;

    public class PixelMemento {

        public static const UNDO:String = "undo";
        public static const REDO:String = "redo";

        public var isActive:Boolean;
        public var customColor:uint;
        public var pixel:Pixel;
        public var hasCustomColor:Boolean = false;
        public var type:String;

        public function PixelMemento(pixel:Pixel, type:String){
            this.pixel = pixel;
            this.type = type;
        }

    }
}//package hu.carnation.qrhacker.memento
