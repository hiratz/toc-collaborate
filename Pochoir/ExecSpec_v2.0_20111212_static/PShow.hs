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
 -   Suggestsions:                  yuantang@csail.mit.edu
 -   Bugs:                          yuantang@csail.mit.edu
 -
 --------------------------------------------------------------------------------
 -}
module PShow where

import Text.ParserCombinators.Parsec
import Control.Monad
import qualified Data.Map as Map
import Data.List

import PData
import PUtils

simplifyDimExpr :: DimExpr -> DimExpr
simplifyDimExpr de = 
    let newDimExpr = simplifyDimExprItem de
    in  if newDimExpr == de then newDimExpr
                            else simplifyDimExpr newDimExpr

simplifyDimExprItem :: DimExpr -> DimExpr
simplifyDimExprItem (DimVAR v) = DimVAR v
simplifyDimExprItem (DimINT n) = DimINT n
simplifyDimExprItem (DimDuo "-" (DimINT m) (DimINT n)) = DimINT (m-n)
simplifyDimExprItem (DimDuo "+" (DimINT m) (DimINT n)) = DimINT (m+n)
simplifyDimExprItem (DimDuo "*" (DimINT m) (DimINT n)) = DimINT (m*n)
simplifyDimExprItem (DimDuo bop e1 e2)
    | bop == "+" && e1 == DimINT 0 = e2
    | bop == "+" && e2 == DimINT 0 = e1
    | bop == "-" && e2 == DimINT 0 = e1
    | bop == "*" && e1 == DimINT 0 = DimINT 0
    | bop == "*" && e2 == DimINT 0 = DimINT 0
    | bop == "*" && e1 == DimINT 1 = e2
    | bop == "*" && e2 == DimINT 1 = e1
    | otherwise = DimDuo bop (simplifyDimExprItem e1) (simplifyDimExprItem e2)
simplifyDimExprItem (DimParen e) = DimParen (simplifyDimExprItem e)

getFromStmts :: (PArray -> Expr -> PRWMode -> [Iter]) -> PRWMode -> Map.Map PName PArray -> [Stmt] -> [Iter]
getFromStmts l_action _ _ [] = []
getFromStmts l_action l_rw l_arrayMap l_stmts@(a:as) = 
    let i1 = getFromStmt a 
        i2 = getFromStmts l_action l_rw l_arrayMap as 
    in  union i1 i2
    where getFromStmt (BRACES stmts) = getFromStmts l_action l_rw l_arrayMap stmts 
          getFromStmt (EXPR e) = getFromExpr l_rw e
          getFromStmt (DEXPR qs t es) = concatMap (getFromExpr l_rw) es
          getFromStmt (IF e s1 s2) = 
              let iter1 = getFromExpr l_rw e 
                  iter2 = getFromStmt s1 
                  iter3 = getFromStmt s2 
              in  union iter1 (union iter2 iter3)
          getFromStmt (SWITCH e stmts) = 
              let iter1 = getFromExpr l_rw e 
                  iter2 = getFromStmts l_action l_rw l_arrayMap stmts
              in  union iter1 iter2
          getFromStmt (CASE v stmts) = getFromStmts l_action l_rw l_arrayMap stmts
          getFromStmt (DEFAULT stmts) = getFromStmts l_action l_rw l_arrayMap stmts
          getFromStmt (NOP) = []
          getFromStmt (BREAK) = []
          getFromStmt (DO e stmts) = 
              let iter1 = getFromExpr l_rw e 
                  iter2 = getFromStmts l_action l_rw l_arrayMap stmts
              in  union iter1 iter2
          getFromStmt (WHILE e stmts) = 
              let iter1 = getFromExpr l_rw e 
                  iter2 = getFromStmts l_action l_rw l_arrayMap stmts
              in  union iter1 iter2
          getFromStmt (FOR sL s) = 
              let iter1 = getFromStmt s 
                  iter2 = concat $ map (getFromStmts l_action l_rw l_arrayMap) sL
              in  union iter1 iter2
          getFromStmt (CONT) = []
          getFromStmt (RET e) = getFromExpr l_rw e
          getFromStmt (RETURN) = []
          getFromStmt (UNKNOWN s) = []
          getFromExpr _ (VAR q v) = []
          getFromExpr l_rw (PVAR q v dL) = 
              case Map.lookup v l_arrayMap of
                   Nothing -> []
                   Just arrayInUse -> l_action arrayInUse (PVAR q v dL) l_rw
          getFromExpr _ (BVAR v dim) = []
          getFromExpr l_rw (BExprVAR v e) = getFromExpr l_rw e
          getFromExpr l_rw (SVAR t e c f) = getFromExpr l_rw e
          getFromExpr l_rw (PSVAR t e c f) = getFromExpr l_rw e
          getFromExpr l_rw (Uno uop e) = getFromExpr l_rw e
          getFromExpr l_rw (PostUno uop e) = getFromExpr l_rw e
          getFromExpr l_rw (Duo bop e1 e2) = 
            if bop == "=" 
                then let iter1 = getFromExpr PWrite e1
                         iter2 = getFromExpr PRead e2
                     in  (union iter1 iter2)
                else let iter1 = getFromExpr l_rw e1
                         iter2 = getFromExpr l_rw e2
                     in  (union iter1 iter2)
          getFromExpr l_rw (PARENS e) = getFromExpr l_rw e
          getFromExpr _ _ = []

transStmts :: [Stmt] -> (Expr -> Expr) -> [Stmt]
transStmts [] _ = []
transStmts l_stmts@(a:as) l_action = transStmt a : transStmts as l_action
    where transStmt (BRACES stmts) = BRACES $ transStmts stmts l_action
          transStmt (EXPR e) = EXPR $ transExpr e
          transStmt (DEXPR qs t es) = DEXPR qs t $ map transExpr es 
          transStmt (IF e s1 s2) = IF (transExpr e) 
                                              (transStmt s1) 
                                              (transStmt s2) 
          transStmt (SWITCH e stmts) = SWITCH (transExpr e) 
                                                  (transStmts stmts l_action)
          transStmt (CASE v stmts) = CASE v $ transStmts stmts l_action
          transStmt (DEFAULT stmts) = DEFAULT $ transStmts stmts l_action
          transStmt NOP =  NOP
          transStmt BREAK =  BREAK
          transStmt (DO e stmts) = DO (transExpr e) (transStmts stmts l_action)
          transStmt (WHILE e stmts) = WHILE (transExpr e)
                                                (transStmts stmts l_action)
          transStmt (FOR sL s) = FOR (map (flip transStmts l_action) sL)
                                         (transStmt s) 
          transStmt (CONT) = CONT
          transStmt (RETURN) = RETURN
          transStmt (RET e) = RET (transExpr e)
          transStmt (UNKNOWN s) = UNKNOWN s 
          transExpr (VAR q v) =  VAR q v
          -- if it's in the form of BVAR, then the user must have already done some
          -- manual transformation on its source, we just leave them untouched!
          transExpr (PVAR q v dL) = l_action (PVAR q v dL)
          transExpr (BVAR v dim) = BVAR v dim
          transExpr (BExprVAR v e) = BExprVAR v $ transExpr e
          transExpr (SVAR t e c f) = SVAR t (transExpr e) c f
          transExpr (PSVAR t e c f) = PSVAR t (transExpr e) c f
          transExpr (Uno uop e) = Uno uop $ transExpr e
          transExpr (PostUno uop e) = PostUno uop $ transExpr e
          transExpr (Duo bop e1 e2) = Duo bop (transExpr e1) (transExpr e2)
          transExpr (PARENS e) = PARENS $ transExpr e
          transExpr (INT n) = (INT n)
          transExpr (FLOAT f) = (FLOAT f)
          transExpr (BOOL b) = (BOOL b)

pIterLookup :: (String, [DimExpr]) -> [Iter] -> Maybe String
pIterLookup (v, dL) [] = Nothing
pIterLookup (v, dL) ((iterName, arrayInUse, dim, rw):is) 
    | v == aName arrayInUse && dL == dim = Just iterName
    | otherwise = pIterLookup (v, dL) is

pDefMacroArrayInUse :: PName -> [PArray] -> [PName] -> String
pDefMacroArrayInUse _ [] _ = ""
pDefMacroArrayInUse l_macro (a:as) pL = pDefMacroShadowItem l_macro a pL ++ pDefMacroArrayInUse l_macro as pL
    where pDefMacroShadowItem l_macro a pL = 
            let l_arrayName = aName a
                l_arrayMacroName = l_arrayName ++ "." ++ l_macro
            in  breakline ++ "#define " ++ pShowArrayTerm l_arrayName pL ++ " " ++
                pShowArrayTerm l_arrayMacroName pL

pShowArrayTerm :: PName -> [PName] -> String
pShowArrayTerm a pL = a ++ "(" ++ pShowListIdentifiers pL ++ ")"

pUndefMacroArrayInUse :: [PArray] -> [PName] -> String
pUndefMacroArrayInUse [] _ = ""
pUndefMacroArrayInUse (a:as) pL = pUndefMacroShadowItem a pL ++ pUndefMacroArrayInUse as pL
    where pUndefMacroShadowItem a pL = 
            let l_arrayName = aName a
            in  breakline ++ "#undef " ++ pShowArrayTerm l_arrayName pL

pShowKernelParams :: [String] -> String
pShowKernelParams l_kernel_params = intercalate ", " l_kernel_params

pShowArrayGaps :: Int -> [PArray] -> String
pShowArrayGaps _ [] = ""
pShowArrayGaps l_rank l_array = breakline ++ "int " ++ 
        intercalate ", " (map (getArrayGaps (l_rank-1)) l_array) ++ ";"

-- AutoKernel is a de-sugared kernel
pShowAutoKernelFunc :: String -> PKernelFunc -> String
pShowAutoKernelFunc l_name l_kernelFunc = 
    let l_params = zipWith (++) (repeat "int ") (kfParams l_kernelFunc)
    in  "/* known Kernel ! */ auto " ++ l_name ++ " = [&] (" ++ 
        pShowKernelParams l_params ++ ") {" ++ breakline ++
        show (kfStmt l_kernelFunc) ++
        breakline ++ "};" ++ breakline

pShowAutoGuardFunc :: String -> PGuardFunc -> String
pShowAutoGuardFunc l_name l_guardFunc = 
    let l_params = zipWith (++) (repeat "int ") (gfParams l_guardFunc)
    in  "/* known Guard ! */ auto " ++ l_name ++ " = [&] (" ++ 
        pShowKernelParams l_params ++ ") -> bool {" ++ breakline ++
        show (gfStmt l_guardFunc) ++ breakline ++ "};" ++ breakline

pShowMacroKernel :: PName -> PKernelFunc -> String
pShowMacroKernel l_macro l_kernel =
    let l_iters = kfIter l_kernel
        l_name = l_macro ++ "_" ++ kfName l_kernel
        l_sArrayInUse = unionArrayIter l_iters
        shadowArrayInUse = pDefMacroArrayInUse l_macro l_sArrayInUse (kfParams l_kernel)
        unshadowArrayInUse = pUndefMacroArrayInUse l_sArrayInUse (kfParams l_kernel)
    in  shadowArrayInUse ++ pShowAutoKernelFunc l_name l_kernel ++ unshadowArrayInUse

pShowUnrolledMacroKernels :: Bool -> PName -> [PKernelFunc] -> String
pShowUnrolledMacroKernels l_cond l_name l_kL@(k:ks)  = 
    let -- l_iters = concatMap kfIter l_kL
        l_iters = foldr union (kfIter k) (map kfIter ks)
        l_arrayInUse = unionArrayIter l_iters 
        l_t = "t"
        l_t_begin = l_t ++ "0"
        l_t_end = l_t ++ "1"
        -- We are assuming all kernels have the same number of input parameters
        l_kfParams = kfParams k
        l_unroll = length l_kL
        l_unfold_kernels = 
            if l_cond then pShowCondMacroKernel False l_t 0 l_unroll l_kL
                      else pShowSingleMacroKernel False l_t l_kL
        -- assuming all kernels have the same rank
        l_rank = length l_kfParams - 1
        l_defMacro = pDefMacroArrayInUse "interior" l_arrayInUse l_kfParams
        l_undefMacro = pUndefMacroArrayInUse l_arrayInUse l_kfParams
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape l_kL)
        l_kernelFuncName = pSys l_name 
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int t0, int t1, " ++ " Grid_Info<" ++ 
                   show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );" ++ breakline 
    in  breakline ++ l_defMacro ++
        breakline ++ l_pHeader ++
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        breakline ++ pShowTimeLoopHeader l_t l_t_begin l_t_end ++ 
        l_unfold_kernels ++
        breakline ++ pShowTimeLoopTail ++ 
        breakline ++ l_tail ++
        breakline ++ l_undefMacro ++ breakline

pShowUnrolledBoundaryKernels :: Bool -> String -> PStencil -> [PKernelFunc] -> String
pShowUnrolledBoundaryKernels l_cond l_name l_stencil l_kL@(l_kernelFunc:l_kernelFuncs) =
    let l_t = "t"
        l_t_begin = l_t ++ "0"
        l_t_end = l_t ++ "1"
        l_rank = sRank l_stencil
        l_unroll = length l_kL
        l_arrayInUse = sArrayInUse l_stencil
        -- We are assuming all kernels have the same number of input parameters
        l_kfParams = kfParams l_kernelFunc
        l_defMacro = pDefMacroArrayInUse "boundary" l_arrayInUse l_kfParams ++ 
                        breakline ++ pDefPMODLU
        l_undefMacro = pUndefPMODLU ++ breakline ++
                        pUndefMacroArrayInUse l_arrayInUse l_kfParams 
        l_showPhysGrid = "Grid_Info<" ++ show l_rank ++ "> l_phys_grid = " ++ 
                         sName l_stencil ++ ".get_phys_grid();"
        l_unfold_kernels = 
                if l_cond then pShowCondMacroKernel True l_t 0 l_unroll l_kL
                          else pShowSingleMacroKernel True l_t l_kL
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape l_kL)
        l_kernelFuncName = pSys l_name
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int t0, int t1, " ++ " Grid_Info<" ++ 
                   show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );" ++ breakline 
    in  breakline ++ l_defMacro ++
        breakline ++ l_pHeader ++
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        breakline ++ l_showPhysGrid ++
        breakline ++ pShowTimeLoopHeader l_t l_t_begin l_t_end ++ 
        l_unfold_kernels ++
        breakline ++ pShowTimeLoopTail ++ 
        breakline ++ l_tail ++
        breakline ++ l_undefMacro ++ breakline

pDefMax :: String
pDefMax = "#define max(a, b) ((a) > (b) ? (a) : (b))"

pUndefMax :: String
pUndefMax = "#undef max(a, b)"

pDefMin :: String
pDefMin = "#define min(a, b) ((a) < (b) ? (a) : (b))"

pUndefMin :: String
pUndefMin = "#undef min(a, b)"

