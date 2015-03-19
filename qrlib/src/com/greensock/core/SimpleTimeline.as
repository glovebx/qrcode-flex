//Created by Action Script Viewer - http://www.buraks.com/asv
package com.greensock.core{
    public class SimpleTimeline extends TweenCore {

        protected var _firstChild:TweenCore;
        protected var _lastChild:TweenCore;
        public var autoRemoveChildren:Boolean;

        public function SimpleTimeline(vars:Object=null){
            super(0, vars);
        }

        public function insert(tween:TweenCore, time=0):TweenCore{
            var prevTimeline:SimpleTimeline = tween.timeline;
            if (((!(tween.cachedOrphan)) && (prevTimeline))){
                prevTimeline.remove(tween, true);
            };
            tween.timeline = this;
            tween.cachedStartTime = (Number(time) + tween.delay);
            if (tween.gc){
                tween.setEnabled(true, true);
            };
            if (((tween.cachedPaused) && (!((prevTimeline == this))))){
                tween.cachedPauseTime = (tween.cachedStartTime + ((this.rawTime - tween.cachedStartTime) / tween.cachedTimeScale));
            };
            if (this._lastChild){
                this._lastChild.nextNode = tween;
            } else {
                this._firstChild = tween;
            };
            tween.prevNode = this._lastChild;
            this._lastChild = tween;
            tween.nextNode = null;
            tween.cachedOrphan = false;
            return (tween);
        }

        public function remove(tween:TweenCore, skipDisable:Boolean=false):void{
            if (tween.cachedOrphan){
                return;
            };
            if (!skipDisable){
                tween.setEnabled(false, true);
            };
            if (tween.nextNode){
                tween.nextNode.prevNode = tween.prevNode;
            } else {
                if (this._lastChild == tween){
                    this._lastChild = tween.prevNode;
                };
            };
            if (tween.prevNode){
                tween.prevNode.nextNode = tween.nextNode;
            } else {
                if (this._firstChild == tween){
                    this._firstChild = tween.nextNode;
                };
            };
            tween.cachedOrphan = true;
        }

        override public function renderTime(time:Number, suppressEvents:Boolean=false, force:Boolean=false):void{
            var dur:Number;
            var next:TweenCore;
            var tween:TweenCore = this._firstChild;
            this.cachedTotalTime = time;
            this.cachedTime = time;
            while (tween) {
                next = tween.nextNode;
                if (((tween.active) || ((((((time >= tween.cachedStartTime)) && (!(tween.cachedPaused)))) && (!(tween.gc)))))){
                    if (!tween.cachedReversed){
                        tween.renderTime(((time - tween.cachedStartTime) * tween.cachedTimeScale), suppressEvents, false);
                    } else {
                        dur = ((tween.cacheIsDirty) ? tween.totalDuration : tween.cachedTotalDuration);
                        tween.renderTime((dur - ((time - tween.cachedStartTime) * tween.cachedTimeScale)), suppressEvents, false);
                    };
                };
                tween = next;
            };
        }

        public function get rawTime():Number{
            return (this.cachedTotalTime);
        }


    }
}//package com.greensock.core
