use std::io::{self, Write};
use std::fmt;

// Custom error type for calculator operations
#[derive(Debug)]
enum CalculatorError {
    InvalidCharacter(char, usize),
    InvalidNumber(String),
    SyntaxError(String),
    DivisionByZero,
    UnbalancedParentheses,
    EmptyExpression,
    UnexpectedToken(String),

}

impl fmt::Display for CalculatorError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            CalculatorError::InvalidCharacter(c, pos) => write!(f, "Geçersiz karakter '{}' pozisyon {}", c, pos),
            CalculatorError::InvalidNumber(s) => write!(f, "Geçersiz sayı: {}", s),
            CalculatorError::SyntaxError(s) => write!(f, "Sözdizimi hatası: {}", s),
            CalculatorError::DivisionByZero => write!(f, "Sıfıra bölme hatası"),
            CalculatorError::UnbalancedParentheses => write!(f, "Dengesiz parantezler"),
            CalculatorError::EmptyExpression => write!(f, "Boş ifade"),
            CalculatorError::UnexpectedToken(s) => write!(f, "Beklenmeyen token: {}", s),
        }
    }
}

type Result<T> = std::result::Result<T, CalculatorError>;

// Token types for our calculator
#[derive(Debug, Clone, PartialEq)]
enum Token {
    Number(f64),
    Plus,
    Minus,
    Multiply,
    Divide,
    LeftParen,
    RightParen,
    EOF,
}

// Lexer to convert input string into tokens
struct Lexer {
    input: String,
    position: usize,
    current_char: Option<char>,
}

impl Lexer {
    fn new(input: String) -> Self {
        let mut lexer = Lexer {
            input,
            position: 0,
            current_char: None,
        };
        lexer.current_char = lexer.input.chars().next();
        lexer
    }

    fn advance(&mut self) {
        self.position += 1;
        if self.position >= self.input.len() {
            self.current_char = None;
        } else {
            self.current_char = self.input.chars().nth(self.position);
        }
    }

    fn skip_whitespace(&mut self) {
        while let Some(c) = self.current_char {
            if !c.is_whitespace() {
                break;
            }
            self.advance();
        }
    }

    fn number(&mut self) -> Result<Token> {
        let mut num_str = String::new();
        let mut has_decimal = false;
        // Position tracking is kept for potential future enhancements

        while let Some(c) = self.current_char {
            if c.is_digit(10) {
                num_str.push(c);
                self.advance();
            } else if c == '.' && !has_decimal {
                has_decimal = true;
                num_str.push(c);
                self.advance();
            } else {
                break;
            }
        }

        // Check if we have a valid number
        if num_str.is_empty() || num_str == "." {
            return Err(CalculatorError::InvalidNumber(num_str));
        }

        match num_str.parse::<f64>() {
            Ok(num) => Ok(Token::Number(num)),
            Err(_) => Err(CalculatorError::InvalidNumber(num_str)),
        }
    }

    fn get_next_token(&mut self) -> Result<Token> {
        if self.current_char.is_none() {
            return Ok(Token::EOF);
        }

        self.skip_whitespace();

        match self.current_char {
            None => Ok(Token::EOF),
            Some(c) => {
                if c.is_digit(10) || c == '.' {
                    return self.number();
                }

                match c {
                    '+' => {
                        self.advance();
                        Ok(Token::Plus)
                    }
                    '-' => {
                        self.advance();
                        Ok(Token::Minus)
                    }
                    '*' => {
                        self.advance();
                        Ok(Token::Multiply)
                    }
                    '/' => {
                        self.advance();
                        Ok(Token::Divide)
                    }
                    '(' => {
                        self.advance();
                        Ok(Token::LeftParen)
                    }
                    ')' => {
                        self.advance();
                        Ok(Token::RightParen)
                    }
                    _ => Err(CalculatorError::InvalidCharacter(c, self.position)),
                }
            }
        }
    }
}

// Parser to interpret the tokens
struct Parser {
    lexer: Lexer,
    current_token: Token,
    paren_count: i32,
}

impl Parser {
    fn new(lexer: Lexer) -> Result<Self> {
        let mut parser = Parser {
            lexer,
            current_token: Token::EOF,
            paren_count: 0,
        };
        parser.current_token = parser.lexer.get_next_token()?;
        Ok(parser)
    }

