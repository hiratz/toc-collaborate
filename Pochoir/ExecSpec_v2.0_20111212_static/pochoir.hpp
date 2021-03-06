/*
 **********************************************************************************
 *  Copyright (C) 2010-2011  Massachusetts Institute of Technology
 *  Copyright (C) 2010-2011  Yuan Tang <yuantang@csail.mit.edu>
 * 		                     Charles E. Leiserson <cel@mit.edu>
 * 	 
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *   Suggestsions:                  yuantang@csail.mit.edu
 *   Bugs:                          yuantang@csail.mit.edu
 *
 *********************************************************************************
 */

#ifndef EXPR_STENCIL_HPP
#define EXPR_STENCIL_HPP

#include "pochoir_common.hpp"
#include "pochoir_kernel.hpp"
#include "pochoir_walk.hpp"
#include "pochoir_array.hpp"
/* assuming there won't be more than 10 Pochoir_Array in one Pochoir object! */
// #define ARRAY_SIZE 10

template <int N_RANK>
class Pochoir {
    private:
        int slope_[N_RANK];
        Grid_Info<N_RANK> logic_grid_;
        Grid_Info<N_RANK> phys_grid_;
        int time_shift_;
        int toggle_;
        int timestep_;
        bool regArrayFlag_, regLogicDomainFlag_, regPhysDomainFlag_, regShapeFlag_;
        void checkFlag(bool flag, char const * str);
        void checkFlags(void);
        template <typename T_Array>
        void getPhysDomainFromArray(T_Array & arr);
        template <typename T_Array>
        void cmpPhysDomainFromArray(T_Array & arr);
        void Register_Shape(Pochoir_Shape<N_RANK> * shape, int N_SIZE);
        Pochoir_Shape<N_RANK> * shape_;
        int shape_size_;
        int num_arr_;
        int arr_type_size_;
        int sz_pxgk_, sz_pigk_, sz_ptigk_;
        int lcm_unroll_;
        Pochoir_Mode pmode_;
        /* assuming that the number of distinct sub-regions is less than 10 */
        Vector_Info< Pochoir_Guard<N_RANK> > pxgs_, pigs_, ptigs_;
        Vector_Info< Pochoir_Tile_Kernel<N_RANK> > pxts_, pits_, ptits_;
        Vector_Info< Pochoir_Guard<N_RANK> > opgs_;
        Vector_Info< Pochoir_Combined_Obase_Kernel<N_RANK> > opks_;

        /* Private Register Kernel Function */
        template <typename I>
        void reg_tile_dim(Pochoir_Tile_Kernel<N_RANK> & pt, int dim, I i);
        template <typename I, typename ... IS>
        void reg_tile_dim(Pochoir_Tile_Kernel<N_RANK> & pt, int dim, I i, IS ... is);

    public:
    /* various form of Register_Exclusive_Tile_Kernels */
    /* this is the version to register a single kernel for the entire region
     * guarded by 'g'
     */
    void Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k);
    template <int N_SIZE1>
    void Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]);
    /* this is for 2D checkerboard style tile.
     * the total dimensions here include the time dimension
     */
    template <int N_SIZE1, int N_SIZE2>
    void Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]);
    template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
    void Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]);

    /* various form of Register_Inclusive_Tile_Kernels */
    void Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k);
    template <int N_SIZE1>
    void Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]);
    template <int N_SIZE1, int N_SIZE2>
    void Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]);
    template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
    void Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]);
    
    /* various form of Register_Tiny_Inclusive_Tile_Kernels */
    void Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k);
    template <int N_SIZE1>
    void Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]);
    template <int N_SIZE1, int N_SIZE2>
    void Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]);
    template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
    void Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]);

     /* various form of Register_Tile_Kernels */
    void Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k);
    template <int N_SIZE1>
    void Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]);
    template <int N_SIZE1, int N_SIZE2>
    void Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]);
    template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
    void Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]);

    void Register_Tile_Obase_Kernels(Pochoir_Guard<N_RANK> & g, int unroll, Pochoir_Obase_Kernel<N_RANK> & k, Pochoir_Obase_Kernel<N_RANK> & bk);
    void Register_Tile_Obase_Kernels(Pochoir_Guard<N_RANK> & g, int unroll, Pochoir_Obase_Kernel<N_RANK> & k, Pochoir_Obase_Kernel<N_RANK> & cond_k, Pochoir_Obase_Kernel<N_RANK> & bk, Pochoir_Obase_Kernel<N_RANK> & cond_bk); 
    // get slope(s)
    int slope(int const _idx) { return slope_[_idx]; }
    Pochoir() {
        for (int i = 0; i < N_RANK; ++i) {
            slope_[i] = 0;
            logic_grid_.x0[i] = logic_grid_.x1[i] = logic_grid_.dx0[i] = logic_grid_.dx1[i] = 0;
            phys_grid_.x0[i] = phys_grid_.x1[i] = phys_grid_.dx0[i] = phys_grid_.dx1[i] = 0;
        }
        shape_ = NULL; shape_size_ = 0; time_shift_ = 0; toggle_ = 0;
        timestep_ = 0;
        regArrayFlag_ = regLogicDomainFlag_ = regPhysDomainFlag_ = regShapeFlag_ = false;
        num_arr_ = 0;
        arr_type_size_ = 0;
        sz_pxgk_ = 0; sz_pigk_ = 0; sz_ptigk_ = 0;
        lcm_unroll_ = 1;
        pmode_ = Pochoir_Null;
    }

    /* currently, we just compute the slope[] out of the shape[] */
    /* We get the Grid_Info out of arrayInUse */
    template <typename T>
    void Register_Array(Pochoir_Array<T, N_RANK> & a);
    template <typename T, typename ... TS>
    void Register_Array(Pochoir_Array<T, N_RANK> & a, Pochoir_Array<TS, N_RANK> ... as);

    /* We should still keep the Register_Domain for zero-padding!!! */
    template <typename D>
    void Register_Domain(D const & d);
    template <typename D, typename ... DS>
    void Register_Domain(D const & d, DS ... ds);
    /* register boundary value function with corresponding Pochoir_Array object directly */
    template <typename T_Array, typename RET>
    void registerBoundaryFn(T_Array & arr, RET (*_bv)(T_Array &, int, int, int)) {
        arr.Register_Boundary(_bv);
        Register_Array(arr);
    } 
    Grid_Info<N_RANK> get_phys_grid(void);

    /* Executable Spec */
    void Run(int timestep);
    void Run_Obase(int timestep);
    Pochoir_Plan<N_RANK> & Gen_Plan(int timepstep);
    Pochoir_Plan<N_RANK> & Gen_Plan_Obase(int timepstep);
    Pochoir_Plan<N_RANK> & Load_Plan(const char * file_name);
    void Store_Plan(const char * file_name, Pochoir_Plan<N_RANK> & _plan);
    void Run(Pochoir_Plan<N_RANK> & _plan);
    void Run_Stagger(Pochoir_Plan<N_RANK> & _plan);
    void Run_Obase(Pochoir_Plan<N_RANK> & _plan);
    void Run_Obase_Merge(Pochoir_Plan<N_RANK> & _plan);
};

