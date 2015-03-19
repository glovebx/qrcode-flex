//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform{
    import flash.display.Sprite;

    public class ControlPoint extends Sprite {

        private static const CIRCLE_SIZE:Number = 6;
        private static const BIG_CIRCLE_SIZE:Number = 10;
        private static const HIT_SIZE:Number = 10;

        private var circle:Sprite;
        private var circleOver:Sprite;
        private var hitSprite:Sprite;
        private var _onOver:Boolean;
        private var _isFirstPoint:Boolean;

        public function ControlPoint(_x:Number, _y:Number, isFirstPoint:Boolean=false):void{
            this.circle = new Sprite();
            if (isFirstPoint){
                this.circle.graphics.beginFill(0xFFFFFF, 1);
                this.circle.graphics.lineStyle(1, 2728157);
                this.circle.graphics.drawEllipse((-(BIG_CIRCLE_SIZE) / 2), (-(BIG_CIRCLE_SIZE) / 2), BIG_CIRCLE_SIZE, BIG_CIRCLE_SIZE);
            } else {
                this.circle.graphics.beginFill(0xFFFFFF, 1);
                this.circle.graphics.lineStyle(1, 2728157);
                this.circle.graphics.drawRect((-(CIRCLE_SIZE) / 2), (-(CIRCLE_SIZE) / 2), CIRCLE_SIZE, CIRCLE_SIZE);
            };
            this.circle.graphics.endFill();
            addChild(this.circle);
            this.circleOver = new Sprite();
            this.circleOver.graphics.beginFill(0xFFFFFF, 1);
            if (isFirstPoint){
                this.circleOver.graphics.drawEllipse((-(BIG_CIRCLE_SIZE) / 2), (-(BIG_CIRCLE_SIZE) / 2), BIG_CIRCLE_SIZE, BIG_CIRCLE_SIZE);
            } else {
                this.circleOver.graphics.drawRect((-(CIRCLE_SIZE) / 2), (-(CIRCLE_SIZE) / 2), CIRCLE_SIZE, CIRCLE_SIZE);
            };
            this.circleOver.graphics.endFill();
            addChild(this.circleOver);
            this.circleOver.visible = false;
            this.hitSprite = new Sprite();
            this.hitSprite.graphics.beginFill(0xFFFFFF, 0);
            this.hitSprite.graphics.drawRect((-(HIT_SIZE) / 2), (-(HIT_SIZE) / 2), HIT_SIZE, HIT_SIZE);
            this.hitSprite.graphics.endFill();
            addChild(this.hitSprite);
            this.x = _x;
            this.y = _y;
        }

        public function dispose():void{
            removeChild(this.circle);
            removeChild(this.circleOver);
            removeChild(this.hitSprite);
            this.circle = null;
            this.circleOver = null;
            this.hitSprite = null;
        }

        public function get onOver():Boolean{
            return (this._onOver);
        }

        public function set onOver(value:Boolean):void{
            this._onOver = value;
            this.circleOver.visible = value;
        }

        public function get isFirstPoint():Boolean{
            return (this._isFirstPoint);
        }

        public function set isFirstPoint(value:Boolean):void{
            this._isFirstPoint = value;
        }


    }
}//package hu.carnation.transform
