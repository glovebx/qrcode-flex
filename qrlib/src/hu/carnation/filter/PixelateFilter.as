//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.filter{
    import flash.filters.ShaderFilter;
    import flash.display.Shader;

    public class PixelateFilter extends ShaderFilter {

        private var Filter:Class;

        public function PixelateFilter(dim:Number=1):void{
            this.Filter = PixelateFilter_Filter;
            super();
            this.shader = new Shader(new this.Filter());
        }

        public function set dimension(value:Number):void{
            shader.data.dimension.value[0] = value;
        }

        public function get dimension():Number{
            return (shader.data.dimension.value[0]);
        }


    }
}//package hu.carnation.filter