template <int N_RANK> template <typename I>
void Pochoir<N_RANK>::reg_tile_dim(Pochoir_Tile_Kernel<N_RANK> & pt, int dim, I i) {
    pt.size_[0] = i; 
    pt.pointer_[0] = 0;
    pt.stride_[0] = 1;
    for (int i = 1; i < dim; ++i) {
        pt.stride_[i] = pt.stride_[i - 1] * pt.size_[i - 1];
    }
    return;
}

template <int N_RANK> template <typename I, typename ... IS>
void Pochoir<N_RANK>::reg_tile_dim(Pochoir_Tile_Kernel<N_RANK> & pt, int dim, I i, IS ... is) {
    int l_dim = sizeof ... (IS);
    pt.size_[l_dim] = i;
    pt.pointer_[l_dim] = 0;
    reg_tile_dim(pt, dim, is ...);
    return;
}

/* this is the version that register a single kernel for the entire region
 * guarded by 'g'
 */
template <int N_RANK>
void Pochoir<N_RANK>::Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_ptig = new Pochoir_Guard<N_RANK>;
    *l_ptig = g;
    ptigs_.add_element(*l_ptig);
    Pochoir_Tile_Kernel<N_RANK> * l_ptit = new Pochoir_Tile_Kernel<N_RANK>;
    l_ptit->kernel_ = new T_Kernel;
    l_ptit->kernel_[0] = k;
    Register_Shape(k.Get_Shape(), k.Get_Shape_Size());
    reg_tile_dim(*l_ptit, 1, 1);
    ptits_.add_element(*l_ptit);
    ++sz_ptigk_;
    assert(sz_ptigk_ == ptits_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1>
void Pochoir<N_RANK>::Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_ptig = new Pochoir_Guard<N_RANK>;
    *l_ptig = g;
    ptigs_.add_element(*l_ptig);
    Pochoir_Tile_Kernel<N_RANK> * l_ptit = new Pochoir_Tile_Kernel<N_RANK>;
    l_ptit->kernel_ = new T_Kernel[N_SIZE1];
    for (int i = 0; i < N_SIZE1; ++i) {
        l_ptit->kernel_[i] = tile[i];
        Register_Shape(tile[i].Get_Shape(), tile[i].Get_Shape_Size());
    }
    reg_tile_dim(*l_ptit, 1, N_SIZE1);
    ptits_.add_element(*l_ptit);
    ++sz_ptigk_;
    assert(sz_ptigk_ == ptits_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2>
void Pochoir<N_RANK>::Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_ptig = new Pochoir_Guard<N_RANK>;
    *l_ptig = g;
    ptigs_.add_element(*l_ptig);
    Pochoir_Tile_Kernel<N_RANK> * l_ptit = new Pochoir_Tile_Kernel<N_RANK>;
    l_ptit->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
            l_ptit->kernel_[i * N_SIZE2 + j] = tile[i][j];
            Register_Shape(tile[i][j].Get_Shape(), tile[i][j].Get_Shape_Size());
        }
    }
    reg_tile_dim(*l_ptit, 2, N_SIZE1, N_SIZE2);
    ptits_.add_element(*l_ptit);
    ++sz_ptigk_;
    assert(sz_ptigk_ == ptits_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
void Pochoir<N_RANK>::Register_Tiny_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_ptig = new Pochoir_Guard<N_RANK>;
    *l_ptig = g;
    ptigs_.add_element(*l_ptig);
    Pochoir_Tile_Kernel<N_RANK> * l_ptit = new Pochoir_Tile_Kernel<N_RANK>;
    l_ptit->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2 * N_SIZE3];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
    for (int k = 0; k < N_SIZE3; ++k) {
        l_ptit->kernel_[i * N_SIZE2 * N_SIZE3 + j * N_SIZE3 + k] = tile[i][j][k]; 
        Register_Shape(tile[i][j][k].Get_Shape(), tile[i][j][k].Get_Shape_Size());
    }
        }
    }
    reg_tile_dim(*l_ptit, 3, N_SIZE1, N_SIZE2, N_SIZE3);
    ptits_.add_element(*l_ptit);
    ++sz_ptigk_;
    assert(sz_ptigk_ == ptits_.size());
    return;
}