pShowMUnrolledBoundaryKernels :: Bool -> String -> PStencil -> [PKernelFunc] -> String
pShowMUnrolledBoundaryKernels l_cond l_name l_stencil l_kL@(l_kernel:l_kernels) = 
    let l_unroll = length l_kL
        s_unroll = show l_unroll 
        l_time_shift = sTimeShift l_stencil
        s_time_shift = show l_time_shift
        l_t = "t"
        l_t_pHeader_begin = "t0"
        l_t_pHeader_end = "t0 + (" ++ s_unroll ++ " - (t0 + " ++ s_time_shift ++ ") % " ++ s_unroll ++ ")"
        l_t_pHeader_end' = "min(" ++ l_t_pHeader_end ++ ", t1)"
        ll_t_pHeader_begin = "l_t_pHeader_begin"
        ll_t_pHeader_end = "l_t_pHeader_end"
        l_def_t_pHeader_begin = "int " ++ ll_t_pHeader_begin ++ " = " ++ l_t_pHeader_begin ++ ";"
        l_def_t_pHeader_end = "int " ++ ll_t_pHeader_end ++ " = " ++ l_t_pHeader_end' ++ ";"
        l_t_mid_begin = ll_t_pHeader_end
        l_t_mid_end = "t1 - " ++ "(t1 + " ++ s_time_shift ++ ") % " ++ s_unroll
        l_t_mid_end' = "min(" ++ l_t_mid_end ++ ", t1)"
        ll_t_mid_begin = "l_t_mid_begin"
        ll_t_mid_end = "l_t_mid_end"
        l_def_t_mid_begin = "int " ++ ll_t_mid_begin ++ " = " ++ l_t_mid_begin ++ ";"
        l_def_t_mid_end = "int " ++ ll_t_mid_end ++ " = " ++ l_t_mid_end' ++ ";"
        l_t_tail_begin = "max(" ++ ll_t_pHeader_end ++ ", " ++ ll_t_mid_end ++ ")"
        l_t_tail_end = "t1"
        l_t_tail_end' = l_t_tail_end
        ll_t_tail_begin = "l_t_tail_begin"
        ll_t_tail_end = "l_t_tail_end"
        l_def_t_tail_begin = "int " ++ ll_t_tail_begin ++ " = " ++ l_t_tail_begin ++ ";"
        l_def_t_tail_end = "int " ++ ll_t_tail_end ++ " = " ++ l_t_tail_end' ++ ";"
        l_t_pHeader_cout = "// std::cout << \"l_t_pHeader_begin = \" << " ++ ll_t_pHeader_begin ++ "<< \" l_t_pHeader_end = \" << " ++ ll_t_pHeader_end ++ " << std::endl;"
        l_t_mid_cout = "// std::cout << \"l_t_mid_begin = \" << " ++ ll_t_mid_begin ++ "<< \" l_t_mid_end = \" << " ++ ll_t_mid_end ++ " << std::endl;"
        l_t_tail_cout = "// std::cout << \"l_t_tail_begin = \" << " ++ ll_t_tail_begin ++ "<< \" l_t_tail_end = \" << " ++ ll_t_tail_end ++ " << std::endl;"
        l_rank = sRank l_stencil
        l_arrayInUse = sArrayInUse l_stencil
        -- We are assuming all kernels have the same number of input parameters
        l_kfParams = kfParams l_kernel
        l_defMacro = pDefMacroArrayInUse "boundary" l_arrayInUse l_kfParams ++ 
                        breakline ++ pDefPMODLU
        l_undefMacro = pUndefPMODLU ++ breakline ++
                        pUndefMacroArrayInUse l_arrayInUse l_kfParams 
        l_showPhysGrid = "Grid_Info<" ++ show l_rank ++ "> l_phys_grid = " ++ 
                         sName l_stencil ++ ".get_phys_grid();"
        l_pHeader_kernel = pShowCondMacroKernel True l_t 0 l_unroll l_kL
        l_tail_kernel = l_pHeader_kernel
        l_mid_kernel = pShowSingleMacroKernel True l_t l_kL
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape l_kL)
        l_kernelFuncName = pSys l_name
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int t0, int t1, " ++ " Grid_Info<" ++ 
                   show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );" ++ breakline 
    in  breakline ++ pDefMax ++
        breakline ++ pDefMin ++
        breakline ++ l_defMacro ++
        breakline ++ l_pHeader ++
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        breakline ++ l_showPhysGrid ++
        breakline ++ l_def_t_pHeader_begin ++ breakline ++ l_def_t_pHeader_end ++
        breakline ++ l_def_t_mid_begin ++ breakline ++ l_def_t_mid_end ++
        breakline ++ l_def_t_tail_begin ++ breakline ++ l_def_t_tail_end ++
        breakline ++ l_t_pHeader_cout ++
        breakline ++ l_t_mid_cout ++
        breakline ++ l_t_tail_cout ++
        breakline ++ pShowTimeLoopHeader l_t ll_t_pHeader_begin ll_t_pHeader_end ++
        l_pHeader_kernel ++ breakline ++ pShowTimeLoopTail ++
        breakline ++ pShowTimeLoopHeader l_t ll_t_mid_begin ll_t_mid_end ++
        l_mid_kernel ++ breakline ++ pShowTimeLoopTail ++
        breakline ++ pShowTimeLoopHeader l_t ll_t_tail_begin ll_t_tail_end ++
        l_tail_kernel ++ breakline ++ pShowTimeLoopTail ++
        breakline ++ l_tail ++
        breakline ++ l_undefMacro ++ 
        breakline ++ pUndefMax ++ breakline ++ pUndefMin 

pShowMUnrolledKernels :: String -> PStencil -> [PKernelFunc] -> (Bool -> String -> Int -> Int -> [PKernelFunc] -> String) -> String
pShowMUnrolledKernels l_name l_stencil l_kL@(l_kernel:l_kernels) l_showSingleKernel= 
    let l_rank = sRank l_stencil
        l_iter = concatMap kfIter l_kL
        -- l_arrayInUse = unionArrayIter l_iter
        l_arrayInUse = sArrayInUse l_stencil
        l_unroll = length l_kL
        s_unroll = show l_unroll
        l_time_shift = sTimeShift l_stencil
        s_time_shift = show l_time_shift
        l_t = "t"
        l_t_pHeader_begin = "t0"
        l_t_pHeader_end = "t0 + (" ++ s_unroll ++ " - (t0 + " ++ s_time_shift ++ ") % " ++ s_unroll ++ ")"
        l_t_pHeader_end' = "min(" ++ l_t_pHeader_end ++ ", t1)"
        ll_t_pHeader_begin = "l_t_pHeader_begin"
        ll_t_pHeader_end = "l_t_pHeader_end"
        l_def_t_pHeader_begin = "int " ++ ll_t_pHeader_begin ++ " = " ++ l_t_pHeader_begin ++ ";"
        l_def_t_pHeader_end = "int " ++ ll_t_pHeader_end ++ " = " ++ l_t_pHeader_end' ++ ";"
        l_t_mid_begin = ll_t_pHeader_end
        l_t_mid_end = "t1 - " ++ "(t1 + " ++ s_time_shift ++ ") % " ++ s_unroll
        l_t_mid_end' = "min(" ++ l_t_mid_end ++ ", t1)"
        ll_t_mid_begin = "l_t_mid_begin"
        ll_t_mid_end = "l_t_mid_end"
        l_def_t_mid_begin = "int " ++ ll_t_mid_begin ++ " = " ++ l_t_mid_begin ++ ";"
        l_def_t_mid_end = "int " ++ ll_t_mid_end ++ " = " ++ l_t_mid_end' ++ ";"
        l_t_tail_begin = "max(" ++ ll_t_pHeader_end ++ ", " ++ ll_t_mid_end ++ ")"
        l_t_tail_end = "t1"
        l_t_tail_end' = l_t_tail_end
        ll_t_tail_begin = "l_t_tail_begin"
        ll_t_tail_end = "l_t_tail_end"
        l_def_t_tail_begin = "int " ++ ll_t_tail_begin ++ " = " ++ l_t_tail_begin ++ ";"
        l_def_t_tail_end = "int " ++ ll_t_tail_end ++ " = " ++ l_t_tail_end' ++ ";"
        l_t_pHeader_cout = "// std::cout << \"l_t_pHeader_begin = \" << " ++ ll_t_pHeader_begin ++ " << \" l_t_pHeader_end = \" << " ++ ll_t_pHeader_end ++ " << std::endl;"
        l_t_mid_cout = "// std::cout << \"l_t_mid_begin = \" << " ++ ll_t_mid_begin ++ "<< \" l_t_mid_end = \" << " ++ ll_t_mid_end ++ " << std::endl;"
        l_t_tail_cout = "// std::cout << \"l_t_tail_begin = \" << " ++ ll_t_tail_begin ++ " << \" l_t_tail_end = \" << " ++ ll_t_tail_end ++ " << std::endl;"
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape l_kL)
        l_kernelFuncName = pSys l_name
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int t0, int t1, " ++ " Grid_Info<" ++ 
                   show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );" ++ breakline 
        l_pHeader_kernel = l_showSingleKernel True l_t 0 l_unroll l_kL
        l_tail_kernel = l_pHeader_kernel
        l_mid_kernel = l_showSingleKernel False l_t 0 l_unroll l_kL
    in  breakline ++ pDefMax ++
        breakline ++ pDefMin ++
        breakline ++ l_pHeader ++ 
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayInfo l_arrayInUse ++ pShowArrayGaps l_rank l_arrayInUse ++ 
        breakline ++ pShowRankAttr l_rank "stride" l_arrayInUse ++ 
        breakline ++ l_def_t_pHeader_begin ++ breakline ++ l_def_t_pHeader_end ++
        breakline ++ l_def_t_mid_begin ++ breakline ++ l_def_t_mid_end ++
        breakline ++ l_def_t_tail_begin ++ breakline ++ l_def_t_tail_end ++
        breakline ++ l_t_pHeader_cout ++
        breakline ++ l_t_mid_cout ++
        breakline ++ l_t_tail_cout ++
        breakline ++ pShowTimeLoopHeader l_t ll_t_pHeader_begin ll_t_pHeader_end ++ 
        l_pHeader_kernel ++ breakline ++ pShowTimeLoopTail ++
        breakline ++ pShowTimeLoopHeader l_t ll_t_mid_begin ll_t_mid_end ++
        l_mid_kernel ++ breakline ++ pShowTimeLoopTail ++
        breakline ++ pShowTimeLoopHeader l_t ll_t_tail_begin ll_t_tail_end ++
        l_tail_kernel ++ breakline ++ pShowTimeLoopTail ++
        breakline ++ l_tail ++
        breakline ++ pUndefMax ++ breakline ++ pUndefMin

------------------------------------------------------------------------------
-- so far, the split-caching mode doesn't work for multiple-kernel case!!!! --
------------------------------------------------------------------------------
pShowUnrolledCachingKernels :: PStencil -> Bool -> String -> [PKernelFunc] -> String
pShowUnrolledCachingKernels l_stencil l_cond l_name l_kL@(l_kernel:l_kernels) = 
    let l_rank = length (kfParams l_kernel) - 1
        l_iter = concatMap kfIter l_kL
        l_rdIters = pGetMinIters $ pGetReadIters l_iter
        l_wrIters = pGetMinIters $ pGetWriteIters l_iter 
        l_arrayInUse = unionArrayIter l_iter
        l_t = "t"
        l_t_begin = "t0"
        l_t_end = "t1"
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape l_kL)
        l_kernelFuncName = pSys l_name
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int t0, int t1, " ++ " Grid_Info<" ++ 
                   show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );" ++ breakline 
    in  breakline ++ l_pHeader ++ 
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayInfo l_arrayInUse ++ pShowArrayGaps l_rank l_arrayInUse ++
        breakline ++ pShowRankAttr l_rank "stride" l_arrayInUse ++ 
        -- Additional copy-in info for caching kernel ---------------------------
        pShowDeltaT ++ breakline ++ pAllocStack l_arrayInUse ++ breakline ++ 
        pShowLocalCacheAttr l_rank l_arrayInUse l_stencil ++ breakline ++ 
        pShowLocalCopyIn l_rank (kfParams l_kernel) l_arrayInUse l_rdIters ++ breakline ++ 
        pShowLocalGridForComp l_rank (pHead l_arrayInUse) ++ breakline ++
        -------------------------------------------------------------------------
        pShowTimeLoopHeader l_t l_t_begin l_t_end ++ breakline ++
        pShowSingleCachingKernel l_t l_kL ++
        pShowTimeLoopTail ++ breakline ++ 
        -- Additional copy-out info for caching kernel ---------------------------
        pShowLocalCopyOut l_rank (kfParams l_kernel) l_arrayInUse l_wrIters ++ 
        breakline ++ pFreeStack l_arrayInUse ++ 
        ---------------------------------------------------------------------------
        breakline ++ l_tail

pShowUnrolledKernels :: Bool -> String -> PStencil -> [PKernelFunc] -> (Bool -> String -> Int -> Int -> [PKernelFunc] -> String) -> String
pShowUnrolledKernels l_cond l_name l_stencil l_kL@(l_kernel:l_kernels) l_showSingleKernel= 
    let l_rank = length (kfParams l_kernel) - 1
        l_iter = concatMap kfIter l_kL
        l_arrayInUse = unionArrayIter l_iter
        l_t = "t"
        l_t_begin = "t0" 
        l_t_end = "t1"
        l_unroll = length l_kL
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape l_kL)
        l_kernelFuncName = pSys l_name
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int t0, int t1, " ++ " Grid_Info<" ++ 
                   show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );" ++ breakline 
    in  breakline ++ l_pHeader ++ 
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayInfo l_arrayInUse ++ pShowArrayGaps l_rank l_arrayInUse ++ 
        breakline ++ pShowRankAttr l_rank "stride" l_arrayInUse ++ 
        breakline ++ pShowTimeLoopHeader l_t l_t_begin l_t_end ++ 
        l_showSingleKernel l_cond l_t 0 l_unroll l_kL ++
        breakline ++ pShowTimeLoopTail ++ breakline ++ l_tail

pDefPMODLU :: String
pDefPMODLU = "#define pmod_lu(a, lb, ub) ((a) - (((ub)-(lb)) & -((a)>=(ub))))"

pUndefPMODLU :: String
pUndefPMODLU = "#undef pmod_lu"

pShowSingleCachingKernel :: String -> [PKernelFunc] -> String
pShowSingleCachingKernel _ [] = ""
pShowSingleCachingKernel l_t l_kL@(l_kernel:l_kernels) =
    let l_rank = length (kfParams l_kernel) - 1
        l_iter = kfIter l_kernel
        l_arrayInUse = unionArrayIter l_iter
    in  breakline ++ "{" ++
        breakline ++ pShowPointers l_iter ++ 
        breakline ++ pShowPointerSetLocal l_iter (kfParams l_kernel) ++
        pShowPointerForHeader l_rank False l_iter (tail $ kfParams l_kernel) ++
        breakline ++ pShowPointerStmt False l_kernel ++ breakline ++ 
        pShowObaseForTail l_rank ++ 
        pAdjustTrape l_rank ++ breakline ++ pAdjustT l_t l_kernels ++
        breakline ++ "}" ++ pShowSingleCachingKernel l_t l_kernels

