/* Basit Hesap Makinesi Interpreter - Prolog Implementasyonu */

/* Token tipleri iu00e7in sabitler */
token_type(number, 0).
token_type(plus, 1).
token_type(minus, 2).
token_type(multiply, 3).
token_type(divide, 4).
token_type(lparen, 5).
token_type(rparen, 6).
token_type(eof, 7).

/* Hata mesajlaru0131 */
error_message(invalid_char, 'Geu00e7ersiz karakter').
error_message(invalid_number, 'Geu00e7ersiz sayu0131').
error_message(syntax_error, 'Su00f6zdizimi hatasu0131').
error_message(div_by_zero, 'Su0131fu0131ra bu00f6lme hatasu0131').
error_message(unbalanced_parens, 'Dengesiz parantezler').
error_message(empty_expr, 'Bou015f ifade').
error_message(unexpected_token, 'Beklenmeyen token').

/* Lexer - Tokenize */

% Karakter listesini tokenlara dönüştür
tokenize(Input, Tokens) :-
    string_chars(Input, Chars),
    tokenize_chars(Chars, Tokens).

tokenize_chars(Chars, Tokens) :-
    phrase(tokens(Tokens), Chars).

% DCG kuralları ile tokenize işlemi
tokens([]) --> [].
tokens([Token|Tokens]) --> space, token(Token), tokens(Tokens).
tokens([Token|Tokens]) --> token(Token), tokens(Tokens).

% Boşluk karakterleri
space --> [C], { char_type(C, space) }, space.
space --> [C], { char_type(C, space) }.

% Token tanımları
token(token(number, N)) --> number(N).
token(token(plus, '+')) --> ['+'].
token(token(minus, '-')) --> ['-'].
token(token(multiply, '*')) --> ['*'].
token(token(divide, '/')) --> ['/'].
token(token(lparen, '(')) --> ['('].
token(token(rparen, ')')) --> [')'].

% Sayı okuma
number(N) --> digits(D), ['.'], digits(F), { append(D, ['.'], T), append(T, F, L), number_chars(N, L) }.
number(N) --> digits(D), { number_chars(N, D) }.

% Rakamları oku
digits([D|Ds]) --> digit(D), digits(Ds).
digits([D]) --> digit(D).

digit(D) --> [D], { char_type(D, digit) }.

/* Parser */

% Ana ayrıştırma fonksiyonu
parse(Tokens, Result) :-
    expr(Tokens, Result, []).

% İfade ayrıştırma (toplama, çıkarma)
expr(Tokens, Result, Rest) :-
    term(Tokens, TermResult, TermRest),
    expr_rest(TermRest, TermResult, Result, Rest).

% İfade devamı (toplama, çıkarma)
expr_rest([token(plus, _)|Tokens], Left, Result, Rest) :-
    term(Tokens, TermResult, TermRest),
    Value is Left + TermResult,
    expr_rest(TermRest, Value, Result, Rest).
expr_rest([token(minus, _)|Tokens], Left, Result, Rest) :-
    term(Tokens, TermResult, TermRest),
    Value is Left - TermResult,
    expr_rest(TermRest, Value, Result, Rest).
expr_rest(Tokens, Result, Result, Tokens).

% Terim ayrıştırma (çarpma, bölme)
term(Tokens, Result, Rest) :-
    factor(Tokens, FactorResult, FactorRest),
    term_rest(FactorRest, FactorResult, Result, Rest).

% Terim devamı
term_rest([token(multiply, _)|Tokens], Left, Result, Rest) :-
    factor(Tokens, FactorResult, FactorRest),
    Value is Left * FactorResult,
    term_rest(FactorRest, Value, Result, Rest).
term_rest([token(divide, _)|Tokens], Left, Result, Rest) :-
    factor(Tokens, FactorResult, FactorRest),
    (FactorResult =:= 0 ->
        error_message(div_by_zero, Msg),
        throw(Msg)
    ;
        Value is Left / FactorResult,
        term_rest(FactorRest, Value, Result, Rest)
    ).
term_rest(Tokens, Result, Result, Tokens).

% Faktör ayrıştırma (sayılar, parantezli ifadeler)
factor([token(number, Value)|Rest], Value, Rest).
factor([token(lparen, _)|Tokens], Result, [token(rparen, _)|Rest]) :-
    expr(Tokens, Result, [token(rparen, _)|Rest]).
factor([token(minus, _)|Tokens], Result, Rest) :-
    factor(Tokens, FactorResult, Rest),
    Result is -FactorResult.
factor([Token|_], _, _) :-
    Token = token(Type, _),
    error_message(unexpected_token, Msg),
    format(atom(Error), '~w: ~w', [Msg, Type]),
    throw(Error).
factor([], _, _) :-
    error_message(unexpected_token, Msg),
    format(atom(Error), '~w: Beklenmeyen ifade sonu', [Msg]),
    throw(Error).

/* Interpreter */

% Ana yorumlama fonksiyonu
interpret(ExprString, Result) :-
    % Boş ifade kontrolü
    (string_chars(ExprString, []), !, error_message(empty_expr, Msg), throw(Msg));
    (
        tokenize(ExprString, Tokens),
        parse(Tokens, Result)
    ).

/* Ana program */
main :-
    write('Basit Hesap Makinesi Interpreter'), nl,
    write('Çıkmak için "exit" yazın'), nl,
    write('Desteklenen işlemler: +, -, *, /, (, )'), nl,
    repl.

% REPL (Read-Eval-Print Loop)
repl :-
    write('>> '),
    flush_output,
    read_line_to_string(user_input, Input),
    (Input = "exit" ->
        true
    ;
        (Input = "" ->
            repl
        ;
            catch(
                (interpret(Input, Result),
                 format('Sonuç: ~g~n', [Result])),
                Error,
                format('Hata: ~w~n', [Error])
            ),
            repl
        )
    ).

:- initialization(main).