template <int N_RANK>
void Pochoir<N_RANK>::Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pig = new Pochoir_Guard<N_RANK>;
    *l_pig = g;
    pigs_.add_element(*l_pig);
    Pochoir_Tile_Kernel<N_RANK> * l_pit = new Pochoir_Tile_Kernel<N_RANK>;
    l_pit->kernel_ = new T_Kernel[1];
    l_pit->kernel_[0] = k;
    Register_Shape(k.Get_Shape(), k.Get_Shape_Size());
    reg_tile_dim(*l_pit, 1, 1);
    pits_.add_element(*l_pit);
    ++sz_pigk_;
    assert(sz_pigk_ == pits_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1>
void Pochoir<N_RANK>::Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pig = new Pochoir_Guard<N_RANK>;
    *l_pig = g;
    pigs_.add_element(*l_pig);
    Pochoir_Tile_Kernel<N_RANK> * l_pit = new Pochoir_Tile_Kernel<N_RANK>;
    l_pit->kernel_ = new T_Kernel[N_SIZE1];
    for (int i = 0; i < N_SIZE1; ++i) {
        l_pit->kernel_[i] = tile[i];
        Register_Shape(tile[i].Get_Shape(), tile[i].Get_Shape_Size());
    }
    reg_tile_dim(*l_pit, 1, N_SIZE1);
    pits_.add_element(*l_pit);
    ++sz_pigk_;
    assert(sz_pigk_ == pits_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2>
void Pochoir<N_RANK>::Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pig = new Pochoir_Guard<N_RANK>;
    *l_pig = g;
    pigs_.add_element(*l_pig);
    Pochoir_Tile_Kernel<N_RANK> * l_pit = new Pochoir_Tile_Kernel<N_RANK>;
    l_pit->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
            l_pit->kernel_[i * N_SIZE2 + j] = tile[i][j];
            Register_Shape(tile[i][j].Get_Shape(), tile[i][j].Get_Shape_Size());
        }
    }
    reg_tile_dim(*l_pit, 2, N_SIZE1, N_SIZE2);
    pits_.add_element(*l_pit);
    ++sz_pigk_;
    assert(sz_pigk_ == pits_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
void Pochoir<N_RANK>::Register_Inclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pig = new Pochoir_Guard<N_RANK>;
    *l_pig = g;
    pigs_.add_element(*l_pig);
    Pochoir_Tile_Kernel<N_RANK> * l_pit = new Pochoir_Tile_Kernel<N_RANK>;
    l_pit->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2 * N_SIZE3];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
    for (int k = 0; k < N_SIZE3; ++k) {
        l_pit->kernel_[i * N_SIZE2 * N_SIZE3 + j * N_SIZE3 + k] = tile[i][j][k];
        Register_Shape(tile[i][j][k].Get_Shape(), tile[i][j][k].Get_Shape_Size());
    }
        }
    }
    reg_tile_dim(*l_pit, 3, N_SIZE1, N_SIZE2, N_SIZE3);
    pits_.add_element(*l_pit);
    ++sz_pigk_;
    assert(sz_pigk_ == pits_.size());
    return;
}


template <int N_RANK>
void Pochoir<N_RANK>::Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[1];
    l_pxt->kernel_[0] = k;
    Register_Shape(k.Get_Shape(), k.Get_Shape_Size());
    reg_tile_dim(*l_pxt, 1, 1);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1>
void Pochoir<N_RANK>::Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[N_SIZE1];
    for (int i = 0; i < N_SIZE1; ++i) {
        l_pxt->kernel_[i] = tile[i];
        Register_Shape(tile[i].Get_Shape(), tile[i].Get_Shape_Size());
    }
    reg_tile_dim(*l_pxt, 1, N_SIZE1);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2>
void Pochoir<N_RANK>::Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
            l_pxt->kernel_[i * N_SIZE2 + j] = tile[i][j];
            Register_Shape(tile[i][j].Get_Shape(), tile[i][j].Get_Shape_Size());
        }
    }
    reg_tile_dim(*l_pxt, 2, N_SIZE1, N_SIZE2);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
void Pochoir<N_RANK>::Register_Exclusive_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2 * N_SIZE3];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
    for (int k = 0; k < N_SIZE3; ++k) {
        l_pxt->kernel_[i * N_SIZE2 * N_SIZE3 + j * N_SIZE3 + k] = tile[i][j][k];
        Register_Shape(tile[i][j][k].Get_Shape(), tile[i][j][k].Get_Shape_Size());
    }
        }
    }
    reg_tile_dim(*l_pxt, 3, N_SIZE1, N_SIZE2, N_SIZE3);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}


template <int N_RANK>
void Pochoir<N_RANK>::Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> & k) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[1];
    l_pxt->kernel_[0] = k;
    Register_Shape(k.Get_Shape(), k.Get_Shape_Size());
    reg_tile_dim(*l_pxt, 1, 1);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1>
void Pochoir<N_RANK>::Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[N_SIZE1];
    for (int i = 0; i < N_SIZE1; ++i) {
        l_pxt->kernel_[i] = tile[i];
        Register_Shape(tile[i].Get_Shape(), tile[i].Get_Shape_Size());
    }
    reg_tile_dim(*l_pxt, 1, N_SIZE1);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2>
void Pochoir<N_RANK>::Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
            l_pxt->kernel_[i * N_SIZE2 + j] = tile[i][j];
            Register_Shape(tile[i][j].Get_Shape(), tile[i][j].Get_Shape_Size());
        }
    }
    reg_tile_dim(*l_pxt, 2, N_SIZE1, N_SIZE2);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}

template <int N_RANK> template <int N_SIZE1, int N_SIZE2, int N_SIZE3>
void Pochoir<N_RANK>::Register_Tile_Kernels(Pochoir_Guard<N_RANK> & g, Pochoir_Kernel<N_RANK> (& tile)[N_SIZE1][N_SIZE2][N_SIZE3]) {
    typedef Pochoir_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Tile;
    Pochoir_Guard<N_RANK> * l_pxg = new Pochoir_Guard<N_RANK>;
    *l_pxg = g;
    pxgs_.add_element(*l_pxg);
    Pochoir_Tile_Kernel<N_RANK> * l_pxt = new Pochoir_Tile_Kernel<N_RANK>;
    l_pxt->kernel_ = new T_Kernel[N_SIZE1 * N_SIZE2 * N_SIZE3];
    for (int i = 0; i < N_SIZE1; ++i) {
        for (int j = 0; j < N_SIZE2; ++j) {
    for (int k = 0; k < N_SIZE3; ++k) {
        l_pxt->kernel_[i * N_SIZE2 * N_SIZE3 + j * N_SIZE3 + k] = tile[i][j][k];
        Register_Shape(tile[i][j][k].Get_Shape(), tile[i][j][k].Get_Shape_Size());
    }
        }
    }
    reg_tile_dim(*l_pxt, 3, N_SIZE1, N_SIZE2, N_SIZE3);
    pxts_.add_element(*l_pxt);
    ++sz_pxgk_;
    assert(sz_pxgk_ == pxts_.size());
    return;
}

