#lang racket

;;; Basit Hesap Makinesi Interpreter - Scheme Implementasyonu

;; Hata mesajları
(define ERROR-INVALID-CHAR "Geçersiz karakter")
(define ERROR-INVALID-NUMBER "Geçersiz sayı")
(define ERROR-SYNTAX "Sözdizimi hatası")
(define ERROR-DIV-BY-ZERO "Sıfıra bölme hatası")
(define ERROR-UNBALANCED-PARENS "Dengesiz parantezler")
(define ERROR-EMPTY-EXPR "Boş ifade")

;; Lexer - Tokenize
(define (tokenize str)
  (define (tokenize-helper s tokens)
    (cond
      [(string=? s "") (reverse tokens)]
      [(char-whitespace? (string-ref s 0))
       (tokenize-helper (substring s 1) tokens)]
      [(char-numeric? (string-ref s 0))
       (let-values ([(num rest) (read-number s)])
         (tokenize-helper rest (cons (cons 'number num) tokens)))]
      [(char=? (string-ref s 0) #\+)
       (tokenize-helper (substring s 1) (cons (cons 'plus '+) tokens))]
      [(char=? (string-ref s 0) #\-)
       (tokenize-helper (substring s 1) (cons (cons 'minus '-) tokens))]
      [(char=? (string-ref s 0) #\*)
       (tokenize-helper (substring s 1) (cons (cons 'multiply '*) tokens))]
      [(char=? (string-ref s 0) #\/)
       (tokenize-helper (substring s 1) (cons (cons 'divide '/) tokens))]
      [(char=? (string-ref s 0) #\()
       (tokenize-helper (substring s 1) (cons (cons 'lparen '()) tokens))]
      [(char=? (string-ref s 0) #\))
       (tokenize-helper (substring s 1) (cons (cons 'rparen '()) tokens))]
      [else (error ERROR-INVALID-CHAR (string (string-ref s 0)))]))
  
  ;; Sayı okuma
  (define (read-number s)
    (define (collect i has-dot acc)
      (if (>= i (string-length s))
          (values (string->number acc) "")
          (let ([c (string-ref s i)])
            (cond
              [(char-numeric? c)
               (collect (+ i 1) has-dot (string-append acc (string c)))]
              [(and (char=? c #\.) (not has-dot))
               (collect (+ i 1) #t (string-append acc "."))]
              [else
               (values (string->number acc) (substring s i))]))))
    (collect 0 #f ""))
  
  (tokenize-helper str '()))

;; Parser
(define (parse tokens)
  (define (parse-expr tokens)
    (let-values ([(term rest) (parse-term tokens)])
      (parse-expr-tail term rest)))
  
  (define (parse-expr-tail left tokens)
    (cond
      [(null? tokens) (values left '())]
      [(eq? (caar tokens) 'plus)
       (let-values ([(term rest) (parse-term (cdr tokens))])
         (parse-expr-tail (+ left term) rest))]
      [(eq? (caar tokens) 'minus)
       (let-values ([(term rest) (parse-term (cdr tokens))])
         (parse-expr-tail (- left term) rest))]
      [else (values left tokens)]))
  
  (define (parse-term tokens)
    (let-values ([(factor rest) (parse-factor tokens)])
      (parse-term-tail factor rest)))
  
  (define (parse-term-tail left tokens)
    (cond
      [(null? tokens) (values left '())]
      [(eq? (caar tokens) 'multiply)
       (let-values ([(factor rest) (parse-factor (cdr tokens))])
         (parse-term-tail (* left factor) rest))]
      [(eq? (caar tokens) 'divide)
       (let-values ([(factor rest) (parse-factor (cdr tokens))])
         (when (= factor 0)
           (error ERROR-DIV-BY-ZERO))
         (parse-term-tail (/ left factor) rest))]
      [else (values left tokens)]))
  
  (define (parse-factor tokens)
    (cond
      [(null? tokens) (error ERROR-SYNTAX "Beklenmeyen ifade sonu")]
      [(eq? (caar tokens) 'number)
       (values (cdar tokens) (cdr tokens))]
      [(eq? (caar tokens) 'lparen)
       (let-values ([(expr rest) (parse-expr (cdr tokens))])
         (if (or (null? rest) (not (eq? (caar rest) 'rparen)))
             (error ERROR-UNBALANCED-PARENS)
             (values expr (cdr rest))))]
      [(eq? (caar tokens) 'minus)
       (let-values ([(factor rest) (parse-factor (cdr tokens))])
         (values (- factor) rest))]
      [else (error ERROR-SYNTAX "Beklenmeyen token")]))
  
  (let-values ([(result rest) (parse-expr tokens)])
    (if (null? rest)
        result
        (error ERROR-SYNTAX "İfade sonunda beklenmeyen token"))))

;; Interpreter
(define (interpret expr)
  (if (regexp-match? #rx"^\\s*$" expr)
      (error ERROR-EMPTY-EXPR)
      (parse (tokenize expr))))

;; Ana program
(define (main)
  (display "Basit Hesap Makinesi Interpreter\n")
  (display "Çıkmak için \"exit\" yazın\n")
  (display "Desteklenen işlemler: +, -, *, /, (, )\n")
  
  (let loop ()
    (display ">> ")
    (flush-output)
    (let ([input (read-line)])
      (cond
        [(eof-object? input) (void)]
        [(string-ci=? input "exit") (void)]
        [(regexp-match? #rx"^\\s*$" input) (loop)]
        [else
         (with-handlers
           ([(lambda (exn) #t)
             (lambda (exn)
               (display "Hata: ")
               (display (exn-message exn))
               (newline))])
           (let ([result (interpret input)])
             (printf "Sonuç: ~a\n" result)))
         (loop)]))))

;; Programı çalıştır
(main)
