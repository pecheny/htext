package font.bmf.h2d;

/**
	A core 2D rendering component representing a region of an underlying `h3d.mat.Texture`.

	Tiles cannot be created directly, and instances are created with the following methods:
	* Via the Resource Management system: `hxd.res.Image.toTile`.
	* From pre-existing Texture: `Tile.fromTexture`.
	* From pre-existing `BitmapData` or `Pixels`: `Tile.fromBitmap` and `Tile.fromPixels` (as well as `Tile.autoCut`).
	* From solid color: `Tile.fromColor`.
	* From previously existing Tile instance via various methods, such as `Tile.sub`.
**/
@:allow(font.bmf.h2d)
class Tile {
	var u:Float;
	var v:Float;
	var u2:Float;
	var v2:Float;

	public var texWidth:Int = -1;
	public var texHeight:Int = -1;

	/**
		Visual offset of the Tile along the X axis during rendering.
	**/
	public var dx:Float;

	/**
		Visual offset of the Tile along the Y axis during rendering.
	**/
	public var dy:Float;

	/**
		Horizontal position of the Tile on the Texture.

		Cannot be modified directly, use `Tile.setPosition` instead.
	**/
	public var x(default, null):Float;

	/**
		Vertical position of the Tile on the Texture.

		Cannot be modified directly, use `Tile.setPosition` instead.
	**/
	public var y(default, null):Float;

	/**
		Width of the Tile.
		Not guaranteed to represent real width of the Tile on texture. (see `Tile.scaleToSize`)

		Cannot be modified directly, use `Tile.setSize` instead.
	**/
	public var width(default, null):Float;

	/**
		Height of the Tile.
		Not guaranteed to represent real height of the Tile on texture. (see `Tile.scaleToSize`)

		Cannot be modified directly, use `Tile.setSize` instead.
	**/
	public var height(default, null):Float;

	public function new(x:Float, y:Float, w:Float, h:Float, dx:Float = 0, dy:Float = 0, texWidth = 1, texHeight = 1) {
		this.texWidth = texWidth;
		this.texHeight = texHeight;
		this.x = x;
		this.y = y;
		this.width = w;
		this.height = h;
		this.dx = dx;
		this.dy = dy;
		recalcUV();
	}

	/**
		Create a sub-region of this Tile with specified size and offset.
		@param x The offset on top of the current Tile offset along the X axis.
		@param y The offset on top of the current Tile offset along the Y axis.
		@param w The width of the new Tile region. Can exceed current tile size.
		@param h The height of the new Tile region. Can exceed the current tile size.
		@param dx An optional visual offset of the new Tile along the X axis.
		@param dy An optional visual offset of the new Tile along the Y axis.
	**/
	public function sub(x:Float, y:Float, w:Float, h:Float, dx = 0., dy = 0.):Tile {
		return new Tile(this.x + x, this.y + y, w, h, dx, dy, texWidth, texHeight);
	}

	/**
		Returns a new Tile with shifting origin point (`dx` and `dy`) to the tile center.

		To modify this Tile origin point, use `Tile.setCenterRatio`.
	**/
	public function center():Tile {
		return sub(0, 0, width, height, -(width * .5), -(height * .5));
	}

	/**
		Sets `dx` / `dy` as origin point dictated by `px` / `py` with a default being center.
	**/
	public inline function setCenterRatio(?px:Float = 0.5, ?py:Float = 0.5):Void {
		dx = -(px * width);
		dy = -(py * height);
	}

	/**
		Flips the Tile horizontally. Note that `dx` is flipped as well.
	**/
	public function flipX():Void {
		var tmp = u;
		u = u2;
		u2 = tmp;
		dx = -dx - width;
	}

	/**
		Flips the Tile vertically. Note that `dy` is flipped as well.
	**/
	public function flipY():Void {
		var tmp = v;
		v = v2;
		v2 = tmp;
		dy = -dy - height;
	}

	/**
		Set the Tile position in the texture to the specified coordinate.
	**/
	public function setPosition(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
		recalcUV();
	}

	inline function recalcUV() {
		if (hasAtlasSize()) {
			u = x / texWidth;
			v = y / texHeight;
			u2 = (x + width) / texWidth;
			v2 = (y + height) / texHeight;
		}
	}

	inline function hasAtlasSize() {
		return texHeight > 0 && texWidth > 0;
	}

	/**
		Set the Tile size in the texture to the specified dimensions.
	**/
	public function setSize(w:Float, h:Float):Void {
		this.width = w;
		this.height = h;
		if (hasAtlasSize()) {
			u2 = (x + w) / texWidth;
			v2 = (y + h) / texHeight;
		}
	}