template <int N_RANK> 
void Pochoir<N_RANK>::Register_Tile_Obase_Kernels(Pochoir_Guard<N_RANK> & g, int unroll, Pochoir_Obase_Kernel<N_RANK> & k, Pochoir_Obase_Kernel<N_RANK> & bk) {
    typedef Pochoir_Obase_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Obase_Tile;
    Pochoir_Guard<N_RANK> * l_opg = new Pochoir_Guard<N_RANK>;
    *l_opg = g;
    opgs_.add_element(*l_opg);
    Pochoir_Combined_Obase_Kernel<N_RANK> * l_opk = new Pochoir_Combined_Obase_Kernel<N_RANK>;
    l_opk->unroll_ = unroll;
    l_opk->kernel_ = new T_Kernel;
    l_opk->kernel_[0] = k;
    Register_Shape(k.Get_Shape(), k.Get_Shape_Size());
    l_opk->bkernel_ = new T_Kernel;
    l_opk->bkernel_[0] = bk;
    Register_Shape(bk.Get_Shape(), bk.Get_Shape_Size());
    l_opk->cond_kernel_ = NULL;
    l_opk->cond_bkernel_ = NULL;
    opks_.add_element(*l_opk);
    lcm_unroll_ = lcm(lcm_unroll_, unroll);
    ++sz_pxgk_;
    assert(sz_pxgk_ == opks_.size());
}

template <int N_RANK> 
void Pochoir<N_RANK>::Register_Tile_Obase_Kernels(Pochoir_Guard<N_RANK> & g, int unroll, Pochoir_Obase_Kernel<N_RANK> & k, Pochoir_Obase_Kernel<N_RANK> & cond_k, Pochoir_Obase_Kernel<N_RANK> & bk, Pochoir_Obase_Kernel<N_RANK> & cond_bk) {
    typedef Pochoir_Obase_Kernel<N_RANK> T_Kernel;
    pmode_ = Pochoir_Obase_Tile;
    Pochoir_Guard<N_RANK> * l_opg = new Pochoir_Guard<N_RANK>;
    *l_opg = g;
    opgs_.add_element(*l_opg);
    Pochoir_Combined_Obase_Kernel<N_RANK> * l_opk = new Pochoir_Combined_Obase_Kernel<N_RANK>;
    l_opk->unroll_ = unroll;
    l_opk->kernel_ = new T_Kernel;
    l_opk->kernel_[0] = k;
    Register_Shape(k.Get_Shape(), k.Get_Shape_Size());
    l_opk->cond_kernel_ = new T_Kernel;
    l_opk->cond_kernel_[0] = cond_k;
    Register_Shape(cond_k.Get_Shape(), cond_k.Get_Shape_Size());
    l_opk->bkernel_ = new T_Kernel;
    l_opk->bkernel_[0] = bk;
    Register_Shape(bk.Get_Shape(), bk.Get_Shape_Size());
    l_opk->cond_bkernel_ = new T_Kernel;
    l_opk->cond_bkernel_[0] = cond_bk;
    Register_Shape(cond_bk.Get_Shape(), cond_bk.Get_Shape_Size());
    opks_.add_element(*l_opk);
    lcm_unroll_ = lcm(lcm_unroll_, unroll);
    ++sz_pxgk_;
    assert(sz_pxgk_ == opks_.size());
}

template <int N_RANK>
void Pochoir<N_RANK>::checkFlag(bool flag, char const * str) {
    if (!flag) {
        printf("\nPochoir registration error:\n");
        printf("You forgot to register %s.\n", str);
        exit(1);
    }
}

template <int N_RANK>
void Pochoir<N_RANK>::checkFlags(void) {
    checkFlag(regArrayFlag_, "Pochoir array");
    checkFlag(regLogicDomainFlag_, "Logic Domain");
    checkFlag(regPhysDomainFlag_, "Physical Domain");
    checkFlag(regShapeFlag_, "Shape");
    return;
}

template <int N_RANK> template <typename T_Array> 
void Pochoir<N_RANK>::getPhysDomainFromArray(T_Array & arr) {
    /* get the physical grid */
    for (int i = 0; i < N_RANK; ++i) {
        phys_grid_.x0[i] = 0; phys_grid_.x1[i] = arr.size(i);
        /* if logic domain is not set, let's set it the same as physical grid */
        if (!regLogicDomainFlag_) {
            logic_grid_.x0[i] = 0; logic_grid_.x1[i] = arr.size(i);
        }
    }

    regPhysDomainFlag_ = true;
    regLogicDomainFlag_ = true;
}

template <int N_RANK> template <typename T_Array> 
void Pochoir<N_RANK>::cmpPhysDomainFromArray(T_Array & arr) {
    /* check the consistency of all engaged Pochoir_Array */
    for (int j = 0; j < N_RANK; ++j) {
        if (arr.size(j) != phys_grid_.x1[j]) {
            printf("Pochoir array size mismatch error:\n");
            printf("Registered Pochoir arrays have different sizes!\n");
            exit(1);
        }
    }
}

