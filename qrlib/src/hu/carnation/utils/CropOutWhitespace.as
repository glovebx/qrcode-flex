//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.utils{
    import flash.geom.Rectangle;
    import flash.display.BitmapData;
    import flash.geom.Matrix;

    public class CropOutWhitespace {

        public function CropOutWhitespace(){
            throw (new Error("CropOutWhitespace class is static container only"));
        }

        public static function crop(bd:BitmapData):BitmapData{
            var rect:Rectangle = bd.getColorBoundsRect(0xFF000000, 0, false);
            var bmd2:BitmapData = new BitmapData(rect.width, rect.height, true, 0);
            bmd2.draw(bd, new Matrix(1, 0, 0, 1, -(rect.x), -(rect.y)));
            return (bmd2);
        }


    }
}//package hu.carnation.utils