	/**
		Rescales the Tile to be of the set width and height, but without affecting the uv coordinates.

		Using this method allows to upscale/downscale Tiles, but creates a mismatch between the tile uv and width/height values.
		Due to that, using any methods that modify the uv value will cause the new uv to treat scaled width and height as true dimensions
		and can lead to unexpected results if not accounted for.
	**/
	public function scaleToSize(w:Float, h:Float):Void {
		this.width = w;
		this.height = h;
	}

	/**
		Scrolls the texture position by specified amount.
	**/
	public function scrollDiscrete(dx:Float, dy:Float):Void {
		u += dx / texWidth;
		v -= dy / texHeight;
		u2 += dx / texWidth;
		v2 -= dy / texHeight;
		x = u * texWidth;
		y = v * texHeight;
	}

	/**
		Disposes of the Tile and its underlying Texture.
		Note that if Texture is used by other Tile instances, it will cause them to point at a disposed texture and can lead to errors.
	**/
	// public function dispose() : Void {
	// 	if( innerTex != null ) innerTex.dispose();
	// 	innerTex = null;
	// }

	/**
		Create a copy of this Tile instance.
	**/
	public function clone():Tile {
		var t = new Tile(x, y, width, height, dx, dy);
		// t.innerTex = innerTex;
		t.u = u;
		t.u2 = u2;
		t.v = v;
		t.v2 = v2;
		return t;
	}

	/**
		Split the Tile horizontally or vertically by the number of given frames.
		@param frames The amount of frames this Tile has to be split into.
		@param vertical Causes split to be done vertically instead of horizontal split.
		@param subpixel When enabled, retains the floating-point remainder if calculated frame size is not integral.
	**/
	public function split(frames:Int = 0, vertical = false, subpixel = false):Array<Tile> {
		var tl = [];
		if (vertical) {
			if (frames == 0)
				frames = Std.int(height / width);
			var stride = subpixel ? height / frames : Std.int(height / frames);
			for (i in 0...frames)
				tl.push(sub(0, i * stride, width, stride));
		} else {
			if (frames == 0)
				frames = Std.int(width / height);
			var stride = subpixel ? width / frames : Std.int(width / frames);
			for (i in 0...frames)
				tl.push(sub(i * stride, 0, stride, height));
		}
		return tl;
	}

	/**
		Split the tile into a list of tiles of Size x Size pixels.

		@param size The width and height of the new Tiles.
		@param dx Optional visual offset of the new Tiles along the X axis.
		@param dy Optional visual offset of the new Tiles along the Y axis.
		@returns A one-dimensional array ordered in Y/X.
	**/
	public function gridFlatten(size:Float, dx = 0., dy = 0.):Array<Tile> {
		return [
			for (y in 0...Std.int(height / size))
				for (x in 0...Std.int(width / size))
					sub(x * size, y * size, size, size, dx, dy)
		];
	}

	/**
		Split the tile into a list of tiles of Size x Size pixels.

		@param size The width and height of the new Tiles.
		@param dx Optional visual offset of the new Tiles along the X axis.
		@param dy Optional visual offset of the new Tiles along the Y axis.
		@returns A two-dimensional array ordered in `[X][Y]`.
	**/
	public function grid(size:Float, dx = 0., dy = 0.):Array<Array<Tile>> {
		return [
			for (x in 0...Std.int(width / size)) [
				for (y in 0...Std.int(height / size))
					sub(x * size, y * size, size, size, dx, dy)
			]
		];
	}

	@:dox(hide)
	public function toString():String {
		return "Tile(" + x + "," + y + "," + width + "x" + height + (dx != 0 || dy != 0 ? "," + dx + ":" + dy : "") + ")";
	}

