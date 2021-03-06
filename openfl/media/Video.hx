package openfl.media;


import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLTexture;
import lime.graphics.GLRenderContext;
import lime.utils.Float32Array;
import openfl._internal.renderer.canvas.CanvasVideo;
import openfl._internal.renderer.dom.DOMVideo;
import openfl._internal.renderer.opengl.GLVideo;
import openfl._internal.renderer.RenderSession;
import openfl.display.DisplayObject;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.net.NetStream;

@:access(openfl.geom.Rectangle)
@:access(openfl.net.NetStream)


class Video extends DisplayObject {
	
	
	public var deblocking:Int;
	public var smoothing:Bool;
	public var videoHeight (get, never):Int;
	public var videoWidth (get, never):Int;
	
	private var __active:Bool;
	private var __buffer:GLBuffer;
	private var __bufferAlpha:Float;
	private var __bufferData:Float32Array;
	private var __dirty:Bool;
	private var __height:Float;
	private var __stream:NetStream;
	private var __texture:GLTexture;
	private var __textureTime:Float;
	private var __width:Float;
	
	
	public function new (width:Int = 320, height:Int = 240):Void {
		
		super ();
		
		__width = width;
		__height = height;
		
		smoothing = false;
		deblocking = 0;
		
	}
	
	
	public function attachNetStream (netStream:NetStream):Void {
		
		__stream = netStream;
		
		#if (js && html5)
		__stream.__video.play ();
		#end
		
	}
	
	
	public function clear ():Void {
		
		
		
	}
	
	
	private override function __getBounds (rect:Rectangle, matrix:Matrix):Void {
		
		var bounds = Rectangle.__temp;
		bounds.setTo (0, 0, __width, __height);
		bounds.__transform (bounds, matrix);
		
		rect.__expand (bounds.x, bounds.y, bounds.width, bounds.height);
		
	}
	
	
	private function __getBuffer (gl:GLRenderContext, alpha:Float):GLBuffer {
		
		var width = videoWidth;
		var height = videoHeight;
		
		if (width == 0 || height == 0) return null;
		
		if (__buffer == null) {
			
			#if openfl_power_of_two
			
			var newWidth = 1;
			var newHeight = 1;
			
			while (newWidth < width) {
				
				newWidth <<= 1;
				
			}
			
			while (newHeight < height) {
				
				newHeight <<= 1;
				
			}
			
			var uvWidth = width / newWidth;
			var uvHeight = height / newHeight;
			
			#else
			
			var uvWidth = 1;
			var uvHeight = 1;
			
			#end
			
			__bufferData = new Float32Array ([
				
				width, height, 0, uvWidth, uvHeight, alpha,
				0, height, 0, 0, uvHeight, alpha,
				width, 0, 0, uvWidth, 0, alpha,
				0, 0, 0, 0, 0, alpha
				
			]);
			
			__bufferAlpha = alpha;
			__buffer = gl.createBuffer ();
			
			gl.bindBuffer (gl.ARRAY_BUFFER, __buffer);
			gl.bufferData (gl.ARRAY_BUFFER, __bufferData, gl.STATIC_DRAW);
			//gl.bindBuffer (gl.ARRAY_BUFFER, null);
			
		} else if (__bufferAlpha != alpha) {
			
			__bufferData[5] = alpha;
			__bufferData[11] = alpha;
			__bufferData[17] = alpha;
			__bufferData[23] = alpha;
			__bufferAlpha = alpha;
			
			gl.bindBuffer (gl.ARRAY_BUFFER, __buffer);
			gl.bufferData (gl.ARRAY_BUFFER, __bufferData, gl.STATIC_DRAW);
			
		}
		
		return __buffer;
		
	}
	
	
	private function __getTexture (gl:GLRenderContext):GLTexture {
		
		#if (js && html5)
		
		if (__stream == null) return null;
		
		if (__texture == null) {
			
			__texture = gl.createTexture ();
			gl.bindTexture (gl.TEXTURE_2D, __texture);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
			__textureTime = -1;
			
		}
		
		if (__stream.__video.currentTime != __textureTime) {
			
			var internalFormat = gl.RGBA;
			var format = gl.RGBA;
			
			gl.bindTexture (gl.TEXTURE_2D, __texture);
			gl.texImage2D (gl.TEXTURE_2D, 0, internalFormat, format, gl.UNSIGNED_BYTE, __stream.__video);
			
			__textureTime = __stream.__video.currentTime;
			
		}
		
		return __texture;
		
		#else
		
		return null;
		
		#end
		
	}
	
	
	private override function __hitTest (x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool {
		
		if (!hitObject.visible || __isMask) return false;
		if (mask != null && !mask.__hitTestMask (x, y)) return false;
		
		var point = globalToLocal (new Point (x, y));
		
		if (point.x > 0 && point.y > 0 && point.x <= __width && point.y <= __height) {
			
			if (stack != null) {
				
				stack.push (hitObject);
				
			}
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	private override function __hitTestMask (x:Float, y:Float):Bool {
		
		var point = globalToLocal (new Point (x, y));
		
		if (point.x > 0 && point.y > 0 && point.x <= __width && point.y <= __height) {
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	private override function __renderCanvas (renderSession:RenderSession):Void {
		
		CanvasVideo.render (this, renderSession);
		
	}
	
	
	private override function __renderDOM (renderSession:RenderSession):Void {
		
		DOMVideo.render (this, renderSession);
		
	}
	
	
	private override function __renderGL (renderSession:RenderSession):Void {
		
		GLVideo.render (this, renderSession);
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private override function get_height ():Float {
		
		return __height * scaleY;
		
	}
	
	
	private override function set_height (value:Float):Float {
		
		if (scaleY != 1 || value != __height) {
			
			__setTransformDirty ();
			__dirty = true;
			
		}
		
		scaleY = 1;
		return __height = value;
		
	}
	
	
	private function get_videoHeight ():Int {
		
		#if (js && html5)
		if (__stream != null) {
			
			return Std.int (__stream.__video.videoHeight);
			
		}
		#end
		
		return 0;
		
	}
	
	
	private function get_videoWidth ():Int {
		
		#if (js && html5)
		if (__stream != null) {
			
			return Std.int (__stream.__video.videoWidth);
			
		}
		#end
		
		return 0;
		
	}
	
	
	private override function get_width ():Float {
		
		return __width * scaleX;
		
	}
	
	
	private override function set_width (value:Float):Float {
		
		if (scaleX != 1 || __width != value) {
			
			__setTransformDirty ();
			__dirty = true;
			
		}
		
		scaleX = 1;
		return __width = value;
		
	}
	
	
}