pShowSingleCPointerKernel :: Bool -> String -> Int -> Int -> [PKernelFunc] -> String
pShowSingleCPointerKernel _ _ _ _ [] = ""
pShowSingleCPointerKernel l_cond l_t l_resid l_unroll l_kL@(l_kernel:l_kernels) = 
    let l_rank = length (kfParams l_kernel) - 1
        l_iter = kfIter l_kernel
        l_arrayInUse = unionArrayIter l_iter
        l_guard_pHead = if l_cond && l_unroll > 1 
                          then pShowUnrollTGuardHead l_t l_resid l_unroll 
                                    (shapeTimeShift $ kfShape l_kernel)
                          else ""
        l_guard_tail = if l_cond && l_unroll > 1 then pShowUnrollGuardTail (length l_kernels) else ""
        l_adjust_T = if l_cond && l_unroll > 1  then "" else pAdjustT l_t l_kernels
    in  breakline ++ l_guard_pHead ++
        breakline ++ "{" ++
        breakline ++ pShowRawForHeader (tail $ kfParams l_kernel) ++
        breakline ++ pShowCPointerStmt l_kernel ++ breakline ++ 
        pShowObaseForTail l_rank ++
        pAdjustTrape l_rank ++ breakline ++ l_adjust_T ++
        breakline ++ "}" ++ 
        breakline ++ l_guard_tail ++
        pShowSingleCPointerKernel l_cond l_t (l_resid + 1) l_unroll l_kernels

pShowSingleOptPointerKernel :: Bool -> String -> Int -> Int -> [PKernelFunc] -> String
pShowSingleOptPointerKernel _ _ _ _ [] = ""
pShowSingleOptPointerKernel l_cond l_t l_resid l_unroll l_kL@(l_kernel:l_kernels) =
    let l_rank = length (kfParams l_kernel) - 1
        l_iter = kfIter l_kernel
        l_arrayInUse = unionArrayIter l_iter
        l_guard_pHead = if l_cond && l_unroll > 1
                          then pShowUnrollTGuardHead l_t l_resid l_unroll 
                                    (shapeTimeShift $ kfShape l_kernel)
                          else ""
        l_guard_tail = if l_cond && l_unroll > 1 then pShowUnrollGuardTail (length l_kernels) else ""
        l_adjust_T = if l_cond && l_unroll > 1 then "" else pAdjustT l_t l_kernels
    in  breakline ++ l_guard_pHead ++ 
        breakline ++ "{" ++
        pShowPointers l_iter ++ breakline ++ 
        pShowOptPointerSet l_iter (kfParams l_kernel)++ breakline ++ 
        pShowPointerForHeader l_rank True l_iter (tail $ kfParams l_kernel) ++
        breakline ++ pShowOptPointerStmt l_kernel ++ breakline ++ 
        pShowObaseForTail l_rank ++
        pAdjustTrape l_rank ++ breakline ++ l_adjust_T ++
        breakline ++ "}" ++ 
        breakline ++ l_guard_tail ++
        pShowSingleOptPointerKernel l_cond l_t (l_resid + 1) l_unroll l_kernels
 
pShowSinglePointerKernel :: Bool -> String -> Int -> Int -> [PKernelFunc] -> String
pShowSinglePointerKernel _ _ _ _ [] = ""
pShowSinglePointerKernel l_cond l_t l_resid l_unroll l_kL@(l_kernel:l_kernels) =
    let l_rank = length (kfParams l_kernel) - 1
        l_iter = kfIter l_kernel
        l_arrayInUse = unionArrayIter l_iter
        l_guard_pHead = if l_cond && l_unroll > 1 
                          then pShowUnrollTGuardHead l_t l_resid l_unroll 
                                    (shapeTimeShift $ kfShape l_kernel)
                          else ""
        l_guard_tail = if l_cond && l_unroll > 1 then pShowUnrollGuardTail (length l_kernels) else ""
        l_adjust_T = if l_cond && l_unroll > 1 then "" else pAdjustT l_t l_kernels
    in  breakline ++ l_guard_pHead ++
        breakline ++ "{" ++ 
        pShowPointers l_iter ++ breakline ++ 
        pShowPointerSet l_iter (kfParams l_kernel)++ breakline ++ 
        pShowPointerForHeader l_rank True l_iter (tail $ kfParams l_kernel) ++
        breakline ++ pShowPointerStmt True l_kernel ++ breakline ++ 
        pShowObaseForTail l_rank ++
        pAdjustTrape l_rank ++ breakline ++ l_adjust_T ++
        breakline ++ "}" ++ 
        breakline ++ l_guard_tail ++ 
        pShowSinglePointerKernel l_cond l_t (l_resid + 1) l_unroll l_kernels
 
pShowSingleMacroKernel :: Bool -> String -> [PKernelFunc] -> String
pShowSingleMacroKernel _ _ [] = ""
pShowSingleMacroKernel l_bound l_t (l_kernel:l_kernels) =
    let l_params = tail $ kfParams l_kernel
        l_rank = length (kfParams l_kernel) - 1
    in  breakline ++ pShowMetaGridHeader l_bound l_params ++
        breakline ++ show (kfStmt l_kernel) ++
        breakline ++ pShowMetaGridTail l_params ++ 
        breakline ++ pAdjustTrape l_rank ++ breakline ++ pAdjustT l_t l_kernels ++ 
        pShowSingleMacroKernel l_bound l_t l_kernels 

pShowUnrollTGuardHead :: String -> Int -> Int -> Int -> String
pShowUnrollTGuardHead l_t l_resid l_unroll l_timeShift =
    let l_modOp = " % "
        l_divisor = show l_unroll
        l_dividend = " ( " ++ l_t ++ " + " ++ show l_timeShift ++ " ) "
    in  "if (" ++ l_dividend ++ l_modOp ++ l_divisor ++ " == " ++ show l_resid ++ ") {"

{------------------------------------------------------------------------------------
 - starting procedures for tile                                                     -
 ------------------------------------------------------------------------------------}
pInsCheckMod :: String -> String -> String
pInsCheckMod a b 
    | b == "1" = ""
    | otherwise = a ++ " % " ++ b

pInsCheckEq :: String -> String -> String
pInsCheckEq a b
    | a == "" || b == "" = ""
    | otherwise = a ++ " == " ++ b

pShowTileGuardHeadOnAll :: [String] -> [Int] -> [Int] -> Int -> String
pShowTileGuardHeadOnAll l_params l_dim_sizes l_tile_index l_time_shift =
    let l_t = pHead l_params
        l_t_dividend = " ( " ++ l_t ++ " + " ++ show l_time_shift ++ " ) "
        l_dividends = [l_t_dividend] ++ tail l_params
        l_divisors = map show l_dim_sizes
        l_lefts = zipWith pInsCheckMod l_dividends l_divisors
        l_rights = map show l_tile_index
        l_dim_guards = zipWith pInsCheckEq l_lefts l_rights
        l_rev_dim_guards = filter (/= "") l_dim_guards
        l_guards = intercalate " && " l_rev_dim_guards
    in  if null l_guards then "{" else  "if (" ++ l_guards ++ ") {"

pShowTileGuardHeadOnSpatial :: [String] -> [Int] -> [Int] -> String
pShowTileGuardHeadOnSpatial l_spatial_params l_spatial_dim_sizes l_tile_spatial_index =
    let l_dividends = l_spatial_params
        l_divisors = map show l_spatial_dim_sizes
        l_lefts = zipWith pInsCheckMod l_dividends l_divisors
        l_rights = map show l_tile_spatial_index
        l_dim_guards = zipWith pInsCheckEq l_lefts l_rights
        l_rev_dim_guards = filter (/= "") l_dim_guards
        l_guards = intercalate " && " l_rev_dim_guards
    in  if null l_guards then "{" else "if (" ++ l_guards ++ ") {"

pShowUnrollGuardTail :: Int -> String
pShowUnrollGuardTail l_len 
    | l_len == 0 = "}"
    | otherwise = "} else"

{- Starting the procedure for overlapped irregular stencils 
 -}
