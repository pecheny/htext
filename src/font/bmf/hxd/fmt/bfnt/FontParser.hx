package font.bmf.hxd.fmt.bfnt;

import font.bmf.h2d.Font;
import font.bmf.h2d.Tile;
#if (haxe_ver < 4)
import haxe.xml.Fast in Access;
#else
import haxe.xml.Access;
#end

class FontParser {
	@:access(font.bmf.h2d.Font)
	public static function parse(bytes:haxe.io.Bytes, path:String):Font {
		// TODO: Support multiple textures per font.
		var atlasWidth = 1;
		var atlasHeight = 1;
		var tile:Tile = null;
		var font:Font = new Font(null, 0);
		var glyphs = font.glyphs;

		// Supported formats:
		// Littera formats: XML and Text
		// http://kvazars.com/littera/
		// BMFont: Binary(v3)/Text/XML
		// http://www.angelcode.com/products/bmfont/
		// FontBuilder: Divo/BMF
		// https://github.com/andryblack/fontbuilder/downloads
		// Hiero from LibGDX is BMF Text format and supported as well.
		// https://github.com/libgdx/libgdx

		font.baseLine = 0;

		switch (bytes.getInt32(0)) {
			case 0x6F666E69:
				// BFont text format, version 3 (starts with info ...)
				// Can be produced by Littera Text format as well
				var lines = bytes.toString().split("\n");

				// BMFont pads values with spaces, littera doesn't.
				var reg = ~/ *?([0-9a-zA-Z]+)=("[^"]+"|.+?)(?:[ \r]|$)/;
				var idx:Int;

				inline function next():Void {
					var pos = reg.matchedPos();
					idx = pos.pos + pos.len;
				}
				inline function processValue():String {
					var v = reg.matched(2);
					if (v.charCodeAt(0) == '"'.code)
						return v.substring(1, v.length - 1);
					return v;
				}
				inline function extractInt():Int {
					return Std.parseInt(processValue());
				}

				function getSDFChannel() {
					// todo implement channel detection according to values from common block
					return 0;
				}

				var pageCount = 0;

				for (line in lines) {
					idx = line.indexOf(" ");
					switch (line.substr(0, idx)) {
						case "info":
							while (idx < line.length && reg.matchSub(line, idx)) {
								switch (reg.matched(1)) {
									case "face": font.name = processValue();
									case "size": font.size = font.initSize = extractInt();
								}
								next();
							}
						case "common":
							while (idx < line.length && reg.matchSub(line, idx)) {
								switch (reg.matched(1)) {
									case "scaleW": atlasWidth = extractInt();
									case "scaleH": atlasHeight = extractInt();
									case "lineHeight": font.lineHeight = extractInt();
									case "base": font.baseLine = extractInt();
									case "pages":
										pageCount = extractInt();
										if (pageCount != 1) trace("Warning: BMF format only supports one page at the moment.");
								}
								next();
							}
							tile = new Tile(0, 0, atlasWidth, atlasHeight, 0, 0, atlasWidth, atlasHeight);
						case "page":
							while (idx < line.length && reg.matchSub(line, idx)) {
								switch (reg.matched(1)) {
									case "file": font.tilePath = processValue();
								}
								next();
							}
						case "char":
							var id = 0, x = 0, y = 0, width = 0, height = 0, xoffset = 0, yoffset = 0, xadvance = 0;
							while (idx < line.length && reg.matchSub(line, idx)) {
								switch (reg.matched(1)) {
									case "id": id = extractInt();
									case "x": x = extractInt();
									case "y": y = extractInt();
									case "width": width = extractInt();
									case "height": height = extractInt();
									case "xoffset": xoffset = extractInt();
									case "yoffset": yoffset = extractInt();
									case "xadvance": xadvance = extractInt();
								}
								next();
							}
							var t = tile.sub(x, y, width, height, xoffset, yoffset);
							var fc = new FontChar(t, xadvance);
							glyphs.set(id, fc);
						case "kerning":
							var first = 0, second = 0, advance = 0;
							while (idx < line.length && reg.matchSub(line, idx)) {
								switch (reg.matched(1)) {
									case "first": first = extractInt();
									case "second": second = extractInt();
									case "amount": advance = extractInt();
								}
								next();
							}
							var fc = glyphs.get(second);
							if (fc != null) fc.addKerning(first, advance);
						case "sdf":
							var dfSize:Int = 1;
							var mode:SDFMode = SDF(0);
							while (idx < line.length && reg.matchSub(line, idx)) {
								switch (reg.matched(1)) {
									case "size": dfSize = extractInt();
									case "mode": switch processValue() {
										case "sdf": mode = SDF(getSDFChannel());
										case "psdf": mode = PSDF(getSDFChannel());
										case "msdf": mode = MSDF;
									}

								}
								next();
							}
							font.type = SignedDistanceField(mode, dfSize);

					}
				}

			case sign:
				throw "Unknown font signature " + StringTools.hex(sign, 8);
		}
		if (glyphs.get(" ".code) == null)
			glyphs.set(" ".code, new FontChar(tile.sub(0, 0, 0, 0), font.size >> 1));

		font.tile = tile;

		if (font.baseLine == 0) {
			var padding:Float = 0;
			var space = glyphs.get(" ".code);
			if (space != null)
				padding = (space.t.height * .5);

			var a = glyphs.get("A".code);
			if (a == null)
				a = glyphs.get("a".code);
			if (a == null)
				a = glyphs.get("0".code); // numerical only
			if (a == null)
				font.baseLine = font.lineHeight - 2 - padding;
			else
				font.baseLine = a.t.dy + a.t.height - padding;
		}

		var fallback = glyphs.get(0xFFFD); // <?>
		if (fallback == null)
			fallback = glyphs.get(0x25A1); // square
		if (fallback == null)
			fallback = glyphs.get("?".code);
		if (fallback != null)
			font.defaultChar = fallback;

		return font;
	}
}