template <int N_RANK> template <typename T>
void Pochoir<N_RANK>::Register_Array(Pochoir_Array<T, N_RANK> & a) {
    if (!regShapeFlag_) {
        printf("Please register Shape before register Array!\n");
        exit(1);
    }

    if (num_arr_ == 0) {
        arr_type_size_ = sizeof(T);
        // arr_type_size_ = sizeof(double);
#if DEBUG
        printf("<%s:%d> arr_type_size = %d\n", __FILE__, __LINE__, arr_type_size_);
#endif
        ++num_arr_;
    } 
    if (!regPhysDomainFlag_) {
        getPhysDomainFromArray(a);
    } else {
        cmpPhysDomainFromArray(a);
    }
    a.Register_Shape(shape_, shape_size_);
#if 0
    arr.set_slope(slope_);
    arr.set_toggle(toggle_);
    arr.alloc_mem();
#endif
    regArrayFlag_ = true;
}

template <int N_RANK> template <typename T, typename ... TS>
void Pochoir<N_RANK>::Register_Array(Pochoir_Array<T, N_RANK> & a, Pochoir_Array<TS, N_RANK> ... as) {
    if (!regShapeFlag_) {
        printf("Please register Shape before register Array!\n");
        exit(1);
    }

    if (num_arr_ == 0) {
        arr_type_size_ = sizeof(T);
        // arr_type_size_ = sizeof(double);
#if DEBUG
        printf("<%s:%d> arr_type_size = %d\n", __FILE__, __LINE__, arr_type_size_);
#endif
        ++num_arr_;
    } 
    if (!regPhysDomainFlag_) {
        getPhysDomainFromArray(a);
    } else {
        cmpPhysDomainFromArray(a);
    }
    a.Register_Shape(shape_, shape_size_);
#if 0
    arr.set_slope(slope_);
    arr.set_toggle(toggle_);
    arr.alloc_mem();
#endif
    Register_Array(as ...);
    regArrayFlag_ = true;
}

template <int N_RANK> 
void Pochoir<N_RANK>::Register_Shape(Pochoir_Shape<N_RANK> * shape, int N_SIZE) {
    /* we extract time_shift_, toggle_, slope_ out of Shape */
    Pochoir_Shape<N_RANK> * l_shape;
    if (!regShapeFlag_) {
        regShapeFlag_ = true;
        l_shape = new Pochoir_Shape<N_RANK>[N_SIZE];
        shape_ = l_shape;
    } else {
        l_shape = new Pochoir_Shape<N_RANK>[N_SIZE + shape_size_] ;
        /* copy in the old shape value */
        for (int i = 0; i < shape_size_; ++i)  {
            for (int r = 0; r < N_RANK+1; ++r)  {
                l_shape[i].shift[r]  = shape_[i].shift[r];
            }
        }
        delete (shape_);
        shape_ = l_shape;
    }
    /* currently we just get the slope_[]  and toggle_ out of the shape[]  */
    int l_min_time_shift=0, l_max_time_shift=0, depth=0;
    for (int i = 0; i < N_SIZE; ++i)  {
        if (shape[i] .shift[0] < l_min_time_shift)
            l_min_time_shift = shape[i].shift[0];
        if (shape[i].shift[0] > l_max_time_shift)
            l_max_time_shift = shape[i].shift[0];
    }
    depth = l_max_time_shift - l_min_time_shift;
    time_shift_ = max(time_shift_, 0 - l_min_time_shift);
    toggle_ = max(toggle_, depth + 1);
    for (int i = 0; i < N_SIZE; ++i) {
        for (int r = 0; r < N_RANK+1; ++r) {
//            shape_[shape_size_ + i].shift[r] = (r > 0) ? shape[i].shift[r] : shape[i].shift[r] + time_shift_;
            shape_[shape_size_ + i].shift[r] = shape[i].shift[r];
        }
    }
    for (int i = 0; i < N_SIZE; ++i) {
        for (int r = 0; r < N_RANK+1; ++r) {
            slope_[N_RANK-r] = (r > 0) ? max(slope_[N_RANK-r], abs((int)ceil((float)shape_[i].shift[N_RANK-r]/(l_max_time_shift - shape_[i].shift[0])))) : 0;
        }
    }
    shape_size_ += N_SIZE;
#if 1 
    printf("<%s> toggle = %d\n", __FUNCTION__, toggle_);
    for (int r = 0; r < N_RANK; ++r) {
        printf("<%s> slope[%d] = %d, ", __FUNCTION__, r, slope_[r]);
    }
    printf("\n");
#endif
}

template <int N_RANK> template <typename D>
void Pochoir<N_RANK>::Register_Domain(D const & d) {
    logic_grid_.x0[0] = d.first();
    logic_grid_.x1[0] = d.first() + d.size();
    regLogicDomainFlag_ = true;
}

template <int N_RANK> template <typename D, typename ... DS>
void Pochoir<N_RANK>::Register_Domain(D const & d, DS ... ds) {
    int l_pointer = sizeof...(DS);
    logic_grid_.x0[l_pointer] = d.first();
    logic_grid_.x1[l_pointer] = d.first() + d.size();
}

template <int N_RANK> 
Grid_Info<N_RANK> Pochoir<N_RANK>::get_phys_grid(void) {
    return phys_grid_;
}

/* Run the kernel functions stored in array of function pointers */
template <int N_RANK>
void Pochoir<N_RANK>::Run(int timestep) {
    Algorithm<N_RANK> algor(slope_);
    algor.set_phys_grid(phys_grid_);
    algor.set_thres(arr_type_size_);
    algor.set_unroll(lcm_unroll_);
    if (pks_ != NULL) {
        algor.set_pks(sz_pxgk_, pxgs_, pks_);
    } else if (pxts_ != NULL) {
        algor.set_pts(sz_pxgk_, pxgs_, pxts_);
    } else {
        printf("Something is wrong in Run(Timestep)!\n");
        exit(1);
    }
    timestep_ = timestep;
    /* base_case_kernel() will mimic exact the behavior of serial nested loop!
    */
    checkFlags();
    inRun = true;
    algor.base_case_kernel_guard(0 + time_shift_, timestep + time_shift_, logic_grid_);
    inRun = false;
}

