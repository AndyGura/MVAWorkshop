package com.andrewgura.controllers {
import com.andrewgura.vo.LangVO;
import com.andrewgura.vo.MVAProjectVO;

import flash.events.Event;

public class MVAController {

    private var project:MVAProjectVO;

    public function MVAController(project:MVAProjectVO) {
        this.project = project;
    }

    public function addLanguage(lang:LangVO):void {
        for each (var language:LangVO in project.langs) {
            if (language.code == lang.code) {
                addLanguage(new LangVO(lang.code + '_', lang.name));
                return;
            }
        }
        project.langs.addItem(lang);
        for each (var item:* in project.entries) {
            item[lang.code] = '';
        }
        project.dispatchEvent(new Event('langsChange'));
        project.dispatchEvent(new Event('dataChange'));
    }

    public function removeLanguage(lang:LangVO):void {
        if (project.langs.getItemIndex(lang) > -1) {
            project.langs.removeItem(lang);
            for each (var item:* in project.entries) {
                delete item[lang.code];
            }
            project.dispatchEvent(new Event('langsChange'));
            project.dispatchEvent(new Event('dataChange'));
        }
    }

    public function changeLanguage(code:String, newData:*):void {
        for each (var lang:LangVO in project.langs) {
            if (lang.code != code) {
                continue;
            }
            var oldCode:String = lang.code;
            lang.code = newData.code;
            lang.name = newData.name;
            if (lang.code != oldCode) {
                for each (var item:* in project.entries) {
                    item[lang.code] = item[oldCode];
                    delete item[oldCode];
                }
            }
            project.dispatchEvent(new Event('langsChange'));
            project.dispatchEvent(new Event('dataChange'));
            return;
        }
    }

    public function checkLastEmptyEntry():void {
        var lastItem:* = MVAProjectVO(project).entries[MVAProjectVO(project).entries.length - 1];
        for (var k:String in lastItem) {
            if (lastItem[k].length > 0) {
                var object:* = {string: ''};
                for each (var lang:LangVO in project.langs) {
                    object[lang.code] = '';
                }
                project.entries.addItem(object);
                return;
            }
        }
    }

}
}
