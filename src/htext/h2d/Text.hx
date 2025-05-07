package htext.h2d;

/**
	A basic text renderer with multiline support.

	See [Text](https://github.com/HeapsIO/heaps/wiki/Text) section of the manual for more details.
**/

//import font.IFont;

import font.bmf.hxd.Charset;
typedef Char = StrChar; // Int;

abstract StrChar(String) from String to String {
	@:to inline function toInt() return this.charCodeAt(0);
}

@:forward(length, substr)
abstract StrCharAccess(String) from String to String {
	public static inline var EMPTY = "";
	public inline function at(i):Char return this.charAt(i);
}


@:forward(length, substr)
abstract CharCodeAccess(String) from String to String {
	public static inline var EMPTY = -1;
	public inline function at(i) return this.charCodeAt(i);
}



//typedef CharAccess = CharCodeAccess;
typedef CharAccess = StrCharAccess;


typedef TileGroup<T:FontChar2> = {
	public function add(v:T, x:Float, y:Float, ?scale:Float, dfSize:Int ) :Void;
	public function clear() :Void;
}

typedef IFont = {
	function getChar(ch:Char):FontChar2;
	function getLineHeight():Float;
	function getBaseline():Float;
	function getKerningOffset(prevChar:Char, char:Char) :Float;
	function getDFSize():Int;
}


typedef FontChar2 = {
	var dy(default, null):Float;
	function getAdvance():Float;
}

class Text<T:FontChar2, TG:TileGroup<T>> {
	/**
		The font used to render text.
	**/
//    public var font(default, set):Font2<T>;
	public var font(default, set):IFont;

	/**
		Current rendered text.
	**/
	public var text(default, set):String;

	/**
		When set, limits maximum line width and causes word-wrap.
		Affects positioning of the text depending on `textAlign` value.

		When Text is affected by size constraints (see `Object.constraintSize`), smallest of the two is used for word-wrap.
	**/
	public var maxWidth(default, set):Null<Float>;

	/**
		Calculated text width. Can exceed maxWidth in certain cases.
	**/
	public var textWidth(get, null):Float;

	/**
		Calculated text height.

		Not a completely precise text metric and increments in the `Font.lineHeight` steps.
		In `HtmlText`, can be increased by various values depending on the active line font and `HtmlText.lineHeightMode` value.
	**/
	public var textHeight(get, null):Float;

	/**
		Text align rules dictate how the text lines are positioned.
		See `Align` for specific details on each alignment mode.
	**/
	public var textAlign(default, set):Align;

	/**
		Extra letter spacing in pixels.
	**/
	public var letterSpacing(default, set):Float = 0;

	/**
		Extra line spacing in pixels.
	**/
	public var lineSpacing(default, set):Float = 0;

	/**
		Allow line break.
	**/
	public var lineBreak(default, set):Bool = true;


	var charset = Charset.getDefault();

	var glyphs:TG;
	var needsRebuild:Bool;
	var currentText:String;
	var textChanged:Bool = true;

	var calcDone:Bool;
	var calcXMin:Float;
	var calcYMin:Float;
	var calcWidth:Float;
	var calcHeight:Float;
	var calcSizeHeight:Float;
	var constraintWidth:Float = -1;
	var realMaxWidth:Float = -1;

	// var sdfShader : h3d.shader.SignedDistanceField;

	/**
		Creates a new Text instance.
		@param font The font used to render the Text.
		@param parent An optional parent `h2d.Object` instance to which Text adds itself if set.
	**/
	public function new(font:IFont, target:TG) {
		glyphs = target;
		this.font = font;
		textAlign = Left;
		text = "";
		currentText = "";
	}

	function set_font(font) {
		if (this.font == font)
			return font;
		this.font = font;
		// if (font != null) {
		// 	switch (font.type) {
		// 		case BitmapFont:
		// 			if (sdfShader != null) {
		// 				removeShader(sdfShader);
		// 				sdfShader = null;
		// 			}
		// 		case SignedDistanceField(channel, alphaCutoff, smoothing):
		// 			if (sdfShader == null) {
		// 				sdfShader = new h3d.shader.SignedDistanceField();
		// 				addShader(sdfShader);
		// 			}
		// 			sdfShader.alphaCutoff = alphaCutoff;
		// 			sdfShader.smoothing = smoothing;
		// 			sdfShader.channel = channel;
		// 	}
		// }
//		glyphs.visible = false;
		rebuild();
		return font;
	}

