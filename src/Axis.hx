package;
#if !alayout
import haxe.ds.ReadOnlyArray;
@:enum abstract Axis2D(Int) to Int {
    public static var keys = [horizontal, vertical,];
    var horizontal = 0;
    var vertical = 1;
    inline private static var HORIZONTAL_STRING:String = "horizontal";
    inline private static var VERTIVAL_STRING:String = "vertical";

    @:to public function toString():String {
        return if (this == horizontal) HORIZONTAL_STRING else VERTIVAL_STRING;
    }

    @:from static inline function fromString(s:String) {
        return switch s {
            case HORIZONTAL_STRING: horizontal;
            case VERTIVAL_STRING: vertical;
            case s: throw "Cant parse axis ";
        }
    }

    public static inline function fromInt(v:Int) {
        #if debug
		if (v != 0 && v != 1)
			throw 'wrong axis $v';
		#end
        return cast v;
    }

    public inline function toInt():Int
    return this;
}

typedef AxisCollection2D<T> = AxisCollection<T>;

@:forward(keys, copy)
abstract AxisCollection<T>(Map<Axis2D, T>) from Map<Axis2D, T> {
    public inline function new()
    this = new Map();

    @:arrayAccess public inline function get(a:Axis2D):T {
        #if debug
		if (!hasValueFor(a))
			throw "no value for axis " + a;
		#end
        return this[a];
    }

    @:arrayAccess public inline function set(a:Axis2D, val:T):T
    return this[a] = val;

    public inline function hasValueFor(a:Axis2D)
    return this.exists(a);
}

typedef Location2D = {
        pos:ReadOnlyArray<Float>,
        size:ReadOnlyArray<Float>,
        aspects:ReadOnlyArray<Float>,
}
#else
typedef Axis2D = al.al2d.Axis2D;
typedef Transformer = transform.Transformer;
#end

typedef ROAxisCollection2D<T> = ReadOnlyArray<T>;