    fn eat(&mut self, expected_token: &Token) -> Result<()> {
        if std::mem::discriminant(&self.current_token) == std::mem::discriminant(expected_token) {
            self.current_token = self.lexer.get_next_token()?;
            Ok(())
        } else {
            Err(CalculatorError::SyntaxError(format!(
                "Beklenen: {:?}, Alınan: {:?}",
                expected_token, self.current_token
            )))
        }
    }

    // Grammar rules implementation
    // expr   : term ((PLUS | MINUS) term)*
    // term   : factor ((MUL | DIV) factor)*
    // factor : NUMBER | LPAREN expr RPAREN | MINUS factor

    fn factor(&mut self) -> Result<f64> {
        match self.current_token.clone() {
            Token::Number(val) => {
                let value = val;
                self.eat(&Token::Number(val))?;
                Ok(value)
            }
            Token::LeftParen => {
                self.paren_count += 1;
                self.eat(&Token::LeftParen)?;
                let result = self.expr()?;
                self.eat(&Token::RightParen)?;
                self.paren_count -= 1;
                Ok(result)
            }
            Token::Minus => {
                self.eat(&Token::Minus)?;
                let result = self.factor()?;
                Ok(-result)
            }
            _ => Err(CalculatorError::UnexpectedToken(format!("{:?}", self.current_token))),
        }
    }

    fn term(&mut self) -> Result<f64> {
        let mut result = self.factor()?;

        while matches!(self.current_token, Token::Multiply | Token::Divide) {
            match self.current_token {
                Token::Multiply => {
                    self.eat(&Token::Multiply)?;
                    result *= self.factor()?;
                }
                Token::Divide => {
                    self.eat(&Token::Divide)?;
                    let divisor = self.factor()?;
                    if divisor == 0.0 {
                        return Err(CalculatorError::DivisionByZero);
                    }
                    result /= divisor;
                }
                _ => unreachable!(),
            }
        }

        Ok(result)
    }

    fn expr(&mut self) -> Result<f64> {
        let mut result = self.term()?;

        while matches!(self.current_token, Token::Plus | Token::Minus) {
            match self.current_token {
                Token::Plus => {
                    self.eat(&Token::Plus)?;
                    result += self.term()?;
                }
                Token::Minus => {
                    self.eat(&Token::Minus)?;
                    result -= self.term()?;
                }
                _ => unreachable!(),
            }
        }

        Ok(result)
    }

    fn parse(&mut self) -> Result<f64> {
        let result = self.expr()?;
        
        // Check if we've reached the end of input
        if self.current_token != Token::EOF {
            return Err(CalculatorError::SyntaxError(
                format!("İfade sonunda beklenmeyen token: {:?}", self.current_token)
            ));
        }
        
        // Check for unbalanced parentheses
        if self.paren_count != 0 {
            return Err(CalculatorError::UnbalancedParentheses);
        }
        
        Ok(result)
    }
}

// Interpreter to evaluate expressions
struct Interpreter {
    parser: Parser,
}

impl Interpreter {
    fn new(text: String) -> Result<Self> {
        if text.trim().is_empty() {
            return Err(CalculatorError::EmptyExpression);
        }
        
        let lexer = Lexer::new(text);
        let parser = Parser::new(lexer)?;
        Ok(Interpreter { parser })
    }

    fn interpret(&mut self) -> Result<f64> {
        self.parser.parse()
    }
}

fn main() {
    println!("Basit Hesap Makinesi Interpreter");
    println!("Çıkmak için \"exit\" yazın");
    println!("Desteklenen işlemler: +, -, *, /, (, )");
    
    loop {
        print!(">> ");
        io::stdout().flush().unwrap();
        
        let mut input = String::new();
        match io::stdin().read_line(&mut input) {
            Ok(_) => {},
            Err(e) => {
                println!("Girdi okuma hatası: {}", e);
                continue;
            }
        }
        
        let input = input.trim();
        if input.to_lowercase() == "exit" {
            break;
        }
        
        if input.is_empty() {
            continue;
        }
        
        match calculate(input) {
            Ok(result) => println!("Sonuç: {}", result),
            Err(e) => println!("Hata: {}", e),
        }
    }
}

fn calculate(input: &str) -> std::result::Result<f64, String> {
    match Interpreter::new(input.to_string()) {
        Ok(mut interpreter) => {
            match interpreter.interpret() {
                Ok(result) => Ok(result),
                Err(e) => Err(e.to_string()),
            }
        },
        Err(e) => Err(e.to_string()),
    }
}