	function set_textAlign(a) {
		if (textAlign == a)
			return a;
		textAlign = a;
		rebuild();
		return a;
	}

	function set_letterSpacing(s) {
		if (letterSpacing == s)
			return s;
		letterSpacing = s;
		rebuild();
		return s;
	}

	function set_lineSpacing(s) {
		if (lineSpacing == s)
			return s;
		lineSpacing = s;
		rebuild();
		return s;
	}

	function set_lineBreak(b) {
		if (lineBreak == b)
			return b;
		lineBreak = b;
		rebuild();
		return b;
	}

	public function constraintSize(width:Float, height:Float) {
		constraintWidth = width;
		updateConstraint();
	}

	inline function checkText() {
		if (textChanged && text != currentText) {
			textChanged = false;
			currentText = text;
			calcDone = false;
			needsRebuild = true;
		}
	}

	// override function sync(ctx:RenderContext) {
	// 	super.sync(ctx);
	// 	checkText();
	// 	if (needsRebuild)
	// 		initGlyphs(currentText);
	// }
	// override function draw(ctx:RenderContext) {
	// 	if (glyphs == null) {
	// 		emitTile(ctx, h2d.Tile.fromColor(0xFF00FF, 16, 16));
	// 		return;
	// 	}
	// 	checkText();
	// 	if (needsRebuild)
	// 		initGlyphs(currentText);
	// 	if (dropShadow != null) {
	// 		var oldX = absX, oldY = absY;
	// 		absX += dropShadow.dx * matA + dropShadow.dy * matC;
	// 		absY += dropShadow.dx * matB + dropShadow.dy * matD;
	// 		var oldR = color.r;
	// 		var oldG = color.g;
	// 		var oldB = color.b;
	// 		var oldA = color.a;
	// 		color.setColor(dropShadow.color);
	// 		color.a = dropShadow.alpha * oldA;
	// 		glyphs.drawWith(ctx, this);
	// 		absX = oldX;
	// 		absY = oldY;
	// 		color.set(oldR, oldG, oldB, oldA);
	// 	}
	// 	glyphs.drawWith(ctx, this);
	// }

	function set_text(t:String) {
		var t = t == null ? "null" : t;
		if (t == this.text)
			return t;
		this.text = t;
		textChanged = true;
		validateText();
		onContentChanged();
		return t;
	}

	/**
		Extra validation of the `text` variable when it's changed. Override to add custom validation.

		Only validation of the text is allowed, and attempting to change the text value will lead to undefined behavior.
	**/
	@:dox(show)
	function validateText() {}

	function rebuild() {
		calcDone = false;
		needsRebuild = true;
		onContentChanged();
	}

	/**
		Calculates and returns width of the provided `text` with settings this Text instance.
	**/
	public function calcTextWidth(text:String) {
		if (calcDone) {
			var ow = calcWidth,
				oh = calcHeight,
				osh = calcSizeHeight,
				ox = calcXMin,
				oy = calcYMin;
			initGlyphs(text, false);
			var w = calcWidth;
			calcWidth = ow;
			calcHeight = oh;
			calcSizeHeight = osh;
			calcXMin = ox;
			calcYMin = oy;
			return w;
		} else {
			initGlyphs(text, false);
			calcDone = false;
			return calcWidth;
		}
	}

	/**
		Perform a word-wrap of the `text` based on this Text settings.
	**/
	public function splitText(text:String) {
		return splitRawText(text, 0, 0);
	}

