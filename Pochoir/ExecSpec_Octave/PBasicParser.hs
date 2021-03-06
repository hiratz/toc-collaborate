{-
 ----------------------------------------------------------------------------------
 -  Copyright (C) 2010-2011  Massachusetts Institute of Technology
 -  Copyright (C) 2010-2011  Yuan Tang <yuantang@csail.mit.edu>
 - 		                     Charles E. Leiserson <cel@mit.edu>
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
 -   Suggestions:                   yuantang@csail.mit.edu
 -   Bugs:                          yuantang@csail.mit.edu
 -
 --------------------------------------------------------------------------------
 -}

module PBasicParser where

import Text.ParserCombinators.Parsec
import qualified Text.ParserCombinators.Parsec.Token as Token
import Text.ParserCombinators.Parsec.Expr
import Text.ParserCombinators.Parsec.Language
import Text.Read (read)

import Data.Char
import Data.List
import qualified Data.Map as Map

import PShow
import PUtils
import PData

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
                                  ">>", "<<", "%", "^", "->"],
               reservedNames = ["Pochoir_Array", "Pochoir", "Pochoir_Domain", 
                                "Pochoir", "Pochoir_Kernel", "Pochoir_Guard", 
                                "auto", "{", "};", "const", "volatile", "register", 
                                "#define", "#include", "int", "float", "double", 
                                "bool", "true", "false",
                                "if", "else", "switch", "case", "break", "default",
                                "while", "do", "for", "return", "continue"],
               caseSensitive = True})

{- definition of all token parser -}
whiteSpace = Token.whiteSpace lexer
lexeme = Token.lexeme lexer
symbol = Token.symbol lexer
natural = Token.natural lexer
number = Token.naturalOrFloat lexer
integer = Token.integer lexer
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
pIdentifier :: GenParser Char ParserState String
pIdentifier = do l_start <- letter <|> char '_'
                 l_body <- many (alphaNum <|> char '_' <?> "Wrong Identifier")
                 return (l_start : l_body)

pFileName :: GenParser Char ParserState String
pFileName = pIdentifier 
        <|> do char '\"' 
               l_strs <- sepBy stringLiteral (char '.')
               char '\"'
               return (mkQuote $ concat l_strs)

pDelim :: GenParser Char ParserState String
pDelim = do try comma
            return ", "
     <|> do try semi
            return ";\n"
     <|> do try $ symbol ")"
            return ") "

pMember :: String -> GenParser Char ParserState String
pMember l_memFunc = 
    do l_start <- char '.'
       l_body <- string l_memFunc
       return (l_memFunc)

pPochoirKernelParams :: GenParser Char ParserState (PName, PName)
pPochoirKernelParams = 
    do l_shape <- identifier
       comma
       l_kernelFunc <- identifier
       return (l_shape, l_kernelFunc)

pParseTileKernel :: GenParser Char ParserState PTileKernel
pParseTileKernel =
     do try $ symbol "{"
        l_tiles <- commaSep pParseTileKernel
        symbol "}"
        return $ LK l_tiles
 <|> do l_kernelName <- try $ identifier
        l_state <- getState
        case Map.lookup l_kernelName $ pKernel l_state of
             -- Nothing -> return emptyTileKernel
             Nothing -> return $ SK emptyKernel { kName = l_kernelName }
             Just l_kernel -> return $ SK l_kernel 

ppArray :: String -> ParserState -> GenParser Char ParserState (String, String)
ppArray l_id l_state =
        do try $ pMember "Register_Boundary"
           l_boundaryFn <- parens pIdentifier
           semi
           case Map.lookup l_id $ pArray l_state of
               Nothing -> 
                    do let l_ret = l_id ++ ".Register_Boundary(" ++ l_boundaryFn ++ "); /* UNKNOWN Register_Boundary with " ++ l_id ++ "*/" ++ breakline
                       return (l_ret, "")
               Just l_array -> 
                    do updateState $ updateArrayBoundary l_id True 
                       let l_ret = l_id ++ ".Register_Boundary(" ++ l_boundaryFn ++ "); /* Register_Boundary */" ++ breakline
                       return (l_ret, l_ret)
    <|> do try $ pMember "Register_Shape"
           l_shape <- parens identifier
           semi
           case Map.lookup l_id $ pArray l_state of
               Nothing -> 
                    do let l_ret = l_id ++ ".Register_Shape(" ++ l_shape ++ "); /* UNKNOWN Register_Shape with " ++ l_id ++ "*/" ++ breakline
                       return (l_ret, "")
               Just l_pArray ->
                   case Map.lookup l_shape $ pShape l_state of
                       Nothing -> 
                            do let l_ret = l_id ++ ".Register_Shape(" ++ l_shape ++ "); /* UNKNOWN Register_Shape with " ++ l_shape ++ "*/" ++ breakline
                               return (l_ret, "")
                       Just l_pShape -> 
                            do let l_ret = "/* Known */" ++ breakline ++ l_id ++ ".Register_Shape(" ++ l_shape ++ ");" ++ breakline
                               return (l_ret, l_ret)

