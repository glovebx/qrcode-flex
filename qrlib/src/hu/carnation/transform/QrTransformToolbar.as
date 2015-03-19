//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform{
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import mx.core.FlexSprite;
    import mx.core.UIComponent;

    public class QrTransformToolbar extends Sprite {

        public static const LASSO_TOOL:String = "lassoTool";
        public static const EFFECT_TOOL:String = "effectTool";
        public static const FLIP_VERTICAL_TOOL:String = "flipVerticalTool";
        public static const FLIP_HORIZONTAL_TOOL:String = "flipHorizontalTool";
        public static const DELETE_TOOL:String = "deleteTool";

		[Embed(source="assets/flipHorizontalIcon.swf")]
        public var flipHorizontalIcon:Class;//instance name
		
		[Embed(source="assets/flipVerticalIcon.swf")]
        public var flipVerticalIcon:Class;//instance name
		
		[Embed(source="assets/lassoToolIcon.swf")]
        public var lassoToolIcon:Class;//instance name
		
		[Embed(source="assets/effectToolIcon.swf")]
        public var effectToolIcon:Class;//instance name
		
		[Embed(source="assets/deleteToolIcon.swf")]
        public var deleteToolIcon:Class;//instance name
		
        private var iconArray:Array;

        public function QrTransformToolbar():void{
            this.iconArray = ["flipHorizontalIcon", "flipVerticalIcon", "lassoToolIcon", "effectToolIcon", "deleteToolIcon"];
            super();
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        private function init(_arg1:Event):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.setupListeners();
        }

        public function setupListeners():void{
//            var _local1:Class;
//            var _local2:int;
//            while (_local2 < this.iconArray.length) {
//                _local1 = this[this.iconArray[_local2]];
//                _local1.buttonMode = true;
//                _local1.mouseChildren = false;
//                _local1.addEventListener(MouseEvent.CLICK, this.toolBarIconClick, false, 0, true);
//                _local1.addEventListener(MouseEvent.MOUSE_OVER, this.toolbarIconOver, false, 0, true);
//                _local1.addEventListener(MouseEvent.MOUSE_OUT, this.toolBarIconOut, false, 0, true);
//                _local2++;
//            };
        }

        public function removeListeners():void{
//            var _local1:MovieClip;
//            var _local2:int;
//            while (_local2 < this.iconArray.length) {
//                _local1 = MovieClip(this[this.iconArray[_local2]]);
//                _local1.removeEventListener(MouseEvent.CLICK, this.toolBarIconClick);
//                _local1.removeEventListener(MouseEvent.MOUSE_OVER, this.toolbarIconOver);
//                _local1.removeEventListener(MouseEvent.MOUSE_OUT, this.toolBarIconOut);
//                _local2++;
//            };
        }

        private function toolbarIconOver(_arg1:MouseEvent):void{
            var _local2:MovieClip = (_arg1.currentTarget as MovieClip);
            _local2.gotoAndStop(2);
        }

        private function toolBarIconOut(_arg1:MouseEvent):void{
            var _local2:MovieClip = (_arg1.currentTarget as MovieClip);
            _local2.gotoAndStop(1);
        }

        private function toolBarIconClick(_arg1:MouseEvent):void{
            switch (_arg1.currentTarget){
                case this.flipHorizontalIcon:
                    dispatchEvent(new Event(FLIP_HORIZONTAL_TOOL));
                    return;
                case this.flipVerticalIcon:
                    dispatchEvent(new Event(FLIP_VERTICAL_TOOL));
                    return;
                case this.lassoToolIcon:
                    dispatchEvent(new Event(LASSO_TOOL));
                    return;
                case this.effectToolIcon:
                    dispatchEvent(new Event(EFFECT_TOOL));
                    return;
                case this.deleteToolIcon:
                    dispatchEvent(new Event(DELETE_TOOL));
                    return;
            };
        }

        public function updatePosition(_arg1:Number, _arg2:Number):void{
            this.x = _arg1;
            this.y = _arg2;
        }

        public function dispose():void{
            this.removeListeners();
        }


    }
}//package hu.carnation.transform
