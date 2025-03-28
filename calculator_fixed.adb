with Ada.Text_IO;          use Ada.Text_IO;
with Ada.Float_Text_IO;     use Ada.Float_Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Exceptions;        use Ada.Exceptions;

procedure Calculator_Fixed is
   -- Define custom exceptions for error handling
   Invalid_Character     : exception;
   Invalid_Number        : exception;
   Syntax_Error          : exception;
   Division_By_Zero      : exception;
   Unbalanced_Parentheses : exception;
   Empty_Expression      : exception;
   Unexpected_Token      : exception;
   
   -- Token types for our calculator
   type Token_Type is (
      Number,
      Plus,
      Minus,
      Multiply,
      Divide,
      Left_Paren,
      Right_Paren,
      EOF
   );
   
   -- Token record to store token information
   type Token is record
      Kind  : Token_Type;
      Value : Float := 0.0;
   end record;
   
   -- Lexer to convert input string into tokens
   type Lexer is record
      Input     : Unbounded_String;
      Position  : Natural := 1;
      Char      : Character := ' ';
   end record;
   
   -- Parser to interpret the tokens
   type Parser is record
      Current_Token : Token;
      Paren_Count   : Integer := 0;
      Lex           : Lexer;
   end record;
   
   -- Function prototypes
   procedure Advance (Lex : in out Lexer);
   procedure Skip_Whitespace (Lex : in out Lexer);
   function Get_Next_Token (Lex : in out Lexer) return Token;
   function Parse_Number (Lex : in out Lexer) return Token;
   
   function Expr (P : in out Parser) return Float;
   function Term (P : in out Parser) return Float;
   function Factor (P : in out Parser) return Float;
   procedure Eat (P : in out Parser; Expected_Type : Token_Type);
   
   -- Lexer implementation
   procedure Advance (Lex : in out Lexer) is
   begin
      Lex.Position := Lex.Position + 1;
      
      if Lex.Position > Length (Lex.Input) then
         Lex.Char := ASCII.NUL;
      else
         Lex.Char := Element (Lex.Input, Lex.Position);
      end if;
   end Advance;
   
   procedure Skip_Whitespace (Lex : in out Lexer) is
   begin
      while Lex.Char /= ASCII.NUL and then Lex.Char = ' ' loop
         Advance (Lex);
      end loop;
   end Skip_Whitespace;
   
   function Parse_Number (Lex : in out Lexer) return Token is
      Num_Str : Unbounded_String := To_Unbounded_String ("");
      Has_Decimal : Boolean := False;
      Result : Token;
   begin
      while Lex.Char /= ASCII.NUL and then 
            (Lex.Char in '0' .. '9' or 
             (Lex.Char = '.' and not Has_Decimal)) loop
         
         if Lex.Char = '.' then
            Has_Decimal := True;
         end if;
         
         Append (Num_Str, Lex.Char);
         Advance (Lex);
      end loop;
      
      -- Check if we have a valid number
      if Length (Num_Str) = 0 or else To_String (Num_Str) = "." then
         raise Invalid_Number with "Gecersiz sayi: " & To_String (Num_Str);
      end if;
      
      -- Convert string to float
      begin
         Result.Kind := Number;
         Result.Value := Float'Value (To_String (Num_Str));
         return Result;
      exception
         when others =>
            raise Invalid_Number with "Gecersiz sayi: " & To_String (Num_Str);
      end;
   end Parse_Number;
   
   function Get_Next_Token (Lex : in out Lexer) return Token is
      Result : Token;
   begin
      if Lex.Char = ASCII.NUL then
         Result.Kind := EOF;
         return Result;
      end if;
      
      Skip_Whitespace (Lex);
      
      if Lex.Char = ASCII.NUL then
         Result.Kind := EOF;
         return Result;
      end if;
      
      if Lex.Char in '0' .. '9' or Lex.Char = '.' then
         return Parse_Number (Lex);
      end if;
      
      case Lex.Char is
         when '+' =>
            Result.Kind := Plus;
            Advance (Lex);
         when '-' =>
            Result.Kind := Minus;
            Advance (Lex);
         when '*' =>
            Result.Kind := Multiply;
            Advance (Lex);
         when '/' =>
            Result.Kind := Divide;
            Advance (Lex);
         when '(' =>
            Result.Kind := Left_Paren;
            Advance (Lex);
         when ')' =>
            Result.Kind := Right_Paren;
            Advance (Lex);
         when others =>
            raise Invalid_Character with "Gecersiz karakter: '" & Lex.Char & "' pozisyon " & 
                                         Integer'Image (Lex.Position);
      end case;
      
      return Result;
   end Get_Next_Token;
   
   -- Parser implementation
   procedure Eat (P : in out Parser; Expected_Type : Token_Type) is
   begin
      if P.Current_Token.Kind = Expected_Type then
         P.Current_Token := Get_Next_Token (P.Lex);
      else
         raise Syntax_Error with "Beklenen: " & Token_Type'Image (Expected_Type) & 
                               ", Alinan: " & Token_Type'Image (P.Current_Token.Kind);
      end if;
   end Eat;
   
   function Factor (P : in out Parser) return Float is
      Result : Float;
   begin
      case P.Current_Token.Kind is
         when Number =>
            Result := P.Current_Token.Value;
            Eat (P, Number);
            return Result;
            
         when Left_Paren =>
            P.Paren_Count := P.Paren_Count + 1;
            Eat (P, Left_Paren);
            Result := Expr (P);
            Eat (P, Right_Paren);
            P.Paren_Count := P.Paren_Count - 1;
            return Result;
            
         when Minus =>
            Eat (P, Minus);
            return -Factor (P);
            
         when others =>
            raise Unexpected_Token with "Beklenmeyen token: " & 
                                      Token_Type'Image (P.Current_Token.Kind);
      end case;
   end Factor;
   
   function Term (P : in out Parser) return Float is
      Result : Float;
      Right  : Float;
   begin
      Result := Factor (P);
      
      while P.Current_Token.Kind in Multiply | Divide loop
         if P.Current_Token.Kind = Multiply then
            Eat (P, Multiply);
            Result := Result * Factor (P);
         elsif P.Current_Token.Kind = Divide then
            Eat (P, Divide);
            Right := Factor (P);
            
            if Right = 0.0 then
               raise Division_By_Zero with "Sifira bolme hatasi";
            end if;
            
            Result := Result / Right;
         end if;
      end loop;
      
      return Result;
   end Term;
   
   function Expr (P : in out Parser) return Float is
      Result : Float;
   begin
      Result := Term (P);
      
      while P.Current_Token.Kind in Plus | Minus loop
         if P.Current_Token.Kind = Plus then
            Eat (P, Plus);
            Result := Result + Term (P);
         elsif P.Current_Token.Kind = Minus then
            Eat (P, Minus);
            Result := Result - Term (P);
         end if;
      end loop;
      
      return Result;
   end Expr;
   
   -- Interpreter function to evaluate expressions
   function Interpret (Input : String) return Float is
      L : Lexer;
      P : Parser;
      Result : Float;
   begin
      if Input'Length = 0 then
         raise Empty_Expression with "Bos ifade";
      end if;
      
      -- Initialize lexer
      L.Input := To_Unbounded_String (Input);
      L.Position := 0;
      Advance (L);
      
      -- Initialize parser
      P.Lex := L;
      P.Current_Token := Get_Next_Token (P.Lex);
      
      -- Parse and interpret
      Result := Expr (P);
      
      -- Check if we've reached the end of input
      if P.Current_Token.Kind /= EOF then
         raise Syntax_Error with "Ifade sonunda beklenmeyen token: " & 
                               Token_Type'Image (P.Current_Token.Kind);
      end if;
      
      -- Check for unbalanced parentheses
      if P.Paren_Count /= 0 then
         raise Unbalanced_Parentheses with "Dengesiz parantezler";
      end if;
      
      return Result;
   end Interpret;
   
   -- Test expressions
   procedure Test_Expression (Expression : String) is
      Error_Message : Unbounded_String;
   begin
      Put ("Ifade: " & Expression & " => ");
      begin
         Put (Interpret (Expression), Fore => 0, Aft => 6, Exp => 0);
         New_Line;
      exception
         when E : others =>
            -- Use Exception_Identity to check exception type
            declare
               Msg : constant String := Exception_Message(E);
            begin
               if Exception_Identity(E) = Invalid_Character'Identity then
                  Error_Message := To_Unbounded_String ("Gecersiz karakter hatasi");
               elsif Exception_Identity(E) = Invalid_Number'Identity then
                  Error_Message := To_Unbounded_String ("Gecersiz sayi hatasi");
               elsif Exception_Identity(E) = Syntax_Error'Identity then
                  Error_Message := To_Unbounded_String ("Sozdizimi hatasi");
               elsif Exception_Identity(E) = Division_By_Zero'Identity then
                  Error_Message := To_Unbounded_String ("Sifira bolme hatasi");
               elsif Exception_Identity(E) = Unbalanced_Parentheses'Identity then
                  Error_Message := To_Unbounded_String ("Dengesiz parantezler");
               elsif Exception_Identity(E) = Empty_Expression'Identity then
                  Error_Message := To_Unbounded_String ("Bos ifade");
               elsif Exception_Identity(E) = Unexpected_Token'Identity then
                  Error_Message := To_Unbounded_String ("Beklenmeyen token");
               else
                  Error_Message := To_Unbounded_String ("Bilinmeyen hata: " & Msg);
               end if;
            end;
            Put_Line ("Hata: " & To_String(Error_Message));
      end;
   end Test_Expression;
   
   -- Interactive REPL (Read-Eval-Print Loop)
   procedure Run_REPL is
      Input : String (1 .. 100);
      Last  : Natural;
   begin
      loop
         Put (">> ");
         Get_Line (Input, Last);
         
         declare
            Expression : constant String := Input (1 .. Last);
         begin
            exit when Expression = "exit" or Expression = "quit";
            
            if Expression'Length > 0 then
               begin
                  Put ("Sonuc: ");
                  Put (Interpret (Expression), Fore => 0, Aft => 6, Exp => 0);
                  New_Line;
               exception
                  when E : others =>
                     declare
                        Msg : constant String := Exception_Message(E);
                     begin
                        if Exception_Identity(E) = Invalid_Character'Identity then
                           Put_Line ("Hata: Gecersiz karakter hatasi");
                        elsif Exception_Identity(E) = Invalid_Number'Identity then
                           Put_Line ("Hata: Gecersiz sayi hatasi");
                        elsif Exception_Identity(E) = Syntax_Error'Identity then
                           Put_Line ("Hata: Sozdizimi hatasi");
                        elsif Exception_Identity(E) = Division_By_Zero'Identity then
                           Put_Line ("Hata: Sifira bolme hatasi");
                        elsif Exception_Identity(E) = Unbalanced_Parentheses'Identity then
                           Put_Line ("Hata: Dengesiz parantezler");
                        elsif Exception_Identity(E) = Empty_Expression'Identity then
                           Put_Line ("Hata: Bos ifade");
                        elsif Exception_Identity(E) = Unexpected_Token'Identity then
                           Put_Line ("Hata: Beklenmeyen token");
                        else
                           Put_Line ("Hata: " & Msg);
                        end if;
                     end;
               end;
            end if;
         end;
      end loop;
      
      Put_Line ("Hesap makinesi kapatiliyor...");
   end Run_REPL;

begin
   Put_Line ("Basit Hesap Makinesi Interpreter");
   Put_Line ("Cikmak icin 'exit' veya 'quit' yazin");
   Put_Line ("Desteklenen islemler: +, -, *, /, (, )");
   New_Line;
   
   -- Run the interactive REPL
   Run_REPL;
end Calculator_Fixed;
