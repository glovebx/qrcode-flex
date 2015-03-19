//Created by Action Script Viewer - http://www.buraks.com/asv
package com.greensock.easing{
    public class Strong {

        public static const power:uint = 4;


        public static function easeIn(_arg1:Number, _arg2:Number, _arg3:Number, _arg4:Number):Number{
            _arg1 = (_arg1 / _arg4);
            return (((((((_arg3 * _arg1) * _arg1) * _arg1) * _arg1) * _arg1) + _arg2));
        }

        public static function easeOut(_arg1:Number, _arg2:Number, _arg3:Number, _arg4:Number):Number{
            _arg1 = ((_arg1 / _arg4) - 1);
            return (((_arg3 * (((((_arg1 * _arg1) * _arg1) * _arg1) * _arg1) + 1)) + _arg2));
        }

        public static function easeInOut(_arg1:Number, _arg2:Number, _arg3:Number, _arg4:Number):Number{
            _arg1 = (_arg1 / (_arg4 * 0.5));
            if (_arg1 < 1){
                return ((((((((_arg3 * 0.5) * _arg1) * _arg1) * _arg1) * _arg1) * _arg1) + _arg2));
            };
            _arg1 = (_arg1 - 2);
            return ((((_arg3 * 0.5) * (((((_arg1 * _arg1) * _arg1) * _arg1) * _arg1) + 2)) + _arg2));
        }


    }
}//package com.greensock.easing