ppStencil :: String -> ParserState -> GenParser Char ParserState (String, String)
ppStencil l_id l_state = 
        do try $ pMember "Register_Array"
           l_arrays <- parens $ commaSep1 identifier
           semi
           case Map.lookup l_id $ pStencil l_state of 
               Nothing -> let l_ret = l_id ++ ".Register_Array(" ++ 
                                      intercalate ", " l_arrays ++ 
                                      "); /* UNKNOWN Register_Array with" ++ 
                                      l_id ++ "*/" ++ breakline
                          in  return (l_ret, "")
               Just l_stencil -> 
                    do let l_pArrayStatus = map (flip checkValidPArray l_state) l_arrays
                       let l_validPArray = foldr (&&) True $ map fst l_pArrayStatus
                       if (l_validPArray == True) 
                          then do let l_pArrays = map snd l_pArrayStatus 
                                  let l_revPArrays = map (flip fillToggleInPArray (sToggle l_stencil)) l_pArrays
                                  updateStencilArray l_id l_revPArrays
                                  let l_ret = l_id ++ ".Register_Array(" ++ 
                                              intercalate ", " l_arrays ++ 
                                              "); /* Known Register Array */" ++ breakline
                                  return (l_ret, l_ret)
                          else let l_ret = l_id ++ ".Register_Array(" ++ 
                                           intercalate ", " l_arrays ++ 
                                           "); /* UNKNOWN Pochoir Array */" ++ 
                                           breakline
                               in  return (l_ret, "")
    <|> do try $ pMember "Gen_Plan"
           l_tstep <- parens exprStmtDim
           semi
           let l_ret = l_id ++ ".Gen_Plan(" ++ show l_tstep ++ "); /* known */" ++ breakline
           return (l_ret, l_ret)
    <|> do try $ pMember "Run"
           l_tstep <- parens exprStmtDim
           semi
           case Map.lookup l_id $ pStencil l_state of
               Nothing -> let l_ret = breakline ++ l_id ++ ".Run(" ++ show l_tstep ++ 
                                      "); /* Run with UNKNOWN Stencil " ++ l_id ++ 
                                      " */" ++ breakline
                          in  return (l_ret, "")
               Just l_stencil -> 
                          do let l_arrayInUse = sArrayInUse l_stencil
                             let l_regBound = foldr (||) False $ map (getArrayRegBound l_state) l_arrayInUse 
                             updateState $ updateStencilBoundary l_id l_regBound 
                             let l_ret = breakline ++ l_id ++ ".Run(" ++ show l_tstep ++ ");" ++ breakline
                             return (l_ret, l_ret)
    <|> do try $ pMember "Register_Tile_Kernels"
           -- the returned l_guard and l_tile are of type PGuard, PTile, respectively
           (l_guard, l_tile) <- parens pStencilRegisterTileKernelParams
           semi
           case Map.lookup l_id $ pStencil l_state of
               Nothing -> let l_ret = l_id ++ ".Register_Tile_Kernels(" ++ 
                                      (gName l_guard) ++ (concat $ gComment l_guard) ++ 
                                      ", " ++ 
                                      (tName l_tile) ++ (tComment l_tile) ++ 
                                      "); /* UNKNOWN Stencil " ++ 
                                      l_id ++ "*/" ++ breakline
                          in  return (l_ret, "")
               Just l_stencil ->
                   do let l_sRegTileKernel = sRegTileKernel l_stencil
                      let l_tile_order = pTileOrder l_state
                      let l_tile' = l_tile { tOrigGuard = l_guard { gTileOrder = l_tile_order }, tOrder = l_tile_order }
                      let l_rev_sRegTileKernel = l_sRegTileKernel ++ 
                                                 [(l_guard, l_tile')]
                      updateState $ updatePTileOrder $ l_tile_order + 1
                      updateState $ updateTileOrigGuard (tName l_tile) l_guard
                      updateState $ updateStencilRegTileKernel l_id l_rev_sRegTileKernel
                      let l_pShapes = map kShape $ getTileKernels l_tile'
                      let l_merged_pShape = foldr mergePShapes (sShape l_stencil) l_pShapes
                      updateState $ updateStencilToggle l_id (shapeToggle l_merged_pShape)
                      updateState $ updateStencilTimeShift l_id (shapeTimeShift l_merged_pShape)
                      updateState $ updateStencilShape l_id l_merged_pShape
                      -- We don't return anything in Register_Kernel 
                      -- until 'Run', because we know the Register_Array
                      -- only after Register_Kernel
                      let l_ret = l_id ++ ".Register_Tile_Kernels(" ++
                                  (gName l_guard) ++ (concat $ gComment l_guard) ++ 
                                  ", " ++ (tName l_tile') ++ (tComment l_tile')  ++ 
                                  ");" ++ breakline
                      return (l_ret, l_ret)
    <|> do return (l_id, "")

-- get all iterators from Kernel
getIterFromKernel :: PMode -> PStencil -> [PName] -> [Stmt] -> [Iter]
getIterFromKernel l_mode l_stencil l_params l_stmts =
       let l_iters =
                   case l_mode of 
                       -- -all-cond-tile modes
                       -- all-cond-tile-overlap modes
                       PAllCondTileMacroOverlap -> 
                                getFromStmts getIter PRead 
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts
                       PAllCondTileCPointerOverlap -> 
                                getFromStmts getIter PRead
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts
                       PAllCondTilePointerOverlap -> 
                                getFromStmts (getPointer l_params) PRead 
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts
                       PAllCondTileOptPointerOverlap -> 
                                getFromStmts getIter PRead
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts 
                       -- unroll-t-tile-overlap modes
                       PUnrollTimeTileMacroOverlap -> 
                                getFromStmts getIter PRead 
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts
                       PUnrollTimeTileCPointerOverlap -> 
                                getFromStmts getIter PRead
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts
                       PUnrollTimeTilePointerOverlap -> 
                                getFromStmts (getPointer l_params) PRead 
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts
                       PUnrollTimeTileOptPointerOverlap -> 
                                getFromStmts getIter PRead
                                    (transArrayMap $ sArrayInUse l_stencil) 
                                    l_stmts 
           l_revIters = transIterN 0 l_iters
       in  l_revIters

{------------------------------------------------------------------------------------- 
 - Beginning functions for overlapped modes
 -------------------------------------------------------------------------------------
 -}
pShowAutoTileString :: PMode -> PStencil -> (PGuard, [PTile]) -> String
pShowAutoTileString l_mode l_stencil (l_guard, []) = pShowDefaultTileString l_mode l_stencil l_guard
pShowAutoTileString l_mode l_stencil (l_guard, l_tiles@(t:ts)) =
    let l_guardName = pGetOverlapGuardName l_guard
        l_order = gOrder l_guard
        l_comments = pShowAutoTileComments l_tiles
        -- getTileKernels also fills the guardFunc/tile_op/tile_order into PKernelFuncs
        l_kernels = concatMap getTileKernels l_tiles
        l_unroll = foldr max 0 $ map pTileLength l_tiles
        -- group kernels by the tile index (tIndex)
        -- l_kernels_by_tIndex = groupBy eqIndexPKernel l_kernels
        -- l_kernels_by_tIndex = pGroupBy eqIndexPKernel l_kernels
        -- l_kernels_by_tIndex = pGroupPKernelBy eqIndexPKernelTOrder l_kernels
        l_kernels_by_tIndex = pGroupPKernelByMerge eqVarLenIndexPKernelTOrder l_kernels
        l_kernels_by_tIndex_by_t = pGroupBy eqTGroupPKernel l_kernels_by_tIndex
        -- for each l_tile_index, there could be a list of kernel functions
        l_tile_indices = map (kIndex . pHead) l_kernels_by_tIndex
        l_tile_indices_by_t = map (map (kIndex . pHead)) l_kernels_by_tIndex_by_t
        -- l_kernel_funcs : [[PKernelFunc]]
        l_kernel_funcs = map (map kFunc) l_kernels_by_tIndex
        l_kernel_funcs_by_t = map (map (map kFunc)) l_kernels_by_tIndex_by_t
        l_stmts = concatMap kfStmt $ concat l_kernel_funcs
        l_params = kfParams $ pHead $ pHead l_kernel_funcs
        l_iters = getIterFromKernel l_mode l_stencil l_params l_stmts
        l_rev_kernel_funcs = map (map (pFillIters l_iters)) l_kernel_funcs
        l_rev_kernel_funcs_by_t = map (map (map (pFillIters l_iters))) l_kernel_funcs_by_t
        l_id = sName l_stencil
    in  case l_mode of
            PAllCondTileMacroOverlap ->
                pSplitAllCondTileOverlapScope
                  ("Macro", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_stencil, l_comments)
                  (pShowMacroStmt False)
            PAllCondTileCPointerOverlap ->
                pSplitAllCondTileOverlapScope
                  ("CPointer", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_stencil, l_comments)
                  pShowCPointerStmt
            PAllCondTilePointerOverlap ->
                pSplitAllCondTileOverlapScope
                  ("Pointer", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_stencil, l_comments)
                  (pShowPointerStmt True)
            PAllCondTileOptPointerOverlap ->
                pSplitAllCondTileOverlapScope
                  ("Opt_Pointer", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_stencil, l_comments)
                  pShowOptPointerStmt
            PUnrollTimeTileMacroOverlap ->
                pSplitUnrollTimeTileOverlapScope 
                  ("Macro", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_tile_indices_by_t, l_rev_kernel_funcs_by_t, l_stencil, l_comments)
                  (pShowMacroStmt False)
            PUnrollTimeTileCPointerOverlap ->
                pSplitUnrollTimeTileOverlapScope
                  ("CPointer", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_tile_indices_by_t, l_rev_kernel_funcs_by_t, l_stencil, l_comments)
                  pShowCPointerStmt
            PUnrollTimeTilePointerOverlap ->
                pSplitUnrollTimeTileOverlapScope
                  ("Pointer", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_tile_indices_by_t, l_rev_kernel_funcs_by_t, l_stencil, l_comments)
                  (pShowPointerStmt True)
            PUnrollTimeTileOptPointerOverlap ->
                pSplitUnrollTimeTileOverlapScope
                  ("Opt_Pointer", l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_rev_kernel_funcs, l_tile_indices_by_t, l_rev_kernel_funcs_by_t, l_stencil, l_comments)
                  pShowOptPointerStmt

pSplitAllCondTileOverlapScope :: (String, PMode, PName, PName, Int, Int, [[Int]], [[PKernelFunc]], PStencil, String) -> (PKernelFunc -> String) -> String
pSplitAllCondTileOverlapScope (l_tag, l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_kfss, l_stencil, l_comments) l_showSingleKernel =
    let oldKernelName = intercalate "_" $ map kfName $ concat l_kfss
        -- bdryKernelName = l_tag ++ "_boundary_" ++ oldKernelName
        -- obaseKernelName = l_tag ++ "_interior_" ++ oldKernelName
        bdryKernelName = l_tag ++ "_boundary_kernel_" ++ show l_order
        obaseKernelName = l_tag ++ "_interior_kernel_" ++ show l_order
        regBound = sRegBound l_stencil
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape $ concat l_kfss)
        l_pShape' = pFillPShapeName "" l_order l_pShape
        bdryKernel = if regBound
                        then pShowAllCondTileOverlapKernels (pShowMacroStmt True) 
                                regBound PAllCondTileMacroOverlap 
                                bdryKernelName l_stencil l_pShape'
                                l_tile_indices l_kfss
                        else ""
        obaseKernel = pShowAllCondTileOverlapKernels 
                        l_showSingleKernel 
                        False l_mode obaseKernelName l_stencil l_pShape'
                        l_tile_indices l_kfss
        runKernel = if regBound
                       then obaseKernelName ++ ", " ++ bdryKernelName
                       else obaseKernelName
    in  (breakline ++ l_comments ++
         breakline ++ show l_pShape' ++ bdryKernel ++ breakline ++ obaseKernel ++
         breakline ++ l_id ++ ".Register_Tile_Obase_Kernels(" ++ l_guardName ++
         ", " ++ show l_unroll ++ ", " ++ runKernel ++ ");" ++ breakline)

pSplitUnrollTimeTileOverlapScope :: (String, PMode, PName, PName, Int, Int, [[Int]], [[PKernelFunc]], [[[Int]]], [[[PKernelFunc]]], PStencil, String) -> (PKernelFunc -> String) -> String
pSplitUnrollTimeTileOverlapScope (l_tag, l_mode, l_id, l_guardName, l_order, l_unroll, l_tile_indices, l_kfss, l_tile_indices_by_t, l_kfss_by_t, l_stencil, l_comments) l_showSingleKernel =
    let oldKernelName = intercalate "_" $ map kfName $ concat l_kfss
        -- bdryKernelName = l_tag ++ "_boundary_" ++ oldKernelName
        -- cond_bdryKernelName = l_tag ++ "_cond_boundary_" ++ oldKernelName
        -- obaseKernelName = l_tag ++ "_interior_" ++ oldKernelName
        -- cond_obaseKernelName = l_tag ++ "_cond_interior_" ++ oldKernelName
        bdryKernelName = l_tag ++ "_boundary_kernel_" ++ show l_order
        cond_bdryKernelName = l_tag ++ "_cond_boundary_kernel_" ++ show l_order
        obaseKernelName = l_tag ++ "_interior_kernel_" ++ show l_order
        cond_obaseKernelName = l_tag ++ "_cond_interior_kernel_" ++ show l_order
        regBound = sRegBound l_stencil
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape $ concat l_kfss)
        l_pShape' = pFillPShapeName "" l_order l_pShape
        cond_bdryKernel = if regBound
                             then pShowAllCondTileOverlapKernels 
                                     (pShowMacroStmt True) 
                                     regBound PAllCondTileMacroOverlap 
                                     cond_bdryKernelName l_stencil l_pShape'
                                     l_tile_indices l_kfss
                             else ""
        bdryKernel = if regBound
                        then pShowUnrollTimeTileOverlapKernels
                                (pShowMacroStmt True)
                                regBound PUnrollTimeTileMacroOverlap
                                bdryKernelName l_stencil l_pShape'
                                l_tile_indices_by_t l_kfss_by_t
                        else ""
        cond_obaseKernel = pShowAllCondTileOverlapKernels 
                                l_showSingleKernel 
                                False l_mode 
                                cond_obaseKernelName l_stencil l_pShape'
                                l_tile_indices l_kfss
        obaseKernel = pShowUnrollTimeTileOverlapKernels
                                l_showSingleKernel
                                False l_mode 
                                obaseKernelName l_stencil l_pShape'
                                l_tile_indices_by_t l_kfss_by_t
        runKernel = if regBound
                       then obaseKernelName ++ ", " ++ cond_obaseKernelName ++
                            ", " ++ bdryKernelName ++ ", " ++ cond_bdryKernelName
                       else obaseKernelName ++ ", " ++ cond_obaseKernelName
    in  (breakline ++ l_comments ++ breakline ++ show l_pShape' ++ 
         bdryKernel ++ breakline ++ cond_bdryKernel ++ breakline ++
         obaseKernel ++ breakline ++ cond_obaseKernel ++ breakline ++ 
         l_id ++ ".Register_Tile_Obase_Kernels(" ++ l_guardName ++
         ", " ++ show l_unroll ++ ", " ++ runKernel ++ ");" ++ breakline)