	/**
		<span class="label">Advanced usage</span>
		Perform a word-wrap of the text based on this Text settings.
		@param text String to word-wrap.
		@param leftMargin Starting x offset of the first line.
		@param afterData Minimum remaining space required at the end of the line.
		@param font Optional overriding font to use instead of currently set.
		@param sizes Optional line width array. Will be populated with sizes of split lines if present. Sizes will include both `leftMargin` in it's first line entry.
		@param prevChar Optional character code for concatenation purposes (proper kernings).
	**/
	@:dox(show)
	function splitRawText(text:CharAccess, leftMargin = 0., afterData = 0., ?font:IFont, ?sizes:Array<Float>, ?prevChar:String) {
		var maxWidth = realMaxWidth;
		if (maxWidth < 0) {
			if (sizes == null)
				return text;
			else
				maxWidth = Math.POSITIVE_INFINITY;
		}
		if (font == null)
			font = this.font;
		var lines = [], restPos = 0;
		var x = leftMargin;
		for (i in 0...text.length) {
			var cc = text.at(i);
			var e = font.getChar(cc);
			var newline = cc == '\n'.code;
			var esize = e.getAdvance() + font.getKerningOffset(prevChar, cc);
			var nc = text.at(i + 1);
            if (charset.isBreakChar(cc) && (nc == null || !charset.isComplementChar(nc))) {
				if (lines.length == 0 && leftMargin > 0 && x > maxWidth) {
					lines.push("");
					if (sizes != null)
						sizes.push(leftMargin);
					x -= leftMargin;
				}
				var size = x + esize + letterSpacing; /* TODO : no letter spacing */
				var k = i + 1, max = text.length;
				var prevChar = prevChar;
				var breakFound = false;
				while (size <= maxWidth && k < max) {
					var cc = text.at(k++);
                    if (lineBreak && (charset.isSpace(cc) || cc == '\n'.code)) {
						breakFound = true;
						break;
					}
					var e = font.getChar(cc);
					size += e.getAdvance() + letterSpacing + font.getKerningOffset(prevChar, cc);
					prevChar = cc;
					var nc = text.at(k + 1);
                    if (charset.isBreakChar(cc) && (nc == null || !charset.isComplementChar(nc)))
						break;
				}
				if (lineBreak && (size > maxWidth || (!breakFound && size + afterData > maxWidth))) {
					newline = true;
                    if (charset.isSpace(cc)) {
						lines.push(text.substr(restPos, i - restPos));
						e = null;
					} else {
						lines.push(text.substr(restPos, i + 1 - restPos));
					}
					restPos = i + 1;
				}
			}
			if (e != null && cc != '\n'.code)
				x += esize + letterSpacing;
			if (newline) {
				if (sizes != null)
					sizes.push(x);
				x = 0;
				prevChar = CharAccess.EMPTY;
			} else
				prevChar = cc;
		}
		if (restPos < text.length) {
			if (lines.length == 0 && leftMargin > 0 && x + afterData - letterSpacing > maxWidth) {
				lines.push("");
				if (sizes != null)
					sizes.push(leftMargin);
				x -= leftMargin;
			}
			lines.push(text.substr(restPos, text.length - restPos));
			if (sizes != null)
				sizes.push(x);
		}
		return lines.join("\n");
	}

	/**
		Returns cut `text` based on `progress` percentile.
		Can be used to gradually show appearing text. (Especially useful when using `HtmlText`)
	**/
	public function getTextProgress(text:String, progress:Float) {
		if (progress >= text.length)
			return text;
		return text.substr(0, Std.int(progress));
	}

