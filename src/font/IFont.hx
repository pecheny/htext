package font;
import font.GLGlyphData;
interface IFont {
    function getChar(key:String):GLGlyphData;
    function getLineHeight():Float;
    function getBaseline():Float;
    function getKerningOffset(ch1:String, ch2:String):Float;
    function getDFSize():Int;
}