pGetOverlapGuardTiles :: PMode -> PStencil -> [(PGuard, PTile)] -> [(PGuard, PTile)] -> [(PGuard, PTile)] -> (String, [(PGuard, [PTile])])
pGetOverlapGuardTiles l_mode l_stencil l_xGTs l_iGTs l_tiGTs =
    let -- we are assuming that all guards and kernels are of the same rank
        l_rank = if length l_xGTs > 0
                    then gRank $ fst $ pHead l_xGTs
                    else if length l_iGTs > 0
                            then gRank $ fst $ pHead l_iGTs
                            else gRank $ fst $ pHead l_tiGTs
        l_xPGuardTiles = pGetExclusiveGuardTiles l_mode l_rank l_xGTs l_iGTs l_tiGTs
        l_iPGuardTiles = pGetInclusiveGuardTiles l_mode l_xGTs l_iGTs l_tiGTs
        l_xPGuardTiles' = zipWith pFillGuardOrder [0..] l_xPGuardTiles
        l_len_xGTs = length l_xPGuardTiles
        l_iPGuardTiles' = zipWith pFillGuardOrder [l_len_xGTs..] l_iPGuardTiles
        l_xGuards = map (pShowAutoGuardString " && ") l_xPGuardTiles'
        l_iGuards = map (pShowAutoGuardString " || ") l_iPGuardTiles'
        -- l_xGuardNames = map (pSubstitute "!" "_Not_" . gName . fst) l_xPGuardTiles'
        -- l_iGuardNames = map (pSubstitute "!" "_Not_" . gName . fst) l_iPGuardTiles'
        l_xTiles = map (pShowAutoTileString l_mode l_stencil) l_xPGuardTiles'
        l_iTiles = map (pShowAutoTileString l_mode l_stencil) l_iPGuardTiles'
        l_str_xGTs = zipWith (++) l_xGuards l_xTiles
        l_str_iGTs = zipWith (++) l_iGuards l_iTiles
    in  (breakline ++ concat l_str_xGTs ++ breakline ++ concat l_str_iGTs,
            l_xPGuardTiles' ++ l_iPGuardTiles')

