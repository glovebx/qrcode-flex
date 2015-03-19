/*
  Copyright (c) 2008, Adobe Systems Incorporated
  All rights reserved.

  Redistribution and use in source and binary forms, with or without 
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
  
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
  
  * Neither the name of Adobe Systems Incorporated nor the names of its 
    contributors may be used to endorse or promote products derived from 
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package co.moodshare.pdf.encoding
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;

	/**
	 * Class that converts BitmapData into a valid PNG
	 */	
	public class PNGEncoder
	{
		/**
		 * Creates a PNG image from the specified BitmapData.
		 * 
		 * Supports the creation of a colortype 6 (32 bit ARGB)
		 * and color type 2 (24 bit RGB) PNG dependng on the transparency of
		 * the supplied BitmapData.
		 *
		 * @param image The BitmapData that will be converted into the PNG format.
		 * @return a ByteArray representing the PNG encoded image data.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */			
	    public static function encode( img:BitmapData ):ByteArray
	    {
	        // Create output byte array
	        var png:ByteArray = createOutput();
	        
	        // Build IHDR chunk
	        var IHDR:ByteArray = createIHDR( img.width, img.height, 8, img.transparent ? 6 : 2 );
	        
	        writeChunk(png,0x49484452,IHDR);
	        // Build IDAT chunk
	        var IDAT:ByteArray= new ByteArray();
	        for(var i:int=0;i < img.height;i++) {
	            // no filter
	            IDAT.writeByte(0);
	            var p:uint;
	            var j:int;
	            if ( !img.transparent ) {
	                for(j=0;j < img.width;j++) {
	                    p = img.getPixel(j,i);
	                    
	                    IDAT.writeByte( (p >> 16) & 0xff );
                		IDAT.writeByte( (p >> 8) & 0xff );
                		IDAT.writeByte( (p >> 0) & 0xff );
	                    //IDAT.writeUnsignedInt(
	                        //uint(((p&0xFFFFFF) << 8)|0xFF));
	                }
	            } else {
	            	
	                for(j=0;j < img.width;j++)
	                {
	                    p = img.getPixel32(j,i);
                		
	                    IDAT.writeUnsignedInt(
	                        uint(((p&0xFFFFFF) << 8)|
	                        (p>>>24)));
	                }
	            }
	        }
	        
	        IDAT.compress();
	        writeChunk(png,0x49444154,IDAT);
	        // Build IEND chunk
	        writeChunk(png,0x49454E44,null);
	        // return PNG
	        return png;
	    }
	    
	    /**
		 * Creates an 8 bit grayscale PNG image from the alpha channel of the supplied BitmapData.
		 * 
		 * Supports the creation of a colorType 0 (8 bit PNG)
		 *
		 * @param image The BitmapData that will be converted into the PNG format.
		 * @return a ByteArray representing the PNG encoded image data.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */		
	    public static function encodeGrayscale( img:BitmapData ):ByteArray
	    {
	        // Create output byte array
	        var png:ByteArray = createOutput();
	        
	        // Build IHDR chunk
	        var IHDR:ByteArray = createIHDR( img.width, img.height, 8, 0 );
	        
	        writeChunk(png,0x49484452,IHDR);
	        // Build IDAT chunk
	        var IDAT:ByteArray= new ByteArray();
	        for(var i:int=0;i < img.height;i++) {
	            // no filter
	            IDAT.writeByte(0);
	            var p:uint;
	            var j:int;
	            for(j=0;j < img.width;j++)
	            {
                    p = img.getPixel32(j,i);
                    IDAT.writeByte( (p >> 24) & 0xff );
                }
	        }
	        IDAT.compress();
	        
	        writeChunk(png,0x49444154,IDAT);
	        // Build IEND chunk
	        writeChunk(png,0x49454E44,null);
	        // return PNG
	        return png;
	    }
	    
	    /**
		 * Creates a PNG image from the supplied raw ByteArray.
		 * 
		 * The supplied ByteArray should only contain pixel level information
		 * and must be RGBA - BitmapData outputs ARGB and will need to be modified
		 * first using the <code>convertARGBToRGBA()</code> method first
		 * 
		 * i.e each byte in the ByteArray is an 8 bit component relating to a pixel
		 * within an image.
		 * 
		 * Supports the creation of colorType
		 * 
		 * <li>0 (8 bit grayscale) - every byte of the supplied byteArray respresents a pixel</li>
		 * <li>2 (24 bit RGB) - every 3 bytes of the supplied byteArray respresent a pixel</li>
		 * <li>4 (16 bit grayscale alpha) - every 2 bytes of the supplied byteArray respresent a pixel</li>
		 * <li>6 (32 bit RGBA) - every 4 bytes of the supplied byteArray respresent a pixel</li>
		 *
		 * @param bytes The ByteArray instance to be converted into a PNG
		 * @param width The width of the outputted PNG
		 * @param height The height of the outputted PNG
		 * @param transparent Whether the outputted PNG contains transparency
		 * @param grayScale Whether the outputted PNG should be grayscale
		 * @return a ByteArray representing the PNG encoded image data.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */	
	    public static function encodeBytes( width:Number,
	    									height:Number,
	    									bytes:ByteArray,
	    									transparent:Boolean = false,
	    									grayScale:Boolean = false ):ByteArray
	    {
	    	 // Create output byte array
	        var png:ByteArray = createOutput();
	        
	        var ct : int = transparent ? grayScale ? 4 : 6 : grayScale ? 0 : 2;
	        // Build IHDR chunk
	        var IHDR:ByteArray = createIHDR( width, height, 8, ct );
	        
	        writeChunk(png,0x49484452,IHDR);
	        // Build IDAT chunk
	        var IDAT:ByteArray= new ByteArray();
	        var i:int = 0;
	        var rl : int = width * bytesPerPixel( ct );
	        
	        var row : ByteArray = new ByteArray();
	        bytes.position = 0;
	        
	        for( i; i < height ;i++ )
	        {
	            // adds no filter
	            IDAT.writeByte(0);
	            bytes.readBytes( row, 0, rl );
	            IDAT.writeBytes( row );
	        }
	        
	        IDAT.compress();
	        writeChunk(png,0x49444154,IDAT);
	        // Build IEND chunk
	        writeChunk(png,0x49454E44,null);
	        // return PNG
	        return png;
	    }
	    
	    /**
	     * Converts the supplied ARGB ByteArray - as returned
	     * by BitmpaData.getPixels() - from ARGB to RGBA, the expected
	     * type for a PNG - and probably some other things...
	     * 
	     * @param bytes An ARGB ByteArray
	     * @return the converted ByteArray
	     */
	    public static function convertARGBToRGBA( bytes:ByteArray ):ByteArray
	    {
	    	bytes.position = 0;
	    	
	    	var RGBA : ByteArray = new ByteArray();			
			var p : uint;
			
			while( bytes.bytesAvailable )
			{
				p = bytes.readUnsignedInt();
				RGBA.writeUnsignedInt( ( p >>> 8 )|( p << 24 ) );
			}
			
			return RGBA;
	    }
	    
	    
	    private static function createOutput():ByteArray
	    {
	    	 // Create output byte array
	        var png:ByteArray = new ByteArray();
	        // Write PNG signature
	        png.writeUnsignedInt(0x89504e47);
	        png.writeUnsignedInt(0x0D0A1A0A);
	        
	        return png;
	    }
	    
	    
	    private static function createIHDR( width:Number,
		    							    height:Number,
		    							    bitDepth:int,
		    							    colorType:int ):ByteArray
	    {
	    	var IHDR:ByteArray = new ByteArray();
	        IHDR.writeInt( width );
	        IHDR.writeInt( height );
	        IHDR.writeByte( bitDepth );//bit depth
	        IHDR.writeByte( colorType );//color type - 6 = 32 bit ARGB : 2 : 24 bit RGB : 0 = grayscale
	        IHDR.writeByte(0);//compression
	        IHDR.writeByte(0);//filter method
	        IHDR.writeByte(0);//interlace method
	    	
	    	return IHDR;
	    }
	    
	
	    private static var crcTable:Array;
	    private static var crcTableComputed:Boolean = false;
	
	    private static function writeChunk(png:ByteArray, 
	            type:uint, data:ByteArray):void {
	        if (!crcTableComputed) {
	            crcTableComputed = true;
	            crcTable = [];
	            var c:uint;
	            for (var n:uint = 0; n < 256; n++) {
	                c = n;
	                for (var k:uint = 0; k < 8; k++) {
	                    if (c & 1) {
	                        c = uint(uint(0xedb88320) ^ 
	                            uint(c >>> 1));
	                    } else {
	                        c = uint(c >>> 1);
	                    }
	                }
	                crcTable[n] = c;
	            }
	        }
	        var len:uint = 0;
	        if (data != null) {
	            len = data.length;
	        }
	        png.writeUnsignedInt(len);
	        var p:uint = png.position;
	        png.writeUnsignedInt(type);
	        if ( data != null ) {
	            png.writeBytes(data);
	        }
	        var e:uint = png.position;
	        png.position = p;
	        c = 0xffffffff;
	        for (var i:int = 0; i < (e-p); i++) {
	            c = uint(crcTable[
	                (c ^ png.readUnsignedByte()) & 
	                uint(0xff)] ^ uint(c >>> 8));
	        }
	        c = uint(c^uint(0xffffffff));
	        png.position = e;
	        png.writeUnsignedInt(c);
	    }
	    
	    
	    private static function bytesPerPixel( colorType:int ):int
	    {
	    	var result : int;
	    	
	    	switch( colorType )
	        {
	        	case 0 :
	        		
	        		result = 1;
	        		break;
	        		
	        	case 2 :
	        		
	        		result = 3;
	        		break;
	        		
	        	case 4 :
	        		
	        		result = 2;
	        		break;
	        		
	        	case 6 :
	        		
	        		result = 4;
	        		break;
	        }
	        
	        return result;
	    }
	}
}
