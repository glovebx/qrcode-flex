//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform{
    import __AS3__.vec.*;
    import __AS3__.vec.Vector;
    
    import com.greensock.*;
    import com.greensock.TweenLite;
    import com.greensock.data.*;
    import com.greensock.events.*;
    import com.greensock.events.TransformEvent;
    import com.greensock.plugins.*;
    import com.greensock.plugins.BlurFilterPlugin;
    import com.greensock.plugins.ColorMatrixFilterPlugin;
    import com.greensock.plugins.TweenPlugin;
    import com.greensock.transform.*;
    import com.greensock.transform.TransformItem;
    import com.greensock.transform.TransformManager;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.ui.Keyboard;
    
    import hu.carnation.filter.PixelateFilter;
    import hu.carnation.qr.model.Model;
    import hu.carnation.qrhacker.IMain;
    import hu.carnation.transform.components.LassoToolWindow;
    import hu.carnation.utils.CropOutWhitespace;
    
    import org.casalib.ui.Key;
    import org.casalib.util.StageReference;

    public class QrTransformItemManager extends Sprite {

        public static const SELECTION_CHANGE:String = "onSelectionChange";
        public static const FINISH_TRANSFORM:String = "onFinishTransform";
        private static const PADDING:Number = 20;

        private var model:Model;
		private var mainRef:IMain;
        private var addedSprites:Vector.<Sprite>;
        private var transformManager:TransformManager;
        private var transformItemVector:Vector.<TransformItem>;
        private var lastTransformedItem:TransformItem;
        private var qrTransformToolbar:QrTransformToolbar;
        private var effectsPanel:EffectsPanel;
        private var lassoTool:LassoTool;
        private var maskWindow:LassoToolWindow;
        private var key:Key;
        private var pixelFilter:PixelateFilter;
        private var background:Sprite;
        private var itemsNum:int = 0;
        private var transformChanged:Boolean = false;
        private var w:Number;
        private var h:Number;
        private var lassoTransformItem:TransformItem;
        private var lassoSpriteItem:Sprite;

        public function QrTransformItemManager(w:Number, h:Number, model:Model, mainRef:IMain):void{
            this.pixelFilter = new PixelateFilter();
            super();
            this.w = w;
            this.h = h;
            this.model = model;
			this.mainRef = mainRef;
            TweenPlugin.activate([ColorMatrixFilterPlugin, BlurFilterPlugin]);
            this.drawBackground(w, h);
            this.addEventListener(MouseEvent.CLICK, this.onHolderClick, false, 0, true);
        }

        public function init():void{
            StageReference.setStage(stage);
            this.key = Key.getInstance();
            this.transformManager = new TransformManager();
            this.transformManager.arrowKeysMove = true;
            this.transformManager.bounds = new Rectangle(PADDING, PADDING, (this.w - (2 * PADDING)), (this.h - (2 * PADDING)));
			//this.transformManager.bounds = new Rectangle(0, 0, this.w, this.h);
            this.transformManager.allowDelete = true;
            this.transformManager.autoDeselect = false;
            this.transformManager.constrainScale = true;
            this.transformManager.allowMultiSelect = false;
            this.transformManager.addEventListener(TransformEvent.SELECTION_CHANGE, this.transformManagerHandler, false, 0, true);
            this.transformManager.addEventListener(TransformEvent.MOVE, this.transformManagerHandler, false, 0, true);
            this.transformManager.addEventListener(TransformEvent.SCALE, this.transformManagerHandler, false, 0, true);
            this.transformManager.addEventListener(TransformEvent.ROTATE, this.transformManagerHandler, false, 0, true);
            this.transformManager.addEventListener(TransformEvent.DELETE, this.transformManagerHandler, false, 0, true);
            this.transformManager.addEventListener(TransformEvent.FINISH_INTERACTIVE_MOVE, this.transformManagerHandler, false, 0, true);
            this.transformManager.addEventListener(TransformEvent.FINISH_INTERACTIVE_ROTATE, this.transformManagerHandler, false, 0, true);
            this.transformManager.addEventListener(TransformEvent.FINISH_INTERACTIVE_SCALE, this.transformManagerHandler, false, 0, true);
        }

        private function drawBackground(w:Number, h:Number):void{
            this.background = new Sprite();
            this.background.name = "background";
            this.background.graphics.beginFill(0xFFFFFF, 0);
			//this.background.graphics.beginFill(0x000000, 1);
            this.background.graphics.drawRect(0, 0, w, h);
            this.background.graphics.endFill();
            addChildAt(this.background, 0);
            this.background.visible = false;
        }

        private function onHolderClick(e:MouseEvent):void{
            if (e.target == this.background){
                if (this.lassoTool){
                    this.lassoTool.closePath();
                } else {
                    this.transformManager.deselectAll();
                };
            };
        }

        public function addItem(item:Sprite):void{
            var scaleSize:Number;
            if (!this.transformManager){
                this.init();
            };
            if (!this.addedSprites){
                this.addedSprites = new Vector.<Sprite>();
            };
            this.addChild(item);
            var pixelHCount:int = this.model.qrMatrix.width();
            var division:Number = this.model.pixelSize;
            var gridStartPoint:Point = new Point();
			
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            gridStartPoint.x = int(((rect.width - (pixelHCount * division)) / 2));
            gridStartPoint.y = int(((rect.height - (pixelHCount * division)) / 2));
            var transformItem:TransformItem = this.transformManager.addItem(item);
            var itemBigSide:Number = Math.max(transformItem.width, transformItem.height);
            var targetSize:int = (140 - (140 % division));
            if (itemBigSide > targetSize){
                scaleSize = (targetSize / itemBigSide);
                transformItem.scale(scaleSize, scaleSize);
            };
            this.lastTransformedItem = transformItem;
            this.snapToGrid();
            this.pixelFilter.dimension = 1;
            transformItem.targetObject.filters = [this.pixelFilter];
            this.addedSprites.push(item);
            this.itemsNum++;
        }

        private function transformManagerHandler(e:TransformEvent):void{
            switch (e.type){
                case TransformEvent.SELECTION_CHANGE:
                    this.updateToolbar();
                    this.hideEffectsPanel();
                    if (this.lassoTool){
                        this.hideLassoTool();
                    };
                    if (this.transformManager.selectedItems[0]){
                        this.lastTransformedItem = this.transformManager.selectedItems[0];
                        this.background.visible = true;
                    } else {
                        this.background.visible = false;
                        if (this.transformChanged){
                            dispatchEvent(new Event(SELECTION_CHANGE));
                        };
                        this.transformChanged = false;
                    };
                    break;
                case TransformEvent.SCALE:
                case TransformEvent.ROTATE:
                case TransformEvent.MOVE:
                    this.updateToolbarPosition();
                    this.updateEffectsPanelPosition();
                    this.transformChanged = true;
                    break;
                case TransformEvent.FINISH_INTERACTIVE_MOVE:
                case TransformEvent.FINISH_INTERACTIVE_ROTATE:
                    this.lastTransformedItem = this.transformManager.selectedItems[0];
                    this.snapToGrid();
                    break;
                case TransformEvent.FINISH_INTERACTIVE_SCALE:
                    this.lastTransformedItem = this.transformManager.selectedItems[0];
                    this.resizeToGrid();
                    this.snapToGrid();
                    break;
                case TransformEvent.DELETE:
                    this.itemsNum--;
                    dispatchEvent(new Event(SELECTION_CHANGE));
                    break;
            };
        }

        private function resizeToGrid():void{
            var division:Number;
            if (((((this.model.qrMatrix) && (this.lastTransformedItem))) && (this.key.isDown(Keyboard.CONTROL)))){
                division = this.model.pixelSize;
                this.lastTransformedItem.width = (Math.round((this.lastTransformedItem.width / division)) * division);
                this.lastTransformedItem.scaleY = this.lastTransformedItem.scaleX;
            };
        }

        private function snapToGrid():void{
            var pixelHCount:int;
            var division:Number;
            var gridStartPoint:Point;
            var transformItemX:Number;
            var transformItemY:Number;
            var positionBetweenTwoGridY:Number;
            var positionBetweenTwoGridX:Number;
            if (((((this.model.qrMatrix) && (this.lastTransformedItem))) && (this.key.isDown(Keyboard.CONTROL)))){
                pixelHCount = this.model.qrMatrix.width();
                division = this.model.pixelSize;
                gridStartPoint = new Point();
				
				var rect:Rectangle = mainRef.getQrDisplayRegion();
                gridStartPoint.x = int(((rect.width - (pixelHCount * division)) / 2));
                gridStartPoint.y = int(((rect.height - (pixelHCount * division)) / 2));
                transformItemX = (this.lastTransformedItem.x - (this.lastTransformedItem.width / 2));
                transformItemY = (this.lastTransformedItem.y - (this.lastTransformedItem.height / 2));
                positionBetweenTwoGridY = ((transformItemY - gridStartPoint.y) - (int(((transformItemY - gridStartPoint.y) / division)) * division));
                positionBetweenTwoGridX = ((transformItemX - gridStartPoint.y) - (int(((transformItemX - gridStartPoint.x) / division)) * division));
                if (positionBetweenTwoGridY < (division / 2)){
                    this.lastTransformedItem.y = (this.lastTransformedItem.y - positionBetweenTwoGridY);
                } else {
                    this.lastTransformedItem.y = (this.lastTransformedItem.y + (division - positionBetweenTwoGridY));
                };
                if (positionBetweenTwoGridX < (division / 2)){
                    this.lastTransformedItem.x = (this.lastTransformedItem.x - positionBetweenTwoGridX);
                } else {
                    this.lastTransformedItem.x = (this.lastTransformedItem.x + (division - positionBetweenTwoGridX));
                };
            };
            this.updateToolbarPosition();
            this.updateEffectsPanelPosition();
        }

        private function updateToolbar():void{
            if (this.transformManager.selectedItems[0]){
                if (!this.qrTransformToolbar){
                    this.qrTransformToolbar = new QrTransformToolbar();
                    addChild(this.qrTransformToolbar);
                    this.qrTransformToolbar.addEventListener(QrTransformToolbar.EFFECT_TOOL, this.toolbarHandler, false, 0, true);
                    this.qrTransformToolbar.addEventListener(QrTransformToolbar.LASSO_TOOL, this.toolbarHandler, false, 0, true);
                    this.qrTransformToolbar.addEventListener(QrTransformToolbar.FLIP_HORIZONTAL_TOOL, this.toolbarHandler, false, 0, true);
                    this.qrTransformToolbar.addEventListener(QrTransformToolbar.FLIP_VERTICAL_TOOL, this.toolbarHandler, false, 0, true);
                    this.qrTransformToolbar.addEventListener(QrTransformToolbar.DELETE_TOOL, this.toolbarHandler, false, 0, true);
                };
                this.updateToolbarPosition();
            } else {
                this.hideToolbar();
            };
        }

        private function hideToolbar():void{
            if (this.qrTransformToolbar){
                this.qrTransformToolbar.dispose();
                removeChild(this.qrTransformToolbar);
                this.qrTransformToolbar = null;
            };
        }

        private function toolbarHandler(e:Event):void{
            var transformItem:TransformItem = TransformItem(this.transformManager.selectedItems[0]);
            switch (e.type){
                case QrTransformToolbar.EFFECT_TOOL:
                    this.showEffectsPanel();
                    break;
                case QrTransformToolbar.LASSO_TOOL:
                    this.hideEffectsPanel();
                    this.hideToolbar();
                    this.showLassoTool();
                    break;
                case QrTransformToolbar.FLIP_HORIZONTAL_TOOL:
                    transformItem.scaleX = (transformItem.scaleX * -1);
                    this.hideEffectsPanel();
                    break;
                case QrTransformToolbar.FLIP_VERTICAL_TOOL:
                    transformItem.scaleY = (transformItem.scaleY * -1);
                    this.hideEffectsPanel();
                    break;
                case QrTransformToolbar.DELETE_TOOL:
                    this.hideEffectsPanel();
                    this.hideLassoTool();
                    this.transformManager.deleteSelection();
                    break;
            };
        }

        private function updateToolbarPosition():void{
            var _x:Number;
            var _y:Number;
            if (this.qrTransformToolbar){
                setChildIndex(this.qrTransformToolbar, (numChildren - 1));
            };
            var transformItem:TransformItem = TransformItem(this.transformManager.selectedItems[0]);
            if (transformItem){
                _x = transformItem.x;
                _y = (transformItem.y + (transformItem.height / 2));
                if (this.qrTransformToolbar){
                    this.qrTransformToolbar.updatePosition(_x, _y);
                };
            };
        }

        private function showEffectsPanel():void{
            if (!this.effectsPanel){
                this.effectsPanel = new EffectsPanel();
                this.effectsPanel.x = (this.effectsPanel.y = 30);
                addChild(this.effectsPanel);
            };
            this.effectsPanel.addEventListener(EffectsPanel.EFFECTS_UPDATED, this.onEffectsChanged, false, 0, true);
            this.effectsPanel.addEventListener(EffectsPanel.CLOSE, this.hideEffectsPanel, false, 0, true);
            this.effectsPanel.visible = true;
            this.updateEffectsPanelPosition();
        }

        private function hideEffectsPanel(e:Event=null):void{
            if (this.effectsPanel){
                this.effectsPanel.removeEventListener(EffectsPanel.EFFECTS_UPDATED, this.onEffectsChanged);
                this.effectsPanel.removeEventListener(EffectsPanel.CLOSE, this.hideEffectsPanel);
                this.effectsPanel.visible = false;
            };
        }

        private function onEffectsChanged(e:Event):void{
            if (!this.transformManager.selectedItems[0]){
                return;
            };
            var transformItem:TransformItem = TransformItem(this.transformManager.selectedItems[0]);
            if (this.effectsPanel.pixelateEnabled){
                this.pixelFilter.dimension = this.effectsPanel.pixelateAmountValue;
            } else {
                this.pixelFilter.dimension = 1;
            };
            var colorMatrixFilterVars:Object = {};
            if (this.effectsPanel.colorizeEnabled){
                colorMatrixFilterVars.colorize = this.effectsPanel.colorizePickerValue;
                colorMatrixFilterVars.amount = this.effectsPanel.colorizeAmountValue;
            };
            if (this.effectsPanel.contrastEnabled){
                colorMatrixFilterVars.contrast = this.effectsPanel.contrastAmountValue;
            };
            if (this.effectsPanel.brightnessEnabled){
                colorMatrixFilterVars.brightness = this.effectsPanel.brightnessAmountValue;
            };
            if (this.effectsPanel.saturationEnabled){
                colorMatrixFilterVars.saturation = this.effectsPanel.saturationAmountValue;
            };
            if (this.effectsPanel.hueEnabled){
                colorMatrixFilterVars.hue = this.effectsPanel.hueAmountValue;
            };
            if (this.effectsPanel.thresholdEnabled){
                colorMatrixFilterVars.threshold = this.effectsPanel.thresholdAmountValue;
            };
            TweenLite.to(transformItem.targetObject, 0, {"colorMatrixFilter":colorMatrixFilterVars});
        }

        private function updateEffectsPanelPosition():void{
            if (!this.effectsPanel){
                return;
            };
            setChildIndex(this.effectsPanel, (numChildren - 1));
        }

        private function showLassoTool():void{
            var padding:Number = 50;
            this.lassoTransformItem = TransformItem(this.transformManager.selectedItems[0]);
            this.transformManager.deselectAll();
            if (this.lassoTool){
                this.lassoTool = null;
                this.lassoTool.removeEventListener(LassoTool.CONTROLPOINTS_ADDED, this.lassoToolHandler);
                this.lassoTool.removeEventListener(LassoTool.CANCEL, this.lassoToolHandler);
                removeChild(this.lassoTool);
            };
            this.lassoTool = new LassoTool((-(padding) / 2), (-(padding) / 2), (this.lassoTransformItem.width + padding), (this.lassoTransformItem.height + padding));
            this.lassoTool.x = (this.lassoTransformItem.x - (this.lassoTransformItem.width / 2));
            this.lassoTool.y = (this.lassoTransformItem.y - (this.lassoTransformItem.height / 2));
            this.lassoTool.addEventListener(LassoTool.CONTROLPOINTS_ADDED, this.lassoToolHandler, false, 0, true);
            this.lassoTool.addEventListener(LassoTool.CANCEL, this.lassoToolHandler, false, 0, true);
            this.lassoSpriteItem = new Sprite();
            this.lassoSpriteItem = (this.lassoTransformItem.targetObject as Sprite);
            addChild(this.lassoSpriteItem);
            this.transformManager.removeItem(this.lassoTransformItem);
            addChild(this.lassoTool);
            this.updateEffectsPanelPosition();
        }

        private function lassoToolHandler(e:Event):void{
            var lassoMask:Sprite;
            var _local3:Point;
            var _local4:Sprite;
            var _local5:BitmapData;
            var _local6:Bitmap;
            trace(("QrTransformItemManager.lassoToolHandler(e) : type? " + e.type));
            switch (e.type){
                case LassoTool.CONTROLPOINTS_ADDED:
                    if (!this.maskWindow){
                        this.maskWindow = new LassoToolWindow();
                        addChild(this.maskWindow);
                    };
                    this.maskWindow.addEventListener(LassoToolWindow.OK_CLICK, this.lassoToolHandler);
                    this.maskWindow.addEventListener(LassoToolWindow.CANCEL_CLICK, this.lassoToolHandler);
                    this.maskWindow.addEventListener(LassoToolWindow.TOGGLEMASK_CLICK, this.lassoToolHandler);
                    break;
                case LassoTool.CANCEL:
                    this.lassoTool.dispose();
                    this.lassoSpriteItem.mask = null;
                    this.hideLassoTool();
                    this.transformManager.addItem(this.lassoSpriteItem);
                    break;
                case LassoToolWindow.OK_CLICK:
                    _local3 = new Point(this.lassoSpriteItem.x, this.lassoSpriteItem.y);
                    lassoMask = this.lassoTool.getLassoSprite();
                    lassoMask.x = (lassoMask.y = 0);
                    _local4 = new Sprite();
                    _local4.addChild(this.lassoSpriteItem);
                    this.lassoSpriteItem.x = (this.lassoSpriteItem.width / 2);
                    this.lassoSpriteItem.y = (this.lassoSpriteItem.height / 2);
                    _local4.addChild(lassoMask);
                    this.lassoSpriteItem.mask = lassoMask;
                    _local5 = new BitmapData(_local4.width, _local4.height, true, 0xFFFFFF);
                    _local5.draw(_local4);
                    _local6 = new Bitmap(CropOutWhitespace.crop(_local5));
                    _local4 = null;
                    _local4 = new Sprite();
                    _local4.addChild(_local6);
                    _local6.x = (-(_local6.width) / 2);
                    _local6.y = (-(_local6.height) / 2);
                    _local4.x = _local3.x;
                    _local4.y = _local3.y;
                    this.hideLassoTool();
                    this.addItem(_local4);
                    break;
                case LassoToolWindow.CANCEL_CLICK:
                    this.lassoTool.dispose();
                    this.lassoSpriteItem.mask = null;
                    this.hideLassoTool();
                    this.transformManager.addItem(this.lassoSpriteItem);
                    break;
                case LassoToolWindow.TOGGLEMASK_CLICK:
                    if (this.lassoSpriteItem.mask){
                        this.lassoSpriteItem.mask = null;
                        this.lassoTool.lassoSpriteReturned();
                    } else {
                        lassoMask = this.lassoTool.getLassoSprite();
                        lassoMask.x = (this.lassoSpriteItem.x - (this.lassoSpriteItem.width / 2));
                        lassoMask.y = (this.lassoSpriteItem.y - (this.lassoSpriteItem.height / 2));
                        addChild(lassoMask);
                        this.lassoSpriteItem.mask = lassoMask;
                    };
                    break;
            };
        }

        private function hideLassoTool():void{
            if (this.lassoTool){
                this.lassoTool.dispose();
                removeChild(this.lassoTool);
                this.lassoTool = null;
            };
            if (this.maskWindow){
                if (contains(this.maskWindow)){
                    removeChild(this.maskWindow);
                };
                this.maskWindow.removeEventListener(LassoToolWindow.OK_CLICK, this.lassoToolHandler);
                this.maskWindow.removeEventListener(LassoToolWindow.CANCEL_CLICK, this.lassoToolHandler);
                this.maskWindow.removeEventListener(LassoToolWindow.TOGGLEMASK_CLICK, this.lassoToolHandler);
                this.maskWindow = null;
            };
        }

        public function deselectAllItem():void{
            trace("QrTransformItemManager.deselectAllItem()");
            if (this.lassoTool){
                this.lassoTool.closePath();
            } else {
                this.transformManager.deselectAll();
            };
        }

        public function get hasItem():Boolean{
            return (!((this.itemsNum == 0)));
        }

		// add by gujj 2012/12/21
		public function get exportableTransformItem():TransformItem {
			return this.lastTransformedItem;
		}
		
        public function get hasSelectedItem():Boolean{
            return (this.transformManager.selectedItems[0]);
        }

        public function enable():void{
            this.transformManager.enabled = true;
            this.addEventListener(MouseEvent.CLICK, this.onHolderClick, false, 0, true);
        }

        public function disable():void{
            this.transformManager.enabled = false;
            this.removeEventListener(MouseEvent.CLICK, this.onHolderClick);
        }

        public function dispose():void{
            var item:Sprite;
            var i:int;
            this.hideEffectsPanel();
            this.hideLassoTool();
            this.hideToolbar();
            this.transformManager.destroy();
            if (this.addedSprites){
                i = 0;
                while (i < this.addedSprites.length) {
                    item = Sprite(this.addedSprites[i]);
                    if (contains(item)){
                        removeChild(item);
                    };
                    item = null;
                    i++;
                };
                this.addedSprites = new Vector.<Sprite>();
				this.itemsNum = 0; //add bu gujj 2014/5/22
            };
            if (this.effectsPanel){
                this.effectsPanel.dispose();
                removeChild(this.effectsPanel);
                this.effectsPanel = null;
            };
        }


    }
}//package hu.carnation.transform
