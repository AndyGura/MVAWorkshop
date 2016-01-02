package com.andrewgura.helpers {
import com.andrewgura.vo.LangVO;
import com.andrewgura.vo.MVAProjectVO;
import com.andrewgura.vo.ProjectVO;

import flash.utils.Dictionary;

public class ClassTemplateHelper {

    private static var instance:ClassTemplateHelper = new ClassTemplateHelper();

    public static var PLACEHOLDER_METHOD_MAP:Dictionary = preparePlaceholdersDictionary();
    private static function preparePlaceholdersDictionary():Dictionary {
        var output:Dictionary = new Dictionary();
        output['$$package$$'] = instance.getPackageName;
        output['$$langVO_constants$$'] = instance.getLangVOConsts;
        output['$$locale_keys_constants$$'] = instance.getLocaleKeys;
        output['$$mva_embed_constants$$'] = instance.getMvaEmbeds;
        output['$$lang_dictionary_initializing$$'] = instance.getLangDict;
        return output;
    }

    public static function processPlaceHolders(input:String, project:ProjectVO):String {
        for (var k:String in PLACEHOLDER_METHOD_MAP) {
            if (input.indexOf(k) >= 0) {
                input = input.replace(k,PLACEHOLDER_METHOD_MAP[k](project));
            }
        }
        return input;
    }

    private function getPackageName(project:MVAProjectVO):String {
        return project.outputClassesPackagePath.replace(/\//gi, '.');
    }

    private function getLangVOConsts(project:MVAProjectVO):String {
        var langVoConsts:String = '';
        for each (var lang:LangVO in project.langs) {
            langVoConsts += '    public static var ' + lang.code + '_LANG:LangVO = new LangVO("' + lang.code + '", "' + lang.name + '");\n';
        }
        return langVoConsts;
    }

    private function getLocaleKeys(project:MVAProjectVO):String {
        var localeKeysConsts:String = '';
        for each (var entry:* in project.entries) {
            localeKeysConsts += '	public static const ' + entry.string + ':String = "' + entry.string + '";\n';
        }
        return localeKeysConsts;
    }

    private function getMvaEmbeds(project:MVAProjectVO):String {
        var mvaEmbeds:String = '';
        for each (var lang:LangVO in project.langs) {
            mvaEmbeds += '    [Embed(source="/' + project.outputMVAPath + '/' + lang.code + '.mva", mimeType="application/octet-stream")]\n';
            mvaEmbeds += '    private static const ' + lang.code + '_MVA:Class;\n';
        }
        return mvaEmbeds;
    }

    private function getLangDict(project:MVAProjectVO):String {
        var langsDict:String = '';
        for each (var lang:LangVO in project.langs) {
            langsDict += '        output[LocaleConst.' + lang.code + '_LANG] = ' + lang.code + '_MVA;\n';
        }
        return langsDict;
    }


}
}
