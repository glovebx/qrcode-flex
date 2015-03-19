package co.moodshare.pdf
{
	import co.moodshare.pdf.decoding.PNGDecoder;
	import co.moodshare.pdf.images.RawImage;

	import org.alivepdf.encoding.JPEGEncoder;
	import org.alivepdf.encoding.PNGEncoder;
	import org.alivepdf.encoding.TIFFEncoder;
	import org.alivepdf.images.ColorSpace;
	import org.alivepdf.images.DoJPEGImage;
	import org.alivepdf.images.DoPNGImage;
	import org.alivepdf.images.DoTIFFImage;
	import org.alivepdf.images.GIFImage;
	import org.alivepdf.images.ImageFormat;
	import org.alivepdf.images.JPEGImage;
	import org.alivepdf.images.PDFImage;
	import org.alivepdf.images.PNGImage;
	import org.alivepdf.images.TIFFImage;
	import org.alivepdf.images.gif.player.GIFPlayer;
	import org.alivepdf.layout.Resize;
	import org.alivepdf.layout.Size;
	import org.alivepdf.links.ILink;
	import org.alivepdf.pdf.PDF;

	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * 
	 * description
	 *
	 * @langversion ActionScript 3
	 * @playerversion Flash 9.0.0
	 *
	 * @author jamesrobb
	 * @since Jun 8, 2011
	 * 
	 */
	public class MSPDF extends PDF 
	{

		public function MSPDF(orientation : String = 'Portrait', unit : String = 'Mm', autoPageBreak : Boolean = true, pageSize : Size = null, rotation : int = 0)
		{
			super( orientation, unit, autoPageBreak, pageSize, rotation );
		}
		
		
		/**
		 * The addImageStream method takes an incoming image as a ByteArray. This method can be used to embed high-quality images (300 dpi) to the PDF.
		 * You must specify the image color space, if you don't know, there is a lot of chance the color space will be ColorSpace.DEVICE_RGB.
		 * 
		 * @param imageBytes The image stream (PNG, JPEG, GIF)
		 * @param colorSpace The image colorspace
		 * @param resizeMode A resizing behavior, like : new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) to center the image in the page
		 * @param x The x position
		 * @param y The y position
		 * @param width The width of the image
		 * @param height The height of the image
		 * @param rotation The rotation of the image
		 * @param alpha The image alpha
		 * @param blendMode The blend mode to use if multiple images are overlapping
		 * @param keepTransformation Do you want the image current transformation (scaled, rotated) to be preserved
		 * @param link The link to associate the image with when clicked
		 * @example
		 * This example shows how to add an RGB image as a ByteArray into the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImageStream( bytes, ColorSpace.DEVICE_RGB );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a CMYK image as a ByteArray into the current page, the image will take the whole page :
		 * <div class="listing">
		 * <pre>
		 * var resize:Resize = new Resize ( Mode.FULL_PAGE, Position.CENTERED ); 
		 * myPDF.addImageStream( bytes, ColorSpace.DEVICE_RGB, resize );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a CMYK image as a ByteArray into the current page, the image will take the whole page but white margins will be preserved :
		 * <div class="listing">
		 * <pre>
		 * var resize:Resize = new Resize ( Mode.RESIZE_PAGE, Position.CENTERED ); 
		 * myPDF.addImageStream( bytes, ColorSpace.DEVICE_CMYK, resize );
		 * </pre>
		 * </div>
		 */	 
		override public function addImageStream ( imageBytes:ByteArray,
												  colorSpace:String,
												  resizeMode:Resize=null,
												  x:Number=0,
												  y:Number=0,
												  width:Number=0,
												  height:Number=0,
												  rotation:Number=0,
												  alpha:Number=1,
												  blendMode:String="Normal",
												  link:ILink=null ):void
		{
			if ( streamDictionary[imageBytes] == null )
			{
				imageBytes.position = 0;
				
				var id:int = getTotalProperties ( streamDictionary )+1;
				
				if ( imageBytes.readUnsignedShort() == JPEGImage.HEADER )
				{
					image = new JPEGImage ( imageBytes, colorSpace, id );
					
				}else if ( PNGDecoder.isPNG( imageBytes ) ) {
					
					if( PNGDecoder.getColorType( imageBytes ) != 6 )
					{
						image = new PNGImage ( imageBytes, colorSpace, id );
					
					}else{
						
						var bmd : BitmapData = PNGDecoder.decode( imageBytes );
						addBitmapData( bmd, resizeMode, x, y, width, height, rotation, alpha, blendMode, link );
						return;
					}
					
				}else if ( !(imageBytes.position = 0) && imageBytes.readUTFBytes(3) == GIFImage.HEADER ) {
					
					imageBytes.position = 0;
					var decoder:GIFPlayer = new GIFPlayer(false);
					var capture:BitmapData = decoder.loadBytes( imageBytes );
					var bytes:ByteArray = PNGEncoder.encode ( capture );
					image = new DoPNGImage ( capture, bytes, id );
					
				} else if ( !(imageBytes.position = 0) && (imageBytes.endian = Endian.LITTLE_ENDIAN) && imageBytes.readByte() == 73 ){
					
					image = new TIFFImage ( imageBytes, colorSpace, id );
					
				} else throw new Error ("Image format not supported for now.");
				
				streamDictionary[imageBytes] = image;
				
			} else image = streamDictionary[imageBytes];
			
			setAlpha ( alpha, blendMode );
			placeImage( x, y, width, height, rotation, resizeMode, link );
		}
		
		/**
		 * The addImage method takes an incoming DisplayObject. A JPG or PNG (non-transparent) snapshot is done and included in the PDF document.
		 * 
		 * @param displayObject The DisplayObject to embed as a bitmap in the PDF
		 * @param resizeMode A resizing behavior, like : new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) to center the image in the page
		 * @param x The x position
		 * @param y The y position
		 * @param width The width of the image
		 * @param height The height of the image
		 * @param rotation The rotation of the image
		 * @param alpha The image alpha
		 * @param keepTransformation Do you want the image current transformation (scaled, rotated) to be preserved
		 * @param imageFormat The compression to use for the image (PNG or JPG)
		 * @param quality The compression quality if JPG is used
		 * @param blendMode The blend mode to use if multiple images are overlapping
		 * @param link The link to associate the image with when clicked
		 * @example
		 * This example shows how to add a 100% compression quality JPG image centerd on the page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImage( displayObject, new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a 100% compression quality JPG image with no resizing behavior positioned at 20, 20 on the page:
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImage( displayObject, null, 20, 20 );
		 * </pre>
		 * </div>
		 * 
		 */	 
		public function addDisplayObject ( displayObject:DisplayObject,
										   resizeMode:Resize=null,
										   x:Number=0, y:Number=0,
										   width:Number=0,
										   height:Number=0,
										   rotation:Number=0,
										   alpha:Number=1,
										   keepTransformation:Boolean=true,
										   imageFormat:String="PNG",
										   quality:Number=100,
										   blendMode:String="Normal",
										   link:ILink=null ):void
		{			
			if ( streamDictionary[displayObject] == null )
			{	
				var bytes:ByteArray;				
				var bitmapDataBuffer:BitmapData;
				var transformMatrix:Matrix;
				
				displayObjectbounds = displayObject.getBounds( displayObject );
				
				bitmapDataBuffer = new BitmapData ( ( width ) ? width : displayObject.width,
													( height ) ? height : displayObject.height,
													( imageFormat == ImageFormat.PNG ),
													( imageFormat == ImageFormat.PNG ) ? 0x00000000 : 4.294967295E9 );
				
				if ( keepTransformation )
				{		
					transformMatrix = displayObject.transform.matrix;
					transformMatrix.tx = transformMatrix.ty = 0;
					transformMatrix.translate( -(displayObjectbounds.x*displayObject.scaleX), -(displayObjectbounds.y*displayObject.scaleY) );
					
				} else 
				{	
					transformMatrix = new Matrix();
					transformMatrix.translate( -displayObjectbounds.x, -displayObjectbounds.y );
				}
				
				bitmapDataBuffer.draw ( displayObject, transformMatrix );
				
				var id:int = getTotalProperties ( streamDictionary )+1;
				
				if ( imageFormat == ImageFormat.JPG ) 
				{
					var encoder:JPEGEncoder = new JPEGEncoder ( quality );
					bytes = encoder.encode ( bitmapDataBuffer );
					image = new DoJPEGImage ( bitmapDataBuffer, bytes, id );
					
				} else if ( imageFormat == ImageFormat.PNG )
				{
					//bytes = PNGEncoder.encode ( bitmapDataBuffer );
					//image = new DoPNGImage ( bitmapDataBuffer, bytes, id );
					
					addBitmapData( bitmapDataBuffer, resizeMode, x, y, width, height, rotation, alpha, blendMode, link );
					return;
					
				} else
				{
					bytes = TIFFEncoder.encode ( bitmapDataBuffer );
					image = new DoTIFFImage ( bitmapDataBuffer, bytes, id );
				}
				
				streamDictionary[displayObject] = image;
				
			} else image = streamDictionary[displayObject];
			
			setAlpha( alpha, blendMode );
			placeImage( x, y, width, height, rotation, resizeMode, link );
		}
		
		/**
		 * The addTransparentImage method takes an incoming transparent BitmapData instance
		 * 
		 * @param displayObject The DisplayObject to embed as a bitmap in the PDF
		 * @param resizeMode A resizing behavior, like : new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) to center the image in the page
		 * @param x The x position
		 * @param y The y position
		 * @param width The width of the image
		 * @param height The height of the image
		 * @param rotation The rotation of the image
		 * @param alpha The image alpha
		 * @param keepTransformation Do you want the image current transformation (scaled, rotated) to be preserved
		 * @param imageFormat The compression to use for the image (PNG or JPG)
		 * @param quality The compression quality if JPG is used
		 * @param blendMode The blend mode to use if multiple images are overlapping
		 * @param link The link to associate the image with when clicked
		 * @example
		 * This example shows how to add a 100% compression quality JPG image centerd on the page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImage( displayObject, new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a 100% compression quality JPG image with no resizing behavior positioned at 20, 20 on the page:
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImage( displayObject, null, 20, 20 );
		 * </pre>
		 * </div>
		 * 
		 */	
		public function addBitmapData ( bmd:BitmapData,
								 	    resizeMode:Resize=null,
									    x:Number=0,
									    y:Number=0,
									    width:Number=0,
									    height:Number=0,
									    rotation:Number=0,
									    alpha:Number=1,
									    blendMode:String="Normal",
									    link:ILink=null ):void
		{
			var color: ByteArray = new ByteArray();
	        var trans: ByteArray = new ByteArray();
	        var img: ByteArray = bmd.getPixels( bmd.rect );
	        
	        img.position = 0;
	        
	        var transparent : Boolean = bmd.transparent;
	        var pixel : uint;
        	
			while( img.bytesAvailable )
			{
				pixel = img.readInt();
				
				color.writeByte( ( pixel >> 16 ) & 0xff );
                color.writeByte( ( pixel >> 8 ) & 0xff );
                color.writeByte( ( pixel >> 0 ) & 0xff );
				
				if( transparent ) trans.writeByte( ( pixel >> 24 ) & 0xff );
	        }
			
			color.position = 0;
			trans.position = 0;
			
			var id : int;
			
			/*
			 * if transparent, add mask
			 */
			if( transparent )
			{
				id = getTotalProperties ( streamDictionary ) + 1;
				image = new RawImage( trans, ColorSpace.DEVICE_GRAY, id, bmd.width, bmd.height );
				
				streamDictionary[trans] = image;
				
				/*
				 * TODO - mask still appears in pdf even though it's successfully masked the image?
				 * 
				 * One solution is to position it outside the canvas - @see http://staff.dasdeck.de/valentin/fpdf/fpdf_alpha/
				 * seems like a hack - but then again so does having to makes it's alpha 0.
				 * 
				 * I've posted a thread on one of the Adobe forums and am awaiting a reply for the correct solution.
				 */
				setAlpha( 0 );
				placeImage( x, y, width, height, rotation, resizeMode, null );
			}
			
			id = getTotalProperties ( streamDictionary ) + 1;
			image = new RawImage( color, ColorSpace.DEVICE_RGB, id, bmd.width, bmd.height, bmd.transparent );
			
			streamDictionary[color] = image;
			
			setAlpha ( alpha, blendMode );
			placeImage( x, y, width, height, rotation, resizeMode, link );
		}
		
		/*
		 * overriden due to the hightlight block of code below
		 */
		override protected function insertImages ():void
		{
			var filter:String = new String();
			var stream:ByteArray;
			var images : Array = [];
			var image:PDFImage;
			
			/*
			 * Due to the way that the soft masks work, the identifier n
			 * is used to link the mask to it's target.
			 * 
			 * Therefore the images must first be ordered by their
			 * resourceId, as a mask is always added to the streamDictionary
			 * immediately before it's target.
			 */
			for each ( image in streamDictionary )
			{
				images.push( image );
			}
			
			images.sortOn( [ "resourceId" ], Array.NUMERIC );
			
			//////////////////////////////////////////////////////
			
			for each ( image in images )
			{
				newObj();
				image.n = n;
				write('<</Type /XObject');
				write('/Subtype /Image');
				write('/Width '+image.width);
				write('/Height '+image.height);
				
				if ( image.masked )
					write('/SMask '+(n-1)+' 0 R');
				
				if( image.colorSpace == ColorSpace.INDEXED ) 
					write ('/ColorSpace [/'+ColorSpace.INDEXED+' /'+ColorSpace.DEVICE_RGB+' '+((image as PNGImage).pal.length/3-1)+' '+(n+1)+' 0 R]');
				else
				{
					write('/ColorSpace /'+image.colorSpace);
					if( image.colorSpace == ColorSpace.DEVICE_CMYK ) 
						write ('/Decode [1 0 1 0 1 0 1 0]');
				}
				
				write ('/BitsPerComponent '+image.bitsPerComponent);
				
				if (image.filter != null ) 
					write ('/Filter /'+image.filter);
				
				if ( image is PNGImage || image is GIFImage )
				{
					if ( image.parameters != null ) 
						write (image.parameters);
					
					if ( image.transparency != null && image.transparency is Array )
					{
						var trns:String = '';
						var lng:int = image.transparency.length;
						for (var i:int=0;i<lng;i++) 
							trns += image.transparency[i]+' '+image.transparency[i]+' ';
						write('/Mask ['+trns+']');	
					}
				}
				
				stream = image.bytes;
				write('/Length '+stream.length+'>>');
				write('stream');
				buffer.writeBytes (stream);
				buffer.writeUTFBytes ("\n");
				write("endstream");
				write('endobj');
				
				if( image.colorSpace == ColorSpace.INDEXED )
				{
					newObj();
					var pal:String = (image as PNGImage).pal;
					write('<<'+filter+'/Length '+pal.length+'>>');
					writeStream(pal);
					write('endobj');
				}
			}
		}
		
	}
	
}