pGetAllCondTileOverlapKernels :: PMode -> PStencil -> [(PGuard, PTile)] -> [(PGuard, PTile)] -> [(PGuard, PTile)] -> (String, [(PGuard, [PTile])])
pGetAllCondTileOverlapKernels l_mode l_stencil l_xGTs l_iGTs l_tiGTs =
    let l_GuardTiles = pGetOverlapGuardTiles l_mode l_stencil l_xGTs l_iGTs l_tiGTs
    in  l_GuardTiles


{------------------------------------------------------------------------------------- 
 - End functions for overlapped modes
 -------------------------------------------------------------------------------------
 -}

-------------------------------------------------------------------------------------------
--                             Following are C++ Grammar Parser                         ---
-------------------------------------------------------------------------------------------
pStencilRun :: GenParser Char ParserState (String, String)
pStencilRun = 
        do l_tstep <- try exprStmtDim
           comma
           l_func <- identifier
           return (show l_tstep, l_func)
    <?> "Stencil Run Parameters"

-- parse the input parameters of Register_Kernel:
-- it contains one guard function, and multiple computing kernels
pStencilRegisterStaggerKernelParams :: GenParser Char ParserState (PGuard, [PKernel])
pStencilRegisterStaggerKernelParams = 
        do l_guardName <- identifier 
           comma
           l_kernelNames <- commaSep1 identifier
           l_state <- getState
           let l_guard = getValidGuard l_state l_guardName
           let l_kernels = map (getValidKernel l_state) l_kernelNames
           return (l_guard, l_kernels)
    <?> "Stencil Register_Stagger_Kernels Parameters"

