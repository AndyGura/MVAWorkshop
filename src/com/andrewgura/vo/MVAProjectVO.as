package com.andrewgura.vo {

import flash.utils.ByteArray;
import flash.utils.ByteArray;

import mx.collections.ArrayCollection;

import spark.components.gridClasses.GridColumn;

[Bindable]
public class MVAProjectVO extends ProjectVO {

    public var langs:ArrayCollection = new ArrayCollection();
    public var entries:ArrayCollection = new ArrayCollection([{string: ''}]);

    [Bindable(event="langsChange")]
    public function get dataGridColumnsProvider():ArrayCollection {
        var output:Array = [];
        var gridColumn:GridColumn = new GridColumn();
        gridColumn.dataField = 'string';
        gridColumn.headerText = 'String ID';
        output.push(gridColumn);
        for each (var lang:LangVO in langs) {
            gridColumn = new GridColumn();
            gridColumn.dataField = lang.code;
            gridColumn.headerText = lang.name;
            output.push(gridColumn);
        }
        return new ArrayCollection(output);
    }

    override public function serialize():ByteArray {
        var output:ByteArray = super.serialize();
        output.writeObject({langs: this.langs.source, entries: this.entries.source});
        return output;
    }

    override public function deserialize(name:String, fileName:String, data:ByteArray):void {
        super.deserialize(name, fileName, data);
        var simpleData:* = data.readObject();
        this.langs = new ArrayCollection(simpleData.langs);
        this.entries = new ArrayCollection(simpleData.entries);
    }
}

}
