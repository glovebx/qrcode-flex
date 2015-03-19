//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.math{
    import flash.geom.Point;

    public class GraphicsHelper {


        public static function getDistanceFromLine(a:Point, b:Point, c:Point, as_seg:Boolean=false):Object{
            var dx:Number;
            var dy:Number;
            c.y = (c.y * -1);
            var obj:Object = new Object();
            obj.dist = -1;
            obj.pt = new Point();
            var m:Number = ((a.y - b.y) / (a.x - b.x));
            var B:Number = (((1 / m) * c.x) - c.y);
            var d:Point = new Point(b.x, ((b.x * (-1 / m)) + B));
            var e:Point = new Point(a.x, ((a.x * (-1 / m)) + B));
            var poi:Point = lineIntersectLine(a, b, d, e, as_seg);
            if (poi != null){
                dx = (poi.x - c.x);
                dy = (poi.y + c.y);
                obj.dist = Math.floor(Math.pow(((dx * dx) + (dy * dy)), 0.5));
                obj.poi = poi;
            };
            return (obj);
        }

        public static function lineIntersectLine(A:Point, B:Point, E:Point, F:Point, as_seg:Boolean=false):Point{
            var ip:Point;
            var a1:Number;
            var a2:Number;
            var b1:Number;
            var b2:Number;
            var c1:Number;
            var c2:Number;
            a1 = (B.y - A.y);
            b1 = (A.x - B.x);
            c1 = ((B.x * A.y) - (A.x * B.y));
            a2 = (F.y - E.y);
            b2 = (E.x - F.x);
            c2 = ((F.x * E.y) - (E.x * F.y));
            var denom:Number = ((a1 * b2) - (a2 * b1));
            if (denom == 0){
                return (null);
            };
            ip = new Point();
            ip.x = (((b1 * c2) - (b2 * c1)) / denom);
            ip.y = (((a2 * c1) - (a1 * c2)) / denom);
            if (as_seg){
                if ((Math.pow((ip.x - B.x), 2) + Math.pow((ip.y - B.y), 2)) > (Math.pow((A.x - B.x), 2) + Math.pow((A.y - B.y), 2))){
                    return (null);
                };
                if ((Math.pow((ip.x - A.x), 2) + Math.pow((ip.y - A.y), 2)) > (Math.pow((A.x - B.x), 2) + Math.pow((A.y - B.y), 2))){
                    return (null);
                };
                if ((Math.pow((ip.x - F.x), 2) + Math.pow((ip.y - F.y), 2)) > (Math.pow((E.x - F.x), 2) + Math.pow((E.y - F.y), 2))){
                    return (null);
                };
                if ((Math.pow((ip.x - E.x), 2) + Math.pow((ip.y - E.y), 2)) > (Math.pow((E.x - F.x), 2) + Math.pow((E.y - F.y), 2))){
                    return (null);
                };
            };
            return (ip);
        }


    }
}//package hu.carnation.math
