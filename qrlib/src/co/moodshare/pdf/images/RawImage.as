package co.moodshare.pdf.images
{
	import org.alivepdf.images.ColorSpace;
	import org.alivepdf.images.PDFImage;

	import flash.utils.ByteArray;

	/**
	 * 
	 * description
	 *
	 * @langversion ActionScript 3
	 * @playerversion Flash 9.0.0
	 *
	 * @author jamesrobb
	 * @since Jun 7, 2011
	 * 
	 */
	public class RawImage extends PDFImage 
	{



		public function RawImage( imageStream : ByteArray,
								  colorSpace : String,
								  id : int,
								  wd : Number,
								  ht : Number,
								  isMasked : Boolean = false )
		{
			_width = wd;
			_height = ht;
//			_masked = isMasked;
			
			super( imageStream, colorSpace, id );
		}
		
		/*
		 * @see http://www.w3.org/TR/PNG-Chunks.html
		 */
		protected override function parse():void
		{
			var color : int = ( _colorSpace == ColorSpace.DEVICE_GRAY ) ? 1 : 3;
			
			_parameters = '/DecodeParms <</Predictor 15 /Colors ' + color + ' /BitsPerComponent '+bitsPerComponent+' /Columns '+width+'>>';
		}
		
	}
	
}
