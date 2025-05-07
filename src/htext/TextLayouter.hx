package htext;

import font.GLGlyphData.Glyphs;
import font.GLGlyphData.TileRecord;
import haxe.ds.ReadOnlyArray;
import htext.Align;

interface TextWidthConstraint {
    function setWidthConstraint(val:Float):Void;
}

interface TextLayouter<T:TileRecord> extends TextWidthConstraint {
    function setText(val:String):Void;
    function getTiles():ReadOnlyArray<T>;
    // TODO: there should be an api to set align independently / separately for axis. Two methods or method  (Axis2D, Align)->Void
    function setTextAlign(align:Align, ?valign:Align):Void;
    function calculateVertOffset():Float;
}

interface CharsLayouterFactory {
    function create<T:TileRecord>(fontName:String = "", fac:Void->Glyphs<T> = null):TextLayouter<T>;
}