/* obase for interior and ExecSpec for boundary */
template <int N_RANK> 
void Pochoir<N_RANK>::Run_Obase(int timestep) {
//    int l_total_points = 1;
    Algorithm<N_RANK> algor(slope_);
    algor.set_phys_grid(phys_grid_);
    algor.set_thres(arr_type_size_);
    if (pmode_ == Pochoir_Obase_Tile) {
        algor.set_opks(sz_pxgk_, opgs_.get_root(), opks_.get_root());
    } else {
        printf("Something is wrong in Run_Obase(Timestep)!\n");
        exit(1);
    }
    algor.set_unroll(lcm_unroll_);
    timestep_ = timestep;
    checkFlags();
    // cutting based on shorter bar
    algor.adaptive_bicut_p(0 + time_shift_, timestep + time_shift_, logic_grid_);
}

template <int N_RANK> 
Pochoir_Plan<N_RANK> & Pochoir<N_RANK>::Gen_Plan(int timestep) {
    /* we don't squeeze out the NONE_EXCLUSIVE_IFS in Gen_Plan, 
     * but do in Gen_Plan_Obase
     */
    Pochoir_Plan<N_RANK> * l_plan = new Pochoir_Plan<N_RANK>();
    int l_sz_base_data, l_sz_sync_data;
    Spawn_Tree<N_RANK> * l_tree;
    Node_Info<N_RANK> * l_root;

    Algorithm<N_RANK> algor(slope_);
    algor.set_phys_grid(phys_grid_);
    algor.set_thres(arr_type_size_);
    /* set individual unroll factor from opgk_ */
    if (pmode_ == Pochoir_Obase_Tile) {
        algor.set_opks(sz_pxgk_, opgs_, opks_.get_root());
    } else if (pmode_ == Pochoir_Tile) {
        /* we partition the computing domain align to the 'exclusive_if's */
        algor.set_pts(sz_pxgk_, pxgs_, pxts_.get_root());
    } else {
        printf("Something is wrong in Gen_Plan(Timestep)!\n");
        exit(1);
    }
    algor.set_unroll(lcm_unroll_);
    timestep_ = timestep;
    checkFlags();
    l_tree = new Spawn_Tree<N_RANK>();
    l_tree->set_add_empty_region(true);
    l_root = l_tree->get_root();
    algor.set_tree(l_tree);
    algor.gen_plan_bicut_p(l_root, 0 + time_shift_, timestep + time_shift_, logic_grid_);
    l_sz_base_data = algor.get_sz_base_data();
    l_sz_sync_data = max(1, algor.get_sz_sync_data());
    l_plan->alloc_base_data(l_sz_base_data);
    l_plan->alloc_sync_data(l_sz_sync_data);
    int l_tree_size_begin = l_tree->size();
#if DEBUG
    printf("sz_base_data = %d, sz_sync_data = %d\n", l_sz_base_data, l_sz_sync_data);
    printf("tree size = %d\n", l_tree_size_begin);
#endif
    /* after remove all nodes, the only remaining node will be the 'root' */
    while (l_tree_size_begin > 1) {
        l_tree->dfs_until_sync(l_root->left, (*(l_plan->base_data_)));
        int l_tree_size_end = l_tree->size();
        if (l_tree_size_begin - l_tree_size_end > 0) {
            l_plan->sync_data_->add_element(l_tree_size_begin - l_tree_size_end);
        }
        l_tree->dfs_rm_sync(l_root->left);
        l_tree_size_begin = l_tree->size();
#if DEBUG
        printf("tree size = %d\n", l_tree_size_begin);
#endif
    }
    l_plan->sync_data_->scan();
    l_plan->sync_data_->add_element(END_SYNC);
    return (*l_plan);
}

template <int N_RANK> 
Pochoir_Plan<N_RANK> & Pochoir<N_RANK>::Gen_Plan_Obase(int timestep) {
    /* we don't squeeze out the NONE_EXCLUSIVE_IFS in Gen_Plan, 
     * but do in Gen_Plan_Obase
     */
    Pochoir_Plan<N_RANK> * l_plan = new Pochoir_Plan<N_RANK>();
    int l_sz_base_data, l_sz_sync_data;
    Spawn_Tree<N_RANK> * l_tree;
    Node_Info<N_RANK> * l_root;

    Algorithm<N_RANK> algor(slope_);
    algor.set_phys_grid(phys_grid_);
    algor.set_thres(arr_type_size_);
    /* set individual unroll factor from opgk_ */
    if (pmode_ == Pochoir_Obase_Tile) {
        algor.set_opks(sz_pxgk_, opgs_, opks_.get_root());
    } else if (pmode_ == Pochoir_Tile) {
        /* we partition the computing domain align to the 'exclusive_if's */
        algor.set_pts(sz_pxgk_, pxgs_, pxts_.get_root());
    } else {
        printf("Something is wrong in Gen_Plan_Obase(Timestep)!\n");
        exit(1);
    }
    algor.set_unroll(lcm_unroll_);
    timestep_ = timestep;
    checkFlags();
    l_tree = new Spawn_Tree<N_RANK>();
    l_tree->set_add_empty_region(false);
    l_root = l_tree->get_root();
    algor.set_tree(l_tree);
    algor.gen_plan_bicut_p(l_root, 0 + time_shift_, timestep + time_shift_, logic_grid_);
    l_sz_base_data = algor.get_sz_base_data();
    l_sz_sync_data = max(1, algor.get_sz_sync_data());
    l_plan->alloc_base_data(l_sz_base_data);
    l_plan->alloc_sync_data(l_sz_sync_data);
    int l_tree_size_begin = l_tree->size();
#if DEBUG
    printf("sz_base_data = %d, sz_sync_data = %d\n", l_sz_base_data, l_sz_sync_data);
    printf("tree size = %d\n", l_tree_size_begin);
#endif
    /* after remove all nodes, the only remaining node will be the 'root' */
    while (l_tree_size_begin > 1) {
        l_tree->dfs_until_sync(l_root->left, (*(l_plan->base_data_)));
        int l_tree_size_end = l_tree->size();
        if (l_tree_size_begin - l_tree_size_end > 0) {
            l_plan->sync_data_->add_element(l_tree_size_begin - l_tree_size_end);
        }
        l_tree->dfs_rm_sync(l_root->left);
        l_tree_size_begin = l_tree->size();
#if DEBUG
        printf("tree size = %d\n", l_tree_size_begin);
#endif
    }
    l_plan->sync_data_->scan();
    l_plan->sync_data_->add_element(END_SYNC);
    return (*l_plan);
}

