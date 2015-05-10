/// Written in the D programming language.
/// Date: 2015, Joakim Brännström
/// License: GPL
/// Author: Joakim Brännström (joakim.brannstrom@gmx.com)
///
/// This program is free software; you can redistribute it and/or modify
/// it under the terms of the GNU General Public License as published by
/// the Free Software Foundation; either version 2 of the License, or
/// (at your option) any later version.
///
/// This program is distributed in the hope that it will be useful,
/// but WITHOUT ANY WARRANTY; without even the implied warranty of
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
/// GNU General Public License for more details.
///
/// You should have received a copy of the GNU General Public License
/// along with this program; if not, write to the Free Software
/// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
module generator.stub.misc;

private:

import std.algorithm : canFind;
import std.array : join;
import std.conv : to;
import std.string : replace, strip;
import std.typecons : Nullable;

import clang.Cursor;

import translator.Type;

//import generator.analyzer : log_node;
import generator.stub.types;

package:

/** Name mangling that occurs when translating to C++ code.
 */
enum NameMangling {
    Plain, // no mangling
    Callback,
    CallCounter,
    ReturnType
}

auto cppOperatorToName(const ref CppMethodName name) pure nothrow @safe {
    Nullable!CppMethodName r;

    switch (cast(string) name) {
    case "operator=":
        r = CppMethodName("opAssign");
        break;
    default:
        break;
    }

    return r;
}

/// Null if it was unable to convert.
auto mangleToVariable(const CppMethodName method) pure nothrow @safe {
    Nullable!CppVariable rval;

    if (canFind(cast(string) method, "operator")) {
        auto callback_method = cppOperatorToName(method);

        if (!callback_method.isNull)
            rval = cast(CppVariable) callback_method;
    }
    else {
        rval = cast(CppVariable) method;
    }

    return rval;
}

/// Null if it was unable to convert.
auto mangleToCallbackMethod(const CppMethodName method) pure nothrow @safe {
    Nullable!CppMethodName rval;
    // same mangle schema but different return types so resuing but in a safe
    // manner not don't affect the rest of the program.
    auto tmp = mangleToVariable(method);
    if (!tmp.isNull) {
        rval = cast(CppMethodName) tmp.get;
    }

    return rval;
}

auto mangleToCallbackStructVariable(const StubPrefix prefix, const CppClassName name) pure nothrow @safe {
    return CppVariable(cast(string) prefix ~ cast(string) name ~ "_callback");
}

auto mangleToStaticStructVariable(const StubPrefix prefix, const CppClassName name) pure nothrow @safe {
    return CppVariable(cast(string) prefix ~ cast(string) name ~ "_static");
}

auto mangleToCountStructVariable(const StubPrefix prefix, const CppClassName name) pure nothrow @safe {
    return CppVariable(cast(string) prefix ~ cast(string) name ~ "_cnt");
}

/// Null if it was unable to convert.
auto mangleToReturnVariable(const CppMethodName method) pure nothrow @safe {
    Nullable!CppVariable rval;

    if (canFind(cast(string) method, "operator")) {
        auto callback_method = cppOperatorToName(method);

        if (!callback_method.isNull)
            rval = CppVariable(cast(string) callback_method ~ "_return");
    }

    return rval;
}

auto mangleTypeToCallbackStructType(const CppType type) pure @safe {
    string r = (cast(string) type).replace("const", "");
    if (canFind(r, "&")) {
        r = r.replace("&", "") ~ "*";
    }

    return CppType(r.strip);
}

auto mangleToStubClassName(const StubPrefix prefix, const CppClassName name) pure nothrow @safe {
    return CppClassName(prefix ~ name);
}

/** If the variable name is empty return a TypeName with a random name derived
 * from idx.
 */
auto genRandomName(const TypeName tn, ulong idx) {
    if ((cast(string) tn.name).strip.length == 0) {
        return TypeName(tn.type, CppVariable("x" ~ to!string(idx)));
    }

    return tn;
}

/** Travers a node tree and gather all paramdecl to an array.
 * Params:
 * cursor = A node containing ParmDecl nodes as children.
 * Example:
 * -----
 * class Simple{ Simple(char x, char y); }
 * -----
 * The AST for the above is kind of the following:
 * Example:
 * ---
 * Simple [CXCursor_Constructor Type(CXType(CXType_FunctionProto))
 *   x [CXCursor_ParmDecl Type(CXType(CXType_Char_S))
 *   y [CXCursor_ParmDecl Type(CXType(CXType_Char_S))
 * ---
 * It is translated to the array [("char", "x"), ("char", "y")].
 */
TypeName[] parmDeclToTypeName(Cursor cursor) {
    alias toString3 = translator.Type.toString;
    TypeName[] params;

    foreach (param; cursor.func.parameters) {
        auto type = translateType(param.type);
        params ~= TypeName(CppType(toString3(type)), CppVariable(param.spelling));
    }

    logger.trace(params);
    return params;
}

/// Convert a vector of TypeName to string pairs.
auto toStrings(const TypeName[] vars) pure @safe nothrow {
    import std.algorithm : map;
    import std.array : array;

    string[] params = vars.map!(tn => cast(string) tn.type ~ " " ~ cast(string) tn.name).array;

    return params;
}

/// Convert a vector of TypeName to a comma separated string.
auto toString(const TypeName[] vars) pure @safe nothrow {
    auto params = vars.toStrings;
    return join(params, ", ");
}
