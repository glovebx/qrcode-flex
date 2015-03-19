//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform{
    import flash.display.Sprite;
    import hu.carnation.transform.components.EffectsPanelItem;
    import __AS3__.vec.Vector;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import com.greensock.TweenNano;
    import com.greensock.*;
    import __AS3__.vec.*;
    import com.greensock.easing.*;

    public class EffectsPanel extends Sprite {

        public static const EFFECTS_UPDATED:String = "onEffectsUpdated";
        public static const CLOSE:String = "close";
        private static const OPENED_ITEM_DISTANCE:Number = 44;
        private static const CLOSED_ITEM_DISTANCE:Number = 24;

        private var colorizeItem:EffectsPanelItem;
        private var contrastItem:EffectsPanelItem;
        private var brightnessItem:EffectsPanelItem;
        private var saturationItem:EffectsPanelItem;
        private var hueItem:EffectsPanelItem;
        private var thresholdItem:EffectsPanelItem;
        private var pixelateItem:EffectsPanelItem;
        private var panelItems:Vector.<EffectsPanelItem>;
        public var closeButton:Sprite;//instance name

        public function EffectsPanel(){
            var _local1:EffectsPanelItem;
            super();
            this.panelItems = new Vector.<EffectsPanelItem>();
            this.colorizeItem = new EffectsPanelItem("colorize", 0, 3, 0.1, 1, false, true);
            this.contrastItem = new EffectsPanelItem("contrast", -3, 3, 0.1, 1);
            this.brightnessItem = new EffectsPanelItem("brightness", -3, 3, 0.1, 1);
            this.saturationItem = new EffectsPanelItem("saturation", -3, 3, 0.1, 1);
            this.hueItem = new EffectsPanelItem("hue", 0, 360, 10, 1);
            this.thresholdItem = new EffectsPanelItem("threshold", 0, 0xFF, 2, 100);
            this.pixelateItem = new EffectsPanelItem("pixelate", 1, 20, 1, 5, true);
            this.colorizeItem.y = 49;
            addChild(this.colorizeItem);
            this.panelItems.push(this.colorizeItem);
            this.contrastItem.y = (this.colorizeItem.y + CLOSED_ITEM_DISTANCE);
            addChild(this.contrastItem);
            this.panelItems.push(this.contrastItem);
            this.brightnessItem.y = (this.contrastItem.y + CLOSED_ITEM_DISTANCE);
            addChild(this.brightnessItem);
            this.panelItems.push(this.brightnessItem);
            this.saturationItem.y = (this.brightnessItem.y + CLOSED_ITEM_DISTANCE);
            addChild(this.saturationItem);
            this.panelItems.push(this.saturationItem);
            this.hueItem.y = (this.saturationItem.y + CLOSED_ITEM_DISTANCE);
            addChild(this.hueItem);
            this.panelItems.push(this.hueItem);
            this.thresholdItem.y = (this.hueItem.y + CLOSED_ITEM_DISTANCE);
            addChild(this.thresholdItem);
            this.panelItems.push(this.thresholdItem);
            this.pixelateItem.y = (this.thresholdItem.y + CLOSED_ITEM_DISTANCE);
            addChild(this.pixelateItem);
            this.panelItems.push(this.pixelateItem);
            var _local2:int;
            while (_local2 < this.panelItems.length) {
                _local1 = EffectsPanelItem(this.panelItems[_local2]);
                _local1.addEventListener(Event.CHANGE, this.onEffectsChange, false, 0, true);
                _local1.addEventListener(EffectsPanelItem.ITEM_COLLAPSE, this.inItemCollapse, false, 0, true);
                _local2++;
            };
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        private function init(_arg1:Event):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.addEventListener(Event.REMOVED_FROM_STAGE, this.dispose, false, 0, true);
            this.closeButton.buttonMode = true;
            this.closeButton.mouseChildren = false;
            this.closeButton.addEventListener(MouseEvent.CLICK, this.onCloseClick, false, 0, true);
            this.addEventListener(MouseEvent.MOUSE_DOWN, this.onPanelMouseDown, false, 0, true);
        }

        private function onCloseClick(_arg1:MouseEvent):void{
            dispatchEvent(new Event(CLOSE));
        }

        private function onPanelMouseDown(_arg1:MouseEvent):void{
            this.addEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp, false, 0, true);
            this.startDrag(false, new Rectangle(0, 0, (stage.stageWidth - this.width), (stage.stageHeight - this.height)));
        }

        private function onPanelMouseUp(_arg1:MouseEvent):void{
            this.stopDrag();
            this.removeEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp);
        }

        private function inItemCollapse(_arg1:Event):void{
            var _local4:EffectsPanelItem;
            var _local2:EffectsPanelItem = (_arg1.currentTarget as EffectsPanelItem);
            var _local3:int = (this.panelItems.indexOf(_local2) + 1);
            var _local5:Number = _local2.y;
            var _local6:int = _local3;
            while (_local6 < this.panelItems.length) {
                _local4 = (this.panelItems[_local6] as EffectsPanelItem);
                _local5 = (_local5 + ((_local2.opened) ? OPENED_ITEM_DISTANCE : CLOSED_ITEM_DISTANCE));
                TweenNano.to(_local4, 0.3, {"y":_local5});
                _local2 = _local4;
                _local6++;
            };
        }

        private function onEffectsChange(_arg1:Event):void{
            dispatchEvent(new Event(EFFECTS_UPDATED));
        }

        public function updatePosition(_arg1:Number, _arg2:Number):void{
            this.x = _arg1;
            this.y = _arg2;
        }

        public function dispose(_arg1:Event=null):void{
            this.closeButton.addEventListener(MouseEvent.CLICK, this.onCloseClick);
            removeEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
            this.addEventListener(MouseEvent.MOUSE_DOWN, this.onPanelMouseDown, false, 0, true);
            this.addEventListener(MouseEvent.MOUSE_UP, this.onPanelMouseUp, false, 0, true);
        }

        public function get colorizeEnabled():Boolean{
            return (this.colorizeItem.selected);
        }

        public function get colorizePickerValue():uint{
            return (this.colorizeItem.selectedColor);
        }

        public function get colorizeAmountValue():Number{
            return (this.colorizeItem.value);
        }

        public function get contrastEnabled():Boolean{
            return (this.contrastItem.selected);
        }

        public function get contrastAmountValue():Number{
            return (this.contrastItem.value);
        }

        public function get brightnessEnabled():Boolean{
            return (this.brightnessItem.selected);
        }

        public function get brightnessAmountValue():Number{
            return (this.brightnessItem.value);
        }

        public function get saturationEnabled():Boolean{
            return (this.saturationItem.selected);
        }

        public function get saturationAmountValue():Number{
            return (this.saturationItem.value);
        }

        public function get hueEnabled():Boolean{
            return (this.hueItem.selected);
        }

        public function get hueAmountValue():Number{
            return (this.hueItem.value);
        }

        public function get thresholdEnabled():Boolean{
            return (this.thresholdItem.selected);
        }

        public function get thresholdAmountValue():Number{
            return (this.thresholdItem.value);
        }

        public function get pixelateEnabled():Boolean{
            return (this.pixelateItem.selected);
        }

        public function get pixelateAmountValue():Number{
            return (this.pixelateItem.value);
        }


    }
}//package hu.carnation.transform