template <int N_RANK>
void Pochoir<N_RANK>::Store_Plan(const char * file_name, Pochoir_Plan<N_RANK> & _plan) {
    char * l_base_file_name = new char[100];
    sprintf(l_base_file_name, "base_%s\0", file_name);
    char * l_sync_file_name = new char[100];
    sprintf(l_sync_file_name, "sync_%s\0", file_name);
    _plan.store_plan(l_base_file_name, l_sync_file_name);
    return;
}

template <int N_RANK>
Pochoir_Plan<N_RANK> & Pochoir<N_RANK>::Load_Plan(const char * file_name) {
    char * l_base_file_name = new char[100];
    sprintf(l_base_file_name, "base_%s\0", file_name);
    char * l_sync_file_name = new char[100];
    sprintf(l_sync_file_name, "sync_%s\0", file_name);
    Pochoir_Plan<N_RANK> * l_plan = new Pochoir_Plan<N_RANK>();
    l_plan->load_plan(l_base_file_name, l_sync_file_name);
    return (*l_plan);
}

template <int N_RANK>
void Pochoir<N_RANK>::Run_Stagger(Pochoir_Plan<N_RANK> & _plan) {
    assert(pks_ != NULL);
    int offset = 0;
    for (int j = 0; _plan.sync_data_->region_[j] != END_SYNC; ++j) {
        for (int i = offset; i < _plan.sync_data_->region_[j]; ++i) {
            int l_region_n = _plan.base_data_->region_[i].region_n;
            if (l_region_n >= 0) {
                int l_t0 = _plan.base_data_->region_[i].t0;
                int l_t1 = _plan.base_data_->region_[i].t1;
                Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
                Pochoir_Run_Regional_Stagger_Kernel<N_RANK> l_kernel(pks_[l_region_n]);
                l_kernel.set_pointer(l_t0 - time_shift_);
                for (int t = l_t0; t < l_t1; ) {
                    meta_grid_boundary<N_RANK>::single_step(t, l_grid, phys_grid_, l_kernel);
                    for (int i = 0; i < N_RANK; ++i) {
                        l_grid.x0[i] += l_grid.dx0[i]; l_grid.x1[i] += l_grid.dx1[i];
                    }
                    ++t;
                    l_kernel.shift_pointer();
                }
            }
        }
        offset = _plan.sync_data_->region_[j];
    }
    return;
}

template <int N_RANK>
void Pochoir<N_RANK>::Run(Pochoir_Plan<N_RANK> & _plan) {
    assert(pxts_ != NULL);
    int offset = 0;
    for (int j = 0; _plan.sync_data_->region_[j] != END_SYNC; ++j) {
        for (int i = offset; i < _plan.sync_data_->region_[j]; ++i) {
            int l_region_n = _plan.base_data_->region_[i].region_n;
            int l_t0 = _plan.base_data_->region_[i].t0;
            int l_t1 = _plan.base_data_->region_[i].t1;
            Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
            for (int t = l_t0; t < l_t1; ++t) {
                if (l_region_n >= 0) {
                    /* execute one of the exclusive_if's */
                    Pochoir_Run_Regional_Tile_Kernel<N_RANK> l_kernel(time_shift_, pxts_[l_region_n]);
                    meta_grid_boundary<N_RANK>::single_step(t, l_grid, phys_grid_, l_kernel);
                }
                for (int i = 0; i < sz_pigk_; ++i) {
                    Pochoir_Run_Regional_Guard_Tile_Kernel<N_RANK> l_kernel(time_shift_, pigs_[i], pits_[i]);
                    meta_grid_boundary<N_RANK>::single_step(t, l_grid, phys_grid_, l_kernel);
                }
                for (int i = 0; i < sz_ptigk_; ++i) {
                    Pochoir_Run_Regional_Guard_Tile_Kernel<N_RANK> l_kernel(time_shift_, ptigs_[i], ptits_[i]);
                    meta_grid_boundary<N_RANK>::single_step(t, l_grid, phys_grid_, l_kernel);
                }
                for (int i = 0; i < N_RANK; ++i) {
                    l_grid.x0[i] += l_grid.dx0[i]; l_grid.x1[i] += l_grid.dx1[i];
                }
            }
        }
        offset = _plan.sync_data_->region_[j];
    }
    return;
}

