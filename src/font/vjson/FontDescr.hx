package font.vjson;
import haxe.DynamicAccess;
@:enum abstract TextureAtlasFormat(String) {
    var TextureAtlasFontJson = "TextureAtlasFontJson";
}
@:enum abstract Technique(String) {
    var msdf = "msdf";
}
typedef TexRec = {
    localPath:String
}

typedef Rect = {
    x:Int,
    y:Int,
    w:Int,
    h:Int,
}

typedef CharDescr = {
    advance:Float,
    glyph:{
        atlasScale:Float,
        atlasRect:Rect,
        offset:{
            x:Float,
            y:Float
        }
    }
}

typedef FontDescr = {
    format:TextureAtlasFormat,
    technique:Technique,
    characters:DynamicAccess< CharDescr>,
    kerning:DynamicAccess< Float>,
    textures:Array<Array<TexRec>>,
    textureSize:{
        w:Int,
        h:Int
    },
    ascender:Float,
    descender:Float,
    typoAscender:Float,
    typoDescender:Float,
    lowercaseHeight:Float,
    metadata:Dynamic,
    glyphBounds:DynamicAccess<Bounds>,
    fieldRange_px:Int
}

typedef FontData = {
    glyphAtlasTexture:String,

}

typedef Bounds = {
    l:Float,
    r:Float,
    t:Float,
    b:Float,
}