pShowAutoGuardString :: String -> (PGuard, [PTile]) -> String
pShowAutoGuardString l_op (_, []) = ""
pShowAutoGuardString l_op (l_pGuard, l_tiles@(t:ts)) = 
    let l_gfName = pGetOverlapGuardFuncName l_pGuard
        l_gName = pGetOverlapGuardName l_pGuard
        l_pShapes = map (kShape) $ concatMap getTileKernels l_tiles
        l_mergedPShape = pSysShape $ foldr mergePShapes emptyShape l_pShapes
        l_timeShift = shapeTimeShift l_mergedPShape
        l_rank = gRank l_pGuard
        l_decl_params = "int t, " ++ 
                    (intercalate ", " $ take l_rank $ map ((++) "int i" . show) [0,1..])
        l_invoke_params = 
                    if l_timeShift /= 0
                       then "t + " ++ show l_timeShift ++ ", " ++
                            (intercalate ", " $ take l_rank $ map ((++) "i" . show) [0,1..])
                       else "t, " ++ 
                            (intercalate ", " $ take l_rank $ map ((++) "i" . show) [0,1..])
        l_decl_params' = " ( " ++ l_decl_params ++ " ) "
        l_invoke_params' = " ( " ++ l_invoke_params ++ " ) " 
        l_content = intercalate l_op $ 
                        map (flip (++) l_invoke_params' . pAddUnderScore) $ 
                        gComment l_pGuard
    in  breakline ++ "auto " ++ l_gfName ++ " = [&] " ++ l_decl_params' ++ 
        " -> bool {" ++
        breakline ++ "return ( " ++ l_content ++ " );" ++ breakline ++ " };" ++
        breakline ++ "Pochoir_Guard <" ++ show l_rank ++ "> " ++ l_gName ++ " ( " ++ 
        l_gfName ++ " ); \n"

pShowAutoTileComments :: [PTile] -> String
pShowAutoTileComments [] = breakline ++ "/* directly return */"
pShowAutoTileComments l_ts =
    breakline ++ "/* " ++ 
    breakline ++ intercalate (";" ++ breakline)
                    (zipWith (++) (map tName l_ts) 
                                  (map ((++) " - " . show . tOp) l_ts)) ++
    breakline ++ " */"

pShowAllCondTileOverlapSerialKernel :: (PKernelFunc -> String) -> [PKernelFunc] -> String
pShowAllCondTileOverlapSerialKernel _ [] = ""
pShowAllCondTileOverlapSerialKernel l_showSingleKernel l_kL@(k:ks) =
    breakline ++ l_showSingleKernel k ++
    breakline ++ pShowAllCondTileOverlapSerialKernel l_showSingleKernel ks

pShowAllCondTileOverlapInclusiveKernel :: (PKernelFunc -> String) -> TileOp -> [PKernelFunc] -> String
pShowAllCondTileOverlapInclusiveKernel _ _ [] = ""
pShowAllCondTileOverlapInclusiveKernel l_showSingleKernel l_tile_op l_kfs@(k:ks) =
    let l_params = kfParams k
        l_spatial_params = tail l_params
        l_t = pHead l_params
        l_iter = kfIter k
        l_arrayInUse = unionArrayIter l_iter
        l_pShape = pSysShape $ foldr mergePShapes emptyShape (map kfShape l_kfs)
        l_timeShift = shapeTimeShift l_pShape
        l_t_dim = if l_timeShift /= 0
                     then l_t ++ " + " ++ show l_timeShift
                     else l_t
        g = ("__" ++ (gfName $ kfGuardFunc k) ++ "__") ++ " ( " ++
            l_t_dim ++ ", " ++ intercalate ", " l_spatial_params ++ " ) "
        l_tail = if (l_tile_op == PEXCLUSIVE && length ks > 0)
                    then "} else "
                    else "}"
    in  (breakline ++ "if (" ++ g ++ ") {" ++
         breakline ++ l_showSingleKernel k ++
         breakline ++ l_tail ++
         breakline ++ pShowAllCondTileOverlapInclusiveKernel l_showSingleKernel l_tile_op ks)

pShowAllCondTileOverlapSingleKernel :: (PKernelFunc -> String) -> [[PKernelFunc]] -> String
pShowAllCondTileOverlapSingleKernel _ [] = ""
pShowAllCondTileOverlapSingleKernel l_showSingleKernel l_kfss@(k:ks) =
    case (kfTileOp . pHead) k of
        PSERIAL -> 
            pShowAllCondTileOverlapSerialKernel l_showSingleKernel k ++
            pShowAllCondTileOverlapSingleKernel l_showSingleKernel ks
        PEXCLUSIVE ->
            pShowAllCondTileOverlapInclusiveKernel 
                    l_showSingleKernel PEXCLUSIVE k ++
            pShowAllCondTileOverlapSingleKernel l_showSingleKernel ks
        PINCLUSIVE -> 
            pShowAllCondTileOverlapInclusiveKernel 
                    l_showSingleKernel PINCLUSIVE k ++
            pShowAllCondTileOverlapSingleKernel l_showSingleKernel ks

{-
pShowOverlapGuardTail :: [Int] -> [[Int]] -> String
pShowOverlapGuardTail _ [] = "}"
pShowOverlapGuardTail t ts = if length t == (length . pHead) ts
                                then "} else "
                                else "}"
-}

pShowOverlapGuardTail :: [PKernelFunc] -> [[PKernelFunc]] -> String
pShowOverlapGuardTail _ [] = "}"
pShowOverlapGuardTail _ [[]] = "}"
pShowOverlapGuardTail k ks = if (kfTileOrder . pHead) k == (kfTileOrder . pHead . pHead) ks
                                then "} else"
                                else "}"

pShowAllCondTileOverlapKernelLoops :: (PKernelFunc -> String) -> [[Int]] -> [[PKernelFunc]] -> String
pShowAllCondTileOverlapKernelLoops _ [] _ = ""
pShowAllCondTileOverlapKernelLoops l_showSingleKernel l_tile_indices@(t:ts) l_kL@(k:ks) =
    let l_params = kfParams $ pHead k
        l_spatial_params = tail l_params
        l_rank = length l_spatial_params
        l_dim_sizes = getTileSizes l_tile_indices
        l_tile_index = pHead l_tile_indices
        l_guard_pHead = pShowTileGuardHeadOnAll l_params l_dim_sizes l_tile_index
                                                (shapeTimeShift $ kfShape $ pHead k)
        l_guard_tail = pShowOverlapGuardTail k ks
        k' = pGroupBy eqTileOpPKernelFunc k
        l_kernels = pShowAllCondTileOverlapSingleKernel l_showSingleKernel k'
    in  breakline ++ l_guard_pHead ++
        breakline ++ l_kernels ++
        breakline ++ l_guard_tail ++
        pShowAllCondTileOverlapKernelLoops l_showSingleKernel ts ks

pShowAllCondTileOverlapKernels :: (PKernelFunc -> String) -> Bool -> PMode -> String -> PStencil -> PShape -> [[Int]] -> [[PKernelFunc]] -> String
pShowAllCondTileOverlapKernels _ _ _ _ _ _ _ [] = ""
pShowAllCondTileOverlapKernels l_showSingleKernel l_bound l_mode l_name l_stencil l_pShape l_tile_indices l_kfss@(k:ks) =
    let l_rank = sRank l_stencil
        l_arrayInUse = sArrayInUse l_stencil
        l_kernel_funcs = concat l_kfss
        l_iter = foldr union (kfIter $ pHead l_kernel_funcs) 
                             (map kfIter $ tail l_kernel_funcs)
        -- We are assuming that all kernel functions have the 
        -- same number of input parameters
        l_params = (kfParams . pHead . pHead) l_kfss
        l_spatial_params = tail l_params
        l_t = pHead l_params
        l_t_begin = l_t ++ "0"
        l_t_end = l_t ++ "1"
        l_kernelFuncName = pSys l_name
        l_showPhysGrid = "Grid_Info <" ++ show l_rank ++ "> l_phys_grid = " ++
                            sName l_stencil ++ ".get_phys_grid();"
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++
                   " = [&] (int " ++ l_t_begin ++ ", int " ++ l_t_end ++ ", " ++
                   " Grid_Info <" ++ show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel <" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++
                 shapeName l_pShape ++ " );"
        l_spatial_loop_pHeader = 
            case l_mode of
                PAllCondTileMacroOverlap ->
                            pShowMetaGridHeader l_bound l_spatial_params
                PAllCondTileCPointerOverlap -> 
                            pShowMetaGridHeader False l_spatial_params
                PAllCondTilePointerOverlap ->
                            pShowPointers l_iter ++ breakline ++
                            pShowPointerSet l_iter l_params ++ breakline ++
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
                PAllCondTileOptPointerOverlap ->
                            pShowPointers l_iter ++ breakline ++
                            pShowOptPointerSet l_iter l_params ++ breakline ++
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
                PUnrollTimeTileMacroOverlap ->
                            pShowMetaGridHeader l_bound l_spatial_params
                PUnrollTimeTileCPointerOverlap -> 
                            pShowMetaGridHeader False l_spatial_params
                PUnrollTimeTilePointerOverlap ->
                            pShowPointers l_iter ++ breakline ++
                            pShowPointerSet l_iter l_params ++ breakline ++
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
                PUnrollTimeTileOptPointerOverlap ->
                            pShowPointers l_iter ++ breakline ++
                            pShowOptPointerSet l_iter l_params ++ breakline ++
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
        l_spatial_loop_tail = 
            case l_mode of
                PAllCondTileMacroOverlap ->
                            pShowMetaGridTail l_spatial_params
                PAllCondTileCPointerOverlap ->
                            pShowMetaGridTail l_spatial_params
                PAllCondTilePointerOverlap -> 
                            pShowObaseForTail l_rank
                PAllCondTileOptPointerOverlap ->
                            pShowObaseForTail l_rank
                PUnrollTimeTileMacroOverlap ->
                            pShowMetaGridTail l_spatial_params
                PUnrollTimeTileCPointerOverlap ->
                            pShowMetaGridTail l_spatial_params
                PUnrollTimeTilePointerOverlap -> 
                            pShowObaseForTail l_rank
                PUnrollTimeTileOptPointerOverlap ->
                            pShowObaseForTail l_rank
        l_unfold_kernels = 
            pShowAllCondTileOverlapKernelLoops l_showSingleKernel 
                l_tile_indices l_kfss
        l_def_mod_lu = if l_bound then pDefPMODLU else ""
        l_undef_mod_lu = if l_bound then pUndefPMODLU else ""
        l_str_tile_indices = "/* " ++ show l_tile_indices ++ " */"
        l_str_kernel_funcs = "/* " ++ show (map (map kfName) l_kfss) ++ " */"
    in  breakline ++ l_def_mod_lu ++
        breakline ++ l_str_tile_indices ++
        breakline ++ l_str_kernel_funcs ++
        breakline ++ l_pHeader ++
        breakline ++ "Grid_Info <" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayInfo l_arrayInUse ++ pShowArrayGaps l_rank l_arrayInUse ++
        breakline ++ pShowRankAttr l_rank "stride" l_arrayInUse ++
        breakline ++ l_showPhysGrid ++
        breakline ++ pShowTimeLoopHeader l_t l_t_begin l_t_end ++
        breakline ++ l_spatial_loop_pHeader ++
        l_unfold_kernels ++
        breakline ++ l_spatial_loop_tail ++
        breakline ++ pAdjustTrape l_rank ++
        breakline ++ pShowTimeLoopTail ++
        breakline ++ l_tail ++ breakline ++ l_undef_mod_lu ++ breakline

pShowUnrollTimeTileOverlapKernels :: (PKernelFunc -> String) -> Bool -> PMode -> String -> PStencil -> PShape -> [[[Int]]] -> [[[PKernelFunc]]] -> String
pShowUnrollTimeTileOverlapKernels _ _ _ _ _ _ _ [] = ""
pShowUnrollTimeTileOverlapKernels l_showSingleKernel l_bound l_mode l_name l_stencil l_pShape l_tile_indices_by_t l_kfss_by_t@(k:ks) =
    let l_rank = sRank l_stencil
        l_arrayInUse = sArrayInUse l_stencil
        l_kernel_funcs = concat $ concat l_kfss_by_t
        l_iter = foldr union (kfIter $ pHead l_kernel_funcs) 
                             (map kfIter $ tail l_kernel_funcs)
        -- We are assuming that all kernel functions have the 
        -- same number of input parameters
        l_params = (kfParams . pHead) l_kernel_funcs
        l_spatial_params = tail l_params
        l_t = pHead l_params
        l_t_begin = l_t ++ "0"
        l_t_end = l_t ++ "1"
        l_kernelFuncName = pSys l_name
        l_showPhysGrid = "Grid_Info <" ++ show l_rank ++ "> l_phys_grid = " ++
                            sName l_stencil ++ ".get_phys_grid();"
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++
                   " = [&] (int " ++ l_t_begin ++ ", int " ++ l_t_end ++ ", " ++
                   " Grid_Info <" ++ show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel <" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++
                 shapeName l_pShape ++ " );"
        l_unfold_kernels = 
            pShowUnrollTimeTileOverlapKernelOnT 
                l_showSingleKernel l_bound l_mode l_stencil
                l_tile_indices_by_t l_kfss_by_t
        l_def_mod_lu = if l_bound then pDefPMODLU else ""
        l_undef_mod_lu = if l_bound then pUndefPMODLU else ""
        l_str_tile_indices_by_t = "/* " ++ show l_tile_indices_by_t ++ " */"
        l_str_kernel_funcs_by_t = "/* " ++ show (map (map (map kfName)) l_kfss_by_t) ++ " */"
    in  breakline ++ l_def_mod_lu ++
        breakline ++ l_str_tile_indices_by_t ++
        breakline ++ l_str_kernel_funcs_by_t ++
        breakline ++ l_pHeader ++
        breakline ++ "Grid_Info <" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayInfo l_arrayInUse ++ pShowArrayGaps l_rank l_arrayInUse ++
        breakline ++ pShowRankAttr l_rank "stride" l_arrayInUse ++
        breakline ++ l_showPhysGrid ++
        breakline ++ pShowTimeLoopHeader l_t l_t_begin l_t_end ++
        breakline ++ l_unfold_kernels ++
        breakline ++ pShowTimeLoopTail ++
        breakline ++ l_tail ++ breakline ++ l_undef_mod_lu ++ breakline

pShowUnrollTimeTileOverlapKernelOnT :: (PKernelFunc -> String) -> Bool -> PMode -> PStencil -> [[[Int]]] -> [[[PKernelFunc]]] -> String
pShowUnrollTimeTileOverlapKernelOnT _ _ _ _ [] _ = ""
pShowUnrollTimeTileOverlapKernelOnT l_showSingleKernel l_bound l_mode l_stencil l_tile_indices_by_t@(t:ts) l_kfss_by_t@(k:ks) =
    let l_rank = sRank l_stencil
        l_params = (kfParams . pHead . pHead) k
        l_t = pHead l_params
        l_spatial_params = tail l_params
        l_kfs = (concat . concat) l_kfss_by_t
        l_iter = foldr union (kfIter $ pHead l_kfs) (map kfIter $ tail l_kfs)
        l_adjust_T = if length ks > 0 then pAdjustT l_t ks else ""
        l_unfold_kernels = pShowUnrollTimeTileOverlapKernelLoops l_showSingleKernel t k
        l_spatial_loop_pHeader = 
            case l_mode of
                PUnrollTimeTileMacroOverlap ->
                            pShowMetaGridHeader l_bound l_spatial_params
                PUnrollTimeTileCPointerOverlap -> 
                            pShowMetaGridHeader False l_spatial_params
                PUnrollTimeTilePointerOverlap ->
                            pShowPointers l_iter ++ breakline ++
                            pShowPointerSet l_iter l_params ++ breakline ++
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
                PUnrollTimeTileOptPointerOverlap ->
                            pShowPointers l_iter ++ breakline ++
                            pShowOptPointerSet l_iter l_params ++ breakline ++
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
        l_spatial_loop_tail = 
            case l_mode of
                PUnrollTimeTileMacroOverlap ->
                            pShowMetaGridTail l_spatial_params
                PUnrollTimeTileCPointerOverlap ->
                            pShowMetaGridTail l_spatial_params
                PUnrollTimeTilePointerOverlap -> 
                            pShowObaseForTail l_rank
                PUnrollTimeTileOptPointerOverlap ->
                            pShowObaseForTail l_rank
    in  breakline ++ "{" ++
        breakline ++ l_spatial_loop_pHeader ++
        breakline ++ l_unfold_kernels ++
        breakline ++ l_spatial_loop_tail ++
        breakline ++ pAdjustTrape l_rank ++
        breakline ++ l_adjust_T ++
        breakline ++ "}" ++
        pShowUnrollTimeTileOverlapKernelOnT l_showSingleKernel l_bound l_mode l_stencil ts ks

pShowUnrollTimeTileOverlapKernelLoops :: (PKernelFunc -> String) -> [[Int]] -> [[PKernelFunc]] -> String
pShowUnrollTimeTileOverlapKernelLoops _ [] _ = ""
pShowUnrollTimeTileOverlapKernelLoops l_showSingleKernel l_tile_indices@(t:ts) l_kL@(k:ks) =
    let l_params = kfParams $ pHead k
        l_spatial_params = tail l_params
        l_rank = length l_spatial_params
        l_dim_sizes = getTileSizes l_tile_indices
        l_tile_index = pHead l_tile_indices
        l_guard_pHead = pShowTileGuardHeadOnSpatial l_spatial_params
                            (tail l_dim_sizes) (tail l_tile_index)
        l_guard_tail = pShowOverlapGuardTail k ks
        k' = pGroupBy eqTileOpPKernelFunc k
        l_unfold_kernels = pShowAllCondTileOverlapSingleKernel l_showSingleKernel k'
    in  breakline ++ l_guard_pHead ++
        breakline ++ l_unfold_kernels ++
        breakline ++ l_guard_tail ++
        pShowUnrollTimeTileOverlapKernelLoops l_showSingleKernel ts ks

pShowDefaultTileString :: PMode -> PStencil -> PGuard -> String
pShowDefaultTileString l_mode l_stencil l_guard = "" 

pShowUnrollTimeTileKernels :: (PKernelFunc -> String) -> Bool -> PMode -> String -> PStencil -> PShape -> [[[Int]]] -> [[PKernelFunc]] -> String
pShowUnrollTimeTileKernels l_showSingleKernel l_bound l_mode l_name l_stencil l_pShape l_tile_indices_group_by_t l_kfs_group_by_t = 
    let l_rank = sRank l_stencil
        l_kfs = concat l_kfs_group_by_t
        l_iter = foldr union (kfIter $ pHead l_kfs) (map kfIter $ tail l_kfs)
        l_arrayInUse = sArrayInUse l_stencil
        l_params = kfParams $ pHead l_kfs
        l_spatial_params = tail l_params
        l_t = pHead l_params
        l_t_begin = l_t ++ "0" 
        l_t_end = l_t ++ "1"
        l_kernelFuncName = pSys l_name
        l_showPhysGrid = "Grid_Info <" ++ show l_rank ++ "> l_phys_grid = " ++
                            sName l_stencil ++ ".get_phys_grid();"
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int " ++ l_t_begin ++ ", int " ++ l_t_end ++ ", " ++
                   "Grid_Info<" ++ show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );"
        l_unfold_kernels = pShowUnrollTimeTileKernelOnT 
                                l_showSingleKernel l_bound l_mode l_stencil 
                                l_tile_indices_group_by_t l_kfs_group_by_t 
        l_def_mod_lu = if l_bound then pDefPMODLU else ""
        l_undef_mod_lu = if l_bound then pUndefPMODLU else ""
    in  breakline ++ l_def_mod_lu ++
        breakline ++ l_pHeader ++ 
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayInfo l_arrayInUse ++ pShowArrayGaps l_rank l_arrayInUse ++ 
        breakline ++ pShowRankAttr l_rank "stride" l_arrayInUse ++ 
        breakline ++ l_showPhysGrid ++
        breakline ++ pShowTimeLoopHeader l_t l_t_begin l_t_end ++ 
        breakline ++ l_unfold_kernels ++
        breakline ++ pShowTimeLoopTail ++ 
        breakline ++ l_tail ++ breakline ++ l_undef_mod_lu ++ breakline
   
pShowUnrollTimeTileKernelOnT :: (PKernelFunc -> String) -> Bool -> PMode -> PStencil -> [[[Int]]] -> [[PKernelFunc]] -> String
pShowUnrollTimeTileKernelOnT _ _ _ _ [] _ = ""
pShowUnrollTimeTileKernelOnT l_showSingleKernel l_bound l_mode l_stencil l_tile_indices_group_by_t@(t:ts) l_kfs_group_by_t@(k:ks) =
    let l_rank = sRank l_stencil
        l_params = kfParams $ pHead k
        l_t = pHead l_params
        l_spatial_params = tail l_params
        l_kfs = concat l_kfs_group_by_t
        l_iter = foldr union (kfIter $ pHead l_kfs) (map kfIter $ tail l_kfs)
        l_adjust_T = if length ks > 0 then pAdjustT l_t ks else ""
        l_unfold_kernels = pShowUnrollTimeTileKernelLoops l_showSingleKernel t k
        l_spatial_loop_pHeader =
            case l_mode of
                PUnrollTimeTileMacro ->
                        pShowMetaGridHeader l_bound l_spatial_params
                PUnrollTimeTileCPointer -> 
                        pShowMetaGridHeader False l_spatial_params
                PUnrollTimeTilePointer -> 
                        pShowPointers l_iter ++ breakline ++ 
                        pShowPointerSet l_iter l_params ++ breakline ++ 
                        pShowPointerForHeader l_rank True l_iter l_spatial_params
                PUnrollTimeTileOptPointer -> 
                        pShowPointers l_iter ++ breakline ++ 
                        pShowOptPointerSet l_iter l_params ++ breakline ++ 
                        pShowPointerForHeader l_rank True l_iter l_spatial_params
        l_spatial_loop_tail =
            case l_mode of
                PUnrollTimeTileMacro ->
                        pShowMetaGridTail l_spatial_params
                PUnrollTimeTileCPointer -> 
                        pShowMetaGridTail l_spatial_params 
                PUnrollTimeTilePointer -> 
                        pShowObaseForTail l_rank 
                PUnrollTimeTileOptPointer -> 
                        pShowObaseForTail l_rank 
    in  breakline ++ "{" ++ 
        breakline ++ l_spatial_loop_pHeader ++
        breakline ++ l_unfold_kernels ++
        breakline ++ l_spatial_loop_tail ++ 
        breakline ++ pAdjustTrape l_rank ++ 
        breakline ++ l_adjust_T ++ 
        breakline ++ "}" ++
        pShowUnrollTimeTileKernelOnT l_showSingleKernel l_bound l_mode l_stencil ts ks

