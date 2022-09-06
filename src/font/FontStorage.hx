package font;
import haxe.io.Path;
class FontStorage {
    var fac:FontFactory<IFont>;
    var fonts:Map<FontAlias, FontInstance<IFont>> = new Map();

    public function new(factory) {
        this.fac = factory;
    }

    public function initFont(alias:FontAlias, descrPath:String, fac:FontFactory<IFont> = null):FontInstance<IFont> {
        var instance = createInstance(descrPath, fac);
        if (fonts.exists(alias))
            trace('[Warn] font $alias inited already.');
        fonts.set(alias, instance);
        return instance;
    }

    public function getFont(alias:String):FontInstance<IFont> {
        return fonts.get(alias);
    }

    function createInstance(descrPath:String, fac) {
        if (fac== null)
            fac = this.fac;
        var font = fac.create(descrPath) ;
//        var image = lime.utils.Assets.getImage();
//        @:privateAccess font.textureImage = image;
        return font;
    }
}
typedef FontAlias = String;

