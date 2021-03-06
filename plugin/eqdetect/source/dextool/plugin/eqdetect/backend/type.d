/**
Copyright: Copyright (c) 2018, Nils Petersson & Niklas Pettersson. All rights reserved.
License: MPL-2
Author: Nils Petersson (nilpe995@student.liu.se) & Niklas Pettersson (nikpe353@student.liu.se)

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
*/

module dextool.plugin.eqdetect.backend.type;


struct ErrorResult {
    char[][] inputdata;
    char[] status;
}

import dextool.plugin.mutate.backend.type : Language, Offset;

struct Mutation {
    string path;
    Offset offset;
    int kind;
    Language lang;
    int id;
}

import clang.Cursor;
import clang.Type;

struct EntryFunction{
    string function_name;
    Parameter[] function_params;
    Type returnType;
    string semanticIdentifier;
};

struct Parameter{
    string semanticIdentifier;
    string type;
    string name;
}

const string NAME_PREFIX = "m_";
