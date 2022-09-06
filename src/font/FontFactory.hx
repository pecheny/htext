package font;
interface FontFactory<T> {
    function create(path:String):FontInstance<T>;
}
