{-
 ----------------------------------------------------------------------------------
 -  Copyright (C) 2010  Massachusetts Institute of Technology
 -  Copyright (C) 2010  Yuan Tang <yuantang@csail.mit.edu>
 - 		                Charles E. Leiserson <cel@mit.edu>
 - 	 
 -   This program is free software: you can redistribute it and/or modify
 -   it under the terms of the GNU General Public License as published by
 -   the Free Software Foundation, either version 3 of the License, or
 -   (at your option) any later version.
 -
 -   This program is distributed in the hope that it will be useful,
 -   but WITHOUT ANY WARRANTY; without even the implied warranty of
 -   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 -   GNU General Public License for more details.
 -
 -   You should have received a copy of the GNU General Public License
 -   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 -
 -   Suggestsions:                  yuantang@csail.mit.edu
 -   Bugs:                          yuantang@csail.mit.edu
 -
 --------------------------------------------------------------------------------
 -}

module PBasicParser_3dfd where

import Text.ParserCombinators.Parsec
import qualified Text.ParserCombinators.Parsec.Token as Token
import Text.ParserCombinators.Parsec.Expr
import Text.ParserCombinators.Parsec.Language
import Text.Read (read)

import Data.Char
import Data.List
import qualified Data.Map as Map

-- import PShow
-- import PUtils
import PData_3dfd

{- all the token parsers -}
lexer :: Token.TokenParser st 
lexer = Token.makeTokenParser (javaStyle
             { commentStart = "/*",
               commentEnd = "*/",
               commentLine = "//",
               identStart = letter <|> oneOf "_'",
               identLetter = alphaNum <|> oneOf "_'", 
               nestedComments = True,
               reservedOpNames = ["*", "/", "+", "-", "!", "&&", "||", "=", ">", ">=", 
                                  "<", "<=", "==", "!=", "+=", "-=", "*=", "&=", "|=", 
                                  "<<=", ">>=", "^=", "++", "--", "?", ":", "&", "|", "~",
                                  ">>", "<<", "%", "^"],
               reservedNames = ["Pochoir_Array", "Pochoir", "Pochoir_Domain", 
                                "Pochoir", "Pochoir_pRange", 
                                "Pochoir_kernel_1D", "Pochoir_kernel_2D", 
                                "Pochoir_kernel_3D", "Pochoir_kernel_end",
                                "auto", "};", "const", "volatile", "register", 
                                "Pochoir_Boundary_1D", "Pochoir_Boundary_2D",
                                "Pochoir_Boundary_3D", "Pochoir_Boundary_end",
                                "time", "ms", "int", "float", "double", "bool", "true", "false",
                                "if", "else", "switch", "case", "break", "default",
                                "while", "do", "for"],
               caseSensitive = True})

{- definition of all token parser -}
whiteSpace = Token.whiteSpace lexer
lexeme = Token.lexeme lexer
symbol = Token.symbol lexer
natural = Token.natural lexer
number = Token.naturalOrFloat lexer
integer = Token.integer lexer
float = Token.float lexer
brackets = Token.brackets lexer
braces = Token.braces lexer
parens = Token.parens lexer
angles = Token.angles lexer
semi = Token.semi lexer
colon = Token.colon lexer
dot = Token.dot lexer
identifier = Token.identifier lexer
reserved = Token.reserved lexer
reservedOp = Token.reservedOp lexer
comma = Token.comma lexer
semiSep = Token.semiSep lexer
semiSep1 = Token.semiSep1 lexer
commaSep = Token.commaSep lexer
commaSep1 = Token.commaSep1 lexer
charLiteral = Token.charLiteral lexer
stringLiteral = Token.stringLiteral lexer

-- pIdentifier doesn't strip whites, compared with 'identifier', 
-- so we can preserve the relative order of original source input

pDelim :: GenParser Char ParserState String
pDelim = do try comma
            return ", "
     <|> do try semi
            return ";\n"
     <|> do try $ symbol ")"
            return ") "