-- for tile kernel, because the kernels has been tiled up in an array of array,
-- so we only need to parse one kernel
-- bookmark
pStencilRegisterTileKernelParams :: GenParser Char ParserState (PGuard, PTile)
pStencilRegisterTileKernelParams = 
        do l_guardName <- identifier 
           comma
           l_tileName <- identifier
           l_state <- getState
           let l_guard = getValidGuard l_state l_guardName
           let l_tile = getValidTile l_state l_tileName
           return (l_guard, l_tile)
    <?> "Stencil Register_Tile_Kernels Parameters"

-- pDeclStatic <type, rank>
pDeclStatic :: GenParser Char ParserState (PType, PValue)
pDeclStatic = do l_type <- pType 
                 comma
                 -- exprDeclDim is an int that has to be known at compile-time
                 l_rank <- exprDeclDim
                 return (l_type, l_rank)

pDeclStaticNum :: GenParser Char ParserState (PValue)
pDeclStaticNum = do l_rank <- exprDeclDim
                    return (l_rank)

pDeclDynamic :: GenParser Char ParserState ([PName], PName, [DimExpr])
pDeclDynamic = do (l_qualifiers, l_name) <- try pVarDecl
--                  l_dims <- parens (commaSep1 exprDeclDim)
                  -- exprStmtDim is something might be known at Run-time
                  l_dims <- option [] (parens $ commaSep1 exprStmtDim)
                  return (l_qualifiers, l_name, l_dims)

pDeclPochoir :: GenParser Char ParserState ([PName], PName, String)
pDeclPochoir = do (l_qualifiers, l_name) <- try pVarDecl
                  return (l_qualifiers, l_name, "")

pVarDecl :: GenParser Char ParserState ([PName], PName)
pVarDecl = do l_qualifiers <- many cppQualifier
              l_name <- identifier
              return (l_qualifiers, l_name)

