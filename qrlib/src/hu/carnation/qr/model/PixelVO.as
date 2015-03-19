//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qr.model{
    import flash.geom.Point;
    import __AS3__.vec.Vector;
    import __AS3__.vec.*;

    public class PixelVO {

        public var active:Boolean;
        public var color:uint;
        public var position:Point;
        public var size:Number;
        public var cornerRadius:Number;
        public var siblings:Vector.<Boolean>;
        public var customColor:uint;
        public var hasCustomColor:Boolean = false;

        public function PixelVO(){
            this.siblings = new Vector.<Boolean>();
            super();
        }

    }
}//package hu.carnation.qr.model
