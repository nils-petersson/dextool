/**
Copyright: Copyright (c) 2018, Nils Petersson & Niklas Pettersson. All rights reserved.
License: MPL-2
Author: Nils Petersson (nilpe995@student.liu.se) & Niklas Pettersson (nikpe353@student.liu.se)

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

This module contains the functionality for extracting snippets of code from a given cursor
and returns a validated UTF8 string of the extracted code. It also returns the mutated
version of the code extracted.
TODO: rename SnippetFinder*/

module dextool.plugin.eqdetect.backend.codegenerator;

import dextool.plugin.eqdetect.backend.type : Mutation;
import dextool.type : FileName;
import std.typecons : Tuple;

@safe:

class SnippetFinder {
    import clang.Cursor;

    static string generateSource(Cursor cursor, Mutation mutation) {
        import std.stdio : File;
        import std.file : getSize;

        auto file = File(cursor.extent.path, "r");
        auto buffer = file.rawRead(new char[getSize(cursor.extent.path)]);

        import std.utf : validate, toUTF8;

        validate(buffer);

        return toUTF8(buffer);
    }

    static auto generateMut(string content, Mutation mutation) {
        import dextool.plugin.mutate.backend.generate_mutant : makeMutation;
        import dextool.plugin.mutate.backend.type : Offset,
            mutationStruct = Mutation;

        auto mut = makeMutation(cast(mutationStruct.Kind) mutation.kind, mutation.lang);
        auto temp = mut.top() ~ content[0 .. mutation.offset.begin];
        temp = temp ~ mut.mutate(content[mutation.offset.begin .. mutation.offset.end]);
        temp = temp ~ content[mutation.offset.end .. content.length];
        return temp;
    }

    // Generating code that will be used by klee to evaluate the source and mutant code.
    static auto generateKlee(string[] params, FileName source_name,
            FileName mutant_name, string function_name) {
        import std.format : format;
        import dsrcgen.c : CModule;

        auto code = new CModule();

        // add klee imports
        code.include(`<klee/klee.h>`);
        code.include(`<assert.h>`);

        // add import for the files that are being tested
        code.include(format(`%s`, source_name));
        code.include(format(`%s`, mutant_name));

        string func_params;

        // add klee-main
        with (code.func_body(`int`, `main`)) {

            // variable declaration
            for (int i = 0; i < params.length; i++) {
                stmt(format(`%s var%s;`, params[i], i));
                func_params = func_params ~ format(`var%s,`, i);
            }

            // remove last comma that was inserted into the parameters
            if (func_params.length != 0) {
                func_params = func_params[0 .. $ - 1];
            }

            // symbolic variable for each parameter
            for (int i = 0; i < params.length; i++) {
                stmt(format(`klee_make_symbolic(&var%s, sizeof(%s), "var%s")`, i, params[i], i));
            }

            // equivalence detection
            with (if_(format(`%s(%s) == m_%s(%s)`, function_name, func_params,
                    function_name, func_params))) {
                return_(`1`);
            }

            with (else_) {
                stmt(`klee_assert(0)`);
                return_(`0`);
            }

        }
        return code.render;
    }
}