pShowUnrollTimeTileKernelLoops :: (PKernelFunc -> String) -> [[Int]] -> [PKernelFunc] -> String
pShowUnrollTimeTileKernelLoops _ [] _ = ""
pShowUnrollTimeTileKernelLoops l_showSingleKernel l_tile_indices@(t:ts) l_kfs@(k:ks) =
    let l_spatial_params = tail $ kfParams k
        l_dim_sizes = getTileSizes l_tile_indices
        l_tile_index = t
        l_guard_pHead = pShowTileGuardHeadOnSpatial l_spatial_params 
                            (tail l_dim_sizes) (tail l_tile_index)
        l_guard_tail = pShowOverlapGuardTail [k] [ks]
    in  breakline ++ l_guard_pHead ++ 
        breakline ++ l_showSingleKernel k ++ 
        breakline ++ l_guard_tail ++
        pShowUnrollTimeTileKernelLoops l_showSingleKernel ts ks 

pShowAllCondTileKernelLoops :: (PKernelFunc -> String) -> [[Int]] -> [PKernelFunc] -> String
pShowAllCondTileKernelLoops _ _ [] = ""
pShowAllCondTileKernelLoops l_showSingleKernel l_tile_indices@(t:ts) l_kfs@(k:ks) =
    let l_params = kfParams k
        l_spatial_params = tail $ kfParams k
        l_dim_sizes = getTileSizes l_tile_indices
        l_tile_index = pHead l_tile_indices
        l_guard_pHead = pShowTileGuardHeadOnAll l_params l_dim_sizes l_tile_index 
                                    (shapeTimeShift $ kfShape k)
        l_guard_tail = pShowOverlapGuardTail [k] [ks]
    in  breakline ++ l_guard_pHead ++ 
        breakline ++ l_showSingleKernel k ++ 
        breakline ++ l_guard_tail ++
        pShowAllCondTileKernelLoops l_showSingleKernel (tail l_tile_indices) ks
 
-- This function is used for interior region only!!
pShowAllCondTileKernels :: (PKernelFunc -> String) -> Bool -> PMode -> String -> PStencil -> PShape -> [[Int]] -> [PKernelFunc] -> String
pShowAllCondTileKernels l_showSingleKernel l_bound l_mode l_name l_stencil l_pShape l_tile_indices l_kfs@(k:ks) = 
    let l_rank = sRank l_stencil
        l_arrayInUse = sArrayInUse l_stencil
        l_iter = foldr union (kfIter k) (map kfIter ks)
        l_params = kfParams k
        l_spatial_params = tail l_params
        l_t = pHead l_params
        l_t_begin = l_t ++ "0" 
        l_t_end = l_t ++ "1" 
        l_kernelFuncName = pSys l_name
        l_showPhysGrid = "Grid_Info <" ++ show l_rank ++ "> l_phys_grid = " ++
                            sName l_stencil ++ ".get_phys_grid();" 
        l_pHeader = "/* KNOWN! */ auto " ++ l_kernelFuncName ++ 
                   " = [&] (int " ++ l_t_begin ++ ", int " ++ l_t_end ++ ", " ++
                   "Grid_Info<" ++ show l_rank ++ "> const & grid) {"
        l_tail = "};" ++ breakline ++ "Pochoir_Obase_Kernel<" ++ show l_rank ++
                 "> " ++ l_name ++ "( " ++ l_kernelFuncName ++ ", " ++ 
                 shapeName l_pShape ++ " );" ++ breakline 
        l_spatial_loop_pHeader =
            case l_mode of
                PAllCondTileMacro -> 
                            pShowMetaGridHeader l_bound l_spatial_params
                PAllCondTileCPointer -> 
                            pShowMetaGridHeader False l_spatial_params
                PAllCondTilePointer -> 
                            pShowPointers l_iter ++ breakline ++ 
                            pShowPointerSet l_iter l_params ++ breakline ++ 
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
                PAllCondTileOptPointer -> 
                            pShowPointers l_iter ++ breakline ++ 
                            pShowOptPointerSet l_iter l_params ++ breakline ++ 
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
                PUnrollTimeTileMacro -> 
                            pShowMetaGridHeader l_bound l_spatial_params
                PUnrollTimeTileCPointer -> 
                            pShowMetaGridHeader False l_spatial_params
                PUnrollTimeTilePointer -> 
                            pShowPointers l_iter ++ breakline ++ 
                            pShowPointerSet l_iter l_params ++ breakline ++ 
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
                PUnrollTimeTileOptPointer -> 
                            pShowPointers l_iter ++ breakline ++ 
                            pShowOptPointerSet l_iter l_params ++ breakline ++ 
                            pShowPointerForHeader l_rank True l_iter l_spatial_params
        l_spatial_loop_tail =
            case l_mode of
                PAllCondTileMacro ->
                            pShowMetaGridTail l_spatial_params
                PAllCondTileCPointer -> 
                            pShowMetaGridTail l_spatial_params 
                PAllCondTilePointer -> 
                            pShowObaseForTail l_rank 
                PAllCondTileOptPointer -> 
                            pShowObaseForTail l_rank 
                PUnrollTimeTileMacro ->
                            pShowMetaGridTail l_spatial_params
                PUnrollTimeTileCPointer -> 
                            pShowMetaGridTail l_spatial_params 
                PUnrollTimeTilePointer -> 
                            pShowObaseForTail l_rank 
                PUnrollTimeTileOptPointer -> 
                            pShowObaseForTail l_rank 
        l_unfold_kernels =
            pShowAllCondTileKernelLoops l_showSingleKernel
                l_tile_indices l_kfs
        l_def_mod_lu = if l_bound then pDefPMODLU else ""
        l_undef_mod_lu = if l_bound then pUndefPMODLU else ""
    in  breakline ++ l_def_mod_lu ++
        breakline ++ l_pHeader ++ 
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayInfo l_arrayInUse ++ pShowArrayGaps l_rank l_arrayInUse ++ 
        breakline ++ pShowRankAttr l_rank "stride" l_arrayInUse ++ 
        breakline ++ l_showPhysGrid ++
        breakline ++ pShowTimeLoopHeader l_t l_t_begin l_t_end ++ 
        breakline ++ l_spatial_loop_pHeader ++ 
        l_unfold_kernels ++
        breakline ++ l_spatial_loop_tail ++ 
        breakline ++ pAdjustTrape l_rank ++
        breakline ++ pShowTimeLoopTail ++ 
        breakline ++ l_tail ++ breakline ++ l_undef_mod_lu ++ breakline

{------------------------------------------------------------------------------------
 - end procedures for tile                                                          -
 ------------------------------------------------------------------------------------}
pShowCondMacroKernel :: Bool -> String -> Int -> Int -> [PKernelFunc] -> String
pShowCondMacroKernel _ _ _ _ [] = ""
pShowCondMacroKernel l_bound l_t l_resid l_unroll (l_kernel:l_kernels) =
    let l_params = tail $ kfParams l_kernel
        l_rank = length (kfParams l_kernel) - 1
        -- l_modOp = if l_unroll == 2 then " & " else " % "
        l_guard_pHead = if l_unroll > 1 
                          then pShowUnrollTGuardHead l_t l_resid l_unroll 
                                                    (shapeTimeShift $ kfShape l_kernel)
                          else ""
        l_guard_tail = if l_unroll > 1 then pShowUnrollGuardTail (length l_kernels) else ""
        l_adjust_T = if l_unroll > 1 then "" else pAdjustT l_t l_kernels
    in  breakline ++ l_guard_pHead ++ 
        breakline ++ pShowMetaGridHeader l_bound l_params ++
        breakline ++ show (kfStmt l_kernel) ++ 
        breakline ++ pShowMetaGridTail l_params ++ 
        breakline ++ pAdjustTrape l_rank ++ breakline ++ 
        breakline ++ l_adjust_T ++
        breakline ++ l_guard_tail ++
        pShowCondMacroKernel l_bound l_t (l_resid + 1) l_unroll l_kernels 

pAdjustT :: String -> [a] -> String
pAdjustT l_t l = if null l then "" else "++" ++ l_t ++ ";" 

-- l_bound == True : generate spatial loop pHeader for boundary clone
-- l_bound == False : generate spatial loop pHeader for interior clone
-- when it's for boundary clone, we have macro 'pmod_lu' which is to 
-- adjust the index for the home cell (the point on the left side of 
-- assignment operator) !!!
pShowMetaGridHeader :: Bool -> [String] -> String
pShowMetaGridHeader _ [] = ""
pShowMetaGridHeader l_bound pL@(p:ps) =
    let l_rank = show (length pL - 1)
        l_iter = if l_bound then "old_" ++ p else p
        l_start = "l_grid.x0[" ++ l_rank ++ "]"
        l_end = "l_grid.x1[" ++ l_rank ++ "]"
        l_new_iter = p
        l_phys_start = "l_phys_grid.x0[" ++ l_rank ++ "]"
        l_phys_end = "l_phys_grid.x1[" ++ l_rank ++ "]"
        l_adjust_iter = if l_bound 
                            then breakline ++ "int " ++ l_new_iter ++ 
                                 " = pmod_lu(" ++ l_iter ++ ", " ++ 
                                 l_phys_start ++ ", " ++ 
                                 l_phys_end ++ ");"
                            else ""
        l_showPragma = if length pL - 1 == 0 then pShowPragma else ""
    in  breakline ++ l_showPragma ++ 
        breakline ++ "for (int " ++ l_iter ++ " = " ++ l_start ++ "; " ++
        l_iter ++ " < " ++ l_end ++ "; ++" ++ l_iter ++ ") {" ++ l_adjust_iter ++
        pShowMetaGridHeader l_bound ps 

pShowMetaGridTail :: [String] -> String
pShowMetaGridTail [] = ""
pShowMetaGridTail pL@(p:ps) = "} " ++ pShowMetaGridTail ps
    
pShowObaseKernel :: String -> PKernelFunc -> String
pShowObaseKernel l_name l_kernel = 
    let l_rank = length (kfParams l_kernel) - 1
        l_iter = kfIter l_kernel
        l_array = unionArrayIter l_iter
        l_t = pHead $ kfParams l_kernel
        l_t_begin = l_t ++ "0"
        l_t_end = l_t ++ "1"
    in  breakline ++ "auto " ++ l_name ++ " = [&] (" ++
        "int t0, int t1, Grid_Info<" ++ show l_rank ++ "> const & grid) {" ++ 
        breakline ++ "Grid_Info<" ++ show l_rank ++ "> l_grid = grid;" ++
        pShowArrayGaps l_rank l_array ++
        breakline ++ pShowRankAttr l_rank "stride" l_array ++ breakline ++
        pShowTimeLoopHeader l_t l_t_begin l_t_end ++ breakline ++
        pShowIterSet l_iter (kfParams l_kernel)++
        breakline ++ pShowObaseForHeader l_rank l_iter (tail $ kfParams l_kernel) ++
        breakline ++ pShowObaseStmt l_kernel ++ breakline ++ pShowObaseForTail l_rank ++
        pAdjustTrape l_rank ++ breakline ++ pShowTimeLoopTail ++ breakline ++ "};\n"

-- we assume all Pochoir_Array associated with the same Pochoir object has the same size,
-- otherwise we will trigger an error at run-time!
pShowLocalGridForCopyOut :: Int -> String
pShowLocalGridForCopyOut l_rank =
    let l_offsets = pGenRankListEmpty l_rank 
        l_x0s = pShowXs 0 l_rank "" l_offsets ++ breakline
        l_x1s = pShowXs 1 l_rank "" l_offsets ++ breakline
    in  l_x0s ++ l_x1s

pGenRankListEmpty :: Int -> [String]
pGenRankListEmpty 1 = [""]
pGenRankListEmpty l_rank = "":pGenRankListEmpty (l_rank-1)

pShowLocalGridForCopyIn :: Int -> String
pShowLocalGridForCopyIn l_rank =
    let l_offsets = pGenRankList "l_dx_" l_rank
        l_x0s = pShowXs 0 l_rank " - " l_offsets ++ breakline
        l_x1s = pShowXs 1 l_rank " + " l_offsets ++ breakline
    in  l_x0s ++ l_x1s

pShowLocalGridForComp :: Int -> PArray -> String
pShowLocalGridForComp l_rank l_array =
    let l_a = aName l_array
        l_offsets = pGenRankList ("lc_" ++ l_a ++ "_begin_") l_rank
        l_x0s = pShowXs 0 l_rank " - " l_offsets ++ breakline
        l_x1s = pShowXs 1 l_rank " - " l_offsets ++ breakline
    in  l_x0s ++ l_x1s

pShowXs :: Int -> Int -> String -> [String] -> String
pShowXs l_end l_rank l_op l_offsets =
    let lc_xs = pGenRankListFull ("l_grid.x" ++ show l_end ++ "[") l_rank "]"
        l_xs = pGenRankListFull ("grid.x" ++ show l_end ++ "[") l_rank "]"
        l_rs = zipWith (pIns l_op) l_xs l_offsets
        l_rrs = map (flip (++) ";") l_rs
        -- l_r1s = zipWith (pIns " + ") l_r0s l_dx0s
    in  intercalate breakline $ zipWith (pIns " = ") lc_xs l_rrs

-- PName : list of kernel parameters
pShowPointerSetLocal :: [Iter] -> [PName] -> String
pShowPointerSetLocal [] _ = ""
pShowPointerSetLocal iL@(i:is) l_kernelParams = concatMap pShowPointerSetLocalTerm iL
    where pShowPointerSetLocalTerm (iterName, array, dim, rw) = 
            let l_arrayName = aName array
                l_rank = length l_kernelParams - 1
                l_arrayBaseName = "lc_" ++ l_arrayName
                l_arrayTotalSize = "lc_" ++ l_arrayName ++ "_total_size"
                l_arrayStrideList = pGenRankList ("lc_" ++ l_arrayName ++ "_stride_") l_rank 
                l_transDimList = tail $ pShowTransDim dim l_kernelParams
                -- l_begins = pGenRankList ("lc_" ++ l_arrayName ++ "_begin_") l_rank
                -- l_offsets = zipWith (pInsParens " - ") (map show l_transDimList) l_begins
                l_arraySpaceOffset = 
                    intercalate " + " $ zipWith (pIns " * ") (map show l_transDimList) l_arrayStrideList
                l_arrayTimeOffset = (pShowTimeOffset (aToggle array) (pHead dim)) ++ 
                                    " * " ++ l_arrayTotalSize
            in  breakline ++ iterName ++ " = " ++ l_arrayBaseName ++ " + " ++ 
                l_arrayTimeOffset ++ " + " ++ l_arraySpaceOffset ++ ";" 

