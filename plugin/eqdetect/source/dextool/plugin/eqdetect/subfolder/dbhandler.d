/**
Copyright: Copyright (c) 2018, Nils Petersson & Niklas Pettersson. All rights reserved.
License: MPL-2
Author: Nils Petersson (nilpe995@student.liu.se) & Niklas Pettersson (nikpe353@student.liu.se)

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

TODO:Description of file
*/
module dextool.plugin.eqdetect.subfolder.dbhandler;

import d2sqlite3 : sqlDatabase = Database;
import std.format : format;
import std.typecons : Nullable, NullableRef, nullableRef;
import dextool.plugin.mutate.backend.type;


struct Mutation{
    string path;
    int offset_begin;
    int offset_end;
    int kind;
    Language lang;
}

class DbHandler{
    string path;
    sqlDatabase db;

    this(string filepath){
        import std.stdio;
        this.path = filepath;
        db = sqlDatabase(path);
    }

    Mutation[] getMutations(){
        import std.conv : to;
        import std.stdio;
        import std.path;
        auto stmt = db.prepare(format("SELECT mp_id, kind FROM mutation WHERE status='3';"));
        auto mutations = stmt.execute;
        Mutation[] mutation_list;
        foreach(m; mutations){
            Mutation mutation;
            mutation.kind = m.peek!int(1);
            mutation = getMutationPoint(mutation, m.peek!string(0));
            if(extension(mutation.path) != ".h"){
                mutation_list = mutation_list ~ mutation;
            }
        }

        return mutation_list;
    }

    Mutation getMutationPoint(Mutation mutation, string mp_id){
        import std.stdio;
        import std.conv : to;
        auto stmt = db.prepare(format("SELECT file_id, offset_begin, offset_end FROM mutation_point WHERE id='%s';", mp_id));
        auto res = stmt.execute;
        mutation = getFilePath(mutation, res.front.peek!string(0));
        mutation.offset_begin = res.front.peek!int(1);
        mutation.offset_end = res.front.peek!int(2);

        return mutation;
    }

    Mutation getFilePath(Mutation mutation, string file_id){
        auto stmt = db.prepare(format("SELECT path, lang FROM files WHERE id='%s';", file_id));
        auto res = stmt.execute;

        auto path = res.front.peek!string(0);
        path = "../" ~ path; //Ugly solution for now

        mutation.path = path;
        mutation.lang = res.front.peek!Language(1);
        return mutation;
    }

}
