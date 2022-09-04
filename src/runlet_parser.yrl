Nonterminals

filter
pipeline.

Terminals

'|'
'>'
command
integer float string.

Rootsymbol pipeline.

pipeline    -> filter '|' pipeline : ['$1'] ++ '$3'.
pipeline    -> filter '>' integer : ['$1'] ++ [{<<">">>, [unwrap('$3')]}].
pipeline    -> filter '>' string : ['$1'] ++ [{<<">">>, [unwrap('$3')]}].
pipeline    -> filter '>' command : ['$1'] ++ [{<<">">>, [unwrap('$3')]}].
pipeline    -> filter : ['$1'].

filter      -> command integer integer integer : {unwrap('$1'), [unwrap('$2'), unwrap('$3'), unwrap('$4')]}.
filter      -> command float integer integer : {unwrap('$1'), [unwrap('$2'), unwrap('$3'), unwrap('$4')]}.
filter      -> command string integer integer : {unwrap('$1'), [unwrap('$2'), unwrap('$3'), unwrap('$4')]}.

filter      -> command integer integer : {unwrap('$1'), [unwrap('$2'), unwrap('$3')]}.
filter      -> command integer : {unwrap('$1'), [unwrap('$2')]}.
filter      -> command float : {unwrap('$1'), [unwrap('$2')]}.

filter      -> command integer string : {unwrap('$1'), [unwrap('$2'), unwrap('$3')]}.
filter      -> command float string : {unwrap('$1'), [unwrap('$2'), unwrap('$3')]}.

filter      -> command string integer : {unwrap('$1'), [unwrap('$2'), unwrap('$3')]}.
filter      -> command string float : {unwrap('$1'), [unwrap('$2'), unwrap('$3')]}.
filter      -> command string string : {unwrap('$1'), [unwrap('$2'), unwrap('$3')]}.
filter      -> command string : {unwrap('$1'), [unwrap('$2')]}.
filter      -> command command : {unwrap('$1'), [unwrap('$2')]}.
filter      -> command command integer : {unwrap('$1'), [unwrap('$2'), unwrap('$3')]}.
filter      -> command : {unwrap('$1'), []}.

Erlang code.

unwrap({string,_,V}) -> list_to_binary(V);
unwrap({_,_,V}) -> V.