pShowLocalCopyOut :: Int -> [PName] -> [PArray] -> [Iter] -> String
pShowLocalCopyOut l_rank l_kfParams l_arrays l_wrIters =
    let l_t = pHead l_kfParams
        l_t_begin = l_t ++ "0"
        l_t_end = l_t ++ "1"
    in "/* Copy Out */" ++ breakline ++ 
       pShowLocalGridForCopyOut l_rank ++ breakline ++
       pShowTimeLoopHeader l_t l_t_begin l_t_end ++ breakline ++
       (intercalate breakline $ map (pShowCopyInOutBase False l_rank $ pHead l_kfParams) l_wrIters) ++ breakline ++
       pShowCopyLoopHeader False l_rank (tail l_kfParams) l_arrays ++ breakline ++
       (intercalate breakline $ map (pShowCopyInOutBody False) l_arrays) ++ breakline ++
       pShowCopyLoopTail l_rank ++ breakline ++ pAdjustTrape l_rank ++ breakline ++ 
       pShowTimeLoopTail ++ breakline 

pShowLocalCopyIn :: Int -> [PName] -> [PArray] -> [Iter] -> String
pShowLocalCopyIn l_rank l_kfParams l_arrays l_rdIters =
    let l_t = pHead l_kfParams
        l_t_begin = l_t ++ "0"
        l_t_end = l_t ++ "1"
    in "/* Copy In */" ++ breakline ++ 
       pShowLocalGridForCopyIn l_rank ++ breakline ++
       pShowTimeLoopHeader l_t l_t_begin l_t_end ++ breakline ++
       (intercalate breakline $ map (pShowCopyInOutBase True l_rank $ pHead l_kfParams) l_rdIters) ++ breakline ++
       pShowCopyLoopHeader True l_rank (tail l_kfParams) l_arrays ++ breakline ++
       (intercalate breakline $ map (pShowCopyInOutBody True) l_arrays) ++ breakline ++
       pShowCopyLoopTail l_rank ++ breakline ++ pAdjustTrape l_rank ++ breakline ++
       pShowTimeLoopTail ++ breakline

pShowCopyInOutBody :: Bool -> PArray -> String
pShowCopyInOutBody l_inOut l_array =
    let l_a = aName l_array
        l_suffix = if l_inOut == True then "_in" else "_out"
        lc_iter = "lc_" ++ l_a ++ l_suffix ++ "[0]"
        l_iter = "l_" ++ l_a ++ l_suffix ++ "[0]"
    in  if l_inOut == True 
            then lc_iter ++ " = " ++ l_iter ++ ";"
            else l_iter ++ " = " ++ lc_iter ++ ";"

pShowCopyLoopHeader :: Bool -> Int -> [PName] -> [PArray] -> String
pShowCopyLoopHeader l_inOut 1 l_kSpatialParams l_arrays =
    let l_loopVar = pHead l_kSpatialParams
        lc_incGap = intercalate ", " $ map (pShowIncGap l_inOut "lc_" 1) l_arrays
        l_incGap = intercalate ", " $ map (pShowIncGap l_inOut "l_" 1) l_arrays
    in  "for (int " ++ 
        l_loopVar ++ " = l_grid.x0[" ++ show (1-1) ++ "]; " ++ 
        l_loopVar ++ " < l_grid.x1[" ++ show (1-1) ++ "]; ++" ++
        l_loopVar ++ ", " ++ breakline ++ lc_incGap ++ ", " ++ 
        breakline ++ l_incGap ++ ") {"
pShowCopyLoopHeader l_inOut l_rank l_kSpatialParams l_arrays =
    let lc_gaps = intercalate breakline $ map (pShowArrayGap "lc_" l_rank) l_arrays
        l_gaps = intercalate breakline $ map (pShowArrayGap "l_" l_rank) l_arrays
        l_loopVar = pHead l_kSpatialParams
        lc_incGap = intercalate ", " $ map (pShowIncGap l_inOut "lc_" l_rank) l_arrays
        l_incGap = intercalate ", " $ map (pShowIncGap l_inOut "l_" l_rank) l_arrays
    in  lc_gaps ++ breakline ++ l_gaps ++ breakline ++ "for (int " ++ 
        l_loopVar ++ " = l_grid.x0[" ++ show (l_rank-1) ++ "]; " ++ 
        l_loopVar ++ " < l_grid.x1[" ++ show (l_rank-1) ++ "]; ++" ++
        l_loopVar ++ ", " ++ breakline ++ lc_incGap ++ ", " ++ 
        breakline ++ l_incGap ++ ") {" ++
        breakline ++ pShowCopyLoopHeader l_inOut (l_rank-1) (tail l_kSpatialParams) l_arrays

pShowIncGap :: Bool -> String -> Int -> PArray -> String
pShowIncGap l_inOut pre 1 l_array =
    let l_a = aName l_array
        l_suffix = if l_inOut == True then "_in" else "_out"
        l_iter = pre ++ l_a ++ l_suffix
    in  "++" ++ l_iter
pShowIncGap l_inOut pre l_rank l_array =
    let l_a = aName l_array
        l_suffix = if l_inOut == True then "_in" else "_out"
        l_iter = pre ++ l_a ++ l_suffix
        l_gap = pre ++ "gap_" ++ l_a ++ "_" ++ show (l_rank-1)
    in  l_iter ++ " += " ++ l_gap

pShowArrayGap :: String -> Int -> PArray -> String
pShowArrayGap pre l_rank l_array =
    let l_a = aName l_array
        l_gap = pre ++ "gap_" ++ l_a ++ "_" ++ show (l_rank-1)
        l_stride = pre ++ l_a ++ "_stride_" ++ show (l_rank-1)
        l_pre_stride = pre ++ l_a ++ "_stride_" ++ show (l_rank-2)
        l_offset = "(l_grid.x0[" ++ show (l_rank-2) ++ "] - l_grid.x1[" ++ show (l_rank-2) ++ "])"
    in  "int " ++ l_gap ++ " = " ++ l_stride ++ " + " ++ l_offset ++ " * " ++ l_pre_stride ++ ";"

pShowCopyLoopTail :: Int -> String
pShowCopyLoopTail 1 = "}"
pShowCopyLoopTail l_rank = "}" ++ breakline ++ pShowCopyLoopTail (l_rank-1)

pShowCopyInOutBase :: Bool -> Int -> PName -> Iter -> String
pShowCopyInOutBase l_inOut l_rank l_t l_rwIter =
    let l_array = pIterArray l_rwIter 
        l_type = show (aType l_array) ++ " * "
        l_a = aName l_array
        lc_base = "lc_" ++ l_a
        l_base = l_a ++ "_base"
        l_suffix = if l_inOut == True then "_in" else "_out"
        l_t_dim = pHead $ pIterDims l_rwIter 
        lc_iter = "lc_" ++ l_a ++ l_suffix
        l_iter = "l_" ++ l_a ++ l_suffix
        l_toggle = aToggle l_array
        lc_total_size = "lc_" ++ l_a ++ "_total_size"
        l_total_size = "l_" ++ l_a ++ "_total_size"
        lc_strides = pGenRankList ("lc_" ++ l_a ++ "_stride_") l_rank
        l_strides = pGenRankList ("l_" ++ l_a ++ "_stride_") l_rank
        l_grid_begins = pGenRankListFull "l_grid.x0[" l_rank "]"
        lc_begins = pGenRankList ("lc_" ++ l_a ++ "_begin_") l_rank
        lc_grid_offsets = zipWith (pInsParens " - ") l_grid_begins lc_begins
        lc_offsets = zipWith (pIns " * ") lc_grid_offsets lc_strides
        lc_a_base = l_type ++ lc_iter ++ " = " ++ lc_base ++ " + " ++
                  (pShowTimeOffset l_toggle l_t_dim) ++
                  " * " ++ lc_total_size ++ " + " ++ 
                  intercalate " + " lc_offsets ++ ";" ++ breakline
        l_grid_offsets = zipWith (pIns " * ") l_grid_begins l_strides
        l_a_base = l_type ++ l_iter ++ " = " ++ l_base ++ " + " ++
                 (pShowTimeOffset l_toggle l_t_dim) ++
                 " * " ++ l_total_size ++ " + " ++
                 intercalate " + " l_grid_offsets ++ ";" ++ breakline
    in  lc_a_base ++ l_a_base

pShowTimeLoopHeader :: String -> String -> String -> String
pShowTimeLoopHeader l_t l_t_begin l_t_end =
    "for (int " ++ l_t ++ " = " ++ l_t_begin ++ "; " ++ 
    l_t ++ " < " ++ l_t_end ++ "; ++" ++ l_t ++ ") {"

pShowTimeLoopTail :: String
pShowTimeLoopTail = "} /* end for t */"

pShowCopyInLoop :: Int -> [PName] -> PArray -> String
pShowCopyInLoop l_rank l_kSpatialParams l_array =
    let l_forHead = pShowLocalForHeader l_rank l_kSpatialParams l_array
        l_forTail = pShowLocalForTail l_rank
        l_toggle = aToggle l_array
        l_body = pShowLocalCopyInBody l_toggle l_kSpatialParams l_array
    in  l_forHead ++ l_body ++ l_forTail

pShowLocalCopyInBody :: Int -> [PName] -> PArray -> String
pShowLocalCopyInBody 1 l_kSpatialParams l_array =
    let l_a = aName l_array
        l_rank = aRank l_array
        l_local_addr = "lc_" ++ l_a ++ "_in_" ++ show 0
        l_global_addr = "l_" ++ l_a ++ "_in_" ++ show 0
        l_local_offset = intercalate " + " $ zipWith (pIns " * ") l_kSpatialParams (pGenRankList ("lc_" ++ l_a ++ "_stride_") l_rank)
        l_global_offset = intercalate " + " $ zipWith (pIns " * ") l_kSpatialParams (pGenRankList ("l_" ++ l_a ++ "_stride_") l_rank)
    in  l_local_addr ++ "[" ++ l_local_offset ++ "] = " ++ l_global_addr ++ "[" ++ l_global_offset ++ "];" ++ breakline
pShowLocalCopyInBody l_toggle l_kSpatialParams l_array =
    let l_a = aName l_array
        l_rank = aRank l_array
        l_local_addr = "lc_" ++ l_a ++ "_in_" ++ show (l_toggle-1)
        l_global_addr = "l_" ++ l_a ++ "_in_" ++ show (l_toggle-1)
        l_local_offset = intercalate " + " $ zipWith (pIns " * ") l_kSpatialParams (pGenRankList ("lc_" ++ l_a ++ "_stride_") l_rank)
        l_global_offset = intercalate " + " $ zipWith (pIns " * ") l_kSpatialParams (pGenRankList ("l_" ++ l_a ++ "_stride_") l_rank)
    in  l_local_addr ++ "[" ++ l_local_offset ++ "] = " ++ l_global_addr ++ "[" ++ l_global_offset ++ "];" ++ breakline ++ pShowLocalCopyInBody (l_toggle-1) l_kSpatialParams l_array

pIns :: String -> String -> String -> String
pIns mid a b = a ++ mid ++ b

pInsParens :: String -> String -> String -> String
pInsParens mid a b = "(" ++ a ++ mid ++ b ++ ")"

pGenRankList :: String -> Int -> [String]
pGenRankList pre 1 = [pre ++ show 0]
pGenRankList pre l_rank = [pre ++ show (l_rank-1)] ++ pGenRankList pre (l_rank-1)

pGenRankListFull :: String -> Int -> String -> [String]
pGenRankListFull pre 1 suf = [pre ++ show 0 ++ suf]
pGenRankListFull pre l_rank suf = [pre ++ show (l_rank-1) ++ suf] ++ 
                                  pGenRankListFull pre (l_rank-1) suf

pShowLocalForHeader :: Int -> [PName] -> PArray -> String
pShowLocalForHeader 1 l_kSpatialParams l_array =
    let l_loopVar = pHead l_kSpatialParams
        l_begin = show 0
        l_end = "lc_" ++ aName l_array ++ "_size_" ++ show 0
    in  "for (int " ++ l_loopVar ++ " = " ++ l_begin ++ "; " ++ 
        l_loopVar ++ " < " ++ l_end ++ "; " ++ "++" ++ l_loopVar ++ ") {" ++ 
        breakline
pShowLocalForHeader n l_kSpatialParams l_array =
    let l_loopVar = pHead l_kSpatialParams
        l_begin = show 0 
        l_end = "lc_" ++ aName l_array ++ "_size_" ++ show (n-1)
    in  "for (int " ++ l_loopVar ++ " = " ++ l_begin ++ "; " ++ 
        l_loopVar ++ " < " ++ l_end ++ "; " ++ "++" ++ l_loopVar ++ ") {" ++ 
        breakline ++ pShowLocalForHeader (n-1) (tail l_kSpatialParams) l_array

pShowLocalForTail :: Int -> String
pShowLocalForTail 1 = "}"
pShowLocalForTail n = "}" ++ pShowLocalForTail (n-1) 

pShowDeltaT :: String
pShowDeltaT = "const int lt = t1 - t0;"

pFreeHeap :: [PArray] -> String
pFreeHeap l_arrays = concatMap pFreeHeapItem l_arrays
    where pFreeHeapItem l_array =
            let l_a = aName l_array
                l_cache = "lc_" ++ l_a
            in  "free(" ++ l_cache ++ ");" ++ breakline

pAllocHeap :: [PArray] -> String
pAllocHeap l_arrays = concatMap pAllocHeapItem l_arrays
    where pAllocHeapItem l_array = 
            let l_type = show (aType l_array) 
                l_a = aName l_array
                l_size = " 2 * 120 * 120 "
                l_cache = " lc_" ++ l_a
            in  l_type ++ " *" ++ l_cache ++ " = new " ++ 
                l_type ++ " [" ++ l_size ++ "];" ++ breakline

pFreeStack :: [PArray] -> String
pFreeStack l_arrays = ""

pAllocStack :: [PArray] -> String
pAllocStack l_arrays = concatMap pAllocStackItem l_arrays
    where pAllocStackItem l_array = 
            let l_type = show (aType l_array) 
                l_a = aName l_array
                l_toggle = aToggle l_array
                l_size = show l_toggle ++ " * 120 * 120"
                l_cache = " lc_" ++ l_a
            in  l_type ++ l_cache ++ " [ " ++ l_size ++ " ];" ++ breakline

pShowLocalCacheAttr :: Int -> [PArray] -> PStencil -> String
pShowLocalCacheAttr l_rank l_arrays l_stencil = 
    pShowColor l_rank ++ breakline ++ 
    pShowSlopes l_rank l_stencil ++ breakline ++ 
    (intercalate breakline $ map (pShowEndIndex l_rank 0) l_arrays) ++ breakline ++ 
    (intercalate breakline $ map (pShowEndIndex l_rank 1) l_arrays) ++ breakline ++
    (intercalate breakline $ map (pShowLocalArraySize l_rank) l_arrays) ++ breakline ++
    (intercalate breakline $ map (pShowLocalStride l_rank) l_arrays) ++ breakline ++
    (intercalate breakline $ map (pShowLocalTotalSize l_rank) l_arrays) ++ breakline 

pShowLocalTotalSize :: Int -> PArray -> String
pShowLocalTotalSize  l_rank l_array =
    let l_a = aName l_array
        l_var = "lc_" ++ l_a ++ "_total_size" 
        l_total_size = pShowSizeSum "lc" l_rank l_array
    in  "const int " ++ l_var ++ " = " ++ l_total_size ++ ";"

pShowLocalStride :: Int -> PArray -> String
pShowLocalStride l_rank l_array = 
    "const int " ++ pShowLocalStrideTerm l_rank l_array

