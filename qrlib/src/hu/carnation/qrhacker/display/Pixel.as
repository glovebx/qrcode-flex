//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker.display{
    import co.moodshare.pdf.MSPDF;
    
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    
    import hu.carnation.qr.model.PixelVO;
    
    import mx.core.FlexSprite;
    
    import org.alivepdf.colors.RGBColor;

    public class Pixel extends FlexSprite {

        private var _pixelVO:PixelVO;
        private var pixel:FlexSprite;

        public function Pixel():void{
        }

        public function renderToPDF(pdf:MSPDF, padding:Number, scale:Number):void{
            var pixelSize:Number = (this.pixelVO.size * scale);
            if (this.pixelVO.customColor){
                pdf.beginFill(new RGBColor(this.pixelVO.customColor));
            } else {
                pdf.beginFill(new RGBColor(this.pixelVO.color));
            };
            if (this.pixelVO.cornerRadius != 0){
                this.renderGraphics(pdf, padding, pixelSize);
            } else {
                if (this.pixelVO.active){
                    pdf.drawRect(new Rectangle(((this.pixelVO.position.x * pixelSize) + padding)
						, ((this.pixelVO.position.y * pixelSize) + padding), pixelSize, pixelSize));
                    pdf.end();
                };
            };
        }

        private function get rightop():Boolean{
            return (this.pixelVO.siblings[5]);
        }

		// target is Graphics or PDF
        private function renderGraphics(target, padding:Number, size:Number):void{
            var isPixel:Boolean = (target is Graphics);
            var radiusBySize:Number = (this.pixelVO.cornerRadius * (size / 2));
            var _x:Number = ((this.pixelVO.position.x * size) + padding);
            var _y:Number = ((this.pixelVO.position.y * size) + padding);
            if (this.pixelVO.active){
                target.moveTo(_x, ((size / 2) + _y));
                if (((!(this.left)) && (!(this.top)))){
                    if (this.pixelVO.cornerRadius != 1){
                        target.lineTo(_x, (radiusBySize + _y));
                    };
                    if (isPixel){
                        target.curveTo(_x, _y, (radiusBySize + _x), _y);
                    } else {
						// PDF.as @see org.alivepdf.pdf.PDF
                        target.curveTo(_x, (_y + (radiusBySize / 2)), (_x + (radiusBySize / 2)), _y, (radiusBySize + _x), _y);
                    };
                } else {
                    target.lineTo(_x, _y);
                };
                target.lineTo(((size / 2) + _x), _y);
                if (((!(this.top)) && (!(this.right)))){
                    target.lineTo(((size - radiusBySize) + _x), _y);
                    if (isPixel){
                        target.curveTo((size + _x), _y, (size + _x), (radiusBySize + _y));
                    } else {
						// PDF.as @see org.alivepdf.pdf.PDF
                        target.curveTo(((size + _x) - (radiusBySize / 2)), _y, (size + _x), (_y + (radiusBySize / 2)), (size + _x), (radiusBySize + _y));
                    };
                } else {
                    target.lineTo((size + _x), _y);
                };
                target.lineTo((size + _x), ((size / 2) + _y));
                if (((!(this.right)) && (!(this.bottom)))){
                    target.lineTo((size + _x), ((size - radiusBySize) + _y));
                    if (isPixel){
                        target.curveTo((size + _x), (size + _y), ((size - radiusBySize) + _x), (size + _y));
                    } else {
						// PDF.as @see org.alivepdf.pdf.PDF
                        target.curveTo((size + _x), ((size + _y) - (radiusBySize / 2)), ((size + _x) - (radiusBySize / 2)), (size + _y), ((size - radiusBySize) + _x), (size + _y));
                    };
                } else {
                    target.lineTo((size + _x), (size + _y));
                };
                target.lineTo(((size / 2) + _x), (size + _y));
                if (((!(this.bottom)) && (!(this.left)))){
                    target.lineTo((radiusBySize + _x), (size + _y));
                    if (isPixel){
                        target.curveTo(_x, (size + _y), _x, ((size - radiusBySize) + _y));
                    } else {
						// PDF.as @see org.alivepdf.pdf.PDF
                        target.curveTo((_x + (radiusBySize / 2)), (size + _y), _x, ((size + _y) - (radiusBySize / 2)), _x, ((size - radiusBySize) + _y));
                    };
                } else {
                    target.lineTo(_x, (size + _y));
                };
                target.lineTo(_x, ((size / 2) + _y));
                if (isPixel){
                    target.endFill();
                } else {
                    MSPDF(target).end();
                };
            } else {
                if (isPixel){
                    target.beginFill(0, 0);
                    target.moveTo(_x, _y);
                    target.lineTo((size + _x), _y);
                    target.lineTo((size + _x), (size + _y));
                    target.lineTo(_x, (size + _y));
                    target.lineTo(_x, _y);
                    target.endFill();
                };
                if (((((((!(this.bottom)) && (!(this.top)))) && (!(this.left)))) && (!(this.right)))){
                    return;
                };
            };
        }

        private function get bottom():Boolean{
            return (this.pixelVO.siblings[3]);
        }

        private function get left():Boolean{
            return (this.pixelVO.siblings[0]);
        }

        private function get lefttop():Boolean{
            return (this.pixelVO.siblings[4]);
        }

        private function get leftbottom():Boolean{
            return (this.pixelVO.siblings[7]);
        }

        private function get top():Boolean{
            return (this.pixelVO.siblings[1]);
        }

        private function get rightbottom():Boolean{
            return (this.pixelVO.siblings[6]);
        }

        public function get pixelVO():PixelVO{
            return (this._pixelVO);
        }

        override public function get x():Number{
            return ((this.pixelVO.position.x * this.pixelVO.size));
        }

        override public function get y():Number{
            return ((this.pixelVO.position.y * this.pixelVO.size));
        }

        private function get right():Boolean{
            return (this.pixelVO.siblings[2]);
        }

        public function updatePixel():void{
            if (!this.pixel){
                this.pixel = new FlexSprite();
                addChild(this.pixel);
            };
            this.pixel.graphics.clear();
            if (this.pixelVO.hasCustomColor){
                this.pixel.graphics.beginFill(this.pixelVO.customColor);
            } else {
                this.pixel.graphics.beginFill(this.pixelVO.color);
            };
            this.renderGraphics(this.pixel.graphics, 0, this.pixelVO.size);
        }

        public function set pixelVO(value:PixelVO):void{
            this._pixelVO = value;
        }

        public function dispose():void{
            this.pixel.graphics.clear();
            removeChild(this.pixel);
            this.pixel = null;
            this.pixelVO = null;
        }


    }
}//package hu.carnation.qrhacker.display
