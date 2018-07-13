/**
Copyright: Copyright (c) 2018, Nils Petersson & Niklas Pettersson. All rights reserved.
License: MPL-2
Author: Nils Petersson (nilpe995@student.liu.se) & Niklas Pettersson (nikpe353@student.liu.se)

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
*/

module dextool.plugin.eqdetect.backend.parser;

import dextool.plugin.eqdetect.backend.type: ErrorResult;

static ErrorResult errorTextParser(string filepath){
    import std.stdio;
    import std.string : split;
    import std.file : FileException;

    ErrorResult errorResult;
    try{
        foreach(s; File(filepath, "r").byLine){
            errorResult.status = s.split(":")[0];
            if(errorResult.status == "Assert" || errorResult.status == "Abort"){
                import std.algorithm.iteration : splitter;
                import std.range : dropOne;
                foreach(data; s.splitter("data: ").dropOne){ //first element does not contain data
                    errorResult.inputdata = errorResult.inputdata ~ data.split(" ")[0];
                }
            }
        }
        return errorResult;
    }
    catch(FileException e){
        import std.experimental.logger;
        warning(e.msg);
        return errorResult;
    }
}