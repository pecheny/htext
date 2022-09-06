package font;
import lime.graphics.Image;
class FontInstance<T> {
    public var font(default, null):T;
    public var texturePath:String;
    public var textureImage(default, null):Image;

    public function new(f, tp) {
        font = f;
        texturePath = tp;
    }

    public function getId() {
        return "font_" + texturePath;
    }
}
