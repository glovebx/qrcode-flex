//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qr.model{
    import com.google.zxing.common.ByteMatrix;
    
    import flash.display.Bitmap;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    
    import hu.carnation.qr.event.QrCodeEvent;

    public class Model extends EventDispatcher {

        private var _role:String;
        private var _encodeType:String;
        private var _encodeString:String;
        private var _qrSize:Number;
        private var _qrMatrix:ByteMatrix;
        private var _brightness:Number;
        private var _pixelColor:uint;
        private var _advancedPixelColor:uint;
        private var _pixelSize:Number = 10;
        private var _cornerRadius:Number = 0;
        private var _pixelType:int;
        private var _backgroundColor:uint = 0xFFFFFF;
        private var _backgroundURL:String = "";
        private var _backgroundAlpha:Number = 1;
        private var _foregroundColor:uint = 0;
        private var _foregroundURL:String = "";
        private var _foregroundAlpha:Number = 1;
        private var _photo:Bitmap;
        private var _photoURL:String;
        private var _pdfScale:Number = 1;
		
		//二维码纠错级别
		/* Error Correction Level
		L - [Default] Allows recovery of up to 7% data loss
		M - Allows recovery of up to 15% data loss
		Q - Allows recovery of up to 25% data loss
		H - Allows recovery of up to 30% data loss */		
		private var _ecLevel:String = "H";
		private var _margin:Number = 0;

        public function Model(target:IEventDispatcher=null){
            super(target);
        }

        public function get qrMatrix():ByteMatrix{
            return (this._qrMatrix);
        }

        public function set qrMatrix(value:ByteMatrix):void{
            this._qrMatrix = value;
            if (((value) && (this.qrSize))){
                this.pixelSize = int((this.qrSize / value.width()));
            };
            dispatchEvent(new QrCodeEvent(QrCodeEvent.QRMATRIX_CHANGE));
        }

        public function get qrSize():Number{
            return (this._qrSize);
        }

        public function set qrSize(value:Number):void{
            this._qrSize = value;
            if (this.qrMatrix){
                this.pixelSize = int((value / this.qrMatrix.width()));
            };
        }

		public function get margin():Number{
			return (this._margin);
		}
		
		public function set margin(value:Number):void{
			this._margin = value;
		}
		
		public function get ecLevel():String{
			return (this._ecLevel);
		}
		
		public function set ecLevel(value:String):void{
			this._ecLevel = value;
		}
		
        public function get pixelSize():Number{
            return (this._pixelSize);
        }

        public function set pixelSize(value:Number):void{
            this._pixelSize = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.PIXELSIZE_CHANGE));
        }

        public function get pixelColor():uint{
            return (this._pixelColor);
        }

        public function set pixelColor(value:uint):void{
            this._pixelColor = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.PIXELCOLOR_CHANGED));
        }

        public function get advancedPixelColor():uint{
            return (this._advancedPixelColor);
        }

        public function set advancedPixelColor(value:uint):void{
            this._advancedPixelColor = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.ADVANCED_PIXELCOLOR_CHANGED));
        }

        public function get pixelType():int{
            return (this._pixelType);
        }

        public function set pixelType(value:int):void{
            this._pixelType = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.PIXELTYPE_CHANGE));
        }

        public function get cornerRadius():Number{
            return (this._cornerRadius);
        }

        public function set cornerRadius(value:Number):void{
            this._cornerRadius = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.CORNERRADIUS_CHANGED));
        }

        public function get backgroundColor():uint{
            return (this._backgroundColor);
        }

        public function set backgroundColor(value:uint):void{
            this._backgroundColor = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.BACKGROUNDCOLOR_CHANGED));
        }

        public function get backgroundAlpha():Number{
            return (this._backgroundAlpha);
        }

        public function set backgroundAlpha(value:Number):void{
            this._backgroundAlpha = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.BACKGROUNDALPHA_CHANGED));
        }

        public function get backgroundURL():String{
            return (this._backgroundURL);
        }

        public function set backgroundURL(value:String):void{
            this._backgroundURL = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.BACKGROUNDURL_CHANGED));
        }

        public function get foregroundColor():uint{
            return (this._foregroundColor);
        }

        public function set foregroundColor(value:uint):void{
            this._foregroundColor = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.FOREGROUNDCOLOR_CHANGED));
        }

        public function get foregroundAlpha():Number{
            return (this._foregroundAlpha);
        }

        public function set foregroundAlpha(value:Number):void{
            this._foregroundAlpha = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.FOREGROUNDALPHA_CHANGED));
        }

        public function get foregroundURL():String{
            return (this._foregroundURL);
        }

        public function set foregroundURL(value:String):void{
            this._foregroundURL = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.FOREGROUNDURL_CHANGED));
        }

        public function get photo():Bitmap{
            return (this._photo);
        }

        public function set photo(value:Bitmap):void{
            this._photo = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.PHOTO_UPLOADED));
        }

        public function get photoURL():String{
            return (this._photoURL);
        }

        public function set photoURL(value:String):void{
            this._photoURL = value;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.PHOTOURL_CHANGED));
        }

        public function get pdfScale():Number{
            return (this._pdfScale);
        }

        public function set pdfScale(value:Number):void{
            this._pdfScale = value;
        }

        public function get brightness():Number{
            return (this._brightness);
        }

        public function set brightness(value:Number):void{
            this._brightness = value;
        }

        public function get encodeType():String{
            return (this._encodeType);
        }

        public function set encodeType(value:String):void{
            this._encodeType = value;
        }

        public function get encodeString():String{
            return (this._encodeString);
        }

        public function set encodeString(value:String):void{
            this._encodeString = value;
        }

        public function get role():String{
            return (this._role);
        }

        public function set role(value:String):void{
            this._role = value;
        }


    }
}//package hu.carnation.qr.model