	function initGlyphs(text:CharAccess, rebuild = true):Void {
		if (rebuild)
			glyphs.clear();
		var x = 0., y = 0., xMax = 0., xMin = 0., yMin = 0., prevChar = CharAccess.EMPTY, linei = 0;
		var align = textAlign;
		var lines = new Array<Float>();
		var dl = font.getLineHeight() + lineSpacing;
		var t:CharAccess = splitRawText(text, 0, 0, lines);

		for (lw in lines) {
			if (lw > x)
				x = lw;
		}
		calcWidth = x;

		switch (align) {
			case Center, Right, MultilineCenter, MultilineRight:
				var max = if (align == MultilineCenter || align == MultilineRight) Math.ceil(calcWidth) else realMaxWidth < 0 ? 0 : Math.ceil(realMaxWidth);
				var k = align == Center || align == MultilineCenter ? 0.5 : 1;
				for (i in 0...lines.length)
					lines[i] = Math.ffloor((max - lines[i]) * k);
				x = lines[0];
				xMin = x;
			case Left:
				x = 0;
		}

		for (i in 0...t.length) {
			var cc = t.at(i);
			var e = font.getChar(cc);
			var offs = font.getKerningOffset(prevChar, cc);
			var esize = e.getAdvance() + offs;
			// if the next word goes past the max width, change it into a newline

			if (cc == '\n'.code) {
				if (x > xMax)
					xMax = x;
				switch (align) {
					case Left:
						x = 0;
					case Right, Center, MultilineCenter, MultilineRight:
						x = lines[++linei];
						if (x < xMin)
							xMin = x;
				}
				y += dl;
				prevChar = CharAccess.EMPTY;
			} else {
				if (e != null) {
					if (rebuild)
						glyphs.add(cast e, x + offs, y, 1, font.getDFSize());
					var dy = e.dy + font.getLineHeight();
					if (y == 0 && dy < yMin)
						yMin = dy;
					x += esize + letterSpacing;
				}
				prevChar = cc;
			}
		}
		if (x > xMax)
			xMax = x;

		calcXMin = xMin;
		calcYMin = yMin;
		calcWidth = xMax - xMin;
		calcHeight = y + font.getLineHeight();
        calcSizeHeight = y + (font.getBaseline() > 0 ? font.getBaseline() : font.getLineHeight());
		calcDone = true;
		if (rebuild)
			needsRebuild = false;
	}

	inline function updateSize() {
		checkText();
		if (!calcDone)
			initGlyphs(text, needsRebuild);
	}

	function get_textHeight() {
		updateSize();
		return calcHeight;
	}

	function get_textWidth() {
		updateSize();
		return calcWidth;
	}

	function set_maxWidth(w) {
		if (maxWidth == w)
			return w;
		maxWidth = w;
		updateConstraint();
		return w;
	}

	function updateConstraint() {
		var old = realMaxWidth;
		if (maxWidth == null)
			realMaxWidth = constraintWidth;
		else if (constraintWidth < 0)
			realMaxWidth = maxWidth;
		else
			realMaxWidth = Math.min(maxWidth, constraintWidth);
		if (realMaxWidth != old)
			rebuild();
	}

	inline function onContentChanged() {}
}

/**
	`Text` alignment rules.
**/
enum Align {
	/**
		Aligns the text to the left edge.
	**/
	Left;

	/**
		Aligns the text to the right edge.

		When `Text.maxWidth` is set and/or Text size is constrained (see `Object.constraintSize`), right edge is considered the smallest of the two.

		Otherwise edge is at the `0` coordinate of the Text instance.

		See Text sample for showcase.
	**/
	Right;

	/**
		Centers the text alignment.

		When `Text.maxWidth` is set and/or Text size is constrained (see `Object.constraintSize`), center is calculated from 0 to the smallest of the two.

		Otherwise text is centered around `0` coordinate of the Text instance.

		See Text sample for showcase.
	**/
	Center;

	/**
		With respect to Text constraints, aligns the text to the right edge of the longest line width.

		When `Text.maxWidth` is set and/or Text size is constrained (see `Object.constraintSize`),
		right edge is calculated as the smallest value of the `maxWidth`, constrained width and longest line width (after word-wrap from constraints).

		Otherwise uses longest line width as the right edge.

		See Text sample for showcase.
	**/
	MultilineRight;

	/**
		Centers the text with respect to Text constraints with the longest line width.

		When `Text.maxWidth` is set and/or Text size is constrained (see `Object.constraintSize`),
		center is calculated from the to the smallest value of the `maxWidth`, constrained width and longest line width (after word-wrap from constraints).

		Otherwise calculates center from 0 to the longest line width.

		See Text sample for showcase.
	**/
	MultilineCenter;
}
