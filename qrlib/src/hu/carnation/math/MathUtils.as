//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.math{
    public class MathUtils {

        public static const RAD2DEG:Number = (180 / Math.PI);//57.2957795130823


        public static function rangeRandom(low:Number, high:Number, rounding:Boolean=false):Number{
            var rnd:Number = ((Math.random() * (high - low)) + low);
            if (rounding == true){
                rnd = Math.floor((rnd + 1));
            };
            return (rnd);
        }

        public static function plusMinusRandom():int{
            var result:int = (((Math.random())>0.5) ? 1 : -1);
            return (result);
        }

        public static function rotation(pointA:Object, pointB:Object, degrees:Boolean=false):Number{
            var calculated_rotation:Number = Math.atan2((pointB.y - pointA.y), (pointB.x - pointA.x));
            if (degrees == true){
                calculated_rotation = (calculated_rotation * MathUtils.RAD2DEG);
            };
            return (calculated_rotation);
        }


    }
}//package hu.carnation.math