cppQualifier :: GenParser Char ParserState PName
cppQualifier = 
       do reservedOp "*"
          return "*"
   <|> do reservedOp "&"
          return "&"
   <|> do reserved "const"
          return "const"
   <|> do reserved "volatile"
          return "volatile"
   <|> do reserved "register"
          return "register"

ppShape :: GenParser Char ParserState [Int]
ppShape = do l_shape <- braces (commaSep1 $ (integer <|> braces(integer)) >>= return . fromInteger)
             return (l_shape)

{- parse a single statement which is ended by ';' -}
pStubStatement :: GenParser Char ParserState Stmt
pStubStatement = do stmt <- manyTill anyChar $ try semi
                    return (UNKNOWN $ stmt ++ ";")
             <|> do stmt <- manyTill anyChar $ try $ symbol "}"
                    return (UNKNOWN $ stmt ++ "}")
             <|> do stmt <- manyTill anyChar $ try eol 
                    return (UNKNOWN $ stmt)

{- parse a single statement which is ended by ';' 
 - new version : return the expr (syntax tree) instead of string
 -}
pStatement :: GenParser Char ParserState Stmt
pStatement = try pParenStmt 
         <|> try pDeclLocalStmt
         <|> try pIfStmt
         <|> try pSwitchStmt
         <|> try pDoStmt
         <|> try pWhileStmt
         <|> try pForStmt
         <|> try pExprStmt
         <|> try pNOPStmt
       --  <|> try pNOOPStmt
         <|> try pRetStmt
         <|> try pReturnStmt
         <|> try pContStmt
      -- pStubStatement scan in everything else except the "Pochoir_kernel_end" or "};"
         <|> try pStubStatement
         <?> "Statement"

-- pNOOPStmt :: GenParser Char ParserState Stmt
-- pNOOPStmt =
--     do return NOP

pNOPStmt :: GenParser Char ParserState Stmt
pNOPStmt =
    do semi
       return NOP

pContStmt :: GenParser Char ParserState Stmt
pContStmt =
    do reserved "continue"
       semi
       return (CONT)

pReturnStmt :: GenParser Char ParserState Stmt
pReturnStmt =
    do reserved "return"
       semi
       return (RETURN)

pRetStmt :: GenParser Char ParserState Stmt
pRetStmt =
    do reserved "return"
       l_expr <- try exprStmt
       semi
       return (RET l_expr)

pExprStmt :: GenParser Char ParserState Stmt
pExprStmt =
    do {- C++ comments are filtered by exprStmt -}
       l_expr <- try exprStmt
       semi
       return (EXPR l_expr)

pForStmt :: GenParser Char ParserState Stmt
pForStmt = 
    do reserved "for"
       l_exprs <- parens $ semiSep1 (commaSep pForExpr)
       l_stmt <- pStatement
       return (FOR l_exprs l_stmt)

pDoStmt :: GenParser Char ParserState Stmt
pDoStmt =
    do reserved "do"
       symbol "{"
       l_stmts <- manyTill pStatement (try $ symbol "}")
       -- l_stmt <- pStatement
       reserved "while"
       l_expr <- exprStmt
       semi
       return (DO l_expr l_stmts)

pWhileStmt :: GenParser Char ParserState Stmt
pWhileStmt =
    do reserved "while"
       l_boolExpr <- exprStmt
       symbol "{"
       l_stmts <- manyTill pStatement (try $ symbol "}")
       return (WHILE l_boolExpr l_stmts)

pParenStmt :: GenParser Char ParserState Stmt
pParenStmt =
    do symbol "{"
       l_stmts <- manyTill pStatement (try $ symbol "}")
       return (BRACES l_stmts)

pTypeDecl :: GenParser Char ParserState ([PName], PType)
pTypeDecl = do l_qualifiers <- many cppQualifier
               l_type <- pType
               return (l_qualifiers ++ [typeName l_type], l_type)

pTypeDecl_r :: GenParser Char ParserState ([PName], PType)
pTypeDecl_r = do l_type <- pType
                 l_qualifiers <- many cppQualifier
                 return ([typeName l_type] ++ l_qualifiers, l_type)

pDeclLocalStmt :: GenParser Char ParserState Stmt
pDeclLocalStmt =
    do (l_qualifiers, l_type) <- try pTypeDecl <|> try pTypeDecl_r
       l_exprs <- commaSep1 exprStmt 
       semi
       return (DEXPR l_qualifiers l_type l_exprs)

pIfStmt :: GenParser Char ParserState Stmt
pIfStmt =
    do reserved "if"
       l_boolExpr <- exprStmt
       l_trueBranch <- pStatement
       l_falseBranch <- option NOP pElseBranch
       return (IF l_boolExpr l_trueBranch l_falseBranch)

pSwitchStmt :: GenParser Char ParserState Stmt
pSwitchStmt =
    do reserved "switch"
       l_boolExpr <- exprStmt
       l_cases <- braces (many pCase)
       return (SWITCH l_boolExpr l_cases)
 
pParams :: GenParser Char ParserState (RegionT, Bool)
pParams = do l_regionT <- pRegionParam
             option "" comma
             l_obase <- option False (pObaseParam)
             return (l_regionT, l_obase)

