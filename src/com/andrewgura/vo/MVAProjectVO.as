package com.andrewgura.vo {

import flash.events.Event;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;

import spark.components.gridClasses.GridColumn;

[Bindable]
public class MVAProjectVO extends ProjectVO {

    public var langs:ArrayCollection = new ArrayCollection();
    public var entries:ArrayCollection = new ArrayCollection();

    public var outputProjectPath:String = '';
    public var outputMVAPath:String = 'assets/langs';
    public var outputClassesPackagePath:String = 'com/andrewgura/locales';

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
        output.writeObject({
            outputProjectPath: outputProjectPath,
            outputMVAPath: outputMVAPath,
            outputClassesPackagePath: outputClassesPackagePath
        });
        output.writeObject({langs: this.langs.source, entries: this.entries.source});
        return output;
    }

    override public function deserialize(name:String, fileName:String, data:ByteArray):void {
        super.deserialize(name, fileName, data);

        var settings:* = data.readObject();
        this.outputProjectPath = settings.outputProjectPath;
        this.outputMVAPath = settings.outputMVAPath;
        this.outputClassesPackagePath = settings.outputClassesPackagePath;

        var simpleData:* = data.readObject();
        var langs:ArrayCollection = new ArrayCollection(simpleData.langs);
        this.langs = new ArrayCollection();
        for each (var l:* in langs) {
            this.langs.addItem(new LangVO(l.code, l.name));
        }
        this.entries = new ArrayCollection(simpleData.entries);
        dispatchEvent(new Event("langsChange"));
    }

    public function getExportedMVA(langCode:String):ByteArray {
        var output:ByteArray = new ByteArray();
        var dict:Dictionary = new Dictionary();
        for each (var entry:* in entries) {
            dict[entry["string"]] = entry[langCode];
        }
        output.writeObject(dict);
        output.compress();
        return output;
    }

    public function getOutputLocaleConstClassText(pAckage:String):String {
        var output:String = 'package ' + pAckage + ' {\n';
        output += 'public class LocaleConst {\n\n';
        for each (var lang:LangVO in langs) {
            output += '    public static var ' + lang.code + '_LANG:LangVO = new LangVO("' + lang.code + '", "' + lang.name + '");\n';
        }
        output += '\n';
        for each (var entry:* in entries) {
            output += '	public static const ' + entry.string + ':String = "' + entry.string + '";\n';
        }
        output += '\n}\n}';
        return output;
    }

    public function getOutputLocaleControllerClassText(pAckage:String):String {
        var output:String = 'package ' + pAckage + ' {\n\n';
        output += 'import flash.utils.Dictionary;\n\n';
        output += 'import flash.utils.ByteArray;\n\n';
        output += 'public class LocaleController {\n\n';
        for each (var lang:LangVO in langs) {
            output += '    [Embed(source="/' + outputMVAPath + '/' + lang.code + '.mva", mimeType="application/octet-stream")]\n';
            output += '    private static const ' + lang.code + '_MVA:Class;\n';
        }
        output += '\n';
        output += '    private static var LANG_MVAS:Dictionary = prepareMVASDictionary();\n';
        output += '    private static function prepareMVASDictionary():Dictionary {\n';
        output += '        var output:Dictionary = new Dictionary();\n';
        for each (lang in langs) {
            output += '        output[LocaleConst.' + lang.code + '_LANG] = ' + lang.code + '_MVA;\n';
        }
        output += '        return output;\n';
        output += '    }\n\n';
        output += '    public static function loadLanguage(language:LangVO):void {\n';
        output += '        var mva:ByteArray = ByteArray(new LANG_MVAS[language]());\n';
        output += '        mva.uncompress();\n';
        output += '        var o:* = mva.readObject();\n';
        output += '        LocaleModel.instance.loadedLanguage = language;\n';
        output += '        LocaleModel.instance.stringResources = o as Dictionary;\n';
        output += '    }\n\n';
        output += '}\n}';
        return output;
    }

    public function getOutputLocaleModelClassText(pAckage:String):String {
        var output:String = 'package ' + pAckage + ' {\n\n';
        output += 'import flash.events.Event;\n';
        output += 'import flash.events.EventDispatcher;\n';
        output += 'import flash.utils.Dictionary;\n\n';
        output += 'public class LocaleModel extends EventDispatcher {\n\n';
        output += '    public var loadedLanguage:LangVO;\n\n';
        output += '    private var isLoaded:Boolean = false;\n\n';
        output += '    private var _stringResources:Dictionary;\n';
        output += '    public function set stringResources(value:Dictionary):void {\n';
        output += '        if (_stringResources !== value && value) {\n';
        output += '            isLoaded = true;\n';
        output += '            _stringResources = value;\n';
        output += '            dispatchEvent(new Event("stringResourcesChange"));\n';
        output += '        }\n';
        output += '    }\n\n';
        output += '    [Bindable(event="stringResourcesChange")]\n';
        output += '    public function getStr(stringID:String):String {\n';
        output += '        if (!isLoaded) {\n';
        output += '            return "";\n';
        output += '        }\n';
        output += '        return _stringResources[stringID];\n';
        output += '    }\n\n';
        output += '    //=====================================================SINGLETON====================================================\n\n';
        output += '    private static var _instance:LocaleModel;\n';
        output += '    public static function get instance():LocaleModel {\n';
        output += '        if (!_instance) {\n';
        output += '            _instance = new LocaleModel(new SingletonEnforcer());\n';
        output += '        }\n';
        output += '        return _instance;\n';
        output += '    }\n';
        output += '    public function LocaleModel(arg:SingletonEnforcer) {\n';
        output += '        if (!arg) {throw new Error();}\n';
        output += '    }\n';
        output += '}\n}\n';
        output += 'class SingletonEnforcer {}';
        return output;
    }

    public function getOutputLangVOClassText(pAckage:String):String {
        var output:String = 'package ' + pAckage + ' {\n';
        output += '[Bindable]\n';
        output += 'public class LangVO {\n\n';
        output += ' public var code:String;\n';
        output += ' public var name:String;\n\n';
        output += ' public function LangVO(code:String, name:String) {\n';
        output += '     this.code = code;\n';
        output += '     this.name = name;\n';
        output += ' }\n\n}\n}';
        return output;
    }

}

}
