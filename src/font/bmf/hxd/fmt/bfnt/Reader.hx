package font.bmf.hxd.fmt.bfnt;

import haxe.io.Input;

@:access(font.bmf.h2d.Font)
class Reader {
	var i:Input;
	var font:font.bmf.h2d.Font;
	var defaultChar:Int;

	public var path(default, null):String;

	public function new(i:Input) {
		this.i = i;
	}

	public function readHeader() {
		if (i.readString(4) != "BFNT" || i.readByte() != 0)
			throw "Not a BFNT file!";

		var font:font.bmf.h2d.Font = null;

		switch (i.readByte()) {
			case 1:
				font = new font.bmf.h2d.Font(i.readString(i.readUInt16()), i.readInt16());
				path = font.tilePath = i.readString(i.readUInt16());
				// var tile = font.tile = resolveTile(font.tilePath);
				font.lineHeight = i.readInt16();
				font.baseLine = i.readInt16();
				defaultChar = i.readInt32();

			case ver:
				throw "Unknown BFNT version: " + ver;
		}
		return this;
	}

	public function read(atlas:Tile):font.bmf.h2d.Font {
		var id:Int;
		while ((id = i.readInt32()) != 0) {
			var t = atlas.sub(i.readUInt16(), i.readUInt16(), i.readUInt16(), i.readUInt16(), i.readInt16(), i.readInt16());
			var glyph = new font.bmf.h2d.Font.FontChar(t, i.readInt16());
			font.glyphs.set(id, glyph);
			if (id == defaultChar)
				font.defaultChar = glyph;
			var prevChar:Int;
			while ((prevChar = i.readInt32()) != 0) {
				glyph.addKerning(prevChar, i.readInt16());
			}
		}
		return font;
	}

	public static inline function parse(bytes:haxe.io.Bytes):Reader {
		return new Reader(new haxe.io.BytesInput(bytes)).readHeader();
	}
}