pRegionParam :: GenParser Char ParserState RegionT
pRegionParam = do reserved "Periodic"
                  return Periodic
           <|> do reserved "Non-periodic"
                  return Nonperiodic
           <?> "Periodic/Non-periodic"

pObaseParam :: GenParser Char ParserState Bool
pObaseParam = do reserved "Obase"
                 return True
            <|>  return False
                  
pForExpr :: GenParser Char ParserState Stmt
pForExpr =  do (l_qualifiers, l_type) <- try pTypeDecl <|> try pTypeDecl_r
               l_exprs <- commaSep1 exprStmt 
               return (DEXPR l_qualifiers l_type l_exprs)
        <|> do l_expr <- exprStmt
               return (EXPR l_expr)
        <|> do whiteSpace
               return NOP
        <?> "For Expression"

pCase :: GenParser Char ParserState Stmt
pCase = do reserved "case"
           l_value <- natural >>= return . fromInteger
           colon
           l_stmts <- manyTill pStatement $ reserved "break"
           semi
           return (CASE l_value (l_stmts ++ [BREAK]))
    <|> do reserved "default"
           colon
           l_stmts <- manyTill pStatement $ reserved "break"
           semi
           return (DEFAULT (l_stmts ++ [BREAK]))
    <?> "Cases"

pElseBranch :: GenParser Char ParserState Stmt
pElseBranch = do reserved "else"
                 l_stmt <- pStatement
                 return l_stmt

pType :: GenParser Char ParserState PType
pType = do reserved "double" 
           return PType{typeName = "double", basicType = PDouble}
    <|> do reserved "int"
           return PType{typeName = "int", basicType = PInt}
    <|> do reserved "float"
           return PType{typeName = "float", basicType = PFloat}
    <|> do reserved "bool"
           return PType{typeName = "bool", basicType = PBool}
    <|> do reserved "char"
           return PType{typeName = "char", basicType = PChar}
    <|> do reserved "short"
           return PType{typeName = "short", basicType = PShort}
    <|> do reserved "long"
           return PType{typeName = "long", basicType = PLong}
    <|> do reserved "unsigned"
           return PType{typeName = "unsigned", basicType = PUnsigned}
    <|> do reserved "signed"
           return PType{typeName = "signed", basicType = PSigned}
    <|> do reserved "void"
           return PType{typeName = "void", basicType = PVoid}
    <|> do l_type <- identifier
           l_qualifiers <- many cppQualifier
           return PType{typeName = l_type ++ (intercalate " " l_qualifiers), basicType = PUserType}
    <|> do l_qualifiers <- many cppQualifier
           l_type <- identifier 
           return PType{typeName = (intercalate " " l_qualifiers) ++ l_type, basicType = PUserType}

eol :: GenParser Char ParserState String
eol = do string "\n" 
         whiteSpace
         return "\n"
  <|> do string "\r\n" 
         whiteSpace
         return "\r\n"
  <|> do string "\n\r" 
         whiteSpace
         return "\n\r"
  <?> "eol"

-- Expression Parser for Dim in Declaration --
exprDeclDim :: GenParser Char ParserState Int
exprDeclDim = buildExpressionParser tableDeclDim termDeclDim
   <?> "exprDeclDim"

tableDeclDim = [[Prefix (reservedOp "-" >> return negate)],
         [op "*" (*) AssocLeft, op "/" div AssocLeft],
         [op "+" (+) AssocLeft, op "-" (-) AssocLeft]]
         where op s fop assoc = Infix (do {reservedOp s; return fop} <?> "operator") assoc

termDeclDim :: GenParser Char ParserState Int
termDeclDim = 
       try (parens exprDeclDim)
   <|> do num_dim <- try (natural)
          return (fromInteger num_dim)
   <?> "termDeclDim"

-- Expression Parser for Dim in Statements --
exprStmtDim :: GenParser Char ParserState DimExpr
exprStmtDim = buildExpressionParser tableStmtDim termStmtDim <?> "ExprStmtDim"

tableStmtDim = [
         [bop "*" "*" AssocLeft, bop "/" "/" AssocLeft],
         [bop "+" "+" AssocLeft, bop "-" "-" AssocLeft],
         [bop "==" "==" AssocLeft, bop "!=" "!=" AssocLeft]]
         where bop str fop assoc = Infix ((reservedOp str >> return (DimDuo fop)) <?> "operator") assoc

termStmtDim :: GenParser Char ParserState DimExpr
termStmtDim = do e <- try (parens exprStmtDim)
                 return (DimParen e)
          <|> do literal_dim <- try (identifier)
                 return (DimVAR literal_dim)
          <|> do num_dim <- try (natural)
                 return (DimINT $ fromInteger num_dim)
          <?> "TermStmtDim"

-- Expression Parser for Statements --
exprStmt :: GenParser Char ParserState Expr
exprStmt = buildExpressionParser tableStmt termStmt
   <?> "Expression Statement"