pShowLocalStrideTerm :: Int -> PArray -> String
pShowLocalStrideTerm 1 l_array = 
    let l_a = aName l_array
        l_dim = show 0
        l_strideName = "lc_" ++ l_a ++ "_stride_" ++ l_dim
        l_size = show 1
    in  l_strideName ++ " = " ++ l_size ++ ";"
pShowLocalStrideTerm n l_array =
    let l_a = aName l_array
        l_dim = show (n-1)
        l_strideName = "lc_" ++ l_a ++ "_stride_" ++ l_dim
        l_size = pShowSizeSum "lc" (n-1) l_array
    in  l_strideName ++ " = " ++ l_size ++ ", " ++ pShowLocalStrideTerm (n-1) l_array

pShowSizeSum :: String -> Int -> PArray -> String
pShowSizeSum pre 1 l_array =
    let l_a = aName l_array
        l_dim = show 0
        l_size = pre ++ "_" ++ l_a ++ "_size_" ++ l_dim
    in  l_size 
pShowSizeSum pre n l_array =
    let l_a = aName l_array
        l_dim = show (n-1) 
        l_size = pre ++ "_" ++ l_a ++ "_size_" ++ l_dim
    in  l_size ++ " * " ++ pShowSizeSum pre (n-1) l_array 

pShowLocalArraySize :: Int -> PArray -> String
pShowLocalArraySize 1 l_array =
    let l_a = aName l_array
        l_dim = show 0
        l_var = "lc_" ++ l_a ++ "_size_" ++ l_dim
        l_end = "lc_" ++ l_a ++ "_end_" ++ l_dim
        l_begin = "lc_" ++ l_a ++ "_begin_" ++ l_dim
    in  "const int " ++ l_var ++ " = " ++ l_end ++ " - " ++ l_begin ++ " + 1;"
pShowLocalArraySize n l_array =
    let l_a = aName l_array
        l_dim = show (n-1) 
        l_var = "lc_" ++ l_a ++ "_size_" ++ l_dim
        l_end = "lc_" ++ l_a ++ "_end_" ++ l_dim
        l_begin = "lc_" ++ l_a ++ "_begin_" ++ l_dim
    in  "const int " ++ l_var ++ " = " ++ l_end ++ " - " ++ l_begin ++ " + 1;" ++ 
        breakline ++ pShowLocalArraySize (n-1) l_array

pShowSlopes :: Int -> PStencil -> String
pShowSlopes l_rank l_stencil = 
    let l_dxs = pGenRankList "const int l_dx_" l_rank
        l_slopes = pGenRankListFull ((sName l_stencil) ++ ".slope(") l_rank ")"
        l_rs = map (flip (++) ";")  l_slopes
    in  intercalate breakline $ zipWith (pIns " = ") l_dxs l_rs

pShowColor :: Int -> String
pShowColor 1 = "const bool black_0 = (grid.dx0[0] >= 0 & grid.dx1[0] <= 0);"
pShowColor n = 
    let l_dim = show (n - 1)
        l_begin_slope = "grid.dx0[" ++ l_dim ++ "]"
        l_end_slope = "grid.dx1[" ++ l_dim ++ "]"
        l_var = "black_" ++ l_dim
    in  "const bool " ++ l_var ++ " = (" ++ l_begin_slope ++ " >= 0 & " ++
        l_end_slope ++ " <= 0);" ++ breakline ++ pShowColor (n-1)

pShowEndIndex :: Int -> Int -> PArray -> String
pShowEndIndex l_rank l_end l_array =
    let l_a = aName l_array
        l_endVar = if l_end == 0 then "_begin_" else "_end_"
        l_type = "const int "
        l_lvalues = pGenRankList ("lc_" ++ l_a ++ l_endVar) l_rank
        l_lefts = map ((++) l_type) l_lvalues
        l_blacks = pGenRankList "black_" l_rank
        l_slopes = pGenRankList "l_dx_" l_rank
        l_grid_xs = if l_end == 0 
                        then pGenRankListFull "grid.x0[" l_rank "]"
                        else pGenRankListFull "grid.x1[" l_rank "]"
        l_grid_dxs = if l_end == 0
                        then pGenRankListFull "grid.dx0[" l_rank "]"
                        else pGenRankListFull "grid.dx1[" l_rank "]"
        l_glue = if l_end == 0 then " - " else " + "
        l_r1s = zipWith (pIns l_glue) l_grid_xs l_slopes
        l_r20s = map (flip (++) " * lt") l_grid_dxs
        l_r21s = zipWith (pIns l_glue) l_r20s l_slopes
        l_r2s = zipWith (pIns " + ") l_grid_xs l_r21s
        l_rr0s = zipWith (pIns " ? ") l_blacks l_r1s
        l_rr1s = zipWith (pIns " : ") l_rr0s l_r2s
        l_rights = map (flip (++) ";") l_rr1s
    in  intercalate breakline $ zipWith (pIns " = ") l_lefts l_rights

pShowMacroStmt :: Bool -> PKernelFunc -> String
pShowMacroStmt l_bound l_kernel =
    let l_params = kfParams l_kernel
        l_iter = kfIter l_kernel
        l_arrayInUse = unionArrayIter l_iter
        l_def_macro = if l_bound 
                         then pDefMacroArrayInUse "boundary" l_arrayInUse l_params 
                         else pDefMacroArrayInUse "interior" l_arrayInUse l_params
        l_undef_macro = pUndefMacroArrayInUse l_arrayInUse l_params
    in  breakline ++ l_def_macro ++
        breakline ++ (show . kfStmt) l_kernel ++
        breakline ++ l_undef_macro

pShowCPointerStmt :: PKernelFunc -> String
pShowCPointerStmt l_kernel = 
    let l_params = kfParams l_kernel
        l_spatial_params = tail l_params
        l_iter = kfIter l_kernel
        l_arrayInUse = unionArrayIter l_iter
        oldStmts = kfStmt l_kernel
        obaseStmts = transStmts oldStmts $ transCPointer l_iter
    in  breakline ++ pShowRefMacro l_params l_arrayInUse ++
        breakline ++ show obaseStmts ++
        breakline ++ pShowRefUnMacro l_arrayInUse

transCPointer :: [Iter] -> Expr -> Expr
transCPointer l_iters (PVAR q v dL) =
    case pIterLookup (v, dL) l_iters of
        Nothing -> PVAR q v dL
        Just iterName -> VAR q $ pRef v dL
transCPointer l_iters e = e

pRef :: PName -> [DimExpr] -> String
pRef a dL = "ref_" ++ a ++ "(" ++ (intercalate ", " $ map show dL) ++ ")"

pShowRawForHeader :: [PName] -> String
pShowRawForHeader [] = ""
pShowRawForHeader pL@(p:ps) = 
    let len_pL = length pL
        idx = p
        l_rank = len_pL-1
        l_pragma = if l_rank == 0 then pShowPragma else ""
    in  l_pragma ++ 
        breakline ++ "for (int " ++ idx ++ " = l_grid.x0[" ++ show l_rank ++
        "]; " ++ idx ++ " < l_grid.x1[" ++ show l_rank ++ "]; ++" ++ idx ++ ") {" ++
        pShowRawForHeader ps 
 
pShowPragma :: String
pShowPragma = breakline ++ "#pragma ivdep"
-- pShowPragma = "#pragma ivdep" ++ breakline ++ "#pragma simd"

pShowRefUnMacro :: [PArray] -> String
pShowRefUnMacro [] = ""
pShowRefUnMacro (a:as) = 
    let l_name = aName a
    in  "#undef ref_" ++ l_name ++ breakline ++ breakline

pShowRefMacro :: [PName] -> [PArray] -> String
pShowRefMacro _ [] = ""
pShowRefMacro l_kernelParams aL@(a:as) =
    let l_name = aName a
        l_t = pHead l_kernelParams
        l_dims = tail l_kernelParams
        l_toggle = aToggle a
        l_rank = aRank a
    in  "#define ref_" ++ l_name ++ "(" ++ pShowKernelParams l_kernelParams ++
        ") " ++ l_name ++ "_base[" ++ pShowTimeOffset l_toggle (DimVAR l_t) ++
        " * l_" ++ l_name ++ "_total_size + " ++ 
        (intercalate " + " $ zipWith pMul l_dims $ pGenRankList ("l_" ++ l_name ++ "_stride_") l_rank) ++ "]" ++
        breakline ++ breakline ++ pShowRefMacro l_kernelParams as

pMul :: String -> String -> String
pMul a b = "(" ++ a ++ ") * " ++ b

pShowArrayInfo :: [PArray] -> String
pShowArrayInfo [] = ""
pShowArrayInfo arrayInUse = foldr pShowArrayInfoItem "" arrayInUse
    where pShowArrayInfoItem l_arrayItem str =
            let l_type = aType l_arrayItem
                l_a = aName l_arrayItem
            in  str ++ breakline ++ show l_type ++ " * " ++ l_a ++ "_base"  ++ 
                " = " ++ l_a ++ ".data();" ++ breakline ++
                "const int " ++ "l_" ++ l_a ++ "_total_size = " ++ l_a ++
                ".total_size();" ++ breakline

pShowRankAttr :: Int -> String -> [PArray] -> String
pShowRankAttr n _ [] = ""
pShowRankAttr n attr aL@(a:as) = "const int " ++ getAttrs n aL ++ ";\n"
    where getAttrs n aL@(a:as) = intercalate ", " $ concatMap (getAttr n) aL
          getAttr 1 a = let r = 0 
                        in  ["l_" ++ (aName a) ++ "_" ++ attr ++ "_" ++ 
                             show r ++ " = " ++ (aName a) ++ "." ++ attr ++ 
                             "(" ++ show r ++ ")"]
          getAttr n a = let r = n-1
                        in  ["l_" ++ (aName a) ++ "_" ++ attr ++ "_" ++ 
                             show r ++ " = " ++ (aName a) ++ "." ++ attr ++
                             "(" ++ show r ++ ")"] ++ getAttr (n-1) a

pShowPointers :: [Iter] -> String
pShowPointers [] = ""
pShowPointers iL@(i:is) = foldr pShowPointer "" iL
    where pShowPointer (nameIter, arrayInUse, dL, rw) str =
                str ++ breakline ++ (show $ aType arrayInUse) ++ " * " ++ nameIter ++ ";"

pShowPointerStmt :: Bool -> PKernelFunc -> String
pShowPointerStmt global l_kernel = 
    let oldStmts = kfStmt l_kernel
        l_iter = kfIter l_kernel
        obaseStmts = transStmts oldStmts $ transPointer global l_iter
    in show obaseStmts

pShowObaseStmt :: PKernelFunc -> String
pShowObaseStmt l_kernel = 
    let oldStmts = kfStmt l_kernel
        l_iter = kfIter l_kernel
        obaseStmts = transStmts oldStmts $ transIter l_iter
    in show obaseStmts

pShowOptPointerStmt :: PKernelFunc -> String
pShowOptPointerStmt l_kernel = 
    let oldStmts = kfStmt l_kernel
        l_iter = kfIter l_kernel
        obaseStmts = transStmts oldStmts $ transOptPointer l_iter
    in  show obaseStmts

transOptPointer :: [Iter] -> Expr -> Expr
transOptPointer l_iters (PVAR q v dL) =
    case pIterLookup (v, dL) l_iters of
        Nothing -> PVAR q v dL
        Just iterName -> VAR q $ "(*" ++ iterName ++ ")"
transOptPointer l_iters e = e

