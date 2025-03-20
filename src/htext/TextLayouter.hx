package htext;
import font.GLGlyphData.TileRecord;
import haxe.ds.ReadOnlyArray;
import htext.Align;

interface TextLayouter {
    function setText(val:String):Void;
    function getTiles():ReadOnlyArray<TileRecord>;
    function setWidthConstraint(val:Float):Void;
    //TODO: there should be an api to set align independently / separately for axis. Two methods or method  (Axis2D, Align)->Void
    function setTextAlign(align:Align, ?valign:Align):Void;
    function calculateVertOffset():Float ;
}

interface CharsLayouterFactory {
    function create(fontName:String = ""):TextLayouter;
}

