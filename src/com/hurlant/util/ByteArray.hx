package com.hurlant.util;

import haxe.io.Bytes;
abstract ByteArray(ByteArrayData) to ByteArrayData from ByteArrayData {
    public var position(get, set):Int;
    public var length(get, set):Int;
    public var bytesAvailable(get, never):Int;
    public var endian(get, set):Endian;

    public function new() { this = new ByteArrayData(); }

    static public function fromBytes(bytes:Bytes):ByteArray {
        var out = new ByteArray();
        for (n in 0 ... bytes.length) out.writeByte(bytes.get(n));
        out.position = 0;
        return out;
    }

    public function getBytes():Bytes { return this.getBytes(); }

    public function readBytes(output:ByteArray, offset:Int, length:Int) { return this.readBytes(output, offset, length); }

    public function readMultiByte(length:Int, encoding:String):String {
        return this.readMultiByte(length, encoding);
    }

    public function writeMultiByte(str:String, encoding:String) {
        return this.writeMultiByte(str, encoding);
    }

    public function readUnsignedInt():UInt {
        return this.readUnsignedInt();
    }

    public function readUnsignedByte():Int {
        return this.readUnsignedByte();
    }

    public function writeUTF(str:String) {
        return this.writeUTF(str);
    }

    public function writeUTFBytes(str:String) {
        return this.writeUTFBytes(str);
    }

    public function writeByte(value:Int) {
        return this.writeByte(value);
    }

    public function writeBytes(input:ByteArray, offset:Int = 0, length:Int = 0) {
        return this.writeBytes(input, offset, length);
    }

    public function readUTFBytes(length:Int):String {
        return this.readUTFBytes(length);
    }

    public function writeUnsignedByte(value:Int) {
        return this.writeUnsignedByte(value);
    }

    public function writeUnsignedInt(value:Int) {
        return this.writeUnsignedInt(value);
    }

    private function get_endian():Endian {
        return this.endian;
    }

    private function get_position():Int {
        return this.position;
    }

    private function get_length():Int {
        return this.length;
    }

    private function get_bytesAvailable():Int {
        return this.bytesAvailable;
    }

    private function set_endian(value:Endian):Endian {
        return this.endian = value;
    }

    private function set_position(value:Int):Int {
        return this.position = value;
    }

    private function set_length(value:Int):Int {
        return this.length = value;
    }

    @:arrayAccess public function get(index:Int):Int { return this.get(index); }
    @:arrayAccess public function set(index:Int, value:Int):Int { return this.set(index, value); }
}

class ByteArrayData implements IDataOutput implements IDataInput {
    public var position(get, set):Int;
    public var length(get, set):Int;
    public var bytesAvailable(get, never):Int;
    public var endian:Endian = Endian.BIG_ENDIAN;
    //public var endian:Endian = Endian.LITTLE_ENDIAN;
    private var _data:Bytes = Bytes.alloc(16);
    private var _length:Int = 0;
    private var _position:Int = 0;

    public function new() {
    }

    private function ensureLength(elength:Int) {
        var oldLength = this._length;
        this._length = Std.int(Math.max(this._length, elength));

        if (_data.length < this._length) {
            var newData = Bytes.alloc(Std.int(Math.max(_data.length * 2, this._length)));
            var oldData = _data;
            newData.blit(0, oldData, 0, oldLength);
            _data = newData;
        }
    }

    public function readBytes(output:ByteArray, offset:Int, length:Int) {
        if (length == 0) length = this.bytesAvailable;
        output.position = offset;
        for (n in 0 ... length) output.writeByte(this.readUnsignedByte());
    }

    public function readUTFBytes(length:Int):String {
        return readMultiByte(length, 'ascii');
    }

    public function readMultiByte(length:Int, encoding:String):String {
        // @TODO: handle encoding
        var str = '';
        for (n in 0 ... length) str += String.fromCharCode(readUnsignedByte());
        return str;
    }

    public function readUnsignedByte():Int {
        ensureWrite(1);
        var result = get(this._position) & 0xFF;
        this._position += 1;
        return result;
    }

    public function readUnsignedInt():UInt {
        ensureWrite(4);
        var result = bswap32Endian(this._data.getInt32(this.position));
        this._position += 4;
        return result;
    }

    public function set(index:Int, value:Int):Int {
        ensureLength(index + 1);
        this._data.set(index, value);
        return value;
    }

    public function get(index:Int):Int {
        ensureLength(index + 1);
        return this._data.get(index) & 0xFF;
    }

    public function writeUTF(str:String) {
        this.writeUnsignedShort(str.length);
        this.writeUTFBytes(str);
    }

    public function writeUTFBytes(str:String) {
        return writeMultiByte(str, 'ascii');
    }

    public function writeMultiByte(str:String, encoding:String) {
        for (n in 0 ... str.length) {
            writeUnsignedByte(str.charCodeAt(n));
        }
    }

    public function writeByte(value:Int) {
        writeUnsignedByte(value);
    }

    public function writeShort(value:Int) {
        writeUnsignedShort(value);
    }

    public function writeBytes(input:ByteArray, offset:Int = 0, length:Int = 0) {
        if (length == 0) length = input.length - offset;
        //throw new Error('Not implemented');
        for (n in 0 ... length) {
            this.writeByte(input[offset + n]);
        }
    }

    public function writeUnsignedByte(value:Int) {
        ensureWrite(1);
        this._data.set(this._position, value);
        this._position += 1;
    }

    public function writeUnsignedShort(value:Int) {
        ensureWrite(2);
        this._data.setUInt16(this._position, bswap16Endian(value));
        this._position += 2;
    }

    public function writeUnsignedInt(value:Int) {
        ensureWrite(4);
        this._data.setInt32(this._position, bswap32Endian(value));
        this._position += 4;
    }

    private function get_position():Int {
        return this._position;
    }

    private function get_length():Int {
        return this._length;
    }

    private function set_position(value:Int):Int {
        return _position = value;
    }

    private function set_length(value:Int):Int {
        ensureLength(value);
        return this._length = value;
    }

    private function get_bytesAvailable():Int {
        return this.length - this.position;
    }

    private function ensureWrite(count:Int) {
        ensureLength(this._position + count);
    }

    private function bswap32Endian(value:Int):Int {
        return (this.endian == Endian.BIG_ENDIAN) ? bswap32(value) : value;
    }

    private function bswap32(a:Int):Int {
        return (a << 24) | ((a & 0x0000ff00) << 8) | ((a & 0x00ff0000) >> 8) | (a >> 24);
    }

    private function bswap16Endian(value:Int):Int {
        return (this.endian == Endian.BIG_ENDIAN) ? bswap16(value) : value;
    }

    private function bswap16(value:Int):Int {
        return ((value & 0xFF) << 8) | ((value >> 8) & 0xFF);
    }

    public function getBytes():Bytes {
        var out = Bytes.alloc(length);
        out.blit(0, this._data, 0, length);
        return out;
    }
}
