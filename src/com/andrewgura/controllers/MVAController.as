package com.andrewgura.controllers {
import com.andrewgura.helpers.ClassTemplateHelper;
import com.andrewgura.ui.popup.AppPopups;
import com.andrewgura.ui.popup.PopupFactory;
import com.andrewgura.vo.LangVO;
import com.andrewgura.vo.MVAProjectVO;

import flash.events.Event;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;

import mx.events.CollectionEvent;

public class MVAController {

    private var project:MVAProjectVO;

    public function MVAController(project:MVAProjectVO) {
        this.project = project;
        if (project) {
            this.project.entries.addEventListener(CollectionEvent.COLLECTION_CHANGE, onEntriesChange);
        }
    }

    public function onEntriesChange(event:CollectionEvent):void {
        project.isChangesSaved = false;
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
        project.isChangesSaved = false;
    }

    public function removeLanguage(lang:LangVO):void {
        if (project.langs.getItemIndex(lang) > -1) {
            project.langs.removeItem(lang);
            for each (var item:* in project.entries) {
                delete item[lang.code];
            }
            project.dispatchEvent(new Event('langsChange'));
            project.isChangesSaved = false;
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
            project.isChangesSaved = false;
            return;
        }
    }

    public function getEntryByID(id:String):Object {
        for each (var entry:Object in project.entries) {
            if (entry["string"] == id) {
                return entry;
            }
        }
        return null;
    }

    public function addEntry():void {
        var nameOfEntry:String = getNewNameForDuplicate('NEW_ENTRY');
        var entry:Object = {string: nameOfEntry};
        for each (var lang:LangVO in project.langs) {
            entry[lang.code] = '';
        }
        project.entries.addItem(entry);
    }

    public function getNewNameForDuplicate(id:String, excludeIndex:Number = -1):String {
        var nameOfEntry:String = id;
        var i:Number = 0;
        var foundEntry:* = getEntryByID(nameOfEntry);
        while (foundEntry != null && project.entries.getItemIndex(foundEntry) != excludeIndex) {
            i++;
            nameOfEntry = id + '_' + i;
            foundEntry = getEntryByID(nameOfEntry);
        }
        return nameOfEntry;
    }

    public function removeEntries(entries:Array):void {
        for each (var id:String in entries) {
            if (!getEntryByID(id)) {
                continue;
            }
            project.entries.removeItem(getEntryByID(id));
        }
    }

    public function exportMVA():void {
        var outputDirectory:File;
        var outputPath:String = MVAProjectVO(project).outputProjectPath;
        if (outputPath.substr(0, 1) == "/") {
            //we are using MVAWorkshop on linux under wine;
            outputPath = 'Z:' + outputPath;
        }
        try {
            var windowsPartitionPathIndex:Number = Math.max(outputPath.indexOf(':\\'), outputPath.indexOf(':/'));
            if (windowsPartitionPathIndex == -1) {
                // we are using relative output path;
                var targetFile:File = (new File()).resolvePath(project.fileName);
                outputDirectory = targetFile.parent.resolvePath(outputPath);
            } else {
                outputDirectory = new File(outputPath);
            }
        } catch (e:Error) {
        }
        if (!outputDirectory || !outputDirectory.exists || !outputDirectory.isDirectory) {
            exportError('Wrong output project directory!');
            return;
        }
        var mvaDirectory:File = outputDirectory.resolvePath(project.outputMVAPath);
        if (!mvaDirectory.exists) {
            mvaDirectory.createDirectory();
        }
        var fs:FileStream = new FileStream();
        for each (var lang:LangVO in project.langs) {
            var mvaData:ByteArray = project.getExportedMVA(lang.code);
            fs.open(mvaDirectory.resolvePath(lang.code + '.mva'), FileMode.WRITE);
            fs.writeBytes(mvaData);
            fs.close();
        }
        var packageDirectory:File = outputDirectory.resolvePath(project.outputClassesPackagePath);
        if (!mvaDirectory.exists) {
            mvaDirectory.createDirectory();
        }

        for each (var className:String in ["LocaleConst", "LocaleController", "LocaleModel", "LangVO"]) {
            var templateFile:File = File.applicationDirectory.resolvePath('assets/class_templates/' + className + '.txt');
            fs.open(templateFile, FileMode.READ);
            var classText:String = fs.readMultiByte(templateFile.size, File.systemCharset);
            fs.close();
            fs.open(packageDirectory.resolvePath(className + '.as'), FileMode.WRITE);
            fs.writeUTFBytes(ClassTemplateHelper.processPlaceHolders(classText, project));
            fs.close();
        }

        PopupFactory.instance.showPopup(AppPopups.INFO_POPUP, 'Export success!');
    }

    private function exportError(msg:String):void {
        PopupFactory.instance.showPopup(AppPopups.ERROR_POPUP, msg, true, null, onOkClick);
        function onOkClick(event:Event):void {
            MainController.openProjectSettings();
        }
    }

}
}
