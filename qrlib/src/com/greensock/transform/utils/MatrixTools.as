//Created by Action Script Viewer - http://www.buraks.com/asv
package com.greensock.transform.utils{
    import flash.geom.Matrix;

    public class MatrixTools {

        private static const VERSION:Number = 1;


        public static function getDirectionX($m:Matrix):Number{
            var sx:Number = Math.sqrt((($m.a * $m.a) + ($m.b * $m.b)));
            if ($m.a < 0){
                return (-(sx));
            };
            return (sx);
        }

        public static function getDirectionY($m:Matrix):Number{
            var sy:Number = Math.sqrt((($m.c * $m.c) + ($m.d * $m.d)));
            if ($m.d < 0){
                return (-(sy));
            };
            return (sy);
        }

        public static function getScaleX($m:Matrix):Number{
            var sx:Number = Math.sqrt((($m.a * $m.a) + ($m.b * $m.b)));
            if (((($m.a < 0)) && (($m.d > 0)))){
                return (-(sx));
            };
            return (sx);
        }

        public static function getScaleY($m:Matrix):Number{
            var sy:Number = Math.sqrt((($m.c * $m.c) + ($m.d * $m.d)));
            if (((($m.d < 0)) && (($m.a > 0)))){
                return (-(sy));
            };
            return (sy);
        }

        public static function getAngle($m:Matrix):Number{
            var a:Number = Math.atan2($m.b, $m.a);
            if (((($m.a < 0)) && (($m.d >= 0)))){
                return ((((a)<=0) ? (a + Math.PI) : (a - Math.PI)));
            };
            return (a);
        }

        public static function getFlashAngle($m:Matrix):Number{
            var a:Number = Math.atan2($m.b, $m.a);
            if ((((a < 0)) && ((($m.a * $m.d) < 0)))){
                a = ((a - Math.PI) % Math.PI);
            };
            return (a);
        }

        public static function scaleMatrix($m:Matrix, $sx:Number, $sy:Number, $angle:Number, $skew:Number):void{
            var cosAngle:Number = Math.cos($angle);
            var sinAngle:Number = Math.sin($angle);
            var cosSkew:Number = Math.cos($skew);
            var sinSkew:Number = Math.sin($skew);
            var a:Number = (((cosAngle * $m.a) + (sinAngle * $m.b)) * $sx);
            var b:Number = (((cosAngle * $m.b) - (sinAngle * $m.a)) * $sy);
            var c:Number = (((cosSkew * $m.c) - (sinSkew * $m.d)) * $sx);
            var d:Number = (((cosSkew * $m.d) + (sinSkew * $m.c)) * $sy);
            $m.a = ((cosAngle * a) - (sinAngle * b));
            $m.b = ((cosAngle * b) + (sinAngle * a));
            $m.c = ((cosSkew * c) + (sinSkew * d));
            $m.d = ((cosSkew * d) - (sinSkew * c));
        }

        public static function getSkew($m:Matrix):Number{
            return (Math.atan2($m.c, $m.d));
        }

        public static function setSkewX($m:Matrix, $skewX:Number):void{
            var sy:Number = Math.sqrt((($m.c * $m.c) + ($m.d * $m.d)));
            $m.c = (-(sy) * Math.sin($skewX));
            $m.d = (sy * Math.cos($skewX));
        }

        public static function setSkewY($m:Matrix, $skewY:Number):void{
            var sx:Number = Math.sqrt((($m.a * $m.a) + ($m.b * $m.b)));
            $m.a = (sx * Math.cos($skewY));
            $m.b = (sx * Math.sin($skewY));
        }


    }
}//package com.greensock.transform.utils
