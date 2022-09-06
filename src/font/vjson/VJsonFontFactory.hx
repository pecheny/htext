package font.vjson;
class VJsonFontFactory implements FontFactory<IFont> {
    public function new (){}
    public function create(fontPath:String, ?dfSize:Int) {
        var gpuTextFont:FontDescr = haxe.Json.parse(lime.utils.Assets.getText(fontPath));
        var atlasAlias = gpuTextFont.textures[0][0].localPath;
        return new FontInstance<IFont>(new GLFont(gpuTextFont), atlasAlias);
    }
}