	// function upload( bmp:hxd.BitmapData ) : Void {
	// 	var w = innerTex.width;
	// 	var h = innerTex.height;
	// 	#if flash
	// 	if( w != bmp.width || h != bmp.height ) {
	// 		var bmp2 = new flash.display.BitmapData(w, h, true, 0);
	// 		var p0 = new flash.geom.Point(0, 0);
	// 		var bmp = bmp.toNative();
	// 		bmp2.copyPixels(bmp, bmp.rect, p0, bmp, p0, true);
	// 		innerTex.uploadBitmap(hxd.BitmapData.fromNative(bmp2));
	// 		bmp2.dispose();
	// 	} else
	// 	#end
	// 	innerTex.uploadBitmap(bmp);
	// }
	/**
		Create a solid color Tile with specified width, height, color and alpha.
		@param color The RGB color of the Tile.
		@param width The width of the Tile in pixels.
		@param height The height of the Tile in pixels.
		@param alpha The transparency of the Tile.
	**/
	// public static function fromColor( color : Int, ?width = 1, ?height = 1, ?alpha = 1. ) : Tile {
	// 	var t = new Tile(h3d.mat.Texture.fromColor(color,alpha),0,0,1,1);
	// 	// scale to size
	// 	t.width = width;
	// 	t.height = height;
	// 	return t;
	// }
	/**
		Creates a new Texture from provided BitmapData and returns a Tile representing it.
	**/
	// public static function fromBitmap( bmp : hxd.BitmapData ) : Tile {
	// 	var tex = h3d.mat.Texture.fromBitmap(bmp);
	// 	return new Tile(tex, 0, 0, bmp.width, bmp.height);
	// }
	// /**
	// 	Creates a new POT Texture from bmp and cuts it in a grid of tiles with maximum size of `[width, height]`.
	// 	Algorithm will use bottom-right pixels as background color and cut out empty space from each Tile and
	// 	will modify the origin point to retain the Tile position.
	// 	Each row scan continues as long as there are no empty tiles.
	// 	@param bmp The BitmapData which will be split into tiles.
	// 	@param width The width of a single grid entry.
	// 	@param height An optional height of a single grid entry. Width will be used if not provided.
	// **/
	// public static function autoCut( bmp : hxd.BitmapData, width : Int, ?height : Int ) : { main: Tile, tiles: Array<Array<Tile>> } {
	// 	#if js
	// 	bmp.lock();
	// 	#end
	// 	if( height == null ) height = width;
	// 	var colorBG = bmp.getPixel(bmp.width - 1, bmp.height - 1);
	// 	var tl = new Array();
	// 	var w = 1, h = 1;
	// 	while( w < bmp.width )
	// 		w <<= 1;
	// 	while( h < bmp.height )
	// 		h <<= 1;
	// 	var tex = new h3d.mat.Texture(w, h);
	// 	for( y in 0...Std.int(bmp.height / height) ) {
	// 		var a = [];
	// 		tl[y] = a;
	// 		for( x in 0...Std.int(bmp.width / width) ) {
	// 			var sz = isEmpty(bmp, x * width, y * height, width, height, colorBG);
	// 			if( sz == null )
	// 				break;
	// 			a.push(new Tile(tex,x*width+sz.dx, y*height+sz.dy, sz.w, sz.h, sz.dx, sz.dy));
	// 		}
	// 	}
	// 	#if js
	// 	bmp.unlock();
	// 	#end
	// 	var main = new Tile(tex, 0, 0, bmp.width, bmp.height);
	// 	main.upload(bmp);
	// 	return { main : main, tiles : tl };
	// }
	/**
		Create new Tile from provided Texture instance.
	**/
	// public static function fromTexture( t : h3d.mat.Texture ) : Tile {
	// 	return new Tile(t, 0, 0, t.width, t.height);
	// }
	/**
		Creates new POT Texture from Pixels and returns a Tile representing it.
	**/
	// public static function fromPixels( pixels : hxd.Pixels ) : Tile {
	// 	var pix2 = pixels.makeSquare(true);
	// 	var t = h3d.mat.Texture.fromPixels(pix2, h3d.mat.Texture.nativeFormat);
	// 	if( pix2 != pixels ) pix2.dispose();
	// 	return new Tile(t, 0, 0, pixels.width, pixels.height);
	// }
	// static function isEmpty( b : hxd.BitmapData, px : Int, py : Int, width : Int, height : Int, bg : Int ) {
	// 	var empty = true;
	// 	var xmin = width, ymin = height, xmax = 0, ymax = 0;
	// 	for( x in 0...width )
	// 		for( y in 0...height ) {
	// 			var color : Int = b.getPixel(x + px, y + py);
	// 			if( color & 0xFF000000 == 0 ) {
	// 				if( color != 0 ) b.setPixel(x + px, y + py, 0);
	// 				continue;
	// 			}
	// 			if( color != bg ) {
	// 				empty = false;
	// 				if( x < xmin ) xmin = x;
	// 				if( y < ymin ) ymin = y;
	// 				if( x > xmax ) xmax = x;
	// 				if( y > ymax ) ymax = y;
	// 			}
	// 			if( color == bg && color != 0 )
	// 				b.setPixel(x + px, y + py, 0);
	// 		}
	// 	return empty ? null : { dx : xmin, dy : ymin, w : xmax - xmin + 1, h : ymax - ymin + 1 };
	// }
}