-- convert the input parameters in all stmts to new, 
-- uniform version aligned only to the length of the kernel params
transKernelParams :: [String] -> Int -> Int -> Expr -> Expr
transKernelParams l_params idx l_len_params (PVAR q v dL) = 
    let dL' = transKernelParamsItem l_params idx l_len_params dL
    in  (PVAR q v dL')
transKernelParams _ _ _ e = e

transKernelParamsItem :: [String] -> Int -> Int -> [DimExpr] -> [DimExpr]
transKernelParamsItem _ _ _ [] = []
transKernelParamsItem [] _ _ dL = dL
transKernelParamsItem l_params@(p:ps) idx l_len_params dL@(d:ds) = 
    [(transKernelParamsItemTerm p idx l_len_params d)] ++ 
    (transKernelParamsItem ps (idx+1) l_len_params ds)
   
transKernelParamsItemTerm :: String -> Int -> Int -> DimExpr -> DimExpr
transKernelParamsItemTerm p idx len (DimVAR i) =
    if p == i then if idx == 0 then DimVAR "t" else DimVAR ("i" ++ show (len - idx))
              else DimVAR i
transKernelParamsItemTerm p idx len (DimDuo bop i j) = 
    DimDuo bop 
        (transKernelParamsItemTerm p idx len i) 
        (transKernelParamsItemTerm p idx len j)
transKernelParamsItemTerm p idx len (DimParen d) = 
    DimParen (transKernelParamsItemTerm p idx len d)
transKernelParamsItemTerm p idx len (DimINT n) = DimINT n

transPointer :: Bool -> [Iter] -> Expr -> Expr
transPointer global l_iters (PVAR q v dL) =
    let pre = if global == True then "l_" else "lc_"
    in  case pPointerLookup (v, dL) l_iters of
            Nothing -> PVAR q v dL
            Just (iterName, arrayInUse, des, rw) -> 
                BVAR iterName de
                    where de = simplifyDimExpr naive_de
                          naive_de = foldr plusCombDimExpr x $ zipWith mulDimExpr strideL $ tail $ excludeDimExpr dL des 
                          strideL = pGenRankList (pre ++ aName arrayInUse ++ "_stride_") (aRank arrayInUse) 
                          x = (DimINT 0)
transPointer _ _ e = e

plusCombDimExpr :: DimExpr -> DimExpr -> DimExpr
plusCombDimExpr e1 e2 = DimDuo "+" e1 e2

mulDimExpr :: String -> DimExpr -> DimExpr
mulDimExpr stride dim = DimDuo "*" (DimVAR stride) dim

excludeDimExpr :: [DimExpr] -> [DimExpr] -> [DimExpr]
excludeDimExpr dL [] = dL
excludeDimExpr [] _ = []
excludeDimExpr (d:ds) (r:rs) = (excludeDimExprItem d r):(excludeDimExpr ds rs)
    where excludeDimExprItem (DimVAR v) r = if (DimVAR v) == r then DimINT 0 else (DimVAR v)
          excludeDimExprItem (DimDuo bop e1 e2) r 
            | (DimDuo bop e1 e2) == r = DimINT 0
            | e1 == r = DimParen (DimDuo bop (DimINT 0) e2)
            | e2 == r = DimParen (DimDuo bop e1 (DimINT 0))
            | otherwise = (DimDuo bop (excludeDimExprItem e1 r) (excludeDimExprItem e2 r))
          excludeDimExprItem (DimINT n) r = if (DimINT n) == r then DimINT 0 else (DimINT n)
          excludeDimExprItem (DimParen e) r 
            | (DimParen e) == r = DimINT 0
            | e == r = DimINT 0
            | otherwise = DimParen (excludeDimExprItem e r)

pPointerLookup :: (PName, [DimExpr]) -> [Iter] -> Maybe Iter
pPointerLookup (v, dL) [] = Nothing
pPointerLookup (v, dL) ((iterName, arrayInUse, dL', rw):is)
    | v == aName arrayInUse && pHead dL == pHead dL' = Just (iterName, arrayInUse, dL', rw)
    | otherwise = pPointerLookup (v, dL) is

transIter :: [Iter] -> Expr -> Expr
transIter l_iters (PVAR q v dL) =
    case pIterLookup (v, dL) l_iters of
        Nothing -> PVAR q v dL
        Just iterName -> VAR q iterName
transIter l_iters e = e

pShowIterSet :: [Iter] -> [PName] -> String
pShowIterSet iL@(i:is) l_kernelParams = concat $ map pShowIterSetTerm iL
    where pShowIterSetTerm (name, array, dim, rw) = 
            breakline ++ name ++ ".set(" ++ show (pShowTransDim dim l_kernelParams) ++ ");" 
            --
-- PName : list of kernel parameters
pShowOptPointerSet :: [Iter] -> [PName] -> String
pShowOptPointerSet [] _ = ""
pShowOptPointerSet iL@(i:is) l_kernelParams = 
    let baseIters = transIterN 0 $ getBaseIter l_kernelParams iL
    in  pShowPointers baseIters ++ (concat $ map pShowOptPointerSetTerm baseIters) ++ pShowNonBaseIters baseIters iL
        where pShowOptPointerSetTerm (iterName, array, dim, rw) = 
                let l_arrayName = aName array
                    l_arrayBaseName = l_arrayName ++ "_base"
                    l_arrayTotalSize = "l_" ++ l_arrayName ++ "_total_size"
                    l_arrayStrideList = 
                        pGenRankList ("l_" ++ l_arrayName ++ "_stride_") (length l_kernelParams - 1)
                    l_transDimList = tail $ pShowTransDim dim l_kernelParams
                    l_arraySpaceOffset = 
                        intercalate " + " $ zipWith pCombineDim l_transDimList l_arrayStrideList
                    l_arrayTimeOffset = (pShowTimeOffset (aToggle array) (pHead dim)) ++ 
                                        " * " ++ l_arrayTotalSize
                in  breakline ++ iterName ++ " = " ++ l_arrayBaseName ++ " + " ++ 
                    l_arrayTimeOffset ++ " + " ++ l_arraySpaceOffset ++ ";" 

pShowNonBaseIters :: [Iter] -> [Iter] -> String
pShowNonBaseIters _ [] = ""
pShowNonBaseIters bL iL@(i:is) = pShowShiftFromBase i bL ++ pShowNonBaseIters bL is
    where pShowShiftFromBase _ [] = "/* NO baseIter found! */"
          pShowShiftFromBase (iName, iArray, iDims, iRW) ((bName, bArray, bDims, bRW):bs)
            | iArray == bArray && pHead iDims == pHead bDims =
                let l_arrayName = aName iArray
                    l_arrayStrideList =
                        pGenRankList ("l_" ++ l_arrayName ++ "_stride_") (length iDims - 1) 
                    l_transDimList = map simplifyDimExpr $ zipWith excludeBaseDim (tail iDims) (tail bDims)
                    l_arraySpaceOffset = 
                        intercalate " + " $ zipWith pCombineDim l_transDimList l_arrayStrideList
                in  breakline ++ iName ++ " = "  ++ bName ++ " + " ++ l_arraySpaceOffset ++ ";"
            | otherwise = pShowShiftFromBase (iName, iArray, iDims, iRW) bs

excludeBaseDim :: DimExpr -> DimExpr -> DimExpr
excludeBaseDim (DimVAR i) b 
    | DimVAR i == b = (DimINT 0)
    | otherwise = DimVAR i
excludeBaseDim (DimINT n) b
    | DimINT n == b = (DimINT 0)
    | otherwise = DimINT n
excludeBaseDim (DimDuo bop e1 e2) b = 
    DimDuo bop (excludeBaseDim e1 b) (excludeBaseDim e2 b)
excludeBaseDim (DimParen e) b = DimParen (excludeBaseDim e b)

-- PName : list of kernel parameters
pShowPointerSet :: [Iter] -> [PName] -> String
pShowPointerSet [] _ = ""
pShowPointerSet iL@(i:is) l_kernelParams = concatMap pShowPointerSetTerm iL
    where pShowPointerSetTerm (iterName, array, dim, rw) = 
            let l_arrayName = aName array
                l_arrayBaseName = l_arrayName ++ "_base"
                l_arrayTotalSize = "l_" ++ l_arrayName ++ "_total_size"
                l_arrayStrideList = 
                    pGenRankList ("l_" ++ l_arrayName ++ "_stride_") (length l_kernelParams - 1) 
                l_transDimList = tail $ pShowTransDim dim l_kernelParams
                l_arraySpaceOffset = 
                    intercalate " + " $ zipWith pCombineDim l_transDimList l_arrayStrideList
                l_arrayTimeOffset = (pShowTimeOffset (aToggle array) (pHead dim)) ++ 
                                    " * " ++ l_arrayTotalSize
            in  breakline ++ iterName ++ " = " ++ l_arrayBaseName ++ " + " ++ 
                l_arrayTimeOffset ++ " + " ++ l_arraySpaceOffset ++ ";" 

pShowTimeOffset :: Int -> DimExpr -> String
pShowTimeOffset toggle tDim 
    | toggle == 2 = "((" ++ show tDim ++ ")" ++ " & 0x1" ++ ")"
    | toggle == 4 = "((" ++ show tDim ++ ")" ++ " & 0x11" ++ ")"
    | otherwise = "((" ++ show tDim ++ ") % " ++ show toggle ++ ")"

pCombineDim :: DimExpr -> String -> String
-- l_stride_pa_0 may NOT necessary be "1", 
-- plus that we have already set all strides to be of type "const int"
pCombineDim de stride = "(" ++ show de ++ ") * " ++ stride

pShowTransDim :: [DimExpr] -> [PName] -> [DimExpr]
pShowTransDim (d:ds) (p:ps) = 
    let l_rank = length ds
    in  (d:(pTransDim 1 l_rank ds ps))

pTransDim :: Int -> Int -> [DimExpr] -> [PName] -> [DimExpr]
pTransDim n r [] _ = []
pTransDim n r dL@(d:ds) pL@(p:ps) = pTransDimTerm n r d p : pTransDim (n+1) r ds ps
    where pTransDimTerm n r (DimVAR v) p
              | v == p = DimVAR ("l_grid.x0[" ++ show (r-n) ++ "]")
              | otherwise = DimVAR v
          pTransDimTerm n r (DimINT i) p = DimINT i
          pTransDimTerm n r (DimDuo bop e1 e2) p = 
              DimDuo bop (pTransDimTerm n r e1 p) (pTransDimTerm n r e2 p)
        
{-
pShowIters :: [Iter] -> String
pShowIters [] = ""
pShowIters ((l_name, l_array, l_dim, l_rw):is) = 
    let l_type = aType l_array
        l_rank = aRank l_array
        l_toggle = aToggle l_array
        l_arrayName = aName l_array
    in breakline ++ "Pochoir_Iterator<" ++ show l_type ++ ", " ++ show l_rank ++ 
       ", " ++ show l_toggle ++ "> " ++
       l_name ++ "(" ++ l_arrayName ++ ");" ++ pShowIters is   
-}

unionArrayIter :: [Iter] -> [PArray]
unionArrayIter [] = []
unionArrayIter iL@(i:is) = union (getArrayItem i) (unionArrayIter is)
    where getArrayItem (_, a, _, _) = [a]

getArrayIter :: [Iter] -> [PName]
getArrayIter [] = []
getArrayIter iL@(i:is) = (getArrayItem i) ++ (getArrayIter is)
    where getArrayItem (_, a, _, _) = [aName a]

pShowObaseForTail :: Int -> String
pShowObaseForTail n 
    | n == 0 = "/* end for (sub-trapezoid) */ "
    | otherwise = "} " ++ pShowObaseForTail (n-1)

{-
pAdjustTrape :: Int -> String
pAdjustTrape l_rank = 
    breakline ++ "/* Adjust sub-trapezoid! */" ++
    breakline ++ "for (int i = 0; i < " ++ show l_rank ++ "; ++i) {" ++ 
    breakline ++ "\tl_grid.x0[i] += l_grid.dx0[i]; l_grid.x1[i] += l_grid.dx1[i];" ++
    breakline ++ "}" 
-}

pAdjustTrape :: Int -> String
pAdjustTrape l_rank =
    let l_x0s = pGenRankListFull "l_grid.x0[" l_rank "]"
        l_x1s = pGenRankListFull "l_grid.x1[" l_rank "]"
        l_dx0s = pGenRankListFull " += l_grid.dx0[" l_rank "];"
        l_dx1s = pGenRankListFull " += l_grid.dx1[" l_rank "];"
    in  breakline ++ "/* Adjust sub-trapezoid! */" ++
        breakline ++ (intercalate breakline $ zipWith (++) l_x0s l_dx0s) ++ 
        breakline ++ (intercalate breakline $ zipWith (++) l_x1s l_dx1s)

-- pL is the parameter list of original user supplied computing kernel
pShowObaseForHeader :: Int -> [Iter] -> [PName] -> String
pShowObaseForHeader _ _ [] = ""
pShowObaseForHeader 1 iL pL = 
                           breakline ++ pShowForHeader 0 True (unionArrayIter iL) pL ++ 
                           pShowIterComma iL ++
                           breakline ++ intercalate (", " ++ breakline) 
                                        (map ((++) "++" . getIterName) iL) ++ ") {"
pShowObaseForHeader n iL pL = 
                           breakline ++ pShowForHeader (n-1) True (unionArrayIter iL) pL ++ 
                           pShowIterComma iL ++
                           breakline ++ intercalate (", " ++ breakline) 
                                     (zipWith wrapIterInc
                                        (map (getArrayGap (n-1)) (getArrayIter iL))
                                        (map getIterName iL)) ++ 
                           ") {" ++ pShowObaseForHeader (n-1) iL pL
    where wrapIterInc gap iter = iter ++ ".inc(" ++ gap ++ ")"

-- pL is the parameter list of original user supplied computing kernel
pShowPointerForHeader :: Int -> Bool -> [Iter] -> [PName] -> String
pShowPointerForHeader _ _ _ [] = ""
pShowPointerForHeader 1 global iL pL = 
                           breakline ++ pShowPragma ++
                           breakline ++ pShowForHeader 0 global (unionArrayIter iL) pL ++  
                           pShowIterComma iL ++
                           breakline ++ intercalate (", " ++ breakline) 
                                        (map ((++) "++" . getIterName) iL) ++ ") {"
--                                        (map ((flip (++) "+=1") . getIterName) iL) ++ ") {"

pShowPointerForHeader n global iL pL = 
                           breakline ++ 
                           pShowForHeader (n-1) global (unionArrayIter iL) pL ++ 
                           pShowIterComma iL ++
                           breakline ++ intercalate (", " ++ breakline) 
                                     (zipWith wrapIterInc
                                        (map (getArrayGap (n-1)) (getArrayIter iL))
                                        (map getIterName iL)) ++ 
                           ") {" ++ pShowPointerForHeader (n-1) global iL pL
    where wrapIterInc gap iter = iter ++ " += " ++ gap 

pShowIterComma :: [Iter] -> String
pShowIterComma [] = ""
pShowIterComma iL@(i:is) = ", "

pShowForHeader :: Int -> Bool -> [PArray] -> [PName] -> String
pShowForHeader _ _ _ [] = ""
pShowForHeader i global aL pL = 
    let len_pL = length pL
        l_var = pL !! (len_pL - 1 - i)
        l_rank = show i
        l_begin = "l_grid.x0[" ++ l_rank ++ "]"
        l_end = "l_grid.x1[" ++ l_rank ++ "]"
    in  adjustGap i global aL ++ "for (int " ++ l_var ++ 
        " = " ++ l_begin ++ "; " ++ l_var ++ " < " ++ l_end ++ "; ++" ++ l_var
                    
adjustGap :: Int -> Bool -> [PArray] -> String
adjustGap l_rank _ [] = ""
adjustGap l_rank global aL@(a:as) = 
    if l_rank > 0 then pShowAdjustGap l_rank aL
             else ""
    where pShowAdjustGap l_rank [] = ""
          pShowAdjustGap l_rank aL@(a:as) = concatMap (pShowAdjustGapTerm l_rank) aL
          pShowAdjustGapTerm l_rank a = 
            let l_a = aName a
                l_gap = "gap_" ++ l_a ++ "_" ++ show l_rank
                pre = if global == True then "l_" else "lc_"
                l_stride = pre ++ l_a ++ "_stride_" ++ show l_rank 
                l_pre_stride = pre ++ l_a ++ "_stride_" ++ show (l_rank - 1)
                l_begin = "l_grid.x0[" ++ show (l_rank-1) ++ "]"
                l_end = "l_grid.x1[" ++ show (l_rank-1) ++ "]"
            in  l_gap ++ " = " ++ l_stride ++ " + (" ++ l_begin ++ " - " ++ l_end ++ 
                ") * " ++ l_pre_stride ++ ";" ++ breakline
          
getIterName :: Iter -> String
getIterName (name, _, _, _) = name

getArrayGaps :: Int -> PArray -> String
getArrayGaps 0 array = getArrayGap 0 (aName array)
getArrayGaps n array = getArrayGap n (aName array) ++ ", " ++ getArrayGaps (n-1) array

getArrayGap :: Int -> PName -> String
getArrayGap n array = "gap_" ++ array ++ "_" ++ show n

pShowListIdentifiers :: [PName] -> String
pShowListIdentifiers [] = ""
pShowListIdentifiers (n:ns) = n ++ pShowListIdentifiersL ns
    where pShowListIdentifiersL [] = ""
          pShowListIdentifiersL nL@(n:ns) = ", " ++ pShowListIdentifiers nL

pShowDynamicDecl :: (Show a) => [([PName], PName, a)] -> (a -> String) -> String
pShowDynamicDecl [] _ = ""
pShowDynamicDecl (p:ps) showA = pShowDynamicDeclItem p showA ++ pShowDynamicDeclL ps showA
    where pShowDynamicDeclL [] _ = ""
          pShowDynamicDeclL xL@(x:xs) showA = ", " ++ pShowDynamicDecl xL showA

pShowDynamicDeclItem :: (Show a) => ([PName], PName, a) -> (a -> String) -> String
pShowDynamicDeclItem ([], v, attr) showA = 
    let sAttr = showA attr
    in  if sAttr == "" then v else v ++ " ( " ++ sAttr ++ " ) "
pShowDynamicDeclItem (qL@(q:qs), v, attr) showA = 
    let sAttr = showA attr
    in  if sAttr == "" then intercalate " " qL ++ v 
                       else intercalate " " qL ++ v ++ " ( " ++ sAttr ++ " ) "

pShowArrayDim :: [DimExpr] -> String
pShowArrayDim [] = ""
pShowArrayDim (c:cs) = show c ++ pShowArrayDimL cs
    where pShowArrayDimL [] = ""
          pShowArrayDimL (d:ds) = ", " ++ show d ++ pShowArrayDimL ds

pShowArrayDimItem :: Int -> String
pShowArrayDimItem i = "[ " ++ show i ++ " ]"

pShowArrayDims :: [Int] -> String
pShowArrayDims iL@(i:is) = concatMap pShowArrayDimItem iL
