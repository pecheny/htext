package htext;
import font.GLGlyphData.TileRecord;
import haxe.ds.ReadOnlyArray;
import htext.Align;

interface TextLayouter {
    function setText(val:String):Void;
    function getTiles():ReadOnlyArray<TileRecord>;
    function setWidthConstraint(val:Float):Void;
    function setTextAlign(align:Align, valign:Align = Center):Void;
    function calculateVertOffset():Float ;
}

interface CharsLayouterFactory {
    function create(fontName:String = ""):TextLayouter;
}

