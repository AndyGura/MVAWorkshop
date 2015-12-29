package com.andrewgura.vo {

import flash.events.Event;
import flash.utils.ByteArray;

import mx.collections.ArrayCollection;

import spark.components.gridClasses.GridColumn;

[Bindable]
public class MVAProjectVO extends ProjectVO {

    public var langs:ArrayCollection = new ArrayCollection();
    public var entries:ArrayCollection = new ArrayCollection();

    public var outputProjectPath:String = '';


    [Bindable(event="langsChange")]
    public function get dataGridColumnsProvider():ArrayCollection {
        var output:Array = [];
        var gridColumn:GridColumn = new GridColumn();
        gridColumn.dataField = 'string';
        gridColumn.headerText = 'String ID';
        gridColumn.editable = false;
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
        var langs:ArrayCollection = new ArrayCollection(simpleData.langs);
        this.langs = new ArrayCollection();
        for each (var l:* in langs) {
            this.langs.addItem(new LangVO(l.code, l.name));
        }
        this.entries = new ArrayCollection(simpleData.entries);
        dispatchEvent(new Event("langsChange"));
    }
}

}