tableStmt = [[Postfix (reservedOp "++" >> return (PostUno "++")),
              Postfix (reservedOp "--" >> return (PostUno "--"))],
            [Prefix (reservedOp "!" >> return (Uno "!")),
              Prefix (reservedOp "~" >> return (Uno "~")),
              Prefix (reservedOp "++" >> return (Uno "++")),
              Prefix (reservedOp "--" >> return (Uno "--")),
              Prefix (reservedOp "-" >> return (Uno "-")),
              Prefix (reservedOp "+" >> return (Uno "+")), --Unary Plus
              Prefix (reservedOp "*" >> return (Uno "*")), --Dereference
              Prefix (reservedOp "&" >> return (Uno "&"))  --Address of
             ],
         [op "*" "*" AssocLeft, op "/" "/" AssocLeft,
          op "%" "%" AssocLeft],
         [op "+" "+" AssocLeft, op "-" "-" AssocLeft],
         [op ">>" ">>" AssocLeft, op "<<" "<<" AssocLeft],
         [op ">" ">" AssocLeft, op "<" "<" AssocLeft,
          op ">=" ">=" AssocLeft, op "<=" "<=" AssocLeft],
         [op "==" "==" AssocLeft, op "!=" "!=" AssocLeft],
         [op "&" "&" AssocLeft], --bitwise and
         [op "^" "^" AssocLeft], --bitwise xor
         [op "|" "|" AssocLeft], --bitwise inclusive or
         [op "&&" "&&" AssocLeft], --logical and
         [op "||" "||" AssocLeft], --logical or
         [op ":" ":" AssocLeft],
         [op "?" "?" AssocLeft],
         [Infix (reservedOp "=" >> return (Duo "=")) AssocLeft,
          Infix (reservedOp "/=" >> return (Duo "/=")) AssocLeft,
          Infix (reservedOp "*=" >> return (Duo "*=")) AssocLeft,
          Infix (reservedOp "+=" >> return (Duo "+=")) AssocLeft,
          Infix (reservedOp "-=" >> return (Duo "-=")) AssocLeft,
          Infix (reservedOp "%=" >> return (Duo "%=")) AssocLeft,
          Infix (reservedOp "&=" >> return (Duo "&=")) AssocLeft,
          Infix (reservedOp "|=" >> return (Duo "|=")) AssocLeft,
          Infix (reservedOp "^=" >> return (Duo "^=")) AssocLeft,
          Infix (reservedOp ">>=" >> return (Duo ">>=")) AssocLeft,
          Infix (reservedOp "<<=" >> return (Duo "<<=")) AssocLeft
          ]]
         where op s fop assoc = Infix (do {reservedOp s; return (Duo fop)} <?> "operator") assoc

termStmt :: GenParser Char ParserState Expr
termStmt =  do try pArrayOfStructTermStmt
        <|> do try ppArrayOfStructTermStmt
        <|> do l_expr <- try (parens exprStmt) 
               return (PARENS l_expr)
        <|> do l_num <- try (number)
               case l_num of
                  Left n -> return (INT $ fromInteger n)
                  Right n -> return (FLOAT n)
        <|> do reserved "true" 
               return (BOOL "true") 
        <|> do reserved "false"
               return (BOOL "false")
        <|> do try pParenTermStmt
        <|> do try pBracketTermStmt
        <|> do try pBExprTermStmt
        -- pArrayOfStructTermStmt has to be before pPlainVarTermStmt
        -- because pPlainVarTermStmt just scan a plain identifier
        -- so, it's a conflict with pArrayOfStructTermStmt
        <|> do try pPlainVarTermStmt
        <?> "term statement"

pParenTermStmt :: GenParser Char ParserState Expr
pParenTermStmt =
    do l_qualifiers <- try (many cppQualifier)
       l_var <- try identifier
       l_dims <- parens (commaSep1 exprStmtDim)
       return (PVAR (concat l_qualifiers) l_var l_dims)

pBracketTermStmt :: GenParser Char ParserState Expr
pBracketTermStmt =
    do l_var <- try identifier
       l_dim <- brackets exprStmtDim
       return (BVAR l_var l_dim)

pBExprTermStmt :: GenParser Char ParserState Expr
pBExprTermStmt =
    do l_var <- try identifier
       l_expr <- brackets exprStmt
       return (BExprVAR l_var l_expr)

pPlainVarTermStmt :: GenParser Char ParserState Expr
pPlainVarTermStmt =
    do l_qualifiers <- try (many cppQualifier)
       l_var <- try identifier
       return (VAR (concat l_qualifiers) l_var)

pArrayOfStructTermStmt :: GenParser Char ParserState Expr
pArrayOfStructTermStmt =
    do l_type <- try pType
       l_pTerm <- parens pParenTermStmt
       l_connector <- symbol "." <|> symbol "->"
       l_field <- identifier
       return (SVAR l_type l_pTerm l_connector l_field)

ppArrayOfStructTermStmt :: GenParser Char ParserState Expr
ppArrayOfStructTermStmt =
    do let opt_type = PType{basicType = PUserType, typeName = ""}
       l_pTerm <- pParenTermStmt 
       l_connector <- symbol "." <|> symbol "->"
       l_field <- identifier
       return (SVAR opt_type l_pTerm l_connector l_field)

pPArrayOfStructTermStmt :: GenParser Char ParserState Expr
pPArrayOfStructTermStmt =
    do l_type <- parens pType
       l_pTerm <- parens pParenTermStmt
       l_connector <- symbol "." <|> symbol "->"
       l_field <- identifier
       return (PSVAR l_type l_pTerm l_connector l_field)