template <int N_RANK>
void Pochoir<N_RANK>::Run_Obase(Pochoir_Plan<N_RANK> & _plan) {
    Algorithm<N_RANK> algor(slope_);
    algor.set_phys_grid(phys_grid_);
    algor.set_thres(arr_type_size_);
    algor.set_unroll(lcm_unroll_);
    algor.set_time_shift(time_shift_);
    if (pmode_ == Pochoir_Obase_Tile) {
        algor.set_opks(sz_pxgk_, opgs_, opks_.get_root());
    } else {
        printf("Something is wrong in Run_Obase(Plan)!\n");
        exit(1);
    }
    checkFlags();
#if USE_CILK_FOR
    int offset = 0;
    for (int j = 0; _plan.sync_data_->region_[j] != END_SYNC; ++j) {
        cilk_for (int i = offset; i < _plan.sync_data_->region_[j]; ++i) {
            int l_region_n = _plan.base_data_->region_[i].region_n;
            assert(l_region_n >= 0);
            int l_t0 = _plan.base_data_->region_[i].t0;
            int l_t1 = _plan.base_data_->region_[i].t1;
            Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
            algor.plan_bicut_p(l_t0, l_t1, l_grid, l_region_n);
        }
        offset = _plan.sync_data_->region_[j];
    }
#else
    int offset = 0, i;
    for (int j = 0; _plan.sync_data_->region_[j] != END_SYNC; ++j) {
        for (i = offset; i < _plan.sync_data_->region_[j]-1; ++i) {
            int l_region_n = _plan.base_data_->region_[i].region_n;
            assert(l_region_n >= 0);
            int l_t0 = _plan.base_data_->region_[i].t0;
            int l_t1 = _plan.base_data_->region_[i].t1;
            Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
            cilk_spawn algor.plan_bicut_p(l_t0, l_t1, l_grid, l_region_n);
        }
        int l_region_n = _plan.base_data_->region_[i].region_n;
        assert(l_region_n >= 0);
        int l_t0 = _plan.base_data_->region_[i].t0;
        int l_t1 = _plan.base_data_->region_[i].t1;
        Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
        algor.plan_bicut_p(l_t0, l_t1, l_grid, l_region_n);
        cilk_sync;
        offset = _plan.sync_data_->region_[j];
    }
#endif
#if DEBUG
    int l_num_kernel = 0, l_num_cond_kernel = 0, l_num_bkernel = 0, l_num_cond_bkernel = 0;
    algor.read_stat_kernel(l_num_kernel, l_num_cond_kernel, l_num_bkernel, l_num_cond_bkernel);
    printf("kernel = %d, cond_kernel = %d, bkernel = %d, cond_bkernel = %d\n",
            l_num_kernel, l_num_cond_kernel, l_num_bkernel, l_num_cond_bkernel);
#endif
    return;
}

template <int N_RANK>
void Pochoir<N_RANK>::Run_Obase_Merge(Pochoir_Plan<N_RANK> & _plan) {
    Algorithm<N_RANK> algor(slope_);
    algor.set_phys_grid(phys_grid_);
    algor.set_thres(arr_type_size_);
    algor.set_unroll(lcm_unroll_);
    algor.set_time_shift(time_shift_);
    if (pmode_ == Pochoir_Obase_Tile) {
        algor.set_opks(sz_pxgk_, opgs_, opks_.get_root());
    } else {
        printf("Something is wrong in Run_Obase(Plan)!\n");
        exit(1);
    }
    checkFlags();
#if USE_CILK_FOR
    int offset = 0;
    for (int j = 0; _plan.sync_data_->region_[j] != END_SYNC; ++j) {
        cilk_for (int i = offset; i < _plan.sync_data_->region_[j]; ++i) {
            int l_region_n = _plan.base_data_->region_[i].region_n;
            assert(l_region_n >= 0);
            int l_t0 = _plan.base_data_->region_[i].t0;
            int l_t1 = _plan.base_data_->region_[i].t1;
            Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
            typename Pochoir_Types<N_RANK>::T_Obase_Kernel & f = opks_[l_region_n].kernel_[0].Get_Kernel();
            typename Pochoir_Types<N_RANK>::T_Obase_Kernel & bf = opks_[l_region_n].bkernel_[0].Get_Kernel();
            algor.plan_bicut_mp(l_t0, l_t1, l_grid, l_region_n, f, bf);
        }
        offset = _plan.sync_data_->region_[j];
    }
#else
    int offset = 0, i;
    for (int j = 0; _plan.sync_data_->region_[j] != END_SYNC; ++j) {
        for (i = offset; i < _plan.sync_data_->region_[j]-1; ++i) {
            int l_region_n = _plan.base_data_->region_[i].region_n;
            assert(l_region_n >= 0);
            int l_t0 = _plan.base_data_->region_[i].t0;
            int l_t1 = _plan.base_data_->region_[i].t1;
            Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
            typename Pochoir_Types<N_RANK>::T_Obase_Kernel & f = opks_[l_region_n].kernel_[0].Get_Kernel();
            typename Pochoir_Types<N_RANK>::T_Obase_Kernel & bf = opks_[l_region_n].bkernel_[0].Get_Kernel();
            cilk_spawn algor.plan_bicut_mp(l_t0, l_t1, l_grid, l_region_n, f, bf);
        }
        int l_region_n = _plan.base_data_->region_[i].region_n;
        assert(l_region_n >= 0);
        int l_t0 = _plan.base_data_->region_[i].t0;
        int l_t1 = _plan.base_data_->region_[i].t1;
        Grid_Info<N_RANK> l_grid = _plan.base_data_->region_[i].grid;
        typename Pochoir_Types<N_RANK>::T_Obase_Kernel & f = opks_[l_region_n].kernel_[0].Get_Kernel();
        typename Pochoir_Types<N_RANK>::T_Obase_Kernel & bf = opks_[l_region_n].bkernel_[0].Get_Kernel();
        algor.plan_bicut_mp(l_t0, l_t1, l_grid, l_region_n, f, bf);
        cilk_sync;
        offset = _plan.sync_data_->region_[j];
    }

#endif
#if DEBUG
    int l_num_kernel = 0, l_num_cond_kernel = 0, l_num_bkernel = 0, l_num_cond_bkernel = 0;
    algor.read_stat_kernel(l_num_kernel, l_num_cond_kernel, l_num_bkernel, l_num_cond_bkernel);
    printf("kernel = %d, cond_kernel = %d, bkernel = %d, cond_bkernel = %d\n",
            l_num_kernel, l_num_cond_kernel, l_num_bkernel, l_num_cond_bkernel);
#endif
    return;
}
#endif
