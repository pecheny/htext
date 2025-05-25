package htext;

import font.GLGlyphData.Glyphs;
import font.GLGlyphData.TileRecord;
import haxe.ds.ReadOnlyArray;
import htext.Align;

interface TextWidthConstraint {
    function setWidthConstraint(val:Float):Void;
}

interface TextLayouter extends TextWidthConstraint {
    function setText(val:String):Void;
    function getTiles():ReadOnlyArray<TileRecord>;
    // TODO: there should be an api to set align independently / separately for axis. Two methods or method  (Axis2D, Align)->Void
    function setTextAlign(align:Align, ?valign:Align):Void;
    /** 
     * Returns vertical offset of the label pivot (y coord of first's line baseline) according to vertical align and number of lines.
    **/
    function calculateVertOffset():Float;
    /**
     * Adds a fuction to preprocess the text before laying out.
    **/
    function setProcessor(pr:TextProcessor):Void;
}

interface CharsLayouterFactory {
    function create<T:TileRecord>(fontName:String = "", glyphs:Glyphs<T> = null):TextLayouter;
}

abstract TextProcessor(String->String) from String->String {
    // public inline function add(pr) {
    //     if (this == null)
    //         this = [];
    //     this.push(pr);
    // }

    public inline function process(text) {
        return if (this == null) text else this(text);
        // Lambda.fold(this, (p, s) -> p(s), text);
    }
}

