Definitions.

DIGIT       = [0-9]

SPACE       = [\000-\s]

COMMENT     = #.*
STRING      = ("([^\\"]|\\.)*"|'([^\\']|\\.)*'|/([^\\/]|\\.)*/|@([^\\@]|\\.)*@)

COMMAND     = \\*[a-zA-Z][a-zA-Z0-9_-]*

Rules.

\|              : {token, {'|', TokenLine}}.

\>              : {token, {'>', TokenLine}}.

{COMMAND}       : {token, {command, TokenLine, list_to_binary(TokenChars)}}.

({DIGIT}{DIGIT}*) : {token, {integer, TokenLine, list_to_integer(TokenChars)}}.
({DIGIT}{DIGIT}*\.{DIGIT}{DIGIT}*) : {token, {float, TokenLine, list_to_float(TokenChars)}}.
{STRING}        : {token, {string, TokenLine,
                    unescape_quote(strip(TokenChars, TokenLen))}}.

{COMMENT}       : skip_token.
{SPACE}         : skip_token.

Erlang code.

strip(TokenChars,TokenLen) ->
    lists:sublist(TokenChars, 2, TokenLen - 2).

unescape_quote(String) ->
    re:replace(String, <<"\\", 34>>, <<34>>, [global, {return, list}]).
